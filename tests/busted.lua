-- Busted-style test framework for Orbit Jump
-- Provides a simple testing framework similar to Busted

local Utils = require("src.utils.utils")

-- BustedLite table
local BustedLite = {}

-- Test state
local suites = {}
local currentSuite = nil
local results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
}

-- ANSI color codes
local colors = {
    green = "\27[32m",
    red = "\27[31m",
    yellow = "\27[33m",
    reset = "\27[0m"
}

-- Helper to print colored text
local function printColored(color, text)
    Utils.Logger.output(colors[color] .. text .. colors.reset)
end

-- Comprehensive Test Assertions (Enhanced from ModernTestFramework)
local assert = {}

-- Basic assertions
function assert.equals(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s\nExpected: %s\nActual: %s", 
            message or "Values not equal", tostring(expected), tostring(actual)), 2)
    end
end

function assert.equal(expected, actual, message)
    return assert.equals(expected, actual, message)
end

function assert.not_equal(expected, actual, message)
    if expected == actual then
        error(string.format("Assertion failed: expected not %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""), 2)
    end
end

function assert.is_true(value, message)
    if not value then
        error(message or "Expected true, got " .. tostring(value), 2)
    end
end

function assert.is_false(value, message)
    if value then
        error(message or "Expected false, got " .. tostring(value), 2)
    end
end

function assert.is_nil(value, message)
    if value ~= nil then
        error(message or "Expected nil, got " .. tostring(value), 2)
    end
end

function assert.is_not_nil(value, message)
    if value == nil then
        error(message or "Expected non-nil value", 2)
    end
end

-- Type assertions
function assert.is_type(expectedType, value, message)
    if type(value) ~= expectedType then
        error(string.format("Assertion failed: expected type %s, got %s. %s", 
            expectedType, type(value), message or ""), 2)
    end
end

-- Numeric comparisons
function assert.greater_than(expected, actual, message)
    if actual <= expected then
        error(string.format("Assertion failed: expected > %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""), 2)
    end
end

function assert.less_than(expected, actual, message)
    if actual >= expected then
        error(string.format("Assertion failed: expected < %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""), 2)
    end
end

function assert.greater_or_equal(expected, actual, message)
    if actual < expected then
        error(string.format("Assertion failed: expected >= %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""), 2)
    end
end

function assert.less_or_equal(expected, actual, message)
    if actual > expected then
        error(string.format("Assertion failed: expected <= %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""), 2)
    end
end

-- Approximate equality for floating point
function assert.near(expected, actual, tolerance, message)
    tolerance = tolerance or 0.001
    if math.abs(expected - actual) > tolerance then
        error(string.format("Assertion failed: expected %f ± %f, got %f. %s", 
            expected, tolerance, actual, message or ""), 2)
    end
end

-- String assertions
function assert.matches(actual, pattern, message)
    if not string.match(actual, pattern) then
        error(string.format("Assertion failed: expected '%s' to match pattern '%s'. %s", 
            actual, pattern, message or ""), 2)
    end
end

function assert.contains(haystack, needle, message)
    if not string.find(haystack, needle, 1, true) then
        error(string.format("Assertion failed: expected '%s' to contain '%s'. %s", 
            haystack, needle, message or ""), 2)
    end
end

-- Collection assertions
function assert.is_empty(collection, message)
    if type(collection) == "table" then
        for k, v in pairs(collection) do
            error(string.format("Assertion failed: expected empty table, but found key %s with value %s. %s", 
                tostring(k), tostring(v), message or ""), 2)
        end
    elseif type(collection) == "string" then
        if #collection > 0 then
            error(string.format("Assertion failed: expected empty string, got '%s'. %s", 
                collection, message or ""), 2)
        end
    else
        error(string.format("Assertion failed: cannot check emptiness of type %s. %s", 
            type(collection), message or ""), 2)
    end
end

-- Error testing
function assert.has_error(fn, message)
    local success = Utils.ErrorHandler.safeCall(fn)
    if success then
        error(message or "Expected function to throw error", 2)
    end
end

function assert.has_no_error(fn, message)
    local success, err = Utils.ErrorHandler.safeCall(fn)
    if not success then
        error(string.format("%s\nUnexpected error: %s", message or "Expected no error", err), 2)
    end
end

-- Deep table comparison
function assert.are_same(expected, actual, message)
    local function deepEquals(a, b)
        if type(a) ~= type(b) then return false end
        if type(a) ~= "table" then return a == b end
        
        for k, v in pairs(a) do
            if not deepEquals(v, b[k]) then return false end
        end
        for k, v in pairs(b) do
            if not deepEquals(v, a[k]) then return false end
        end
        return true
    end
    
    if not deepEquals(expected, actual) then
        error(string.format("%s\nExpected: %s\nActual: %s", 
            message or "Tables not equal", tostring(expected), tostring(actual)), 2)
    end
end

-- Table structure assertions
function assert.same(expected, actual, message)
    return assert.are_same(expected, actual, message)
end

-- Spy/Mock functionality
local function spy(fn)
    local spyData = {
        calls = {},
        callCount = 0
    }
    
    local spyFn = function(...)
        spyData.callCount = spyData.callCount + 1
        table.insert(spyData.calls, {...})
        if fn then
            return fn(...)
        end
    end
    
    -- Create a metatable to allow accessing spy properties
    local mt = {
        __index = function(t, k)
            if k == "calls" then
                return spyData.calls
            elseif k == "callCount" then
                return function() return spyData.callCount end
            elseif k == "reset" then
                return function()
                    spyData.calls = {}
                    spyData.callCount = 0
                end
            end
        end,
        __call = function(t, ...)
            return spyFn(...)
        end
    }
    
    return setmetatable({}, mt)
end

-- Test definition functions
function describe(name, fn)
    local suite = {
        name = name,
        tests = {},
        beforeEach = nil,
        afterEach = nil
    }
    
    currentSuite = suite
    table.insert(suites, suite)
    
    -- Execute the describe block to collect tests
    fn()
    
    currentSuite = nil
end

function it(name, fn)
    if not currentSuite then
        error("'it' must be called inside a 'describe' block")
    end
    
    table.insert(currentSuite.tests, {
        name = name,
        fn = fn
    })
end

function before_each(fn)
    if not currentSuite then
        error("'before_each' must be called inside a 'describe' block")
    end
    currentSuite.beforeEach = fn
end

function after_each(fn)
    if not currentSuite then
        error("'after_each' must be called inside a 'describe' block")
    end
    currentSuite.afterEach = fn
end

-- Enhanced test runner with setup/teardown support
local function runTest(testName, testFn, suite, testContext)
    local startTime = os.clock()
    local success, error = true, nil
    
    -- Reset mocks before each test
    local Mocks = Utils.require("tests.mocks")
    if Mocks and Mocks.reset then
        Mocks.reset()
    end
    
    -- Run beforeEach if defined
    if suite.beforeEach then
        success, error = Utils.ErrorHandler.safeCall(suite.beforeEach)
        if not success then
            local duration = os.clock() - startTime
            printColored("red", string.format("✗ %s (%.3fs) - Setup failed: %s", testName, duration, error))
            table.insert(results.errors, {name = testName, error = "Setup failed: " .. error})
            return false
        end
    end
    
    -- Run the actual test
    if success then
        success, error = Utils.ErrorHandler.safeCall(testFn)
    end
    
    -- Run afterEach if defined (even if test failed)
    if suite.afterEach then
        local teardownSuccess, teardownError = Utils.ErrorHandler.safeCall(suite.afterEach)
        if not teardownSuccess then
            if success then
                success = false
                error = "Teardown failed: " .. teardownError  
            else
                error = error .. " | Teardown failed: " .. teardownError
            end
        end
    end
    
    local duration = os.clock() - startTime
    
    if success then
        printColored("green", string.format("  ✓ %s (%.3fs)", testName, duration))
        results.passed = results.passed + 1
        return true
    else
        printColored("red", string.format("  ✗ %s (%.3fs)", testName, duration))
        printColored("red", string.format("    %s", error))
        table.insert(results.errors, {name = testName, error = error})
        results.failed = results.failed + 1
        return false
    end
end

-- Enhanced test suite runner
local function runSuite(suite)
    printColored("yellow", string.format("\n%s", suite.name))
    
    local suitePassed = 0
    local suiteFailed = 0
    
    for i, test in ipairs(suite.tests) do
        results.total = results.total + 1
        if runTest(test.name, test.fn, suite) then
            suitePassed = suitePassed + 1
        else
            suiteFailed = suiteFailed + 1
        end
    end
    
    -- Suite summary
    if #suite.tests > 0 then
        local suiteColor = suiteFailed == 0 and "green" or "red"
        printColored(suiteColor, string.format("  %d/%d tests passed", suitePassed, suitePassed + suiteFailed))
    end
    
    return suitePassed, suiteFailed
end

-- Enhanced report generator
local function generateReport(stats)
    print("\n" .. string.rep("=", 60))
    
    -- Overall results
    local successRate = stats.total > 0 and (stats.passed / stats.total * 100) or 0
    
    if stats.failed == 0 then
        printColored("green", "🎉 All tests passed!")
    else
        printColored("red", string.format("💥 %d tests failed!", stats.failed))
    end
    
    print(string.format("📊 Results: %d total | %d passed | %d failed (%.1f%% success)", 
        stats.total, stats.passed, stats.failed, successRate))
    print(string.format("⏱️  Time: %.3fs", stats.time))
    
    -- Detailed failure report
    if stats.failed > 0 and #stats.errors > 0 then
        printColored("red", "\n❌ Failed Tests:")
        for i, err in ipairs(stats.errors) do
            printColored("red", string.format("  %d. %s", i, err.name))
            print(string.format("     %s", err.error))
        end
    end
    
    print(string.rep("=", 60))
end

-- Reset function for running multiple test files
function BustedLite.reset()
    suites = {}
    currentSuite = nil
    results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
end

-- Run all test suites  
function BustedLite.run()
    local startTime = os.clock()
    
    -- Initialize results
    results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    printColored("yellow", "🚀 Running Busted-style Tests")
    printColored("yellow", string.rep("=", 50))
    
    -- Run all suites
    for _, suite in ipairs(suites) do
        runSuite(suite)
    end
    
    local endTime = os.clock()
    
    -- Generate final report
    local totalTime = endTime - startTime
    generateReport({
        total = results.total,
        passed = results.passed,
        failed = results.failed,
        time = totalTime,
        errors = results.errors
    })
    
    return results.failed == 0
end

-- Export global functions
_G.describe = describe
_G.it = it
_G.before_each = before_each
_G.after_each = after_each
_G.assert = assert
_G.spy = spy

return BustedLite