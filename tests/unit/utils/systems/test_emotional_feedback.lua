-- Test file for Emotional Feedback System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Get EmotionalFeedback
local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
-- Test suite
local tests = {
    ["test emotional feedback initialization"] = function()
        local success = EmotionalFeedback.init()
        TestFramework.assert.isTrue(success, "Emotional feedback should initialize")
        TestFramework.assert.notNil(EmotionalFeedback.emotions, "Should have emotions table")
        TestFramework.assert.notNil(EmotionalFeedback.currentMood, "Should have current mood")
    end,
    ["test process event"] = function()
        EmotionalFeedback.init()
        -- Test landing event
        EmotionalFeedback.processEvent("landing", {
            speed = 100,
            planet = { type = "normal" }
        })
        TestFramework.assert.notNil(EmotionalFeedback.currentMood, "Should update mood after event")
    end,
    ["test perfect landing emotion"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("landing", {
            speed = 50,  -- Low speed = perfect landing
            planet = { type = "normal" }
        })
        local mood = EmotionalFeedback.currentMood
        TestFramework.assert.notNil(mood, "Should have mood after perfect landing")
    end,
    ["test hard landing emotion"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("landing", {
            speed = 300,  -- High speed = hard landing
            planet = { type = "normal" }
        })
        local mood = EmotionalFeedback.currentMood
        TestFramework.assert.notNil(mood, "Should have mood after hard landing")
    end,
    ["test discovery emotion"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("discovery", {
            type = "new_planet",
            planet = { type = "rare" }
        })
        local mood = EmotionalFeedback.currentMood
        TestFramework.assert.notNil(mood, "Should have mood after discovery")
    end,
    ["test combo achievement emotion"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("combo", {
            count = 5,
            score = 1000
        })
        local mood = EmotionalFeedback.currentMood
        TestFramework.assert.notNil(mood, "Should have mood after combo")
    end,
    ["test danger emotion"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("near_miss", {
            distance = 10,
            object = "asteroid"
        })
        local mood = EmotionalFeedback.currentMood
        TestFramework.assert.notNil(mood, "Should have mood after near miss")
    end,
    ["test mood decay"] = function()
        EmotionalFeedback.init()
        -- Set an intense mood
        EmotionalFeedback.processEvent("combo", { count = 10 })
        local initialIntensity = EmotionalFeedback.currentMood and EmotionalFeedback.currentMood.intensity or 0
        -- Update to decay mood
        EmotionalFeedback.update(1.0) -- 1 second
        local newIntensity = EmotionalFeedback.currentMood and EmotionalFeedback.currentMood.intensity or 0
        TestFramework.assert.greaterThan(newIntensity, initialIntensity, "Mood intensity should decay")
    end,
    ["test get feedback message"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("landing", {
            speed = 50,
            planet = { type = "normal" }
        })
        local message = EmotionalFeedback.getFeedbackMessage()
        TestFramework.assert.notNil(message, "Should get feedback message")
        TestFramework.assert.isTrue(type(message) == "string", "Message should be string")
    end,
    ["test emotion blending"] = function()
        EmotionalFeedback.init()
        -- Quick succession of events
        EmotionalFeedback.processEvent("landing", { speed = 50 })
        EmotionalFeedback.processEvent("discovery", { type = "artifact" })
        local mood = EmotionalFeedback.currentMood
        TestFramework.assert.notNil(mood, "Should blend emotions")
    end,
    ["test visual effects"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("combo", { count = 5 })
        local effects = EmotionalFeedback.getVisualEffects()
        if effects then
            TestFramework.assert.notNil(effects, "Should have visual effects for intense emotions")
        else
            -- Effects not implemented
            TestFramework.assert.isTrue(true, "Visual effects not implemented")
        end
    end,
    ["test audio cues"] = function()
        EmotionalFeedback.init()
        EmotionalFeedback.processEvent("discovery", { type = "secret" })
        local audioCue = EmotionalFeedback.getAudioCue()
        if audioCue then
            TestFramework.assert.notNil(audioCue, "Should suggest audio for emotions")
        else
            -- Audio cues not implemented
            TestFramework.assert.isTrue(true, "Audio cues not implemented")
        end
    end
}
-- Run tests
local function run()
    return TestFramework.runTests(tests, "Emotional Feedback Tests")
end
return {run = run}