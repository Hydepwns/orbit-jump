--[[
    System Orchestrator: The Conductor of Digital Symphony
    
    In game architecture, order matters. This orchestrator ensures every system
    plays its part at precisely the right moment, creating harmony from what
    could easily become chaos.
    
    Architectural Philosophy:
    - Systems are instruments in an orchestra, not solo performers
    - Update order is a musical score - timing creates the experience  
    - Dependencies flow like melodies - clear, predictable, beautiful
    - Side effects are choreographed, never accidental
    
    "Great architecture doesn't just work - it sings."
--]]

local Utils = require("src.utils.utils")
local ErrorHandler = Utils.require("src.utils.error_handler")

local SystemOrchestrator = {
    -- Systems organized by architectural responsibility
    layers = {
        -- Foundation Layer: Core services everything depends on
        foundation = {
            systems = {},
            purpose = "Essential services that enable all other systems"
        },
        
        -- Input Layer: Capture player intent before anything changes
        input = {
            systems = {},
            purpose = "Translate human desires into digital actions"
        },
        
        -- Simulation Layer: The physics and logic heart
        simulation = {
            systems = {},
            purpose = "Model the world according to consistent rules"
        },
        
        -- Gameplay Layer: Game-specific mechanics and rules
        gameplay = {
            systems = {},
            purpose = "Transform simulation into meaningful play"
        },
        
        -- Presentation Layer: Show the world to the player
        presentation = {
            systems = {},
            purpose = "Create beauty from data, meaning from mechanics"
        },
        
        -- Meta Layer: Track progress, achievements, analytics
        meta = {
            systems = {},
            purpose = "Remember the journey, celebrate the milestones"
        }
    },
    
    -- System registry with metadata
    systems = {},
    
    -- Update order (carefully orchestrated for optimal flow)
    updateOrder = {
        "foundation",    -- Services must be ready first
        "input",        -- Capture intent before world changes
        "simulation",   -- Physics and world state updates
        "gameplay",     -- Game rules applied to world state
        "presentation", -- Render the current truth
        "meta"         -- Observe and record what happened
    }
}

--[[
    Register a system with the orchestrator
    
    Each system declares its layer, dependencies, and purpose. This metadata
    helps developers understand not just what systems do, but why they exist
    and how they relate to others.
--]]
function SystemOrchestrator.register(name, system, config)
    config = config or {}
    
    -- Skip registration if system couldn't be loaded
    if not system then
        Utils.Logger.warn("Skipping registration of %s - system not available", name)
        return false
    end
    
    -- Validate system interface
    assert(system.update or system.draw or system.init, 
           name .. " must implement at least one of: init, update, draw")
    
    -- Store system with metadata
    SystemOrchestrator.systems[name] = {
        system = system,
        layer = config.layer or "gameplay",
        dependencies = config.dependencies or {},
        purpose = config.purpose or "Undocumented system",
        updatePriority = config.priority or 50,
        enabled = true,
        performance = {
            updateTime = 0,
            drawTime = 0,
            calls = 0
        }
    }
    
    -- Add to appropriate layer
    local layer = SystemOrchestrator.layers[config.layer or "gameplay"]
    if layer then
        table.insert(layer.systems, name)
        -- Sort by priority within layer
        table.sort(layer.systems, function(a, b)
            local sysA = SystemOrchestrator.systems[a]
            local sysB = SystemOrchestrator.systems[b]
            if not sysA or not sysB then
                return false  -- Keep original order if either system is missing
            end
            return sysA.updatePriority < sysB.updatePriority
        end)
    else
        Utils.Logger.warn("Unknown layer '%s' for system '%s'", config.layer, name)
    end
    
    Utils.Logger.info("Registered system '%s' in layer '%s': %s", 
                     name, config.layer or "gameplay", config.purpose)
    return true
end

