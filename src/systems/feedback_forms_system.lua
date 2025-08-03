--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Forms System - Micro-surveys and Player Sentiment Collection
    ═══════════════════════════════════════════════════════════════════════════
    This system implements micro-surveys and feedback collection as outlined in
    the Feedback Integration Plan. It provides unobtrusive feedback collection
    at key moments to gather player sentiment and satisfaction data.
--]]
local Utils = require("src.utils.utils")
local FeedbackForms = {}
-- System state
FeedbackForms.isActive = false
FeedbackForms.currentSurvey = nil
FeedbackForms.pendingSurveys = {}
FeedbackForms.lastSurveyTime = 0
FeedbackForms.surveyCountdown = 0
-- Survey timing and triggering settings
FeedbackForms.settings = {
    min_time_between_surveys = 300, -- 5 minutes minimum between surveys
    max_surveys_per_session = 3,    -- Maximum surveys per session
    survey_timeout = 20,            -- Auto-dismiss after 20 seconds
    surveys_shown_this_session = 0,
    -- Trigger thresholds
    streak_milestone_threshold = 10, -- Show after streaks of 10+
    level_up_survey_chance = 0.2,   -- 20% chance on level up
    frustration_trigger_threshold = 3, -- Show after 3 frustration events
    achievement_survey_chance = 0.3, -- 30% chance on achievement
    session_time_triggers = {300, 900, 1800}, -- 5min, 15min, 30min session surveys
}
-- Survey definitions from the plan
FeedbackForms.surveyTypes = {
    -- Micro-surveys (1 question, quick response)
    quick_satisfaction = {
        type = "micro",
        title = "Quick Check",
        question = "How are you feeling about the game right now?",
        options = {
            {text = "😍 Loving it!", value = 5},
            {text = "😊 Good", value = 4},
            {text = "😐 Okay", value = 3},
            {text = "😕 Meh", value = 2},
            {text = "😤 Frustrated", value = 1}
        },
        trigger_contexts = {"streak_milestone", "random_check"}
    },
    difficulty_check = {
        type = "micro",
        title = "Difficulty Check",
        question = "How's the difficulty feeling?",
        options = {
            {text = "Too Easy", value = 1},
            {text = "Just Right", value = 3},
            {text = "Too Hard", value = 5}
        },
        trigger_contexts = {"frustration_detected", "death_streak"}
    },
    progression_satisfaction = {
        type = "micro",
        title = "Progress Check",
        question = "How satisfied are you with your progress?",
        options = {
            {text = "Very Satisfied", value = 5},
            {text = "Satisfied", value = 4},
            {text = "Neutral", value = 3},
            {text = "Unsatisfied", value = 2},
            {text = "Very Unsatisfied", value = 1}
        },
        trigger_contexts = {"level_up", "upgrade_purchase", "session_milestone"}
    },
    event_experience = {
        type = "micro",
        title = "Events",
        question = "How do you feel about mystery boxes and events?",
        options = {
            {text = "Love them!", value = 5},
            {text = "Good addition", value = 4},
            {text = "They're okay", value = 3},
            {text = "A bit much", value = 2},
            {text = "Too overwhelming", value = 1}
        },
        trigger_contexts = {"mystery_box_collected", "event_overwhelm"}
    },
    -- Post-session survey (more comprehensive)
    session_summary = {
        type = "session",
        title = "Session Feedback",
        questions = {
            {
                id = "overall_satisfaction",
                question = "Overall, how was this play session?",
                type = "rating",
                scale = 5
            },
            {
                id = "progression_feeling",
                question = "Did you feel like you made good progress?",
                type = "rating",
                scale = 5
            },
            {
                id = "difficulty_balance",
                question = "Was the difficulty well-balanced?",
                type = "rating",
                scale = 5
            },
            {
                id = "most_enjoyed",
                question = "What did you enjoy most this session?",
                type = "multiple_choice",
                options = {"Achieving streaks", "Discovering new areas", "Collecting rewards", "Improving skills", "The progression system"}
            },
            {
                id = "biggest_frustration",
                question = "What was your biggest frustration (if any)?",
                type = "multiple_choice",
                options = {"Difficulty spikes", "Lost streaks", "Too many events", "Slow progression", "Technical issues", "None"}
            }
        },
        trigger_contexts = {"session_end"}
    },
    -- Exit survey (when player quits/uninstalls - placeholder for now)
    exit_survey = {
        type = "exit",
        title = "Before You Go...",
        questions = {
            {
                id = "quit_reason",
                question = "What's the main reason you're stopping?",
                type = "multiple_choice",
                options = {"Just done for now", "Too difficult", "Got boring", "Technical issues", "Not enough time", "Other"}
            },
            {
                id = "return_likelihood",
                question = "How likely are you to play again?",
                type = "rating",
                scale = 5
            }
        },
        trigger_contexts = {"early_quit", "rage_quit"}
    },
    -- Achievement celebration with feedback
    achievement_celebration = {
        type = "micro",
        title = "Achievement!",
        question = "How did this achievement feel?",
        options = {
            {text = "Amazing! 🎉", value = 5},
            {text = "Good! 😊", value = 4},
            {text = "Okay 👍", value = 3},
            {text = "Meh 😐", value = 2},
            {text = "Didn't care 😑", value = 1}
        },
        trigger_contexts = {"achievement_unlocked"}
    }
}
-- Survey response storage
FeedbackForms.responses = {}
-- Initialize feedback forms system
function FeedbackForms.init()
    FeedbackForms.isActive = true
    FeedbackForms.lastSurveyTime = love.timer.getTime()
    FeedbackForms.responses = {}
    FeedbackForms.settings.surveys_shown_this_session = 0
    -- Load previous responses
    FeedbackForms.loadResponses()
    Utils.Logger.info("📝 Feedback Forms System initialized")
    return true
