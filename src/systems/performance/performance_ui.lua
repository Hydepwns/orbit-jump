-- Performance UI Module
-- Handles performance-related user interface rendering and display
local Utils = require("src.utils.utils")
local PerformanceMetrics = require("src.systems.performance.performance_metrics")
local PerformanceUI = {}
-- UI state
PerformanceUI.isVisible = false
PerformanceUI.currentTab = "overview"
PerformanceUI.scrollOffset = 0
PerformanceUI.autoRefresh = true
PerformanceUI.refreshInterval = 1.0
PerformanceUI.lastRefresh = 0
-- UI constants
PerformanceUI.constants = {
  PANEL_WIDTH = 500,
  PANEL_HEIGHT = 700,
  MARGIN = 10,
  CHART_HEIGHT = 150,
  BAR_HEIGHT = 20,
  TEXT_HEIGHT = 16
}
-- Initialize performance UI
function PerformanceUI.init()
  PerformanceUI.isVisible = false
  PerformanceUI.currentTab = "overview"
  PerformanceUI.scrollOffset = 0
  PerformanceUI.autoRefresh = true
  PerformanceUI.refreshInterval = 1.0
  PerformanceUI.lastRefresh = 0
  Utils.Logger.info("Performance UI initialized")
end
-- Toggle performance panel visibility
function PerformanceUI.toggle()
  PerformanceUI.isVisible = not PerformanceUI.isVisible
  if PerformanceUI.isVisible then
    PerformanceUI.scrollOffset = 0
  end
end
-- Show performance panel
function PerformanceUI.show()
  PerformanceUI.isVisible = true
  PerformanceUI.scrollOffset = 0
end
-- Hide performance panel
function PerformanceUI.hide()
  PerformanceUI.isVisible = false
end
-- Update performance UI
function PerformanceUI.update(dt)
  if not PerformanceUI.isVisible then
    return
  end
  -- Auto refresh
  if PerformanceUI.autoRefresh then
    PerformanceUI.lastRefresh = PerformanceUI.lastRefresh + dt
    if PerformanceUI.lastRefresh >= PerformanceUI.refreshInterval then
      PerformanceUI.lastRefresh = 0
      -- Force refresh of metrics
      PerformanceMetrics.updateMemory()
      PerformanceMetrics.updateSystemMetrics()
    end
  end
end
-- Draw performance UI
function PerformanceUI.draw()
  if not PerformanceUI.isVisible then
    return
  end
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  -- Draw background overlay
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
  -- Calculate panel position
  local panelX = (screenWidth - PerformanceUI.constants.PANEL_WIDTH) / 2
  local panelY = (screenHeight - PerformanceUI.constants.PANEL_HEIGHT) / 2
  -- Draw main panel
  PerformanceUI.drawPanel(panelX, panelY)
  -- Draw tabs
  PerformanceUI.drawTabs(panelX, panelY)
  -- Draw content based on current tab
  PerformanceUI.drawContent(panelX, panelY)
end
-- Draw main panel
function PerformanceUI.drawPanel(x, y)
  love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
  love.graphics.rectangle("fill", x, y, PerformanceUI.constants.PANEL_WIDTH, PerformanceUI.constants.PANEL_HEIGHT, 10)
  love.graphics.setColor(0.3, 0.3, 0.5, 1)
  love.graphics.rectangle("line", x, y, PerformanceUI.constants.PANEL_WIDTH, PerformanceUI.constants.PANEL_HEIGHT, 10)
  -- Draw title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(24))
  love.graphics.printf("📊 Performance Monitor", x, y + 20, PerformanceUI.constants.PANEL_WIDTH, "center")
