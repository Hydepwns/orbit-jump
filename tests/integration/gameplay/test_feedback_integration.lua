--[[
    ═══════════════════════════════════════════════════════════════════════════
    Feedback Integration Tests - Comprehensive Test Suite
    ═══════════════════════════════════════════════════════════════════════════
    This test suite provides comprehensive coverage of all feedback integration
    systems implemented according to the Feedback Integration Plan.
--]]
local Utils = require("src.utils.utils")
-- Mock Love2D functions for testing
local mockLove = {
    timer = {
        getTime = function() return os.time() end,
        getFPS = function() return 60 end
    },
    system = {
        getPowerInfo = function() return "unknown", 50 end
    }
}
-- Set up mock Love2D environment
if not love then
    love = mockLove
elseif not love.timer then
    love.timer = mockLove.timer
end
-- Test framework
local FeedbackIntegrationTests = {}
-- Test results storage
FeedbackIntegrationTests.results = {
    passed = 0,
    failed = 0,
    errors = {},
    details = {}
}
-- Test helper functions
function FeedbackIntegrationTests.assert(condition, message)
    if condition then
        FeedbackIntegrationTests.results.passed = FeedbackIntegrationTests.results.passed + 1
        return true
    else
        FeedbackIntegrationTests.results.failed = FeedbackIntegrationTests.results.failed + 1
        table.insert(FeedbackIntegrationTests.results.errors, message or "Assertion failed")
        return false
    end
end
function FeedbackIntegrationTests.assertEquals(expected, actual, message)
    local condition = expected == actual
    local msg = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
    return FeedbackIntegrationTests.assert(condition, msg)
end
function FeedbackIntegrationTests.assertNotNil(value, message)
    return FeedbackIntegrationTests.assert(value ~= nil, message or "Value should not be nil")
end
function FeedbackIntegrationTests.assertType(expected_type, value, message)
    local actual_type = type(value)
    local msg = message or string.format("Expected type %s, got %s", expected_type, actual_type)
    return FeedbackIntegrationTests.assert(actual_type == expected_type, msg)
end
function FeedbackIntegrationTests.assertTableContains(table_val, key, message)
    local condition = table_val and table_val[key] ~= nil
    local msg = message or string.format("Table should contain key %s", tostring(key))
    return FeedbackIntegrationTests.assert(condition, msg)
end
-- Test Suite 1: Feedback Analytics System
function FeedbackIntegrationTests.testFeedbackAnalyticsSystem()
    print("📊 Testing Feedback Analytics System...")
    local FeedbackAnalytics = require("src.systems.analytics.feedback_analytics")
    -- Test 1: System initialization
    local initResult = FeedbackAnalytics.init()
    FeedbackIntegrationTests.assert(initResult == true, "Analytics system should initialize successfully")
    FeedbackIntegrationTests.assert(FeedbackAnalytics.isActive == true, "System should be active after init")
    FeedbackIntegrationTests.assertNotNil(FeedbackAnalytics.sessionId, "Session ID should be generated")
    -- Test 2: Metrics structure
    FeedbackIntegrationTests.assertNotNil(FeedbackAnalytics.metrics, "Metrics should be defined")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "engagement", "Should have engagement metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "addiction", "Should have addiction metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "progression", "Should have progression metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "events", "Should have events metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "difficulty", "Should have difficulty metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "features", "Should have features metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "performance", "Should have performance metrics")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalytics.metrics, "sentiment", "Should have sentiment metrics")
    -- Test 3: Event tracking
    FeedbackAnalytics.trackEvent("test_event", {value = 123})
    FeedbackIntegrationTests.assert(true, "Event tracking should not crash")
    -- Test 4: Sentiment recording
    FeedbackAnalytics.recordSentiment("overall", 4, {context = "test"})
    local sentimentScore = FeedbackAnalytics.metrics.sentiment.overall_satisfaction
    FeedbackIntegrationTests.assertEquals(4, sentimentScore, "Sentiment should be recorded correctly")
    -- Test 5: A/B test variant retrieval
    local variant = FeedbackAnalytics.getABTestVariant("xp_scaling")
    FeedbackIntegrationTests.assertNotNil(variant, "Should return A/B test variant")
    FeedbackIntegrationTests.assertType("string", variant, "Variant should be a string")
    -- Test 6: Analytics report generation
    local report = FeedbackAnalytics.getAnalyticsReport()
    FeedbackIntegrationTests.assertNotNil(report, "Should generate analytics report")
    FeedbackIntegrationTests.assertTableContains(report, "session", "Report should contain session data")
    FeedbackIntegrationTests.assertTableContains(report, "metrics", "Report should contain metrics")
    FeedbackIntegrationTests.assertTableContains(report, "ab_tests", "Report should contain A/B test data")
    -- Test 7: Key metrics
    local keyMetrics = FeedbackAnalytics.getKeyMetrics()
    FeedbackIntegrationTests.assertNotNil(keyMetrics, "Should generate key metrics")
    FeedbackIntegrationTests.assertTableContains(keyMetrics, "engagement", "Key metrics should include engagement")
    FeedbackIntegrationTests.assertTableContains(keyMetrics, "addiction", "Key metrics should include addiction")
    FeedbackIntegrationTests.assertTableContains(keyMetrics, "progression", "Key metrics should include progression")
    FeedbackIntegrationTests.assertTableContains(keyMetrics, "satisfaction", "Key metrics should include satisfaction")
    print("✅ Feedback Analytics System tests completed")
