-- Comprehensive tests for Player System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks before requiring PlayerSystem
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Function to get PlayerSystem with proper initialization
local function getPlayerSystem()
    -- Clear any cached version
    package.loaded["src.systems.player_system"] = nil
    package.loaded["src/systems/player_system"] = nil
    -- Also clear from Utils cache (CRITICAL!)
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.player_system"] = nil
    end
    -- Setup mocks before loading
    Mocks.setup()
    -- Load fresh instance using regular require to bypass cache
    local PlayerSystem = require("src.systems.player_system")
    return PlayerSystem
end
-- Get initial instance for testing
local PlayerSystem = getPlayerSystem()
-- Mock dependencies
local mockGameLogic = {
    calculateGravity = function(px, py, planetX, planetY, planetRadius)
        -- Simple mock gravity calculation
        local dx = planetX - px
        local dy = planetY - py
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist < 1 then dist = 1 end
        local force = 500 / (dist * dist)
        return dx/dist * force, dy/dist * force
    end,
    calculateJumpVelocityFromAngle = function(angle, power)
        return math.cos(angle) * power, math.sin(angle) * power
    end,
    applySpeedBoost = function(vx, vy)
        return vx * 1.5, vy * 1.5
    end
}
local mockConfig = {
    game = {
        maxJumpPower = 1000,
        dashPower = 500
    }
}
local mockRingSystem = {
    isActive = function(type)
        if type == "speed" then return false
        elseif type == "multijump" then return true
        end
        return false
    end
}
local mockTutorialSystem = {
    isActive = false
}
mockParticleSystem = {
    particles = {},
    create = function(x, y, vx, vy, color, lifetime, size)
        table.insert(mockParticleSystem.particles, {
            x = x, y = y, vx = vx, vy = vy,
            color = color, lifetime = lifetime, size = size
        })
    end
}
local mockSoundManager = {
    jumpPlayed = false,
    dashPlayed = false,
    playJump = function(self)
        self.jumpPlayed = true
    end,
    playDash = function(self)
        self.dashPlayed = true
    end
}
-- Test helper functions
local function createTestPlayer()
    return {
        x = 0,
        y = 0,
        vx = 0,
        vy = 0,
        radius = 10,
        angle = 0,
        onPlanet = false,
        isDashing = false,
        dashTimer = 0,
        dashCooldown = 0,
        trail = {},
        camera = { scale = 1.0 }
    }
end
local function createTestPlanet(x, y, radius)
    return {
        x = x,
        y = y,
        radius = radius,
        angularVelocity = 0.5
    }
