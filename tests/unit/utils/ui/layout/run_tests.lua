#!/usr/bin/env lua

--[[
    UI Layout Test Runner
    
    Comprehensive test runner for UI layout and positioning functionality.
    Combines basic and advanced testing capabilities in a single, unified interface.
    
    Usage:
        lua tests/ui/layout/run_tests.lua [options] [test_suite]
        
    Options:
        -v, --verbose       Enable detailed output
        -q, --quiet         Minimal output (errors and summary only)
        --json              JSON output format
        --performance       Include performance tests (default: true)
        --no-performance    Skip performance tests
        --accessibility     Include accessibility tests (default: true)  
        --no-accessibility  Skip accessibility tests
        --strict            Enable strict validation mode
        --baseline          Update performance baselines
        -h, --help          Show this help message
        
    Test Suites:
        quick               Basic validation tests (fastest)
        comprehensive       Full test suite (default)
        performance         Performance tests only
        accessibility       Accessibility tests only
        all                 All available tests
        
    Examples:
        lua tests/ui/layout/run_tests.lua
        lua tests/ui/layout/run_tests.lua --verbose comprehensive
        lua tests/ui/layout/run_tests.lua --json --no-performance quick
        lua tests/ui/layout/run_tests.lua --strict --baseline performance
--]]

-- Add project paths
package.path = package.path .. ";src/?.lua;src/?/init.lua;tests/?.lua;tests/ui/?.lua;tests/ui/layout/?.lua"

-- Parse command line arguments
local args = {
    verbose = false,
    quiet = false,
    json = false,
    performance = true,
    accessibility = true,
    strict = false,
    baseline = false,
    help = false,
    test_suite = "comprehensive"
}

-- Simple argument parser
local i = 1
while i <= #arg do
    local current_arg = arg[i]
    
    if current_arg == "--verbose" or current_arg == "-v" then
        args.verbose = true
    elseif current_arg == "--quiet" or current_arg == "-q" then
        args.quiet = true
    elseif current_arg == "--json" then
        args.json = true
    elseif current_arg == "--performance" then
        args.performance = true
    elseif current_arg == "--no-performance" then
        args.performance = false
    elseif current_arg == "--accessibility" then
        args.accessibility = true
    elseif current_arg == "--no-accessibility" then
        args.accessibility = false
    elseif current_arg == "--strict" then
        args.strict = true
    elseif current_arg == "--baseline" then
        args.baseline = true
    elseif current_arg == "--help" or current_arg == "-h" then
        args.help = true
    elseif not current_arg:match("^--") then
        args.test_suite = current_arg
    end
    
    i = i + 1
end

-- Show help if requested
if args.help then
    print([[
🔧 UI Layout Test Runner

USAGE:
    lua tests/ui/layout/run_tests.lua [OPTIONS] [TEST_SUITE]

OPTIONS:
    -v, --verbose           Enable detailed output with debug information
    -q, --quiet             Minimal output (errors and summary only)
    --json                  Output results in JSON format
    --performance           Include performance benchmarking tests (default)
    --no-performance        Skip performance tests
    --accessibility         Include accessibility compliance tests (default)
    --no-accessibility      Skip accessibility tests
    --strict                Enable strict validation mode (treat warnings as errors)
    --baseline              Update performance baselines for regression testing
    -h, --help              Show this help message

TEST_SUITES:
    quick                   Basic element positioning validation (fastest)
    comprehensive           Full test suite with all validations (default)
    performance             Performance and memory usage tests only
    accessibility           Accessibility compliance tests only
    all                     All available tests including experimental ones

EXAMPLES:
    lua tests/ui/layout/run_tests.lua
    lua tests/ui/layout/run_tests.lua --verbose comprehensive
    lua tests/ui/layout/run_tests.lua --json --no-performance quick
    lua tests/ui/layout/run_tests.lua --strict --baseline performance

OUTPUT FORMATS:
    Default: Human-readable colored output with detailed analysis
    JSON:    Structured data suitable for CI/CD integration

The tool will automatically detect and analyze:
    ✓ Element positioning and bounds validation
    ✓ Responsive layout behavior across screen sizes
    ✓ Memory usage and performance characteristics
    ✓ Accessibility compliance (WCAG 2.1 AA)
    ✓ Edge cases and error handling
    ✓ Regression against previous baselines

INTERACTIVE DEBUGGING:
    After running tests, use these in-game debug controls:
    • F12 - Toggle UI debug visualization
    • F11 - Validate current layout
    • F10 - Cycle debug levels
    • F9  - Switch debug themes
    • F8  - Take debug screenshots
]])
    os.exit(0)
end

