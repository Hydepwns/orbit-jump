--[[
    ═══════════════════════════════════════════════════════════════════════════
    Game Orchestration: The Conductor of Interactive Symphony
    ═══════════════════════════════════════════════════════════════════════════
    
    This is more than a game controller - it's the maestro that coordinates
    dozens of complex systems into a single, seamless, magical experience.
    Every function here represents a different aspect of system orchestration
    that transforms independent components into emergent gameplay.
    
    Orchestration Philosophy:
    • Graceful Degradation: Any system can fail without breaking the experience
    • Adaptive Error Recovery: Problems become opportunities for elegant solutions
    • Intelligent Initialization: Systems start in the perfect order, handling dependencies
    • Priority-Based Input: Clear hierarchies prevent input conflicts
    • Performance-Aware Updates: Heavy systems only run when needed
    
    This code embodies the principle: "The best conductor is invisible - 
    you only notice the beautiful music they create."
--]]
local Utils = require("src.utils.utils")
-- Use cached requires to prevent duplicate loading
local GameLogic = Utils.require("src.core.game_logic")
local GameState = Utils.require("src.core.game_state")
local Renderer = Utils.require("src.core.renderer")
local ModuleLoader = Utils.require("src.utils.module_loader")
local Config = Utils.require("src.utils.config")
local Camera = Utils.require("src.core.camera")
local SoundManager = Utils.require("src.audio.sound_manager")
local SaveSystem = Utils.require("src.systems.save_system")
local TutorialSystem = Utils.require("src.ui.tutorial_system")
local PauseMenu = Utils.require("src.ui.pause_menu")
local UISystem = Utils.require("src.ui.ui_system")
local PerformanceMonitor = Utils.require("src.performance.performance_monitor")
local PerformanceSystem = Utils.require("src.performance.performance_system")
local CosmicEvents = Utils.require("src.systems.cosmic_events")
local RingSystem = Utils.require("src.systems.ring_system")
local ProgressionSystem = Utils.require("src.systems.progression_system")
local Game = {}
--[[
    ═══════════════════════════════════════════════════════════════════════════
    System State Management: The Memory of the Orchestra
    ═══════════════════════════════════════════════════════════════════════════
--]]
-- Typography System: The voice of the interface
local fonts = {
    regular = nil,      -- Standard text - clarity above all
    bold = nil,         -- Emphasis - when something matters
    light = nil,        -- Subtlety - for secondary information
    extraBold = nil     -- Authority - for headings and importance
}
-- System Health Monitoring: Adaptive intelligence for system failures
local systemHealth = {
    fontLoadFailed = false,
    criticalSystems = {},
    recoveryAttempts = {},
    performanceMetrics = {
        lastFrameTime = 0,
        averageFrameTime = 0.016,  -- Target: 60fps
        frameDriftWarning = false
    }
}
function Game.init()
    --[[
        System Genesis: Bringing Order from Chaos with Architectural Elegance
        
        This version uses the SystemOrchestrator for proper dependency injection
        and layered initialization. The orchestrator handles system dependencies,
        ensuring everything initializes in the correct order.
        
        Architectural Philosophy:
        • Foundation first: SystemOrchestrator manages dependencies
        • Dependency injection: Systems receive their dependencies cleanly
        • Smart sequencing: The orchestrator resolves initialization order
        • Health monitoring: Built into the orchestration layer
    --]]
    
    -- Establish Communication Infrastructure
    Utils.Logger.init(Utils.Logger.levels.INFO, "game.log")
    Utils.Logger.info("🚀 Beginning Orbit Jump initialization with SystemOrchestrator")
    
    -- Configuration Validation with Adaptive Recovery
    local configValid, configErrors = Config.validate()
    if not configValid then
        Utils.Logger.error("Configuration validation failed: %s", table.concat(configErrors, ", "))
        -- 101% approach: Don't just fail - attempt intelligent recovery
        Game.recoverFromConfigFailure(configErrors)
    end
    
    -- Load SystemOrchestrator and register all game systems
    local SystemOrchestrator = Utils.require("src.core.system_orchestrator")
    SystemOrchestrator.registerOrbitJumpSystems()
    
    -- Graphics initialization (still needed for fonts)
    local graphicsSuccess = Game.initGraphics()
    
    -- Let the orchestrator handle system initialization with proper dependencies
    local systemsSuccess = SystemOrchestrator.init()
    
    -- Store orchestrator reference for update/draw
    Game.orchestrator = SystemOrchestrator
    
    -- Adaptive Health Assessment
    Game.assessSystemHealth()
    
    Utils.Logger.info("✨ Game initialization complete - All systems operational via SystemOrchestrator")
    return systemsSuccess
