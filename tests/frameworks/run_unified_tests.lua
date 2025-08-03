-- Unified Test Runner for Orbit Jump
-- Consolidates all test types into a single, efficient runner
local Utils = require("src.utils.utils")
local UnifiedTestFramework = Utils.require("tests.unified_test_framework")
-- Configuration
local config = {
    testTypes = {
        unit = true,
        integration = true,
        performance = true,
        ui = true
    },
    parallel = false,
    verbose = false,
    filter = nil,
    timeout = 30 -- seconds
}
-- ANSI color codes
local colors = {
    green = "\27[32m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m"
}
local function printColored(color, text)
    Utils.Logger.output(colors[color] .. text .. colors.reset)
end
-- Parse command line arguments
local function parseArgs(...)
    local args = {...}
    local i = 1
    -- Handle case where no arguments are passed
    if #args == 0 then
        return
    end
    while i <= #args do
        local arg = args[i]
        if arg == "--unit-only" then
            config.testTypes.unit = true
            config.testTypes.integration = false
            config.testTypes.performance = false
            config.testTypes.ui = false
        elseif arg == "--integration-only" then
            config.testTypes.unit = false
            config.testTypes.integration = true
            config.testTypes.performance = false
            config.testTypes.ui = false
        elseif arg == "--performance-only" then
            config.testTypes.unit = false
            config.testTypes.integration = false
            config.testTypes.performance = true
            config.testTypes.ui = false
        elseif arg == "--ui-only" then
            config.testTypes.unit = false
            config.testTypes.integration = false
            config.testTypes.performance = false
            config.testTypes.ui = true
        elseif arg == "--parallel" then
            config.parallel = true
        elseif arg == "--verbose" or arg == "-v" then
            config.verbose = true
        elseif arg == "--filter" then
            i = i + 1
            if i <= #args then
                config.filter = args[i]
            end
        elseif arg == "--timeout" then
            i = i + 1
            if i <= #args then
                config.timeout = tonumber(args[i]) or 30
            end
        elseif arg == "--help" or arg == "-h" then
            print("Unified Test Runner for Orbit Jump")
            print("Usage: lua run_unified_tests.lua [options]")
            print("")
            print("Options:")
            print("  --unit-only        Run only unit tests")
            print("  --integration-only Run only integration tests")
            print("  --performance-only Run only performance tests")
            print("  --ui-only          Run only UI tests")
            print("  --parallel         Run tests in parallel (experimental)")
            print("  --verbose, -v      Enable verbose output")
            print("  --filter <pattern> Filter tests by name pattern")
            print("  --timeout <seconds> Set test timeout (default: 30)")
            print("  --help, -h         Show this help message")
            print("")
            print("Examples:")
            print("  lua run_unified_tests.lua                    # Run all tests")
            print("  lua run_unified_tests.lua --unit-only        # Run only unit tests")
            print("  lua run_unified_tests.lua --filter \"player\" # Run tests with 'player' in name")
            os.exit(0)
        end
        i = i + 1
    end
end
-- Test discovery
local function discoverTests()
    local tests = {
        unit = {},
        integration = {},
        performance = {},
        ui = {}
    }
    -- Unit tests
    if config.testTypes.unit then
        local unitTestFiles = {
            "tests/unit/game_logic_tests.lua",
            "tests/unit/renderer_tests.lua",
            "tests/unit/save_system_tests.lua",
            "tests/unit/utils_tests.lua",
            "tests/unit/camera_tests.lua",
            "tests/unit/collision_tests.lua",
            "tests/unit/test_sound_manager.lua",
            "tests/unit/test_sound_generator.lua",
            "tests/unit/test_performance_monitor.lua",
            "tests/unit/test_performance_system.lua"
        }
        for _, file in ipairs(unitTestFiles) do
            local success, testSuite = pcall(Utils.require, file:gsub("^tests/", ""):gsub("%.lua$", ""))
            if config.verbose then
                printColored("blue", "  🔍 Loading " .. file .. " - Success: " .. tostring(success) .. ", Type: " .. type(testSuite))
            end
            if success and testSuite and type(testSuite) == "table" then
                tests.unit[file] = testSuite
                if config.verbose then
                    printColored("green", "  ✅ Loaded " .. file)
                end
            else
                if config.verbose then
                    printColored("yellow", "  ⚠️  Skipped " .. file .. " (not a valid test suite)")
                end
            end
        end
    end
    -- Integration tests
    if config.testTypes.integration then
        local integrationTestFiles = {
            "tests/integration/test_addiction_features_integration.lua"
        }
        for _, file in ipairs(integrationTestFiles) do
            local success, testSuite = pcall(Utils.require, file:gsub("^tests/", ""):gsub("%.lua$", ""))
            if success and testSuite then
                tests.integration[file] = testSuite
            end
        end
    end
    -- Performance tests
    if config.testTypes.performance then
        local performanceTestFiles = {
            "tests/performance/test_performance_benchmarks.lua"
        }
        for _, file in ipairs(performanceTestFiles) do
            local success, testSuite = pcall(Utils.require, file:gsub("^tests/", ""):gsub("%.lua$", ""))
            if success and testSuite then
                tests.performance[file] = testSuite
            end
        end
    end
    -- UI tests
    if config.testTypes.ui then
        local uiTestFiles = {
            "tests/ui/test_ui_system.lua",
            "tests/ui/test_pause_menu.lua",
            "tests/ui/test_settings_menu.lua",
            "tests/ui/test_tutorial_system.lua",
            "tests/ui/test_upgrade_system.lua",
            "tests/ui/test_achievement_system.lua"
        }
        for _, file in ipairs(uiTestFiles) do
            local success, testSuite = pcall(Utils.require, file:gsub("^tests/", ""):gsub("%.lua$", ""))
            if success and testSuite then
                tests.ui[file] = testSuite
            end
        end
    end
    return tests
