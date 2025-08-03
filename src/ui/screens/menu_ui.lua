-- Menu UI Screen for Orbit Jump
-- Handles main menu, settings, and navigation

local Utils = require("src.utils.utils")
local Button = require("src.ui.components.button")
local Layout = require("src.ui.components.layout")

local MenuUI = {}

-- Menu UI state
MenuUI.state = {
    currentScreen = "main", -- main, settings, accessibility, stats
    menuSelection = 1,
    settingsSelection = 1,
    settingsCategory = "addiction", -- addiction, audio, visual, accessibility
    statsSelection = 1
}

-- UI elements
MenuUI.elements = {
    menuButtons = {},
    settingsButtons = {},
    statsButtons = {},
    categoryTabs = {}
}

-- Initialize menu UI
function MenuUI.init(fonts)
    MenuUI.fonts = fonts or _G.GameFonts
    
    -- Create layout
    MenuUI.layout = Layout.createResponsiveLayout()
    
    -- Create main menu buttons
    MenuUI.elements.menuButtons = {
        Button.new({
            text = "Resume Game",
            width = 200,
            height = 40,
            onClick = function() MenuUI.onResumeClick() end
        }),
        Button.new({
            text = "Settings",
            width = 200,
            height = 40,
            onClick = function() MenuUI.onSettingsClick() end
        }),
        Button.new({
            text = "Statistics",
            width = 200,
            height = 40,
            onClick = function() MenuUI.onStatsClick() end
        }),
        Button.new({
            text = "Accessibility",
            width = 200,
            height = 40,
            onClick = function() MenuUI.onAccessibilityClick() end
        }),
        Button.new({
            text = "Exit Game",
            width = 200,
            height = 40,
            onClick = function() MenuUI.onExitClick() end
        })
    }
    
    -- Create settings category tabs
    MenuUI.elements.categoryTabs = {
        Button.new({
            text = "Addiction",
            width = 100,
            height = 30,
            onClick = function() MenuUI.onCategoryClick("addiction") end
        }),
        Button.new({
            text = "Audio",
            width = 100,
            height = 30,
            onClick = function() MenuUI.onCategoryClick("audio") end
        }),
        Button.new({
            text = "Visual",
            width = 100,
            height = 30,
            onClick = function() MenuUI.onCategoryClick("visual") end
        }),
        Button.new({
            text = "Accessibility",
            width = 100,
            height = 30,
            onClick = function() MenuUI.onCategoryClick("accessibility") end
        })
    }
    
    -- Add elements to layout
    MenuUI:addElementsToLayout()
    
    -- Update layout
    MenuUI.layout:calculate()
    MenuUI.layout:apply()
    
    return true
end

-- Add elements to layout
function MenuUI:addElementsToLayout()
    -- Clear existing elements
    MenuUI.layout.elements = {}
    
    if MenuUI.state.currentScreen == "main" then
        -- Add main menu buttons
        for i, button in ipairs(MenuUI.elements.menuButtons) do
            MenuUI.layout:addElement(button, {
                x = "center",
                y = 150 + (i - 1) * 50,
                width = 200,
                height = 40,
                align = "center"
            })
        end
    elseif MenuUI.state.currentScreen == "settings" then
        -- Add category tabs
        for i, tab in ipairs(MenuUI.elements.categoryTabs) do
            MenuUI.layout:addElement(tab, {
                x = 50 + (i - 1) * 110,
                y = 100,
                width = 100,
                height = 30
            })
        end
        
        -- Add settings buttons (will be populated based on category)
        MenuUI:addSettingsButtons()
    elseif MenuUI.state.currentScreen == "stats" then
        -- Add stats buttons
        MenuUI:addStatsButtons()
    end
end

-- Add settings buttons based on current category
function MenuUI:addSettingsButtons()
    local settings = MenuUI:getCurrentSettingsMap()
    local startY = 150
    
    for i, setting in ipairs(settings) do
        local button = Button.new({
            text = setting.name,
            width = 300,
            height = 30,
            onClick = function() MenuUI.onSettingToggle(i) end
        })
        
        MenuUI.layout:addElement(button, {
            x = 50,
            y = startY + (i - 1) * 40,
            width = 300,
            height = 30
        })
        
        table.insert(MenuUI.elements.settingsButtons, button)
    end
end

-- Add stats buttons
function MenuUI:addStatsButtons()
    local statsOptions = {
        "Current Session",
        "Performance Analysis", 
        "Personal Bests",
        "Overall Statistics"
    }
    
    for i, option in ipairs(statsOptions) do
        local button = Button.new({
            text = option,
            width = 250,
            height = 35,
            onClick = function() MenuUI.onStatsOptionClick(i) end
        })
        
        MenuUI.layout:addElement(button, {
            x = 50,
            y = 150 + (i - 1) * 45,
            width = 250,
            height = 35
        })
        
        table.insert(MenuUI.elements.statsButtons, button)
    end
