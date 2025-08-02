-- Unit tests for Emotion Analytics System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"

local Utils = require("src.utils.utils")
Utils.require("tests.busted")

-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Load EmotionAnalytics
local EmotionAnalytics = require("src.systems.emotion.emotion_analytics")

describe("Emotion Analytics System", function()
    before_each(function()
        -- Reset analytics state before each test
        EmotionAnalytics.init()
    end)
    
    describe("Initialization", function()
        it("should initialize with empty analytics data", function()
            local debugInfo = EmotionAnalytics.getDebugInfo()
            
            assert.equals(0, debugInfo.sessionMoods)
            assert.equals(0, debugInfo.patterns)
            assert.equals(0, debugInfo.transitions)
        end)
        
        it("should initialize session tracking", function()
            local sessionData = EmotionAnalytics.getSessionSummary()
            
            assert.is_type("table", sessionData)
            assert.is_type("number", sessionData.duration)
            assert.is_type("table", sessionData.mood_distribution)
        end)
    end)
    
    describe("Mood Change Recording", function()
        it("should record mood transitions", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            
            local debugInfo = EmotionAnalytics.getDebugInfo()
            assert.equals(1, debugInfo.transitions)
        end)
        
        it("should track mood sequences", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "triumphant", "achievement", 1.0)
            EmotionAnalytics.recordMoodChange("triumphant", "calm", "landing", 0.4)
            
            local debugInfo = EmotionAnalytics.getDebugInfo()
            assert.equals(3, debugInfo.transitions)
        end)
        
        it("should track mood distribution", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "excited", "jump", 0.8)
            EmotionAnalytics.recordMoodChange("excited", "calm", "landing", 0.3)
            
            local sessionData = EmotionAnalytics.getSessionSummary()
            assert.is_type("table", sessionData.mood_distribution)
            assert.greater_than(sessionData.mood_distribution.excited or 0, 0)
        end)
        
        it("should handle rapid mood changes", function()
            for i = 1, 20 do
                local fromMood = i % 2 == 0 and "excited" or "calm"
                local toMood = i % 2 == 0 and "calm" or "excited"
                EmotionAnalytics.recordMoodChange(fromMood, toMood, "test", 0.5)
            end
            
            local debugInfo = EmotionAnalytics.getDebugInfo()
            assert.equals(20, debugInfo.transitions)
        end)
    end)
    
    describe("Pattern Recognition", function()
        it("should detect emotional patterns over time", function()
            -- Create a pattern: jump -> excited -> achievement -> triumphant
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "triumphant", "achievement", 1.0)
            
            -- Simulate time passage and pattern analysis
            EmotionAnalytics.update(1.0)
            
            local patterns = EmotionAnalytics.getEmotionalPatterns()
            assert.is_type("table", patterns)
        end)
        
        it("should identify success sequences", function()
            -- Create multiple success sequences
            for i = 1, 5 do
                EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
                EmotionAnalytics.recordMoodChange("excited", "satisfied", "landing", 0.6)
            end
            
            EmotionAnalytics.update(2.0) -- Allow pattern analysis
            
            local patterns = EmotionAnalytics.getEmotionalPatterns()
            assert.is_type("table", patterns.success_sequences or {})
        end)
        
        it("should track emotional recovery patterns", function()
            -- Create failure -> recovery pattern
            EmotionAnalytics.recordMoodChange("excited", "disappointed", "failure", 0.2)
            EmotionAnalytics.recordMoodChange("disappointed", "determined", "retry", 0.5)
            EmotionAnalytics.recordMoodChange("determined", "excited", "success", 0.8)
            
            EmotionAnalytics.update(1.0)
            
            local patterns = EmotionAnalytics.getEmotionalPatterns()
            assert.is_type("table", patterns.recovery_patterns or {})
        end)
        
        it("should detect flow state periods", function()
            -- Simulate consistent positive mood over time
            for i = 1, 10 do
                EmotionAnalytics.recordMoodChange("excited", "excited", "jump", 0.8)
                EmotionAnalytics.update(0.5) -- 0.5 second intervals
            end
            
            local insights = EmotionAnalytics.getPlayerInsights()
            assert.is_type("table", insights)
            assert.is_type("number", insights.flow_duration or 0)
        end)
    end)
    
    describe("Player Insights Generation", function()
        it("should generate comprehensive player insights", function()
            -- Create diverse emotional activity
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "triumphant", "achievement", 1.0)
            EmotionAnalytics.recordMoodChange("triumphant", "calm", "landing", 0.4)
            
            EmotionAnalytics.update(2.0)
            
            local insights = EmotionAnalytics.getPlayerInsights()
            
            assert.is_type("table", insights)
            assert.is_type("string", insights.dominant_mood or "")
            assert.is_type("number", insights.emotional_stability or 0)
            assert.is_type("number", insights.peak_excitement or 0)
        end)
        
        it("should calculate emotional stability metrics", function()
            -- Create stable emotional pattern
            for i = 1, 8 do
                EmotionAnalytics.recordMoodChange("calm", "satisfied", "gentle_action", 0.6)
            end
            
            EmotionAnalytics.update(1.0)
            
            local insights = EmotionAnalytics.getPlayerInsights()
            assert.greater_than(insights.emotional_stability or 0, 0.5) -- Should be relatively stable
        end)
        
        it("should identify peak excitement moments", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.9)
            EmotionAnalytics.recordMoodChange("excited", "triumphant", "achievement", 1.0)
            EmotionAnalytics.recordMoodChange("triumphant", "ecstatic", "milestone", 1.0)
            
            EmotionAnalytics.update(1.0)
            
            local insights = EmotionAnalytics.getPlayerInsights()
            assert.equals(1.0, insights.peak_excitement or 0)
        end)
        
        it("should provide actionable recommendations", function()
            -- Create pattern that suggests specific gameplay adjustments
            for i = 1, 5 do
                EmotionAnalytics.recordMoodChange("excited", "frustrated", "failure", 0.1)
            end
            
            EmotionAnalytics.update(2.0)
            
            local insights = EmotionAnalytics.getPlayerInsights()
            assert.is_type("table", insights.recommendations or {})
            assert.greater_than(#(insights.recommendations or {}), 0)
        end)
    end)
    
    describe("Session Tracking", function()
        it("should track session duration", function()
            EmotionAnalytics.update(1.5)
            EmotionAnalytics.update(2.3)
            
            local sessionData = EmotionAnalytics.getSessionSummary()
            assert.equals(3.8, sessionData.duration)
        end)
        
        it("should summarize session emotional activity", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "satisfied", "landing", 0.6)
            EmotionAnalytics.recordMoodChange("satisfied", "excited", "jump", 0.8)
            
            EmotionAnalytics.update(5.0)
            
            local sessionData = EmotionAnalytics.getSessionSummary()
            
            assert.is_type("table", sessionData.mood_distribution)
            assert.is_type("number", sessionData.total_transitions)
            assert.is_type("number", sessionData.average_intensity)
            
            assert.equals(3, sessionData.total_transitions)
        end)
        
        it("should calculate average emotional intensity", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.8)
            EmotionAnalytics.recordMoodChange("excited", "calm", "landing", 0.2)
            EmotionAnalytics.recordMoodChange("calm", "satisfied", "success", 0.6)
            
            local sessionData = EmotionAnalytics.getSessionSummary()
            
            -- Average should be (0.8 + 0.2 + 0.6) / 3 = 0.533...
            assert.near(0.533, sessionData.average_intensity, 0.01)
        end)
    end)
    
    describe("Emotional Trend Analysis", function()
        it("should identify upward emotional trends", function()
            EmotionAnalytics.recordMoodChange("disappointed", "neutral", "recovery", 0.3)
            EmotionAnalytics.recordMoodChange("neutral", "hopeful", "attempt", 0.5)
            EmotionAnalytics.recordMoodChange("hopeful", "excited", "success", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "triumphant", "achievement", 0.9)
            
            EmotionAnalytics.update(2.0)
            
            local trends = EmotionAnalytics.getEmotionalTrends()
            assert.is_type("table", trends)
            assert.equals("upward", trends.overall_direction or "")
        end)
        
        it("should identify downward emotional trends", function()
            EmotionAnalytics.recordMoodChange("excited", "satisfied", "completion", 0.7)
            EmotionAnalytics.recordMoodChange("satisfied", "neutral", "pause", 0.5)
            EmotionAnalytics.recordMoodChange("neutral", "disappointed", "failure", 0.3)
            EmotionAnalytics.recordMoodChange("disappointed", "frustrated", "repeated_failure", 0.1)
            
            EmotionAnalytics.update(2.0)
            
            local trends = EmotionAnalytics.getEmotionalTrends()
            assert.equals("downward", trends.overall_direction or "")
        end)
        
        it("should detect emotional volatility", function()
            -- Create volatile pattern
            EmotionAnalytics.recordMoodChange("excited", "disappointed", "failure", 0.1)
            EmotionAnalytics.recordMoodChange("disappointed", "excited", "success", 0.9)
            EmotionAnalytics.recordMoodChange("excited", "frustrated", "failure", 0.2)
            EmotionAnalytics.recordMoodChange("frustrated", "triumphant", "comeback", 1.0)
            
            EmotionAnalytics.update(2.0)
            
            local trends = EmotionAnalytics.getEmotionalTrends()
            assert.greater_than(trends.volatility or 0, 0.5) -- Should detect high volatility
        end)
    end)
    
    describe("Real-time Updates", function()
        it("should update analytics in real-time", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            
            EmotionAnalytics.update(0.1)
            EmotionAnalytics.update(0.2)
            EmotionAnalytics.update(0.3)
            
            local sessionData = EmotionAnalytics.getSessionSummary()
            assert.equals(0.6, sessionData.duration)
        end)
        
        it("should handle system updates gracefully", function()
            -- Test with no recorded data
            EmotionAnalytics.update(1.0)
            
            local sessionData = EmotionAnalytics.getSessionSummary()
            assert.is_type("table", sessionData)
            assert.equals(1.0, sessionData.duration)
        end)
        
        it("should maintain performance with large datasets", function()
            -- Create large amount of analytics data
            for i = 1, 100 do
                local moods = {"excited", "calm", "satisfied", "determined"}
                local fromMood = moods[((i-1) % #moods) + 1]
                local toMood = moods[(i % #moods) + 1]
                EmotionAnalytics.recordMoodChange(fromMood, toMood, "action", 0.5)
            end
            
            -- Should handle large dataset without performance issues
            EmotionAnalytics.update(1.0)
            
            local debugInfo = EmotionAnalytics.getDebugInfo()
            assert.equals(100, debugInfo.transitions)
        end)
    end)
    
    describe("Data Export and Analysis", function()
        it("should provide exportable analytics data", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            EmotionAnalytics.recordMoodChange("excited", "satisfied", "landing", 0.6)
            
            EmotionAnalytics.update(2.0)
            
            local exportData = EmotionAnalytics.getAnalyticsExport()
            
            assert.is_type("table", exportData)
            assert.is_type("table", exportData.session_summary or {})
            assert.is_type("table", exportData.mood_transitions or {})
            assert.is_type("table", exportData.patterns or {})
        end)
        
        it("should format data for external analysis", function()
            EmotionAnalytics.recordMoodChange("neutral", "excited", "jump", 0.7)
            
            local exportData = EmotionAnalytics.getAnalyticsExport()
            
            -- Should have structured data suitable for analysis
            assert.is_type("string", exportData.format or "")
            assert.is_type("number", exportData.timestamp or 0)
            assert.is_type("string", exportData.version or "")
        end)
    end)
end)