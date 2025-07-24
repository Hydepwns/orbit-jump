-- Comprehensive tests for Map System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks before requiring MapSystem
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock love functions
love.graphics = {
    getWidth = function() return 800 end,
    getHeight = function() return 600 end,
    rectangle = function() end,
    circle = function() end,
    line = function() end,
    printf = function() end,
    print = function() end,
    setFont = function() end,
    getFont = function() return {} end,
    newFont = function() return {} end,
    setLineWidth = function() end,
    push = function() end,
    pop = function() end,
    setScissor = function() end
}

love.mouse = {
    position = {x = 0, y = 0},
    getPosition = function()
        return love.mouse.position.x, love.mouse.position.y
    end
}

-- Mock Utils functions
Utils.setColor = function() end

-- Require MapSystem after mocks are set up
local MapSystem = Utils.require("src.systems.map_system")

-- Mock dependencies
mockWarpZones = {
    activeZones = {}
}

mockArtifactSystem = {
    drawOnMapCalled = false,
    drawOnMap = function(camera, centerX, centerY, scale, alpha)
        mockArtifactSystem.drawOnMapCalled = true
        mockArtifactSystem.lastDrawParams = {
            camera = camera,
            centerX = centerX,
            centerY = centerY,
            scale = scale,
            alpha = alpha
        }
    end
}

-- Test helper functions
local function createTestPlayer(x, y, angle)
    return {
        x = x or 0,
        y = y or 0,
        angle = angle or 0
    }
end

local function createTestPlanet(id, x, y, type, discovered, radius)
    return {
        id = id,
        x = x,
        y = y,
        type = type,
        discovered = discovered == nil and true or discovered,
        radius = radius or 50
    }
end

local function resetMocks()
    mockWarpZones.activeZones = {}
    mockArtifactSystem.drawOnMapCalled = false
    mockArtifactSystem.lastDrawParams = nil
end

