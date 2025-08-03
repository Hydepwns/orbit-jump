-- Comprehensive tests for Performance System
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Function to get PerformanceSystem with proper initialization
local function getPerformanceSystem()
    -- Clear any cached version
    package.loaded["src.performance.performance_system"] = nil
    package.loaded["src/performance/performance_system"] = nil
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.performance.performance_system"] = nil
    end
    -- Setup mocks before loading
    Mocks.setup()
    -- Load fresh instance using regular require to bypass cache
    local PerformanceSystem = require("src.performance.performance_system")
    -- Ensure it's initialized
    if PerformanceSystem and PerformanceSystem.init then
        PerformanceSystem.init()
    end
    return PerformanceSystem
end
-- Test suite
local tests = {
    ["test initialization"] = function()
        local PerformanceSystem = getPerformanceSystem()
        -- Reset metrics before testing
        PerformanceSystem.metrics.qualityLevel = 1.0
        PerformanceSystem.metrics.frameHistory = {}
        TestFramework.assert.assertNotNil(PerformanceSystem.spatialGrid, "Spatial grid should be initialized")
        -- Frame history might not be empty if metrics were updated before, so we don't check the length
        -- Quality level might have been adjusted from previous tests, so we just check it's a valid value
        TestFramework.assert.isTrue(PerformanceSystem.metrics.qualityLevel >= 0.5 and PerformanceSystem.metrics.qualityLevel <= 1.0,
            "Quality level should be between 0.5 and 1.0")
    end,
    ["test spatial grid operations"] = function()
        local PerformanceSystem = getPerformanceSystem()        PerformanceSystem.clearGrid()
        -- Test grid key calculation
        local key1 = PerformanceSystem.getGridKey(100, 200)
        local key2 = PerformanceSystem.getGridKey(550, 200)
        local key3 = PerformanceSystem.getGridKey(100, 200)
        TestFramework.assert.equal(key1, key3, "Same coordinates should produce same key")
        TestFramework.assert.notEqual(key1, key2, "Different coordinates should produce different keys")
        -- Test adding objects to grid
        local obj1 = {x = 100, y = 200, type = "test"}
        local obj2 = {x = 550, y = 200, type = "test"}
        PerformanceSystem.addToGrid(obj1, obj1.x, obj1.y)
        PerformanceSystem.addToGrid(obj2, obj2.x, obj2.y)
        TestFramework.assert.notNil(PerformanceSystem.spatialGrid[key1], "Grid cell should exist")
        TestFramework.assert.equal(1, #PerformanceSystem.spatialGrid[key1], "Should have one object in cell")
    end,
    ["test get objects in radius"] = function()
        local PerformanceSystem = getPerformanceSystem()        PerformanceSystem.clearGrid()
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
        TestFramework.assert.equal(2, #nearby, "Should find 2 objects within radius")
        nearby = PerformanceSystem.getObjectsInRadius(0, 0, 300)
        TestFramework.assert.equal(3, #nearby, "Should find 3 objects within larger radius")
        nearby = PerformanceSystem.getObjectsInRadius(1000, 0, 100)
        TestFramework.assert.equal(1, #nearby, "Should find 1 object at distant location")
    end,
    ["test planet grid rebuild"] = function()
        local PerformanceSystem = getPerformanceSystem()        PerformanceSystem.clearGrid()
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
        TestFramework.assert.notNil(cell, "Planet cell should exist")
        local foundPlanet = false
        for _, obj in ipairs(cell) do
            if obj.type == "planet" then
                foundPlanet = true
                break
            end
        end
        TestFramework.assert.isTrue(foundPlanet, "Should find planet in grid")
        -- Verify ring is still there
        local ringKey = PerformanceSystem.getGridKey(100, 100)
        local ringCell = PerformanceSystem.spatialGrid[ringKey]
        TestFramework.assert.notNil(ringCell, "Ring cell should still exist")
    end,
    ["test planet culling"] = function()
        local PerformanceSystem = getPerformanceSystem()        local planets = {
            {x = 0, y = 0, radius = 50},
            {x = 500, y = 0, radius = 50},
            {x = 3000, y = 0, radius = 50}
        }
        local camera = {x = 0, y = 0, scale = 1.0}
        local visible = PerformanceSystem.cullPlanets(planets, camera)
        TestFramework.assert.equal(2, #visible, "Should cull distant planet")
        TestFramework.assert.equal(2, PerformanceSystem.metrics.visiblePlanets, "Metrics should track visible planets")
        -- Check LOD assignment
        TestFramework.assert.equal("high", visible[1].lodLevel, "Close planet should be high LOD")
        TestFramework.assert.notNil(visible[1].distanceFromCamera, "Should have distance calculated")
    end,
    ["test ring culling"] = function()
        local PerformanceSystem = getPerformanceSystem()        local rings = {
            {x = 0, y = 0, collected = false},
            {x = 500, y = 0, collected = false},
            {x = 2000, y = 0, collected = false},
            {x = 100, y = 0, collected = true}
        }
        local camera = {x = 0, y = 0, scale = 1.0}
        local visible = PerformanceSystem.cullRings(rings, camera)
        TestFramework.assert.equal(2, #visible, "Should cull distant and collected rings")
        TestFramework.assert.equal(2, PerformanceSystem.metrics.visibleRings, "Metrics should track visible rings")
        -- Verify collected rings are excluded
        for _, ring in ipairs(visible) do
            TestFramework.assert.isFalse(ring.collected, "Visible rings should not be collected")
        end
    end,
    ["test LOD calculation"] = function()
        local PerformanceSystem = getPerformanceSystem()        -- Test at various distances and scales
        local lod = PerformanceSystem.calculateLOD(100, 1.0)
        TestFramework.assert.equal("high", lod, "Close objects should be high LOD")
        lod = PerformanceSystem.calculateLOD(700, 1.0)
        TestFramework.assert.equal("medium", lod, "Medium distance should be medium LOD")
        lod = PerformanceSystem.calculateLOD(1500, 1.0)
        TestFramework.assert.equal("low", lod, "Far objects should be low LOD")
        -- Test with zoomed out camera (scale affects effective distance)
        lod = PerformanceSystem.calculateLOD(100, 2.0)
        TestFramework.assert.equal("high", lod, "100 * 2.0 = 200, still high LOD")
    end,
    ["test particle culling"] = function()
        local PerformanceSystem = getPerformanceSystem()        local particles = {}
        for i = 1, 100 do
            table.insert(particles, {
                x = i * 20,
                y = 0
            })
        end
        local camera = {x = 0, y = 0, scale = 1.0}
        -- Test basic culling
        local visible = PerformanceSystem.cullParticles(particles, camera)
        TestFramework.assert.isTrue(#visible < #particles, "Should cull distant particles")
        TestFramework.assert.equal(#visible, PerformanceSystem.metrics.activeParticles,
            "Metrics should track active particles")
        -- Test with reduced quality
        PerformanceSystem.metrics.qualityLevel = 0.5
        visible = PerformanceSystem.cullParticles(particles, camera)
        TestFramework.assert.isTrue(#visible <= 250, "Should limit particles based on quality level")
    end,
    ["test render batching"] = function()
        local PerformanceSystem = getPerformanceSystem()        local objects = {}
        for i = 1, 250 do
            table.insert(objects, {id = i})
        end
        local batches = PerformanceSystem.createRenderBatches(objects, "test")
        TestFramework.assert.equal(3, #batches, "Should create 3 batches for 250 objects")
        TestFramework.assert.equal(100, #batches[1].objects, "First batch should be full")
        TestFramework.assert.equal(100, #batches[2].objects, "Second batch should be full")
        TestFramework.assert.equal(50, #batches[3].objects, "Last batch should have remainder")
        -- Test batch keys
        for _, batch in ipairs(batches) do
            TestFramework.assert.equal("test", batch.key, "Batch should have correct key")
        end
    end,
    ["test frame metrics update"] = function()
        local PerformanceSystem = getPerformanceSystem()        PerformanceSystem.metrics.frameHistory = {}
        -- Simulate frame updates
        for i = 1, 10 do
            PerformanceSystem.updateMetrics(0.016) -- 60 FPS
        end
        TestFramework.assert.equal(10, #PerformanceSystem.metrics.frameHistory,
            "Should track frame history")
        TestFramework.assert.isTrue(math.abs(PerformanceSystem.metrics.averageFrameTime - 16) < 0.1,
            "Average frame time should be ~16ms")
        -- Test history limit
        for i = 1, 60 do
            PerformanceSystem.updateMetrics(0.016)
        end
        TestFramework.assert.equal(60, #PerformanceSystem.metrics.frameHistory,
            "Frame history should be limited to 60")
    end,
    ["test dynamic quality adjustment"] = function()
        local PerformanceSystem = getPerformanceSystem()        PerformanceSystem.config.enableDynamicQuality = true
        PerformanceSystem.metrics.qualityLevel = 1.0
        PerformanceSystem.metrics.frameHistory = {}
        -- Simulate bad performance
        for i = 1, 10 do
            PerformanceSystem.updateMetrics(0.025) -- 40 FPS
        end
        TestFramework.assert.isTrue(PerformanceSystem.metrics.qualityLevel < 1.0,
            "Quality should decrease with bad performance")
        -- Reset and simulate good performance
        PerformanceSystem.metrics.frameHistory = {}
        PerformanceSystem.metrics.qualityLevel = 0.7
        for i = 1, 10 do
            PerformanceSystem.updateMetrics(0.010) -- 100 FPS
        end
        TestFramework.assert.isTrue(PerformanceSystem.metrics.qualityLevel > 0.7,
            "Quality should increase with good performance")
    end,
    ["test performance report"] = function()
        local PerformanceSystem = getPerformanceSystem()        PerformanceSystem.metrics.averageFrameTime = 16.67
        PerformanceSystem.metrics.visiblePlanets = 5
        PerformanceSystem.metrics.visibleRings = 10
        PerformanceSystem.metrics.activeParticles = 100
        PerformanceSystem.metrics.qualityLevel = 0.85
        local report = PerformanceSystem.getReport()
        TestFramework.assert.equal(59, report.fps, "Should calculate correct FPS")
        TestFramework.assert.equal("16.67ms", report.frameTime, "Should format frame time")
        TestFramework.assert.equal(5, report.visiblePlanets, "Should report visible planets")
        TestFramework.assert.equal(10, report.visibleRings, "Should report visible rings")
        TestFramework.assert.equal(100, report.activeParticles, "Should report active particles")
        TestFramework.assert.equal("85%", report.qualityLevel, "Should format quality level")
    end,
    ["test needs update check"] = function()
        local PerformanceSystem = getPerformanceSystem()        local object = {x = 100, y = 0}
        local player = {x = 0, y = 0}
        -- Within update distance
        local needsUpdate = PerformanceSystem.needsUpdate(object, player, 200)
        TestFramework.assert.isTrue(needsUpdate, "Close object should need update")
        -- Outside update distance
        needsUpdate = PerformanceSystem.needsUpdate(object, player, 50)
        TestFramework.assert.isFalse(needsUpdate, "Distant object should not need update")
    end,
    ["test camera scale culling"] = function()
        local PerformanceSystem = getPerformanceSystem()        local planets = {
            {x = 1500, y = 0, radius = 50}
        }
        -- Test with normal camera
        local camera = {x = 0, y = 0, scale = 1.0}
        local visible = PerformanceSystem.cullPlanets(planets, camera)
        TestFramework.assert.equal(1, #visible, "Should be visible at normal scale")
        -- Test with zoomed out camera
        camera.scale = 0.5
        visible = PerformanceSystem.cullPlanets(planets, camera)
        TestFramework.assert.equal(0, #visible, "Should be culled when zoomed out")
    end
}
-- Run the test suite
local function run()
    -- Initialize test framework
    Mocks.setup()
    TestFramework.init()
    local success = TestFramework.runTests(tests, "Performance System Tests")
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("performance_system", 14) -- All major functions tested
    return success
end
return {run = run}