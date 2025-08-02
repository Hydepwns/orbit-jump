--[[
    ═══════════════════════════════════════════════════════════════════════════
    Performance Monitoring System - Real-time Performance Tracking
    ═══════════════════════════════════════════════════════════════════════════
    
    This system implements comprehensive performance monitoring as outlined in
    the Feedback Integration Plan, tracking FPS, memory usage, load times,
    crashes, and other technical metrics critical for player experience.
--]]

local Utils = require("src.utils.utils")

local PerformanceMonitoring = {}

-- System state
PerformanceMonitoring.isActive = false
PerformanceMonitoring.startTime = 0
PerformanceMonitoring.lastUpdateTime = 0

-- Performance metrics tracking
PerformanceMonitoring.metrics = {
    -- Frame rate tracking
    fps = {
        current = 60,
        average = 60,
        min = 60,
        max = 60,
        samples = {},
        sample_count = 0,
        frame_drops = 0,
        low_fps_events = {},
        target_fps = 60
    },
    
    -- Memory usage tracking
    memory = {
        current_mb = 0,
        peak_mb = 0,
        average_mb = 0,
        samples = {},
        memory_warnings = 0,
        gc_events = {},
        memory_leaks = {}
    },
    
    -- Load time tracking
    load_times = {
        game_startup = 0,
        level_transitions = {},
        asset_loads = {},
        save_loads = {},
        system_inits = {}
    },
    
    -- Error and crash tracking
    errors = {
        crash_count = 0,
        error_count = 0,
        warning_count = 0,
        lua_errors = {},
        system_errors = {},
        recovery_attempts = 0
    },
    
    -- System performance
    system = {
        cpu_usage = 0,
        battery_level = 100,
        thermal_state = "normal",
        available_memory = 0,
        disk_space = 0
    },
    
    -- Network performance (if applicable)
    network = {
        latency = 0,
        packet_loss = 0,
        connection_drops = 0,
        bandwidth_usage = 0
    }
}

-- Performance thresholds and alerts
PerformanceMonitoring.thresholds = {
    fps_critical = 30,      -- FPS below this triggers critical alert
    fps_warning = 45,       -- FPS below this triggers warning
    memory_warning = 256,   -- Memory above this (MB) triggers warning
    memory_critical = 512,  -- Memory above this (MB) triggers critical alert
    load_time_warning = 3,  -- Load times above this (seconds) trigger warning
    load_time_critical = 5, -- Load times above this (seconds) trigger critical
    
    -- Frame drop detection
    frame_drop_threshold = 10, -- Drop of 10+ FPS in 1 second
    sustained_low_fps_duration = 5, -- 5 seconds of low FPS triggers alert
}

-- Performance history for trend analysis
PerformanceMonitoring.history = {
    fps_history = {},
    memory_history = {},
    load_time_history = {},
    max_history_size = 1000
}

-- Performance impact tracking
PerformanceMonitoring.impact = {
    player_actions_during_lag = {},
    quit_during_performance_issue = 0,
    frustration_events = {},
    performance_related_feedback = {}
}

-- Initialize performance monitoring
function PerformanceMonitoring.init()
    PerformanceMonitoring.isActive = true
    PerformanceMonitoring.startTime = love.timer.getTime()
    PerformanceMonitoring.lastUpdateTime = PerformanceMonitoring.startTime
    
    -- Reset current session metrics
    PerformanceMonitoring.resetSessionMetrics()
    
    -- Load historical data
    PerformanceMonitoring.loadHistoricalData()
    
    -- Initialize system monitoring
    PerformanceMonitoring.initSystemMonitoring()
    
    -- Track startup time
    PerformanceMonitoring.trackLoadTime("game_startup", PerformanceMonitoring.startTime)
    
    Utils.Logger.info("⚡ Performance Monitoring System initialized")
    return true
end

-- Reset session-specific metrics
function PerformanceMonitoring.resetSessionMetrics()
    local metrics = PerformanceMonitoring.metrics
    
    -- Reset FPS tracking
    metrics.fps.samples = {}
    metrics.fps.sample_count = 0
    metrics.fps.frame_drops = 0
    metrics.fps.low_fps_events = {}
    
    -- Reset memory tracking
    metrics.memory.samples = {}
    metrics.memory.memory_warnings = 0
    metrics.memory.gc_events = {}
    
    -- Reset error tracking for session
    metrics.errors.recovery_attempts = 0
    
    Utils.Logger.debug("⚡ Session metrics reset")
