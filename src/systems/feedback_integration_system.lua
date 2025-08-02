--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Integration System - Master Orchestrator
    ═══════════════════════════════════════════════════════════════════════════
    
    This system orchestrates all feedback integration components according to
    the Feedback Integration Plan, providing a unified interface and ensuring
    proper coordination between all subsystems.
--]]

local Utils = require("src.utils.utils")

local FeedbackIntegration = {}

-- System state
FeedbackIntegration.isActive = false
FeedbackIntegration.initializationTime = 0
FeedbackIntegration.lastUpdateTime = 0

-- Subsystem references
FeedbackIntegration.subsystems = {
    analytics = nil,
    forms = nil,
    performance = nil,
    config = nil,
    analyzer = nil
}

-- Integration settings
FeedbackIntegration.settings = {
    update_interval = 1.0,      -- Update all systems every second
    auto_analysis_interval = 300, -- Run analysis every 5 minutes
    auto_intervention = true,   -- Enable automatic interventions
    data_sync_interval = 60,    -- Sync data between systems every minute
    
    -- Feature flags
    features = {
        analytics_enabled = true,
        forms_enabled = true,
        performance_monitoring_enabled = true,
        dynamic_config_enabled = true,
        analysis_pipeline_enabled = true,
        auto_optimization_enabled = true
    }
}

-- System health monitoring
FeedbackIntegration.health = {
    subsystem_status = {},
    last_health_check = 0,
    error_count = 0,
    warning_count = 0,
    performance_score = 100
}

-- Data synchronization tracking
FeedbackIntegration.sync = {
    last_sync_time = 0,
    pending_syncs = {},
    sync_errors = {}
}

-- Initialize the complete feedback integration system
function FeedbackIntegration.init()
    local startTime = love.timer.getTime()
    FeedbackIntegration.initializationTime = startTime
    FeedbackIntegration.lastUpdateTime = startTime
    
    Utils.Logger.info("🚀 Initializing Feedback Integration System...")
    
    -- Initialize all subsystems
    local success = FeedbackIntegration.initializeSubsystems()
    if not success then
        Utils.Logger.error("❌ Failed to initialize feedback integration subsystems")
        return false
    end
    
    -- Set up cross-system integrations
    FeedbackIntegration.setupIntegrations()
    
    -- Initialize health monitoring
    FeedbackIntegration.initializeHealthMonitoring()
    
    -- Set up data synchronization
    FeedbackIntegration.initializeDataSync()
    
    -- Mark system as active
    FeedbackIntegration.isActive = true
    
    local initDuration = love.timer.getTime() - startTime
    Utils.Logger.info("✅ Feedback Integration System initialized in %.2fs", initDuration)
    
    -- Track initialization event
    if FeedbackIntegration.subsystems.analytics then
        FeedbackIntegration.subsystems.analytics.trackEvent("feedback_system_initialized", {
            duration = initDuration,
            subsystems_active = FeedbackIntegration.countActiveSubsystems()
        })
    end
    
    return true
end