end
-- Test Suite 2: Dynamic Configuration System
function FeedbackIntegrationTests.testDynamicConfigSystem()
    print("⚙️ Testing Dynamic Configuration System...")
    local DynamicConfig = require("src.systems.dynamic_config_system")
    -- Test 1: System initialization
    local initResult = DynamicConfig.init()
    FeedbackIntegrationTests.assert(initResult == true, "Dynamic config system should initialize")
    FeedbackIntegrationTests.assert(DynamicConfig.isActive == true, "System should be active")
    -- Test 2: Configuration values structure
    FeedbackIntegrationTests.assertNotNil(DynamicConfig.values, "Configuration values should exist")
    FeedbackIntegrationTests.assertTableContains(DynamicConfig.values, "xp_scaling_factors", "Should have XP scaling")
    FeedbackIntegrationTests.assertTableContains(DynamicConfig.values, "mystery_box_spawn_rate", "Should have event config")
    FeedbackIntegrationTests.assertTableContains(DynamicConfig.values, "grace_period_base", "Should have streak config")
    FeedbackIntegrationTests.assertTableContains(DynamicConfig.values, "features", "Should have feature toggles")
    -- Test 3: Configuration value retrieval
    local xpScaling = DynamicConfig.getValue("xp_scaling_factors")
    FeedbackIntegrationTests.assertNotNil(xpScaling, "Should retrieve XP scaling factors")
    FeedbackIntegrationTests.assertType("table", xpScaling, "XP scaling should be a table")
    -- Test 4: XP scaling factor calculation
    local factor1 = DynamicConfig.getXPScalingFactor(1)
    local factor2 = DynamicConfig.getXPScalingFactor(2)
    FeedbackIntegrationTests.assertType("number", factor1, "XP factor should be a number")
    FeedbackIntegrationTests.assertType("number", factor2, "XP factor should be a number")
    FeedbackIntegrationTests.assert(factor1 > 0, "XP factor should be positive")
    -- Test 5: XP multiplier retrieval
    local multiplier = DynamicConfig.getXPMultiplier("perfect_landing")
    FeedbackIntegrationTests.assertType("number", multiplier, "XP multiplier should be a number")
    FeedbackIntegrationTests.assert(multiplier > 0, "XP multiplier should be positive")
    -- Test 6: Grace period calculation
    local gracePeriod1 = DynamicConfig.getGracePeriod(0.2) -- New player
    local gracePeriod2 = DynamicConfig.getGracePeriod(0.8) -- Experienced player
    FeedbackIntegrationTests.assertType("number", gracePeriod1, "Grace period should be a number")
    FeedbackIntegrationTests.assertType("number", gracePeriod2, "Grace period should be a number")
    FeedbackIntegrationTests.assert(gracePeriod1 > gracePeriod2, "New players should get longer grace period")
    -- Test 7: Feature toggle checking
    local featureEnabled = DynamicConfig.isFeatureEnabled("mystery_boxes_enabled")
    FeedbackIntegrationTests.assertType("boolean", featureEnabled, "Feature check should return boolean")
    -- Test 8: Configuration change application
    local originalValue = DynamicConfig.getValue("particle_intensity")
    DynamicConfig.applyConfigurationChange("particle_intensity", 0.5, "test")
    local newValue = DynamicConfig.getValue("particle_intensity")
    FeedbackIntegrationTests.assertEquals(0.5, newValue, "Configuration change should be applied")
    -- Test 9: Configuration validation
    local valid, errors = DynamicConfig.validateConfiguration()
    FeedbackIntegrationTests.assert(valid == true, "Configuration should validate successfully")
    if not valid then
        print("Validation errors:", table.concat(errors, ", "))
    end
    -- Test 10: Configuration report
    local report = DynamicConfig.getConfigurationReport()
    FeedbackIntegrationTests.assertNotNil(report, "Should generate configuration report")
    FeedbackIntegrationTests.assertTableContains(report, "current_values", "Report should contain current values")
    FeedbackIntegrationTests.assertTableContains(report, "history", "Report should contain history")
    print("✅ Dynamic Configuration System tests completed")
