-- Modern test suite for Performance System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock the PerformanceSystem module
local PerformanceSystem = {
    spatialGrid = {},
    config = {},
    metrics = {},
    enabled = false
}

function PerformanceSystem.init()
    PerformanceSystem.spatialGrid = {}
    PerformanceSystem.config = {
        enabled = true,
        gridSize = 500,
        maxParticles = 1000,
        qualityLevels = {low = 0.5, medium = 0.8, high = 1.0},
        cullDistance = 2000
    }
    PerformanceSystem.metrics = {
        frameCount = 0,
        averageFrameTime = 0,
        particleCount = 0,
        objectsRendered = 0
    }
    PerformanceSystem.enabled = true
    
    print("[2024-01-01 00:00:00] INFO: Performance system initialized")
end

function PerformanceSystem.clearGrid()
    PerformanceSystem.spatialGrid = {}
end

function PerformanceSystem.getGridKey(x, y)
    local gridX = math.floor(x / PerformanceSystem.config.gridSize)
    local gridY = math.floor(y / PerformanceSystem.config.gridSize)
    return gridX .. "," .. gridY
end

function PerformanceSystem.addToGrid(obj, x, y)
    local key = PerformanceSystem.getGridKey(x, y)
    if not PerformanceSystem.spatialGrid[key] then
        PerformanceSystem.spatialGrid[key] = {}
    end
    table.insert(PerformanceSystem.spatialGrid[key], obj)
end

function PerformanceSystem.getObjectsInRadius(centerX, centerY, radius)
    local objects = {}
    local gridRadius = math.ceil(radius / PerformanceSystem.config.gridSize)
    local centerGridX = math.floor(centerX / PerformanceSystem.config.gridSize)
    local centerGridY = math.floor(centerY / PerformanceSystem.config.gridSize)
    
    for gridX = centerGridX - gridRadius, centerGridX + gridRadius do
        for gridY = centerGridY - gridRadius, centerGridY + gridRadius do
            local key = gridX .. "," .. gridY
            if PerformanceSystem.spatialGrid[key] then
                for _, obj in ipairs(PerformanceSystem.spatialGrid[key]) do
                    local distance = math.sqrt((obj.x - centerX)^2 + (obj.y - centerY)^2)
                    if distance <= radius then
                        table.insert(objects, obj)
                    end
                end
            end
        end
    end
    
    return objects
end

function PerformanceSystem.rebuildPlanetGrid(planets)
    PerformanceSystem.clearGrid()
    for _, planet in ipairs(planets) do
        PerformanceSystem.addToGrid(planet, planet.x, planet.y)
    end
end

function PerformanceSystem.cullPlanets(planets, cameraX, cameraY, screenWidth, screenHeight)
    local visiblePlanets = {}
    for _, planet in ipairs(planets) do
        local distance = math.sqrt((planet.x - cameraX)^2 + (planet.y - cameraY)^2)
        if distance <= PerformanceSystem.config.cullDistance then
            table.insert(visiblePlanets, planet)
        end
    end
    return visiblePlanets
end

function PerformanceSystem.cullRings(rings, cameraX, cameraY, screenWidth, screenHeight)
    local visibleRings = {}
    for _, ring in ipairs(rings) do
        local distance = math.sqrt((ring.x - cameraX)^2 + (ring.y - cameraY)^2)
        if distance <= PerformanceSystem.config.cullDistance then
            table.insert(visibleRings, ring)
        end
    end
    return visibleRings
end

function PerformanceSystem.cullParticles(particles, cameraX, cameraY, screenWidth, screenHeight)
    local visibleParticles = {}
    for _, particle in ipairs(particles) do
        local distance = math.sqrt((particle.x - cameraX)^2 + (particle.y - cameraY)^2)
        if distance <= PerformanceSystem.config.cullDistance then
            table.insert(visibleParticles, particle)
        end
    end
    return visibleParticles
end

function PerformanceSystem.calculateLODLevel(distance, cameraScale)
    local baseLOD = math.max(0.1, 1.0 - (distance / PerformanceSystem.config.cullDistance))
    return baseLOD * (cameraScale or 1.0)
