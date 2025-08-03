-- Simple tests for Emotional Feedback System using working patterns
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Mock achievement system
local mockAchievementSystem = {
    onWarpDriveUnlocked = spy()
}
-- Mock particle system with all required functions
local mockParticleSystem = {
    createEmotionalParticles = function() end,
    createCelebrationBurst = function() end,
    burst = function() end,
    create = function() end
}
-- Mock sound manager
local mockSoundManager = {
    playEmotionalCue = function() end,
    setEmotionalFilter = function() end
}
-- Mock camera
local mockCamera = {
    addEmotionalShake = function() end
}
-- Mock Utils.require
local originalUtilsRequire = Utils.require
Utils.require = function(module)
    if module == "src.systems.achievement_system" then
        return mockAchievementSystem
    elseif module == "src.systems.particle_system" then
        return mockParticleSystem
    elseif module == "src.audio.sound_manager" then
        return mockSoundManager
    elseif module == "src.core.camera" then
        return mockCamera
    elseif module == "src.core.game_state" then
        return {player = {x = 100, y = 200}}
    end
    return originalUtilsRequire(module)
end
-- Add direct assignment for ParticleSystem global reference
ParticleSystem = mockParticleSystem
-- Load systems
local EmotionCore = require("src.systems.emotion.emotion_core")
local EmotionalFeedback = require("src.systems.emotional_feedback")
describe("Emotional Feedback System - Core Tests", function()
    before_each(function()
        -- Reset systems
        EmotionCore.init()
        EmotionalFeedback.init()
    end)
    describe("Emotion Core", function()
        it("should initialize with correct state", function()
            local state = EmotionCore.getEmotionalState()
            assert.equals(0.5, state.confidence)
            assert.equals(0.0, state.momentum)
            assert.equals(0, state.streak)
        end)
        it("should update confidence", function()
            EmotionCore.updateConfidence(0.3)
            local state = EmotionCore.getEmotionalState()
            assert.equals(0.8, state.confidence)
        end)
        it("should handle mood transitions", function()
            EmotionCore.transitionToMood("excited", 0.8)
            local mood = EmotionCore.getCurrentMood()
            assert.equals("excited", mood.type)
            assert.equals(0.8, mood.intensity)
        end)
    end)
    describe("Main Facade", function()
        it("should initialize without errors", function()
            local result = EmotionalFeedback.init()
            assert.is_true(result)
        end)
        it("should process jump events", function()
            EmotionalFeedback.processEvent("jump", {
                pullPower = 0.7,
                success = true,
                isFirstJump = false
            })
            -- Should transition to energetic mood
            local mood = EmotionCore.getCurrentMood()
            assert.equals("energetic", mood.type)
        end)
        it("should process landing events", function()
            EmotionalFeedback.processEvent("landing", {
                player = {x = 100, y = 200, vx = 50, vy = 30},
                planet = {type = "normal"},
                speed = 80
            })
            -- Should transition to smooth mood for moderate speed
            local mood = EmotionCore.getCurrentMood()
            assert.equals("smooth", mood.type)
        end)
        it("should handle achievement events", function()
            EmotionalFeedback.processEvent("achievement", {type = "milestone"})
            local mood = EmotionCore.getCurrentMood()
            assert.equals("triumphant", mood.type)
            assert.equals(1.0, mood.intensity)
        end)
        it("should provide backwards compatibility", function()
            assert.is_type("function", EmotionalFeedback.triggerMultiSensoryFeedback)
            assert.is_type("function", EmotionalFeedback.getEmotionalState)
            assert.is_type("function", EmotionalFeedback.getFeedbackMessage)
        end)
    end)
    describe("Event Integration", function()
        it("should handle combo events", function()
            -- Check initial state first
            local initialState = EmotionCore.getEmotionalState()
            local expectedFinal = initialState.streak + 5
            EmotionalFeedback.processEvent("combo", {count = 5})
            local state = EmotionCore.getEmotionalState()
            assert.equals(expectedFinal, state.streak)
        end)
        it("should handle near miss events", function()
            EmotionalFeedback.processEvent("near_miss", {})
            local mood = EmotionCore.getCurrentMood()
            assert.equals("intense", mood.type)
            assert.equals(0.8, mood.intensity)
        end)
        it("should handle failure gracefully", function()
            EmotionalFeedback.processEvent("failure", {type = "collision"})
            local mood = EmotionCore.getCurrentMood()
            assert.equals("determined", mood.type)
        end)
    end)
end)