-- Comprehensive tests for Performance Monitor
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock collectgarbage
local mockMemoryUsage = 1024
local oldCollectgarbage = collectgarbage
collectgarbage = function(command)
    if command == "count" then
        return mockMemoryUsage
    else
        return oldCollectgarbage(command)
    end
end

local PerformanceMonitor = Utils.require("src.performance.performance_monitor")

-- Test suite
local tests = {
    ["test initialization"] = function()
        PerformanceMonitor.init({
            enabled = true,
            showOnScreen = false,
            trackMemory = true,
            trackCollisions = true,
            sampleSize = 60,
            logInterval = 5.0
        })
        
        TestFramework.utils.assertNotNil(PerformanceMonitor, "Monitor should be initialized")
        TestFramework.utils.assertTrue(PerformanceMonitor.config.enabled, "Should be enabled")
        TestFramework.utils.assertFalse(PerformanceMonitor.config.showOnScreen, "Should not show on screen")
        TestFramework.utils.assertTrue(PerformanceMonitor.config.trackMemory, "Should track memory")
        TestFramework.utils.assertEqual(60, PerformanceMonitor.config.sampleSize, "Sample size should be 60")
    end,
    
    ["test fps tracking"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Simulate 60 FPS
        for i = 1, 10 do
            PerformanceMonitor.update(1/60) -- 16.67ms
        end
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertNotNil(report.fps, "Should have FPS data")
        TestFramework.utils.assertTrue(report.fps.current > 59 and report.fps.current < 61, 
            "Current FPS should be around 60")
        TestFramework.utils.assertTrue(report.fps.average > 59 and report.fps.average < 61, 
            "Average FPS should be around 60")
    end,
    
    ["test frame time tracking"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Simulate varying frame times
        local frameTimes = {0.016, 0.017, 0.015, 0.018, 0.016}
        
        for _, dt in ipairs(frameTimes) do
            PerformanceMonitor.update(dt)
        end
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertNotNil(report.frameTime, "Should have frame time data")
        TestFramework.utils.assertTrue(report.frameTime.current > 0, "Current frame time should be positive")
        TestFramework.utils.assertTrue(report.frameTime.min <= report.frameTime.max, 
            "Min should be less than or equal to max")
    end,
    
    ["test memory tracking"] = function()
        PerformanceMonitor.init({enabled = true, trackMemory = true})
        
        -- Simulate memory changes
        mockMemoryUsage = 1024
        PerformanceMonitor.update(0.016)
        
        mockMemoryUsage = 2048
        PerformanceMonitor.update(0.016)
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertEqual(2048, report.memory.current, "Current memory should be 2048 KB")
        TestFramework.utils.assertEqual(2048, report.memory.peak, "Peak memory should be 2048 KB")
    end,
    
    ["test particle count tracking"] = function()
        PerformanceMonitor.init({enabled = true})
        
        PerformanceMonitor.updateParticleCount(100)
        PerformanceMonitor.updateParticleCount(200)
        PerformanceMonitor.updateParticleCount(150)
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertEqual(150, report.particles.current, "Current particles should be 150")
        TestFramework.utils.assertEqual(200, report.particles.peak, "Peak particles should be 200")
    end,
    
    ["test collision tracking"] = function()
        PerformanceMonitor.init({enabled = true, trackCollisions = true})
        
        -- Mock timer
        local mockTime = 0
        love.timer.getTime = function() return mockTime end
        
        -- Track multiple collisions
        for i = 1, 5 do
            local startTime = mockTime
            mockTime = mockTime + 0.001 -- 1ms per collision check
            PerformanceMonitor.trackCollision(startTime)
        end
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertEqual(5, report.collisions.count, "Should have 5 collision checks")
        TestFramework.utils.assertTrue(report.collisions.time > 0, "Should have collision time tracked")
    end,
    
    ["test timer operations"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Mock timer
        local mockTime = 0
        love.timer.getTime = function() return mockTime end
        
        -- Test game logic timer
        PerformanceMonitor.startTimer("gameLogic")
        mockTime = mockTime + 0.005 -- 5ms
        local duration = PerformanceMonitor.endTimer("gameLogic")
        
        TestFramework.utils.assertEqual(0.005, duration, "Should return timer duration")
        
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertEqual(0.005, report.updateTimes.gameLogic, 
            "Should track game logic time")
        
        -- Test rendering timer
        PerformanceMonitor.startTimer("rendering")
        mockTime = mockTime + 0.003 -- 3ms
        PerformanceMonitor.endTimer("rendering")
        
        report = PerformanceMonitor.getReport()
        TestFramework.utils.assertEqual(0.003, report.updateTimes.rendering, 
            "Should track rendering time")
    end,
    
    ["test reset functionality"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Add some data
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(100)
        PerformanceMonitor.startTimer("test")
        
        -- Reset
        PerformanceMonitor.reset()
        
        TestFramework.utils.assertEqual(math.huge, PerformanceMonitor.metrics.fps.min, 
            "FPS min should be reset")
        TestFramework.utils.assertEqual(0, PerformanceMonitor.metrics.fps.max, 
            "FPS max should be reset")
        TestFramework.utils.assertEqual(0, #PerformanceMonitor.metrics.fps.samples, 
            "FPS samples should be cleared")
        TestFramework.utils.assertEqual(0, PerformanceMonitor.metrics.particleCount.peak, 
            "Particle peak should be reset")
    end,
    
    ["test disabled state"] = function()
        PerformanceMonitor.init({enabled = false})
        
        -- Try various operations while disabled
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(100)
        PerformanceMonitor.startTimer("test")
        local duration = PerformanceMonitor.endTimer("test")
        PerformanceMonitor.trackCollision(0)
        
        TestFramework.utils.assertEqual(0, duration, "Timer should return 0 when disabled")
        
        -- Draw should not crash
        local success = pcall(function()
            PerformanceMonitor.draw()
        end)
        TestFramework.utils.assertTrue(success, "Draw should not crash when disabled")
    end,
    
    ["test sample size limit"] = function()
        PerformanceMonitor.init({enabled = true, sampleSize = 5})
        
        -- Add more samples than the limit
        for i = 1, 10 do
            PerformanceMonitor.update(0.016)
        end
        
        TestFramework.utils.assertEqual(5, #PerformanceMonitor.metrics.fps.samples, 
            "FPS samples should be limited to 5")
        TestFramework.utils.assertEqual(5, #PerformanceMonitor.metrics.frameTime.samples, 
            "Frame time samples should be limited to 5")
    end,
    
    ["test performance logging"] = function()
        PerformanceMonitor.init({enabled = true, logInterval = 0.1})
        
        local logCalled = false
        local oldLog = Utils.Logger.info
        Utils.Logger.info = function(...)
            logCalled = true
        end
        
        -- Update past the log interval
        PerformanceMonitor.update(0.15)
        
        TestFramework.utils.assertTrue(logCalled, "Should log performance")
        
        -- Restore logger
        Utils.Logger.info = oldLog
    end,
    
    ["test draw overlay"] = function()
        PerformanceMonitor.init({enabled = true, showOnScreen = true})
        
        -- Add some data
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(50)
        
        -- Test draw - should not crash
        local success = pcall(function()
            PerformanceMonitor.draw()
        end)
        TestFramework.utils.assertTrue(success, "Draw should not crash")
        
        -- Test with low FPS warning
        PerformanceMonitor.update(0.05) -- 20 FPS
        success = pcall(function()
            PerformanceMonitor.draw()
        end)
        TestFramework.utils.assertTrue(success, "Draw should handle low FPS warning")
    end,
    
    ["test comprehensive report"] = function()
        PerformanceMonitor.init({
            enabled = true,
            trackMemory = true,
            trackCollisions = true
        })
        
        -- Mock timer
        local mockTime = 0
        love.timer.getTime = function() return mockTime end
        
        -- Add various metrics
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(75)
        
        PerformanceMonitor.startTimer("gameLogic")
        mockTime = mockTime + 0.002
        PerformanceMonitor.endTimer("gameLogic")
        
        PerformanceMonitor.trackCollision(mockTime)
        mockTime = mockTime + 0.001
        
        local report = PerformanceMonitor.getReport()
        
        -- Verify all sections exist
        TestFramework.utils.assertNotNil(report.fps, "Report should have FPS data")
        TestFramework.utils.assertNotNil(report.frameTime, "Report should have frame time data")
        TestFramework.utils.assertNotNil(report.memory, "Report should have memory data")
        TestFramework.utils.assertNotNil(report.particles, "Report should have particle data")
        TestFramework.utils.assertNotNil(report.collisions, "Report should have collision data")
        TestFramework.utils.assertNotNil(report.updateTimes, "Report should have update times")
    end,
    
    ["test edge cases"] = function()
        PerformanceMonitor.init({enabled = true})
        
        -- Test with very small dt (high FPS)
        PerformanceMonitor.update(0.001) -- 1000 FPS
        local report = PerformanceMonitor.getReport()
        TestFramework.utils.assertTrue(report.fps.current > 900, "Should handle high FPS")
        
        -- Test with very large dt (low FPS)
        PerformanceMonitor.update(1.0) -- 1 FPS
        report = PerformanceMonitor.getReport()
        TestFramework.utils.assertTrue(report.fps.current <= 1, "Should handle low FPS")
        
        -- Test ending timer that wasn't started
        local duration = PerformanceMonitor.endTimer("nonexistent")
        TestFramework.utils.assertEqual(0, duration, "Should return 0 for nonexistent timer")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Performance Monitor Tests", tests)
    
    -- Restore collectgarbage
    collectgarbage = oldCollectgarbage
    
    return success
end

return {run = run}