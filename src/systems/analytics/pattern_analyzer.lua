--[[
    Pattern Analyzer: Pattern Recognition and Analysis
    This module analyzes player patterns including skill progression,
    emotional states, and session patterns to understand player behavior deeply.
--]]
local Utils = require("src.utils.utils")
local PatternAnalyzer = {}
-- Skill progression tracking
PatternAnalyzer.skillProgression = {
    initialSkill = 0,            -- Baseline skill when we started tracking
    currentSkill = 0,            -- Current skill level (0-1)
    skillVelocity = 0,           -- Rate of improvement
    skillPlateau = false,        -- Have they hit a learning plateau?
    -- Mastery Indicators
    consistency = 0,             -- How reliable are their movements?
    adaptability = 0,            -- How well do they handle new situations?
    efficiency = 0,              -- How optimal are their solutions?
    creativity = 0,              -- How often do they find novel approaches?
    -- Learning Patterns
    practiceTime = 0,            -- Time spent on similar tasks
    challengeSeeking = 0,        -- How often they attempt difficult things
    failureRecovery = 0,         -- How well they bounce back from mistakes
    improvementRate = {}         -- Historical skill progression
}
-- Emotional pattern tracking
PatternAnalyzer.emotionalProfile = {
    frustrationTolerance = 0,    -- How much difficulty they enjoy
    flowStateDuration = 0,       -- Time spent in smooth, effortless play
    pauseFrequency = 0,          -- How often they take breaks
    retryPersistence = 0,        -- How many times they attempt difficult jumps
    -- Emotional States (inferred from behavior)
    currentMood = "neutral",     -- "focused", "frustrated", "exploring", "mastery"
    sessionEnergy = 1.0,         -- 0-1: tired to energetic
    confidenceLevel = 0.5,       -- 0-1: hesitant to bold
    -- Satisfaction Indicators
    achievementReactions = {},   -- How they respond to success
    failurePatterns = {},        -- How they handle setbacks
    engagementLevel = 0,         -- How absorbed they are in the game
    sessionSatisfaction = 0      -- Overall satisfaction with current session
}
-- Session pattern tracking
PatternAnalyzer.sessionData = {
    totalSessions = 0,
    averageSessionLength = 0,
    preferredPlayTimes = {},     -- When they like to play
    sessionStartMood = {},       -- How they typically begin
    sessionEndMood = {},         -- How they typically finish
    -- Engagement Patterns
    warmupTime = 0,              -- Time to get into flow
    peakPerformanceTime = 0,     -- When they play best in a session
    fadeTime = 0,                -- When performance starts declining
    -- Break Patterns
    breakFrequency = 0,          -- How often they pause
    breakDuration = 0,           -- How long breaks typically last
    returnBehavior = "",         -- How they re-engage after breaks
    -- Long-term Patterns
    playSchedule = {},           -- Weekly/daily patterns
    seasonalChanges = {},        -- How behavior changes over time
    progressSatisfaction = 0     -- How they feel about long-term progress
}
-- Analysis state
PatternAnalyzer.lastActionTime = 0
PatternAnalyzer.sessionStartTime = 0
PatternAnalyzer.currentAnalysisWindow = {}
-- Initialize pattern analysis
function PatternAnalyzer.init()
    PatternAnalyzer.sessionStartTime = love and love.timer and love.timer.getTime() or os.time()
    PatternAnalyzer.lastActionTime = PatternAnalyzer.sessionStartTime
    PatternAnalyzer.initializeSkillProfile()
    PatternAnalyzer.initializeEmotionalProfile()
    PatternAnalyzer.initializeSessionProfile()
end
-- Initialize skill profile
function PatternAnalyzer.initializeSkillProfile()
    if not PatternAnalyzer.skillProgression then
        PatternAnalyzer.skillProgression = {
            initialSkill = 0, currentSkill = 0, skillVelocity = 0, skillPlateau = false,
            consistency = 0, adaptability = 0, efficiency = 0, creativity = 0,
            practiceTime = 0, challengeSeeking = 0, failureRecovery = 0,
            improvementRate = {}
        }
    end
