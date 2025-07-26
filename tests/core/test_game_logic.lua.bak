-- Tests for Game Logic
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local GameLogic = Utils.require("src.core.game_logic")

-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test distance calculations
    calculateDistance = function()
        local dist, dx, dy = Utils.distance(0, 0, 3, 4)
        TestFramework.utils.assertEqual(5, dist, "Should calculate distance correctly")
        TestFramework.utils.assertEqual(3, dx, "Should calculate dx correctly")
        TestFramework.utils.assertEqual(4, dy, "Should calculate dy correctly")
    end,
    
    ["calculateDistance with negative coordinates"] = function()
        local dist, dx, dy = Utils.distance(-1, -1, 2, 3)
        TestFramework.utils.assertEqual(5, dist, "Should handle negative coordinates")
        TestFramework.utils.assertEqual(3, dx, "Should calculate dx with negatives")
        TestFramework.utils.assertEqual(4, dy, "Should calculate dy with negatives")
    end,
    
    -- Test vector normalization
    normalizeVector = function()
        local nx, ny = GameLogic.normalizeVector(3, 4)
        TestFramework.utils.assertEqual(0.6, nx, "Should normalize x component")
        TestFramework.utils.assertEqual(0.8, ny, "Should normalize y component")
        
        -- Test magnitude
        local mag = math.sqrt(nx*nx + ny*ny)
        TestFramework.utils.assertEqual(1.0, mag, "Normalized vector should have magnitude 1")
    end,
    
    ["normalizeVector with zero vector"] = function()
        local nx, ny = GameLogic.normalizeVector(0, 0)
        TestFramework.utils.assertEqual(0, nx, "Zero vector should return 0 for x")
        TestFramework.utils.assertEqual(0, ny, "Zero vector should return 0 for y")
    end,
    
    -- Test gravity calculations
    calculateGravity = function()
        local gx, gy = GameLogic.calculateGravity(100, 100, 200, 100, 50)
        TestFramework.utils.assertTrue(gx > 0, "Gravity should pull right towards planet")
        TestFramework.utils.assertEqual(0, gy, "No vertical gravity component")
        
        -- Test gravity strength decreases with distance
        local gx2, gy2 = GameLogic.calculateGravity(100, 100, 300, 100, 50)
        TestFramework.utils.assertTrue(gx2 < gx, "Gravity should be weaker at greater distance")
    end,
    
    ["calculateGravity inside planet"] = function()
        local gx, gy = GameLogic.calculateGravity(100, 100, 100, 100, 50)
        TestFramework.utils.assertEqual(0, gx, "No gravity inside planet")
        TestFramework.utils.assertEqual(0, gy, "No gravity inside planet")
    end,
    
    -- Test orbit calculations
    calculateOrbitPosition = function()
        local x, y = GameLogic.calculateOrbitPosition(100, 100, 0, 50)
        TestFramework.utils.assertEqual(150, x, "Should calculate x position at angle 0")
        TestFramework.utils.assertEqual(100, y, "Should calculate y position at angle 0")
        
        local x2, y2 = GameLogic.calculateOrbitPosition(100, 100, math.pi/2, 50)
        TestFramework.utils.assertEqual(100, x2, "Should calculate x position at angle π/2")
        TestFramework.utils.assertEqual(150, y2, "Should calculate y position at angle π/2")
    end,
    
    -- Test collision detection
    checkRingCollision = function()
        -- Player passing through ring (at edge)
        local hit = GameLogic.checkRingCollision(125, 100, 10, 100, 100, 30, 20)
        TestFramework.utils.assertTrue(hit, "Should detect collision when player in ring")
        
        -- Player too far
        local miss = GameLogic.checkRingCollision(200, 100, 10, 100, 100, 30, 20)
        TestFramework.utils.assertFalse(miss, "Should not detect collision when too far")
        
        -- Player in center hole
        local inHole = GameLogic.checkRingCollision(100, 100, 5, 100, 100, 30, 20)
        TestFramework.utils.assertFalse(inHole, "Should not detect collision in center hole")
    end,
    
    checkPlanetCollision = function()
        -- Player touching planet
        local hit = GameLogic.checkPlanetCollision(150, 100, 10, 100, 100, 50)
        TestFramework.utils.assertTrue(hit, "Should detect collision when touching")
        
        -- Player far from planet
        local miss = GameLogic.checkPlanetCollision(200, 100, 10, 100, 100, 50)
        TestFramework.utils.assertFalse(miss, "Should not detect collision when far")
    end,
    
    -- Test jump mechanics
    calculateJumpVelocity = function()
        local vx, vy = GameLogic.calculateJumpVelocity(150, 100, 100, 100, 300, 0, 0)
        TestFramework.utils.assertEqual(300, vx, "Should jump away from planet horizontally")
        TestFramework.utils.assertEqual(0, vy, "No vertical component for horizontal jump")
        
        -- With tangent velocity
        local vx2, vy2 = GameLogic.calculateJumpVelocity(150, 100, 100, 100, 300, 50, 0)
        TestFramework.utils.assertEqual(350, vx2, "Should add tangent velocity")
        TestFramework.utils.assertEqual(0, vy2, "No vertical component")
    end,
    
    calculateTangentVelocity = function()
        local vx, vy = GameLogic.calculateTangentVelocity(0, 1, 50)
        TestFramework.utils.assertEqual(0, vx, "No horizontal component at angle 0")
        TestFramework.utils.assertEqual(50, vy, "Should have vertical component")
        
        local vx2, vy2 = GameLogic.calculateTangentVelocity(math.pi/2, 1, 50)
        TestFramework.utils.assertEqual(-50, vx2, "Should have negative horizontal component")
        TestFramework.utils.assertTrue(math.abs(vy2) < 0.001, "No vertical component at π/2")
    end,
    
    -- Test speed boost
    applySpeedBoost = function()
        local vx, vy = GameLogic.applySpeedBoost(100, 0, 2.0)
        TestFramework.utils.assertEqual(200, vx, "Should double horizontal speed")
        TestFramework.utils.assertEqual(0, vy, "Should preserve vertical speed")
        
        local vx2, vy2 = GameLogic.applySpeedBoost(100, 100, 0.5)
        TestFramework.utils.assertEqual(50, vx2, "Should halve horizontal speed")
        TestFramework.utils.assertEqual(50, vy2, "Should halve vertical speed")
    end,
    
    ["applySpeedBoost with zero velocity"] = function()
        local vx, vy = GameLogic.applySpeedBoost(0, 0, 2.0)
        TestFramework.utils.assertEqual(0, vx, "Should preserve zero velocity")
        TestFramework.utils.assertEqual(0, vy, "Should preserve zero velocity")
    end,
    
    -- Test bounds checking
    isOutOfBounds = function()
        TestFramework.utils.assertTrue(GameLogic.isOutOfBounds(-150, 100, 800, 600), "Should be out of bounds left")
        TestFramework.utils.assertTrue(GameLogic.isOutOfBounds(950, 100, 800, 600), "Should be out of bounds right")
        TestFramework.utils.assertTrue(GameLogic.isOutOfBounds(100, -150, 800, 600), "Should be out of bounds top")
        TestFramework.utils.assertTrue(GameLogic.isOutOfBounds(100, 750, 800, 600), "Should be out of bounds bottom")
        TestFramework.utils.assertFalse(GameLogic.isOutOfBounds(400, 300, 800, 600), "Should be in bounds")
    end,
    
    -- Test progression system integration
    calculateComboBonus = function()
        local bonus = GameLogic.calculateComboBonus(5, nil)
        TestFramework.utils.assertEqual(35, bonus, "Should calculate base combo bonus")
        
        -- Test with progression system (mock)
        local mockProgression = {
            getUpgradeMultiplier = function() return 2.0 end
        }
        local bonus2 = GameLogic.calculateComboBonus(5, mockProgression)
        TestFramework.utils.assertEqual(70, bonus2, "Should apply progression multiplier")
    end,
    
    calculateSpeedBoost = function()
        local boost = GameLogic.calculateSpeedBoost(3, nil)
        TestFramework.utils.assertEqual(1.3, boost, "Should calculate base speed boost")
        
        -- Test with progression system (mock)
        local mockProgression = {
            getUpgradeMultiplier = function() return 1.5 end
        }
        local boost2 = GameLogic.calculateSpeedBoost(3, mockProgression)
        TestFramework.utils.assertTrue(math.abs(boost2 - 1.95) < 0.001, "Should apply progression multiplier")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runSuite("Game Logic Tests", tests)
end

return {run = run}