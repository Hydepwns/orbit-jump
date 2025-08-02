--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Analysis Pipeline - Automated Analysis & Insight Generation
    ═══════════════════════════════════════════════════════════════════════════
    
    This system implements the automated feedback analysis pipeline from the
    Feedback Integration Plan, processing player data to generate actionable
    insights for game optimization and balance adjustments.
--]]

local Utils = require("src.utils.utils")

local FeedbackAnalyzer = {}

-- System state
FeedbackAnalyzer.isActive = false
FeedbackAnalyzer.lastAnalysisTime = 0
FeedbackAnalyzer.analysisInterval = 60 -- Run analysis every 60 seconds

-- Analysis results storage
FeedbackAnalyzer.insights = {
    engagement_insights = {},
    balance_insights = {},
    progression_insights = {},
    sentiment_insights = {},
    performance_insights = {},
    behavioral_insights = {}
}

-- Statistical analysis tools
FeedbackAnalyzer.statistics = {
    confidence_level = 0.95,
    min_sample_size = 30,
    effect_size_thresholds = {
        small = 0.2,
        medium = 0.5,
        large = 0.8
    }
}

-- Analysis patterns and thresholds
FeedbackAnalyzer.patterns = {
    -- Engagement patterns
    engagement = {
        session_length_ideal = {min = 600, max = 1800}, -- 10-30 minutes
        retention_thresholds = {day_1 = 0.75, day_7 = 0.40, day_30 = 0.25},
        activity_patterns = {}
    },
    
    -- Balance indicators
    balance = {
        quit_point_threshold = 0.15, -- 15% quit rate at any level triggers review
        frustration_threshold = 3,   -- 3+ frustration events per session
        flow_state_target = 0.6,     -- 60% of session should be in flow
        difficulty_satisfaction_min = 3.5 -- Out of 5
    },
    
    -- Progression satisfaction
    progression = {
        xp_rate_target = {min = 120, max = 300}, -- XP per minute
        level_time_target = {min = 300, max = 900}, -- Seconds per level
        reward_frequency_ideal = 180, -- Reward every 3 minutes
        progression_satisfaction_min = 4.0
    },
    
    -- Sentiment thresholds
    sentiment = {
        satisfaction_critical = 3.0, -- Below this triggers immediate review
        satisfaction_warning = 3.5,  -- Below this triggers investigation
        sentiment_trend_threshold = 0.5 -- Trend change that triggers alert
    }
}

-- Behavioral pattern detection
FeedbackAnalyzer.behaviorPatterns = {
    player_segments = {},
    common_journeys = {},
    drop_off_points = {},
    engagement_drivers = {}
}

-- Initialize feedback analysis pipeline
function FeedbackAnalyzer.init()
    FeedbackAnalyzer.isActive = true
    FeedbackAnalyzer.lastAnalysisTime = love.timer.getTime()
    
    -- Load historical insights
    FeedbackAnalyzer.loadHistoricalInsights()
    
    -- Initialize analysis modules
    FeedbackAnalyzer.initializeAnalysisModules()
    
    Utils.Logger.info("🔍 Feedback Analysis Pipeline initialized")
    return true
end

-- Initialize analysis modules
function FeedbackAnalyzer.initializeAnalysisModules()
    -- Set up statistical analysis tools
    FeedbackAnalyzer.setupStatisticalAnalysis()
    
    -- Initialize pattern recognition
    FeedbackAnalyzer.initializePatternRecognition()
    
    -- Set up predictive modeling
    FeedbackAnalyzer.initializePredictiveModels()
end

