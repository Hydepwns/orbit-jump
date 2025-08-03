--[[
    Orbit Jump Utilities: Modular Architecture
    
    This module provides a unified interface to all utility functions,
    organized into focused, single-responsibility modules for better
    maintainability and performance.
--]]

local Utils = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Module Loading: Performance Through Intelligent Caching
    ═══════════════════════════════════════════════════════════════════════════
--]]

Utils.moduleCache = {}

function Utils.require(modulePath)
    -- Philosophy: Cache what's expensive, make cache invalidation explicit
    -- This prevents duplicate loading while allowing controlled resets for testing
    if not Utils.moduleCache[modulePath] then
        Utils.moduleCache[modulePath] = require(modulePath)
    end
    return Utils.moduleCache[modulePath]
end

function Utils.clearModuleCache()
    -- Teaching moment: Sometimes you need to forget everything and start fresh
    -- Essential for test isolation and hot-reloading during development
    Utils.moduleCache = {}
end

function Utils.safeRequire(modulePath)
    -- Safe require that returns nil instead of erroring if module doesn't exist
    local success, module = pcall(require, modulePath)
    if success then
        return module
    else
        if Utils.Logger then
            Utils.Logger.warn("Failed to load module: %s (%s)", modulePath, module)
        end
        return nil
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Load Modular Components
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Math utilities
local Vector = Utils.require("src.utils.math.vector")
local Geometry = Utils.require("src.utils.math.geometry")
local Interpolation = Utils.require("src.utils.math.interpolation")

-- Rendering utilities
local Drawing = Utils.require("src.utils.rendering.drawing")
local UIComponents = Utils.require("src.utils.rendering.ui_components")

-- Input utilities
local MobileInput = Utils.require("src.utils.input.mobile_input")

-- Data utilities
local Serialization = Utils.require("src.utils.data.serialization")
local Formatting = Utils.require("src.utils.data.formatting")

-- Existing utilities (already modularized)
local ErrorHandler = Utils.require("src.utils.error_handler")
local SpatialGrid = Utils.require("src.utils.spatial_grid")
local ObjectPool = Utils.require("src.utils.object_pool")
local AssetLoader = Utils.require("src.utils.asset_loader")
local RenderBatch = Utils.require("src.utils.render_batch")
local ModuleLoader = Utils.require("src.utils.module_loader")
local EventBus = Utils.require("src.utils.event_bus")
local Constants = Utils.require("src.utils.constants")

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Backward Compatibility Layer
    ═══════════════════════════════════════════════════════════════════════════
    
    This section provides backward compatibility by exposing all functions
    through the Utils namespace, maintaining the existing API while using
    the new modular structure underneath.
--]]

-- Math functions
Utils.distance = Vector.distance
Utils.fastDistance = Vector.fastDistance
Utils.distanceSquared = Vector.distanceSquared
Utils.normalize = Vector.normalize
Utils.normalizeInPlace = Vector.normalizeInPlace
Utils.clamp = Vector.clamp
Utils.lerp = Vector.lerp
Utils.angleBetween = Vector.angleBetween
Utils.rotatePoint = Vector.rotatePoint
Utils.vectorLength = Vector.vectorLength
Utils.vectorScale = Vector.vectorScale
Utils.vectorAdd = Vector.vectorAdd
Utils.vectorSubtract = Vector.vectorSubtract
Utils.randomFloat = Vector.randomFloat

-- Geometry functions
Utils.circleCollision = Geometry.circleCollision
Utils.ringCollision = Geometry.ringCollision
Utils.pointInRect = Geometry.pointInRect

-- Drawing functions
Utils.setColor = Drawing.setColor
Utils.drawCircle = Drawing.drawCircle
Utils.drawRing = Drawing.drawRing
Utils.drawTextWithShadow = Drawing.drawTextWithShadow
Utils.drawTextWithOutline = Drawing.drawTextWithOutline

-- UI component functions
Utils.drawButton = UIComponents.drawButton
Utils.drawProgressBar = UIComponents.drawProgressBar

-- Mobile input functions
Utils.MobileInput = MobileInput

-- Serialization functions
Utils.serialize = Serialization.serialize
Utils.deserialize = Serialization.deserialize

-- Formatting functions
Utils.formatNumber = Formatting.formatNumber
Utils.formatTime = Formatting.formatTime

-- Particle system functions
Utils.createParticle = Drawing.createParticle
Utils.updateParticle = Drawing.updateParticle

-- Table utility functions
Utils.deepCopy = Serialization.deepCopy
Utils.mergeTables = Serialization.mergeTables
Utils.tableLength = Serialization.tableLength

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Namespace Organization
    ═══════════════════════════════════════════════════════════════════════════
    
    Organize functions into logical namespaces for better organization
    while maintaining backward compatibility.
--]]

-- Math namespace
Utils.Math = {
    Vector = Vector,
    Geometry = Geometry,
    Interpolation = Interpolation
}

-- Rendering namespace
Utils.Rendering = {
    Drawing = Drawing,
    UIComponents = UIComponents
}

-- Input namespace
Utils.Input = {
    Mobile = MobileInput
}

-- Data namespace
Utils.Data = {
    Serialization = Serialization,
    Formatting = Formatting
}

-- System namespace (existing modules)
Utils.System = {
    ErrorHandler = ErrorHandler,
    SpatialGrid = SpatialGrid,
    ObjectPool = ObjectPool,
    AssetLoader = AssetLoader,
    RenderBatch = RenderBatch,
    ModuleLoader = ModuleLoader,
    EventBus = EventBus,
    Constants = Constants
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Legacy Support
    ═══════════════════════════════════════════════════════════════════════════
    
    Support for legacy code that expects certain structures to exist.
--]]

-- Legacy Logger support (if not already loaded)
if not Utils.Logger then
    Utils.Logger = {
        init = function() end,
        log = function() end,
        debug = function() end,
        info = function() end,
        warn = function() end,
        error = function() end,
        close = function() end
    }
end

-- Legacy ErrorHandler support
if not Utils.ErrorHandler then
    Utils.ErrorHandler = ErrorHandler
end

-- Legacy ObjectPool support
if not Utils.ObjectPool then
    Utils.ObjectPool = ObjectPool
end

-- Legacy SpatialGrid support
if not Utils.SpatialGrid then
    Utils.SpatialGrid = SpatialGrid
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions: Core Utilities
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Lua version compatibility: Ensuring graceful behavior across environments
local atan2 = math.atan2 or function(y, x)
    -- Fallback for newer Lua versions where atan2 was removed
    -- Handle nil values gracefully
    if not y or not x then
        return 0
    end
    return math.atan(y, x)
end
Utils.atan2 = atan2

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Module Information
    ═══════════════════════════════════════════════════════════════════════════
--]]

Utils.VERSION = "2.0.0"
Utils.MODULAR = true

function Utils.getModuleInfo()
    return {
        version = Utils.VERSION,
        modular = Utils.MODULAR,
        modules = {
            "src.utils.math.vector",
            "src.utils.math.geometry", 
            "src.utils.math.interpolation",
            "src.utils.rendering.drawing",
            "src.utils.rendering.ui_components",
            "src.utils.input.mobile_input",
            "src.utils.data.serialization",
            "src.utils.data.formatting",
            "src.utils.error_handler",
            "src.utils.spatial_grid",
            "src.utils.object_pool",
            "src.utils.asset_loader",
            "src.utils.render_batch",
            "src.utils.module_loader",
            "src.utils.event_bus",
            "src.utils.constants"
        }
    }
end

return Utils 