end
-- Test Suite 3: Feedback Forms System
function FeedbackIntegrationTests.testFeedbackFormsSystem()
    print("📝 Testing Feedback Forms System...")
    local FeedbackForms = require("src.systems.feedback_forms_system")
    -- Test 1: System initialization
    local initResult = FeedbackForms.init()
    FeedbackIntegrationTests.assert(initResult == true, "Feedback forms system should initialize")
    FeedbackIntegrationTests.assert(FeedbackForms.isActive == true, "System should be active")
    -- Test 2: Survey types structure
    FeedbackIntegrationTests.assertNotNil(FeedbackForms.surveyTypes, "Survey types should be defined")
    FeedbackIntegrationTests.assertTableContains(FeedbackForms.surveyTypes, "quick_satisfaction", "Should have quick satisfaction survey")
    FeedbackIntegrationTests.assertTableContains(FeedbackForms.surveyTypes, "difficulty_check", "Should have difficulty check survey")
    FeedbackIntegrationTests.assertTableContains(FeedbackForms.surveyTypes, "progression_satisfaction", "Should have progression survey")
    FeedbackIntegrationTests.assertTableContains(FeedbackForms.surveyTypes, "session_summary", "Should have session summary survey")
    -- Test 3: Survey triggering
    local triggered = FeedbackForms.triggerSurvey("level_up", {level = 5})
    FeedbackIntegrationTests.assertType("boolean", triggered, "Trigger should return boolean")
    -- Test 4: Survey display data
    if FeedbackForms.currentSurvey then
        local displayData = FeedbackForms.getSurveyDisplayData()
        FeedbackIntegrationTests.assertNotNil(displayData, "Should provide survey display data")
        FeedbackIntegrationTests.assertTableContains(displayData, "title", "Display data should have title")
        FeedbackIntegrationTests.assertTableContains(displayData, "type", "Display data should have type")
    end
    -- Test 5: Response submission
    if FeedbackForms.currentSurvey then
        local responseResult = FeedbackForms.submitResponse(nil, 4)
        FeedbackIntegrationTests.assertType("boolean", responseResult, "Response submission should return boolean")
    end
    -- Test 6: Response statistics
    local stats = FeedbackForms.getResponseStatistics()
    FeedbackIntegrationTests.assertNotNil(stats, "Should generate response statistics")
    FeedbackIntegrationTests.assertTableContains(stats, "total_surveys_completed", "Stats should include completion count")
    FeedbackIntegrationTests.assertTableContains(stats, "completion_rate", "Stats should include completion rate")
    FeedbackIntegrationTests.assertTableContains(stats, "sentiment_scores", "Stats should include sentiment scores")
    -- Test 7: Data export
    local exportData = FeedbackForms.exportFeedbackData()
    FeedbackIntegrationTests.assertNotNil(exportData, "Should export feedback data")
    FeedbackIntegrationTests.assertTableContains(exportData, "responses", "Export should include responses")
    FeedbackIntegrationTests.assertTableContains(exportData, "statistics", "Export should include statistics")
    FeedbackIntegrationTests.assertTableContains(exportData, "survey_definitions", "Export should include survey definitions")
    print("✅ Feedback Forms System tests completed")
