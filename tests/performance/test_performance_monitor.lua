-- Comprehensive tests for Performance Monitor
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
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
-- Function to get PerformanceMonitor with proper initialization
local function getPerformanceMonitor()
    -- Clear any cached version
    package.loaded["src.performance.performance_monitor"] = nil
    package.loaded["src/performance/performance_monitor"] = nil
    -- Also clear from Utils cache (CRITICAL!)
    if Utils.moduleCache then
        Utils.moduleCache["src.performance.performance_monitor"] = nil
    end
    -- Setup mocks before loading
    Mocks.setup()
    -- Mock Utils.Logger to prevent failures
    if not Utils.Logger then
        Utils.Logger = {}
    end
    Utils.Logger.info = function(...) end
    -- Mock Utils.setColor to prevent failures
    if not Utils.setColor then
        Utils.setColor = function(...) end
    end
    -- Mock additional graphics functions if they're not already mocked
    if not love.graphics.rectangle then
        love.graphics.rectangle = function(...) end
    end
    if not love.graphics.print then
        love.graphics.print = function(...) end
    end
    -- Load fresh instance using regular require to bypass cache
    local PerformanceMonitor = require("src.performance.performance_monitor")
    -- Ensure it's initialized
    if PerformanceMonitor and PerformanceMonitor.init then
        PerformanceMonitor.init()
    end
    return PerformanceMonitor