-- Initialize all subsystems
function FeedbackIntegration.initializeSubsystems()
    local subsystemResults = {}
    
    -- Initialize Feedback Analytics
    if FeedbackIntegration.settings.features.analytics_enabled then
        local FeedbackAnalytics = Utils.require("src.systems.analytics.feedback_analytics")
        if FeedbackAnalytics then
            subsystemResults.analytics = FeedbackAnalytics.init()
            FeedbackIntegration.subsystems.analytics = FeedbackAnalytics
            Utils.Logger.info("📊 Feedback Analytics: %s", subsystemResults.analytics and "✅" or "❌")
        end
    end
    
    -- Initialize Dynamic Configuration
    if FeedbackIntegration.settings.features.dynamic_config_enabled then
        local DynamicConfig = Utils.require("src.systems.dynamic_config_system")
        if DynamicConfig then
            subsystemResults.config = DynamicConfig.init()
            FeedbackIntegration.subsystems.config = DynamicConfig
            Utils.Logger.info("⚙️ Dynamic Config: %s", subsystemResults.config and "✅" or "❌")
        end
    end
    
    -- Initialize Feedback Forms
    if FeedbackIntegration.settings.features.forms_enabled then
        local FeedbackForms = Utils.require("src.systems.feedback_forms_system")
        if FeedbackForms then
            subsystemResults.forms = FeedbackForms.init()
            FeedbackIntegration.subsystems.forms = FeedbackForms
            Utils.Logger.info("📝 Feedback Forms: %s", subsystemResults.forms and "✅" or "❌")
        end
    end
    
    -- Initialize Performance Monitoring
    if FeedbackIntegration.settings.features.performance_monitoring_enabled then
        local PerformanceMonitoring = Utils.require("src.systems.performance_monitoring_system")
        if PerformanceMonitoring then
            subsystemResults.performance = PerformanceMonitoring.init()
            FeedbackIntegration.subsystems.performance = PerformanceMonitoring
            Utils.Logger.info("⚡ Performance Monitoring: %s", subsystemResults.performance and "✅" or "❌")
        end
    end
    
    -- Initialize Feedback Analyzer
    if FeedbackIntegration.settings.features.analysis_pipeline_enabled then
        local FeedbackAnalyzer = Utils.require("src.systems.feedback_analysis_pipeline")
        if FeedbackAnalyzer then
            subsystemResults.analyzer = FeedbackAnalyzer.init()
            FeedbackIntegration.subsystems.analyzer = FeedbackAnalyzer
            Utils.Logger.info("🔍 Analysis Pipeline: %s", subsystemResults.analyzer and "✅" or "❌")
        end
    end
    
    -- Check if enough subsystems initialized successfully
    local successCount = 0
    local totalCount = 0
    for system, result in pairs(subsystemResults) do
        totalCount = totalCount + 1
        if result then successCount = successCount + 1 end
    end
    
    local successRate = totalCount > 0 and (successCount / totalCount) or 0
    
    if successRate < 0.5 then
        Utils.Logger.error("❌ Insufficient subsystems initialized: %.1f%% success rate", successRate * 100)
        return false
    end
    
    Utils.Logger.info("✅ Subsystem initialization: %.1f%% success rate (%d/%d)", 
                     successRate * 100, successCount, totalCount)
    return true
end

-- Set up cross-system integrations
function FeedbackIntegration.setupIntegrations()
    -- Integration 1: Analytics → Dynamic Config (A/B test assignments)
    if FeedbackIntegration.subsystems.analytics and FeedbackIntegration.subsystems.config then
        -- The dynamic config system already pulls A/B assignments from analytics
        Utils.Logger.debug("🔗 Analytics ↔ Dynamic Config integration enabled")
    end
    
    -- Integration 2: Performance → Dynamic Config (automatic optimization)
    if FeedbackIntegration.subsystems.performance and FeedbackIntegration.subsystems.config then
        -- Performance monitoring can trigger automatic config changes
        Utils.Logger.debug("🔗 Performance ↔ Dynamic Config integration enabled")
    end
    
    -- Integration 3: Forms → Analytics (sentiment data flow)
    if FeedbackIntegration.subsystems.forms and FeedbackIntegration.subsystems.analytics then
        -- Forms system automatically sends sentiment data to analytics
        Utils.Logger.debug("🔗 Forms → Analytics integration enabled")
    end
    
    -- Integration 4: All systems → Analyzer (data aggregation)
    if FeedbackIntegration.subsystems.analyzer then
        -- Analyzer pulls data from all other systems
        Utils.Logger.debug("🔗 All Systems → Analyzer integration enabled")
    end
end

-- Initialize health monitoring
function FeedbackIntegration.initializeHealthMonitoring()
    FeedbackIntegration.health.last_health_check = love.timer.getTime()
    FeedbackIntegration.health.subsystem_status = {}
    
    -- Check initial health of all subsystems
    FeedbackIntegration.performHealthCheck()
    
    Utils.Logger.debug("🏥 Health monitoring initialized")
end

-- Initialize data synchronization
function FeedbackIntegration.initializeDataSync()
    FeedbackIntegration.sync.last_sync_time = love.timer.getTime()
    FeedbackIntegration.sync.pending_syncs = {}
    FeedbackIntegration.sync.sync_errors = {}
    
    Utils.Logger.debug("🔄 Data synchronization initialized")
end

-- Main update function - orchestrates all subsystems
function FeedbackIntegration.update(dt)
    if not FeedbackIntegration.isActive then return end
    
    local currentTime = love.timer.getTime()
    
    -- Update all active subsystems
    FeedbackIntegration.updateSubsystems(dt)
    
    -- Perform periodic tasks
    if currentTime - FeedbackIntegration.lastUpdateTime >= FeedbackIntegration.settings.update_interval then
        FeedbackIntegration.performPeriodicTasks()
        FeedbackIntegration.lastUpdateTime = currentTime
    end
    
    -- Sync data between systems
    if currentTime - FeedbackIntegration.sync.last_sync_time >= FeedbackIntegration.settings.data_sync_interval then
        FeedbackIntegration.syncData()
        FeedbackIntegration.sync.last_sync_time = currentTime
    end
end

