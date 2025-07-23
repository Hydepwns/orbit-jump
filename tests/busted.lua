-- Busted-style test framework for Orbit Jump
-- Provides a simple testing framework similar to Busted

local Utils = require("src.utils.utils")

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

-- Test assertions
local assert = {}

function assert.equals(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s\nExpected: %s\nActual: %s", 
            message or "Values not equal", tostring(expected), tostring(actual)), 2)
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

function assert.has_error(fn, message)
    local success = Utils.ErrorHandler.safeCall(fn)
    if success then
        error(message or "Expected function to throw error", 2)
    end
end

function assert.are_same(expected, actual, message)
    -- Deep comparison for tables
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

-- Test runner
local function runTest(testName, testFn)
    local startTime = os.clock()
    local success = Utils.ErrorHandler.safeCall(testFn)
    local duration = os.clock() - startTime
    
    if success then
        printColored("green", string.format("✓ %s (%.3fs)", testName, duration))
        return true
    else
        printColored("red", string.format("✗ %s (%.3fs) - %s", testName, duration, success))
        return false
    end
end

-- Test suite runner
local function runSuite(suiteName, tests)
    Utils.Logger.info("\n" .. suiteName)
    
    local passed = 0
    local failed = 0
    
    for testName, testFn in pairs(tests) do
        if runTest(testName, testFn) then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end
    
    return passed, failed
end

-- Report generator
local function generateReport(stats)
    Utils.Logger.info("\n" .. string.rep("=", 50))
    Utils.Logger.info(string.format("Total: %d | Passed: %d | Failed: %d | Time: %.3fs",
        stats.total, stats.passed, stats.failed, stats.time))
    
    if stats.failed > 0 then
        Utils.Logger.info("\nFailures:")
        for _, err in ipairs(stats.errors) do
            Utils.Logger.error("  " .. err.error)
        end
    end
    
    Utils.Logger.info(string.rep("=", 50))
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

-- Export global functions
_G.describe = describe
_G.it = it
_G.before_each = before_each
_G.after_each = after_each
_G.assert = assert
_G.spy = spy

return BustedLite