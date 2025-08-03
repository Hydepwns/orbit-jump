--[[
    Debug Logging for Orbit Jump
    
    This module handles debug logging, event history, and session management.
--]]

local DebugConfig = require("src.ui.debug.debug_config")

local DebugLogging = {}

-- Logging state
DebugLogging.currentLogLevel = DebugConfig.LogLevel.INFO
DebugLogging.eventHistory = {}
DebugLogging.sessionId = tostring(os.time())
DebugLogging.logFile = "ui_debug_" .. DebugLogging.sessionId .. ".log"
DebugLogging.maxHistorySize = 1000

-- Initialize logging system
function DebugLogging.init()
    DebugLogging.sessionId = tostring(os.time())
    DebugLogging.logFile = "ui_debug_" .. DebugLogging.sessionId .. ".log"
    DebugLogging.eventHistory = {}
    
    DebugLogging.log(DebugConfig.LogLevel.INFO, "🔧 Debug logging system initialized")
    DebugLogging.log(DebugConfig.LogLevel.DEBUG, "Session ID: %s, Log level: %d", 
        DebugLogging.sessionId, DebugLogging.currentLogLevel)
end

-- Enhanced logging system
function DebugLogging.log(level, message, ...)
    if not DebugConfig.shouldLog(DebugLogging.currentLogLevel, level) then 
        return 
    end
    
    local levelName = DebugConfig.getLogLevelName(level)
    local timestamp = os.date("%H:%M:%S")
    local formattedMessage = string.format(message, ...)
    local logEntry = string.format("[%s] %s: %s", timestamp, levelName, formattedMessage)
    
    -- Log to console
    DebugLogging.logToConsole(level, formattedMessage)
    
    -- Store in event history
    DebugLogging.addToHistory(timestamp, level, formattedMessage)
    
    -- Write to file if enabled
    DebugLogging.writeToFile(logEntry)
end

-- Log to console with appropriate level
function DebugLogging.logToConsole(level, message)
    -- Try to use Utils.Logger if available
    local Utils = require("src.utils.utils")
    if Utils and Utils.Logger then
        if level == DebugConfig.LogLevel.ERROR then
            Utils.Logger.error(message)
        elseif level == DebugConfig.LogLevel.WARN then
            Utils.Logger.warn(message)
        else
            Utils.Logger.info(message)
        end
    else
        -- Fallback to print
        print(string.format("[%s] %s", DebugConfig.getLogLevelName(level), message))
    end
end

-- Add entry to event history
function DebugLogging.addToHistory(timestamp, level, message)
    table.insert(DebugLogging.eventHistory, {
        timestamp = timestamp,
        level = level,
        message = message
    })
    
    -- Keep history manageable
    if #DebugLogging.eventHistory > DebugLogging.maxHistorySize then
        table.remove(DebugLogging.eventHistory, 1)
    end
end

-- Write log entry to file
function DebugLogging.writeToFile(logEntry)
    if love and love.filesystem then
        local success, err = pcall(function()
            love.filesystem.append(DebugLogging.logFile, logEntry .. "\n")
        end)
        
        if not success then
            print("Failed to write to log file: " .. tostring(err))
        end
    end
end

-- Set log level
function DebugLogging.setLogLevel(level)
    DebugLogging.currentLogLevel = level
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Debug log level set to %d (%s)", 
        level, DebugConfig.getLogLevelName(level))
end

-- Get current log level
function DebugLogging.getLogLevel()
    return DebugLogging.currentLogLevel
end

-- Get log level name
function DebugLogging.getLogLevelName()
    return DebugConfig.getLogLevelName(DebugLogging.currentLogLevel)
end

-- Get event history
function DebugLogging.getEventHistory()
    return DebugLogging.eventHistory
end

-- Get filtered event history
function DebugLogging.getFilteredHistory(level, maxEntries)
    local filtered = {}
    local count = 0
    maxEntries = maxEntries or 50
    
    for i = #DebugLogging.eventHistory, 1, -1 do
        local entry = DebugLogging.eventHistory[i]
        if entry.level <= level then
            table.insert(filtered, 1, entry)
            count = count + 1
            if count >= maxEntries then
                break
            end
        end
    end
    
    return filtered
end

-- Get recent events
function DebugLogging.getRecentEvents(count)
    count = count or 10
    local recent = {}
    
    for i = #DebugLogging.eventHistory - count + 1, #DebugLogging.eventHistory do
        if i > 0 then
            table.insert(recent, DebugLogging.eventHistory[i])
        end
    end
    
    return recent
end

-- Get events by level
function DebugLogging.getEventsByLevel(level)
    local events = {}
    
    for _, entry in ipairs(DebugLogging.eventHistory) do
        if entry.level == level then
            table.insert(events, entry)
        end
    end
    
    return events
end

-- Get error events
function DebugLogging.getErrorEvents()
    return DebugLogging.getEventsByLevel(DebugConfig.LogLevel.ERROR)
end

-- Get warning events
function DebugLogging.getWarningEvents()
    return DebugLogging.getEventsByLevel(DebugConfig.LogLevel.WARN)
end

-- Get session information
function DebugLogging.getSessionInfo()
    return {
        sessionId = DebugLogging.sessionId,
        logFile = DebugLogging.logFile,
        currentLevel = DebugLogging.currentLogLevel,
        levelName = DebugLogging.getLogLevelName(),
        totalEvents = #DebugLogging.eventHistory,
        errorCount = #DebugLogging.getErrorEvents(),
        warningCount = #DebugLogging.getWarningEvents()
    }
end

-- Clear event history
function DebugLogging.clearHistory()
    DebugLogging.eventHistory = {}
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Event history cleared")
end

-- Export event history
function DebugLogging.exportHistory()
    local export = {
        sessionInfo = DebugLogging.getSessionInfo(),
        events = DebugLogging.eventHistory,
        exportTime = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    return export
end

-- Log performance metrics
function DebugLogging.logPerformance(metrics)
    DebugLogging.log(DebugConfig.LogLevel.DEBUG, 
        "Performance: Frame=%.2fms, DrawCalls=%d, Elements=%d, Memory=%.1fKB",
        metrics.frameTime * 1000, metrics.drawCalls, metrics.elementCount, 
        metrics.memoryUsage / 1024)
end

-- Log element registration
function DebugLogging.logElementRegistration(name, element, valid)
    DebugLogging.log(DebugConfig.LogLevel.DEBUG, 
        "🔧 UI Element registered: %s at (%.1f, %.1f) size %.1fx%.1f [%s]", 
        name, element.x or 0, element.y or 0, element.width or 0, element.height or 0,
        valid and "VALID" or "INVALID")
end

-- Log validation issues
function DebugLogging.logValidationIssues(elementName, issues)
    if #issues > 0 then
        DebugLogging.log(DebugConfig.LogLevel.WARN, 
            "Validation issues for %s: %s", elementName, table.concat(issues, ", "))
    end
end

-- Log layout validation
function DebugLogging.logLayoutValidation(issueCount, totalElements)
    DebugLogging.log(DebugConfig.LogLevel.INFO, 
        "Layout validation complete: %d issues found in %d elements", 
        issueCount, totalElements)
end

-- Log theme change
function DebugLogging.logThemeChange(themeName)
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Switched to %s theme", themeName)
end

-- Log debug toggle
function DebugLogging.logDebugToggle(enabled)
    local status = enabled and "ENABLED" or "DISABLED"
    DebugLogging.log(DebugConfig.LogLevel.INFO, "🔧 UI Debug visualization %s", status)
end

return DebugLogging 