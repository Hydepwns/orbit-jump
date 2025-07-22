-- Unit tests for game logic
package.path = package.path .. ";../?.lua"

local TestFramework = require("tests.test_framework")
local GameLogic = require("game_logic")

local test = TestFramework:new()

-- Test distance calculations
test:describe("calculateDistance", function(t)
    local dist, dx, dy = GameLogic.calculateDistance(0, 0, 3, 4)
    t:assertEquals(dist, 5, "Should calculate distance correctly")
    t:assertEquals(dx, 3, "Should calculate dx correctly")
    t:assertEquals(dy, 4, "Should calculate dy correctly")
end)

test:describe("calculateDistance with negative coordinates", function(t)
    local dist, dx, dy = GameLogic.calculateDistance(-1, -1, 2, 3)
    t:assertAlmostEquals(dist, 5, 0.001, "Should handle negative coordinates")
    t:assertEquals(dx, 3, "Should calculate dx with negatives")
    t:assertEquals(dy, 4, "Should calculate dy with negatives")
end)

-- Test vector normalization
test:describe("normalizeVector", function(t)
    local nx, ny = GameLogic.normalizeVector(3, 4)
    t:assertAlmostEquals(nx, 0.6, 0.001, "Should normalize x component")
    t:assertAlmostEquals(ny, 0.8, 0.001, "Should normalize y component")
    
    -- Test magnitude
    local mag = math.sqrt(nx*nx + ny*ny)
    t:assertAlmostEquals(mag, 1.0, 0.001, "Normalized vector should have magnitude 1")
end)

test:describe("normalizeVector with zero vector", function(t)
    local nx, ny = GameLogic.normalizeVector(0, 0)
    t:assertEquals(nx, 0, "Zero vector should return 0 for x")
    t:assertEquals(ny, 0, "Zero vector should return 0 for y")
end)

-- Test gravity calculations
test:describe("calculateGravity", function(t)
    local gx, gy = GameLogic.calculateGravity(100, 100, 200, 100, 50)
    t:assertTrue(gx > 0, "Gravity should pull right towards planet")
    t:assertAlmostEquals(gy, 0, 0.001, "No vertical gravity component")
    
    -- Test gravity strength decreases with distance
    local gx2, gy2 = GameLogic.calculateGravity(100, 100, 300, 100, 50)
    t:assertTrue(gx2 < gx, "Gravity should be weaker at greater distance")
end)

test:describe("calculateGravity inside planet", function(t)
    local gx, gy = GameLogic.calculateGravity(100, 100, 100, 100, 50)
    t:assertEquals(gx, 0, "No gravity inside planet")
    t:assertEquals(gy, 0, "No gravity inside planet")
end)

-- Test orbit calculations
test:describe("calculateOrbitPosition", function(t)
    local x, y = GameLogic.calculateOrbitPosition(100, 100, 0, 50)
    t:assertAlmostEquals(x, 150, 0.001, "Should calculate x position at angle 0")
    t:assertAlmostEquals(y, 100, 0.001, "Should calculate y position at angle 0")
    
    local x2, y2 = GameLogic.calculateOrbitPosition(100, 100, math.pi/2, 50)
    t:assertAlmostEquals(x2, 100, 0.001, "Should calculate x position at angle π/2")
    t:assertAlmostEquals(y2, 150, 0.001, "Should calculate y position at angle π/2")
end)

-- Test collision detection
test:describe("checkRingCollision", function(t)
    -- Player passing through ring (at edge)
    local hit = GameLogic.checkRingCollision(125, 100, 10, 100, 100, 30, 20)
    t:assertTrue(hit, "Should detect collision when player in ring")
    
    -- Player too far
    local miss = GameLogic.checkRingCollision(200, 100, 10, 100, 100, 30, 20)
    t:assertFalse(miss, "Should not detect collision when too far")
    
    -- Player in center hole
    local inHole = GameLogic.checkRingCollision(100, 100, 5, 100, 100, 30, 20)
    t:assertFalse(inHole, "Should not detect collision in center hole")
end)

test:describe("checkPlanetCollision", function(t)
    -- Player touching planet
    local hit = GameLogic.checkPlanetCollision(150, 100, 10, 100, 100, 50)
    t:assertTrue(hit, "Should detect collision when touching")
    
    -- Player far from planet
    local miss = GameLogic.checkPlanetCollision(200, 100, 10, 100, 100, 50)
    t:assertFalse(miss, "Should not detect collision when far")
end)

