-- Comprehensive tests for Map System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks before requiring MapSystem
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Store original love state before modifications
local originalLoveGraphics = love.graphics
local originalLoveMouse = love.mouse

-- Preserve existing graphics functions and only add what's missing
love.graphics = love.graphics or {}
love.graphics.getWidth = love.graphics.getWidth or function() return 800 end
love.graphics.getHeight = love.graphics.getHeight or function() return 600 end
love.graphics.rectangle = love.graphics.rectangle or function() end
love.graphics.circle = love.graphics.circle or function() end
love.graphics.line = love.graphics.line or function() end
love.graphics.printf = love.graphics.printf or function() end
love.graphics.print = love.graphics.print or function() end
love.graphics.setFont = love.graphics.setFont or function() end
love.graphics.getFont = love.graphics.getFont or function() return {} end
love.graphics.newFont = love.graphics.newFont or function() return {} end
love.graphics.setLineWidth = love.graphics.setLineWidth or function() end
love.graphics.push = love.graphics.push or function() end
love.graphics.pop = love.graphics.pop or function() end
love.graphics.setScissor = love.graphics.setScissor or function() end

-- Set up mouse if needed
love.mouse = love.mouse or {}
love.mouse.position = love.mouse.position or {x = 0, y = 0}
love.mouse.getPosition = love.mouse.getPosition or function()
    return love.mouse.position.x, love.mouse.position.y
end

-- Function to restore original state
local function restoreOriginalLove()
    if originalLoveGraphics then
        love.graphics = originalLoveGraphics
    end
    if originalLoveMouse then
        love.mouse = originalLoveMouse
    end
end

-- Mock Utils functions
Utils.setColor = function() end
Utils.drawCircle = function() end

-- Function to get MapSystem with proper initialization
local function getMapSystem()
    -- Clear any cached version
    package.loaded["src.systems.map_system"] = nil
    package.loaded["src/systems/map_system"] = nil
    
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.map_system"] = nil
    end
    
    -- Setup mocks before loading
    Mocks.setup()
    
    -- Load fresh instance using regular require to bypass cache
    local MapSystem = require("src.systems.map_system")
    
    -- Ensure it's initialized
    if MapSystem and MapSystem.init then
        MapSystem.init()
    end
    
    return MapSystem
end

-- Get initial MapSystem instance
local MapSystem = getMapSystem()

-- Mock dependencies
local mockWarpZones = {
    activeZones = {}
}

-- Mock Utils.require to return mock dependencies
local originalUtilsRequire = Utils.require
Utils.require = function(module)
    if module == "src.systems.warp_zones" then
        return mockWarpZones
    end
    -- Fall back to original for other modules
    if originalUtilsRequire then
        return originalUtilsRequire(module)
    end
    return nil
end

