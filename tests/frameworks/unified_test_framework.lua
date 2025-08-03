-- Unified Test Framework for Orbit Jump
-- Combines Modern framework and Busted-style features into a single, comprehensive solution
local Utils = require("src.utils.utils")
local Mocks = Utils.require("tests.frameworks.mocks")
local UnifiedTestFramework = {}
-- Test statistics
local testStats = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0,
    startTime = 0,
    endTime = 0
}
-- Test context for sharing data between tests
local testContext = {}
-- Test suites and current suite tracking
local suites = {}
local currentSuite = nil
local results = {
    total = 0,
    passed = 0,
    failed = 0,
    errors = {}
}
-- ANSI color codes for output
local colors = {
    green = "\27[32m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m"
}
-- Helper to print colored text
local function printColored(color, text)
    if Utils and Utils.Logger and Utils.Logger.output then
        Utils.Logger.output(colors[color] .. text .. colors.reset)
    else
        print(colors[color] .. text .. colors.reset)
    end
end
-- Initialize the test framework
function UnifiedTestFramework.init()
    printColored("blue", "🔧 Setting up test statistics...")
    testStats = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        startTime = os.clock(),
        endTime = 0
    }
    testContext = {}
    suites = {}
    currentSuite = nil
    results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    printColored("blue", "🔧 Setting up mocks...")
    -- Setup mocks
    if Mocks and Mocks.setup then
        local success, error = pcall(Mocks.setup)
        if not success then
            printColored("yellow", "⚠️  Mock setup failed: " .. tostring(error))
        end
    else
        printColored("yellow", "⚠️  Mocks not available")
    end
    printColored("blue", "🚀 Unified Test Framework Initialized")
end
-- Reset function for running multiple test files
function UnifiedTestFramework.reset()
    testStats = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        startTime = os.clock(),
        endTime = 0
    }
    testContext = {}
    suites = {}
    currentSuite = nil
    results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    -- Reset mocks
    if Mocks and Mocks.reset then
        Mocks.reset()
    end
