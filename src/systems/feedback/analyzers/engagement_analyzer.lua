--[[
    ═══════════════════════════════════════════════════════════════════════════
    Engagement Analyzer - Player Engagement Metrics & Analysis
    ═══════════════════════════════════════════════════════════════════════════
    
    This module analyzes player engagement patterns, retention metrics, and
    session behavior to provide insights for improving player retention.
--]]

local Utils = require("src.utils.utils")
local StatisticalTools = require("src.systems.feedback.statistics.statistical_tools")

local EngagementAnalyzer = {}

-- Configuration
EngagementAnalyzer.config = {
    session_length_ideal = {min = 600, max = 1800}, -- 10-30 minutes
    retention_thresholds = {day_1 = 0.75, day_7 = 0.40, day_30 = 0.25},
    engagement_metrics = {
        session_frequency_weight = 0.3,
        session_duration_weight = 0.25,
        progression_speed_weight = 0.2,
        feature_usage_weight = 0.15,
        social_interaction_weight = 0.1
    }
}

-- Analyze overall engagement metrics
function EngagementAnalyzer.analyzeEngagement(sessionData, playerMetrics)
    if not sessionData or not playerMetrics then
        return {error = "Missing session data or player metrics"}
    end
    
    local analysis = {
        overall_score = 0,
        metrics = {},
        insights = {},
        recommendations = {}
    }
    
    -- Calculate individual engagement metrics
    analysis.metrics.session_frequency = EngagementAnalyzer.analyzeSessionFrequency(sessionData)
    analysis.metrics.session_duration = EngagementAnalyzer.analyzeSessionDuration(sessionData)
    analysis.metrics.progression_speed = EngagementAnalyzer.analyzeProgressionSpeed(sessionData)
    analysis.metrics.feature_usage = EngagementAnalyzer.analyzeFeatureUsage(sessionData)
    analysis.metrics.social_interaction = EngagementAnalyzer.analyzeSocialInteraction(sessionData)
    
    -- Calculate overall engagement score
    analysis.overall_score = EngagementAnalyzer.calculateEngagementScore(analysis.metrics)
    
    -- Generate insights
    analysis.insights = EngagementAnalyzer.generateEngagementInsights(analysis.metrics)
    
    -- Generate recommendations
    analysis.recommendations = EngagementAnalyzer.generateEngagementRecommendations(analysis.metrics, analysis.overall_score)
    
    return analysis
end

