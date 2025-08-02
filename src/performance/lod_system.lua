--[[
    ═══════════════════════════════════════════════════════════════════════════
    LOD (Level of Detail) System: Adaptive Object Complexity
    ═══════════════════════════════════════════════════════════════════════════
    
    This system provides different levels of detail for objects based on their
    distance from the camera. Distant objects use simplified representations
    to improve performance while maintaining visual quality.
    
    Performance Benefits:
    • Reduces polygon count for distant objects
    • Simplifies particle effects at distance
    • Optimizes rendering for large scenes
    • Maintains visual quality for close objects
--]]

local Utils = require("src.utils.utils")
local LODSystem = {}

-- LOD configuration
LODSystem.config = {
    -- Distance thresholds for LOD levels
    distances = {
        high = 500,      -- High detail within this distance
        medium = 1000,   -- Medium detail within this distance
        low = 2000,      -- Low detail within this distance
        cull = 3000      -- Cull objects beyond this distance
    },
    
    -- Quality settings for each LOD level
    quality = {
        high = {
            particleCount = 1.0,      -- Full particle count
            detailLevel = 1.0,        -- Full detail
            animationSpeed = 1.0,     -- Full animation speed
            shadowEnabled = true,     -- Enable shadows
            glowEnabled = true        -- Enable glow effects
        },
        medium = {
            particleCount = 0.5,      -- Half particle count
            detailLevel = 0.7,        -- 70% detail
            animationSpeed = 0.8,     -- 80% animation speed
            shadowEnabled = false,    -- Disable shadows
            glowEnabled = true        -- Keep glow effects
        },
        low = {
            particleCount = 0.2,      -- 20% particle count
            detailLevel = 0.3,        -- 30% detail
            animationSpeed = 0.5,     -- 50% animation speed
            shadowEnabled = false,    -- Disable shadows
            glowEnabled = false       -- Disable glow effects
        }
    },
    
    -- Object-specific LOD settings
    objectTypes = {
        planet = {
            high = { segments = 32, rings = 3, atmosphere = true },
            medium = { segments = 16, rings = 2, atmosphere = true },
            low = { segments = 8, rings = 1, atmosphere = false }
        },
        ring = {
            high = { segments = 12, glow = true, sparkle = true },
            medium = { segments = 8, glow = true, sparkle = false },
            low = { segments = 4, glow = false, sparkle = false }
        },
        particle = {
            high = { count = 100, size = 1.0, alpha = 1.0 },
            medium = { count = 50, size = 0.8, alpha = 0.8 },
            low = { count = 20, size = 0.6, alpha = 0.6 }
        },
        player = {
            high = { trail = true, effects = true, glow = true },
            medium = { trail = true, effects = false, glow = true },
            low = { trail = false, effects = false, glow = false }
        }
    }
}

-- LOD cache for performance
LODSystem.cache = {
    objectLODs = {},     -- Cached LOD levels for objects
    distanceCache = {},  -- Cached distances
    lastUpdate = 0       -- Last update time
}

-- Initialize LOD system
function LODSystem.init()
    LODSystem.clearCache()
    Utils.Logger.info("LOD system initialized")
end

-- Clear LOD cache
function LODSystem.clearCache()
    LODSystem.cache.objectLODs = {}
    LODSystem.cache.distanceCache = {}
    LODSystem.cache.lastUpdate = 0
end

-- Calculate LOD level based on distance
function LODSystem.calculateLOD(distance, objectType)
    local distances = LODSystem.config.distances
    
    if distance <= distances.high then
        return "high"
    elseif distance <= distances.medium then
        return "medium"
    elseif distance <= distances.low then
        return "low"
    else
        return "cull"
    end
end

-- Get LOD settings for an object
function LODSystem.getLODSettings(objectType, lodLevel)
    local quality = LODSystem.config.quality[lodLevel]
    local objectSettings = LODSystem.config.objectTypes[objectType]
    
    if not quality or not objectSettings then
        return nil
    end
    
    return {
        quality = quality,
        object = objectSettings[lodLevel] or objectSettings.medium,
        lodLevel = lodLevel
    }
end

-- Update object LOD based on camera position
function LODSystem.updateObjectLOD(object, camera)
    if not camera then return "high" end
    
    local distance = Utils.distance(camera.x, camera.y, object.x, object.y)
    local lodLevel = LODSystem.calculateLOD(distance, object.type)
    
    -- Cache the LOD level
    object.lodLevel = lodLevel
    object.distanceFromCamera = distance
    
    return lodLevel
end

-- Update multiple objects LOD
function LODSystem.updateObjectsLOD(objects, camera)
    local updated = 0
    local culled = 0
    
    for _, object in ipairs(objects) do
        local lodLevel = LODSystem.updateObjectLOD(object, camera)
        
        if lodLevel == "cull" then
            culled = culled + 1
        else
            updated = updated + 1
        end
    end
    
    return updated, culled
end

-- Get visible objects (non-culled)
function LODSystem.getVisibleObjects(objects)
    local visible = {}
    
    for _, object in ipairs(objects) do
        if object.lodLevel and object.lodLevel ~= "cull" then
            table.insert(visible, object)
        end
    end
    
    return visible
end

-- Apply LOD settings to planet rendering
function LODSystem.applyPlanetLOD(planet, settings)
    if not settings then return end
    
    planet.lodSettings = settings
    
    -- Apply quality settings
    planet.segments = settings.object.segments
    planet.rings = settings.object.rings
    planet.atmosphere = settings.object.atmosphere
    planet.glowIntensity = settings.quality.glowEnabled and 1.0 or 0.0
    planet.shadowEnabled = settings.quality.shadowEnabled
