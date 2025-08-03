-- Tests for Dev Tools
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
local DevTools = Utils.require("src.dev.dev_tools")
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    ["dev tools initialization"] = function()
        DevTools.init()
        TestFramework.assert.assertNotNil(DevTools.state, "Dev tools state should exist")
        TestFramework.assert.assertNotNil(DevTools.state.debugMode, "Debug mode flag should exist")
        TestFramework.assert.assertFalse(DevTools.state.debugMode, "Debug mode should be off initially")
        TestFramework.assert.assertFalse(DevTools.state.showHitboxes, "Hitboxes should be off initially")
        TestFramework.assert.assertFalse(DevTools.state.showPerformance, "Performance should be off initially")
        TestFramework.assert.assertFalse(DevTools.state.paused, "Game should not be paused initially")
    end,
    ["toggle debug mode"] = function()
        DevTools.init()
        local initial = DevTools.state.debugMode
        DevTools.handleInput("f1")
        TestFramework.assert.assertEqual(not initial, DevTools.state.debugMode, "Should toggle debug mode")
        DevTools.handleInput("f1")
        TestFramework.assert.assertEqual(initial, DevTools.state.debugMode, "Should toggle back")
    end,
    ["toggle hitboxes"] = function()
        DevTools.init()
        local initial = DevTools.state.showHitboxes
        DevTools.handleInput("f2")
        TestFramework.assert.assertEqual(not initial, DevTools.state.showHitboxes, "Should toggle hitboxes")
    end,
    ["toggle performance overlay"] = function()
        DevTools.init()
        local initial = DevTools.state.showPerformance
        DevTools.handleInput("f3")
        TestFramework.assert.assertEqual(not initial, DevTools.state.showPerformance, "Should toggle performance")
    end,
    ["toggle debug info"] = function()
        DevTools.init()
        local initial = DevTools.state.showDebugInfo
        DevTools.handleInput("f4")
        TestFramework.assert.assertEqual(not initial, DevTools.state.showDebugInfo, "Should toggle debug info")
    end,
    ["pause game"] = function()
        DevTools.init()
        local initial = DevTools.state.paused
        DevTools.handleInput("f5")
        TestFramework.assert.assertEqual(not initial, DevTools.state.paused, "Should toggle pause")
    end,
    ["toggle slow motion"] = function()
        DevTools.init()
        local initial = DevTools.state.slowMotion
        DevTools.handleInput("f6")
        TestFramework.assert.assertEqual(not initial, DevTools.state.slowMotion, "Should toggle slow motion")
    end,
    ["update with slow motion"] = function()
        DevTools.init()
        DevTools.state.slowMotion = true
        local dt = 0.016 -- 60 FPS
        local modifiedDt = DevTools.update(dt)
        TestFramework.assert.assertEqual(dt * DevTools.state.slowMotionFactor, modifiedDt, "Should apply slow motion factor")
    end,
    ["update without slow motion"] = function()
        DevTools.init()
        DevTools.state.slowMotion = false
        local dt = 0.016
        local modifiedDt = DevTools.update(dt)
        TestFramework.assert.assertEqual(dt, modifiedDt, "Should not modify dt")
    end,
    ["update when paused"] = function()
        DevTools.init()
        DevTools.state.paused = true
        local dt = 0.016
        local modifiedDt = DevTools.update(dt)
        TestFramework.assert.assertEqual(0, modifiedDt, "Should return 0 when paused")
    end,
    ["draw does not error"] = function()
        DevTools.init()
        DevTools.state.debugMode = true
        -- Should not throw any errors
        TestFramework.assert.assertNotNil(DevTools.draw, "Draw function should exist")
        -- Mock GameState for drawing
        local mockGameState = {
            player = {x = 100, y = 100, radius = 10, vx = 50, vy = 50},
            getPlanets = function() return {{x = 200, y = 200, radius = 50}} end,
            getRings = function() return {{x = 300, y = 300, radius = 30, innerRadius = 20, collected = false}} end,
            getScore = function() return 100 end,
            getCombo = function() return 5 end,
            getGameTime = function() return 10.5 end,
            getParticles = function() return {} end
        }
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then
                return mockGameState
            else
                return oldRequire(path)
            end
        end
        -- Test drawing functions
        local success = pcall(function()
            DevTools.debugDraw.hitboxes()
            DevTools.debugDraw.vectors()
            DevTools.debugDraw.info()
        end)
        TestFramework.assert.assertTrue(success, "Drawing functions should not error")
        -- Restore
        Utils.require = oldRequire
    end,
    ["analyze performance"] = function()
        DevTools.init()
        -- Mock PerformanceMonitor
        local mockPerformanceMonitor = {
            getReport = function()
                return {
                    fps = {average = 60, min = 55, max = 65},
                    frameTime = {average = 16.67},
                    memory = {peak = 1024},
                    collisions = {count = 100, time = 0.001}
                }
            end
        }
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.performance.performance_monitor" then
                return mockPerformanceMonitor
            else
                return oldRequire(path)
            end
        end
        -- Should not error
        local success = pcall(function()
            DevTools.analyzePerformance()
        end)
        TestFramework.assert.assertTrue(success, "Performance analysis should not error")
        -- Restore
        Utils.require = oldRequire
    end,
    ["game reset"] = function()
        DevTools.init()
        local resetCalled = false
        local mockGameState = {
            reset = function()
                resetCalled = true
            end
        }
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then
                return mockGameState
            else
                return oldRequire(path)
            end
        end
        DevTools.resetGame()
        TestFramework.assert.assertTrue(resetCalled, "Game reset should be called")
        -- Restore
        Utils.require = oldRequire
    end,
    ["take screenshot"] = function()
        DevTools.init()
        -- Mock love.graphics.captureScreenshot
        local captureScreenshotCalled = false
        love.graphics.captureScreenshot = function(callback)
            captureScreenshotCalled = true
            -- Simulate successful screenshot
            local mockData = {
                encode = function(self, format, filename)
                    -- Do nothing
                end
            }
            callback(mockData)
            return true
        end
        DevTools.takeScreenshot()
        TestFramework.assert.assertTrue(captureScreenshotCalled, "Screenshot should be attempted")
    end,
    ["debug key handling"] = function()
        DevTools.init()
        -- Test all F-keys
        local keys = {"f1", "f2", "f3", "f4", "f5", "f6"}
        for _, key in ipairs(keys) do
            local success = pcall(function()
                DevTools.handleInput(key)
            end)
            TestFramework.assert.assertTrue(success, "Handling " .. key .. " should not error")
        end
    end
}
-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Dev Tools Tests")
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("dev_tools", 15) -- All major functions tested
    return success
end
return {run = run}