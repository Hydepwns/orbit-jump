-- Tests for Collision System
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Function to get CollisionSystem with proper initialization
local function getCollisionSystem()
    -- Clear any cached version
    package.loaded["src.systems.collision_system"] = nil
    package.loaded["src/systems/collision_system"] = nil
    
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.collision_system"] = nil
    end
    
    -- Setup mocks before loading
    Mocks.setup()
    
    -- Mock ring system to avoid ring_constellations dependency
    local originalRequire = Utils.require
    Utils.require = function(path)
        if path == "src.systems.ring_system" then
            return {
                collectRing = function(ring, gameState)
                    ring.collected = true
                    if gameState and gameState.addScore then
                        gameState.addScore(10)
                    end
                    if gameState and gameState.addCombo then
                        gameState.addCombo()
                    end
                    return 10
                end
            }
        else
            return originalRequire(path)
        end
    end
    
    -- Load fresh instance using regular require to bypass cache
    local CollisionSystem = require("src.systems.collision_system")
    
    -- Restore Utils.require
    Utils.require = originalRequire
    
    -- Ensure it's initialized
    if CollisionSystem and CollisionSystem.init then
        CollisionSystem.init()
    end
    
    return CollisionSystem
end

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test planet collision detection
    ["planet collision detection"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        TestFramework.assert.assertNotNil(result, "Should detect collision with planet")
        TestFramework.assert.assertEqual(planet, result, "Should return the collided planet")
    end,
    
    ["planet collision detection with spatial grid"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local spatialGrid = {
            getObjectsInRadius = function(x, y, radius)
                return {planet}
            end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, spatialGrid, gameState, soundManager)
        
        TestFramework.assert.assertNotNil(result, "Should detect collision using spatial grid")
        TestFramework.assert.assertEqual(planet, result, "Should return the collided planet")
    end,
    
    ["no planet collision when player on planet"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = true}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, {}, {})
        
        TestFramework.assert.assertNil(result, "Should not detect collision when player is on planet")
    end,
    
    ["no planet collision when player too far"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 1000, y = 1000, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, {}, {})
        
        TestFramework.assert.assertNil(result, "Should not detect collision when player is too far")
    end,
    
    ["no planet collision with nil player"] = function()
        local CollisionSystem = getCollisionSystem()
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(nil, planets, nil, {}, {})
        
        TestFramework.assert.assertNil(result, "Should not detect collision with nil player")
    end,
    
    -- Test planet landing
    ["planet landing handling"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50, type = "standard"}
        local gameState = {
            getPlanets = function() return {planet} end,
            addScore = function() end
        }
        local soundManager = {
            playLand = function() end
        }
        
        CollisionSystem.handlePlanetLanding(player, planet, gameState, soundManager)
        
        TestFramework.assert.assertTrue(player.onPlanet, "Player should be marked as on planet")
        TestFramework.assert.assertEqual(0, player.vx, "Player velocity should be reset")
        TestFramework.assert.assertEqual(0, player.vy, "Player velocity should be reset")
        TestFramework.assert.assertNotNil(player.angle, "Player should have landing angle")
    end,
    
    ["planet landing position adjustment"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50, type = "standard"}
        local gameState = {
            getPlanets = function() return {planet} end,
            addScore = function() end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local originalX = player.x
        local originalY = player.y
        
        CollisionSystem.handlePlanetLanding(player, planet, gameState, soundManager)
        
        -- Player should be positioned on planet surface
        local distance = math.sqrt((player.x - planet.x)^2 + (player.y - planet.y)^2)
        local expectedDistance = planet.radius + player.radius + 5
        TestFramework.assert.assertTrue(math.abs(distance - expectedDistance) < 1, "Player should be on planet surface")
    end,
    
    ["quantum planet teleportation"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50, type = "quantum"}
        local targetPlanet = {x = 2000, y = 2000, radius = 50, id = 2}
        local gameState = {
            getPlanets = function() return {planet, targetPlanet} end,
            addScore = function() end
        }
        local soundManager = {
            playLand = function() end
        }
        
        -- Mock the required modules
        local originalRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.cosmic_events" then
                return { triggerQuantumTeleport = function() end }
            elseif path == "src.systems.warp_drive" then
                return { createWarpEffect = function() end }
            else
                return originalRequire(path)
            end
        end
        
        -- Mock random to return target planet
        local originalRandom = math.random
        math.random = function() return 2 end
        
        CollisionSystem.handlePlanetLanding(player, planet, gameState, soundManager)
        
        -- Player should be teleported to target planet
        TestFramework.assert.assertTrue(player.x > 1000, "Player should be teleported to distant planet")
        TestFramework.assert.assertTrue(player.y > 1000, "Player should be teleported to distant planet")
        
        -- Restore functions
        math.random = originalRandom
        Utils.require = originalRequire
    end,
    
    -- Test ring collision detection
    ["ring collision detection"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 120, y = 100, radius = 10, onPlanet = false, vx = 0, vy = 0}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playCollectRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        TestFramework.assert.assertNotNil(result, "Should detect collision with ring")
        TestFramework.assert.assertEqual(1, #result, "Should return one collected ring")
        TestFramework.assert.assertEqual(ring, result[1], "Should return the collided ring")
    end,
    
    ["ring collision detection with spatial grid"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 120, y = 100, radius = 10, onPlanet = false, vx = 0, vy = 0}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playCollectRing = function() end
        }
        
        local spatialGrid = {
            getObjectsInRadius = function(x, y, radius)
                return {ring}
            end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, spatialGrid, gameState, soundManager)
        
        TestFramework.assert.assertNotNil(result, "Should detect collision using spatial grid")
        TestFramework.assert.assertEqual(1, #result, "Should return one collected ring")
    end,
    
    ["no ring collision when player on planet"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = true, vx = 0, vy = 0}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playCollectRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        TestFramework.assert.assertEqual(0, #result, "Should not detect collision when player is on planet")
    end,
    
    ["no ring collision with collected ring"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false, vx = 0, vy = 0}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = true}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playCollectRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        TestFramework.assert.assertEqual(0, #result, "Should not detect collision with collected ring")
    end,
    
    ["multiple ring collisions"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 120, y = 100, radius = 10, onPlanet = false, vx = 0, vy = 0}
        local ring1 = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local ring2 = {x = 120, y = 120, radius = 30, innerRadius = 15, collected = false, color = {0, 1, 0, 1}}
        local rings = {ring1, ring2}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playCollectRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        TestFramework.assert.assertNotNil(result, "Should detect multiple collisions")
        TestFramework.assert.assertEqual(2, #result, "Should return two collected rings")
    end,
    
    -- Test ring burst effect
    ["ring burst effect creation"] = function()
        local CollisionSystem = getCollisionSystem()
        local ring = {x = 100, y = 100, color = {1, 0, 0, 1}}
        local player = {x = 100, y = 100, vx = 50, vy = 30}
        
        -- Mock ParticleSystem
        local particleCount = 0
        local originalCreate = Utils.require("src.systems.particle_system").create
        Utils.require("src.systems.particle_system").create = function()
            particleCount = particleCount + 1
        end
        
        CollisionSystem.createRingBurst(ring, player)
        
        TestFramework.assert.assertEqual(20, particleCount, "Should create 20 particles for burst effect")
        
        -- Restore original function
        Utils.require("src.systems.particle_system").create = originalCreate
    end,
    
    -- Test player in ring detection
    ["player in ring detection"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10}
        local ring = {x = 100, y = 100, radius = 50, innerRadius = 20}
        
        -- Move player to be in the ring (not in center hole)
        player.x = 130
        player.y = 100
        
        local result = CollisionSystem.isPlayerInRing(player, ring)
        
        TestFramework.assert.assertTrue(result, "Should detect player inside ring")
    end,
    
    ["player not in ring detection"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 1000, y = 1000, radius = 10}
        local ring = {x = 100, y = 100, radius = 50, innerRadius = 20}
        
        local result = CollisionSystem.isPlayerInRing(player, ring)
        
        TestFramework.assert.assertFalse(result, "Should not detect player outside ring")
    end,
    
    ["player in ring center hole"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 5}
        local ring = {x = 100, y = 100, radius = 50, innerRadius = 20}
        
        local result = CollisionSystem.isPlayerInRing(player, ring)
        
        TestFramework.assert.assertFalse(result, "Should not detect player in center hole")
    end,
    
    -- Test spatial grid operations
    ["spatial grid update"] = function()
        local CollisionSystem = getCollisionSystem()
        local spatialGrid = {
            clear = function() end,
            addObject = function() end
        }
        local planets = {{x = 100, y = 100}, {x = 200, y = 200}}
        local rings = {{x = 150, y = 150, collected = false}, {x = 250, y = 250, collected = true}}
        
        -- Mock the functions to track calls
        local clearCalls = 0
        local addObjectCalls = 0
        spatialGrid.clear = function() clearCalls = clearCalls + 1 end
        spatialGrid.addObject = function() addObjectCalls = addObjectCalls + 1 end
        
        CollisionSystem.updateSpatialGrid(spatialGrid, planets, rings)
        
        TestFramework.assert.assertEqual(1, clearCalls, "Should clear spatial grid once")
        TestFramework.assert.assertEqual(3, addObjectCalls, "Should add 2 planets + 1 uncollected ring")
    end,
    
    ["spatial grid update with nil grid"] = function()
        local CollisionSystem = getCollisionSystem()
        local planets = {{x = 100, y = 100}}
        local rings = {{x = 150, y = 150, collected = false}}
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            CollisionSystem.updateSpatialGrid(nil, planets, rings)
        end)
        
        TestFramework.assert.assertTrue(success, "Should handle nil spatial grid gracefully")
    end,
    
    -- Test planet discovery tracking
    ["planet discovery tracking"] = function()
        local CollisionSystem = getCollisionSystem()
        local planet = {x = 100, y = 100, radius = 50, discovered = false, lore = "Test lore"}
        local gameState = {
            addScore = function() end
        }
        
        -- Mock systems
        local ProgressionSystem = Utils.require("src.systems.progression_system")
        local AchievementSystem = Utils.require("src.systems.achievement_system")
        local MapSystem = Utils.require("src.systems.map_system")
        local PlanetLore = Utils.require("src.systems.planet_lore")
        
        local originalOnPlanetDiscovered = ProgressionSystem.onPlanetDiscovered
        local originalCheckPlanetAchievements = AchievementSystem.checkPlanetAchievements
        local originalDiscoverPlanet = MapSystem.discoverPlanet
        local originalShowLore = PlanetLore.showLore
        
        ProgressionSystem.onPlanetDiscovered = function() end
        AchievementSystem.checkPlanetAchievements = function() end
        MapSystem.discoverPlanet = function() end
        PlanetLore.showLore = function() end
        
        CollisionSystem.trackPlanetDiscovery(planet, gameState)
        
        TestFramework.assert.assertTrue(planet.discovered, "Planet should be marked as discovered")
        
        -- Restore original functions
        ProgressionSystem.onPlanetDiscovered = originalOnPlanetDiscovered
        AchievementSystem.checkPlanetAchievements = originalCheckPlanetAchievements
        MapSystem.discoverPlanet = originalDiscoverPlanet
        PlanetLore.showLore = originalShowLore
    end,
    
    ["planet discovery tracking for already discovered planet"] = function()
        local CollisionSystem = getCollisionSystem()
        local planet = {x = 100, y = 100, radius = 50, discovered = true}
        local gameState = {
            addScore = function() end
        }
        
        local scoreCalls = 0
        gameState.addScore = function() scoreCalls = scoreCalls + 1 end
        
        CollisionSystem.trackPlanetDiscovery(planet, gameState)
        
        TestFramework.assert.assertEqual(0, scoreCalls, "Should not add score for already discovered planet")
    end,
    
    -- Test edge cases
    ["collision with empty arrays"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        
        local planetResult = CollisionSystem.checkPlanetCollisions(player, {}, nil, {}, {})
        local ringResult = CollisionSystem.checkRingCollisions(player, {}, nil, {}, {})
        
        TestFramework.assert.assertNil(planetResult, "Should handle empty planets array")
        TestFramework.assert.assertNotNil(ringResult, "Should return empty array for empty rings")
        TestFramework.assert.assertEqual(0, #ringResult, "Should return empty array")
    end,
    
    ["collision with nil arrays"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        
        local planetResult = CollisionSystem.checkPlanetCollisions(player, nil, nil, {}, {})
        local ringResult = CollisionSystem.checkRingCollisions(player, nil, nil, {}, {})
        
        TestFramework.assert.assertNil(planetResult, "Should handle nil planets array")
        TestFramework.assert.assertNotNil(ringResult, "Should return empty array for nil rings")
        TestFramework.assert.assertEqual(0, #ringResult, "Should return empty array")
    end,
    
    ["ring collision with game state integration"] = function()
        local CollisionSystem = getCollisionSystem()
        local player = {x = 120, y = 100, radius = 10, onPlanet = false, vx = 0, vy = 0}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local rings = {ring}
        
        local scoreAdded = false
        local comboAdded = false
        local gameState = {
            addScore = function() scoreAdded = true end,
            addCombo = function() comboAdded = true end
        }
        local soundManager = {
            playCollectRing = function() end
        }
        
        CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        TestFramework.assert.assertTrue(scoreAdded, "Should add score for ring collection")
        TestFramework.assert.assertTrue(comboAdded, "Should add combo for ring collection")
    end
}

-- Run the test suite
local function run()
    -- Initialize test framework
    Mocks.setup()
    TestFramework.init()
    
    local success = TestFramework.runTests(tests, "Collision System Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("collision_system", 10) -- All major functions tested
    
    return success
end

return {run = run} 