-- Main game controller
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

-- Font variables
local fonts = {
    regular = nil,
    bold = nil,
    light = nil,
    extraBold = nil
}

function Game.init()
    -- Initialize logging system
    Utils.Logger.init(Utils.Logger.levels.INFO, "game.log")
    Utils.Logger.info("Starting Orbit Jump game")
    
    -- Validate configuration
    local configValid, configErrors = Config.validate()
    if not configValid then
        Utils.Logger.error("Configuration validation failed: %s", table.concat(configErrors, ", "))
        error("Invalid configuration")
    end
    
    -- Initialize core systems
    Game.initGraphics()
    Game.initSystems()
    
    Utils.Logger.info("Game initialization complete")
end

function Game.initGraphics()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    
    -- Load fonts
    local fontLoadSuccess, fontError = Utils.ErrorHandler.safeCall(function()
        fonts.regular = love.graphics.newFont("assets/fonts/MonaspaceArgon-Regular.otf", 16)
        fonts.bold = love.graphics.newFont("assets/fonts/MonaspaceArgon-Bold.otf", 16)
        fonts.light = love.graphics.newFont("assets/fonts/MonaspaceArgon-Light.otf", 16)
        fonts.extraBold = love.graphics.newFont("assets/fonts/MonaspaceArgon-ExtraBold.otf", 24)
    end)
    
    if not fontLoadSuccess then
        Utils.Logger.error("Failed to load fonts: %s", tostring(fontError))
        -- Use default fonts as fallback
        fonts.regular = love.graphics.getFont()
        fonts.bold = love.graphics.getFont()
        fonts.light = love.graphics.getFont()
        fonts.extraBold = love.graphics.getFont()
    end
    
    love.graphics.setFont(fonts.regular)
end

function Game.initSystems()
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Initialize core systems directly (they need special handling)
    -- GameState, Renderer, and Camera are already loaded at the top
    
    -- Initialize camera instance first
    Game.camera = Camera:new()
    Game.camera.screenWidth = screenWidth
    Game.camera.screenHeight = screenHeight
    
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
    -- Update all systems
    -- GameState, Renderer, PauseMenu, TutorialSystem, and PerformanceMonitor are already loaded at the top
    
    -- Handle pause state
    if not PauseMenu.shouldPauseGameplay() then
        GameState.update(dt)
        
        -- Update camera to follow player
        if Game.camera and GameState.player then
            Game.camera:follow(GameState.player, dt)
        end
        
        -- Update other systems as needed
        -- CosmicEvents, RingSystem, ProgressionSystem, SaveSystem, UISystem, and PerformanceSystem are already loaded at the top
        
        -- Update systems with their specific parameter requirements
        if CosmicEvents.update then
            CosmicEvents.update(dt, GameState.player, Game.camera)
        end
        
        if RingSystem.update then
            RingSystem.update(dt, GameState.player, GameState.objects.rings)
        end
        
        if ProgressionSystem.update then
            ProgressionSystem.update(dt)
        end
        
        if SaveSystem.update then
            SaveSystem.update(dt)
        end
        
        if UISystem.update then
            UISystem.update(dt, ProgressionSystem, nil) -- Pass progression system, blockchain is optional
        end
        
        if PerformanceSystem.update then
            PerformanceSystem.update(dt)
        end
    end
    
    -- Always update these even when paused
    PauseMenu.update(dt)
    TutorialSystem.update(dt, GameState.player)
    PerformanceMonitor.update(dt)
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
        local visiblePlanets = PerformanceSystem.cullPlanets(GameState.getPlanets(), Game.camera)
        local visibleRings = PerformanceSystem.cullRings(GameState.getRings(), Game.camera)
        local visibleParticles = PerformanceSystem.cullParticles(GameState.getParticles(), Game.camera)
        
        Renderer.drawPlanets(visiblePlanets)
        Renderer.drawRings(visibleRings)
        Renderer.drawParticles(visibleParticles)
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
        Renderer.drawMobileControls(GameState.player, fonts)
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
    
    GameState.handleKeyPress(key)
end

function Game.handleMousePress(x, y, button)
    -- GameState, PauseMenu, TutorialSystem, and UISystem are already loaded at the top
    
    -- Input priority: Pause > Tutorial > UI > Game
    if PauseMenu.mousepressed and PauseMenu.mousepressed(x, y, button) then
        return
    end
    
    if TutorialSystem.mousepressed and TutorialSystem.mousepressed(x, y, button) then
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
    
    if TutorialSystem.mousemoved and TutorialSystem.mousemoved(x, y) then
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
    
    if TutorialSystem.mousereleased and TutorialSystem.mousereleased(x, y, button) then
        return
    end
    
    if UISystem.mousereleased and UISystem.mousereleased(x, y, button) then
        return
    end
    
    GameState.handleMouseRelease(x, y, button)
end

function Game.quit()
    -- Save game before quitting
    -- SaveSystem is already loaded at the top
    SaveSystem.save()
    
    Utils.Logger.info("Game shutting down")
end

return Game