end
-- Initialize emotional profile
function PatternAnalyzer.initializeEmotionalProfile()
    if not PatternAnalyzer.emotionalProfile then
        PatternAnalyzer.emotionalProfile = {
            frustrationTolerance = 0.5, flowStateDuration = 0, pauseFrequency = 0,
            retryPersistence = 0.5, currentMood = "neutral", sessionEnergy = 1.0,
            confidenceLevel = 0.5, achievementReactions = {}, failurePatterns = {},
            engagementLevel = 0.5, sessionSatisfaction = 0.5
        }
    end
end
-- Initialize session profile
function PatternAnalyzer.initializeSessionProfile()
    if not PatternAnalyzer.sessionData then
        PatternAnalyzer.sessionData = {
            totalSessions = 0, averageSessionLength = 0, preferredPlayTimes = {},
            sessionStartMood = {}, sessionEndMood = {}, warmupTime = 0,
            peakPerformanceTime = 0, fadeTime = 0, breakFrequency = 0,
            breakDuration = 0, returnBehavior = "", playSchedule = {},
            seasonalChanges = {}, progressSatisfaction = 0.5
        }
    end
end
-- Begin new session
function PatternAnalyzer.beginSession()
    local sessionData = PatternAnalyzer.sessionData
    sessionData.totalSessions = sessionData.totalSessions + 1
    -- Analyze how they start sessions
    local startMood = PatternAnalyzer.inferCurrentMood()
    table.insert(sessionData.sessionStartMood, startMood)
    PatternAnalyzer.emotionalProfile.currentMood = startMood
    PatternAnalyzer.emotionalProfile.sessionEnergy = 1.0
    Utils.Logger.info("📊 Session %d begun - mood: %s",
        sessionData.totalSessions, startMood)
end
-- Infer current mood from behavior patterns
function PatternAnalyzer.inferCurrentMood()
    local emotional = PatternAnalyzer.emotionalProfile
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    local timeSinceLastAction = currentTime - PatternAnalyzer.lastActionTime
    -- Long pause might indicate frustration or contemplation
    if timeSinceLastAction > 30 then
        if emotional.retryPersistence < 0.3 then
            return "frustrated"
        else
            return "contemplative"
        end
    end
    -- High confidence and energy = flow state
    if emotional.confidenceLevel > 0.7 and emotional.sessionEnergy > 0.6 then
        return "flow"
    end
    -- Low energy might mean tired or bored
    if emotional.sessionEnergy < 0.3 then
        return "tired"
    end
    -- High engagement = focused
    if emotional.engagementLevel > 0.7 then
        return "focused"
    end
    return "neutral"
end
-- Track emotional event
function PatternAnalyzer.onEmotionalEvent(eventType, intensity, context)
    local emotional = PatternAnalyzer.emotionalProfile
    if eventType == "success" then
        -- Success increases confidence
        emotional.confidenceLevel = math.min(1, emotional.confidenceLevel + intensity * 0.1)
        emotional.sessionSatisfaction = emotional.sessionSatisfaction * 0.9 + intensity * 0.1
        -- Track achievement reaction
        table.insert(emotional.achievementReactions, {
            intensity = intensity,
            context = context,
            mood = emotional.currentMood
        })
    elseif eventType == "failure" then
        -- Failure might decrease confidence, but also shows persistence
        emotional.confidenceLevel = math.max(0, emotional.confidenceLevel - intensity * 0.05)
        emotional.retryPersistence = emotional.retryPersistence * 0.9 + 0.1
        -- Track failure pattern
        table.insert(emotional.failurePatterns, {
            intensity = intensity,
            context = context,
            recovery = emotional.confidenceLevel
        })
    elseif eventType == "pause" then
        emotional.pauseFrequency = emotional.pauseFrequency + 1
    elseif eventType == "flow" then
        emotional.flowStateDuration = emotional.flowStateDuration + intensity
        emotional.engagementLevel = math.min(1, emotional.engagementLevel + 0.1)
    end
    -- Update current mood based on recent events
    emotional.currentMood = PatternAnalyzer.inferCurrentMood()
