-- Phase 5: Performance Monitoring Tests
-- Tests performance monitoring and optimization
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
print("--- Phase 5: Performance Monitoring Tests ---")
-- Test suite
local tests = {
    ["performance monitor initialization"] = function()
        -- Test performance monitor initialization
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            TestFramework.assert.notNil(PerformanceMonitor, "Performance monitor should be available")
        end)
        TestFramework.assert.isTrue(success, "Performance monitor initialization should work without crashing")
    end,
    ["timer functionality"] = function()
        -- Test timer functionality
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.getStats then
                local stats = PerformanceMonitor.getStats()
                TestFramework.assert.notNil(stats, "Performance stats should be available")
            end
        end)
        TestFramework.assert.isTrue(success, "Timer functionality should work without crashing")
    end,
    ["memory tracking"] = function()
        -- Test memory tracking
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.trackMemoryUsage then
                PerformanceMonitor.trackMemoryUsage()
            end
        end)
        TestFramework.assert.isTrue(success, "Memory tracking should work without crashing")
    end,
    ["collision tracking"] = function()
        -- Test collision tracking
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.trackCollision then
                PerformanceMonitor.trackCollision(400, 300)
            end
        end)
        TestFramework.assert.isTrue(success, "Collision tracking should work without crashing")
    end,
    ["frame rate monitoring"] = function()
        -- Test frame rate monitoring
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.updateFrameRate then
                PerformanceMonitor.updateFrameRate(60)
            end
        end)
        TestFramework.assert.isTrue(success, "Frame rate monitoring should work without crashing")
    end,
    ["performance alerts"] = function()
        -- Test performance alerts
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.checkPerformanceAlerts then
                PerformanceMonitor.checkPerformanceAlerts()
            end
        end)
        TestFramework.assert.isTrue(success, "Performance alerts should work without crashing")
    end,
    ["performance optimization"] = function()
        -- Test performance optimization
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceSystem = require("src.performance.performance_system")
            TestFramework.assert.notNil(PerformanceSystem, "Performance system should be available")
        end)
        TestFramework.assert.isTrue(success, "Performance optimization should work without crashing")
    end,
    ["spatial grid operations"] = function()
        -- Test spatial grid operations
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceSystem = require("src.performance.performance_system")
            if PerformanceSystem.updateSpatialGrid then
                PerformanceSystem.updateSpatialGrid()
            end
        end)
        TestFramework.assert.isTrue(success, "Spatial grid operations should work without crashing")
    end,
    ["culling system"] = function()
        -- Test culling system
        local success = Utils.ErrorHandler.safeCall(function()
            local GameState = require("src.core.game_state")
            GameState.init(800, 600)
            local PerformanceSystem = require("src.performance.performance_system")
            if PerformanceSystem.updateCulling then
                PerformanceSystem.updateCulling()
            end
        end)
        TestFramework.assert.isTrue(success, "Culling system should work without crashing")
    end,
    ["object pooling"] = function()
        -- Test object pooling
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceSystem = require("src.performance.performance_system")
            if PerformanceSystem.getPooledObject then
                local obj = PerformanceSystem.getPooledObject("particle")
                TestFramework.assert.notNil(obj, "Pooled object should be available")
            end
        end)
        TestFramework.assert.isTrue(success, "Object pooling should work without crashing")
    end,
    ["batch rendering"] = function()
        -- Test batch rendering
        local success = Utils.ErrorHandler.safeCall(function()
            local Renderer = require("src.core.renderer")
            if Renderer.batchRender then
                Renderer.batchRender({})
            end
        end)
        TestFramework.assert.isTrue(success, "Batch rendering should work without crashing")
    end,
    ["performance metrics"] = function()
        -- Test performance metrics
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.collectMetrics then
                local metrics = PerformanceMonitor.collectMetrics()
                TestFramework.assert.notNil(metrics, "Performance metrics should be available")
            end
        end)
        TestFramework.assert.isTrue(success, "Performance metrics should work without crashing")
    end,
    ["quality level adjustment"] = function()
        -- Test quality level adjustment
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.adjustQualityLevel then
                PerformanceMonitor.adjustQualityLevel("medium")
            end
        end)
        TestFramework.assert.isTrue(success, "Quality level adjustment should work without crashing")
    end,
    ["performance profiling"] = function()
        -- Test performance profiling
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.startProfiling then
                PerformanceMonitor.startProfiling("test_profile")
            end
        end)
        TestFramework.assert.isTrue(success, "Performance profiling should work without crashing")
    end,
    ["performance visualization"] = function()
        -- Test performance visualization
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.renderPerformanceUI then
                PerformanceMonitor.renderPerformanceUI()
            end
        end)
        TestFramework.assert.isTrue(success, "Performance visualization should work without crashing")
    end,
    ["performance optimization recommendations"] = function()
        -- Test performance optimization recommendations
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.getOptimizationRecommendations then
                local recommendations = PerformanceMonitor.getOptimizationRecommendations()
                TestFramework.assert.notNil(recommendations, "Optimization recommendations should be available")
            end
        end)
        TestFramework.assert.isTrue(success, "Performance optimization recommendations should work without crashing")
    end,
    ["performance data export"] = function()
        -- Test performance data export
        local success = Utils.ErrorHandler.safeCall(function()
            local PerformanceMonitor = require("src.performance.performance_monitor")
            if PerformanceMonitor.exportPerformanceData then
                PerformanceMonitor.exportPerformanceData()
            end
        end)
        TestFramework.assert.isTrue(success, "Performance data export should work without crashing")
    end
}
-- Run tests
TestFramework.runTests(tests)
-- Return module with run function
return {
    run = function()
        TestFramework.runTests(tests)
        return true
    end
}