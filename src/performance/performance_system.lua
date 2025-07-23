-- Performance Optimization System for Orbit Jump
-- Handles spatial partitioning, culling, and efficient updates

local Utils = Utils.Utils.require("src.utils.utils")
local PerformanceSystem = {}

-- Configuration
PerformanceSystem.config = {
    -- Spatial grid
    gridCellSize = 500,
    
    -- Culling distances
    planetCullDistance = 2000,
    ringCullDistance = 1500,
    particleCullDistance = 1000,
    
    -- Update distances
    planetUpdateDistance = 1500,
    ringUpdateDistance = 1200,
    
    -- LOD (Level of Detail) distances
    lodHighDistance = 500,
    lodMediumDistance = 1000,
    
    -- Batch rendering
    maxBatchSize = 100,
    
    -- Frame budget (ms)
    targetFrameTime = 16.67, -- 60 FPS
    
    -- Dynamic quality
    enableDynamicQuality = true,
    minParticles = 50,
    maxParticles = 500
}

-- Performance metrics
PerformanceSystem.metrics = {
    visiblePlanets = 0,
    visibleRings = 0,
    activeParticles = 0,
    frameTime = 0,
    averageFrameTime = 0,
    frameHistory = {},
    qualityLevel = 1.0
}

-- Spatial grid for efficient lookups
PerformanceSystem.spatialGrid = {}

-- Initialize
function PerformanceSystem.init()
    PerformanceSystem.clearGrid()
    Utils.Logger.info("Performance system initialized")
end

-- Clear spatial grid
function PerformanceSystem.clearGrid()
    PerformanceSystem.spatialGrid = {}
end

-- Get grid cell key
function PerformanceSystem.getGridKey(x, y)
    local cellSize = PerformanceSystem.config.gridCellSize
    local gx = math.floor(x / cellSize)
    local gy = math.floor(y / cellSize)
    return string.format("%d,%d", gx, gy)
end

-- Add object to spatial grid
function PerformanceSystem.addToGrid(object, x, y)
    local key = PerformanceSystem.getGridKey(x, y)
    if not PerformanceSystem.spatialGrid[key] then
        PerformanceSystem.spatialGrid[key] = {}
    end
    table.insert(PerformanceSystem.spatialGrid[key], object)
end

-- Get objects in radius
function PerformanceSystem.getObjectsInRadius(x, y, radius)
    local objects = {}
    local cellSize = PerformanceSystem.config.gridCellSize
    local cellRadius = math.ceil(radius / cellSize)
    
    for dx = -cellRadius, cellRadius do
        for dy = -cellRadius, cellRadius do
            local gx = math.floor(x / cellSize) + dx
            local gy = math.floor(y / cellSize) + dy
            local key = string.format("%d,%d", gx, gy)
            
            if PerformanceSystem.spatialGrid[key] then
                for _, obj in ipairs(PerformanceSystem.spatialGrid[key]) do
                    local dist = Utils.distance(x, y, obj.x, obj.y)
                    if dist <= radius then
                        table.insert(objects, obj)
                    end
                end
            end
        end
    end
    
    return objects
end

-- Rebuild spatial grid for planets
function PerformanceSystem.rebuildPlanetGrid(planets)
    -- Clear planet entries
    for key, objects in pairs(PerformanceSystem.spatialGrid) do
        for i = #objects, 1, -1 do
            if objects[i].type == "planet" then
                table.remove(objects, i)
            end
        end
    end
    
    -- Add planets to grid
    for _, planet in ipairs(planets) do
        planet.type = "planet"
        PerformanceSystem.addToGrid(planet, planet.x, planet.y)
    end
end

-- Cull planets based on camera position
function PerformanceSystem.cullPlanets(planets, camera)
    local visiblePlanets = {}
    local camX, camY = camera.x, camera.y
    local cullDistance = PerformanceSystem.config.planetCullDistance * camera.scale
    
    for _, planet in ipairs(planets) do
        local dist = Utils.distance(camX, camY, planet.x, planet.y)
        if dist <= cullDistance + planet.radius then
            planet.distanceFromCamera = dist
            planet.lodLevel = PerformanceSystem.calculateLOD(dist, camera.scale)
            table.insert(visiblePlanets, planet)
        end
    end
    
    PerformanceSystem.metrics.visiblePlanets = #visiblePlanets
    return visiblePlanets
end

-- Cull rings based on camera position
function PerformanceSystem.cullRings(rings, camera)
    local visibleRings = {}
    local camX, camY = camera.x, camera.y
    local cullDistance = PerformanceSystem.config.ringCullDistance * camera.scale
    
    for _, ring in ipairs(rings) do
        if not ring.collected then
            local dist = Utils.distance(camX, camY, ring.x, ring.y)
            if dist <= cullDistance then
                ring.distanceFromCamera = dist
                table.insert(visibleRings, ring)
            end
        end
    end
    
    PerformanceSystem.metrics.visibleRings = #visibleRings
    return visibleRings
end

-- Calculate LOD level
function PerformanceSystem.calculateLOD(distance, cameraScale)
    local adjustedDistance = distance * cameraScale
    
    if adjustedDistance < PerformanceSystem.config.lodHighDistance then
        return "high"
    elseif adjustedDistance < PerformanceSystem.config.lodMediumDistance then
        return "medium"
    else
        return "low"
    end
end

