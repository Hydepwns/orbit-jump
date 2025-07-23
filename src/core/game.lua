-- Main game controller
local GameLogic = require("src.core.game_logic")
local GameState = require("src.core.game_state")
local Renderer = require("src.core.renderer")
local ModuleLoader = require("src.utils.module_loader")
local Utils = require("src.utils.utils")
local Config = require("src.utils.config")

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
    local fontLoadSuccess, fontError = pcall(function()
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
    local GameState = require("src.core.game_state")
    local Renderer = require("src.core.renderer")
    local Camera = require("src.core.camera")
    
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
    ModuleLoader.initModule("ui.ui_system", "init")
    ModuleLoader.initModule("ui.pause_menu", "init")
    
    -- Initialize audio
    local SoundManager = require("src.audio.sound_manager")
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
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem.hasSave() then
        SaveSystem.load()
    end
    
    -- Initialize and start tutorial if first time
    local TutorialSystem = require("src.ui.tutorial_system")
    TutorialSystem.init()  -- This will check save state and start if needed
end

function Game.update(dt)
    -- Update all systems
    local GameState = require("src.core.game_state")
    local Renderer = require("src.core.renderer")
    local PauseMenu = require("src.ui.pause_menu")
    local TutorialSystem = require("src.ui.tutorial_system")
    local PerformanceMonitor = require("src.performance.performance_monitor")
    
    -- Handle pause state
    if not PauseMenu.shouldPauseGameplay() then
        GameState.update(dt)
        
        -- Update camera to follow player
        if Game.camera and GameState.player then
            Game.camera:follow(GameState.player, dt)
        end
        
        -- Update other systems as needed
        local CosmicEvents = require("src.systems.cosmic_events")
        local RingSystem = require("src.systems.ring_system")
        local ProgressionSystem = require("src.systems.progression_system")
        local SaveSystem = require("src.systems.save_system")
        local UISystem = require("src.ui.ui_system")
        local PerformanceSystem = require("src.performance.performance_system")
        
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
    local Renderer = require("src.core.renderer")
    local GameState = require("src.core.game_state")
    local UISystem = require("src.ui.ui_system")
    local TutorialSystem = require("src.ui.tutorial_system")
    local PauseMenu = require("src.ui.pause_menu")
    local PerformanceMonitor = require("src.performance.performance_monitor")
    local Config = require("src.utils.config")
    
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
        local PerformanceSystem = require("src.performance.performance_system")
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
    
    -- Clear camera transform
    if Game.camera then
        Game.camera:clear()
    end
    
    -- Draw UI (no camera transform)
    UISystem.draw()
    TutorialSystem.draw(player, Game.camera)
    PauseMenu.draw()
    
    -- Draw save indicator
    local SaveSystem = require("src.systems.save_system")
    SaveSystem.drawUI()
    
    -- Draw performance overlay if enabled
    if Config.dev.showFPS then
        PerformanceMonitor.draw()
    end
end

function Game.handleKeyPress(key)
    local GameState = require("src.core.game_state")
    local PauseMenu = require("src.ui.pause_menu")
    local TutorialSystem = require("src.ui.tutorial_system")
    local UISystem = require("src.ui.ui_system")
    
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
    local GameState = require("src.core.game_state")
    local PauseMenu = require("src.ui.pause_menu")
    local TutorialSystem = require("src.ui.tutorial_system")
    local UISystem = require("src.ui.ui_system")
    
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
    local GameState = require("src.core.game_state")
    local PauseMenu = require("src.ui.pause_menu")
    local TutorialSystem = require("src.ui.tutorial_system")
    local UISystem = require("src.ui.ui_system")
    
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
    local GameState = require("src.core.game_state")
    local PauseMenu = require("src.ui.pause_menu")
    local TutorialSystem = require("src.ui.tutorial_system")
    local UISystem = require("src.ui.ui_system")
    
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
    local SaveSystem = require("src.systems.save_system")
    SaveSystem.save()
    
    Utils.Logger.info("Game shutting down")
end

return Game