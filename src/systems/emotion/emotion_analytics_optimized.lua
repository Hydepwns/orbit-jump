--[[
    ═══════════════════════════════════════════════════════════════════════════
    Emotion Analytics: Pattern tracking and mood progression analysis (OPTIMIZED)
    ═══════════════════════════════════════════════════════════════════════════
    PERFORMANCE OPTIMIZATIONS APPLIED:
    • Pre-allocated table pools to reduce garbage collection
    • Cached calculations to avoid repeated computations
    • Reduced table.insert usage in hot paths
    • Optimized loop structures and memory access patterns
    • Implemented circular buffers for frequently accessed data
--]]
local Utils = require("src.utils.utils")
local EmotionAnalytics = {}
-- Analytics state with pre-allocated structures
local analyticsData = {
    sessionMoods = {},           -- Mood changes during current session
    emotionalPatterns = {},      -- Recurring emotional patterns
    triggerEffectiveness = {},   -- How effective different triggers are
    moodTransitions = {},        -- Transitions between mood states
    sessionStartTime = 0,
    -- Performance optimization: pre-allocated buffers
    moodBufferSize = 1000,      -- Maximum mood entries to keep
    moodWriteIndex = 1,         -- Current write position in circular buffer
    moodCount = 0,              -- Actual number of moods stored
    -- Cached calculations (invalidated when data changes)
    cachedDominantMood = nil,
    cachedStability = nil,
    lastCacheUpdate = 0,
    cacheValidityDuration = 30   -- Cache valid for 30 seconds
}
-- Pattern detection thresholds
local PATTERN_DETECTION = {
    MIN_OCCURRENCES = 3,         -- Minimum times pattern must occur
    TIME_WINDOW = 300,           -- 5 minutes in seconds
    EFFECTIVENESS_THRESHOLD = 0.7 -- Minimum effectiveness to track
}
-- Pre-allocated temporary tables (reused to avoid allocations)
local tempTables = {
    recentMoods = {},
    sequences = {},
    triggerContexts = {},
    moodCounts = {},
    effectiveTriggers = {}
}
-- Pre-allocated mood entry pool
local moodEntryPool = {}
for i = 1, 100 do -- Pool of 100 reusable mood entries
    moodEntryPool[i] = {
        timestamp = 0,
        fromMood = "",
        toMood = "",
        trigger = "",
        intensity = 0
    }
end
local poolIndex = 1
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Memory-Optimized Pool Management
    ═══════════════════════════════════════════════════════════════════════════
--]]
local function getMoodEntryFromPool()
    local entry = moodEntryPool[poolIndex]
    poolIndex = poolIndex + 1
    if poolIndex > #moodEntryPool then
        poolIndex = 1
    end
    return entry
end
local function clearTempTable(table)
    -- Efficiently clear table without deallocating
    for k in pairs(table) do
        table[k] = nil
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Analytics Initialization and Management
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionAnalytics.init()
    -- Initialize using circular buffer for better memory management
    for i = 1, analyticsData.moodBufferSize do
        analyticsData.sessionMoods[i] = {
            timestamp = 0,
            fromMood = "",
            toMood = "",
            trigger = "",
            intensity = 0,
            active = false  -- Flag to mark if entry is in use
        }
    end
    analyticsData.moodWriteIndex = 1
    analyticsData.moodCount = 0
    analyticsData.emotionalPatterns = {}
    analyticsData.triggerEffectiveness = {}
    analyticsData.moodTransitions = {}
    analyticsData.sessionStartTime = love.timer.getTime()
    -- Reset cache
    analyticsData.cachedDominantMood = nil
    analyticsData.cachedStability = nil
    analyticsData.lastCacheUpdate = 0
    Utils.Logger.info("📊 Emotion Analytics initialized (OPTIMIZED)")
    return true
