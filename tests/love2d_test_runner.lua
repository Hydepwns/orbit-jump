--[[
    LÖVE2D Test Runner
    Runs tests within the LÖVE2D context, allowing tests to access
    love.graphics, love.physics, and other LÖVE2D modules.
    Usage:
        love . test [options] [test_suite]
    This runner integrates with the existing test framework but runs
    inside LÖVE2D's environment.
--]]
local TestRunner = {}
-- Test configuration
TestRunner.config = {
    testDirs = {
        "tests/unit",
        "tests/integration",
        "tests/performance"
    },
    outputMode = "console", -- console, file, both
    showProgress = true,
    stopOnFirstFailure = false,
    filter = nil, -- Test name filter
    suite = "all", -- all, unit, integration, performance
    coverage = false,
    timeLimit = 60, -- Max seconds per test
    -- Visual test mode
    visual = {
        enabled = false,
        autoClose = true,
        closeDelay = 2
    }
}
-- Test state
TestRunner.state = {
    running = false,
    currentTest = nil,
    results = {
        passed = 0,
        failed = 0,
        skipped = 0,
        errors = {}
    },
    startTime = 0,
    tests = {},
    currentIndex = 0
}
-- Initialize test framework
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
        near = function(a, b, epsilon, message)
            epsilon = epsilon or 0.0001
            if math.abs(a - b) > epsilon then
                error((message or "Near assertion failed") .. ": " .. tostring(a) .. " not near " .. tostring(b))
            end
        end,
        throws = function(fn, message)
            local success = pcall(fn)
            if success then
                error((message or "Expected function to throw"))
            end
        end
    }
}
-- Make TestFramework available globally for tests
_G.TestFramework = TestFramework
-- Parse command line arguments
function TestRunner.parseArgs(args)
    local i = 1
    while i <= #args do
        local arg = args[i]
        if arg == "test" then
            -- Skip the test command itself
        elseif arg == "--filter" or arg == "-f" then
            i = i + 1
            TestRunner.config.filter = args[i]
        elseif arg == "--visual" or arg == "-v" then
            TestRunner.config.visual.enabled = true
        elseif arg == "--coverage" then
            TestRunner.config.coverage = true
        elseif arg == "--stop-on-failure" then
            TestRunner.config.stopOnFirstFailure = true
        elseif arg == "--no-progress" then
            TestRunner.config.showProgress = false
        elseif arg == "--time-limit" then
            i = i + 1
            TestRunner.config.timeLimit = tonumber(args[i]) or 60
        else
            -- Assume it's a test suite name
            TestRunner.config.suite = arg
        end
        i = i + 1
    end
end
-- Discover test files
function TestRunner.discoverTests()
    local tests = {}
    -- Determine which directories to search
    local dirsToSearch = {}
    if TestRunner.config.suite == "all" then
        dirsToSearch = TestRunner.config.testDirs
    elseif TestRunner.config.suite == "unit" then
        table.insert(dirsToSearch, "tests/unit")
    elseif TestRunner.config.suite == "integration" then
        table.insert(dirsToSearch, "tests/integration")
    elseif TestRunner.config.suite == "performance" then
        table.insert(dirsToSearch, "tests/performance")
    end
    -- Search directories
    for _, dir in ipairs(dirsToSearch) do
        TestRunner.discoverTestsInDir(dir, tests)
    end
    return tests
