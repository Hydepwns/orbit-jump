-- UI System for Orbit Jump
-- Handles progression display, upgrade menus, and blockchain status

local Utils = require("src.utils.utils")
-- Try to load the enhanced debug system, fall back to basic version if needed
local UIDebug = Utils.safeRequire("src.ui.debug.ui_debug_enhanced") or 
                Utils.safeRequire("src.ui.debug.ui_debug") or 
                {
                    init = function() end,
                    draw = function() end,
                    keypressed = function() return false end,
                    updatePerformanceMetrics = function() end,
                    registerElement = function() end
                }
local UISystem = {}

-- UI state
UISystem.currentScreen = "game" -- game, menu, upgrades, achievements, blockchain, settings, accessibility, stats
UISystem.showProgression = false -- Disabled to prevent UI overlap
UISystem.showBlockchainStatus = false
UISystem.menuSelection = 1
UISystem.upgradeSelection = 1
UISystem.settingsSelection = 1
UISystem.settingsCategory = "addiction" -- addiction, audio, visual, accessibility
UISystem.statsSelection = 1

-- Event notification state
UISystem.eventNotification = {
    active = false,
    message = "",
    color = {1, 1, 1, 1},
    timer = 0,
    duration = 3.0,
    fadeIn = 0.3,
    fadeOut = 0.5
}

-- UI elements
UISystem.elements = {
    progressionBar = { x = 10, y = 10, width = 200, height = 20 },
    upgradeButton = { x = 10, y = 40, width = 100, height = 30 },
    blockchainButton = { x = 120, y = 40, width = 100, height = 30 },
    menuPanel = { x = 50, y = 100, width = 300, height = 400 }
}

-- Responsive UI scaling with accessibility compliance
function UISystem.updateResponsiveLayout()
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    
    local uiScale = 1.0 -- Default scale
    local isMobile = false -- Default to desktop
    
    -- Safely get UI scale and mobile detection
    if Utils.MobileInput and Utils.MobileInput.getUIScale then
        uiScale = Utils.MobileInput.getUIScale()
    end
    if Utils.MobileInput and Utils.MobileInput.isMobile then
        isMobile = Utils.MobileInput.isMobile()
    end
    
    -- Load mobile accessibility system
    local MobileAccessibility = Utils.require("src.systems.mobile_accessibility")
    
    -- Update UI element positions and sizes based on screen size
    if isMobile then
        -- Mobile layout with accessibility compliance
        local minTouchTarget = MobileAccessibility and MobileAccessibility.getMinTouchTarget() or 44
        
        -- Progression bar - ensure minimum touch target height
        local progressionHeight = math.max(30, minTouchTarget)
        UISystem.elements.progressionBar = { 
            x = 10, y = 10, 
            width = screenWidth - 20, height = progressionHeight
        }
        
        -- Buttons - ensure minimum touch target size
        local buttonHeight = math.max(50, minTouchTarget)
        local buttonWidth = math.max((screenWidth - 30) / 2, minTouchTarget)
        
        UISystem.elements.upgradeButton = { 
            x = 10, y = 10 + progressionHeight + 10, 
            width = buttonWidth, height = buttonHeight
        }
        UISystem.elements.blockchainButton = { 
            x = screenWidth / 2 + 5, y = 10 + progressionHeight + 10, 
            width = buttonWidth, height = buttonHeight
        }
        
        -- Menu panel - positioned below buttons with proper spacing
        local menuY = 10 + progressionHeight + 10 + buttonHeight + 10
        UISystem.elements.menuPanel = { 
            x = 20, y = menuY, 
            width = screenWidth - 40, height = screenHeight - menuY - 20
        }
    else
        -- Desktop layout - original positioning
        UISystem.elements.progressionBar = { x = 10, y = 10, width = 200, height = 20 }
        UISystem.elements.upgradeButton = { x = 10, y = 40, width = 100, height = 30 }
        UISystem.elements.blockchainButton = { x = 120, y = 40, width = 100, height = 30 }
        UISystem.elements.menuPanel = { x = 50, y = 30, width = 700, height = 550 }
    end
    
    -- Apply accessibility fixes if system is available
    if MobileAccessibility then
        local fixes = MobileAccessibility.applyAccessibilityFixes(UISystem.elements)
        if #fixes > 0 then
            Utils.Logger.info("Applied accessibility fixes: %s", table.concat(fixes, ", "))
        end
        
        -- Validate layout for accessibility
        local issues, warnings = MobileAccessibility.validateLayout(UISystem.elements)
        if #issues > 0 then
            Utils.Logger.warn("Accessibility issues found: %s", table.concat(issues, ", "))
        end
        if #warnings > 0 then
            Utils.Logger.warn("Accessibility warnings: %s", table.concat(warnings, ", "))
        end
    end
    
    -- Store scale for use in drawing
    UISystem.uiScale = uiScale
    UISystem.isMobile = isMobile
    
    -- Register elements with debug system
    for name, element in pairs(UISystem.elements) do
        UIDebug.registerElement("UISystem." .. name, element)
    end
end

function UISystem.init(fonts)
    UISystem.fonts = fonts
    UISystem.updateResponsiveLayout()
    UIDebug.init()
    
    -- Load user configuration
    local Config = Utils.require("src.utils.config")
    if Config and Config.load then
        Config.load()
    end
end

function UISystem.update(dt, progressionSystem, blockchainIntegration)
    UISystem.progressionSystem = progressionSystem
    UISystem.blockchainIntegration = blockchainIntegration
    
    -- Update performance metrics for debug system
    UIDebug.updatePerformanceMetrics(dt)
    
    -- Update event notification
    UISystem.updateEventNotification(dt)
    
    -- Update responsive layout if screen size changed
    local currentWidth, currentHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        currentWidth, currentHeight = love.graphics.getDimensions()
    end
    if not UISystem.lastScreenSize then
        UISystem.lastScreenSize = { width = currentWidth, height = currentHeight }
    elseif UISystem.lastScreenSize.width ~= currentWidth or UISystem.lastScreenSize.height ~= currentHeight then
        UISystem.updateResponsiveLayout()
        UISystem.lastScreenSize = { width = currentWidth, height = currentHeight }
    end
end

function UISystem.draw()
    if UISystem.currentScreen == "game" then
        -- Draw minimal game UI (score, combo, etc)
        UISystem.drawGameUI()
    else
        -- Draw menu screens
        if UISystem.currentScreen == "menu" then
            UISystem.drawMenuUI()
        elseif UISystem.currentScreen == "upgrades" then
            UISystem.drawUpgradeUI()
        elseif UISystem.currentScreen == "achievements" then
            UISystem.drawAchievementUI()
        elseif UISystem.currentScreen == "prestige" then
            local PrestigeSystem = Utils.require("src.systems.prestige_system")
            if PrestigeSystem then
                PrestigeSystem.drawPrestigeMenu()
            end
        elseif UISystem.currentScreen == "mastery" then
            local MasterySystem = Utils.require("src.systems.mastery_system")
            if MasterySystem then
                MasterySystem.drawMasteryMenu()
            end
        elseif UISystem.currentScreen == "daily_streak" then
            local DailyStreakSystem = Utils.require("src.systems.daily_streak_system")
            if DailyStreakSystem then
                DailyStreakSystem.drawCalendar()
            end
        elseif UISystem.currentScreen == "blockchain" then
            UISystem.drawBlockchainUI()
        elseif UISystem.currentScreen == "stats" then
            UISystem.drawStatsUI()
        elseif UISystem.currentScreen == "settings" then
            UISystem.drawSettingsUI()
        elseif UISystem.currentScreen == "accessibility" then
            UISystem.drawAccessibilityUI()
        end
    end
    
    -- Draw event notification
    UISystem.drawEventNotification()
    
    -- Draw debug visualization last (on top)
    UIDebug.draw()
