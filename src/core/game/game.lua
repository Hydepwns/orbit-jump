--[[
    ═══════════════════════════════════════════════════════════════════════════
    Game - Main Game Coordinator
    ═══════════════════════════════════════════════════════════════════════════
    
    This is the main coordinator for the game, orchestrating initialization,
    game loop management, and system coordination. It provides a clean interface
    for LÖVE2D callbacks and manages the overall game state.
    
    Refactored from the original monolithic game.lua to use a modular
    architecture with separate initialization, game loop, and system management.
--]]

local Utils = require("src.utils.utils")

-- Import the new modular components
local GameInitializer = require("src.core.game.game_initializer")
local GameLoop = require("src.core.game.game_loop")

local Game = {}

-- Game state
Game.isInitialized = false
Game.isRunning = false
Game.startTime = 0

-- System health monitoring
Game.systemHealth = {
    criticalSystems = {},
    recoveryAttempts = {},
    performanceMetrics = {
        lastFrameTime = 0,
        averageFrameTime = 0.016,  -- Target: 60fps
        frameDriftWarning = false
    }
}

-- Initialize game
function Game.init()
    Game.startTime = love.timer.getTime()
    Utils.Logger.info("🚀 Starting Orbit Jump with modular architecture")
    
    -- Initialize all game systems
    local success, errors = GameInitializer.init()
    if not success then
        Utils.Logger.error("❌ Game initialization failed")
        for _, error in ipairs(errors or {}) do
            Utils.Logger.error("  - %s", error)
        end
        return false
    end
    
    -- Initialize game loop
    local loopSuccess = GameLoop.init()
    if not loopSuccess then
        Utils.Logger.error("❌ Game loop initialization failed")
        return false
    end
    
    Game.isInitialized = true
    Game.isRunning = true
    
    local initTime = love.timer.getTime() - Game.startTime
    Utils.Logger.info("🎉 Game started successfully in %.2f seconds", initTime)
    
    return true
end

-- Update game (called every frame)
function Game.update(dt)
    if not Game.isInitialized or not Game.isRunning then
        return
    end
    
    -- Update game loop
    GameLoop.update(dt)
    
    -- Monitor system health
    Game.monitorSystemHealth(dt)
    
    -- Handle system recovery if needed
    Game.handleSystemRecovery()
end

-- Draw game (called every frame)
function Game.draw()
    if not Game.isInitialized or not Game.isRunning then
        return
    end
    
    -- Draw game loop
    GameLoop.draw()
    
    -- Draw system health indicators if needed
    if Game.systemHealth.frameDriftWarning then
        Game.drawSystemHealthWarning()
    end
end

-- Monitor system health
function Game.monitorSystemHealth(dt)
    -- Update performance metrics
    Game.systemHealth.performanceMetrics.lastFrameTime = dt
    Game.systemHealth.performanceMetrics.averageFrameTime = 
        Game.systemHealth.performanceMetrics.averageFrameTime * 0.9 + dt * 0.1
    
    -- Check for frame drift
    local targetFrameTime = 1 / 60
    local frameDrift = math.abs(dt - targetFrameTime)
    if frameDrift > targetFrameTime * 0.1 then -- More than 10% drift
        Game.systemHealth.performanceMetrics.frameDriftWarning = true
        Utils.Logger.warning("⚠️ Frame drift detected: %.3f ms", frameDrift * 1000)
    else
        Game.systemHealth.performanceMetrics.frameDriftWarning = false
    end
    
    -- Monitor critical systems
    Game.monitorCriticalSystems()
end

-- Monitor critical systems
function Game.monitorCriticalSystems()
    local criticalSystems = {
        gameState = _G.GameState,
        renderer = _G.Renderer,
        camera = _G.GameCamera,
        soundManager = _G.GameSoundManager,
        uiSystem = _G.GameUISystem
    }
    
    for name, system in pairs(criticalSystems) do
        if not system then
            Game.systemHealth.criticalSystems[name] = {
                status = "missing",
                lastCheck = love.timer.getTime()
            }
            Utils.Logger.error("🚨 Critical system missing: %s", name)
        else
            Game.systemHealth.criticalSystems[name] = {
                status = "healthy",
                lastCheck = love.timer.getTime()
            }
        end
    end
