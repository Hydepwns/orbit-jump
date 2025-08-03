-- Session Statistics Tracking System
-- Provides detailed analytics and performance tracking for player improvement
local Utils = require("src.utils.utils")
local SessionStatsSystem = {}
-- Current session data
SessionStatsSystem.currentSession = {
    startTime = 0,
    duration = 0,
    -- Landing performance
    totalLandings = 0,
    perfectLandings = 0,
    imperfectLandings = 0,
    perfectLandingAccuracy = 0,
    -- Streak performance
    bestStreak = 0,
    streakAttempts = 0,
    streaksLost = 0,
    gracePeriodSaves = 0,
    streakRecoverySuccessRate = 0,
    -- XP and progression
    xpGained = 0,
    xpSources = {},
    levelsGained = 0,
    xpPerMinute = 0,
    -- Ring collection
    ringsCollected = 0,
    comboCount = 0,
    bestCombo = 0,
    ringsPerMinute = 0,
    -- Events and bonuses
    mysteryBoxesOpened = 0,
    randomEventsTriggered = 0,
    bonusesActivated = {},
    -- Movement and gameplay
    jumpsPerformed = 0,
    dashesUsed = 0,
    totalDistance = 0,
    averageJumpDistance = 0,
    -- Improvement metrics
    improvementTrend = 0, -- Positive = improving, negative = declining
    consistencyScore = 0, -- 0-100, higher = more consistent performance
    focusScore = 0, -- Based on streak maintenance and accuracy
}
-- Historical data for trends
SessionStatsSystem.historicalData = {
    recentSessions = {}, -- Last 10 sessions
    dailyAverages = {}, -- Last 30 days
    weeklyTrends = {}, -- Last 12 weeks
    personalBests = {}
}
-- Performance categories for analysis
SessionStatsSystem.performanceCategories = {
    "perfect_landing_accuracy",
    "streak_recovery_rate",
    "xp_efficiency",
    "combo_mastery",
    "consistency",
    "focus_duration"
}
-- Initialize session stats system
function SessionStatsSystem.init()
    SessionStatsSystem.loadHistoricalData()
    SessionStatsSystem.startNewSession()
    Utils.Logger.info("Session Stats System initialized")
    return true
end
-- Start a new session
function SessionStatsSystem.startNewSession()
    SessionStatsSystem.currentSession = {
        startTime = love.timer.getTime(),
        duration = 0,
        totalLandings = 0,
        perfectLandings = 0,
        imperfectLandings = 0,
        perfectLandingAccuracy = 0,
        bestStreak = 0,
        streakAttempts = 0,
        streaksLost = 0,
        gracePeriodSaves = 0,
        streakRecoverySuccessRate = 0,
        xpGained = 0,
        xpSources = {},
        levelsGained = 0,
        xpPerMinute = 0,
        ringsCollected = 0,
        comboCount = 0,
        bestCombo = 0,
        ringsPerMinute = 0,
        mysteryBoxesOpened = 0,
        randomEventsTriggered = 0,
        bonusesActivated = {},
        jumpsPerformed = 0,
        dashesUsed = 0,
        totalDistance = 0,
        averageJumpDistance = 0,
        improvementTrend = 0,
        consistencyScore = 0,
        focusScore = 0
    }
    Utils.Logger.info("New session started")
end
-- Update session stats
function SessionStatsSystem.update(dt)
    SessionStatsSystem.currentSession.duration = SessionStatsSystem.currentSession.duration + dt
    -- Calculate real-time metrics
    SessionStatsSystem.calculateRealTimeMetrics()