end

function UISystem.drawGameUI()
    local GameState = Utils.require("src.core.game_state")
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getWidth then
        screenWidth = love.graphics.getWidth()
    end
    if love and love.graphics and love.graphics.getHeight then
        screenHeight = love.graphics.getHeight()
    end
    
    -- Draw score and combo
    Utils.setColor({1, 1, 1}, 1)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.print("Score: " .. GameState.getScore(), 10, 10)
    
    -- Draw combo if active
    if GameState.getCombo() > 0 then
        Utils.setColor({1, 1, 0}, 1)
        love.graphics.print("Combo: " .. GameState.getCombo() .. "x", 10, 35)
    end
    
    -- Draw Daily Streak
    local DailyStreakSystem = Utils.require("src.systems.daily_streak_system")
    if DailyStreakSystem then
        DailyStreakSystem.draw()
    end
    
    -- Draw Prestige indicator
    local PrestigeSystem = Utils.require("src.systems.prestige_system")
    if PrestigeSystem then
        PrestigeSystem.draw()
    end
    
    -- Draw Mastery indicator
    local MasterySystem = Utils.require("src.systems.mastery_system")
    if MasterySystem then
        MasterySystem.draw()
    end
    
    -- Draw Achievement notifications
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem then
        AchievementSystem.draw()
    end
    
    -- Draw controls hint
    Utils.setColor({0.7, 0.7, 0.7}, 0.8)
    love.graphics.print("Press U for upgrades | TAB for map", screenWidth - 250, 10)
    
    -- Draw daily reward notification if pending
    local GameState = Utils.require("src.core.game_state")
    if GameState.data.pending_daily_reward then
        local DailyStreakSystem = Utils.require("src.systems.daily_streak_system")
        if DailyStreakSystem then
            DailyStreakSystem.drawRewardNotification(GameState.data.pending_daily_reward)
            
            -- Clear the notification after a few seconds
            if not UISystem.dailyRewardTimer then
                UISystem.dailyRewardTimer = 0
            end
            UISystem.dailyRewardTimer = UISystem.dailyRewardTimer + love.timer.getDelta()
            if UISystem.dailyRewardTimer > 5 then
                GameState.data.pending_daily_reward = nil
                UISystem.dailyRewardTimer = nil
            end
        end
    end
    
    -- Draw reset hint if in space
    if not GameState.player.onPlanet then
        love.graphics.print("Press R to reset if stuck", screenWidth - 200, screenHeight - 30)
    end
    
    -- Draw learning system status (101% feature)
    UISystem.drawLearningIndicator(screenWidth, screenHeight)
end

-- Draw learning system indicator
function UISystem.drawLearningIndicator(screenWidth, screenHeight)
    --[[
        Learning Awareness: Making the Invisible Visible
        
        This indicator shows the player that the game is learning and adapting
        to their behavior. It's a small but important piece of the 101% experience -
        letting players know that their unique style is being recognized and valued.
    --]]
    
    -- Get learning status from various systems
    local WarpDrive = Utils.require("src.systems.warp_drive")
    local PlayerAnalytics = Utils.require("src.systems.player_analytics")
    local PlayerSystem = Utils.require("src.systems.player_system")
    
    local isLearning = false
    local learningInfo = {}
    
    -- Check if WarpDrive is learning
    if WarpDrive and WarpDrive.memory then
        local stats = WarpDrive.getMemoryStats()
        if stats.totalWarps > 0 then
            isLearning = true
            table.insert(learningInfo, string.format("Route Memory: %d paths", stats.knownRoutes))
            if stats.efficiency > 0.5 then
                table.insert(learningInfo, string.format("Efficiency: %.0f%%", stats.efficiency * 100))
            end
        end
    end
    
    -- Check if PlayerAnalytics is learning
    if PlayerAnalytics and PlayerAnalytics.memory then
        local profile = PlayerAnalytics.getPlayerProfile()
        if profile and profile.skillLevel and profile.skillLevel > 0 then
            isLearning = true
            table.insert(learningInfo, string.format("Skill: %.0f%%", profile.skillLevel * 100))
            table.insert(learningInfo, string.format("Style: %s", profile.movementStyle or "learning"))
        end
    end
    
    -- Check if physics are adapting
    if PlayerSystem and PlayerSystem.getAdaptivePhysicsStatus then
        local physicsStatus = PlayerSystem.getAdaptivePhysicsStatus()
        if physicsStatus.isAdapting then
            isLearning = true
            table.insert(learningInfo, "Physics: Adapted")
        end
    end
    
    -- Draw the indicator if systems are learning
    if isLearning then
        local indicatorX = screenWidth - 220
        local indicatorY = screenHeight - 120
        local indicatorWidth = 200
        local indicatorHeight = 80
        
        -- Background with subtle pulse
        local pulseAlpha = 0.3 + 0.2 * math.sin(love.timer.getTime() * 2)
        Utils.setColor({0.1, 0.3, 0.6}, pulseAlpha)
        love.graphics.rectangle("fill", indicatorX, indicatorY, indicatorWidth, indicatorHeight, 5)
        
        -- Border
        Utils.setColor({0.3, 0.6, 1.0}, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", indicatorX, indicatorY, indicatorWidth, indicatorHeight, 5)
        
        -- Title with brain icon effect
        Utils.setColor({0.8, 0.9, 1.0}, 1.0)
        love.graphics.setFont(love.graphics.newFont(12))
        local brainPulse = 1.0 + 0.1 * math.sin(love.timer.getTime() * 3)
        love.graphics.print("🧠 Learning...", indicatorX + 8, indicatorY + 8)
        
        -- Learning details
        Utils.setColor({0.7, 0.8, 0.9}, 0.9)
        love.graphics.setFont(love.graphics.newFont(10))
        for i, info in ipairs(learningInfo) do
            if i <= 3 then -- Show max 3 lines to fit
                love.graphics.print(info, indicatorX + 8, indicatorY + 25 + (i-1) * 15)
            end
        end
    end
end

function UISystem.drawProgressionBar()
    local bar = UISystem.elements.progressionBar
    local data = UISystem.progressionSystem.data
    
    -- Calculate progress (example: based on total score)
    local progress = math.min(data.totalScore / 10000, 1.0)
    
    Utils.drawProgressBar(bar.x, bar.y, bar.width, bar.height, progress)
    
    -- Draw border
    Utils.setColor(Utils.colors.text)
    love.graphics.rectangle("line", bar.x, bar.y, bar.width, bar.height)
    
    -- Draw text
    love.graphics.setFont(UISystem.fonts.regular)
    love.graphics.print("Progress: " .. math.floor(progress * 100) .. "%", bar.x, bar.y + 2)
end

function UISystem.drawButton(text, x, y, width, height)
    -- Handle case where Utils.drawButton is not available or love.graphics is not available
    if not Utils.drawButton then
        return -- Skip drawing if function not available
    end
    
    -- Use pcall to safely call the drawButton function
    local success, result = pcall(Utils.drawButton, text, x, y, width, height)
    if not success then
        -- If drawing fails, just return without error
        return
    end
end

function UISystem.drawMenuUI()
    local panel = UISystem.elements.menuPanel
    
    -- Draw background
    Utils.setColor(Utils.colors.background)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height)
    
    Utils.setColor(Utils.colors.text)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height)
    
    -- Draw menu options
    local options = {"Continue", "Upgrades", "Achievements", "Prestige", "Mastery", "Daily Streak", "Statistics", "Settings", "Blockchain", "Back to Game"}
    local y = panel.y + 20
    
    for i, option in ipairs(options) do
        if i == UISystem.menuSelection then
            Utils.setColor(Utils.colors.highlight)
        else
            Utils.setColor(Utils.colors.text)
        end
        
        love.graphics.setFont(UISystem.fonts.bold)
        love.graphics.print(option, panel.x + 20, y)
        y = y + 40
    end