end

-- Handle system recovery
function Game.handleSystemRecovery()
    local currentTime = love.timer.getTime()
    
    for systemName, health in pairs(Game.systemHealth.criticalSystems) do
        if health.status == "missing" then
            -- Attempt recovery
            local recoveryAttempts = Game.systemHealth.recoveryAttempts[systemName] or 0
            if recoveryAttempts < 3 then -- Limit recovery attempts
                Game.systemHealth.recoveryAttempts[systemName] = recoveryAttempts + 1
                Utils.Logger.warning("🔄 Attempting recovery for system: %s (attempt %d)", systemName, recoveryAttempts + 1)
                
                -- Attempt to reload the system
                local success = Game.attemptSystemRecovery(systemName)
                if success then
                    health.status = "recovered"
                    Utils.Logger.info("✅ System recovered: %s", systemName)
                end
            else
                Utils.Logger.error("❌ System recovery failed after 3 attempts: %s", systemName)
            end
        end
    end
end

-- Attempt system recovery
function Game.attemptSystemRecovery(systemName)
    -- This would attempt to reload or reinitialize the system
    -- For now, just log the attempt
    Utils.Logger.info("🔄 Recovery attempt for system: %s", systemName)
    return false -- Recovery not implemented yet
end

-- Draw system health warning
function Game.drawSystemHealthWarning()
    love.graphics.setColor(1, 0.5, 0, 0.8)
    love.graphics.print("⚠️ Performance Warning", 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle window resize
function Game.resize(w, h)
    if not Game.isInitialized then return end
    
    Utils.Logger.info("📐 Window resized to %dx%d", w, h)
    
    -- Update camera dimensions
    if _G.GameCamera then
        _G.GameCamera.screenWidth = w
        _G.GameCamera.screenHeight = h
    end
    
    -- Update UI system
    if _G.GameUISystem and _G.GameUISystem.resize then
        _G.GameUISystem.resize(w, h)
    end
    
    -- Update game state
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.resize then
        GameState.resize(w, h)
    end
end

-- Handle key press
function Game.keypressed(key, scancode, isrepeat)
    if not Game.isInitialized then return end
    
    -- Handle global key presses
    if key == "f11" then
        Game.toggleFullscreen()
    elseif key == "f12" then
        Game.takeScreenshot()
    end
    
    -- Delegate to game systems
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.keypressed then
        GameState.keypressed(key, scancode, isrepeat)
    end
end

-- Handle key release
function Game.keyreleased(key, scancode)
    if not Game.isInitialized then return end
    
    -- Delegate to game systems
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.keyreleased then
        GameState.keyreleased(key, scancode)
    end
end

-- Handle mouse press
function Game.mousepressed(x, y, button, istouch, presses)
    if not Game.isInitialized then return end
    
    -- Delegate to UI system
    if _G.GameUISystem and _G.GameUISystem.mousepressed then
        _G.GameUISystem.mousepressed(x, y, button, istouch, presses)
    end
end

-- Handle mouse release
function Game.mousereleased(x, y, button, istouch, presses)
    if not Game.isInitialized then return end
    
    -- Delegate to UI system
    if _G.GameUISystem and _G.GameUISystem.mousereleased then
        _G.GameUISystem.mousereleased(x, y, button, istouch, presses)
    end
end

-- Handle mouse movement
function Game.mousemoved(x, y, dx, dy, istouch)
    if not Game.isInitialized then return end
    
    -- Delegate to UI system
    if _G.GameUISystem and _G.GameUISystem.mousemoved then
        _G.GameUISystem.mousemoved(x, y, dx, dy, istouch)
    end
end

-- Handle touch press
function Game.touchpressed(id, x, y, dx, dy, pressure)
    if not Game.isInitialized then return end
    
    -- Delegate to UI system
    if _G.GameUISystem and _G.GameUISystem.touchpressed then
        _G.GameUISystem.touchpressed(id, x, y, dx, dy, pressure)
    end
end

-- Handle touch release
function Game.touchreleased(id, x, y, dx, dy, pressure)
    if not Game.isInitialized then return end
    
    -- Delegate to UI system
    if _G.GameUISystem and _G.GameUISystem.touchreleased then
        _G.GameUISystem.touchreleased(id, x, y, dx, dy, pressure)
    end
end

-- Handle touch movement
function Game.touchmoved(id, x, y, dx, dy, pressure)
    if not Game.isInitialized then return end
    
    -- Delegate to UI system
    if _G.GameUISystem and _G.GameUISystem.touchmoved then
        _G.GameUISystem.touchmoved(id, x, y, dx, dy, pressure)
    end
end

-- Toggle fullscreen
function Game.toggleFullscreen()
    local fullscreen = love.window.getFullscreen()
    love.window.setFullscreen(not fullscreen)
    Utils.Logger.info("🖥️ Fullscreen %s", not fullscreen and "enabled" or "disabled")
end

-- Take screenshot
function Game.takeScreenshot()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("screenshot_%s.png", timestamp)
    
    local success = love.graphics.captureScreenshot(filename)
    if success then
        Utils.Logger.info("📸 Screenshot saved: %s", filename)
    else
        Utils.Logger.error("❌ Failed to save screenshot")
    end
end

-- Pause game
function Game.pause()
    if Game.isRunning then
        GameLoop.togglePause()
    end
end

-- Resume game
function Game.resume()
    if Game.isRunning then
        GameLoop.togglePause()
    end
end

-- Stop game
function Game.stop()
    Game.isRunning = false
    GameLoop.stop()
    Utils.Logger.info("🛑 Game stopped")
end

-- Restart game
function Game.restart()
    Utils.Logger.info("🔄 Restarting game...")
    
    -- Stop current game
    Game.stop()
    
    -- Reset systems
    GameInitializer.reset()
    GameLoop.reset()
    
    -- Reinitialize
    local success = Game.init()
    if success then
        Utils.Logger.info("✅ Game restarted successfully")
    else
        Utils.Logger.error("❌ Game restart failed")
    end
    
    return success
end

-- Get game status
function Game.getStatus()
    return {
        is_initialized = Game.isInitialized,
        is_running = Game.isRunning,
        uptime = love.timer.getTime() - Game.startTime,
        system_health = Game.systemHealth,
        game_loop_status = GameLoop.getStatus(),
        initializer_status = GameInitializer.getSystemStatus()
    }
end

-- Get performance metrics
function Game.getPerformanceMetrics()
    return {
        game_loop = GameLoop.getPerformanceMetrics(),
        system_health = Game.systemHealth.performanceMetrics,
        uptime = love.timer.getTime() - Game.startTime
    }
end

-- Shutdown game
function Game.shutdown()
    Utils.Logger.info("🛑 Shutting down game...")
    
    -- Stop game loop
    GameLoop.stop()
    
    -- Shutdown systems
    local systems = {
        "src.systems.save_system",
        "src.systems.achievement_system",
        "src.systems.player_analytics"
    }
    
    for _, systemPath in ipairs(systems) do
        local system = Utils.require(systemPath)
        if system and system.shutdown then
            system.shutdown()
        end
    end
    
    -- Shutdown audio
    if _G.GameSoundManager and _G.GameSoundManager.shutdown then
        _G.GameSoundManager:shutdown()
    end
    
    Game.isInitialized = false
    Game.isRunning = false
    
    Utils.Logger.info("✅ Game shutdown complete")
end

-- Focus gained
function Game.focus(focused)
    if focused then
        Utils.Logger.info("🎯 Game window focused")
        -- Resume audio if needed
        if _G.GameSoundManager and _G.GameSoundManager.resume then
            _G.GameSoundManager:resume()
        end
    else
        Utils.Logger.info("🔍 Game window lost focus")
        -- Pause audio if needed
        if _G.GameSoundManager and _G.GameSoundManager.pause then
            _G.GameSoundManager:pause()
        end
    end
end

-- Quit game
function Game.quit()
    Utils.Logger.info("👋 Quitting game...")
    Game.shutdown()
    love.event.quit()
end

return Game 