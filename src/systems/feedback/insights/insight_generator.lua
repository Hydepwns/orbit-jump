--[[
    ═══════════════════════════════════════════════════════════════════════════
    Insight Generator - Automated Insight Creation & Analysis
    ═══════════════════════════════════════════════════════════════════════════
    
    This module generates actionable insights from analysis results, combining
    multiple data sources to create comprehensive recommendations for game optimization.
--]]

local Utils = require("src.utils.utils")
local StatisticalTools = require("src.systems.feedback.statistics.statistical_tools")

local InsightGenerator = {}

-- Configuration
InsightGenerator.config = {
    insight_priorities = {
        critical = 1,
        high = 2,
        medium = 3,
        low = 4
    },
    insight_categories = {
        engagement = "player_engagement",
        balance = "game_balance",
        progression = "player_progression",
        retention = "player_retention",
        performance = "technical_performance",
        satisfaction = "player_satisfaction"
    },
    confidence_thresholds = {
        high = 0.8,
        medium = 0.6,
        low = 0.4
    }
}

-- Generate comprehensive insights from analysis results
function InsightGenerator.generateInsights(analysisResults)
    if not analysisResults then
        return {error = "No analysis results provided"}
    end
    
    local insights = {
        summary = {},
        detailed_insights = {},
        recommendations = {},
        priority_actions = {},
        trends = {},
        generated_at = os.time()
    }
    
    -- Generate summary insights
    insights.summary = InsightGenerator.generateSummaryInsights(analysisResults)
    
    -- Generate detailed insights by category
    insights.detailed_insights = InsightGenerator.generateDetailedInsights(analysisResults)
    
    -- Generate actionable recommendations
    insights.recommendations = InsightGenerator.generateRecommendations(analysisResults)
    
    -- Identify priority actions
    insights.priority_actions = InsightGenerator.identifyPriorityActions(insights.recommendations)
    
    -- Analyze trends
    insights.trends = InsightGenerator.analyzeTrends(analysisResults)
    
    return insights
end

-- Generate summary insights
function InsightGenerator.generateSummaryInsights(analysisResults)
    local summary = {
        overall_health = "good",
        key_metrics = {},
        critical_issues = 0,
        improvement_areas = {},
        positive_trends = {}
    }
    
    -- Calculate overall health score
    local healthScore = 0
    local metricCount = 0
    
    if analysisResults.engagement and analysisResults.engagement.overall_score then
        healthScore = healthScore + analysisResults.engagement.overall_score
        metricCount = metricCount + 1
    end
    
    if analysisResults.balance and analysisResults.balance.overall_score then
        healthScore = healthScore + analysisResults.balance.overall_score
        metricCount = metricCount + 1
    end
    
    if analysisResults.progression and analysisResults.progression.overall_score then
        healthScore = healthScore + analysisResults.progression.overall_score
        metricCount = metricCount + 1
    end
    
    if metricCount > 0 then
        local avgHealthScore = healthScore / metricCount
        if avgHealthScore >= 80 then
            summary.overall_health = "excellent"
        elseif avgHealthScore >= 60 then
            summary.overall_health = "good"
        elseif avgHealthScore >= 40 then
            summary.overall_health = "fair"
        else
            summary.overall_health = "poor"
        end
    end
    
    -- Identify key metrics
    summary.key_metrics = InsightGenerator.extractKeyMetrics(analysisResults)
    
    -- Count critical issues
    summary.critical_issues = InsightGenerator.countCriticalIssues(analysisResults)
    
    -- Identify improvement areas
    summary.improvement_areas = InsightGenerator.identifyImprovementAreas(analysisResults)
    
    -- Identify positive trends
    summary.positive_trends = InsightGenerator.identifyPositiveTrends(analysisResults)
    
    return summary
end