--[[
    Initialize all systems in dependency order
    
    This ensures each system starts with its dependencies already prepared,
    preventing initialization order bugs that plague many game architectures.
--]]
function SystemOrchestrator.init()
    Utils.Logger.info("Orchestrator: Initializing systems...")
    
    local initialized = {}
    local function initSystem(name)
        if initialized[name] then return true end
        
        local sysData = SystemOrchestrator.systems[name]
        if not sysData then 
            Utils.Logger.error("Unknown system: %s", name)
            return false 
        end
        
        -- Initialize dependencies first
        for _, dep in ipairs(sysData.dependencies) do
            if not initSystem(dep) then
                Utils.Logger.error("Failed to initialize dependency '%s' for '%s'", dep, name)
                return false
            end
        end
        
        -- Initialize the system with dependencies
        if sysData.system.init then
            -- Build dependency table
            local dependencies = {}
            for _, depName in ipairs(sysData.dependencies) do
                local depSystem = SystemOrchestrator.systems[depName]
                if depSystem then
                    dependencies[depName] = depSystem.system
                end
            end
            
            local success, err = pcall(sysData.system.init, dependencies)
            if not success then
                Utils.Logger.error("Failed to initialize '%s': %s", name, err)
                return false
            end
        end
        
        initialized[name] = true
        Utils.Logger.info("Initialized: %s", name)
        return true
    end
    
    -- Initialize all systems
    for name, _ in pairs(SystemOrchestrator.systems) do
        initSystem(name)
    end
    
    return true
end

--[[
    Update all systems in orchestrated order
    
    The update flow is carefully designed:
    1. Foundation services prepare the frame
    2. Input is captured before anything changes
    3. Simulation runs physics and world updates
    4. Gameplay applies rules to the simulated world
    5. Presentation prepares rendering data
    6. Meta systems observe and record
--]]
function SystemOrchestrator.update(dt)
    -- Performance monitoring integration
    local PerformanceMonitor = Utils.safeRequire("src.performance.performance_monitor")
    
    for _, layerName in ipairs(SystemOrchestrator.updateOrder) do
        local layer = SystemOrchestrator.layers[layerName]
        
        for _, systemName in ipairs(layer.systems) do
            local sysData = SystemOrchestrator.systems[systemName]
            
            if sysData and sysData.enabled and sysData.system.update then
                if PerformanceMonitor then
                    -- Profile with educational insights
                    PerformanceMonitor.profile(systemName, function()
                        local success, err = ErrorHandler.safeCall(sysData.system.update, dt)
                        if not success then
                            Utils.Logger.error("System '%s' update error: %s", systemName, err)
                        end
                    end)
                else
                    -- Direct update without profiling
                    local startTime = love.timer.getTime()
                    local success, err = ErrorHandler.safeCall(sysData.system.update, dt)
                    if not success then
                        Utils.Logger.error("System '%s' update error: %s", systemName, err)
                    end
                    sysData.performance.updateTime = love.timer.getTime() - startTime
                    sysData.performance.calls = sysData.performance.calls + 1
                end
            end
        end
    end
end

--[[
    Draw all systems with presentation logic
    
    Drawing is separate from update to maintain clean architecture.
    Only presentation layer systems typically implement draw.
--]]
function SystemOrchestrator.draw()
    -- Only presentation and UI layers typically draw
    local drawLayers = {"presentation", "meta"}
    
    for _, layerName in ipairs(drawLayers) do
        local layer = SystemOrchestrator.layers[layerName]
        if layer then
            for _, systemName in ipairs(layer.systems) do
                local sysData = SystemOrchestrator.systems[systemName]
                
                if sysData and sysData.enabled and sysData.system.draw then
                    local startTime = love.timer.getTime()
                    local success, err = ErrorHandler.safeCall(sysData.system.draw)
                    if not success then
                        Utils.Logger.error("System '%s' draw error: %s", systemName, err)
                    end
                    sysData.performance.drawTime = love.timer.getTime() - startTime
                end
            end
        end
    end
end

