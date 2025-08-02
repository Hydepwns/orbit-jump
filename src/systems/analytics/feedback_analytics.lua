--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Analytics System - Core Analytics for Feedback Integration Plan
    ═══════════════════════════════════════════════════════════════════════════
    
    This system implements the comprehensive analytics framework outlined in the
    Feedback Integration Plan, collecting all the key metrics needed for data-driven
    optimization and player experience enhancement.
--]]

local Utils = require("src.utils.utils")
local Config = require("src.utils.config")

local FeedbackAnalytics = {}

-- Analytics state
FeedbackAnalytics.isActive = false
FeedbackAnalytics.sessionStartTime = 0
FeedbackAnalytics.sessionId = nil

-- Core metrics data structure from the plan
FeedbackAnalytics.metrics = {
    -- Engagement Metrics
    engagement = {
        session_duration = 0,
        sessions_per_day = 0,
        retention_1_day = false,
        retention_7_day = false,
        retention_30_day = false,
        last_session_timestamp = 0,
        total_sessions = 0,
        daily_playtime = 0
    },
    
    -- Addiction Mechanics Performance
    addiction = {
        average_streak_length = 0,
        max_streak_achieved = 0,
        streak_recovery_rate = 0,
        grace_period_usage = 0,
        streak_breaks = 0,
        streak_shields_used = 0,
        total_streaks = 0,
        streak_anxiety_score = 0
    },
    
    -- Progression Satisfaction
    progression = {
        xp_per_minute = 0,
        levels_per_session = 0,
        reward_unlock_frequency = 0,
        prestige_adoption_rate = 0,
        upgrade_purchase_rate = 0,
        achievement_completion_rate = 0,
        progression_satisfaction_score = 0,
        quit_during_progression = 0
    },
    
    -- Event System Balance
    events = {
        mystery_box_spawn_satisfaction = 0,
        random_event_overwhelm_score = 0,
        event_anticipation_vs_annoyance = 0,
        mystery_boxes_collected = 0,
        random_events_experienced = 0,
        event_interruption_annoyance = 0,
        event_skip_rate = 0
    },
    
    -- Difficulty Curve
    difficulty = {
        quit_points_by_level = {},
        frustration_indicators = {},
        flow_state_duration = 0,
        difficulty_spikes = {},
        player_skill_progression = 0,
        adaptive_difficulty_triggers = 0,
        death_points = {}
    },
    
    -- Feature Usage
    features = {
        most_used_bonuses = {},
        least_used_features = {},
        accessibility_feature_usage = {},
        ui_element_interactions = {},
        tutorial_completion_segments = {},
        settings_changes = {}
    },
    
    -- Performance Metrics
    performance = {
        avg_fps = 60,
        min_fps = 60,
        max_fps = 60,
        frame_drops = 0,
        load_times = {},
        memory_usage = 0,
        crash_count = 0,
        error_count = 0
    },
    
    -- Player Sentiment (micro-surveys and behavioral analysis)
    sentiment = {
        overall_satisfaction = 0,
        progression_satisfaction = 0,
        difficulty_satisfaction = 0,
        event_satisfaction = 0,
        ui_satisfaction = 0,
        survey_responses = {},
        behavioral_mood_indicators = {}
    }
}

-- Session tracking
FeedbackAnalytics.session = {
    id = nil,
    startTime = 0,
    duration = 0,
    jumps = 0,
    landings = 0,
    streaks = 0,
    achievements = 0,
    levels_gained = 0,
    xp_gained = 0,
    events_triggered = 0,
    quit_reason = nil,
    flow_state_periods = {},
    frustration_events = {}
}

-- A/B Testing tracking
FeedbackAnalytics.abTests = {
    active_tests = {},
    test_results = {},
    cohort_id = nil,
    test_assignments = {}
}