-- Generate detailed insights by category
function InsightGenerator.generateDetailedInsights(analysisResults)
    local detailedInsights = {}
    
    -- Engagement insights
    if analysisResults.engagement then
        detailedInsights.engagement = InsightGenerator.generateEngagementInsights(analysisResults.engagement)
    end
    
    -- Balance insights
    if analysisResults.balance then
        detailedInsights.balance = InsightGenerator.generateBalanceInsights(analysisResults.balance)
    end
    
    -- Progression insights
    if analysisResults.progression then
        detailedInsights.progression = InsightGenerator.generateProgressionInsights(analysisResults.progression)
    end
    
    -- Retention insights
    if analysisResults.retention then
        detailedInsights.retention = InsightGenerator.generateRetentionInsights(analysisResults.retention)
    end
    
    -- Performance insights
    if analysisResults.performance then
        detailedInsights.performance = InsightGenerator.generatePerformanceInsights(analysisResults.performance)
    end
    
    -- Satisfaction insights
    if analysisResults.satisfaction then
        detailedInsights.satisfaction = InsightGenerator.generateSatisfactionInsights(analysisResults.satisfaction)
    end
    
    return detailedInsights
end

-- Generate engagement insights
function InsightGenerator.generateEngagementInsights(engagementData)
    local insights = {
        session_patterns = {},
        retention_metrics = {},
        engagement_drivers = {},
        risk_factors = {}
    }
    
    if engagementData.metrics then
        -- Session frequency insights
        if engagementData.metrics.session_frequency then
            local freq = engagementData.metrics.session_frequency
            if freq.sessions_per_day < 1 then
                table.insert(insights.risk_factors, {
                    type = "low_session_frequency",
                    severity = "high",
                    description = "Players are not engaging frequently enough",
                    impact = "High risk of churn"
                })
            end
            
            if freq.frequency_trend == "decreasing" then
                table.insert(insights.session_patterns, {
                    type = "declining_engagement",
                    severity = "medium",
                    description = "Session frequency is declining over time",
                    trend = "negative"
                })
            end
        end
        
        -- Session duration insights
        if engagementData.metrics.session_duration then
            local duration = engagementData.metrics.session_duration
            if duration.ideal_duration_ratio < 0.5 then
                table.insert(insights.session_patterns, {
                    type = "suboptimal_session_length",
                    severity = "medium",
                    description = "Most sessions are outside the ideal duration range",
                    recommendation = "Adjust difficulty curve to encourage longer sessions"
                })
            end
        end
        
        -- Progression speed insights
        if engagementData.metrics.progression_speed then
            local progression = engagementData.metrics.progression_speed
            if progression.levels_per_session < 1 then
                table.insert(insights.risk_factors, {
                    type = "slow_progression",
                    severity = "high",
                    description = "Players are progressing too slowly",
                    impact = "May lead to frustration and churn"
                })
            end
        end
    end
    
    return insights
end

-- Generate balance insights
function InsightGenerator.generateBalanceInsights(balanceData)
    local insights = {
        difficulty_issues = {},
        progression_balance = {},
        reward_effectiveness = {},
        satisfaction_metrics = {}
    }
    
    if balanceData.metrics then
        -- Difficulty insights
        if balanceData.metrics.difficulty and balanceData.metrics.difficulty.difficulty_spikes then
            for _, spike in ipairs(balanceData.metrics.difficulty.difficulty_spikes) do
                table.insert(insights.difficulty_issues, {
                    type = "difficulty_spike",
                    level = spike.level,
                    severity = spike.severity,
                    description = string.format("Level %s has completion rate of %.1f%%", 
                                              spike.level, spike.completion_rate * 100),
                    recommendation = "Consider reducing difficulty or adding hints"
                })
            end
        end
        
        -- Progression insights
        if balanceData.metrics.progression then
            local progression = balanceData.metrics.progression
            if progression.progression_speed and progression.progression_speed.avg_rate then
                if progression.progression_speed.avg_rate < 0.2 then
                    table.insert(insights.progression_balance, {
                        type = "slow_progression",
                        severity = "medium",
                        description = "Overall progression speed is too slow",
                        recommendation = "Increase progression speed or reduce level requirements"
                    })
                elseif progression.progression_speed.avg_rate > 1.0 then
                    table.insert(insights.progression_balance, {
                        type = "fast_progression",
                        severity = "low",
                        description = "Progression speed may be too fast",
                        recommendation = "Consider adding more content or increasing difficulty"
                    })
                end
            end
        end
        
        -- Reward insights
        if balanceData.metrics.rewards then
            local rewards = balanceData.metrics.rewards
            if rewards.reward_frequency and rewards.reward_frequency.avg_interval then
                if rewards.reward_frequency.avg_interval > 300 then
                    table.insert(insights.reward_effectiveness, {
                        type = "infrequent_rewards",
                        severity = "medium",
                        description = "Rewards are too infrequent",
                        recommendation = "Increase reward frequency or add intermediate rewards"
                    })
                end
            end
        end
    end
    
    return insights
