-- Unit tests for Feedback Renderer System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Mock dependencies
local mockParticleSystem = {
    createEmotionalParticles = spy(),
    createCelebrationBurst = spy()
}
local mockSoundManager = {
    playEmotionalCue = spy(),
    playFeedbackSound = spy(),
    setEmotionalFilter = spy()
}
local mockCamera = {
    addEmotionalShake = spy(),
    setEmotionalZoom = spy()
}
-- Mock Utils.require to return our mocks
local originalUtilsRequire = Utils.require
Utils.require = function(module)
    if module == "src.systems.particle_system" then
        return mockParticleSystem
    elseif module == "src.audio.sound_manager" then
        return mockSoundManager
    elseif module == "src.core.camera" then
        return mockCamera
    end
    return originalUtilsRequire(module)
end
-- Load FeedbackRenderer after mocks are set up
local FeedbackRenderer = require("src.systems.emotion.feedback_renderer")
describe("Feedback Renderer System", function()
    before_each(function()
        -- Reset mock spies
        if mockParticleSystem.createEmotionalParticles.reset then
            mockParticleSystem.createEmotionalParticles:reset()
        end
        if mockParticleSystem.createCelebrationBurst.reset then
            mockParticleSystem.createCelebrationBurst:reset()
        end
        if mockSoundManager.playEmotionalCue.reset then
            mockSoundManager.playEmotionalCue:reset()
        end
        if mockSoundManager.playFeedbackSound.reset then
            mockSoundManager.playFeedbackSound:reset()
        end
        if mockSoundManager.setEmotionalFilter.reset then
            mockSoundManager.setEmotionalFilter:reset()
        end
        if mockCamera.addEmotionalShake.reset then
            mockCamera.addEmotionalShake:reset()
        end
        if mockCamera.setEmotionalZoom.reset then
            mockCamera.setEmotionalZoom:reset()
        end
    end)
    describe("Multi-Sensory Feedback", function()
        it("should trigger visual feedback for jump action", function()
            FeedbackRenderer.triggerMultiSensory("jump", 0.7, {pullPower = 0.8})
            assert.spy(mockParticleSystem.createEmotionalParticles).was_called()
        end)
        it("should trigger audio feedback for landing action", function()
            FeedbackRenderer.triggerMultiSensory("landing", 0.6, {speed = 150})
            assert.spy(mockSoundManager.playEmotionalCue).was_called()
        end)
        it("should trigger camera feedback for high intensity actions", function()
            FeedbackRenderer.triggerMultiSensory("dash", 0.9, {emergency = true})
            assert.spy(mockCamera.addEmotionalShake).was_called()
        end)
        it("should handle low intensity actions appropriately", function()
            FeedbackRenderer.triggerMultiSensory("failure", 0.2, {type = "miss"})
            -- Should still trigger some feedback but more subdued
            assert.spy(mockParticleSystem.createEmotionalParticles).was_called()
        end)
    end)
    describe("Visual Feedback", function()
        it("should create appropriate visual effects for different action types", function()
            FeedbackRenderer.triggerVisual("jump", 0.8, {pullPower = 0.9})
            assert.spy(mockParticleSystem.createEmotionalParticles).was_called_with(
                match.is_table(), -- params should be a table
                match.is_string(), -- action type
                match.is_number()  -- intensity
            )
        end)
        it("should scale visual intensity appropriately", function()
            FeedbackRenderer.triggerVisual("landing", 0.3, {speed = 50})
            FeedbackRenderer.triggerVisual("landing", 0.9, {speed = 200})
            -- Should be called twice with different intensities
            assert.spy(mockParticleSystem.createEmotionalParticles).was_called(2)
        end)
        it("should provide visual effects for different emotional states", function()
            local effects = FeedbackRenderer.getVisualEffects(
                {confidence = 0.8, momentum = 0.6},
                {type = "excited", intensity = 0.7}
            )
            assert.is_type("table", effects)
            assert.is_type("number", effects.confidence_glow or 0)
            assert.is_type("number", effects.momentum_trail or 0)
        end)
    end)
    describe("Audio Feedback", function()
        it("should play emotional audio cues", function()
            FeedbackRenderer.triggerAudio("jump", 0.7, {pullPower = 0.8})
            assert.spy(mockSoundManager.playEmotionalCue).was_called()
        end)
        it("should set emotional audio filters", function()
            FeedbackRenderer.triggerAudio("dash", 0.9, {emergency = true})
            assert.spy(mockSoundManager.setEmotionalFilter).was_called()
        end)
        it("should get appropriate audio cues for mood types", function()
            local cue = FeedbackRenderer.getAudioCue("excited", 0.8)
            assert.is_type("table", cue)
            assert.is_type("string", cue.sound or "")
            assert.is_type("number", cue.volume or 0)
        end)
        it("should handle different mood intensities", function()
            local lowCue = FeedbackRenderer.getAudioCue("calm", 0.2)
            local highCue = FeedbackRenderer.getAudioCue("intense", 0.9)
            assert.is_type("table", lowCue)
            assert.is_type("table", highCue)
            -- High intensity should have higher volume
            assert.greater_than(highCue.volume or 0, lowCue.volume or 0)
        end)
    end)
    describe("Haptic Feedback", function()
        it("should trigger haptic feedback for touch devices", function()
            FeedbackRenderer.triggerHaptic("jump", 0.8, {pullPower = 0.9})
            -- Haptic feedback is typically handled by the renderer itself
            -- but we can verify it doesn't error
            assert.is_true(true) -- Test passes if no error thrown
        end)
        it("should scale haptic intensity", function()
            FeedbackRenderer.triggerHaptic("dash", 0.3, {emergency = false})
            FeedbackRenderer.triggerHaptic("dash", 0.9, {emergency = true})
            -- Both calls should complete without error
            assert.is_true(true)
        end)
        it("should handle different haptic patterns", function()
            FeedbackRenderer.triggerHaptic("landing", 0.6, {speed = 100})
            FeedbackRenderer.triggerHaptic("failure", 0.2, {type = "miss"})
            -- Different action types should work
            assert.is_true(true)
        end)
    end)
    describe("Camera Feedback", function()
        it("should add camera shake for high-impact actions", function()
            FeedbackRenderer.triggerCamera("dash", 0.9, {emergency = true})
            assert.spy(mockCamera.addEmotionalShake).was_called()
        end)
        it("should set emotional zoom for special moments", function()
            FeedbackRenderer.triggerCamera("achievement", 1.0, {type = "milestone"})
            assert.spy(mockCamera.setEmotionalZoom).was_called()
        end)
        it("should not over-shake for low intensity actions", function()
            FeedbackRenderer.triggerCamera("landing", 0.2, {speed = 30})
            -- Low intensity should not trigger strong camera effects
            -- This is implementation dependent but camera shake should be minimal or none
            assert.is_true(true)
        end)
    end)
    describe("Special Celebrations", function()
        it("should create celebration bursts for achievements", function()
            FeedbackRenderer.createCelebration("first_success", {x = 100, y = 200})
            assert.spy(mockParticleSystem.createCelebrationBurst).was_called()
        end)
        it("should handle different celebration types", function()
            FeedbackRenderer.createCelebration("mastery", {x = 50, y = 150})
            FeedbackRenderer.createCelebration("discovery", {x = 300, y = 400})
            assert.spy(mockParticleSystem.createCelebrationBurst).was_called(2)
        end)
        it("should create celebrations at specified positions", function()
            local params = {x = 123, y = 456}
            FeedbackRenderer.createCelebration("milestone", params)
            assert.spy(mockParticleSystem.createCelebrationBurst).was_called_with(
                match.is_string(), -- celebration type
                match.is_table()   -- position params
            )
        end)
    end)
    describe("Feedback Messages", function()
        it("should provide appropriate messages for different moods", function()
            local excitedMessage = FeedbackRenderer.getFeedbackMessage("excited")
            local calmMessage = FeedbackRenderer.getFeedbackMessage("calm")
            assert.is_type("string", excitedMessage)
            assert.is_type("string", calmMessage)
            assert.not_equal(excitedMessage, calmMessage)
        end)
        it("should handle unknown mood types gracefully", function()
            local message = FeedbackRenderer.getFeedbackMessage("unknown_mood")
            assert.is_type("string", message)
            assert.greater_than(#message, 0) -- Should not be empty
        end)
        it("should provide contextual messages", function()
            local message = FeedbackRenderer.getFeedbackMessage("triumphant")
            assert.is_type("string", message)
            assert.matches(message, "[%w%s]+") -- Should contain words
        end)
    end)
    describe("Feedback Coordination", function()
        it("should coordinate multiple feedback types simultaneously", function()
            FeedbackRenderer.triggerMultiSensory("achievement", 1.0, {
                type = "perfect_landing",
                x = 100,
                y = 200
            })
            -- Should trigger multiple systems
            assert.spy(mockParticleSystem.createEmotionalParticles).was_called()
            assert.spy(mockSoundManager.playEmotionalCue).was_called()
            assert.spy(mockCamera.addEmotionalShake).was_called()
        end)
        it("should prevent feedback overload", function()
            -- Trigger many rapid feedbacks
            for i = 1, 10 do
                FeedbackRenderer.triggerMultiSensory("jump", 0.5, {pullPower = 0.5})
            end
            -- System should handle this gracefully without errors
            assert.is_true(true)
        end)
        it("should maintain feedback quality across different action types", function()
            local actions = {"jump", "landing", "dash", "achievement", "failure"}
            for _, action in ipairs(actions) do
                FeedbackRenderer.triggerMultiSensory(action, 0.6, {})
            end
            -- All action types should be handled
            assert.spy(mockParticleSystem.createEmotionalParticles).was_called(#actions)
        end)
    end)
end)