end
-- Discover tests in a directory
function TestRunner.discoverTestsInDir(dir, tests)
    local items = love.filesystem.getDirectoryItems(dir)
    for _, item in ipairs(items) do
        local path = dir .. "/" .. item
        local info = love.filesystem.getInfo(path)
        if info then
            if info.type == "file" and item:match("^test_.*%.lua$") then
                -- Found a test file
                local testSuite = {
                    file = path,
                    name = item:gsub("%.lua$", ""),
                    tests = {}
                }
                -- Try to load the test file
                local modulePath = path:gsub("%.lua$", ""):gsub("/", ".")
                local success, module = pcall(require, modulePath)
                if success and type(module) == "table" then
                    -- Extract tests from module
                    if type(module.run) == "function" then
                        -- Single run function
                        table.insert(testSuite.tests, {
                            name = testSuite.name,
                            fn = module.run
                        })
                    else
                        -- Multiple test functions
                        for testName, testFn in pairs(module) do
                            if type(testFn) == "function" and testName ~= "setup" and testName ~= "teardown" then
                                table.insert(testSuite.tests, {
                                    name = testName,
                                    fn = testFn
                                })
                            end
                        end
                    end
                    -- Store setup/teardown if present
                    testSuite.setup = module.setup
                    testSuite.teardown = module.teardown
                end
                if #testSuite.tests > 0 then
                    -- Apply filter if specified
                    if TestRunner.config.filter then
                        local filteredTests = {}
                        for _, test in ipairs(testSuite.tests) do
                            if test.name:match(TestRunner.config.filter) then
                                table.insert(filteredTests, test)
                            end
                        end
                        testSuite.tests = filteredTests
                    end
                    if #testSuite.tests > 0 then
                        table.insert(tests, testSuite)
                    end
                end
            elseif info.type == "directory" then
                -- Recurse into subdirectory
                TestRunner.discoverTestsInDir(path, tests)
            end
        end
    end
