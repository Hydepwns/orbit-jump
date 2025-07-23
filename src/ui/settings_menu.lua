-- Settings Menu for Orbit Jump
-- Allows players to configure volume, controls, and other preferences

local Utils = Utils.Utils.require("src.utils.utils")
local SettingsMenu = {}

-- Settings state
SettingsMenu.isVisible = false
SettingsMenu.selectedTab = 1
SettingsMenu.selectedOption = 1
SettingsMenu.fadeAlpha = 0
SettingsMenu.unsavedChanges = false

-- Settings categories
SettingsMenu.tabs = {
    {name = "Audio", icon = "🔊"},
    {name = "Controls", icon = "🎮"},
    {name = "Graphics", icon = "🖼️"},
    {name = "Gameplay", icon = "⚙️"}
}

-- Default settings
SettingsMenu.defaults = {
    -- Audio
    masterVolume = 1.0,
    soundVolume = 1.0,
    musicVolume = 0.5,
    
    -- Controls
    dashKey1 = "lshift",
    dashKey2 = "z",
    dashKey3 = "x",
    mapKey = "tab",
    upgradeKey = "u",
    loreKey = "l",
    pauseKey = "escape",
    
    -- Graphics
    particleQuality = 1.0,  -- 0.5 = low, 1.0 = high
    showFPS = false,
    screenShake = true,
    fullscreen = false,
    vsync = true,
    
    -- Gameplay
    autoSave = true,
    autoSaveInterval = 60,
    tutorialHints = true,
    mobileControls = "auto",  -- auto, always, never
    cameraZoom = 1.0
}

-- Current settings (loaded from file or defaults)
SettingsMenu.current = {}

-- Settings file
SettingsMenu.settingsFile = "settings.dat"

-- Initialize
function SettingsMenu.init()
    -- Load settings from file or use defaults
    SettingsMenu.load()
    
    -- Apply settings
    SettingsMenu.applySettings()
    
    Utils.Logger.info("Settings menu initialized")
end

-- Load settings from file
function SettingsMenu.load()
    if love.filesystem.getInfo(SettingsMenu.settingsFile) then
        local contents = love.filesystem.read(SettingsMenu.settingsFile)
        if contents then
            local json = Utils.Utils.require("libs.json")
            local success, settings  = Utils.ErrorHandler.safeCall(json.decode, contents)
            if success then
                -- Merge with defaults to ensure all keys exist
                SettingsMenu.current = {}
                for k, v in pairs(SettingsMenu.defaults) do
                    SettingsMenu.current[k] = settings[k] or v
                end
                Utils.Logger.info("Settings loaded from file")
                return
            end
        end
    end
    
    -- Use defaults
    SettingsMenu.current = {}
    for k, v in pairs(SettingsMenu.defaults) do
        SettingsMenu.current[k] = v
    end
    Utils.Logger.info("Using default settings")
end

-- Save settings to file
function SettingsMenu.save()
    local json = Utils.Utils.require("libs.json")
    local data = json.encode(SettingsMenu.current)
    love.filesystem.write(SettingsMenu.settingsFile, data)
    SettingsMenu.unsavedChanges = false
    Utils.Logger.info("Settings saved")
end

-- Apply current settings to game
function SettingsMenu.applySettings()
    -- Apply audio settings
    local soundManager = Utils.Utils.require("src.audio.sound_manager")
    soundManager:setVolume(SettingsMenu.current.masterVolume * SettingsMenu.current.soundVolume)
    
    -- Apply graphics settings
    love.window.setFullscreen(SettingsMenu.current.fullscreen)
    love.window.setVSync(SettingsMenu.current.vsync and 1 or 0)
    
    -- Apply to performance system
    local PerformanceSystem = Utils.Utils.require("src.performance.performance_system")
    if PerformanceSystem.config then
        PerformanceSystem.config.showDebug = SettingsMenu.current.showFPS
    end
    
    -- Apply to camera
    local Camera = Utils.Utils.require("src.core.camera")
    if Camera.enableShake ~= nil then
        Camera.enableShake = SettingsMenu.current.screenShake
    end
    
    -- Apply auto-save settings
    local SaveSystem = Utils.Utils.require("src.systems.save_system")
    if SaveSystem then
        SaveSystem.autoSaveInterval = SettingsMenu.current.autoSaveInterval
    end
end

-- Toggle settings menu
function SettingsMenu.toggle()
    SettingsMenu.isVisible = not SettingsMenu.isVisible
    if SettingsMenu.isVisible then
        SettingsMenu.selectedTab = 1
        SettingsMenu.selectedOption = 1
    elseif SettingsMenu.unsavedChanges then
        -- Auto-save on close
        SettingsMenu.save()
        SettingsMenu.applySettings()
    end