-- Analyze session frequency patterns
function EngagementAnalyzer.analyzeSessionFrequency(sessionData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    
    local analysis = {
        sessions_per_day = 0,
        session_consistency = 0,
        frequency_trend = "stable",
        score = 0
    }
    
    -- Calculate sessions per day
    local sessionCounts = {}
    for _, session in ipairs(sessionData) do
        if session.date then
            local date = os.date("%Y-%m-%d", session.date)
            sessionCounts[date] = (sessionCounts[date] or 0) + 1
        end
    end
    
    local totalSessions = 0
    local totalDays = 0
    for _, count in pairs(sessionCounts) do
        totalSessions = totalSessions + count
        totalDays = totalDays + 1
    end
    
    if totalDays > 0 then
        analysis.sessions_per_day = totalSessions / totalDays
    end
    
    -- Calculate session consistency
    local frequencies = {}
    for _, count in pairs(sessionCounts) do
        table.insert(frequencies, count)
    end
    
    if #frequencies > 1 then
        local mean = StatisticalTools.mean(frequencies)
        local stdDev = StatisticalTools.standardDeviation(frequencies, mean)
        analysis.session_consistency = mean > 0 and (1 - (stdDev / mean)) or 0
    end
    
    -- Determine frequency trend
    if #frequencies >= 7 then
        local recentFreq = StatisticalTools.mean(frequencies, math.max(1, #frequencies - 3))
        local olderFreq = StatisticalTools.mean(frequencies, 1, math.max(1, #frequencies - 6))
        
        if recentFreq > olderFreq * 1.1 then
            analysis.frequency_trend = "increasing"
        elseif recentFreq < olderFreq * 0.9 then
            analysis.frequency_trend = "decreasing"
        end
    end
    
    -- Calculate score (0-100)
    analysis.score = math.min(100, analysis.sessions_per_day * 20) -- 5+ sessions per day = 100
    
    return analysis
end

-- Analyze session duration patterns
function EngagementAnalyzer.analyzeSessionDuration(sessionData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    
    local analysis = {
        average_duration = 0,
        duration_distribution = {},
        ideal_duration_ratio = 0,
        score = 0
    }
    
    -- Extract session durations
    local durations = {}
    for _, session in ipairs(sessionData) do
        if session.duration and session.duration > 0 then
            table.insert(durations, session.duration)
        end
    end
    
    if #durations > 0 then
        analysis.average_duration = StatisticalTools.mean(durations)
        
        -- Calculate duration distribution
        local shortSessions = 0
        local idealSessions = 0
        local longSessions = 0
        
        for _, duration in ipairs(durations) do
            if duration < EngagementAnalyzer.config.session_length_ideal.min then
                shortSessions = shortSessions + 1
            elseif duration <= EngagementAnalyzer.config.session_length_ideal.max then
                idealSessions = idealSessions + 1
            else
                longSessions = longSessions + 1
            end
        end
        
        analysis.duration_distribution = {
            short = shortSessions,
            ideal = idealSessions,
            long = longSessions,
            total = #durations
        }
        
        -- Calculate ideal duration ratio
        analysis.ideal_duration_ratio = idealSessions / #durations
        
        -- Calculate score based on ideal duration ratio
        analysis.score = analysis.ideal_duration_ratio * 100
    end
    
    return analysis
end

-- Analyze progression speed
function EngagementAnalyzer.analyzeProgressionSpeed(sessionData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    
    local analysis = {
        levels_per_session = 0,
        progression_consistency = 0,
        progression_satisfaction = 0,
        score = 0
    }
    
    -- Calculate levels per session
    local totalLevels = 0
    local validSessions = 0
    
    for _, session in ipairs(sessionData) do
        if session.levels_completed then
            totalLevels = totalLevels + session.levels_completed
            validSessions = validSessions + 1
        end
    end
    
    if validSessions > 0 then
        analysis.levels_per_session = totalLevels / validSessions
    end
    
    -- Calculate progression consistency
    local levelsPerSession = {}
    for _, session in ipairs(sessionData) do
        if session.levels_completed then
            table.insert(levelsPerSession, session.levels_completed)
        end
    end
    
    if #levelsPerSession > 1 then
        local mean = StatisticalTools.mean(levelsPerSession)
        local stdDev = StatisticalTools.standardDeviation(levelsPerSession, mean)
        analysis.progression_consistency = mean > 0 and (1 - (stdDev / mean)) or 0
    end
    
    -- Estimate progression satisfaction (would come from actual feedback)
    analysis.progression_satisfaction = math.min(5, analysis.levels_per_session * 0.5 + 2.5)
    
    -- Calculate score
    analysis.score = math.min(100, (analysis.levels_per_session * 10) + (analysis.progression_consistency * 50))
    
    return analysis
end

-- Analyze feature usage patterns
function EngagementAnalyzer.analyzeFeatureUsage(sessionData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    
    local analysis = {
        features_used = {},
        feature_diversity = 0,
        feature_frequency = {},
        score = 0
    }
    
    -- Track feature usage across sessions
    local featureCounts = {}
    local totalSessions = 0
    
    for _, session in ipairs(sessionData) do
        if session.features_used then
            totalSessions = totalSessions + 1
            for feature, used in pairs(session.features_used) do
                if used then
                    featureCounts[feature] = (featureCounts[feature] or 0) + 1
                end
            end
        end
    end
    
    -- Calculate feature diversity
    local uniqueFeatures = 0
    for feature, count in pairs(featureCounts) do
        uniqueFeatures = uniqueFeatures + 1
        analysis.features_used[feature] = count
        analysis.feature_frequency[feature] = count / totalSessions
    end
    
    analysis.feature_diversity = uniqueFeatures
    
    -- Calculate score based on feature diversity and usage
    local avgUsageRate = 0
    local usageCount = 0
    for _, rate in pairs(analysis.feature_frequency) do
        avgUsageRate = avgUsageRate + rate
        usageCount = usageCount + 1
    end
    
    if usageCount > 0 then
        avgUsageRate = avgUsageRate / usageCount
    end
    
    analysis.score = math.min(100, (analysis.feature_diversity * 10) + (avgUsageRate * 50))
    
    return analysis
end

-- Analyze social interaction patterns
function EngagementAnalyzer.analyzeSocialInteraction(sessionData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    
    local analysis = {
        social_actions = 0,
        social_features_used = {},
        social_engagement_rate = 0,
        score = 0
    }
    
    -- Count social interactions
    local totalSessions = 0
    local sessionsWithSocial = 0
    
    for _, session in ipairs(sessionData) do
        totalSessions = totalSessions + 1
        if session.social_actions then
            analysis.social_actions = analysis.social_actions + session.social_actions
            if session.social_actions > 0 then
                sessionsWithSocial = sessionsWithSocial + 1
            end
        end
        
        if session.social_features then
            for feature, used in pairs(session.social_features) do
                if used then
                    analysis.social_features_used[feature] = (analysis.social_features_used[feature] or 0) + 1
                end
            end
        end
    end
    
    -- Calculate social engagement rate
    if totalSessions > 0 then
        analysis.social_engagement_rate = sessionsWithSocial / totalSessions
    end
    
    -- Calculate score
    analysis.score = math.min(100, (analysis.social_engagement_rate * 60) + (analysis.social_actions * 2))
    
    return analysis
end

-- Calculate overall engagement score
function EngagementAnalyzer.calculateEngagementScore(metrics)
    local score = 0
    local weights = EngagementAnalyzer.config.engagement_metrics
    
    if metrics.session_frequency and metrics.session_frequency.score then
        score = score + (metrics.session_frequency.score * weights.session_frequency_weight)
    end
    
    if metrics.session_duration and metrics.session_duration.score then
        score = score + (metrics.session_duration.score * weights.session_duration_weight)
    end
    
    if metrics.progression_speed and metrics.progression_speed.score then
        score = score + (metrics.progression_speed.score * weights.progression_speed_weight)
    end
    
    if metrics.feature_usage and metrics.feature_usage.score then
        score = score + (metrics.feature_usage.score * weights.feature_usage_weight)
    end
    
    if metrics.social_interaction and metrics.social_interaction.score then
        score = score + (metrics.social_interaction.score * weights.social_interaction_weight)
    end
    
    return math.min(100, score)
end

-- Generate engagement insights
function EngagementAnalyzer.generateEngagementInsights(metrics)
    local insights = {}
    
    -- Session frequency insights
    if metrics.session_frequency then
        if metrics.session_frequency.sessions_per_day < 1 then
            table.insert(insights, {
                type = "warning",
                category = "session_frequency",
                message = "Low session frequency detected - players may be losing interest",
                priority = "high"
            })
        elseif metrics.session_frequency.frequency_trend == "decreasing" then
            table.insert(insights, {
                type = "warning",
                category = "session_frequency",
                message = "Session frequency is decreasing over time",
                priority = "medium"
            })
        end
    end
    
    -- Session duration insights
    if metrics.session_duration then
        if metrics.session_duration.ideal_duration_ratio < 0.5 then
            table.insert(insights, {
                type = "warning",
                category = "session_duration",
                message = "Most sessions are outside the ideal duration range",
                priority = "medium"
            })
        end
    end
    
    -- Progression insights
    if metrics.progression_speed then
        if metrics.progression_speed.levels_per_session < 1 then
            table.insert(insights, {
                type = "warning",
                category = "progression",
                message = "Low progression speed - players may be stuck",
                priority = "high"
            })
        end
    end
    
    -- Feature usage insights
    if metrics.feature_usage then
        if metrics.feature_usage.feature_diversity < 3 then
            table.insert(insights, {
                type = "info",
                category = "feature_usage",
                message = "Low feature diversity - consider promoting underused features",
                priority = "low"
            })
        end
    end
    
    return insights
end

-- Generate engagement recommendations
function EngagementAnalyzer.generateEngagementRecommendations(metrics, overallScore)
    local recommendations = {}
    
    if overallScore < 50 then
        table.insert(recommendations, {
            priority = "critical",
            category = "overall",
            action = "Implement comprehensive engagement improvement strategy",
            impact = "high"
        })
    end
    
    -- Session frequency recommendations
    if metrics.session_frequency and metrics.session_frequency.sessions_per_day < 1 then
        table.insert(recommendations, {
            priority = "high",
            category = "session_frequency",
            action = "Implement daily rewards and push notifications",
            impact = "medium"
        })
    end
    
    -- Session duration recommendations
    if metrics.session_duration and metrics.session_duration.ideal_duration_ratio < 0.5 then
        table.insert(recommendations, {
            priority = "medium",
            category = "session_duration",
            action = "Adjust difficulty curve to encourage longer sessions",
            impact = "medium"
        })
    end
    
    -- Progression recommendations
    if metrics.progression_speed and metrics.progression_speed.levels_per_session < 1 then
        table.insert(recommendations, {
            priority = "high",
            category = "progression",
            action = "Review and adjust level difficulty",
            impact = "high"
        })
    end
    
    return recommendations
end

-- Analyze retention patterns
function EngagementAnalyzer.analyzeRetention(sessionData, playerCohorts)
    if not sessionData or not playerCohorts then
        return {error = "Missing session data or player cohorts"}
    end
    
    local analysis = {
        retention_rates = {},
        cohort_analysis = {},
        churn_indicators = {},
        recommendations = {}
    }
    
    -- Calculate retention rates for different time periods
    for period, threshold in pairs(EngagementAnalyzer.config.retention_thresholds) do
        analysis.retention_rates[period] = EngagementAnalyzer.calculateRetentionRate(sessionData, period)
    end
    
    -- Analyze player cohorts
    analysis.cohort_analysis = EngagementAnalyzer.analyzePlayerCohorts(playerCohorts)
    
    -- Identify churn indicators
    analysis.churn_indicators = EngagementAnalyzer.identifyChurnIndicators(sessionData)
    
    -- Generate retention recommendations
    analysis.recommendations = EngagementAnalyzer.generateRetentionRecommendations(analysis)
    
    return analysis
end

-- Calculate retention rate for a specific period
function EngagementAnalyzer.calculateRetentionRate(sessionData, period)
    -- Simplified retention calculation
    -- In production, this would track actual player return rates
    local baseRate = 0.8 -- 80% base retention
    
    if period == "day_1" then
        return baseRate
    elseif period == "day_7" then
        return baseRate * 0.6
    elseif period == "day_30" then
        return baseRate * 0.4
    end
    
    return baseRate
end

-- Analyze player cohorts
function EngagementAnalyzer.analyzePlayerCohorts(playerCohorts)
    local analysis = {}
    
    for cohort, players in pairs(playerCohorts) do
        analysis[cohort] = {
            size = #players,
            avg_engagement = 0,
            retention_rate = 0,
            churn_risk = "low"
        }
        
        -- Calculate average engagement for cohort
        local totalEngagement = 0
        for _, player in ipairs(players) do
            totalEngagement = totalEngagement + (player.engagement_score or 0)
        end
        
        if #players > 0 then
            analysis[cohort].avg_engagement = totalEngagement / #players
        end
        
        -- Determine churn risk
        if analysis[cohort].avg_engagement < 30 then
            analysis[cohort].churn_risk = "high"
        elseif analysis[cohort].avg_engagement < 60 then
            analysis[cohort].churn_risk = "medium"
        end
    end
    
    return analysis
end

-- Identify churn indicators
function EngagementAnalyzer.identifyChurnIndicators(sessionData)
    local indicators = {}
    
    -- Look for patterns that indicate potential churn
    local recentSessions = {}
    for _, session in ipairs(sessionData) do
        if session.date and session.date > (os.time() - 7 * 24 * 3600) then -- Last 7 days
            table.insert(recentSessions, session)
        end
    end
    
    if #recentSessions == 0 then
        table.insert(indicators, {
            type = "critical",
            indicator = "no_recent_activity",
            description = "No activity in the last 7 days"
        })
    end
    
    return indicators
end

-- Generate retention recommendations
function EngagementAnalyzer.generateRetentionRecommendations(analysis)
    local recommendations = {}
    
    -- Check retention rates against thresholds
    for period, rate in pairs(analysis.retention_rates) do
        local threshold = EngagementAnalyzer.config.retention_thresholds[period]
        if rate < threshold then
            table.insert(recommendations, {
                priority = "high",
                period = period,
                action = string.format("Improve %s retention - current: %.1f%%, target: %.1f%%", 
                                     period, rate * 100, threshold * 100),
                impact = "high"
            })
        end
    end
    
    return recommendations
end

return EngagementAnalyzer 