end
-- Initialize LÖVE2D callbacks
function TestRunner.init()
    -- Store original LÖVE callbacks
    TestRunner.originalCallbacks = {
        update = love.update,
        draw = love.draw,
        keypressed = love.keypressed
    }
    -- Override LÖVE callbacks
    love.update = function(dt)
        TestRunner.update(dt)
    end
    love.draw = function()
        TestRunner.draw()
    end
    love.keypressed = function(key)
        if key == "escape" then
            love.event.quit(TestRunner.state.results.failed > 0 and 1 or 0)
        elseif key == "space" and TestRunner.state.running then
            -- Skip current test
            TestRunner.skipCurrentTest()
        end
    end
    -- Parse command line arguments
    TestRunner.parseArgs(love.arg)
    -- Discover tests
    print("🔍 Discovering tests...")
    TestRunner.state.tests = TestRunner.discoverTests()
    -- Count total tests
    local totalTests = 0
    for _, suite in ipairs(TestRunner.state.tests) do
        totalTests = totalTests + #suite.tests
    end
    print(string.format("📋 Found %d test files with %d tests", #TestRunner.state.tests, totalTests))
    -- Start running tests
    TestRunner.state.running = true
    TestRunner.state.startTime = love.timer.getTime()
    TestRunner.state.currentIndex = 1
end
-- Update test execution
function TestRunner.update(dt)
    if not TestRunner.state.running then
        return
    end
    -- Check if we have tests to run
    if TestRunner.state.currentIndex > #TestRunner.state.tests then
        TestRunner.finish()
        return
    end
    -- Get current test suite
    local suite = TestRunner.state.tests[TestRunner.state.currentIndex]
    -- Run next test in suite
    if not suite.currentTestIndex then
        suite.currentTestIndex = 1
        -- Run setup if present
        if suite.setup then
            local success, err = pcall(suite.setup)
            if not success then
                print(string.format("❌ Setup failed for %s: %s", suite.name, err))
            end
        end
    end
    if suite.currentTestIndex <= #suite.tests then
        local test = suite.tests[suite.currentTestIndex]
        TestRunner.runTest(suite, test)
        suite.currentTestIndex = suite.currentTestIndex + 1
    else
        -- Suite complete, run teardown
        if suite.teardown then
            local success, err = pcall(suite.teardown)
            if not success then
                print(string.format("❌ Teardown failed for %s: %s", suite.name, err))
            end
        end
        -- Move to next suite
        TestRunner.state.currentIndex = TestRunner.state.currentIndex + 1
    end
end
-- Run a single test
function TestRunner.runTest(suite, test)
    TestRunner.state.currentTest = {
        suite = suite.name,
        name = test.name
    }
    if TestRunner.config.showProgress then
        io.write(string.format("Running %s:%s... ", suite.name, test.name))
        io.flush()
    end
    local startTime = love.timer.getTime()
    local success, err = pcall(test.fn)
    local duration = love.timer.getTime() - startTime
    if success then
        TestRunner.state.results.passed = TestRunner.state.results.passed + 1
        if TestRunner.config.showProgress then
            print(string.format("✅ (%.3fs)", duration))
        end
    else
        TestRunner.state.results.failed = TestRunner.state.results.failed + 1
        table.insert(TestRunner.state.results.errors, {
            suite = suite.name,
            test = test.name,
            error = err
        })
        if TestRunner.config.showProgress then
            print(string.format("❌ (%.3fs)", duration))
            print("   Error: " .. tostring(err))
        end
        if TestRunner.config.stopOnFirstFailure then
            TestRunner.finish()
        end
    end
    -- Check time limit
    if duration > TestRunner.config.timeLimit then
        print(string.format("   ⚠️  Test took %.3fs (limit: %ds)", duration, TestRunner.config.timeLimit))
    end
end
-- Skip current test
function TestRunner.skipCurrentTest()
    if TestRunner.state.currentTest then
        TestRunner.state.results.skipped = TestRunner.state.results.skipped + 1
        print("⏭️  Skipped")
    end
end
-- Draw test results (for visual mode)
function TestRunner.draw()
    if not TestRunner.config.visual.enabled then
        return
    end
    love.graphics.clear(0.1, 0.1, 0.1)
    love.graphics.setColor(1, 1, 1)
    -- Title
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("LÖVE2D Test Runner", 20, 20)
    -- Progress
    love.graphics.setFont(love.graphics.newFont(16))
    local progress = string.format("Tests: %d passed, %d failed, %d skipped",
        TestRunner.state.results.passed,
        TestRunner.state.results.failed,
        TestRunner.state.results.skipped)
    love.graphics.print(progress, 20, 60)
    -- Current test
    if TestRunner.state.currentTest then
        love.graphics.print("Current: " .. TestRunner.state.currentTest.suite .. ":" .. TestRunner.state.currentTest.name, 20, 90)
    end
    -- Recent errors
    love.graphics.setColor(1, 0.5, 0.5)
    local y = 130
    for i = math.max(1, #TestRunner.state.results.errors - 5), #TestRunner.state.results.errors do
        local error = TestRunner.state.results.errors[i]
        if error then
            love.graphics.print(string.format("❌ %s:%s", error.suite, error.test), 20, y)
            y = y + 20
        end
    end
    -- Instructions
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print("Press ESC to exit, SPACE to skip current test", 20, love.graphics.getHeight() - 30)
end
-- Finish test run
function TestRunner.finish()
    TestRunner.state.running = false
    local duration = love.timer.getTime() - TestRunner.state.startTime
    -- Print summary
    print("\n" .. string.rep("=", 60))
    print("📊 Test Results:")
    print(string.format("   Passed: %d", TestRunner.state.results.passed))
    print(string.format("   Failed: %d", TestRunner.state.results.failed))
    print(string.format("   Skipped: %d", TestRunner.state.results.skipped))
    print(string.format("   Duration: %.3fs", duration))
    -- Print errors
    if #TestRunner.state.results.errors > 0 then
        print("\n❌ Failed Tests:")
        for _, error in ipairs(TestRunner.state.results.errors) do
            print(string.format("   %s:%s", error.suite, error.test))
            print("      " .. error.error)
        end
    end
    -- Exit with appropriate code
    local exitCode = TestRunner.state.results.failed > 0 and 1 or 0
    if TestRunner.config.visual.enabled and TestRunner.config.visual.autoClose then
        -- Wait before closing in visual mode
        love.timer.sleep(TestRunner.config.visual.closeDelay)
    end
    love.event.quit(exitCode)
end
return TestRunner