#!/usr/bin/env lua
-- Test runner for orbit jump game

print("================================")
print("Orbit Jump Game Test Suite")
print("================================\n")

local allPassed = true

-- Run unit tests
print("\n--- Unit Tests ---")
local unitTests = require("tests.test_game_logic")
if not unitTests:run() then
    allPassed = false
end

-- Run integration tests
print("\n\n--- Integration Tests ---")
local integrationTests = require("tests.test_game_state")
if not integrationTests:run() then
    allPassed = false
end

print("\n================================")
if allPassed then
    print("All tests passed!")
    os.exit(0)
else
    print("Some tests failed!")
    os.exit(1)
end