--[[
    Enhanced UI Debug System: Modular Architecture
    
    This module coordinates the debug system using the new modular structure
    with separate modules for configuration, logging, validation, performance, and rendering.
--]]

local DebugConfig = require("src.ui.debug.debug_config")
local DebugLogging = require("src.ui.debug.debug_logging")
local DebugValidation = require("src.ui.debug.debug_validation")
local DebugPerformance = require("src.ui.debug.debug_performance")
local DebugRendering = require("src.ui.debug.debug_rendering")

local UIDebug = {}

-- Debug state and configuration
UIDebug.enabled = false
UIDebug.showBounds = true
UIDebug.showLabels = true
UIDebug.showMetrics = true
UIDebug.showPerformance = true
UIDebug.showMemoryUsage = false
UIDebug.logPositioning = false
UIDebug.logEvents = false
UIDebug.strictValidation = false
UIDebug.autoValidate = true
UIDebug.screenshotMode = false

-- Initialize enhanced debug system
function UIDebug.init(config)
    -- Apply configuration if provided
    if config then
        for key, value in pairs(config) do
            if UIDebug[key] ~= nil then
                UIDebug[key] = value
            end
        end
    end
    
    UIDebug.enabled = false -- Start disabled, toggle with F12
    
    -- Initialize all modules
    DebugLogging.init()
    DebugValidation.resetTracking()
    DebugPerformance.init()
    
    DebugLogging.log(DebugConfig.LogLevel.INFO, "🔧 Advanced UI Debug system initialized (F12 to toggle)")
end

-- Toggle debug visualization with enhanced feedback
function UIDebug.toggle()
    UIDebug.enabled = not UIDebug.enabled
    local status = UIDebug.enabled and "ENABLED" or "DISABLED"
    
    DebugLogging.logDebugToggle(UIDebug.enabled)
    
    if UIDebug.enabled then
        UIDebug.validateCurrentLayout()
        DebugLogging.log(DebugConfig.LogLevel.DEBUG, "Debug mode activated - tracking %d elements", 
            DebugValidation.countTrackedElements())
    else
        DebugLogging.log(DebugConfig.LogLevel.DEBUG, "Debug mode deactivated")
    end
    
    return UIDebug.enabled
end

-- Set debug level
function UIDebug.setLogLevel(level)
    DebugLogging.setLogLevel(level)
end

-- Switch color theme
function UIDebug.setTheme(themeName)
    if DebugConfig.colorThemes[themeName] then
        DebugRendering.setTheme(themeName)
    else
        DebugLogging.log(DebugConfig.LogLevel.WARN, "Unknown theme: %s", themeName)
    end
end

-- Enhanced element registration with metadata
function UIDebug.registerElement(name, element, parentFrame, metadata)
    return DebugValidation.registerElement(name, element, parentFrame, metadata)
end

-- Validate current layout
function UIDebug.validateCurrentLayout(customRules)
    local startTime = love and love.timer and love.timer.getTime() or os.time()
    
    local result = DebugValidation.validateCurrentLayout(customRules)
    
    -- Update performance metrics
    local endTime = love and love.timer and love.timer.getTime() or os.time()
    local validationTime = endTime - startTime
    DebugPerformance.setValidationTime(validationTime)
    
    return result
end

-- Draw the debug interface
function UIDebug.draw()
    if not UIDebug.enabled then
        return
    end
    
    -- Update performance metrics
    DebugPerformance.setElementCount(DebugValidation.countTrackedElements())
    
    -- Draw debug interface
    DebugRendering.draw()
    
    -- Draw screenshot mode if active
    if UIDebug.screenshotMode then
        DebugRendering.drawScreenshotMode()
    end
end

-- Handle key press
function UIDebug.keypressed(key, scancode, isrepeat)
    if key == "f12" then
        UIDebug.toggle()
        return true
    end
    
    if not UIDebug.enabled then
        return false
    end
    
    if key == "t" then
        UIDebug.cycleDebugLevel()
        return true
    elseif key == "r" then
        UIDebug.toggleTheme()
        return true
    elseif key == "v" then
        UIDebug.validateCurrentLayout()
        return true
    elseif key == "s" then
        UIDebug.takeScreenshot()
        return true
    elseif key == "i" then
        UIDebug.showElementInspector()
        return true
    elseif key == "c" then
        UIDebug.clearHistory()
        return true
    elseif key == "space" and UIDebug.screenshotMode then
        UIDebug.takeScreenshot()
        return true
    elseif key == "escape" and UIDebug.screenshotMode then
        UIDebug.screenshotMode = false
        return true
    end
    
    return false