end

-- Initialize system-level monitoring
function PerformanceMonitoring.initSystemMonitoring()
    -- Get initial system state
    PerformanceMonitoring.updateSystemMetrics()
    
    -- Set up error handling integration
    PerformanceMonitoring.setupErrorHandling()
end

-- Set up error handling integration
function PerformanceMonitoring.setupErrorHandling()
    -- Hook into Love2D error handler if available
    if love.errorhandler then
        local originalErrorHandler = love.errorhandler
        love.errorhandler = function(msg)
            PerformanceMonitoring.trackError("crash", msg, debug.traceback())
            return originalErrorHandler(msg)
        end
    end
    
    -- Set up Lua error tracking
    local function trackLuaError(level, message)
        PerformanceMonitoring.trackError("lua_error", message, debug.traceback("", level + 1))
    end
    
    -- Override error and assert functions to track issues
    local originalError = error
    error = function(msg, level)
        trackLuaError(level or 1, msg)
        return originalError(msg, level)
    end
end

-- Update performance metrics (called each frame)
function PerformanceMonitoring.update(dt)
    if not PerformanceMonitoring.isActive then return end
    
    local currentTime = love.timer.getTime()
    
    -- Update FPS metrics
    PerformanceMonitoring.updateFPSMetrics(dt)
    
    -- Update memory metrics (less frequently)
    if currentTime - PerformanceMonitoring.lastUpdateTime > 1.0 then
        PerformanceMonitoring.updateMemoryMetrics()
        PerformanceMonitoring.updateSystemMetrics()
        PerformanceMonitoring.checkPerformanceThresholds()
        PerformanceMonitoring.lastUpdateTime = currentTime
    end
    
    -- Store performance snapshots for history
    PerformanceMonitoring.updatePerformanceHistory()
end