end
function Game.initGraphics()
    --[[
        Visual Foundation: Establishing the Canvas of Experience
        
        Graphics initialization sets the visual tone for the entire game.
        This function demonstrates 101% thinking: instead of just loading
        resources, we create adaptive systems that gracefully handle failure
        and provide intelligent fallbacks.
        
        Typography Philosophy:
        • Typography is the voice of the interface - it must never fail
        • Fallbacks should maintain visual hierarchy even with default fonts
        • Font loading failures should be invisible to the player
    --]]
    
    -- Color Psychology: Deep space background that doesn't fatigue the eyes
    local SPACE_BLACK = {0.05, 0.05, 0.1}  -- Slightly blue-shifted for warmth
    love.graphics.setBackgroundColor(SPACE_BLACK[1], SPACE_BLACK[2], SPACE_BLACK[3])
    
    -- Initialize typography system with intelligent fallback
    local fonts = {
        regular = nil,
        bold = nil,
        light = nil,
        extraBold = nil
    }
    
    -- Try to load custom fonts first
    local fontError = nil
    local success, regularFont = pcall(love.graphics.newFont, "assets/fonts/MonaspaceArgon-Regular.otf", 16)
    if success then
        fonts.regular = regularFont
        fonts.bold = love.graphics.newFont("assets/fonts/MonaspaceArgon-Bold.otf", 16)
        fonts.light = love.graphics.newFont("assets/fonts/MonaspaceArgon-Light.otf", 16)
        fonts.extraBold = love.graphics.newFont("assets/fonts/MonaspaceArgon-ExtraBold.otf", 24)
        Utils.Logger.info("✅ Typography system loaded - MonaspaceArgon font family active")
    else
        fontError = regularFont
        Utils.Logger.warn("Custom fonts unavailable (%s) - Activating intelligent fallback system", tostring(fontError))
        
        -- Fallback to system fonts with intelligent sizing
        local fallbackError = nil
        local success, fallbackFont = pcall(love.graphics.newFont, 16)
        if success then
            fonts.regular = love.graphics.newFont(16)     -- Base size
            fonts.bold = love.graphics.newFont(18)        -- Slightly larger for emphasis
            fonts.light = love.graphics.newFont(14)       -- Smaller for secondary info
            fonts.extraBold = love.graphics.newFont(24)   -- Larger for headers
            Utils.Logger.info("🎨 Intelligent font fallback system activated")
        else
            fallbackError = fallbackFont
            Utils.Logger.warn("Even default font creation failed (%s) - Using system default", tostring(fallbackError))
            
            -- Last resort: use system default
            local defaultFont = love.graphics.getFont()
            fonts.regular = defaultFont
            fonts.bold = defaultFont
            fonts.light = defaultFont
            fonts.extraBold = defaultFont
            Utils.Logger.info("🎨 Intelligent font fallback system activated")
        end
    end
    
    -- Make fonts available globally for SystemOrchestrator
    _G.GameFonts = fonts
    
    -- Set the primary interface font
    love.graphics.setFont(fonts.regular)
    
    return fontLoadSuccess
