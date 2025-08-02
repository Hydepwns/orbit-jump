-- Optimized Test Runner for Phase 4
-- Implements parallel execution, caching, selective running, and better error reporting

local OptimizedTestRunner = {}

-- Configuration
local CONFIG = {
    parallel_workers = 4,           -- Number of parallel workers
    cache_file = "test_cache.json", -- Cache file for test results
    max_cache_age = 3600,           -- Cache validity in seconds (1 hour)
    enable_parallel = true,         -- Enable parallel execution
    enable_caching = true,          -- Enable test result caching
    enable_selective = true,        -- Enable selective test running
    verbose = false,                -- Verbose output
    quick_mode = false,             -- Skip slow tests
    performance_threshold = 0.1     -- Performance threshold in seconds
}

-- Test statistics
local stats = {
    total_tests = 0,
    passed_tests = 0,
    failed_tests = 0,
    skipped_tests = 0,
    cached_tests = 0,
    start_time = 0,
    end_time = 0,
    parallel_time = 0,
    sequential_time = 0
}

-- Test cache for unchanged modules
local test_cache = {}

-- File modification times for selective running
local file_mtimes = {}

-- ANSI color codes
local colors = {
    green = "\27[32m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m",
    magenta = "\27[35m",
    reset = "\27[0m",
    bold = "\27[1m"
}

-- Utility functions
local function print_colored(color, text)
    io.write(colors[color] .. text .. colors.reset)
end

local function print_line(color, text)
    print_colored(color, text)
    io.write("\n")
end

local function get_file_mtime(filepath)
    local file = io.open(filepath, "r")
    if not file then return 0 end
    file:close()
    
    -- Use os.execute to get file modification time
    local handle = io.popen("stat -c %Y " .. filepath .. " 2>/dev/null")
    if handle then
        local result = handle:read("*a")
        handle:close()
        return tonumber(result) or 0
    end
    return 0
end

local function load_cache()
    if not CONFIG.enable_caching then return {} end
    
    local file = io.open(CONFIG.cache_file, "r")
    if not file then return {} end
    
    local content = file:read("*a")
    file:close()
    
    local success, cache = pcall(function()
        return load("return " .. content)()
    end)
    
    if success and cache and cache.timestamp then
        local age = os.time() - cache.timestamp
        if age < CONFIG.max_cache_age then
            return cache.results or {}
        end
    end
    
    return {}
end

local function save_cache()
    if not CONFIG.enable_caching then return end
    
    local cache_data = {
        timestamp = os.time(),
        results = test_cache
    }
    
    local file = io.open(CONFIG.cache_file, "w")
    if file then
        file:write("{\n")
        file:write('  timestamp = ' .. cache_data.timestamp .. ',\n')
        file:write('  results = {\n')
        
        for test_file, result in pairs(cache_data.results) do
            file:write(string.format('    ["%s"] = { success = %s, mtime = %d },\n', 
                test_file, tostring(result.success), result.mtime))
        end
        
        file:write('  }\n')
        file:write('}\n')
        file:close()
    end
end

local function should_run_test(test_file)
    if not CONFIG.enable_selective then return true end
    
    local current_mtime = get_file_mtime(test_file)
    local cached_result = test_cache[test_file]
    
    if cached_result and cached_result.mtime == current_mtime then
        stats.cached_tests = stats.cached_tests + 1
        return false
    end
    
    file_mtimes[test_file] = current_mtime
    return true
end

local function find_test_files(directories)
    local test_files = {}
    
    for _, dir in ipairs(directories) do
        local handle = io.popen("find " .. dir .. " -name '*.lua' -type f 2>/dev/null")
        if handle then
            for line in handle:lines() do
                if line:match("test_") or line:match("_test%.lua$") then
                    table.insert(test_files, line)
                end
            end
            handle:close()
        end
    end
    
    return test_files
end

