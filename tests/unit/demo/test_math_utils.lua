-- Demo test file for Phase 4 optimization demonstration
-- Tests simple math utility functions

package.path = package.path .. ";frameworks/?.lua"

local TestFramework = require("simple_test_framework")

-- Initialize test framework
TestFramework.init()

-- Mock math utilities for testing
local MathUtils = {
    add = function(a, b) return a + b end,
    subtract = function(a, b) return a - b end,
    multiply = function(a, b) return a * b end,
    divide = function(a, b) 
        if b == 0 then error("Division by zero") end
        return a / b 
    end,
    power = function(a, b) return a ^ b end,
    sqrt = function(a) 
        if a < 0 then error("Cannot take square root of negative number") end
        return math.sqrt(a) 
    end,
    clamp = function(value, min, max)
        if value < min then return min end
        if value > max then return max end
        return value
    end,
    lerp = function(a, b, t) return a + (b - a) * t end
}

-- Test suite
TestFramework.describe("Math Utilities", function()
    
    TestFramework.it("should add two numbers correctly", function()
        TestFramework.assert.equal(5, MathUtils.add(2, 3), "2 + 3 should equal 5")
        TestFramework.assert.equal(0, MathUtils.add(-1, 1), "-1 + 1 should equal 0")
        TestFramework.assert.equal(-5, MathUtils.add(-2, -3), "-2 + (-3) should equal -5")
    end)
    
    TestFramework.it("should subtract two numbers correctly", function()
        TestFramework.assert.equal(2, MathUtils.subtract(5, 3), "5 - 3 should equal 2")
        TestFramework.assert.equal(-2, MathUtils.subtract(1, 3), "1 - 3 should equal -2")
        TestFramework.assert.equal(0, MathUtils.subtract(5, 5), "5 - 5 should equal 0")
    end)
    
    TestFramework.it("should multiply two numbers correctly", function()
        TestFramework.assert.equal(6, MathUtils.multiply(2, 3), "2 * 3 should equal 6")
        TestFramework.assert.equal(-6, MathUtils.multiply(2, -3), "2 * (-3) should equal -6")
        TestFramework.assert.equal(0, MathUtils.multiply(5, 0), "5 * 0 should equal 0")
    end)
    
    TestFramework.it("should divide two numbers correctly", function()
        TestFramework.assert.equal(2, MathUtils.divide(6, 3), "6 / 3 should equal 2")
        TestFramework.assert.equal(0.5, MathUtils.divide(1, 2), "1 / 2 should equal 0.5")
        TestFramework.assert.equal(-2, MathUtils.divide(-6, 3), "-6 / 3 should equal -2")
    end)
    
    TestFramework.it("should handle division by zero", function()
        local success, error = pcall(function()
            MathUtils.divide(5, 0)
        end)
        TestFramework.assert.isFalse(success, "Division by zero should throw error")
        TestFramework.assert.notNil(error, "Error should not be nil")
    end)
    
    TestFramework.it("should calculate powers correctly", function()
        TestFramework.assert.equal(8, MathUtils.power(2, 3), "2^3 should equal 8")
        TestFramework.assert.equal(1, MathUtils.power(5, 0), "5^0 should equal 1")
        TestFramework.assert.equal(0.25, MathUtils.power(2, -2), "2^(-2) should equal 0.25")
    end)
    
    TestFramework.it("should calculate square roots correctly", function()
        TestFramework.assert.equal(3, MathUtils.sqrt(9), "sqrt(9) should equal 3")
        TestFramework.assert.equal(0, MathUtils.sqrt(0), "sqrt(0) should equal 0")
        TestFramework.assert.approx(1.414, MathUtils.sqrt(2), 0.001, "sqrt(2) should be approximately 1.414")
    end)
    
    TestFramework.it("should handle negative square roots", function()
        local success, error = pcall(function()
            MathUtils.sqrt(-1)
        end)
        TestFramework.assert.isFalse(success, "Square root of negative should throw error")
        TestFramework.assert.notNil(error, "Error should not be nil")
    end)
    
    TestFramework.it("should clamp values correctly", function()
        TestFramework.assert.equal(5, MathUtils.clamp(5, 0, 10), "5 should remain 5 when clamped to [0,10]")
        TestFramework.assert.equal(0, MathUtils.clamp(-5, 0, 10), "-5 should be clamped to 0")
        TestFramework.assert.equal(10, MathUtils.clamp(15, 0, 10), "15 should be clamped to 10")
        TestFramework.assert.equal(0, MathUtils.clamp(0, 0, 10), "0 should remain 0 when clamped to [0,10]")
        TestFramework.assert.equal(10, MathUtils.clamp(10, 0, 10), "10 should remain 10 when clamped to [0,10]")
    end)
    
    TestFramework.it("should interpolate values correctly", function()
        TestFramework.assert.equal(5, MathUtils.lerp(0, 10, 0.5), "lerp(0, 10, 0.5) should equal 5")
        TestFramework.assert.equal(0, MathUtils.lerp(0, 10, 0), "lerp(0, 10, 0) should equal 0")
        TestFramework.assert.equal(10, MathUtils.lerp(0, 10, 1), "lerp(0, 10, 1) should equal 10")
        TestFramework.assert.equal(2.5, MathUtils.lerp(0, 10, 0.25), "lerp(0, 10, 0.25) should equal 2.5")
    end)
    
end)

-- Print test summary
TestFramework.print_summary() 