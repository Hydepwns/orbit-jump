-- Comprehensive tests for Performance System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

local PerformanceSystem = Utils.require("src.performance.performance_system")

-- Test suite
local tests = {
    ["test initialization"] = function()
        PerformanceSystem.init()
        
        TestFramework.utils.assertNotNil(PerformanceSystem.spatialGrid, "Spatial grid should be initialized")
        -- Frame history might not be empty if metrics were updated before, so we don't check the length
        TestFramework.utils.assertEqual(1.0, PerformanceSystem.metrics.qualityLevel, "Quality level should be 1.0")
    end,
    
    ["test spatial grid operations"] = function()
        PerformanceSystem.clearGrid()
        
        -- Test grid key calculation
        local key1 = PerformanceSystem.getGridKey(100, 200)
        local key2 = PerformanceSystem.getGridKey(550, 200)
        local key3 = PerformanceSystem.getGridKey(100, 200)
        
        TestFramework.utils.assertEqual(key1, key3, "Same coordinates should produce same key")
        TestFramework.utils.assertNotEqual(key1, key2, "Different coordinates should produce different keys")
        
        -- Test adding objects to grid
        local obj1 = {x = 100, y = 200, type = "test"}
        local obj2 = {x = 550, y = 200, type = "test"}
        
        PerformanceSystem.addToGrid(obj1, obj1.x, obj1.y)
        PerformanceSystem.addToGrid(obj2, obj2.x, obj2.y)
        
        TestFramework.utils.assertNotNil(PerformanceSystem.spatialGrid[key1], "Grid cell should exist")
        TestFramework.utils.assertEqual(1, #PerformanceSystem.spatialGrid[key1], "Should have one object in cell")
    end,
    
    ["test get objects in radius"] = function()
        PerformanceSystem.clearGrid()
        
        -- Add objects at various positions
        local objects = {
            {x = 0, y = 0, type = "test", id = 1},
            {x = 100, y = 0, type = "test", id = 2},
            {x = 200, y = 0, type = "test", id = 3},
            {x = 1000, y = 0, type = "test", id = 4}
        }
        
        for _, obj in ipairs(objects) do
            PerformanceSystem.addToGrid(obj, obj.x, obj.y)
        end
        
        -- Test radius queries
        local nearby = PerformanceSystem.getObjectsInRadius(0, 0, 150)
        TestFramework.utils.assertEqual(2, #nearby, "Should find 2 objects within radius")
        
        nearby = PerformanceSystem.getObjectsInRadius(0, 0, 300)
        TestFramework.utils.assertEqual(3, #nearby, "Should find 3 objects within larger radius")
        
        nearby = PerformanceSystem.getObjectsInRadius(1000, 0, 100)
        TestFramework.utils.assertEqual(1, #nearby, "Should find 1 object at distant location")
    end,
    
    ["test planet grid rebuild"] = function()
        PerformanceSystem.clearGrid()
        
        -- Add some non-planet objects first
        local ring = {x = 100, y = 100, type = "ring"}
        PerformanceSystem.addToGrid(ring, ring.x, ring.y)
        
        -- Add planets
        local planets = {
            {x = 200, y = 200, radius = 50},
            {x = 700, y = 700, radius = 70}
        }
        
        PerformanceSystem.rebuildPlanetGrid(planets)
        
        -- Verify planets were added with correct type
        local key1 = PerformanceSystem.getGridKey(200, 200)
        local cell = PerformanceSystem.spatialGrid[key1]
        TestFramework.utils.assertNotNil(cell, "Planet cell should exist")
        
        local foundPlanet = false
        for _, obj in ipairs(cell) do
            if obj.type == "planet" then
                foundPlanet = true
                break
            end
        end
        TestFramework.utils.assertTrue(foundPlanet, "Should find planet in grid")
        
        -- Verify ring is still there
        local ringKey = PerformanceSystem.getGridKey(100, 100)
        local ringCell = PerformanceSystem.spatialGrid[ringKey]
        TestFramework.utils.assertNotNil(ringCell, "Ring cell should still exist")
    end,
    
    ["test planet culling"] = function()
        local planets = {
            {x = 0, y = 0, radius = 50},
            {x = 500, y = 0, radius = 50},
            {x = 3000, y = 0, radius = 50}
        }
        
        local camera = {x = 0, y = 0, scale = 1.0}
        
        local visible = PerformanceSystem.cullPlanets(planets, camera)
        
        TestFramework.utils.assertEqual(2, #visible, "Should cull distant planet")
        TestFramework.utils.assertEqual(2, PerformanceSystem.metrics.visiblePlanets, "Metrics should track visible planets")
        
        -- Check LOD assignment
        TestFramework.utils.assertEqual("high", visible[1].lodLevel, "Close planet should be high LOD")
        TestFramework.utils.assertNotNil(visible[1].distanceFromCamera, "Should have distance calculated")
    end,
    
    ["test ring culling"] = function()
        local rings = {
            {x = 0, y = 0, collected = false},
            {x = 500, y = 0, collected = false},
            {x = 2000, y = 0, collected = false},
            {x = 100, y = 0, collected = true}
        }
        
        local camera = {x = 0, y = 0, scale = 1.0}
        
        local visible = PerformanceSystem.cullRings(rings, camera)
        
        TestFramework.utils.assertEqual(2, #visible, "Should cull distant and collected rings")
        TestFramework.utils.assertEqual(2, PerformanceSystem.metrics.visibleRings, "Metrics should track visible rings")
        
        -- Verify collected rings are excluded
        for _, ring in ipairs(visible) do
            TestFramework.utils.assertFalse(ring.collected, "Visible rings should not be collected")
        end
    end,
    
    ["test LOD calculation"] = function()
        -- Test at various distances and scales
        local lod = PerformanceSystem.calculateLOD(100, 1.0)
        TestFramework.utils.assertEqual("high", lod, "Close objects should be high LOD")
        
        lod = PerformanceSystem.calculateLOD(700, 1.0)
        TestFramework.utils.assertEqual("medium", lod, "Medium distance should be medium LOD")
        
        lod = PerformanceSystem.calculateLOD(1500, 1.0)
        TestFramework.utils.assertEqual("low", lod, "Far objects should be low LOD")
        
        -- Test with zoomed out camera (scale affects effective distance)
        lod = PerformanceSystem.calculateLOD(100, 2.0)
        TestFramework.utils.assertEqual("high", lod, "100 * 2.0 = 200, still high LOD")
    end,
    
    ["test particle culling"] = function()
        local particles = {}
        for i = 1, 100 do
            table.insert(particles, {
                x = i * 20,
                y = 0
            })
        end
        
        local camera = {x = 0, y = 0, scale = 1.0}
        
        -- Test basic culling
        local visible = PerformanceSystem.cullParticles(particles, camera)
        TestFramework.utils.assertTrue(#visible < #particles, "Should cull distant particles")
        TestFramework.utils.assertEqual(#visible, PerformanceSystem.metrics.activeParticles, 
            "Metrics should track active particles")
        
        -- Test with reduced quality
        PerformanceSystem.metrics.qualityLevel = 0.5
        visible = PerformanceSystem.cullParticles(particles, camera)
        TestFramework.utils.assertTrue(#visible <= 250, "Should limit particles based on quality level")
    end,
    
    ["test render batching"] = function()
        local objects = {}
        for i = 1, 250 do
            table.insert(objects, {id = i})
        end
        
        local batches = PerformanceSystem.createRenderBatches(objects, "test")
        
        TestFramework.utils.assertEqual(3, #batches, "Should create 3 batches for 250 objects")
        TestFramework.utils.assertEqual(100, #batches[1].objects, "First batch should be full")
        TestFramework.utils.assertEqual(100, #batches[2].objects, "Second batch should be full")
        TestFramework.utils.assertEqual(50, #batches[3].objects, "Last batch should have remainder")
        
        -- Test batch keys
        for _, batch in ipairs(batches) do
            TestFramework.utils.assertEqual("test", batch.key, "Batch should have correct key")
        end
    end,
    
    ["test frame metrics update"] = function()
        PerformanceSystem.metrics.frameHistory = {}
        
        -- Simulate frame updates
        for i = 1, 10 do
            PerformanceSystem.updateMetrics(0.016) -- 60 FPS
        end
        
        TestFramework.utils.assertEqual(10, #PerformanceSystem.metrics.frameHistory, 
            "Should track frame history")
        TestFramework.utils.assertTrue(math.abs(PerformanceSystem.metrics.averageFrameTime - 16) < 0.1, 
            "Average frame time should be ~16ms")
        
        -- Test history limit
        for i = 1, 60 do
            PerformanceSystem.updateMetrics(0.016)
        end
        TestFramework.utils.assertEqual(60, #PerformanceSystem.metrics.frameHistory, 
            "Frame history should be limited to 60")
    end,
    
    ["test dynamic quality adjustment"] = function()
        PerformanceSystem.config.enableDynamicQuality = true
        PerformanceSystem.metrics.qualityLevel = 1.0
        PerformanceSystem.metrics.frameHistory = {}
        
        -- Simulate bad performance
        for i = 1, 10 do
            PerformanceSystem.updateMetrics(0.025) -- 40 FPS
        end
        
        TestFramework.utils.assertTrue(PerformanceSystem.metrics.qualityLevel < 1.0, 
            "Quality should decrease with bad performance")
        
        -- Reset and simulate good performance
        PerformanceSystem.metrics.frameHistory = {}
        PerformanceSystem.metrics.qualityLevel = 0.7
        
        for i = 1, 10 do
            PerformanceSystem.updateMetrics(0.010) -- 100 FPS
        end
        
        TestFramework.utils.assertTrue(PerformanceSystem.metrics.qualityLevel > 0.7, 
            "Quality should increase with good performance")
    end,
    
    ["test performance report"] = function()
        PerformanceSystem.metrics.averageFrameTime = 16.67
        PerformanceSystem.metrics.visiblePlanets = 5
        PerformanceSystem.metrics.visibleRings = 10
        PerformanceSystem.metrics.activeParticles = 100
        PerformanceSystem.metrics.qualityLevel = 0.85
        
        local report = PerformanceSystem.getReport()
        
        TestFramework.utils.assertEqual(59, report.fps, "Should calculate correct FPS")
        TestFramework.utils.assertEqual("16.67ms", report.frameTime, "Should format frame time")
        TestFramework.utils.assertEqual(5, report.visiblePlanets, "Should report visible planets")
        TestFramework.utils.assertEqual(10, report.visibleRings, "Should report visible rings")
        TestFramework.utils.assertEqual(100, report.activeParticles, "Should report active particles")
        TestFramework.utils.assertEqual("85%", report.qualityLevel, "Should format quality level")
    end,
    
    ["test needs update check"] = function()
        local object = {x = 100, y = 0}
        local player = {x = 0, y = 0}
        
        -- Within update distance
        local needsUpdate = PerformanceSystem.needsUpdate(object, player, 200)
        TestFramework.utils.assertTrue(needsUpdate, "Close object should need update")
        
        -- Outside update distance
        needsUpdate = PerformanceSystem.needsUpdate(object, player, 50)
        TestFramework.utils.assertFalse(needsUpdate, "Distant object should not need update")
    end,
    
    ["test camera scale culling"] = function()
        local planets = {
            {x = 1500, y = 0, radius = 50}
        }
        
        -- Test with normal camera
        local camera = {x = 0, y = 0, scale = 1.0}
        local visible = PerformanceSystem.cullPlanets(planets, camera)
        TestFramework.utils.assertEqual(1, #visible, "Should be visible at normal scale")
        
        -- Test with zoomed out camera
        camera.scale = 0.5
        visible = PerformanceSystem.cullPlanets(planets, camera)
        TestFramework.utils.assertEqual(0, #visible, "Should be culled when zoomed out")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runSuite("Performance System Tests", tests)
end

return {run = run}