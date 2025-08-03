-- Performance Metrics Module
-- Handles performance data collection and analysis
local Utils = require("src.utils.utils")
local PerformanceMetrics = {}
-- Performance metrics tracking
PerformanceMetrics.metrics = {
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
PerformanceMetrics.thresholds = {
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
PerformanceMetrics.history = {
  fps_history = {},
  memory_history = {},
  error_history = {},
  load_time_history = {}
}
-- Initialize performance metrics
function PerformanceMetrics.init()
  PerformanceMetrics.resetMetrics()
  PerformanceMetrics.startTime = love.timer.getTime()
  Utils.Logger.info("Performance metrics initialized")
end
-- Reset all metrics
function PerformanceMetrics.resetMetrics()
  PerformanceMetrics.metrics = {
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
    memory = {
      current_mb = 0,
      peak_mb = 0,
      average_mb = 0,
      samples = {},
      memory_warnings = 0,
      gc_events = {},
      memory_leaks = {}
    },
    load_times = {
      game_startup = 0,
      level_transitions = {},
      asset_loads = {},
      save_loads = {},
      system_inits = {}
    },
    errors = {
      crash_count = 0,
      error_count = 0,
      warning_count = 0,
      lua_errors = {},
      system_errors = {},
      recovery_attempts = 0
    },
    system = {
      cpu_usage = 0,
      battery_level = 100,
      thermal_state = "normal",
      available_memory = 0,
      disk_space = 0
    },
    network = {
      latency = 0,
      packet_loss = 0,
      connection_drops = 0,
      bandwidth_usage = 0
    }
  }
  PerformanceMetrics.history = {
    fps_history = {},
    memory_history = {},
    error_history = {},
    load_time_history = {}
  }
end
-- Update FPS metrics
function PerformanceMetrics.updateFPS(currentFPS)
  local fps = PerformanceMetrics.metrics.fps
  fps.current = currentFPS
  -- Add to samples
  table.insert(fps.samples, currentFPS)
  fps.sample_count = fps.sample_count + 1
  -- Keep only last 60 samples (1 second at 60 FPS)
  if #fps.samples > 60 then
    table.remove(fps.samples, 1)
  end
  -- Calculate statistics
  local sum = 0
  local min = math.huge
  local max = 0
  for _, sample in ipairs(fps.samples) do
    sum = sum + sample
    min = math.min(min, sample)
    max = math.max(max, sample)
  end
  fps.average = sum / #fps.samples
  fps.min = min
  fps.max = max
  -- Detect frame drops
  if currentFPS < fps.target_fps - PerformanceMetrics.thresholds.frame_drop_threshold then
    fps.frame_drops = fps.frame_drops + 1
  end
  -- Check for sustained low FPS
  local lowFPSCount = 0
  for _, sample in ipairs(fps.samples) do
    if sample < PerformanceMetrics.thresholds.fps_warning then
      lowFPSCount = lowFPSCount + 1
    end
  end
  if lowFPSCount >= PerformanceMetrics.thresholds.sustained_low_fps_duration then
    table.insert(fps.low_fps_events, {
      time = love.timer.getTime(),
      duration = lowFPSCount,
      average_fps = fps.average
    })
    -- Limit low_fps_events to prevent unbounded growth
    local MAX_LOW_FPS_EVENTS = 100
    if #fps.low_fps_events > MAX_LOW_FPS_EVENTS then
      table.remove(fps.low_fps_events, 1)
    end
  end
  -- Add to history with bounds checking
  table.insert(PerformanceMetrics.history.fps_history, {
    time = love.timer.getTime(),
    fps = currentFPS,
    average = fps.average
  })
  -- Keep history bounded to prevent memory issues
  local MAX_FPS_HISTORY = 3600 -- 1 hour at 1 sample per second
  if #PerformanceMetrics.history.fps_history > MAX_FPS_HISTORY then
    table.remove(PerformanceMetrics.history.fps_history, 1)
  end
end
-- Update memory metrics
function PerformanceMetrics.updateMemory()
  local memory = PerformanceMetrics.metrics.memory
  -- Get current memory usage (approximate)
  local info = collectgarbage("count")
  memory.current_mb = info / 1024 -- Convert KB to MB
  -- Update peak
  if memory.current_mb > memory.peak_mb then
    memory.peak_mb = memory.current_mb
  end
  -- Add to samples
  table.insert(memory.samples, memory.current_mb)
  -- Keep only last 60 samples
  if #memory.samples > 60 then
    table.remove(memory.samples, 1)
  end
  -- Calculate average
  local sum = 0
  for _, sample in ipairs(memory.samples) do
    sum = sum + sample
  end
  memory.average_mb = sum / #memory.samples
  -- Check for memory warnings
  if memory.current_mb > PerformanceMetrics.thresholds.memory_critical then
    memory.memory_warnings = memory.memory_warnings + 1
    table.insert(memory.gc_events, {
      time = love.timer.getTime(),
      memory_before = memory.current_mb,
      type = "critical"
    })
    -- Limit gc_events to prevent unbounded growth
    local MAX_GC_EVENTS = 100
    if #memory.gc_events > MAX_GC_EVENTS then
      table.remove(memory.gc_events, 1)
    end
  elseif memory.current_mb > PerformanceMetrics.thresholds.memory_warning then
    memory.memory_warnings = memory.memory_warnings + 1
    table.insert(memory.gc_events, {
      time = love.timer.getTime(),
      memory_before = memory.current_mb,
      type = "warning"
    })
    -- Limit gc_events to prevent unbounded growth
    local MAX_GC_EVENTS = 100
    if #memory.gc_events > MAX_GC_EVENTS then
      table.remove(memory.gc_events, 1)
    end
  end
  -- Add to history with bounds checking
  table.insert(PerformanceMetrics.history.memory_history, {
    time = love.timer.getTime(),
    memory_mb = memory.current_mb,
    peak_mb = memory.peak_mb
  })
  -- Keep history bounded to prevent memory issues
  local MAX_MEMORY_HISTORY = 3600 -- 1 hour at 1 sample per second
  if #PerformanceMetrics.history.memory_history > MAX_MEMORY_HISTORY then
    table.remove(PerformanceMetrics.history.memory_history, 1)
  end
end
-- Record load time
function PerformanceMetrics.recordLoadTime(loadType, duration)
  local loadTimes = PerformanceMetrics.metrics.load_times
  if loadType == "startup" then
    loadTimes.game_startup = duration
  elseif loadType == "level" then
    table.insert(loadTimes.level_transitions, {
      time = love.timer.getTime(),
      duration = duration
    })
    -- Limit level_transitions to prevent unbounded growth
    local MAX_LEVEL_TRANSITIONS = 100
    if #loadTimes.level_transitions > MAX_LEVEL_TRANSITIONS then
      table.remove(loadTimes.level_transitions, 1)
    end
  elseif loadType == "asset" then
    table.insert(loadTimes.asset_loads, {
      time = love.timer.getTime(),
      duration = duration
    })
    -- Limit asset_loads to prevent unbounded growth
    local MAX_ASSET_LOADS = 100
    if #loadTimes.asset_loads > MAX_ASSET_LOADS then
      table.remove(loadTimes.asset_loads, 1)
    end
  elseif loadType == "save" then
    table.insert(loadTimes.save_loads, {
      time = love.timer.getTime(),
      duration = duration
    })
    -- Limit save_loads to prevent unbounded growth
    local MAX_SAVE_LOADS = 100
    if #loadTimes.save_loads > MAX_SAVE_LOADS then
      table.remove(loadTimes.save_loads, 1)
    end
  elseif loadType == "system" then
    table.insert(loadTimes.system_inits, {
      time = love.timer.getTime(),
      duration = duration
    })
    -- Limit system_inits to prevent unbounded growth
    local MAX_SYSTEM_INITS = 100
    if #loadTimes.system_inits > MAX_SYSTEM_INITS then
      table.remove(loadTimes.system_inits, 1)
    end
  end
  -- Add to history with bounds checking
  table.insert(PerformanceMetrics.history.load_time_history, {
    time = love.timer.getTime(),
    type = loadType,
    duration = duration
  })
  -- Keep history bounded to prevent memory issues
  local MAX_LOAD_TIME_HISTORY = 1000
  if #PerformanceMetrics.history.load_time_history > MAX_LOAD_TIME_HISTORY then
    table.remove(PerformanceMetrics.history.load_time_history, 1)
  end
end
-- Record error
function PerformanceMetrics.recordError(errorType, message, stackTrace)
  local errors = PerformanceMetrics.metrics.errors
  if errorType == "crash" then
    errors.crash_count = errors.crash_count + 1
  elseif errorType == "error" then
    errors.error_count = errors.error_count + 1
  elseif errorType == "warning" then
    errors.warning_count = errors.warning_count + 1
  end
  local errorData = {
    time = love.timer.getTime(),
    type = errorType,
    message = message,
    stack_trace = stackTrace
  }
  if errorType == "lua_error" then
    table.insert(errors.lua_errors, errorData)
    -- Limit lua_errors to prevent unbounded growth
    local MAX_LUA_ERRORS = 100
    if #errors.lua_errors > MAX_LUA_ERRORS then
      table.remove(errors.lua_errors, 1)
    end
  else
    table.insert(errors.system_errors, errorData)
    -- Limit system_errors to prevent unbounded growth
    local MAX_SYSTEM_ERRORS = 100
    if #errors.system_errors > MAX_SYSTEM_ERRORS then
      table.remove(errors.system_errors, 1)
    end
  end
  -- Add to history with bounds checking
  table.insert(PerformanceMetrics.history.error_history, errorData)
  -- Keep history bounded to prevent memory issues
  local MAX_ERROR_HISTORY = 1000
  if #PerformanceMetrics.history.error_history > MAX_ERROR_HISTORY then
    table.remove(PerformanceMetrics.history.error_history, 1)
  end
end
-- Update system metrics
function PerformanceMetrics.updateSystemMetrics()
  local system = PerformanceMetrics.metrics.system
  -- These would be platform-specific implementations
  -- For now, we'll use placeholder values
  -- CPU usage (would need platform-specific code)
  system.cpu_usage = 0 -- Placeholder
  -- Battery level (mobile only)
  if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
    -- Would need platform-specific battery API
    system.battery_level = 100 -- Placeholder
  end
  -- Thermal state (mobile only)
  if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
    -- Would need platform-specific thermal API
    system.thermal_state = "normal" -- Placeholder
  end
  -- Available memory
  system.available_memory = collectgarbage("count") / 1024 -- MB
  -- Disk space (would need platform-specific code)
  system.disk_space = 0 -- Placeholder
end
-- Get performance summary
function PerformanceMetrics.getSummary()
  local fps = PerformanceMetrics.metrics.fps
  local memory = PerformanceMetrics.metrics.memory
  local errors = PerformanceMetrics.metrics.errors
  return {
    fps = {
      current = fps.current,
      average = fps.average,
      min = fps.min,
      max = fps.max,
      frame_drops = fps.frame_drops,
      low_fps_events = #fps.low_fps_events
    },
    memory = {
      current_mb = memory.current_mb,
      peak_mb = memory.peak_mb,
      average_mb = memory.average_mb,
      warnings = memory.memory_warnings
    },
    errors = {
      crashes = errors.crash_count,
      errors = errors.error_count,
      warnings = errors.warning_count
    },
    load_times = PerformanceMetrics.metrics.load_times,
    system = PerformanceMetrics.metrics.system
  }
end
-- Get performance alerts
function PerformanceMetrics.getAlerts()
  local alerts = {}
  local fps = PerformanceMetrics.metrics.fps
  local memory = PerformanceMetrics.metrics.memory
  -- FPS alerts
  if fps.current < PerformanceMetrics.thresholds.fps_critical then
    table.insert(alerts, {
      type = "critical",
      category = "fps",
      message = string.format("Critical FPS: %d", fps.current),
      value = fps.current
    })
  elseif fps.current < PerformanceMetrics.thresholds.fps_warning then
    table.insert(alerts, {
      type = "warning",
      category = "fps",
      message = string.format("Low FPS: %d", fps.current),
      value = fps.current
    })
  end
  -- Memory alerts
  if memory.current_mb > PerformanceMetrics.thresholds.memory_critical then
    table.insert(alerts, {
      type = "critical",
      category = "memory",
      message = string.format("Critical memory usage: %.1f MB", memory.current_mb),
      value = memory.current_mb
    })
  elseif memory.current_mb > PerformanceMetrics.thresholds.memory_warning then
    table.insert(alerts, {
      type = "warning",
      category = "memory",
      message = string.format("High memory usage: %.1f MB", memory.current_mb),
      value = memory.current_mb
    })
  end
  -- Error alerts
  if PerformanceMetrics.metrics.errors.crash_count > 0 then
    table.insert(alerts, {
      type = "critical",
      category = "errors",
      message = string.format("Crashes detected: %d", PerformanceMetrics.metrics.errors.crash_count),
      value = PerformanceMetrics.metrics.errors.crash_count
    })
  end
  return alerts
end
-- Get performance trends
function PerformanceMetrics.getTrends()
  local trends = {
    fps_trend = "stable",
    memory_trend = "stable",
    error_trend = "stable"
  }
  -- Analyze FPS trend
  if #PerformanceMetrics.history.fps_history >= 60 then
    local recent = PerformanceMetrics.history.fps_history[#PerformanceMetrics.history.fps_history].fps
    local older = PerformanceMetrics.history.fps_history[#PerformanceMetrics.history.fps_history - 59].fps
    if recent > older + 5 then
      trends.fps_trend = "improving"
    elseif recent < older - 5 then
      trends.fps_trend = "declining"
    end
  end
  -- Analyze memory trend
  if #PerformanceMetrics.history.memory_history >= 60 then
    local recent = PerformanceMetrics.history.memory_history[#PerformanceMetrics.history.memory_history].memory_mb
    local older = PerformanceMetrics.history.memory_history[#PerformanceMetrics.history.memory_history - 59].memory_mb
    if recent > older + 10 then
      trends.memory_trend = "increasing"
    elseif recent < older - 10 then
      trends.memory_trend = "decreasing"
    end
  end
  return trends
end
-- Save performance data
function PerformanceMetrics.saveData()
  local saveData = {
    metrics = PerformanceMetrics.metrics,
    history = PerformanceMetrics.history,
    thresholds = PerformanceMetrics.thresholds
  }
  return Utils.saveData("performance_metrics", saveData)
end
-- Load performance data
function PerformanceMetrics.loadData()
  local saveData = Utils.loadData("performance_metrics")
  if saveData then
    PerformanceMetrics.metrics = saveData.metrics or PerformanceMetrics.metrics
    PerformanceMetrics.history = saveData.history or PerformanceMetrics.history
    PerformanceMetrics.thresholds = saveData.thresholds or PerformanceMetrics.thresholds
    Utils.Logger.info("Performance metrics data loaded")
    return true
  end
  return false
end
return PerformanceMetrics