_G.mockArtifactSystem = {
    drawOnMapCalled = false,
    drawOnMap = function(camera, centerX, centerY, scale, alpha)
        _G.mockArtifactSystem.drawOnMapCalled = true
        _G.mockArtifactSystem.lastDrawParams = {
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
    _G.mockArtifactSystem.drawOnMapCalled = false
    _G.mockArtifactSystem.lastDrawParams = nil
end

-- Test suite
local tests = {
    ["test initialization"] = function()
        local MapSystem = getMapSystem()
        
        TestFramework.assert.assertEqual(0, MapSystem.getDiscoveredCount(), "No planets should be discovered initially")
        TestFramework.assert.assertEqual(0, #MapSystem.visitedSectors, "No sectors should be visited initially")
        TestFramework.assert.assertFalse(MapSystem.isVisible, "Map should not be visible initially")
        TestFramework.assert.assertEqual(0, MapSystem.mapAlpha, "Map alpha should be 0 initially")
    end,
    
    ["test toggle map visibility"] = function()
        local MapSystem = getMapSystem()
        
        -- Toggle on
        MapSystem.toggle()
        TestFramework.assert.assertTrue(MapSystem.isVisible, "Map should be visible after toggle")
        TestFramework.assert.assertEqual(0, MapSystem.mapOffset.x, "Map offset X should be reset")
        TestFramework.assert.assertEqual(0, MapSystem.mapOffset.y, "Map offset Y should be reset")
        
        -- Toggle off
        MapSystem.toggle()
        TestFramework.assert.assertFalse(MapSystem.isVisible, "Map should not be visible after second toggle")
    end,
    
    ["test map fade in and out"] = function()
        MapSystem.init()
        
        -- Test fade in
        MapSystem.isVisible = true
        MapSystem.update(0.1, createTestPlayer(), {})
        TestFramework.assert.assertTrue(MapSystem.mapAlpha > 0, "Map alpha should increase when visible")
        TestFramework.assert.assertTrue(MapSystem.mapAlpha <= 1, "Map alpha should not exceed 1")
        
        -- Complete fade in
        MapSystem.update(1.0, createTestPlayer(), {})
        TestFramework.assert.assertEqual(1, MapSystem.mapAlpha, "Map alpha should reach 1")
        
        -- Test fade out
        MapSystem.isVisible = false
        MapSystem.update(0.1, createTestPlayer(), {})
        TestFramework.assert.assertTrue(MapSystem.mapAlpha < 1, "Map alpha should decrease when not visible")
        
        -- Complete fade out
        MapSystem.update(1.0, createTestPlayer(), {})
        TestFramework.assert.assertEqual(0, MapSystem.mapAlpha, "Map alpha should reach 0")
    end,
    
    ["test planet discovery tracking"] = function()
        MapSystem.init()
        
        local planets = {
            createTestPlanet("planet1", 100, 100, "ice", true),
            createTestPlanet("planet2", 200, 200, "lava", false),
            createTestPlanet("planet3", 300, 300, "tech", true)
        }
        
        MapSystem.update(0.1, createTestPlayer(), planets)
        
        TestFramework.assert.assertEqual(2, MapSystem.getDiscoveredCount(), "Should track 2 discovered planets")
        TestFramework.assert.assertNotNil(MapSystem.discoveredPlanets["planet1"], "Planet 1 should be tracked")
        TestFramework.assert.assertNil(MapSystem.discoveredPlanets["planet2"], "Planet 2 should not be tracked")
        TestFramework.assert.assertNotNil(MapSystem.discoveredPlanets["planet3"], "Planet 3 should be tracked")
        
        -- Check stored planet data
        local planet1Data = MapSystem.discoveredPlanets["planet1"]
        TestFramework.assert.assertEqual(100, planet1Data.x, "Planet position X should be stored")
        TestFramework.assert.assertEqual(100, planet1Data.y, "Planet position Y should be stored")
        TestFramework.assert.assertEqual("ice", planet1Data.type, "Planet type should be stored")
        TestFramework.assert.assertEqual(50, planet1Data.radius, "Planet radius should be stored")
    end,
    
    ["test sector tracking"] = function()
        MapSystem.init()
        
        -- Player at origin
        MapSystem.update(0.1, createTestPlayer(0, 0), {})
        TestFramework.assert.assertNotNil(MapSystem.visitedSectors["0,0"], "Origin sector should be visited")
        
        -- Player moves to new sector
        MapSystem.update(0.1, createTestPlayer(1500, 1500), {})
        TestFramework.assert.assertNotNil(MapSystem.visitedSectors["1,1"], "New sector should be visited")
        
        -- Player in negative sector
        MapSystem.update(0.1, createTestPlayer(-1500, -1500), {})
        TestFramework.assert.assertNotNil(MapSystem.visitedSectors["-2,-2"], "Negative sector should be tracked")
        
        -- Count sectors
        local sectorCount = 0
        for _ in pairs(MapSystem.visitedSectors) do
            sectorCount = sectorCount + 1
        end
        TestFramework.assert.assertEqual(3, sectorCount, "Should have 3 visited sectors")
    end,
    
    ["test mouse drag"] = function()
        MapSystem.init()
        MapSystem.isVisible = true
        
        -- Start drag
        MapSystem.mousepressed(100, 100, 1)
        TestFramework.assert.assertTrue(MapSystem.isDragging, "Should start dragging on left click")
        TestFramework.assert.assertEqual(100, MapSystem.dragStart.x, "Drag start X should be set")
        TestFramework.assert.assertEqual(100, MapSystem.dragStart.y, "Drag start Y should be set")
        
        -- Move mouse
        MapSystem.mousemoved(150, 120)
        TestFramework.assert.assertEqual(50, MapSystem.mapOffset.x, "Map offset X should update")
        TestFramework.assert.assertEqual(20, MapSystem.mapOffset.y, "Map offset Y should update")
        
        -- Release drag
        MapSystem.mousereleased(150, 120, 1)
        TestFramework.assert.assertFalse(MapSystem.isDragging, "Should stop dragging on release")
    end,
    
    ["test right click center"] = function()
        MapSystem.init()
        MapSystem.isVisible = true
        MapSystem.mapOffset = {x = 100, y = 100}
        
        MapSystem.mousepressed(200, 200, 3)
        TestFramework.assert.assertEqual(0, MapSystem.mapOffset.x, "Map offset X should reset on right click")
        TestFramework.assert.assertEqual(0, MapSystem.mapOffset.y, "Map offset Y should reset on right click")
    end,
    
    ["test zoom controls"] = function()
        MapSystem.init()
        MapSystem.isVisible = true
        MapSystem.zoomLevel = 2
        
        -- Zoom in
        MapSystem.wheelmoved(0, 1)
        TestFramework.assert.assertEqual(1, MapSystem.zoomLevel, "Should zoom in")
        
        -- Try to zoom in past limit
        MapSystem.wheelmoved(0, 1)
        TestFramework.assert.assertEqual(1, MapSystem.zoomLevel, "Should not zoom in past minimum")
        
        -- Zoom out
        MapSystem.wheelmoved(0, -1)
        MapSystem.wheelmoved(0, -1)
        TestFramework.assert.assertEqual(3, MapSystem.zoomLevel, "Should zoom out to max")
        
        -- Try to zoom out past limit
        MapSystem.wheelmoved(0, -1)
        TestFramework.assert.assertEqual(3, MapSystem.zoomLevel, "Should not zoom out past maximum")
    end,
    
    ["test zoom when map not visible"] = function()
        MapSystem.init()
        MapSystem.isVisible = false
        MapSystem.zoomLevel = 2
        
        MapSystem.wheelmoved(0, 1)
        TestFramework.assert.assertEqual(2, MapSystem.zoomLevel, "Should not change zoom when map not visible")
    end,
    
    ["test is blocking input"] = function()
        MapSystem.init()
        
        -- Not visible
        TestFramework.assert.assertFalse(MapSystem.isBlockingInput(), "Should not block input when not visible")
        
        -- Visible but fading in
        MapSystem.isVisible = true
        MapSystem.mapAlpha = 0.3
        TestFramework.assert.assertFalse(MapSystem.isBlockingInput(), "Should not block input when alpha < 0.5")
        
        -- Fully visible
        MapSystem.mapAlpha = 0.8
        TestFramework.assert.assertTrue(MapSystem.isBlockingInput(), "Should block input when visible and alpha > 0.5")
    end,
    
    ["test draw with artifacts"] = function()
        resetMocks()
        
        -- Mock artifact system
        local originalUtilsRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.artifact_system" then
                return _G.mockArtifactSystem
            else
                return originalUtilsRequire(path)
            end
        end
        
        local MapSystem = getMapSystem()
        MapSystem.mapAlpha = 1.0
        
        local player = createTestPlayer(0, 0)
        local camera = {}
        
        MapSystem.draw(player, {}, camera)
        
        TestFramework.assert.assertTrue(_G.mockArtifactSystem.drawOnMapCalled, "Should call artifact draw on map")
        TestFramework.assert.assertEqual(camera, _G.mockArtifactSystem.lastDrawParams.camera, "Should pass camera")
        TestFramework.assert.assertEqual(1.0, _G.mockArtifactSystem.lastDrawParams.alpha, "Should pass map alpha")
        
        -- Restore original Utils.require
        Utils.require = originalUtilsRequire
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test draw with warp zones"] = function()
        resetMocks()
        
        -- Mock warp zones
        local originalUtilsRequire = Utils.require
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
                return originalUtilsRequire(path)
            end
        end
        
        local MapSystem = getMapSystem()
        MapSystem.mapAlpha = 1.0
        
        -- This test verifies that warp zones are considered in the draw function
        -- The actual drawing is mocked, so we just ensure no errors occur
        local success = pcall(function()
            MapSystem.draw(createTestPlayer(0, 0), {}, {})
        end)
        
        TestFramework.assert.assertTrue(success, "Should draw without errors when warp zones present")
        
        -- Restore
        Utils.require = originalUtilsRequire
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
        TestFramework.assert.assertEqual("ice", MapSystem.discoveredPlanets["ice_planet"].type)
        TestFramework.assert.assertEqual("lava", MapSystem.discoveredPlanets["lava_planet"].type)
        TestFramework.assert.assertEqual("tech", MapSystem.discoveredPlanets["tech_planet"].type)
        TestFramework.assert.assertEqual("void", MapSystem.discoveredPlanets["void_planet"].type)
        TestFramework.assert.assertEqual("quantum", MapSystem.discoveredPlanets["quantum_planet"].type)
        TestFramework.assert.assertNil(MapSystem.discoveredPlanets["standard_planet"].type)
    end,
    
    ["test hover detection"] = function()
        -- Mock WarpZones and ArtifactSystem before loading MapSystem
        local originalRequire = Utils.require
        Utils.require = function(module)
            if module == "src.systems.warp_zones" then
                return {
                    activeZones = {}
                }
            elseif module == "src.systems.artifact_system" then
                return {
                    spawnedArtifacts = {
                        {
                            x = 100,
                            y = 100,
                            collected = false,
                            definition = {
                                color = {1, 0, 1},
                                name = "Test Artifact"
                            }
                        }
                    },
                    drawOnMap = function(camera, mapCenterX, mapCenterY, scale, alpha)
                        -- Mock implementation that tests the hover logic
                        return true
                    end
                }
            end
            return originalRequire and originalRequire(module) or require(module)
        end
        
        local MapSystem = getMapSystem()
        MapSystem.mapAlpha = 1.0
        
        -- Set mouse position
        love.mouse.position.x = 400
        love.mouse.position.y = 300
        
        -- This test verifies hover detection logic is considered
        -- The actual rendering is mocked
        local mockCamera = { x = 0, y = 0 }
        local success, errorMsg = pcall(function()
            MapSystem.draw(createTestPlayer(0, 0), {}, mockCamera)
        end)
        
        if not success then
            print("Hover detection error:", errorMsg)
        end
        
        TestFramework.assert.assertTrue(success, "Should handle hover detection without errors: " .. (errorMsg or "unknown error"))
        
        -- Restore Utils.require
        Utils.require = originalRequire
    end,
    
    ["test discovered count"] = function()
        MapSystem.init()
        
        TestFramework.assert.assertEqual(0, MapSystem.getDiscoveredCount(), "Should start with 0 discovered")
        
        -- Add discovered planets manually
        MapSystem.discoveredPlanets["planet1"] = {x = 100, y = 100}
        MapSystem.discoveredPlanets["planet2"] = {x = 200, y = 200}
        MapSystem.discoveredPlanets["planet3"] = {x = 300, y = 300}
        
        TestFramework.assert.assertEqual(3, MapSystem.getDiscoveredCount(), "Should count all discovered planets")
    end,
    
    ["test zoom level ranges"] = function()
        TestFramework.assert.assertEqual(2000, MapSystem.zoomLevels[1], "Local zoom should be 2000 units")
        TestFramework.assert.assertEqual(5000, MapSystem.zoomLevels[2], "Sector zoom should be 5000 units")
        TestFramework.assert.assertEqual(10000, MapSystem.zoomLevels[3], "Galaxy zoom should be 10000 units")
    end
}

-- Run the test suite
local function run()
    -- Setup mocks and framework before running tests
    Mocks.setup()
    TestFramework.init()
    local result = TestFramework.runTests(tests, "Map System Tests")
    -- Restore original love state to prevent pollution
    restoreOriginalLove()
    return result
end

return {run = run}