end

function UISystem.drawAccessibilityUI()
    local MobileAccessibility = Utils.require("src.systems.mobile_accessibility")
    
    -- Get screen dimensions
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    
    -- Calculate responsive panel size
    local panelWidth = math.min(500, screenWidth - 40)
    local panelHeight = math.min(400, screenHeight - 40)
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = (screenHeight - panelHeight) / 2
    
    -- Draw background with transparency
    Utils.setColor({0, 0, 0}, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10)
    
    Utils.setColor({1, 0.8, 0.2}, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10)
    
    -- Draw title
    local titleFont = love.graphics.newFont(18)
    love.graphics.setFont(titleFont)
    Utils.setColor({1, 0.8, 0.2})
    love.graphics.printf("ACCESSIBILITY", panelX, panelY + 20, panelWidth, "center")
    
    -- Draw device info
    local mediumFont = love.graphics.newFont(14)
    love.graphics.setFont(mediumFont)
    Utils.setColor({1, 1, 0.5})
    
    if MobileAccessibility then
        local report = MobileAccessibility.getReport()
        local info = string.format("Device: %s (%s) - Touch Target: %dpx", 
            report.deviceType, report.os, report.minTouchTarget)
        love.graphics.printf(info, panelX, panelY + 45, panelWidth, "center")
    end
    
    -- Draw accessibility features
    local startY = panelY + 80
    local itemHeight = 40
    local features = {
        {key = "highContrast", name = "High Contrast Mode", desc = "Enhanced color contrast"},
        {key = "largeText", name = "Large Text", desc = "Increased font sizes"},
        {key = "reducedMotion", name = "Reduced Motion", desc = "Minimize animations"},
        {key = "hapticFeedback", name = "Haptic Feedback", desc = "Touch vibration"},
        {key = "soundFeedback", name = "Sound Feedback", desc = "Audio cues"}
    }
    
    for i, feature in ipairs(features) do
        local y = startY + (i - 1) * (itemHeight + 5)
        
        -- Draw feature name
        Utils.setColor(Utils.colors.white)
        local smallFont = love.graphics.newFont(12)
        love.graphics.setFont(smallFont)
        love.graphics.print(feature.name, panelX + 20, y + 5)
        
        -- Draw description
        Utils.setColor({0.6, 0.6, 0.6})
        local tinyFont = love.graphics.newFont(10)
        love.graphics.setFont(tinyFont)
        love.graphics.print(feature.desc, panelX + 20, y + 22)
        
        -- Draw toggle status
        if MobileAccessibility then
            local isEnabled = MobileAccessibility.features[feature.key]
            local statusText = isEnabled and "ON" or "OFF"
            local statusColor = isEnabled and {0.2, 1, 0.2} or {0.6, 0.6, 0.6}
            
            Utils.setColor(statusColor)
            love.graphics.print(statusText, panelX + panelWidth - 60, y + 10)
        end
    end
    
    -- Draw controls
    local smallFont = love.graphics.newFont(10)
    love.graphics.setFont(smallFont)
    Utils.setColor({0.6, 0.6, 0.6})
    love.graphics.printf("F8: Large Text    F9: High Contrast    ESC: Close", 
        panelX, panelY + panelHeight - 25, panelWidth, "center")
end

function UISystem.drawSettingsUI()
    local Config = Utils.require("src.utils.config")
    if not Config then return end
    
    -- Get screen dimensions
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    
    -- Calculate responsive panel size
    local panelWidth = math.min(700, screenWidth - 40)
    local panelHeight = math.min(500, screenHeight - 40)
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = (screenHeight - panelHeight) / 2
    
    -- Draw background with transparency
    Utils.setColor({0, 0, 0}, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10)
    
    Utils.setColor({1, 0.8, 0.2}, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10)
    
    -- Draw title
    local titleFont = love.graphics.newFont(18)
    love.graphics.setFont(titleFont)
    Utils.setColor({1, 0.8, 0.2})
    love.graphics.printf("ADDICTION FEATURES SETTINGS", panelX, panelY + 20, panelWidth, "center")
    
    -- Draw category tabs
    UISystem.drawSettingsTabs(panelX, panelY + 50, panelWidth)
    
    -- Draw settings based on current category
    if UISystem.settingsCategory == "addiction" then
        UISystem.drawAddictionSettings(panelX, panelY + 90, panelWidth, panelHeight - 140)
    elseif UISystem.settingsCategory == "visual" then
        UISystem.drawVisualSettings(panelX, panelY + 90, panelWidth, panelHeight - 140)
    elseif UISystem.settingsCategory == "audio" then
        UISystem.drawAudioSettings(panelX, panelY + 90, panelWidth, panelHeight - 140)
    elseif UISystem.settingsCategory == "accessibility" then
        UISystem.drawAccessibilitySettings(panelX, panelY + 90, panelWidth, panelHeight - 140)
    end
    
    -- Draw controls
    local smallFont = love.graphics.newFont(10)
    love.graphics.setFont(smallFont)
    Utils.setColor({0.6, 0.6, 0.6})
    love.graphics.printf("TAB: Switch Category    UP/DOWN: Navigate    ENTER: Toggle    ESC: Close", 
        panelX, panelY + panelHeight - 25, panelWidth, "center")
end

function UISystem.drawSettingsTabs(x, y, width)
    local categories = {"addiction", "visual", "audio", "accessibility"}
    local tabWidth = width / #categories
    
    for i, category in ipairs(categories) do
        local tabX = x + (i - 1) * tabWidth
        local isActive = UISystem.settingsCategory == category
        
        -- Tab background
        if isActive then
            Utils.setColor({1, 0.8, 0.2}, 0.3)
        else
            Utils.setColor({0.3, 0.3, 0.3}, 0.5)
        end
        love.graphics.rectangle("fill", tabX, y, tabWidth, 30, 5)
        
        -- Tab border
        if isActive then
            Utils.setColor({1, 0.8, 0.2})
        else
            Utils.setColor({0.6, 0.6, 0.6})
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", tabX, y, tabWidth, 30, 5)
        love.graphics.setLineWidth(1)
        
        -- Tab text
        Utils.setColor(isActive and {1, 1, 1} or {0.8, 0.8, 0.8})
        local font = love.graphics.newFont(12)
        love.graphics.setFont(font)
        love.graphics.printf(category:upper(), tabX, y + 8, tabWidth, "center")
    end
