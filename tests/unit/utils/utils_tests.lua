-- Modern Utils Tests
-- Tests for utility functions

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")

local tests = {
  -- Math utilities
  ["should calculate distance correctly"] = function()
    local distance, dx, dy = Utils.distance(0, 0, 3, 4)
    ModernTestFramework.assert.equal(5, distance, "Distance should be 5 for 3-4-5 triangle")
    ModernTestFramework.assert.equal(3, dx, "Delta X should be 3")
    ModernTestFramework.assert.equal(4, dy, "Delta Y should be 4")
  end,

  ["should handle nil inputs in distance"] = function()
    local success, result = pcall(Utils.distance, nil, nil, 5, 5)
    ModernTestFramework.assert.isFalse(success, "Should fail for nil inputs")
  end,

  ["should normalize vectors correctly"] = function()
    local nx, ny = Utils.normalize(3, 4)
    ModernTestFramework.assert.approx(0.6, nx, 0.001, "Normalized X should be 0.6")
    ModernTestFramework.assert.approx(0.8, ny, 0.001, "Normalized Y should be 0.8")
  end,

  ["should handle zero vector in normalize"] = function()
    local nx, ny = Utils.normalize(0, 0)
    ModernTestFramework.assert.equal(0, nx, "Zero vector X should be 0")
    ModernTestFramework.assert.equal(0, ny, "Zero vector Y should be 0")
  end,

  ["should handle nil inputs in normalize"] = function()
    local nx, ny = Utils.normalize(nil, 4)
    ModernTestFramework.assert.equal(0, nx, "Nil input X should be 0")
    ModernTestFramework.assert.equal(0, ny, "Nil input Y should be 0")
  end,

  ["should clamp values correctly"] = function()
    ModernTestFramework.assert.equal(5, Utils.clamp(3, 5, 10), "Should clamp to minimum")
    ModernTestFramework.assert.equal(10, Utils.clamp(15, 5, 10), "Should clamp to maximum")
    ModernTestFramework.assert.equal(7, Utils.clamp(7, 5, 10), "Should not clamp value in range")
  end,

  ["should lerp values correctly"] = function()
    ModernTestFramework.assert.equal(5, Utils.lerp(0, 10, 0.5), "Should lerp to middle")
    ModernTestFramework.assert.equal(0, Utils.lerp(0, 10, 0), "Should lerp to start")
    ModernTestFramework.assert.equal(10, Utils.lerp(0, 10, 1), "Should lerp to end")
  end,

  ["should calculate angle between points"] = function()
    local angle = Utils.angleBetween(0, 0, 1, 0)
    ModernTestFramework.assert.approx(0, angle, 0.001, "Angle should be 0 for horizontal line")

    local angle2 = Utils.angleBetween(0, 0, 0, 1)
    ModernTestFramework.assert.approx(math.pi / 2, angle2, 0.001, "Angle should be π/2 for vertical line")
  end,

  ["should rotate points correctly"] = function()
    local x, y = Utils.rotatePoint(1, 0, 0, 0, math.pi / 2)
    ModernTestFramework.assert.approx(0, x, 0.001, "Rotated X should be 0")
    ModernTestFramework.assert.approx(1, y, 0.001, "Rotated Y should be 1")
  end,

  -- Vector utilities
  ["should calculate vector length"] = function()
    local length = Utils.vectorLength(3, 4)
    ModernTestFramework.assert.equal(5, length, "Vector length should be 5")
  end,

  ["should handle nil inputs in vector length"] = function()
    local length = Utils.vectorLength(nil, 4)
    ModernTestFramework.assert.equal(0, length, "Should return 0 for nil inputs")
  end,

  ["should scale vectors correctly"] = function()
    local x, y = Utils.vectorScale(3, 4, 2)
    ModernTestFramework.assert.equal(6, x, "Scaled X should be 6")
    ModernTestFramework.assert.equal(8, y, "Scaled Y should be 8")
  end,

  ["should handle nil inputs in vector scale"] = function()
    local x, y = Utils.vectorScale(nil, 4, 2)
    ModernTestFramework.assert.equal(0, x, "Should return 0 for nil inputs")
    ModernTestFramework.assert.equal(0, y, "Should return 0 for nil inputs")
  end,

  ["should add vectors correctly"] = function()
    local x, y = Utils.vectorAdd(1, 2, 3, 4)
    ModernTestFramework.assert.equal(4, x, "Sum X should be 4")
    ModernTestFramework.assert.equal(6, y, "Sum Y should be 6")
  end,

  ["should subtract vectors correctly"] = function()
    local x, y = Utils.vectorSubtract(5, 6, 2, 3)
    ModernTestFramework.assert.equal(3, x, "Difference X should be 3")
    ModernTestFramework.assert.equal(3, y, "Difference Y should be 3")
  end,

  -- Random utilities
  ["should generate random float in range"] = function()
    local value = Utils.randomFloat(0, 1)
    ModernTestFramework.assert.isTrue(value >= 0, "Random value should be >= 0")
    ModernTestFramework.assert.isTrue(value <= 1, "Random value should be <= 1")
  end,

  -- Module loading
  ["should cache modules correctly"] = function()
    local module1 = Utils.require("src.utils.config")
    local module2 = Utils.require("src.utils.config")
    ModernTestFramework.assert.equal(module1, module2, "Should return same module instance")
  end,

  ["should clear module cache"] = function()
    local module1 = Utils.require("src.utils.constants")
    Utils.clearModuleCache()
    local module2 = Utils.require("src.utils.constants")

    ModernTestFramework.assert.equal(module1, module2, "Should return same instance after cache clear")
  end,

  -- Color utilities
  ["should set color correctly"] = function()
    ModernTestFramework.utils.resetCalls()

    Utils.setColor(1, 0, 0, 1)

    ModernTestFramework.assert.called("setColor", 1, "Should call setColor")
  end,

  -- Number formatting
  ["should format numbers correctly"] = function()
    local formatted = Utils.formatNumber(1500)
    ModernTestFramework.assert.equal("1.5K", formatted, "Should format thousands with K")

    local formatted2 = Utils.formatNumber(500)
    ModernTestFramework.assert.equal("500", formatted2, "Should not format numbers under 1000")
  end,

  -- Object pool
  ["should create object pool"] = function()
    local createFunc = function() return { id = 1 } end
    local resetFunc = function(obj) obj.id = 1 end
    local pool = Utils.ObjectPool.new(createFunc, resetFunc)

    ModernTestFramework.assert.notNil(pool, "Should create pool")
    ModernTestFramework.assert.notNil(pool.acquire, "Should have acquire method")
    ModernTestFramework.assert.notNil(pool.release, "Should have release method")
  end,

  ["should acquire objects from pool"] = function()
    local createFunc = function() return { id = 1 } end
    local resetFunc = function(obj) obj.id = 1 end
    local pool = Utils.ObjectPool.new(createFunc, resetFunc)

    local obj = pool:acquire()
    ModernTestFramework.assert.notNil(obj, "Should acquire object")
    ModernTestFramework.assert.equal(1, obj.id, "Should have correct object data")
  end,

  ["should release objects to pool"] = function()
    local createFunc = function() return { id = 1 } end
    local resetFunc = function(obj) obj.id = 1 end
    local pool = Utils.ObjectPool.new(createFunc, resetFunc)

    local obj = pool:acquire()
    pool:release(obj)

    -- Should be able to acquire again
    local obj2 = pool:acquire()
    ModernTestFramework.assert.notNil(obj2, "Should be able to acquire released object")
  end,

  -- Error handling
  ["should handle safe function calls"] = function()
    local success, result = Utils.ErrorHandler.safeCall(function() return "success" end)
    ModernTestFramework.assert.isTrue(success, "Should succeed for valid function")
    ModernTestFramework.assert.equal("success", result, "Should return function result")
  end,

  ["should handle safe function calls with errors"] = function()
    local success, err = Utils.ErrorHandler.safeCall(function() error("test error") end)
    ModernTestFramework.assert.isFalse(success, "Should fail for error function")
    ModernTestFramework.assert.notNil(err, "Should return error message")
  end,

  -- Logger
  ["should have logger functions"] = function()
    ModernTestFramework.assert.notNil(Utils.Logger.info, "Should have info function")
    ModernTestFramework.assert.notNil(Utils.Logger.warn, "Should have warn function")
    ModernTestFramework.assert.notNil(Utils.Logger.error, "Should have error function")
    ModernTestFramework.assert.notNil(Utils.Logger.debug, "Should have debug function")
  end,

  ["should have logger levels"] = function()
    ModernTestFramework.assert.notNil(Utils.Logger.levels.DEBUG, "Should have DEBUG level")
    ModernTestFramework.assert.notNil(Utils.Logger.levels.INFO, "Should have INFO level")
    ModernTestFramework.assert.notNil(Utils.Logger.levels.WARN, "Should have WARN level")
    ModernTestFramework.assert.notNil(Utils.Logger.levels.ERROR, "Should have ERROR level")
  end,

  -- Compatibility
  ["should have atan2 compatibility"] = function()
    local angle = Utils.atan2(1, 0)
    ModernTestFramework.assert.approx(math.pi / 2, angle, 0.001, "atan2 should work correctly")
  end,

  -- Edge cases
  ["should handle extreme values in clamp"] = function()
    ModernTestFramework.assert.equal(5, Utils.clamp(-1000, 5, 10), "Should clamp extreme negative")
    ModernTestFramework.assert.equal(10, Utils.clamp(1000, 5, 10), "Should clamp extreme positive")
  end,

  ["should handle zero range in lerp"] = function()
    local result = Utils.lerp(5, 5, 0.5)
    ModernTestFramework.assert.equal(5, result, "Should handle zero range")
  end,

  ["should handle negative scale in vector scale"] = function()
    local x, y = Utils.vectorScale(3, 4, -2)
    ModernTestFramework.assert.equal(-6, x, "Should handle negative scale")
    ModernTestFramework.assert.equal(-8, y, "Should handle negative scale")
  end
}

return tests
