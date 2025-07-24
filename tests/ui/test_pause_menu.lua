-- Test file for Pause Menu System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["test pause menu initialization"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        TestFramework.assert.equal(false, PauseMenu.isPaused, "Should start unpaused")
        TestFramework.assert.equal(1, PauseMenu.selectedOption, "Should start with first option selected")
        TestFramework.assert.equal(0, PauseMenu.fadeAlpha, "Should start with no fade")
    end,

    ["test pause functionality"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        PauseMenu.pause()
        
        TestFramework.assert.equal(true, PauseMenu.isPaused, "Should be paused")
        TestFramework.assert.equal(1, PauseMenu.selectedOption, "Should reset to first option")
    end,

    ["test resume functionality"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        PauseMenu.pause()
        PauseMenu.resume()
        
        TestFramework.assert.equal(false, PauseMenu.isPaused, "Should be unpaused")
    end,

    ["test toggle functionality"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        -- Toggle from unpaused to paused
        PauseMenu.toggle()
        TestFramework.assert.equal(true, PauseMenu.isPaused, "Should be paused after toggle")
        
        -- Toggle from paused to unpaused
        PauseMenu.toggle()
        TestFramework.assert.equal(false, PauseMenu.isPaused, "Should be unpaused after second toggle")
    end,

    ["test menu options structure"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        
        TestFramework.assert.notNil(PauseMenu.options, "Options should exist")
        TestFramework.assert.equal(5, #PauseMenu.options, "Should have 5 menu options")
        
        -- Check option structure
        for i, option in ipairs(PauseMenu.options) do
            TestFramework.assert.notNil(option.text, "Option " .. i .. " should have text")
            TestFramework.assert.notNil(option.action, "Option " .. i .. " should have action")
            TestFramework.assert.equal("function", type(option.action), "Option " .. i .. " action should be function")
        end
    end,

    ["test menu option texts"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        
        local expectedTexts = {"Resume", "Settings", "Save Game", "Main Menu", "Quit"}
        
        for i, expectedText in ipairs(expectedTexts) do
            TestFramework.assert.equal(expectedText, PauseMenu.options[i].text, 
                "Option " .. i .. " should have correct text")
        end
    end,

    ["test fade update when paused"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        PauseMenu.pause()
        local initialAlpha = PauseMenu.fadeAlpha
        
        PauseMenu.update(0.1) -- 0.1 seconds
        
        TestFramework.assert.greaterThan(initialAlpha, PauseMenu.fadeAlpha, "Fade should increase when paused")
    end,

    ["test fade update when unpaused"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        PauseMenu.pause()
        PauseMenu.update(0.2) -- Build up some fade
        local initialAlpha = PauseMenu.fadeAlpha
        
        PauseMenu.resume()
        PauseMenu.update(0.1) -- 0.1 seconds
        
        TestFramework.assert.lessThan(initialAlpha, PauseMenu.fadeAlpha, "Fade should decrease when unpaused")
    end,

    ["test fade limits"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        -- Test maximum fade
        PauseMenu.pause()
        PauseMenu.update(1.0) -- Long enough to reach max
        TestFramework.assert.lessThanOrEqual(1.0, PauseMenu.fadeAlpha, "Fade should not exceed 1.0")
        
        -- Test minimum fade
        PauseMenu.resume()
        PauseMenu.update(1.0) -- Long enough to reach min
        TestFramework.assert.greaterThanOrEqual(0.0, PauseMenu.fadeAlpha, "Fade should not go below 0.0")
    end,

    ["test keyboard navigation up"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        PauseMenu.selectedOption = 3
        PauseMenu.keypressed("up")
        
        TestFramework.assert.equal(2, PauseMenu.selectedOption, "Should move up one option")
    end,

    ["test keyboard navigation down"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        PauseMenu.selectedOption = 2
        PauseMenu.keypressed("down")
        
        TestFramework.assert.equal(3, PauseMenu.selectedOption, "Should move down one option")
    end,

    ["test keyboard navigation limits"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Test upper limit
        PauseMenu.selectedOption = 1
        PauseMenu.keypressed("up")
        TestFramework.assert.equal(1, PauseMenu.selectedOption, "Should not go below option 1")
        
        -- Test lower limit
        PauseMenu.selectedOption = #PauseMenu.options
        PauseMenu.keypressed("down")
        TestFramework.assert.equal(#PauseMenu.options, PauseMenu.selectedOption, "Should not go above last option")
    end,

    ["test pause key detection"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        -- Test escape key
        local result = PauseMenu.keypressed("escape")
        TestFramework.assert.equal(true, result, "Should handle escape key")
        TestFramework.assert.equal(true, PauseMenu.isPaused, "Should pause on escape")
        
        PauseMenu.resume()
        
        -- Test p key
        result = PauseMenu.keypressed("p")
        TestFramework.assert.equal(true, result, "Should handle p key")
        TestFramework.assert.equal(true, PauseMenu.isPaused, "Should pause on p")
    end,

    ["test resume on escape when paused"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        local result = PauseMenu.keypressed("escape")
        
        TestFramework.assert.equal(true, result, "Should handle escape key when paused")
        TestFramework.assert.equal(false, PauseMenu.isPaused, "Should resume on escape when paused")
    end,

    ["test option selection with enter"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock the resume function to track if it's called
        local resumeCalled = false
        local originalResume = PauseMenu.resume
        PauseMenu.resume = function()
            resumeCalled = true
        end
        
        PauseMenu.selectedOption = 1 -- Resume option
        PauseMenu.keypressed("return")
        
        TestFramework.assert.equal(true, resumeCalled, "Should call resume action when enter pressed")
        
        -- Restore original function
        PauseMenu.resume = originalResume
    end,

    ["test option selection with space"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock the resume function to track if it's called
        local resumeCalled = false
        local originalResume = PauseMenu.resume
        PauseMenu.resume = function()
            resumeCalled = true
        end
        
        PauseMenu.selectedOption = 1 -- Resume option
        PauseMenu.keypressed("space")
        
        TestFramework.assert.equal(true, resumeCalled, "Should call resume action when space pressed")
        
        -- Restore original function
        PauseMenu.resume = originalResume
    end,

    ["test input consumption when paused"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        local result = PauseMenu.keypressed("a")
        
        TestFramework.assert.equal(true, result, "Should consume all input when paused")
    end,

    ["test input not consumed when unpaused"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        local result = PauseMenu.keypressed("a")
        
        TestFramework.assert.equal(false, result, "Should not consume input when unpaused")
    end,

    ["test mouse click detection"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock screen dimensions
        Mocks.love.graphics.getWidth = function() return 800 end
        Mocks.love.graphics.getHeight = function() return 600 end
        
        local result = PauseMenu.mousepressed(400, 300, 1)
        
        TestFramework.assert.equal(true, result, "Should handle mouse clicks when paused")
    end,

    ["test mouse click not handled when unpaused"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        local result = PauseMenu.mousepressed(400, 300, 1)
        
        TestFramework.assert.equal(false, result, "Should not handle mouse clicks when unpaused")
    end,

    ["test should pause gameplay"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        
        -- Should not pause when unpaused
        TestFramework.assert.equal(false, PauseMenu.shouldPauseGameplay(), "Should not pause gameplay when unpaused")
        
        -- Should pause when paused with sufficient fade
        PauseMenu.pause()
        PauseMenu.fadeAlpha = 0.5
        TestFramework.assert.equal(true, PauseMenu.shouldPauseGameplay(), "Should pause gameplay when paused with fade")
        
        -- Should not pause when fade is too low
        PauseMenu.fadeAlpha = 0.05
        TestFramework.assert.equal(false, PauseMenu.shouldPauseGameplay(), "Should not pause gameplay with low fade")
    end,

    ["test menu option actions exist"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        
        for i, option in ipairs(PauseMenu.options) do
            TestFramework.assert.notNil(option.action, "Option " .. i .. " should have action")
            TestFramework.assert.equal("function", type(option.action), "Option " .. i .. " action should be function")
        end
    end,

    ["test resume option action"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Test that resume option calls resume
        local resumeCalled = false
        local originalResume = PauseMenu.resume
        PauseMenu.resume = function()
            resumeCalled = true
        end
        
        PauseMenu.options[1].action()
        
        TestFramework.assert.equal(true, resumeCalled, "Resume option should call resume function")
        
        -- Restore original function
        PauseMenu.resume = originalResume
    end,

    ["test settings option action"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock SettingsMenu
        local settingsMenuCalled = false
        local resumeCalled = false
        
        local originalRequire = Utils.require
        Utils.require = function(module)
            if module == "src.ui.settings_menu" then
                return {
                    toggle = function()
                        settingsMenuCalled = true
                    end
                }
            end
            return originalRequire(module)
        end
        
        local originalResume = PauseMenu.resume
        PauseMenu.resume = function()
            resumeCalled = true
        end
        
        PauseMenu.options[2].action()
        
        TestFramework.assert.equal(true, settingsMenuCalled, "Settings option should call settings menu")
        TestFramework.assert.equal(true, resumeCalled, "Settings option should call resume")
        
        -- Restore original functions
        Utils.require = originalRequire
        PauseMenu.resume = originalResume
    end,

    ["test save game option action"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock SaveSystem
        local saveCalled = false
        local originalRequire = Utils.require
        Utils.require = function(module)
            if module == "src.systems.save_system" then
                return {
                    save = function()
                        saveCalled = true
                    end
                }
            end
            return originalRequire(module)
        end
        
        PauseMenu.options[3].action()
        
        TestFramework.assert.equal(true, saveCalled, "Save Game option should call save system")
        
        -- Restore original function
        Utils.require = originalRequire
    end,

    ["test main menu option action"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock love.event.quit
        local quitCalled = false
        local originalQuit = Mocks.love.event.quit
        Mocks.love.event.quit = function(restart)
            quitCalled = true
            TestFramework.assert.equal("restart", restart, "Should call quit with restart parameter")
        end
        
        PauseMenu.options[4].action()
        
        TestFramework.assert.equal(true, quitCalled, "Main Menu option should call quit with restart")
        
        -- Restore original function
        Mocks.love.event.quit = originalQuit
    end,

    ["test quit option action"] = function()
        local PauseMenu = Utils.require("src.ui.pause_menu")
        PauseMenu.init()
        PauseMenu.pause()
        
        -- Mock love.event.quit
        local quitCalled = false
        local originalQuit = Mocks.love.event.quit
        Mocks.love.event.quit = function()
            quitCalled = true
        end
        
        PauseMenu.options[5].action()
        
        TestFramework.assert.equal(true, quitCalled, "Quit option should call quit")
        
        -- Restore original function
        Mocks.love.event.quit = originalQuit
    end
}

-- Run tests
TestFramework.runTests(tests) 