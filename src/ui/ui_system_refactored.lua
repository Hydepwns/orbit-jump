-- Refactored UI System for Orbit Jump
-- Coordinates all UI screens and provides a clean interface

local Utils = require("src.utils.utils")
local GameUI = require("src.ui.screens.game_ui")
local MenuUI = require("src.ui.screens.menu_ui")
local Notification = require("src.ui.components.notification")
local UIAnimationSystem = require("src.ui.ui_animation_system")

local UISystem = {}

-- UI state
UISystem.currentScreen = "game" -- game, menu, upgrades, achievements, blockchain, settings, accessibility, stats
UISystem.screens = {}
UISystem.notificationManager = nil
UISystem.fonts = nil

-- Initialize the UI system
function UISystem.init(fonts)
    UISystem.fonts = fonts or _G.GameFonts
    
    -- Initialize UI Animation System
    UIAnimationSystem.init()
    
    -- Initialize notification manager
    UISystem.notificationManager = Notification.createManager()
    
    -- Initialize screen modules
    UISystem.screens.game = GameUI
    UISystem.screens.menu = MenuUI
    
    -- Initialize each screen
    for name, screen in pairs(UISystem.screens) do
        if screen.init then
            local success = screen.init(UISystem.fonts)
            if not success then
                Utils.Logger.error("Failed to initialize UI screen: %s", name)
            end
        end
    end
    
    -- Set up screen callbacks
    UISystem:setupScreenCallbacks()
    
    Utils.Logger.info("UI System initialized successfully")
    return true
end

-- Set up callbacks between screens
function UISystem:setupScreenCallbacks()
    -- Game UI callbacks
    if UISystem.screens.game then
        UISystem.screens.game.setOnUpgradeRequested(function()
            UISystem:switchToScreen("upgrades")
        end)
        
        UISystem.screens.game.setOnBlockchainRequested(function()
            UISystem:switchToScreen("blockchain")
        end)
    end
    
    -- Menu UI callbacks
    if UISystem.screens.menu then
        UISystem.screens.menu.setOnResumeRequested(function()
            UISystem:switchToScreen("game")
        end)
        
        UISystem.screens.menu.setOnExitRequested(function()
            UISystem:onExitRequested()
        end)
        
        UISystem.screens.menu.setOnSettingChanged(function(category, index)
            UISystem:onSettingChanged(category, index)
        end)
    end
end

-- Update the UI system
function UISystem.update(dt, progressionSystem, blockchainIntegration)
    -- Update UI Animation System
    UIAnimationSystem.update(dt)
    
    -- Update notification manager
    if UISystem.notificationManager then
        UISystem.notificationManager:update(dt)
    end
    
    -- Update current screen
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.update then
        currentScreen.update(dt, progressionSystem, blockchainIntegration)
    end
end

-- Draw the UI system
function UISystem.draw()
    -- Draw current screen
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.draw then
        currentScreen.draw()
    end
    
    -- Draw notifications
    if UISystem.notificationManager then
        UISystem.notificationManager:draw()
    end
    
    -- Draw UI animations
    UIAnimationSystem.draw()
end

-- Handle mouse input
function UISystem.mousepressed(x, y, button)
    -- Check if any screen handles the input
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.mousepressed then
        local handled = currentScreen.mousepressed(x, y, button)
        if handled then
            return true
        end
    end
    
    return false
end

-- Handle mouse movement
function UISystem.mousemoved(x, y)
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.mousemoved then
        currentScreen.mousemoved(x, y)
    end
end

-- Handle keyboard input
function UISystem.keypressed(key)
    -- Global keyboard shortcuts
    if key == "escape" then
        if UISystem.currentScreen == "game" then
            UISystem:switchToScreen("menu")
            return true
        elseif UISystem.currentScreen == "menu" then
            UISystem:switchToScreen("game")
            return true
        end
    end
    
    -- Pass to current screen
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.keypressed then
        local handled = currentScreen.keypressed(key)
        if handled then
            return true
        end
    end
    
    return false
end

-- Switch to a different screen
function UISystem:switchToScreen(screenName)
    if UISystem.screens[screenName] then
        UISystem.currentScreen = screenName
        Utils.Logger.info("Switched to UI screen: %s", screenName)
        return true
    else
        Utils.Logger.warn("Unknown UI screen: %s", screenName)
        return false
    end
end

