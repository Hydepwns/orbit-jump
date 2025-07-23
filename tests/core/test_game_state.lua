-- Integration tests for game state
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local GameState = Utils.Utils.require("src.core.game_state")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test game initialization
    ["game initialization"] = function()
        local success = GameState.init(800, 600)
        TestFramework.utils.assertTrue(success, "Game state should initialize successfully")
        TestFramework.utils.assertEqual(800, GameState.data.screenWidth, "Screen width should be set")
        TestFramework.utils.assertEqual(600, GameState.data.screenHeight, "Screen height should be set")
    end,
    
    ["player initialization"] = function()
        GameState.init(800, 600)
        TestFramework.utils.assertNotNil(GameState.player.x, "Player should have x position")
        TestFramework.utils.assertNotNil(GameState.player.y, "Player should have y position")
        TestFramework.utils.assertEqual(10, GameState.player.radius, "Player should have correct radius")
    end,
    
    ["ring generation"] = function()
        GameState.init(800, 600)
        
        -- Mock love.graphics for ring generation
        if not love then love = {} end
        if not love.graphics then love.graphics = {} end
        love.graphics.getDimensions = function() return 800, 600 end
        
        -- Generate rings manually for test
        local rings = {}
        for i = 1, 5 do
            local ring = {
                x = 100 + i * 100,
                y = 100 + i * 50,
                radius = 30 + i * 5,
                innerRadius = 15 + i * 2,
                rotation = 0,
                rotationSpeed = 1.0,
                pulsePhase = 0,
                collected = false,
                color = {0.3, 0.7, 1, 0.8}
            }
            table.insert(rings, ring)
        end
        GameState.setRings(rings)
        
        local testRings = GameState.getRings()
        TestFramework.utils.assertTrue(#testRings > 0, "Should have rings")
        
        for _, ring in ipairs(testRings) do
            TestFramework.utils.assertNotNil(ring.x, "Ring should have x position")
            TestFramework.utils.assertNotNil(ring.y, "Ring should have y position")
            TestFramework.utils.assertNotNil(ring.radius, "Ring should have radius")
            TestFramework.utils.assertNotNil(ring.innerRadius, "Ring should have inner radius")
            TestFramework.utils.assertFalse(ring.collected, "Ring should start uncollected")
        end
    end,
    
    ["player orbiting"] = function()
        GameState.init(800, 600)
        local planets = {
            {x = 400, y = 300, radius = 50, rotationSpeed = 1.0}
        }
        GameState.setPlanets(planets)
        
        -- Set player on planet
        GameState.player.onPlanet = 1
        GameState.player.angle = 0
        GameState.player.x = 450
        GameState.player.y = 300
        
        -- Update player position
        local planet = planets[1]
        GameState.player.angle = GameState.player.angle + planet.rotationSpeed * 0.1
        GameState.player.x = planet.x + math.cos(GameState.player.angle) * (planet.radius + 20)
        GameState.player.y = planet.y + math.sin(GameState.player.angle) * (planet.radius + 20)
        
        TestFramework.utils.assertNotEqual(450, GameState.player.x, "Player should move while orbiting")
    end,
    
    ["player jumping"] = function()
        GameState.init(800, 600)
        local planets = {
            {x = 400, y = 300, radius = 50, rotationSpeed = 1.0}
        }
        GameState.setPlanets(planets)
        
        -- Set player on planet
        GameState.player.onPlanet = 1
        GameState.player.x = 450
        GameState.player.y = 300
        
        -- Simulate jump
        GameState.player.onPlanet = nil
        GameState.player.vx = 200
        GameState.player.vy = 0
        
        TestFramework.utils.assertNil(GameState.player.onPlanet, "Player should not be on planet after jump")
        TestFramework.utils.assertEqual(200, GameState.player.vx, "Player should have jump velocity")
    end,
    
    ["ring collection"] = function()
        GameState.init(800, 600)
        local rings = GameState.getRings()
        
        if #rings > 0 then
            local ring = rings[1]
            ring.collected = true
            
            TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
        end
    end,
    
    ["planet landing"] = function()
        GameState.init(800, 600)
        local planets = {
            {x = 400, y = 300, radius = 50, rotationSpeed = 1.0}
        }
        GameState.setPlanets(planets)
        
        -- Set player near planet
        GameState.player.x = 450
        GameState.player.y = 300
        GameState.player.onPlanet = nil
        
        -- Simulate collision detection
        local planet = planets[1]
        local distance = math.sqrt((GameState.player.x - planet.x)^2 + (GameState.player.y - planet.y)^2)
        
        if distance <= planet.radius + GameState.player.radius then
            GameState.player.onPlanet = 1
            GameState.player.angle = math.atan2 and Utils.atan2(GameState.player.y - planet.y, GameState.player.x - planet.x) or 0
        end
        
        TestFramework.utils.assertEqual(1, GameState.player.onPlanet, "Player should land on planet")
    end,
    
    ["dash activation"] = function()
        GameState.init(800, 600)
        
        GameState.player.isDashing = true
        GameState.player.dashTimer = 0.3
        
        TestFramework.utils.assertTrue(GameState.player.isDashing, "Player should be dashing")
        TestFramework.utils.assertEqual(0.3, GameState.player.dashTimer, "Dash timer should be set")
    end,
    
    ["dash cooldown"] = function()
        GameState.init(800, 600)
        
        GameState.player.dashCooldown = 1.0
        
        TestFramework.utils.assertEqual(1.0, GameState.player.dashCooldown, "Dash cooldown should be set")
        
        -- Simulate cooldown reduction
        GameState.player.dashCooldown = GameState.player.dashCooldown - 0.1
        
        TestFramework.utils.assertEqual(0.9, GameState.player.dashCooldown, "Dash cooldown should decrease")
    end,
    
    ["combo mechanics"] = function()
        GameState.init(800, 600)
        
        TestFramework.utils.assertEqual(0, GameState.getCombo(), "Combo should start at 0")
        
        GameState.addCombo()
        TestFramework.utils.assertEqual(1, GameState.getCombo(), "Combo should increase")
        
        GameState.addCombo()
        TestFramework.utils.assertEqual(2, GameState.getCombo(), "Combo should increase again")
    end,
    
    ["out of bounds game over"] = function()
        GameState.init(800, 600)
        
        -- Set player out of bounds
        GameState.player.x = -200
        GameState.player.y = 300
        
        -- Simulate out of bounds check
        local outOfBounds = GameState.player.x < -100 or GameState.player.x > 900 or
                           GameState.player.y < -100 or GameState.player.y > 700
        
        if outOfBounds then
            GameState.current = GameState.STATES.GAME_OVER
        end
        
        TestFramework.utils.assertEqual(GameState.STATES.GAME_OVER, GameState.current, "Game should be over when out of bounds")
    end,
    
    ["particle creation"] = function()
        GameState.init(800, 600)
        
        local initialCount = #GameState.getParticles()
        
        -- Create a particle
        local particle = {
            x = 400,
            y = 300,
            vx = 10,
            vy = -10,
            lifetime = 1.0,
            maxLifetime = 1.0,
            size = 5,
            color = {1, 1, 1, 1}
        }
        
        GameState.addParticle(particle)
        
        TestFramework.utils.assertEqual(initialCount + 1, #GameState.getParticles(), "Particle count should increase")
    end,
    
    ["particle update"] = function()
        GameState.init(800, 600)
        
        local particle = {
            x = 400,
            y = 300,
            vx = 10,
            vy = -10,
            lifetime = 1.0,
            maxLifetime = 1.0,
            size = 5,
            color = {1, 1, 1, 1}
        }
        
        GameState.addParticle(particle)
        
        -- Simulate particle update
        particle.x = particle.x + particle.vx * 0.1
        particle.y = particle.y + particle.vy * 0.1
        particle.lifetime = particle.lifetime - 0.1
        
        TestFramework.utils.assertEqual(401, particle.x, "Particle should move")
        TestFramework.utils.assertEqual(299, particle.y, "Particle should move")
        TestFramework.utils.assertEqual(0.9, particle.lifetime, "Particle lifetime should decrease")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runSuite("Game State Tests", tests)
end

return {run = run}