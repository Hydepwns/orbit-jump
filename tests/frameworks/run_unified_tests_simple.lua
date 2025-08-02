-- Simplified Unified Test Runner for Orbit Jump
-- Basic version to test core functionality

local Utils = require("src.utils.utils")
local UnifiedTestFramework = Utils.require("tests.unified_test_framework")

print("🚀 Starting Simplified Unified Test Runner")

-- Initialize the framework
print("🔧 Initializing framework...")
UnifiedTestFramework.init()
print("✅ Framework initialized")

-- Simple test discovery
print("🔍 Discovering tests...")
local tests = {
    unit = {},
    integration = {},
    performance = {},
    ui = {}
}

-- Try to load one unit test file
local success, testSuite = pcall(Utils.require, "tests.unit.game_logic_tests")
if success and testSuite and type(testSuite) == "table" then
    tests.unit["tests/unit/game_logic_tests.lua"] = testSuite
    print("✅ Loaded game_logic_tests")
else
    print("❌ Failed to load game_logic_tests: " .. tostring(testSuite))
end

print("📋 Test discovery complete")

-- Count total tests
local totalTestSuites = 0
for _, testType in pairs(tests) do
    for _ in pairs(testType) do
        totalTestSuites = totalTestSuites + 1
    end
end

print("📊 Found " .. totalTestSuites .. " test suites")

if totalTestSuites == 0 then
    print("⚠️  No tests found")
    os.exit(0)
end

-- Run tests
print("🏃 Running tests...")
local overallStartTime = os.clock()
local totalPassed = 0
local totalFailed = 0

for testType, testSuites in pairs(tests) do
    if next(testSuites) then
        print("📋 Running " .. testType .. " tests...")
        
        for suiteName, testSuite in pairs(testSuites) do
            print("  🔍 Suite: " .. suiteName)
            
            local suitePassed = 0
            local suiteFailed = 0
            
            for testName, testFn in pairs(testSuite) do
                local startTime = os.clock()
                local success, error = Utils.ErrorHandler.safeCall(testFn)
                local duration = os.clock() - startTime
                
                if success then
                    print("    ✅ " .. testName .. " (" .. string.format("%.3f", duration) .. "s)")
                    suitePassed = suitePassed + 1
                    totalPassed = totalPassed + 1
                else
                    print("    ❌ " .. testName .. " (" .. string.format("%.3f", duration) .. "s) - " .. error)
                    suiteFailed = suiteFailed + 1
                    totalFailed = totalFailed + 1
                end
            end
            
            print("    📊 " .. suitePassed .. "/" .. (suitePassed + suiteFailed) .. " tests passed")
        end
    end
end

local overallEndTime = os.clock()
local overallTime = overallEndTime - overallStartTime

-- Final summary
print(string.rep("=", 60))
print("📊 Overall Test Results:")
print("  Total: " .. (totalPassed + totalFailed) .. " | Passed: " .. totalPassed .. " | Failed: " .. totalFailed .. " | Time: " .. string.format("%.3f", overallTime) .. "s")

if totalFailed == 0 then
    print("🎉 All tests passed!")
    os.exit(0)
else
    print("💥 " .. totalFailed .. " tests failed!")
    os.exit(1)
end 