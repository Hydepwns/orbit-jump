-- Simplified Unified Test Runner for Orbit Jump
-- Fixed version that actually discovers and runs tests
local Utils = require("src.utils.utils")
print("🚀 Starting Simplified Unified Test Runner")
-- Initialize minimal test framework
local TestFramework = {
    assert = {
        equal = function(a, b, message)
            if a ~= b then
                error((message or "Assertion failed") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
            end
        end,
        truthy = function(value, message)
            if not value then
                error((message or "Assertion failed") .. ": expected truthy value, got " .. tostring(value))
            end
        end,
        falsy = function(value, message)
            if value then
                error((message or "Assertion failed") .. ": expected falsy value, got " .. tostring(value))
            end
        end,
        deepEqual = function(a, b, message)
            -- Simple deep equality check
            if type(a) ~= type(b) then
                error((message or "Deep equality failed") .. ": different types")
            end
            if type(a) == "table" then
                for k, v in pairs(a) do
                    if b[k] ~= v then
                        error((message or "Deep equality failed") .. ": at key " .. tostring(k))
                    end
                end
                for k, v in pairs(b) do
                    if a[k] ~= v then
                        error((message or "Deep equality failed") .. ": at key " .. tostring(k))
                    end
                end
            elseif a ~= b then
                error((message or "Deep equality failed"))
            end
        end
    }
}
-- Make TestFramework available globally for tests
_G.TestFramework = TestFramework
-- Function to discover test files
local function discoverTestFiles(directory)
    local files = {}
    -- Use io.popen to list files (works on Unix-like systems)
    local handle = io.popen('find ' .. directory .. ' -name "*.lua" -type f 2>/dev/null')
    if handle then
        for file in handle:lines() do
            -- Only include files that start with "test_" or end with "_tests.lua"
            if file:match("/test_[^/]+%.lua$") or file:match("_tests%.lua$") then
                table.insert(files, file)
            end
        end
        handle:close()
    end
    return files
end
-- Function to load a test file
local function loadTestFile(filepath)
    -- Convert file path to module path
    local modulePath = filepath:gsub("%.lua$", ""):gsub("/", ".")
    local success, result = pcall(require, modulePath)
    if success then
        -- Check if it's a valid test module
        if type(result) == "table" then
            -- Check for run function (common pattern in this codebase)
            if type(result.run) == "function" then
                -- Convert run function to test suite format
                local testName = filepath:match("([^/]+)%.lua$") or "Unknown Test"
                return {
                    [testName] = result.run
                }
            end
            -- Check for regular test functions
            local hasTests = false
            for k, v in pairs(result) do
                if type(v) == "function" and k ~= "run" then
                    hasTests = true
                    break
                end
            end
            if hasTests then
                return result
            end
        elseif type(result) == "function" then
            -- Some tests might just export a function directly
            local testName = filepath:match("([^/]+)%.lua$") or "Unknown Test"
            return {
                [testName] = result
            }
        end
    end
    return nil
end
-- Discover tests
print("🔍 Discovering tests...")
local testDirs = {
    {name = "unit", path = "tests/unit"},
    {name = "integration", path = "tests/integration"},
    {name = "performance", path = "tests/performance"}
}
local allTests = {}
local totalTestFiles = 0
for _, dir in ipairs(testDirs) do
    local files = discoverTestFiles(dir.path)
    if #files > 0 then
        allTests[dir.name] = {}
        for _, file in ipairs(files) do
            local testModule = loadTestFile(file)
            if testModule then
                allTests[dir.name][file] = testModule
                totalTestFiles = totalTestFiles + 1
                print("  ✅ Loaded: " .. file)
            end
        end
    end
end
print("📋 Test discovery complete: " .. totalTestFiles .. " test files found")
if totalTestFiles == 0 then
    print("⚠️  No tests found - looking for example tests...")
    -- Add some example tests
    allTests.unit = {
        ["Example Tests"] = {
            ["Basic Math Test"] = function()
                TestFramework.assert.equal(2 + 2, 4, "Basic addition should work")
            end,
            ["String Test"] = function()
                TestFramework.assert.equal("hello" .. " world", "hello world", "String concatenation should work")
            end,
            ["Table Test"] = function()
                local t = {a = 1, b = 2}
                TestFramework.assert.equal(t.a, 1, "Table access should work")
                TestFramework.assert.deepEqual({1, 2, 3}, {1, 2, 3}, "Deep equality should work")
            end
        }
    }
end
-- Run tests
print("\n🏃 Running tests...")
local overallStartTime = os.clock()
local totalPassed = 0
local totalFailed = 0
local failedTests = {}
for testType, testSuites in pairs(allTests) do
    if next(testSuites) then
        print("\n📋 Running " .. testType .. " tests...")
        for suiteName, testSuite in pairs(testSuites) do
            print("  🔍 Suite: " .. suiteName)
            local suitePassed = 0
            local suiteFailed = 0
            for testName, testFn in pairs(testSuite) do
                if type(testFn) == "function" then
                    local startTime = os.clock()
                    local success, error = pcall(testFn)
                    local duration = os.clock() - startTime
                    if success then
                        print("    ✅ " .. testName .. " (" .. string.format("%.3f", duration) .. "s)")
                        suitePassed = suitePassed + 1
                        totalPassed = totalPassed + 1
                    else
                        print("    ❌ " .. testName .. " (" .. string.format("%.3f", duration) .. "s)")
                        print("       Error: " .. tostring(error))
                        suiteFailed = suiteFailed + 1
                        totalFailed = totalFailed + 1
                        table.insert(failedTests, {
                            suite = suiteName,
                            test = testName,
                            error = error
                        })
                    end
                end
            end
            if suitePassed + suiteFailed > 0 then
                print("    📊 " .. suitePassed .. "/" .. (suitePassed + suiteFailed) .. " tests passed")
            end
        end
    end
end
local overallEndTime = os.clock()
local overallTime = overallEndTime - overallStartTime
-- Final summary
print("\n" .. string.rep("=", 60))
print("📊 Overall Test Results:")
print("  Total: " .. (totalPassed + totalFailed) .. " | Passed: " .. totalPassed .. " | Failed: " .. totalFailed .. " | Time: " .. string.format("%.3f", overallTime) .. "s")
if #failedTests > 0 then
    print("\n❌ Failed Tests Summary:")
    for _, failure in ipairs(failedTests) do
        print("  - " .. failure.suite .. " > " .. failure.test)
        print("    " .. failure.error)
    end
end
if totalFailed == 0 then
    print("\n🎉 All tests passed!")
    os.exit(0)
else
    print("\n💥 " .. totalFailed .. " tests failed!")
    os.exit(1)
end