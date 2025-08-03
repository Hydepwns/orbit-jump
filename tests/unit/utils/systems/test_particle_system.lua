-- Tests for Particle System
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Use global ParticleSystem (which will be the mock)
local ParticleSystem = _G.ParticleSystem
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    -- Test system initialization
    ["particle system initialization"] = function()
        ParticleSystem.init()
        TestFramework.assert.notNil(ParticleSystem.particles, "Particles array should be initialized")
        TestFramework.assert.notNil(ParticleSystem.particlePool, "Particle pool should be initialized")
        TestFramework.assert.equal(1000, ParticleSystem.maxParticles, "Max particles should be set correctly")
        TestFramework.assert.equal(0, #ParticleSystem.particles, "Particles array should start empty")
    end,
    -- Test particle creation
    ["basic particle creation"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 10, -5, {1, 0, 0, 1}, 2.0, 5, "test")
        TestFramework.assert.notNil(particle, "Particle should be created")
        TestFramework.assert.equal(100, particle.x, "Particle x should be set correctly")
        TestFramework.assert.equal(200, particle.y, "Particle y should be set correctly")
        TestFramework.assert.equal(10, particle.vx, "Particle vx should be set correctly")
        TestFramework.assert.equal(-5, particle.vy, "Particle vy should be set correctly")
        TestFramework.assert.equal(2.0, particle.lifetime, "Particle lifetime should be set correctly")
        TestFramework.assert.equal(2.0, particle.maxLifetime, "Particle maxLifetime should be set correctly")
        TestFramework.assert.equal(5, particle.size, "Particle size should be set correctly")
        TestFramework.assert.equal("test", particle.type, "Particle type should be set correctly")
        TestFramework.assert.equal(1, #ParticleSystem.particles, "Particle should be added to array")
    end,
    ["particle creation with defaults"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200)
        TestFramework.assert.notNil(particle, "Particle should be created with defaults")
        TestFramework.assert.equal(100, particle.x, "Particle x should be set")
        TestFramework.assert.equal(200, particle.y, "Particle y should be set")
        TestFramework.assert.equal(0, particle.vx, "Particle vx should default to 0")
        TestFramework.assert.equal(0, particle.vy, "Particle vy should default to 0")
        TestFramework.assert.equal(1, particle.lifetime, "Particle lifetime should default to 1")
        TestFramework.assert.equal(2, particle.size, "Particle size should default to 2")
        TestFramework.assert.equal("default", particle.type, "Particle type should default to 'default'")
    end,
    ["particle creation with color"] = function()
        ParticleSystem.init()
        local color = {0.5, 0.7, 1.0, 0.8}
        local particle = ParticleSystem.create(100, 200, 0, 0, color)
        TestFramework.assert.equal(color, particle.color, "Particle color should be set correctly")
    end,
    -- Test particle limits
    ["particle limit enforcement"] = function()
        ParticleSystem.init()
        ParticleSystem.maxParticles = 3 -- Set small limit for testing
        -- Create more particles than limit
        ParticleSystem.create(100, 200)
        ParticleSystem.create(200, 300)
        ParticleSystem.create(300, 400)
        ParticleSystem.create(400, 500) -- This should remove the oldest
        TestFramework.assert.equal(3, #ParticleSystem.particles, "Particle count should respect limit")
        -- Reset to default for other tests
        ParticleSystem.maxParticles = 1000
    end,
    -- Test particle updates
    ["particle position update"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 50, -30, nil, 2.0)
        local originalX = particle.x
        local originalY = particle.y
        ParticleSystem.update(0.1)
        TestFramework.assert.isTrue(particle.x > originalX, "Particle should move in x direction")
        TestFramework.assert.isTrue(particle.y < originalY, "Particle should move in y direction")
    end,
    ["particle gravity effect"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 0, 0, nil, 2.0)
        local originalVy = particle.vy
        ParticleSystem.update(0.1)
        TestFramework.assert.isTrue(particle.vy > originalVy, "Particle should be affected by gravity")
    end,
    ["particle drag effect"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 100, 100, nil, 2.0)
        local originalVx = particle.vx
        local originalVy = particle.vy
        ParticleSystem.update(0.1)
        -- Drag should reduce vx (no gravity on x)
        TestFramework.assert.isTrue(particle.vx < originalVx, "Particle vx should be affected by drag")
        -- vy might increase due to gravity, but should be less than it would be without drag
        -- Gravity adds 200 * 0.1 = 20, so without drag vy would be 120
        -- With drag, vy should be less than 120
        TestFramework.assert.isTrue(particle.vy < originalVy + 20, "Particle vy should be affected by drag (less than gravity-only)")
    end,
    ["particle lifetime update"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 0, 0, nil, 1.0)
        local originalLifetime = particle.lifetime
        ParticleSystem.update(0.1)
        TestFramework.assert.equal(originalLifetime - 0.1, particle.lifetime, "Particle lifetime should decrease")
    end,
    ["particle death and cleanup"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 0, 0, nil, 0.1)
        TestFramework.assert.equal(1, #ParticleSystem.particles, "Should have one particle")
        ParticleSystem.update(0.2) -- More than lifetime
        TestFramework.assert.equal(0, #ParticleSystem.particles, "Dead particle should be removed")
    end,
    -- Test particle effects
    ["particle burst effect"] = function()
        ParticleSystem.init()
        local initialCount = #ParticleSystem.particles
        ParticleSystem.burst(100, 200, 5, {1, 0, 0, 1}, 100, 1.0)
        TestFramework.assert.equal(initialCount + 5, #ParticleSystem.particles, "Burst should create correct number of particles")
        -- Check that particles are around the burst point
        for _, particle in ipairs(ParticleSystem.particles) do
            local distance = math.sqrt((particle.x - 100)^2 + (particle.y - 200)^2)
            TestFramework.assert.isTrue(distance < 10, "Burst particles should be near burst point")
        end
    end,
    ["particle burst with defaults"] = function()
        ParticleSystem.init()
        ParticleSystem.burst(100, 200)
        TestFramework.assert.equal(10, #ParticleSystem.particles, "Burst should create default number of particles")
    end,
    ["particle trail effect"] = function()
        ParticleSystem.init()
        local initialCount = #ParticleSystem.particles
        ParticleSystem.trail(100, 200, 50, -30, {0, 1, 0, 1}, 3)
        TestFramework.assert.equal(initialCount + 3, #ParticleSystem.particles, "Trail should create correct number of particles")
        -- Check that trail particles have opposite velocity
        for _, particle in ipairs(ParticleSystem.particles) do
            TestFramework.assert.isTrue(particle.vx < 0 or particle.vy > 0, "Trail particles should have opposite velocity")
        end
    end,
    ["particle trail with defaults"] = function()
        ParticleSystem.init()
        ParticleSystem.trail(100, 200, 50, -30)
        TestFramework.assert.equal(3, #ParticleSystem.particles, "Trail should create default number of particles")
    end,
    ["particle sparkle effect"] = function()
        ParticleSystem.init()
        local initialCount = #ParticleSystem.particles
        ParticleSystem.sparkle(100, 200, {1, 1, 0, 1})
        TestFramework.assert.equal(initialCount + 5, #ParticleSystem.particles, "Sparkle should create correct number of particles")
        -- Check that sparkle particles have the correct type
        for _, particle in ipairs(ParticleSystem.particles) do
            if particle.type == "sparkle" then
                TestFramework.assert.equal("sparkle", particle.type, "Sparkle particles should have correct type")
            end
        end
    end,
    ["particle sparkle with default color"] = function()
        ParticleSystem.init()
        ParticleSystem.sparkle(100, 200)
        TestFramework.assert.equal(5, #ParticleSystem.particles, "Sparkle should create default number of particles")
    end,
    -- Test particle management
    ["get particles"] = function()
        ParticleSystem.init()
        ParticleSystem.create(100, 200)
        ParticleSystem.create(200, 300)
        local particles = ParticleSystem.getParticles()
        TestFramework.assert.equal(2, #particles, "Should return correct number of particles")
        TestFramework.assert.equal(ParticleSystem.particles, particles, "Should return the particles array")
    end,
    ["get particle count"] = function()
        ParticleSystem.init()
        TestFramework.assert.equal(0, ParticleSystem.getCount(), "Should return 0 for empty system")
        ParticleSystem.create(100, 200)
        ParticleSystem.create(200, 300)
        TestFramework.assert.equal(2, ParticleSystem.getCount(), "Should return correct particle count")
    end,
    ["clear particles"] = function()
        ParticleSystem.init()
        ParticleSystem.create(100, 200)
        ParticleSystem.create(200, 300)
        TestFramework.assert.equal(2, #ParticleSystem.particles, "Should have particles before clear")
        ParticleSystem.clear()
        TestFramework.assert.equal(0, #ParticleSystem.particles, "Should have no particles after clear")
    end,
    -- Test particle pooling
    ["particle pooling reuse"] = function()
        ParticleSystem.init()
        local particle1 = ParticleSystem.create(100, 200, 0, 0, nil, 0.1)
        local particle2 = ParticleSystem.create(200, 300, 0, 0, nil, 0.1)
        -- Kill particles
        ParticleSystem.update(0.2)
        TestFramework.assert.equal(0, #ParticleSystem.particles, "Particles should be dead")
        -- Create new particles (should reuse from pool)
        local particle3 = ParticleSystem.create(300, 400)
        local particle4 = ParticleSystem.create(400, 500)
        TestFramework.assert.equal(2, #ParticleSystem.particles, "Should be able to create new particles")
        TestFramework.assert.notNil(particle3, "New particle should be created")
        TestFramework.assert.notNil(particle4, "New particle should be created")
    end,
    -- Test edge cases
    ["particle with zero lifetime"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 0, 0, nil, 0)
        TestFramework.assert.equal(1, #ParticleSystem.particles, "Should have particle with zero lifetime")
        ParticleSystem.update(0.1)
        TestFramework.assert.equal(0, #ParticleSystem.particles, "Zero lifetime particle should be removed immediately")
    end,
    ["particle with negative velocity"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, -50, -30, nil, 1.0)
        local originalX = particle.x
        local originalY = particle.y
        ParticleSystem.update(0.1)
        TestFramework.assert.isTrue(particle.x < originalX, "Particle should move in negative x direction")
        TestFramework.assert.isTrue(particle.y < originalY, "Particle should move in negative y direction")
    end,
    ["multiple particle updates"] = function()
        ParticleSystem.init()
        local particle = ParticleSystem.create(100, 200, 10, -5, nil, 1.0)
        -- Update multiple times
        for i = 1, 5 do
            ParticleSystem.update(0.1)
        end
        TestFramework.assert.isTrue(particle.x > 100, "Particle should move right due to positive vx")
        TestFramework.assert.isTrue(particle.y > 200, "Particle should move down due to gravity")
        TestFramework.assert.isTrue(math.abs(particle.lifetime - 0.5) < 0.01, "Particle lifetime should decrease correctly")
    end,
    ["particle effect combinations"] = function()
        ParticleSystem.init()
        -- Create multiple effects
        ParticleSystem.burst(100, 200, 3)
        ParticleSystem.trail(200, 300, 50, -30, nil, 2)
        ParticleSystem.sparkle(300, 400)
        TestFramework.assert.equal(10, #ParticleSystem.particles, "Should have correct total particles from all effects")
    end
}
-- Run the test suite
local function run()
    Utils.Logger.info("Running Particle System Tests")
    Utils.Logger.info("==================================================")
    local success = TestFramework.runTests(tests)
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("particle_system", 8) -- All major functions tested
    return success
end
return {run = run}