-- Unit tests for Pattern Analyzer System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Load PatternAnalyzer
local PatternAnalyzer = require("src.systems.analytics.pattern_analyzer")
describe("Pattern Analyzer System", function()
    before_each(function()
        -- Reset analyzer state if there's an init function
        if PatternAnalyzer.init then
            PatternAnalyzer.init()
        end
    end)
    describe("Skill Progression Profile", function()
        it("should have skill progression structure", function()
            local skill = PatternAnalyzer.skillProgression
            assert.is_type("table", skill)
            assert.is_type("number", skill.initialSkill)
            assert.is_type("number", skill.currentSkill)
            assert.is_type("number", skill.skillVelocity)
            assert.is_type("boolean", skill.skillPlateau)
        end)
        it("should have mastery indicators", function()
            local skill = PatternAnalyzer.skillProgression
            assert.is_type("number", skill.consistency)
            assert.is_type("number", skill.adaptability)
            assert.is_type("number", skill.efficiency)
            assert.is_type("number", skill.creativity)
        end)
        it("should have learning pattern metrics", function()
            local skill = PatternAnalyzer.skillProgression
            assert.is_type("number", skill.practiceTime)
            assert.is_type("number", skill.challengeSeeking)
            assert.is_type("number", skill.failureRecovery)
            assert.is_type("table", skill.improvementRate)
        end)
        it("should initialize with default skill values", function()
            local skill = PatternAnalyzer.skillProgression
            assert.equals(0, skill.initialSkill)
            assert.equals(0, skill.currentSkill)
            assert.equals(0, skill.skillVelocity)
            assert.is_false(skill.skillPlateau)
        end)
    end)
    describe("Emotional Profile", function()
        it("should have emotional pattern structure", function()
            local emotion = PatternAnalyzer.emotionalProfile
            assert.is_type("table", emotion)
            assert.is_type("number", emotion.frustrationTolerance)
            assert.is_type("number", emotion.flowStateDuration)
            assert.is_type("number", emotion.pauseFrequency)
            assert.is_type("number", emotion.retryPersistence)
        end)
        it("should have current emotional state", function()
            local emotion = PatternAnalyzer.emotionalProfile
            assert.is_type("string", emotion.currentMood)
            assert.is_type("number", emotion.sessionEnergy)
            assert.is_type("number", emotion.confidenceLevel)
        end)
        it("should have satisfaction indicators", function()
            local emotion = PatternAnalyzer.emotionalProfile
            assert.is_type("table", emotion.achievementReactions)
            assert.is_type("table", emotion.failurePatterns)
            assert.is_type("number", emotion.engagementLevel)
            assert.is_type("number", emotion.sessionSatisfaction)
        end)
        it("should initialize with default emotional values", function()
            local emotion = PatternAnalyzer.emotionalProfile
            assert.equals("neutral", emotion.currentMood)
            assert.equals(1.0, emotion.sessionEnergy)
            assert.equals(0.5, emotion.confidenceLevel)
        end)
    end)
    describe("Value Ranges", function()
        it("should have skill values in valid ranges", function()
            local skill = PatternAnalyzer.skillProgression
            -- Skill levels should be normalized 0-1
            assert.is_true(skill.currentSkill >= 0)
            assert.is_true(skill.currentSkill <= 1)
            assert.is_true(skill.initialSkill >= 0)
            assert.is_true(skill.initialSkill <= 1)
        end)
        it("should have mastery indicators in valid ranges", function()
            local skill = PatternAnalyzer.skillProgression
            assert.is_true(skill.consistency >= 0)
            assert.is_true(skill.adaptability >= 0)
            assert.is_true(skill.efficiency >= 0)
            assert.is_true(skill.creativity >= 0)
        end)
        it("should have emotional values in valid ranges", function()
            local emotion = PatternAnalyzer.emotionalProfile
            assert.is_true(emotion.sessionEnergy >= 0)
            assert.is_true(emotion.sessionEnergy <= 1)
            assert.is_true(emotion.confidenceLevel >= 0)
            assert.is_true(emotion.confidenceLevel <= 1)
        end)
        it("should have non-negative time-based metrics", function()
            local skill = PatternAnalyzer.skillProgression
            local emotion = PatternAnalyzer.emotionalProfile
            assert.greater_or_equal(0, skill.practiceTime)
            assert.greater_or_equal(0, emotion.flowStateDuration)
            assert.greater_or_equal(0, emotion.pauseFrequency)
        end)
    end)
    describe("Data Structure Integrity", function()
        it("should maintain separate profile structures", function()
            local skill = PatternAnalyzer.skillProgression
            local emotion = PatternAnalyzer.emotionalProfile
            -- Should be different objects
            assert.not_equal(skill, emotion)
            -- Should have different field sets
            assert.is_not_nil(skill.skillVelocity)
            assert.is_nil(skill.currentMood)
            assert.is_not_nil(emotion.currentMood)
            assert.is_nil(emotion.skillVelocity)
        end)
        it("should allow profile modifications", function()
            local skill = PatternAnalyzer.skillProgression
            local originalSkill = skill.currentSkill
            skill.currentSkill = 0.7
            assert.equals(0.7, skill.currentSkill)
            assert.not_equal(originalSkill, skill.currentSkill)
        end)
        it("should handle mood changes", function()
            local emotion = PatternAnalyzer.emotionalProfile
            emotion.currentMood = "focused"
            assert.equals("focused", emotion.currentMood)
        end)
        it("should maintain array structures", function()
            local skill = PatternAnalyzer.skillProgression
            local emotion = PatternAnalyzer.emotionalProfile
            assert.is_type("table", skill.improvementRate)
            assert.is_type("table", emotion.achievementReactions)
            assert.is_type("table", emotion.failurePatterns)
        end)
    end)
    describe("Profile Access", function()
        it("should provide read access to skill metrics", function()
            local skill = PatternAnalyzer.skillProgression
            -- Should be able to read all metrics without errors
            local _ = skill.currentSkill
            local _ = skill.consistency
            local _ = skill.adaptability
            local _ = skill.practiceTime
            -- If we get here, all accesses succeeded
            assert.is_true(true)
        end)
        it("should provide read access to emotional metrics", function()
            local emotion = PatternAnalyzer.emotionalProfile
            -- Should be able to read all metrics without errors
            local _ = emotion.currentMood
            local _ = emotion.sessionEnergy
            local _ = emotion.confidenceLevel
            local _ = emotion.engagementLevel
            -- If we get here, all accesses succeeded
            assert.is_true(true)
        end)
        it("should handle missing fields gracefully", function()
            local skill = PatternAnalyzer.skillProgression
            -- Accessing non-existent field should return nil
            assert.is_nil(skill.nonExistentField)
        end)
    end)
    describe("State Management", function()
        it("should maintain skill progression state", function()
            local skill = PatternAnalyzer.skillProgression
            skill.currentSkill = 0.8
            skill.skillPlateau = true
            skill.consistency = 0.9
            assert.equals(0.8, skill.currentSkill)
            assert.is_true(skill.skillPlateau)
            assert.equals(0.9, skill.consistency)
        end)
        it("should maintain emotional state", function()
            local emotion = PatternAnalyzer.emotionalProfile
            emotion.currentMood = "mastery"
            emotion.sessionEnergy = 0.3
            emotion.confidenceLevel = 0.9
            assert.equals("mastery", emotion.currentMood)
            assert.equals(0.3, emotion.sessionEnergy)
            assert.equals(0.9, emotion.confidenceLevel)
        end)
        it("should handle array data modifications", function()
            local skill = PatternAnalyzer.skillProgression
            table.insert(skill.improvementRate, {time = 100, skill = 0.5})
            assert.equals(1, #skill.improvementRate)
            assert.equals(100, skill.improvementRate[1].time)
        end)
    end)
    describe("Mood States", function()
        it("should handle different mood states", function()
            local emotion = PatternAnalyzer.emotionalProfile
            local validMoods = {"neutral", "focused", "frustrated", "exploring", "mastery"}
            for _, mood in ipairs(validMoods) do
                emotion.currentMood = mood
                assert.equals(mood, emotion.currentMood)
            end
        end)
        it("should handle custom mood states", function()
            local emotion = PatternAnalyzer.emotionalProfile
            emotion.currentMood = "determined"
            assert.equals("determined", emotion.currentMood)
        end)
    end)
end)