end

-- Generate progression insights
function InsightGenerator.generateProgressionInsights(progressionData)
    local insights = {
        progression_speed = {},
        progression_consistency = {},
        progression_satisfaction = {},
        progression_barriers = {}
    }
    
    -- Add progression-specific insights here
    -- This would analyze progression patterns, level completion rates, etc.
    
    return insights
end

-- Generate retention insights
function InsightGenerator.generateRetentionInsights(retentionData)
    local insights = {
        retention_rates = {},
        churn_indicators = {},
        retention_drivers = {},
        cohort_analysis = {}
    }
    
    -- Add retention-specific insights here
    -- This would analyze retention patterns, churn predictors, etc.
    
    return insights
end

-- Generate performance insights
function InsightGenerator.generatePerformanceInsights(performanceData)
    local insights = {
        technical_issues = {},
        performance_metrics = {},
        optimization_opportunities = {},
        stability_concerns = {}
    }
    
    -- Add performance-specific insights here
    -- This would analyze technical performance, crashes, etc.
    
    return insights
end

-- Generate satisfaction insights
function InsightGenerator.generateSatisfactionInsights(satisfactionData)
    local insights = {
        satisfaction_levels = {},
        satisfaction_factors = {},
        satisfaction_trends = {},
        improvement_areas = {}
    }
    
    -- Add satisfaction-specific insights here
    -- This would analyze player satisfaction, feedback trends, etc.
    
    return insights
end

-- Generate actionable recommendations
function InsightGenerator.generateRecommendations(analysisResults)
    local recommendations = {
        immediate_actions = {},
        short_term = {},
        long_term = {},
        monitoring = {}
    }
    
    -- Extract recommendations from all analysis results
    if analysisResults.engagement and analysisResults.engagement.recommendations then
        for _, rec in ipairs(analysisResults.engagement.recommendations) do
            if rec.priority == "critical" then
                table.insert(recommendations.immediate_actions, rec)
            elseif rec.priority == "high" then
                table.insert(recommendations.short_term, rec)
            else
                table.insert(recommendations.long_term, rec)
            end
        end
    end
    
    if analysisResults.balance and analysisResults.balance.recommendations then
        for _, rec in ipairs(analysisResults.balance.recommendations) do
            if rec.priority == "critical" then
                table.insert(recommendations.immediate_actions, rec)
            elseif rec.priority == "high" then
                table.insert(recommendations.short_term, rec)
            else
                table.insert(recommendations.long_term, rec)
            end
        end
    end
    
    -- Add monitoring recommendations
    recommendations.monitoring = InsightGenerator.generateMonitoringRecommendations(analysisResults)
    
    return recommendations
end

-- Identify priority actions
function InsightGenerator.identifyPriorityActions(recommendations)
    local priorityActions = {
        critical = {},
        high = {},
        medium = {},
        low = {}
    }
    
    -- Sort recommendations by priority
    for _, rec in ipairs(recommendations.immediate_actions) do
        table.insert(priorityActions.critical, rec)
    end
    
    for _, rec in ipairs(recommendations.short_term) do
        table.insert(priorityActions.high, rec)
    end
    
    for _, rec in ipairs(recommendations.long_term) do
        table.insert(priorityActions.medium, rec)
    end
    
    return priorityActions
end

-- Analyze trends
function InsightGenerator.analyzeTrends(analysisResults)
    local trends = {
        engagement_trends = {},
        balance_trends = {},
        performance_trends = {},
        satisfaction_trends = {}
    }
    
    -- Add trend analysis here
    -- This would compare current results with historical data
    
    return trends
end

-- Extract key metrics
function InsightGenerator.extractKeyMetrics(analysisResults)
    local keyMetrics = {}
    
    if analysisResults.engagement and analysisResults.engagement.overall_score then
        table.insert(keyMetrics, {
            name = "engagement_score",
            value = analysisResults.engagement.overall_score,
            unit = "score",
            trend = "stable"
        })
    end
    
    if analysisResults.balance and analysisResults.balance.overall_score then
        table.insert(keyMetrics, {
            name = "balance_score",
            value = analysisResults.balance.overall_score,
            unit = "score",
            trend = "stable"
        })
    end
    
    return keyMetrics
