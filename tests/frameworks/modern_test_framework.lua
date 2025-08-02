-- Modern Test Framework for Orbit Jump
-- Combines the best features of legacy and Busted-style frameworks

local Utils = require("src.utils.utils")
local Mocks = Utils.require("tests.mocks")

local ModernTestFramework = {}

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

-- Initialize the test framework
function ModernTestFramework.init()
    testStats = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
        startTime = os.clock(),
        endTime = 0
    }
    testContext = {}
    
    -- Setup mocks
    Mocks.setup()
    
    print("🚀 Modern Test Framework Initialized")
end

-- Assertion functions
ModernTestFramework.assert = {
    -- Basic assertions
    equal = function(expected, actual, message)
        if expected ~= actual then
            error(string.format("Assertion failed: expected %s, got %s. %s", 
                tostring(expected), tostring(actual), message or ""))
        end
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
    
    -- Function call tracking
    called = function(functionName, expectedCount, message)
        local actualCount = Mocks.getCallCount(functionName)
        if actualCount ~= expectedCount then
            error(string.format("Assertion failed: expected %s to be called %d times, got %d. %s", 
                functionName, expectedCount, actualCount, message or ""))
        end
    end,
    
    calledAtLeast = function(functionName, expectedCount, message)
        local actualCount = Mocks.getCallCount(functionName)
        if actualCount < expectedCount then
            error(string.format("Assertion failed: expected %s to be called at least %d times, got %d. %s", 
                functionName, expectedCount, actualCount, message or ""))
        end
    end,
    
    -- Approximate equality for floating point
    approx = function(expected, actual, tolerance, message)
        tolerance = tolerance or 0.001
        if math.abs(expected - actual) > tolerance then
            error(string.format("Assertion failed: expected %f ± %f, got %f. %s", 
                expected, tolerance, actual, message or ""))
        end
    end,
    
    -- String assertions
    contains = function(expected, actual, message)
        if not string.find(actual, expected, 1, true) then
            error(string.format("Assertion failed: expected '%s' to contain '%s'. %s", 
                actual, expected, message or ""))
        end
    end,
    
    stringContains = function(expected, actual, message)
        if not string.find(actual, expected, 1, true) then
            error(string.format("Assertion failed: expected '%s' to contain '%s'. %s", 
                actual, expected, message or ""))
        end
    end,
    
    -- Pattern matching assertion
    match = function(actual, pattern, message)
        if not string.match(actual, pattern) then
            error(string.format("Assertion failed: expected '%s' to match pattern '%s'. %s", 
                actual, pattern, message or ""))
        end
    end,
    
    -- Table assertions
    tableEqual = function(expected, actual, message)
        if type(expected) ~= "table" or type(actual) ~= "table" then
            error(string.format("Assertion failed: both values must be tables. %s", message or ""))
        end
        
        for k, v in pairs(expected) do
            if actual[k] ~= v then
                error(string.format("Assertion failed: expected[%s] = %s, actual[%s] = %s. %s", 
                    tostring(k), tostring(v), tostring(k), tostring(actual[k]), message or ""))
            end
        end
        
        for k, v in pairs(actual) do
            if expected[k] == nil then
                error(string.format("Assertion failed: unexpected key %s with value %s. %s", 
                    tostring(k), tostring(v), message or ""))
            end
        end
    end,
    
    -- Collection assertions
    isEmpty = function(collection, message)
        if type(collection) == "table" then
            for k, v in pairs(collection) do
                error(string.format("Assertion failed: expected empty table, but found key %s with value %s. %s", 
                    tostring(k), tostring(v), message or ""))
            end
        elseif type(collection) == "string" then
            if #collection > 0 then
                error(string.format("Assertion failed: expected empty string, got '%s'. %s", 
                    collection, message or ""))
            end
        else
            error(string.format("Assertion failed: cannot check emptiness of type %s. %s", 
                type(collection), message or ""))
        end
    end,
    
    -- Deep equality comparison for tables
    deepEqual = function(expected, actual, message)
        local function deepCompare(t1, t2)
            if type(t1) ~= type(t2) then return false end
            if type(t1) ~= "table" then return t1 == t2 end
            
            for k, v in pairs(t1) do
                if not deepCompare(v, t2[k]) then return false end
            end
            
            for k, v in pairs(t2) do
                if t1[k] == nil then return false end
            end
            
            return true
        end
        
        if not deepCompare(expected, actual) then
            error(string.format("Assertion failed: tables are not deeply equal. %s", message or ""))
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
    
    greaterThanOrEqual = function(expected, actual, message)
        if actual < expected then
            error(string.format("Assertion failed: expected >= %s, got %s. %s", 
                tostring(expected), tostring(actual), message or ""))
        end
    end,
    
    lessThanOrEqual = function(expected, actual, message)
        if actual > expected then
            error(string.format("Assertion failed: expected <= %s, got %s. %s", 
                tostring(expected), tostring(actual), message or ""))
        end
    end,
    
    approximatelyEqual = function(expected, actual, tolerance, message)
        tolerance = tolerance or 0.001
        if math.abs(expected - actual) > tolerance then
            error(string.format("Assertion failed: expected %f ± %f, got %f. %s", 
                expected, tolerance, actual, message or ""))
        end
    end
}