end

-- Cycle debug level
function UIDebug.cycleDebugLevel()
    local currentLevel = DebugLogging.getLogLevel()
    local levels = {DebugConfig.LogLevel.ERROR, DebugConfig.LogLevel.WARN, 
                   DebugConfig.LogLevel.INFO, DebugConfig.LogLevel.DEBUG, DebugConfig.LogLevel.VERBOSE}
    
    local nextIndex = 1
    for i, level in ipairs(levels) do
        if level == currentLevel then
            nextIndex = i % #levels + 1
            break
        end
    end
    
    UIDebug.setLogLevel(levels[nextIndex])
end

-- Toggle theme
function UIDebug.toggleTheme()
    local themes = DebugConfig.getAvailableThemes()
    local currentTheme = DebugRendering.getCurrentTheme()
    
    local nextIndex = 1
    for i, theme in ipairs(themes) do
        if theme == currentTheme then
            nextIndex = i % #themes + 1
            break
        end
    end
    
    UIDebug.setTheme(themes[nextIndex])
end

-- Take screenshot
function UIDebug.takeScreenshot()
    if love and love.graphics then
        local canvas = love.graphics.newCanvas()
        love.graphics.setCanvas(canvas)
        love.graphics.clear()
        
        -- Draw the current frame
        -- Note: This would need to be called from the main draw function
        
        love.graphics.setCanvas()
        
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local filename = string.format("debug_screenshot_%s.png", timestamp)
        
        -- Save the canvas
        local imageData = canvas:newImageData()
        imageData:encode("png", filename)
        
        DebugLogging.log(DebugConfig.LogLevel.INFO, "Screenshot saved: %s", filename)
    end
end

-- Export debug data
function UIDebug.exportDebugData()
    local export = {
        session = DebugLogging.getSessionInfo(),
        validation = DebugValidation.exportValidationData(),
        performance = DebugPerformance.exportPerformanceData(),
        events = DebugLogging.exportHistory(),
        exportTime = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    return export
end

-- Show element inspector
function UIDebug.showElementInspector()
    -- This would be implemented to show detailed element information
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Element inspector activated")
end

-- Reset tracking
function UIDebug.resetTracking()
    DebugValidation.resetTracking()
    DebugPerformance.reset()
    DebugLogging.clearHistory()
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Debug tracking reset")
end

-- Clear history
function UIDebug.clearHistory()
    DebugLogging.clearHistory()
    DebugPerformance.clearHistory()
    DebugValidation.clearIssues()
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Debug history cleared")
end

-- Update debug system
function UIDebug.update(dt)
    if UIDebug.enabled then
        DebugPerformance.update(dt)
        
        -- Auto-validate if enabled
        if UIDebug.autoValidate then
            UIDebug.validateCurrentLayout()
        end
    end
end

-- Get debug statistics
function UIDebug.getDebugStats()
    return {
        enabled = UIDebug.enabled,
        elementCount = DebugValidation.countTrackedElements(),
        issueCount = DebugValidation.countLayoutIssues(),
        performance = DebugPerformance.getPerformanceSummary(),
        session = DebugLogging.getSessionInfo(),
        theme = DebugRendering.getCurrentTheme()
    }
end

-- Check if debug is enabled
function UIDebug.isEnabled()
    return UIDebug.enabled
end

-- Get tracked elements
function UIDebug.getTrackedElements()
    return DebugValidation.getTrackedElements()
end

-- Get layout issues
function UIDebug.getLayoutIssues()
    return DebugValidation.getLayoutIssues()
end

-- Get performance metrics
function UIDebug.getPerformanceMetrics()
    return DebugPerformance.getPerformanceMetrics()
end

-- Get event history
function UIDebug.getEventHistory()
    return DebugLogging.getEventHistory()
end

-- Backward compatibility
UIDebug.LogLevel = DebugConfig.LogLevel
UIDebug.colorThemes = DebugConfig.colorThemes
UIDebug.validationRules = DebugConfig.validationRules

return UIDebug 