-- Initialize the feedback analytics system
function FeedbackAnalytics.init()
    FeedbackAnalytics.sessionStartTime = love.timer.getTime()
    FeedbackAnalytics.sessionId = FeedbackAnalytics.generateSessionId()
    FeedbackAnalytics.isActive = true
    
    -- Initialize session
    FeedbackAnalytics.session.id = FeedbackAnalytics.sessionId
    FeedbackAnalytics.session.startTime = FeedbackAnalytics.sessionStartTime
    
    -- Load persistent data
    FeedbackAnalytics.loadPersistentData()
    
    -- Initialize A/B test assignments
    FeedbackAnalytics.initializeABTests()
    
    -- Track session start
    FeedbackAnalytics.trackEvent("session_start", {
        session_id = FeedbackAnalytics.sessionId,
        timestamp = FeedbackAnalytics.sessionStartTime
    })
    
    Utils.Logger.info("📊 Feedback Analytics System initialized - Session ID: %s", FeedbackAnalytics.sessionId)
    return true
end

-- Generate unique session ID
function FeedbackAnalytics.generateSessionId()
    local timestamp = math.floor(love.timer.getTime() * 1000)
    local random = math.random(10000, 99999)
    return string.format("session_%d_%d", timestamp, random)
end

-- Initialize A/B testing assignments
function FeedbackAnalytics.initializeABTests()
    -- Assign player to cohorts based on persistent player ID
    local playerId = FeedbackAnalytics.getPlayerId()
    local cohortSeed = tonumber(string.sub(playerId, -4)) or 0
    
    FeedbackAnalytics.abTests.cohort_id = cohortSeed % 10 -- 10 cohorts (0-9)
    
    -- Assign A/B test variants based on cohort
    FeedbackAnalytics.abTests.test_assignments = {
        xp_scaling = FeedbackAnalytics.abTests.cohort_id < 3 and "variant_a" or 
                    (FeedbackAnalytics.abTests.cohort_id < 6 and "variant_b" or "control"),
        event_frequency = FeedbackAnalytics.abTests.cohort_id % 3 == 0 and "high" or 
                         (FeedbackAnalytics.abTests.cohort_id % 3 == 1 and "normal" or "low"),
        grace_period = FeedbackAnalytics.abTests.cohort_id < 5 and 3.0 or 3.5,
        visual_intensity = FeedbackAnalytics.abTests.cohort_id % 2 == 0 and "full" or "reduced"
    }
    
    Utils.Logger.debug("A/B Test assignments: Cohort %d, XP: %s, Events: %s", 
                      FeedbackAnalytics.abTests.cohort_id,
                      FeedbackAnalytics.abTests.test_assignments.xp_scaling,
                      FeedbackAnalytics.abTests.test_assignments.event_frequency)
end

-- Get persistent player ID
function FeedbackAnalytics.getPlayerId()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local saveData = SaveSystem.getData()
        if saveData and saveData.playerId then
            return saveData.playerId
        end
    end
    
    -- Generate new player ID
    local playerId = string.format("player_%d_%d", 
                                  math.floor(love.timer.getTime() * 1000),
                                  math.random(100000, 999999))
    
    -- Save it
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("playerId", playerId)
    end
    
    return playerId
end

-- Track gameplay event
function FeedbackAnalytics.trackEvent(eventName, data)
    if not FeedbackAnalytics.isActive then return end
    
    local timestamp = love.timer.getTime()
    local event = {
        name = eventName,
        timestamp = timestamp,
        session_id = FeedbackAnalytics.sessionId,
        data = data or {}
    }
    
    -- Update relevant metrics based on event type
    FeedbackAnalytics.updateMetricsFromEvent(eventName, data)
    
    -- Store event for analysis
    FeedbackAnalytics.storeEvent(event)
    
    Utils.Logger.debug("📊 Event tracked: %s", eventName)
end

