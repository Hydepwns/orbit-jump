-- Interactive Test Runner for Orbit Jump
-- Phase 5: Enhanced Developer Experience
-- Provides interactive CLI with filtering and improved error reporting

local Utils = require("src.utils.utils")
local UnifiedTestFramework = Utils.require("tests.frameworks.unified_test_framework")

-- ANSI color codes for rich output
local colors = {
    green = "\27[32m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m",
    magenta = "\27[35m",
    white = "\27[37m",
    bold = "\27[1m",
    reset = "\27[0m"
}

-- Interactive runner configuration
local config = {
    testTypes = {
        unit = { enabled = true, path = "tests/unit" },
        integration = { enabled = true, path = "tests/integration" },
        performance = { enabled = true, path = "tests/performance" },
        ui = { enabled = true, path = "tests/ui" }
    },
    parallel = false,
    verbose = false,
    filter = nil,
    timeout = 30,
    watch = false,
    interactive = true
}

-- Test discovery and management
local testRegistry = {
    suites = {},
    totalTests = 0,
    discoveredTests = {}
}

-- Enhanced error reporting
local errorReporter = {
    errors = {},
    warnings = {},
    suggestions = {}
}

-- Helper functions
local function printColored(color, text)
    local colorCode = colors[color] or colors.reset
    Utils.Logger.output(colorCode .. text .. colors.reset)
end

local function printBold(text)
    Utils.Logger.output(colors.bold .. text .. colors.reset)
end

local function printHeader(text)
    printColored("cyan", "\n" .. string.rep("=", 60))
    printColored("cyan", " " .. text)
    printColored("cyan", string.rep("=", 60))
end

local function printSubHeader(text)
    printColored("blue", "\n" .. string.rep("-", 40))
    printColored("blue", " " .. text)
    printColored("blue", string.rep("-", 40))
end

-- Enhanced error reporting functions
local function addError(category, message, details, suggestion)
    table.insert(errorReporter.errors, {
        category = category,
        message = message,
        details = details,
        suggestion = suggestion,
        timestamp = os.time()
    })
end

local function addWarning(category, message, details)
    table.insert(errorReporter.warnings, {
        category = category,
        message = message,
        details = details,
        timestamp = os.time()
    })
end

local function addSuggestion(category, message, details)
    table.insert(errorReporter.suggestions, {
        category = category,
        message = message,
        details = details,
        timestamp = os.time()
    })
end