end

-- Update menu UI
function MenuUI.update(dt)
    -- Update layout
    MenuUI.layout:update()
    
    -- Update button states based on selection
    MenuUI:updateButtonStates()
end

-- Draw menu UI
function MenuUI.draw()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Draw background overlay
    Utils.setColor({0, 0, 0, 0.7})
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw title
    Utils.setColor({1, 1, 1, 1})
    local font = MenuUI.fonts and MenuUI.fonts.large or love.graphics.getFont()
    love.graphics.setFont(font)
    local title = MenuUI:getScreenTitle()
    local titleWidth = font:getWidth(title)
    love.graphics.print(title, screenWidth / 2 - titleWidth / 2, 50)
    
    -- Draw current screen content
    if MenuUI.state.currentScreen == "main" then
        MenuUI:drawMainMenu()
    elseif MenuUI.state.currentScreen == "settings" then
        MenuUI:drawSettings()
    elseif MenuUI.state.currentScreen == "stats" then
        MenuUI:drawStats()
    elseif MenuUI.state.currentScreen == "accessibility" then
        MenuUI:drawAccessibility()
    end
    
    -- Draw back button
    if MenuUI.state.currentScreen ~= "main" then
        MenuUI:drawBackButton()
    end
end

-- Draw main menu
function MenuUI:drawMainMenu()
    -- Draw menu buttons
    for _, button in ipairs(MenuUI.elements.menuButtons) do
        button:draw()
    end
end

-- Draw settings screen
function MenuUI:drawSettings()
    -- Draw category tabs
    for i, tab in ipairs(MenuUI.elements.categoryTabs) do
        -- Highlight active category
        if MenuUI.state.settingsCategory == MenuUI:getCategoryFromIndex(i) then
            tab.colors.normal = {0.4, 0.4, 0.6, 0.9}
        else
            tab.colors.normal = {0.2, 0.2, 0.3, 0.8}
        end
        tab:draw()
    end
    
    -- Draw settings buttons
    for _, button in ipairs(MenuUI.elements.settingsButtons) do
        button:draw()
    end
    
    -- Draw current settings values
    MenuUI:drawSettingsValues()
end

-- Draw stats screen
function MenuUI:drawStats()
    -- Draw stats buttons
    for _, button in ipairs(MenuUI.elements.statsButtons) do
        button:draw()
    end
    
    -- Draw selected stats content
    MenuUI:drawStatsContent()
end

-- Draw accessibility screen
function MenuUI:drawAccessibility()
    -- Draw accessibility options
    local options = {
        "High Contrast Mode",
        "Large Text",
        "Screen Reader Support",
        "Reduced Motion",
        "Color Blind Support"
    }
    
    for i, option in ipairs(options) do
        local y = 150 + (i - 1) * 40
        Utils.setColor({1, 1, 1, 1})
        local font = MenuUI.fonts and MenuUI.fonts.medium or love.graphics.getFont()
        love.graphics.setFont(font)
        love.graphics.print(option, 50, y)
    end
end

-- Draw back button
function MenuUI:drawBackButton()
    local backButton = Button.new({
        text = "Back",
        width = 80,
        height = 30,
        onClick = function() MenuUI.onBackClick() end
    })
    
    backButton.x = 20
    backButton.y = 20
    backButton:draw()
end

-- Draw settings values
function MenuUI:drawSettingsValues()
    local settings = MenuUI:getCurrentSettingsMap()
    local startY = 150
    
    for i, setting in ipairs(settings) do
        local y = startY + (i - 1) * 40
        local value = setting.value and "ON" or "OFF"
        local color = setting.value and {0.2, 0.8, 0.2, 1} or {0.8, 0.2, 0.2, 1}
        
        Utils.setColor(color)
        local font = MenuUI.fonts and GameUI.fonts.small or love.graphics.getFont()
        love.graphics.setFont(font)
        love.graphics.print(value, 370, y + 5)
    end
end

-- Draw stats content
function MenuUI:drawStatsContent()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local contentX = 350
    local contentY = 150
    local contentWidth = screenWidth - contentX - 50
    
    Utils.setColor({1, 1, 1, 1})
    local font = MenuUI.fonts and MenuUI.fonts.medium or love.graphics.getFont()
    love.graphics.setFont(font)
    
    if MenuUI.state.statsSelection == 1 then
        love.graphics.print("Current Session Statistics", contentX, contentY)
        -- Add more detailed stats here
    elseif MenuUI.state.statsSelection == 2 then
        love.graphics.print("Performance Analysis", contentX, contentY)
        -- Add performance analysis here
    elseif MenuUI.state.statsSelection == 3 then
        love.graphics.print("Personal Bests", contentX, contentY)
        -- Add personal bests here
    elseif MenuUI.state.statsSelection == 4 then
        love.graphics.print("Overall Statistics", contentX, contentY)
        -- Add overall stats here
    end
