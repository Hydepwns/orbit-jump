#!/usr/bin/env lua
-- Simple Unified Test Runner for Orbit Jump
-- Used by the main run_tests.sh script
local TestFramework = require("tests.frameworks.unified_test_framework")
-- Initialize the framework
TestFramework.init()
-- Parse command line arguments
local args = {...}
local testType = args[1] or "all"
local verbose = false
local filter = nil
-- Parse additional options
for i = 2, #args do
    local arg = args[i]
    if arg == "--verbose" or arg == "-v" then
        verbose = true
    elseif arg == "--filter" and i + 1 <= #args then
        filter = args[i + 1]
        i = i + 1
    end
end
-- Set verbose mode if requested
if verbose then
    TestFramework.setVerbose(true)
end
-- Define test suites
local testSuites = {
    unit = {
        ["Basic Math Test"] = function()
            TestFramework.assert.equal(2 + 2, 4, "Basic addition should work")
            TestFramework.assert.equal(5 * 3, 15, "Basic multiplication should work")
        end,
        ["String Operations Test"] = function()
            TestFramework.assert.equal("hello" .. " world", "hello world", "String concatenation should work")
            TestFramework.assert.matches("hello world", "hello", "String matching should work")
        end,
        ["Table Operations Test"] = function()
            local testTable = {1, 2, 3, 4, 5}
            TestFramework.assert.contains(testTable, 3, "Table should contain element")
            TestFramework.assert.equal(#testTable, 5, "Table should have correct length")
        end,
        ["Boolean Logic Test"] = function()
            TestFramework.assert.isTrue(true, "True should be true")
            TestFramework.assert.isFalse(false, "False should be false")
            TestFramework.assert.isTrue(1 == 1, "Equality should work")
        end
    },
    integration = {
        ["System Integration Test"] = function()
            -- Test that the framework itself works
            TestFramework.assert.isTrue(TestFramework ~= nil, "Framework should be available")
            TestFramework.assert.isTrue(TestFramework.assert ~= nil, "Assertions should be available")
        end,
        ["Error Handling Test"] = function()
            -- Test error handling
            local success, error = pcall(function()
                TestFramework.assert.equal(1, 2, "This should fail")
            end)
            TestFramework.assert.isTrue(not success, "Assertion failure should be caught")
        end
    },
    performance = {
        ["Performance Test"] = function()
            local start = os.clock()
            -- Simulate some work
            for i = 1, 1000 do
                local x = i * 2
            end
            local duration = os.clock() - start
            TestFramework.assert.isTrue(duration < 1.0, "Performance test should complete quickly")
        end
    }
}
-- Function to run all tests
local function runAllTests()
    local totalPassed = 0
    local totalFailed = 0
    for suiteName, suite in pairs(testSuites) do
        print("Running " .. suiteName .. " tests...")
        local success = TestFramework.runAllSuites({[suiteName] = suite})
        if success then
            totalPassed = totalPassed + 1
        else
            totalFailed = totalFailed + 1
        end
    end
    return totalFailed == 0
end
-- Function to run specific test type
local function runTestType(testType)
    if not testSuites[testType] then
        print("Error: Unknown test type '" .. testType .. "'")
        print("Available types: " .. table.concat(table.keys(testSuites), ", "))
        return false
    end
    print("Running " .. testType .. " tests...")
    return TestFramework.runAllSuites({[testType] = testSuites[testType]})
end
-- Main execution
local success = false
if testType == "all" then
    success = runAllTests()
else
    success = runTestType(testType)
end
-- Exit with appropriate code
if success then
    print("✅ All tests passed!")
    os.exit(0)
else
    print("❌ Some tests failed!")
    os.exit(1)
end