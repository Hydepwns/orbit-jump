-- Performance Monitoring System Coordinator
-- Main performance monitoring system that coordinates all performance modules

local Utils = require("src.utils.utils")
local PerformanceMetrics = require("src.systems.performance.performance_metrics")
local PerformanceUI = require("src.systems.performance.performance_ui")

local PerformanceSystem = {}

-- System state
PerformanceSystem.isActive = false
PerformanceSystem.isInitialized = false
PerformanceSystem.startTime = 0
PerformanceSystem.lastUpdateTime = 0
PerformanceSystem.updateInterval = 1.0 -- Update every second

-- Initialize performance monitoring system
function PerformanceSystem.init()
  if PerformanceSystem.isInitialized then
    return true
  end
  
  -- Initialize all modules
  PerformanceMetrics = PerformanceMetrics or require("src.systems.performance.performance_metrics")
  PerformanceUI = PerformanceUI or require("src.systems.performance.performance_ui")
  
  PerformanceMetrics.init()
  PerformanceUI.init()
  
  -- Load saved data
  PerformanceMetrics.loadData()
  
  PerformanceSystem.isInitialized = true
  Utils.Logger.info("Performance monitoring system initialized successfully")
  
  return true
end

-- Start performance monitoring
function PerformanceSystem.start()
  if not PerformanceSystem.isInitialized then
    Utils.Logger.warning("Performance system not initialized")
    return false
  end
  
  PerformanceSystem.isActive = true
  PerformanceSystem.startTime = love.timer.getTime()
  PerformanceSystem.lastUpdateTime = love.timer.getTime()
  
  Utils.Logger.info("Performance monitoring started")
  return true
end

-- Stop performance monitoring
function PerformanceSystem.stop()
  if not PerformanceSystem.isInitialized then
    return false
  end
  
  PerformanceSystem.isActive = false
  
  -- Save data before stopping
  PerformanceMetrics.saveData()
  
  Utils.Logger.info("Performance monitoring stopped")
  return true
end

-- Update performance monitoring system
function PerformanceSystem.update(dt)
  if not PerformanceSystem.isInitialized or not PerformanceSystem.isActive then
    return
  end
  
  local currentTime = love.timer.getTime()
  
  -- Update at regular intervals
  if currentTime - PerformanceSystem.lastUpdateTime >= PerformanceSystem.updateInterval then
    PerformanceSystem.lastUpdateTime = currentTime
    
    -- Update FPS
    local currentFPS = love.timer.getFPS()
    PerformanceMetrics.updateFPS(currentFPS)
    
    -- Update memory
    PerformanceMetrics.updateMemory()
    
    -- Update system metrics
    PerformanceMetrics.updateSystemMetrics()
  end
  
  -- Update UI
  PerformanceUI.update(dt)
end

-- Draw performance monitoring system
function PerformanceSystem.draw()
  if not PerformanceSystem.isInitialized then
    return
  end
  
  PerformanceUI.draw()
end

-- Handle input
function PerformanceSystem.mousepressed(x, y, button)
  if not PerformanceSystem.isInitialized then
    return false
  end
  
  return PerformanceUI.mousepressed(x, y, button)
end

function PerformanceSystem.wheelmoved(x, y)
  if not PerformanceSystem.isInitialized then
    return false
  end
  
  return PerformanceUI.wheelmoved(x, y)
end

-- Public API for other systems

-- Record load time
function PerformanceSystem.recordLoadTime(loadType, duration)
  if not PerformanceSystem.isInitialized then
    Utils.Logger.warning("Performance system not initialized")
    return false
  end
  
  PerformanceMetrics.recordLoadTime(loadType, duration)
  return true
end

-- Record error
function PerformanceSystem.recordError(errorType, message, stackTrace)
  if not PerformanceSystem.isInitialized then
    Utils.Logger.warning("Performance system not initialized")
    return false
  end
  
  PerformanceMetrics.recordError(errorType, message, stackTrace)
  return true
end

-- Get performance summary
function PerformanceSystem.getSummary()
  if not PerformanceSystem.isInitialized then
    return nil
  end
  
  return PerformanceMetrics.getSummary()
end

-- Get performance alerts
function PerformanceSystem.getAlerts()
  if not PerformanceSystem.isInitialized then
    return {}
  end
  
  return PerformanceMetrics.getAlerts()
end

-- Get performance trends
function PerformanceSystem.getTrends()
  if not PerformanceSystem.isInitialized then
    return {}
  end
  
  return PerformanceMetrics.getTrends()
end

-- Get current FPS
function PerformanceSystem.getCurrentFPS()
  if not PerformanceSystem.isInitialized then
    return 0
  end
  
  return PerformanceMetrics.metrics.fps.current
end

-- Get memory usage
function PerformanceSystem.getMemoryUsage()
  if not PerformanceSystem.isInitialized then
    return 0
  end
  
  return PerformanceMetrics.metrics.memory.current_mb
