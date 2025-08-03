--[[
    ═══════════════════════════════════════════════════════════════════════════
    Game Loop - Update & Draw Loop Management
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles the main game loop, including update and draw cycles,
    performance monitoring, and system orchestration. It provides a clean
    separation between game loop logic and other game systems.
--]]

local Utils = require("src.utils.utils")
local PerformanceMonitor = require("src.performance.performance_monitor")

local GameLoop = {}

-- Game loop state
GameLoop.isRunning = false
GameLoop.isPaused = false
GameLoop.frameCount = 0
GameLoop.lastFrameTime = 0
GameLoop.deltaTime = 0
GameLoop.fps = 60
GameLoop.targetFPS = 60

-- Performance monitoring
GameLoop.performanceMetrics = {
    frameTime = 0,
    updateTime = 0,
    drawTime = 0,
    fps = 60,
    frameDrift = 0
}

-- System update priorities
GameLoop.updatePriorities = {
    critical = 1,    -- Input, physics, core game logic
    high = 2,        -- Game systems, AI
    medium = 3,      -- UI updates, effects
    low = 4          -- Background tasks, cleanup
}

-- Initialize game loop
function GameLoop.init()
    GameLoop.isRunning = true
    GameLoop.isPaused = false
    GameLoop.frameCount = 0
    GameLoop.lastFrameTime = love.timer.getTime()
    
    -- Initialize performance monitoring
    if PerformanceMonitor then
        PerformanceMonitor.init()
    end
    
    Utils.Logger.info("🔄 Game loop initialized")
    return true
end

-- Main update function
function GameLoop.update(dt)
    if not GameLoop.isRunning then return end
    
    local updateStartTime = love.timer.getTime()
    
    -- Update delta time and frame count
    GameLoop.deltaTime = dt
    GameLoop.frameCount = GameLoop.frameCount + 1
    
    -- Update performance metrics
    GameLoop.updatePerformanceMetrics(dt)
    
    -- Handle pause state
    if GameLoop.isPaused then
        GameLoop.updatePausedState(dt)
        return
    end
    
    -- Update systems in priority order
    GameLoop.updateCriticalSystems(dt)
    GameLoop.updateHighPrioritySystems(dt)
    GameLoop.updateMediumPrioritySystems(dt)
    GameLoop.updateLowPrioritySystems(dt)
    
    -- Update performance monitoring
    if PerformanceMonitor then
        PerformanceMonitor.update(dt)
    end
    
    -- Record update time
    GameLoop.performanceMetrics.updateTime = love.timer.getTime() - updateStartTime
end

-- Main draw function
function GameLoop.draw()
    if not GameLoop.isRunning then return end
    
    local drawStartTime = love.timer.getTime()
    
    -- Clear screen
    love.graphics.clear(0.1, 0.1, 0.2, 1)
    
    -- Draw game systems
    GameLoop.drawGameSystems()
    
    -- Draw UI systems
    GameLoop.drawUISystems()
    
    -- Draw performance overlay (if enabled)
    if PerformanceMonitor and PerformanceMonitor.isOverlayEnabled() then
        PerformanceMonitor.drawOverlay()
    end
    
    -- Record draw time
    GameLoop.performanceMetrics.drawTime = love.timer.getTime() - drawStartTime
end

-- Update critical systems (highest priority)
function GameLoop.updateCriticalSystems(dt)
    -- Update input handling
    GameLoop.updateInput(dt)
    
    -- Update core game logic
    GameLoop.updateCoreGameLogic(dt)
    
    -- Update physics/collision
    GameLoop.updatePhysics(dt)
end

-- Update high priority systems
function GameLoop.updateHighPrioritySystems(dt)
    -- Update game systems
    GameLoop.updateGameSystems(dt)
    
    -- Update AI systems
    GameLoop.updateAISystems(dt)
    
    -- Update audio systems
    GameLoop.updateAudioSystems(dt)
end

-- Update medium priority systems
function GameLoop.updateMediumPrioritySystems(dt)
    -- Update UI systems
    GameLoop.updateUISystems(dt)
    
    -- Update visual effects
    GameLoop.updateVisualEffects(dt)
    
    -- Update particle systems
    GameLoop.updateParticleSystems(dt)
end

-- Update low priority systems
function GameLoop.updateLowPrioritySystems(dt)
    -- Update background tasks
    GameLoop.updateBackgroundTasks(dt)
    
    -- Update cleanup systems
    GameLoop.updateCleanupSystems(dt)
    
    -- Update analytics/monitoring
    GameLoop.updateAnalytics(dt)
end

-- Update input handling
function GameLoop.updateInput(dt)
    -- Handle keyboard input
    GameLoop.handleKeyboardInput()
    
    -- Handle mouse input
    GameLoop.handleMouseInput()
    
    -- Handle touch input (mobile)
    GameLoop.handleTouchInput()
end