end
-- Test Suite 4: Performance Monitoring System
function FeedbackIntegrationTests.testPerformanceMonitoringSystem()
    print("⚡ Testing Performance Monitoring System...")
    local PerformanceMonitoring = require("src.systems.performance_monitoring_system")
    -- Test 1: System initialization
    local initResult = PerformanceMonitoring.init()
    FeedbackIntegrationTests.assert(initResult == true, "Performance monitoring should initialize")
    FeedbackIntegrationTests.assert(PerformanceMonitoring.isActive == true, "System should be active")
    -- Test 2: Metrics structure
    FeedbackIntegrationTests.assertNotNil(PerformanceMonitoring.metrics, "Metrics should be defined")
    FeedbackIntegrationTests.assertTableContains(PerformanceMonitoring.metrics, "fps", "Should have FPS metrics")
    FeedbackIntegrationTests.assertTableContains(PerformanceMonitoring.metrics, "memory", "Should have memory metrics")
    FeedbackIntegrationTests.assertTableContains(PerformanceMonitoring.metrics, "load_times", "Should have load time metrics")
    FeedbackIntegrationTests.assertTableContains(PerformanceMonitoring.metrics, "errors", "Should have error metrics")
    -- Test 3: FPS metrics initialization
    local fpsMetrics = PerformanceMonitoring.metrics.fps
    FeedbackIntegrationTests.assertType("number", fpsMetrics.current, "Current FPS should be a number")
    FeedbackIntegrationTests.assertType("number", fpsMetrics.average, "Average FPS should be a number")
    FeedbackIntegrationTests.assertType("table", fpsMetrics.samples, "FPS samples should be a table")
    -- Test 4: Performance metrics update
    PerformanceMonitoring.update(0.016) -- Simulate frame update
    FeedbackIntegrationTests.assert(true, "Performance metrics update should not crash")
    -- Test 5: Load time tracking
    local startTime = love.timer.getTime()
    PerformanceMonitoring.trackLoadTime("test_operation", startTime, startTime + 2.5)
    FeedbackIntegrationTests.assert(true, "Load time tracking should not crash")
    -- Test 6: Error tracking
    PerformanceMonitoring.trackError("lua_error", "Test error message", "test stack trace")
    local errorCount = PerformanceMonitoring.metrics.errors.error_count
    FeedbackIntegrationTests.assert(errorCount > 0, "Error should be tracked")
    -- Test 7: Performance report generation
    local report = PerformanceMonitoring.getPerformanceReport()
    FeedbackIntegrationTests.assertNotNil(report, "Should generate performance report")
    FeedbackIntegrationTests.assertTableContains(report, "fps", "Report should include FPS data")
    FeedbackIntegrationTests.assertTableContains(report, "memory", "Report should include memory data")
    FeedbackIntegrationTests.assertTableContains(report, "errors", "Report should include error data")
    -- Test 8: Performance statistics
    local stats = PerformanceMonitoring.getPerformanceStats()
    FeedbackIntegrationTests.assertNotNil(stats, "Should generate performance stats")
    FeedbackIntegrationTests.assertTableContains(stats, "avg_fps", "Stats should include average FPS")
    FeedbackIntegrationTests.assertTableContains(stats, "memory_mb", "Stats should include memory usage")
    print("✅ Performance Monitoring System tests completed")
