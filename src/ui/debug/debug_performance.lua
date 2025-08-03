--[[
    Debug Performance Monitoring for Orbit Jump
    
    This module handles performance metrics, monitoring, and analysis.
--]]

local DebugConfig = require("src.ui.debug.debug_config")
local DebugLogging = require("src.ui.debug.debug_logging")

local DebugPerformance = {}

-- Performance state
DebugPerformance.performanceMetrics = {
    frameTime = 0,
    drawCalls = 0,
    elementCount = 0,
    validationTime = 0,
    memoryUsage = 0,
    history = {}
}
DebugPerformance.lastFrameTime = 0
DebugPerformance.frameCount = 0
DebugPerformance.maxHistorySize = 100

-- Initialize performance monitoring
function DebugPerformance.init()
    DebugPerformance.performanceMetrics = {
        frameTime = 0,
        drawCalls = 0,
        elementCount = 0,
        validationTime = 0,
        memoryUsage = 0,
        history = {}
    }
    DebugPerformance.lastFrameTime = love and love.timer and love.timer.getTime() or os.time()
    DebugPerformance.frameCount = 0
    
    DebugLogging.log(DebugConfig.LogLevel.INFO, "🔧 Performance monitoring initialized")
end

-- Update performance metrics
function DebugPerformance.update(dt)
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    
    -- Update frame time
    DebugPerformance.performanceMetrics.frameTime = dt
    DebugPerformance.lastFrameTime = currentTime
    DebugPerformance.frameCount = DebugPerformance.frameCount + 1
    
    -- Update memory usage
    DebugPerformance.updateMemoryUsage()
    
    -- Add to history
    DebugPerformance.addToHistory()
    
    -- Log performance periodically
    if DebugPerformance.frameCount % 60 == 0 then -- Every 60 frames
        DebugLogging.logPerformance(DebugPerformance.performanceMetrics)
    end
end

-- Update memory usage
function DebugPerformance.updateMemoryUsage()
    -- Try to get memory usage from LÖVE
    if love and love.system then
        local memory = love.system.getMemoryUsage()
        if memory then
            DebugPerformance.performanceMetrics.memoryUsage = memory
        end
    end
    
    -- Fallback: estimate based on tracked elements
    local elementCount = DebugPerformance.performanceMetrics.elementCount
    DebugPerformance.performanceMetrics.memoryUsage = elementCount * 1024 -- Rough estimate
end

-- Add current metrics to history
function DebugPerformance.addToHistory()
    local metrics = {
        frameTime = DebugPerformance.performanceMetrics.frameTime,
        drawCalls = DebugPerformance.performanceMetrics.drawCalls,
        elementCount = DebugPerformance.performanceMetrics.elementCount,
        validationTime = DebugPerformance.performanceMetrics.validationTime,
        memoryUsage = DebugPerformance.performanceMetrics.memoryUsage,
        timestamp = love and love.timer and love.timer.getTime() or os.time()
    }
    
    table.insert(DebugPerformance.performanceMetrics.history, metrics)
    
    -- Keep history manageable
    if #DebugPerformance.performanceMetrics.history > DebugPerformance.maxHistorySize then
        table.remove(DebugPerformance.performanceMetrics.history, 1)
    end
end

-- Set draw call count
function DebugPerformance.setDrawCalls(count)
    DebugPerformance.performanceMetrics.drawCalls = count or 0
end

-- Set element count
function DebugPerformance.setElementCount(count)
    DebugPerformance.performanceMetrics.elementCount = count or 0
end

-- Set validation time
function DebugPerformance.setValidationTime(time)
    DebugPerformance.performanceMetrics.validationTime = time or 0
end

-- Get current performance metrics
function DebugPerformance.getPerformanceMetrics()
    return DebugPerformance.performanceMetrics
end

