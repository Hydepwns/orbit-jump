#!/usr/bin/env lua
-- Comprehensive Test Runner for Orbit Jump
-- Runs all test suites and generates coverage reports

local Utils = require("src.utils.utils")

Utils.Logger.info("================================")
Utils.Logger.info("Orbit Jump Comprehensive Test Suite")
Utils.Logger.info("================================\n")

local allPassed = true

-- Setup mocks for all tests
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Run Core Tests
Utils.Logger.info("\n--- Core Tests ---")
local coreTests = {
    Utils.require("tests.core.test_game_logic"),
    Utils.require("tests.core.test_game_state"),
    Utils.require("tests.core.test_game_state_extended"),
    Utils.require("tests.core.test_config"),
    Utils.require("tests.core.test_game_simple")
}

for _, test in ipairs(coreTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Utility Tests
Utils.Logger.info("\n--- Utility Tests ---")
local utilityTests = {
    Utils.require("tests.utils.test_utils"),
    Utils.require("tests.utils.test_camera"),
    Utils.require("tests.utils.test_renderer"),
    Utils.require("tests.core.test_renderer")
}

for _, test in ipairs(utilityTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run System Tests
Utils.Logger.info("\n--- System Tests ---")
local systemTests = {
    Utils.require("tests.systems.test_collision_system"),
    Utils.require("tests.systems.test_particle_system"),
    Utils.require("tests.systems.test_progression_system"),
    Utils.require("tests.systems.test_ring_system"),
    Utils.require("tests.systems.test_save_system"),
    Utils.require("tests.systems.test_player_system"),
    Utils.require("tests.systems.test_artifact_system"),
    Utils.require("tests.systems.test_warp_drive"),
    Utils.require("tests.systems.test_map_system"),
    Utils.require("tests.systems.test_ring_constellations")
}

for _, test in ipairs(systemTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Audio Tests
Utils.Logger.info("\n--- Audio Tests ---")
local audioTests = {
    Utils.require("tests.audio.test_sound_manager"),
    Utils.require("tests.audio.test_sound_generator")
}

for _, test in ipairs(audioTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run UI Tests
Utils.Logger.info("\n--- UI Tests ---")
local uiTests = {
    Utils.require("tests.ui.test_ui_system"),
    Utils.require("tests.ui.test_achievement_system"),
    Utils.require("tests.ui.test_upgrade_system"),
    Utils.require("tests.ui.test_lore_viewer"),
    Utils.require("tests.ui.test_tutorial_system"),
    Utils.require("tests.ui.test_settings_menu"),
    Utils.require("tests.ui.test_pause_menu")
}

for _, test in ipairs(uiTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run World Tests
Utils.Logger.info("\n--- World Tests ---")
local worldTests = {
    Utils.require("tests.world.test_world_generator"),
    Utils.require("tests.world.test_cosmic_events"),
    Utils.require("tests.world.test_warp_zones"),
    Utils.require("tests.world.test_planet_lore")
}

for _, test in ipairs(worldTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Performance Tests
Utils.Logger.info("\n--- Performance Tests ---")
local performanceTests = {
    Utils.require("tests.performance.test_performance_monitor"),
    Utils.require("tests.performance.test_performance_system")
}

for _, test in ipairs(performanceTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Development Tools Tests
Utils.Logger.info("\n--- Development Tools Tests ---")
local devTests = {
    Utils.require("tests.dev.test_dev_tools")
}

for _, test in ipairs(devTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Blockchain Tests
Utils.Logger.info("\n--- Blockchain Tests ---")
local blockchainTests = {
    Utils.require("tests.blockchain.test_blockchain_integration")
}

for _, test in ipairs(blockchainTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Run Integration Tests
Utils.Logger.info("\n--- Integration Tests ---")
local integrationTests = {
    Utils.require("tests.integration_tests.test_integration")
}

for _, test in ipairs(integrationTests) do
    if not test:run() then
        allPassed = false
    end
end

-- Generate coverage report
Utils.Logger.info("\n\n--- Coverage Report ---")
local TestCoverage = Utils.require("tests.test_coverage")
TestCoverage.generateReport()

Utils.Logger.info("\n================================")
if allPassed then
    Utils.Logger.info("✅ All tests passed!")
    os.exit(0)
else
    Utils.Logger.info("❌ Some tests failed!")
    os.exit(1)
end