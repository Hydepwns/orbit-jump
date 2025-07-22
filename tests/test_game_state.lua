-- Integration tests for game state
package.path = package.path .. ";../?.lua"

local TestFramework = require("tests.test_framework")

-- Mock LÖVE2D functions for testing
love = {
    graphics = {
        getDimensions = function() return 800, 600 end,
        setBackgroundColor = function() end,
        setColor = function() end,
        circle = function() end,
        arc = function() end,
        line = function() end,
        printf = function() end,
        print = function() end,
        setLineWidth = function() end
    },
    timer = {
        getTime = function() return 0 end
    },
    mouse = {
        getPosition = function() return 0, 0 end
    },
    event = {
        quit = function() end
    }
}

-- Mock math functions that might not be available in plain Lua
if not math.atan2 then
    math.atan2 = function(y, x)
        if x > 0 then
            return math.atan(y/x)
        elseif x < 0 and y >= 0 then
            return math.atan(y/x) + math.pi
        elseif x < 0 and y < 0 then
            return math.atan(y/x) - math.pi
        elseif x == 0 and y > 0 then
            return math.pi / 2
        elseif x == 0 and y < 0 then
            return -math.pi / 2
        else
            return 0
        end
    end
end

local Game = require("game")
local test = TestFramework:new()

-- Test game state initialization
test:describe("game initialization", function(t)
    Game.init(800, 600)
    
    t:assertNotNil(Game.player, "Player should be initialized")
    t:assertNotNil(Game.planets, "Planets should be initialized")
    t:assertNotNil(Game.rings, "Rings should be initialized")
    t:assertEquals(Game.gameState, "playing", "Game should start in playing state")
    t:assertEquals(Game.score, 0, "Score should start at 0")
    t:assertEquals(Game.combo, 0, "Combo should start at 0")
end)

test:describe("player initialization", function(t)
    Game.init(800, 600)
    
    t:assertEquals(Game.player.onPlanet, 1, "Player should start on first planet")
    t:assertEquals(Game.player.vx, 0, "Player should have no initial x velocity")
    t:assertEquals(Game.player.vy, 0, "Player should have no initial y velocity")
    t:assertEquals(Game.player.speedBoost, 1.0, "Player should have no initial speed boost")
    t:assertFalse(Game.player.isDashing, "Player should not be dashing initially")
end)

