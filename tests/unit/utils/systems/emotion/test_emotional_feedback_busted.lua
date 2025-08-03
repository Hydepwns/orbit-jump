-- Unit tests for Emotional Feedback System (Main Facade) using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Mock subsystem dependencies
local mockEmotionCore = {
    init = spy(),
    update = spy(),
    getEmotionalState = spy(function()
        return {confidence = 0.7, momentum = 0.5, achievement_streak = 2, flow_state_duration = 5.0}
    end),
    getCurrentMood = spy(function()
        return {type = "excited", intensity = 0.8}
    end),
    getEmotionalMemory = spy(function()
        return {perfect_landings = 3, dramatic_saves = 1, first_successful_jump = true}
    end),
    transitionToMood = spy(),
    updateConfidence = spy(),
    updateMomentum = spy(),
    incrementStreak = spy(),
    resetStreak = spy(),
    recordPerfectLanding = spy(),
    recordDramaticSave = spy(),
    recordFirstJump = spy(),
    hasFirstJump = spy(function() return false end),
    canTriggerSurprise = spy(function() return true end),
    startSurpriseCooldown = spy(),
    getConfig = spy(function(type)
        if type == "jump" then
            return {baseIntensity = 0.3, powerMultiplier = 0.7, maxIntensity = 1.0}
        elseif type == "landing" then
            return {baseIntensity = 0.4, speedMultiplier = 0.6, perfectBonus = 0.3, gentleBonus = 0.2}
        elseif type == "dash" then
            return {baseIntensity = 0.5, emergencyBonus = 0.3}
        end
        return {}
    end)
}
local mockFeedbackRenderer = {
    triggerMultiSensory = spy(),
    triggerVisual = spy(),
    triggerAudio = spy(),
    triggerHaptic = spy(),
    triggerCamera = spy(),
    createCelebration = spy(),
    getFeedbackMessage = spy(function() return "Great job!" end),
    getVisualEffects = spy(function() return {glow = 0.8} end),
    getAudioCue = spy(function() return {sound = "success", volume = 0.7} end)
}
local mockEmotionAnalytics = {
    init = spy(),
    update = spy(),
    recordMoodChange = spy()
}
-- Mock Utils.require to return our mocks
local originalUtilsRequire = Utils.require
Utils.require = function(module)
    if module == "src.systems.emotion.emotion_core" then
        return mockEmotionCore
    elseif module == "src.systems.emotion.feedback_renderer" then
        return mockFeedbackRenderer
    elseif module == "src.systems.emotion.emotion_analytics" then
        return mockEmotionAnalytics
    elseif module == "src.core.game_state" then
        return {player = {x = 100, y = 200}}
    end
    return originalUtilsRequire(module)
