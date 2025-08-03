--[[
    ═══════════════════════════════════════════════════════════════════════════
    Balance Analyzer - Game Balance & Difficulty Analysis
    ═══════════════════════════════════════════════════════════════════════════
    This module analyzes game balance, difficulty curves, and player progression
    to identify balance issues and provide recommendations for adjustments.
--]]
local Utils = require("src.utils.utils")
local StatisticalTools = require("src.systems.feedback.statistics.statistical_tools")
local BalanceAnalyzer = {}
-- Configuration
BalanceAnalyzer.config = {
    quit_point_threshold = 0.15, -- 15% quit rate triggers review
    frustration_threshold = 3,   -- 3+ frustration events per session
    flow_state_target = 0.6,     -- 60% of session should be in flow
    difficulty_satisfaction_min = 3.5, -- Out of 5
    balance_metrics = {
        difficulty_weight = 0.3,
        progression_weight = 0.25,
        reward_weight = 0.2,
        frustration_weight = 0.15,
        satisfaction_weight = 0.1
    }
}
-- Analyze overall game balance
function BalanceAnalyzer.analyzeBalance(sessionData, playerMetrics, levelData)
    if not sessionData or not playerMetrics then
        return {error = "Missing session data or player metrics"}
    end
    local analysis = {
        overall_score = 0,
        metrics = {},
        balance_issues = {},
        recommendations = {}
    }
    -- Calculate individual balance metrics
    analysis.metrics.difficulty = BalanceAnalyzer.analyzeDifficulty(sessionData, levelData)
    analysis.metrics.progression = BalanceAnalyzer.analyzeProgression(sessionData, levelData)
    analysis.metrics.rewards = BalanceAnalyzer.analyzeRewards(sessionData, playerMetrics)
    analysis.metrics.frustration = BalanceAnalyzer.analyzeFrustration(sessionData, playerMetrics)
    analysis.metrics.satisfaction = BalanceAnalyzer.analyzeSatisfaction(playerMetrics)
    -- Calculate overall balance score
    analysis.overall_score = BalanceAnalyzer.calculateBalanceScore(analysis.metrics)
    -- Identify balance issues
    analysis.balance_issues = BalanceAnalyzer.identifyBalanceIssues(analysis.metrics)
    -- Generate recommendations
    analysis.recommendations = BalanceAnalyzer.generateBalanceRecommendations(analysis.metrics, analysis.balance_issues)
    return analysis
