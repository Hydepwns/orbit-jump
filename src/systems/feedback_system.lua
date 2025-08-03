--[[
    Feedback Collection System - Player Experience Analytics
    This system collects anonymous gameplay analytics and player feedback
    to optimize game balance and user experience. All data collection
    follows privacy best practices with opt-in consent.
    Key Features:
    - Real-time gameplay metrics collection
    - Player sentiment tracking through micro-surveys
    - Performance monitoring and crash reporting
    - A/B testing infrastructure
    - Privacy-compliant data handling
--]]
local Utils = require("src.utils.utils")
local FeedbackSystem = {}
-- System state
FeedbackSystem.enabled = true
FeedbackSystem.consentGiven = false
FeedbackSystem.sessionId = nil
FeedbackSystem.playerCohort = "default"
-- Data collection buffers
FeedbackSystem.metricsBuffer = {}
FeedbackSystem.eventsBuffer = {}
FeedbackSystem.performanceBuffer = {}
FeedbackSystem.sentimentBuffer = {}
-- Configuration
FeedbackSystem.config = {
    -- Data retention
    buffer_size = 1000,
    flush_interval = 30.0, -- seconds
    session_timeout = 300.0, -- 5 minutes of inactivity
    -- Sampling rates
    performance_sample_rate = 0.1, -- 10% of frames
    event_sample_rate = 1.0, -- All events
    sentiment_trigger_rate = 0.05, -- 5% chance after significant events
    -- Privacy settings
    anonymize_data = true,
    local_storage_only = false, -- Set to true to prevent external data sending
    data_retention_days = 30
}
-- Metrics definitions
FeedbackSystem.METRICS = {
    -- Engagement Metrics
    SESSION_DURATION = "session_duration",
    STREAK_LENGTH = "streak_length",
    XP_PER_MINUTE = "xp_per_minute",
    RETENTION_INDICATOR = "retention_indicator",
    -- Balance Metrics
    GRACE_PERIOD_USAGE = "grace_period_usage",
    EVENT_SATISFACTION = "event_satisfaction",
    PROGRESSION_RATE = "progression_rate",
    DIFFICULTY_SPIKE = "difficulty_spike",
    -- Performance Metrics
    FRAME_RATE = "frame_rate",
    MEMORY_USAGE = "memory_usage",
    LOAD_TIME = "load_time",
    CRASH_INDICATOR = "crash_indicator",
    -- Feature Usage
    FEATURE_ADOPTION = "feature_adoption",
    ACCESSIBILITY_USAGE = "accessibility_usage",
    UI_INTERACTION = "ui_interaction"
}
-- Initialize feedback system
function FeedbackSystem.init()
    FeedbackSystem.sessionId = FeedbackSystem.generateSessionId()
    FeedbackSystem.consentGiven = FeedbackSystem.loadConsentStatus()
    FeedbackSystem.playerCohort = FeedbackSystem.determinePlayerCohort()
    -- Initialize buffers
    FeedbackSystem.metricsBuffer = {}
    FeedbackSystem.eventsBuffer = {}
    FeedbackSystem.performanceBuffer = {}
    FeedbackSystem.sentimentBuffer = {}
    -- Load A/B testing configuration
    FeedbackSystem.loadABTestConfig()
    Utils.Logger.info("Feedback System initialized - Session: %s, Cohort: %s",
                      FeedbackSystem.sessionId, FeedbackSystem.playerCohort)
    return true
end
-- Generate unique session identifier
function FeedbackSystem.generateSessionId()
    local timestamp = os.time()
    local random = math.random(1000, 9999)
    return string.format("session_%d_%d", timestamp, random)
end
-- Load user consent status
function FeedbackSystem.loadConsentStatus()
    if love.filesystem.getInfo("feedback_consent.dat") then
        local data = love.filesystem.read("feedback_consent.dat")
        return data == "true"
    end
    return false -- Default to no consent
end
-- Save user consent status
function FeedbackSystem.saveConsentStatus(consent)
    FeedbackSystem.consentGiven = consent
    love.filesystem.write("feedback_consent.dat", tostring(consent))
    Utils.Logger.info("Feedback consent updated: %s", tostring(consent))
