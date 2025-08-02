-- Simple test for Unified Test Framework
-- This file tests the basic functionality of the unified framework

local Utils = require("src.utils.utils")
local UnifiedTestFramework = Utils.require("tests.unified_test_framework")

-- Initialize the framework
UnifiedTestFramework.init()

-- Simple test suite
local tests = {
    ["should pass basic assertion"] = function()
        UnifiedTestFramework.assert.equal(2 + 2, 4, "Basic math should work")
    end,
    
    ["should handle string comparison"] = function()
        UnifiedTestFramework.assert.equal("hello", "hello", "Strings should match")
    end,
    
    ["should handle boolean assertions"] = function()
        UnifiedTestFramework.assert.isTrue(true, "True should be true")
        UnifiedTestFramework.assert.isFalse(false, "False should be false")
    end
}

-- Run the tests using the unified framework
local allPassed = UnifiedTestFramework.runAllSuites({
    ["Simple Tests"] = tests
})

-- Exit with appropriate code
if allPassed then
    print("🎉 All unified framework tests passed!")
    os.exit(0)
else
    print("💥 Some unified framework tests failed!")
    os.exit(1)
end 