-- Get current screen
function UISystem:getCurrentScreen()
    return UISystem.currentScreen
end

-- Show a notification
function UISystem:showNotification(message, type, duration)
    if UISystem.notificationManager then
        UISystem.notificationManager:add({
            message = message,
            type = type or Notification.types.INFO,
            duration = duration or 3.0
        })
    end
end

-- Show different types of notifications
function UISystem:showInfoNotification(message, duration)
    UISystem:showNotification(message, Notification.types.INFO, duration)
end

function UISystem:showSuccessNotification(message, duration)
    UISystem:showNotification(message, Notification.types.SUCCESS, duration)
end

function UISystem:showWarningNotification(message, duration)
    UISystem:showNotification(message, Notification.types.WARNING, duration)
end

function UISystem:showErrorNotification(message, duration)
    UISystem:showNotification(message, Notification.types.ERROR, duration)
end

function UISystem:showAchievementNotification(message, duration)
    UISystem:showNotification(message, Notification.types.ACHIEVEMENT, duration)
end

function UISystem:showLevelUpNotification(message, duration)
    UISystem:showNotification(message, Notification.types.LEVEL_UP, duration)
end

-- Update game-specific UI elements
function UISystem:updateGameUI(progressionSystem, blockchainIntegration)
    if UISystem.screens.game then
        -- Update progression data
        if progressionSystem then
            local currentXP = progressionSystem.getCurrentXP()
            local maxXP = progressionSystem.getXPForNextLevel()
            local level = progressionSystem.getCurrentLevel()
            UISystem.screens.game.updateProgression(currentXP, maxXP, level)
        end
        
        -- Update stuck warning
        if _G.GameState and _G.GameState.player then
            UISystem.screens.game.setShowStuckWarning(_G.GameState.player.stuckWarning or false)
        end
    end
end

-- Set callbacks for external systems
function UISystem:setOnExitRequested(callback)
    UISystem.onExitRequested = callback
end

function UISystem:setOnSettingChanged(callback)
    UISystem.onSettingChanged = callback
end

-- Event handlers
function UISystem:onExitRequested()
    if UISystem.onExitRequested then
        UISystem.onExitRequested()
    end
end

function UISystem:onSettingChanged(category, index)
    if UISystem.onSettingChanged then
        UISystem.onSettingChanged(category, index)
    end
end

-- Get UI bounds for collision detection
function UISystem:getBounds()
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.getBounds then
        return currentScreen.getBounds()
    end
    return nil
end

-- Check if UI is blocking input
function UISystem:isBlockingInput()
    return UISystem.currentScreen ~= "game"
end

-- Get current screen state
function UISystem:getScreenState()
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.state then
        return currentScreen.state
    end
    return {}
end

-- Set screen state
function UISystem:setScreenState(state)
    local currentScreen = UISystem.screens[UISystem.currentScreen]
    if currentScreen and currentScreen.state then
        for key, value in pairs(state) do
            currentScreen.state[key] = value
        end
    end
end

-- Cleanup
function UISystem:cleanup()
    -- Cleanup screens
    for name, screen in pairs(UISystem.screens) do
        if screen.cleanup then
            screen.cleanup()
        end
    end
    
    -- Clear references
    UISystem.screens = {}
    UISystem.notificationManager = nil
    UISystem.fonts = nil
    
    Utils.Logger.info("UI System cleaned up")
end

-- Error handling wrapper
function UISystem:safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        Utils.Logger.error("UI System error: %s", result)
        UISystem:showErrorNotification("UI Error: " .. tostring(result))
        return nil
    end
    return result
end

-- Validation helpers
function UISystem:validateScreen(screenName)
    if not UISystem.screens[screenName] then
        Utils.Logger.error("Invalid screen name: %s", screenName)
        return false
    end
    return true
end

function UISystem:validateFonts()
    if not UISystem.fonts then
        Utils.Logger.warn("UI System fonts not initialized")
        return false
    end
    return true
end

-- Debug information
function UISystem:getDebugInfo()
    return {
        currentScreen = UISystem.currentScreen,
        availableScreens = table.keys(UISystem.screens),
        notificationCount = UISystem.notificationManager and UISystem.notificationManager:getCount() or 0,
        animationCount = UIAnimationSystem.getCount(),
        fontsLoaded = UISystem.fonts ~= nil
    }
end

-- Helper function to get table keys
function table.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

return UISystem 