-- Handle keyboard input
function GameLoop.handleKeyboardInput()
    -- Handle game-specific keyboard input
    if love.keyboard.isDown("escape") then
        GameLoop.togglePause()
    end
    
    if love.keyboard.isDown("f1") then
        GameLoop.togglePerformanceOverlay()
    end
    
    -- Delegate to game systems
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.handleInput then
        GameState.handleInput()
    end
end

-- Handle mouse input
function GameLoop.handleMouseInput()
    -- Handle mouse input for UI systems
    local UISystem = Utils.require("src.ui.ui_system")
    if UISystem and UISystem.handleMouseInput then
        UISystem.handleMouseInput()
    end
end

-- Handle touch input
function GameLoop.handleTouchInput()
    -- Handle touch input for mobile devices
    local UISystem = Utils.require("src.ui.ui_system")
    if UISystem and UISystem.handleTouchInput then
        UISystem.handleTouchInput()
    end
end

-- Update core game logic
function GameLoop.updateCoreGameLogic(dt)
    -- Update game state
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.update then
        GameState.update(dt)
    end
    
    -- Update game logic
    local GameLogic = Utils.require("src.core.game_logic")
    if GameLogic and GameLogic.update then
        GameLogic.update(dt)
    end
end

-- Update physics
function GameLoop.updatePhysics(dt)
    -- Update collision detection
    local CollisionSystem = Utils.require("src.systems.collision_system")
    if CollisionSystem and CollisionSystem.update then
        CollisionSystem.update(dt)
    end
    
    -- Update particle physics
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem and ParticleSystem.update then
        ParticleSystem.update(dt)
    end
end

-- Update game systems
function GameLoop.updateGameSystems(dt)
    -- Update progression system
    local ProgressionSystem = Utils.require("src.systems.progression_system")
    if ProgressionSystem and ProgressionSystem.update then
        ProgressionSystem.update(dt)
    end
    
    -- Update ring system
    local RingSystem = Utils.require("src.systems.ring_system")
    if RingSystem and RingSystem.update then
        RingSystem.update(dt)
    end
    
    -- Update streak system
    local StreakSystem = Utils.require("src.systems.streak.streak_system")
    if StreakSystem and StreakSystem.update then
        StreakSystem.update(dt)
    end
    
    -- Update XP system
    local XPSystem = Utils.require("src.systems.xp_system")
    if XPSystem and XPSystem.update then
        XPSystem.update(dt)
    end
    
    -- Update other game systems
    local systems = {
        "src.systems.world_generator",
        "src.systems.cosmic_events",
        "src.systems.warp_zones",
        "src.systems.map_system",
        "src.systems.warp_drive",
        "src.systems.artifact_system",
        "src.systems.save_system",
        "src.systems.achievement_system",
        "src.systems.upgrade_system",
        "src.systems.emotional_feedback"
    }
    
    for _, systemPath in ipairs(systems) do
        local system = Utils.require(systemPath)
        if system and system.update then
            system.update(dt)
        end
    end
end

-- Update AI systems
function GameLoop.updateAISystems(dt)
    -- Update AI systems if any
    -- This would include enemy AI, NPC behavior, etc.
end

-- Update audio systems
function GameLoop.updateAudioSystems(dt)
    -- Update sound manager
    if _G.GameSoundManager and _G.GameSoundManager.update then
        _G.GameSoundManager:update(dt)
    end
end

-- Update UI systems
function GameLoop.updateUISystems(dt)
    -- Update main UI system
    if _G.GameUISystem and _G.GameUISystem.update then
        _G.GameUISystem.update(dt)
    end
    
    -- Update UI animation system
    local UIAnimationSystem = Utils.require("src.ui.ui_animation_system")
    if UIAnimationSystem and UIAnimationSystem.update then
        UIAnimationSystem.update(dt)
    end
    
    -- Update feedback UI
    local FeedbackUI = Utils.require("src.ui.feedback_ui")
    if FeedbackUI and FeedbackUI.update then
        FeedbackUI.update(dt)
    end
end

-- Update visual effects
function GameLoop.updateVisualEffects(dt)
    -- Update streak effects
    local StreakEffects = Utils.require("src.systems.streak.streak_effects")
    if StreakEffects and StreakEffects.update then
        StreakEffects.update(dt)
    end
    
    -- Update other visual effects
    local systems = {
        "src.systems.particle_system",
        "src.systems.enhanced_pullback_indicator"
    }
    
    for _, systemPath in ipairs(systems) do
        local system = Utils.require(systemPath)
        if system and system.update then
            system.update(dt)
        end
    end
end

-- Update particle systems
function GameLoop.updateParticleSystems(dt)
    -- Update particle system
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem and ParticleSystem.update then
        ParticleSystem.update(dt)
    end
end

-- Update background tasks
function GameLoop.updateBackgroundTasks(dt)
    -- Update background processing tasks
    -- This could include data processing, analytics, etc.
end