test:describe("ring generation", function(t)
    Game.init(800, 600)
    
    t:assertEquals(#Game.rings, 15, "Should generate 15 rings")
    
    for i, ring in ipairs(Game.rings) do
        t:assertFalse(ring.collected, "Ring should not be collected initially")
        t:assertTrue(ring.x >= 100 and ring.x <= 700, "Ring x should be in bounds")
        t:assertTrue(ring.y >= 100 and ring.y <= 500, "Ring y should be in bounds")
        
        -- Check rings aren't too close to planets
        for _, planet in ipairs(Game.planets) do
            local dx = ring.x - planet.x
            local dy = ring.y - planet.y
            local distance = math.sqrt(dx*dx + dy*dy)
            t:assertTrue(distance >= planet.radius + 50, "Ring should not be too close to planet")
        end
    end
end)

-- Test player movement
test:describe("player orbiting", function(t)
    Game.init(800, 600)
    
    local initialAngle = Game.player.angle
    local initialX = Game.player.x
    
    Game.updatePlayer(0.1) -- Update for 0.1 seconds
    
    t:assertNotNil(Game.player.angle, "Player angle should exist")
    t:assertTrue(Game.player.angle ~= initialAngle, "Player angle should change while orbiting")
    t:assertEquals(Game.player.onPlanet, 1, "Player should remain on planet")
end)

test:describe("player jumping", function(t)
    Game.init(800, 600)
    
    t:assertEquals(Game.player.onPlanet, 1, "Player should start on planet")
    
    Game.pullPower = 50
    Game.jump()
    
    t:assertEquals(Game.player.onPlanet, nil, "Player should leave planet after jump")
    t:assertTrue(Game.player.vx ~= 0 or Game.player.vy ~= 0, "Player should have velocity after jump")
end)

-- Test collision detection
test:describe("ring collection", function(t)
    Game.init(800, 600)
    
    -- Reset combo to ensure clean test
    Game.combo = 0
    
    -- Place player at first ring location
    local ring = Game.rings[1]
    Game.player.x = ring.x + ring.radius - 5
    Game.player.y = ring.y
    Game.player.onPlanet = nil
    
    local initialScore = Game.score
    Game.checkRingCollisions()
    
    t:assertTrue(ring.collected, "Ring should be collected")
    t:assertTrue(Game.score > initialScore, "Score should increase")
    t:assertEquals(Game.combo, 1, "Combo should be 1")
end)

test:describe("planet landing", function(t)
    Game.init(800, 600)
    
    -- Launch player
    Game.player.onPlanet = nil
    Game.player.vx = 0
    Game.player.vy = 0
    
    -- Place player near second planet
    local planet = Game.planets[2]
    Game.player.x = planet.x + planet.radius - 5
    Game.player.y = planet.y
    
    Game.checkCollisions()
    
    t:assertEquals(Game.player.onPlanet, 2, "Player should land on second planet")
    t:assertEquals(Game.score, 1, "Score should increase by 1 for landing")
end)

-- Test dash mechanics
test:describe("dash activation", function(t)
    Game.init(800, 600)
    
    -- Launch player into space
    Game.player.onPlanet = nil
    Game.player.vx = 100
    Game.player.vy = 0
    Game.player.dashCooldown = 0
    
    Game.dash()
    
    t:assertTrue(Game.player.isDashing, "Player should be dashing")
    t:assertTrue(Game.player.dashTimer > 0, "Dash timer should be set")
    t:assertTrue(Game.player.dashCooldown > 0, "Dash cooldown should be set")
    t:assertTrue(math.abs(Game.player.vx) > 100, "Velocity should increase from dash")
end)

test:describe("dash cooldown", function(t)
    Game.init(800, 600)
    
    Game.player.onPlanet = nil
    Game.player.dashCooldown = 0.5
    
    Game.dash()
    
    t:assertFalse(Game.player.isDashing, "Should not dash during cooldown")
end)

-- Test combo system
test:describe("combo mechanics", function(t)
    Game.init(800, 600)
    
    -- Simulate collecting multiple rings
    Game.combo = 3
    Game.comboTimer = 2.0
    
    local boost = Game.player.speedBoost
    Game.update(0.1)
    
    t:assertTrue(Game.comboTimer < 2.0, "Combo timer should decrease")
    t:assertEquals(Game.combo, 3, "Combo should remain while timer active")
    
    -- Let combo expire
    Game.comboTimer = 0.1
    Game.update(0.2)
    
    t:assertEquals(Game.combo, 0, "Combo should reset when timer expires")
    t:assertEquals(Game.player.speedBoost, 1.0, "Speed boost should reset")
end)

-- Test game over conditions
test:describe("out of bounds game over", function(t)
    Game.init(800, 600)
    
    -- Send player out of bounds
    Game.player.onPlanet = nil
    Game.player.x = -200
    Game.player.y = 300
    
    Game.updatePlayer(0.1)
    
    t:assertEquals(Game.gameState, "gameOver", "Game should end when out of bounds")
end)

-- Test particle system
test:describe("particle creation", function(t)
    Game.init(800, 600)
    
    local initialParticles = #Game.particles
    
    Game.createParticle(100, 100, 50, -50, {1, 0, 0}, 1.0)
    
    t:assertEquals(#Game.particles, initialParticles + 1, "Should create one particle")
    
    local p = Game.particles[#Game.particles]
    t:assertEquals(p.x, 100, "Particle x position")
    t:assertEquals(p.y, 100, "Particle y position")
    t:assertEquals(p.vx, 50, "Particle x velocity")
    t:assertEquals(p.vy, -50, "Particle y velocity")
end)

test:describe("particle update", function(t)
    Game.init(800, 600)
    
    Game.particles = {} -- Clear particles
    Game.createParticle(100, 100, 100, 0, {1, 1, 1}, 1.0)
    
    local p = Game.particles[1]
    local initialX = p.x
    local initialVy = p.vy
    
    Game.updateParticles(0.1)
    
    t:assertTrue(p.x > initialX, "Particle should move horizontally")
    t:assertTrue(p.vy > initialVy, "Particle should accelerate downward (gravity)")
    t:assertTrue(p.lifetime < 1.0, "Particle lifetime should decrease")
end)

return test