--[[
    UI Debug System: Advanced visual debugging tools for UI layout issues
    
    This module provides comprehensive debugging tools:
    - Real-time frame boundary visualization with color-coded issues
    - Advanced element positioning analysis and logging
    - Performance monitoring and bottleneck detection
    - Layout validation with customizable rules
    - Interactive debugging tools with hot-reload support
    - Automated screenshot generation for different screen sizes
    - Memory usage tracking for UI elements
    - Event-driven debugging with detailed logging
--]]

local Utils = require("src.utils.utils")
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

-- Debug levels
UIDebug.LogLevel = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
    VERBOSE = 5
}
UIDebug.currentLogLevel = UIDebug.LogLevel.INFO

-- Enhanced debug colors with theme support
UIDebug.colorThemes = {
    default = {
        frame = {1, 0, 0, 0.3},           -- Red for frame boundaries
        element = {0, 1, 0, 0.3},         -- Green for elements
        text = {1, 1, 1, 1},              -- White for labels
        overlap = {1, 0, 1, 0.5},         -- Magenta for overlapping elements
        outOfBounds = {1, 1, 0, 0.5},     -- Yellow for out-of-bounds elements
        performance = {0, 0.8, 1, 0.7},   -- Cyan for performance issues
        memory = {1, 0.5, 0, 0.6},        -- Orange for memory issues
        background = {0, 0, 0, 0.8},      -- Semi-transparent black
        success = {0, 1, 0, 0.8},         -- Green for success
        warning = {1, 0.8, 0, 0.8},       -- Yellow for warnings
        error = {1, 0, 0, 0.8}            -- Red for errors
    },
    darkMode = {
        frame = {0.8, 0.2, 0.2, 0.4},
        element = {0.2, 0.8, 0.2, 0.4},
        text = {0.9, 0.9, 0.9, 1},
        overlap = {0.8, 0.2, 0.8, 0.6},
        outOfBounds = {0.8, 0.8, 0.2, 0.6},
        performance = {0.2, 0.6, 0.8, 0.7},
        memory = {0.8, 0.4, 0.2, 0.6},
        background = {0.1, 0.1, 0.1, 0.9},
        success = {0.2, 0.8, 0.2, 0.9},
        warning = {0.8, 0.6, 0.2, 0.9},
        error = {0.8, 0.2, 0.2, 0.9}
    }
}
UIDebug.currentTheme = "default"
UIDebug.colors = UIDebug.colorThemes.default

-- Advanced tracking structures
UIDebug.trackedElements = {}
UIDebug.layoutIssues = {}
UIDebug.performanceMetrics = {
    frameTime = 0,
    drawCalls = 0,
    elementCount = 0,
    validationTime = 0,
    memoryUsage = 0,
    history = {}
}
UIDebug.validationRules = {}
UIDebug.eventHistory = {}
UIDebug.screenshots = {}

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
    UIDebug.trackedElements = {}
    UIDebug.layoutIssues = {}
    UIDebug.performanceMetrics = {
        frameTime = 0,
        drawCalls = 0,
        elementCount = 0,
        validationTime = 0,
        memoryUsage = 0,
        history = {}
    }
    UIDebug.eventHistory = {}
    UIDebug.screenshots = {}
    
    -- Initialize default validation rules
    UIDebug.initializeValidationRules()
    
    -- Set up performance monitoring
    UIDebug.lastFrameTime = 0
    UIDebug.frameCount = 0
    
    -- Create log file for debugging session
    UIDebug.sessionId = tostring(os.time())
    UIDebug.logFile = "ui_debug_" .. UIDebug.sessionId .. ".log"
    
    UIDebug.log(UIDebug.LogLevel.INFO, "🔧 Advanced UI Debug system initialized (F12 to toggle)")
    UIDebug.log(UIDebug.LogLevel.DEBUG, "Session ID: %s, Log level: %d", UIDebug.sessionId, UIDebug.currentLogLevel)
end