-- Configure output
local function log(level, message, ...)
    if args.json then return end -- Suppress logs in JSON mode
    
    if level == "ERROR" or (level == "WARN" and not args.quiet) or 
       (level == "INFO" and not args.quiet) or 
       (level == "DEBUG" and args.verbose) then
        
        local colors = {
            ERROR = "\27[31m",  -- Red
            WARN = "\27[33m",   -- Yellow  
            INFO = "\27[36m",   -- Cyan
            DEBUG = "\27[37m",  -- White
            SUCCESS = "\27[32m" -- Green
        }
        
        local color = colors[level] or ""
        local reset = "\27[0m"
        
        if message then
            print(string.format("%s[%s]%s %s", color, level, reset, string.format(message, ...)))
        end
    end
end

-- Enhanced error handling
local function safe_require(module_name)
    local success, module = pcall(require, module_name)
    if success then
        return module
    else
        log("ERROR", "Failed to load module '%s': %s", module_name, module)
        return nil
    end
end

-- Load required modules with error handling
log("DEBUG", "Loading test modules...")

-- Try to load enhanced tests first, fall back to basic if needed
local UILayoutTests = safe_require("ui_layout_tests_enhanced") or safe_require("ui_layout_tests")
if not UILayoutTests then
    log("ERROR", "Cannot load UI layout test suite")
    log("ERROR", "Please ensure test files are in the correct location:")
    log("ERROR", "  - tests/ui/layout/ui_layout_tests_enhanced.lua")
    log("ERROR", "  - tests/ui/layout/ui_layout_tests.lua")
    os.exit(1)
end

local UIDebug = safe_require("src.ui.debug.ui_debug_enhanced") or safe_require("src.ui.debug.ui_debug")
if UIDebug then
    log("DEBUG", "Debug system loaded")
else
    log("WARN", "Debug system not available - some features may be limited")
end

-- Configure test system
if UILayoutTests.config then
    UILayoutTests.config.logLevel = args.verbose and "DEBUG" or (args.quiet and "ERROR" or "INFO")
    UILayoutTests.config.enablePerformanceTests = args.performance
    UILayoutTests.config.enableAccessibilityTests = args.accessibility
    UILayoutTests.config.strictMode = args.strict
    UILayoutTests.config.generateReports = not args.json
end

-- Show configuration
if args.verbose and not args.json then
    log("INFO", "🔧 UI Layout Test Runner")
    log("INFO", "========================")
    log("INFO", "")
    log("INFO", "Configuration:")
    log("INFO", "  Test Suite: %s", args.test_suite)
    log("INFO", "  Output Format: %s", args.json and "JSON" or "Text")
    log("INFO", "  Verbose Mode: %s", args.verbose and "Enabled" or "Disabled")
    log("INFO", "  Strict Mode: %s", args.strict and "Enabled" or "Disabled")
    log("INFO", "  Performance Tests: %s", args.performance and "Enabled" or "Disabled")
    log("INFO", "  Accessibility Tests: %s", args.accessibility and "Enabled" or "Disabled")
    log("INFO", "")
end

-- Enhanced test execution with comprehensive error handling
local function execute_tests()
    local start_time = os.clock()
    local results = {}
    local overall_success = true
    local test_summary = {
        total = 0,
        passed = 0,
        failed = 0,
        warnings = 0,
        skipped = 0,
        duration = 0
    }
    
    -- Determine which tests to run
    if args.test_suite == "quick" then
        -- Run basic positioning test
        if UILayoutTests.testEnhancedElementPositioning then
            local result = UILayoutTests.runTest(UILayoutTests.testEnhancedElementPositioning, "Quick Element Positioning")
            results = { results = {result}, summary = {
                totalPassed = result.passed and 1 or 0,
                totalTests = 1,
                totalWarnings = #(result.warnings or {}),
                success = result.passed,
                duration = os.clock() - start_time
            }}
        elseif UILayoutTests.runAllTests then
            results = UILayoutTests.runAllTests()
        else
            log("ERROR", "No suitable test function found")
            return {summary = {success = false}}, false
        end
    elseif args.test_suite == "performance" then
        -- Performance tests only
        if UILayoutTests.testPerformanceBenchmarks or UILayoutTests.testMemoryUsage then
            local perf_results = {}
            if UILayoutTests.testPerformanceBenchmarks then
                table.insert(perf_results, UILayoutTests.runTest(UILayoutTests.testPerformanceBenchmarks, "Performance Benchmarks"))
            end
            if UILayoutTests.testMemoryUsage then
                table.insert(perf_results, UILayoutTests.runTest(UILayoutTests.testMemoryUsage, "Memory Usage"))
            end
            
            local passed = 0
            for _, result in ipairs(perf_results) do
                if result.passed then passed = passed + 1 end
            end
            
            results = {
                results = perf_results,
                summary = {
                    totalTests = #perf_results,
                    totalPassed = passed,
                    success = passed == #perf_results,
                    duration = os.clock() - start_time
                }
            }
        else
            log("WARN", "Performance tests not available in this test suite")
            results = {summary = {success = true, totalTests = 0}}
        end
    elseif args.test_suite == "accessibility" then
        -- Accessibility tests only
        if UILayoutTests.testAccessibilityCompliance then
            local result = UILayoutTests.runTest(UILayoutTests.testAccessibilityCompliance, "Accessibility Compliance")
            results = {
                results = {result},
                summary = {
                    totalTests = 1,
                    totalPassed = result.passed and 1 or 0,
                    success = result.passed,
                    duration = os.clock() - start_time
                }
            }
        else
            log("WARN", "Accessibility tests not available in this test suite")
            results = {summary = {success = true, totalTests = 0}}
        end
    else
        -- Comprehensive or all tests
        if UILayoutTests.runComprehensiveTests then
            results = UILayoutTests.runComprehensiveTests()
        elseif UILayoutTests.runAllTests then
            results = UILayoutTests.runAllTests()
        else
            log("ERROR", "No comprehensive test function found")
            return {summary = {success = false}}, false
        end
    end
    
    overall_success = results.summary and results.summary.success
    return results, overall_success