end

-- Get system information
function PerformanceSystem.getSystemInfo()
  if not PerformanceSystem.isInitialized then
    return {}
  end
  
  return PerformanceMetrics.metrics.system
end

-- Check if performance is acceptable
function PerformanceSystem.isPerformanceAcceptable()
  if not PerformanceSystem.isInitialized then
    return true
  end
  
  local alerts = PerformanceSystem.getAlerts()
  local criticalAlerts = 0
  
  for _, alert in ipairs(alerts) do
    if alert.type == "critical" then
      criticalAlerts = criticalAlerts + 1
    end
  end
  
  return criticalAlerts == 0
end

-- Get performance score (0-100)
function PerformanceSystem.getPerformanceScore()
  if not PerformanceSystem.isInitialized then
    return 100
  end
  
  local summary = PerformanceSystem.getSummary()
  local score = 100
  
  -- FPS score (40% weight)
  local fpsScore = math.min(100, (summary.fps.current / 60) * 100)
  score = score * 0.6 + fpsScore * 0.4
  
  -- Memory score (30% weight)
  local memoryUsage = summary.memory.current_mb
  local memoryScore = math.max(0, 100 - (memoryUsage / PerformanceMetrics.thresholds.memory_critical) * 100)
  score = score * 0.7 + memoryScore * 0.3
  
  -- Error score (30% weight)
  local errorScore = 100
  if summary.errors.crashes > 0 then
    errorScore = errorScore - 50
  end
  if summary.errors.errors > 10 then
    errorScore = errorScore - 30
  end
  if summary.errors.warnings > 20 then
    errorScore = errorScore - 20
  end
  errorScore = math.max(0, errorScore)
  score = score * 0.7 + errorScore * 0.3
  
  return math.floor(score)
end

-- UI Controls

-- Toggle performance UI
function PerformanceSystem.toggleUI()
  if not PerformanceSystem.isInitialized then
    return
  end
  
  PerformanceUI.toggle()
end

-- Show performance UI
function PerformanceSystem.showUI()
  if not PerformanceSystem.isInitialized then
    return
  end
  
  PerformanceUI.show()
end

-- Hide performance UI
function PerformanceSystem.hideUI()
  if not PerformanceSystem.isInitialized then
    return
  end
  
  PerformanceUI.hide()
end

-- Check if UI is visible
function PerformanceSystem.isUIVisible()
  if not PerformanceSystem.isInitialized then
    return false
  end
  
  return PerformanceUI.isVisible
end

-- Save/Load functions
function PerformanceSystem.save()
  if not PerformanceSystem.isInitialized then
    return false
  end
  
  return PerformanceMetrics.saveData()
end

function PerformanceSystem.load()
  if not PerformanceSystem.isInitialized then
    return false
  end
  
  return PerformanceMetrics.loadData()
end

function PerformanceSystem.reset()
  if not PerformanceSystem.isInitialized then
    return
  end
  
  PerformanceMetrics.resetMetrics()
  Utils.Logger.info("Performance data reset")
end

-- Debug functions
function PerformanceSystem.debug()
  if not PerformanceSystem.isInitialized then
    print("Performance system not initialized")
    return
  end
  
  print("=== Performance System Debug ===")
  print("Active:", PerformanceSystem.isActive)
  print("Initialized:", PerformanceSystem.isInitialized)
  
  local summary = PerformanceSystem.getSummary()
  print("Current FPS:", summary.fps.current)
  print("Average FPS:", summary.fps.average)
  print("Memory Usage:", string.format("%.1f MB", summary.memory.current_mb))
  print("Peak Memory:", string.format("%.1f MB", summary.memory.peak_mb))
  print("Crashes:", summary.errors.crashes)
  print("Errors:", summary.errors.errors)
  print("Warnings:", summary.errors.warnings)
  
  local alerts = PerformanceSystem.getAlerts()
  print("Active Alerts:", #alerts)
  for i, alert in ipairs(alerts) do
    print(string.format("  %d. [%s] %s", i, alert.type, alert.message))
  end
  
  local trends = PerformanceSystem.getTrends()
  print("FPS Trend:", trends.fps_trend)
  print("Memory Trend:", trends.memory_trend)
  print("Error Trend:", trends.error_trend)
  
  local score = PerformanceSystem.getPerformanceScore()
  print("Performance Score:", score .. "/100")
end

-- Test functions for development
function PerformanceSystem.testRecordError()
  if not PerformanceSystem.isInitialized then
    print("Performance system not initialized")
    return
  end
  
  PerformanceSystem.recordError("warning", "Test warning message", "test_stack_trace")
  print("Test error recorded")
end

function PerformanceSystem.testRecordLoadTime()
  if not PerformanceSystem.isInitialized then
    print("Performance system not initialized")
    return
  end
  
  PerformanceSystem.recordLoadTime("test", 2.5)
  print("Test load time recorded")
end

return PerformanceSystem 