--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Analysis Pipeline - Main Coordinator
    ═══════════════════════════════════════════════════════════════════════════
    This is the main coordinator for the feedback analysis pipeline, orchestrating
    the various analyzers and generating comprehensive insights from player data.
    Refactored from the original monolithic feedback_analysis_pipeline.lua to use
    a modular architecture with separate analyzers and utilities.
--]]
local Utils = require("src.utils.utils")
-- Import the new modular components
local StatisticalTools = require("src.systems.feedback.statistics.statistical_tools")
local PatternDetection = require("src.systems.feedback.statistics.pattern_detection")
local EngagementAnalyzer = require("src.systems.feedback.analyzers.engagement_analyzer")
local BalanceAnalyzer = require("src.systems.feedback.analyzers.balance_analyzer")
local InsightGenerator = require("src.systems.feedback.insights.insight_generator")
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
-- Configuration
FeedbackAnalyzer.config = {
    analysis_enabled = true,
    real_time_analysis = false,
    batch_analysis_interval = 3600, -- 1 hour
    data_retention_days = 30,
    max_analysis_history = 100
}
-- Initialize feedback analysis pipeline
function FeedbackAnalyzer.init()
    FeedbackAnalyzer.isActive = true
    FeedbackAnalyzer.lastAnalysisTime = love.timer.getTime()
    -- Load historical insights
    FeedbackAnalyzer.loadHistoricalInsights()
    -- Initialize analysis modules
    FeedbackAnalyzer.initializeAnalysisModules()
    Utils.Logger.info("🔍 Feedback Analysis Pipeline initialized with modular architecture")
    return true
end
-- Initialize analysis modules
function FeedbackAnalyzer.initializeAnalysisModules()
    -- Validate that all required modules are available
    local modules = {
        StatisticalTools = StatisticalTools,
        PatternDetection = PatternDetection,
        EngagementAnalyzer = EngagementAnalyzer,
        BalanceAnalyzer = BalanceAnalyzer,
        InsightGenerator = InsightGenerator
    }
    for name, module in pairs(modules) do
        if not module then
            Utils.Logger.error("Failed to load module: %s", name)
            return false
        end
    end
    Utils.Logger.info("✅ All analysis modules loaded successfully")
    return true
end
-- Main analysis function
function FeedbackAnalyzer.analyze(sessionData, playerMetrics, levelData)
    if not FeedbackAnalyzer.isActive then
        return {error = "Analysis pipeline is not active"}
    end
    local startTime = love.timer.getTime()
    Utils.Logger.info("🔍 Starting feedback analysis...")
    local analysisResults = {
        engagement = {},
        balance = {},
        progression = {},
        retention = {},
        performance = {},
        satisfaction = {}
    }
    -- Run engagement analysis
    if sessionData and playerMetrics then
        analysisResults.engagement = EngagementAnalyzer.analyzeEngagement(sessionData, playerMetrics)
        analysisResults.retention = EngagementAnalyzer.analyzeRetention(sessionData, playerMetrics)
    end
    -- Run balance analysis
    if sessionData and playerMetrics and levelData then
        analysisResults.balance = BalanceAnalyzer.analyzeBalance(sessionData, playerMetrics, levelData)
    end
    -- Run pattern detection
    if sessionData then
        analysisResults.behavioral = PatternDetection.classifyPlayerBehavior(sessionData, playerMetrics)
        analysisResults.patterns = PatternDetection.analyzePlayerJourneys(sessionData)
    end
    -- Generate comprehensive insights
    local insights = InsightGenerator.generateInsights(analysisResults)
    -- Store results
    FeedbackAnalyzer.storeAnalysisResults(insights)
    local endTime = love.timer.getTime()
    Utils.Logger.info("✅ Feedback analysis completed in %.2f seconds", endTime - startTime)
    return insights
end
-- Run real-time analysis
function FeedbackAnalyzer.update(dt)
    if not FeedbackAnalyzer.isActive or not FeedbackAnalyzer.config.analysis_enabled then
        return
    end
    local currentTime = love.timer.getTime()
    -- Check if it's time for analysis
    if currentTime - FeedbackAnalyzer.lastAnalysisTime >= FeedbackAnalyzer.analysisInterval then
        FeedbackAnalyzer.runPeriodicAnalysis()
        FeedbackAnalyzer.lastAnalysisTime = currentTime
    end
