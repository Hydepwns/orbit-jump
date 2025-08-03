-- Game UI Screen for Orbit Jump
-- Handles in-game overlay, progression display, and learning indicators

local Utils = require("src.utils.utils")
local Button = require("src.ui.components.button")
local ProgressBar = require("src.ui.components.progress_bar")
local Layout = require("src.ui.components.layout")
local UIAnimationSystem = require("src.ui.ui_animation_system")

local GameUI = {}

-- Game UI state
GameUI.state = {
    showProgression = false,
    showLearningIndicator = true,
    showExplorationIndicator = true,
    showStuckWarning = false
}

-- UI elements
GameUI.elements = {
    progressionBar = nil,
    upgradeButton = nil,
    blockchainButton = nil,
    learningIndicator = nil,
    explorationIndicator = nil
}

-- Initialize game UI
function GameUI.init(fonts)
    GameUI.fonts = fonts or _G.GameFonts
    
    -- Create layout
    GameUI.layout = Layout.createResponsiveLayout()
    
    -- Create progression bar
    GameUI.elements.progressionBar = ProgressBar.createXPBar(10, 10, 200, 20)
    
    -- Create buttons
    GameUI.elements.upgradeButton = Button.new({
        text = "Upgrades",
        width = 100,
        height = 30,
        onClick = function() GameUI.onUpgradeClick() end
    })
    
    GameUI.elements.blockchainButton = Button.new({
        text = "Blockchain",
        width = 100,
        height = 30,
        onClick = function() GameUI.onBlockchainClick() end
    })
    
    -- Add elements to layout
    GameUI.layout:addElement(GameUI.elements.progressionBar, {
        x = 10,
        y = 10,
        width = "auto",
        height = 20,
        flex = 1
    })
    
    GameUI.layout:addElement(GameUI.elements.upgradeButton, {
        x = 10,
        y = 40,
        width = 100,
        height = 30
    })
    
    GameUI.layout:addElement(GameUI.elements.blockchainButton, {
        x = 120,
        y = 40,
        width = 100,
        height = 30
    })
    
    -- Update layout
    GameUI.layout:calculate()
    GameUI.layout:apply()
    
    return true
end

-- Update game UI
function GameUI.update(dt, progressionSystem, blockchainIntegration)
    -- Update layout
    GameUI.layout:update()
    
    -- Update progression bar
    if GameUI.elements.progressionBar and progressionSystem then
        local currentXP = progressionSystem.getCurrentXP()
        local maxXP = progressionSystem.getXPForNextLevel()
        GameUI.elements.progressionBar:setValues(currentXP, maxXP)
        GameUI.elements.progressionBar:update(dt)
    end
    
    -- Update learning indicator animation
    if GameUI.state.showLearningIndicator then
        GameUI.updateLearningIndicator(dt)
    end
    
    -- Update exploration indicator animation
    if GameUI.state.showExplorationIndicator then
        GameUI.updateExplorationIndicator(dt)
    end
end

-- Draw game UI
function GameUI.draw()
    -- Draw progression bar
    if GameUI.state.showProgression and GameUI.elements.progressionBar then
        GameUI.elements.progressionBar:draw()
    end
    
    -- Draw buttons
    if GameUI.elements.upgradeButton then
        GameUI.elements.upgradeButton:draw()
    end
    
    if GameUI.elements.blockchainButton then
        GameUI.elements.blockchainButton:draw()
    end
    
    -- Draw learning indicator
    if GameUI.state.showLearningIndicator then
        GameUI.drawLearningIndicator()
    end
    
    -- Draw exploration indicator
    if GameUI.state.showExplorationIndicator then
        GameUI.drawExplorationIndicator()
    end
    
    -- Draw stuck warning
    if GameUI.state.showStuckWarning then
        GameUI.drawStuckWarning()
    end
end

-- Draw learning indicator
function GameUI.drawLearningIndicator()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local indicatorSize = 40
    local indicatorX = screenWidth - indicatorSize - 20
    local indicatorY = screenHeight - indicatorSize - 20
    
    -- Constrain position to screen bounds
    indicatorX = math.max(20, math.min(screenWidth - indicatorSize - 20, indicatorX))
    indicatorY = math.max(20, math.min(screenHeight - indicatorSize - 20, indicatorY))
    
    -- Create pulse animation
    UIAnimationSystem.createPulseAnimation({
        x = indicatorX,
        y = indicatorY,
        width = indicatorSize,
        height = indicatorSize,
        color = {0.3, 0.7, 1.0, 0.8},
        pulseSpeed = 2.0,
        pulseAmplitude = 0.2
    })
    
    -- Draw brain icon
    Utils.setColor({1, 1, 1, 0.9})
    love.graphics.circle("fill", indicatorX + indicatorSize/2, indicatorY + indicatorSize/2, indicatorSize/3)
    
    -- Draw "L" text
    Utils.setColor({0.2, 0.2, 0.3, 1})
    local font = GameUI.fonts and GameUI.fonts.small or love.graphics.getFont()
    love.graphics.setFont(font)
    local text = "L"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, 
        indicatorX + (indicatorSize - textWidth) / 2,
        indicatorY + (indicatorSize - textHeight) / 2
    )