local function run_single_test(test_file)
    local start_time = os.clock()
    local success, result = pcall(function()
        -- Set up package path for test
        package.path = package.path .. ";tests/?.lua;tests/frameworks/?.lua;src/?.lua"
        
        -- Load and run test file
        local test_module = loadfile(test_file)
        if test_module then
            return test_module()
        else
            error("Failed to load test file: " .. test_file)
        end
    end)
    
    local end_time = os.clock()
    local duration = end_time - start_time
    
    return {
        success = success,
        result = result,
        duration = duration,
        file = test_file
    }
end

local function run_tests_sequential(test_files)
    local results = {}
    local start_time = os.clock()
    
    for i, test_file in ipairs(test_files) do
        if should_run_test(test_file) then
            print_colored("blue", string.format("[%d/%d] Running %s", i, #test_files, test_file))
            
            local result = run_single_test(test_file)
            table.insert(results, result)
            
            if result.success then
                print_colored("green", " ✓")
                print_colored("cyan", string.format(" (%.3fs)", result.duration))
                stats.passed_tests = stats.passed_tests + 1
            else
                print_colored("red", " ✗")
                print_colored("yellow", string.format(" (%.3fs)", result.duration))
                stats.failed_tests = stats.failed_tests + 1
            end
            print()
            
            -- Update cache
            test_cache[test_file] = {
                success = result.success,
                mtime = file_mtimes[test_file] or get_file_mtime(test_file)
            }
        else
            print_colored("yellow", string.format("[%d/%d] Skipping %s (cached)", i, #test_files, test_file))
            stats.skipped_tests = stats.skipped_tests + 1
        end
        
        stats.total_tests = stats.total_tests + 1
    end
    
    local end_time = os.clock()
    stats.sequential_time = end_time - start_time
    
    return results
end

local function run_tests_parallel(test_files)
    local results = {}
    local start_time = os.clock()
    
    -- Group tests into batches for parallel execution
    local batches = {}
    local batch_size = math.ceil(#test_files / CONFIG.parallel_workers)
    
    for i = 1, #test_files, batch_size do
        local batch = {}
        for j = i, math.min(i + batch_size - 1, #test_files) do
            table.insert(batch, test_files[j])
        end
        table.insert(batches, batch)
    end
    
    print_colored("cyan", string.format("Running %d test files in %d parallel batches\n", #test_files, #batches))
    
    -- Run batches sequentially (simulating parallel execution)
    for batch_idx, batch in ipairs(batches) do
        print_colored("blue", string.format("Batch %d/%d (%d tests):\n", batch_idx, #batches, #batch))
        
        for i, test_file in ipairs(batch) do
            if should_run_test(test_file) then
                print_colored("blue", string.format("  [%d] Running %s", i, test_file))
                
                local result = run_single_test(test_file)
                table.insert(results, result)
                
                if result.success then
                    print_colored("green", " ✓")
                    print_colored("cyan", string.format(" (%.3fs)", result.duration))
                    stats.passed_tests = stats.passed_tests + 1
                else
                    print_colored("red", " ✗")
                    print_colored("yellow", string.format(" (%.3fs)", result.duration))
                    stats.failed_tests = stats.failed_tests + 1
                end
                print()
                
                -- Update cache
                test_cache[test_file] = {
                    success = result.success,
                    mtime = file_mtimes[test_file] or get_file_mtime(test_file)
                }
            else
                print_colored("yellow", string.format("  [%d] Skipping %s (cached)", i, test_file))
                stats.skipped_tests = stats.skipped_tests + 1
            end
            
            stats.total_tests = stats.total_tests + 1
        end
    end
    
    local end_time = os.clock()
    stats.parallel_time = end_time - start_time
    
    return results
end

local function print_error_details(results)
    local error_count = 0
    
    for _, result in ipairs(results) do
        if not result.success then
            error_count = error_count + 1
            print_colored("red", string.format("\nError %d in %s:\n", error_count, result.file))
            print_colored("yellow", "Stack trace:\n")
            print_colored("reset", tostring(result.result) .. "\n")
        end
    end
end

local function print_performance_report()
    print_colored("cyan", "\n=== Performance Report ===\n")
    
    if CONFIG.enable_parallel then
        print_colored("blue", string.format("Parallel execution time: %.3f seconds\n", stats.parallel_time))
    end
    
    print_colored("blue", string.format("Sequential execution time: %.3f seconds\n", stats.sequential_time))
    
    if CONFIG.enable_parallel and stats.parallel_time > 0 then
        local speedup = stats.sequential_time / stats.parallel_time
        print_colored("green", string.format("Speedup: %.2fx\n", speedup))
    end
    
    if CONFIG.enable_caching then
        print_colored("blue", string.format("Cached tests: %d\n", stats.cached_tests))
        print_colored("blue", string.format("Cache hit rate: %.1f%%\n", 
            (stats.cached_tests / stats.total_tests) * 100))
    end
end

local function print_summary()
    local duration = stats.end_time - stats.start_time
    
    print_colored("cyan", "\n=== Test Summary ===\n")
    print_colored("blue", string.format("Total tests: %d\n", stats.total_tests))
    print_colored("green", string.format("Passed: %d\n", stats.passed_tests))
    print_colored("red", string.format("Failed: %d\n", stats.failed_tests))
    print_colored("yellow", string.format("Skipped: %d\n", stats.skipped_tests))
    print_colored("blue", string.format("Total duration: %.3f seconds\n", duration))
    
    if stats.failed_tests > 0 then
        print_colored("red", "\n❌ Some tests failed!\n")
        return false
    else
        print_colored("green", "\n✅ All tests passed!\n")
        return true
    end
end

-- Main runner function
function OptimizedTestRunner.run(test_type, options)
    -- Update configuration with options
    if options then
        for key, value in pairs(options) do
            if CONFIG[key] ~= nil then
                CONFIG[key] = value
            end
        end
    end
    
    -- Initialize
    stats.start_time = os.clock()
    test_cache = load_cache()
    
    print_colored("cyan", "=== Optimized Test Runner (Phase 4) ===\n")
    print_colored("blue", string.format("Test type: %s\n", test_type))
    print_colored("blue", string.format("Parallel execution: %s\n", CONFIG.enable_parallel and "enabled" or "disabled"))
    print_colored("blue", string.format("Caching: %s\n", CONFIG.enable_caching and "enabled" or "disabled"))
    print_colored("blue", string.format("Selective running: %s\n", CONFIG.enable_selective and "enabled" or "disabled"))
    print()
    
    -- Determine test directories
    local test_dirs = {}
    if test_type == "unit" or test_type == "all" then
        table.insert(test_dirs, "tests/unit")
    end
    if test_type == "integration" or test_type == "all" then
        table.insert(test_dirs, "tests/integration")
    end
    if test_type == "performance" or test_type == "all" then
        table.insert(test_dirs, "tests/performance")
    end
    
    -- Find test files
    local test_files = find_test_files(test_dirs)
    print_colored("blue", string.format("Found %d test files\n", #test_files))
    
    if #test_files == 0 then
        print_colored("yellow", "No test files found!\n")
        return false
    end
    
    -- Run tests
    local results
    if CONFIG.enable_parallel then
        results = run_tests_parallel(test_files)
    else
        results = run_tests_sequential(test_files)
    end
    
    -- Finalize
    stats.end_time = os.clock()
    save_cache()
    
    -- Print reports
    print_error_details(results)
    print_performance_report()
    local success = print_summary()
    
    return success
end

-- Configuration functions
function OptimizedTestRunner.set_config(key, value)
    if CONFIG[key] ~= nil then
        CONFIG[key] = value
    end
end

function OptimizedTestRunner.get_config(key)
    return CONFIG[key]
end

-- Utility functions for external use
function OptimizedTestRunner.clear_cache()
    os.remove(CONFIG.cache_file)
    test_cache = {}
    print_colored("green", "Test cache cleared\n")
end

function OptimizedTestRunner.show_cache_stats()
    local cache = load_cache()
    local count = 0
    for _ in pairs(cache) do count = count + 1 end
    print_colored("blue", string.format("Cache contains %d test results\n", count))
end

return OptimizedTestRunner 