end
-- Test suite
local tests = {
    ["test initialization"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({
            enabled = true,
            showOnScreen = false,
            trackMemory = true,
            trackCollisions = true,
            sampleSize = 60,
            logInterval = 5.0
        })
        TestFramework.assert.notNil(PerformanceMonitor, "Monitor should be initialized")
        TestFramework.assert.isTrue(PerformanceMonitor.config.enabled, "Should be enabled")
        TestFramework.assert.isFalse(PerformanceMonitor.config.showOnScreen, "Should not show on screen")
        TestFramework.assert.isTrue(PerformanceMonitor.config.trackMemory, "Should track memory")
        TestFramework.assert.equal(60, PerformanceMonitor.config.sampleSize, "Sample size should be 60")
    end,
    ["test fps tracking"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true})
        -- Simulate 60 FPS
        for i = 1, 10 do
            PerformanceMonitor.update(1/60) -- 16.67ms
        end
        local report = PerformanceMonitor.getReport()
        TestFramework.assert.notNil(report.fps, "Should have FPS data")
        TestFramework.assert.isTrue(report.fps.current > 59 and report.fps.current < 61,
            "Current FPS should be around 60")
        TestFramework.assert.isTrue(report.fps.average > 59 and report.fps.average < 61,
            "Average FPS should be around 60")
    end,
    ["test frame time tracking"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true})
        -- Simulate varying frame times
        local frameTimes = {0.016, 0.017, 0.015, 0.018, 0.016}
        for _, dt in ipairs(frameTimes) do
            PerformanceMonitor.update(dt)
        end
        local report = PerformanceMonitor.getReport()
        TestFramework.assert.notNil(report.frameTime, "Should have frame time data")
        TestFramework.assert.isTrue(report.frameTime.current > 0, "Current frame time should be positive")
        TestFramework.assert.isTrue(report.frameTime.min <= report.frameTime.max,
            "Min should be less than or equal to max")
    end,
    ["test memory tracking"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true, trackMemory = true})
        -- Simulate memory changes
        mockMemoryUsage = 1024
        PerformanceMonitor.update(0.016)
        mockMemoryUsage = 2048
        PerformanceMonitor.update(0.016)
        local report = PerformanceMonitor.getReport()
        TestFramework.assert.equal(2048, report.memory.current, "Current memory should be 2048 KB")
        TestFramework.assert.equal(2048, report.memory.peak, "Peak memory should be 2048 KB")
    end,
    ["test particle count tracking"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true})
        PerformanceMonitor.updateParticleCount(100)
        PerformanceMonitor.updateParticleCount(200)
        PerformanceMonitor.updateParticleCount(150)
        local report = PerformanceMonitor.getReport()
        TestFramework.assert.equal(150, report.particles.current, "Current particles should be 150")
        TestFramework.assert.equal(200, report.particles.peak, "Peak particles should be 200")
    end,
    ["test collision tracking"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
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
        TestFramework.assert.equal(5, report.collisions.count, "Should have 5 collision checks")
        TestFramework.assert.isTrue(report.collisions.time > 0, "Should have collision time tracked")
    end,
    ["test timer operations"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true})
        -- Mock timer
        local mockTime = 0
        love.timer.getTime = function() return mockTime end
        -- Test game logic timer
        PerformanceMonitor.startTimer("gameLogic")
        mockTime = mockTime + 0.005 -- 5ms
        local duration = PerformanceMonitor.endTimer("gameLogic")
        TestFramework.assert.equal(0.005, duration, "Should return timer duration")
        local report = PerformanceMonitor.getReport()
        TestFramework.assert.equal(0.005, report.updateTimes.gameLogic,
            "Should track game logic time")
        -- Test rendering timer
        PerformanceMonitor.startTimer("rendering")
        mockTime = mockTime + 0.003 -- 3ms
        PerformanceMonitor.endTimer("rendering")
        report = PerformanceMonitor.getReport()
        TestFramework.assert.equal(0.003, report.updateTimes.rendering,
            "Should track rendering time")
    end,
    ["test reset functionality"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true})
        -- Add some data
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(100)
        PerformanceMonitor.startTimer("test")
        -- Reset
        PerformanceMonitor.reset()
        TestFramework.assert.equal(math.huge, PerformanceMonitor.metrics.fps.min,
            "FPS min should be reset")
        TestFramework.assert.equal(0, PerformanceMonitor.metrics.fps.max,
            "FPS max should be reset")
        TestFramework.assert.equal(0, #PerformanceMonitor.metrics.fps.samples,
            "FPS samples should be cleared")
        TestFramework.assert.equal(0, PerformanceMonitor.metrics.particleCount.peak,
            "Particle peak should be reset")
    end,
    ["test disabled state"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = false})
        -- Try various operations while disabled
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(100)
        PerformanceMonitor.startTimer("test")
        local duration = PerformanceMonitor.endTimer("test")
        PerformanceMonitor.trackCollision(0)
        TestFramework.assert.equal(0, duration, "Timer should return 0 when disabled")
        -- Draw should not crash
        local success = pcall(function()
            PerformanceMonitor.draw()
        end)
        TestFramework.assert.isTrue(success, "Draw should not crash when disabled")
    end,
    ["test sample size limit"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true, sampleSize = 5})
        -- Add more samples than the limit
        for i = 1, 10 do
            PerformanceMonitor.update(0.016)
        end
        TestFramework.assert.equal(5, #PerformanceMonitor.metrics.fps.samples,
            "FPS samples should be limited to 5")
        TestFramework.assert.equal(5, #PerformanceMonitor.metrics.frameTime.samples,
            "Frame time samples should be limited to 5")
    end,
    ["test performance logging"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true, logInterval = 0.1})
        local logCalled = false
        local oldLog = Utils.Logger.info
        Utils.Logger.info = function(...)
            logCalled = true
        end
        -- Update past the log interval
        PerformanceMonitor.update(0.15)
        TestFramework.assert.isTrue(logCalled, "Should log performance")
        -- Restore logger
        Utils.Logger.info = oldLog
    end,
    ["test draw overlay"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true, showOnScreen = true})
        -- Add some data
        PerformanceMonitor.update(0.016)
        PerformanceMonitor.updateParticleCount(50)
        -- Test draw - should not crash
        local success = pcall(function()
            PerformanceMonitor.draw()
        end)
        TestFramework.assert.isTrue(success, "Draw should not crash")
        -- Test with low FPS warning
        PerformanceMonitor.update(0.05) -- 20 FPS
        success = pcall(function()
            PerformanceMonitor.draw()
        end)
        TestFramework.assert.isTrue(success, "Draw should handle low FPS warning")
    end,
    ["test comprehensive report"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
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
        TestFramework.assert.notNil(report.fps, "Report should have FPS data")
        TestFramework.assert.notNil(report.frameTime, "Report should have frame time data")
        TestFramework.assert.notNil(report.memory, "Report should have memory data")
        TestFramework.assert.notNil(report.particles, "Report should have particle data")
        TestFramework.assert.notNil(report.collisions, "Report should have collision data")
        TestFramework.assert.notNil(report.updateTimes, "Report should have update times")
    end,
    ["test edge cases"] = function()
        local PerformanceMonitor = getPerformanceMonitor()
        PerformanceMonitor.init({enabled = true})
        -- Test with very small dt (high FPS)
        PerformanceMonitor.update(0.001) -- 1000 FPS
        local report = PerformanceMonitor.getReport()
        TestFramework.assert.isTrue(report.fps.current > 900, "Should handle high FPS")
        -- Test with very large dt (low FPS)
        PerformanceMonitor.update(1.0) -- 1 FPS
        report = PerformanceMonitor.getReport()
        TestFramework.assert.isTrue(report.fps.current <= 1, "Should handle low FPS")
        -- Test ending timer that wasn't started
        local duration = PerformanceMonitor.endTimer("nonexistent")
        TestFramework.assert.equal(0, duration, "Should return 0 for nonexistent timer")
    end
}
-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Performance Monitor Tests")
    -- Restore collectgarbage
    collectgarbage = oldCollectgarbage
    return success
end
return {run = run}