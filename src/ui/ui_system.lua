-- UI System for Orbit Jump
-- Handles progression display, upgrade menus, and blockchain status

local Utils = require("src.utils.utils")
local UISystem = {}

-- UI state
UISystem.currentScreen = "game" -- game, menu, upgrades, achievements, blockchain
UISystem.showProgression = false -- Disabled to prevent UI overlap
UISystem.showBlockchainStatus = false
UISystem.menuSelection = 1
UISystem.upgradeSelection = 1

-- UI elements
UISystem.elements = {
    progressionBar = { x = 10, y = 10, width = 200, height = 20 },
    upgradeButton = { x = 10, y = 40, width = 100, height = 30 },
    blockchainButton = { x = 120, y = 40, width = 100, height = 30 },
    menuPanel = { x = 50, y = 100, width = 300, height = 400 }
}

-- Responsive UI scaling
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
    
    -- Update UI element positions and sizes based on screen size
    if isMobile then
        -- Mobile layout - stack elements vertically and make them larger
        UISystem.elements.progressionBar = { 
            x = 10, y = 10, 
            width = screenWidth - 20, height = 30 
        }
        UISystem.elements.upgradeButton = { 
            x = 10, y = 50, 
            width = (screenWidth - 30) / 2, height = 50 
        }
        UISystem.elements.blockchainButton = { 
            x = screenWidth / 2 + 5, y = 50, 
            width = (screenWidth - 30) / 2, height = 50 
        }
        UISystem.elements.menuPanel = { 
            x = 20, y = 120, 
            width = screenWidth - 40, height = screenHeight - 140 
        }
    else
        -- Desktop layout - original positioning
        UISystem.elements.progressionBar = { x = 10, y = 10, width = 200, height = 20 }
        UISystem.elements.upgradeButton = { x = 10, y = 40, width = 100, height = 30 }
        UISystem.elements.blockchainButton = { x = 120, y = 40, width = 100, height = 30 }
        UISystem.elements.menuPanel = { x = 50, y = 30, width = 700, height = 550 }
    end
    
    -- Store scale for use in drawing
    UISystem.uiScale = uiScale
    UISystem.isMobile = isMobile
end

function UISystem.init(fonts)
    UISystem.fonts = fonts
    UISystem.updateResponsiveLayout()
end

function UISystem.update(dt, progressionSystem, blockchainIntegration)
    UISystem.progressionSystem = progressionSystem
    UISystem.blockchainIntegration = blockchainIntegration
    
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
        elseif UISystem.currentScreen == "blockchain" then
            UISystem.drawBlockchainUI()
        end
    end
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
    
    -- Draw controls hint
    Utils.setColor({0.7, 0.7, 0.7}, 0.8)
    love.graphics.print("Press U for upgrades | TAB for map", screenWidth - 250, 10)
    
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
    local options = {"Continue", "Upgrades", "Achievements", "Blockchain", "Back to Game"}
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