end
-- Calculate real-time performance metrics
function SessionStatsSystem.calculateRealTimeMetrics()
    local session = SessionStatsSystem.currentSession
    local durationMinutes = session.duration / 60
    -- Perfect landing accuracy
    if session.totalLandings > 0 then
        session.perfectLandingAccuracy = (session.perfectLandings / session.totalLandings) * 100
    end
    -- Streak recovery success rate
    if session.streakAttempts > 0 then
        session.streakRecoverySuccessRate = (session.gracePeriodSaves / session.streakAttempts) * 100
    end
    -- Rate-based metrics (per minute)
    if durationMinutes > 0 then
        session.xpPerMinute = session.xpGained / durationMinutes
        session.ringsPerMinute = session.ringsCollected / durationMinutes
    end
    -- Average jump distance
    if session.jumpsPerformed > 0 then
        session.averageJumpDistance = session.totalDistance / session.jumpsPerformed
    end
    -- Focus score (based on consistency and streak maintenance)
    SessionStatsSystem.calculateFocusScore()
    -- Consistency score (based on performance variance)
    SessionStatsSystem.calculateConsistencyScore()
end
-- Calculate focus score based on sustained performance
function SessionStatsSystem.calculateFocusScore()
    local session = SessionStatsSystem.currentSession
    -- Base score from accuracy
    local accuracyScore = session.perfectLandingAccuracy or 0
    -- Bonus for maintaining streaks
    local streakBonus = math.min(session.bestStreak * 2, 40)
    -- Penalty for losing streaks frequently
    local streakPenalty = session.streaksLost * 5
    -- Bonus for recovery saves
    local recoveryBonus = session.gracePeriodSaves * 3
    session.focusScore = math.max(0, math.min(100, accuracyScore + streakBonus - streakPenalty + recoveryBonus))
end
-- Calculate consistency score based on performance variance
function SessionStatsSystem.calculateConsistencyScore()
    local session = SessionStatsSystem.currentSession
    -- Simple consistency metric based on streak vs losses ratio
    if session.streaksLost == 0 and session.bestStreak > 5 then
        session.consistencyScore = math.min(100, 80 + session.bestStreak)
    elseif session.streaksLost > 0 then
        local ratio = session.bestStreak / session.streaksLost
        session.consistencyScore = math.min(100, ratio * 20)
    else
        session.consistencyScore = 50 -- Neutral baseline
    end
end
-- Event tracking functions
function SessionStatsSystem.onPerfectLanding()
    local session = SessionStatsSystem.currentSession
    session.totalLandings = session.totalLandings + 1
    session.perfectLandings = session.perfectLandings + 1
end
function SessionStatsSystem.onImperfectLanding()
    local session = SessionStatsSystem.currentSession
    session.totalLandings = session.totalLandings + 1
    session.imperfectLandings = session.imperfectLandings + 1
end
function SessionStatsSystem.onStreakUpdate(currentStreak)
    local session = SessionStatsSystem.currentSession
    if currentStreak > session.bestStreak then
        session.bestStreak = currentStreak
    end
    -- Track streak attempts (new streak starting)
    if currentStreak == 1 then
        session.streakAttempts = session.streakAttempts + 1
    end
end
function SessionStatsSystem.onStreakLost(lostStreak)
    local session = SessionStatsSystem.currentSession
    session.streaksLost = session.streaksLost + 1
end
function SessionStatsSystem.onGracePeriodSave()
    local session = SessionStatsSystem.currentSession
    session.gracePeriodSaves = session.gracePeriodSaves + 1
end
function SessionStatsSystem.onXPGained(amount, source)
    local session = SessionStatsSystem.currentSession
    session.xpGained = session.xpGained + amount
    -- Track XP sources
    if not session.xpSources[source] then
        session.xpSources[source] = 0
    end
    session.xpSources[source] = session.xpSources[source] + amount
end
function SessionStatsSystem.onLevelUp()
    local session = SessionStatsSystem.currentSession
    session.levelsGained = session.levelsGained + 1
end
function SessionStatsSystem.onRingCollected(comboCount)
    local session = SessionStatsSystem.currentSession
    session.ringsCollected = session.ringsCollected + 1
    session.comboCount = comboCount or 0
    if session.comboCount > session.bestCombo then
        session.bestCombo = session.comboCount
    end
end
function SessionStatsSystem.onMysteryBoxOpened()
    local session = SessionStatsSystem.currentSession
    session.mysteryBoxesOpened = session.mysteryBoxesOpened + 1