-- Update FPS tracking
function PerformanceMonitoring.updateFPSMetrics(dt)
    local fps = love.timer.getFPS()
    local metrics = PerformanceMonitoring.metrics.fps
    
    -- Update current FPS
    metrics.current = fps
    
    -- Add to samples
    table.insert(metrics.samples, fps)
    metrics.sample_count = metrics.sample_count + 1
    
    -- Limit sample size
    if #metrics.samples > 300 then -- Keep last 5 seconds at 60 FPS
        table.remove(metrics.samples, 1)
        metrics.sample_count = math.min(metrics.sample_count, 300)
    end
    
    -- Calculate average FPS
    local sum = 0
    for _, sample in ipairs(metrics.samples) do
        sum = sum + sample
    end
    metrics.average = sum / #metrics.samples
    
    -- Update min/max
    metrics.min = math.min(metrics.min, fps)
    metrics.max = math.max(metrics.max, fps)
    
    -- Detect frame drops
    if #metrics.samples >= 2 then
        local prevFPS = metrics.samples[#metrics.samples - 1]
        local fpsDrop = prevFPS - fps
        
        if fpsDrop >= PerformanceMonitoring.thresholds.frame_drop_threshold then
            metrics.frame_drops = metrics.frame_drops + 1
            PerformanceMonitoring.trackFrameDrop(fps, fpsDrop)
        end
    end
    
    -- Track sustained low FPS
    PerformanceMonitoring.trackSustainedLowFPS(fps)
end

-- Track sustained low FPS periods
function PerformanceMonitoring.trackSustainedLowFPS(currentFPS)
    local metrics = PerformanceMonitoring.metrics.fps
    local threshold = PerformanceMonitoring.thresholds.fps_warning
    local currentTime = love.timer.getTime()
    
    -- Check if we're in a low FPS period
    if currentFPS < threshold then
        -- Start tracking or continue existing low FPS event
        if #metrics.low_fps_events == 0 or metrics.low_fps_events[#metrics.low_fps_events].end_time then
            -- Start new low FPS event
            table.insert(metrics.low_fps_events, {
                start_time = currentTime,
                start_fps = currentFPS,
                min_fps = currentFPS,
                end_time = nil
            })
        else
            -- Update existing event
            local event = metrics.low_fps_events[#metrics.low_fps_events]
            event.min_fps = math.min(event.min_fps, currentFPS)
        end
    else
        -- End low FPS period if we were in one
        if #metrics.low_fps_events > 0 and not metrics.low_fps_events[#metrics.low_fps_events].end_time then
            local event = metrics.low_fps_events[#metrics.low_fps_events]
            event.end_time = currentTime
            event.duration = currentTime - event.start_time
            
            -- If it was sustained long enough, trigger alert
            if event.duration >= PerformanceMonitoring.thresholds.sustained_low_fps_duration then
                PerformanceMonitoring.triggerPerformanceAlert("sustained_low_fps", event)
            end
        end
    end
end

-- Track frame drop event
function PerformanceMonitoring.trackFrameDrop(currentFPS, dropAmount)
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("frame_drop", {
            current_fps = currentFPS,
            drop_amount = dropAmount,
            timestamp = love.timer.getTime()
        })
    end
    
    Utils.Logger.warn("⚡ Frame drop detected: %.1f FPS (drop: %.1f)", currentFPS, dropAmount)
end

-- Update memory usage metrics
function PerformanceMonitoring.updateMemoryMetrics()
    local memoryMB = collectgarbage("count") / 1024 -- Convert KB to MB
    local metrics = PerformanceMonitoring.metrics.memory
    
    -- Update current memory
    metrics.current_mb = memoryMB
    
    -- Update peak memory
    metrics.peak_mb = math.max(metrics.peak_mb, memoryMB)
    
    -- Add to samples
    table.insert(metrics.samples, memoryMB)
    
    -- Limit sample size
    if #metrics.samples > 60 then -- Keep last 60 seconds
        table.remove(metrics.samples, 1)
    end
    
    -- Calculate average memory
    local sum = 0
    for _, sample in ipairs(metrics.samples) do
        sum = sum + sample
    end
    metrics.average_mb = sum / #metrics.samples
    
    -- Check for memory warnings
    if memoryMB > PerformanceMonitoring.thresholds.memory_warning then
        PerformanceMonitoring.trackMemoryWarning(memoryMB)
    end
    
    -- Track garbage collection
    local gcBefore = collectgarbage("count")
    collectgarbage("collect")
    local gcAfter = collectgarbage("count")
    
    if gcBefore - gcAfter > 1024 then -- More than 1MB collected
        table.insert(metrics.gc_events, {
            timestamp = love.timer.getTime(),
            memory_before = gcBefore / 1024,
            memory_after = gcAfter / 1024,
            memory_freed = (gcBefore - gcAfter) / 1024
        })
    end
end

-- Update system-level metrics
function PerformanceMonitoring.updateSystemMetrics()
    local metrics = PerformanceMonitoring.metrics.system
    
    -- Battery level (mobile/laptop)
    if love.system and love.system.getPowerInfo then
        local state, percent = love.system.getPowerInfo()
        if percent then
            metrics.battery_level = percent
        end
    end
    
    -- Available memory (system level)
    if love.system and love.system.getProcessorCount then
        -- This is a placeholder - actual system memory would need platform-specific code
        metrics.available_memory = collectgarbage("count") / 1024
    end
end

-- Track load time for various operations
function PerformanceMonitoring.trackLoadTime(operation, startTime, endTime)
    endTime = endTime or love.timer.getTime()
    local duration = endTime - startTime
    
    local loadTimes = PerformanceMonitoring.metrics.load_times
    
    if operation == "game_startup" then
        loadTimes.game_startup = duration
    elseif operation == "level_transition" then
        table.insert(loadTimes.level_transitions, {
            duration = duration,
            timestamp = endTime
        })
    elseif operation == "asset_load" then
        table.insert(loadTimes.asset_loads, {
            duration = duration,
            timestamp = endTime
        })
    elseif operation == "save_load" then
        table.insert(loadTimes.save_loads, {
            duration = duration,
            timestamp = endTime
        })
    elseif operation == "system_init" then
        table.insert(loadTimes.system_inits, {
            duration = duration,
            timestamp = endTime,
            system = "unknown"
        })
    end
    
    -- Check load time thresholds
    if duration > PerformanceMonitoring.thresholds.load_time_warning then
        PerformanceMonitoring.triggerPerformanceAlert("slow_load_time", {
            operation = operation,
            duration = duration
        })
    end
    
    -- Send to analytics
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("load_time", {
            operation = operation,
            duration = duration
        })
    end
    
    Utils.Logger.debug("⚡ Load time tracked: %s = %.2fs", operation, duration)
end

-- Track error or crash
function PerformanceMonitoring.trackError(errorType, message, stackTrace)
    local metrics = PerformanceMonitoring.metrics.errors
    local currentTime = love.timer.getTime()
    
    local errorData = {
        type = errorType,
        message = message,
        stack_trace = stackTrace,
        timestamp = currentTime,
        fps_at_error = PerformanceMonitoring.metrics.fps.current,
        memory_at_error = PerformanceMonitoring.metrics.memory.current_mb
    }
    
    if errorType == "crash" then
        metrics.crash_count = metrics.crash_count + 1
        table.insert(metrics.system_errors, errorData)
    elseif errorType == "lua_error" then
        metrics.error_count = metrics.error_count + 1
        table.insert(metrics.lua_errors, errorData)
    elseif errorType == "warning" then
        metrics.warning_count = metrics.warning_count + 1
    end
    
    -- Send to analytics
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("error_tracked", {
            error_type = errorType,
            message = message,
            fps = errorData.fps_at_error,
            memory = errorData.memory_at_error
        })
    end
    
    Utils.Logger.error("⚡ Error tracked: %s - %s", errorType, message)
end

-- Track memory warning
function PerformanceMonitoring.trackMemoryWarning(memoryMB)
    local metrics = PerformanceMonitoring.metrics.memory
    metrics.memory_warnings = metrics.memory_warnings + 1
    
    PerformanceMonitoring.triggerPerformanceAlert("high_memory_usage", {
        memory_mb = memoryMB,
        threshold = PerformanceMonitoring.thresholds.memory_warning
    })
end

-- Check performance thresholds and trigger alerts
function PerformanceMonitoring.checkPerformanceThresholds()
    local metrics = PerformanceMonitoring.metrics
    
    -- Check FPS thresholds
    if metrics.fps.current < PerformanceMonitoring.thresholds.fps_critical then
        PerformanceMonitoring.triggerPerformanceAlert("critical_fps", {
            fps = metrics.fps.current,
            threshold = PerformanceMonitoring.thresholds.fps_critical
        })
    end
    
    -- Check memory thresholds
    if metrics.memory.current_mb > PerformanceMonitoring.thresholds.memory_critical then
        PerformanceMonitoring.triggerPerformanceAlert("critical_memory", {
            memory_mb = metrics.memory.current_mb,
            threshold = PerformanceMonitoring.thresholds.memory_critical
        })
    end
end

-- Trigger performance alert
function PerformanceMonitoring.triggerPerformanceAlert(alertType, data)
    -- Send to analytics system
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("performance_alert", {
            alert_type = alertType,
            data = data,
            timestamp = love.timer.getTime()
        })
    end
    
    -- Trigger automatic optimization if possible
    PerformanceMonitoring.attemptPerformanceOptimization(alertType, data)
    
    Utils.Logger.warn("⚠️ Performance alert: %s", alertType)
end

-- Attempt automatic performance optimization
function PerformanceMonitoring.attemptPerformanceOptimization(alertType, data)
    local DynamicConfig = Utils.require("src.systems.dynamic_config_system")
    if not DynamicConfig then return end
    
    if alertType == "critical_fps" or alertType == "sustained_low_fps" then
        -- Reduce visual effects
        DynamicConfig.applyConfigurationChange("particle_intensity", 0.5, "performance_optimization")
        DynamicConfig.applyConfigurationChange("screen_glow_intensity", 0.3, "performance_optimization")
        
        Utils.Logger.info("⚡ Applied FPS optimization: reduced visual effects")
        
    elseif alertType == "critical_memory" then
        -- Trigger garbage collection and reduce memory-intensive features
        collectgarbage("collect")
        
        -- Reduce particle systems and history tracking
        DynamicConfig.applyConfigurationChange("particle_intensity", 0.3, "memory_optimization")
        
        Utils.Logger.info("⚡ Applied memory optimization: reduced particle intensity")
    end
    
    PerformanceMonitoring.metrics.errors.recovery_attempts = PerformanceMonitoring.metrics.errors.recovery_attempts + 1
end

-- Update performance history for trend analysis
function PerformanceMonitoring.updatePerformanceHistory()
    local currentTime = love.timer.getTime()
    local history = PerformanceMonitoring.history
    
    -- Add current metrics to history (every 10 seconds)
    if #history.fps_history == 0 or currentTime - history.fps_history[#history.fps_history].timestamp > 10 then
        -- FPS history
        table.insert(history.fps_history, {
            timestamp = currentTime,
            fps = PerformanceMonitoring.metrics.fps.current,
            average_fps = PerformanceMonitoring.metrics.fps.average
        })
        
        -- Memory history
        table.insert(history.memory_history, {
            timestamp = currentTime,
            memory_mb = PerformanceMonitoring.metrics.memory.current_mb,
            average_memory = PerformanceMonitoring.metrics.memory.average_mb
        })
        
        -- Limit history size
        if #history.fps_history > history.max_history_size then
            table.remove(history.fps_history, 1)
        end
        if #history.memory_history > history.max_history_size then
            table.remove(history.memory_history, 1)
        end
    end
end

-- Get current performance report
function PerformanceMonitoring.getPerformanceReport()
    local currentTime = love.timer.getTime()
    local sessionDuration = currentTime - PerformanceMonitoring.startTime
    
    return {
        session_duration = sessionDuration,
        fps = {
            current = PerformanceMonitoring.metrics.fps.current,
            average = PerformanceMonitoring.metrics.fps.average,
            min = PerformanceMonitoring.metrics.fps.min,
            max = PerformanceMonitoring.metrics.fps.max,
            frame_drops = PerformanceMonitoring.metrics.fps.frame_drops,
            low_fps_events = #PerformanceMonitoring.metrics.fps.low_fps_events
        },
        memory = {
            current_mb = PerformanceMonitoring.metrics.memory.current_mb,
            peak_mb = PerformanceMonitoring.metrics.memory.peak_mb,
            average_mb = PerformanceMonitoring.metrics.memory.average_mb,
            gc_events = #PerformanceMonitoring.metrics.memory.gc_events,
            warnings = PerformanceMonitoring.metrics.memory.memory_warnings
        },
        errors = {
            crashes = PerformanceMonitoring.metrics.errors.crash_count,
            errors = PerformanceMonitoring.metrics.errors.error_count,
            warnings = PerformanceMonitoring.metrics.errors.warning_count,
            recovery_attempts = PerformanceMonitoring.metrics.errors.recovery_attempts
        },
        load_times = PerformanceMonitoring.metrics.load_times,
        timestamp = currentTime
    }
end

-- Get performance statistics for analytics
function PerformanceMonitoring.getPerformanceStats()
    return {
        avg_fps = PerformanceMonitoring.metrics.fps.average,
        min_fps = PerformanceMonitoring.metrics.fps.min,
        frame_drops = PerformanceMonitoring.metrics.fps.frame_drops,
        memory_mb = PerformanceMonitoring.metrics.memory.current_mb,
        peak_memory_mb = PerformanceMonitoring.metrics.memory.peak_mb,
        crash_count = PerformanceMonitoring.metrics.errors.crash_count,
        error_count = PerformanceMonitoring.metrics.errors.error_count,
        startup_time = PerformanceMonitoring.metrics.load_times.game_startup
    }
end

-- Save performance data
function PerformanceMonitoring.save()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("performanceMonitoring", {
            metrics = PerformanceMonitoring.metrics,
            history = PerformanceMonitoring.history,
            thresholds = PerformanceMonitoring.thresholds,
            last_save = love.timer.getTime()
        })
    end
end

-- Load historical performance data
function PerformanceMonitoring.loadHistoricalData()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local data = SaveSystem.getData("performanceMonitoring")
        if data then
            -- Load historical trends but reset session metrics
            if data.history then
                PerformanceMonitoring.history = data.history
            end
            
            -- Load persistent error counts
            if data.metrics and data.metrics.errors then
                PerformanceMonitoring.metrics.errors.crash_count = data.metrics.errors.crash_count or 0
                PerformanceMonitoring.metrics.errors.error_count = data.metrics.errors.error_count or 0
            end
            
            Utils.Logger.info("⚡ Historical performance data loaded")
        end
    end
end

-- Clean up and save final data
function PerformanceMonitoring.cleanup()
    if PerformanceMonitoring.isActive then
        PerformanceMonitoring.save()
        PerformanceMonitoring.isActive = false
        Utils.Logger.info("⚡ Performance Monitoring System cleaned up")
    end
end

return PerformanceMonitoring