-- Tests for Collision System
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")
local CollisionSystem = Utils.Utils.require("src.systems.collision_system")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test planet collision detection
    ["planet collision detection"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, {}, {})
        
        TestFramework.utils.assertNotNil(result, "Should detect collision with planet")
        TestFramework.utils.assertEqual(planet, result, "Should return the collided planet")
    end,
    
    ["planet collision detection with spatial grid"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local spatialGrid = {
            getObjectsInRadius = function(x, y, radius)
                return {planet}
            end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, spatialGrid, {}, {})
        
        TestFramework.utils.assertNotNil(result, "Should detect collision using spatial grid")
        TestFramework.utils.assertEqual(planet, result, "Should return the collided planet")
    end,
    
    ["no planet collision when player on planet"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = true}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, {}, {})
        
        TestFramework.utils.assertNil(result, "Should not detect collision when player is on planet")
    end,
    
    ["no planet collision when player too far"] = function()
        local player = {x = 1000, y = 1000, radius = 10, onPlanet = false}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, {}, {})
        
        TestFramework.utils.assertNil(result, "Should not detect collision when player is too far")
    end,
    
    ["no planet collision with nil player"] = function()
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        
        local result = CollisionSystem.checkPlanetCollisions(nil, planets, nil, {}, {})
        
        TestFramework.utils.assertNil(result, "Should not detect collision with nil player")
    end,
    
    -- Test planet landing
    ["planet landing handling"] = function()
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
        
        TestFramework.utils.assertTrue(player.onPlanet, "Player should be marked as on planet")
        TestFramework.utils.assertEqual(0, player.vx, "Player velocity should be reset")
        TestFramework.utils.assertEqual(0, player.vy, "Player velocity should be reset")
        TestFramework.utils.assertNotNil(player.angle, "Player should have landing angle")
    end,
    
    ["planet landing position adjustment"] = function()
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
        TestFramework.utils.assertTrue(math.abs(distance - expectedDistance) < 1, "Player should be on planet surface")
    end,
    
    ["quantum planet teleportation"] = function()
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
        
        -- Mock random to return target planet
        local originalRandom = math.random
        math.random = function() return 2 end
        
        CollisionSystem.handlePlanetLanding(player, planet, gameState, soundManager)
        
        -- Player should be teleported to target planet
        TestFramework.utils.assertTrue(player.x > 1000, "Player should be teleported to distant planet")
        TestFramework.utils.assertTrue(player.y > 1000, "Player should be teleported to distant planet")
        
        -- Restore random function
        math.random = originalRandom
    end,
    
    -- Test ring collision detection
    ["ring collision detection"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local rings = {ring}
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, {}, {})
        
        TestFramework.utils.assertNotNil(result, "Should detect collision with ring")
        TestFramework.utils.assertEqual(1, #result, "Should return one collected ring")
        TestFramework.utils.assertEqual(ring, result[1], "Should return the collided ring")
    end,
    
    ["ring collision detection with spatial grid"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local rings = {ring}
        
        local spatialGrid = {
            getObjectsInRadius = function(x, y, radius)
                return {ring}
            end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, spatialGrid, {}, {})
        
        TestFramework.utils.assertNotNil(result, "Should detect collision using spatial grid")
        TestFramework.utils.assertEqual(1, #result, "Should return one collected ring")
    end,
    
    ["no ring collision when player on planet"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = true}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false}
        local rings = {ring}
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, {}, {})
        
        TestFramework.utils.assertNil(result, "Should not detect collision when player is on planet")
    end,
    
    ["no ring collision with collected ring"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local ring = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = true}
        local rings = {ring}
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, {}, {})
        
        TestFramework.utils.assertNil(result, "Should not detect collision with collected ring")
    end,
    
    ["multiple ring collisions"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        local ring1 = {x = 100, y = 100, radius = 30, innerRadius = 15, collected = false, color = {1, 0, 0, 1}}
        local ring2 = {x = 110, y = 110, radius = 30, innerRadius = 15, collected = false, color = {0, 1, 0, 1}}
        local rings = {ring1, ring2}
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, {}, {})
        
        TestFramework.utils.assertNotNil(result, "Should detect multiple collisions")
        TestFramework.utils.assertEqual(2, #result, "Should return two collected rings")
    end,
    
    -- Test ring burst effect
    ["ring burst effect creation"] = function()
        local ring = {x = 100, y = 100, color = {1, 0, 0, 1}}
        local player = {x = 100, y = 100, vx = 50, vy = 30}
        
        -- Mock ParticleSystem
        local particleCount = 0
        local originalCreate = Utils.Utils.require("src.systems.particle_system").create
        Utils.require("src.systems.particle_system").create = function()
            particleCount = particleCount + 1
        end
        
        CollisionSystem.createRingBurst(ring, player)
        
        TestFramework.utils.assertEqual(20, particleCount, "Should create 20 particles for burst effect")
        
        -- Restore original function
        Utils.require("src.systems.particle_system").create = originalCreate
    end,
    
    -- Test player in ring detection
    ["player in ring detection"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local ring = {x = 100, y = 100, outerRadius = 50, innerRadius = 20}
        
        local result = CollisionSystem.isPlayerInRing(player, ring)
        
        TestFramework.utils.assertTrue(result, "Should detect player inside ring")
    end,
    
    ["player not in ring detection"] = function()
        local player = {x = 1000, y = 1000, radius = 10}
        local ring = {x = 100, y = 100, outerRadius = 50, innerRadius = 20}
        
        local result = CollisionSystem.isPlayerInRing(player, ring)
        
        TestFramework.utils.assertFalse(result, "Should not detect player outside ring")
    end,
    
    ["player in ring center hole"] = function()
        local player = {x = 100, y = 100, radius = 5}
        local ring = {x = 100, y = 100, outerRadius = 50, innerRadius = 20}
        
        local result = CollisionSystem.isPlayerInRing(player, ring)
        
        TestFramework.utils.assertFalse(result, "Should not detect player in center hole")
    end,
    
    -- Test spatial grid operations
    ["spatial grid update"] = function()
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
        
        TestFramework.utils.assertEqual(1, clearCalls, "Should clear spatial grid once")
        TestFramework.utils.assertEqual(3, addObjectCalls, "Should add 2 planets + 1 uncollected ring")
    end,
    
    ["spatial grid update with nil grid"] = function()
        local planets = {{x = 100, y = 100}}
        local rings = {{x = 150, y = 150, collected = false}}
        
        -- Should not crash
        local success  = Utils.ErrorHandler.safeCall(function()
            CollisionSystem.updateSpatialGrid(nil, planets, rings)
        end)
        
        TestFramework.utils.assertTrue(success, "Should handle nil spatial grid gracefully")
    end,
    
    -- Test planet discovery tracking
    ["planet discovery tracking"] = function()
        local planet = {x = 100, y = 100, radius = 50, discovered = false, lore = "Test lore"}
        local gameState = {
            addScore = function() end
        }
        
        -- Mock systems
        local ProgressionSystem = Utils.Utils.require("src.systems.progression_system")
        local AchievementSystem = Utils.Utils.require("src.systems.achievement_system")
        local MapSystem = Utils.Utils.require("src.systems.map_system")
        local PlanetLore = Utils.Utils.require("src.systems.planet_lore")
        
        local originalOnPlanetDiscovered = ProgressionSystem.onPlanetDiscovered
        local originalCheckPlanetAchievements = AchievementSystem.checkPlanetAchievements
        local originalDiscoverPlanet = MapSystem.discoverPlanet
        local originalShowLore = PlanetLore.showLore
        
        ProgressionSystem.onPlanetDiscovered = function() end
        AchievementSystem.checkPlanetAchievements = function() end
        MapSystem.discoverPlanet = function() end
        PlanetLore.showLore = function() end
        
        CollisionSystem.trackPlanetDiscovery(planet, gameState)
        
        TestFramework.utils.assertTrue(planet.discovered, "Planet should be marked as discovered")
        
        -- Restore original functions
        ProgressionSystem.onPlanetDiscovered = originalOnPlanetDiscovered
        AchievementSystem.checkPlanetAchievements = originalCheckPlanetAchievements
        MapSystem.discoverPlanet = originalDiscoverPlanet
        PlanetLore.showLore = originalShowLore
    end,
    
    ["planet discovery tracking for already discovered planet"] = function()
        local planet = {x = 100, y = 100, radius = 50, discovered = true}
        local gameState = {
            addScore = function() end
        }
        
        local scoreCalls = 0
        gameState.addScore = function() scoreCalls = scoreCalls + 1 end
        
        CollisionSystem.trackPlanetDiscovery(planet, gameState)
        
        TestFramework.utils.assertEqual(0, scoreCalls, "Should not add score for already discovered planet")
    end,
    
    -- Test edge cases
    ["collision with empty arrays"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        
        local planetResult = CollisionSystem.checkPlanetCollisions(player, {}, nil, {}, {})
        local ringResult = CollisionSystem.checkRingCollisions(player, {}, nil, {}, {})
        
        TestFramework.utils.assertNil(planetResult, "Should handle empty planets array")
        TestFramework.utils.assertNotNil(ringResult, "Should return empty array for empty rings")
        TestFramework.utils.assertEqual(0, #ringResult, "Should return empty array")
    end,
    
    ["collision with nil arrays"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
        
        local planetResult = CollisionSystem.checkPlanetCollisions(player, nil, nil, {}, {})
        local ringResult = CollisionSystem.checkRingCollisions(player, nil, nil, {}, {})
        
        TestFramework.utils.assertNil(planetResult, "Should handle nil planets array")
        TestFramework.utils.assertNotNil(ringResult, "Should return empty array for nil rings")
        TestFramework.utils.assertEqual(0, #ringResult, "Should return empty array")
    end,
    
    ["ring collision with game state integration"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = false}
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
        
        TestFramework.utils.assertTrue(scoreAdded, "Should add score for ring collection")
        TestFramework.utils.assertTrue(comboAdded, "Should add combo for ring collection")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Collision System Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("collision_system", 10) -- All major functions tested
    
    return success
end

return {run = run} 