-- Update metrics based on tracked events
function FeedbackAnalytics.updateMetricsFromEvent(eventName, data)
    local currentTime = love.timer.getTime()
    
    if eventName == "player_jump" then
        FeedbackAnalytics.session.jumps = FeedbackAnalytics.session.jumps + 1
        
    elseif eventName == "streak_started" then
        FeedbackAnalytics.session.streaks = FeedbackAnalytics.session.streaks + 1
        FeedbackAnalytics.metrics.addiction.total_streaks = FeedbackAnalytics.metrics.addiction.total_streaks + 1
        
    elseif eventName == "streak_broken" then
        FeedbackAnalytics.metrics.addiction.streak_breaks = FeedbackAnalytics.metrics.addiction.streak_breaks + 1
        if data and data.length then
            local avgLength = FeedbackAnalytics.metrics.addiction.average_streak_length
            local totalStreaks = FeedbackAnalytics.metrics.addiction.total_streaks
            FeedbackAnalytics.metrics.addiction.average_streak_length = 
                (avgLength * (totalStreaks - 1) + data.length) / totalStreaks
            
            if data.length > FeedbackAnalytics.metrics.addiction.max_streak_achieved then
                FeedbackAnalytics.metrics.addiction.max_streak_achieved = data.length
            end
        end
        
    elseif eventName == "grace_period_used" then
        FeedbackAnalytics.metrics.addiction.grace_period_usage = 
            FeedbackAnalytics.metrics.addiction.grace_period_usage + 1
            
    elseif eventName == "level_up" then
        FeedbackAnalytics.session.levels_gained = FeedbackAnalytics.session.levels_gained + 1
        if data and data.xp then
            FeedbackAnalytics.session.xp_gained = FeedbackAnalytics.session.xp_gained + data.xp
        end
        
    elseif eventName == "mystery_box_collected" then
        FeedbackAnalytics.metrics.events.mystery_boxes_collected = 
            FeedbackAnalytics.metrics.events.mystery_boxes_collected + 1
            
    elseif eventName == "random_event_triggered" then
        FeedbackAnalytics.metrics.events.random_events_experienced = 
            FeedbackAnalytics.metrics.events.random_events_experienced + 1
        FeedbackAnalytics.session.events_triggered = FeedbackAnalytics.session.events_triggered + 1
        
    elseif eventName == "frustration_detected" then
        table.insert(FeedbackAnalytics.session.frustration_events, {
            timestamp = currentTime,
            context = data.context or "unknown",
            intensity = data.intensity or 1.0
        })
        table.insert(FeedbackAnalytics.metrics.difficulty.frustration_indicators, {
            timestamp = currentTime,
            level = data.level,
            context = data.context,
            intensity = data.intensity
        })
        
    elseif eventName == "flow_state_detected" then
        table.insert(FeedbackAnalytics.session.flow_state_periods, {
            start_time = data.start_time or currentTime,
            end_time = data.end_time or currentTime,
            duration = data.duration or 0
        })
        
    elseif eventName == "quit_point" then
        local level = data.level or 0
        if not FeedbackAnalytics.metrics.difficulty.quit_points_by_level[level] then
            FeedbackAnalytics.metrics.difficulty.quit_points_by_level[level] = 0
        end
        FeedbackAnalytics.metrics.difficulty.quit_points_by_level[level] = 
            FeedbackAnalytics.metrics.difficulty.quit_points_by_level[level] + 1
            
    elseif eventName == "performance_issue" then
        if data.type == "frame_drop" then
            FeedbackAnalytics.metrics.performance.frame_drops = 
                FeedbackAnalytics.metrics.performance.frame_drops + 1
        elseif data.type == "crash" then
            FeedbackAnalytics.metrics.performance.crash_count = 
                FeedbackAnalytics.metrics.performance.crash_count + 1
        end
    end
end

-- Store event for later analysis
function FeedbackAnalytics.storeEvent(event)
    -- In a real implementation, this would send to analytics service
    -- For now, we'll store locally and batch upload
    
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        local existingEvents = SaveSystem.getData("analytics_events") or {}
        table.insert(existingEvents, event)
        
        -- Keep only last 1000 events to prevent memory issues
        if #existingEvents > 1000 then
            table.remove(existingEvents, 1)
        end
        
        SaveSystem.setData("analytics_events", existingEvents)
    end
end