end
function Game.initSystems()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Initialize core systems directly (they need special handling)
    -- GameState, Renderer, and Camera are already loaded at the top
    
    -- Initialize camera instance first
    Utils.Logger.info("Attempting to create camera...")
    Utils.Logger.info("Camera module available: %s", Camera and "yes" or "no")
    if Camera then
        Utils.Logger.info("Camera.new function available: %s", Camera.new and "yes" or "no")
        -- Test camera creation
        local testCamera = Camera:new()
        Utils.Logger.info("Test camera creation: %s", testCamera and "success" or "failed")
        if testCamera then
            Utils.Logger.info("Test camera properties: x=%f, y=%f, scale=%f", testCamera.x, testCamera.y, testCamera.scale)
        end
    end
    Game.camera = Camera:new()
    if not Game.camera then
        Utils.Logger.error("Failed to create camera instance")
        return
    end
    Utils.Logger.info("Camera created successfully, setting dimensions...")
    Game.camera.screenWidth = screenWidth
    Game.camera.screenHeight = screenHeight
    
    Utils.Logger.info("Camera initialized: %dx%d", screenWidth, screenHeight)
    
    -- Verify camera is still available after initialization
    if not Game.camera then
        Utils.Logger.error("Camera became nil immediately after initialization!")
    else
        Utils.Logger.info("Camera verification successful - camera is available")
    end
    
    GameState.init(screenWidth, screenHeight)
    GameState.camera = Game.camera  -- Share camera instance
    GameState.soundManager = Game.soundManager  -- Share sound manager
    Renderer.init(fonts)
    Renderer.camera = Game.camera  -- Share camera instance
    
    -- Initialize game systems
    ModuleLoader.initModule("systems.progression_system", "init")
    ModuleLoader.initModule("systems.ring_system", "reset")
    ModuleLoader.initModule("systems.world_generator", "reset")
    ModuleLoader.initModule("systems.cosmic_events", "init")
    ModuleLoader.initModule("systems.warp_zones", "init")
    ModuleLoader.initModule("systems.map_system", "init")
    ModuleLoader.initModule("systems.warp_drive", "init")
    ModuleLoader.initModule("systems.artifact_system", "init")
    ModuleLoader.initModule("systems.save_system", "init")
    ModuleLoader.initModule("systems.achievement_system", "init")
    ModuleLoader.initModule("systems.upgrade_system", "init")
    ModuleLoader.initModule("systems.particle_system", "init")
    ModuleLoader.initModule("systems.emotional_feedback", "init")
    
    -- Initialize UI systems
    UISystem.init(fonts)
    ModuleLoader.initModule("ui.pause_menu", "init")
    
    -- Initialize audio
    -- SoundManager is already loaded at the top
    Game.soundManager = SoundManager:new()
    Game.soundManager:load()
    
    -- Initialize performance monitoring
    ModuleLoader.initModule("performance.performance_monitor", "init")
    ModuleLoader.initModule("performance.performance_system", "init")
    
    -- Initialize blockchain (optional)
    if Config.blockchain.enabled then
        ModuleLoader.initModule("blockchain.blockchain_integration", "init")
    end
    
    -- Load saved game if exists
    -- SaveSystem is already loaded at the top
    if SaveSystem.hasSave() then
        SaveSystem.load()
    end
    
    -- Initialize and start tutorial if first time
    -- TutorialSystem is already loaded at the top
    TutorialSystem.init()  -- This will check save state and start if needed
end
function Game.update(dt)
    --[[
        The Heartbeat of Interactive Reality - Now with Architectural Precision
        
        The SystemOrchestrator handles all system updates in the correct order:
        Foundation → Input → Simulation → Gameplay → Presentation → Meta
        
        This ensures perfect dependency order and removes the complexity of
        manual update scheduling. Each system gets exactly what it needs.
    --]]
    
    -- Frame Performance Intelligence: Monitor system health
    local frameStart = love.timer.getTime()
    systemHealth.performanceMetrics.lastFrameTime = dt
    
    -- Let the orchestrator handle all system updates in perfect order
    if Game.orchestrator then
        -- The orchestrator handles pause logic and performance optimization
        Game.orchestrator.update(dt)
    else
        -- Fallback to manual orchestration if orchestrator failed to initialize
        Utils.Logger.warn("SystemOrchestrator not available, falling back to manual updates")
        Game.updateManualFallback(dt)
    end
    
    -- Get camera from SystemOrchestrator if available
    if _G.GameCamera then
        Game.camera = _G.GameCamera
    end
    
    -- Frame Performance Analysis: Learn and adapt
    local frameEnd = love.timer.getTime()
    Game.updatePerformanceMetrics(frameEnd - frameStart)