end

function UISystem.drawAddictionSettings(x, y, width, height)
    local Config = Utils.require("src.utils.config")
    if not Config or not Config.addiction then return end
    
    local settings = {
        {key = "event_frequency", name = "Event Frequency", 
         options = {"high", "normal", "low", "off"}, 
         desc = "How often mystery boxes and random events appear"},
        {key = "streak_pressure_mode", name = "Streak Pressure", 
         options = {"competitive", "casual", "zen"}, 
         desc = "Grace period length for streak recovery"},
        {key = "notification_frequency", name = "Notifications", 
         options = {"all", "important", "minimal"}, 
         desc = "Which events show notification popups"},
        {key = "progress_visibility", name = "Progress Display", 
         options = {"always", "contextual", "hidden"}, 
         desc = "When to show XP and level progress"},
        {key = "xp_gain_animations", name = "XP Animations", type = "boolean",
         desc = "Show floating XP gain numbers"},
        {key = "level_up_celebrations", name = "Level Up Effects", type = "boolean",
         desc = "Show level up celebration animations"},
        {key = "mystery_box_buildup", name = "Mystery Box Buildup", type = "boolean",
         desc = "Show anticipation animations for mystery boxes"},
        {key = "milestone_notifications", name = "Milestone Alerts", type = "boolean",
         desc = "Show notifications for streak milestones"}
    }
    
    UISystem.drawSettingsList(settings, Config.addiction, x, y, width, height)
end

function UISystem.drawVisualSettings(x, y, width, height)
    local Config = Utils.require("src.utils.config")
    if not Config or not Config.addiction then return end
    
    local settings = {
        {key = "visual_effects_intensity", name = "Effects Intensity", 
         options = {"full", "reduced", "minimal"}, 
         desc = "Visual effects scaling and intensity"},
        {key = "streak_screen_effects", name = "Streak Screen Effects", type = "boolean",
         desc = "Full-screen effects during streak events"},
        {key = "motion_sensitivity", name = "Reduce Motion", type = "boolean",
         desc = "Reduce screen shake and flash effects"},
        {key = "colorblind_support", name = "Colorblind Support", type = "boolean",
         desc = "Alternative visual indicators for colors"}
    }
    
    UISystem.drawSettingsList(settings, Config.addiction, x, y, width, height)
end

function UISystem.drawAudioSettings(x, y, width, height)
    local Config = Utils.require("src.utils.config")
    if not Config or not Config.addiction then return end
    
    local settings = {
        {key = "audio_feedback_level", name = "Audio Feedback", 
         options = {"full", "reduced", "essential"}, 
         desc = "Amount of audio feedback for events"},
        {key = "hearing_impaired", name = "Hearing Impaired Mode", type = "boolean",
         desc = "Enhanced visual feedback to replace audio cues"}
    }
    
    UISystem.drawSettingsList(settings, Config.addiction, x, y, width, height)
end

function UISystem.drawAccessibilitySettings(x, y, width, height)
    local Config = Utils.require("src.utils.config")
    if not Config or not Config.addiction then return end
    
    local settings = {
        {key = "session_break_reminders", name = "Break Reminders", type = "boolean",
         desc = "Remind to take breaks during long sessions"},
        {key = "session_limit_warnings", name = "Session Warnings", type = "boolean",
         desc = "Warn about extended play sessions"},
        {key = "auto_pause_inactive", name = "Auto-Pause Timer", 
         options = {"0", "300", "600", "900", "1800"}, 
         desc = "Auto-pause after inactivity (seconds, 0=disabled)"}
    }
    
    UISystem.drawSettingsList(settings, Config.addiction, x, y, width, height)
end

function UISystem.drawSettingsList(settings, configSection, x, y, width, height)
    local font = love.graphics.newFont(12)
    love.graphics.setFont(font)
    local itemHeight = 50
    
    for i, setting in ipairs(settings) do
        local itemY = y + (i - 1) * itemHeight
        local isSelected = UISystem.settingsSelection == i
        
        -- Highlight selected item
        if isSelected then
            Utils.setColor({1, 0.8, 0.2}, 0.2)
            love.graphics.rectangle("fill", x + 10, itemY - 2, width - 20, itemHeight - 4, 5)
        end
        
        -- Setting name
        Utils.setColor({1, 1, 1})
        love.graphics.print(setting.name, x + 20, itemY + 5)
        
        -- Setting value
        local currentValue = configSection[setting.key]
        local valueText = ""
        
        if setting.type == "boolean" then
            valueText = currentValue and "ON" or "OFF"
            Utils.setColor(currentValue and {0.2, 1, 0.2} or {1, 0.2, 0.2})
        elseif setting.options then
            valueText = tostring(currentValue):upper()
            Utils.setColor({0.8, 0.8, 1})
        else
            valueText = tostring(currentValue)
            Utils.setColor({0.8, 0.8, 0.8})
        end
        
        love.graphics.print(valueText, x + width - 120, itemY + 5)
        
        -- Description
        Utils.setColor({0.6, 0.6, 0.6})
        local smallFont = love.graphics.newFont(10)
        love.graphics.setFont(smallFont)
        love.graphics.printf(setting.desc, x + 20, itemY + 25, width - 140, "left")
        love.graphics.setFont(font)
    end
end

function UISystem.drawStatsUI()
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if not SessionStatsSystem then return end
    
    -- Get screen dimensions
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    
    -- Calculate responsive panel size
    local panelWidth = math.min(800, screenWidth - 40)
    local panelHeight = math.min(600, screenHeight - 40)
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = (screenHeight - panelHeight) / 2
    
    -- Draw background with transparency
    Utils.setColor({0, 0, 0}, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10)
    
    Utils.setColor({1, 0.8, 0.2}, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10)
    
    -- Draw title
    local titleFont = love.graphics.newFont(18)
    love.graphics.setFont(titleFont)
    Utils.setColor({1, 0.8, 0.2})
    love.graphics.printf("SESSION STATISTICS", panelX, panelY + 20, panelWidth, "center")
    
    -- Get current session data
    local session = SessionStatsSystem.getCurrentSession()
    local summary = SessionStatsSystem.getSessionSummary()
    local comparison = SessionStatsSystem.getPerformanceComparison()
    local historical = SessionStatsSystem.getHistoricalData()
    
    -- Draw sections
    local sections = {"Current Session", "Performance Analysis", "Personal Bests"}
    local sectionHeight = (panelHeight - 120) / 3
    
    for i, sectionName in ipairs(sections) do
        local isSelected = UISystem.statsSelection == i
        local sectionY = panelY + 60 + (i - 1) * sectionHeight
        
        -- Section header
        if isSelected then
            Utils.setColor({1, 0.8, 0.2}, 0.3)
            love.graphics.rectangle("fill", panelX + 10, sectionY, panelWidth - 20, sectionHeight - 10, 5)
        end
        
        Utils.setColor(isSelected and {1, 1, 1} or {0.8, 0.8, 0.8})
        local headerFont = love.graphics.newFont(14)
        love.graphics.setFont(headerFont)
        love.graphics.print(sectionName, panelX + 20, sectionY + 10)
        
        -- Section content
        if i == 1 then
            UISystem.drawCurrentSessionStats(session, summary, panelX + 20, sectionY + 35, panelWidth - 40)
        elseif i == 2 then
            UISystem.drawPerformanceAnalysis(comparison, panelX + 20, sectionY + 35, panelWidth - 40)
        elseif i == 3 then
            UISystem.drawPersonalBests(historical.personalBests, panelX + 20, sectionY + 35, panelWidth - 40)
        end
    end
    
    -- Draw controls
    local smallFont = love.graphics.newFont(10)
    love.graphics.setFont(smallFont)
    Utils.setColor({0.6, 0.6, 0.6})
    love.graphics.printf("UP/DOWN: Navigate Sections    ESC: Close", 
        panelX, panelY + panelHeight - 25, panelWidth, "center")