-- Test discovery
local function discoverTests()
    printSubHeader("🔍 Discovering Tests")
    
    local discovered = 0
    for testType, config in pairs(config.testTypes) do
        if config.enabled then
            printColored("blue", "  Scanning " .. testType .. " tests...")
            
            -- Scan directory for test files
            local testFiles = {}
            local success, files = pcall(function()
                return Utils.FileUtils.listFiles(config.path, "*.lua")
            end)
            
            if success and files then
                for _, file in ipairs(files) do
                    if string.match(file, "test.*%.lua$") or string.match(file, ".*_test%.lua$") then
                        table.insert(testFiles, file)
                        discovered = discovered + 1
                    end
                end
                
                testRegistry.discoveredTests[testType] = testFiles
                printColored("green", "    Found " .. #testFiles .. " test files")
            else
                addWarning("discovery", "Failed to scan " .. testType .. " tests", "Directory may not exist or be accessible")
                printColored("yellow", "    No test files found or directory not accessible")
            end
        end
    end
    
    testRegistry.totalTests = discovered
    printColored("green", "\n✅ Discovered " .. discovered .. " total test files")
    return discovered
end

-- Interactive menu system
local function showMainMenu()
    printHeader("🎮 Interactive Test Runner")
    printColored("white", "Available options:")
    printColored("cyan", "  1. Run all tests")
    printColored("cyan", "  2. Run specific test type")
    printColored("cyan", "  3. Run tests with filter")
    printColored("cyan", "  4. Watch mode (auto-rerun on changes)")
    printColored("cyan", "  5. Show test statistics")
    printColored("cyan", "  6. Show error report")
    printColored("cyan", "  7. Configure settings")
    printColored("cyan", "  8. Exit")
    printColored("white", "\nEnter your choice (1-8): ")
end

local function showTestTypeMenu()
    printSubHeader("📋 Select Test Type")
    local options = {}
    local index = 1
    
    for testType, config in pairs(config.testTypes) do
        local status = config.enabled and "✅" or "❌"
        printColored("white", "  " .. index .. ". " .. testType .. " tests " .. status)
        options[index] = testType
        index = index + 1
    end
    
    printColored("white", "  " .. index .. ". Back to main menu")
    printColored("white", "\nEnter your choice (1-" .. index .. "): ")
    
    return options
end

local function showFilterMenu()
    printSubHeader("🔍 Test Filtering")
    printColored("white", "Enter a pattern to filter tests:")
    printColored("yellow", "Examples:")
    printColored("yellow", "  - 'player' (tests containing 'player' in name)")
    printColored("yellow", "  - 'core.*system' (regex pattern)")
    printColored("yellow", "  - 'test_physics' (exact test file)")
    printColored("white", "\nFilter pattern (or 'none' to clear): ")
end

local function showConfigurationMenu()
    printSubHeader("⚙️  Configuration")
    printColored("white", "Current settings:")
    printColored("cyan", "  Parallel execution: " .. (config.parallel and "✅" or "❌"))
    printColored("cyan", "  Verbose output: " .. (config.verbose and "✅" or "❌"))
    printColored("cyan", "  Test timeout: " .. config.timeout .. " seconds")
    printColored("cyan", "  Watch mode: " .. (config.watch and "✅" or "❌"))
    
    printColored("white", "\nOptions:")
    printColored("cyan", "  1. Toggle parallel execution")
    printColored("cyan", "  2. Toggle verbose output")
    printColored("cyan", "  3. Set test timeout")
    printColored("cyan", "  4. Toggle watch mode")
    printColored("cyan", "  5. Back to main menu")
    printColored("white", "\nEnter your choice (1-5): ")
end

-- Enhanced error reporting display
local function showErrorReport()
    printHeader("📊 Error Report")
    
    if #errorReporter.errors == 0 and #errorReporter.warnings == 0 and #errorReporter.suggestions == 0 then
        printColored("green", "✅ No errors, warnings, or suggestions to report!")
        return
    end
    
    -- Display errors
    if #errorReporter.errors > 0 then
        printSubHeader("❌ Errors (" .. #errorReporter.errors .. ")")
        for i, error in ipairs(errorReporter.errors) do
            printColored("red", "  " .. i .. ". " .. error.category .. ": " .. error.message)
            if error.details then
                printColored("yellow", "     Details: " .. error.details)
            end
            if error.suggestion then
                printColored("cyan", "     Suggestion: " .. error.suggestion)
            end
            print()
        end
    end
    
    -- Display warnings
    if #errorReporter.warnings > 0 then
        printSubHeader("⚠️  Warnings (" .. #errorReporter.warnings .. ")")
        for i, warning in ipairs(errorReporter.warnings) do
            printColored("yellow", "  " .. i .. ". " .. warning.category .. ": " .. warning.message)
            if warning.details then
                printColored("white", "     Details: " .. warning.details)
            end
            print()
        end
    end
    
    -- Display suggestions
    if #errorReporter.suggestions > 0 then
        printSubHeader("💡 Suggestions (" .. #errorReporter.suggestions .. ")")
        for i, suggestion in ipairs(errorReporter.suggestions) do
            printColored("cyan", "  " .. i .. ". " .. suggestion.category .. ": " .. suggestion.message)
            if suggestion.details then
                printColored("white", "     Details: " .. suggestion.details)
            end
            print()
        end
    end
end

-- Test execution with enhanced error handling
local function runTests(testType, filter)
    printHeader("🚀 Running Tests")
    
    if testType then
        printColored("blue", "Test type: " .. testType)
    end
    
    if filter then
        printColored("blue", "Filter: " .. filter)
    end
    
    -- Initialize framework
    local success, error = pcall(UnifiedTestFramework.init)
    if not success then
        addError("initialization", "Failed to initialize test framework", error, "Check framework dependencies and configuration")
        printColored("red", "❌ Failed to initialize test framework: " .. tostring(error))
        return false
    end
    
    -- Discover tests if not already done
    if testRegistry.totalTests == 0 then
        discoverTests()
    end
    
    -- Execute tests
    local startTime = os.clock()
    local results = {
        total = 0,
        passed = 0,
        failed = 0,
        errors = {}
    }
    
    -- Run tests based on type and filter
    for type, typeConfig in pairs(config.testTypes) do
        if typeConfig.enabled and (not testType or type == testType) then
            local testFiles = testRegistry.discoveredTests[type] or {}
            
            for _, testFile in ipairs(testFiles) do
                if not filter or string.match(testFile, filter) then
                    printColored("blue", "  Running: " .. testFile)
                    
                    local fileSuccess, fileError = pcall(function()
                        return UnifiedTestFramework.runTestFile(testFile)
                    end)
                    
                    if fileSuccess then
                        results.total = results.total + 1
                        results.passed = results.passed + 1
                        printColored("green", "    ✅ Passed")
                    else
                        results.total = results.total + 1
                        results.failed = results.failed + 1
                        table.insert(results.errors, {
                            file = testFile,
                            error = fileError
                        })
                        printColored("red", "    ❌ Failed: " .. tostring(fileError))
                        
                        -- Add detailed error information
                        addError("test_execution", "Test file failed: " .. testFile, fileError, "Check test file syntax and dependencies")
                    end
                end
            end
        end
    end
    
    local endTime = os.clock()
    local duration = endTime - startTime
    
    -- Display results
    printSubHeader("📊 Test Results")
    printColored("white", "Total tests: " .. results.total)
    printColored("green", "Passed: " .. results.passed)
    printColored("red", "Failed: " .. results.failed)
    printColored("blue", "Duration: " .. string.format("%.2f", duration) .. " seconds")
    
    if results.failed > 0 then
        printSubHeader("❌ Failed Tests")
        for _, error in ipairs(results.errors) do
            printColored("red", "  " .. error.file .. ": " .. tostring(error.error))
        end
    end
    
    return results.failed == 0
end

-- Watch mode implementation
local function startWatchMode()
    printHeader("👀 Watch Mode")
    printColored("yellow", "Watching for file changes... (Press Ctrl+C to stop)")
    
    -- This is a simplified watch mode - in a real implementation,
    -- you would use file system events or polling
    while true do
        -- Check for file changes (simplified)
        local hasChanges = false
        
        -- Run tests if changes detected
        if hasChanges then
            printColored("blue", "\n🔄 Changes detected, re-running tests...")
            runTests()
        end
        
        -- Sleep for a short interval
        os.execute("sleep 1")
    end
end

-- Main interactive loop
local function runInteractive()
    while true do
        showMainMenu()
        
        local choice = io.read("*n")
        if not choice then
            printColored("red", "Invalid input. Please enter a number.")
            goto continue
        end
        
        if choice == 1 then
            -- Run all tests
            runTests()
        elseif choice == 2 then
            -- Run specific test type
            local options = showTestTypeMenu()
            local typeChoice = io.read("*n")
            if typeChoice and options[typeChoice] then
                runTests(options[typeChoice])
            end
        elseif choice == 3 then
            -- Run tests with filter
            showFilterMenu()
            local filter = io.read("*l")
            if filter and filter ~= "none" then
                runTests(nil, filter)
            end
        elseif choice == 4 then
            -- Watch mode
            startWatchMode()
        elseif choice == 5 then
            -- Show test statistics
            printHeader("📈 Test Statistics")
            printColored("white", "Total discovered tests: " .. testRegistry.totalTests)
            for testType, testFiles in pairs(testRegistry.discoveredTests) do
                printColored("cyan", testType .. " tests: " .. #testFiles)
            end
        elseif choice == 6 then
            -- Show error report
            showErrorReport()
        elseif choice == 7 then
            -- Configure settings
            showConfigurationMenu()
            local configChoice = io.read("*n")
            if configChoice == 1 then
                config.parallel = not config.parallel
            elseif configChoice == 2 then
                config.verbose = not config.verbose
            elseif configChoice == 3 then
                printColored("white", "Enter new timeout (seconds): ")
                local timeout = io.read("*n")
                if timeout then
                    config.timeout = timeout
                end
            elseif configChoice == 4 then
                config.watch = not config.watch
            end
        elseif choice == 8 then
            -- Exit
            printColored("green", "👋 Goodbye!")
            break
        else
            printColored("red", "Invalid choice. Please enter a number between 1 and 8.")
        end
        
        ::continue::
        printColored("white", "\nPress Enter to continue...")
        io.read("*l")
    end
end

-- Command line interface
local function parseArgs(...)
    local args = {...}
    local i = 1
    
    while i <= #args do
        local arg = args[i]
        
        if arg == "--interactive" or arg == "-i" then
            config.interactive = true
        elseif arg == "--non-interactive" then
            config.interactive = false
        elseif arg == "--watch" or arg == "-w" then
            config.watch = true
        elseif arg == "--filter" then
            i = i + 1
            if i <= #args then
                config.filter = args[i]
            end
        elseif arg == "--type" then
            i = i + 1
            if i <= #args then
                local testType = args[i]
                for type, _ in pairs(config.testTypes) do
                    config.testTypes[type].enabled = (type == testType)
                end
            end
        elseif arg == "--verbose" or arg == "-v" then
            config.verbose = true
        elseif arg == "--parallel" then
            config.parallel = true
        elseif arg == "--help" or arg == "-h" then
            print("Interactive Test Runner for Orbit Jump")
            print("Usage: lua interactive_test_runner.lua [options]")
            print("")
            print("Options:")
            print("  --interactive, -i     Start interactive mode (default)")
            print("  --non-interactive     Run tests directly without menu")
            print("  --watch, -w          Enable watch mode")
            print("  --filter <pattern>   Filter tests by pattern")
            print("  --type <testtype>    Run only specific test type")
            print("  --verbose, -v        Enable verbose output")
            print("  --parallel           Enable parallel execution")
            print("  --help, -h           Show this help message")
            os.exit(0)
        end
        
        i = i + 1
    end
end

-- Main entry point
local function main(...)
    printColored("blue", "🎮 Interactive Test Runner v1.0")
    printColored("blue", "Phase 5: Enhanced Developer Experience")
    
    -- Parse command line arguments
    parseArgs(...)
    
    -- Discover tests
    discoverTests()
    
    if config.interactive then
        runInteractive()
    else
        -- Non-interactive mode
        runTests()
    end
end

-- Export the module
return {
    main = main,
    runTests = runTests,
    showErrorReport = showErrorReport,
    discoverTests = discoverTests,
    config = config
} 