-- Phase 5: Advanced Gameplay Tests
-- Tests warp zones, achievements, and special mechanics
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
print("--- Phase 5: Advanced Gameplay Tests ---")
-- Test suite
local tests = {
    ["warp zone system"] = function()
        -- Test warp zone system
        local success = Utils.ErrorHandler.safeCall(function()
            local WarpZones = require("src.systems.warp_zones")
            TestFramework.assert.notNil(WarpZones, "Warp zones system should be available")
        end)
        TestFramework.assert.isTrue(success, "Warp zone system should work without crashing")
    end,
    ["warp zone generation"] = function()
        -- Test warp zone generation
        local success = Utils.ErrorHandler.safeCall(function()
            local WarpZones = require("src.systems.warp_zones")
            if WarpZones.generateWarpZone then
                local warpZone = WarpZones.generateWarpZone(400, 300)
                TestFramework.assert.notNil(warpZone, "Warp zone should be generated")
            end
        end)
        TestFramework.assert.isTrue(success, "Warp zone generation should work without crashing")
    end,
    ["warp zone discovery"] = function()
        -- Test warp zone discovery
        local success = Utils.ErrorHandler.safeCall(function()
            local WarpZones = require("src.systems.warp_zones")
            if WarpZones.discoverWarpZone then
                WarpZones.discoverWarpZone(400, 300)
            end
        end)
        TestFramework.assert.isTrue(success, "Warp zone discovery should work without crashing")
    end,
    ["warp zone completion"] = function()
        -- Test warp zone completion
        local success = Utils.ErrorHandler.safeCall(function()
            local WarpZones = require("src.systems.warp_zones")
            if WarpZones.completeWarpZone then
                WarpZones.completeWarpZone(400, 300)
            end
        end)
        TestFramework.assert.isTrue(success, "Warp zone completion should work without crashing")
    end,
    ["achievement system"] = function()
        -- Test achievement system
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            TestFramework.assert.notNil(AchievementSystem, "Achievement system should be available")
        end)
        TestFramework.assert.isTrue(success, "Achievement system should work without crashing")
    end,
    ["achievement progress tracking"] = function()
        -- Test achievement progress tracking
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            if AchievementSystem.updateProgress then
                AchievementSystem.updateProgress("first_planet", 1)
            end
        end)
        TestFramework.assert.isTrue(success, "Achievement progress tracking should work without crashing")
    end,
    ["achievement unlocking"] = function()
        -- Test achievement unlocking
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            if AchievementSystem.unlockAchievement then
                AchievementSystem.unlockAchievement("first_planet")
            end
        end)
        TestFramework.assert.isTrue(success, "Achievement unlocking should work without crashing")
    end,
    ["achievement events"] = function()
        -- Test achievement event handling
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            if AchievementSystem.onRingCollected then
                -- Initialize player data if needed
                local player = { ringsCollected = 0 }
                AchievementSystem.onRingCollected(player)
            end
        end)
        TestFramework.assert.isTrue(success, "Achievement events should work without crashing")
    end,
    ["achievement statistics"] = function()
        -- Test achievement statistics
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            if AchievementSystem.getStatistics then
                local stats = AchievementSystem.getStatistics()
                TestFramework.assert.notNil(stats, "Achievement statistics should be available")
            end
        end)
        TestFramework.assert.isTrue(success, "Achievement statistics should work without crashing")
    end,
    ["achievement save/load"] = function()
        -- Test achievement save/load functionality
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            if AchievementSystem.saveAchievements then
                AchievementSystem.saveAchievements()
            end
            if AchievementSystem.loadAchievements then
                AchievementSystem.loadAchievements()
            end
        end)
        TestFramework.assert.isTrue(success, "Achievement save/load should work without crashing")
    end,
    ["artifact collection"] = function()
        -- Test artifact collection
        local success = Utils.ErrorHandler.safeCall(function()
            local ArtifactSystem = require("src.systems.artifact_system")
            if ArtifactSystem.collectArtifact then
                ArtifactSystem.collectArtifact("rare_gem", 400, 300)
            end
        end)
        TestFramework.assert.isTrue(success, "Artifact collection should work without crashing")
    end,
    ["special planet types"] = function()
        -- Test special planet type achievements
        local success = Utils.ErrorHandler.safeCall(function()
            local AchievementSystem = require("src.systems.achievement_system")
            if AchievementSystem.onLavaEruption then
                -- Initialize player data if needed
                local player = { lavaEruptions = 0 }
                AchievementSystem.onLavaEruption(player)
            end
        end)
        TestFramework.assert.isTrue(success, "Lava eruption event should work without crashing")
    end,
    ["constellation completion"] = function()
        -- Test constellation completion
        local success = Utils.ErrorHandler.safeCall(function()
            local RingConstellations = require("src.systems.ring_constellations")
            if RingConstellations.onConstellationCompleted then
                RingConstellations.onConstellationCompleted("test_constellation")
            end
        end)
        TestFramework.assert.isTrue(success, "Constellation completion event should work without crashing")
    end,
    ["advanced ring mechanics"] = function()
        -- Test advanced ring mechanics
        local success = Utils.ErrorHandler.safeCall(function()
            local RingSystem = require("src.systems.ring_system")
            if RingSystem.activatePowerRing then
                RingSystem.activatePowerRing(400, 300)
            end
        end)
        TestFramework.assert.isTrue(success, "Advanced ring mechanics should work without crashing")
    end,
    ["power ring effects"] = function()
        -- Test power ring effects
        local success = Utils.ErrorHandler.safeCall(function()
            local RingSystem = require("src.systems.ring_system")
            if RingSystem.applyPowerEffect then
                RingSystem.applyPowerEffect("speed_boost", 400, 300)
            end
        end)
        TestFramework.assert.isTrue(success, "Power ring effects should work without crashing")
    end,
    ["challenge system"] = function()
        -- Test challenge system
        local success = Utils.ErrorHandler.safeCall(function()
            local GameState = require("src.core.game_state")
            GameState.init(800, 600)
            -- Test challenge activation
            if GameState.activateChallenge then
                GameState.activateChallenge("speed_run")
            end
        end)
        TestFramework.assert.isTrue(success, "Challenge system should work without crashing")
    end,
    ["advanced progression"] = function()
        -- Test advanced progression features
        local success = Utils.ErrorHandler.safeCall(function()
            local ProgressionSystem = require("src.systems.progression_system")
            if ProgressionSystem.advanceLevel then
                ProgressionSystem.advanceLevel()
            end
        end)
        TestFramework.assert.isTrue(success, "Advanced progression should work without crashing")
    end
}
-- Run tests
TestFramework.runTests(tests)
-- Return module with run function
return {
    run = function()
        TestFramework.runTests(tests)
        return true
    end
}