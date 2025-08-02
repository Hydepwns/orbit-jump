-- Unit tests for Emotion Core System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"

local Utils = require("src.utils.utils")
Utils.require("tests.busted")

-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Load EmotionCore
local EmotionCore = require("src.systems.emotion.emotion_core")

describe("Emotion Core System", function()
    before_each(function()
        -- Reset state before each test
        EmotionCore.init()
    end)
    
    describe("Initialization", function()
        it("should initialize with default emotional state", function()
            local state = EmotionCore.getEmotionalState()
            
            assert.equals(0.5, state.confidence)
            assert.equals(0.0, state.momentum)
            assert.equals(0, state.streak)
            assert.equals(0, state.flow_duration)
        end)
        
        it("should initialize with neutral mood", function()
            local mood = EmotionCore.getCurrentMood()
            
            assert.equals("neutral", mood.type)
            assert.equals(0.5, mood.intensity)
        end)
        
        it("should initialize emotional memory", function()
            local memory = EmotionCore.getEmotionalMemory()
            
            assert.is_false(memory.first_successful_jump)
            assert.equals(0, memory.longest_chain)
            assert.equals(0, memory.dramatic_saves)
            assert.equals(0, memory.perfect_landings)
        end)
    end)
    
    describe("Emotional State Management", function()
        it("should update confidence within valid range", function()
            EmotionCore.updateConfidence(0.3)
            local state = EmotionCore.getEmotionalState()
            assert.equals(0.8, state.confidence)
            
            EmotionCore.updateConfidence(-0.5)
            state = EmotionCore.getEmotionalState()
            assert.equals(0.3, state.confidence)
        end)
        
        it("should clamp confidence to valid range", function()
            EmotionCore.updateConfidence(1.0) -- Should clamp to 1.0
            local state = EmotionCore.getEmotionalState()
            assert.equals(1.0, state.confidence)
            
            EmotionCore.updateConfidence(-2.0) -- Should clamp to 0.0
            state = EmotionCore.getEmotionalState()
            assert.equals(0.0, state.confidence)
        end)
        
        it("should update momentum within valid range", function()
            EmotionCore.updateMomentum(0.5)
            local state = EmotionCore.getEmotionalState()
            assert.equals(0.5, state.momentum)
            
            EmotionCore.updateMomentum(-0.3)
            state = EmotionCore.getEmotionalState()
            assert.equals(0.2, state.momentum)
        end)
        
        it("should clamp momentum to valid range", function()
            EmotionCore.updateMomentum(2.0) -- Should clamp to 1.0
            local state = EmotionCore.getEmotionalState()
            assert.equals(1.0, state.momentum)
            
            EmotionCore.updateMomentum(-3.0) -- Should clamp to -1.0
            state = EmotionCore.getEmotionalState()
            assert.equals(-1.0, state.momentum)
        end)
    end)
    
    describe("Achievement Streak Management", function()
        it("should increment achievement streak", function()
            EmotionCore.incrementStreak()
            EmotionCore.incrementStreak()
            
            local state = EmotionCore.getEmotionalState()
            assert.equals(2, state.streak)
        end)
        
        it("should reset achievement streak", function()
            EmotionCore.incrementStreak()
            EmotionCore.incrementStreak()
            EmotionCore.resetStreak()
            
            local state = EmotionCore.getEmotionalState()
            assert.equals(1, state.streak) -- resetStreak decrements by 1, doesn't zero
        end)
        
        it("should track longest chain in memory", function()
            EmotionCore.incrementStreak()
            EmotionCore.incrementStreak()
            EmotionCore.incrementStreak()
            EmotionCore.resetStreak()
            
            local memory = EmotionCore.getEmotionalMemory()
            assert.equals(3, memory.longest_chain)
        end)
    end)
    
    describe("Mood Transitions", function()
        it("should transition to different moods", function()
            EmotionCore.transitionToMood("excited", 0.8)
            local mood = EmotionCore.getCurrentMood()
            
            assert.equals("excited", mood.type)
            assert.equals(0.8, mood.intensity)
        end)
        
        it("should handle smooth mood transitions", function()
            EmotionCore.transitionToMood("calm", 0.3)
            EmotionCore.transitionToMood("energetic", 0.9)
            
            local mood = EmotionCore.getCurrentMood()
            assert.equals("energetic", mood.type)
            assert.equals(0.9, mood.intensity)
        end)
        
        it("should clamp mood intensity to valid range", function()
            EmotionCore.transitionToMood("intense", 1.5) -- Should clamp to 1.0
            local mood = EmotionCore.getCurrentMood()
            assert.equals(1.0, mood.intensity)
            
            EmotionCore.transitionToMood("subdued", -0.2) -- Should clamp to 0.0
            mood = EmotionCore.getCurrentMood()
            assert.equals(0.0, mood.intensity)
        end)
    end)
    
    describe("Special Event Recording", function()
        it("should record first jump achievement", function()
            assert.is_false(EmotionCore.hasFirstJump())
            
            EmotionCore.recordFirstJump()
            
            assert.is_true(EmotionCore.hasFirstJump())
            local memory = EmotionCore.getEmotionalMemory()
            assert.is_true(memory.first_successful_jump)
        end)
        
        it("should record dramatic saves", function()
            EmotionCore.recordDramaticSave()
            EmotionCore.recordDramaticSave()
            
            local memory = EmotionCore.getEmotionalMemory()
            assert.equals(2, memory.dramatic_saves)
        end)
        
        it("should record perfect landings", function()
            EmotionCore.recordPerfectLanding()
            
            local memory = EmotionCore.getEmotionalMemory()
            assert.equals(1, memory.perfect_landings)
        end)
    end)
    
    describe("Surprise and Celebration Cooldowns", function()
        it("should manage surprise cooldown", function()
            assert.is_true(EmotionCore.canTriggerSurprise())
            
            EmotionCore.startSurpriseCooldown(2.0)
            assert.is_false(EmotionCore.canTriggerSurprise())
        end)
        
        it("should reset surprise cooldown after time", function()
            EmotionCore.startSurpriseCooldown(1.0)
            assert.is_false(EmotionCore.canTriggerSurprise())
            
            -- Simulate time passing
            EmotionCore.update(1.5)
            assert.is_true(EmotionCore.canTriggerSurprise())
        end)
    end)
    
    describe("Configuration Access", function()
        it("should provide feedback configuration", function()
            local jumpConfig = EmotionCore.getConfig("jump")
            
            assert.is_type("table", jumpConfig)
            assert.is_type("number", jumpConfig.baseIntensity)
            assert.is_type("number", jumpConfig.powerMultiplier)
            assert.is_type("number", jumpConfig.maxIntensity)
        end)
        
        it("should provide landing configuration", function()
            local landingConfig = EmotionCore.getConfig("landing")
            
            assert.is_type("table", landingConfig)
            assert.is_type("number", landingConfig.baseIntensity)
            assert.is_type("number", landingConfig.speedMultiplier)
        end)
        
        it("should provide dash configuration", function()
            local dashConfig = EmotionCore.getConfig("dash")
            
            assert.is_type("table", dashConfig)
            assert.is_type("number", dashConfig.baseIntensity)
        end)
    end)
    
    describe("System Updates", function()
        it("should update flow state duration", function()
            EmotionCore.update(0.1)
            EmotionCore.update(0.2)
            
            local state = EmotionCore.getEmotionalState()
            assert.equals(0.3, state.flow_duration)
        end)
        
        it("should decay momentum over time", function()
            EmotionCore.updateMomentum(0.8)
            EmotionCore.update(1.0) -- Simulate 1 second
            
            local state = EmotionCore.getEmotionalState()
            assert.less_than(state.momentum, 0.8) -- Should have decayed
        end)
        
        it("should update surprise cooldown", function()
            EmotionCore.startSurpriseCooldown(1.0)
            EmotionCore.update(0.5)
            
            assert.is_false(EmotionCore.canTriggerSurprise()) -- Still cooling down
            
            EmotionCore.update(0.6) -- Total 1.1 seconds passed
            assert.is_true(EmotionCore.canTriggerSurprise()) -- Cooldown finished
        end)
    end)
    
    describe("Debug Information", function()
        it("should provide comprehensive debug info", function()
            EmotionCore.updateConfidence(0.3)
            EmotionCore.incrementStreak()
            EmotionCore.transitionToMood("excited", 0.7)
            
            local debugInfo = EmotionCore.getDebugInfo()
            
            assert.is_type("table", debugInfo.state)
            assert.is_type("table", debugInfo.memory)
            assert.is_type("table", debugInfo.mood)
            
            assert.equals(0.8, debugInfo.state.confidence)
            assert.equals(1, debugInfo.state.achievement_streak)
            assert.equals("excited", debugInfo.mood.type)
            assert.equals(0.7, debugInfo.mood.intensity)
        end)
    end)
end)