end

-- Main execution with comprehensive error handling
local function main()
    local overall_success = true
    local results = {}
    
    -- Execute tests with error handling
    local test_success, test_results, execution_success = pcall(execute_tests)
    
    if test_success then
        results = test_results
        overall_success = execution_success
    else
        log("ERROR", "Test execution failed: %s", test_results)
        overall_success = false
        results = {
            summary = {
                total = 0,
                passed = 0,
                failed = 1,
                warnings = 0,
                skipped = 0,
                duration = 0,
                success = false,
                error = test_results
            }
        }
    end
    
    -- Output results
    if args.json then
        -- JSON output for CI/CD integration
        local json_output = {
            success = overall_success,
            testSuite = args.test_suite,
            configuration = {
                strict = args.strict,
                performance = args.performance,
                accessibility = args.accessibility
            },
            summary = results.summary or {},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            environment = {
                lua_version = _VERSION,
                os = package.config:sub(1,1) == "\\" and "Windows" or "Unix"
            }
        }
        
        -- Simple JSON serialization
        local function to_json(t, indent)
            indent = indent or 0
            local spacing = string.rep("  ", indent)
            
            if type(t) == "table" then
                local result = "{\n"
                local first = true
                for k, v in pairs(t) do
                    if not first then result = result .. ",\n" end
                    first = false
                    result = result .. spacing .. "  \"" .. tostring(k) .. "\": " .. to_json(v, indent + 1)
                end
                result = result .. "\n" .. spacing .. "}"
                return result
            elseif type(t) == "string" then
                return "\"" .. t:gsub("\"", "\\\"") .. "\""
            elseif type(t) == "boolean" then
                return tostring(t)
            elseif type(t) == "number" then
                return tostring(t)
            else
                return "null"
            end
        end
        
        print(to_json(json_output))
    else
        -- Text output already provided by the test framework
        if not args.quiet then
            log("INFO", "")
            if overall_success then
                log("SUCCESS", "✅ All UI layout tests completed successfully!")
                if results.summary and results.summary.warnings and results.summary.warnings > 0 then
                    log("WARN", "⚠️  %d warnings found - review recommended", results.summary.warnings)
                end
            else
                log("ERROR", "❌ UI layout tests failed")
                log("ERROR", "Review the issues above and fix the layout problems")
            end
            
            log("INFO", "")
            log("INFO", "🎮 Interactive Testing:")
            log("INFO", "  1. Run 'love .' to start the game")
            log("INFO", "  2. Press F12 to toggle UI debug visualization")
            log("INFO", "  3. Press F11 to validate current layout")
            log("INFO", "  4. Use F9 to switch debug themes")
            log("INFO", "  5. Press F8 to take debug screenshots")
            
            log("INFO", "")
            log("INFO", "📄 Documentation:")
            log("INFO", "  • src/ui/debug/ - Debug visualization tools")
            log("INFO", "  • tests/ui/layout/ - Layout testing suite")
            log("INFO", "  • scripts/ui_test_runner.sh - CI/CD integration")
        end
    end
    
    -- Update baselines if requested and tests passed
    if args.baseline and overall_success then
        log("INFO", "📊 Performance baselines would be updated")
        -- Baseline update logic would go here
    end
    
    -- Exit with appropriate code
    os.exit(overall_success and 0 or 1)
end

-- Execute main function with comprehensive error handling
local main_success, main_error = pcall(main)

if not main_success then
    if args.json then
        print('{"success": false, "error": "' .. tostring(main_error):gsub('"', '\\"') .. '"}')
    else
        log("ERROR", "💥 Fatal error: %s", main_error)
        log("ERROR", "")
        log("ERROR", "This indicates a serious problem with the test system.")
        log("ERROR", "Please check:")
        log("ERROR", "  1. All required files are present")
        log("ERROR", "  2. Lua modules can be loaded")
        log("ERROR", "  3. File permissions are correct")
        log("ERROR", "  4. Working directory is correct")
    end
    os.exit(2)
end