end

-- Update
function SettingsMenu.update(dt)
    if SettingsMenu.isVisible then
        SettingsMenu.fadeAlpha = math.min(SettingsMenu.fadeAlpha + dt * 5, 1)
    else
        SettingsMenu.fadeAlpha = math.max(SettingsMenu.fadeAlpha - dt * 5, 0)
    end
end

-- Get options for current tab
function SettingsMenu.getCurrentOptions()
    local tab = SettingsMenu.tabs[SettingsMenu.selectedTab]
    
    if tab.name == "Audio" then
        return {
            {key = "masterVolume", name = "Master Volume", type = "slider", min = 0, max = 1},
            {key = "soundVolume", name = "Sound Effects", type = "slider", min = 0, max = 1},
            {key = "musicVolume", name = "Music Volume", type = "slider", min = 0, max = 1}
        }
    elseif tab.name == "Controls" then
        return {
            {key = "dashKey1", name = "Dash Key 1", type = "key"},
            {key = "dashKey2", name = "Dash Key 2", type = "key"},
            {key = "mapKey", name = "Map Key", type = "key"},
            {key = "upgradeKey", name = "Upgrades Key", type = "key"},
            {key = "loreKey", name = "Lore Viewer Key", type = "key"},
            {key = "pauseKey", name = "Pause Key", type = "key"}
        }
    elseif tab.name == "Graphics" then
        return {
            {key = "particleQuality", name = "Particle Quality", type = "choice", 
             choices = {{value = 0.5, label = "Low"}, {value = 0.75, label = "Medium"}, {value = 1.0, label = "High"}}},
            {key = "showFPS", name = "Show FPS", type = "toggle"},
            {key = "screenShake", name = "Screen Shake", type = "toggle"},
            {key = "fullscreen", name = "Fullscreen", type = "toggle"},
            {key = "vsync", name = "VSync", type = "toggle"}
        }
    elseif tab.name == "Gameplay" then
        return {
            {key = "autoSave", name = "Auto-Save", type = "toggle"},
            {key = "autoSaveInterval", name = "Auto-Save Interval", type = "slider", min = 30, max = 300, step = 30, unit = "s"},
            {key = "tutorialHints", name = "Tutorial Hints", type = "toggle"},
            {key = "mobileControls", name = "Mobile Controls", type = "choice",
             choices = {{value = "auto", label = "Auto"}, {value = "always", label = "Always"}, {value = "never", label = "Never"}}},
            {key = "cameraZoom", name = "Camera Zoom", type = "slider", min = 0.5, max = 1.5}
        }
    end
    
    return {}
end

