--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player Analytics: The Observer of Human Behavior
    ═══════════════════════════════════════════════════════════════════════════
    This is the main interface for the player analytics system. It orchestrates
    the various subsystems to provide comprehensive player behavior analysis.
    The actual implementation is now modularized into:
    - behavior_tracker.lua: Player behavior tracking
    - pattern_analyzer.lua: Pattern recognition and analysis
    - insight_generator.lua: Insight generation and reporting
--]]
local Utils = require("src.utils.utils")
local BehaviorTracker = require("src.systems.analytics.behavior_tracker")
local PatternAnalyzer = require("src.systems.analytics.pattern_analyzer")
local InsightGenerator = require("src.systems.analytics.insight_generator")
local PlayerAnalytics = {}
-- Analytics state
PlayerAnalytics.isTracking = false
PlayerAnalytics.sessionStartTime = 0
PlayerAnalytics.lastActionTime = 0
-- Initialize all subsystems
function PlayerAnalytics.init()
    PlayerAnalytics.sessionStartTime = love and love.timer and love.timer.getTime() or os.time()
    PlayerAnalytics.lastActionTime = PlayerAnalytics.sessionStartTime
    PlayerAnalytics.isTracking = true
    -- Initialize subsystems
    BehaviorTracker.init()
    PatternAnalyzer.init()
    InsightGenerator.init()
    -- Set data references for testing
    PlayerAnalytics.data = InsightGenerator.data
    PlayerAnalytics.session = InsightGenerator.session
    -- Restore from save data
    PlayerAnalytics.restoreFromSave()
    -- Begin session analysis
    PatternAnalyzer.beginSession()
    Utils.Logger.info("🔍 Player Analytics initialized - Observing with compassion")
    return true
end
-- Track player jump
function PlayerAnalytics.onPlayerJump(jumpPower, jumpAngle, startX, startY, targetX, targetY, planningTime)
    if not PlayerAnalytics.isTracking then return end
    -- Track behavior
    BehaviorTracker.onPlayerJump(jumpPower, jumpAngle, startX, startY, targetX, targetY, planningTime)
    -- Track event
    InsightGenerator.trackEvent("jump", {
        power = jumpPower,
        angle = jumpAngle,
        distance = Utils.distance(startX, startY, targetX, targetY),
        planningTime = planningTime
    })
    -- Update skill progression based on jump performance
    local accuracy = math.max(0, 1 - math.abs(jumpPower - 50) / 50) -- Optimal at 50 power
    PatternAnalyzer.updateSkillProgression({
        accuracy = accuracy,
        consistency = 1 - BehaviorTracker.movementProfile.jumpPowerVariance / 30,
        efficiency = planningTime and (planningTime > 0.5 and planningTime < 5) and 1 or 0.5
    })
    PlayerAnalytics.lastActionTime = love.timer.getTime()
end
-- Track planet discovery
function PlayerAnalytics.onPlanetDiscovered(planet, discoveryMethod, attemptsToReach)
    if not PlayerAnalytics.isTracking then return end
    -- Track behavior
    BehaviorTracker.onPlanetDiscovered(planet, discoveryMethod, attemptsToReach)
    -- Track event
    InsightGenerator.trackEvent("planet_discovered", {
        planet = planet.name or planet.id,
        method = discoveryMethod,
        attempts = attemptsToReach
    })
    -- Emotional event - discovery is positive
    PatternAnalyzer.onEmotionalEvent("success", 0.8, "planet_discovery")
    PlayerAnalytics.lastActionTime = love.timer.getTime()
end
-- Track emotional event
function PlayerAnalytics.onEmotionalEvent(eventType, intensity, context)
    if not PlayerAnalytics.isTracking then return end
    PatternAnalyzer.onEmotionalEvent(eventType, intensity, context)
    InsightGenerator.trackEvent("emotional_event", {
        type = eventType,
        intensity = intensity,
        context = context
    })
end
-- Get player profile with insights
function PlayerAnalytics.getPlayerProfile()
    local behaviorSummary = BehaviorTracker.getSummary()
    local patternAnalysis = PatternAnalyzer.getAnalysis()
    return InsightGenerator.getPlayerProfile(behaviorSummary, patternAnalysis)
end
-- Get system recommendations
function PlayerAnalytics.getSystemRecommendations()
    local behaviorSummary = BehaviorTracker.getSummary()
    local patternAnalysis = PatternAnalyzer.getAnalysis()
    return InsightGenerator.getSystemRecommendations(behaviorSummary, patternAnalysis)
end
-- Update analytics (called each frame)
function PlayerAnalytics.update(dt)
    if not PlayerAnalytics.isTracking then return end
    -- Update pattern analysis
    PatternAnalyzer.updateSession(dt)
    -- Update session duration
    InsightGenerator.session.duration = love.timer.getTime() - InsightGenerator.session.startTime
end
-- Track generic event
function PlayerAnalytics.trackEvent(eventName, params)
    if not PlayerAnalytics.isTracking then return end
    InsightGenerator.trackEvent(eventName, params)
    PlayerAnalytics.lastActionTime = love.timer.getTime()
end
-- Track gameplay metrics
function PlayerAnalytics.trackGameplay(params)
    if not PlayerAnalytics.isTracking then return end
    if params.action == "jump" then
        InsightGenerator.data.gameplay.jumps = InsightGenerator.data.gameplay.jumps + 1
    elseif params.action == "landing" then
        InsightGenerator.data.gameplay.landings = InsightGenerator.data.gameplay.landings + 1
    elseif params.action == "dash" then
        InsightGenerator.data.gameplay.dashes = InsightGenerator.data.gameplay.dashes + 1
    end
    table.insert(InsightGenerator.data.gameplay.events, {
        action = params.action,
        params = params,
        timestamp = love.timer.getTime()
    })