-- Update all subsystems
function FeedbackIntegration.updateSubsystems(dt)
    -- Update Analytics
    if FeedbackIntegration.subsystems.analytics and FeedbackIntegration.subsystems.analytics.update then
        FeedbackIntegration.subsystems.analytics.update(dt)
    end
    
    -- Update Forms
    if FeedbackIntegration.subsystems.forms and FeedbackIntegration.subsystems.forms.update then
        FeedbackIntegration.subsystems.forms.update(dt)
    end
    
    -- Update Performance Monitoring
    if FeedbackIntegration.subsystems.performance and FeedbackIntegration.subsystems.performance.update then
        FeedbackIntegration.subsystems.performance.update(dt)
    end
    
    -- Update Dynamic Config
    if FeedbackIntegration.subsystems.config and FeedbackIntegration.subsystems.config.update then
        FeedbackIntegration.subsystems.config.update(dt)
    end
    
    -- Update Analyzer
    if FeedbackIntegration.subsystems.analyzer and FeedbackIntegration.subsystems.analyzer.update then
        FeedbackIntegration.subsystems.analyzer.update(dt)
    end
end

-- Perform periodic maintenance tasks
function FeedbackIntegration.performPeriodicTasks()
    -- Health check
    FeedbackIntegration.performHealthCheck()
    
    -- Check for interventions
    if FeedbackIntegration.settings.auto_intervention then
        FeedbackIntegration.checkAutoInterventions()
    end
    
    -- Clean up old data
    FeedbackIntegration.performDataCleanup()
    
    -- Update performance score
    FeedbackIntegration.updatePerformanceScore()
end

-- Perform system health check
function FeedbackIntegration.performHealthCheck()
    local currentTime = love.timer.getTime()
    FeedbackIntegration.health.last_health_check = currentTime
    
    local healthyCount = 0
    local totalCount = 0
    
    -- Check each subsystem
    for name, system in pairs(FeedbackIntegration.subsystems) do
        totalCount = totalCount + 1
        
        local isHealthy = true
        local status = "healthy"
        
        -- Basic health checks
        if not system or not system.isActive then
            isHealthy = false
            status = "inactive"
        elseif system.getStatus then
            local systemStatus = system.getStatus()
            if systemStatus and systemStatus.errors and systemStatus.errors > 10 then
                isHealthy = false
                status = "error_threshold_exceeded"
            end
        end
        
        FeedbackIntegration.health.subsystem_status[name] = {
            healthy = isHealthy,
            status = status,
            last_check = currentTime
        }
        
        if isHealthy then healthyCount = healthyCount + 1 end
    end
    
    -- Calculate overall health score
    local healthScore = totalCount > 0 and (healthyCount / totalCount * 100) or 0
    FeedbackIntegration.health.performance_score = healthScore
    
    if healthScore < 50 then
        Utils.Logger.warn("⚠️ System health degraded: %.1f%%", healthScore)
    end
end

-- Check for automatic interventions
function FeedbackIntegration.checkAutoInterventions()
    -- Get performance data
    local performanceData = nil
    if FeedbackIntegration.subsystems.performance then
        performanceData = FeedbackIntegration.subsystems.performance.getPerformanceStats()
    end
    
    -- Get analytics data
    local analyticsData = nil
    if FeedbackIntegration.subsystems.analytics then
        analyticsData = FeedbackIntegration.subsystems.analytics.getKeyMetrics()
    end
    
    -- Check for interventions needed
    local interventions = {}
    
    -- Performance-based interventions
    if performanceData then
        if performanceData.avg_fps < 30 then
            table.insert(interventions, {
                type = "performance",
                severity = "high",
                action = "reduce_visual_effects",
                data = performanceData
            })
        end
        
        if performanceData.crash_count > 0 then
            table.insert(interventions, {
                type = "stability",
                severity = "critical",
                action = "enable_safe_mode", 
                data = performanceData
            })
        end
    end
    
    -- Analytics-based interventions
    if analyticsData and analyticsData.satisfaction then
        if analyticsData.satisfaction.overall < 2.5 then
            table.insert(interventions, {
                type = "satisfaction",
                severity = "high",
                action = "adjust_difficulty",
                data = analyticsData
            })
        end
    end
    
    -- Execute interventions
    for _, intervention in ipairs(interventions) do
        FeedbackIntegration.executeIntervention(intervention)
    end
end