end

-- Count critical issues
function InsightGenerator.countCriticalIssues(analysisResults)
    local criticalCount = 0
    
    -- Count critical issues from all analysis results
    if analysisResults.engagement and analysisResults.engagement.insights then
        for _, insight in ipairs(analysisResults.engagement.insights) do
            if insight.priority == "critical" then
                criticalCount = criticalCount + 1
            end
        end
    end
    
    if analysisResults.balance and analysisResults.balance.balance_issues then
        for _, issue in ipairs(analysisResults.balance.balance_issues) do
            if issue.priority == "high" then
                criticalCount = criticalCount + 1
            end
        end
    end
    
    return criticalCount
end

-- Identify improvement areas
function InsightGenerator.identifyImprovementAreas(analysisResults)
    local improvementAreas = {}
    
    -- Identify areas that need improvement based on analysis results
    if analysisResults.engagement and analysisResults.engagement.overall_score then
        if analysisResults.engagement.overall_score < 60 then
            table.insert(improvementAreas, {
                area = "player_engagement",
                priority = "high",
                description = "Overall engagement score is below target"
            })
        end
    end
    
    if analysisResults.balance and analysisResults.balance.overall_score then
        if analysisResults.balance.overall_score < 60 then
            table.insert(improvementAreas, {
                area = "game_balance",
                priority = "high",
                description = "Game balance needs improvement"
            })
        end
    end
    
    return improvementAreas
end

-- Identify positive trends
function InsightGenerator.identifyPositiveTrends(analysisResults)
    local positiveTrends = {}
    
    -- Identify positive trends from analysis results
    if analysisResults.engagement and analysisResults.engagement.overall_score then
        if analysisResults.engagement.overall_score > 80 then
            table.insert(positiveTrends, {
                area = "player_engagement",
                description = "High engagement levels maintained",
                impact = "positive"
            })
        end
    end
    
    return positiveTrends
end

-- Generate monitoring recommendations
function InsightGenerator.generateMonitoringRecommendations(analysisResults)
    local monitoring = {
        metrics_to_track = {},
        alerts_to_set = {},
        reports_to_generate = {}
    }
    
    -- Add monitoring recommendations based on analysis results
    table.insert(monitoring.metrics_to_track, {
        metric = "session_frequency",
        frequency = "daily",
        threshold = 1.0,
        description = "Monitor daily session frequency"
    })
    
    table.insert(monitoring.metrics_to_track, {
        metric = "completion_rates",
        frequency = "weekly",
        threshold = 0.7,
        description = "Monitor level completion rates"
    })
    
    return monitoring
end

-- Generate insight report
function InsightGenerator.generateReport(insights, format)
    format = format or "json"
    
    if format == "json" then
        return insights
    elseif format == "summary" then
        return InsightGenerator.generateSummaryReport(insights)
    elseif format == "detailed" then
        return InsightGenerator.generateDetailedReport(insights)
    end
    
    return insights
end

-- Generate summary report
function InsightGenerator.generateSummaryReport(insights)
    local summary = {
        title = "Game Analysis Summary Report",
        generated_at = os.date("%Y-%m-%d %H:%M:%S", insights.generated_at),
        overall_health = insights.summary.overall_health,
        critical_issues = insights.summary.critical_issues,
        key_recommendations = {}
    }
    
    -- Extract top recommendations
    for _, rec in ipairs(insights.recommendations.immediate_actions) do
        table.insert(summary.key_recommendations, rec)
    end
    
    for _, rec in ipairs(insights.recommendations.short_term) do
        if #summary.key_recommendations < 5 then
            table.insert(summary.key_recommendations, rec)
        end
    end
    
    return summary
end

-- Generate detailed report
function InsightGenerator.generateDetailedReport(insights)
    local detailed = {
        title = "Detailed Game Analysis Report",
        generated_at = os.date("%Y-%m-%d %H:%M:%S", insights.generated_at),
        summary = insights.summary,
        detailed_insights = insights.detailed_insights,
        recommendations = insights.recommendations,
        priority_actions = insights.priority_actions,
        trends = insights.trends
    }
    
    return detailed
end

return InsightGenerator 