end

function UISystem.drawCurrentSessionStats(session, summary, x, y, width)
    local font = love.graphics.newFont(11)
    love.graphics.setFont(font)
    
    local stats = {
        {"Duration:", summary.duration},
        {"Perfect Landing Accuracy:", summary.perfectLandingAccuracy},
        {"Best Streak:", tostring(summary.bestStreak)},
        {"XP Gained:", tostring(summary.xpGained)},
        {"XP Per Minute:", summary.xpPerMinute},
        {"Rings Collected:", tostring(summary.ringsCollected)},
        {"Focus Score:", tostring(summary.focusScore) .. "/100"},
        {"Consistency Score:", tostring(summary.consistencyScore) .. "/100"}
    }
    
    local col1Width = width * 0.6
    local col2Width = width * 0.4
    
    for i, stat in ipairs(stats) do
        local statY = y + (i - 1) * 18
        
        -- Stat name
        Utils.setColor({0.9, 0.9, 0.9})
        love.graphics.print(stat[1], x, statY)
        
        -- Stat value with color coding
        local value = stat[2]
        if string.find(stat[1], "Score") then
            -- Color code scores
            local score = tonumber(string.match(value, "%d+"))
            if score then
                if score >= 80 then
                    Utils.setColor({0.2, 1, 0.2}) -- Green
                elseif score >= 60 then
                    Utils.setColor({1, 1, 0.2}) -- Yellow
                else
                    Utils.setColor({1, 0.4, 0.4}) -- Red
                end
            else
                Utils.setColor({1, 1, 1})
            end
        elseif string.find(stat[1], "Accuracy") then
            -- Color code accuracy
            local accuracy = tonumber(string.match(value, "([%d%.]+)"))
            if accuracy then
                if accuracy >= 80 then
                    Utils.setColor({0.2, 1, 0.2}) -- Green
                elseif accuracy >= 60 then
                    Utils.setColor({1, 1, 0.2}) -- Yellow
                else
                    Utils.setColor({1, 0.4, 0.4}) -- Red
                end
            else
                Utils.setColor({1, 1, 1})
            end
        else
            Utils.setColor({1, 1, 1})
        end
        
        love.graphics.print(value, x + col1Width, statY)
    end
end

function UISystem.drawPerformanceAnalysis(comparison, x, y, width)
    local font = love.graphics.newFont(11)
    love.graphics.setFont(font)
    
    if not comparison then
        Utils.setColor({0.7, 0.7, 0.7})
        love.graphics.print("Play more sessions to see performance trends", x, y)
        return
    end
    
    local analyses = {
        {"Accuracy vs Average:", string.format("%+.1f%%", comparison.accuracyDiff)},
        {"XP Rate vs Average:", string.format("%+.1f/min", comparison.xpDiff)},
        {"Streak vs Average:", string.format("%+d", comparison.streakDiff)},
        {"Focus vs Average:", string.format("%+d", comparison.focusDiff)}
    }
    
    local col1Width = width * 0.6
    
    for i, analysis in ipairs(analyses) do
        local analysisY = y + (i - 1) * 18
        
        -- Analysis name
        Utils.setColor({0.9, 0.9, 0.9})
        love.graphics.print(analysis[1], x, analysisY)
        
        -- Analysis value with improvement/decline color
        local value = analysis[2]
        local isImprovement = string.sub(value, 1, 1) == "+"
        if isImprovement then
            Utils.setColor({0.2, 1, 0.2}) -- Green for improvement
        elseif string.sub(value, 1, 1) == "-" then
            Utils.setColor({1, 0.4, 0.4}) -- Red for decline
        else
            Utils.setColor({1, 1, 0.2}) -- Yellow for neutral
        end
        
        love.graphics.print(value, x + col1Width, analysisY)
    end
    
    -- Overall trend
    Utils.setColor({0.8, 0.8, 1})
    love.graphics.print("Overall Performance Trend:", x, y + 80)
    
    local trendText = "Stable"
    local trendColor = {1, 1, 0.2}
    if comparison.accuracyDiff > 5 and comparison.xpDiff > 0 then
        trendText = "Improving"
        trendColor = {0.2, 1, 0.2}
    elseif comparison.accuracyDiff < -5 or comparison.xpDiff < -5 then
        trendText = "Needs Focus"
        trendColor = {1, 0.4, 0.4}
    end
    
    Utils.setColor(trendColor)
    love.graphics.print(trendText, x + col1Width, y + 80)
end

function UISystem.drawPersonalBests(bests, x, y, width)
    local font = love.graphics.newFont(11)
    love.graphics.setFont(font)
    
    if not bests or not bests.bestStreak then
        Utils.setColor({0.7, 0.7, 0.7})
        love.graphics.print("No personal bests recorded yet", x, y)
        return
    end
    
    local bestStats = {
        {"Best Streak:", tostring(bests.bestStreak or 0)},
        {"Highest Accuracy:", string.format("%.1f%%", bests.highestAccuracy or 0)},
        {"Fastest XP Rate:", string.format("%.1f/min", bests.fastestXP or 0)},
        {"Longest Session:", string.format("%.1fm", (bests.longestSession or 0) / 60)},
        {"Most Rings:", tostring(bests.mostRings or 0)}
    }
    
    local col1Width = width * 0.6
    
    for i, best in ipairs(bestStats) do
        local bestY = y + (i - 1) * 18
        
        -- Best name
        Utils.setColor({0.9, 0.9, 0.9})
        love.graphics.print(best[1], x, bestY)
        
        -- Best value in gold
        Utils.setColor({1, 0.8, 0.2})
        love.graphics.print(best[2], x + col1Width, bestY)
    end
end