end

-- Draw exploration indicator
function GameUI.drawExplorationIndicator()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local indicatorSize = 30
    local indicatorX = screenWidth - indicatorSize - 10
    local indicatorY = 10
    
    -- Constrain position to screen bounds
    indicatorX = math.max(10, math.min(screenWidth - indicatorSize - 10, indicatorX))
    indicatorY = math.max(10, math.min(screenHeight - indicatorSize - 10, indicatorY))
    
    -- Create floating animation
    UIAnimationSystem.createFloatingUI({
        x = indicatorX,
        y = indicatorY,
        width = indicatorSize,
        height = indicatorSize,
        color = {0.8, 0.4, 0.8, 0.7},
        floatSpeed = 1.5,
        floatAmplitude = 5
    })
    
    -- Draw exploration icon
    Utils.setColor({1, 1, 1, 0.8})
    love.graphics.circle("fill", indicatorX + indicatorSize/2, indicatorY + indicatorSize/2, indicatorSize/3)
    
    -- Draw "E" text
    Utils.setColor({0.2, 0.2, 0.3, 1})
    local font = GameUI.fonts and GameUI.fonts.small or love.graphics.getFont()
    love.graphics.setFont(font)
    local text = "E"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, 
        indicatorX + (indicatorSize - textWidth) / 2,
        indicatorY + (indicatorSize - textHeight) / 2
    )
end

-- Draw stuck warning
function GameUI.drawStuckWarning()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local warningText = "SLOW MOVEMENT - PRESS R TO RESET"
    
    -- Create pulsing warning
    UIAnimationSystem.createPulseAnimation({
        x = screenWidth / 2 - 150,
        y = screenHeight / 2 - 20,
        width = 300,
        height = 40,
        color = {0.8, 0.2, 0.2, 0.8},
        pulseSpeed = 3.0,
        pulseAmplitude = 0.3
    })
    
    -- Draw warning text
    Utils.setColor({1, 1, 1, 1})
    local font = GameUI.fonts and GameUI.fonts.medium or love.graphics.getFont()
    love.graphics.setFont(font)
    local textWidth = font:getWidth(warningText)
    love.graphics.print(warningText, 
        screenWidth / 2 - textWidth / 2,
        screenHeight / 2 - font:getHeight() / 2
    )
end

-- Update learning indicator
function GameUI.updateLearningIndicator(dt)
    -- Animation is handled by UIAnimationSystem
end

-- Update exploration indicator
function GameUI.updateExplorationIndicator(dt)
    -- Animation is handled by UIAnimationSystem
end

-- Handle mouse input
function GameUI.mousepressed(x, y, button)
    if button == 1 then -- Left click
        -- Check button clicks
        if GameUI.elements.upgradeButton and GameUI.elements.upgradeButton:contains(x, y) then
            GameUI.onUpgradeClick()
            return true
        end
        
        if GameUI.elements.blockchainButton and GameUI.elements.blockchainButton:contains(x, y) then
            GameUI.onBlockchainClick()
            return true
        end
    end
    
    return false
end

-- Handle mouse movement for hover effects
function GameUI.mousemoved(x, y)
    local mousePressed = love.mouse.isDown(1)
    
    -- Update button hover states
    if GameUI.elements.upgradeButton then
        GameUI.elements.upgradeButton:update(x, y, mousePressed)
    end
    
    if GameUI.elements.blockchainButton then
        GameUI.elements.blockchainButton:update(x, y, mousePressed)
    end
end

-- Button click handlers
function GameUI.onUpgradeClick()
    -- This will be handled by the main UI system
    if GameUI.onUpgradeRequested then
        GameUI.onUpgradeRequested()
    end
end

function GameUI.onBlockchainClick()
    -- This will be handled by the main UI system
    if GameUI.onBlockchainRequested then
        GameUI.onBlockchainRequested()
    end
end

-- Set callbacks
function GameUI.setOnUpgradeRequested(callback)
    GameUI.onUpgradeRequested = callback
end

function GameUI.setOnBlockchainRequested(callback)
    GameUI.onBlockchainRequested = callback
end

-- Show/hide UI elements
function GameUI.setShowProgression(show)
    GameUI.state.showProgression = show
end

function GameUI.setShowLearningIndicator(show)
    GameUI.state.showLearningIndicator = show
end

function GameUI.setShowExplorationIndicator(show)
    GameUI.state.showExplorationIndicator = show
end

function GameUI.setShowStuckWarning(show)
    GameUI.state.showStuckWarning = show
end

-- Update progression data
function GameUI.updateProgression(currentXP, maxXP, level)
    if GameUI.elements.progressionBar then
        GameUI.elements.progressionBar:setValues(currentXP, maxXP)
        GameUI.elements.progressionBar:setLabel("Level " .. (level or 1))
    end
end

-- Get UI bounds for collision detection
function GameUI.getBounds()
    return GameUI.layout:getBounds()
end

-- Cleanup
function GameUI.cleanup()
    GameUI.elements = {}
    GameUI.layout = nil
    GameUI.fonts = nil
end

return GameUI 