end
-- Trigger a survey based on context
function FeedbackForms.triggerSurvey(context, data)
    if not FeedbackForms.isActive then return false end
    if FeedbackForms.currentSurvey then return false end -- Survey already active
    -- Check if we've hit survey limits
    if FeedbackForms.settings.surveys_shown_this_session >= FeedbackForms.settings.max_surveys_per_session then
        return false
    end
    -- Check minimum time between surveys
    local currentTime = love.timer.getTime()
    if currentTime - FeedbackForms.lastSurveyTime < FeedbackForms.settings.min_time_between_surveys then
        return false
    end
    -- Find appropriate survey for context
    local surveyKey = FeedbackForms.selectSurveyForContext(context, data)
    if not surveyKey then return false end
    local survey = FeedbackForms.surveyTypes[surveyKey]
    if not survey then return false end
    -- Check context-specific triggering logic
    if not FeedbackForms.shouldTriggerSurvey(context, survey, data) then
        return false
    end
    -- Trigger the survey
    FeedbackForms.showSurvey(surveyKey, context, data)
    return true
end
-- Select appropriate survey for given context
function FeedbackForms.selectSurveyForContext(context, data)
    -- Context-specific survey selection
    if context == "streak_milestone" then
        if data and data.streak_length and data.streak_length >= FeedbackForms.settings.streak_milestone_threshold then
            return "quick_satisfaction"
        end
    elseif context == "level_up" then
        if math.random() < FeedbackForms.settings.level_up_survey_chance then
            return "progression_satisfaction"
        end
    elseif context == "frustration_detected" then
        return "difficulty_check"
    elseif context == "achievement_unlocked" then
        if math.random() < FeedbackForms.settings.achievement_survey_chance then
            return "achievement_celebration"
        end
    elseif context == "mystery_box_collected" or context == "event_overwhelm" then
        return "event_experience"
    elseif context == "session_end" then
        -- Only show session survey if session was long enough
        if data and data.session_duration and data.session_duration > 300 then -- 5+ minutes
            return "session_summary"
        end
    elseif context == "session_time_check" then
        return "quick_satisfaction"
    elseif context == "early_quit" or context == "rage_quit" then
        return "exit_survey"
    end
    return nil
end
-- Check if survey should be triggered based on additional logic
function FeedbackForms.shouldTriggerSurvey(context, survey, data)
    -- Random chance reduction for frequent contexts
    if context == "level_up" or context == "achievement_unlocked" then
        -- Already handled in selectSurveyForContext
        return true
    end
    -- Frustration context needs multiple events
    if context == "frustration_detected" then
        local frustrationCount = data and data.frustration_count or 1
        return frustrationCount >= FeedbackForms.settings.frustration_trigger_threshold
    end
    -- Session time checks
    if context == "session_time_check" then
        local sessionTime = data and data.session_time or 0
        for _, triggerTime in ipairs(FeedbackForms.settings.session_time_triggers) do
            if math.abs(sessionTime - triggerTime) < 30 then -- Within 30 seconds of trigger time
                return true
            end
        end
        return false
    end
    return true