function UISystem.drawUpgradeUI()
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    
    -- Get screen dimensions
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    
    -- Calculate responsive panel size
    local panelWidth = math.min(750, screenWidth - 40)
    local panelHeight = math.min(500, screenHeight - 40)
    local panelX = (screenWidth - panelWidth) / 2
    local panelY = (screenHeight - panelHeight) / 2
    
    -- Draw background with transparency
    Utils.setColor({0, 0, 0}, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight, 10)
    
    Utils.setColor({1, 0.8, 0.2}, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight, 10)
    
    -- Draw title
    local titleFont = love.graphics.newFont(18)
    love.graphics.setFont(titleFont)
    Utils.setColor({1, 0.8, 0.2})
    love.graphics.printf("UPGRADES", panelX, panelY + 20, panelWidth, "center")
    
    -- Draw currency
    local mediumFont = love.graphics.newFont(14)
    love.graphics.setFont(mediumFont)
    Utils.setColor({1, 1, 0.5})
    love.graphics.printf("Points: " .. UpgradeSystem.currency, panelX, panelY + 45, panelWidth, "center")
    
    -- Draw upgrades in a scrollable grid
    local upgradeList = {
        "jump_power", "jump_control", "dash_power", "dash_cooldown",
        "ring_magnet", "ring_value", "combo_timer", "combo_multiplier",
        "shield_duration", "exploration_bonus", "warp_drive"
    }
    
    local startY = panelY + 80
    local columnWidth = (panelWidth - 60) / 2
    local rowHeight = 60  -- Reduced height for better fit
    local maxRows = math.floor((panelHeight - 120) / (rowHeight + 5)) -- Leave space for controls
    local itemsPerPage = maxRows * 2
    
    -- Calculate scroll position
    local currentPage = math.floor((UISystem.upgradeSelection - 1) / itemsPerPage)
    local startIndex = currentPage * itemsPerPage + 1
    
    for i = startIndex, math.min(startIndex + itemsPerPage - 1, #upgradeList) do
        local upgradeId = upgradeList[i]
        local upgrade = UpgradeSystem.upgrades[upgradeId]
        if upgrade then
            -- Calculate position (two columns)
            local localIndex = i - startIndex + 1
            local col = (localIndex - 1) % 2
            local row = math.floor((localIndex - 1) / 2)
            local x = panelX + 20 + col * (columnWidth + 20)
            local y = startY + row * (rowHeight + 5)
            
            -- Highlight selected
            if i == UISystem.upgradeSelection then
                Utils.setColor({1, 1, 0.5}, 0.3)
                love.graphics.rectangle("fill", x - 5, y - 5, columnWidth - 10, rowHeight - 10, 5)
            end
            
            -- Draw upgrade icon and name
            Utils.setColor(Utils.colors.white)
            local smallFont = love.graphics.newFont(11)
            love.graphics.setFont(smallFont)
            love.graphics.print(upgrade.icon .. " " .. upgrade.name, x, y)
            
            -- Draw level and cost on same line
            local tinyFont = love.graphics.newFont(9)
            love.graphics.setFont(tinyFont)
            local levelText = "Lv." .. upgrade.currentLevel .. "/" .. upgrade.maxLevel
            Utils.setColor({0.8, 0.8, 0.8})
            love.graphics.print(levelText, x, y + 16)
            
            -- Draw cost
            local cost = UpgradeSystem.getUpgradeCost(upgradeId)
            if cost > 0 then
                if UpgradeSystem.canAfford(upgradeId) then
                    Utils.setColor({0.2, 1, 0.2})
                    love.graphics.print(cost .. " pts", x + columnWidth - 70, y + 16)
                else
                    Utils.setColor({1, 0.2, 0.2})
                    love.graphics.print(cost .. " pts", x + columnWidth - 70, y + 16)
                end
            else
                Utils.setColor({1, 0.8, 0.2})
                love.graphics.print("MAXED", x + columnWidth - 70, y + 16)
            end
            
            -- Draw description (truncated if too long)
            Utils.setColor({0.6, 0.6, 0.6})
            love.graphics.setFont(tinyFont)
            local desc = upgrade.description
            if #desc > 35 then
                desc = desc:sub(1, 32) .. "..."
            end
            love.graphics.printf(desc, x, y + 30, columnWidth - 20, "left")
            
            -- Draw progress bar
            local barY = y + 45
            local barWidth = columnWidth - 40
            local barHeight = 3
            
            -- Background
            Utils.setColor({0.2, 0.2, 0.2}, 0.8)
            love.graphics.rectangle("fill", x, barY, barWidth, barHeight, 2)
            
            -- Fill
            if upgrade.maxLevel > 0 then
                local fillWidth = (upgrade.currentLevel / upgrade.maxLevel) * barWidth
                Utils.setColor({0.2, 0.8, 0.2}, 0.8)
                love.graphics.rectangle("fill", x, barY, fillWidth, barHeight, 2)
            end
        end
    end
    
    -- Draw page indicator if needed
    if #upgradeList > itemsPerPage then
        local totalPages = math.ceil(#upgradeList / itemsPerPage)
        local currentPageNum = currentPage + 1
        Utils.setColor({0.8, 0.8, 0.8})
        love.graphics.printf(string.format("Page %d/%d", currentPageNum, totalPages), 
            panelX, panelY + panelHeight - 60, panelWidth, "center")
    end
    
    -- Draw controls
    local smallFont = love.graphics.newFont(10)
    love.graphics.setFont(smallFont)
    Utils.setColor({0.6, 0.6, 0.6})
    love.graphics.printf("↑/↓: Navigate    Enter: Purchase    ESC: Close", 
        panelX, panelY + panelHeight - 25, panelWidth, "center")
    
    -- Draw upgrade effect preview for selected item
    local selectedUpgradeId = upgradeList[UISystem.upgradeSelection]
    if selectedUpgradeId then
        local upgrade = UpgradeSystem.upgrades[selectedUpgradeId]
        if upgrade and upgrade.currentLevel < upgrade.maxLevel then
            local nextEffect = upgrade.effect(upgrade.currentLevel + 1)
            local currentEffect = upgrade.currentLevel > 0 and upgrade.effect(upgrade.currentLevel) or 1
            
            local effectText = ""
            if type(nextEffect) == "number" then
                if nextEffect > 1 then
                    effectText = string.format("Next: +%.0f%%", (nextEffect - 1) * 100)
                elseif nextEffect < 1 then
                    effectText = string.format("Next: -%.0f%%", (1 - nextEffect) * 100)
                else
                    effectText = "Next: Unlock"
                end
            else
                effectText = "Next: Special effect"
            end
            
            Utils.setColor({0.8, 0.8, 0.8})
            love.graphics.printf(effectText, panelX, panelY + panelHeight - 40, panelWidth, "center")
        end
    end
end

function UISystem.drawAchievementUI()
    local panel = UISystem.elements.menuPanel
    
    -- Draw background
    Utils.setColor(Utils.colors.background)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height)
    
    Utils.setColor(Utils.colors.text)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height)
    
    -- Draw title
    love.graphics.setFont(UISystem.fonts.extraBold)
    love.graphics.print("ACHIEVEMENTS", panel.x + 20, panel.y + 20)
    
    -- Draw achievements
    local y = panel.y + 60
    for id, achievement in pairs(UISystem.progressionSystem.achievements) do
        if achievement.unlocked then
            Utils.setColor(Utils.colors.green)
        else
            Utils.setColor(Utils.colors.gray)
        end
        
        love.graphics.setFont(UISystem.fonts.bold)
        love.graphics.print(achievement.name, panel.x + 20, y)
        
        love.graphics.setFont(UISystem.fonts.regular)
        love.graphics.print(achievement.description, panel.x + 20, y + 20)
        
        if achievement.unlocked then
            love.graphics.print("Score: " .. achievement.score, panel.x + 20, y + 40)
        end
        
        y = y + 70
    end
