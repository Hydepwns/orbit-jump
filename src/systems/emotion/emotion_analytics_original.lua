--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotion Analytics: Pattern tracking and mood progression analysis
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles emotional pattern tracking, mood progression analysis,
    and integration with the player analytics system.
--]]

local Utils = require("src.utils.utils")
local EmotionAnalytics = {}

-- Analytics state
local analyticsData = {
    sessionMoods = {},           -- Mood changes during current session
    emotionalPatterns = {},      -- Recurring emotional patterns
    triggerEffectiveness = {},   -- How effective different triggers are
    moodTransitions = {},        -- Transitions between mood states
    sessionStartTime = 0
}

-- Pattern detection thresholds
local PATTERN_DETECTION = {
    MIN_OCCURRENCES = 3,         -- Minimum times pattern must occur
    TIME_WINDOW = 300,           -- 5 minutes in seconds
    EFFECTIVENESS_THRESHOLD = 0.7 -- Minimum effectiveness to track
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Analytics Initialization and Management
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionAnalytics.init()
    analyticsData.sessionMoods = {}
    analyticsData.emotionalPatterns = {}
    analyticsData.triggerEffectiveness = {}
    analyticsData.moodTransitions = {}
    analyticsData.sessionStartTime = love.timer.getTime()
    
    Utils.Logger.info("📊 Emotion Analytics initialized")
    return true
end

function EmotionAnalytics.update(dt)
    -- Periodic analysis and cleanup
    local currentTime = love.timer.getTime()
    local sessionDuration = currentTime - analyticsData.sessionStartTime
    
    -- Every 30 seconds, analyze patterns
    if math.floor(sessionDuration) % 30 == 0 then
        EmotionAnalytics._analyzeEmotionalPatterns()
    end
    
    -- Clean up old data every 5 minutes
    if math.floor(sessionDuration) % 300 == 0 then
        EmotionAnalytics._cleanupOldData()
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotional Event Tracking
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionAnalytics.recordMoodChange(fromMood, toMood, trigger, intensity)
    local timestamp = love.timer.getTime()
    
    -- Record mood change
    table.insert(analyticsData.sessionMoods, {
        timestamp = timestamp,
        fromMood = fromMood,
        toMood = toMood,
        trigger = trigger,
        intensity = intensity
    })
    
    -- Track mood transitions
    local transitionKey = fromMood .. "_to_" .. toMood
    if not analyticsData.moodTransitions[transitionKey] then
        analyticsData.moodTransitions[transitionKey] = {
            count = 0,
            totalIntensity = 0,
            triggers = {}
        }
    end
    
    local transition = analyticsData.moodTransitions[transitionKey]
    transition.count = transition.count + 1
    transition.totalIntensity = transition.totalIntensity + intensity
    
    -- Track triggers for this transition
    if not transition.triggers[trigger] then
        transition.triggers[trigger] = 0
    end
    transition.triggers[trigger] = transition.triggers[trigger] + 1
end

function EmotionAnalytics.recordTriggerEffectiveness(trigger, expectedIntensity, actualIntensity)
    if not analyticsData.triggerEffectiveness[trigger] then
        analyticsData.triggerEffectiveness[trigger] = {
            samples = 0,
            totalExpected = 0,
            totalActual = 0,
            effectiveness = 0
        }
    end
    
    local data = analyticsData.triggerEffectiveness[trigger]
    data.samples = data.samples + 1
    data.totalExpected = data.totalExpected + expectedIntensity
    data.totalActual = data.totalActual + actualIntensity
    
    -- Calculate effectiveness as ratio of actual to expected
    data.effectiveness = data.totalActual / data.totalExpected
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Pattern Analysis
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionAnalytics._analyzeEmotionalPatterns()
    local currentTime = love.timer.getTime()
    local windowStart = currentTime - PATTERN_DETECTION.TIME_WINDOW
    
    -- Filter recent mood changes
    local recentMoods = {}
    for _, mood in ipairs(analyticsData.sessionMoods) do
        if mood.timestamp >= windowStart then
            table.insert(recentMoods, mood)
        end
    end
    
    -- Look for recurring patterns
    EmotionAnalytics._detectMoodSequences(recentMoods)
    EmotionAnalytics._detectTriggerPatterns(recentMoods)
end

function EmotionAnalytics._detectMoodSequences(recentMoods)
    -- Detect sequences of mood changes that repeat
    local sequences = {}
    
    for i = 1, #recentMoods - 2 do
        local sequence = recentMoods[i].toMood .. "_" .. recentMoods[i+1].toMood .. "_" .. recentMoods[i+2].toMood
        
        if not sequences[sequence] then
            sequences[sequence] = 0
        end
        sequences[sequence] = sequences[sequence] + 1
    end
    
    -- Store significant patterns
    for sequence, count in pairs(sequences) do
        if count >= PATTERN_DETECTION.MIN_OCCURRENCES then
            analyticsData.emotionalPatterns[sequence] = {
                type = "mood_sequence",
                count = count,
                lastSeen = love.timer.getTime()
            }
        end
    end
end

function EmotionAnalytics._detectTriggerPatterns(recentMoods)
    -- Detect which triggers are most effective in different contexts
    local triggerContexts = {}
    
    for _, mood in ipairs(recentMoods) do
        local context = mood.fromMood .. "_context"
        
        if not triggerContexts[context] then
            triggerContexts[context] = {}
        end
        
        if not triggerContexts[context][mood.trigger] then
            triggerContexts[context][mood.trigger] = {
                count = 0,
                totalIntensity = 0
            }
        end
        
        local triggerData = triggerContexts[context][mood.trigger]
        triggerData.count = triggerData.count + 1
        triggerData.totalIntensity = triggerData.totalIntensity + mood.intensity
    end
    
    -- Store effective trigger patterns
    for context, triggers in pairs(triggerContexts) do
        for trigger, data in pairs(triggers) do
            local avgIntensity = data.totalIntensity / data.count
            if avgIntensity >= PATTERN_DETECTION.EFFECTIVENESS_THRESHOLD then
                local patternKey = context .. "_" .. trigger
                analyticsData.emotionalPatterns[patternKey] = {
                    type = "trigger_effectiveness",
                    avgIntensity = avgIntensity,
                    count = data.count,
                    lastSeen = love.timer.getTime()
                }
            end
        end
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Analytics Insights
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionAnalytics.getMoodProgression()
    -- Return mood progression over the session
    local progression = {}
    
    for _, mood in ipairs(analyticsData.sessionMoods) do
        table.insert(progression, {
            time = mood.timestamp - analyticsData.sessionStartTime,
            mood = mood.toMood,
            intensity = mood.intensity
        })
    end
    
    return progression
end

function EmotionAnalytics.getEmotionalSummary()
    -- Provide a summary of emotional patterns and insights
    local summary = {
        sessionDuration = love.timer.getTime() - analyticsData.sessionStartTime,
        totalMoodChanges = #analyticsData.sessionMoods,
        dominantMood = EmotionAnalytics._getDominantMood(),
        mostEffectiveTriggers = EmotionAnalytics._getMostEffectiveTriggers(),
        emotionalStability = EmotionAnalytics._calculateEmotionalStability(),
        patterns = analyticsData.emotionalPatterns
    }
    
    return summary
end

function EmotionAnalytics._getDominantMood()
    local moodCounts = {}
    
    for _, mood in ipairs(analyticsData.sessionMoods) do
        if not moodCounts[mood.toMood] then
            moodCounts[mood.toMood] = 0
        end
        moodCounts[mood.toMood] = moodCounts[mood.toMood] + 1
    end
    
    local dominantMood = "neutral"
    local maxCount = 0
    
    for mood, count in pairs(moodCounts) do
        if count > maxCount then
            maxCount = count
            dominantMood = mood
        end
    end
    
    return dominantMood
end

function EmotionAnalytics._getMostEffectiveTriggers()
    local effectiveTriggers = {}
    
    for trigger, data in pairs(analyticsData.triggerEffectiveness) do
        if data.effectiveness >= PATTERN_DETECTION.EFFECTIVENESS_THRESHOLD then
            table.insert(effectiveTriggers, {
                trigger = trigger,
                effectiveness = data.effectiveness,
                samples = data.samples
            })
        end
    end
    
    -- Sort by effectiveness
    table.sort(effectiveTriggers, function(a, b)
        return a.effectiveness > b.effectiveness
    end)
    
    return effectiveTriggers
end

function EmotionAnalytics._calculateEmotionalStability()
    -- Calculate how stable the player's emotional state is
    if #analyticsData.sessionMoods < 2 then
        return 1.0  -- Perfectly stable if no mood changes
    end
    
    local intensityVariation = 0
    for i = 2, #analyticsData.sessionMoods do
        local diff = math.abs(analyticsData.sessionMoods[i].intensity - analyticsData.sessionMoods[i-1].intensity)
        intensityVariation = intensityVariation + diff
    end
    
    local avgVariation = intensityVariation / (#analyticsData.sessionMoods - 1)
    
    -- Return stability as inverse of variation (0-1 scale)
    return math.max(0, 1 - avgVariation)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Integration with Player Analytics
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionAnalytics.getPlayerAnalyticsData()
    -- Prepare emotional data for player analytics system
    local PlayerAnalytics = Utils.require("src.systems.analytics.behavior_tracker")
    
    if not PlayerAnalytics then
        return nil
    end
    
    return {
        emotionalSummary = EmotionAnalytics.getEmotionalSummary(),
        moodProgression = EmotionAnalytics.getMoodProgression(),
        triggerEffectiveness = analyticsData.triggerEffectiveness,
        detectedPatterns = analyticsData.emotionalPatterns
    }
end

function EmotionAnalytics.integrateWithBehaviorTracker(behaviorData)
    -- Correlate emotional patterns with behavior patterns
    -- This allows us to understand which behaviors lead to which emotions
    
    local correlations = {}
    
    -- Example: correlate jump success rate with mood changes
    if behaviorData.jumpSuccessRate then
        local recentMoods = EmotionAnalytics._getRecentMoods(60) -- Last minute
        local avgMoodIntensity = 0
        
        for _, mood in ipairs(recentMoods) do
            avgMoodIntensity = avgMoodIntensity + mood.intensity
        end
        
        if #recentMoods > 0 then
            avgMoodIntensity = avgMoodIntensity / #recentMoods
            correlations.jumpSuccessToMood = {
                successRate = behaviorData.jumpSuccessRate,
                avgMoodIntensity = avgMoodIntensity
            }
        end
    end
    
    return correlations
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions
    ═══════════════════════════════════════════════════════════════════════════
--]]