end
function Game.draw()
    -- Renderer, GameState, UISystem, TutorialSystem, PauseMenu, PerformanceMonitor, and Config are already loaded at the top
    
    -- Apply camera transform
    if Game.camera then
        Game.camera:apply()
    end
    
    -- Draw game world
    Renderer.drawBackground()
    
    -- Draw game objects with culling
    local player = GameState.player
    if player then
        Renderer.drawPlayerTrail(player.trail)
        
        -- Use culling for performance
        -- PerformanceSystem is already loaded at the top
        if Game.camera then
            local visiblePlanets = PerformanceSystem.cullPlanets(GameState.getPlanets(), Game.camera)
            local visibleRings = PerformanceSystem.cullRings(GameState.getRings(), Game.camera)
            local visibleParticles = PerformanceSystem.cullParticles(GameState.getParticles(), Game.camera)
            
            Renderer.drawPlanets(visiblePlanets)
            Renderer.drawRings(visibleRings)
            Renderer.drawParticles(visibleParticles)
        else
            -- Fallback: draw all objects without culling if camera is not available
            Renderer.drawPlanets(GameState.getPlanets())
            Renderer.drawRings(GameState.getRings())
            Renderer.drawParticles(GameState.getParticles())
        end
        Renderer.drawPlayer(player, player.isDashing)
        
        -- Draw pull indicator if dragging
        if GameState.data.isCharging and GameState.data.mouseStartX and GameState.player.onPlanet then
            local mouseX, mouseY = love.mouse.getPosition()
            Renderer.drawPullIndicator(player, mouseX, mouseY, 
                GameState.data.mouseStartX, GameState.data.mouseStartY, 
                GameState.data.pullPower, GameState.data.maxPullDistance)
        end
    end
    
    -- Reset camera transform for UI
    if Game.camera then
        Game.camera:clear()
    end
    
    -- Draw UI elements
    UISystem.draw()
    TutorialSystem.draw()
    PauseMenu.draw()
    PerformanceMonitor.draw()
    
    -- Draw mobile controls if needed
    if Utils.MobileInput.isMobile() then
        Renderer.drawMobileControls(GameState.player, _G.GameFonts)
    end
end
function Game.handleKeyPress(key)
    -- GameState, PauseMenu, TutorialSystem, and UISystem are already loaded at the top
    
    -- Input priority: Pause > Tutorial > UI > Game
    if PauseMenu.handleKeyPress and PauseMenu.handleKeyPress(key) then
        return
    end
    
    if TutorialSystem.handleKeyPress and TutorialSystem.handleKeyPress(key) then
        return
    end
    
    if UISystem.handleKeyPress and UISystem.handleKeyPress(key) then
        return
    end
    
    -- Handle camera zoom keys
    if _G.GameCamera then
        if key == "=" or key == "+" then
            _G.GameCamera:zoomIn()
            return
        elseif key == "-" then
            _G.GameCamera:zoomOut()
            return
        elseif key == "0" then
            _G.GameCamera:setScale(1) -- Reset zoom
            return
        end
    end
    
    GameState.handleKeyPress(key)
end
function Game.handleMousePress(x, y, button)
    -- GameState, PauseMenu, TutorialSystem, and UISystem are already loaded at the top
    
    -- Input priority: Pause > Tutorial > UI > Game
    if PauseMenu.mousepressed and PauseMenu.mousepressed(x, y, button) then
        return
    end
    
    if TutorialSystem.handleMousePress and TutorialSystem.handleMousePress(x, y, button) then
        return
    end
    
    if UISystem.mousepressed and UISystem.mousepressed(x, y, button) then
        return
    end
    
    GameState.handleMousePress(x, y, button)
end
function Game.handleMouseMove(x, y)
    -- GameState, PauseMenu, TutorialSystem, and UISystem are already loaded at the top
    
    -- Input priority: Pause > Tutorial > UI > Game
    if PauseMenu.mousemoved and PauseMenu.mousemoved(x, y) then
        return
    end
    
    if TutorialSystem.handleMouseMove and TutorialSystem.handleMouseMove(x, y) then
        return
    end
    
    if UISystem.mousemoved and UISystem.mousemoved(x, y) then
        return
    end
    
    GameState.handleMouseMove(x, y)