end
-- Show a survey to the player
function FeedbackForms.showSurvey(surveyKey, context, data)
    local survey = FeedbackForms.surveyTypes[surveyKey]
    if not survey then return end
    FeedbackForms.currentSurvey = {
        key = surveyKey,
        survey = survey,
        context = context,
        data = data,
        startTime = love.timer.getTime(),
        responses = {}
    }
    FeedbackForms.surveyCountdown = FeedbackForms.settings.survey_timeout
    FeedbackForms.settings.surveys_shown_this_session = FeedbackForms.settings.surveys_shown_this_session + 1
    -- Track survey shown event
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("survey_shown", {
            survey_type = surveyKey,
            context = context,
            session_survey_count = FeedbackForms.settings.surveys_shown_this_session
        })
    end
    Utils.Logger.info("📝 Survey shown: %s (context: %s)", surveyKey, context)
end
-- Submit survey response
function FeedbackForms.submitResponse(questionId, response)
    if not FeedbackForms.currentSurvey then return false end
    -- Store response
    if questionId then
        FeedbackForms.currentSurvey.responses[questionId] = response
    else
        -- For micro-surveys with single response
        FeedbackForms.currentSurvey.responses.rating = response
    end
    -- For micro-surveys, auto-complete after first response
    if FeedbackForms.currentSurvey.survey.type == "micro" then
        FeedbackForms.completeSurvey()
    end
    return true
end
-- Complete current survey
function FeedbackForms.completeSurvey()
    if not FeedbackForms.currentSurvey then return end
    local survey = FeedbackForms.currentSurvey
    local completionTime = love.timer.getTime()
    local duration = completionTime - survey.startTime
    -- Store response data
    local responseData = {
        survey_key = survey.key,
        survey_type = survey.survey.type,
        context = survey.context,
        responses = survey.responses,
        duration = duration,
        timestamp = completionTime,
        session_id = FeedbackAnalytics and FeedbackAnalytics.sessionId or "unknown"
    }
    table.insert(FeedbackForms.responses, responseData)
    -- Send to analytics system
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics then
        -- Record sentiment if it's a satisfaction survey
        if survey.key == "quick_satisfaction" or survey.key == "progression_satisfaction" then
            local rating = survey.responses.rating or survey.responses.overall_satisfaction or 3
            FeedbackAnalytics.recordSentiment(
                survey.key == "quick_satisfaction" and "overall" or "progression",
                rating,
                {context = survey.context, duration = duration}
            )
        elseif survey.key == "difficulty_check" then
            FeedbackAnalytics.recordSentiment("difficulty", survey.responses.rating or 3,
                                            {context = survey.context})
        elseif survey.key == "event_experience" then
            FeedbackAnalytics.recordSentiment("events", survey.responses.rating or 3,
                                            {context = survey.context})
        end
        -- Track survey completion
        FeedbackAnalytics.trackEvent("survey_completed", {
            survey_type = survey.key,
            context = survey.context,
            duration = duration,
            response_count = FeedbackForms.countResponses(survey.responses)
        })
    end
    -- Save responses
    FeedbackForms.saveResponses()
    -- Clean up
    FeedbackForms.lastSurveyTime = completionTime
    FeedbackForms.currentSurvey = nil
    Utils.Logger.info("📝 Survey completed: %s (duration: %.1fs)", survey.key, duration)
end
-- Dismiss current survey without completion
function FeedbackForms.dismissSurvey(reason)
    if not FeedbackForms.currentSurvey then return end
    local survey = FeedbackForms.currentSurvey
    local dismissTime = love.timer.getTime()
    local duration = dismissTime - survey.startTime
    -- Track survey dismissal
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("survey_dismissed", {
            survey_type = survey.key,
            context = survey.context,
            reason = reason or "unknown",
            duration = duration
        })
    end
    FeedbackForms.lastSurveyTime = dismissTime
    FeedbackForms.currentSurvey = nil
    Utils.Logger.info("📝 Survey dismissed: %s (reason: %s)", survey.key, reason or "unknown")
end
-- Update system (handle timeouts, etc.)
function FeedbackForms.update(dt)
    if not FeedbackForms.isActive then return end
    -- Handle survey timeout
    if FeedbackForms.currentSurvey then
        FeedbackForms.surveyCountdown = FeedbackForms.surveyCountdown - dt
        if FeedbackForms.surveyCountdown <= 0 then
            FeedbackForms.dismissSurvey("timeout")
        end
    end
    -- Check for session time-based surveys
    FeedbackForms.checkSessionTimeTriggers()