-- Update performance metrics
function FeedbackAnalytics.updatePerformanceMetrics(fps, memory)
    if not FeedbackAnalytics.isActive then return end
    
    local perf = FeedbackAnalytics.metrics.performance
    
    -- Update FPS tracking
    if fps then
        perf.avg_fps = (perf.avg_fps * 0.9) + (fps * 0.1) -- Exponential moving average
        perf.min_fps = math.min(perf.min_fps, fps)
        perf.max_fps = math.max(perf.max_fps, fps)
        
        -- Detect frame drops (below 45 FPS)
        if fps < 45 then
            FeedbackAnalytics.trackEvent("performance_issue", {
                type = "frame_drop",
                fps = fps,
                timestamp = love.timer.getTime()
            })
        end
    end
    
    -- Update memory usage
    if memory then
        perf.memory_usage = memory
    end
end

-- Track player sentiment through micro-surveys
function FeedbackAnalytics.recordSentiment(surveyType, rating, context)
    if not FeedbackAnalytics.isActive then return end
    
    local sentiment = {
        type = surveyType,
        rating = rating,
        context = context or {},
        timestamp = love.timer.getTime(),
        session_id = FeedbackAnalytics.sessionId
    }
    
    table.insert(FeedbackAnalytics.metrics.sentiment.survey_responses, sentiment)
    
    -- Update overall satisfaction scores
    if surveyType == "overall" then
        FeedbackAnalytics.metrics.sentiment.overall_satisfaction = rating
    elseif surveyType == "progression" then
        FeedbackAnalytics.metrics.sentiment.progression_satisfaction = rating
    elseif surveyType == "difficulty" then
        FeedbackAnalytics.metrics.sentiment.difficulty_satisfaction = rating
    elseif surveyType == "events" then
        FeedbackAnalytics.metrics.sentiment.event_satisfaction = rating
    end
    
    FeedbackAnalytics.trackEvent("sentiment_survey", sentiment)
    Utils.Logger.info("📊 Sentiment recorded: %s rated %d/5", surveyType, rating)
end

-- Get A/B test variant for a feature
function FeedbackAnalytics.getABTestVariant(testName)
    return FeedbackAnalytics.abTests.test_assignments[testName] or "control"
end

-- Track A/B test result
function FeedbackAnalytics.trackABTestResult(testName, variant, metric, value)
    if not FeedbackAnalytics.abTests.test_results[testName] then
        FeedbackAnalytics.abTests.test_results[testName] = {}
    end
    
    if not FeedbackAnalytics.abTests.test_results[testName][variant] then
        FeedbackAnalytics.abTests.test_results[testName][variant] = {}
    end
    
    table.insert(FeedbackAnalytics.abTests.test_results[testName][variant], {
        metric = metric,
        value = value,
        timestamp = love.timer.getTime(),
        session_id = FeedbackAnalytics.sessionId
    })
    
    FeedbackAnalytics.trackEvent("ab_test_result", {
        test = testName,
        variant = variant,
        metric = metric,
        value = value
    })
end

-- Update session duration and calculate derived metrics
function FeedbackAnalytics.update(dt)
    if not FeedbackAnalytics.isActive then return end
    
    local currentTime = love.timer.getTime()
    FeedbackAnalytics.session.duration = currentTime - FeedbackAnalytics.sessionStartTime
    FeedbackAnalytics.metrics.engagement.session_duration = FeedbackAnalytics.session.duration
    
    -- Calculate XP per minute
    if FeedbackAnalytics.session.duration > 0 then
        FeedbackAnalytics.metrics.progression.xp_per_minute = 
            (FeedbackAnalytics.session.xp_gained / FeedbackAnalytics.session.duration) * 60
    end
    
    -- Calculate levels per session
    FeedbackAnalytics.metrics.progression.levels_per_session = FeedbackAnalytics.session.levels_gained
    
    -- Update flow state duration
    local totalFlowTime = 0
    for _, flowPeriod in ipairs(FeedbackAnalytics.session.flow_state_periods) do
        totalFlowTime = totalFlowTime + (flowPeriod.duration or 0)
    end
    FeedbackAnalytics.metrics.difficulty.flow_state_duration = totalFlowTime