end
-- Determine player cohort for A/B testing
function FeedbackSystem.determinePlayerCohort()
    -- Simple hash-based cohort assignment for consistency
    local playerId = FeedbackSystem.getPlayerId()
    local hash = 0
    for i = 1, #playerId do
        hash = hash + string.byte(playerId, i)
    end
    local cohortNum = hash % 4
    local cohorts = {"control", "variant_a", "variant_b", "variant_c"}
    return cohorts[cohortNum + 1]
end
-- Get anonymous player identifier
function FeedbackSystem.getPlayerId()
    if love.filesystem.getInfo("player_id.dat") then
        return love.filesystem.read("player_id.dat")
    else
        -- Generate anonymous ID
        local id = "player_" .. os.time() .. "_" .. math.random(10000, 99999)
        love.filesystem.write("player_id.dat", id)
        return id
    end
end
-- Record gameplay metric
function FeedbackSystem.recordMetric(metricType, value, context)
    if not FeedbackSystem.enabled or not FeedbackSystem.consentGiven then
        return
    end
    local metric = {
        type = metricType,
        value = value,
        context = context or {},
        timestamp = love.timer.getTime(),
        session_id = FeedbackSystem.sessionId,
        cohort = FeedbackSystem.playerCohort
    }
    table.insert(FeedbackSystem.metricsBuffer, metric)
    -- Maintain buffer size
    if #FeedbackSystem.metricsBuffer > FeedbackSystem.config.buffer_size then
        table.remove(FeedbackSystem.metricsBuffer, 1)
    end
end
-- Record gameplay event
function FeedbackSystem.recordEvent(eventType, eventData)
    if not FeedbackSystem.enabled or not FeedbackSystem.consentGiven then
        return
    end
    -- Sample events based on configuration
    if math.random() > FeedbackSystem.config.event_sample_rate then
        return
    end
    local event = {
        type = eventType,
        data = eventData or {},
        timestamp = love.timer.getTime(),
        session_id = FeedbackSystem.sessionId,
        cohort = FeedbackSystem.playerCohort
    }
    table.insert(FeedbackSystem.eventsBuffer, event)
    -- Maintain buffer size
    if #FeedbackSystem.eventsBuffer > FeedbackSystem.config.buffer_size then
        table.remove(FeedbackSystem.eventsBuffer, 1)
    end
    -- Trigger sentiment collection for significant events
    if FeedbackSystem.isSignificantEvent(eventType) then
        FeedbackSystem.maybeTriggerSentimentSurvey(eventType, eventData)
    end
end
-- Record performance data
function FeedbackSystem.recordPerformance(fps, memoryMB, frameTime)
    if not FeedbackSystem.enabled or not FeedbackSystem.consentGiven then
        return
    end
    -- Sample performance data
    if math.random() > FeedbackSystem.config.performance_sample_rate then
        return
    end
    local perfData = {
        fps = fps,
        memory_mb = memoryMB,
        frame_time_ms = frameTime * 1000,
        timestamp = love.timer.getTime(),
        session_id = FeedbackSystem.sessionId
    }
    table.insert(FeedbackSystem.performanceBuffer, perfData)
    -- Maintain buffer size
    if #FeedbackSystem.performanceBuffer > FeedbackSystem.config.buffer_size then
        table.remove(FeedbackSystem.performanceBuffer, 1)
    end
end
-- Check if event is significant enough to trigger sentiment collection
function FeedbackSystem.isSignificantEvent(eventType)
    local significantEvents = {
        "streak_broken",
        "level_up",
        "prestige_unlock",
        "achievement_earned",
        "frustration_quit",
        "mystery_box_opened",
        "first_perfect_landing"
    }
    for _, significantEvent in ipairs(significantEvents) do
        if eventType == significantEvent then
            return true
        end
    end
    return false