function UISystem.drawUpgradeUI()
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    local panel = UISystem.elements.menuPanel
    
    -- Center panel on screen
    local screenWidth, screenHeight = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    panel.x = (screenWidth - panel.width) / 2
    panel.y = (screenHeight - panel.height) / 2
    
    -- Draw background with transparency
    Utils.setColor({0, 0, 0}, 0.9)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height, 10)
    
    Utils.setColor({1, 0.8, 0.2}, 0.8)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height, 10)
    
    -- Draw title
    local titleFont = love.graphics.newFont(18)
    love.graphics.setFont(titleFont)
    Utils.setColor({1, 0.8, 0.2})
    love.graphics.printf("UPGRADES", panel.x, panel.y + 20, panel.width, "center")
    
    -- Draw currency
    local mediumFont = love.graphics.newFont(14)
    love.graphics.setFont(mediumFont)
    Utils.setColor({1, 1, 0.5})
    love.graphics.printf("Points: " .. UpgradeSystem.currency, panel.x, panel.y + 45, panel.width, "center")
    
    -- Draw upgrades in two columns
    local upgradeList = {
        "jump_power", "jump_control", "dash_power", "dash_cooldown",
        "ring_magnet", "ring_value", "combo_timer", "combo_multiplier",
        "shield_duration", "exploration_bonus", "warp_drive"
    }
    
    local startY = panel.y + 80
    local columnWidth = (panel.width - 60) / 2
    local rowHeight = 70  -- Adjusted for smaller fonts
    local index = 1
    
    for i, upgradeId in ipairs(upgradeList) do
        local upgrade = UpgradeSystem.upgrades[upgradeId]
        if upgrade then
            -- Calculate position (two columns)
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local x = panel.x + 20 + col * (columnWidth + 20)
            local y = startY + row * (rowHeight + 5)
            
            -- Highlight selected
            if index == UISystem.upgradeSelection then
                Utils.setColor({1, 1, 0.5}, 0.3)
                love.graphics.rectangle("fill", x - 5, y - 5, columnWidth - 10, rowHeight - 10, 5)
            end
            
            -- Draw upgrade icon and name (smaller font)
            Utils.setColor(Utils.colors.white)
            local smallFont = love.graphics.newFont(12)
            love.graphics.setFont(smallFont)
            love.graphics.print(upgrade.icon .. " " .. upgrade.name, x, y)
            
            -- Draw level and cost on same line
            local tinyFont = love.graphics.newFont(10)
            love.graphics.setFont(tinyFont)
            local levelText = "Lv." .. upgrade.currentLevel .. "/" .. upgrade.maxLevel
            Utils.setColor({0.8, 0.8, 0.8})
            love.graphics.print(levelText, x, y + 18)
            
            -- Draw cost
            local cost = UpgradeSystem.getUpgradeCost(upgradeId)
            if cost > 0 then
                if UpgradeSystem.canAfford(upgradeId) then
                    Utils.setColor({0.2, 1, 0.2})
                    love.graphics.print(cost .. " pts", x + columnWidth - 80, y + 18)
                else
                    Utils.setColor({1, 0.2, 0.2})
                    love.graphics.print(cost .. " pts", x + columnWidth - 80, y + 18)
                end
            else
                Utils.setColor({1, 0.8, 0.2})
                love.graphics.print("MAXED", x + columnWidth - 80, y + 18)
            end
            
            -- Draw description (even smaller font)
            Utils.setColor({0.6, 0.6, 0.6})
            love.graphics.setFont(tinyFont)
            love.graphics.printf(upgrade.description, x, y + 35, columnWidth - 20, "left")
            
            -- Draw progress bar
            local barY = y + 55
            local barWidth = columnWidth - 40
            local barHeight = 4
            
            -- Background
            Utils.setColor({0.2, 0.2, 0.2}, 0.8)
            love.graphics.rectangle("fill", x, barY, barWidth, barHeight, 2)
            
            -- Fill
            if upgrade.maxLevel > 0 then
                local fillWidth = (upgrade.currentLevel / upgrade.maxLevel) * barWidth
                Utils.setColor({0.2, 0.8, 0.2}, 0.8)
                love.graphics.rectangle("fill", x, barY, fillWidth, barHeight, 2)
            end
            
            index = index + 1
        end
    end
    
    -- Draw controls
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)
    Utils.setColor({0.6, 0.6, 0.6})
    love.graphics.printf("↑/↓/←/→: Navigate    Enter: Purchase    ESC: Close", 
        panel.x, panel.y + panel.height - 25, panel.width, "center")
    
    -- Draw upgrade effect preview for selected item
    local selectedUpgradeId = upgradeList[UISystem.upgradeSelection]
    if selectedUpgradeId then
        local upgrade = UpgradeSystem.upgrades[selectedUpgradeId]
        if upgrade and upgrade.currentLevel < upgrade.maxLevel then
            local nextEffect = upgrade.effect(upgrade.currentLevel + 1)
            local currentEffect = upgrade.effect(upgrade.currentLevel)
            
            Utils.setColor({0.8, 0.8, 0.8})
            love.graphics.printf("Next Level: " .. string.format("%.0f%%", (nextEffect - 1) * 100) .. " effect", 
                panel.x, panel.y + panel.height - 45, panel.width, "center")
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
    if UISystem.currentScreen == "menu" then
        if key == "up" then
            UISystem.menuSelection = math.max(1, UISystem.menuSelection - 1)
        elseif key == "down" then
            UISystem.menuSelection = math.min(5, UISystem.menuSelection + 1)
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
    elseif UISystem.currentScreen == "achievements" or UISystem.currentScreen == "blockchain" then
        if key == "escape" then
            UISystem.currentScreen = "menu"
        end
    end
end

function UISystem.handleMenuSelection()
    if UISystem.menuSelection == 1 then -- Continue
        UISystem.currentScreen = "game"
    elseif UISystem.menuSelection == 2 then -- Upgrades
        UISystem.currentScreen = "upgrades"
    elseif UISystem.menuSelection == 3 then -- Achievements
        UISystem.currentScreen = "achievements"
    elseif UISystem.menuSelection == 4 then -- Blockchain
        UISystem.currentScreen = "blockchain"
    elseif UISystem.menuSelection == 5 then -- Back to Game
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
    if UISystem.currentScreen == "game" then
        if key == "u" then
            UISystem.currentScreen = "upgrades"
            return true
        end
    else
        if key == "escape" then
            UISystem.currentScreen = "game"
            return true
        elseif UISystem.currentScreen == "upgrades" then
            -- Handle upgrade navigation
            local UpgradeSystem = Utils.require("src.systems.upgrade_system")
            if key == "up" then
                UISystem.upgradeSelection = math.max(1, UISystem.upgradeSelection - 1)
                return true
            elseif key == "down" then
                local maxUpgrades = 6 -- We have 6 upgrade types
                UISystem.upgradeSelection = math.min(maxUpgrades, UISystem.upgradeSelection + 1)
                return true
            elseif key == "return" or key == "space" then
                -- Purchase selected upgrade
                local i = 1
                for id, _ in pairs(UpgradeSystem.upgrades) do
                    if i == UISystem.upgradeSelection then
                        UpgradeSystem.purchase(id)
                        break
                    end
                    i = i + 1
                end
                return true
            end
        end
    end
    return false
end

return UISystem 