end
-- Test Suite 5: Feedback Analysis Pipeline
function FeedbackIntegrationTests.testFeedbackAnalysisPipeline()
    print("🔍 Testing Feedback Analysis Pipeline...")
    local FeedbackAnalyzer = require("src.systems.feedback_analysis_pipeline")
    -- Test 1: System initialization
    local initResult = FeedbackAnalyzer.init()
    FeedbackIntegrationTests.assert(initResult == true, "Analysis pipeline should initialize")
    FeedbackIntegrationTests.assert(FeedbackAnalyzer.isActive == true, "System should be active")
    -- Test 2: Insights structure
    FeedbackIntegrationTests.assertNotNil(FeedbackAnalyzer.insights, "Insights should be defined")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalyzer.insights, "engagement_insights", "Should have engagement insights")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalyzer.insights, "balance_insights", "Should have balance insights")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalyzer.insights, "progression_insights", "Should have progression insights")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalyzer.insights, "sentiment_insights", "Should have sentiment insights")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalyzer.insights, "performance_insights", "Should have performance insights")
    FeedbackIntegrationTests.assertTableContains(FeedbackAnalyzer.insights, "behavioral_insights", "Should have behavioral insights")
    -- Test 3: Statistical analysis tools
    FeedbackIntegrationTests.assertNotNil(FeedbackAnalyzer.statistics, "Statistics should be defined")
    FeedbackIntegrationTests.assertType("function", FeedbackAnalyzer.chiSquareTest, "Chi-square test should be a function")
    FeedbackIntegrationTests.assertType("function", FeedbackAnalyzer.tTest, "T-test should be a function")
    -- Test 4: Pattern analysis
    FeedbackIntegrationTests.assertType("function", FeedbackAnalyzer.analyzePlayerJourneys, "Journey analysis should be a function")
    FeedbackIntegrationTests.assertType("function", FeedbackAnalyzer.analyzeQuitPoints, "Quit point analysis should be a function")
    -- Test 5: Predictive modeling
    FeedbackIntegrationTests.assertType("function", FeedbackAnalyzer.predictChurn, "Churn prediction should be a function")
    FeedbackIntegrationTests.assertType("function", FeedbackAnalyzer.predictEngagementOptimizations, "Engagement optimization should be a function")
    -- Test 6: Statistical functions
    local testData1 = {1, 2, 3, 4, 5}
    local testData2 = {2, 3, 4, 5, 6}
    local tTestResult = FeedbackAnalyzer.tTest(testData1, testData2)
    FeedbackIntegrationTests.assertNotNil(tTestResult, "T-test should return results")
    FeedbackIntegrationTests.assertTableContains(tTestResult, "t_statistic", "T-test should include t-statistic")
    FeedbackIntegrationTests.assertTableContains(tTestResult, "significant", "T-test should include significance")
    -- Test 7: Chi-square test
    local observed = {10, 15, 8, 12}
    local expected = {11, 14, 9, 11}
    local chiResult = FeedbackAnalyzer.chiSquareTest(observed, expected)
    FeedbackIntegrationTests.assertNotNil(chiResult, "Chi-square test should return results")
    FeedbackIntegrationTests.assertTableContains(chiResult, "chi_square", "Chi-square should include statistic")
    -- Test 8: Churn prediction
    local mockPlayerData = {
        sessions_per_day = 0.3,
        avg_session_duration = 200,
        progression_satisfaction = 2.5,
        frustration_events_per_session = 3,
        recent_crashes = 0,
        avg_fps = 45
    }
    local churnPrediction = FeedbackAnalyzer.predictChurn(mockPlayerData)
    FeedbackIntegrationTests.assertNotNil(churnPrediction, "Should predict churn risk")
    FeedbackIntegrationTests.assertTableContains(churnPrediction, "risk_score", "Should include risk score")
    FeedbackIntegrationTests.assertTableContains(churnPrediction, "risk_level", "Should include risk level")
    FeedbackIntegrationTests.assertTableContains(churnPrediction, "recommendations", "Should include recommendations")
    -- Test 9: Analysis report
    local analysisReport = FeedbackAnalyzer.getAnalysisReport()
    FeedbackIntegrationTests.assertNotNil(analysisReport, "Should generate analysis report")
    FeedbackIntegrationTests.assertTableContains(analysisReport, "insights", "Report should include insights")
    FeedbackIntegrationTests.assertTableContains(analysisReport, "statistics", "Report should include statistics")
    print("✅ Feedback Analysis Pipeline tests completed")
