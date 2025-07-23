-- Pause Menu System for Orbit Jump
-- Handles game pausing and pause menu UI

local Utils = require("src.utils.utils")
local PauseMenu = {}

-- Pause state
PauseMenu.isPaused = false
PauseMenu.selectedOption = 1
PauseMenu.fadeAlpha = 0

-- Menu options
PauseMenu.options = {
    {
        text = "Resume",
        action = function()
            PauseMenu.resume()
        end
    },
    {
        text = "Settings",
        action = function()
            -- Open settings menu
            local SettingsMenu = Utils.require("src.ui.settings_menu")
            SettingsMenu.toggle()
            PauseMenu.resume()
        end
    },
    {
        text = "Save Game",
        action = function()
            local SaveSystem = Utils.require("src.systems.save_system")
            SaveSystem.save()
            -- Stay paused to show save indicator
        end
    },
    {
        text = "Main Menu",
        action = function()
            -- Reset to main menu
            love.event.quit("restart")
        end
    },
    {
        text = "Quit",
        action = function()
            love.event.quit()
        end
    }
}

-- Initialize
function PauseMenu.init()
    PauseMenu.isPaused = false
    PauseMenu.selectedOption = 1
    PauseMenu.fadeAlpha = 0
end

-- Toggle pause
function PauseMenu.toggle()
    if PauseMenu.isPaused then
        PauseMenu.resume()
    else
        PauseMenu.pause()
    end
end

-- Pause game
function PauseMenu.pause()
    PauseMenu.isPaused = true
    PauseMenu.selectedOption = 1
    Utils.Logger.info("Game paused")
end

-- Resume game
function PauseMenu.resume()
    PauseMenu.isPaused = false
    Utils.Logger.info("Game resumed")
end

-- Update pause menu
function PauseMenu.update(dt)
    -- Update fade effect
    if PauseMenu.isPaused then
        PauseMenu.fadeAlpha = math.min(PauseMenu.fadeAlpha + dt * 5, 1)
    else
        PauseMenu.fadeAlpha = math.max(PauseMenu.fadeAlpha - dt * 5, 0)
    end
end

-- Handle input
function PauseMenu.keypressed(key)
    if not PauseMenu.isPaused then
        -- Check for pause key
        if key == "escape" or key == "p" then
            PauseMenu.pause()
            return true
        end
        return false
    end
    
    -- Handle menu navigation
    if key == "up" then
        PauseMenu.selectedOption = math.max(1, PauseMenu.selectedOption - 1)
    elseif key == "down" then
        PauseMenu.selectedOption = math.min(#PauseMenu.options, PauseMenu.selectedOption + 1)
    elseif key == "return" or key == "space" then
        -- Execute selected option
        local option = PauseMenu.options[PauseMenu.selectedOption]
        if option and option.action then
            option.action()
        end
    elseif key == "escape" then
        -- Resume on escape
        PauseMenu.resume()
    end
    
    return true -- Consume input when paused
end

-- Handle mouse input
function PauseMenu.mousepressed(x, y, button)
    if not PauseMenu.isPaused then return false end
    
    if button == 1 then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        local menuWidth = 400
        local menuHeight = 350
        local menuX = (screenWidth - menuWidth) / 2
        local menuY = (screenHeight - menuHeight) / 2
        
        local optionHeight = 50
        local startY = menuY + 80
        
        -- Check which option was clicked
        for i, option in ipairs(PauseMenu.options) do
            local optionY = startY + (i - 1) * optionHeight
            
            if x >= menuX and x <= menuX + menuWidth and
               y >= optionY and y <= optionY + optionHeight then
                PauseMenu.selectedOption = i
                option.action()
                return true
            end
        end
    end
    
    return true -- Consume input when paused
end

-- Draw pause menu
function PauseMenu.draw()
    if PauseMenu.fadeAlpha <= 0 then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw darkened overlay
    Utils.setColor({0, 0, 0}, 0.7 * PauseMenu.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Menu dimensions
    local menuWidth = 400
    local menuHeight = 350
    local menuX = (screenWidth - menuWidth) / 2
    local menuY = (screenHeight - menuHeight) / 2
    
    -- Draw menu background
    Utils.setColor({0.1, 0.1, 0.2}, 0.9 * PauseMenu.fadeAlpha)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight, 10)
    
    -- Draw menu border
    Utils.setColor({0.5, 0.8, 1}, PauseMenu.fadeAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight, 10)
    
    -- Draw title
    Utils.setColor({1, 1, 1}, PauseMenu.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf("PAUSED", menuX, menuY + 20, menuWidth, "center")
    
    -- Draw options
    local optionHeight = 50
    local startY = menuY + 80
    
    love.graphics.setFont(love.graphics.newFont(20))
    
    for i, option in ipairs(PauseMenu.options) do
        local optionY = startY + (i - 1) * optionHeight
        
        -- Highlight selected option
        if i == PauseMenu.selectedOption then
            Utils.setColor({0.2, 0.4, 0.8}, 0.5 * PauseMenu.fadeAlpha)
            love.graphics.rectangle("fill", menuX + 20, optionY, menuWidth - 40, optionHeight - 10, 5)
            
            Utils.setColor({1, 1, 0}, PauseMenu.fadeAlpha)
        else
            Utils.setColor({0.8, 0.8, 0.8}, PauseMenu.fadeAlpha)
        end
        
        -- Draw option text
        love.graphics.printf(option.text, menuX, optionY + 10, menuWidth, "center")
    end
    
    -- Draw help text
    Utils.setColor({0.5, 0.5, 0.5}, PauseMenu.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("↑/↓: Navigate    Enter: Select    ESC: Resume", 
        menuX, menuY + menuHeight - 30, menuWidth, "center")
end

-- Check if game should be paused
function PauseMenu.shouldPauseGameplay()
    return PauseMenu.isPaused and PauseMenu.fadeAlpha > 0.1
end

return PauseMenu