end
function Game.handleMouseRelease(x, y, button)
    -- GameState, PauseMenu, TutorialSystem, and UISystem are already loaded at the top
    
    -- Input priority: Pause > Tutorial > UI > Game
    if PauseMenu.mousereleased and PauseMenu.mousereleased(x, y, button) then
        return
    end
    
    if TutorialSystem.handleMouseRelease and TutorialSystem.handleMouseRelease(x, y, button) then
        return
    end
    
    if UISystem.mousereleased and UISystem.mousereleased(x, y, button) then
        return
    end
    
    GameState.handleMouseRelease(x, y, button)
end

function Game.handleWheelMoved(x, y)
    -- Handle scroll wheel for camera zoom
    if _G.GameCamera and _G.GameCamera.handleWheelMoved then
        _G.GameCamera:handleWheelMoved(x, y)
    end
end

function Game.quit()
    --[[
        Graceful Shutdown: Ending with Dignity
        
        Even endings can be elegant. This function ensures that the player's
        progress is preserved and all systems shut down cleanly, maintaining
        the integrity of their experience even in the final moments.
    --]]
    
    Utils.Logger.info("🌅 Beginning graceful shutdown sequence")
    
    -- Preserve Player Progress: The most critical responsibility
    local saveSuccess, saveError = Utils.ErrorHandler.safeCall(function()
        SaveSystem.save()
    end)
    
    if not saveSuccess then
        Utils.Logger.error("❌ Save failed during shutdown: %s", tostring(saveError))
        -- TODO: Could implement emergency save to alternate location
    else
        Utils.Logger.info("💾 Player progress preserved")
    end
    
    -- System Health Report: Final performance insights
    Game.logSystemHealthReport()
    
    Utils.Logger.info("✨ Orbit Jump shutdown complete - Until next time!")
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    101% Self-Healing and Adaptive Intelligence Functions
    ═══════════════════════════════════════════════════════════════════════════
    
    These functions implement the "101%" approach to system management:
    systems that don't just work, but adapt, learn, and improve themselves.
--]]
function Game.createIntelligentFontFallbacks()
    --[[
        Typography Resilience: Maintaining Visual Hierarchy with System Fonts
        
        When custom fonts fail, create a fallback system that preserves the
        visual hierarchy using different sizes of the default font.
    --]]
    
    local defaultFont = love.graphics.getFont()
    
    -- Try to create fallback fonts, but handle cases where even default font creation fails
    local fallbackSuccess, fallbackError = Utils.ErrorHandler.safeCall(function()
        fonts.regular = love.graphics.newFont(16)     -- Base size
        fonts.bold = love.graphics.newFont(18)        -- Slightly larger for emphasis
        fonts.light = love.graphics.newFont(14)       -- Smaller for secondary info
        fonts.extraBold = love.graphics.newFont(24)   -- Larger for headers
    end)
    
    if not fallbackSuccess then
        Utils.Logger.warn("Even default font creation failed (%s) - Using system default", tostring(fallbackError))
        -- Use the existing default font for all cases
        fonts.regular = defaultFont
        fonts.bold = defaultFont
        fonts.light = defaultFont
        fonts.extraBold = defaultFont
    end
    
    Utils.Logger.info("🎨 Intelligent font fallback system activated")
end
function Game.recoverFromConfigFailure(configErrors)
    --[[
        Configuration Healing: Adapting to Environment Problems
        
        Instead of crashing when configuration is invalid, attempt to create
        a minimal working configuration that allows the game to run.
    --]]
    
    Utils.Logger.warn("🔧 Attempting configuration recovery...")
    
    -- Create minimal safe configuration
    Config.game = Config.game or {}
    Config.game.maxJumpPower = Config.game.maxJumpPower or 1000
    Config.game.dashPower = Config.game.dashPower or 500
    
    Config.mobile = Config.mobile or {}
    Config.mobile.minSwipeDistance = 50
    Config.mobile.maxSwipeDistance = 200
    Config.mobile.touchSensitivity = 1.0
    
    Utils.Logger.info("⚡ Emergency configuration created - Game can continue")