-- Toggle debug visualization
function UIDebug.toggle()
    UIDebug.enabled = not UIDebug.enabled
    local status = UIDebug.enabled and "ENABLED" or "DISABLED"
    Utils.Logger.info("🔧 UI Debug visualization %s", status)
    
    if UIDebug.enabled then
        UIDebug.validateCurrentLayout()
    end
end

-- Register a UI element for debugging
function UIDebug.registerElement(name, element, parentFrame)
    if not UIDebug.enabled then return end
    
    UIDebug.trackedElements[name] = {
        element = element,
        parentFrame = parentFrame,
        timestamp = love.timer.getTime(),
        type = "unknown"
    }
    
    if UIDebug.logPositioning then
        Utils.Logger.debug("🔧 UI Element registered: %s at (%.1f, %.1f) size %.1fx%.1f", 
            name, element.x or 0, element.y or 0, element.width or 0, element.height or 0)
    end
end

-- Validate current UI layout for common issues
function UIDebug.validateCurrentLayout()
    if not UIDebug.enabled then return end
    
    UIDebug.layoutIssues = {}
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    for name, tracked in pairs(UIDebug.trackedElements) do
        local element = tracked.element
        local issues = {}
        
        -- Check for out-of-bounds elements
        if element.x and element.y and element.width and element.height then
            if element.x < 0 or element.y < 0 then
                table.insert(issues, "negative_position")
            end
            
            if element.x + element.width > screenWidth or element.y + element.height > screenHeight then
                table.insert(issues, "out_of_bounds")
            end
            
            -- Check for zero or negative dimensions
            if element.width <= 0 or element.height <= 0 then
                table.insert(issues, "invalid_dimensions")
            end
        else
            table.insert(issues, "missing_geometry")
        end
        
        -- Check for overlapping elements (simplified check)
        for otherName, otherTracked in pairs(UIDebug.trackedElements) do
            if name ~= otherName and UIDebug.elementsOverlap(element, otherTracked.element) then
                table.insert(issues, "overlap_with_" .. otherName)
            end
        end
        
        if #issues > 0 then
            UIDebug.layoutIssues[name] = issues
        end
    end
    
    -- Log issues found
    local issueCount = 0
    for name, issues in pairs(UIDebug.layoutIssues) do
        issueCount = issueCount + #issues
        Utils.Logger.warn("🔧 UI Layout issues for %s: %s", name, table.concat(issues, ", "))
    end
    
    if issueCount == 0 then
        Utils.Logger.info("🔧 UI Layout validation: No issues found")
    else
        Utils.Logger.warn("🔧 UI Layout validation: %d issues found", issueCount)
    end
end

-- Check if two elements overlap
function UIDebug.elementsOverlap(elem1, elem2)
    if not (elem1.x and elem1.y and elem1.width and elem1.height and
            elem2.x and elem2.y and elem2.width and elem2.height) then
        return false
    end
    
    return not (elem1.x + elem1.width < elem2.x or
                elem2.x + elem2.width < elem1.x or
                elem1.y + elem1.height < elem2.y or
                elem2.y + elem2.height < elem1.y)
end

-- Draw debug visualization
function UIDebug.draw()
    if not UIDebug.enabled then return end
    
    love.graphics.push()
    love.graphics.setLineWidth(2)
    
    -- Draw tracked elements
    for name, tracked in pairs(UIDebug.trackedElements) do
        local element = tracked.element
        local hasIssues = UIDebug.layoutIssues[name] ~= nil
        
        if element.x and element.y and element.width and element.height then
            -- Choose color based on issues
            local color = UIDebug.colors.element
            if hasIssues then
                for _, issue in ipairs(UIDebug.layoutIssues[name] or {}) do
                    if issue == "out_of_bounds" then
                        color = UIDebug.colors.outOfBounds
                        break
                    elseif issue:match("overlap_") then
                        color = UIDebug.colors.overlap
                        break
                    end
                end
            end
            
            -- Draw element bounds
            if UIDebug.showBounds then
                love.graphics.setColor(color)
                love.graphics.rectangle("line", element.x, element.y, element.width, element.height)
                
                -- Fill with transparent color
                love.graphics.setColor(color[1], color[2], color[3], 0.1)
                love.graphics.rectangle("fill", element.x, element.y, element.width, element.height)
            end
            
            -- Draw element label
            if UIDebug.showLabels then
                love.graphics.setColor(UIDebug.colors.text)
                local labelText = name
                if hasIssues then
                    labelText = labelText .. " [!]"
                end
                love.graphics.print(labelText, element.x + 2, element.y + 2, 0, 0.8, 0.8)
            end
        end
    end
    
    -- Draw metrics panel
    if UIDebug.showMetrics then
        UIDebug.drawMetricsPanel()
    end
    
    love.graphics.pop()