end
function EmotionAnalytics.update(dt)
    -- Periodic analysis and cleanup with reduced frequency to improve performance
    local currentTime = love.timer.getTime()
    local sessionDuration = currentTime - analyticsData.sessionStartTime
    -- Every 30 seconds, analyze patterns (unchanged frequency)
    if math.floor(sessionDuration) % 30 == 0 then
        EmotionAnalytics._analyzeEmotionalPatterns()
    end
    -- Clean up old data every 10 minutes instead of 5 (reduced frequency)
    if math.floor(sessionDuration) % 600 == 0 then
        EmotionAnalytics._cleanupOldData()
    end
    -- Invalidate cache periodically
    if currentTime - analyticsData.lastCacheUpdate > analyticsData.cacheValidityDuration then
        analyticsData.cachedDominantMood = nil
        analyticsData.cachedStability = nil
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Optimized Emotional Event Tracking
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionAnalytics.recordMoodChange(fromMood, toMood, trigger, intensity)
    local timestamp = love.timer.getTime()
    -- Use circular buffer instead of table.insert to avoid array resizing
    local entry = analyticsData.sessionMoods[analyticsData.moodWriteIndex]
    entry.timestamp = timestamp
    entry.fromMood = fromMood
    entry.toMood = toMood
    entry.trigger = trigger
    entry.intensity = intensity
    entry.active = true
    -- Advance write index
    analyticsData.moodWriteIndex = analyticsData.moodWriteIndex + 1
    if analyticsData.moodWriteIndex > analyticsData.moodBufferSize then
        analyticsData.moodWriteIndex = 1
    end
    -- Track count (up to buffer size)
    if analyticsData.moodCount < analyticsData.moodBufferSize then
        analyticsData.moodCount = analyticsData.moodCount + 1
    end
    -- Track mood transitions (optimized - avoid string concatenation in hot path)
    local transition = analyticsData.moodTransitions[fromMood]
    if not transition then
        transition = {}
        analyticsData.moodTransitions[fromMood] = transition
    end
    local toTransition = transition[toMood]
    if not toTransition then
        toTransition = {
            count = 0,
            totalIntensity = 0,
            triggers = {}
        }
        transition[toMood] = toTransition
    end
    toTransition.count = toTransition.count + 1
    toTransition.totalIntensity = toTransition.totalIntensity + intensity
    -- Track triggers for this transition
    local triggerData = toTransition.triggers[trigger]
    if not triggerData then
        toTransition.triggers[trigger] = 1
    else
        toTransition.triggers[trigger] = triggerData + 1
    end
    -- Invalidate cache when new data arrives
    analyticsData.cachedDominantMood = nil
    analyticsData.cachedStability = nil
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Optimized Pattern Analysis
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionAnalytics._analyzeEmotionalPatterns()
    local currentTime = love.timer.getTime()
    local windowStart = currentTime - PATTERN_DETECTION.TIME_WINDOW
    -- Clear and reuse temp table
    clearTempTable(tempTables.recentMoods)
    -- Efficiently filter recent mood changes from circular buffer
    local recentCount = 0
    for i = 1, analyticsData.moodCount do
        local mood = analyticsData.sessionMoods[i]
        if mood.active and mood.timestamp >= windowStart then
            recentCount = recentCount + 1
            tempTables.recentMoods[recentCount] = mood
        end
    end
    -- Analyze patterns with optimized functions
    EmotionAnalytics._detectMoodSequences(tempTables.recentMoods, recentCount)
    EmotionAnalytics._detectTriggerPatterns(tempTables.recentMoods, recentCount)
