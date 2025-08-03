-- Development Tools for Orbit Jump
-- Provides utilities for debugging, testing, and development workflow
local Utils = require("src.utils.utils")
local DevTools = {}
-- Development state
DevTools.state = {
    debugMode = false,
    showHitboxes = false,
    showPerformance = false,
    showDebugInfo = false,
    paused = false,
    slowMotion = false,
    slowMotionFactor = 0.5
}
-- Debug drawing functions
DevTools.debugDraw = {}
function DevTools.debugDraw.hitboxes()
    if not DevTools.state.showHitboxes then return end
    local GameState = Utils.require("src.core.game_state")
    local player = GameState.player
    local planets = GameState.getPlanets()
    local rings = GameState.getRings()
    -- Draw player hitbox
    Utils.setColor(Utils.colors.red, 0.3)
    love.graphics.circle("line", player.x, player.y, player.radius)
    -- Draw planet hitboxes
    for _, planet in ipairs(planets) do
        Utils.setColor(Utils.colors.green, 0.3)
        love.graphics.circle("line", planet.x, planet.y, planet.radius)
    end
    -- Draw ring hitboxes
    for _, ring in ipairs(rings) do
        if not ring.collected then
            Utils.setColor(Utils.colors.blue, 0.3)
            love.graphics.circle("line", ring.x, ring.y, ring.radius)
            love.graphics.circle("line", ring.x, ring.y, ring.innerRadius)
        end
    end