-- Execute an automatic intervention
function FeedbackIntegration.executeIntervention(intervention)
    if not FeedbackIntegration.subsystems.config then return false end
    
    local config = FeedbackIntegration.subsystems.config
    local success = false
    
    if intervention.action == "reduce_visual_effects" then
        config.applyConfigurationBatch({
            particle_intensity = 0.5,
            screen_glow_intensity = 0.3
        }, "auto_intervention_performance")
        success = true
        
    elseif intervention.action == "enable_safe_mode" then
        config.applyConfigurationBatch({
            particle_intensity = 0.2,
            screen_glow_intensity = 0.1,
            animation_speed = 0.8
        }, "auto_intervention_stability")
        success = true
        
    elseif intervention.action == "adjust_difficulty" then
        config.applyConfigurationBatch({
            difficulty_scaling = 0.8,
            grace_period_base = 4.0
        }, "auto_intervention_satisfaction")
        success = true
    end
    
    if success then
        Utils.Logger.info("🔧 Auto-intervention executed: %s", intervention.action)
        
        -- Track intervention
        if FeedbackIntegration.subsystems.analytics then
            FeedbackIntegration.subsystems.analytics.trackEvent("auto_intervention_executed", {
                type = intervention.type,
                action = intervention.action,
                severity = intervention.severity
            })
        end
    end
    
    return success
end

-- Sync data between systems
function FeedbackIntegration.syncData()
    -- Performance data to analytics
    if FeedbackIntegration.subsystems.performance and FeedbackIntegration.subsystems.analytics then
        local perfStats = FeedbackIntegration.subsystems.performance.getPerformanceStats()
        if perfStats then
            FeedbackIntegration.subsystems.analytics.updatePerformanceMetrics(perfStats.avg_fps, perfStats.memory_mb)
        end
    end
    
    -- Forms data to analytics (happens automatically through sentiment recording)
    
    -- Analytics data to analyzer (happens automatically through data gathering)
    
    Utils.Logger.debug("🔄 Data synchronization completed")
end

-- Perform data cleanup
function FeedbackIntegration.performDataCleanup()
    -- Clean old history data to prevent memory issues
    local currentTime = love.timer.getTime()
    local maxAge = 86400 -- 24 hours
    
    -- Request cleanup from each subsystem
    for name, system in pairs(FeedbackIntegration.subsystems) do
        if system and system.cleanup then
            system.cleanup(maxAge)
        end
    end
end

-- Update performance score based on system metrics
function FeedbackIntegration.updatePerformanceScore()
    local score = 100
    
    -- Deduct points for errors
    score = score - (FeedbackIntegration.health.error_count * 5)
    score = score - (FeedbackIntegration.health.warning_count * 2)
    
    -- Deduct points for unhealthy subsystems
    local unhealthyCount = 0
    for _, status in pairs(FeedbackIntegration.health.subsystem_status) do
        if not status.healthy then
            unhealthyCount = unhealthyCount + 1
        end
    end
    score = score - (unhealthyCount * 10)
    
    -- Performance data penalty
    if FeedbackIntegration.subsystems.performance then
        local perfStats = FeedbackIntegration.subsystems.performance.getPerformanceStats()
        if perfStats then
            if perfStats.avg_fps < 30 then score = score - 20 end
            if perfStats.crash_count > 0 then score = score - 30 end
        end
    end
    
    FeedbackIntegration.health.performance_score = math.max(0, score)
end

-- Count active subsystems
function FeedbackIntegration.countActiveSubsystems()
    local count = 0
    for _, system in pairs(FeedbackIntegration.subsystems) do
        if system and system.isActive then
            count = count + 1
        end
    end
    return count
end

-- Get comprehensive system status
function FeedbackIntegration.getSystemStatus()
    return {
        active = FeedbackIntegration.isActive,
        uptime = love.timer.getTime() - FeedbackIntegration.initializationTime,
        subsystems_active = FeedbackIntegration.countActiveSubsystems(),
        health_score = FeedbackIntegration.health.performance_score,
        subsystem_health = FeedbackIntegration.health.subsystem_status,
        last_health_check = FeedbackIntegration.health.last_health_check,
        features_enabled = FeedbackIntegration.settings.features
    }
end

-- Get comprehensive analytics dashboard data
function FeedbackIntegration.getDashboardData()
    local dashboard = {
        timestamp = love.timer.getTime(),
        system_status = FeedbackIntegration.getSystemStatus(),
        key_metrics = {},
        insights = {},
        recommendations = {}
    }
    
    -- Gather key metrics from analytics
    if FeedbackIntegration.subsystems.analytics then
        dashboard.key_metrics = FeedbackIntegration.subsystems.analytics.getKeyMetrics()
    end
    
    -- Gather insights from analyzer
    if FeedbackIntegration.subsystems.analyzer then
        local analysisReport = FeedbackIntegration.subsystems.analyzer.getAnalysisReport()
        if analysisReport then
            dashboard.insights = analysisReport.insights
            dashboard.recommendations = analysisReport.patterns
        end
    end
    
    -- Add performance data
    if FeedbackIntegration.subsystems.performance then
        dashboard.performance = FeedbackIntegration.subsystems.performance.getPerformanceReport()
    end
    
    -- Add configuration data
    if FeedbackIntegration.subsystems.config then
        dashboard.configuration = FeedbackIntegration.subsystems.config.getConfigurationReport()
    end
    
    return dashboard