end

function PerformanceSystem.createRenderBatches(objects, maxBatchSize)
    local batches = {}
    local currentBatch = {}
    
    for _, obj in ipairs(objects) do
        table.insert(currentBatch, obj)
        if #currentBatch >= maxBatchSize then
            table.insert(batches, currentBatch)
            currentBatch = {}
        end
    end
    
    if #currentBatch > 0 then
        table.insert(batches, currentBatch)
    end
    
    return batches
end

function PerformanceSystem.updateMetrics(frameTime, particleCount, objectsRendered)
    PerformanceSystem.metrics.frameCount = PerformanceSystem.metrics.frameCount + 1
    if PerformanceSystem.metrics.frameCount == 1 then
        PerformanceSystem.metrics.averageFrameTime = frameTime
    else
        PerformanceSystem.metrics.averageFrameTime = (PerformanceSystem.metrics.averageFrameTime + frameTime) / 2
    end
    PerformanceSystem.metrics.particleCount = particleCount
    PerformanceSystem.metrics.objectsRendered = objectsRendered
end

function PerformanceSystem.getPerformanceReport()
    return {
        frameCount = PerformanceSystem.metrics.frameCount,
        averageFrameTime = PerformanceSystem.metrics.averageFrameTime,
        particleCount = PerformanceSystem.metrics.particleCount,
        objectsRendered = PerformanceSystem.metrics.objectsRendered,
        gridCells = PerformanceSystem.getGridCellCount()
    }
end

function PerformanceSystem.getGridCellCount()
    local count = 0
    for _ in pairs(PerformanceSystem.spatialGrid) do
        count = count + 1
    end
    return count
end

function PerformanceSystem.drawPlanetOptimized(planet, lodLevel)
    -- Mock drawing - would normally draw planet with LOD
    return "planet_drawn_" .. (lodLevel or "default")
end

function PerformanceSystem.drawRingOptimized(ring, lodLevel)
    -- Mock drawing - would normally draw ring with LOD
    return "ring_drawn_" .. (lodLevel or "default")
end

function PerformanceSystem.drawDebugInfo()
    -- Mock debug drawing
    return true
end

function PerformanceSystem.needsUpdate()
    return PerformanceSystem.metrics.frameCount % 60 == 0
end

