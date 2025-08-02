-- Orbit Jump Performance Test Runner
-- Performance benchmarks and monitoring tests

local lfs = require("lfs")
local path = require("path")

-- Test framework setup
local TestFramework = require("unified_test_framework")
local framework = TestFramework.new()

-- Configuration
local PERFORMANCE_TEST_DIRS = {
    "performance"
}

local PERFORMANCE_PATTERNS = {
    "test_performance_",
    "test_benchmark_",
    "test_stress_"
}

-- Performance thresholds
local PERFORMANCE_THRESHOLDS = {
    unit_test_timeout = 5.0,      -- seconds
    integration_test_timeout = 30.0, -- seconds
    memory_limit = 100 * 1024 * 1024, -- 100MB
    fps_minimum = 30.0,
    load_time_max = 2.0           -- seconds
}

-- Utility functions
local function should_include_file(filename)
    for _, pattern in ipairs(PERFORMANCE_PATTERNS) do
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

-- Performance monitoring
local function get_memory_usage()
    -- Simple memory usage estimation
    local mem = collectgarbage("count") * 1024 -- Convert KB to bytes
    return mem
end

local function check_performance_metrics(test_name, duration, memory_usage)
    local issues = {}
    
    if duration > PERFORMANCE_THRESHOLDS.unit_test_timeout then
        table.insert(issues, string.format("Test took %.2fs (limit: %.1fs)", duration, PERFORMANCE_THRESHOLDS.unit_test_timeout))
    end
    
    if memory_usage > PERFORMANCE_THRESHOLDS.memory_limit then
        table.insert(issues, string.format("Memory usage: %.1fMB (limit: %.1fMB)", 
            memory_usage / (1024 * 1024), PERFORMANCE_THRESHOLDS.memory_limit / (1024 * 1024)))
    end
    
    return issues
end

-- Performance test setup
local function setup_performance_environment()
    print("Setting up performance test environment...")
    
    -- Clear memory
    collectgarbage("collect")
    
    -- Initialize performance monitoring
    -- Set up benchmark data
    
    print("Performance environment ready")
end

local function teardown_performance_environment()
    print("Cleaning up performance test environment...")
    
    -- Clean up benchmark data
    -- Final garbage collection
    
    print("Performance environment cleaned up")
end

-- Main execution
local function run_performance_tests()
    print("=== Orbit Jump Performance Test Suite ===")
    print("Running performance benchmarks...")
    print("")
    
    local total_tests = 0
    local passed_tests = 0
    local failed_tests = 0
    local performance_issues = 0
    local start_time = os.clock()
    
    -- Setup performance environment
    setup_performance_environment()
    
    -- Find all performance test files
    local all_test_files = {}
    for _, dir in ipairs(PERFORMANCE_TEST_DIRS) do
        if lfs.attributes(dir) then
            local files = find_test_files(dir)
            for _, file in ipairs(files) do
                table.insert(all_test_files, file)
            end
        end
    end
    
    -- Sort files for consistent execution order
    table.sort(all_test_files)
    
    print(string.format("Found %d performance test files", #all_test_files))
    print("")
    
    -- Run each test file
    for i, test_file in ipairs(all_test_files) do
        local relative_path = test_file:gsub("^.*/tests/", "")
        print(string.format("[%d/%d] Running %s", i, #all_test_files, relative_path))
        
        local test_start_time = os.clock()
        local initial_memory = get_memory_usage()
        
        local success, result = pcall(function()
            -- Load and run the test file
            local test_module = loadfile(test_file)
            if test_module then
                return test_module()
            else
                error("Failed to load test file: " .. test_file)
            end
        end)
        
        local test_end_time = os.clock()
        local test_duration = test_end_time - test_start_time
        local final_memory = get_memory_usage()
        local memory_usage = final_memory - initial_memory
        
        if success then
            -- Check performance metrics
            local issues = check_performance_metrics(relative_path, test_duration, memory_usage)
            
            if #issues == 0 then
                print(string.format("  ✓ Passed (%.3fs, %.1fKB)", test_duration, memory_usage / 1024))
                passed_tests = passed_tests + 1
            else
                print(string.format("  ⚠ Passed with performance issues (%.3fs, %.1fKB)", test_duration, memory_usage / 1024))
                for _, issue in ipairs(issues) do
                    print("    - " .. issue)
                end
                performance_issues = performance_issues + 1
                passed_tests = passed_tests + 1
            end
        else
            print(string.format("  ✗ Failed: %s (%.3fs)", tostring(result), test_duration))
            failed_tests = failed_tests + 1
        end
        
        total_tests = total_tests + 1
        
        -- Small delay between performance tests
        os.execute("sleep 0.2")
    end
    
    -- Teardown performance environment
    teardown_performance_environment()
    
    local end_time = os.clock()
    local duration = end_time - start_time
    
    -- Print summary
    print("")
    print("=== Performance Test Summary ===")
    print(string.format("Total tests: %d", total_tests))
    print(string.format("Passed: %d", passed_tests))
    print(string.format("Failed: %d", failed_tests))
    print(string.format("Performance issues: %d", performance_issues))
    print(string.format("Duration: %.3f seconds", duration))
    
    if failed_tests > 0 then
        print("")
        print("❌ Some performance tests failed!")
        os.exit(1)
    elseif performance_issues > 0 then
        print("")
        print("⚠️  All tests passed but with performance issues!")
        os.exit(0) -- Don't fail the build for performance warnings
    else
        print("")
        print("✅ All performance tests passed!")
    end
end

-- Run the tests
run_performance_tests() 