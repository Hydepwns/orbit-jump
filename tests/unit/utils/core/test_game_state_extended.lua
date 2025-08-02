-- Extended Tests for Game State
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
local GameState = Utils.require("src.core.game_state")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["challenge mode backup and restore"] = function()
        GameState.init(800, 600)
        
        -- Set up some state
        GameState.objects.planets = {{x = 100, y = 100, radius = 50}}
        GameState.objects.rings = {{x = 200, y = 200, radius = 30}}
        GameState.data.score = 1000
        GameState.data.combo = 5
        
        -- Clear for challenge
        GameState.clearForChallenge()
        
        TestFramework.assert.assertNotNil(GameState.challengeBackup, "Should create backup")
        TestFramework.assert.assertEqual(0, #GameState.objects.planets, "Planets should be cleared")
        TestFramework.assert.assertEqual(0, #GameState.objects.rings, "Rings should be cleared")
        
        -- Restore from challenge
        GameState.restoreFromChallenge()
        
        TestFramework.assert.assertEqual(1, #GameState.objects.planets, "Planets should be restored")
        TestFramework.assert.assertEqual(1, #GameState.objects.rings, "Rings should be restored")
        TestFramework.assert.assertNil(GameState.challengeBackup, "Backup should be cleared")
    end,
    
    ["mouse state management"] = function()
        GameState.init(800, 600)
        
        -- Test mouse down
        GameState.setMouseDown(true, 100, 200)
        TestFramework.assert.assertTrue(GameState.isMouseDown(), "Mouse should be down")
        TestFramework.assert.assertEqual(100, GameState.data.mouseStartX, "Mouse X should be set")
        TestFramework.assert.assertEqual(200, GameState.data.mouseStartY, "Mouse Y should be set")
        
        -- Test mouse up
        GameState.setMouseDown(false)
        TestFramework.assert.assertFalse(GameState.isMouseDown(), "Mouse should be up")
    end,
    
    ["pull power management"] = function()
        GameState.init(800, 600)
        
        GameState.setPullPower(50)
        TestFramework.assert.assertEqual(50, GameState.getPullPower(), "Pull power should be set")
        
        local maxPull = GameState.getMaxPullDistance()
        TestFramework.assert.assertEqual(250, maxPull, "Max pull distance should be default")
    end,
    
    ["config management"] = function()
        GameState.init(800, 600)
        
        -- Set config value
        GameState.setConfig("testKey", "testValue")
        TestFramework.assert.assertEqual("testValue", GameState.getConfig("testKey"), "Config should be set")
        
        -- Get existing config
        local gravity = GameState.getConfig("gravity")
        TestFramework.assert.assertEqual(15000, gravity, "Should get default gravity")
    end,
    
    ["UI screen management"] = function()
        GameState.init(800, 600)
        
        GameState.setUIScreen("menu")
        TestFramework.assert.assertEqual("menu", GameState.getUIScreen(), "UI screen should be set")
        TestFramework.assert.assertTrue(GameState.isUIScreen("menu"), "Should be on menu screen")
        TestFramework.assert.assertFalse(GameState.isUIScreen("game"), "Should not be on game screen")
    end,
    
    ["particle management"] = function()
        GameState.init(800, 600)
        
        -- Add particle
        local particle = {x = 100, y = 100, vx = 10, vy = -10}
        GameState.addParticle(particle)
        
        local particles = GameState.getParticles()
        TestFramework.assert.assertEqual(1, #particles, "Should have one particle")
        
        -- Remove particle
        GameState.removeParticle(1)
        particles = GameState.getParticles()
        TestFramework.assert.assertEqual(0, #particles, "Should have no particles")
    end,
    
    ["player state helpers"] = function()
        GameState.init(800, 600)
        
        -- Test in space
        GameState.player.onPlanet = nil
        TestFramework.assert.assertTrue(GameState.isPlayerInSpace(), "Player should be in space")
        TestFramework.assert.assertFalse(GameState.isPlayerOnPlanet(), "Player should not be on planet")
        TestFramework.assert.assertFalse(GameState.canJump(), "Should not be able to jump in space")
        TestFramework.assert.assertTrue(GameState.canDash(), "Should be able to dash in space")
        
        -- Test on planet
        GameState.player.onPlanet = 1
        TestFramework.assert.assertFalse(GameState.isPlayerInSpace(), "Player should not be in space")
        TestFramework.assert.assertTrue(GameState.isPlayerOnPlanet(), "Player should be on planet")
        TestFramework.assert.assertTrue(GameState.canJump(), "Should be able to jump on planet")
        TestFramework.assert.assertFalse(GameState.canDash(), "Should not be able to dash on planet")
    end,
    
    ["combo management"] = function()
        GameState.init(800, 600)
        
        -- Add combo
        GameState.addCombo()
        TestFramework.assert.assertEqual(1, GameState.getCombo(), "Combo should be 1")
        TestFramework.assert.assertTrue(GameState.data.comboTimer > 0, "Combo timer should be set")
        
        -- Set combo
        GameState.setCombo(5)
        TestFramework.assert.assertEqual(5, GameState.getCombo(), "Combo should be 5")
        
        -- Test combo timeout - set timer to small positive value so reset logic triggers
        GameState.data.comboTimer = 0.05
        GameState.update(0.1)
        TestFramework.assert.assertEqual(0, GameState.getCombo(), "Combo should reset")
    end,
    
    ["game time tracking"] = function()
        GameState.init(800, 600)
        
        local initialTime = GameState.getGameTime()
        GameState.update(1.5)
        
        TestFramework.assert.assertEqual(initialTime + 1.5, GameState.getGameTime(), "Game time should increase")
    end,
    
    ["speed boost management"] = function()
        GameState.init(800, 600)
        
        GameState.setSpeedBoost(1.5)
        TestFramework.assert.assertEqual(1.5, GameState.getSpeedBoost(), "Speed boost should be set")
        
        -- Test speed boost reset on combo timeout - set timer to small positive value so reset logic triggers
        GameState.data.combo = 5
        GameState.data.comboTimer = 0.05
        GameState.update(0.1)
        TestFramework.assert.assertEqual(1.0, GameState.player.speedBoost, "Speed boost should reset")
    end,
    
    ["player position and velocity"] = function()
        GameState.init(800, 600)
        
        -- Set position
        GameState.setPlayerPosition(300, 400)
        local x, y = GameState.getPlayerPosition()
        TestFramework.assert.assertEqual(300, x, "Player X should be set")
        TestFramework.assert.assertEqual(400, y, "Player Y should be set")
        
        -- Set velocity
        GameState.setPlayerVelocity(50, -100)
        local vx, vy = GameState.getPlayerVelocity()
        TestFramework.assert.assertEqual(50, vx, "Player VX should be set")
        TestFramework.assert.assertEqual(-100, vy, "Player VY should be set")
    end,
    
    ["player planet and angle"] = function()
        GameState.init(800, 600)
        
        -- Set planet
        GameState.setPlayerOnPlanet(3)
        TestFramework.assert.assertEqual(3, GameState.getPlayerOnPlanet(), "Player should be on planet 3")
        
        -- Set angle
        GameState.setPlayerAngle(1.57)
        TestFramework.assert.assertEqual(1.57, GameState.getPlayerAngle(), "Player angle should be set")
    end,
    
    ["rings and planets management"] = function()
        GameState.init(800, 600)
        
        -- Set rings
        local rings = {{x = 100, y = 100}, {x = 200, y = 200}}
        GameState.setRings(rings)
        TestFramework.assert.assertEqual(rings, GameState.getRings(), "Rings should be set")
        
        -- Set planets without player initialization
        local planets = {{x = 300, y = 300, radius = 50}}
        GameState.setPlanets(planets)
        TestFramework.assert.assertEqual(planets, GameState.getPlanets(), "Planets should be set")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Game State Extended Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("game_state", 8) -- Now testing all 8 functions
    
    return success
end

return {run = run}