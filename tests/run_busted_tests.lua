#!/usr/bin/env lua
-- Busted-style test runner for Orbit Jump

local BustedLite = require("tests.busted")

print("================================")
print("Orbit Jump Test Suite (Busted-style)")
print("================================")

local allPassed = true

-- Test files configuration
-- Each entry can specify whether to use mocks
local testFiles = {
    {file = "tests/core/test_game_logic_busted.lua", useMocks = false},
    -- Add more test files here as we convert them
}

-- Run each test file
for _, testConfig in ipairs(testFiles) do
    -- Reset the test framework for each file
    BustedLite.reset()
    
    -- Setup mocks if needed
    if testConfig.useMocks then
        local Mocks = require("tests.mocks")
        Mocks.setup()
    end
    
    -- Load and run the test file
    local success, err = pcall(dofile, testConfig.file)
    if not success then
        print("\nError loading test file " .. testConfig.file .. ":")
        print(err)
        allPassed = false
    else
        -- Run the tests
        local passed = BustedLite.run()
        if not passed then
            allPassed = false
        end
    end
end

-- Exit with appropriate code
if allPassed then
    print("\n✅ All tests passed!")
    os.exit(0)
else
    print("\n❌ Some tests failed!")
    os.exit(1)
end