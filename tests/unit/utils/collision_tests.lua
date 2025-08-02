-- Modern Collision Tests
-- Tests for collision detection and response

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")
local CollisionSystem = Utils.require("src.systems.collision_system")

local tests = {
    -- Planet collision
    ["should detect planet collision when touching"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local planet = {x = 105, y = 105, radius = 20}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.notNil(result, "Should detect planet collision")
        ModernTestFramework.assert.equal(planet, result, "Should return the collided planet")
    end,
    
    ["should not detect planet collision when far"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local planet = {x = 200, y = 200, radius = 20}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.isNil(result, "Should not detect collision when far")
    end,
    
    ["should not detect collision when player on planet"] = function()
        local player = {x = 100, y = 100, radius = 10, onPlanet = 1}
        local planet = {x = 105, y = 105, radius = 20}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.isNil(result, "Should not detect collision when player on planet")
    end,
    
    ["should handle multiple planets"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local planet1 = {x = 200, y = 200, radius = 20}
        local planet2 = {x = 105, y = 105, radius = 20}
        local planets = {planet1, planet2}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.notNil(result, "Should detect collision with one of the planets")
        ModernTestFramework.assert.equal(planet2, result, "Should return the closer planet")
    end,
    
    ["should handle different planet types"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local quantumPlanet = {x = 105, y = 105, radius = 20, type = "quantum"}
        local planets = {quantumPlanet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.notNil(result, "Should detect quantum planet collision")
        ModernTestFramework.assert.equal(quantumPlanet, result, "Should return the quantum planet")
    end,
    
    ["should handle planet landing"] = function()
        local player = {x = 100, y = 100, radius = 10, vx = 50, vy = 30}
        local planet = {x = 105, y = 105, radius = 20}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.equal(1, player.onPlanet, "Player should be marked as on planet")
        ModernTestFramework.assert.equal(0, player.vx, "Player velocity should be reset")
        ModernTestFramework.assert.equal(0, player.vy, "Player velocity should be reset")
    end,
    
    ["should adjust player position on landing"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local planet = {x = 100, y = 100, radius = 50}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        -- Player should be positioned on planet surface
        local distance = Utils.distance(player.x, player.y, planet.x, planet.y)
        ModernTestFramework.assert.approx(65, distance, 1, "Player should be on planet surface")
    end,
    
    ["should detect planet collision using spatial grid"] = function()
        local player = {x = 100, y = 100, radius = 10}
        local planet = {x = 105, y = 105, radius = 20}
        local planets = {planet}
        local spatialGrid = {
            getObjectsInRadius = function(x, y, radius)
                return planets
            end
        }
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, spatialGrid, gameState, soundManager)
        
        ModernTestFramework.assert.notNil(result, "Should detect collision using spatial grid")
        ModernTestFramework.assert.equal(planet, result, "Should return the collided planet")
    end,
    
    -- Ring collision
    ["should detect ring collision when player passes through"] = function()
        local player = {x = 520, y = 300, radius = 10, vx = 100, vy = 0}
        local ring = {x = 500, y = 300, radius = 30, innerRadius = 15, collected = false}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        ModernTestFramework.assert.notNil(result, "Should detect ring collision")
        ModernTestFramework.assert.equal(1, #result, "Should return one collected ring")
        ModernTestFramework.assert.equal(ring, result[1], "Should return the collided ring")
    end,
    
    ["should not detect ring collision when too far"] = function()
        local player = {x = 500, y = 300, radius = 10, vx = 100, vy = 0}
        local ring = {x = 700, y = 500, radius = 30, innerRadius = 15, collected = false}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        ModernTestFramework.assert.equal(0, #result, "Should not detect collision when too far")
    end,
    
    ["should not detect collision with collected ring"] = function()
        local player = {x = 500, y = 300, radius = 10, vx = 100, vy = 0}
        local ring = {x = 500, y = 300, radius = 30, innerRadius = 15, collected = true}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        ModernTestFramework.assert.equal(0, #result, "Should not detect collision with collected ring")
    end,
    
    ["should not detect collision in ring center hole"] = function()
        local player = {x = 500, y = 300, radius = 5, vx = 100, vy = 0}
        local ring = {x = 500, y = 300, radius = 30, innerRadius = 15, collected = false}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playRing = function() end
        }
        
        local result = CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        ModernTestFramework.assert.equal(0, #result, "Should not detect collision in ring center hole")
    end,
    
    ["should handle ring collection"] = function()
        local player = {x = 520, y = 300, radius = 10, vx = 100, vy = 0}
        local ring = {x = 500, y = 300, radius = 30, innerRadius = 15, collected = false}
        local rings = {ring}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playRing = function() end
        }
        
        CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        ModernTestFramework.assert.isTrue(ring.collected, "Ring should be marked as collected")
    end,
    
    ["should handle special ring effects"] = function()
        local player = {x = 520, y = 300, radius = 10, vx = 100, vy = 0}
        local specialRing = {x = 500, y = 300, radius = 30, innerRadius = 15, collected = false, type = "special"}
        local rings = {specialRing}
        local gameState = {
            addScore = function() end,
            addCombo = function() end
        }
        local soundManager = {
            playRing = function() end
        }
        
        CollisionSystem.checkRingCollisions(player, rings, nil, gameState, soundManager)
        
        ModernTestFramework.assert.isTrue(specialRing.collected, "Special ring should be collected")
    end,
    
    -- Edge cases
    ["should handle nil inputs gracefully"] = function()
        local result1 = CollisionSystem.checkPlanetCollisions(nil, {}, nil, {}, {})
        local result2 = CollisionSystem.checkRingCollisions(nil, {}, nil, {}, {})
        
        ModernTestFramework.assert.isNil(result1, "Should handle nil player in planet collision")
        ModernTestFramework.assert.equal(0, #result2, "Should handle nil player in ring collision")
    end,
    
    ["should handle empty object lists"] = function()
        local player = {x = 100, y = 100, radius = 10}
        
        local result1 = CollisionSystem.checkPlanetCollisions(player, {}, nil, {}, {})
        local result2 = CollisionSystem.checkRingCollisions(player, {}, nil, {}, {})
        
        ModernTestFramework.assert.isNil(result1, "Should handle empty planet list")
        ModernTestFramework.assert.equal(0, #result2, "Should return empty table for empty ring list")
    end,
    
    ["should handle zero radius objects"] = function()
        local player = {x = 100, y = 100, radius = 0}
        local planet = {x = 105, y = 105, radius = 20}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.isNil(result, "Should not detect collision with zero radius player")
    end,
    
    ["should handle negative radius objects"] = function()
        local player = {x = 100, y = 100, radius = -10}
        local planet = {x = 105, y = 105, radius = 20}
        local planets = {planet}
        local gameState = {
            addScore = function() end,
            getPlanets = function() return planets end
        }
        local soundManager = {
            playLand = function() end
        }
        
        local result = CollisionSystem.checkPlanetCollisions(player, planets, nil, gameState, soundManager)
        
        ModernTestFramework.assert.isNil(result, "Should not detect collision with negative radius player")
    end,
    
    -- Utility functions
    ["should detect out of bounds correctly"] = function()
        local player = {x = 1000, y = 1000, radius = 10}
        local screenWidth, screenHeight = 800, 600
        local margin = 100
        
        -- Player is outside screen bounds
        local outOfBounds = player.x > screenWidth + margin or 
                           player.x < -margin or 
                           player.y > screenHeight + margin or 
                           player.y < -margin
        
        ModernTestFramework.assert.isTrue(outOfBounds, "Should detect out of bounds correctly")
    end,
    
    ["should not detect boundary collision when in bounds"] = function()
        local player = {x = 400, y = 300, radius = 10}
        local screenWidth, screenHeight = 800, 600
        local margin = 100
        
        -- Player is within screen bounds
        local inBounds = player.x <= screenWidth + margin and 
                        player.x >= -margin and 
                        player.y <= screenHeight + margin and 
                        player.y >= -margin
        
        ModernTestFramework.assert.isTrue(inBounds, "Should not detect boundary collision when in bounds")
    end
}

return tests 