-- Get performance statistics
function DebugPerformance.getPerformanceStats()
    local history = DebugPerformance.performanceMetrics.history
    if #history == 0 then
        return {
            avgFrameTime = 0,
            minFrameTime = 0,
            maxFrameTime = 0,
            avgDrawCalls = 0,
            avgElementCount = 0,
            avgMemoryUsage = 0,
            totalFrames = 0
        }
    end
    
    local totalFrameTime = 0
    local minFrameTime = math.huge
    local maxFrameTime = 0
    local totalDrawCalls = 0
    local totalElementCount = 0
    local totalMemoryUsage = 0
    
    for _, metrics in ipairs(history) do
        totalFrameTime = totalFrameTime + metrics.frameTime
        minFrameTime = math.min(minFrameTime, metrics.frameTime)
        maxFrameTime = math.max(maxFrameTime, metrics.frameTime)
        totalDrawCalls = totalDrawCalls + metrics.drawCalls
        totalElementCount = totalElementCount + metrics.elementCount
        totalMemoryUsage = totalMemoryUsage + metrics.memoryUsage
    end
    
    local count = #history
    
    return {
        avgFrameTime = totalFrameTime / count,
        minFrameTime = minFrameTime,
        maxFrameTime = maxFrameTime,
        avgDrawCalls = totalDrawCalls / count,
        avgElementCount = totalElementCount / count,
        avgMemoryUsage = totalMemoryUsage / count,
        totalFrames = DebugPerformance.frameCount
    }
end

-- Get performance history
function DebugPerformance.getPerformanceHistory()
    return DebugPerformance.performanceMetrics.history
end

-- Get recent performance data
function DebugPerformance.getRecentPerformance(count)
    count = count or 10
    local history = DebugPerformance.performanceMetrics.history
    local recent = {}
    
    for i = #history - count + 1, #history do
        if i > 0 then
            table.insert(recent, history[i])
        end
    end
    
    return recent
end

-- Check for performance issues
function DebugPerformance.checkPerformanceIssues()
    local stats = DebugPerformance.getPerformanceStats()
    local issues = {}
    
    -- Frame time issues
    if stats.avgFrameTime > 0.016 then -- More than 16ms (60fps threshold)
        table.insert(issues, {
            type = "high_frame_time",
            severity = "warning",
            message = string.format("Average frame time: %.2fms (target: <16ms)", stats.avgFrameTime * 1000)
        })
    end
    
    if stats.maxFrameTime > 0.033 then -- More than 33ms (30fps threshold)
        table.insert(issues, {
            type = "spike_frame_time",
            severity = "error",
            message = string.format("Frame time spike: %.2fms", stats.maxFrameTime * 1000)
        })
    end
    
    -- Draw call issues
    if stats.avgDrawCalls > 1000 then
        table.insert(issues, {
            type = "high_draw_calls",
            severity = "warning",
            message = string.format("High draw calls: %.0f per frame", stats.avgDrawCalls)
        })
    end
    
    -- Memory issues
    if stats.avgMemoryUsage > 50 * 1024 * 1024 then -- More than 50MB
        table.insert(issues, {
            type = "high_memory_usage",
            severity = "warning",
            message = string.format("High memory usage: %.1fMB", stats.avgMemoryUsage / (1024 * 1024))
        })
    end
    
    -- Element count issues
    if stats.avgElementCount > 1000 then
        table.insert(issues, {
            type = "high_element_count",
            severity = "warning",
            message = string.format("High element count: %.0f elements", stats.avgElementCount)
        })
    end
    
    return issues
end

-- Get performance summary
function DebugPerformance.getPerformanceSummary()
    local stats = DebugPerformance.getPerformanceStats()
    local issues = DebugPerformance.checkPerformanceIssues()
    
    return {
        current = DebugPerformance.performanceMetrics,
        stats = stats,
        issues = issues,
        frameCount = DebugPerformance.frameCount,
        historySize = #DebugPerformance.performanceMetrics.history
    }
end

-- Clear performance history
function DebugPerformance.clearHistory()
    DebugPerformance.performanceMetrics.history = {}
    DebugPerformance.frameCount = 0
    DebugLogging.log(DebugConfig.LogLevel.INFO, "Performance history cleared")
end

-- Export performance data
function DebugPerformance.exportPerformanceData()
    return {
        current = DebugPerformance.performanceMetrics,
        stats = DebugPerformance.getPerformanceStats(),
        history = DebugPerformance.performanceMetrics.history,
        issues = DebugPerformance.checkPerformanceIssues(),
        summary = {
            frameCount = DebugPerformance.frameCount,
            historySize = #DebugPerformance.performanceMetrics.history,
            exportTime = os.date("%Y-%m-%d %H:%M:%S")
        }
    }
end

-- Reset performance monitoring
function DebugPerformance.reset()
    DebugPerformance.init()
end

return DebugPerformance 