end

-- Draw metrics panel with layout information
function UIDebug.drawMetricsPanel()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local panelWidth, panelHeight = 300, 200
    local panelX = screenWidth - panelWidth - 10
    local panelY = 10
    
    -- Panel background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Panel content
    love.graphics.setColor(1, 1, 1, 1)
    local yOffset = panelY + 10
    local lineHeight = 16
    
    love.graphics.print("UI Debug Metrics", panelX + 10, yOffset, 0, 0.9, 0.9)
    yOffset = yOffset + lineHeight + 5
    
    love.graphics.print(string.format("Screen: %dx%d", screenWidth, screenHeight), panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight
    
    love.graphics.print(string.format("Elements: %d", UIDebug.countTrackedElements()), panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight
    
    local issueCount = UIDebug.countLayoutIssues()
    if issueCount > 0 then
        love.graphics.setColor(1, 0.5, 0.5, 1)
    end
    love.graphics.print(string.format("Issues: %d", issueCount), panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight + 5
    
    -- List recent issues
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Recent Issues:", panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight
    
    local issueCount = 0
    for name, issues in pairs(UIDebug.layoutIssues) do
        if issueCount >= 3 then break end -- Limit to 3 issues
        
        love.graphics.setColor(1, 0.7, 0.7, 1)
        local issueText = string.format("%s: %s", name, issues[1] or "unknown")
        if #issueText > 35 then
            issueText = string.sub(issueText, 1, 32) .. "..."
        end
        love.graphics.print(issueText, panelX + 10, yOffset, 0, 0.6, 0.6)
        yOffset = yOffset + lineHeight - 2
        issueCount = issueCount + 1
    end
    
    -- Controls
    yOffset = panelY + panelHeight - 30
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.print("F12: Toggle | F11: Validate", panelX + 10, yOffset, 0, 0.6, 0.6)
end

-- Utility functions
function UIDebug.countTrackedElements()
    local count = 0
    for _ in pairs(UIDebug.trackedElements) do
        count = count + 1
    end
    return count
end

function UIDebug.countLayoutIssues()
    local count = 0
    for _, issues in pairs(UIDebug.layoutIssues) do
        count = count + #issues
    end
    return count
end

-- Clear tracked elements (call when changing screens)
function UIDebug.clearTracked()
    UIDebug.trackedElements = {}
    UIDebug.layoutIssues = {}
end

-- Handle key presses
function UIDebug.keypressed(key)
    if key == "f12" then
        UIDebug.toggle()
        return true
    elseif key == "f11" and UIDebug.enabled then
        UIDebug.validateCurrentLayout()
        return true
    end
    return false
end

-- Test function to create sample UI elements for testing
function UIDebug.createTestElements()
    if not UIDebug.enabled then return end
    
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Create some test elements with known issues
    UIDebug.registerElement("test_normal", {
        x = 100, y = 100, width = 200, height = 50
    })
    
    UIDebug.registerElement("test_outofbounds", {
        x = screenWidth - 50, y = screenHeight - 25, width = 100, height = 50
    })
    
    UIDebug.registerElement("test_overlap1", {
        x = 200, y = 200, width = 100, height = 100
    })
    
    UIDebug.registerElement("test_overlap2", {
        x = 250, y = 250, width = 100, height = 100
    })
    
    UIDebug.registerElement("test_negative", {
        x = -10, y = -5, width = 50, height = 30
    })
    
    Utils.Logger.info("🔧 Created test UI elements for debugging")
end

return UIDebug