end
-- Update skill progression
function PatternAnalyzer.updateSkillProgression(performanceMetrics)
    local skill = PatternAnalyzer.skillProgression
    -- Calculate new skill level based on performance
    local newSkill = 0
    if performanceMetrics.accuracy then
        newSkill = newSkill + performanceMetrics.accuracy * 0.3
    end
    if performanceMetrics.efficiency then
        newSkill = newSkill + performanceMetrics.efficiency * 0.3
    end
    if performanceMetrics.creativity then
        newSkill = newSkill + performanceMetrics.creativity * 0.2
        skill.creativity = skill.creativity * 0.9 + performanceMetrics.creativity * 0.1
    end
    if performanceMetrics.consistency then
        newSkill = newSkill + performanceMetrics.consistency * 0.2
        skill.consistency = skill.consistency * 0.9 + performanceMetrics.consistency * 0.1
    end
    -- Track skill velocity (rate of change)
    local oldSkill = skill.currentSkill
    skill.currentSkill = skill.currentSkill * 0.95 + newSkill * 0.05
    skill.skillVelocity = skill.currentSkill - oldSkill
    -- Detect plateau
    if math.abs(skill.skillVelocity) < 0.001 and skill.currentSkill > 0.5 then
        skill.skillPlateau = true
    else
        skill.skillPlateau = false
    end
    -- Update improvement rate history
    table.insert(skill.improvementRate, {
        time = love and love.timer and love.timer.getTime() or os.time(),
        skill = skill.currentSkill,
        velocity = skill.skillVelocity
    })
    -- Keep only recent history
    if #skill.improvementRate > 100 then
        table.remove(skill.improvementRate, 1)
    end
end
-- Update session patterns
function PatternAnalyzer.updateSession(dt)
    local currentTime = love and love.timer and love.timer.getTime() or os.time()
    local sessionData = PatternAnalyzer.sessionData
    local emotional = PatternAnalyzer.emotionalProfile
    -- Update session energy (decreases over time)
    local sessionDuration = currentTime - PatternAnalyzer.sessionStartTime
    emotional.sessionEnergy = math.max(0, 1 - sessionDuration / 3600) -- Drops to 0 after 1 hour
    -- Detect peak performance time
    if emotional.currentMood == "flow" and sessionData.peakPerformanceTime == 0 then
        sessionData.peakPerformanceTime = sessionDuration
    end
    -- Detect fade time (when performance starts declining)
    if emotional.sessionEnergy < 0.5 and sessionData.fadeTime == 0 then
        sessionData.fadeTime = sessionDuration
    end
    PatternAnalyzer.lastActionTime = currentTime
end
-- Get pattern analysis
function PatternAnalyzer.getAnalysis()
    return {
        skill = {
            level = PatternAnalyzer.skillProgression.currentSkill,
            velocity = PatternAnalyzer.skillProgression.skillVelocity,
            plateau = PatternAnalyzer.skillProgression.skillPlateau,
            consistency = PatternAnalyzer.skillProgression.consistency
        },
        emotional = {
            mood = PatternAnalyzer.emotionalProfile.currentMood,
            confidence = PatternAnalyzer.emotionalProfile.confidenceLevel,
            energy = PatternAnalyzer.emotionalProfile.sessionEnergy,
            satisfaction = PatternAnalyzer.emotionalProfile.sessionSatisfaction
        },
        session = {
            number = PatternAnalyzer.sessionData.totalSessions,
            duration = love and love.timer and love.timer.getTime() - PatternAnalyzer.sessionStartTime or 0,
            peakTime = PatternAnalyzer.sessionData.peakPerformanceTime,
            fadeTime = PatternAnalyzer.sessionData.fadeTime
        }
    }
end
-- Save pattern data
function PatternAnalyzer.saveState()
    return {
        skillProgression = PatternAnalyzer.skillProgression,
        emotionalProfile = PatternAnalyzer.emotionalProfile,
        sessionData = PatternAnalyzer.sessionData
    }
end
-- Restore pattern data
function PatternAnalyzer.restoreState(state)
    if state then
        if state.skillProgression then
            PatternAnalyzer.skillProgression = state.skillProgression
        end
        if state.emotionalProfile then
            PatternAnalyzer.emotionalProfile = state.emotionalProfile
        end
        if state.sessionData then
            PatternAnalyzer.sessionData = state.sessionData
        end
    end
end
return PatternAnalyzer