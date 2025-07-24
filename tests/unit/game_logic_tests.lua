-- Modern Game Logic Tests
-- Tests for core game mechanics and calculations

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")
local GameLogic = Utils.require("src.core.game_logic")

local tests = {
    -- Distance calculations
    ["should calculate distance correctly"] = function()
        local distance, dx, dy = GameLogic.calculateDistance(0, 0, 3, 4)
        ModernTestFramework.assert.equal(5, distance, "Distance should be 5 for 3-4-5 triangle")
        ModernTestFramework.assert.equal(3, dx, "Delta X should be 3")
        ModernTestFramework.assert.equal(4, dy, "Delta Y should be 4")
    end,
    
    ["should handle negative coordinates"] = function()
        local distance = GameLogic.calculateDistance(-1, -1, 2, 2)
        ModernTestFramework.assert.approx(4.2426406871193, distance, 0.0001, "Distance should be sqrt(18) for diagonal")
    end,
    
    ["should handle nil inputs gracefully"] = function()
        local distance = GameLogic.calculateDistance(nil, 0, 3, 4)
        ModernTestFramework.assert.equal(0, distance, "Should return 0 for nil inputs")
    end,
    
    -- Vector normalization
    ["should normalize vectors correctly"] = function()
        local nx, ny = GameLogic.normalizeVector(3, 4)
        ModernTestFramework.assert.approx(0.6, nx, 0.001, "Normalized X should be 0.6")
        ModernTestFramework.assert.approx(0.8, ny, 0.001, "Normalized Y should be 0.8")
    end,
    
    ["should handle zero vector"] = function()
        local nx, ny = GameLogic.normalizeVector(0, 0)
        ModernTestFramework.assert.equal(0, nx, "Zero vector X should be 0")
        ModernTestFramework.assert.equal(0, ny, "Zero vector Y should be 0")
    end,
    
    ["should handle nil inputs"] = function()
        local nx, ny = GameLogic.normalizeVector(nil, 4)
        ModernTestFramework.assert.equal(0, nx, "Nil input X should be 0")
        ModernTestFramework.assert.equal(0, ny, "Nil input Y should be 0")
    end,
    
    -- Gravity calculations
    ["should calculate gravity correctly"] = function()
        local gx, gy = GameLogic.calculateGravity(100, 100, 400, 300, 50, 1.0)
        ModernTestFramework.assert.isTrue(gx ~= 0, "Gravity X should not be zero")
        ModernTestFramework.assert.isTrue(gy ~= 0, "Gravity Y should not be zero")
    end,
    
    ["should return zero gravity inside planet"] = function()
        local gx, gy = GameLogic.calculateGravity(400, 300, 400, 300, 50, 1.0)
        ModernTestFramework.assert.equal(0, gx, "Gravity X should be zero inside planet")
        ModernTestFramework.assert.equal(0, gy, "Gravity Y should be zero inside planet")
    end,
    
    -- Orbit calculations
    ["should calculate orbit position at angle 0"] = function()
        local x, y = GameLogic.calculateOrbitPosition(400, 300, 0, 50)
        ModernTestFramework.assert.equal(450, x, "X should be center + radius at angle 0")
        ModernTestFramework.assert.equal(300, y, "Y should be center at angle 0")
    end,
    
    ["should calculate orbit position at angle π/2"] = function()
        local x, y = GameLogic.calculateOrbitPosition(400, 300, math.pi/2, 50)
        ModernTestFramework.assert.equal(400, x, "X should be center at angle π/2")
        ModernTestFramework.assert.equal(350, y, "Y should be center + radius at angle π/2")
    end,
    
    -- Collision detection
    ["should detect ring collision when player passes through"] = function()
        local collision = GameLogic.checkRingCollision(520, 300, 15, 500, 300, 30, 5)
        ModernTestFramework.assert.isTrue(collision, "Should detect collision when player is within ring")
    end,
    
    ["should not detect ring collision when too far"] = function()
        local collision = GameLogic.checkRingCollision(600, 300, 15, 500, 300, 30, 5)
        ModernTestFramework.assert.isFalse(collision, "Should not detect collision when player is too far")
    end,
    
    ["should not detect collision in center hole"] = function()
        local collision = GameLogic.checkRingCollision(500, 300, 15, 500, 300, 30, 5)
        ModernTestFramework.assert.isFalse(collision, "Should not detect collision in center hole")
    end,
    
    ["should detect planet collision when touching"] = function()
        local collision = GameLogic.checkPlanetCollision(450, 300, 10, 400, 300, 50)
        ModernTestFramework.assert.isTrue(collision, "Should detect collision when touching planet")
    end,
    
    ["should not detect planet collision when far"] = function()
        local collision = GameLogic.checkPlanetCollision(500, 300, 10, 400, 300, 50)
        ModernTestFramework.assert.isFalse(collision, "Should not detect collision when far from planet")
    end,
    
    -- Jump mechanics
    ["should calculate jump velocity correctly"] = function()
        local vx, vy = GameLogic.calculateJumpVelocity(400, 300, 450, 250, 300, 50, 25)
        ModernTestFramework.assert.isTrue(vx ~= 0, "Jump velocity X should not be zero")
        ModernTestFramework.assert.isTrue(vy ~= 0, "Jump velocity Y should not be zero")
    end,
    
    ["should add tangent velocity to jump"] = function()
        local vx, vy = GameLogic.calculateJumpVelocity(400, 300, 450, 250, 300, 50, 25)
        local speed = math.sqrt(vx*vx + vy*vy)
        ModernTestFramework.assert.approx(287.26, speed, 1, "Jump speed should be approximately 287.26")
    end,
    
    ["should calculate tangent velocity"] = function()
        local tx, ty = GameLogic.calculateTangentVelocity(400, 300, 0.5)
        ModernTestFramework.assert.isTrue(tx ~= 0, "Tangent velocity X should not be zero")
        ModernTestFramework.assert.isTrue(ty ~= 0, "Tangent velocity Y should not be zero")
    end,
    
    -- Speed boost
    ["should apply speed boost correctly"] = function()
        local vx, vy = GameLogic.applySpeedBoost(100, 100, 2.0)
        ModernTestFramework.assert.equal(200, vx, "Speed boost should double X velocity")
        ModernTestFramework.assert.equal(200, vy, "Speed boost should double Y velocity")
    end,
    
    ["should handle fractional boosts"] = function()
        local vx, vy = GameLogic.applySpeedBoost(100, 100, 1.5)
        ModernTestFramework.assert.equal(150, vx, "Speed boost should multiply X velocity by 1.5")
        ModernTestFramework.assert.equal(150, vy, "Speed boost should multiply Y velocity by 1.5")
    end,
    
    ["should preserve zero velocity"] = function()
        local vx, vy = GameLogic.applySpeedBoost(0, 0, 2.0)
        ModernTestFramework.assert.equal(0, vx, "Zero velocity should remain zero")
        ModernTestFramework.assert.equal(0, vy, "Zero velocity should remain zero")
    end,
    
    -- Bounds checking
    ["should detect out of bounds correctly"] = function()
        local outOfBounds = GameLogic.isOutOfBounds(1000, 1000, 800, 600, 100)
        ModernTestFramework.assert.isTrue(outOfBounds, "Should detect out of bounds")
    end,
    
    -- Progression integration
    ["should calculate combo bonus without progression"] = function()
        local bonus = GameLogic.calculateComboBonus(5, nil)
        ModernTestFramework.assert.isTrue(bonus > 0, "Combo bonus should be positive")
    end,
    
    ["should apply progression multiplier to combo bonus"] = function()
        local progression = {
            getUpgradeMultiplier = function(upgrade)
                if upgrade == "comboMultiplier" then
                    return 2.0
                end
                return 1.0
            end
        }
        local bonus = GameLogic.calculateComboBonus(5, progression)
        ModernTestFramework.assert.isTrue(bonus > 0, "Progression combo bonus should be positive")
    end,
    
    ["should calculate speed boost without progression"] = function()
        local boost = GameLogic.calculateSpeedBoost(3, nil)
        ModernTestFramework.assert.isTrue(boost > 0, "Speed boost should be positive")
    end,
    
    ["should apply progression multiplier to speed boost"] = function()
        local progression = {
            getUpgradeMultiplier = function(upgrade)
                if upgrade == "speedBoost" then
                    return 1.5
                end
                return 1.0
            end
        }
        local boost = GameLogic.calculateSpeedBoost(3, progression)
        ModernTestFramework.assert.isTrue(boost > 0, "Progression speed boost should be positive")
    end
}

return tests 