-- Test suite
local tests = {
    ["test initialization"] = function()
        MapSystem.init()
        
        TestFramework.utils.assertEqual(0, MapSystem.getDiscoveredCount(), "No planets should be discovered initially")
        TestFramework.utils.assertEqual(0, #MapSystem.visitedSectors, "No sectors should be visited initially")
        TestFramework.utils.assertFalse(MapSystem.isVisible, "Map should not be visible initially")
        TestFramework.utils.assertEqual(0, MapSystem.mapAlpha, "Map alpha should be 0 initially")
    end,
    
    ["test toggle map visibility"] = function()
        MapSystem.init()
        
        -- Toggle on
        MapSystem.toggle()
        TestFramework.utils.assertTrue(MapSystem.isVisible, "Map should be visible after toggle")
        TestFramework.utils.assertEqual(0, MapSystem.mapOffset.x, "Map offset X should be reset")
        TestFramework.utils.assertEqual(0, MapSystem.mapOffset.y, "Map offset Y should be reset")
        
        -- Toggle off
        MapSystem.toggle()
        TestFramework.utils.assertFalse(MapSystem.isVisible, "Map should not be visible after second toggle")
    end,
    
    ["test map fade in and out"] = function()
        MapSystem.init()
        
        -- Test fade in
        MapSystem.isVisible = true
        MapSystem.update(0.1, createTestPlayer(), {})
        TestFramework.utils.assertTrue(MapSystem.mapAlpha > 0, "Map alpha should increase when visible")
        TestFramework.utils.assertTrue(MapSystem.mapAlpha <= 1, "Map alpha should not exceed 1")
        
        -- Complete fade in
        MapSystem.update(1.0, createTestPlayer(), {})
        TestFramework.utils.assertEqual(1, MapSystem.mapAlpha, "Map alpha should reach 1")
        
        -- Test fade out
        MapSystem.isVisible = false
        MapSystem.update(0.1, createTestPlayer(), {})
        TestFramework.utils.assertTrue(MapSystem.mapAlpha < 1, "Map alpha should decrease when not visible")
        
        -- Complete fade out
        MapSystem.update(1.0, createTestPlayer(), {})
        TestFramework.utils.assertEqual(0, MapSystem.mapAlpha, "Map alpha should reach 0")
    end,
    
    ["test planet discovery tracking"] = function()
        MapSystem.init()
        
        local planets = {
            createTestPlanet("planet1", 100, 100, "ice", true),
            createTestPlanet("planet2", 200, 200, "lava", false),
            createTestPlanet("planet3", 300, 300, "tech", true)
        }
        
        MapSystem.update(0.1, createTestPlayer(), planets)
        
        TestFramework.utils.assertEqual(2, MapSystem.getDiscoveredCount(), "Should track 2 discovered planets")
        TestFramework.utils.assertNotNil(MapSystem.discoveredPlanets["planet1"], "Planet 1 should be tracked")
        TestFramework.utils.assertNil(MapSystem.discoveredPlanets["planet2"], "Planet 2 should not be tracked")
        TestFramework.utils.assertNotNil(MapSystem.discoveredPlanets["planet3"], "Planet 3 should be tracked")
        
        -- Check stored planet data
        local planet1Data = MapSystem.discoveredPlanets["planet1"]
        TestFramework.utils.assertEqual(100, planet1Data.x, "Planet position X should be stored")
        TestFramework.utils.assertEqual(100, planet1Data.y, "Planet position Y should be stored")
        TestFramework.utils.assertEqual("ice", planet1Data.type, "Planet type should be stored")
        TestFramework.utils.assertEqual(50, planet1Data.radius, "Planet radius should be stored")
    end,
    
    ["test sector tracking"] = function()
        MapSystem.init()
        
        -- Player at origin
        MapSystem.update(0.1, createTestPlayer(0, 0), {})
        TestFramework.utils.assertNotNil(MapSystem.visitedSectors["0,0"], "Origin sector should be visited")
        
        -- Player moves to new sector
        MapSystem.update(0.1, createTestPlayer(1500, 1500), {})
        TestFramework.utils.assertNotNil(MapSystem.visitedSectors["1,1"], "New sector should be visited")
        
        -- Player in negative sector
        MapSystem.update(0.1, createTestPlayer(-1500, -1500), {})
        TestFramework.utils.assertNotNil(MapSystem.visitedSectors["-2,-2"], "Negative sector should be tracked")
        
        -- Count sectors
        local sectorCount = 0
        for _ in pairs(MapSystem.visitedSectors) do
            sectorCount = sectorCount + 1
        end
        TestFramework.utils.assertEqual(3, sectorCount, "Should have 3 visited sectors")
    end,
    
    ["test mouse drag"] = function()
        MapSystem.init()
        MapSystem.isVisible = true
        
        -- Start drag
        MapSystem.mousepressed(100, 100, 1)
        TestFramework.utils.assertTrue(MapSystem.isDragging, "Should start dragging on left click")
        TestFramework.utils.assertEqual(100, MapSystem.dragStart.x, "Drag start X should be set")
        TestFramework.utils.assertEqual(100, MapSystem.dragStart.y, "Drag start Y should be set")
        
        -- Move mouse
        MapSystem.mousemoved(150, 120)
        TestFramework.utils.assertEqual(50, MapSystem.mapOffset.x, "Map offset X should update")
        TestFramework.utils.assertEqual(20, MapSystem.mapOffset.y, "Map offset Y should update")
        
        -- Release drag
        MapSystem.mousereleased(150, 120, 1)
        TestFramework.utils.assertFalse(MapSystem.isDragging, "Should stop dragging on release")
    end,
    
    ["test right click center"] = function()
        MapSystem.init()
        MapSystem.isVisible = true
        MapSystem.mapOffset = {x = 100, y = 100}
        
        MapSystem.mousepressed(200, 200, 3)
        TestFramework.utils.assertEqual(0, MapSystem.mapOffset.x, "Map offset X should reset on right click")
        TestFramework.utils.assertEqual(0, MapSystem.mapOffset.y, "Map offset Y should reset on right click")
    end,
    
    ["test zoom controls"] = function()
        MapSystem.init()
        MapSystem.isVisible = true
        MapSystem.zoomLevel = 2
        
        -- Zoom in
        MapSystem.wheelmoved(0, 1)
        TestFramework.utils.assertEqual(1, MapSystem.zoomLevel, "Should zoom in")
        
        -- Try to zoom in past limit
        MapSystem.wheelmoved(0, 1)
        TestFramework.utils.assertEqual(1, MapSystem.zoomLevel, "Should not zoom in past minimum")
        
        -- Zoom out
        MapSystem.wheelmoved(0, -1)
        MapSystem.wheelmoved(0, -1)
        TestFramework.utils.assertEqual(3, MapSystem.zoomLevel, "Should zoom out to max")
        
        -- Try to zoom out past limit
        MapSystem.wheelmoved(0, -1)
        TestFramework.utils.assertEqual(3, MapSystem.zoomLevel, "Should not zoom out past maximum")
    end,
    
    ["test zoom when map not visible"] = function()
        MapSystem.init()
        MapSystem.isVisible = false
        MapSystem.zoomLevel = 2
        
        MapSystem.wheelmoved(0, 1)
        TestFramework.utils.assertEqual(2, MapSystem.zoomLevel, "Should not change zoom when map not visible")
    end,
    
    ["test is blocking input"] = function()
        MapSystem.init()
        
        -- Not visible
        TestFramework.utils.assertFalse(MapSystem.isBlockingInput(), "Should not block input when not visible")
        
        -- Visible but fading in
        MapSystem.isVisible = true
        MapSystem.mapAlpha = 0.3
        TestFramework.utils.assertFalse(MapSystem.isBlockingInput(), "Should not block input when alpha < 0.5")
        
        -- Fully visible
        MapSystem.mapAlpha = 0.8
        TestFramework.utils.assertTrue(MapSystem.isBlockingInput(), "Should block input when visible and alpha > 0.5")
    end,
    
    ["test draw with artifacts"] = function()
        resetMocks()
        
        -- Mock artifact system
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.artifact_system" then
                return mockArtifactSystem
            else
                return oldRequire(path)
            end
        end
        
        MapSystem.init()
        MapSystem.mapAlpha = 1.0
        
        local player = createTestPlayer(0, 0)
        local camera = {}
        
        MapSystem.draw(player, {}, camera)
        
        TestFramework.utils.assertTrue(mockArtifactSystem.drawOnMapCalled, "Should call artifact draw on map")
        TestFramework.utils.assertEqual(camera, mockArtifactSystem.lastDrawParams.camera, "Should pass camera")
        TestFramework.utils.assertEqual(1.0, mockArtifactSystem.lastDrawParams.alpha, "Should pass map alpha")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test draw with warp zones"] = function()
        resetMocks()
        
        -- Mock warp zones
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.warp_zones" then
                return {
                    activeZones = {
                        {x = 1000, y = 1000, discovered = true, data = {color = {1, 0, 1}}},
                        {x = 2000, y = 2000, discovered = false}
                    }
                }
            elseif path == "src.systems.artifact_system" then
                return nil -- No artifact system for this test
            else
                return oldRequire(path)
            end
        end
        
        MapSystem.init()
        MapSystem.mapAlpha = 1.0
        
        -- This test verifies that warp zones are considered in the draw function
        -- The actual drawing is mocked, so we just ensure no errors occur
        local success = pcall(function()
            MapSystem.draw(createTestPlayer(0, 0), {}, {})
        end)
        
        TestFramework.utils.assertTrue(success, "Should draw without errors when warp zones present")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test planet type colors"] = function()
        MapSystem.init()
        MapSystem.mapAlpha = 1.0
        
        -- Create planets of different types
        local planets = {
            createTestPlanet("ice_planet", 100, 100, "ice", true),
            createTestPlanet("lava_planet", 200, 200, "lava", true),
            createTestPlanet("tech_planet", 300, 300, "tech", true),
            createTestPlanet("void_planet", 400, 400, "void", true),
            createTestPlanet("quantum_planet", 500, 500, "quantum", true),
            createTestPlanet("standard_planet", 600, 600, nil, true)
        }
        
        -- Update to track discovered planets
        MapSystem.update(0.1, createTestPlayer(), planets)
        
        -- Verify all types are tracked
        TestFramework.utils.assertEqual("ice", MapSystem.discoveredPlanets["ice_planet"].type)
        TestFramework.utils.assertEqual("lava", MapSystem.discoveredPlanets["lava_planet"].type)
        TestFramework.utils.assertEqual("tech", MapSystem.discoveredPlanets["tech_planet"].type)
        TestFramework.utils.assertEqual("void", MapSystem.discoveredPlanets["void_planet"].type)
        TestFramework.utils.assertEqual("quantum", MapSystem.discoveredPlanets["quantum_planet"].type)
        TestFramework.utils.assertNil(MapSystem.discoveredPlanets["standard_planet"].type)
    end,
    
    ["test hover detection"] = function()
        MapSystem.init()
        MapSystem.mapAlpha = 1.0
        
        -- Set mouse position
        love.mouse.position.x = 400
        love.mouse.position.y = 300
        
        -- This test verifies hover detection logic is considered
        -- The actual rendering is mocked
        local success = pcall(function()
            MapSystem.draw(createTestPlayer(0, 0), {}, {})
        end)
        
        TestFramework.utils.assertTrue(success, "Should handle hover detection without errors")
    end,
    
    ["test discovered count"] = function()
        MapSystem.init()
        
        TestFramework.utils.assertEqual(0, MapSystem.getDiscoveredCount(), "Should start with 0 discovered")
        
        -- Add discovered planets manually
        MapSystem.discoveredPlanets["planet1"] = {x = 100, y = 100}
        MapSystem.discoveredPlanets["planet2"] = {x = 200, y = 200}
        MapSystem.discoveredPlanets["planet3"] = {x = 300, y = 300}
        
        TestFramework.utils.assertEqual(3, MapSystem.getDiscoveredCount(), "Should count all discovered planets")
    end,
    
    ["test zoom level ranges"] = function()
        TestFramework.utils.assertEqual(2000, MapSystem.zoomLevels[1], "Local zoom should be 2000 units")
        TestFramework.utils.assertEqual(5000, MapSystem.zoomLevels[2], "Sector zoom should be 5000 units")
        TestFramework.utils.assertEqual(10000, MapSystem.zoomLevels[3], "Galaxy zoom should be 10000 units")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runSuite("Map System Tests", tests)
end

return {run = run}