end
-- Draw tabs
function PerformanceUI.drawTabs(panelX, panelY)
  local tabs = {"overview", "fps", "memory", "errors", "load_times", "system"}
  local tabWidth = PerformanceUI.constants.PANEL_WIDTH / #tabs
  local tabY = panelY + 60
  for i, tab in ipairs(tabs) do
    local tabX = panelX + (i - 1) * tabWidth
    local isSelected = tab == PerformanceUI.currentTab
    -- Tab background
    if isSelected then
      love.graphics.setColor(0.3, 0.3, 0.6, 1)
    else
      love.graphics.setColor(0.2, 0.2, 0.4, 1)
    end
    love.graphics.rectangle("fill", tabX, tabY, tabWidth, 30, 5)
    -- Tab border
    love.graphics.setColor(0.5, 0.5, 0.7, 1)
    love.graphics.rectangle("line", tabX, tabY, tabWidth, 30, 5)
    -- Tab text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Utils.getFont(12))
    love.graphics.printf(string.upper(tab:gsub("_", " ")), tabX, tabY + 8, tabWidth, "center")
  end
end
-- Draw content based on current tab
function PerformanceUI.drawContent(panelX, panelY)
  local contentY = panelY + 100
  local contentHeight = PerformanceUI.constants.PANEL_HEIGHT - 120
  if PerformanceUI.currentTab == "overview" then
    PerformanceUI.drawOverview(panelX, contentY, contentHeight)
  elseif PerformanceUI.currentTab == "fps" then
    PerformanceUI.drawFPSTab(panelX, contentY, contentHeight)
  elseif PerformanceUI.currentTab == "memory" then
    PerformanceUI.drawMemoryTab(panelX, contentY, contentHeight)
  elseif PerformanceUI.currentTab == "errors" then
    PerformanceUI.drawErrorsTab(panelX, contentY, contentHeight)
  elseif PerformanceUI.currentTab == "load_times" then
    PerformanceUI.drawLoadTimesTab(panelX, contentY, contentHeight)
  elseif PerformanceUI.currentTab == "system" then
    PerformanceUI.drawSystemTab(panelX, contentY, contentHeight)
  end