--[[
    Get a system by name
--]]
function SystemOrchestrator.getSystem(name)
    local sysData = SystemOrchestrator.systems[name]
    return sysData and sysData.system or nil
end

--[[
    Enable or disable a system
--]]
function SystemOrchestrator.setEnabled(name, enabled)
    local sysData = SystemOrchestrator.systems[name]
    if sysData then
        sysData.enabled = enabled
        Utils.Logger.info("System '%s' %s", name, enabled and "enabled" or "disabled")
    else
        Utils.Logger.warn("System '%s' not found", name)
    end
end

--[[
    Get system dependency graph for visualization
    
    This helps developers understand system relationships and identify
    potential architectural issues like circular dependencies.
--]]
function SystemOrchestrator.getDependencyGraph()
    local graph = {
        nodes = {},
        edges = {}
    }
    
    -- Create nodes for each system
    for name, sysData in pairs(SystemOrchestrator.systems) do
        table.insert(graph.nodes, {
            id = name,
            layer = sysData.layer,
            purpose = sysData.purpose,
            enabled = sysData.enabled
        })
        
        -- Create edges for dependencies
        for _, dep in ipairs(sysData.dependencies) do
            table.insert(graph.edges, {
                from = name,
                to = dep,
                type = "depends_on"
            })
        end
    end
    
    return graph
end

--[[
    Generate architecture documentation
    
    Self-documenting architecture that explains itself to new developers.
--]]
function SystemOrchestrator.generateDocumentation()
    local doc = [[
# Orbit Jump System Architecture

## Architectural Layers

]]
    
    for _, layerName in ipairs(SystemOrchestrator.updateOrder) do
        local layer = SystemOrchestrator.layers[layerName]
        doc = doc .. string.format("### %s Layer\n", layerName:gsub("^%l", string.upper))
        doc = doc .. string.format("*%s*\n\n", layer.purpose)
        
        if #layer.systems > 0 then
            doc = doc .. "**Systems:**\n"
            for _, sysName in ipairs(layer.systems) do
                local sysData = SystemOrchestrator.systems[sysName]
                doc = doc .. string.format("- **%s**: %s\n", sysName, sysData.purpose)
                
                if #sysData.dependencies > 0 then
                    doc = doc .. string.format("  - Dependencies: %s\n", 
                                             table.concat(sysData.dependencies, ", "))
                end
            end
        else
            doc = doc .. "*No systems registered in this layer*\n"
        end
        doc = doc .. "\n"
    end
    
    doc = doc .. [[
## Update Flow

The system update order is carefully orchestrated:

```
Foundation → Input → Simulation → Gameplay → Presentation → Meta
```

This ensures:
1. Services are ready before use
2. Input is captured before world changes
3. Physics runs on clean input
4. Game rules apply to physical state
5. Rendering sees final world state
6. Analytics observe completed frame

## Performance Characteristics

]]
    
    -- Add performance data
    local totalUpdate = 0
    local totalDraw = 0
    
    for name, sysData in pairs(SystemOrchestrator.systems) do
        if sysData.performance.calls > 0 then
            local avgUpdate = sysData.performance.updateTime / sysData.performance.calls * 1000
            local avgDraw = sysData.performance.drawTime / sysData.performance.calls * 1000
            
            doc = doc .. string.format("- **%s**: %.2fms update, %.2fms draw\n", 
                                     name, avgUpdate, avgDraw)
            
            totalUpdate = totalUpdate + avgUpdate
            totalDraw = totalDraw + avgDraw
        end
    end
    
    doc = doc .. string.format("\n**Total Frame Time**: %.2fms update + %.2fms draw = %.2fms\n",
                             totalUpdate, totalDraw, totalUpdate + totalDraw)
    
    return doc
end

