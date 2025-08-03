-- Simple Test Framework for Phase 4 Optimization Demo
-- Compatible with existing test files
local SimpleTestFramework = {}
-- Test statistics
local stats = {
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
    blue = "\27[34m",
    reset = "\27[0m"
}
-- Helper to print colored text
local function print_colored(color, text)
    if colors[color] then
        io.write(colors[color] .. text .. colors.reset)
    else
        io.write(text)
    end
end
-- Initialize the test framework
function SimpleTestFramework.init()
    stats = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    print_colored("blue", "Simple Test Framework Initialized\n")
end
-- Assertion functions
SimpleTestFramework.assert = {
    equal = function(expected, actual, message)
        stats.total = stats.total + 1
        if expected == actual then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
            table.insert(stats.errors, error_msg)
            return false
        end
    end,
    notEqual = function(expected, actual, message)
        stats.total = stats.total + 1
        if expected ~= actual then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected not %s, got %s", tostring(expected), tostring(actual))
            table.insert(stats.errors, error_msg)
            return false
        end
    end,
    isTrue = function(value, message)
        stats.total = stats.total + 1
        if value == true then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected true, got %s", tostring(value))
            table.insert(stats.errors, error_msg)
            return false
        end
    end,
    isFalse = function(value, message)
        stats.total = stats.total + 1
        if value == false then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected false, got %s", tostring(value))
            table.insert(stats.errors, error_msg)
            return false
        end
    end,
    isNil = function(value, message)
        stats.total = stats.total + 1
        if value == nil then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected nil, got %s", tostring(value))
            table.insert(stats.errors, error_msg)
            return false
        end
    end,
    notNil = function(value, message)
        stats.total = stats.total + 1
        if value ~= nil then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected not nil, got nil")
            table.insert(stats.errors, error_msg)
            return false
        end
    end,
    approx = function(expected, actual, tolerance, message)
        stats.total = stats.total + 1
        tolerance = tolerance or 0.001
        if math.abs(expected - actual) <= tolerance then
            stats.passed = stats.passed + 1
            return true
        else
            stats.failed = stats.failed + 1
            local error_msg = message or string.format("Expected %s ± %s, got %s", tostring(expected), tostring(tolerance), tostring(actual))
            table.insert(stats.errors, error_msg)
            return false
        end
    end
}
-- Test suite function
function SimpleTestFramework.describe(name, test_function)
    print_colored("blue", "Running test suite: " .. name .. "\n")
    local success, error = pcall(test_function)
    if not success then
        stats.failed = stats.failed + 1
        table.insert(stats.errors, "Test suite error: " .. tostring(error))
    end
end
-- Individual test function
function SimpleTestFramework.it(name, test_function)
    local success, error = pcall(test_function)
    if success then
        print_colored("green", "  ✓ " .. name .. "\n")
    else
        print_colored("red", "  ✗ " .. name .. ": " .. tostring(error) .. "\n")
        stats.failed = stats.failed + 1
        table.insert(stats.errors, name .. ": " .. tostring(error))
    end
end
-- Get test results
function SimpleTestFramework.get_results()
    return {
        total = stats.total,
        passed = stats.passed,
        failed = stats.failed,
        errors = stats.errors
    }
end
-- Print summary
function SimpleTestFramework.print_summary()
    print_colored("cyan", "\n=== Test Summary ===\n")
    print_colored("blue", string.format("Total assertions: %d\n", stats.total))
    print_colored("green", string.format("Passed: %d\n", stats.passed))
    print_colored("red", string.format("Failed: %d\n", stats.failed))
    if #stats.errors > 0 then
        print_colored("red", "\nErrors:\n")
        for i, error in ipairs(stats.errors) do
            print_colored("red", string.format("  %d. %s\n", i, error))
        end
    end
    if stats.failed > 0 then
        print_colored("red", "\n❌ Some tests failed!\n")
        return false
    else
        print_colored("green", "\n✅ All tests passed!\n")
        return true
    end
end
-- Setup function for compatibility
function SimpleTestFramework.setup()
    -- Mock setup for compatibility with existing tests
    if not love then love = {} end
    if not love.graphics then love.graphics = {} end
    if not love.audio then love.audio = {} end
    if not love.window then love.window = {} end
    -- Mock common love functions
    love.graphics.setColor = function() end
    love.graphics.circle = function() end
    love.graphics.rectangle = function() end
    love.graphics.print = function() end
    love.graphics.arc = function() end
    love.audio.newSource = function() return { play = function() end } end
    love.window.getMode = function() return 800, 600 end
end
return SimpleTestFramework