-- Optimize particle updates
function PerformanceSystem.cullParticles(particles, camera)
    local visibleParticles = {}
    local camX, camY = camera.x, camera.y
    local cullDistance = PerformanceSystem.config.particleCullDistance * camera.scale
    
    -- Dynamic particle limit based on performance
    local maxParticles = PerformanceSystem.config.maxParticles
    if PerformanceSystem.config.enableDynamicQuality then
        maxParticles = math.floor(maxParticles * PerformanceSystem.metrics.qualityLevel)
    end
    
    for i, particle in ipairs(particles) do
        if i > maxParticles then break end
        
        local dist = Utils.distance(camX, camY, particle.x, particle.y)
        if dist <= cullDistance then
            table.insert(visibleParticles, particle)
        end
    end
    
    PerformanceSystem.metrics.activeParticles = #visibleParticles
    return visibleParticles
end

-- Batch rendering optimization
function PerformanceSystem.createRenderBatches(objects, batchKey)
    local batches = {}
    local currentBatch = {key = batchKey, objects = {}}
    
    for _, obj in ipairs(objects) do
        table.insert(currentBatch.objects, obj)
        
        if #currentBatch.objects >= PerformanceSystem.config.maxBatchSize then
            table.insert(batches, currentBatch)
            currentBatch = {key = batchKey, objects = {}}
        end
    end
    
    if #currentBatch.objects > 0 then
        table.insert(batches, currentBatch)
    end
    
    return batches
end

-- Update frame metrics
function PerformanceSystem.updateMetrics(dt)
    local frameTime = dt * 1000 -- Convert to milliseconds
    PerformanceSystem.metrics.frameTime = frameTime
    
    -- Update frame history
    table.insert(PerformanceSystem.metrics.frameHistory, frameTime)
    if #PerformanceSystem.metrics.frameHistory > 60 then
        table.remove(PerformanceSystem.metrics.frameHistory, 1)
    end
    
    -- Calculate average
    local sum = 0
    for _, time in ipairs(PerformanceSystem.metrics.frameHistory) do
        sum = sum + time
    end
    PerformanceSystem.metrics.averageFrameTime = sum / #PerformanceSystem.metrics.frameHistory
    
    -- Adjust quality level based on performance
    if PerformanceSystem.config.enableDynamicQuality then
        local targetTime = PerformanceSystem.config.targetFrameTime
        
        if PerformanceSystem.metrics.averageFrameTime > targetTime * 1.2 then
            -- Performance is bad, reduce quality
            PerformanceSystem.metrics.qualityLevel = math.max(0.5, 
                PerformanceSystem.metrics.qualityLevel - dt * 0.5)
        elseif PerformanceSystem.metrics.averageFrameTime < targetTime * 0.8 then
            -- Performance is good, increase quality
            PerformanceSystem.metrics.qualityLevel = math.min(1.0, 
                PerformanceSystem.metrics.qualityLevel + dt * 0.2)
        end
    end
end

-- Get performance report
function PerformanceSystem.getReport()
    return {
        fps = math.floor(1000 / PerformanceSystem.metrics.averageFrameTime),
        frameTime = string.format("%.2fms", PerformanceSystem.metrics.averageFrameTime),
        visiblePlanets = PerformanceSystem.metrics.visiblePlanets,
        visibleRings = PerformanceSystem.metrics.visibleRings,
        activeParticles = PerformanceSystem.metrics.activeParticles,
        qualityLevel = string.format("%.0f%%", PerformanceSystem.metrics.qualityLevel * 100)
    }
end

-- Draw performance debug info
function PerformanceSystem.drawDebug()
    local report = PerformanceSystem.getReport()
    local y = 10
    
    Utils.setColor({1, 1, 1}, 0.8)
    love.graphics.setFont(love.graphics.newFont(12))
    
    love.graphics.print("FPS: " .. report.fps, 10, y)
    y = y + 15
    love.graphics.print("Frame: " .. report.frameTime, 10, y)
    y = y + 15
    love.graphics.print("Planets: " .. report.visiblePlanets, 10, y)
    y = y + 15
    love.graphics.print("Rings: " .. report.visibleRings, 10, y)
    y = y + 15
    love.graphics.print("Particles: " .. report.activeParticles, 10, y)
    y = y + 15
    love.graphics.print("Quality: " .. report.qualityLevel, 10, y)
end

-- Optimize planet rendering based on LOD
function PerformanceSystem.drawPlanetOptimized(planet, renderer)
    if planet.lodLevel == "high" then
        -- Full detail
        renderer.drawPlanets({planet})
    elseif planet.lodLevel == "medium" then
        -- Reduced detail - skip rotation indicator
        local color = planet.color or Utils.colors.planet1
        Utils.drawCircle(planet.x, planet.y, planet.radius, color)
        
        -- Simple type indicator
        if planet.type and planet.discovered then
            love.graphics.setFont(love.graphics.newFont(12))
            Utils.setColor({1, 1, 1}, 0.6)
            love.graphics.print(planet.type:upper(), planet.x - 15, planet.y - 10)
        end
    else
        -- Low detail - just a circle
        local color = planet.color or Utils.colors.planet1
        local dimColor = {color[1] * 0.7, color[2] * 0.7, color[3] * 0.7}
        Utils.drawCircle(planet.x, planet.y, planet.radius, dimColor)
    end
end

-- Optimize ring rendering
function PerformanceSystem.drawRingOptimized(ring, lodLevel)
    if ring.collected then return end
    
    local alpha = ring.color[4] or 0.8
    
    if lodLevel == "high" or ring.distanceFromCamera < 500 then
        -- Full detail - use normal ring renderer
        return false -- Signal to use normal renderer
    else
        -- Simplified ring
        Utils.setColor(ring.color, alpha * 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", ring.x, ring.y, ring.radius)
        return true -- We handled the drawing
    end
end

-- Check if object needs update
function PerformanceSystem.needsUpdate(object, player, updateDistance)
    local dist = Utils.distance(player.x, player.y, object.x, object.y)
    return dist <= updateDistance
end

return PerformanceSystem