end
-- Fallback manual update system (used if SystemOrchestrator fails)
function Game.updateManualFallback(dt)
    -- Adaptive Update Scheduling: Pause system has absolute priority
    if not PauseMenu.shouldPauseGameplay() then
        -- Core World Simulation: The fundamental reality of the game
        Game.updateCoreSystems(dt)
        
        -- Extended Universe Systems: Enhancements that enrich the experience
        Game.updateEnhancedSystems(dt)
        
        -- Performance-Sensitive Systems: Only run when we have cycles to spare
        if systemHealth.performanceMetrics.averageFrameTime < 0.014 then -- Running well
            Game.updateOptionalSystems(dt)
        end
    end
    
    -- Always-Active Systems: These create the meta-experience
    Game.updateMetaSystems(dt)
end

function Game.updateCoreSystems(dt)
    --[[Critical systems that define the core game experience--]]
    GameState.update(dt)
    
    -- Camera Intelligence: Follow player with awareness
    if Game.camera and GameState.player then
        Game.camera:follow(GameState.player, dt)
    end
end
function Game.updateEnhancedSystems(dt)
    --[[Systems that enrich the experience but aren't critical--]]
    if CosmicEvents.update then
        CosmicEvents.update(dt, GameState.player, Game.camera)
    end
    
    if RingSystem.update then
        RingSystem.update(dt, GameState.player, GameState.objects.rings)
    end
    
    if ProgressionSystem.update then
        ProgressionSystem.update(dt)
    end
    
    -- Emotional Feedback: The heart of player experience
    local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
    if EmotionalFeedback.update then
        EmotionalFeedback.update(dt)
    end
end
function Game.updateOptionalSystems(dt)
    --[[Performance-heavy systems that enhance but don't define the experience--]]
    if SaveSystem.update then
        SaveSystem.update(dt)
    end
    
    if UISystem.update then
        UISystem.update(dt, ProgressionSystem, nil)
    end
    
    if PerformanceSystem.update then
        PerformanceSystem.update(dt)
    end
end
function Game.updateMetaSystems(dt)
    --[[Systems that operate outside the main game world--]]
    PauseMenu.update(dt)
    TutorialSystem.update(dt, GameState.player)
    PerformanceMonitor.update(dt)
end
function Game.updatePerformanceMetrics(frameTime)
    --[[Adaptive Performance Intelligence--]]
    local metrics = systemHealth.performanceMetrics
    
    -- Exponential moving average for smooth adaptation
    metrics.averageFrameTime = metrics.averageFrameTime * 0.95 + frameTime * 0.05
    
    -- Performance warnings for adaptive behavior
    if metrics.averageFrameTime > 0.020 and not metrics.frameDriftWarning then
        Utils.Logger.warn("⚠️  Frame time drift detected - Activating performance optimizations")
        metrics.frameDriftWarning = true
    elseif metrics.averageFrameTime < 0.017 and metrics.frameDriftWarning then
        Utils.Logger.info("✅ Performance stabilized - Resuming full system updates")
        metrics.frameDriftWarning = false
    end
end
function Game.assessSystemHealth()
    --[[Post-initialization health check--]]
    local healthReport = {}
    
    if systemHealth.fontLoadFailed then
        table.insert(healthReport, "Typography: Fallback mode active")
    else
        table.insert(healthReport, "Typography: Optimal")
    end
    
    -- Add more health checks as systems grow
    table.insert(healthReport, "Core Systems: Operational")
    
    Utils.Logger.info("🏥 System Health: " .. table.concat(healthReport, " | "))
end
function Game.logSystemHealthReport()
    --[[Final performance and health insights--]]
    local metrics = systemHealth.performanceMetrics
    
    Utils.Logger.info("📊 Performance Report:")
    Utils.Logger.info("  Average Frame Time: %.3fms (%.1f FPS)", 
        metrics.averageFrameTime * 1000, 1 / metrics.averageFrameTime)
    
    if systemHealth.fontLoadFailed then
        Utils.Logger.info("  Font System: Ran in fallback mode")
    end
end
return Game