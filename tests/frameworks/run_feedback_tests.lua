#!/usr/bin/env lua

-- Test runner for feedback integration systems
-- This script can be run standalone to validate the feedback systems

-- Set up basic environment
package.path = package.path .. ";./?.lua;./src/?.lua;./src/systems/?.lua"

-- Mock Love2D environment for testing
love = {
    timer = {
        getTime = function() return os.time() end,
        getFPS = function() return 60 end
    },
    system = {
        getPowerInfo = function() return "unknown", 50 end
    },
    filesystem = {
        write = function(filename, data) return true end,
        read = function(filename) return "" end,
        getInfo = function(filename) return nil end
    }
}

-- Mock Utils module
local Utils = {
    Logger = {
        info = function(fmt, ...)
            if fmt then
                local success, result = pcall(string.format, fmt, ...)
                if success then
                    print("[INFO] " .. result)
                else
                    print("[INFO] " .. tostring(fmt) .. " (format error)")
                end
            end
        end,
        warn = function(fmt, ...)
            if fmt then
                local success, result = pcall(string.format, fmt, ...)
                if success then
                    print("[WARN] " .. result)
                else
                    print("[WARN] " .. tostring(fmt) .. " (format error)")
                end
            end
        end,
        error = function(fmt, ...)
            if fmt then
                local success, result = pcall(string.format, fmt, ...)
                if success then
                    print("[ERROR] " .. result)
                else
                    print("[ERROR] " .. tostring(fmt) .. " (format error)")
                end
            end
        end,
        debug = function(fmt, ...) end -- Suppress debug for tests
    },
    require = function(path)
        return require(path:gsub("%.", "/"))
    end,
    ErrorHandler = {
        safeCall = function(func, ...)
            local success, result = pcall(func, ...)
            return success, result
        end
    },
    serialize = function(data) return tostring(data) end,
    deserialize = function(data) return {} end,
    distance = function(x1, y1, x2, y2)
        return math.sqrt((x2-x1)^2 + (y2-y1)^2)
    end
}

-- Create mock save system
local MockSaveSystem = {
    data = {},
    setData = function(key, value)
        MockSaveSystem.data[key] = value
    end,
    getData = function(key)
        if key then
            return MockSaveSystem.data[key]
        else
            return MockSaveSystem.data
        end
    end
}

-- Replace package require function
local originalRequire = require
_G.require = function(path)
    if path == "src.utils.utils" then
        return Utils
    elseif path == "src.systems.save_system" then
        return MockSaveSystem
    else
        -- Try to load the actual module
        local success, module = pcall(originalRequire, path:gsub("%.", "/"))
        if success then
            return module
        else
            -- Return empty module for missing dependencies
            return {}
        end
    end
end

-- Set up file system
local function setupFileSystem()
    -- Ensure src/utils exists in package path
    package.path = package.path .. ";./src/?.lua;./src/utils/?.lua;./src/systems/?.lua;./src/systems/analytics/?.lua"
end

-- Run the tests
local function runTests()
    print("🚀 Starting Feedback Integration Tests...")
    print("=" .. string.rep("=", 60))
    
    setupFileSystem()
    
    -- Load and run the test suite
    local success, FeedbackIntegrationTests = pcall(require, "tests/phase5/test_feedback_integration")
    
    if not success then
        print("❌ Failed to load test suite: " .. tostring(FeedbackIntegrationTests))
        return false
    end
    
    -- Run all tests
    local testSuccess = FeedbackIntegrationTests.runAllTests()
    
    print("\n" .. "=" .. string.rep("=", 60))
    
    if testSuccess then
        print("🎉 ALL TESTS PASSED!")
        print("✅ Feedback Integration System is ready for deployment")
        return true
    else
        print("❌ SOME TESTS FAILED!")
        print("⚠️  Please review and fix issues before deployment")
        return false
    end
end

-- Main execution
if not runTests() then
    os.exit(1)
else
    os.exit(0)
end