end

-- Get comprehensive analytics report
function FeedbackAnalytics.getAnalyticsReport()
    return {
        session = FeedbackAnalytics.session,
        metrics = FeedbackAnalytics.metrics,
        ab_tests = FeedbackAnalytics.abTests,
        timestamp = love.timer.getTime(),
        cohort_id = FeedbackAnalytics.abTests.cohort_id
    }
end

-- Get key metrics for dashboard
function FeedbackAnalytics.getKeyMetrics()
    return {
        engagement = {
            session_duration = FeedbackAnalytics.session.duration,
            actions_per_minute = FeedbackAnalytics.session.jumps / math.max(FeedbackAnalytics.session.duration / 60, 1)
        },
        addiction = {
            streak_success_rate = FeedbackAnalytics.metrics.addiction.total_streaks > 0 and
                                 (FeedbackAnalytics.metrics.addiction.total_streaks - FeedbackAnalytics.metrics.addiction.streak_breaks) / 
                                 FeedbackAnalytics.metrics.addiction.total_streaks or 0,
            average_streak = FeedbackAnalytics.metrics.addiction.average_streak_length
        },
        progression = {
            xp_rate = FeedbackAnalytics.metrics.progression.xp_per_minute,
            level_rate = FeedbackAnalytics.metrics.progression.levels_per_session
        },
        satisfaction = {
            overall = FeedbackAnalytics.metrics.sentiment.overall_satisfaction,
            progression = FeedbackAnalytics.metrics.sentiment.progression_satisfaction
        }
    }
end

-- Save analytics data
function FeedbackAnalytics.save()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("feedbackAnalytics", {
            metrics = FeedbackAnalytics.metrics,
            session = FeedbackAnalytics.session,
            ab_tests = FeedbackAnalytics.abTests,
            last_save_time = love.timer.getTime()
        })
        Utils.Logger.debug("📊 Feedback analytics data saved")
    end
end

-- Load persistent analytics data
function FeedbackAnalytics.loadPersistentData()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local data = SaveSystem.getData("feedbackAnalytics")
        if data and data.metrics then
            -- Merge persistent data with current session
            for category, values in pairs(data.metrics) do
                if FeedbackAnalytics.metrics[category] then
                    for key, value in pairs(values) do
                        if type(value) == "number" then
                            FeedbackAnalytics.metrics[category][key] = value
                        elseif type(value) == "table" then
                            FeedbackAnalytics.metrics[category][key] = value
                        end
                    end
                end
            end
        end
    end
end

-- End session and calculate final metrics
function FeedbackAnalytics.endSession(quitReason)
    if not FeedbackAnalytics.isActive then return end
    
    FeedbackAnalytics.session.quit_reason = quitReason or "normal_exit"
    
    -- Calculate final session metrics
    local sessionDuration = love.timer.getTime() - FeedbackAnalytics.sessionStartTime
    FeedbackAnalytics.metrics.engagement.total_sessions = FeedbackAnalytics.metrics.engagement.total_sessions + 1
    FeedbackAnalytics.metrics.engagement.daily_playtime = FeedbackAnalytics.metrics.engagement.daily_playtime + sessionDuration
    
    -- Track session end event
    FeedbackAnalytics.trackEvent("session_end", {
        duration = sessionDuration,
        quit_reason = quitReason,
        jumps = FeedbackAnalytics.session.jumps,
        levels_gained = FeedbackAnalytics.session.levels_gained,
        streaks = FeedbackAnalytics.session.streaks
    })
    
    -- Save final data
    FeedbackAnalytics.save()
    
    Utils.Logger.info("📊 Session ended - Duration: %.1fs, Jumps: %d, Levels: %d", 
                     sessionDuration, FeedbackAnalytics.session.jumps, FeedbackAnalytics.session.levels_gained)
    
    FeedbackAnalytics.isActive = false
end

return FeedbackAnalytics