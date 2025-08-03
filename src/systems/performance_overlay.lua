--[[
    Performance Overlay System
    Provides real-time performance visualization overlay for development.
    Shows FPS, memory usage, system health, and other metrics.
--]]
local Utils = require("src.utils.utils")
local PerformanceOverlay = {}
-- Configuration
PerformanceOverlay.config = {
    enabled = false,
    position = { x = 10, y = 10 },
    opacity = 0.8,
    fontSize = 12,
    updateInterval = 0.1, -- Update every 100ms
    -- What to show
    show = {
        fps = true,
        memory = true,
        drawCalls = true,
        entityCount = true,
        systemHealth = true,
        gcInfo = true,
        warnings = true
    },
    -- Visual settings
    colors = {
        background = {0, 0, 0, 0.7},
        text = {1, 1, 1, 1},
        good = {0, 1, 0, 1},
        warning = {1, 1, 0, 1},
        bad = {1, 0, 0, 1},
        graph = {0.5, 0.5, 1, 0.8}
    }
}
-- Runtime data
PerformanceOverlay.data = {
    fps = 60,
    frameTime = 0,
    memory = 0,
    drawCalls = 0,
    entities = 0,
    lastUpdate = 0,
    -- History for graphs
    fpsHistory = {},
    memoryHistory = {},
    maxHistorySize = 60, -- 1 minute at 60fps
    -- Warnings
    warnings = {},
    maxWarnings = 5
}
-- Initialize the overlay
function PerformanceOverlay.init()
    Utils.Logger.info("Performance overlay initialized")
    -- Pre-allocate history arrays
    for i = 1, PerformanceOverlay.data.maxHistorySize do
        PerformanceOverlay.data.fpsHistory[i] = 60
        PerformanceOverlay.data.memoryHistory[i] = 0
    end
end
-- Toggle overlay visibility
function PerformanceOverlay.toggle()
    PerformanceOverlay.config.enabled = not PerformanceOverlay.config.enabled
    if PerformanceOverlay.config.enabled then
        Utils.Logger.info("Performance overlay enabled")
    else
        Utils.Logger.info("Performance overlay disabled")
    end
end
-- Update performance data
function PerformanceOverlay.update(dt)
    if not PerformanceOverlay.config.enabled then
        return
    end
    local data = PerformanceOverlay.data
    local currentTime = love.timer.getTime()
    -- Update at configured interval
    if currentTime - data.lastUpdate < PerformanceOverlay.config.updateInterval then
        return
    end
    data.lastUpdate = currentTime
    -- Calculate FPS
    data.frameTime = dt
    data.fps = dt > 0 and 1 / dt or 0
    -- Get memory usage (in MB)
    data.memory = collectgarbage("count") / 1024
    -- Update history (circular buffer style)
    table.insert(data.fpsHistory, data.fps)
    table.insert(data.memoryHistory, data.memory)
    -- Maintain history size
    if #data.fpsHistory > data.maxHistorySize then
        table.remove(data.fpsHistory, 1)
    end
    if #data.memoryHistory > data.maxHistorySize then
        table.remove(data.memoryHistory, 1)
    end
    -- Count entities
    data.entities = PerformanceOverlay.countEntities()
    -- Check for warnings
    PerformanceOverlay.checkWarnings()