end

-- Update button states
function MenuUI:updateButtonStates()
    -- Update main menu selection
    for i, button in ipairs(MenuUI.elements.menuButtons) do
        if i == MenuUI.state.menuSelection then
            button.colors.normal = {0.4, 0.4, 0.6, 0.9}
        else
            button.colors.normal = {0.2, 0.2, 0.3, 0.8}
        end
    end
    
    -- Update settings selection
    for i, button in ipairs(MenuUI.elements.settingsButtons) do
        if i == MenuUI.state.settingsSelection then
            button.colors.normal = {0.4, 0.4, 0.6, 0.9}
        else
            button.colors.normal = {0.2, 0.2, 0.3, 0.8}
        end
    end
    
    -- Update stats selection
    for i, button in ipairs(MenuUI.elements.statsButtons) do
        if i == MenuUI.state.statsSelection then
            button.colors.normal = {0.4, 0.4, 0.6, 0.9}
        else
            button.colors.normal = {0.2, 0.2, 0.3, 0.8}
        end
    end
end

-- Handle mouse input
function MenuUI.mousepressed(x, y, button)
    if button == 1 then -- Left click
        -- Check button clicks based on current screen
        if MenuUI.state.currentScreen == "main" then
            for i, menuButton in ipairs(MenuUI.elements.menuButtons) do
                if menuButton:contains(x, y) then
                    MenuUI.state.menuSelection = i
                    menuButton.onClick()
                    return true
                end
            end
        elseif MenuUI.state.currentScreen == "settings" then
            -- Check category tabs
            for i, tab in ipairs(MenuUI.elements.categoryTabs) do
                if tab:contains(x, y) then
                    MenuUI.onCategoryClick(MenuUI:getCategoryFromIndex(i))
                    return true
                end
            end
            
            -- Check settings buttons
            for i, settingButton in ipairs(MenuUI.elements.settingsButtons) do
                if settingButton:contains(x, y) then
                    MenuUI.state.settingsSelection = i
                    MenuUI.onSettingToggle(i)
                    return true
                end
            end
        elseif MenuUI.state.currentScreen == "stats" then
            for i, statsButton in ipairs(MenuUI.elements.statsButtons) do
                if statsButton:contains(x, y) then
                    MenuUI.state.statsSelection = i
                    MenuUI.onStatsOptionClick(i)
                    return true
                end
            end
        end
        
        -- Check back button
        if MenuUI.state.currentScreen ~= "main" and x >= 20 and x <= 100 and y >= 20 and y <= 50 then
            MenuUI.onBackClick()
            return true
        end
    end
    
    return false
end

-- Handle mouse movement for hover effects
function MenuUI.mousemoved(x, y)
    local mousePressed = love.mouse.isDown(1)
    
    -- Update button hover states based on current screen
    if MenuUI.state.currentScreen == "main" then
        for _, button in ipairs(MenuUI.elements.menuButtons) do
            button:update(x, y, mousePressed)
        end
    elseif MenuUI.state.currentScreen == "settings" then
        for _, tab in ipairs(MenuUI.elements.categoryTabs) do
            tab:update(x, y, mousePressed)
        end
        for _, button in ipairs(MenuUI.elements.settingsButtons) do
            button:update(x, y, mousePressed)
        end
    elseif MenuUI.state.currentScreen == "stats" then
        for _, button in ipairs(MenuUI.elements.statsButtons) do
            button:update(x, y, mousePressed)
        end
    end
end

-- Handle keyboard input
function MenuUI.keypressed(key)
    if key == "escape" then
        if MenuUI.state.currentScreen == "main" then
            MenuUI.onResumeClick()
        else
            MenuUI.onBackClick()
        end
        return true
    elseif key == "up" or key == "w" then
        MenuUI:moveSelection(-1)
        return true
    elseif key == "down" or key == "s" then
        MenuUI:moveSelection(1)
        return true
    elseif key == "return" or key == "space" then
        MenuUI:activateSelection()
        return true
    end
    
    return false
end