--[[
    Example: Register core Orbit Jump systems
    
    This demonstrates how to properly structure a game's architecture
    using the orchestrator pattern.
--]]
function SystemOrchestrator.registerOrbitJumpSystems()
    -- Foundation Layer - Only register actual systems that have init/update interfaces
    SystemOrchestrator.register("saveSystem", Utils.safeRequire("src.systems.save_system"), {
        layer = "foundation", 
        purpose = "Persistent data management",
        priority = 10
    })
    
    -- GameState System - Initialize game state and player
    SystemOrchestrator.register("gameStateSystem", {
        init = function()
            Utils.Logger.info("Initializing game state system...")
            local GameState = Utils.require("src.core.game_state")
            local screenWidth, screenHeight = love.graphics.getDimensions()
            local success = GameState.init(screenWidth, screenHeight)
            if success then
                Utils.Logger.info("Game state system initialized successfully")
                return true
            else
                Utils.Logger.error("Game state system initialization failed")
                return false
            end
        end,
        update = function(dt)
            -- GameState update logic
            local GameState = Utils.require("src.core.game_state")
            if GameState.update then
                GameState.update(dt)
            end
            return true
        end
    }, {
        layer = "foundation",
        purpose = "Game state management and player initialization",
        priority = 1
    })
    
    -- Camera System - Initialize camera for the game
    SystemOrchestrator.register("cameraSystem", {
        init = function()
            Utils.Logger.info("Initializing camera system...")
            local Camera = Utils.require("src.core.camera")
            if Camera then
                local screenWidth, screenHeight = love.graphics.getDimensions()
                local camera = Camera:new()
                if camera then
                    camera.screenWidth = screenWidth
                    camera.screenHeight = screenHeight
                    
                    -- Initialize camera to center on screen (where player starts)
                    camera.x = 0
                    camera.y = 0
                    
                    Utils.Logger.info("Camera system initialized: %dx%d", screenWidth, screenHeight)
                    
                    -- Store camera in a global location that Game can access
                    _G.GameCamera = camera
                    return true
                else
                    Utils.Logger.error("Failed to create camera instance")
                    return false
                end
            else
                Utils.Logger.error("Camera module not available")
                return false
            end
        end,
        update = function(dt)
            -- Camera update logic if needed
            return true
        end
    }, {
        layer = "foundation",
        purpose = "Camera initialization and management",
        priority = 5
    })
    
    -- Renderer System - Initialize rendering system
    SystemOrchestrator.register("rendererSystem", {
        init = function()
            Utils.Logger.info("Initializing renderer system...")
            local Renderer = Utils.require("src.core.renderer")
            local fonts = _G.GameFonts
            if Renderer and Renderer.init and fonts then
                Renderer.init(fonts)
                Utils.Logger.info("Renderer system initialized successfully")
                return true
            else
                Utils.Logger.error("Renderer module or fonts not available")
                return false
            end
        end,
        update = function(dt)
            -- Renderer doesn't need update logic
            return true
        end
    }, {
        layer = "presentation",
        purpose = "Rendering system initialization",
        priority = 1
    })
    
    -- Gameplay Layer - Register systems that actually exist and have proper interfaces
    SystemOrchestrator.register("progressionSystem", Utils.safeRequire("src.systems.progression_system"), {
        layer = "meta",
        purpose = "Track achievements and unlock progression",
        priority = 10
    })
    
    SystemOrchestrator.register("particleSystem", Utils.safeRequire("src.systems.particle_system"), {
        layer = "presentation",
        purpose = "Visual effects and particle emissions",
        priority = 10
    })
    
    SystemOrchestrator.register("ringSystem", Utils.safeRequire("src.systems.ring_system"), {
        layer = "gameplay",
        purpose = "Collectible rings and combo mechanics",
        priority = 30
    })
    
    SystemOrchestrator.register("emotionalFeedback", Utils.safeRequire("src.systems.emotional_feedback"), {
        layer = "meta",
        purpose = "Create emotional resonance through feedback",
        priority = 20
    })
    
    -- Add more systems as they are updated to support the orchestrator interface
    -- For now, we'll keep it minimal and working
end

return SystemOrchestrator