-- Add aliases for backward compatibility with old test framework
ModernTestFramework.assert.assertEqual = ModernTestFramework.assert.equal
ModernTestFramework.assert.assertNotEqual = ModernTestFramework.assert.notEqual
ModernTestFramework.assert.assertTrue = ModernTestFramework.assert.isTrue
ModernTestFramework.assert.assertFalse = ModernTestFramework.assert.isFalse
ModernTestFramework.assert.assertNil = ModernTestFramework.assert.isNil
ModernTestFramework.assert.assertNotNil = ModernTestFramework.assert.notNil

-- Test utilities
ModernTestFramework.utils = {
    -- Reset call tracker
    resetCalls = function()
        Mocks.resetCallTracker()
    end,
    
    -- Get call count
    getCallCount = function(functionName)
        return Mocks.getCallCount(functionName)
    end,
    
    -- Create mock object
    createMock = function(properties)
        return Mocks.createMock(properties)
    end,
    
    -- Create mock function
    createMockFunction = function(returnValue)
        return Mocks.createMockFunction(returnValue)
    end,
    
    -- Create tracked mock function
    createTrackedMock = function(returnValue)
        return Mocks.createTrackedMockFunction(returnValue)
    end,
    
    -- Set test context
    setContext = function(key, value)
        testContext[key] = value
    end,
    
    -- Get test context
    getContext = function(key)
        return testContext[key]
    end,
    
    -- Clear test context
    clearContext = function()
        testContext = {}
    end
}

-- Test runner
function ModernTestFramework.runTests(testSuite, suiteName)
    suiteName = suiteName or "Test Suite"
    print(string.format("\n📋 Running %s", suiteName))
    print(string.rep("=", 50))
    
    local suiteStartTime = os.clock()
    local suiteStats = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    for testName, testFunction in pairs(testSuite) do
        suiteStats.total = suiteStats.total + 1
        testStats.total = testStats.total + 1
        
        local testStartTime = os.clock()
        local success, error = pcall(function()
            -- Reset mocks for each test
            Mocks.reset()
            ModernTestFramework.utils.clearContext()
            
            -- Run the test
            testFunction()
        end)
        
        local testTime = os.clock() - testStartTime
        
        if success then
            suiteStats.passed = suiteStats.passed + 1
            testStats.passed = testStats.passed + 1
            print(string.format("✅ %s (%.3fs)", testName, testTime))
        else
            suiteStats.failed = suiteStats.failed + 1
            testStats.failed = testStats.failed + 1
            table.insert(suiteStats.errors, {
                name = testName,
                error = error
            })
            print(string.format("❌ %s (%.3fs)", testName, testTime))
            print(string.format("   Error: %s", error))
        end
    end
    
    local suiteTime = os.clock() - suiteStartTime
    
    -- Print suite summary
    print(string.rep("-", 50))
    print(string.format("📊 %s Results:", suiteName))
    print(string.format("   Total: %d | Passed: %d | Failed: %d | Time: %.3fs", 
        suiteStats.total, suiteStats.passed, suiteStats.failed, suiteTime))
    
    if #suiteStats.errors > 0 then
        print("\n❌ Failed Tests:")
        for _, error in ipairs(suiteStats.errors) do
            print(string.format("   • %s: %s", error.name, error.error))
        end
    end
    
    return suiteStats.passed == suiteStats.total
end

-- Run multiple test suites
function ModernTestFramework.runAllSuites(testSuites)
    print("🚀 Modern Test Framework - Running All Suites")
    print(string.rep("=", 60))
    
    local allPassed = true
    
    for suiteName, testSuite in pairs(testSuites) do
        local suitePassed = ModernTestFramework.runTests(testSuite, suiteName)
        if not suitePassed then
            allPassed = false
        end
        print() -- Add spacing between suites
    end
    
    -- Print overall summary
    testStats.endTime = os.clock()
    local totalTime = testStats.endTime - testStats.startTime
    
    print(string.rep("=", 60))
    print("📊 Overall Test Results:")
    print(string.format("   Total: %d | Passed: %d | Failed: %d | Time: %.3fs", 
        testStats.total, testStats.passed, testStats.failed, totalTime))
    
    if testStats.failed == 0 then
        print("🎉 All tests passed!")
    else
        print(string.format("💥 %d tests failed!", testStats.failed))
    end
    
    return allPassed
end

-- Test decorators
ModernTestFramework.beforeEach = function(setupFunction)
    return function(testFunction)
        return function()
            setupFunction()
            testFunction()
        end
    end
end

ModernTestFramework.afterEach = function(teardownFunction)
    return function(testFunction)
        return function()
            local success, error = pcall(testFunction)
            teardownFunction()
            if not success then
                error(error)
            end
        end
    end
end

ModernTestFramework.skip = function(reason)
    return function(testFunction)
        return function()
            testStats.skipped = testStats.skipped + 1
            print(string.format("⏭️  Skipped: %s", reason or "No reason provided"))
        end
    end
end

-- Performance testing
ModernTestFramework.benchmark = function(testFunction, iterations)
    iterations = iterations or 1000
    
    local startTime = os.clock()
    for i = 1, iterations do
        testFunction()
    end
    local endTime = os.clock()
    
    local totalTime = endTime - startTime
    local avgTime = totalTime / iterations
    
    print(string.format("⏱️  Benchmark: %d iterations in %.3fs (avg: %.6fs per iteration)", 
        iterations, totalTime, avgTime))
    
    return avgTime
end

return ModernTestFramework 