end

function UISystem.drawBlockchainUI()
    local panel = UISystem.elements.menuPanel
    
    -- Draw background
    Utils.setColor(Utils.colors.background)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height)
    
    Utils.setColor(Utils.colors.text)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height)
    
    -- Draw title
    love.graphics.setFont(UISystem.fonts.extraBold)
    love.graphics.print("BLOCKCHAIN", panel.x + 20, panel.y + 20)
    
    if UISystem.blockchainIntegration then
        local status = UISystem.blockchainIntegration.getStatus()
        
        love.graphics.setFont(UISystem.fonts.bold)
        love.graphics.print("Status: " .. (status.enabled and "ENABLED" or "DISABLED"), panel.x + 20, panel.y + 60)
        love.graphics.print("Network: " .. status.network, panel.x + 20, panel.y + 80)
        love.graphics.print("Queued Events: " .. status.queuedEvents, panel.x + 20, panel.y + 100)
        
        -- Draw blockchain data
        local data = UISystem.progressionSystem.data.blockchain
        love.graphics.print("Tokens Earned: " .. data.tokensEarned, panel.x + 20, panel.y + 140)
        love.graphics.print("NFTs Unlocked: " .. UISystem.countTable(data.nftsUnlocked), panel.x + 20, panel.y + 160)
        
        if data.walletAddress then
            love.graphics.setFont(UISystem.fonts.regular)
            love.graphics.print("Wallet: " .. string.sub(data.walletAddress, 1, 10) .. "...", panel.x + 20, panel.y + 180)
        end
    else
        love.graphics.setFont(UISystem.fonts.regular)
        love.graphics.print("Blockchain integration not available", panel.x + 20, panel.y + 60)
    end
end

function UISystem.countTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Input handling
function UISystem.keypressed(key)
    -- Handle debug system keys first
    if UIDebug.keypressed(key) then
        return true
    end
    
    if UISystem.currentScreen == "menu" then
        if key == "up" then
            UISystem.menuSelection = math.max(1, UISystem.menuSelection - 1)
        elseif key == "down" then
            UISystem.menuSelection = math.min(10, UISystem.menuSelection + 1)
        elseif key == "return" or key == "space" then
            UISystem.handleMenuSelection()
        elseif key == "escape" then
            UISystem.currentScreen = "game"
        end
    elseif UISystem.currentScreen == "upgrades" then
        if key == "up" then
            UISystem.upgradeSelection = math.max(1, UISystem.upgradeSelection - 2)
        elseif key == "down" then
            UISystem.upgradeSelection = math.min(10, UISystem.upgradeSelection + 2)
        elseif key == "left" then
            if UISystem.upgradeSelection % 2 == 0 then
                UISystem.upgradeSelection = UISystem.upgradeSelection - 1
            end
        elseif key == "right" then
            if UISystem.upgradeSelection % 2 == 1 and UISystem.upgradeSelection < 10 then
                UISystem.upgradeSelection = UISystem.upgradeSelection + 1
            end
        elseif key == "return" or key == "space" then
            UISystem.purchaseUpgrade()
        elseif key == "escape" then
            UISystem.currentScreen = "game"
        end
    elseif UISystem.currentScreen == "settings" then
        if key == "tab" then
            UISystem.handleSettingsCategorySwitch()
        elseif key == "up" then
            UISystem.settingsSelection = math.max(1, UISystem.settingsSelection - 1)
        elseif key == "down" then
            UISystem.settingsSelection = math.min(UISystem.getMaxSettingsSelection(), UISystem.settingsSelection + 1)
        elseif key == "return" or key == "space" then
            UISystem.handleSettingsToggle()
        elseif key == "escape" then
            UISystem.saveSettingsAndExit()
        end
    elseif UISystem.currentScreen == "stats" then
        if key == "up" then
            UISystem.statsSelection = math.max(1, UISystem.statsSelection - 1)
        elseif key == "down" then
            UISystem.statsSelection = math.min(3, UISystem.statsSelection + 1)
        elseif key == "escape" then
            UISystem.currentScreen = "menu"
        end
    elseif UISystem.currentScreen == "achievements" or UISystem.currentScreen == "blockchain" or 
           UISystem.currentScreen == "prestige" or UISystem.currentScreen == "mastery" or
           UISystem.currentScreen == "daily_streak" then
        if key == "escape" then
            UISystem.currentScreen = "menu"
        end
    end
end

function UISystem.handleSettingsCategorySwitch()
    local categories = {"addiction", "visual", "audio", "accessibility"}
    local currentIndex = 1
    
    for i, category in ipairs(categories) do
        if UISystem.settingsCategory == category then
            currentIndex = i
            break
        end
    end
    
    currentIndex = currentIndex + 1
    if currentIndex > #categories then
        currentIndex = 1
    end
    
    UISystem.settingsCategory = categories[currentIndex]
    UISystem.settingsSelection = 1 -- Reset selection when switching categories
end

function UISystem.getMaxSettingsSelection()
    if UISystem.settingsCategory == "addiction" then
        return 8
    elseif UISystem.settingsCategory == "visual" then
        return 4
    elseif UISystem.settingsCategory == "audio" then
        return 2
    elseif UISystem.settingsCategory == "accessibility" then
        return 3
    end
    return 1
end

function UISystem.handleSettingsToggle()
    local Config = Utils.require("src.utils.config")
    if not Config or not Config.addiction then return end
    
    local settingsMap = UISystem.getCurrentSettingsMap()
    local setting = settingsMap[UISystem.settingsSelection]
    if not setting then return end
    
    local currentValue = Config.addiction[setting.key]
    
    if setting.type == "boolean" then
        Config.addiction[setting.key] = not currentValue
    elseif setting.options then
        local currentIndex = 1
        for i, option in ipairs(setting.options) do
            if tostring(currentValue) == option then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex + 1
        if currentIndex > #setting.options then
            currentIndex = 1
        end
        Config.addiction[setting.key] = setting.options[currentIndex]
        
        -- Convert numeric strings back to numbers for certain settings
        if setting.key == "auto_pause_inactive" then
            Config.addiction[setting.key] = tonumber(Config.addiction[setting.key])
        end
    end
end