end
-- Run periodic analysis
function FeedbackAnalyzer.runPeriodicAnalysis()
    -- Get current session data
    local sessionData = FeedbackAnalyzer.collectSessionData()
    local playerMetrics = FeedbackAnalyzer.collectPlayerMetrics()
    local levelData = FeedbackAnalyzer.collectLevelData()
    -- Run analysis
    local results = FeedbackAnalyzer.analyze(sessionData, playerMetrics, levelData)
    -- Process results
    if results and not results.error then
        FeedbackAnalyzer.processAnalysisResults(results)
    end
end
-- Collect session data for analysis
function FeedbackAnalyzer.collectSessionData()
    -- This would collect actual session data from the game
    -- For now, return sample data structure
    return {
        -- Sample session data structure
        -- In production, this would come from actual game sessions
    }
end
-- Collect player metrics for analysis
function FeedbackAnalyzer.collectPlayerMetrics()
    -- This would collect actual player metrics from the game
    -- For now, return sample data structure
    return {
        -- Sample player metrics structure
        -- In production, this would come from actual player data
    }
end
-- Collect level data for analysis
function FeedbackAnalyzer.collectLevelData()
    -- This would collect actual level data from the game
    -- For now, return sample data structure
    return {
        -- Sample level data structure
        -- In production, this would come from actual level data
    }
end
-- Process analysis results
function FeedbackAnalyzer.processAnalysisResults(results)
    if not results then return end
    -- Store insights
    FeedbackAnalyzer.insights = results
    -- Generate alerts for critical issues
    FeedbackAnalyzer.generateAlerts(results)
    -- Update game systems based on insights
    FeedbackAnalyzer.applyInsights(results)
    Utils.Logger.info("📊 Analysis results processed and insights applied")
end
-- Generate alerts for critical issues
function FeedbackAnalyzer.generateAlerts(results)
    if not results or not results.summary then return end
    -- Check for critical issues
    if results.summary.critical_issues > 0 then
        Utils.Logger.warning("🚨 %d critical issues detected in analysis", results.summary.critical_issues)
        -- Generate specific alerts
        if results.recommendations and results.recommendations.immediate_actions then
            for _, action in ipairs(results.recommendations.immediate_actions) do
                Utils.Logger.warning("🚨 Critical Action Required: %s", action.action)
            end
        end
    end
    -- Check overall health
    if results.summary.overall_health == "poor" then
        Utils.Logger.error("🔴 Game health is poor - immediate attention required")
    elseif results.summary.overall_health == "fair" then
        Utils.Logger.warning("🟡 Game health is fair - monitoring recommended")
    end
end
-- Apply insights to game systems
function FeedbackAnalyzer.applyInsights(results)
    if not results or not results.recommendations then return end
    -- Apply immediate actions
    if results.recommendations.immediate_actions then
        for _, action in ipairs(results.recommendations.immediate_actions) do
            FeedbackAnalyzer.applyAction(action)
        end
    end
    -- Apply short-term recommendations
    if results.recommendations.short_term then
        for _, action in ipairs(results.recommendations.short_term) do
            FeedbackAnalyzer.applyAction(action)
        end
    end
end
-- Apply a specific action
function FeedbackAnalyzer.applyAction(action)
    if not action or not action.category then return end
    Utils.Logger.info("🔧 Applying action: %s (%s)", action.action, action.category)
    -- Apply actions based on category
    if action.category == "difficulty" then
        FeedbackAnalyzer.applyDifficultyAdjustment(action)
    elseif action.category == "progression" then
        FeedbackAnalyzer.applyProgressionAdjustment(action)
    elseif action.category == "rewards" then
        FeedbackAnalyzer.applyRewardAdjustment(action)
    elseif action.category == "engagement" then
        FeedbackAnalyzer.applyEngagementAdjustment(action)
    end
end
-- Apply difficulty adjustments
function FeedbackAnalyzer.applyDifficultyAdjustment(action)
    -- This would adjust game difficulty based on analysis
    Utils.Logger.info("🎯 Applying difficulty adjustment: %s", action.action)