end
function SessionStatsSystem.onRandomEventTriggered(eventType)
    local session = SessionStatsSystem.currentSession
    session.randomEventsTriggered = session.randomEventsTriggered + 1
end
function SessionStatsSystem.onBonusActivated(bonusType)
    local session = SessionStatsSystem.currentSession
    if not session.bonusesActivated[bonusType] then
        session.bonusesActivated[bonusType] = 0
    end
    session.bonusesActivated[bonusType] = session.bonusesActivated[bonusType] + 1
end
function SessionStatsSystem.onJump(distance)
    local session = SessionStatsSystem.currentSession
    session.jumpsPerformed = session.jumpsPerformed + 1
    session.totalDistance = session.totalDistance + (distance or 0)
end
function SessionStatsSystem.onDash()
    local session = SessionStatsSystem.currentSession
    session.dashesUsed = session.dashesUsed + 1
end
-- End current session and save to history
function SessionStatsSystem.endSession()
    local session = SessionStatsSystem.currentSession
    -- Final calculations
    SessionStatsSystem.calculateRealTimeMetrics()
    SessionStatsSystem.calculateImprovementTrend()
    -- Save to history
    SessionStatsSystem.saveSessionToHistory(session)
    -- Update personal bests
    SessionStatsSystem.updatePersonalBests(session)
    -- Save historical data
    SessionStatsSystem.saveHistoricalData()
    Utils.Logger.info("Session ended - Duration: %.1fm, XP: %d, Best Streak: %d",
                      session.duration / 60, session.xpGained, session.bestStreak)
