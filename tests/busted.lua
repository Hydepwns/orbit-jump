-- Minimal Busted-style test framework for Orbit Jump
-- Provides describe/it syntax similar to Busted without external dependencies

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
    print(colors[color] .. text .. colors.reset)
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
    local success = pcall(fn)
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
function BustedLite.run()
    local startTime = os.clock()
    
    for _, suite in ipairs(suites) do
        print("\n" .. suite.name)
        
        for _, test in ipairs(suite.tests) do
            results.total = results.total + 1
            
            -- Run beforeEach if defined
            if suite.beforeEach then
                suite.beforeEach()
            end
            
            -- Run the test
            local success, err = pcall(test.fn)
            
            -- Run afterEach if defined
            if suite.afterEach then
                suite.afterEach()
            end
            
            if success then
                results.passed = results.passed + 1
                printColored("green", "  ✓ " .. test.name)
            else
                results.failed = results.failed + 1
                printColored("red", "  ✗ " .. test.name)
                table.insert(results.errors, {
                    suite = suite.name,
                    test = test.name,
                    error = err
                })
            end
        end
    end
    
    -- Print summary
    local endTime = os.clock()
    local duration = endTime - startTime
    
    print("\n" .. string.rep("=", 50))
    print(string.format("Total: %d | Passed: %d | Failed: %d | Time: %.3fs",
        results.total, results.passed, results.failed, duration))
    
    if results.failed > 0 then
        print("\nFailures:")
        for _, err in ipairs(results.errors) do
            printColored("red", string.format("\n%s > %s", err.suite, err.test))
            print("  " .. err.error)
        end
    end
    
    print(string.rep("=", 50))
    
    -- Return success status
    return results.failed == 0
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