end

-- Export all system data for external analysis
function FeedbackIntegration.exportAllData()
    local exportData = {
        timestamp = love.timer.getTime(),
        system_info = FeedbackIntegration.getSystemStatus(),
        analytics = nil,
        forms = nil,
        performance = nil,
        configuration = nil,
        analysis = nil
    }
    
    -- Export from each subsystem
    if FeedbackIntegration.subsystems.analytics then
        exportData.analytics = FeedbackIntegration.subsystems.analytics.getAnalyticsReport()
    end
    
    if FeedbackIntegration.subsystems.forms then
        exportData.forms = FeedbackIntegration.subsystems.forms.exportFeedbackData()
    end
    
    if FeedbackIntegration.subsystems.performance then
        exportData.performance = FeedbackIntegration.subsystems.performance.getPerformanceReport()
    end
    
    if FeedbackIntegration.subsystems.config then
        exportData.configuration = FeedbackIntegration.subsystems.config.exportConfiguration()
    end
    
    if FeedbackIntegration.subsystems.analyzer then
        exportData.analysis = FeedbackIntegration.subsystems.analyzer.getAnalysisReport()
    end
    
    return exportData
end

-- Trigger a survey through the forms system
function FeedbackIntegration.triggerSurvey(context, data)
    if FeedbackIntegration.subsystems.forms then
        return FeedbackIntegration.subsystems.forms.triggerSurvey(context, data)
    end
    return false
end

-- Get current survey for UI
function FeedbackIntegration.getCurrentSurvey()
    if FeedbackIntegration.subsystems.forms then
        return FeedbackIntegration.subsystems.forms.getCurrentSurvey()
    end
    return nil
end

-- Submit survey response
function FeedbackIntegration.submitSurveyResponse(questionId, response)
    if FeedbackIntegration.subsystems.forms then
        return FeedbackIntegration.subsystems.forms.submitResponse(questionId, response)
    end
    return false
end

-- Dismiss current survey
function FeedbackIntegration.dismissSurvey(reason)
    if FeedbackIntegration.subsystems.forms then
        return FeedbackIntegration.subsystems.forms.dismissSurvey(reason)
    end
    return false
end

-- Track a game event across the system
function FeedbackIntegration.trackEvent(eventName, data)
    -- Send to analytics if available
    if FeedbackIntegration.subsystems.analytics then
        FeedbackIntegration.subsystems.analytics.trackEvent(eventName, data)
    end
    
    -- Check if event should trigger a survey
    if FeedbackIntegration.subsystems.forms then
        local surveyTriggers = {
            "level_up", "achievement_unlocked", "streak_milestone", 
            "frustration_detected", "mystery_box_collected"
        }
        
        for _, trigger in ipairs(surveyTriggers) do
            if eventName == trigger then
                FeedbackIntegration.subsystems.forms.triggerSurvey(eventName, data)
                break
            end
        end
    end
end

-- Save all system data
function FeedbackIntegration.saveAllData()
    local savedCount = 0
    
    for name, system in pairs(FeedbackIntegration.subsystems) do
        if system and system.save then
            system.save()
            savedCount = savedCount + 1
        end
    end
    
    Utils.Logger.info("💾 Saved data for %d subsystems", savedCount)
    return savedCount
end

-- Cleanup and shutdown
function FeedbackIntegration.cleanup()
    if not FeedbackIntegration.isActive then return end
    
    Utils.Logger.info("🛑 Shutting down Feedback Integration System...")
    
    -- Save all data before shutdown
    FeedbackIntegration.saveAllData()
    
    -- Cleanup each subsystem
    for name, system in pairs(FeedbackIntegration.subsystems) do
        if system and system.cleanup then
            system.cleanup()
            Utils.Logger.debug("🧹 Cleaned up %s subsystem", name)
        end
    end
    
    FeedbackIntegration.isActive = false
    
    local uptime = love.timer.getTime() - FeedbackIntegration.initializationTime
    Utils.Logger.info("✅ Feedback Integration System shutdown complete (uptime: %.1fs)", uptime)
end

return FeedbackIntegration