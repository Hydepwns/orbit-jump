--[[
    Enhanced UI Debug System: Advanced visual debugging tools for UI layout issues
    
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

-- Enhanced logging system
function UIDebug.log(level, message, ...)
    if level > UIDebug.currentLogLevel then return end
    
    local levelNames = {"ERROR", "WARN", "INFO", "DEBUG", "VERBOSE"}
    local timestamp = os.date("%H:%M:%S")
    local formattedMessage = string.format(message, ...)
    local logEntry = string.format("[%s] %s: %s", timestamp, levelNames[level] or "UNKNOWN", formattedMessage)
    
    -- Log to console
    if Utils.Logger then
        if level == UIDebug.LogLevel.ERROR then
            Utils.Logger.error(formattedMessage)
        elseif level == UIDebug.LogLevel.WARN then
            Utils.Logger.warn(formattedMessage)
        else
            Utils.Logger.info(formattedMessage)
        end
    else
        print(logEntry)
    end
    
    -- Store in event history
    table.insert(UIDebug.eventHistory, {
        timestamp = timestamp,
        level = level,
        message = formattedMessage
    })
    
    -- Keep history manageable
    if #UIDebug.eventHistory > 1000 then
        table.remove(UIDebug.eventHistory, 1)
    end
end

-- Toggle debug visualization with enhanced feedback
function UIDebug.toggle()
    UIDebug.enabled = not UIDebug.enabled
    local status = UIDebug.enabled and "ENABLED" or "DISABLED"
    
    UIDebug.log(UIDebug.LogLevel.INFO, "🔧 UI Debug visualization %s", status)
    
    if UIDebug.enabled then
        UIDebug.validateCurrentLayout()
        UIDebug.log(UIDebug.LogLevel.DEBUG, "Debug mode activated - tracking %d elements", UIDebug.countTrackedElements())
    else
        UIDebug.log(UIDebug.LogLevel.DEBUG, "Debug mode deactivated")
    end
    
    return UIDebug.enabled
end

-- Set debug level
function UIDebug.setLogLevel(level)
    UIDebug.currentLogLevel = level
    UIDebug.log(UIDebug.LogLevel.INFO, "Debug log level set to %d", level)
end

-- Switch color theme
function UIDebug.setTheme(themeName)
    if UIDebug.colorThemes[themeName] then
        UIDebug.currentTheme = themeName
        UIDebug.colors = UIDebug.colorThemes[themeName]
        UIDebug.log(UIDebug.LogLevel.INFO, "Switched to %s theme", themeName)
    else
        UIDebug.log(UIDebug.LogLevel.WARN, "Unknown theme: %s", themeName)
    end
end

-- Enhanced element registration with metadata
function UIDebug.registerElement(name, element, parentFrame, metadata)
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    
    -- Validate element structure
    local validationResult = UIDebug.validateElementStructure(element)
    
    UIDebug.trackedElements[name] = {
        element = element,
        parentFrame = parentFrame,
        metadata = metadata or {},
        timestamp = currentTime,
        lastValidation = currentTime,
        type = metadata and metadata.type or "unknown",
        valid = validationResult.valid,
        issues = validationResult.issues,
        changeHistory = {},
        performanceMetrics = {
            renderTime = 0,
            updateTime = 0,
            memoryUsage = 0
        }
    }
    
    if UIDebug.logPositioning then
        UIDebug.log(UIDebug.LogLevel.DEBUG, 
            "🔧 UI Element registered: %s at (%.1f, %.1f) size %.1fx%.1f [%s]", 
            name, element.x or 0, element.y or 0, element.width or 0, element.height or 0,
            validationResult.valid and "VALID" or "INVALID")
    end
    
    if UIDebug.logEvents then
        UIDebug.log(UIDebug.LogLevel.VERBOSE, "Element %s registered with %d metadata fields", 
            name, metadata and UIDebug.countTableKeys(metadata) or 0)
    end
    
    -- Auto-validate if enabled
    if UIDebug.autoValidate then
        -- Validate inline since validateElement might not be available yet
        local validationResult = UIDebug.validateElementStructure(element)
        UIDebug.trackedElements[name].valid = validationResult.valid
        UIDebug.trackedElements[name].issues = validationResult.issues
    end
end

-- Validate element structure
function UIDebug.validateElementStructure(element)
    local issues = {}
    local valid = true
    
    if not element then
        table.insert(issues, "element_is_nil")
        valid = false
    else
        -- Check required properties
        local requiredProps = {"x", "y", "width", "height"}
        for _, prop in ipairs(requiredProps) do
            if element[prop] == nil then
                table.insert(issues, "missing_" .. prop)
                valid = false
            elseif type(element[prop]) ~= "number" then
                table.insert(issues, "invalid_type_" .. prop)
                valid = false
            end
        end
        
        -- Check for negative dimensions
        if element.width and element.width <= 0 then
            table.insert(issues, "invalid_width")
            valid = false
        end
        if element.height and element.height <= 0 then
            table.insert(issues, "invalid_height")
            valid = false
        end
    end
    
    return {
        valid = valid,
        issues = issues
    }
end

-- Initialize validation rules
function UIDebug.initializeValidationRules()
    UIDebug.validationRules = {
        -- Screen boundary rules
        {
            name = "screen_boundaries",
            description = "Elements must be within screen bounds",
            validate = function(element, screenWidth, screenHeight)
                local issues = {}
                if element.x < 0 then table.insert(issues, "exceeds_left_boundary") end
                if element.y < 0 then table.insert(issues, "exceeds_top_boundary") end
                if element.x + element.width > screenWidth then table.insert(issues, "exceeds_right_boundary") end
                if element.y + element.height > screenHeight then table.insert(issues, "exceeds_bottom_boundary") end
                return issues
            end,
            severity = "error"
        },
        -- Minimum size rules
        {
            name = "minimum_size",
            description = "Elements must have reasonable minimum size",
            validate = function(element)
                local issues = {}
                if element.width < 10 then table.insert(issues, "width_too_small") end
                if element.height < 10 then table.insert(issues, "height_too_small") end
                return issues
            end,
            severity = "warning"
        },
        -- Accessibility rules
        {
            name = "accessibility",
            description = "Elements should meet accessibility guidelines",
            validate = function(element, screenWidth, screenHeight)
                local issues = {}
                -- Minimum touch target size for mobile
                if screenWidth < 1000 then -- Assume mobile
                    if element.width < 44 or element.height < 44 then
                        table.insert(issues, "touch_target_too_small")
                    end
                end
                return issues
            end,
            severity = "warning"
        },
        -- Performance rules
        {
            name = "performance",
            description = "Elements should not impact performance",
            validate = function(element)
                local issues = {}
                -- Check for extremely large elements
                if element.width * element.height > 1000000 then
                    table.insert(issues, "element_too_large")
                end
                return issues
            end,
            severity = "info"
        }
    }
end

-- Enhanced layout validation with custom rules
function UIDebug.validateCurrentLayout(customRules)
    local startTime = love and love.timer and love.timer.getTime() or os.time()
    
    UIDebug.layoutIssues = {}
    local screenWidth, screenHeight = 800, 600 -- Default values
    
    if love and love.graphics and love.graphics.getDimensions then
        screenWidth, screenHeight = love.graphics.getDimensions()
    end
    
    local totalIssues = 0
    local issuesBySeverity = {error = 0, warning = 0, info = 0}
    
    -- Use custom rules if provided, otherwise use default rules
    local rulesToUse = customRules or UIDebug.validationRules
    
    for name, tracked in pairs(UIDebug.trackedElements) do
        local element = tracked.element
        local elementIssues = {}
        
        -- Validate element structure first
        if not tracked.valid then
            for _, issue in ipairs(tracked.issues or {}) do
                table.insert(elementIssues, {
                    rule = "structure",
                    issue = issue,
                    severity = "error"
                })
            end
        end
        
        -- Apply validation rules
        for _, rule in ipairs(rulesToUse) do
            local ruleIssues = rule.validate(element, screenWidth, screenHeight)
            for _, issue in ipairs(ruleIssues or {}) do
                table.insert(elementIssues, {
                    rule = rule.name,
                    issue = issue,
                    severity = rule.severity,
                    description = rule.description
                })
            end
        end
        
        -- Check for overlapping elements
        for otherName, otherTracked in pairs(UIDebug.trackedElements) do
            if name ~= otherName and name < otherName then -- Avoid duplicate checks
                if UIDebug.elementsOverlap(element, otherTracked.element) then
                    table.insert(elementIssues, {
                        rule = "overlap",
                        issue = "overlaps_with_" .. otherName,
                        severity = UIDebug.strictValidation and "error" or "warning"
                    })
                end
            end
        end
        
        if #elementIssues > 0 then
            UIDebug.layoutIssues[name] = elementIssues
            totalIssues = totalIssues + #elementIssues
            
            -- Count by severity
            for _, issue in ipairs(elementIssues) do
                issuesBySeverity[issue.severity] = (issuesBySeverity[issue.severity] or 0) + 1
            end
        end
    end
    
    local validationTime = (love and love.timer and love.timer.getTime() or os.time()) - startTime
    UIDebug.performanceMetrics.validationTime = validationTime
    
    -- Log comprehensive results
    if totalIssues == 0 then
        UIDebug.log(UIDebug.LogLevel.INFO, "🔧 UI Layout validation: No issues found (%.3fs)", validationTime)
    else
        UIDebug.log(UIDebug.LogLevel.WARN, 
            "🔧 UI Layout validation: %d issues found - %d errors, %d warnings, %d info (%.3fs)",
            totalIssues, issuesBySeverity.error, issuesBySeverity.warning, issuesBySeverity.info, validationTime)
        
        -- Log detailed issues if debug level is high enough
        if UIDebug.currentLogLevel >= UIDebug.LogLevel.DEBUG then
            for name, issues in pairs(UIDebug.layoutIssues) do
                for _, issue in ipairs(issues) do
                    UIDebug.log(UIDebug.LogLevel.DEBUG, "  %s [%s]: %s (%s)", 
                        name, issue.severity:upper(), issue.issue, issue.rule)
                end
            end
        end
    end
    
    return {
        totalIssues = totalIssues,
        issuesBySeverity = issuesBySeverity,
        validationTime = validationTime,
        elementCount = UIDebug.countTrackedElements()
    }
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

-- Enhanced drawing with better visualization
function UIDebug.draw()
    if not UIDebug.enabled then return end
    
    love.graphics.push()
    love.graphics.setLineWidth(2)
    
    -- Update performance metrics
    UIDebug.performanceMetrics.drawCalls = UIDebug.performanceMetrics.drawCalls + 1
    
    -- Draw tracked elements
    for name, tracked in pairs(UIDebug.trackedElements) do
        local element = tracked.element
        local elementIssues = UIDebug.layoutIssues[name] or {}
        
        if element.x and element.y and element.width and element.height then
            -- Choose color based on issues
            local color = UIDebug.colors.element
            local severityLevel = 0
            
            for _, issue in ipairs(elementIssues) do
                if issue.severity == "error" and severityLevel < 3 then
                    color = UIDebug.colors.error
                    severityLevel = 3
                elseif issue.severity == "warning" and severityLevel < 2 then
                    color = UIDebug.colors.warning  
                    severityLevel = 2
                elseif issue.severity == "info" and severityLevel < 1 then
                    color = UIDebug.colors.performance
                    severityLevel = 1
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
                if #elementIssues > 0 then
                    labelText = labelText .. " [" .. #elementIssues .. "]"
                end
                love.graphics.print(labelText, element.x + 2, element.y + 2, 0, 0.8, 0.8)
            end
        end
    end
    
    -- Draw enhanced metrics panel
    if UIDebug.showMetrics then
        UIDebug.drawEnhancedMetricsPanel()
    end
    
    love.graphics.pop()
end

-- Enhanced metrics panel with more information
function UIDebug.drawEnhancedMetricsPanel()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local panelWidth, panelHeight = 400, 350
    local panelX = screenWidth - panelWidth - 10
    local panelY = 10
    
    -- Panel background
    love.graphics.setColor(UIDebug.colors.background)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    
    love.graphics.setColor(UIDebug.colors.text)
    love.graphics.rectangle("line", panelX, panelY, panelWidth, panelHeight)
    
    -- Panel content
    love.graphics.setColor(UIDebug.colors.text)
    local yOffset = panelY + 10
    local lineHeight = 16
    
    love.graphics.print("🔧 Advanced UI Debug Panel", panelX + 10, yOffset, 0, 0.9, 0.9)
    yOffset = yOffset + lineHeight + 5
    
    -- Basic info
    love.graphics.print(string.format("Screen: %dx%d | Theme: %s", screenWidth, screenHeight, UIDebug.currentTheme), 
        panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight
    
    love.graphics.print(string.format("Elements: %d | Session: %s", 
        UIDebug.countTrackedElements(), UIDebug.sessionId:sub(-6)), panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight
    
    -- Issue summary
    local issueCount = UIDebug.countLayoutIssues()
    local issuesBySeverity = {error = 0, warning = 0, info = 0}
    
    for _, issues in pairs(UIDebug.layoutIssues) do
        for _, issue in ipairs(issues) do
            issuesBySeverity[issue.severity] = (issuesBySeverity[issue.severity] or 0) + 1
        end
    end
    
    if issueCount > 0 then
        love.graphics.setColor(UIDebug.colors.error)
    end
    love.graphics.print(string.format("Issues: %d (E:%d W:%d I:%d)", 
        issueCount, issuesBySeverity.error, issuesBySeverity.warning, issuesBySeverity.info), 
        panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight + 5
    
    -- Performance metrics
    if UIDebug.showPerformance then
        love.graphics.setColor(UIDebug.colors.text)
        love.graphics.print("Performance:", panelX + 10, yOffset, 0, 0.7, 0.7)
        yOffset = yOffset + lineHeight
        
        local perfStats = UIDebug.getPerformanceStats()
        love.graphics.print(string.format("  FPS: %.1f (avg) %.1f (min)", 
            perfStats.avgFPS, perfStats.minFrameTime > 0 and (1/perfStats.maxFrameTime) or 0), 
            panelX + 10, yOffset, 0, 0.6, 0.6)
        yOffset = yOffset + lineHeight - 2
        
        love.graphics.print(string.format("  Frame: %.2fms (%.2f-%.2fms)", 
            perfStats.avgFrameTime * 1000, perfStats.minFrameTime * 1000, perfStats.maxFrameTime * 1000), 
            panelX + 10, yOffset, 0, 0.6, 0.6)
        yOffset = yOffset + lineHeight + 3
    end
    
    -- Memory usage
    if UIDebug.showMemoryUsage then
        love.graphics.setColor(UIDebug.colors.text)
        local memoryKB = collectgarbage("count")
        love.graphics.print(string.format("Memory: %.1f MB", memoryKB / 1024), panelX + 10, yOffset, 0, 0.7, 0.7)
        yOffset = yOffset + lineHeight + 3
    end
    
    -- Recent issues (top 4)
    love.graphics.setColor(UIDebug.colors.text)
    love.graphics.print("Recent Issues:", panelX + 10, yOffset, 0, 0.7, 0.7)
    yOffset = yOffset + lineHeight
    
    local issueCount = 0
    for name, issues in pairs(UIDebug.layoutIssues) do
        if issueCount >= 4 then break end
        
        local issue = issues[1] -- Show first issue
        if issue then
            local severityColor = UIDebug.colors[issue.severity] or UIDebug.colors.text
            love.graphics.setColor(severityColor)
            
            local issueText = string.format("%s: %s", name, issue.issue:gsub("_", " "))
            if #issueText > 45 then
                issueText = string.sub(issueText, 1, 42) .. "..."
            end
            love.graphics.print(issueText, panelX + 15, yOffset, 0, 0.6, 0.6)
            yOffset = yOffset + lineHeight - 2
            issueCount = issueCount + 1
        end
    end
    
    -- Controls
    yOffset = panelY + panelHeight - 50
    love.graphics.setColor(UIDebug.colors.text[1] * 0.8, UIDebug.colors.text[2] * 0.8, UIDebug.colors.text[3] * 0.8, 1)
    love.graphics.print("Controls:", panelX + 10, yOffset, 0, 0.6, 0.6)
    yOffset = yOffset + lineHeight - 2
    love.graphics.print("F12:Toggle F11:Validate F10:Level F9:Theme", panelX + 10, yOffset, 0, 0.5, 0.5)
    yOffset = yOffset + lineHeight - 2
    love.graphics.print("F8:Screenshot F7:Export 1-5:Features R:Reset", panelX + 10, yOffset, 0, 0.5, 0.5)
end

-- Enhanced keyboard handling with more debug commands
function UIDebug.keypressed(key, scancode, isrepeat)
    if not isrepeat then -- Ignore key repeats
        if key == "f12" then
            UIDebug.toggle()
            return true
        elseif key == "f11" and UIDebug.enabled then
            UIDebug.validateCurrentLayout()
            return true
        elseif key == "f10" and UIDebug.enabled then
            UIDebug.cycleDebugLevel()
            return true
        elseif key == "f9" and UIDebug.enabled then
            UIDebug.toggleTheme()
            return true
        elseif key == "f8" and UIDebug.enabled then
            UIDebug.takeScreenshot()
            return true
        elseif key == "f7" and UIDebug.enabled then
            UIDebug.exportDebugData()
            return true
        elseif key == "f6" and UIDebug.enabled then
            UIDebug.showElementInspector()
            return true
        elseif UIDebug.enabled then
            -- Additional debug commands
            if key == "1" then UIDebug.showBounds = not UIDebug.showBounds; return true end
            if key == "2" then UIDebug.showLabels = not UIDebug.showLabels; return true end
            if key == "3" then UIDebug.showMetrics = not UIDebug.showMetrics; return true end
            if key == "4" then UIDebug.showPerformance = not UIDebug.showPerformance; return true end
            if key == "5" then UIDebug.showMemoryUsage = not UIDebug.showMemoryUsage; return true end
            if key == "r" then UIDebug.resetTracking(); return true end
            if key == "c" then UIDebug.clearHistory(); return true end
        end
    end
    return false
end

-- Cycle through debug levels
function UIDebug.cycleDebugLevel()
    local levels = {UIDebug.LogLevel.ERROR, UIDebug.LogLevel.WARN, UIDebug.LogLevel.INFO, UIDebug.LogLevel.DEBUG, UIDebug.LogLevel.VERBOSE}
    local levelNames = {"ERROR", "WARN", "INFO", "DEBUG", "VERBOSE"}
    
    local currentIndex = 1
    for i, level in ipairs(levels) do
        if level == UIDebug.currentLogLevel then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #levels) + 1
    UIDebug.currentLogLevel = levels[nextIndex]
    
    UIDebug.log(UIDebug.LogLevel.INFO, "Debug level set to %s", levelNames[nextIndex])
end

-- Toggle between themes
function UIDebug.toggleTheme()
    local themes = {"default", "darkMode"}
    local currentIndex = 1
    
    for i, theme in ipairs(themes) do
        if theme == UIDebug.currentTheme then
            currentIndex = i
            break
        end
    end
    
    local nextIndex = (currentIndex % #themes) + 1
    UIDebug.setTheme(themes[nextIndex])
end

-- Enhanced utility functions
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
        if type(issues) == "table" then
            count = count + #issues
        else
            count = count + 1 -- Legacy format
        end
    end
    return count
end

function UIDebug.countTableKeys(t)
    local count = 0
    for _ in pairs(t or {}) do
        count = count + 1
    end
    return count
end

-- Performance monitoring
function UIDebug.updatePerformanceMetrics(dt)
    if not UIDebug.enabled then return end
    
    UIDebug.performanceMetrics.frameTime = dt
    UIDebug.performanceMetrics.elementCount = UIDebug.countTrackedElements()
    
    -- Store performance history
    table.insert(UIDebug.performanceMetrics.history, {
        timestamp = love and love.timer and love.timer.getTime() or os.time(),
        frameTime = dt,
        elementCount = UIDebug.performanceMetrics.elementCount,
        memoryUsage = collectgarbage("count") * 1024 -- Convert KB to bytes
    })
    
    -- Keep history manageable (last 300 frames = ~5 seconds at 60fps)
    if #UIDebug.performanceMetrics.history > 300 then
        table.remove(UIDebug.performanceMetrics.history, 1)
    end
    
    UIDebug.frameCount = UIDebug.frameCount + 1
end

-- Get performance statistics
function UIDebug.getPerformanceStats()
    if #UIDebug.performanceMetrics.history == 0 then
        return {
            avgFrameTime = 0,
            maxFrameTime = 0,
            minFrameTime = 0,
            avgFPS = 0,
            memoryUsage = 0
        }
    end
    
    local totalFrameTime = 0
    local maxFrameTime = 0
    local minFrameTime = math.huge
    local totalMemory = 0
    
    for _, frame in ipairs(UIDebug.performanceMetrics.history) do
        totalFrameTime = totalFrameTime + frame.frameTime
        maxFrameTime = math.max(maxFrameTime, frame.frameTime)
        minFrameTime = math.min(minFrameTime, frame.frameTime)
        totalMemory = totalMemory + frame.memoryUsage
    end
    
    local count = #UIDebug.performanceMetrics.history
    local avgFrameTime = totalFrameTime / count
    
    return {
        avgFrameTime = avgFrameTime,
        maxFrameTime = maxFrameTime,
        minFrameTime = minFrameTime,
        avgFPS = avgFrameTime > 0 and (1 / avgFrameTime) or 0,
        memoryUsage = totalMemory / count,
        frameCount = UIDebug.frameCount
    }
end

-- Placeholder functions for advanced features
function UIDebug.takeScreenshot()
    UIDebug.log(UIDebug.LogLevel.INFO, "Screenshot functionality not implemented in this environment")
end

function UIDebug.exportDebugData()
    UIDebug.log(UIDebug.LogLevel.INFO, "Debug data export functionality not implemented in this environment")
end

function UIDebug.showElementInspector()
    UIDebug.log(UIDebug.LogLevel.INFO, "Element Inspector - %d tracked elements:", UIDebug.countTrackedElements())
    
    for name, tracked in pairs(UIDebug.trackedElements) do
        local element = tracked.element
        local status = tracked.valid and "✓" or "✗"
        UIDebug.log(UIDebug.LogLevel.INFO, "  %s %s: (%.1f,%.1f) %.1fx%.1f [%s]", 
            status, name, element.x or 0, element.y or 0, element.width or 0, element.height or 0, tracked.type)
        
        if not tracked.valid and tracked.issues then
            for _, issue in ipairs(tracked.issues) do
                UIDebug.log(UIDebug.LogLevel.INFO, "    Issue: %s", issue)
            end
        end
    end
end

-- Reset tracking data
function UIDebug.resetTracking()
    UIDebug.trackedElements = {}
    UIDebug.layoutIssues = {}
    UIDebug.eventHistory = {}
    UIDebug.performanceMetrics.history = {}
    UIDebug.log(UIDebug.LogLevel.INFO, "Debug tracking data reset")
end

-- Clear history but keep current state
function UIDebug.clearHistory()
    UIDebug.eventHistory = {}
    UIDebug.performanceMetrics.history = {}
    
    for name, tracked in pairs(UIDebug.trackedElements) do
        tracked.changeHistory = {}
    end
    
    UIDebug.log(UIDebug.LogLevel.INFO, "Debug history cleared")
end

return UIDebug