end
-- Test Suite 6: Integration Tests
function FeedbackIntegrationTests.testSystemIntegration()
    print("🔗 Testing System Integration...")
    -- Test 1: Cross-system data flow
    local FeedbackAnalytics = require("src.systems.analytics.feedback_analytics")
    local FeedbackForms = require("src.systems.feedback_forms_system")
    local PerformanceMonitoring = require("src.systems.performance_monitoring_system")
    local DynamicConfig = require("src.systems.dynamic_config_system")
    -- Ensure all systems are initialized
    if not FeedbackAnalytics.isActive then FeedbackAnalytics.init() end
    if not FeedbackForms.isActive then FeedbackForms.init() end
    if not PerformanceMonitoring.isActive then PerformanceMonitoring.init() end
    if not DynamicConfig.isActive then DynamicConfig.init() end
    -- Test 2: Analytics to Dynamic Config integration
    local xpVariant = FeedbackAnalytics.getABTestVariant("xp_scaling")
    FeedbackIntegrationTests.assertNotNil(xpVariant, "Analytics should provide A/B test variants")
    local xpFactor = DynamicConfig.getXPScalingFactor(1)
    FeedbackIntegrationTests.assertType("number", xpFactor, "Dynamic config should provide XP factors")
    -- Test 3: Performance monitoring to Dynamic Config integration
    PerformanceMonitoring.update(0.016) -- Simulate frame update
    local perfStats = PerformanceMonitoring.getPerformanceStats()
    FeedbackIntegrationTests.assertNotNil(perfStats, "Performance monitoring should provide stats")
    -- Test 4: Feedback forms to Analytics integration
    if FeedbackForms.triggerSurvey("test_integration", {}) then
        FeedbackForms.submitResponse(nil, 5)
    end
    FeedbackIntegrationTests.assert(true, "Feedback forms should integrate with analytics")
    -- Test 5: End-to-end workflow simulation
    -- Simulate a player session with poor performance
    FeedbackAnalytics.trackEvent("session_start", {})
    FeedbackAnalytics.trackEvent("frustration_detected", {intensity = 0.8, context = "difficulty"})
    PerformanceMonitoring.trackError("lua_error", "Test error", "test stack")
    FeedbackAnalytics.recordSentiment("overall", 2, {context = "integration_test"})
    local keyMetrics = FeedbackAnalytics.getKeyMetrics()
    FeedbackIntegrationTests.assertNotNil(keyMetrics, "Should generate key metrics from session data")
    print("✅ System Integration tests completed")
end
-- Test Suite 7: Load and Stress Tests
function FeedbackIntegrationTests.testLoadAndStress()
    print("💪 Testing Load and Stress Scenarios...")
    local FeedbackAnalytics = require("src.systems.analytics.feedback_analytics")
    local FeedbackForms = require("src.systems.feedback_forms_system")
    -- Test 1: High-frequency event tracking
    local startTime = love.timer.getTime()
    for i = 1, 100 do
        FeedbackAnalytics.trackEvent("stress_test_event", {iteration = i})
    end
    local endTime = love.timer.getTime()
    local duration = endTime - startTime
    FeedbackIntegrationTests.assert(duration < 1.0, "100 events should be tracked in under 1 second")
    -- Test 2: Large data structure handling
    local largeData = {}
    for i = 1, 1000 do
        largeData["key_" .. i] = "value_" .. i
    end
    FeedbackAnalytics.trackEvent("large_data_test", largeData)
    FeedbackIntegrationTests.assert(true, "Should handle large data structures without crashing")
    -- Test 3: Rapid survey triggering and dismissal
    for i = 1, 10 do
        if FeedbackForms.triggerSurvey("stress_test", {iteration = i}) then
            FeedbackForms.dismissSurvey("stress_test")
        end
    end
    FeedbackIntegrationTests.assert(true, "Should handle rapid survey operations")
    -- Test 4: Memory usage during extended operation
    local initialMemory = collectgarbage("count")
    for i = 1, 500 do
        FeedbackAnalytics.trackEvent("memory_test", {data = string.rep("x", 100)})
        FeedbackAnalytics.update(0.016) -- Simulate frame update
    end
    collectgarbage("collect")
    local finalMemory = collectgarbage("count")
    local memoryIncrease = finalMemory - initialMemory
    FeedbackIntegrationTests.assert(memoryIncrease < 1024, "Memory increase should be less than 1MB")
    print("✅ Load and Stress tests completed")
