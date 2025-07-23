-- Enhanced Test Framework for Orbit Jump
-- Provides comprehensive testing utilities and reporting

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
    
    return avgTime
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

-- Test runner
function TestFramework.runTest(testName, testFunc)
    TestFramework.stats.total = TestFramework.stats.total + 1
    
    local result = {
        name = testName,
        status = "unknown",
        error = nil,
        duration = 0
    }
    
    local startTime = os.clock()
    
    local success, error = pcall(testFunc)
    result.duration = os.clock() - startTime
    
    if success then
        result.status = "passed"
        TestFramework.stats.passed = TestFramework.stats.passed + 1
        print(string.format("✓ %s (%.3fs)", testName, result.duration))
    else
        result.status = "failed"
        TestFramework.stats.failed = TestFramework.stats.failed + 1
        result.error = error
        print(string.format("✗ %s (%.3fs) - %s", testName, result.duration, error))
    end
    
    table.insert(TestFramework.results, result)
    return success
end

-- Test suite runner
function TestFramework.runSuite(suiteName, tests)
    print(string.format("\n--- %s ---", suiteName))
    
    local allPassed = true
    for testName, testFunc in pairs(tests) do
        if not TestFramework.runTest(testName, testFunc) then
            allPassed = false
        end
    end
    
    return allPassed
end

-- Generate test report
function TestFramework.generateReport()
    TestFramework.stats.endTime = os.clock()
    local totalTime = TestFramework.stats.endTime - TestFramework.stats.startTime
    
    print("\n" .. string.rep("=", 50))
    print("TEST REPORT")
    print(string.rep("=", 50))
    print(string.format("Total Tests: %d", TestFramework.stats.total))
    print(string.format("Passed: %d", TestFramework.stats.passed))
    print(string.format("Failed: %d", TestFramework.stats.failed))
    print(string.format("Skipped: %d", TestFramework.stats.skipped))
    print(string.format("Success Rate: %.1f%%", (TestFramework.stats.passed / TestFramework.stats.total) * 100))
    print(string.format("Total Time: %.3fs", totalTime))
    
    if TestFramework.stats.failed > 0 then
        print("\nFAILED TESTS:")
        for _, result in ipairs(TestFramework.results) do
            if result.status == "failed" then
                print(string.format("  - %s: %s", result.name, result.error))
            end
        end
    end
    
    if next(TestFramework.benchmarks) then
        print("\nPERFORMANCE BENCHMARKS:")
        for name, benchmark in pairs(TestFramework.benchmarks) do
            print(string.format("  %s: %.3fms avg, %.0f ops/sec", 
                name, benchmark.averageTime * 1000, benchmark.operationsPerSecond))
        end
    end
    
    print(string.rep("=", 50))
    
    return TestFramework.stats.failed == 0
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