-- Handle input
function SettingsMenu.keypressed(key)
    if not SettingsMenu.isVisible then
        return false
    end
    
    local options = SettingsMenu.getCurrentOptions()
    local currentOption = options[SettingsMenu.selectedOption]
    
    if key == "escape" then
        SettingsMenu.toggle()
        return true
    elseif key == "left" then
        if SettingsMenu.selectedTab > 1 then
            SettingsMenu.selectedTab = SettingsMenu.selectedTab - 1
            SettingsMenu.selectedOption = 1
        end
        return true
    elseif key == "right" then
        if SettingsMenu.selectedTab < #SettingsMenu.tabs then
            SettingsMenu.selectedTab = SettingsMenu.selectedTab + 1
            SettingsMenu.selectedOption = 1
        end
        return true
    elseif key == "up" then
        SettingsMenu.selectedOption = math.max(1, SettingsMenu.selectedOption - 1)
        return true
    elseif key == "down" then
        SettingsMenu.selectedOption = math.min(#options, SettingsMenu.selectedOption + 1)
        return true
    elseif key == "return" or key == "space" then
        -- Handle option selection
        if currentOption then
            if currentOption.type == "toggle" then
                SettingsMenu.current[currentOption.key] = not SettingsMenu.current[currentOption.key]
                SettingsMenu.unsavedChanges = true
            elseif currentOption.type == "choice" then
                -- Cycle through choices
                local currentValue = SettingsMenu.current[currentOption.key]
                local nextIndex = 1
                for i, choice in ipairs(currentOption.choices) do
                    if choice.value == currentValue then
                        nextIndex = (i % #currentOption.choices) + 1
                        break
                    end
                end
                SettingsMenu.current[currentOption.key] = currentOption.choices[nextIndex].value
                SettingsMenu.unsavedChanges = true
            end
        end
        return true
    elseif key == "a" or key == "d" then
        -- Adjust sliders
        if currentOption and currentOption.type == "slider" then
            local step = currentOption.step or 0.1
            if key == "a" then
                SettingsMenu.current[currentOption.key] = math.max(currentOption.min,
                    SettingsMenu.current[currentOption.key] - step)
            else
                SettingsMenu.current[currentOption.key] = math.min(currentOption.max,
                    SettingsMenu.current[currentOption.key] + step)
            end
            SettingsMenu.unsavedChanges = true
            
            -- Apply audio changes immediately
            if currentOption.key:find("Volume") then
                SettingsMenu.applySettings()
            end
        end
        return true
    elseif key == "f5" then
        -- Save settings
        SettingsMenu.save()
        SettingsMenu.applySettings()
        return true
    elseif key == "f8" then
        -- Reset to defaults
        for k, v in pairs(SettingsMenu.defaults) do
            SettingsMenu.current[k] = v
        end
        SettingsMenu.unsavedChanges = true
        SettingsMenu.applySettings()
        return true
    end
    
    return true -- Consume all input when visible
end

-- Handle mouse input
function SettingsMenu.mousepressed(x, y, button)
    if not SettingsMenu.isVisible or SettingsMenu.fadeAlpha < 0.5 then
        return false
    end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local menuWidth = 700
    local menuHeight = 500
    local menuX = (screenWidth - menuWidth) / 2
    local menuY = (screenHeight - menuHeight) / 2
    
    -- Check if click is outside menu
    if x < menuX or x > menuX + menuWidth or y < menuY or y > menuY + menuHeight then
        SettingsMenu.toggle()
        return true
    end
    
    -- Check tab clicks
    local tabWidth = menuWidth / #SettingsMenu.tabs
    for i = 1, #SettingsMenu.tabs do
        local tabX = menuX + (i - 1) * tabWidth
        if x >= tabX and x <= tabX + tabWidth and y >= menuY and y <= menuY + 50 then
            SettingsMenu.selectedTab = i
            SettingsMenu.selectedOption = 1
            return true
        end
    end
    
    -- Check option clicks
    local options = SettingsMenu.getCurrentOptions()
    local optionY = menuY + 100
    
    for i, option in ipairs(options) do
        if y >= optionY and y <= optionY + 40 then
            SettingsMenu.selectedOption = i
            
            -- Handle clicks on options
            if option.type == "toggle" then
                SettingsMenu.current[option.key] = not SettingsMenu.current[option.key]
                SettingsMenu.unsavedChanges = true
            elseif option.type == "slider" then
                -- Calculate slider position
                local sliderX = menuX + 250
                local sliderWidth = 200
                if x >= sliderX and x <= sliderX + sliderWidth then
                    local percent = (x - sliderX) / sliderWidth
                    local range = option.max - option.min
                    SettingsMenu.current[option.key] = option.min + range * percent
                    SettingsMenu.unsavedChanges = true
                    
                    -- Apply audio changes immediately
                    if option.key:find("Volume") then
                        SettingsMenu.applySettings()
                    end
                end
            end
            
            return true
        end
        optionY = optionY + 50
    end
    
    return true
end

-- Draw settings menu
function SettingsMenu.draw()
    if SettingsMenu.fadeAlpha <= 0 then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw darkened background
    Utils.setColor({0, 0, 0}, 0.7 * SettingsMenu.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Menu dimensions
    local menuWidth = 700
    local menuHeight = 500
    local menuX = (screenWidth - menuWidth) / 2
    local menuY = (screenHeight - menuHeight) / 2
    
    -- Draw menu background
    Utils.setColor({0.1, 0.1, 0.2}, 0.95 * SettingsMenu.fadeAlpha)
    love.graphics.rectangle("fill", menuX, menuY, menuWidth, menuHeight, 10)
    
    -- Draw menu border
    Utils.setColor({0.5, 0.8, 1}, SettingsMenu.fadeAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", menuX, menuY, menuWidth, menuHeight, 10)
    
    -- Draw tabs
    local tabWidth = menuWidth / #SettingsMenu.tabs
    for i, tab in ipairs(SettingsMenu.tabs) do
        local tabX = menuX + (i - 1) * tabWidth
        
        -- Tab background
        if i == SettingsMenu.selectedTab then
            Utils.setColor({0.2, 0.4, 0.8}, 0.5 * SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", tabX, menuY, tabWidth, 50)
        end
        
        -- Tab text
        Utils.setColor({1, 1, 1}, SettingsMenu.fadeAlpha)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.printf(tab.icon .. " " .. tab.name, tabX, menuY + 15, tabWidth, "center")
    end
    
    -- Draw options for current tab
    local options = SettingsMenu.getCurrentOptions()
    local optionY = menuY + 100
    
    love.graphics.setFont(love.graphics.newFont(16))
    
    for i, option in ipairs(options) do
        -- Highlight selected option
        if i == SettingsMenu.selectedOption then
            Utils.setColor({0.2, 0.4, 0.8}, 0.3 * SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", menuX + 20, optionY - 5, menuWidth - 40, 40, 5)
        end
        
        -- Option name
        Utils.setColor({1, 1, 1}, SettingsMenu.fadeAlpha)
        love.graphics.print(option.name, menuX + 40, optionY)
        
        -- Option value/control
        if option.type == "slider" then
            -- Draw slider
            local sliderX = menuX + 250
            local sliderY = optionY + 8
            local sliderWidth = 200
            local value = SettingsMenu.current[option.key]
            local percent = (value - option.min) / (option.max - option.min)
            
            -- Slider track
            Utils.setColor({0.3, 0.3, 0.3}, SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth, 4, 2)
            
            -- Slider fill
            Utils.setColor({0.5, 0.8, 1}, SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", sliderX, sliderY, sliderWidth * percent, 4, 2)
            
            -- Slider handle
            love.graphics.circle("fill", sliderX + sliderWidth * percent, sliderY + 2, 8)
            
            -- Value text
            local valueText = string.format("%.1f", value)
            if option.unit then
                valueText = valueText .. option.unit
            elseif option.key:find("Volume") then
                valueText = string.format("%d%%", value * 100)
            end
            love.graphics.print(valueText, sliderX + sliderWidth + 20, optionY)
            
        elseif option.type == "toggle" then
            -- Draw toggle
            local toggleX = menuX + 250
            local toggleY = optionY
            local isOn = SettingsMenu.current[option.key]
            
            -- Toggle background
            Utils.setColor(isOn and {0.2, 0.8, 0.2} or {0.5, 0.5, 0.5}, SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", toggleX, toggleY, 60, 24, 12)
            
            -- Toggle knob
            Utils.setColor({1, 1, 1}, SettingsMenu.fadeAlpha)
            love.graphics.circle("fill", toggleX + (isOn and 48 or 12), toggleY + 12, 10)
            
            -- State text
            love.graphics.print(isOn and "ON" or "OFF", toggleX + 70, toggleY)
            
        elseif option.type == "choice" then
            -- Draw choice selector
            local choiceX = menuX + 250
            local currentValue = SettingsMenu.current[option.key]
            local currentLabel = ""
            
            for _, choice in ipairs(option.choices) do
                if choice.value == currentValue then
                    currentLabel = choice.label
                    break
                end
            end
            
            -- Choice box
            Utils.setColor({0.3, 0.3, 0.3}, SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", choiceX, optionY, 150, 24, 5)
            
            -- Choice text
            Utils.setColor({1, 1, 1}, SettingsMenu.fadeAlpha)
            love.graphics.printf(currentLabel, choiceX, optionY + 3, 150, "center")
            
            -- Arrows
            love.graphics.print("◄", choiceX - 20, optionY)
            love.graphics.print("►", choiceX + 160, optionY)
            
        elseif option.type == "key" then
            -- Draw key binding
            local keyX = menuX + 250
            local keyValue = SettingsMenu.current[option.key]
            
            -- Key box
            Utils.setColor({0.3, 0.3, 0.3}, SettingsMenu.fadeAlpha)
            love.graphics.rectangle("fill", keyX, optionY, 100, 24, 5)
            
            -- Key text
            Utils.setColor({1, 1, 1}, SettingsMenu.fadeAlpha)
            love.graphics.printf(keyValue:upper(), keyX, optionY + 3, 100, "center")
        end
        
        optionY = optionY + 50
    end
    
    -- Draw help text
    Utils.setColor({0.5, 0.5, 0.5}, SettingsMenu.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("↑/↓: Navigate   ←/→: Change Tab   A/D: Adjust Sliders   F5: Save   F8: Reset   ESC: Close", 
                        menuX, menuY + menuHeight - 40, menuWidth, "center")
    
    -- Draw unsaved changes indicator
    if SettingsMenu.unsavedChanges then
        Utils.setColor({1, 0.8, 0}, SettingsMenu.fadeAlpha)
        love.graphics.print("* Unsaved Changes", menuX + 20, menuY + menuHeight - 60)
    end
end

-- Check if blocking input
function SettingsMenu.isBlockingInput()
    return SettingsMenu.isVisible and SettingsMenu.fadeAlpha > 0.5
end

-- Get setting value
function SettingsMenu.get(key)
    return SettingsMenu.current[key] or SettingsMenu.defaults[key]
end

-- Set setting value
function SettingsMenu.set(key, value)
    SettingsMenu.current[key] = value
    SettingsMenu.unsavedChanges = true
end

return SettingsMenu