end
-- Check for session time-based survey triggers
function FeedbackForms.checkSessionTimeTriggers()
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if not FeedbackAnalytics or not FeedbackAnalytics.session then return end
    local sessionTime = FeedbackAnalytics.session.duration
    for _, triggerTime in ipairs(FeedbackForms.settings.session_time_triggers) do
        if math.abs(sessionTime - triggerTime) < 1 then -- Within 1 second
            FeedbackForms.triggerSurvey("session_time_check", {session_time = sessionTime})
            break
        end
    end
end
-- Count responses in a response set
function FeedbackForms.countResponses(responses)
    local count = 0
    for _ in pairs(responses) do
        count = count + 1
    end
    return count
end
-- Get current survey for UI rendering
function FeedbackForms.getCurrentSurvey()
    return FeedbackForms.currentSurvey
end
-- Get survey display data for UI
function FeedbackForms.getSurveyDisplayData()
    if not FeedbackForms.currentSurvey then return nil end
    local survey = FeedbackForms.currentSurvey.survey
    local timeLeft = FeedbackForms.surveyCountdown
    return {
        title = survey.title,
        type = survey.type,
        question = survey.question,
        questions = survey.questions,
        options = survey.options,
        timeLeft = timeLeft,
        context = FeedbackForms.currentSurvey.context
    }
end
-- Get response statistics
function FeedbackForms.getResponseStatistics()
    local stats = {
        total_surveys_shown = 0,
        total_surveys_completed = 0,
        completion_rate = 0,
        avg_response_time = 0,
        surveys_by_type = {},
        sentiment_scores = {
            overall = {},
            progression = {},
            difficulty = {},
            events = {}
        }
    }
    local totalResponseTime = 0
    for _, response in ipairs(FeedbackForms.responses) do
        stats.total_surveys_completed = stats.total_surveys_completed + 1
        totalResponseTime = totalResponseTime + (response.duration or 0)
        -- Count by type
        local surveyType = response.survey_type or "unknown"
        stats.surveys_by_type[surveyType] = (stats.surveys_by_type[surveyType] or 0) + 1
        -- Collect sentiment scores
        if response.responses.rating then
            if response.survey_key == "quick_satisfaction" then
                table.insert(stats.sentiment_scores.overall, response.responses.rating)
            elseif response.survey_key == "progression_satisfaction" then
                table.insert(stats.sentiment_scores.progression, response.responses.rating)
            elseif response.survey_key == "difficulty_check" then
                table.insert(stats.sentiment_scores.difficulty, response.responses.rating)
            elseif response.survey_key == "event_experience" then
                table.insert(stats.sentiment_scores.events, response.responses.rating)
            end
        end
    end
    -- Calculate averages
    if stats.total_surveys_completed > 0 then
        stats.avg_response_time = totalResponseTime / stats.total_surveys_completed
    end
    stats.total_surveys_shown = FeedbackForms.settings.surveys_shown_this_session
    if stats.total_surveys_shown > 0 then
        stats.completion_rate = stats.total_surveys_completed / stats.total_surveys_shown
    end
    return stats
end
-- Save responses to persistent storage
function FeedbackForms.saveResponses()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("feedbackResponses", {
            responses = FeedbackForms.responses,
            settings = FeedbackForms.settings,
            last_save = love.timer.getTime()
        })
    end
end
-- Load responses from persistent storage
function FeedbackForms.loadResponses()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local data = SaveSystem.getData("feedbackResponses")
        if data and data.responses then
            FeedbackForms.responses = data.responses
            -- Restore some settings but reset session counters
            if data.settings then
                FeedbackForms.settings.min_time_between_surveys = data.settings.min_time_between_surveys or FeedbackForms.settings.min_time_between_surveys
                FeedbackForms.settings.max_surveys_per_session = data.settings.max_surveys_per_session or FeedbackForms.settings.max_surveys_per_session
            end
            Utils.Logger.info("📝 Loaded %d previous survey responses", #FeedbackForms.responses)
        end
    end
end
-- Export all feedback data for analysis
function FeedbackForms.exportFeedbackData()
    return {
        responses = FeedbackForms.responses,
        statistics = FeedbackForms.getResponseStatistics(),
        survey_definitions = FeedbackForms.surveyTypes,
        settings = FeedbackForms.settings,
        export_timestamp = love.timer.getTime()
    }
end
-- Clean up system
function FeedbackForms.cleanup()
    if FeedbackForms.currentSurvey then
        FeedbackForms.dismissSurvey("cleanup")
    end
    FeedbackForms.saveResponses()
    FeedbackForms.isActive = false
    Utils.Logger.info("📝 Feedback Forms System cleaned up")
end
return FeedbackForms