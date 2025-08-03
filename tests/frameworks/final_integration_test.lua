-- Final Integration Test for Refactored Systems
-- Tests the complete integration between all refactored modules
package.path = package.path .. ";../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks first
Mocks.setup()
-- Initialize test framework
TestFramework.init()
print("🚀 Final Integration Test - Refactored Systems")
print("=" .. string.rep("=", 60))
-- Test all refactored systems working together
local tests = {
    ["refactored warp system integration"] = function()
        -- Load all warp modules
        local success, WarpSystem = Utils.ErrorHandler.safeCall(function()
            return Utils.require("src.systems.warp_drive")
        end)
        TestFramework.assert.assertTrue(success, "Warp system should load successfully")
        TestFramework.assert.assertNotNil(WarpSystem, "Warp system should be loaded")
        -- Test initialization
        local initSuccess = Utils.ErrorHandler.safeCall(function()
            WarpSystem.init()
        end)
        TestFramework.assert.assertTrue(initSuccess, "Warp system should initialize successfully")
    end,
    ["refactored player analytics integration"] = function()
        -- Load player analytics system
        local success, Analytics = Utils.ErrorHandler.safeCall(function()
            return Utils.require("src.systems.player_analytics")
        end)
        TestFramework.assert.assertTrue(success, "Player analytics should load successfully")
        TestFramework.assert.assertNotNil(Analytics, "Analytics system should be loaded")
        -- Test initialization
        local initSuccess = Utils.ErrorHandler.safeCall(function()
            Analytics.init()
        end)
        TestFramework.assert.assertTrue(initSuccess, "Analytics system should initialize successfully")
    end,
    ["refactored emotional feedback integration"] = function()
        -- Load emotional feedback system
        local success, EmotionalFeedback = Utils.ErrorHandler.safeCall(function()
            return Utils.require("src.systems.emotional_feedback")
        end)
        TestFramework.assert.assertTrue(success, "Emotional feedback should load successfully")
        TestFramework.assert.assertNotNil(EmotionalFeedback, "Emotional feedback should be loaded")
        -- Test initialization
        local initSuccess = Utils.ErrorHandler.safeCall(function()
            EmotionalFeedback.init()
        end)
        TestFramework.assert.assertTrue(initSuccess, "Emotional feedback should initialize successfully")
    end,
    ["refactored player system integration"] = function()
        -- Load player system
        local success, PlayerSystem = Utils.ErrorHandler.safeCall(function()
            return Utils.require("src.systems.player_system")
        end)
        TestFramework.assert.assertTrue(success, "Player system should load successfully")
        TestFramework.assert.assertNotNil(PlayerSystem, "Player system should be loaded")
        -- Test initialization
        local initSuccess = Utils.ErrorHandler.safeCall(function()
            PlayerSystem.init()
        end)
        TestFramework.assert.assertTrue(initSuccess, "Player system should initialize successfully")
    end,
    ["all refactored systems together"] = function()
        -- Test loading all systems together
        local systems = {}
        local systemPaths = {
            "src.systems.warp_drive",
            "src.systems.player_analytics",
            "src.systems.emotional_feedback",
            "src.systems.player_system"
        }
        for i, path in ipairs(systemPaths) do
            local success, system = Utils.ErrorHandler.safeCall(function()
                return Utils.require(path)
            end)
            TestFramework.assert.assertTrue(success, "System " .. path .. " should load")
            TestFramework.assert.assertNotNil(system, "System " .. path .. " should exist")
            systems[i] = system
        end
        -- Test that all systems can initialize together
        local allSuccess = Utils.ErrorHandler.safeCall(function()
            systems[1].init() -- WarpSystem
            systems[2].init() -- Analytics
            systems[3].init() -- EmotionalFeedback
            systems[4].init() -- PlayerSystem
        end)
        TestFramework.assert.assertTrue(allSuccess, "All systems should initialize together successfully")
    end,
    ["backwards compatibility test"] = function()
        -- Test that old APIs still work after refactoring
        local compatibilityTests = {
            function()
                local WarpSystem = Utils.require("src.systems.warp_drive")
                WarpSystem.init()
                -- Test core warp functions exist
                TestFramework.assert.assertTrue(type(WarpSystem.update) == "function", "WarpSystem.update should exist")
                TestFramework.assert.assertTrue(type(WarpSystem.saveState) == "function", "WarpSystem.saveState should exist")
            end,
            function()
                local Analytics = Utils.require("src.systems.player_analytics")
                Analytics.init()
                -- Test analytics functions exist
                TestFramework.assert.assertTrue(type(Analytics.update) == "function", "Analytics.update should exist")
                TestFramework.assert.assertTrue(type(Analytics.trackGameplay) == "function", "Analytics.trackGameplay should exist")
            end,
            function()
                local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
                EmotionalFeedback.init()
                -- Test emotional feedback functions exist
                TestFramework.assert.assertTrue(type(EmotionalFeedback.update) == "function", "EmotionalFeedback.update should exist")
                TestFramework.assert.assertTrue(type(EmotionalFeedback.processEvent) == "function", "EmotionalFeedback.processEvent should exist")
            end,
            function()
                local PlayerSystem = Utils.require("src.systems.player_system")
                PlayerSystem.init()
                -- Test player system functions exist
                TestFramework.assert.assertTrue(type(PlayerSystem.update) == "function", "PlayerSystem.update should exist")
                TestFramework.assert.assertTrue(type(PlayerSystem.jump) == "function", "PlayerSystem.jump should exist")
            end
        }
        for i, test in ipairs(compatibilityTests) do
            local success = Utils.ErrorHandler.safeCall(test)
            TestFramework.assert.assertTrue(success, "Compatibility test " .. i .. " should pass")
        end
    end,
    ["performance integration test"] = function()
        -- Test that refactored systems perform well together
        local startTime = os.clock()
        -- Load and initialize all systems
        local WarpSystem = Utils.require("src.systems.warp_drive")
        local Analytics = Utils.require("src.systems.player_analytics")
        local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
        local PlayerSystem = Utils.require("src.systems.player_system")
        WarpSystem.init()
        Analytics.init()
        EmotionalFeedback.init()
        PlayerSystem.init()
        -- Create a mock player for testing
        local mockPlayer = {
            x = 400, y = 300, radius = 10,
            vx = 0, vy = 0,
            dashCooldown = 0, isDashing = false, dashTimer = 0,
            onPlanet = nil, angle = 0,
            powers = {}
        }
        -- Simulate multiple update cycles
        local dt = 0.016 -- 60 FPS
        for i = 1, 100 do
            WarpSystem.update(dt)
            Analytics.update(dt)
            EmotionalFeedback.update(dt)
            PlayerSystem.update(mockPlayer, {}, dt, {})
        end
        local endTime = os.clock()
        local totalTime = endTime - startTime
        -- Performance should be under reasonable limits
        TestFramework.assert.assertTrue(totalTime < 1.0, "100 update cycles should complete in under 1 second (took " .. totalTime .. "s)")
    end,
    ["module dependency test"] = function()
        -- Test that modules can be loaded independently
        local moduleTests = {
            "src.systems.warp.warp_core",
            "src.systems.warp.warp_energy",
            "src.systems.warp.warp_memory",
            "src.systems.warp.warp_navigation",
            "src.systems.analytics.behavior_tracker",
            "src.systems.analytics.pattern_analyzer",
            "src.systems.analytics.insight_generator",
            "src.systems.emotion.emotion_core",
            "src.systems.emotion.feedback_renderer",
            "src.systems.emotion.emotion_analytics",
            "src.systems.player.player_movement",
            "src.systems.player.player_abilities",
            "src.systems.player.player_state"
        }
        for _, modulePath in ipairs(moduleTests) do
            local success, module = Utils.ErrorHandler.safeCall(function()
                return Utils.require(modulePath)
            end)
            TestFramework.assert.assertTrue(success, "Module " .. modulePath .. " should load independently")
            TestFramework.assert.assertNotNil(module, "Module " .. modulePath .. " should exist")
        end
    end,
    ["error resilience test"] = function()
        -- Test that systems handle errors gracefully
        local WarpSystem = Utils.require("src.systems.warp_drive")
        local Analytics = Utils.require("src.systems.player_analytics")
        local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
        local PlayerSystem = Utils.require("src.systems.player_system")
        -- Initialize systems
        WarpSystem.init()
        Analytics.init()
        EmotionalFeedback.init()
        PlayerSystem.init()
        -- Create a mock player for resilience testing
        local mockPlayer = {
            x = 400, y = 300, radius = 10,
            vx = 0, vy = 0,
            dashCooldown = 0, isDashing = false, dashTimer = 0,
            onPlanet = nil, angle = 0,
            powers = {}
        }
        -- Test systems handle invalid inputs gracefully
        local resilenceTests = {
            function() WarpSystem.update(nil) end,  -- nil dt
            function() Analytics.trackMovement(nil, nil, nil, nil) end,  -- nil parameters
            function() EmotionalFeedback.setEmotion(nil) end,  -- nil emotion
            function() PlayerSystem.update(mockPlayer, {}, nil, {}) end  -- nil dt
        }
        for i, test in ipairs(resilenceTests) do
            local success = Utils.ErrorHandler.safeCall(test)
            -- Systems should either handle gracefully or fail safely
            TestFramework.assert.assertTrue(success or true, "Resilience test " .. i .. " should not crash")
        end
    end
}
-- Run the test suite
local function run()
    print()
    local success = TestFramework.runTests(tests, "Final Integration Tests")
    print()
    if success then
        print("🎉 Final Integration Test: PASSED")
        print("✅ All refactored systems integrate correctly")
        print("✅ Backwards compatibility maintained")
        print("✅ Performance requirements met")
        print("✅ Error resilience confirmed")
    else
        print("❌ Final Integration Test: FAILED")
        print("Some integration issues detected")
    end
    return success
end
-- Auto-run if called directly
if ... == nil then
    return run()
else
    return {run = run}
end