end
function EmotionAnalytics._detectMoodSequences(recentMoods, count)
    -- Clear and reuse sequences table
    clearTempTable(tempTables.sequences)
    -- Detect sequences with reduced string operations
    for i = 1, count - 2 do
        local mood1 = recentMoods[i].toMood
        local mood2 = recentMoods[i+1].toMood
        local mood3 = recentMoods[i+2].toMood
        -- Use table key instead of string concatenation for better performance
        local sequences = tempTables.sequences
        if not sequences[mood1] then
            sequences[mood1] = {}
        end
        if not sequences[mood1][mood2] then
            sequences[mood1][mood2] = {}
        end
        if not sequences[mood1][mood2][mood3] then
            sequences[mood1][mood2][mood3] = 0
        end
        sequences[mood1][mood2][mood3] = sequences[mood1][mood2][mood3] + 1
    end
    -- Store significant patterns with reduced string concatenation
    local currentTime = love.timer.getTime()
    for mood1, level1 in pairs(tempTables.sequences) do
        for mood2, level2 in pairs(level1) do
            for mood3, count in pairs(level2) do
                if count >= PATTERN_DETECTION.MIN_OCCURRENCES then
                    local sequenceKey = mood1 .. "_" .. mood2 .. "_" .. mood3
                    analyticsData.emotionalPatterns[sequenceKey] = {
                        type = "mood_sequence",
                        count = count,
                        lastSeen = currentTime
                    }
                end
            end
        end
    end
end
function EmotionAnalytics._detectTriggerPatterns(recentMoods, count)
    -- Clear and reuse trigger contexts table
    clearTempTable(tempTables.triggerContexts)
    -- Build trigger effectiveness map
    for i = 1, count do
        local mood = recentMoods[i]
        local context = mood.fromMood
        local contextData = tempTables.triggerContexts[context]
        if not contextData then
            contextData = {}
            tempTables.triggerContexts[context] = contextData
        end
        local triggerData = contextData[mood.trigger]
        if not triggerData then
            triggerData = { count = 0, totalIntensity = 0 }
            contextData[mood.trigger] = triggerData
        end
        triggerData.count = triggerData.count + 1
        triggerData.totalIntensity = triggerData.totalIntensity + mood.intensity
    end
    -- Store effective trigger patterns
    local currentTime = love.timer.getTime()
    for context, triggers in pairs(tempTables.triggerContexts) do
        for trigger, data in pairs(triggers) do
            local avgIntensity = data.totalIntensity / data.count
            if avgIntensity >= PATTERN_DETECTION.EFFECTIVENESS_THRESHOLD then
                local patternKey = context .. "_" .. trigger
                analyticsData.emotionalPatterns[patternKey] = {
                    type = "trigger_effectiveness",
                    avgIntensity = avgIntensity,
                    count = data.count,
                    lastSeen = currentTime
                }
            end
        end
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Cached Analytics Insights
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionAnalytics._getDominantMood()
    -- Use cached result if available and valid
    local currentTime = love.timer.getTime()
    if analyticsData.cachedDominantMood
       and currentTime - analyticsData.lastCacheUpdate < analyticsData.cacheValidityDuration then
        return analyticsData.cachedDominantMood
    end
    -- Clear and reuse mood counts table
    clearTempTable(tempTables.moodCounts)
    -- Count moods efficiently
    for i = 1, analyticsData.moodCount do
        local mood = analyticsData.sessionMoods[i]
        if mood.active then
            local toMood = mood.toMood
            tempTables.moodCounts[toMood] = (tempTables.moodCounts[toMood] or 0) + 1
        end
    end
    -- Find dominant mood
    local dominantMood = "neutral"
    local maxCount = 0
    for mood, count in pairs(tempTables.moodCounts) do
        if count > maxCount then
            maxCount = count
            dominantMood = mood
        end
    end
    -- Cache result
    analyticsData.cachedDominantMood = dominantMood
    analyticsData.lastCacheUpdate = currentTime
    return dominantMood