end
-- Enhanced Assertion Library (combines both frameworks)
UnifiedTestFramework.assert = {
    -- Basic assertions
    equal = function(expected, actual, message)
        if expected ~= actual then
            error(string.format("Assertion failed: expected %s, got %s. %s",
                tostring(expected), tostring(actual), message or ""))
        end
    end,
    equals = function(expected, actual, message)
        return UnifiedTestFramework.assert.equal(expected, actual, message)
    end,
    notEqual = function(expected, actual, message)
        if expected == actual then
            error(string.format("Assertion failed: expected not %s, got %s. %s",
                tostring(expected), tostring(actual), message or ""))
        end
    end,
    isTrue = function(condition, message)
        if not condition then
            error(string.format("Assertion failed: expected true, got false. %s", message or ""))
        end
    end,
    isFalse = function(condition, message)
        if condition then
            error(string.format("Assertion failed: expected false, got true. %s", message or ""))
        end
    end,
    isNil = function(value, message)
        if value ~= nil then
            error(string.format("Assertion failed: expected nil, got %s. %s",
                tostring(value), message or ""))
        end
    end,
    notNil = function(value, message)
        if value == nil then
            error(string.format("Assertion failed: expected not nil, got nil. %s", message or ""))
        end
    end,
    -- Type assertions
    type = function(expectedType, value, message)
        if type(value) ~= expectedType then
            error(string.format("Assertion failed: expected type %s, got %s. %s",
                expectedType, type(value), message or ""))
        end
    end,
    -- Numeric comparisons
    greaterThan = function(expected, actual, message)
        if actual <= expected then
            error(string.format("Assertion failed: expected > %s, got %s. %s",
                tostring(expected), tostring(actual), message or ""))
        end
    end,
    lessThan = function(expected, actual, message)
        if actual >= expected then
            error(string.format("Assertion failed: expected < %s, got %s. %s",
                tostring(expected), tostring(actual), message or ""))
        end
    end,
    -- Function call tracking
    called = function(functionName, expectedCount, message)
        local actualCount = Mocks and Mocks.getCallCount and Mocks.getCallCount(functionName) or 0
        if actualCount ~= expectedCount then
            error(string.format("Assertion failed: expected %s to be called %d times, got %d. %s",
                functionName, expectedCount, actualCount, message or ""))
        end
    end,
    calledAtLeast = function(functionName, expectedCount, message)
        local actualCount = Mocks and Mocks.getCallCount and Mocks.getCallCount(functionName) or 0
        if actualCount < expectedCount then
            error(string.format("Assertion failed: expected %s to be called at least %d times, got %d. %s",
                functionName, expectedCount, actualCount, message or ""))
        end
    end,
    calledWith = function(functionName, expectedArgs, message)
        local calls = Mocks and Mocks.getCalls and Mocks.getCalls(functionName) or {}
        local found = false
        for _, call in ipairs(calls) do
            if #call == #expectedArgs then
                local match = true
                for i, arg in ipairs(expectedArgs) do
                    if call[i] ~= arg then
                        match = false
                        break
                    end
                end
                if match then
                    found = true
                    break
                end
            end
        end
        if not found then
            error(string.format("Assertion failed: expected %s to be called with %s. %s",
                functionName, tostring(expectedArgs), message or ""))
        end
    end,
    -- Additional assertions for compatibility
    near = function(expected, actual, tolerance, message)
        tolerance = tolerance or 0.001
        if math.abs(expected - actual) > tolerance then
            error(string.format("Assertion failed: expected %s ± %s, got %s. %s",
                tostring(expected), tostring(tolerance), tostring(actual), message or ""))
        end
    end,
    matches = function(str, pattern, message)
        if not string.match(str, pattern) then
            error(string.format("Assertion failed: expected string to match pattern '%s', got '%s'. %s",
                pattern, str, message or ""))
        end
    end,
    contains = function(table, element, message)
        local found = false
        for _, value in ipairs(table) do
            if value == element then
                found = true
                break
            end
        end
        if not found then
            error(string.format("Assertion failed: expected table to contain %s. %s",
                tostring(element), message or ""))
        end
    end,
    isEmpty = function(table, message)
        if #table ~= 0 then
            error(string.format("Assertion failed: expected empty table, got table with %d elements. %s",
                #table, message or ""))
        end
    end
}
-- Busted-style API compatibility
local function describe(name, fn)
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
local function it(name, fn)
    if not currentSuite then
        error("'it' must be called inside a 'describe' block")
    end
    table.insert(currentSuite.tests, {
        name = name,
        fn = fn
    })
end
local function before_each(fn)
    if not currentSuite then
        error("'before_each' must be called inside a 'describe' block")
    end
    currentSuite.beforeEach = fn
end
local function after_each(fn)
    if not currentSuite then
        error("'after_each' must be called inside a 'describe' block")
    end
    currentSuite.afterEach = fn
end
-- Global beforeEach/afterEach for use outside describe blocks
local globalBeforeEach = nil
local globalAfterEach = nil
local function beforeEach(fn)
    globalBeforeEach = fn
end
local function afterEach(fn)
    globalAfterEach = fn
end
-- Spy function for function call tracking
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
-- Test execution functions
local function runTest(testName, testFn, suite)
    local startTime = os.clock()
    local success, error = true, nil
    -- Reset mocks before each test
    if Mocks and Mocks.reset then
        Mocks.reset()
    end
    -- Run beforeEach if defined (suite or global)
    local beforeEachFn = suite.beforeEach or globalBeforeEach
    if beforeEachFn then
        success, error = Utils.ErrorHandler.safeCall(beforeEachFn)
        if not success then
            local duration = os.clock() - startTime
            printColored("red", string.format("✗ %s (%.3fs) - Setup failed: %s", testName, duration, error))
            table.insert(results.errors, {name = testName, error = "Setup failed: " .. error})
            return false
        end
    end
    -- Run the actual test
    success, error = Utils.ErrorHandler.safeCall(testFn)
    local duration = os.clock() - startTime
    if success then
        printColored("green", string.format("✅ %s (%.3fs)", testName, duration))
        results.passed = results.passed + 1
    else
        printColored("red", string.format("❌ %s (%.3fs) - %s", testName, duration, error))
        table.insert(results.errors, {name = testName, error = error})
        results.failed = results.failed + 1
    end
    -- Run afterEach if defined (suite or global)
    local afterEachFn = suite.afterEach or globalAfterEach
    if afterEachFn then
        local afterSuccess, afterError = Utils.ErrorHandler.safeCall(afterEachFn)
        if not afterSuccess then
            printColored("yellow", string.format("⚠️  Teardown failed for %s: %s", testName, afterError))
        end
    end
    results.total = results.total + 1
    return success
end
local function runSuite(suite)
    printColored("blue", string.format("\n📋 Suite: %s", suite.name))
    local suitePassed = 0
    local suiteFailed = 0
    for _, test in ipairs(suite.tests) do
        local success = runTest(test.name, test.fn, suite)
        if success then
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
-- Report generation
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
-- Run all test suites (Busted-style)
function UnifiedTestFramework.run()
    local startTime = os.clock()
    -- Initialize results
    results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    printColored("yellow", "🚀 Running Unified Tests")
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
-- Modern framework compatibility - run test suites
function UnifiedTestFramework.runAllSuites(testSuites)
    local startTime = os.clock()
    local allPassed = true
    printColored("yellow", "🚀 Running Test Suites")
    printColored("yellow", string.rep("=", 50))
    for suiteName, testSuite in pairs(testSuites) do
        printColored("blue", string.format("\n📋 Suite: %s", suiteName))
        -- Reset for each suite
        UnifiedTestFramework.reset()
        local suitePassed = 0
        local suiteFailed = 0
        for testName, testFn in pairs(testSuite) do
            local startTime = os.clock()
            local success, error = Utils.ErrorHandler.safeCall(testFn)
            local duration = os.clock() - startTime
            if success then
                printColored("green", string.format("✅ %s (%.3fs)", testName, duration))
                suitePassed = suitePassed + 1
            else
                printColored("red", string.format("❌ %s (%.3fs) - %s", testName, duration, error))
                suiteFailed = suiteFailed + 1
                allPassed = false
            end
        end
        local suiteColor = suiteFailed == 0 and "green" or "red"
        printColored(suiteColor, string.format("  %d/%d tests passed", suitePassed, suitePassed + suiteFailed))
    end
    local endTime = os.clock()
    local totalTime = endTime - startTime
    print("\n" .. string.rep("=", 60))
    if allPassed then
        printColored("green", "🎉 All test suites passed!")
    else
        printColored("red", "💥 Some test suites failed!")
    end
    print(string.format("⏱️  Total Time: %.3fs", totalTime))
    print(string.rep("=", 60))
    return allPassed
end
-- Export global functions for Busted-style compatibility
_G.describe = describe
_G.it = it
_G.before_each = before_each
_G.after_each = after_each
_G.assert = UnifiedTestFramework.assert
_G.spy = spy
-- Export additional functions to the framework
UnifiedTestFramework.spy = spy
UnifiedTestFramework.beforeEach = beforeEach
UnifiedTestFramework.afterEach = afterEach
-- Export the framework
return UnifiedTestFramework