-- Set up statistical analysis tools
function FeedbackAnalyzer.setupStatisticalAnalysis()
    -- Chi-square test implementation
    FeedbackAnalyzer.chiSquareTest = function(observed, expected)
        local chiSquare = 0
        local df = #observed - 1
        
        for i = 1, #observed do
            if expected[i] > 0 then
                chiSquare = chiSquare + ((observed[i] - expected[i])^2) / expected[i]
            end
        end
        
        -- Simplified p-value calculation (would use proper lookup table in production)
        local pValue = chiSquare > 3.841 and 0.05 or 0.1 -- Rough approximation
        
        return {
            chi_square = chiSquare,
            degrees_of_freedom = df,
            p_value = pValue,
            significant = pValue < 0.05
        }
    end
    
    -- T-test implementation for comparing means
    FeedbackAnalyzer.tTest = function(sample1, sample2)
        local function mean(data)
            local sum = 0
            for _, v in ipairs(data) do sum = sum + v end
            return sum / #data
        end
        
        local function variance(data, mean_val)
            local sum = 0
            for _, v in ipairs(data) do sum = sum + (v - mean_val)^2 end
            return sum / (#data - 1)
        end
        
        local mean1, mean2 = mean(sample1), mean(sample2)
        local var1, var2 = variance(sample1, mean1), variance(sample2, mean2)
        local n1, n2 = #sample1, #sample2
        
        local pooledVar = ((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2)
        local standardError = math.sqrt(pooledVar * (1/n1 + 1/n2))
        local tStatistic = (mean1 - mean2) / standardError
        
        -- Simplified significance test
        local significant = math.abs(tStatistic) > 2.0
        
        return {
            t_statistic = tStatistic,
            p_value = significant and 0.04 or 0.2, -- Rough approximation
            significant = significant,
            effect_size = math.abs(mean1 - mean2) / math.sqrt(pooledVar)
        }
    end
end

-- Initialize pattern recognition systems
function FeedbackAnalyzer.initializePatternRecognition()
    -- Player journey analysis
    FeedbackAnalyzer.analyzePlayerJourneys = function(sessionData)
        local journeys = {}
        local commonPaths = {}
        
        -- Analyze session progression patterns
        for _, session in ipairs(sessionData) do
            if session.events then
                local journey = {}
                for _, event in ipairs(session.events) do
                    table.insert(journey, event.name)
                end
                table.insert(journeys, journey)
            end
        end
        
        -- Find common sequences
        local sequenceCounts = {}
        for _, journey in ipairs(journeys) do
            for i = 1, #journey - 2 do
                local sequence = journey[i] .. "->" .. journey[i+1] .. "->" .. journey[i+2]
                sequenceCounts[sequence] = (sequenceCounts[sequence] or 0) + 1
            end
        end
        
        -- Extract most common paths
        for sequence, count in pairs(sequenceCounts) do
            if count >= 3 then -- Minimum 3 occurrences
                table.insert(commonPaths, {sequence = sequence, frequency = count})
            end
        end
        
        table.sort(commonPaths, function(a, b) return a.frequency > b.frequency end)
        
        return {
            total_journeys = #journeys,
            common_paths = commonPaths,
            unique_patterns = FeedbackAnalyzer.countUniquePatterns(journeys)
        }
    end
    
    -- Quit point analysis
    FeedbackAnalyzer.analyzeQuitPoints = function(quitData)
        local quitsByLevel = {}
        local quitsByContext = {}
        
        for level, quitCount in pairs(quitData) do
            if quitCount > 0 then
                quitsByLevel[level] = quitCount
            end
        end
        
        -- Find levels with high quit rates
        local totalQuits = 0
        for _, count in pairs(quitsByLevel) do
            totalQuits = totalQuits + count
        end
        
        local problematicLevels = {}
        for level, count in pairs(quitsByLevel) do
            local quitRate = count / totalQuits
            if quitRate > FeedbackAnalyzer.patterns.balance.quit_point_threshold then
                table.insert(problematicLevels, {level = level, quit_rate = quitRate, quit_count = count})
            end
        end
        
        table.sort(problematicLevels, function(a, b) return a.quit_rate > b.quit_rate end)
        
        return {
            total_quits = totalQuits,
            problematic_levels = problematicLevels,
            quit_distribution = quitsByLevel
        }
    end
end

-- Initialize predictive modeling
function FeedbackAnalyzer.initializePredictiveModels()
    -- Churn prediction model
    FeedbackAnalyzer.predictChurn = function(playerData)
        local churnRiskScore = 0
        local indicators = {}
        
        -- Session frequency indicator
        if playerData.sessions_per_day < 0.5 then
            churnRiskScore = churnRiskScore + 0.3
            table.insert(indicators, "low_session_frequency")
        end
        
        -- Session length indicator
        if playerData.avg_session_duration < 300 then -- Less than 5 minutes
            churnRiskScore = churnRiskScore + 0.25
            table.insert(indicators, "short_sessions")
        end
        
        -- Progression satisfaction
        if playerData.progression_satisfaction < 3.0 then
            churnRiskScore = churnRiskScore + 0.35
            table.insert(indicators, "progression_dissatisfaction")
        end
        
        -- Frustration events
        if playerData.frustration_events_per_session > 2 then
            churnRiskScore = churnRiskScore + 0.2
            table.insert(indicators, "high_frustration")
        end
        
        -- Recent performance issues
        if playerData.recent_crashes > 0 or playerData.avg_fps < 30 then
            churnRiskScore = churnRiskScore + 0.15
            table.insert(indicators, "technical_issues")
        end
        
        local riskLevel = "low"
        if churnRiskScore > 0.7 then riskLevel = "high"
        elseif churnRiskScore > 0.4 then riskLevel = "medium"
        end
        
        return {
            risk_score = churnRiskScore,
            risk_level = riskLevel,
            indicators = indicators,
            recommendations = FeedbackAnalyzer.generateRetentionRecommendations(indicators)
        }
    end
    
    -- Engagement optimization recommendations
    FeedbackAnalyzer.predictEngagementOptimizations = function(playerData)
        local recommendations = {}
        
        -- XP rate optimization
        if playerData.xp_per_minute < FeedbackAnalyzer.patterns.progression.xp_rate_target.min then
            table.insert(recommendations, {
                type = "xp_rate_increase",
                confidence = 0.8,
                expected_impact = "medium",
                description = "Increase XP rates to improve progression satisfaction"
            })
        end
        
        -- Event frequency optimization
        if playerData.event_satisfaction < 3.5 then
            table.insert(recommendations, {
                type = "event_frequency_adjustment",
                confidence = 0.7,
                expected_impact = "medium",
                description = "Adjust event frequency to reduce overwhelm"
            })
        end
        
        -- Difficulty curve optimization
        if playerData.difficulty_satisfaction < 3.5 then
            table.insert(recommendations, {
                type = "difficulty_adjustment",
                confidence = 0.9,
                expected_impact = "high",
                description = "Adjust difficulty curve to improve flow state"
            })
        end
        
        return recommendations
    end
end

-- Main analysis update function
function FeedbackAnalyzer.update(dt)
    if not FeedbackAnalyzer.isActive then return end
    
    local currentTime = love.timer.getTime()
    
    -- Run analysis periodically
    if currentTime - FeedbackAnalyzer.lastAnalysisTime >= FeedbackAnalyzer.analysisInterval then
        FeedbackAnalyzer.runCompleteAnalysis()
        FeedbackAnalyzer.lastAnalysisTime = currentTime
    end
end

-- Run complete analysis pipeline
function FeedbackAnalyzer.runCompleteAnalysis()
    Utils.Logger.info("🔍 Running complete feedback analysis...")
    
    -- Gather data from all systems
    local analyticsData = FeedbackAnalyzer.gatherAnalyticsData()
    local feedbackData = FeedbackAnalyzer.gatherFeedbackData()
    local performanceData = FeedbackAnalyzer.gatherPerformanceData()
    
    -- Run individual analysis modules
    FeedbackAnalyzer.analyzeEngagement(analyticsData)
    FeedbackAnalyzer.analyzeBalance(analyticsData, feedbackData)
    FeedbackAnalyzer.analyzeProgression(analyticsData, feedbackData)
    FeedbackAnalyzer.analyzeSentiment(feedbackData)
    FeedbackAnalyzer.analyzePerformance(performanceData)
    FeedbackAnalyzer.analyzeBehavior(analyticsData)
    
    -- Generate comprehensive insights report
    FeedbackAnalyzer.generateInsightsReport()
    
    -- Check for automatic interventions
    FeedbackAnalyzer.checkAutoInterventions()
    
    -- Save insights
    FeedbackAnalyzer.saveInsights()
    
    Utils.Logger.info("🔍 Analysis complete - %d insights generated", 
                     FeedbackAnalyzer.countTotalInsights())
end

-- Gather analytics data from feedback analytics system
function FeedbackAnalyzer.gatherAnalyticsData()
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics then
        return FeedbackAnalytics.getAnalyticsReport()
    end
    return nil
end

-- Gather feedback data from forms system
function FeedbackAnalyzer.gatherFeedbackData()
    local FeedbackForms = Utils.require("src.systems.feedback_forms_system")
    if FeedbackForms then
        return FeedbackForms.exportFeedbackData()
    end
    return nil
end

-- Gather performance data
function FeedbackAnalyzer.gatherPerformanceData()
    local PerformanceMonitoring = Utils.require("src.systems.performance_monitoring_system")
    if PerformanceMonitoring then
        return PerformanceMonitoring.getPerformanceReport()
    end
    return nil
end

-- Analyze engagement metrics
function FeedbackAnalyzer.analyzeEngagement(data)
    if not data or not data.metrics then return end
    
    local engagement = data.metrics.engagement
    local insights = {}
    
    -- Session duration analysis
    if engagement.session_duration then
        local ideal = FeedbackAnalyzer.patterns.engagement.session_length_ideal
        if engagement.session_duration < ideal.min then
            table.insert(insights, {
                type = "session_too_short",
                severity = "medium",
                metric = engagement.session_duration,
                target = ideal.min,
                recommendation = "Improve early engagement hooks to extend sessions"
            })
        elseif engagement.session_duration > ideal.max then
            table.insert(insights, {
                type = "session_too_long",
                severity = "low",
                metric = engagement.session_duration,
                target = ideal.max,
                recommendation = "Consider adding natural break points"
            })
        end
    end
    
    -- Daily playtime analysis
    if engagement.daily_playtime and engagement.total_sessions then
        local avgSessionLength = engagement.daily_playtime / engagement.total_sessions
        if avgSessionLength < 300 then -- Less than 5 minutes per session
            table.insert(insights, {
                type = "low_session_engagement",
                severity = "high",
                metric = avgSessionLength,
                recommendation = "Investigate early session drop-off causes"
            })
        end
    end
    
    FeedbackAnalyzer.insights.engagement_insights = insights
end

-- Analyze game balance
function FeedbackAnalyzer.analyzeBalance(analyticsData, feedbackData)
    local insights = {}
    
    -- Analyze difficulty satisfaction from feedback
    if feedbackData and feedbackData.statistics then
        local difficultyScores = feedbackData.statistics.sentiment_scores.difficulty
        if #difficultyScores > 0 then
            local avgDifficulty = FeedbackAnalyzer.calculateMean(difficultyScores)
            if avgDifficulty < FeedbackAnalyzer.patterns.balance.difficulty_satisfaction_min then
                table.insert(insights, {
                    type = "difficulty_dissatisfaction",
                    severity = "high",
                    metric = avgDifficulty,
                    target = FeedbackAnalyzer.patterns.balance.difficulty_satisfaction_min,
                    recommendation = "Adjust difficulty curve or add adaptive difficulty"
                })
            end
        end
    end
    
    -- Analyze quit points
    if analyticsData and analyticsData.metrics and analyticsData.metrics.difficulty then
        local quitAnalysis = FeedbackAnalyzer.analyzeQuitPoints(analyticsData.metrics.difficulty.quit_points_by_level)
        if #quitAnalysis.problematic_levels > 0 then
            for _, level in ipairs(quitAnalysis.problematic_levels) do
                table.insert(insights, {
                    type = "high_quit_rate",
                    severity = "high",
                    level = level.level,
                    quit_rate = level.quit_rate,
                    recommendation = string.format("Review level %d difficulty - %.1f%% quit rate", 
                                                  level.level, level.quit_rate * 100)
                })
            end
        end
    end
    
    FeedbackAnalyzer.insights.balance_insights = insights
end

-- Analyze progression satisfaction
function FeedbackAnalyzer.analyzeProgression(analyticsData, feedbackData)
    local insights = {}
    
    if analyticsData and analyticsData.metrics and analyticsData.metrics.progression then
        local progression = analyticsData.metrics.progression
        
        -- XP rate analysis
        if progression.xp_per_minute then
            local target = FeedbackAnalyzer.patterns.progression.xp_rate_target
            if progression.xp_per_minute < target.min then
                table.insert(insights, {
                    type = "xp_rate_too_low",
                    severity = "medium",
                    metric = progression.xp_per_minute,
                    target = target.min,
                    recommendation = "Increase XP rates or add XP bonus events"
                })
            elseif progression.xp_per_minute > target.max then
                table.insert(insights, {
                    type = "xp_rate_too_high",
                    severity = "low",
                    metric = progression.xp_per_minute,
                    target = target.max,
                    recommendation = "Consider reducing XP inflation"
                })
            end
        end
        
        -- Progression satisfaction from feedback
        if feedbackData and feedbackData.statistics then
            local progressionScores = feedbackData.statistics.sentiment_scores.progression
            if #progressionScores > 0 then
                local avgSatisfaction = FeedbackAnalyzer.calculateMean(progressionScores)
                if avgSatisfaction < FeedbackAnalyzer.patterns.progression.progression_satisfaction_min then
                    table.insert(insights, {
                        type = "progression_dissatisfaction",
                        severity = "high",
                        metric = avgSatisfaction,
                        target = FeedbackAnalyzer.patterns.progression.progression_satisfaction_min,
                        recommendation = "Improve progression rewards and pacing"
                    })
                end
            end
        end
    end
    
    FeedbackAnalyzer.insights.progression_insights = insights
end

-- Analyze sentiment trends
function FeedbackAnalyzer.analyzeSentiment(feedbackData)
    local insights = {}
    
    if feedbackData and feedbackData.statistics then
        local stats = feedbackData.statistics
        
        -- Overall satisfaction analysis
        if #stats.sentiment_scores.overall > 0 then
            local avgOverall = FeedbackAnalyzer.calculateMean(stats.sentiment_scores.overall)
            
            if avgOverall < FeedbackAnalyzer.patterns.sentiment.satisfaction_critical then
                table.insert(insights, {
                    type = "critical_satisfaction",
                    severity = "critical",
                    metric = avgOverall,
                    target = FeedbackAnalyzer.patterns.sentiment.satisfaction_critical,
                    recommendation = "Immediate intervention required - low player satisfaction"
                })
            elseif avgOverall < FeedbackAnalyzer.patterns.sentiment.satisfaction_warning then
                table.insert(insights, {
                    type = "low_satisfaction",
                    severity = "high",
                    metric = avgOverall,
                    target = FeedbackAnalyzer.patterns.sentiment.satisfaction_warning,
                    recommendation = "Investigate causes of player dissatisfaction"
                })
            end
        end
        
        -- Event satisfaction analysis
        if #stats.sentiment_scores.events > 0 then
            local avgEvents = FeedbackAnalyzer.calculateMean(stats.sentiment_scores.events)
            if avgEvents < 3.0 then
                table.insert(insights, {
                    type = "event_dissatisfaction",
                    severity = "medium",
                    metric = avgEvents,
                    recommendation = "Review event frequency and variety"
                })
            end
        end
    end
    
    FeedbackAnalyzer.insights.sentiment_insights = insights
end

-- Analyze performance issues
function FeedbackAnalyzer.analyzePerformance(performanceData)
    local insights = {}
    
    if performanceData then
        -- FPS analysis
        if performanceData.fps then
            if performanceData.fps.average < 45 then
                table.insert(insights, {
                    type = "low_fps",
                    severity = "high",
                    metric = performanceData.fps.average,
                    target = 60,
                    recommendation = "Optimize rendering and particle systems"
                })
            end
            
            if performanceData.fps.frame_drops > 10 then
                table.insert(insights, {
                    type = "frequent_frame_drops",
                    severity = "medium",
                    metric = performanceData.fps.frame_drops,
                    recommendation = "Investigate frame drop causes"
                })
            end
        end
        
        -- Memory analysis
        if performanceData.memory then
            if performanceData.memory.peak_mb > 256 then
                table.insert(insights, {
                    type = "high_memory_usage",
                    severity = "medium",
                    metric = performanceData.memory.peak_mb,
                    target = 256,
                    recommendation = "Optimize memory usage and garbage collection"
                })
            end
        end
        
        -- Error analysis
        if performanceData.errors then
            if performanceData.errors.crashes > 0 then
                table.insert(insights, {
                    type = "crashes_detected",
                    severity = "critical",
                    metric = performanceData.errors.crashes,
                    target = 0,
                    recommendation = "Fix crash-causing bugs immediately"
                })
            end
        end
    end
    
    FeedbackAnalyzer.insights.performance_insights = insights
end

-- Analyze player behavior patterns
function FeedbackAnalyzer.analyzeBehavior(analyticsData)
    local insights = {}
    
    if analyticsData and analyticsData.metrics then
        -- Streak behavior analysis
        if analyticsData.metrics.addiction then
            local addiction = analyticsData.metrics.addiction
            
            if addiction.streak_recovery_rate and addiction.streak_recovery_rate < 0.5 then
                table.insert(insights, {
                    type = "low_streak_recovery",
                    severity = "medium",
                    metric = addiction.streak_recovery_rate,
                    recommendation = "Improve streak recovery mechanics or reduce pressure"
                })
            end
            
            if addiction.grace_period_usage and addiction.grace_period_usage > 0.8 then
                table.insert(insights, {
                    type = "high_grace_period_usage",
                    severity = "low",
                    metric = addiction.grace_period_usage,
                    recommendation = "Players rely heavily on grace periods - consider balance"
                })
            end
        end
    end
    
    FeedbackAnalyzer.insights.behavioral_insights = insights
end

-- Generate comprehensive insights report
function FeedbackAnalyzer.generateInsightsReport()
    local totalInsights = FeedbackAnalyzer.countTotalInsights()
    local criticalIssues = FeedbackAnalyzer.countCriticalIssues()
    
    local report = {
        timestamp = love.timer.getTime(),
        total_insights = totalInsights,
        critical_issues = criticalIssues,
        insights_by_category = {
            engagement = #FeedbackAnalyzer.insights.engagement_insights,
            balance = #FeedbackAnalyzer.insights.balance_insights,
            progression = #FeedbackAnalyzer.insights.progression_insights,
            sentiment = #FeedbackAnalyzer.insights.sentiment_insights,
            performance = #FeedbackAnalyzer.insights.performance_insights,
            behavioral = #FeedbackAnalyzer.insights.behavioral_insights
        },
        top_recommendations = FeedbackAnalyzer.getTopRecommendations()
    }
    
    -- Send report to analytics
    local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
    if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
        FeedbackAnalytics.trackEvent("insights_report_generated", report)
    end
    
    Utils.Logger.info("🔍 Insights report generated: %d total insights, %d critical", 
                     totalInsights, criticalIssues)
    
    return report
end

-- Check for automatic interventions
function FeedbackAnalyzer.checkAutoInterventions()
    local interventions = {}
    
    -- Check all insights for auto-intervention triggers
    local allInsights = FeedbackAnalyzer.getAllInsights()
    
    for _, insight in ipairs(allInsights) do
        if insight.severity == "critical" then
            local intervention = FeedbackAnalyzer.createIntervention(insight)
            if intervention then
                table.insert(interventions, intervention)
            end
        end
    end
    
    -- Execute interventions
    for _, intervention in ipairs(interventions) do
        FeedbackAnalyzer.executeIntervention(intervention)
    end
    
    return interventions
end

-- Create intervention from insight
function FeedbackAnalyzer.createIntervention(insight)
    local DynamicConfig = Utils.require("src.systems.dynamic_config_system")
    if not DynamicConfig then return nil end
    
    local intervention = {
        type = insight.type,
        action = nil,
        parameters = {}
    }
    
    if insight.type == "critical_satisfaction" then
        intervention.action = "reduce_difficulty"
        intervention.parameters = {difficulty_scaling = 0.8}
    elseif insight.type == "crashes_detected" then
        intervention.action = "enable_safe_mode"
        intervention.parameters = {particle_intensity = 0.3, screen_glow_intensity = 0.2}
    elseif insight.type == "low_fps" then
        intervention.action = "optimize_performance"
        intervention.parameters = {particle_intensity = 0.5, animation_speed = 0.8}
    elseif insight.type == "xp_rate_too_low" then
        intervention.action = "increase_xp_rates"
        intervention.parameters = {xp_source_multipliers = {perfect_landing = 1.2, combo_ring = 1.1}}
    end
    
    return intervention.action and intervention or nil
end

-- Execute intervention
function FeedbackAnalyzer.executeIntervention(intervention)
    local DynamicConfig = Utils.require("src.systems.dynamic_config_system")
    if not DynamicConfig then return false end
    
    local success = false
    
    if intervention.action == "reduce_difficulty" then
        DynamicConfig.applyConfigurationBatch(intervention.parameters, "auto_intervention")
        success = true
    elseif intervention.action == "enable_safe_mode" then
        DynamicConfig.applyConfigurationBatch(intervention.parameters, "performance_intervention")
        success = true
    elseif intervention.action == "optimize_performance" then
        DynamicConfig.applyConfigurationBatch(intervention.parameters, "fps_intervention")
        success = true
    elseif intervention.action == "increase_xp_rates" then
        DynamicConfig.applyConfigurationBatch(intervention.parameters, "progression_intervention")
        success = true
    end
    
    if success then
        Utils.Logger.info("🔧 Auto-intervention executed: %s", intervention.action)
        
        -- Track intervention
        local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
        if FeedbackAnalytics and FeedbackAnalytics.trackEvent then
            FeedbackAnalytics.trackEvent("auto_intervention", intervention)
        end
    end
    
    return success
end

-- Utility functions
function FeedbackAnalyzer.calculateMean(data)
    if #data == 0 then return 0 end
    local sum = 0
    for _, value in ipairs(data) do
        sum = sum + value
    end
    return sum / #data
end

function FeedbackAnalyzer.countUniquePatterns(patterns)
    local unique = {}
    for _, pattern in ipairs(patterns) do
        local key = table.concat(pattern, "->")
        unique[key] = true
    end
    local count = 0
    for _ in pairs(unique) do count = count + 1 end
    return count
end

function FeedbackAnalyzer.countTotalInsights()
    local total = 0
    for _, category in pairs(FeedbackAnalyzer.insights) do
        total = total + #category
    end
    return total
end

function FeedbackAnalyzer.countCriticalIssues()
    local critical = 0
    for _, category in pairs(FeedbackAnalyzer.insights) do
        for _, insight in ipairs(category) do
            if insight.severity == "critical" then
                critical = critical + 1
            end
        end
    end
    return critical
end

function FeedbackAnalyzer.getAllInsights()
    local allInsights = {}
    for _, category in pairs(FeedbackAnalyzer.insights) do
        for _, insight in ipairs(category) do
            table.insert(allInsights, insight)
        end
    end
    return allInsights
end

function FeedbackAnalyzer.getTopRecommendations()
    local recommendations = {}
    for _, category in pairs(FeedbackAnalyzer.insights) do
        for _, insight in ipairs(category) do
            if insight.recommendation then
                table.insert(recommendations, {
                    severity = insight.severity,
                    recommendation = insight.recommendation,
                    category = insight.type
                })
            end
        end
    end
    
    -- Sort by severity
    table.sort(recommendations, function(a, b)
        local severityOrder = {critical = 4, high = 3, medium = 2, low = 1}
        return (severityOrder[a.severity] or 0) > (severityOrder[b.severity] or 0)
    end)
    
    -- Return top 5
    local top = {}
    for i = 1, math.min(5, #recommendations) do
        table.insert(top, recommendations[i])
    end
    
    return top
end

function FeedbackAnalyzer.generateRetentionRecommendations(indicators)
    local recommendations = {}
    
    for _, indicator in ipairs(indicators) do
        if indicator == "low_session_frequency" then
            table.insert(recommendations, "Add daily login bonuses")
        elseif indicator == "short_sessions" then
            table.insert(recommendations, "Improve onboarding and early hooks")
        elseif indicator == "progression_dissatisfaction" then
            table.insert(recommendations, "Increase progression rewards")
        elseif indicator == "high_frustration" then
            table.insert(recommendations, "Adjust difficulty or add assistance")
        elseif indicator == "technical_issues" then
            table.insert(recommendations, "Fix performance problems")
        end
    end
    
    return recommendations
end

-- Save insights to persistent storage
function FeedbackAnalyzer.saveInsights()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("feedbackInsights", {
            insights = FeedbackAnalyzer.insights,
            last_analysis = FeedbackAnalyzer.lastAnalysisTime,
            analysis_count = (SaveSystem.getData("feedbackInsights") and 
                             SaveSystem.getData("feedbackInsights").analysis_count or 0) + 1
        })
    end
end

-- Load historical insights
function FeedbackAnalyzer.loadHistoricalInsights()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local data = SaveSystem.getData("feedbackInsights")
        if data and data.insights then
            -- Keep some historical context but don't restore all insights
            Utils.Logger.info("🔍 Historical insights data loaded")
        end
    end
end

-- Get comprehensive analysis report
function FeedbackAnalyzer.getAnalysisReport()
    return {
        insights = FeedbackAnalyzer.insights,
        statistics = FeedbackAnalyzer.statistics,
        patterns = FeedbackAnalyzer.patterns,
        last_analysis = FeedbackAnalyzer.lastAnalysisTime,
        total_insights = FeedbackAnalyzer.countTotalInsights(),
        critical_issues = FeedbackAnalyzer.countCriticalIssues()
    }
end

return FeedbackAnalyzer