end
-- Test filtering
local function filterTests(testSuites, pattern)
    if not pattern then
        return testSuites
    end
    local filtered = {}
    for testType, suites in pairs(testSuites) do
        filtered[testType] = {}
        for suiteName, suite in pairs(suites) do
            local filteredSuite = {}
            for testName, testFn in pairs(suite) do
                if testName:lower():match(pattern:lower()) then
                    filteredSuite[testName] = testFn
                end
            end
            if next(filteredSuite) then
                filtered[testType][suiteName] = filteredSuite
            end
        end
    end
    return filtered
end
-- Test execution with timeout
local function runTestWithTimeout(testName, testFn, timeout)
    local startTime = os.clock()
    local success, error = true, nil
    -- Set up timeout
    local function timeoutHandler()
        if os.clock() - startTime > timeout then
            error("Test timed out after " .. timeout .. " seconds")
            return false
        end
        return true
    end
    -- Run the test
    success, error = Utils.ErrorHandler.safeCall(testFn)
    -- Check timeout
    if not timeoutHandler() then
        success = false
        error = "Test timed out after " .. timeout .. " seconds"
    end
    return success, error, os.clock() - startTime
end
-- Run test suites
local function runTestSuites(testSuites, testType)
    printColored("blue", string.format("\n📋 Running %s Tests", testType:upper()))
    printColored("blue", string.rep("=", 50))
    local totalTests = 0
    local passedTests = 0
    local failedTests = 0
    local startTime = os.clock()
    for suiteName, testSuite in pairs(testSuites) do
        if config.verbose then
            printColored("yellow", string.format("\n🔍 Suite: %s", suiteName))
        end
        local suitePassed = 0
        local suiteFailed = 0
        for testName, testFn in pairs(testSuite) do
            totalTests = totalTests + 1
            local success, error, duration = runTestWithTimeout(testName, testFn, config.timeout)
            if success then
                if config.verbose then
                    printColored("green", string.format("  ✅ %s (%.3fs)", testName, duration))
                end
                suitePassed = suitePassed + 1
                passedTests = passedTests + 1
            else
                printColored("red", string.format("  ❌ %s (%.3fs) - %s", testName, duration, error))
                suiteFailed = suiteFailed + 1
                failedTests = failedTests + 1
            end
        end
        if config.verbose and suitePassed + suiteFailed > 0 then
            local suiteColor = suiteFailed == 0 and "green" or "red"
            printColored(suiteColor, string.format("  %d/%d tests passed", suitePassed, suitePassed + suiteFailed))
        end
    end
    local endTime = os.clock()
    local totalTime = endTime - startTime
    printColored("blue", string.format("\n📊 %s Tests Summary:", testType:upper()))
    printColored("blue", string.format("  Total: %d | Passed: %d | Failed: %d | Time: %.3fs",
        totalTests, passedTests, failedTests, totalTime))
    return passedTests, failedTests, totalTime
end
-- Main execution
local function main(...)
    printColored("blue", "🔧 Starting main function...")
    parseArgs(...)
    printColored("yellow", "🚀 Orbit Jump Unified Test Runner")
    printColored("yellow", string.rep("=", 60))
    -- Initialize framework
    printColored("blue", "🔧 Initializing framework...")
    UnifiedTestFramework.init()
    printColored("blue", "✅ Framework initialized")
    -- Discover tests
    printColored("blue", "🔍 Discovering tests...")
    local success, allTests = pcall(discoverTests)
    if not success then
        printColored("red", "❌ Test discovery failed: " .. tostring(allTests))
        os.exit(1)
    end
    printColored("blue", "📋 Test discovery complete")
    -- Apply filters
    if config.filter then
        allTests = filterTests(allTests, config.filter)
        printColored("blue", "🔍 Filter: " .. config.filter)
    end
    -- Count total tests
    local totalTestSuites = 0
    for _, testType in pairs(allTests) do
        for _ in pairs(testType) do
            totalTestSuites = totalTestSuites + 1
        end
    end
    if totalTestSuites == 0 then
        printColored("yellow", "⚠️  No tests found matching criteria")
        os.exit(0)
    end
    printColored("blue", string.format("📋 Found %d test suites", totalTestSuites))
    -- Run tests
    local overallStartTime = os.clock()
    local totalPassed = 0
    local totalFailed = 0
    local totalTime = 0
    for testType, testSuites in pairs(allTests) do
        if next(testSuites) then
            local passed, failed, time = runTestSuites(testSuites, testType)
            totalPassed = totalPassed + passed
            totalFailed = totalFailed + failed
            totalTime = totalTime + time
        end
    end
    local overallEndTime = os.clock()
    local overallTime = overallEndTime - overallStartTime
    -- Final summary
    print(string.rep("=", 60))
    printColored("yellow", "📊 Overall Test Results:")
    printColored("yellow", string.format("  Total: %d | Passed: %d | Failed: %d | Time: %.3fs",
        totalPassed + totalFailed, totalPassed, totalFailed, overallTime))
    if totalFailed == 0 then
        printColored("green", "🎉 All tests passed!")
        os.exit(0)
    else
        printColored("red", string.format("💥 %d tests failed!", totalFailed))
        os.exit(1)
    end
end
-- Run if called directly
if arg and #arg > 0 then
    main(table.unpack(arg))
else
    main()
end