end
function DevTools.debugDraw.vectors()
    if not DevTools.state.showDebugInfo then return end
    local GameState = Utils.require("src.core.game_state")
    local player = GameState.player
    -- Draw velocity vector
    if player.vx ~= 0 or player.vy ~= 0 then
        Utils.setColor(Utils.colors.yellow, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(player.x, player.y, player.x + player.vx * 0.1, player.y + player.vy * 0.1)
        -- Draw velocity magnitude
        local speed = Utils.vectorLength(player.vx, player.vy)
        love.graphics.print(string.format("Speed: %.1f", speed), player.x + 20, player.y - 20)
    end
    -- Draw gravity vectors
    local planets = GameState.getPlanets()
    for _, planet in ipairs(planets) do
        local gx, gy = Utils.require("src.core.game_logic").calculateGravity(player.x, player.y, planet.x, planet.y, planet.radius)
        if gx ~= 0 or gy ~= 0 then
            Utils.setColor(Utils.colors.red, 0.6)
            love.graphics.setLineWidth(1)
            love.graphics.line(player.x, player.y, player.x + gx * 0.01, player.y + gy * 0.01)
        end
    end
end
function DevTools.debugDraw.info()
    if not DevTools.state.showDebugInfo then return end
    local GameState = Utils.require("src.core.game_state")
    local player = GameState.player
    local info = {
        string.format("Player: (%.1f, %.1f)", player.x, player.y),
        string.format("Velocity: (%.1f, %.1f)", player.vx, player.vy),
        string.format("On Planet: %s", player.onPlanet and tostring(player.onPlanet) or "None"),
        string.format("Score: %d", GameState.getScore()),
        string.format("Combo: %d", GameState.getCombo()),
        string.format("Game Time: %.1fs", GameState.getGameTime()),
        string.format("Particles: %d", #GameState.getParticles())
    }
    Utils.setColor(Utils.colors.white, 0.8)
    for i, line in ipairs(info) do
        love.graphics.print(line, 10, 150 + (i - 1) * 20)
    end
end
-- Debug controls
function DevTools.handleInput(key)
    if key == "f1" then
        DevTools.state.debugMode = not DevTools.state.debugMode
        Utils.Logger.info("Debug mode: %s", DevTools.state.debugMode and "ON" or "OFF")
    elseif key == "f2" then
        DevTools.state.showHitboxes = not DevTools.state.showHitboxes
        Utils.Logger.info("Hitboxes: %s", DevTools.state.showHitboxes and "ON" or "OFF")
    elseif key == "f3" then
        DevTools.state.showPerformance = not DevTools.state.showPerformance
        Utils.Logger.info("Performance overlay: %s", DevTools.state.showPerformance and "ON" or "OFF")
    elseif key == "f4" then
        DevTools.state.showDebugInfo = not DevTools.state.showDebugInfo
        Utils.Logger.info("Debug info: %s", DevTools.state.showDebugInfo and "ON" or "OFF")
    elseif key == "f5" then
        DevTools.state.paused = not DevTools.state.paused
        Utils.Logger.info("Game paused: %s", DevTools.state.paused and "ON" or "OFF")
    elseif key == "f6" then
        DevTools.state.slowMotion = not DevTools.state.slowMotion
        Utils.Logger.info("Slow motion: %s", DevTools.state.slowMotion and "ON" or "OFF")
    elseif key == "f7" then
        DevTools.resetGame()
    elseif key == "f8" then
        DevTools.takeScreenshot()
    elseif key == "f9" then
        DevTools.runTests()
    elseif key == "f10" then
        DevTools.generateDocumentation()
    end
end
-- Debug functions
function DevTools.resetGame()
    local GameState = Utils.require("src.core.game_state")
    GameState.reset()
    Utils.Logger.info("Game reset via debug command")
end
function DevTools.takeScreenshot()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("screenshot_%s.png", timestamp)
    local success = love.graphics.captureScreenshot(function(data)
        data:encode("png", filename)
    end)
    if success then
        Utils.Logger.info("Screenshot saved: %s", filename)
    else
        Utils.Logger.error("Failed to take screenshot")
    end
end
function DevTools.runTests()
    Utils.Logger.info("Running test suite...")
    local success, result  = Utils.ErrorHandler.safeCall(function()
        return Utils.require("tests.run_tests")
    end)
    if success then
        Utils.Logger.info("Tests completed successfully")
    else
        Utils.Logger.error("Tests failed: %s", result)
    end
end
function DevTools.generateDocumentation()
    Utils.Logger.info("Generating documentation...")
    local success, result  = Utils.ErrorHandler.safeCall(function()
        local DocsGenerator = Utils.require("src.dev.docs_generator")
        DocsGenerator.generateAll()
    end)
    if success then
        Utils.Logger.info("Documentation generated successfully")
    else
        Utils.Logger.error("Documentation generation failed: %s", result)
    end
end
-- Performance analysis
function DevTools.analyzePerformance()
    local PerformanceMonitor = Utils.require("src.performance.performance_monitor")
    local report = PerformanceMonitor.getReport()
    Utils.Logger.info("Performance Analysis:")
    Utils.Logger.info("  FPS: %.1f avg (%.1f min, %.1f max)",
        report.fps.average, report.fps.min, report.fps.max)
    Utils.Logger.info("  Frame Time: %.2fms avg", report.frameTime.average)
    Utils.Logger.info("  Memory: %.1f KB peak", report.memory.peak)
    Utils.Logger.info("  Collision Checks: %d (%.2fms)",
        report.collisions.count, report.collisions.time * 1000)
    -- Performance recommendations
    if report.fps.average < 30 then
        Utils.Logger.warn("Performance Issue: Low FPS detected")
    end
    if report.memory.peak > 10000 then
        Utils.Logger.warn("Performance Issue: High memory usage detected")
    end
    if report.collisions.time > 0.016 then
        Utils.Logger.warn("Performance Issue: Collision detection taking too long")
    end
end
-- Memory analysis
function DevTools.analyzeMemory()
    local memUsage = collectgarbage("count")
    local memStats = collectgarbage("count")
    Utils.Logger.info("Memory Analysis:")
    Utils.Logger.info("  Current Usage: %.1f KB", memUsage)
    Utils.Logger.info("  Memory Stats: %s", memStats)
    -- Force garbage collection
    collectgarbage("collect")
    local afterGC = collectgarbage("count")
    Utils.Logger.info("  After GC: %.1f KB", afterGC)
    Utils.Logger.info("  Freed: %.1f KB", memUsage - afterGC)
end
-- Game state inspection
function DevTools.inspectGameState()
    local GameState = Utils.require("src.core.game_state")
    Utils.Logger.info("Game State Inspection:")
    Utils.Logger.info("  Current State: %s", GameState.current)
    Utils.Logger.info("  Score: %d", GameState.getScore())
    Utils.Logger.info("  Combo: %d", GameState.getCombo())
    Utils.Logger.info("  Game Time: %.1fs", GameState.getGameTime())
    Utils.Logger.info("  Player Position: (%.1f, %.1f)", GameState.player.x, GameState.player.y)
    Utils.Logger.info("  Player Velocity: (%.1f, %.1f)", GameState.player.vx, GameState.player.vy)
    Utils.Logger.info("  On Planet: %s", GameState.player.onPlanet and tostring(GameState.player.onPlanet) or "None")
    Utils.Logger.info("  Particles: %d", #GameState.getParticles())
    Utils.Logger.info("  Rings Collected: %d/%d",
        #GameState.getRings() - #GameState.getUncollectedRings(), #GameState.getRings())
end
-- Update function for debug features
function DevTools.update(dt)
    if DevTools.state.paused then
        return 0 -- Return 0 delta time to pause the game
    end
    if DevTools.state.slowMotion then
        return dt * DevTools.state.slowMotionFactor
    end
    return dt
end
-- Draw function for debug features
function DevTools.draw()
    if not DevTools.state.debugMode then return end
    DevTools.debugDraw.hitboxes()
    DevTools.debugDraw.vectors()
    DevTools.debugDraw.info()
    if DevTools.state.showPerformance then
        local PerformanceMonitor = Utils.require("src.performance.performance_monitor")
        PerformanceMonitor.draw()
    end
    -- Draw debug controls help
    if DevTools.state.showDebugInfo then
        local help = {
            "F1: Toggle Debug Mode",
            "F2: Toggle Hitboxes",
            "F3: Toggle Performance Overlay",
            "F4: Toggle Debug Info",
            "F5: Pause/Resume",
            "F6: Slow Motion",
            "F7: Reset Game",
            "F8: Screenshot",
            "F9: Run Tests",
            "F10: Generate Docs"
        }
        Utils.setColor(Utils.colors.white, 0.8)
        for i, line in ipairs(help) do
            love.graphics.print(line, love.graphics.getWidth() - 200, 10 + (i - 1) * 20)
        end
    end
end
-- Initialize development tools
function DevTools.init()
    DevTools.state.debugMode = false
    DevTools.state.showHitboxes = false
    DevTools.state.showPerformance = false
    DevTools.state.showDebugInfo = false
    DevTools.state.paused = false
    DevTools.state.slowMotion = false
    Utils.Logger.info("Development tools initialized")
    Utils.Logger.info("Press F1 to toggle debug mode")
end
return DevTools