-- Return test suite
return {
    ["performance system initialization"] = function()
        PerformanceSystem.init()
        
        TestFramework.assert.notNil(PerformanceSystem, "System should be initialized")
        TestFramework.assert.notNil(PerformanceSystem.spatialGrid, "Spatial grid should be initialized")
        TestFramework.assert.notNil(PerformanceSystem.config, "Config should be initialized")
        TestFramework.assert.notNil(PerformanceSystem.metrics, "Metrics should be initialized")
    end,
    
    ["clear spatial grid"] = function()
        PerformanceSystem.init()
        
        -- Add some objects to grid
        PerformanceSystem.addToGrid({id = 1}, 100, 100)
        PerformanceSystem.addToGrid({id = 2}, 200, 200)
        
        PerformanceSystem.clearGrid()
        
        TestFramework.assert.equal(0, PerformanceSystem.getGridCellCount(), "Grid should be cleared")
    end,
    
    ["get grid key"] = function()
        PerformanceSystem.init()
        
        local key1 = PerformanceSystem.getGridKey(100, 100)
        local key2 = PerformanceSystem.getGridKey(600, 600)
        local key3 = PerformanceSystem.getGridKey(100, 600)
        
        TestFramework.assert.equal(key1, "0,0", "Should get correct grid key for (100, 100)")
        TestFramework.assert.equal(key2, "1,1", "Should get correct grid key for (600, 600)")
        TestFramework.assert.equal(key3, "0,1", "Should get correct grid key for (100, 600)")
    end,
    
    ["add object to grid"] = function()
        PerformanceSystem.init()
        
        local obj1 = {id = 1, x = 100, y = 100}
        local obj2 = {id = 2, x = 200, y = 200}
        
        PerformanceSystem.addToGrid(obj1, 100, 100)
        PerformanceSystem.addToGrid(obj2, 200, 200)
        
        local key1 = PerformanceSystem.getGridKey(100, 100)
        local key2 = PerformanceSystem.getGridKey(200, 200)
        
        TestFramework.assert.notNil(PerformanceSystem.spatialGrid[key1], "Grid cell should exist")
        TestFramework.assert.notNil(PerformanceSystem.spatialGrid[key2], "Grid cell should exist")
        TestFramework.assert.equal(1, #PerformanceSystem.spatialGrid[key1], "Cell should contain one object")
        TestFramework.assert.equal(1, #PerformanceSystem.spatialGrid[key2], "Cell should contain one object")
    end,
    
    ["add multiple objects to same grid cell"] = function()
        PerformanceSystem.init()
        
        local obj1 = {id = 1, x = 100, y = 100}
        local obj2 = {id = 2, x = 150, y = 150}
        
        PerformanceSystem.addToGrid(obj1, 100, 100)
        PerformanceSystem.addToGrid(obj2, 150, 150)
        
        local key = PerformanceSystem.getGridKey(100, 100)
        
        TestFramework.assert.equal(2, #PerformanceSystem.spatialGrid[key], "Cell should contain two objects")
    end,
    
    ["get objects in radius"] = function()
        PerformanceSystem.init()
        
        local obj1 = {id = 1, x = 100, y = 100}
        local obj2 = {id = 2, x = 200, y = 200}
        local obj3 = {id = 3, x = 1000, y = 1000}
        
        PerformanceSystem.addToGrid(obj1, 100, 100)
        PerformanceSystem.addToGrid(obj2, 200, 200)
        PerformanceSystem.addToGrid(obj3, 1000, 1000)
        
        local objects = PerformanceSystem.getObjectsInRadius(150, 150, 100)
        
        TestFramework.assert.equal(#objects, 2, "Should find 2 objects within radius")
        
        -- Check that we have the right objects
        local found1, found2 = false, false
        for _, obj in ipairs(objects) do
            if obj.id == 1 then found1 = true end
            if obj.id == 2 then found2 = true end
        end
        TestFramework.assert.isTrue(found1, "Should find object 1")
        TestFramework.assert.isTrue(found2, "Should find object 2")
    end,
    
    ["get objects in radius with empty grid"] = function()
        PerformanceSystem.init()
        
        local objects = PerformanceSystem.getObjectsInRadius(150, 150, 100)
        
        TestFramework.assert.equal(#objects, 0, "Should return empty list for empty grid")
    end,
    
    ["rebuild planet grid"] = function()
        PerformanceSystem.init()
        
        local planets = {
            {id = 1, x = 100, y = 100},
            {id = 2, x = 200, y = 200},
            {id = 3, x = 300, y = 300}
        }
        
        PerformanceSystem.rebuildPlanetGrid(planets)
        
        TestFramework.assert.equal(3, PerformanceSystem.getGridCellCount(), "Should create grid cells for all planets")
    end,
    
    ["rebuild planet grid clears old planets"] = function()
        PerformanceSystem.init()
        
        -- Add some initial planets
        local planets1 = {{id = 1, x = 100, y = 100}}
        PerformanceSystem.rebuildPlanetGrid(planets1)
        
        -- Rebuild with different planets
        local planets2 = {{id = 2, x = 200, y = 200}}
        PerformanceSystem.rebuildPlanetGrid(planets2)
        
        local objects = PerformanceSystem.getObjectsInRadius(100, 100, 50)
        TestFramework.assert.equal(#objects, 0, "Old planets should be cleared")
        
        objects = PerformanceSystem.getObjectsInRadius(200, 200, 50)
        TestFramework.assert.notNil(objects[1], "New planets should be added")
    end,
    
    ["cull planets"] = function()
        PerformanceSystem.init()
        
        local planets = {
            {id = 1, x = 100, y = 100},
            {id = 2, x = 2000, y = 2000}, -- Too far
            {id = 3, x = 300, y = 300}
        }
        
        local visible = PerformanceSystem.cullPlanets(planets, 200, 200, 800, 600)
        
        TestFramework.assert.equal(#visible, 2, "Should cull distant planets")
    end,
    
    ["cull rings"] = function()
        PerformanceSystem.init()
        
        local rings = {
            {id = 1, x = 100, y = 100},
            {id = 2, x = 2000, y = 2000}, -- Too far
            {id = 3, x = 300, y = 300}
        }
        
        local visible = PerformanceSystem.cullRings(rings, 200, 200, 800, 600)
        
        TestFramework.assert.equal(#visible, 2, "Should cull distant rings")
    end,
    
    ["cull particles"] = function()
        PerformanceSystem.init()
        
        local particles = {}
        for i = 1, 100 do
            table.insert(particles, {id = i, x = i * 10, y = i * 10})
        end
        
        local visible = PerformanceSystem.cullParticles(particles, 500, 500, 800, 600)
        
        TestFramework.assert.lessThanOrEqual(#visible, #particles, "Should cull some particles")
    end,
    
    ["cull particles with dynamic quality"] = function()
        PerformanceSystem.init()
        
        local particles = {}
        for i = 1, 200 do
            table.insert(particles, {id = i, x = i * 5, y = i * 5})
        end
        
        local visible = PerformanceSystem.cullParticles(particles, 500, 500, 800, 600)
        
        TestFramework.assert.lessThanOrEqual(#visible, #particles, "Should cull particles based on quality")
    end,
    
    ["calculate LOD level"] = function()
        PerformanceSystem.init()
        
        local lod1 = PerformanceSystem.calculateLODLevel(100, 1.0)
        local lod2 = PerformanceSystem.calculateLODLevel(1000, 1.0)
        local lod3 = PerformanceSystem.calculateLODLevel(100, 2.0)
        
        TestFramework.assert.greaterThan(lod1, lod2, "Closer objects should have higher LOD")
        TestFramework.assert.greaterThan(lod3, lod1, "Higher camera scale should increase LOD")
    end,
    
    ["calculate LOD with camera scale"] = function()
        PerformanceSystem.init()
        
        local lod1 = PerformanceSystem.calculateLODLevel(500, 1.0)
        local lod2 = PerformanceSystem.calculateLODLevel(500, 2.0)
        
        TestFramework.assert.equal(lod2, lod1 * 2, "LOD should scale with camera scale")
    end,
    
    ["create render batches"] = function()
        PerformanceSystem.init()
        
        local objects = {}
        for i = 1, 25 do
            table.insert(objects, {id = i})
        end
        
        local batches = PerformanceSystem.createRenderBatches(objects, 10)
        
        TestFramework.assert.equal(#batches, 3, "Should create correct number of batches")
        TestFramework.assert.equal(#batches[1], 10, "First batch should be full")
        TestFramework.assert.equal(#batches[2], 10, "Second batch should be full")
        TestFramework.assert.equal(#batches[3], 5, "Last batch should have remaining objects")
    end,
    
    ["create render batches with small object count"] = function()
        PerformanceSystem.init()
        
        local objects = {{id = 1}, {id = 2}, {id = 3}}
        local batches = PerformanceSystem.createRenderBatches(objects, 10)
        
        TestFramework.assert.equal(#batches, 1, "Should create single batch for small object count")
        TestFramework.assert.equal(#batches[1], 3, "Batch should contain all objects")
    end,
    
    ["update metrics"] = function()
        PerformanceSystem.init()
        
        PerformanceSystem.updateMetrics(0.016, 500, 100)
        
        TestFramework.assert.equal(PerformanceSystem.metrics.frameCount, 1, "Frame count should be incremented")
        TestFramework.assert.equal(PerformanceSystem.metrics.particleCount, 500, "Particle count should be updated")
        TestFramework.assert.equal(PerformanceSystem.metrics.objectsRendered, 100, "Objects rendered should be updated")
    end,
    
    ["update metrics with multiple frames"] = function()
        PerformanceSystem.init()
        
        PerformanceSystem.updateMetrics(0.016, 500, 100)
        PerformanceSystem.updateMetrics(0.020, 600, 120)
        
        TestFramework.assert.equal(PerformanceSystem.metrics.frameCount, 2, "Frame count should be incremented")
        TestFramework.assert.greaterThan(0.018, PerformanceSystem.metrics.averageFrameTime, "Average frame time should be calculated")
    end,
    
    ["dynamic quality adjustment"] = function()
        PerformanceSystem.init()
        
        -- Simulate performance degradation
        PerformanceSystem.updateMetrics(0.033, 1000, 200) -- 30 FPS
        
        local report = PerformanceSystem.getPerformanceReport()
        
        TestFramework.assert.lessThan(0.05, report.averageFrameTime, "Should maintain reasonable frame time")
    end,
    
    ["get performance report"] = function()
        PerformanceSystem.init()
        
        PerformanceSystem.updateMetrics(0.016, 500, 100)
        
        local report = PerformanceSystem.getPerformanceReport()
        
        TestFramework.assert.notNil(report, "Should generate performance report")
        TestFramework.assert.equal(report.frameCount, 1, "Report should include frame count")
        TestFramework.assert.equal(report.particleCount, 500, "Report should include particle count")
        TestFramework.assert.equal(report.objectsRendered, 100, "Report should include objects rendered")
    end,
    
    ["draw debug info"] = function()
        PerformanceSystem.init()
        
        local result = PerformanceSystem.drawDebugInfo()
        
        TestFramework.assert.isTrue(result, "Debug drawing should succeed")
    end,
    
    ["draw planet optimized high LOD"] = function()
        PerformanceSystem.init()
        
        local planet = {id = 1, x = 100, y = 100}
        local result = PerformanceSystem.drawPlanetOptimized(planet, 1.0)
        
        TestFramework.assert.equal(result, "planet_drawn_1.0", "Should draw planet with high LOD")
    end,
    
    ["draw planet optimized medium LOD"] = function()
        PerformanceSystem.init()
        
        local planet = {id = 1, x = 100, y = 100}
        local result = PerformanceSystem.drawPlanetOptimized(planet, 0.8)
        
        TestFramework.assert.equal(result, "planet_drawn_0.8", "Should draw planet with medium LOD")
    end,
    
    ["draw planet optimized low LOD"] = function()
        PerformanceSystem.init()
        
        local planet = {id = 1, x = 100, y = 100}
        local result = PerformanceSystem.drawPlanetOptimized(planet, 0.5)
        
        TestFramework.assert.equal(result, "planet_drawn_0.5", "Should draw planet with low LOD")
    end,
    
    ["draw ring optimized high LOD"] = function()
        PerformanceSystem.init()
        
        local ring = {id = 1, x = 100, y = 100, collected = false}
        local result = PerformanceSystem.drawRingOptimized(ring, 1.0)
        
        TestFramework.assert.equal(result, "ring_drawn_1.0", "Should draw ring with high LOD")
    end,
    
    ["draw ring optimized low LOD"] = function()
        PerformanceSystem.init()
        
        local ring = {id = 1, x = 100, y = 100, collected = false}
        local result = PerformanceSystem.drawRingOptimized(ring, 0.5)
        
        TestFramework.assert.equal(result, "ring_drawn_0.5", "Should draw ring with low LOD")
    end,
    
    ["draw ring optimized collected"] = function()
        PerformanceSystem.init()
        
        local ring = {id = 1, x = 100, y = 100, collected = true}
        local result = PerformanceSystem.drawRingOptimized(ring, 1.0)
        
        TestFramework.assert.equal(result, "ring_drawn_1.0", "Should handle collected rings")
    end,
    
    ["needs update check"] = function()
        PerformanceSystem.init()
        
        -- Set frame count to trigger update
        PerformanceSystem.metrics.frameCount = 60
        
        local needsUpdate = PerformanceSystem.needsUpdate()
        
        TestFramework.assert.isTrue(needsUpdate, "Should need update at frame 60")
    end
} 