-- Update cleanup systems
function GameLoop.updateCleanupSystems(dt)
    -- Update garbage collection and cleanup
    -- This could include object pooling cleanup, memory management, etc.
end

-- Update analytics
function GameLoop.updateAnalytics(dt)
    -- Update analytics and monitoring systems
    local PlayerAnalytics = Utils.require("src.systems.player_analytics")
    if PlayerAnalytics and PlayerAnalytics.update then
        PlayerAnalytics.update(dt)
    end
end

-- Update paused state
function GameLoop.updatePausedState(dt)
    -- Handle input while paused
    GameLoop.handlePausedInput()
    
    -- Update pause menu
    local PauseMenu = Utils.require("src.ui.pause_menu")
    if PauseMenu and PauseMenu.update then
        PauseMenu.update(dt)
    end
end

-- Handle paused input
function GameLoop.handlePausedInput()
    if love.keyboard.isDown("escape") then
        GameLoop.togglePause()
    end
end

-- Draw game systems
function GameLoop.drawGameSystems()
    -- Draw game state
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.draw then
        GameState.draw()
    end
    
    -- Draw renderer
    local Renderer = Utils.require("src.core.renderer")
    if Renderer and Renderer.draw then
        Renderer.draw()
    end
    
    -- Draw game systems
    local systems = {
        "src.systems.particle_system",
        "src.systems.streak.streak_system",
        "src.systems.enhanced_pullback_indicator"
    }
    
    for _, systemPath in ipairs(systems) do
        local system = Utils.require(systemPath)
        if system and system.draw then
            system.draw()
        end
    end
end

-- Draw UI systems
function GameLoop.drawUISystems()
    -- Draw main UI system
    if _G.GameUISystem and _G.GameUISystem.draw then
        _G.GameUISystem.draw()
    end
    
    -- Draw UI animation system
    local UIAnimationSystem = Utils.require("src.ui.ui_animation_system")
    if UIAnimationSystem and UIAnimationSystem.draw then
        UIAnimationSystem.draw()
    end
    
    -- Draw feedback UI
    local FeedbackUI = Utils.require("src.ui.feedback_ui")
    if FeedbackUI and FeedbackUI.draw then
        FeedbackUI.draw()
    end
    
    -- Draw pause menu if paused
    if GameLoop.isPaused then
        local PauseMenu = Utils.require("src.ui.pause_menu")
        if PauseMenu and PauseMenu.draw then
            PauseMenu.draw()
        end
    end
end

-- Update performance metrics
function GameLoop.updatePerformanceMetrics(dt)
    local currentTime = love.timer.getTime()
    
    -- Calculate FPS
    GameLoop.fps = 1 / dt
    GameLoop.performanceMetrics.fps = GameLoop.fps
    
    -- Calculate frame time
    GameLoop.performanceMetrics.frameTime = dt
    
    -- Calculate frame drift
    GameLoop.performanceMetrics.frameDrift = math.abs(dt - (1 / GameLoop.targetFPS))
    
    -- Update last frame time
    GameLoop.lastFrameTime = currentTime
end

-- Toggle pause state
function GameLoop.togglePause()
    GameLoop.isPaused = not GameLoop.isPaused
    
    if GameLoop.isPaused then
        Utils.Logger.info("⏸️ Game paused")
    else
        Utils.Logger.info("▶️ Game resumed")
    end
end

-- Toggle performance overlay
function GameLoop.togglePerformanceOverlay()
    if PerformanceMonitor then
        PerformanceMonitor.toggleOverlay()
    end
end

-- Stop game loop
function GameLoop.stop()
    GameLoop.isRunning = false
    Utils.Logger.info("🛑 Game loop stopped")
end

-- Resume game loop
function GameLoop.resume()
    GameLoop.isRunning = true
    Utils.Logger.info("▶️ Game loop resumed")
end

-- Get game loop status
function GameLoop.getStatus()
    return {
        is_running = GameLoop.isRunning,
        is_paused = GameLoop.isPaused,
        frame_count = GameLoop.frameCount,
        fps = GameLoop.fps,
        target_fps = GameLoop.targetFPS,
        performance_metrics = GameLoop.performanceMetrics
    }
end

-- Get performance metrics
function GameLoop.getPerformanceMetrics()
    return GameLoop.performanceMetrics
end

-- Set target FPS
function GameLoop.setTargetFPS(fps)
    GameLoop.targetFPS = math.max(1, fps)
    love.timer.setFPS(GameLoop.targetFPS)
    Utils.Logger.info("🎯 Target FPS set to %d", GameLoop.targetFPS)
end

-- Reset game loop
function GameLoop.reset()
    GameLoop.frameCount = 0
    GameLoop.lastFrameTime = love.timer.getTime()
    GameLoop.performanceMetrics = {
        frameTime = 0,
        updateTime = 0,
        drawTime = 0,
        fps = 60,
        frameDrift = 0
    }
    
    Utils.Logger.info("🔄 Game loop reset")
end

return GameLoop 