end
-- Maybe trigger a micro-survey for sentiment collection
function FeedbackSystem.maybeTriggerSentimentSurvey(eventType, eventData)
    if math.random() > FeedbackSystem.config.sentiment_trigger_rate then
        return
    end
    local survey = FeedbackSystem.createSentimentSurvey(eventType, eventData)
    if survey then
        table.insert(FeedbackSystem.sentimentBuffer, survey)
    end
end
-- Create contextual sentiment survey
function FeedbackSystem.createSentimentSurvey(eventType, eventData)
    local surveys = {
        streak_broken = {
            question = "How did losing your streak feel?",
            options = {"Motivating", "Frustrating", "Fair", "Unfair"},
            context = {streak_length = eventData.streak_length or 0}
        },
        level_up = {
            question = "How satisfying was reaching this level?",
            options = {"Very satisfying", "Somewhat satisfying", "Neutral", "Not satisfying"},
            context = {level = eventData.level or 0}
        },
        mystery_box_opened = {
            question = "How did you feel about the reward?",
            options = {"Excited", "Satisfied", "Disappointed", "Indifferent"},
            context = {reward_type = eventData.reward_type or "unknown"}
        }
    }
    local surveyTemplate = surveys[eventType]
    if not surveyTemplate then
        return nil
    end
    return {
        id = FeedbackSystem.generateSurveyId(),
        question = surveyTemplate.question,
        options = surveyTemplate.options,
        context = surveyTemplate.context,
        event_type = eventType,
        timestamp = love.timer.getTime(),
        session_id = FeedbackSystem.sessionId,
        answered = false,
        response = nil
    }
end
-- Generate unique survey ID
function FeedbackSystem.generateSurveyId()
    return "survey_" .. os.time() .. "_" .. math.random(100, 999)
end
-- Update system (called each frame)
function FeedbackSystem.update(dt)
    if not FeedbackSystem.enabled then
        return
    end
    -- Auto-flush buffers periodically
    FeedbackSystem.flushTimer = (FeedbackSystem.flushTimer or 0) + dt
    if FeedbackSystem.flushTimer >= FeedbackSystem.config.flush_interval then
        FeedbackSystem.flushBuffers()
        FeedbackSystem.flushTimer = 0
    end
    -- Record basic performance metrics
    if love.timer.getFPS then
        local fps = love.timer.getFPS()
        local memoryKB = collectgarbage("count")
        FeedbackSystem.recordPerformance(fps, memoryKB / 1024, dt)
    end
end
-- Flush all data buffers to storage
function FeedbackSystem.flushBuffers()
    if not FeedbackSystem.consentGiven then
        return
    end
    local flushData = {
        session_id = FeedbackSystem.sessionId,
        cohort = FeedbackSystem.playerCohort,
        timestamp = love.timer.getTime(),
        metrics = FeedbackSystem.metricsBuffer,
        events = FeedbackSystem.eventsBuffer,
        performance = FeedbackSystem.performanceBuffer,
        sentiment = FeedbackSystem.sentimentBuffer
    }
    -- Save to local storage
    FeedbackSystem.saveToLocalStorage(flushData)
    -- Send to external analytics (if enabled and consented)
    if not FeedbackSystem.config.local_storage_only then
        FeedbackSystem.sendToAnalytics(flushData)
    end
    -- Clear buffers after flush
    FeedbackSystem.metricsBuffer = {}
    FeedbackSystem.eventsBuffer = {}
    FeedbackSystem.performanceBuffer = {}
    -- Keep sentiment buffer for UI display
end
-- Save data to local storage
function FeedbackSystem.saveToLocalStorage(data)
    local filename = string.format("feedback_%s_%d.json",
                                   FeedbackSystem.sessionId,
                                   os.time())
    local success, err = pcall(function()
        local json = Utils.serialize(data)
        love.filesystem.write("feedback/" .. filename, json)
    end)
    if not success then
        Utils.Logger.warn("Failed to save feedback data: %s", tostring(err))
    end
