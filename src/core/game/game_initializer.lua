--[[
    ═══════════════════════════════════════════════════════════════════════════
    Game Initializer - System Initialization & Setup
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles the initialization of all game systems, including
    core systems, UI systems, audio systems, and game-specific modules.
    It provides a clean separation between initialization logic and game loop logic.
--]]

local Utils = require("src.utils.utils")
local ModuleLoader = require("src.utils.module_loader")
local Config = require("src.utils.config")

local GameInitializer = {}

-- Initialization state
GameInitializer.initialized = false
GameInitializer.initStartTime = 0
GameInitializer.initErrors = {}

-- System dependencies
GameInitializer.dependencies = {
    core = {
        "src.core.game_state",
        "src.core.renderer",
        "src.core.camera",
        "src.core.game_logic"
    },
    systems = {
        "src.systems.progression_system",
        "src.systems.ring_system",
        "src.systems.world_generator",
        "src.systems.cosmic_events",
        "src.systems.warp_zones",
        "src.systems.map_system",
        "src.systems.warp_drive",
        "src.systems.artifact_system",
        "src.systems.save_system",
        "src.systems.achievement_system",
        "src.systems.upgrade_system",
        "src.systems.particle_system",
        "src.systems.emotional_feedback"
    },
    ui = {
        "src.ui.ui_system",
        "src.ui.pause_menu",
        "src.ui.ui_animation_system",
        "src.ui.feedback_ui"
    },
    audio = {
        "src.audio.sound_manager"
    }
}

-- Initialize all game systems
function GameInitializer.init()
    GameInitializer.initStartTime = love.timer.getTime()
    Utils.Logger.info("🚀 Starting game initialization...")
    
    -- Validate configuration
    local configValid, configErrors = GameInitializer.validateConfiguration()
    if not configValid then
        Utils.Logger.error("Configuration validation failed: %s", table.concat(configErrors, ", "))
        return false, configErrors
    end
    
    -- Initialize fonts
    local fontSuccess = GameInitializer.initializeFonts()
    if not fontSuccess then
        Utils.Logger.error("Font initialization failed")
        return false, {"Font initialization failed"}
    end
    
    -- Initialize core systems
    local coreSuccess = GameInitializer.initializeCoreSystems()
    if not coreSuccess then
        Utils.Logger.error("Core system initialization failed")
        return false, {"Core system initialization failed"}
    end
    
    -- Initialize game systems
    local systemsSuccess = GameInitializer.initializeGameSystems()
    if not systemsSuccess then
        Utils.Logger.error("Game system initialization failed")
        return false, {"Game system initialization failed"}
    end
    
    -- Initialize UI systems
    local uiSuccess = GameInitializer.initializeUISystems()
    if not uiSuccess then
        Utils.Logger.error("UI system initialization failed")
        return false, {"UI system initialization failed"}
    end
    
    -- Initialize audio systems
    local audioSuccess = GameInitializer.initializeAudioSystems()
    if not audioSuccess then
        Utils.Logger.error("Audio system initialization failed")
        return false, {"Audio system initialization failed"}
    end
    
    -- Final initialization steps
    local finalSuccess = GameInitializer.finalizeInitialization()
    if not finalSuccess then
        Utils.Logger.error("Final initialization failed")
        return false, {"Final initialization failed"}
    end
    
    GameInitializer.initialized = true
    local initTime = love.timer.getTime() - GameInitializer.initStartTime
    Utils.Logger.info("✅ Game initialization completed in %.2f seconds", initTime)
    
    return true
end

-- Validate configuration
function GameInitializer.validateConfiguration()
    if not Config then
        return false, {"Config module not found"}
    end
    
    local valid, errors = Config.validate()
    if not valid then
        return false, errors
    end
    
    Utils.Logger.info("✅ Configuration validation passed")
    return true
end

-- Initialize fonts
function GameInitializer.initializeFonts()
    Utils.Logger.info("🎨 Initializing font system...")
    
    local fonts = {
        regular = nil,
        bold = nil,
        light = nil,
        extraBold = nil
    }
    
    -- Try to load fonts with fallback system
    local fontLoadSuccess = GameInitializer.loadFontsWithFallback(fonts)
    
    if fontLoadSuccess then
        -- Make fonts available globally
        _G.GameFonts = fonts
        love.graphics.setFont(fonts.regular)
        Utils.Logger.info("✅ Font system initialized successfully")
        return true
    else
        Utils.Logger.error("❌ Font system initialization failed")
        return false
    end
end