end
-- Draw overview tab
function PerformanceUI.drawOverview(x, y, height)
  local summary = PerformanceMetrics.getSummary()
  local alerts = PerformanceMetrics.getAlerts()
  local trends = PerformanceMetrics.getTrends()
  -- FPS section
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(18))
  love.graphics.printf("Frame Rate", x + 10, y, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  love.graphics.printf(string.format("Current: %d FPS", summary.fps.current), x + 20, y + 25, 200, "left")
  love.graphics.printf(string.format("Average: %.1f FPS", summary.fps.average), x + 20, y + 45, 200, "left")
  love.graphics.printf(string.format("Min/Max: %d/%d", summary.fps.min, summary.fps.max), x + 20, y + 65, 200, "left")
  -- FPS trend indicator
  local trendColor = {0.3, 0.7, 0.3, 1}
  if trends.fps_trend == "declining" then
    trendColor = {0.7, 0.3, 0.3, 1}
  elseif trends.fps_trend == "improving" then
    trendColor = {0.3, 0.7, 0.3, 1}
  end
  love.graphics.setColor(trendColor)
  love.graphics.printf(string.format("Trend: %s", trends.fps_trend), x + 20, y + 85, 200, "left")
  -- Memory section
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(18))
  love.graphics.printf("Memory Usage", x + 10, y + 120, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  love.graphics.printf(string.format("Current: %.1f MB", summary.memory.current_mb), x + 20, y + 145, 200, "left")
  love.graphics.printf(string.format("Peak: %.1f MB", summary.memory.peak_mb), x + 20, y + 165, 200, "left")
  love.graphics.printf(string.format("Average: %.1f MB", summary.memory.average_mb), x + 20, y + 185, 200, "left")
  -- Memory trend indicator
  local memTrendColor = {0.3, 0.7, 0.3, 1}
  if trends.memory_trend == "increasing" then
    memTrendColor = {0.7, 0.3, 0.3, 1}
  elseif trends.memory_trend == "decreasing" then
    memTrendColor = {0.3, 0.7, 0.3, 1}
  end
  love.graphics.setColor(memTrendColor)
  love.graphics.printf(string.format("Trend: %s", trends.memory_trend), x + 20, y + 205, 200, "left")
  -- Alerts section
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(18))
  love.graphics.printf("Active Alerts", x + 10, y + 240, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  if #alerts == 0 then
    love.graphics.setColor(0.3, 0.7, 0.3, 1)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf("No active alerts", x + 20, y + 265, PerformanceUI.constants.PANEL_WIDTH - 40, "left")
  else
    for i, alert in ipairs(alerts) do
      if i <= 5 then -- Limit to 5 alerts
        local alertColor = {0.7, 0.3, 0.3, 1}
        if alert.type == "warning" then
          alertColor = {0.7, 0.7, 0.3, 1}
        end
        love.graphics.setColor(alertColor)
        love.graphics.setFont(Utils.getFont(12))
        love.graphics.printf(alert.message, x + 20, y + 265 + (i - 1) * 20, PerformanceUI.constants.PANEL_WIDTH - 40, "left")
      end
    end
  end
end
-- Draw FPS tab
function PerformanceUI.drawFPSTab(x, y, height)
  local fps = PerformanceMetrics.metrics.fps
  -- FPS chart
  love.graphics.setColor(0.2, 0.2, 0.3, 1)
  love.graphics.rectangle("fill", x + 10, y, PerformanceUI.constants.PANEL_WIDTH - 20, PerformanceUI.constants.CHART_HEIGHT, 5)
  -- Draw FPS line
  if #fps.samples > 1 then
    love.graphics.setColor(0.3, 0.7, 0.3, 1)
    love.graphics.setLineWidth(2)
    local chartWidth = PerformanceUI.constants.PANEL_WIDTH - 40
    local chartHeight = PerformanceUI.constants.CHART_HEIGHT - 20
    local stepX = chartWidth / (#fps.samples - 1)
    for i = 1, #fps.samples - 1 do
      local x1 = x + 20 + (i - 1) * stepX
      local y1 = y + PerformanceUI.constants.CHART_HEIGHT - 10 - (fps.samples[i] / 60) * chartHeight
      local x2 = x + 20 + i * stepX
      local y2 = y + PerformanceUI.constants.CHART_HEIGHT - 10 - (fps.samples[i + 1] / 60) * chartHeight
      love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setLineWidth(1)
  end
  -- FPS statistics
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("FPS Statistics", x + 10, y + PerformanceUI.constants.CHART_HEIGHT + 10, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  local statsY = y + PerformanceUI.constants.CHART_HEIGHT + 35
  love.graphics.printf(string.format("Frame Drops: %d", fps.frame_drops), x + 20, statsY, 200, "left")
  love.graphics.printf(string.format("Low FPS Events: %d", #fps.low_fps_events), x + 20, statsY + 25, 200, "left")
  love.graphics.printf(string.format("Target FPS: %d", fps.target_fps), x + 20, statsY + 50, 200, "left")
end
-- Draw memory tab
function PerformanceUI.drawMemoryTab(x, y, height)
  local memory = PerformanceMetrics.metrics.memory
  -- Memory usage bar
  local barWidth = PerformanceUI.constants.PANEL_WIDTH - 40
  local barHeight = 30
  love.graphics.setColor(0.2, 0.2, 0.3, 1)
  love.graphics.rectangle("fill", x + 20, y, barWidth, barHeight, 5)
  -- Memory usage fill
  local usageRatio = memory.current_mb / PerformanceMetrics.thresholds.memory_critical
  if usageRatio > 0 then
    local fillColor = {0.3, 0.7, 0.3, 1}
    if usageRatio > 0.8 then
      fillColor = {0.7, 0.3, 0.3, 1}
    elseif usageRatio > 0.6 then
      fillColor = {0.7, 0.7, 0.3, 1}
    end
    love.graphics.setColor(fillColor)
    love.graphics.rectangle("fill", x + 20, y, barWidth * usageRatio, barHeight, 5)
  end
  -- Memory text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(14))
  love.graphics.printf(string.format("%.1f MB / %.1f MB", memory.current_mb, PerformanceMetrics.thresholds.memory_critical),
                       x + 20, y + 5, barWidth, "center")
  -- Memory statistics
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("Memory Statistics", x + 10, y + 50, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  local statsY = y + 75
  love.graphics.printf(string.format("Peak Usage: %.1f MB", memory.peak_mb), x + 20, statsY, 200, "left")
  love.graphics.printf(string.format("Average Usage: %.1f MB", memory.average_mb), x + 20, statsY + 25, 200, "left")
  love.graphics.printf(string.format("Memory Warnings: %d", memory.memory_warnings), x + 20, statsY + 50, 200, "left")
  love.graphics.printf(string.format("GC Events: %d", #memory.gc_events), x + 20, statsY + 75, 200, "left")
end
-- Draw errors tab
function PerformanceUI.drawErrorsTab(x, y, height)
  local errors = PerformanceMetrics.metrics.errors
  -- Error summary
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("Error Summary", x + 10, y, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  local statsY = y + 25
  love.graphics.setColor(0.7, 0.3, 0.3, 1)
  love.graphics.printf(string.format("Crashes: %d", errors.crash_count), x + 20, statsY, 200, "left")
  love.graphics.setColor(0.7, 0.7, 0.3, 1)
  love.graphics.printf(string.format("Errors: %d", errors.error_count), x + 20, statsY + 25, 200, "left")
  love.graphics.setColor(0.3, 0.7, 0.3, 1)
  love.graphics.printf(string.format("Warnings: %d", errors.warning_count), x + 20, statsY + 50, 200, "left")
  -- Recent errors
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("Recent Errors", x + 10, y + 100, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  local recentErrors = {}
  for _, error in ipairs(errors.lua_errors) do
    table.insert(recentErrors, error)
  end
  for _, error in ipairs(errors.system_errors) do
    table.insert(recentErrors, error)
  end
  -- Sort by time
  table.sort(recentErrors, function(a, b) return a.time > b.time end)
  if #recentErrors == 0 then
    love.graphics.setColor(0.3, 0.7, 0.3, 1)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf("No recent errors", x + 20, y + 125, PerformanceUI.constants.PANEL_WIDTH - 40, "left")
  else
    for i, error in ipairs(recentErrors) do
      if i <= 10 then -- Limit to 10 errors
        local errorColor = {0.7, 0.3, 0.3, 1}
        if error.type == "warning" then
          errorColor = {0.7, 0.7, 0.3, 1}
        end
        love.graphics.setColor(errorColor)
        love.graphics.setFont(Utils.getFont(12))
        love.graphics.printf(string.format("[%s] %s", error.type, error.message),
                             x + 20, y + 125 + (i - 1) * 20, PerformanceUI.constants.PANEL_WIDTH - 40, "left")
      end
    end
  end
end
-- Draw load times tab
function PerformanceUI.drawLoadTimesTab(x, y, height)
  local loadTimes = PerformanceMetrics.metrics.load_times
  -- Load time summary
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("Load Time Summary", x + 10, y, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  local statsY = y + 25
  love.graphics.printf(string.format("Game Startup: %.2f s", loadTimes.game_startup), x + 20, statsY, 200, "left")
  love.graphics.printf(string.format("Level Transitions: %d", #loadTimes.level_transitions), x + 20, statsY + 25, 200, "left")
  love.graphics.printf(string.format("Asset Loads: %d", #loadTimes.asset_loads), x + 20, statsY + 50, 200, "left")
  love.graphics.printf(string.format("Save Loads: %d", #loadTimes.save_loads), x + 20, statsY + 75, 200, "left")
  -- Recent load times
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("Recent Load Times", x + 10, y + 120, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  local allLoadTimes = {}
  for _, loadTime in ipairs(loadTimes.level_transitions) do
    table.insert(allLoadTimes, {type = "Level", data = loadTime})
  end
  for _, loadTime in ipairs(loadTimes.asset_loads) do
    table.insert(allLoadTimes, {type = "Asset", data = loadTime})
  end
  for _, loadTime in ipairs(loadTimes.save_loads) do
    table.insert(allLoadTimes, {type = "Save", data = loadTime})
  end
  -- Sort by time
  table.sort(allLoadTimes, function(a, b) return a.data.time > b.data.time end)
  if #allLoadTimes == 0 then
    love.graphics.setColor(0.3, 0.7, 0.3, 1)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf("No recent load times", x + 20, y + 145, PerformanceUI.constants.PANEL_WIDTH - 40, "left")
  else
    for i, loadTime in ipairs(allLoadTimes) do
      if i <= 10 then -- Limit to 10 load times
        local loadColor = {0.3, 0.7, 0.3, 1}
        if loadTime.data.duration > PerformanceMetrics.thresholds.load_time_warning then
          loadColor = {0.7, 0.7, 0.3, 1}
        end
        if loadTime.data.duration > PerformanceMetrics.thresholds.load_time_critical then
          loadColor = {0.7, 0.3, 0.3, 1}
        end
        love.graphics.setColor(loadColor)
        love.graphics.setFont(Utils.getFont(12))
        love.graphics.printf(string.format("[%s] %.2f s", loadTime.type, loadTime.data.duration),
                             x + 20, y + 145 + (i - 1) * 20, PerformanceUI.constants.PANEL_WIDTH - 40, "left")
      end
    end
  end
end
-- Draw system tab
function PerformanceUI.drawSystemTab(x, y, height)
  local system = PerformanceMetrics.metrics.system
  -- System information
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("System Information", x + 10, y, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  local statsY = y + 25
  love.graphics.printf(string.format("CPU Usage: %.1f%%", system.cpu_usage), x + 20, statsY, 200, "left")
  love.graphics.printf(string.format("Available Memory: %.1f MB", system.available_memory), x + 20, statsY + 25, 200, "left")
  love.graphics.printf(string.format("Disk Space: %.1f GB", system.disk_space), x + 20, statsY + 50, 200, "left")
  -- Mobile-specific info
  if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
    love.graphics.printf(string.format("Battery Level: %d%%", system.battery_level), x + 20, statsY + 75, 200, "left")
    love.graphics.printf(string.format("Thermal State: %s", system.thermal_state), x + 20, statsY + 100, 200, "left")
  end
  -- Network information
  local network = PerformanceMetrics.metrics.network
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("Network Information", x + 10, y + 150, PerformanceUI.constants.PANEL_WIDTH - 20, "left")
  love.graphics.setFont(Utils.getFont(14))
  local netY = y + 175
  love.graphics.printf(string.format("Latency: %d ms", network.latency), x + 20, netY, 200, "left")
  love.graphics.printf(string.format("Packet Loss: %.1f%%", network.packet_loss), x + 20, netY + 25, 200, "left")
  love.graphics.printf(string.format("Connection Drops: %d", network.connection_drops), x + 20, netY + 50, 200, "left")
  love.graphics.printf(string.format("Bandwidth: %.1f MB/s", network.bandwidth_usage), x + 20, netY + 75, 200, "left")
end
-- Handle mouse input
function PerformanceUI.mousepressed(x, y, button)
  if not PerformanceUI.isVisible then
    return false
  end
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  local panelX = (screenWidth - PerformanceUI.constants.PANEL_WIDTH) / 2
  local panelY = (screenHeight - PerformanceUI.constants.PANEL_HEIGHT) / 2
  -- Check if click is outside panel
  if x < panelX or x > panelX + PerformanceUI.constants.PANEL_WIDTH or
     y < panelY or y > panelY + PerformanceUI.constants.PANEL_HEIGHT then
    PerformanceUI.hide()
    return true
  end
  -- Handle tab clicks
  local tabs = {"overview", "fps", "memory", "errors", "load_times", "system"}
  local tabWidth = PerformanceUI.constants.PANEL_WIDTH / #tabs
  local tabY = panelY + 60
  for i, tab in ipairs(tabs) do
    local tabX = panelX + (i - 1) * tabWidth
    if x >= tabX and x <= tabX + tabWidth and y >= tabY and y <= tabY + 30 then
      PerformanceUI.currentTab = tab
      return true
    end
  end
  return true
end
-- Handle scroll input
function PerformanceUI.wheelmoved(x, y)
  if not PerformanceUI.isVisible then
    return false
  end
  PerformanceUI.scrollOffset = math.max(0, PerformanceUI.scrollOffset - y * 20)
  return true
end
return PerformanceUI