end
-- Track progression
function PlayerAnalytics.trackProgression(params)
    if not PlayerAnalytics.isTracking then return end
    InsightGenerator.trackProgression(params)
    -- Update skill if it's a skill-related progression
    if params.type == "skill_unlock" or params.type == "achievement" then
        PatternAnalyzer.onEmotionalEvent("success", 1.0, params.type)
    end
end
-- Track preference
function PlayerAnalytics.trackPreference(preferenceName, value)
    if not PlayerAnalytics.isTracking then return end
    InsightGenerator.trackEvent("preference", {
        name = preferenceName,
        value = value
    })
end
-- Track performance metrics
function PlayerAnalytics.trackPerformance(metrics)
    if not PlayerAnalytics.isTracking then return end
    PatternAnalyzer.updateSkillProgression(metrics)
    InsightGenerator.trackEvent("performance", metrics)
end
-- Track error (for debugging)
function PlayerAnalytics.trackError(error)
    Utils.Logger.error("Analytics error tracked: %s", error)
    InsightGenerator.trackEvent("error", {
        message = error,
        timestamp = love.timer.getTime()
    })
end
-- Track achievement
function PlayerAnalytics.trackAchievement(achievement)
    if not PlayerAnalytics.isTracking then return end
    InsightGenerator.trackProgression({
        type = "achievement",
        value = achievement.id or achievement.name
    })
    PatternAnalyzer.onEmotionalEvent("success", 1.0, "achievement")
end
-- Get session report
function PlayerAnalytics.getSessionReport()
    return InsightGenerator.getSessionReport()
end
-- Get summary
function PlayerAnalytics.getSummary()
    local behaviorSummary = BehaviorTracker.getSummary()
    local patternAnalysis = PatternAnalyzer.getAnalysis()
    local sessionReport = InsightGenerator.getSessionReport()
    return {
        behavior = behaviorSummary,
        patterns = patternAnalysis,
        session = sessionReport.session,
        insights = sessionReport.insights,
        totals = {
            jumps = sessionReport.gameplay.jumps,
            events = sessionReport.eventCount,
            progression = sessionReport.progressionCount
        }
    }
end
-- Save analytics data
function PlayerAnalytics.saveAnalyticsData()
    PlayerAnalytics.saveToPersistence()
end
-- Save to persistence
function PlayerAnalytics.saveToPersistence()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("playerAnalytics", PlayerAnalytics.getSaveData())
        Utils.Logger.debug("📊 Player analytics saved")
    end
end
-- Get save data
function PlayerAnalytics.getSaveData()
    return {
        behavior = BehaviorTracker.saveState(),
        patterns = PatternAnalyzer.saveState(),
        insights = InsightGenerator.saveState(),
        lastSaveTime = love.timer.getTime()
    }
end
-- Restore from save
function PlayerAnalytics.restoreFromSave()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local saveData = SaveSystem.getData()
        if saveData and saveData.playerAnalytics then
            PlayerAnalytics.loadData(saveData.playerAnalytics)
            Utils.Logger.info("📊 Player analytics restored from save")
        end
    end
end
-- Load saved data
function PlayerAnalytics.loadData(saveData)
    if saveData.behavior then
        BehaviorTracker.restoreState(saveData.behavior)
    end
    if saveData.patterns then
        PatternAnalyzer.restoreState(saveData.patterns)
    end
    if saveData.insights then
        InsightGenerator.restoreState(saveData.insights)
    end
end
-- Backwards compatibility - expose memory for other systems
PlayerAnalytics.memory = {
    movementProfile = BehaviorTracker.movementProfile,
    explorationProfile = BehaviorTracker.explorationProfile,
    skillProgression = PatternAnalyzer.skillProgression,
    emotionalProfile = PatternAnalyzer.emotionalProfile,
    sessionData = PatternAnalyzer.sessionData
}
-- Expose data for testing (will be set after initialization)
PlayerAnalytics.data = nil
PlayerAnalytics.session = nil
-- Legacy function mappings
PlayerAnalytics.initializeMemoryStructures = function()
    BehaviorTracker.init()
    PatternAnalyzer.init()
end
PlayerAnalytics.beginSession = function()
    PatternAnalyzer.beginSession()
end
PlayerAnalytics.classifyMovementStyle = function()
    return BehaviorTracker.classifyMovementStyle()
end
PlayerAnalytics.inferCurrentMood = function()
    return PatternAnalyzer.inferCurrentMood()
end
PlayerAnalytics.getStatus = function()
    return {
        isTracking = PlayerAnalytics.isTracking,
        sessionTime = love.timer.getTime() - PlayerAnalytics.sessionStartTime
    }
end
-- Update session data
function PlayerAnalytics.updateSession()
    if not PlayerAnalytics.isTracking then return end
    local currentTime = love.timer.getTime()
    local sessionTime = currentTime - PlayerAnalytics.sessionStartTime
    -- Update session data in pattern analyzer
    PatternAnalyzer.updateSession(sessionTime)
    -- Update behavior tracking
    BehaviorTracker.updateSession(sessionTime)
    -- Update insights
    InsightGenerator.updateSession(sessionTime)
    PlayerAnalytics.lastActionTime = currentTime
end
return PlayerAnalytics