end
-- Analyze difficulty patterns
function BalanceAnalyzer.analyzeDifficulty(sessionData, levelData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    local analysis = {
        difficulty_curve = {},
        difficulty_spikes = {},
        completion_rates = {},
        attempt_distribution = {},
        score = 0
    }
    -- Analyze completion rates by level
    local completionRates = {}
    local attemptCounts = {}
    for _, session in ipairs(sessionData) do
        if session.level and session.attempts then
            completionRates[session.level] = completionRates[session.level] or {completed = 0, total = 0}
            attemptCounts[session.level] = attemptCounts[session.level] or {}
            completionRates[session.level].total = completionRates[session.level].total + 1
            if session.completed then
                completionRates[session.level].completed = completionRates[session.level].completed + 1
            end
            table.insert(attemptCounts[session.level], session.attempts)
        end
    end
    -- Calculate difficulty curve
    for level, data in pairs(completionRates) do
        local completionRate = data.completed / data.total
        local avgAttempts = StatisticalTools.mean(attemptCounts[level] or {})
        analysis.difficulty_curve[level] = {
            completion_rate = completionRate,
            avg_attempts = avgAttempts,
            difficulty_score = (1 - completionRate) * 100
        }
        -- Identify difficulty spikes
        if completionRate < 0.5 and data.total >= 10 then
            table.insert(analysis.difficulty_spikes, {
                level = level,
                completion_rate = completionRate,
                avg_attempts = avgAttempts,
                severity = completionRate < 0.3 and "critical" or "moderate"
            })
        end
    end
    -- Calculate overall difficulty score
    local totalCompletionRate = 0
    local levelCount = 0
    for _, data in pairs(completionRates) do
        totalCompletionRate = totalCompletionRate + (data.completed / data.total)
        levelCount = levelCount + 1
    end
    if levelCount > 0 then
        local avgCompletionRate = totalCompletionRate / levelCount
        analysis.score = avgCompletionRate * 100
    end
    return analysis
end
-- Analyze progression patterns
function BalanceAnalyzer.analyzeProgression(sessionData, levelData)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    local analysis = {
        progression_speed = {},
        progression_consistency = {},
        progression_satisfaction = {},
        score = 0
    }
    -- Analyze progression speed
    local progressionRates = {}
    for _, session in ipairs(sessionData) do
        if session.levels_completed and session.duration then
            local rate = session.levels_completed / (session.duration / 60) -- levels per minute
            table.insert(progressionRates, rate)
        end
    end
    if #progressionRates > 0 then
        analysis.progression_speed = {
            avg_rate = StatisticalTools.mean(progressionRates),
            consistency = StatisticalTools.standardDeviation(progressionRates, StatisticalTools.mean(progressionRates)),
            distribution = progressionRates
        }
    end
    -- Analyze progression consistency across levels
    local levelProgression = {}
    for _, session in ipairs(sessionData) do
        if session.level and session.levels_completed then
            levelProgression[session.level] = levelProgression[session.level] or {}
            table.insert(levelProgression[session.level], session.levels_completed)
        end
    end
    for level, rates in pairs(levelProgression) do
        if #rates > 1 then
            analysis.progression_consistency[level] = {
                mean = StatisticalTools.mean(rates),
                std_dev = StatisticalTools.standardDeviation(rates, StatisticalTools.mean(rates)),
                consistency_score = 1 - (StatisticalTools.standardDeviation(rates, StatisticalTools.mean(rates)) / StatisticalTools.mean(rates))
            }
        end
    end
    -- Calculate overall progression score
    if analysis.progression_speed.avg_rate then
        local idealRate = 0.5 -- 1 level every 2 minutes
        local rateScore = math.min(100, (analysis.progression_speed.avg_rate / idealRate) * 100)
        local consistencyScore = analysis.progression_speed.consistency and
                                math.max(0, 100 - (analysis.progression_speed.consistency * 50)) or 50
        analysis.score = (rateScore + consistencyScore) / 2
    end
    return analysis
end
-- Analyze reward patterns
function BalanceAnalyzer.analyzeRewards(sessionData, playerMetrics)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    local analysis = {
        reward_frequency = {},
        reward_satisfaction = {},
        reward_effectiveness = {},
        score = 0
    }
    -- Analyze reward frequency
    local rewardIntervals = {}
    local lastRewardTime = 0
    for _, session in ipairs(sessionData) do
        if session.rewards and #session.rewards > 0 then
            for _, reward in ipairs(session.rewards) do
                if reward.timestamp then
                    local interval = reward.timestamp - lastRewardTime
                    if interval > 0 then
                        table.insert(rewardIntervals, interval)
                    end
                    lastRewardTime = reward.timestamp
                end
            end
        end
    end
    if #rewardIntervals > 0 then
        analysis.reward_frequency = {
            avg_interval = StatisticalTools.mean(rewardIntervals),
            consistency = StatisticalTools.standardDeviation(rewardIntervals, StatisticalTools.mean(rewardIntervals)),
            ideal_interval = 180 -- 3 minutes
        }
    end
    -- Analyze reward satisfaction
    if playerMetrics.reward_satisfaction then
        analysis.reward_satisfaction = {
            avg_satisfaction = StatisticalTools.mean(playerMetrics.reward_satisfaction),
            satisfaction_trend = BalanceAnalyzer.analyzeSatisfactionTrend(playerMetrics.reward_satisfaction)
        }
    end
    -- Calculate reward effectiveness
    local effectivenessScore = 0
    if analysis.reward_frequency.avg_interval then
        local intervalScore = math.max(0, 100 - math.abs(analysis.reward_frequency.avg_interval - analysis.reward_frequency.ideal_interval) * 0.5)
        effectivenessScore = effectivenessScore + intervalScore * 0.6
    end
    if analysis.reward_satisfaction.avg_satisfaction then
        local satisfactionScore = analysis.reward_satisfaction.avg_satisfaction * 20 -- Convert 1-5 to 0-100
        effectivenessScore = effectivenessScore + satisfactionScore * 0.4
    end
    analysis.score = effectivenessScore
    return analysis
end
-- Analyze frustration patterns
function BalanceAnalyzer.analyzeFrustration(sessionData, playerMetrics)
    if not sessionData or #sessionData == 0 then
        return {error = "No session data provided"}
    end
    local analysis = {
        frustration_events = {},
        frustration_triggers = {},
        frustration_recovery = {},
        score = 0
    }
    -- Count frustration events
    local totalFrustrationEvents = 0
    local sessionsWithFrustration = 0
    local frustrationTriggers = {}
    for _, session in ipairs(sessionData) do
        local sessionFrustration = 0
        if session.frustration_events then
            for _, event in ipairs(session.frustration_events) do
                sessionFrustration = sessionFrustration + 1
                totalFrustrationEvents = totalFrustrationEvents + 1
                if event.trigger then
                    frustrationTriggers[event.trigger] = (frustrationTriggers[event.trigger] or 0) + 1
                end
            end
        end
        if sessionFrustration > 0 then
            sessionsWithFrustration = sessionsWithFrustration + 1
        end
    end
    analysis.frustration_events = {
        total_events = totalFrustrationEvents,
        events_per_session = totalFrustrationEvents / #sessionData,
        sessions_with_frustration = sessionsWithFrustration,
        frustration_rate = sessionsWithFrustration / #sessionData
    }
    analysis.frustration_triggers = frustrationTriggers
    -- Analyze frustration recovery
    local recoveryTimes = {}
    for _, session in ipairs(sessionData) do
        if session.frustration_events and session.recovery_time then
            table.insert(recoveryTimes, session.recovery_time)
        end
    end
    if #recoveryTimes > 0 then
        analysis.frustration_recovery = {
            avg_recovery_time = StatisticalTools.mean(recoveryTimes),
            recovery_consistency = StatisticalTools.standardDeviation(recoveryTimes, StatisticalTools.mean(recoveryTimes))
        }
    end
    -- Calculate frustration score (lower is better)
    local frustrationScore = 100
    if analysis.frustration_events.events_per_session > BalanceAnalyzer.config.frustration_threshold then
        frustrationScore = frustrationScore - 30
    end
    if analysis.frustration_events.frustration_rate > 0.5 then
        frustrationScore = frustrationScore - 30
    end
    if analysis.frustration_recovery.avg_recovery_time and analysis.frustration_recovery.avg_recovery_time > 300 then
        frustrationScore = frustrationScore - 20
    end
    analysis.score = math.max(0, frustrationScore)
    return analysis
end
-- Analyze satisfaction patterns
function BalanceAnalyzer.analyzeSatisfaction(playerMetrics)
    if not playerMetrics then
        return {error = "No player metrics provided"}
    end
    local analysis = {
        overall_satisfaction = {},
        satisfaction_factors = {},
        satisfaction_trends = {},
        score = 0
    }
    -- Analyze overall satisfaction
    if playerMetrics.satisfaction_scores then
        analysis.overall_satisfaction = {
            avg_satisfaction = StatisticalTools.mean(playerMetrics.satisfaction_scores),
            satisfaction_distribution = BalanceAnalyzer.analyzeSatisfactionDistribution(playerMetrics.satisfaction_scores),
            trend = BalanceAnalyzer.analyzeSatisfactionTrend(playerMetrics.satisfaction_scores)
        }
    end
    -- Analyze satisfaction factors
    if playerMetrics.satisfaction_factors then
        analysis.satisfaction_factors = playerMetrics.satisfaction_factors
    end
    -- Calculate satisfaction score
    if analysis.overall_satisfaction.avg_satisfaction then
        analysis.score = analysis.overall_satisfaction.avg_satisfaction * 20 -- Convert 1-5 to 0-100
    end
    return analysis
end
-- Calculate overall balance score
function BalanceAnalyzer.calculateBalanceScore(metrics)
    local score = 0
    local weights = BalanceAnalyzer.config.balance_metrics
    if metrics.difficulty and metrics.difficulty.score then
        score = score + (metrics.difficulty.score * weights.difficulty_weight)
    end
    if metrics.progression and metrics.progression.score then
        score = score + (metrics.progression.score * weights.progression_weight)
    end
    if metrics.rewards and metrics.rewards.score then
        score = score + (metrics.rewards.score * weights.reward_weight)
    end
    if metrics.frustration and metrics.frustration.score then
        score = score + (metrics.frustration.score * weights.frustration_weight)
    end
    if metrics.satisfaction and metrics.satisfaction.score then
        score = score + (metrics.satisfaction.score * weights.satisfaction_weight)
    end
    return math.min(100, score)
end
-- Identify balance issues
function BalanceAnalyzer.identifyBalanceIssues(metrics)
    local issues = {}
    -- Difficulty issues
    if metrics.difficulty then
        for _, spike in ipairs(metrics.difficulty.difficulty_spikes) do
            table.insert(issues, {
                type = "difficulty_spike",
                level = spike.level,
                severity = spike.severity,
                description = string.format("Level %s has low completion rate (%.1f%%)",
                                          spike.level, spike.completion_rate * 100),
                priority = spike.severity == "critical" and "high" or "medium"
            })
        end
    end
    -- Progression issues
    if metrics.progression and metrics.progression.progression_speed.avg_rate then
        if metrics.progression.progression_speed.avg_rate < 0.2 then
            table.insert(issues, {
                type = "slow_progression",
                severity = "moderate",
                description = "Progression speed is too slow",
                priority = "medium"
            })
        elseif metrics.progression.progression_speed.avg_rate > 1.0 then
            table.insert(issues, {
                type = "fast_progression",
                severity = "moderate",
                description = "Progression speed is too fast",
                priority = "low"
            })
        end
    end
    -- Reward issues
    if metrics.rewards and metrics.rewards.reward_frequency.avg_interval then
        if metrics.rewards.reward_frequency.avg_interval > 300 then
            table.insert(issues, {
                type = "infrequent_rewards",
                severity = "moderate",
                description = "Rewards are too infrequent",
                priority = "medium"
            })
        end
    end
    -- Frustration issues
    if metrics.frustration and metrics.frustration.frustration_events.events_per_session > BalanceAnalyzer.config.frustration_threshold then
        table.insert(issues, {
            type = "high_frustration",
            severity = "high",
            description = "High frustration rate detected",
            priority = "high"
        })
    end
    -- Satisfaction issues
    if metrics.satisfaction and metrics.satisfaction.overall_satisfaction.avg_satisfaction then
        if metrics.satisfaction.overall_satisfaction.avg_satisfaction < BalanceAnalyzer.config.difficulty_satisfaction_min then
            table.insert(issues, {
                type = "low_satisfaction",
                severity = "high",
                description = "Player satisfaction is below target",
                priority = "high"
            })
        end
    end
    return issues
end
-- Generate balance recommendations
function BalanceAnalyzer.generateBalanceRecommendations(metrics, balanceIssues)
    local recommendations = {}
    -- Generate recommendations based on identified issues
    for _, issue in ipairs(balanceIssues) do
        if issue.type == "difficulty_spike" then
            table.insert(recommendations, {
                priority = issue.priority,
                category = "difficulty",
                action = string.format("Reduce difficulty of level %s", issue.level),
                impact = "high"
            })
        elseif issue.type == "slow_progression" then
            table.insert(recommendations, {
                priority = "medium",
                category = "progression",
                action = "Increase progression speed or reduce level requirements",
                impact = "medium"
            })
        elseif issue.type == "infrequent_rewards" then
            table.insert(recommendations, {
                priority = "medium",
                category = "rewards",
                action = "Increase reward frequency or add intermediate rewards",
                impact = "medium"
            })
        elseif issue.type == "high_frustration" then
            table.insert(recommendations, {
                priority = "high",
                category = "frustration",
                action = "Identify and address frustration triggers",
                impact = "high"
            })
        elseif issue.type == "low_satisfaction" then
            table.insert(recommendations, {
                priority = "high",
                category = "satisfaction",
                action = "Conduct player feedback survey to identify issues",
                impact = "high"
            })
        end
    end
    return recommendations
end
-- Analyze satisfaction distribution
function BalanceAnalyzer.analyzeSatisfactionDistribution(satisfactionScores)
    local distribution = {low = 0, medium = 0, high = 0}
    for _, score in ipairs(satisfactionScores) do
        if score < 3 then
            distribution.low = distribution.low + 1
        elseif score < 4 then
            distribution.medium = distribution.medium + 1
        else
            distribution.high = distribution.high + 1
        end
    end
    return distribution
end
-- Analyze satisfaction trend
function BalanceAnalyzer.analyzeSatisfactionTrend(satisfactionScores)
    if #satisfactionScores < 2 then
        return "insufficient_data"
    end
    local recentScores = {}
    local olderScores = {}
    local midPoint = math.ceil(#satisfactionScores / 2)
    for i = 1, midPoint do
        table.insert(olderScores, satisfactionScores[i])
    end
    for i = midPoint + 1, #satisfactionScores do
        table.insert(recentScores, satisfactionScores[i])
    end
    if #recentScores > 0 and #olderScores > 0 then
        local recentAvg = StatisticalTools.mean(recentScores)
        local olderAvg = StatisticalTools.mean(olderScores)
        if recentAvg > olderAvg * 1.1 then
            return "improving"
        elseif recentAvg < olderAvg * 0.9 then
            return "declining"
        else
            return "stable"
        end
    end
    return "insufficient_data"
end
return BalanceAnalyzer