-- Move selection
function MenuUI:moveSelection(direction)
    if MenuUI.state.currentScreen == "main" then
        MenuUI.state.menuSelection = MenuUI:clampSelection(MenuUI.state.menuSelection + direction, #MenuUI.elements.menuButtons)
    elseif MenuUI.state.currentScreen == "settings" then
        MenuUI.state.settingsSelection = MenuUI:clampSelection(MenuUI.state.settingsSelection + direction, #MenuUI.elements.settingsButtons)
    elseif MenuUI.state.currentScreen == "stats" then
        MenuUI.state.statsSelection = MenuUI:clampSelection(MenuUI.state.statsSelection + direction, #MenuUI.elements.statsButtons)
    end
end

-- Activate current selection
function MenuUI:activateSelection()
    if MenuUI.state.currentScreen == "main" then
        MenuUI.elements.menuButtons[MenuUI.state.menuSelection].onClick()
    elseif MenuUI.state.currentScreen == "settings" then
        MenuUI.onSettingToggle(MenuUI.state.settingsSelection)
    elseif MenuUI.state.currentScreen == "stats" then
        MenuUI.onStatsOptionClick(MenuUI.state.statsSelection)
    end
end

-- Clamp selection to valid range
function MenuUI:clampSelection(selection, max)
    if selection < 1 then
        return max
    elseif selection > max then
        return 1
    else
        return selection
    end
end

-- Get screen title
function MenuUI:getScreenTitle()
    if MenuUI.state.currentScreen == "main" then
        return "Orbit Jump - Main Menu"
    elseif MenuUI.state.currentScreen == "settings" then
        return "Settings"
    elseif MenuUI.state.currentScreen == "stats" then
        return "Statistics"
    elseif MenuUI.state.currentScreen == "accessibility" then
        return "Accessibility"
    else
        return "Menu"
    end
end

-- Get category from index
function MenuUI:getCategoryFromIndex(index)
    local categories = {"addiction", "audio", "visual", "accessibility"}
    return categories[index] or "addiction"
end

-- Get current settings map
function MenuUI:getCurrentSettingsMap()
    -- This would be populated from the actual settings system
    return {
        {name = "Setting 1", value = true},
        {name = "Setting 2", value = false},
        {name = "Setting 3", value = true}
    }
end

-- Event handlers
function MenuUI.onResumeClick()
    MenuUI.state.currentScreen = "main"
    if MenuUI.onResumeRequested then
        MenuUI.onResumeRequested()
    end
end

function MenuUI.onSettingsClick()
    MenuUI.state.currentScreen = "settings"
    MenuUI.state.settingsSelection = 1
    MenuUI:addElementsToLayout()
    MenuUI.layout:calculate()
    MenuUI.layout:apply()
end

function MenuUI.onStatsClick()
    MenuUI.state.currentScreen = "stats"
    MenuUI.state.statsSelection = 1
    MenuUI:addElementsToLayout()
    MenuUI.layout:calculate()
    MenuUI.layout:apply()
end

function MenuUI.onAccessibilityClick()
    MenuUI.state.currentScreen = "accessibility"
    MenuUI:addElementsToLayout()
    MenuUI.layout:calculate()
    MenuUI.layout:apply()
end

function MenuUI.onExitClick()
    if MenuUI.onExitRequested then
        MenuUI.onExitRequested()
    end
end

function MenuUI.onBackClick()
    if MenuUI.state.currentScreen == "settings" or 
       MenuUI.state.currentScreen == "stats" or 
       MenuUI.state.currentScreen == "accessibility" then
        MenuUI.state.currentScreen = "main"
        MenuUI.state.menuSelection = 1
        MenuUI:addElementsToLayout()
        MenuUI.layout:calculate()
        MenuUI.layout:apply()
    end
end

function MenuUI.onCategoryClick(category)
    MenuUI.state.settingsCategory = category
    MenuUI.state.settingsSelection = 1
    MenuUI.elements.settingsButtons = {}
    MenuUI:addElementsToLayout()
    MenuUI.layout:calculate()
    MenuUI.layout:apply()
end

function MenuUI.onSettingToggle(index)
    -- This would toggle the actual setting
    if MenuUI.onSettingChanged then
        MenuUI.onSettingChanged(MenuUI.state.settingsCategory, index)
    end
end

function MenuUI.onStatsOptionClick(index)
    MenuUI.state.statsSelection = index
    -- This would load the specific stats content
end

-- Set callbacks
function MenuUI.setOnResumeRequested(callback)
    MenuUI.onResumeRequested = callback
end

function MenuUI.setOnExitRequested(callback)
    MenuUI.onExitRequested = callback
end

function MenuUI.setOnSettingChanged(callback)
    MenuUI.onSettingChanged = callback
end

-- Cleanup
function MenuUI.cleanup()
    MenuUI.elements = {}
    MenuUI.layout = nil
    MenuUI.fonts = nil
end

return MenuUI 