end
-- Send data to external analytics service (placeholder)
function FeedbackSystem.sendToAnalytics(data)
    -- This would integrate with your analytics service
    -- For now, just log that we would send data
    Utils.Logger.info("Would send %d metrics, %d events, %d performance samples to analytics",
                      #data.metrics, #data.events, #data.performance)
end
-- Load A/B testing configuration
function FeedbackSystem.loadABTestConfig()
    -- This would load dynamic configuration for A/B tests
    -- For now, use default values
    FeedbackSystem.abConfig = {
        xp_scaling_modifier = 1.0,
        event_frequency_modifier = 1.0,
        grace_period_modifier = 1.0,
        particle_intensity_modifier = 1.0
    }
    -- Adjust based on cohort
    if FeedbackSystem.playerCohort == "variant_a" then
        FeedbackSystem.abConfig.event_frequency_modifier = 0.8 -- 20% less events
    elseif FeedbackSystem.playerCohort == "variant_b" then
        FeedbackSystem.abConfig.grace_period_modifier = 1.2 -- 20% longer grace
    elseif FeedbackSystem.playerCohort == "variant_c" then
        FeedbackSystem.abConfig.xp_scaling_modifier = 0.9 -- 10% less XP scaling
    end
end
-- Get A/B test configuration value
function FeedbackSystem.getABConfig(key)
    return FeedbackSystem.abConfig[key] or 1.0
end
-- Get pending sentiment surveys for UI display
function FeedbackSystem.getPendingSentimentSurveys()
    local pending = {}
    for _, survey in ipairs(FeedbackSystem.sentimentBuffer) do
        if not survey.answered then
            table.insert(pending, survey)
        end
    end
    return pending
end
-- Submit response to sentiment survey
function FeedbackSystem.submitSentimentResponse(surveyId, response)
    for _, survey in ipairs(FeedbackSystem.sentimentBuffer) do
        if survey.id == surveyId then
            survey.answered = true
            survey.response = response
            survey.response_timestamp = love.timer.getTime()
            Utils.Logger.info("Sentiment response submitted: %s -> %s", surveyId, response)
            return true
        end
    end
    return false
end
-- Cleanup old data
function FeedbackSystem.cleanup()
    -- Clean up old feedback files
    local files = love.filesystem.getDirectoryItems("feedback")
    local cutoff = os.time() - (FeedbackSystem.config.data_retention_days * 24 * 60 * 60)
    for _, filename in ipairs(files) do
        if filename:match("feedback_.*_(%d+)%.json") then
            local timestamp = tonumber(filename:match("feedback_.*_(%d+)%.json"))
            if timestamp and timestamp < cutoff then
                love.filesystem.remove("feedback/" .. filename)
            end
        end
    end
end
-- Helper functions for common events
function FeedbackSystem.onStreakBroken(streakLength)
    FeedbackSystem.recordEvent("streak_broken", {streak_length = streakLength})
    FeedbackSystem.recordMetric(FeedbackSystem.METRICS.STREAK_LENGTH, streakLength)
end
function FeedbackSystem.onLevelUp(newLevel)
    FeedbackSystem.recordEvent("level_up", {level = newLevel})
    FeedbackSystem.recordMetric(FeedbackSystem.METRICS.PROGRESSION_RATE, newLevel)
end
function FeedbackSystem.onPerfectLanding(streakLength)
    FeedbackSystem.recordEvent("perfect_landing", {streak_length = streakLength})
    if streakLength == 1 then
        FeedbackSystem.recordEvent("first_perfect_landing", {})
    end
end
function FeedbackSystem.onGracePeriodUsed(successful)
    FeedbackSystem.recordEvent("grace_period_used", {successful = successful})
    FeedbackSystem.recordMetric(FeedbackSystem.METRICS.GRACE_PERIOD_USAGE, successful and 1 or 0)
end
function FeedbackSystem.onMysteryBoxOpened(boxType, rewardType)
    FeedbackSystem.recordEvent("mystery_box_opened", {
        box_type = boxType,
        reward_type = rewardType
    })
end
function FeedbackSystem.onFrustrationQuit(reason, gameState)
    FeedbackSystem.recordEvent("frustration_quit", {
        reason = reason,
        level = gameState.level or 0,
        score = gameState.score or 0,
        streak = gameState.streak or 0
    })
end
return FeedbackSystem