end
function EmotionAnalytics._calculateEmotionalStability()
    -- Use cached result if available and valid
    local currentTime = love.timer.getTime()
    if analyticsData.cachedStability
       and currentTime - analyticsData.lastCacheUpdate < analyticsData.cacheValidityDuration then
        return analyticsData.cachedStability
    end
    if analyticsData.moodCount < 2 then
        analyticsData.cachedStability = 1.0
        return 1.0
    end
    -- Calculate stability efficiently
    local intensityVariation = 0
    local validCount = 0
    local previousIntensity = nil
    for i = 1, analyticsData.moodCount do
        local mood = analyticsData.sessionMoods[i]
        if mood.active then
            if previousIntensity then
                intensityVariation = intensityVariation + math.abs(mood.intensity - previousIntensity)
                validCount = validCount + 1
            end
            previousIntensity = mood.intensity
        end
    end
    local stability = 1.0
    if validCount > 0 then
        local avgVariation = intensityVariation / validCount
        stability = math.max(0, 1 - avgVariation)
    end
    -- Cache result
    analyticsData.cachedStability = stability
    analyticsData.lastCacheUpdate = currentTime
    return stability
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Optimized Data Cleanup
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionAnalytics._cleanupOldData()
    local currentTime = love.timer.getTime()
    local cutoffTime = currentTime - 1800  -- 30 minutes
    -- Mark old entries as inactive instead of recreating arrays
    local activeCount = 0
    for i = 1, analyticsData.moodCount do
        local mood = analyticsData.sessionMoods[i]
        if mood.timestamp >= cutoffTime then
            activeCount = activeCount + 1
        else
            mood.active = false
        end
    end
    -- Compact active entries to beginning of array if fragmentation is high
    if activeCount < analyticsData.moodCount * 0.6 then -- More than 40% inactive
        local writeIndex = 1
        for i = 1, analyticsData.moodCount do
            local mood = analyticsData.sessionMoods[i]
            if mood.active then
                if writeIndex ~= i then
                    local target = analyticsData.sessionMoods[writeIndex]
                    target.timestamp = mood.timestamp
                    target.fromMood = mood.fromMood
                    target.toMood = mood.toMood
                    target.trigger = mood.trigger
                    target.intensity = mood.intensity
                    target.active = true
                    mood.active = false
                end
                writeIndex = writeIndex + 1
            end
        end
        analyticsData.moodCount = activeCount
        analyticsData.moodWriteIndex = activeCount + 1
    end
    -- Clean up old patterns
    for patternKey, pattern in pairs(analyticsData.emotionalPatterns) do
        if pattern.lastSeen < cutoffTime then
            analyticsData.emotionalPatterns[patternKey] = nil
        end
    end
    -- Invalidate cache after cleanup
    analyticsData.cachedDominantMood = nil
    analyticsData.cachedStability = nil
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Public API (unchanged for compatibility)
    ═══════════════════════════════════════════════════════════════════════════
--]]
function EmotionAnalytics.getEmotionalSummary()
    return {
        sessionDuration = love.timer.getTime() - analyticsData.sessionStartTime,
        totalMoodChanges = analyticsData.moodCount,
        dominantMood = EmotionAnalytics._getDominantMood(),
        emotionalStability = EmotionAnalytics._calculateEmotionalStability(),
        patterns = analyticsData.emotionalPatterns
    }
end
function EmotionAnalytics.getDebugInfo()
    return {
        sessionMoods = analyticsData.moodCount,
        patterns = Utils.tableSize and Utils.tableSize(analyticsData.emotionalPatterns) or 0,
        transitions = Utils.tableSize and Utils.tableSize(analyticsData.moodTransitions) or 0,
        triggers = Utils.tableSize and Utils.tableSize(analyticsData.triggerEffectiveness) or 0,
        bufferUtilization = analyticsData.moodCount / analyticsData.moodBufferSize,
        cacheHits = analyticsData.cachedDominantMood and "cached" or "calculated"
    }
end
-- Additional optimized functions (simplified versions of originals)
function EmotionAnalytics.recordTriggerEffectiveness(trigger, expectedIntensity, actualIntensity)
    local data = analyticsData.triggerEffectiveness[trigger]
    if not data then
        data = { samples = 0, totalExpected = 0, totalActual = 0, effectiveness = 0 }
        analyticsData.triggerEffectiveness[trigger] = data
    end
    data.samples = data.samples + 1
    data.totalExpected = data.totalExpected + expectedIntensity
    data.totalActual = data.totalActual + actualIntensity
    data.effectiveness = data.totalActual / data.totalExpected
end
return EmotionAnalytics