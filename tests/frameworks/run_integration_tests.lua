-- Orbit Jump Integration Test Runner
-- Tests for system interactions and game flow
local lfs = require("lfs")
local path = require("path")
-- Test framework setup
local TestFramework = require("unified_test_framework")
local framework = TestFramework.new()
-- Configuration
local INTEGRATION_TEST_DIRS = {
    "integration/gameplay",
    "integration/systems",
    "integration/ui"
}
local INCLUDED_PATTERNS = {
    "test_integration_",
    "test_feedback_",
    "test_addiction_",
    "test_stress_",
    "test_edge_",
    "test_cross_",
    "test_user_experience_",
    "test_blockchain_",
    "test_dev_"
}
-- Utility functions
local function should_include_file(filename)
    for _, pattern in ipairs(INCLUDED_PATTERNS) do
        if filename:find(pattern) then
            return true
        end
    end
    return false
end
local function find_test_files(directory)
    local test_files = {}
    local function scan_dir(dir_path)
        for file in lfs.dir(dir_path) do
            if file ~= "." and file ~= ".." then
                local full_path = path.join(dir_path, file)
                local attr = lfs.attributes(full_path)
                if attr.mode == "directory" then
                    scan_dir(full_path)
                elseif attr.mode == "file" and file:match("%.lua$") then
                    if file:match("^test_") and should_include_file(file) then
                        table.insert(test_files, full_path)
                    end
                end
            end
        end
    end
    scan_dir(directory)
    return test_files
end
-- Test setup and teardown
local function setup_integration_environment()
    print("Setting up integration test environment...")
    -- Initialize game state
    -- Load test fixtures
    -- Set up mock services
    print("Integration environment ready")
end
local function teardown_integration_environment()
    print("Cleaning up integration test environment...")
    -- Clean up game state
    -- Reset mock services
    -- Clear test data
    print("Integration environment cleaned up")
end
-- Main execution
local function run_integration_tests()
    print("=== Orbit Jump Integration Test Suite ===")
    print("Running system interaction tests...")
    print("")
    local total_tests = 0
    local passed_tests = 0
    local failed_tests = 0
    local start_time = os.clock()
    -- Setup integration environment
    setup_integration_environment()
    -- Find all integration test files
    local all_test_files = {}
    for _, dir in ipairs(INTEGRATION_TEST_DIRS) do
        if lfs.attributes(dir) then
            local files = find_test_files(dir)
            for _, file in ipairs(files) do
                table.insert(all_test_files, file)
            end
        end
    end
    -- Sort files for consistent execution order
    table.sort(all_test_files)
    print(string.format("Found %d integration test files", #all_test_files))
    print("")
    -- Run each test file
    for i, test_file in ipairs(all_test_files) do
        local relative_path = test_file:gsub("^.*/tests/", "")
        print(string.format("[%d/%d] Running %s", i, #all_test_files, relative_path))
        local success, result = pcall(function()
            -- Load and run the test file
            local test_module = loadfile(test_file)
            if test_module then
                return test_module()
            else
                error("Failed to load test file: " .. test_file)
            end
        end)
        if success then
            print("  ✓ Passed")
            passed_tests = passed_tests + 1
        else
            print("  ✗ Failed: " .. tostring(result))
            failed_tests = failed_tests + 1
        end
        total_tests = total_tests + 1
        -- Small delay between integration tests to avoid interference
        os.execute("sleep 0.1")
    end
    -- Teardown integration environment
    teardown_integration_environment()
    local end_time = os.clock()
    local duration = end_time - start_time
    -- Print summary
    print("")
    print("=== Integration Test Summary ===")
    print(string.format("Total tests: %d", total_tests))
    print(string.format("Passed: %d", passed_tests))
    print(string.format("Failed: %d", failed_tests))
    print(string.format("Duration: %.3f seconds", duration))
    if failed_tests > 0 then
        print("")
        print("❌ Some integration tests failed!")
        os.exit(1)
    else
        print("")
        print("✅ All integration tests passed!")
    end
end
-- Run the tests
run_integration_tests()