-- Load fonts with intelligent fallback system
function GameInitializer.loadFontsWithFallback(fonts)
    local fontSizes = {
        regular = 16,
        bold = 16,
        light = 14,
        extraBold = 18
    }
    
    local fontLoadSuccess = true
    
    for fontType, size in pairs(fontSizes) do
        local success, font = pcall(love.graphics.newFont, size)
        if success then
            fonts[fontType] = font
            Utils.Logger.info("✅ Loaded %s font (size: %d)", fontType, size)
        else
            Utils.Logger.warning("⚠️ Failed to load %s font (size: %d): %s", fontType, size, tostring(font))
            fontLoadSuccess = false
        end
    end
    
    -- If any font failed, try fallback approach
    if not fontLoadSuccess then
        Utils.Logger.info("🔄 Attempting font fallback...")
        
        local fallbackFont = nil
        local fallbackError = nil
        
        -- Try to create a basic font
        local success, font = pcall(love.graphics.newFont, 16)
        if success then
            fallbackFont = font
            Utils.Logger.info("✅ Created fallback font")
        else
            fallbackError = font
            Utils.Logger.warn("⚠️ Fallback font creation failed: %s", tostring(fallbackError))
        end
        
        if fallbackFont then
            -- Use fallback font for all font types
            fonts.regular = fallbackFont
            fonts.bold = fallbackFont
            fonts.light = fallbackFont
            fonts.extraBold = fallbackFont
            Utils.Logger.info("🎨 Intelligent font fallback system activated")
            return true
        else
            -- Last resort: use system default
            local defaultFont = love.graphics.getFont()
            fonts.regular = defaultFont
            fonts.bold = defaultFont
            fonts.light = defaultFont
            fonts.extraBold = defaultFont
            Utils.Logger.info("🎨 Using system default fonts")
            return true
        end
    end
    
    return fontLoadSuccess
end

-- Initialize core systems
function GameInitializer.initializeCoreSystems()
    Utils.Logger.info("🔧 Initializing core systems...")
    
    local screenWidth, screenHeight = love.graphics.getDimensions()
    
    -- Initialize camera
    local cameraSuccess = GameInitializer.initializeCamera(screenWidth, screenHeight)
    if not cameraSuccess then
        return false
    end
    
    -- Initialize core modules
    for _, modulePath in ipairs(GameInitializer.dependencies.core) do
        local success = ModuleLoader.initModule(modulePath, "init")
        if not success then
            Utils.Logger.error("Failed to initialize core module: %s", modulePath)
            table.insert(GameInitializer.initErrors, "Core module: " .. modulePath)
        end
    end
    
    -- Initialize GameState and Renderer with camera
    local GameState = Utils.require("src.core.game_state")
    local Renderer = Utils.require("src.core.renderer")
    
    if GameState and Renderer then
        GameState.init(screenWidth, screenHeight)
        GameState.camera = GameInitializer.camera
        GameState.soundManager = GameInitializer.soundManager
        
        Renderer.init(_G.GameFonts)
        Renderer.camera = GameInitializer.camera
    else
        Utils.Logger.error("Failed to load core modules")
        return false
    end
    
    Utils.Logger.info("✅ Core systems initialized")
    return true
end

-- Initialize camera
function GameInitializer.initializeCamera(screenWidth, screenHeight)
    Utils.Logger.info("📷 Initializing camera...")
    
    local Camera = Utils.require("src.core.camera")
    if not Camera then
        Utils.Logger.error("Camera module not found")
        return false
    end
    
    -- Test camera creation
    local testCamera = Camera:new()
    if not testCamera then
        Utils.Logger.error("Failed to create camera instance")
        return false
    end
    
    GameInitializer.camera = testCamera
    GameInitializer.camera.screenWidth = screenWidth
    GameInitializer.camera.screenHeight = screenHeight
    
    Utils.Logger.info("✅ Camera initialized: %dx%d", screenWidth, screenHeight)
    return true
end

-- Initialize game systems
function GameInitializer.initializeGameSystems()
    Utils.Logger.info("🎮 Initializing game systems...")
    
    for _, modulePath in ipairs(GameInitializer.dependencies.systems) do
        local success = ModuleLoader.initModule(modulePath, "init")
        if not success then
            Utils.Logger.warning("Failed to initialize game system: %s", modulePath)
            table.insert(GameInitializer.initErrors, "Game system: " .. modulePath)
        else
            Utils.Logger.info("✅ Initialized: %s", modulePath)
        end
    end
    
    Utils.Logger.info("✅ Game systems initialized")
    return true
