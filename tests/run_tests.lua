#!/usr/bin/env lua
-- Comprehensive Test Runner for Orbit Jump
-- Runs all test suites and generates coverage reports

print("================================")
print("Orbit Jump Comprehensive Test Suite")
print("================================\n")

local allPassed = true

-- Setup mocks for all tests
local Mocks = require("tests.mocks")
Mocks.setup()

-- Run Core Tests
print("\n--- Core Tests ---")
local coreTests = {
    require("tests.core.test_game_logic"),
    require("tests.core.test_game_state"),
    require("tests.core.test_game_state_extended"),
    require("tests.core.test_config")
}

for _, test in ipairs(coreTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Utility Tests
print("\n--- Utility Tests ---")
local utilityTests = {
    require("tests.utils.test_utils"),
    require("tests.utils.test_camera"),
    require("tests.utils.test_renderer")
}

for _, test in ipairs(utilityTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run System Tests
print("\n--- System Tests ---")
local systemTests = {
    require("tests.systems.test_collision_system"),
    require("tests.systems.test_particle_system"),
    require("tests.systems.test_progression_system"),
    require("tests.systems.test_ring_system")
}

for _, test in ipairs(systemTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Audio Tests
print("\n--- Audio Tests ---")
local audioTests = {
    require("tests.audio.test_sound_manager"),
    require("tests.audio.test_sound_generator")
}

for _, test in ipairs(audioTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run UI Tests
print("\n--- UI Tests ---")
local uiTests = {
    require("tests.ui.test_ui_system"),
    require("tests.ui.test_achievement_system"),
    require("tests.ui.test_upgrade_system")
}

for _, test in ipairs(uiTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run World Tests
print("\n--- World Tests ---")
local worldTests = {
    require("tests.world.test_world_generator"),
    require("tests.world.test_cosmic_events"),
    require("tests.world.test_warp_zones"),
    require("tests.world.test_planet_lore")
}

for _, test in ipairs(worldTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Performance Tests
print("\n--- Performance Tests ---")
local performanceTests = {
    require("tests.performance.test_performance_monitor")
}

for _, test in ipairs(performanceTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Development Tools Tests
print("\n--- Development Tools Tests ---")
local devTests = {
    require("tests.dev.test_dev_tools")
}

for _, test in ipairs(devTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Blockchain Tests
print("\n--- Blockchain Tests ---")
local blockchainTests = {
    require("tests.blockchain.test_blockchain_integration")
}

for _, test in ipairs(blockchainTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Integration Tests
print("\n--- Integration Tests ---")
local integrationTests = {
    require("tests.integration_tests.test_integration")
}

for _, test in ipairs(integrationTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Generate coverage report
print("\n\n--- Coverage Report ---")
local TestCoverage = require("tests.test_coverage")
TestCoverage.generateReport()

print("\n================================")
if allPassed then
    print("✅ All tests passed!")
    os.exit(0)
else
    print("❌ Some tests failed!")
    os.exit(1)
end