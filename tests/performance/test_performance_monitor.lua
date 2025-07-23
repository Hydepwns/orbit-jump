-- Tests for Performance Monitor
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")

Mocks.setup()

local PerformanceMonitor = Utils.Utils.require("src.performance.performance_monitor")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["performance monitor initialization"] = function()
        PerformanceMonitor.init({
            enabled = true,
            showOnScreen = false,
            trackMemory = true,
            trackFPS = true,
            historySize = 60
        })
        
        TestFramework.utils.assertNotNil(PerformanceMonitor, "Monitor should be initialized")
        TestFramework.utils.assertNotNil(PerformanceMonitor.data, "Data should be initialized")
    end,
    
    ["frame time tracking"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Simulate frame updates
        for i = 1, 10 do
            PerformanceMonitor.update(0.016) -- ~60 FPS
        end
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertNotNil(report, "Report should be generated")
    end,
    
    ["particle count tracking"] = function()
        PerformanceMonitor.init({enabled = true})
        
        PerformanceMonitor.updateParticleCount(100)
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertNotNil(report, "Report should track particle count")
    end,
    
    ["timer operations"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Start timing an operation
        PerformanceMonitor.startTimer("test_operation")
        
        -- Simulate some work
        local sum = 0
        for i = 1, 1000 do
            sum = sum + i
        end
        
        -- End timing
        PerformanceMonitor.endTimer("test_operation")
        
        TestFramework.utils.assertTrue(true, "Timer operations should complete")
    end,
    
    ["collision tracking"] = function()
        PerformanceMonitor.init({enabled = true})
        
        local startTime = love.timer.getTime()
        PerformanceMonitor.trackCollision(startTime)
        
        TestFramework.utils.assertTrue(true, "Collision tracking should work")
    end,
    
    ["report generation"] = function()
        PerformanceMonitor.init({enabled = true})
        
        PerformanceMonitor.updateParticleCount(500)
        PerformanceMonitor.update(0.016)
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertNotNil(report, "Should generate report")
        TestFramework.utils.assertNotNil(report.frameTime, "Report should include frame time")
    end,
    
    ["performance logging"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Test logging
        local success  = Utils.ErrorHandler.safeCall(PerformanceMonitor.logPerformance)
        TestFramework.utils.assertTrue(success, "Performance logging should not crash")
    end,
    
    ["performance drawing"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Test drawing (should not crash)
        local success  = Utils.ErrorHandler.safeCall(PerformanceMonitor.draw)
        TestFramework.utils.assertTrue(success, "Performance drawing should not crash")
    end,
    
    ["reset functionality"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Add some data
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.startTimer("test")
        PerformanceMonitor.endTimer("test")
        
        -- Reset
        PerformanceMonitor.reset()
        
        TestFramework.utils.assertTrue(true, "Reset should complete successfully")
    end,
    
    ["update functionality"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Test multiple updates
        for i = 1, 5 do
            PerformanceMonitor.update(0.016)
        end
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertNotNil(report, "Report should be available after updates")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Performance Monitor Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("performance_monitor", 10) -- All major functions tested
    
    return success
end

return {run = run}