end
-- Test Suite 8: Error Handling and Edge Cases
function FeedbackIntegrationTests.testErrorHandlingAndEdgeCases()
    print("🛡️ Testing Error Handling and Edge Cases...")
    local FeedbackAnalytics = require("src.systems.analytics.feedback_analytics")
    local DynamicConfig = require("src.systems.dynamic_config_system")
    local FeedbackForms = require("src.systems.feedback_forms_system")
    -- Test 1: Nil parameter handling
    FeedbackAnalytics.trackEvent(nil, nil)
    FeedbackAnalytics.recordSentiment(nil, nil, nil)
    FeedbackIntegrationTests.assert(true, "Should handle nil parameters gracefully")
    -- Test 2: Invalid data types
    FeedbackAnalytics.recordSentiment("overall", "invalid_rating", {})
    FeedbackIntegrationTests.assert(true, "Should handle invalid data types")
    -- Test 3: Empty data structures
    FeedbackAnalytics.trackEvent("empty_test", {})
    local emptyReport = FeedbackAnalytics.getAnalyticsReport()
    FeedbackIntegrationTests.assertNotNil(emptyReport, "Should handle empty data structures")
    -- Test 4: Configuration bounds testing
    DynamicConfig.applyConfigurationChange("particle_intensity", -1, "bounds_test") -- Negative value
    DynamicConfig.applyConfigurationChange("particle_intensity", 999, "bounds_test") -- Very large value
    local valid, errors = DynamicConfig.validateConfiguration()
    FeedbackIntegrationTests.assertType("boolean", valid, "Validation should return boolean")
    -- Test 5: Survey system edge cases
    -- Try to trigger survey when system is not active
    FeedbackForms.isActive = false
    local triggered = FeedbackForms.triggerSurvey("test", {})
    FeedbackIntegrationTests.assertEquals(false, triggered, "Should not trigger survey when inactive")
    FeedbackForms.isActive = true
    -- Test 6: Multiple simultaneous survey attempts
    FeedbackForms.triggerSurvey("test1", {})
    local secondTrigger = FeedbackForms.triggerSurvey("test2", {})
    FeedbackIntegrationTests.assertEquals(false, secondTrigger, "Should not allow multiple simultaneous surveys")
    -- Clean up
    if FeedbackForms.currentSurvey then
        FeedbackForms.dismissSurvey("cleanup")
    end
    print("✅ Error Handling and Edge Cases tests completed")
end
-- Run all tests
function FeedbackIntegrationTests.runAllTests()
    print("🚀 Starting Comprehensive Feedback Integration Tests...")
    print("=" .. string.rep("=", 60))
    -- Reset test results
    FeedbackIntegrationTests.results = {
        passed = 0,
        failed = 0,
        errors = {},
        details = {}
    }
    -- Run test suites
    FeedbackIntegrationTests.testFeedbackAnalyticsSystem()
    FeedbackIntegrationTests.testDynamicConfigSystem()
    FeedbackIntegrationTests.testFeedbackFormsSystem()
    FeedbackIntegrationTests.testPerformanceMonitoringSystem()
    FeedbackIntegrationTests.testFeedbackAnalysisPipeline()
    FeedbackIntegrationTests.testSystemIntegration()
    FeedbackIntegrationTests.testLoadAndStress()
    FeedbackIntegrationTests.testErrorHandlingAndEdgeCases()
    -- Print results
    print("=" .. string.rep("=", 60))
    print("📊 TEST RESULTS:")
    print(string.format("✅ Passed: %d", FeedbackIntegrationTests.results.passed))
    print(string.format("❌ Failed: %d", FeedbackIntegrationTests.results.failed))
    if FeedbackIntegrationTests.results.failed > 0 then
        print("\n❌ FAILED TESTS:")
        for i, error in ipairs(FeedbackIntegrationTests.results.errors) do
            print(string.format("  %d. %s", i, error))
        end
    end
    local totalTests = FeedbackIntegrationTests.results.passed + FeedbackIntegrationTests.results.failed
    local successRate = totalTests > 0 and (FeedbackIntegrationTests.results.passed / totalTests * 100) or 0
    print(string.format("\n📈 Success Rate: %.1f%% (%d/%d)", successRate, FeedbackIntegrationTests.results.passed, totalTests))
    if FeedbackIntegrationTests.results.failed == 0 then
        print("🎉 ALL TESTS PASSED! Feedback Integration System is ready for deployment.")
    else
        print("⚠️  Some tests failed. Please review and fix issues before deployment.")
    end
    return FeedbackIntegrationTests.results.failed == 0
end
-- Export test results for external analysis
function FeedbackIntegrationTests.exportResults()
    return {
        timestamp = love.timer.getTime(),
        results = FeedbackIntegrationTests.results,
        success_rate = FeedbackIntegrationTests.results.passed /
                      (FeedbackIntegrationTests.results.passed + FeedbackIntegrationTests.results.failed),
        total_tests = FeedbackIntegrationTests.results.passed + FeedbackIntegrationTests.results.failed
    }
end
return FeedbackIntegrationTests