function EmotionAnalytics._getRecentMoods(timeWindow)
    local currentTime = love.timer.getTime()
    local windowStart = currentTime - timeWindow
    local recentMoods = {}
    
    for _, mood in ipairs(analyticsData.sessionMoods) do
        if mood.timestamp >= windowStart then
            table.insert(recentMoods, mood)
        end
    end
    
    return recentMoods
end

function EmotionAnalytics._cleanupOldData()
    -- Remove data older than 30 minutes to prevent memory bloat
    local currentTime = love.timer.getTime()
    local cutoffTime = currentTime - 1800  -- 30 minutes
    
    -- Clean up session moods
    local newSessionMoods = {}
    for _, mood in ipairs(analyticsData.sessionMoods) do
        if mood.timestamp >= cutoffTime then
            table.insert(newSessionMoods, mood)
        end
    end
    analyticsData.sessionMoods = newSessionMoods
    
    -- Clean up old patterns
    for patternKey, pattern in pairs(analyticsData.emotionalPatterns) do
        if pattern.lastSeen < cutoffTime then
            analyticsData.emotionalPatterns[patternKey] = nil
        end
    end
end

function EmotionAnalytics.getDebugInfo()
    return {
        sessionMoods = #analyticsData.sessionMoods,
        patterns = Utils.tableSize(analyticsData.emotionalPatterns),
        transitions = Utils.tableSize(analyticsData.moodTransitions),
        triggers = Utils.tableSize(analyticsData.triggerEffectiveness)
    }
end

return EmotionAnalytics