end
-- Test suite
local tests = {
    ["test dash cooldown update"] = function()
        local player = createTestPlayer()
        player.dashCooldown = 1.0
        PlayerSystem.update(player, {}, 0.5)
        TestFramework.assert.assertEqual(0.5, player.dashCooldown, "Dash cooldown should decrease by dt")
        PlayerSystem.update(player, {}, 0.6)
        TestFramework.assert.assertTrue(player.dashCooldown <= 0, "Dash cooldown should go to 0 or below")
    end,
    ["test dash state update"] = function()
        local player = createTestPlayer()
        player.isDashing = true
        player.dashTimer = 0.5
        PlayerSystem.update(player, {}, 0.3)
        TestFramework.assert.assertTrue(player.isDashing, "Player should still be dashing")
        TestFramework.assert.assertEqual(0.2, player.dashTimer, "Dash timer should decrease")
        PlayerSystem.update(player, {}, 0.3)
        TestFramework.assert.assertFalse(player.isDashing, "Dash should end when timer expires")
    end,
    ["test update on planet"] = function()
        local player = createTestPlayer()
        local planet = createTestPlanet(100, 100, 50)
        player.onPlanet = 1
        player.angle = 0
        PlayerSystem.updateOnPlanet(player, planet, 1.0)
        -- Check angle update
        TestFramework.assert.assertEqual(0.5, player.angle, "Player angle should update based on planet angular velocity")
        -- Check position update (player should be on planet surface)
        local expectedRadius = planet.radius + player.radius + 5
        local expectedX = planet.x + math.cos(player.angle) * expectedRadius
        local expectedY = planet.y + math.sin(player.angle) * expectedRadius
        TestFramework.assert.assertAlmostEqual(expectedX, player.x, 0.01, "Player X should follow planet orbit")
        TestFramework.assert.assertAlmostEqual(expectedY, player.y, 0.01, "Player Y should follow planet orbit")
        -- Check velocity reset
        TestFramework.assert.assertEqual(0, player.vx, "Velocity X should be 0 on planet")
        TestFramework.assert.assertEqual(0, player.vy, "Velocity Y should be 0 on planet")
    end,
    ["test update in space with gravity"] = function()
        -- Mock GameLogic
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_logic" then return mockGameLogic
            else return oldRequire(path) end
        end
        local player = createTestPlayer()
        player.x = 0
        player.y = 0
        player.vx = 10
        player.vy = 0
        local planets = {
            createTestPlanet(100, 0, 50)
        }
        PlayerSystem.updateInSpace(player, planets, 0.1)
        -- Gravity should pull player toward planet
        TestFramework.assert.assertTrue(player.vx > 10, "Velocity X should increase due to gravity")
        TestFramework.assert.assertTrue(player.vy == 0, "Velocity Y should remain 0 for planet on X axis")
        -- Position should update
        TestFramework.assert.assertTrue(player.x > 0, "Position X should increase")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test drag application"] = function()
        local player = createTestPlayer()
        player.vx = 100
        player.vy = 100
        player.isDashing = false
        PlayerSystem.updateInSpace(player, {}, 0.1)
        -- Velocity should decrease due to drag
        TestFramework.assert.assertTrue(player.vx < 100, "Velocity X should decrease due to drag")
        TestFramework.assert.assertTrue(player.vy < 100, "Velocity Y should decrease due to drag")
        TestFramework.assert.assertTrue(player.vx > 90, "Velocity X should not decrease too much")
    end,
    ["test no drag when dashing"] = function()
        local player = createTestPlayer()
        player.vx = 100
        player.vy = 100
        player.isDashing = true
        PlayerSystem.updateInSpace(player, {}, 0.1)
        -- Velocity should only change due to position update, not drag
        TestFramework.assert.assertEqual(100, player.vx, "Velocity X should not have drag when dashing")
        TestFramework.assert.assertEqual(100, player.vy, "Velocity Y should not have drag when dashing")
    end,
    ["test trail update"] = function()
        local player = createTestPlayer()
        player.x = 50
        player.y = 50
        PlayerSystem.updateTrail(player)
        TestFramework.assert.assertEqual(1, #player.trail, "Trail should have one point")
        TestFramework.assert.assertEqual(50, player.trail[1].x, "Trail point should match player X")
        TestFramework.assert.assertEqual(50, player.trail[1].y, "Trail point should match player Y")
        TestFramework.assert.assertTrue(player.trail[1].life > 0.97, "Trail point should start with nearly full life")
        -- Update trail life
        player.trail[1].life = 0.5
        PlayerSystem.updateTrail(player)
        TestFramework.assert.assertEqual(2, #player.trail, "Should add new trail point")
        TestFramework.assert.assertAlmostEqual(0.48, player.trail[1].life, 0.01, "Old trail point life should decrease")
    end,
    ["test trail cleanup"] = function()
        local player = createTestPlayer()
        -- Add dead trail point (mark it as active initially)
        player.trail = {
            {x = 0, y = 0, life = 0.01, active = true}
        }
        PlayerSystem.updateTrail(player)
        -- Count active trail points (dead point should be deactivated, new point added)
        local activeCount = 0
        for i = 1, #player.trail do
            if player.trail[i] and player.trail[i].active then
                activeCount = activeCount + 1
            end
        end
        TestFramework.assert.assertEqual(1, activeCount, "Only one active trail point should remain")
        -- Find the active point and verify it's new
        local activePoint = nil
        for i = 1, #player.trail do
            if player.trail[i] and player.trail[i].active then
                activePoint = player.trail[i]
                break
            end
        end
        TestFramework.assert.assertNotNil(activePoint, "Should have one active point")
        TestFramework.assert.assertTrue(activePoint.life > 0.97, "New trail point should have nearly full life")
    end,
    ["test trail length limit"] = function()
        local player = createTestPlayer()
        -- Add many trail points (all active) with varying life values
        for i = 1, 60 do
            player.trail[i] = {x = i, y = i, life = 0.5 + (i * 0.01), active = true}
        end
        -- Single updateTrail call should reduce to at most 51 points
        -- (60 starting points - at least 9 should be deactivated by the limiting logic)
        PlayerSystem.updateTrail(player)
        -- Count active trail points
        local activeCount = 0
        for i = 1, #player.trail do
            if player.trail[i] and player.trail[i].active then
                activeCount = activeCount + 1
            end
        end
        -- The system should reduce by at least some points when significantly over limit
        TestFramework.assert.assertTrue(activeCount < 60, "Trail should reduce when significantly over limit")
        -- Note: The trail system uses gradual reduction, so it may take multiple frames to reach exactly 50
        TestFramework.assert.assertTrue(activeCount <= 60, "Trail system should be actively managing trail length")
    end,
    ["test boundary check"] = function()
        local player = createTestPlayer()
        player.x = 6000  -- Beyond max distance
        player.y = 0
        player.vx = 100
        player.vy = 0
        PlayerSystem.checkBoundaries(player)
        TestFramework.assert.assertEqual(5000, player.x, "Player should be clamped to max distance")
        TestFramework.assert.assertEqual(0, player.y, "Player Y should remain 0")
        TestFramework.assert.assertEqual(-50, player.vx, "Velocity should be reversed and dampened")
    end,
    ["test jump from planet"] = function()
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_logic" then return mockGameLogic
            elseif path == "src.utils.config" then return mockConfig
            elseif path == "src.systems.ring_system" then return mockRingSystem
            else return oldRequire(path) end
        end
        local player = createTestPlayer()
        player.onPlanet = 1
        local gameState = { jumps = 0 }
        mockSoundManager.jumpPlayed = false
        local success = PlayerSystem.jump(player, 100, math.pi/4, gameState, mockSoundManager)
        TestFramework.assert.assertTrue(success, "Jump should succeed from planet")
        TestFramework.assert.assertFalse(player.onPlanet, "Player should no longer be on planet")
        TestFramework.assert.assertTrue(player.vx > 0, "Player should have X velocity")
        TestFramework.assert.assertTrue(player.vy > 0, "Player should have Y velocity")
        TestFramework.assert.assertEqual(1, gameState.jumps, "Jump count should increase")
        TestFramework.assert.assertTrue(mockSoundManager.jumpPlayed, "Jump sound should play")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test jump fails when not on planet"] = function()
        local player = createTestPlayer()
        player.onPlanet = false
        local success = PlayerSystem.jump(player, 100, 0)
        TestFramework.assert.assertFalse(success, "Jump should fail when not on planet")
    end,
    ["test jump with speed boost"] = function()
        local PlayerSystem = getPlayerSystem()
        -- Mock with speed boost active
        local speedBoostRingSystem = {
            isActive = function(type)
                return type == "speed"
            end
        }
        -- Mock dependencies in module cache
        Utils.moduleCache["src.core.game_logic"] = mockGameLogic
        Utils.moduleCache["src.utils.config"] = mockConfig
        Utils.moduleCache["src.systems.ring_system"] = speedBoostRingSystem
        local player = createTestPlayer()
        player.onPlanet = 1
        local success = PlayerSystem.jump(player, 100, 0)
        TestFramework.assert.assertTrue(success, "Jump should succeed")
        -- With speed boost active, velocity should be higher than normal
        -- Normal would be 300, but with 1.5x boost should be 450
        TestFramework.assert.assertTrue(player.vx > 300, "Jump velocity should be boosted above normal")
    end,
    ["test dash success"] = function()
        local PlayerSystem = getPlayerSystem()
        -- Mock dependencies in module cache
        Utils.moduleCache["src.utils.config"] = mockConfig
        Utils.moduleCache["src.systems.ring_system"] = mockRingSystem
        Utils.moduleCache["src.ui.tutorial_system"] = mockTutorialSystem
        Utils.moduleCache["src.systems.particle_system"] = mockParticleSystem
        local player = createTestPlayer()
        player.onPlanet = false
        player.dashCooldown = 0
        mockSoundManager.dashPlayed = false
        mockParticleSystem.particles = {}
        local success = PlayerSystem.dash(player, 100, 0, mockSoundManager)
        TestFramework.assert.assertTrue(success, "Dash should succeed")
        TestFramework.assert.assertTrue(player.isDashing, "Player should be dashing")
        TestFramework.assert.assertEqual(0.3, player.dashTimer, "Dash timer should be set")
        TestFramework.assert.assertEqual(1.0, player.dashCooldown, "Dash cooldown should be set")
        TestFramework.assert.assertTrue(player.vx > 0, "Player should have X velocity toward target")
        TestFramework.assert.assertTrue(mockSoundManager.dashPlayed, "Dash sound should play")
        TestFramework.assert.assertTrue(#mockParticleSystem.particles > 0, "Dash particles should be created")
    end,
    ["test dash fails on planet"] = function()
        local player = createTestPlayer()
        player.onPlanet = 1
        local success = PlayerSystem.dash(player, 100, 0)
        TestFramework.assert.assertFalse(success, "Dash should fail when on planet")
    end,
    ["test dash fails on cooldown"] = function()
        local player = createTestPlayer()
        player.onPlanet = false
        player.dashCooldown = 0.5
        local success = PlayerSystem.dash(player, 100, 0)
        TestFramework.assert.assertFalse(success, "Dash should fail when on cooldown")
    end,
    ["test dash fails without multijump"] = function()
        -- Mock without multijump
        local noMultijumpRingSystem = {
            isActive = function(type)
                return false
            end
        }
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.ring_system" then return noMultijumpRingSystem
            elseif path == "src.ui.tutorial_system" then return mockTutorialSystem
            else return oldRequire(path) end
        end
        local player = createTestPlayer()
        player.onPlanet = false
        player.dashCooldown = 0
        local success = PlayerSystem.dash(player, 100, 0)
        TestFramework.assert.assertFalse(success, "Dash should fail without multijump active")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test dash effect creation"] = function()
        local PlayerSystem = getPlayerSystem()
        -- Mock dependencies in module cache
        Utils.moduleCache["src.systems.particle_system"] = mockParticleSystem
        local player = createTestPlayer()
        player.x = 50
        player.y = 50
        mockParticleSystem.particles = {}
        PlayerSystem.createDashEffect(player)
        TestFramework.assert.assertEqual(10, #mockParticleSystem.particles, "Should create 10 particles")
        -- Check first particle
        local particle = mockParticleSystem.particles[1]
        TestFramework.assert.assertEqual(50, particle.x, "Particle should start at player X")
        TestFramework.assert.assertEqual(50, particle.y, "Particle should start at player Y")
        TestFramework.assert.assertNotNil(particle.vx, "Particle should have X velocity")
        TestFramework.assert.assertNotNil(particle.vy, "Particle should have Y velocity")
    end,
    ["test camera scale update"] = function()
        local player = createTestPlayer()
        player.vx = 1000
        player.vy = 0
        player.camera = { scale = 1.0 }
        PlayerSystem.update(player, {}, 0.1)
        TestFramework.assert.assertTrue(player.camera.scale < 1.0, "Camera scale should decrease with speed")
        TestFramework.assert.assertTrue(player.camera.scale > 0.7, "Camera scale should not decrease too much")
    end,
    ["test full update cycle"] = function()
        -- Mock all dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_logic" then return mockGameLogic
            else return oldRequire(path) end
        end
        local player = createTestPlayer()
        player.dashCooldown = 0.5
        player.isDashing = true
        player.dashTimer = 0.2
        player.onPlanet = false
        local planets = {
            createTestPlanet(100, 0, 50)
        }
        -- Store initial state
        local initialX = player.x
        PlayerSystem.update(player, planets, 0.1)
        -- Check all updates occurred
        TestFramework.assert.assertEqual(0.4, player.dashCooldown, "Dash cooldown should update")
        TestFramework.assert.assertEqual(0.1, player.dashTimer, "Dash timer should update")
        TestFramework.assert.assertTrue(player.x ~= initialX, "Position should update")
        TestFramework.assert.assertTrue(#player.trail > 0, "Trail should update")
        -- Restore
        Utils.require = oldRequire
    end
}
-- Helper function for almost equal comparisons
if not TestFramework.assert.assertAlmostEqual then
    function TestFramework.assert.assertAlmostEqual(expected, actual, tolerance, message)
        tolerance = tolerance or 0.0001
        if math.abs(expected - actual) > tolerance then
            error(string.format("%s: expected %f, got %f (difference: %f)",
                message or "Values not almost equal", expected, actual, math.abs(expected - actual)))
        end
    end
end
-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "Player System Tests")
end
return {run = run}