end
-- Calculate improvement trend compared to recent sessions
function SessionStatsSystem.calculateImprovementTrend()
    local current = SessionStatsSystem.currentSession
    local recent = SessionStatsSystem.historicalData.recentSessions
    if #recent < 3 then
        current.improvementTrend = 0
        return
    end
    -- Compare current session to average of last 3 sessions
    local recentAverage = {
        perfectLandingAccuracy = 0,
        xpPerMinute = 0,
        bestStreak = 0
    }
    for i = math.max(1, #recent - 2), #recent do
        local session = recent[i]
        recentAverage.perfectLandingAccuracy = recentAverage.perfectLandingAccuracy + (session.perfectLandingAccuracy or 0)
        recentAverage.xpPerMinute = recentAverage.xpPerMinute + (session.xpPerMinute or 0)
        recentAverage.bestStreak = recentAverage.bestStreak + (session.bestStreak or 0)
    end
    local count = math.min(3, #recent)
    recentAverage.perfectLandingAccuracy = recentAverage.perfectLandingAccuracy / count
    recentAverage.xpPerMinute = recentAverage.xpPerMinute / count
    recentAverage.bestStreak = recentAverage.bestStreak / count
    -- Calculate improvement score
    local accuracyImprovement = (current.perfectLandingAccuracy - recentAverage.perfectLandingAccuracy) / 100
    local xpImprovement = (current.xpPerMinute - recentAverage.xpPerMinute) / math.max(1, recentAverage.xpPerMinute)
    local streakImprovement = (current.bestStreak - recentAverage.bestStreak) / math.max(1, recentAverage.bestStreak)
    current.improvementTrend = (accuracyImprovement + xpImprovement + streakImprovement) / 3 * 100
end
-- Save session to historical data
function SessionStatsSystem.saveSessionToHistory(session)
    local recent = SessionStatsSystem.historicalData.recentSessions
    -- Add session copy
    local sessionCopy = {}
    for k, v in pairs(session) do
        sessionCopy[k] = v
    end
    sessionCopy.timestamp = os.time()
    table.insert(recent, sessionCopy)
    -- Limit to last 10 sessions
    while #recent > 10 do
        table.remove(recent, 1)
    end
end
-- Update personal bests
function SessionStatsSystem.updatePersonalBests(session)
    local bests = SessionStatsSystem.historicalData.personalBests
    -- Initialize if empty
    if not bests.bestStreak then
        bests.bestStreak = 0
        bests.highestAccuracy = 0
        bests.fastestXP = 0
        bests.longestSession = 0
        bests.mostRings = 0
    end
    -- Update bests
    if session.bestStreak > bests.bestStreak then
        bests.bestStreak = session.bestStreak
    end
    if session.perfectLandingAccuracy > bests.highestAccuracy then
        bests.highestAccuracy = session.perfectLandingAccuracy
    end
    if session.xpPerMinute > bests.fastestXP then
        bests.fastestXP = session.xpPerMinute
    end
    if session.duration > bests.longestSession then
        bests.longestSession = session.duration
    end
    if session.ringsCollected > bests.mostRings then
        bests.mostRings = session.ringsCollected
    end
end
-- Get session summary for display
function SessionStatsSystem.getSessionSummary()
    local session = SessionStatsSystem.currentSession
    local durationMinutes = math.floor(session.duration / 60)
    local durationSeconds = math.floor(session.duration % 60)
    return {
        duration = string.format("%dm %ds", durationMinutes, durationSeconds),
        perfectLandingAccuracy = string.format("%.1f%%", session.perfectLandingAccuracy or 0),
        bestStreak = session.bestStreak,
        xpGained = session.xpGained,
        xpPerMinute = string.format("%.1f", session.xpPerMinute or 0),
        ringsCollected = session.ringsCollected,
        focusScore = math.floor(session.focusScore),
        consistencyScore = math.floor(session.consistencyScore),
        improvementTrend = session.improvementTrend
    }
end
-- Get performance comparison with recent sessions
function SessionStatsSystem.getPerformanceComparison()
    local current = SessionStatsSystem.currentSession
    local recent = SessionStatsSystem.historicalData.recentSessions
    if #recent == 0 then
        return nil
    end
    -- Calculate averages of recent sessions
    local totals = {
        perfectLandingAccuracy = 0,
        xpPerMinute = 0,
        bestStreak = 0,
        focusScore = 0
    }
    for _, session in ipairs(recent) do
        totals.perfectLandingAccuracy = totals.perfectLandingAccuracy + (session.perfectLandingAccuracy or 0)
        totals.xpPerMinute = totals.xpPerMinute + (session.xpPerMinute or 0)
        totals.bestStreak = totals.bestStreak + (session.bestStreak or 0)
        totals.focusScore = totals.focusScore + (session.focusScore or 0)
    end
    local count = #recent
    local averages = {
        perfectLandingAccuracy = totals.perfectLandingAccuracy / count,
        xpPerMinute = totals.xpPerMinute / count,
        bestStreak = totals.bestStreak / count,
        focusScore = totals.focusScore / count
    }
    -- Calculate differences
    return {
        accuracyDiff = current.perfectLandingAccuracy - averages.perfectLandingAccuracy,
        xpDiff = current.xpPerMinute - averages.xpPerMinute,
        streakDiff = current.bestStreak - averages.bestStreak,
        focusDiff = current.focusScore - averages.focusScore
    }
end
-- Save/Load historical data
function SessionStatsSystem.saveHistoricalData()
    local saveData = {
        recentSessions = SessionStatsSystem.historicalData.recentSessions,
        personalBests = SessionStatsSystem.historicalData.personalBests
    }
    local serialized = Utils.serialize(saveData)
    love.filesystem.write("session_stats.dat", serialized)
end
function SessionStatsSystem.loadHistoricalData()
    if love.filesystem.getInfo("session_stats.dat") then
        local data = love.filesystem.read("session_stats.dat")
        local loadedData = Utils.deserialize(data)
        if loadedData then
            SessionStatsSystem.historicalData.recentSessions = loadedData.recentSessions or {}
            SessionStatsSystem.historicalData.personalBests = loadedData.personalBests or {}
        end
    end
end
-- Get current session data
function SessionStatsSystem.getCurrentSession()
    return SessionStatsSystem.currentSession
end
-- Get historical data
function SessionStatsSystem.getHistoricalData()
    return SessionStatsSystem.historicalData
end
return SessionStatsSystem