end
-- Count active game entities
function PerformanceOverlay.countEntities()
    local count = 0
    -- Count from GameState if available
    local GameState = _G.GameState
    if GameState then
        count = count + (GameState.getPlanets and #GameState.getPlanets() or 0)
        count = count + (GameState.getRings and #GameState.getRings() or 0)
        count = count + (GameState.getParticles and #GameState.getParticles() or 0)
    end
    return count
end
-- Check for performance warnings
function PerformanceOverlay.checkWarnings()
    local data = PerformanceOverlay.data
    local warnings = {}
    -- FPS warning
    if data.fps < 30 then
        table.insert(warnings, {
            type = "fps",
            message = string.format("Low FPS: %.1f", data.fps),
            severity = data.fps < 20 and "bad" or "warning"
        })
    end
    -- Memory warning
    if data.memory > 200 then -- 200MB
        table.insert(warnings, {
            type = "memory",
            message = string.format("High memory: %.1fMB", data.memory),
            severity = data.memory > 300 and "bad" or "warning"
        })
    end
    -- Entity count warning
    if data.entities > 1000 then
        table.insert(warnings, {
            type = "entities",
            message = string.format("Many entities: %d", data.entities),
            severity = "warning"
        })
    end
    -- Update warnings list
    data.warnings = warnings
end
-- Draw the overlay
function PerformanceOverlay.draw()
    if not PerformanceOverlay.config.enabled then
        return
    end
    local config = PerformanceOverlay.config
    local data = PerformanceOverlay.data
    local x, y = config.position.x, config.position.y
    -- Save graphics state
    love.graphics.push()
    love.graphics.setFont(love.graphics.newFont(config.fontSize))
    -- Calculate overlay size
    local width = 250
    local lineHeight = config.fontSize + 4
    local lines = 0
    if config.show.fps then lines = lines + 1 end
    if config.show.memory then lines = lines + 1 end
    if config.show.drawCalls then lines = lines + 1 end
    if config.show.entityCount then lines = lines + 1 end
    if config.show.gcInfo then lines = lines + 1 end
    if config.show.warnings and #data.warnings > 0 then
        lines = lines + math.min(#data.warnings, data.maxWarnings)
    end
    local height = lines * lineHeight + 20
    -- Add space for graphs
    local graphHeight = 50
    if config.show.fps then height = height + graphHeight + 10 end
    -- Draw background
    love.graphics.setColor(config.colors.background)
    love.graphics.rectangle("fill", x, y, width, height, 5)
    -- Draw border
    love.graphics.setColor(config.colors.text)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height, 5)
    -- Draw title
    love.graphics.print("Performance Monitor", x + 10, y + 5)
    y = y + lineHeight + 5
    -- Draw metrics
    if config.show.fps then
        local fpsColor = data.fps >= 55 and config.colors.good or
                        data.fps >= 30 and config.colors.warning or
                        config.colors.bad
        love.graphics.setColor(fpsColor)
        love.graphics.print(string.format("FPS: %.1f (%.2fms)", data.fps, data.frameTime * 1000), x + 10, y)
        y = y + lineHeight
    end
    if config.show.memory then
        local memColor = data.memory < 100 and config.colors.good or
                        data.memory < 200 and config.colors.warning or
                        config.colors.bad
        love.graphics.setColor(memColor)
        love.graphics.print(string.format("Memory: %.1f MB", data.memory), x + 10, y)
        y = y + lineHeight
    end
    if config.show.entityCount then
        love.graphics.setColor(config.colors.text)
        love.graphics.print(string.format("Entities: %d", data.entities), x + 10, y)
        y = y + lineHeight
    end
    if config.show.gcInfo then
        love.graphics.setColor(config.colors.text)
        local gcinfo = string.format("GC: %.1f KB", collectgarbage("count"))
        love.graphics.print(gcinfo, x + 10, y)
        y = y + lineHeight
    end
    -- Draw warnings
    if config.show.warnings and #data.warnings > 0 then
        y = y + 5
        for i, warning in ipairs(data.warnings) do
            if i > data.maxWarnings then break end
            local color = warning.severity == "bad" and config.colors.bad or config.colors.warning
            love.graphics.setColor(color)
            love.graphics.print("⚠ " .. warning.message, x + 10, y)
            y = y + lineHeight
        end
    end
    -- Draw FPS graph
    if config.show.fps and #data.fpsHistory > 1 then
        y = y + 10
        PerformanceOverlay.drawGraph(x + 10, y, width - 20, graphHeight,
            data.fpsHistory, 0, 120, "FPS History")
    end
    -- Restore graphics state
    love.graphics.pop()
end
-- Draw a mini graph
function PerformanceOverlay.drawGraph(x, y, width, height, data, minVal, maxVal, label)
    local config = PerformanceOverlay.config
    -- Draw graph background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, width, height)
    -- Draw graph border
    love.graphics.setColor(config.colors.text)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    -- Draw label
    love.graphics.setColor(config.colors.text)
    love.graphics.print(label, x + 2, y + 2)
    -- Draw data
    if #data > 1 then
        love.graphics.setColor(config.colors.graph)
        local points = {}
        local step = width / (#data - 1)
        for i, value in ipairs(data) do
            local px = x + (i - 1) * step
            local normalized = (value - minVal) / (maxVal - minVal)
            local py = y + height - (normalized * height)
            table.insert(points, px)
            table.insert(points, py)
        end
        if #points >= 4 then
            love.graphics.setLineWidth(2)
            love.graphics.line(points)
        end
    end
    -- Draw target line (60 FPS)
    if label == "FPS History" then
        love.graphics.setColor(0, 1, 0, 0.3)
        local targetY = y + height - ((60 - minVal) / (maxVal - minVal) * height)
        love.graphics.setLineWidth(1)
        love.graphics.line(x, targetY, x + width, targetY)
    end
end
-- Add warning
function PerformanceOverlay.addWarning(type, message, severity)
    if not PerformanceOverlay.config.enabled then
        return
    end
    table.insert(PerformanceOverlay.data.warnings, {
        type = type,
        message = message,
        severity = severity or "warning",
        timestamp = love.timer.getTime()
    })
    -- Limit warnings
    while #PerformanceOverlay.data.warnings > PerformanceOverlay.data.maxWarnings do
        table.remove(PerformanceOverlay.data.warnings, 1)
    end
end
-- Keyboard handler
function PerformanceOverlay.keypressed(key)
    -- Toggle with F3
    if key == "f3" then
        PerformanceOverlay.toggle()
    end
end
return PerformanceOverlay