end
-- Load EmotionalFeedback after mocks are set up
local EmotionalFeedback = require("src.systems.emotional_feedback")
describe("Emotional Feedback System (Main Facade)", function()
    before_each(function()
        -- Reset all mock spies
        for _, mock in pairs({mockEmotionCore, mockFeedbackRenderer, mockEmotionAnalytics}) do
            for _, spy in pairs(mock) do
                if type(spy) == "table" and spy.reset then
                    spy:reset()
                end
            end
        end
    end)
    describe("System Initialization", function()
        it("should initialize all subsystems", function()
            EmotionalFeedback.init()
            assert.spy(mockEmotionCore.init).was_called()
            assert.spy(mockEmotionAnalytics.init).was_called()
        end)
        it("should set up backwards compatibility references", function()
            EmotionalFeedback.init()
            assert.spy(mockEmotionCore.getEmotionalState).was_called()
            assert.spy(mockEmotionCore.getCurrentMood).was_called()
            assert.is_type("table", EmotionalFeedback.emotions)
            assert.is_type("table", EmotionalFeedback.currentMood)
        end)
        it("should return success status", function()
            local result = EmotionalFeedback.init()
            assert.is_true(result)
        end)
    end)
    describe("Event Processing", function()
        before_each(function()
            EmotionalFeedback.init()
        end)
        it("should process landing events with mood transitions", function()
            local params = {
                player = {x = 100, y = 200, vx = 50, vy = 30},
                planet = {type = "normal"},
                speed = 80
            }
            EmotionalFeedback.processEvent("landing", params)
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("smooth", 0.8)
            assert.spy(mockEmotionAnalytics.recordMoodChange).was_called()
        end)
        it("should process jump events with confidence building", function()
            local params = {
                pullPower = 0.8,
                success = true,
                isFirstJump = false
            }
            EmotionalFeedback.processEvent("jump", params)
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("energetic", match.is_number())
            assert.spy(mockEmotionCore.updateConfidence).was_called()
            assert.spy(mockEmotionCore.updateMomentum).was_called()
            assert.spy(mockEmotionCore.incrementStreak).was_called()
        end)
        it("should process dash events with power feedback", function()
            local params = {
                emergency = true,
                success = true
            }
            EmotionalFeedback.processEvent("dash", params)
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("powerful", 0.9)
            assert.spy(mockFeedbackRenderer.triggerMultiSensory).was_called()
        end)
        it("should process achievement events with celebration", function()
            local params = {type = "milestone"}
            EmotionalFeedback.processEvent("achievement", params)
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("triumphant", 1.0)
            assert.spy(mockFeedbackRenderer.createCelebration).was_called()
        end)
        it("should process failure events with resilience building", function()
            local params = {type = "collision"}
            EmotionalFeedback.processEvent("failure", params)
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("determined", 0.4)
            assert.spy(mockEmotionCore.updateMomentum).was_called_with(-0.2)
            assert.spy(mockEmotionCore.resetStreak).was_called()
        end)
        it("should process combo events with escalating excitement", function()
            local params = {count = 7}
            EmotionalFeedback.processEvent("combo", params)
            assert.spy(mockEmotionCore.incrementStreak).was_called(7)
            assert.spy(mockEmotionCore.updateConfidence).was_called()
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("triumphant", match.is_number())
        end)
        it("should process near miss events with drama", function()
            EmotionalFeedback.processEvent("near_miss", {})
            assert.spy(mockEmotionCore.updateMomentum).was_called_with(0.3)
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("intense", 0.8)
            assert.spy(mockEmotionCore.recordDramaticSave).was_called()
        end)
        it("should process discovery events with wonder", function()
            EmotionalFeedback.processEvent("discovery", {})
            assert.spy(mockEmotionCore.transitionToMood).was_called_with("excited", 0.9)
            assert.spy(mockEmotionCore.updateConfidence).was_called_with(0.2)
            assert.spy(mockFeedbackRenderer.createCelebration).was_called_with("discovery")
        end)
    end)
    describe("Specific Event Handlers", function()
        before_each(function()
            EmotionalFeedback.init()
        end)
        it("should handle successful jumps with appropriate intensity", function()
            local intensity = EmotionalFeedback.onJump(0.8, true, false)
            assert.is_type("number", intensity)
            assert.greater_than(intensity, 0)
            assert.spy(mockFeedbackRenderer.triggerMultiSensory).was_called_with("jump", match.is_number(), match.is_table())
        end)
        it("should handle first jump with special celebration", function()
            mockEmotionCore.hasFirstJump = spy(function() return false end)
            local intensity = EmotionalFeedback.onJump(0.6, true, true)
            assert.spy(mockEmotionCore.recordFirstJump).was_called()
            assert.spy(mockFeedbackRenderer.createCelebration).was_called_with("first_jump")
        end)
        it("should handle failed jumps appropriately", function()
            local intensity = EmotionalFeedback.onJump(0.5, false, false)
            assert.spy(mockEmotionCore.updateMomentum).was_called_with(-0.2)
            assert.spy(mockEmotionCore.resetStreak).was_called()
        end)
        it("should handle gentle landings with specific feedback", function()
            local player = {x = 100, y = 200, vx = 20, vy = 10}
            local planet = {type = "normal"}
            local intensity = EmotionalFeedback.onLanding(player, planet, 45, true)
            assert.is_type("number", intensity)
            assert.spy(mockFeedbackRenderer.triggerMultiSensory).was_called_with("landing", match.is_number(), match.is_table())
        end)
        it("should handle emergency dashes with heroic feedback", function()
            local intensity = EmotionalFeedback.onDash(true, true)
            assert.spy(mockEmotionCore.recordDramaticSave).was_called()
            assert.spy(mockFeedbackRenderer.triggerMultiSensory).was_called_with("dash", match.is_number(), {emergency = true})
        end)
    end)
    describe("System Updates", function()
        before_each(function()
            EmotionalFeedback.init()
        end)
        it("should update all subsystems", function()
            EmotionalFeedback.update(0.16)
            assert.spy(mockEmotionCore.update).was_called_with(0.16)
            assert.spy(mockEmotionAnalytics.update).was_called_with(0.16)
        end)
        it("should maintain backwards compatibility references", function()
            EmotionalFeedback.update(0.16)
            assert.spy(mockEmotionCore.getEmotionalState).was_called()
            assert.spy(mockEmotionCore.getCurrentMood).was_called()
            assert.is_type("table", EmotionalFeedback.emotions)
            assert.is_type("table", EmotionalFeedback.currentMood)
        end)
        it("should handle multiple rapid updates", function()
            for i = 1, 10 do
                EmotionalFeedback.update(0.016)
            end
            assert.spy(mockEmotionCore.update).was_called(10)
            assert.spy(mockEmotionAnalytics.update).was_called(10)
        end)
    end)
    describe("Backwards Compatibility", function()
        before_each(function()
            EmotionalFeedback.init()
        end)
        it("should delegate multi-sensory feedback calls", function()
            EmotionalFeedback.triggerMultiSensoryFeedback("jump", 0.8, {pullPower = 0.9})
            assert.spy(mockFeedbackRenderer.triggerMultiSensory).was_called_with("jump", 0.8, {pullPower = 0.9})
        end)
        it("should delegate visual feedback calls", function()
            EmotionalFeedback.triggerVisualFeedback("landing", 0.6, {speed = 100})
            assert.spy(mockFeedbackRenderer.triggerVisual).was_called_with("landing", 0.6, {speed = 100})
        end)
        it("should delegate audio feedback calls", function()
            EmotionalFeedback.triggerAudioFeedback("dash", 0.9, {emergency = true})
            assert.spy(mockFeedbackRenderer.triggerAudio).was_called_with("dash", 0.9, {emergency = true})
        end)
        it("should delegate haptic feedback calls", function()
            EmotionalFeedback.triggerHapticFeedback("achievement", 1.0, {type = "milestone"})
            assert.spy(mockFeedbackRenderer.triggerHaptic).was_called_with("achievement", 1.0, {type = "milestone"})
        end)
        it("should delegate camera feedback calls", function()
            EmotionalFeedback.triggerCameraFeedback("explosion", 0.95, {radius = 100})
            assert.spy(mockFeedbackRenderer.triggerCamera).was_called_with("explosion", 0.95, {radius = 100})
        end)
        it("should provide emotional state access", function()
            local state = EmotionalFeedback.getEmotionalState()
            assert.spy(mockEmotionCore.getEmotionalState).was_called()
            assert.is_type("table", state)
        end)
        it("should provide emotional memory access", function()
            local memory = EmotionalFeedback.getEmotionalMemory()
            assert.spy(mockEmotionCore.getEmotionalMemory).was_called()
            assert.is_type("table", memory)
        end)
        it("should provide feedback messages", function()
            local message = EmotionalFeedback.getFeedbackMessage()
            assert.spy(mockFeedbackRenderer.getFeedbackMessage).was_called()
            assert.is_type("string", message)
        end)
        it("should provide visual effects", function()
            local effects = EmotionalFeedback.getVisualEffects()
            assert.spy(mockFeedbackRenderer.getVisualEffects).was_called()
            assert.is_type("table", effects)
        end)
        it("should provide audio cues", function()
            local cue = EmotionalFeedback.getAudioCue()
            assert.spy(mockFeedbackRenderer.getAudioCue).was_called()
            assert.is_type("table", cue)
        end)
    end)
    describe("Special Celebrations", function()
        before_each(function()
            EmotionalFeedback.init()
            mockEmotionCore.canTriggerSurprise = spy(function() return true end)
        end)
        it("should trigger first jump celebrations", function()
            EmotionalFeedback.triggerSpecialCelebration("first_jump")
            assert.spy(mockFeedbackRenderer.createCelebration).was_called_with("first_success", match.is_table())
            assert.spy(mockEmotionCore.startSurpriseCooldown).was_called_with(3.0)
        end)
        it("should trigger perfect landing celebrations", function()
            EmotionalFeedback.triggerSpecialCelebration("perfect_landing")
            assert.spy(mockFeedbackRenderer.createCelebration).was_called_with("mastery", match.is_table())
        end)
        it("should trigger discovery celebrations", function()
            EmotionalFeedback.triggerSpecialCelebration("discovery")
            assert.spy(mockFeedbackRenderer.createCelebration).was_called_with("discovery", match.is_table())
        end)
        it("should respect celebration cooldown", function()
            mockEmotionCore.canTriggerSurprise = spy(function() return false end)
            EmotionalFeedback.triggerSpecialCelebration("achievement")
            -- Should not create celebration when cooldown is active
            assert.spy(mockFeedbackRenderer.createCelebration).was_not_called()
        end)
        it("should handle legacy celebration burst calls", function()
            EmotionalFeedback.createCelebrationBurst("milestone", {intensity = 0.9})
            assert.spy(mockFeedbackRenderer.createCelebration).was_called_with("milestone", {x = 0, y = 0})
        end)
    end)
    describe("Utility Functions", function()
        it("should detect perfect landings based on game physics", function()
            local player = {x = 100, y = 200, vx = 75, vy = 50}
            local planet = {x = 105, y = 205}
            local isPerfect = EmotionalFeedback.checkPerfectLanding(player, planet)
            assert.is_type("boolean", isPerfect)
        end)
        it("should provide debug information", function()
            mockEmotionCore.getDebugInfo = spy(function()
                return {
                    state = {confidence = 0.8, momentum = 0.6, achievement_streak = 3, flow_state_duration = 8.0},
                    memory = {perfect_landings = 5, dramatic_saves = 2},
                    mood = {type = "triumphant", intensity = 0.9}
                }
            end)
            -- Mock EmotionAnalytics.getDebugInfo
            mockEmotionAnalytics.getDebugInfo = spy(function()
                return {sessionMoods = 15, patterns = 3, transitions = 42}
            end)
            EmotionalFeedback.debugEmotionalState()
            assert.spy(mockEmotionCore.getDebugInfo).was_called()
            assert.spy(mockEmotionAnalytics.getDebugInfo).was_called()
        end)
    end)
end)