end

-- Initialize UI systems
function GameInitializer.initializeUISystems()
    Utils.Logger.info("🖥️ Initializing UI systems...")
    
    -- Initialize main UI system first
    local UISystem = Utils.require("src.ui.ui_system")
    if UISystem then
        UISystem.init(_G.GameFonts)
        GameInitializer.uiSystem = UISystem
    else
        Utils.Logger.error("Failed to load UI system")
        return false
    end
    
    -- Initialize other UI modules
    for _, modulePath in ipairs(GameInitializer.dependencies.ui) do
        if modulePath ~= "src.ui.ui_system" then -- Already initialized
            local success = ModuleLoader.initModule(modulePath, "init")
            if not success then
                Utils.Logger.warning("Failed to initialize UI module: %s", modulePath)
                table.insert(GameInitializer.initErrors, "UI module: " .. modulePath)
            else
                Utils.Logger.info("✅ Initialized: %s", modulePath)
            end
        end
    end
    
    -- Initialize UI animation system
    local UIAnimationSystem = Utils.require("src.ui.ui_animation_system")
    if UIAnimationSystem then
        UIAnimationSystem.init()
        GameInitializer.uiAnimationSystem = UIAnimationSystem
    end
    
    -- Initialize feedback UI system
    local FeedbackUI = Utils.require("src.ui.feedback_ui")
    if FeedbackUI then
        FeedbackUI.init()
        GameInitializer.feedbackUI = FeedbackUI
    end
    
    Utils.Logger.info("✅ UI systems initialized")
    return true
end

-- Initialize audio systems
function GameInitializer.initializeAudioSystems()
    Utils.Logger.info("🔊 Initializing audio systems...")
    
    local SoundManager = Utils.require("src.audio.sound_manager")
    if SoundManager then
        GameInitializer.soundManager = SoundManager:new()
        GameInitializer.soundManager:load()
        Utils.Logger.info("✅ Audio system initialized")
        return true
    else
        Utils.Logger.error("Failed to load audio system")
        return false
    end
end

-- Finalize initialization
function GameInitializer.finalizeInitialization()
    Utils.Logger.info("🎯 Finalizing initialization...")
    
    -- Set up global references
    _G.GameCamera = GameInitializer.camera
    _G.GameSoundManager = GameInitializer.soundManager
    _G.GameUISystem = GameInitializer.uiSystem
    
    -- Verify critical systems
    local criticalSystems = {
        camera = GameInitializer.camera,
        soundManager = GameInitializer.soundManager,
        uiSystem = GameInitializer.uiSystem,
        fonts = _G.GameFonts
    }
    
    for name, system in pairs(criticalSystems) do
        if not system then
            Utils.Logger.error("Critical system missing: %s", name)
            return false
        end
    end
    
    -- Log initialization summary
    local errorCount = #GameInitializer.initErrors
    if errorCount > 0 then
        Utils.Logger.warning("⚠️ Initialization completed with %d warnings", errorCount)
        for _, error in ipairs(GameInitializer.initErrors) do
            Utils.Logger.warning("  - %s", error)
        end
    else
        Utils.Logger.info("🎉 All systems initialized successfully")
    end
    
    return true
end

-- Get initialization status
function GameInitializer.isInitialized()
    return GameInitializer.initialized
end

-- Get initialization errors
function GameInitializer.getInitErrors()
    return GameInitializer.initErrors
end

-- Get initialization time
function GameInitializer.getInitTime()
    if GameInitializer.initialized then
        return love.timer.getTime() - GameInitializer.initStartTime
    end
    return 0
end

-- Reset initialization state
function GameInitializer.reset()
    GameInitializer.initialized = false
    GameInitializer.initStartTime = 0
    GameInitializer.initErrors = {}
    GameInitializer.camera = nil
    GameInitializer.soundManager = nil
    GameInitializer.uiSystem = nil
    GameInitializer.uiAnimationSystem = nil
    GameInitializer.feedbackUI = nil
    
    Utils.Logger.info("🔄 Game initializer reset")
end

-- Get system status
function GameInitializer.getSystemStatus()
    return {
        initialized = GameInitializer.initialized,
        init_time = GameInitializer.getInitTime(),
        error_count = #GameInitializer.initErrors,
        errors = GameInitializer.initErrors,
        camera_available = GameInitializer.camera ~= nil,
        sound_manager_available = GameInitializer.soundManager ~= nil,
        ui_system_available = GameInitializer.uiSystem ~= nil
    }
end

return GameInitializer 