end

-- Apply LOD settings to ring rendering
function LODSystem.applyRingLOD(ring, settings)
    if not settings then return end
    
    ring.lodSettings = settings
    
    -- Apply quality settings
    ring.segments = settings.object.segments
    ring.glowEnabled = settings.object.glow
    ring.sparkleEnabled = settings.object.sparkle
    ring.alpha = settings.quality.alpha
end

-- Apply LOD settings to particle system
function LODSystem.applyParticleLOD(particles, settings)
    if not settings then return end
    
    -- Adjust particle count
    local targetCount = math.floor(settings.object.count * settings.quality.particleCount)
    local currentCount = #particles
    
    if currentCount > targetCount then
        -- Remove excess particles
        for i = currentCount, targetCount + 1, -1 do
            table.remove(particles, i)
        end
    elseif currentCount < targetCount then
        -- Add particles if needed
        for i = currentCount + 1, targetCount do
            table.insert(particles, {
                x = 0, y = 0, vx = 0, vy = 0,
                life = 1.0, maxLife = 1.0,
                size = settings.object.size,
                alpha = settings.object.alpha
            })
        end
    end
    
    -- Apply quality settings to all particles
    for _, particle in ipairs(particles) do
        particle.size = settings.object.size
        particle.alpha = settings.object.alpha
    end
end

-- Apply LOD settings to player rendering
function LODSystem.applyPlayerLOD(player, settings)
    if not settings then return end
    
    player.lodSettings = settings
    
    -- Apply quality settings
    player.trailEnabled = settings.object.trail
    player.effectsEnabled = settings.object.effects
    player.glowEnabled = settings.object.glow
    player.animationSpeed = settings.quality.animationSpeed
end

-- Optimize rendering based on LOD
function LODSystem.optimizeRendering(objects, camera)
    local optimized = {
        high = {},
        medium = {},
        low = {},
        total = 0,
        culled = 0
    }
    
    for _, object in ipairs(objects) do
        local lodLevel = LODSystem.updateObjectLOD(object, camera)
        
        if lodLevel == "cull" then
            optimized.culled = optimized.culled + 1
        else
            table.insert(optimized[lodLevel], object)
            optimized.total = optimized.total + 1
        end
    end
    
    return optimized
end

-- Get LOD statistics
function LODSystem.getStats()
    local stats = {
        cacheSize = 0,
        cacheHits = 0,
        cacheMisses = 0,
        objectsByLOD = {
            high = 0,
            medium = 0,
            low = 0,
            culled = 0
        }
    }
    
    -- Count cached objects
    for _ in pairs(LODSystem.cache.objectLODs) do
        stats.cacheSize = stats.cacheSize + 1
    end
    
    return stats
end

-- Pre-compute LOD for static objects
function LODSystem.precomputeLOD(objects, camera)
    local precomputed = {}
    
    for _, object in ipairs(objects) do
        if object.static then -- Only precompute for static objects
            local distance = Utils.distance(camera.x, camera.y, object.x, object.y)
            local lodLevel = LODSystem.calculateLOD(distance, object.type)
            
            precomputed[object.id] = {
                lodLevel = lodLevel,
                distance = distance,
                settings = LODSystem.getLODSettings(object.type, lodLevel)
            }
        end
    end
    
    return precomputed
end

-- Batch apply LOD settings
function LODSystem.batchApplyLOD(objects, camera)
    local applied = 0
    
    for _, object in ipairs(objects) do
        local lodLevel = LODSystem.updateObjectLOD(object, camera)
        
        if lodLevel ~= "cull" then
            local settings = LODSystem.getLODSettings(object.type, lodLevel)
            
            if settings then
                if object.type == "planet" then
                    LODSystem.applyPlanetLOD(object, settings)
                elseif object.type == "ring" then
                    LODSystem.applyRingLOD(object, settings)
                elseif object.type == "particle" then
                    LODSystem.applyParticleLOD(object.particles, settings)
                elseif object.type == "player" then
                    LODSystem.applyPlayerLOD(object, settings)
                end
                
                applied = applied + 1
            end
        end
    end
    
    return applied
end

-- Dynamic LOD adjustment based on performance
function LODSystem.adjustForPerformance(frameTime, targetFrameTime)
    local performanceRatio = frameTime / targetFrameTime
    
    if performanceRatio > 1.5 then
        -- Performance is poor, increase LOD distances (more objects use lower detail)
        LODSystem.config.distances.high = LODSystem.config.distances.high * 0.8
        LODSystem.config.distances.medium = LODSystem.config.distances.medium * 0.8
        LODSystem.config.distances.low = LODSystem.config.distances.low * 0.8
        
        Utils.Logger.debug("LOD distances reduced for performance: %.2f", performanceRatio)
    elseif performanceRatio < 0.7 then
        -- Performance is good, decrease LOD distances (more objects use higher detail)
        LODSystem.config.distances.high = LODSystem.config.distances.high * 1.1
        LODSystem.config.distances.medium = LODSystem.config.distances.medium * 1.1
        LODSystem.config.distances.low = LODSystem.config.distances.low * 1.1
        
        Utils.Logger.debug("LOD distances increased for quality: %.2f", performanceRatio)
    end
end

-- Clean up LOD system
function LODSystem.cleanup()
    LODSystem.clearCache()
    Utils.Logger.info("LOD system cleaned up")
end

return LODSystem 