-- Test jump mechanics
test:describe("calculateJumpVelocity", function(t)
    local vx, vy = GameLogic.calculateJumpVelocity(150, 100, 100, 100, 300, 0, 0)
    t:assertAlmostEquals(vx, 300, 0.001, "Should jump away from planet horizontally")
    t:assertAlmostEquals(vy, 0, 0.001, "No vertical component for horizontal jump")
    
    -- With tangent velocity
    local vx2, vy2 = GameLogic.calculateJumpVelocity(150, 100, 100, 100, 300, 0, 50)
    t:assertEquals(vx2, 300, "Horizontal jump velocity unchanged")
    t:assertEquals(vy2, 50, "Should include tangent velocity")
end)

test:describe("calculateTangentVelocity", function(t)
    local tx, ty = GameLogic.calculateTangentVelocity(0, 1, 50)
    t:assertAlmostEquals(tx, 0, 0.001, "No x tangent at angle 0")
    t:assertAlmostEquals(ty, 50, 0.001, "Full y tangent at angle 0")
    
    local tx2, ty2 = GameLogic.calculateTangentVelocity(math.pi/2, 1, 50)
    t:assertAlmostEquals(tx2, -50, 0.001, "Negative x tangent at angle π/2")
    t:assertAlmostEquals(ty2, 0, 0.001, "No y tangent at angle π/2")
end)

-- Test speed boost mechanics
test:describe("applySpeedBoost", function(t)
    local vx, vy = GameLogic.applySpeedBoost(100, 0, 1.5)
    t:assertAlmostEquals(vx, 150, 0.001, "Should boost horizontal speed")
    t:assertEquals(vy, 0, "Should maintain direction")
    
    -- Test with diagonal velocity
    local vx2, vy2 = GameLogic.applySpeedBoost(30, 40, 2.0)
    local originalSpeed = 50 -- 3-4-5 triangle
    local newSpeed = math.sqrt(vx2*vx2 + vy2*vy2)
    t:assertAlmostEquals(newSpeed, 100, 0.001, "Should double the speed")
end)

test:describe("applySpeedBoost with zero velocity", function(t)
    local vx, vy = GameLogic.applySpeedBoost(0, 0, 2.0)
    t:assertEquals(vx, 0, "Zero velocity remains zero")
    t:assertEquals(vy, 0, "Zero velocity remains zero")
end)

-- Test boundary checking
test:describe("isOutOfBounds", function(t)
    t:assertFalse(GameLogic.isOutOfBounds(400, 300, 800, 600), "Should be in bounds")
    t:assertTrue(GameLogic.isOutOfBounds(-101, 300, 800, 600), "Should be out left")
    t:assertTrue(GameLogic.isOutOfBounds(901, 300, 800, 600), "Should be out right")
    t:assertTrue(GameLogic.isOutOfBounds(400, -101, 800, 600), "Should be out top")
    t:assertTrue(GameLogic.isOutOfBounds(400, 701, 800, 600), "Should be out bottom")
    
    -- Test custom margin
    t:assertFalse(GameLogic.isOutOfBounds(-50, 300, 800, 600, 50), "Should be in bounds with margin")
    t:assertTrue(GameLogic.isOutOfBounds(-51, 300, 800, 600, 50), "Should be out with margin")
end)

-- Test scoring mechanics
test:describe("calculateComboBonus", function(t)
    t:assertEquals(GameLogic.calculateComboBonus(0), 10, "Base bonus with no combo")
    t:assertEquals(GameLogic.calculateComboBonus(1), 15, "Bonus with combo 1")
    t:assertEquals(GameLogic.calculateComboBonus(5), 35, "Bonus with combo 5")
end)

test:describe("calculateSpeedBoost", function(t)
    t:assertEquals(GameLogic.calculateSpeedBoost(0), 1.0, "No boost with no combo")
    t:assertAlmostEquals(GameLogic.calculateSpeedBoost(1), 1.1, 0.001, "10% boost per combo")
    t:assertAlmostEquals(GameLogic.calculateSpeedBoost(5), 1.5, 0.001, "50% boost at combo 5")
end)

-- Run all tests
return test