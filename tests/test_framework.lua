-- Enhanced Test Framework for Orbit Jump
-- Provides comprehensive testing utilities and reporting

local Utils = Utils.Utils.require("src.utils.utils")

local TestFramework = {}

-- Test statistics
TestFramework.stats = {
    total = 0,
    passed = 0,
    failed = 0,
    skipped = 0,
    startTime = 0,
    endTime = 0
}

-- Test results storage
TestFramework.results = {}

-- Performance benchmarks
TestFramework.benchmarks = {}

-- Test utilities
TestFramework.utils = {}

function TestFramework.utils.assertEqual(expected, actual, message)
    if expected ~= actual then
        error(string.format("Assertion failed: expected %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""))
    end
end

function TestFramework.utils.assertNotEqual(expected, actual, message)
    if expected == actual then
        error(string.format("Assertion failed: expected not %s, got %s. %s", 
            tostring(expected), tostring(actual), message or ""))
    end
end

function TestFramework.utils.assertTrue(condition, message)
    if not condition then
        error(string.format("Assertion failed: expected true, got false. %s", message or ""))
    end
end

function TestFramework.utils.assertFalse(condition, message)
    if condition then
        error(string.format("Assertion failed: expected false, got true. %s", message or ""))
    end
end

function TestFramework.utils.assertNil(value, message)
    if value ~= nil then
        error(string.format("Assertion failed: expected nil, got %s. %s", 
            tostring(value), message or ""))
    end
end

function TestFramework.utils.assertNotNil(value, message)
    if value == nil then
        error(string.format("Assertion failed: expected not nil, got nil. %s", message or ""))
    end
end

function TestFramework.utils.assertTableEqual(expected, actual, message)
    if type(expected) ~= "table" or type(actual) ~= "table" then
        error(string.format("Assertion failed: both arguments must be tables. %s", message or ""))
    end
    
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error(string.format("Assertion failed: table values differ at key %s. Expected %s, got %s. %s", 
                tostring(k), tostring(v), tostring(actual[k]), message or ""))
        end
    end
    
    for k, v in pairs(actual) do
        if expected[k] ~= v then
            error(string.format("Assertion failed: table values differ at key %s. Expected %s, got %s. %s", 
                tostring(k), tostring(expected[k]), tostring(v), message or ""))
        end
    end
end

-- Performance testing utilities
function TestFramework.utils.benchmark(name, iterations, func)
    local startTime = os.clock()
    for i = 1, iterations do
        func()
    end
    local endTime = os.clock()
    local duration = endTime - startTime
    local avgTime = duration / iterations
    
    TestFramework.benchmarks[name] = {
        iterations = iterations,
        totalTime = duration,
        averageTime = avgTime,
        operationsPerSecond = iterations / duration
    }
    
    return TestFramework.benchmarks[name]
end

-- Mock utilities
TestFramework.mock = {}

function TestFramework.mock.createMock()
    local mock = {
        calls = {},
        returnValues = {},
        callCount = 0
    }
    
    function mock:call(...)
        self.callCount = self.callCount + 1
        table.insert(self.calls, {...})
        return table.remove(self.returnValues, 1)
    end
    
    function mock:setReturnValue(value)
        table.insert(self.returnValues, value)
    end
    
    function mock:getCallCount()
        return self.callCount
    end
    
    function mock:getLastCall()
        return self.calls[#self.calls]
    end
    
    function mock:reset()
        self.calls = {}
        self.returnValues = {}
        self.callCount = 0
    end
    
    return mock
end

-- Test execution
function TestFramework.runTest(testName, testFunc)
    local startTime = os.clock()
    local success, error = Utils.ErrorHandler.safeCall(testFunc)
    local endTime = os.clock()
    local duration = endTime - startTime
    
    local result = {
        name = testName,
        success = success,
        error = error,
        duration = duration
    }
    
    if success then
        TestFramework.stats.passed = TestFramework.stats.passed + 1
        Utils.Logger.info("✓ %s (%.3fs)", testName, result.duration)
    else
        TestFramework.stats.failed = TestFramework.stats.failed + 1
        Utils.Logger.error("✗ %s (%.3fs) - %s", testName, result.duration, error)
    end
    
    TestFramework.stats.total = TestFramework.stats.total + 1
    table.insert(TestFramework.results, result)
    
    return result
end

-- Test suite execution
function TestFramework.runSuite(suiteName, tests)
    Utils.Logger.info("\n--- %s ---", suiteName)
    
    for testName, testFunc in pairs(tests) do
        TestFramework.runTest(testName, testFunc)
    end
end

-- Generate test report
function TestFramework.generateReport()
    local totalTime = TestFramework.stats.endTime - TestFramework.stats.startTime
    
    Utils.Logger.info("\n" .. string.rep("=", 50))
    Utils.Logger.info("TEST REPORT")
    Utils.Logger.info(string.rep("=", 50))
    Utils.Logger.info("Total Tests: %d", TestFramework.stats.total)
    Utils.Logger.info("Passed: %d", TestFramework.stats.passed)
    Utils.Logger.info("Failed: %d", TestFramework.stats.failed)
    Utils.Logger.info("Skipped: %d", TestFramework.stats.skipped)
    Utils.Logger.info("Success Rate: %.1f%%", (TestFramework.stats.passed / TestFramework.stats.total) * 100)
    Utils.Logger.info("Total Time: %.3fs", totalTime)
    
    -- Show failed tests
    if TestFramework.stats.failed > 0 then
        Utils.Logger.info("\nFAILED TESTS:")
        for _, result in ipairs(TestFramework.results) do
            if not result.success then
                Utils.Logger.error("  - %s: %s", result.name, result.error)
            end
        end
    end
    
    -- Show performance benchmarks
    if next(TestFramework.benchmarks) then
        Utils.Logger.info("\nPERFORMANCE BENCHMARKS:")
        for name, benchmark in pairs(TestFramework.benchmarks) do
            Utils.Logger.info("  %s: %.3fms avg, %.0f ops/sec", 
                name, benchmark.averageTime * 1000, benchmark.operationsPerSecond)
        end
    end
    
    Utils.Logger.info(string.rep("=", 50))
end

-- Initialize test framework
function TestFramework.init()
    TestFramework.stats.startTime = os.clock()
    TestFramework.stats.total = 0
    TestFramework.stats.passed = 0
    TestFramework.stats.failed = 0
    TestFramework.stats.skipped = 0
    TestFramework.results = {}
    TestFramework.benchmarks = {}
end

return TestFramework