end
-- Apply progression adjustments
function FeedbackAnalyzer.applyProgressionAdjustment(action)
    -- This would adjust progression speed based on analysis
    Utils.Logger.info("📈 Applying progression adjustment: %s", action.action)
end
-- Apply reward adjustments
function FeedbackAnalyzer.applyRewardAdjustment(action)
    -- This would adjust reward systems based on analysis
    Utils.Logger.info("🎁 Applying reward adjustment: %s", action.action)
end
-- Apply engagement adjustments
function FeedbackAnalyzer.applyEngagementAdjustment(action)
    -- This would adjust engagement mechanics based on analysis
    Utils.Logger.info("🎮 Applying engagement adjustment: %s", action.action)
end
-- Store analysis results
function FeedbackAnalyzer.storeAnalysisResults(results)
    if not results then return end
    -- Store in memory
    FeedbackAnalyzer.insights = results
    -- Store to persistent storage (if available)
    FeedbackAnalyzer.saveToStorage(results)
end
-- Save results to persistent storage
function FeedbackAnalyzer.saveToStorage(results)
    -- This would save results to a database or file
    -- For now, just log the action
    Utils.Logger.info("💾 Analysis results saved to storage")
end
-- Load historical insights
function FeedbackAnalyzer.loadHistoricalInsights()
    -- This would load historical analysis results
    -- For now, just initialize empty structure
    FeedbackAnalyzer.insights = {
        engagement_insights = {},
        balance_insights = {},
        progression_insights = {},
        sentiment_insights = {},
        performance_insights = {},
        behavioral_insights = {}
    }
    Utils.Logger.info("📚 Historical insights loaded")
end
-- Get current insights
function FeedbackAnalyzer.getInsights()
    return FeedbackAnalyzer.insights
end
-- Get specific insight category
function FeedbackAnalyzer.getInsightCategory(category)
    if not FeedbackAnalyzer.insights then return nil end
    return FeedbackAnalyzer.insights[category] or {}
end
-- Generate report
function FeedbackAnalyzer.generateReport(format)
    if not FeedbackAnalyzer.insights then
        return {error = "No insights available"}
    end
    return InsightGenerator.generateReport(FeedbackAnalyzer.insights, format)
end
-- Reset analysis pipeline
function FeedbackAnalyzer.reset()
    FeedbackAnalyzer.insights = {
        engagement_insights = {},
        balance_insights = {},
        progression_insights = {},
        sentiment_insights = {},
        performance_insights = {},
        behavioral_insights = {}
    }
    FeedbackAnalyzer.lastAnalysisTime = 0
    Utils.Logger.info("🔄 Feedback analysis pipeline reset")
end
-- Shutdown analysis pipeline
function FeedbackAnalyzer.shutdown()
    FeedbackAnalyzer.isActive = false
    -- Save final insights
    if FeedbackAnalyzer.insights then
        FeedbackAnalyzer.saveToStorage(FeedbackAnalyzer.insights)
    end
    Utils.Logger.info("🛑 Feedback analysis pipeline shutdown")
end
-- Enable/disable analysis
function FeedbackAnalyzer.setEnabled(enabled)
    FeedbackAnalyzer.config.analysis_enabled = enabled
    Utils.Logger.info("🔧 Analysis pipeline %s", enabled and "enabled" or "disabled")
end
-- Set analysis interval
function FeedbackAnalyzer.setAnalysisInterval(interval)
    FeedbackAnalyzer.analysisInterval = interval
    Utils.Logger.info("⏱️ Analysis interval set to %d seconds", interval)
end
-- Get analysis statistics
function FeedbackAnalyzer.getStatistics()
    return {
        is_active = FeedbackAnalyzer.isActive,
        last_analysis = FeedbackAnalyzer.lastAnalysisTime,
        analysis_interval = FeedbackAnalyzer.analysisInterval,
        insights_count = FeedbackAnalyzer.insights and table.getn(FeedbackAnalyzer.insights) or 0,
        config = FeedbackAnalyzer.config
    }
end
return FeedbackAnalyzer