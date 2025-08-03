-- Orbit Jump Unit Test Runner
-- Fast unit tests for individual components and systems
local lfs = require("lfs")
local path = require("path")
-- Test framework setup
local TestFramework = require("unified_test_framework")
local framework = TestFramework.new()
-- Configuration
local UNIT_TEST_DIRS = {
    "unit/core",
    "unit/systems",
    "unit/ui",
    "unit/utils"
}
local EXCLUDED_PATTERNS = {
    "test_performance_",  -- Performance tests go in performance suite
    "test_stress_",       -- Stress tests are integration
    "test_integration_"   -- Integration tests
}
-- Utility functions
local function should_exclude_file(filename)
    for _, pattern in ipairs(EXCLUDED_PATTERNS) do
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
                    if file:match("^test_") and not should_exclude_file(file) then
                        table.insert(test_files, full_path)
                    end
                end
            end
        end
    end
    scan_dir(directory)
    return test_files
end
-- Main execution
local function run_unit_tests()
    print("=== Orbit Jump Unit Test Suite ===")
    print("Running fast unit tests...")
    print("")
    local total_tests = 0
    local passed_tests = 0
    local failed_tests = 0
    local start_time = os.clock()
    -- Find all unit test files
    local all_test_files = {}
    for _, dir in ipairs(UNIT_TEST_DIRS) do
        if lfs.attributes(dir) then
            local files = find_test_files(dir)
            for _, file in ipairs(files) do
                table.insert(all_test_files, file)
            end
        end
    end
    -- Sort files for consistent execution order
    table.sort(all_test_files)
    print(string.format("Found %d unit test files", #all_test_files))
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
    end
    local end_time = os.clock()
    local duration = end_time - start_time
    -- Print summary
    print("")
    print("=== Unit Test Summary ===")
    print(string.format("Total tests: %d", total_tests))
    print(string.format("Passed: %d", passed_tests))
    print(string.format("Failed: %d", failed_tests))
    print(string.format("Duration: %.3f seconds", duration))
    if failed_tests > 0 then
        print("")
        print("❌ Some unit tests failed!")
        os.exit(1)
    else
        print("")
        print("✅ All unit tests passed!")
    end
end
-- Run the tests
run_unit_tests()