function UISystem.getCurrentSettingsMap()
    if UISystem.settingsCategory == "addiction" then
        return {
            {key = "event_frequency", options = {"high", "normal", "low", "off"}},
            {key = "streak_pressure_mode", options = {"competitive", "casual", "zen"}},
            {key = "notification_frequency", options = {"all", "important", "minimal"}},
            {key = "progress_visibility", options = {"always", "contextual", "hidden"}},
            {key = "xp_gain_animations", type = "boolean"},
            {key = "level_up_celebrations", type = "boolean"},
            {key = "mystery_box_buildup", type = "boolean"},
            {key = "milestone_notifications", type = "boolean"}
        }
    elseif UISystem.settingsCategory == "visual" then
        return {
            {key = "visual_effects_intensity", options = {"full", "reduced", "minimal"}},
            {key = "streak_screen_effects", type = "boolean"},
            {key = "motion_sensitivity", type = "boolean"},
            {key = "colorblind_support", type = "boolean"}
        }
    elseif UISystem.settingsCategory == "audio" then
        return {
            {key = "audio_feedback_level", options = {"full", "reduced", "essential"}},
            {key = "hearing_impaired", type = "boolean"}
        }
    elseif UISystem.settingsCategory == "accessibility" then
        return {
            {key = "session_break_reminders", type = "boolean"},
            {key = "session_limit_warnings", type = "boolean"},
            {key = "auto_pause_inactive", options = {"0", "300", "600", "900", "1800"}}
        }
    end
    return {}
end

function UISystem.saveSettingsAndExit()
    local Config = Utils.require("src.utils.config")
    if Config and Config.save then
        Config.save()
    end
    UISystem.currentScreen = "menu"
end

function UISystem.handleMenuSelection()
    if UISystem.menuSelection == 1 then -- Continue
        UISystem.currentScreen = "game"
    elseif UISystem.menuSelection == 2 then -- Upgrades
        UISystem.currentScreen = "upgrades"
    elseif UISystem.menuSelection == 3 then -- Achievements
        UISystem.currentScreen = "achievements"
    elseif UISystem.menuSelection == 4 then -- Prestige
        UISystem.currentScreen = "prestige"
    elseif UISystem.menuSelection == 5 then -- Mastery
        UISystem.currentScreen = "mastery"
    elseif UISystem.menuSelection == 6 then -- Daily Streak
        UISystem.currentScreen = "daily_streak"
    elseif UISystem.menuSelection == 7 then -- Statistics
        UISystem.currentScreen = "stats"
    elseif UISystem.menuSelection == 8 then -- Settings
        UISystem.currentScreen = "settings"
    elseif UISystem.menuSelection == 9 then -- Blockchain
        UISystem.currentScreen = "blockchain"
    elseif UISystem.menuSelection == 10 then -- Back to Game
        UISystem.currentScreen = "game"
    end
end

function UISystem.purchaseUpgrade()
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    
    -- Handle case where upgrade system is not available (e.g., in test environment)
    if not UpgradeSystem or not UpgradeSystem.purchase then
        return false
    end
    
    local upgradeList = {
        "jump_power", "jump_control", "dash_power", "dash_cooldown",
        "ring_magnet", "ring_value", "combo_timer", "combo_multiplier",
        "shield_duration", "exploration_bonus", "warp_drive"
    }
    
    local upgradeId = upgradeList[UISystem.upgradeSelection]
    if upgradeId and UpgradeSystem.purchase(upgradeId) then
        -- Success - upgrade purchased
        return true
    else
        -- Cannot afford or max level
        return false
    end
end

function UISystem.mousepressed(x, y, button)
    if UISystem.currentScreen == "game" then
        -- Check upgrade button
        local upgradeBtn = UISystem.elements.upgradeButton
        if x >= upgradeBtn.x and x <= upgradeBtn.x + upgradeBtn.width and
           y >= upgradeBtn.y and y <= upgradeBtn.y + upgradeBtn.height then
            UISystem.currentScreen = "upgrades"
        end
        
        -- Check blockchain button
        local blockchainBtn = UISystem.elements.blockchainButton
        if x >= blockchainBtn.x and x <= blockchainBtn.x + blockchainBtn.width and
           y >= blockchainBtn.y and y <= blockchainBtn.y + blockchainBtn.height then
            UISystem.currentScreen = "blockchain"
        end
    end
end

-- Key input handler
function UISystem.handleKeyPress(key)
    -- Handle debug system keys first (F12, F11, F10, F9, F8, etc.)
    if UIDebug.keypressed(key) then
        return true
    end
    
    if UISystem.currentScreen == "game" then
        if key == "u" then
            UISystem.currentScreen = "upgrades"
            return true
        elseif key == "s" then
            UISystem.currentScreen = "settings"
            return true
        elseif key == "a" then
            UISystem.currentScreen = "accessibility"
            return true
        end
    else
        if key == "escape" then
            UISystem.currentScreen = "game"
            return true
        elseif UISystem.currentScreen == "upgrades" then
            -- Handle upgrade navigation
            local UpgradeSystem = Utils.require("src.systems.upgrade_system")
            local upgradeList = {
                "jump_power", "jump_control", "dash_power", "dash_cooldown",
                "ring_magnet", "ring_value", "combo_timer", "combo_multiplier",
                "shield_duration", "exploration_bonus", "warp_drive"
            }
            
            if key == "up" then
                UISystem.upgradeSelection = math.max(1, UISystem.upgradeSelection - 1)
                return true
            elseif key == "down" then
                UISystem.upgradeSelection = math.min(#upgradeList, UISystem.upgradeSelection + 1)
                return true
            elseif key == "return" or key == "space" then
                -- Purchase selected upgrade
                local selectedUpgradeId = upgradeList[UISystem.upgradeSelection]
                if selectedUpgradeId then
                    UpgradeSystem.purchase(selectedUpgradeId)
                end
                return true
            end
        end
    end
    return false
end

-- Event notification methods
function UISystem.showEventNotification(message, color)
    UISystem.eventNotification.active = true
    UISystem.eventNotification.message = message
    UISystem.eventNotification.color = color or {1, 1, 1, 1}
    UISystem.eventNotification.timer = 0
end

function UISystem.hideEventNotification()
    UISystem.eventNotification.active = false
end

function UISystem.updateEventNotification(dt)
    if not UISystem.eventNotification.active then return end
    
    UISystem.eventNotification.timer = UISystem.eventNotification.timer + dt
    
    if UISystem.eventNotification.timer >= UISystem.eventNotification.duration then
        UISystem.eventNotification.active = false
    end
end

function UISystem.drawEventNotification()
    if not UISystem.eventNotification.active then return end
    
    local notif = UISystem.eventNotification
    local alpha = 1
    
    -- Fade in/out
    if notif.timer < notif.fadeIn then
        alpha = notif.timer / notif.fadeIn
    elseif notif.timer > notif.duration - notif.fadeOut then
        alpha = (notif.duration - notif.timer) / notif.fadeOut
    end
    
    -- Draw notification
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    love.graphics.push()
    
    -- Background
    love.graphics.setColor(0, 0, 0, 0.7 * alpha)
    love.graphics.rectangle("fill", screenWidth/2 - 200, screenHeight/2 - 50, 400, 100, 10)
    
    -- Text
    love.graphics.setColor(notif.color[1], notif.color[2], notif.color[3], alpha)
    love.graphics.setFont(UISystem.fonts.extraBold or love.graphics.getFont())
    local textWidth = love.graphics.getFont():getWidth(notif.message)
    love.graphics.print(notif.message, screenWidth/2 - textWidth/2, screenHeight/2 - 10)
    
    love.graphics.pop()
end

return UISystem 