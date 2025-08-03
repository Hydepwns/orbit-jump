-- Test file for Settings Menu System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Mock sound manager
local originalRequire = Utils.require
Utils.require = function(module)
    if module == "src.audio.sound_manager" then
        return {
            setVolume = function(volume) end
        }
    elseif module == "src.performance.performance_system" then
        return {
            config = {
                showDebug = false
            }
        }
    elseif module == "src.core.camera" then
        return {
            enableShake = true
        }
    elseif module == "src.systems.save_system" then
        return {
            autoSaveInterval = 60
        }
    elseif module == "libs.json" then
        return {
            encode = function(data) return "{}" end,
            decode = function(data) return {} end
        }
    end
    return originalRequire(module)
end
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    ["test settings menu initialization"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        -- Reset state before init to ensure clean test
        SettingsMenu.isVisible = false
        SettingsMenu.selectedTab = 1
        SettingsMenu.selectedOption = 1
        SettingsMenu.fadeAlpha = 0
        SettingsMenu.unsavedChanges = false
        SettingsMenu.init()
        TestFramework.assert.notNil(SettingsMenu.current, "Should have current settings")
        TestFramework.assert.notNil(SettingsMenu.defaults, "Should have default settings")
        TestFramework.assert.equal(1, SettingsMenu.selectedTab, "Should start at tab 1")
        TestFramework.assert.equal(1, SettingsMenu.selectedOption, "Should start at option 1")
    end,
    ["test settings tabs structure"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        TestFramework.assert.notNil(SettingsMenu.tabs, "Tabs should exist")
        TestFramework.assert.equal(4, #SettingsMenu.tabs, "Should have 4 tabs")
        local expectedTabs = {
            {name = "Audio", icon = "🔊"},
            {name = "Controls", icon = "🎮"},
            {name = "Graphics", icon = "🖼️"},
            {name = "Gameplay", icon = "⚙️"}
        }
        for i, expectedTab in ipairs(expectedTabs) do
            TestFramework.assert.equal(expectedTab.name, SettingsMenu.tabs[i].name,
                "Tab " .. i .. " should have correct name")
            TestFramework.assert.equal(expectedTab.icon, SettingsMenu.tabs[i].icon,
                "Tab " .. i .. " should have correct icon")
        end
    end,
    ["test default settings structure"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        TestFramework.assert.notNil(SettingsMenu.defaults, "Defaults should exist")
        -- Check that all expected settings exist
        local expectedSettings = {
            "masterVolume", "soundVolume", "musicVolume",
            "dashKey1", "dashKey2", "dashKey3", "mapKey", "upgradeKey", "loreKey", "pauseKey",
            "particleQuality", "showFPS", "screenShake", "fullscreen", "vsync",
            "autoSave", "autoSaveInterval", "tutorialHints", "mobileControls", "cameraZoom"
        }
        for _, setting in ipairs(expectedSettings) do
            TestFramework.assert.notNil(SettingsMenu.defaults[setting],
                "Default setting " .. setting .. " should exist")
        end
    end,
    ["test default settings values"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        -- Test specific default values
        TestFramework.assert.equal(1.0, SettingsMenu.defaults.masterVolume, "Master volume should default to 1.0")
        TestFramework.assert.equal(1.0, SettingsMenu.defaults.soundVolume, "Sound volume should default to 1.0")
        TestFramework.assert.equal(0.5, SettingsMenu.defaults.musicVolume, "Music volume should default to 0.5")
        TestFramework.assert.equal("lshift", SettingsMenu.defaults.dashKey1, "Dash key 1 should default to lshift")
        TestFramework.assert.equal("escape", SettingsMenu.defaults.pauseKey, "Pause key should default to escape")
        TestFramework.assert.equal(false, SettingsMenu.defaults.showFPS, "Show FPS should default to false")
        TestFramework.assert.equal(true, SettingsMenu.defaults.screenShake, "Screen shake should default to true")
        TestFramework.assert.equal(true, SettingsMenu.defaults.autoSave, "Auto save should default to true")
        TestFramework.assert.equal(60, SettingsMenu.defaults.autoSaveInterval, "Auto save interval should default to 60")
    end,
    ["test toggle functionality"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Ensure we start in a known state
        SettingsMenu.isVisible = false
        -- Toggle from invisible to visible
        SettingsMenu.toggle()
        TestFramework.assert.equal(true, SettingsMenu.isVisible, "Should be visible after toggle")
        TestFramework.assert.equal(1, SettingsMenu.selectedTab, "Should reset to first tab")
        TestFramework.assert.equal(1, SettingsMenu.selectedOption, "Should reset to first option")
        -- Toggle from visible to invisible
        SettingsMenu.toggle()
        TestFramework.assert.equal(false, SettingsMenu.isVisible, "Should be invisible after second toggle")
    end,
    ["test auto save on close with unsaved changes"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Mock save function
        local saveCalled = false
        local applyCalled = false
        local originalSave = SettingsMenu.save
        local originalApply = SettingsMenu.applySettings
        SettingsMenu.save = function()
            saveCalled = true
        end
        SettingsMenu.applySettings = function()
            applyCalled = true
        end
        -- Set unsaved changes and toggle
        SettingsMenu.unsavedChanges = true
        SettingsMenu.toggle() -- Open
        SettingsMenu.toggle() -- Close
        TestFramework.assert.equal(true, saveCalled, "Should call save when closing with unsaved changes")
        TestFramework.assert.equal(true, applyCalled, "Should call apply settings when closing with unsaved changes")
        -- Restore original functions
        SettingsMenu.save = originalSave
        SettingsMenu.applySettings = originalApply
    end,
    ["test fade update when visible"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        -- Reset state completely before init
        SettingsMenu.fadeAlpha = 0
        SettingsMenu.isVisible = false
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.fadeAlpha = 0 -- Ensure we start from 0
        SettingsMenu.update(0.1) -- 0.1 seconds
        -- fadeAlpha increases by dt * 5, so after 0.1s it should be 0.5
        TestFramework.assert.equal(0.5, SettingsMenu.fadeAlpha, "Fade should increase to 0.5 when visible")
        -- Test it caps at 1.0
        SettingsMenu.update(1.0) -- Another second
        TestFramework.assert.equal(1.0, SettingsMenu.fadeAlpha, "Fade should cap at 1.0")
    end,
    ["test fade update when invisible"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.update(0.2) -- Build up some fade
        local initialAlpha = SettingsMenu.fadeAlpha
        SettingsMenu.isVisible = false
        SettingsMenu.update(0.1) -- 0.1 seconds
        TestFramework.assert.lessThan(initialAlpha, SettingsMenu.fadeAlpha, "Fade should decrease when invisible")
    end,
    ["test fade limits"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Test maximum fade
        SettingsMenu.isVisible = true
        SettingsMenu.update(1.0) -- Long enough to reach max
        TestFramework.assert.lessThanOrEqual(1.0, SettingsMenu.fadeAlpha, "Fade should not exceed 1.0")
        -- Test minimum fade
        SettingsMenu.isVisible = false
        SettingsMenu.update(1.0) -- Long enough to reach min
        TestFramework.assert.greaterThanOrEqual(0.0, SettingsMenu.fadeAlpha, "Fade should not go below 0.0")
    end,
    ["test get current options for audio tab"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.selectedTab = 1 -- Audio tab
        local options = SettingsMenu.getCurrentOptions()
        TestFramework.assert.equal(3, #options, "Audio tab should have 3 options")
        TestFramework.assert.equal("masterVolume", options[1].key, "First option should be master volume")
        TestFramework.assert.equal("slider", options[1].type, "Master volume should be slider type")
        TestFramework.assert.equal(0, options[1].min, "Master volume min should be 0")
        TestFramework.assert.equal(1, options[1].max, "Master volume max should be 1")
    end,
    ["test get current options for controls tab"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.selectedTab = 2 -- Controls tab
        local options = SettingsMenu.getCurrentOptions()
        TestFramework.assert.equal(6, #options, "Controls tab should have 6 options")
        TestFramework.assert.equal("dashKey1", options[1].key, "First option should be dash key 1")
        TestFramework.assert.equal("key", options[1].type, "Dash key should be key type")
    end,
    ["test get current options for graphics tab"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.selectedTab = 3 -- Graphics tab
        local options = SettingsMenu.getCurrentOptions()
        TestFramework.assert.equal(5, #options, "Graphics tab should have 5 options")
        TestFramework.assert.equal("particleQuality", options[1].key, "First option should be particle quality")
        TestFramework.assert.equal("choice", options[1].type, "Particle quality should be choice type")
        TestFramework.assert.equal(3, #options[1].choices, "Particle quality should have 3 choices")
    end,
    ["test get current options for gameplay tab"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.selectedTab = 4 -- Gameplay tab
        local options = SettingsMenu.getCurrentOptions()
        TestFramework.assert.equal(5, #options, "Gameplay tab should have 5 options")
        TestFramework.assert.equal("autoSave", options[1].key, "First option should be auto save")
        TestFramework.assert.equal("toggle", options[1].type, "Auto save should be toggle type")
    end,
    ["test keyboard navigation up"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedOption = 3
        SettingsMenu.keypressed("up")
        TestFramework.assert.equal(2, SettingsMenu.selectedOption, "Should move up one option")
    end,
    ["test keyboard navigation down"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedOption = 2
        SettingsMenu.keypressed("down")
        TestFramework.assert.equal(3, SettingsMenu.selectedOption, "Should move down one option")
    end,
    ["test keyboard navigation limits"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        -- Test upper limit
        SettingsMenu.selectedOption = 1
        SettingsMenu.keypressed("up")
        TestFramework.assert.equal(1, SettingsMenu.selectedOption, "Should not go below option 1")
        -- Test lower limit - use controls tab which has 6 options
        SettingsMenu.selectedTab = 2 -- Controls tab
        SettingsMenu.selectedOption = 6
        SettingsMenu.keypressed("down")
        TestFramework.assert.equal(6, SettingsMenu.selectedOption, "Should not go above last option")
    end,
    ["test tab navigation left"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 3
        SettingsMenu.keypressed("left")
        TestFramework.assert.equal(2, SettingsMenu.selectedTab, "Should move to previous tab")
        TestFramework.assert.equal(1, SettingsMenu.selectedOption, "Should reset to first option")
    end,
    ["test tab navigation right"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 2
        SettingsMenu.keypressed("right")
        TestFramework.assert.equal(3, SettingsMenu.selectedTab, "Should move to next tab")
        TestFramework.assert.equal(1, SettingsMenu.selectedOption, "Should reset to first option")
    end,
    ["test tab navigation limits"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        -- Test left limit
        SettingsMenu.selectedTab = 1
        SettingsMenu.keypressed("left")
        TestFramework.assert.equal(1, SettingsMenu.selectedTab, "Should not go below tab 1")
        -- Test right limit
        SettingsMenu.selectedTab = 4
        SettingsMenu.keypressed("right")
        TestFramework.assert.equal(4, SettingsMenu.selectedTab, "Should not go above last tab")
    end,
    ["test escape key closes menu"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        local result = SettingsMenu.keypressed("escape")
        TestFramework.assert.equal(true, result, "Should handle escape key")
        TestFramework.assert.equal(false, SettingsMenu.isVisible, "Should close menu on escape")
    end,
    ["test toggle option with enter"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 3 -- Graphics tab
        SettingsMenu.selectedOption = 2 -- Show FPS (toggle)
        local initialValue = SettingsMenu.current.showFPS
        SettingsMenu.keypressed("return")
        TestFramework.assert.notEqual(initialValue, SettingsMenu.current.showFPS, "Should toggle show FPS")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test toggle option with space"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 3 -- Graphics tab
        SettingsMenu.selectedOption = 2 -- Show FPS (toggle)
        local initialValue = SettingsMenu.current.showFPS
        SettingsMenu.keypressed("space")
        TestFramework.assert.notEqual(initialValue, SettingsMenu.current.showFPS, "Should toggle show FPS")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test slider adjustment with a key"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 1 -- Audio tab
        SettingsMenu.selectedOption = 1 -- Master volume (slider)
        -- Set to a value that can be decreased
        SettingsMenu.current.masterVolume = 0.9
        local initialValue = SettingsMenu.current.masterVolume
        SettingsMenu.keypressed("a")
        TestFramework.assert.equal(0.8, SettingsMenu.current.masterVolume, "Should decrease volume by 0.1")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test slider adjustment with d key"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 1 -- Audio tab
        SettingsMenu.selectedOption = 1 -- Master volume (slider)
        -- Set to a value that can be increased
        SettingsMenu.current.masterVolume = 0.9
        local initialValue = SettingsMenu.current.masterVolume
        SettingsMenu.keypressed("d")
        TestFramework.assert.equal(1.0, SettingsMenu.current.masterVolume, "Should increase volume by 0.1")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test slider limits"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 1 -- Audio tab
        SettingsMenu.selectedOption = 1 -- Master volume (slider)
        -- Test minimum limit
        SettingsMenu.current.masterVolume = 0.0
        SettingsMenu.keypressed("a")
        TestFramework.assert.equal(0.0, SettingsMenu.current.masterVolume, "Should not go below minimum")
        -- Test maximum limit
        SettingsMenu.current.masterVolume = 1.0
        SettingsMenu.keypressed("d")
        TestFramework.assert.equal(1.0, SettingsMenu.current.masterVolume, "Should not go above maximum")
    end,
    ["test choice cycling"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.selectedTab = 3 -- Graphics tab
        SettingsMenu.selectedOption = 1 -- Particle quality (choice)
        local initialValue = SettingsMenu.current.particleQuality
        SettingsMenu.keypressed("return")
        TestFramework.assert.notEqual(initialValue, SettingsMenu.current.particleQuality, "Should cycle to next choice")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test save settings with f5"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        -- Mock save and apply functions
        local saveCalled = false
        local applyCalled = false
        local originalSave = SettingsMenu.save
        local originalApply = SettingsMenu.applySettings
        SettingsMenu.save = function()
            saveCalled = true
        end
        SettingsMenu.applySettings = function()
            applyCalled = true
        end
        SettingsMenu.keypressed("f5")
        TestFramework.assert.equal(true, saveCalled, "Should call save on F5")
        TestFramework.assert.equal(true, applyCalled, "Should call apply settings on F5")
        -- Restore original functions
        SettingsMenu.save = originalSave
        SettingsMenu.applySettings = originalApply
    end,
    ["test reset to defaults with f8"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        -- Change a setting
        SettingsMenu.current.masterVolume = 0.3
        SettingsMenu.unsavedChanges = false
        -- Mock apply function
        local applyCalled = false
        local originalApply = SettingsMenu.applySettings
        SettingsMenu.applySettings = function()
            applyCalled = true
        end
        SettingsMenu.keypressed("f8")
        TestFramework.assert.equal(1.0, SettingsMenu.current.masterVolume, "Should reset to default value")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
        TestFramework.assert.equal(true, applyCalled, "Should call apply settings")
        -- Restore original function
        SettingsMenu.applySettings = originalApply
    end,
    ["test input consumption when visible"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        local result = SettingsMenu.keypressed("x")
        TestFramework.assert.equal(true, result, "Should consume all input when visible")
    end,
    ["test input not consumed when invisible"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Ensure menu is invisible
        SettingsMenu.isVisible = false
        local result = SettingsMenu.keypressed("x")
        TestFramework.assert.equal(false, result, "Should not consume input when invisible")
    end,
    ["test mouse click outside menu closes it"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.fadeAlpha = 1.0 -- Ensure menu is fully visible
        -- Mock screen dimensions
        Mocks.love.graphics.getWidth = function() return 800 end
        Mocks.love.graphics.getHeight = function() return 600 end
        -- Menu is centered, so click at top-left corner which should be outside
        local result = SettingsMenu.mousepressed(0, 0, 1) -- Click outside menu
        TestFramework.assert.equal(true, result, "Should handle mouse click")
        TestFramework.assert.equal(false, SettingsMenu.isVisible, "Should close menu when clicking outside")
    end,
    ["test mouse click on tab changes selection"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.fadeAlpha = 1.0 -- Ensure menu is fully visible
        SettingsMenu.selectedTab = 1 -- Reset to first tab
        -- Mock screen dimensions
        Mocks.love.graphics.getWidth = function() return 800 end
        Mocks.love.graphics.getHeight = function() return 600 end
        -- Click on second tab (Controls)
        -- Menu width is 700, so menuX = (800-700)/2 = 50
        -- Menu height is 500, so menuY = (600-500)/2 = 50
        -- tabWidth = 700/4 = 175
        -- Second tab starts at menuX + tabWidth = 50 + 175 = 225
        -- Click in middle of second tab: x = 225 + 87.5 = 312.5, y = 50 + 25 = 75
        local result = SettingsMenu.mousepressed(312, 75, 1) -- Click on second tab area
        TestFramework.assert.equal(true, result, "Should handle mouse click")
        TestFramework.assert.equal(2, SettingsMenu.selectedTab, "Should select second tab")
    end,
    ["test mouse click on toggle option"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.fadeAlpha = 1.0
        SettingsMenu.selectedTab = 3 -- Graphics tab
        SettingsMenu.selectedOption = 2 -- Show FPS (toggle)
        -- Mock screen dimensions
        Mocks.love.graphics.getWidth = function() return 800 end
        Mocks.love.graphics.getHeight = function() return 600 end
        -- Get initial value and ensure unsavedChanges is false
        local initialValue = SettingsMenu.current.showFPS
        SettingsMenu.unsavedChanges = false
        -- Calculate click position for second option in Graphics tab
        -- menuY = (600-500)/2 = 50, optionY = menuY + 100 = 150
        -- Second option Y = 150 + 50 = 200 (center at 220)
        local result = SettingsMenu.mousepressed(400, 220, 1) -- Click on second option area
        TestFramework.assert.equal(true, result, "Should handle mouse click")
        TestFramework.assert.notEqual(initialValue, SettingsMenu.current.showFPS, "Should toggle show FPS")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test mouse click not handled when invisible"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Ensure menu is invisible and has no fade
        SettingsMenu.isVisible = false
        SettingsMenu.fadeAlpha = 0
        local result = SettingsMenu.mousepressed(400, 300, 1)
        TestFramework.assert.equal(false, result, "Should not handle mouse clicks when invisible")
    end,
    ["test mouse click not handled with low fade"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.isVisible = true
        SettingsMenu.fadeAlpha = 0.3 -- Low fade
        local result = SettingsMenu.mousepressed(400, 300, 1)
        TestFramework.assert.equal(false, result, "Should not handle mouse clicks with low fade")
    end,
    ["test is blocking input"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Ensure we start in a known state
        SettingsMenu.isVisible = false
        SettingsMenu.fadeAlpha = 0
        -- Should not block when invisible
        TestFramework.assert.equal(false, SettingsMenu.isBlockingInput(), "Should not block input when invisible")
        -- Should block when visible with sufficient fade
        SettingsMenu.isVisible = true
        SettingsMenu.fadeAlpha = 0.7
        TestFramework.assert.equal(true, SettingsMenu.isBlockingInput(), "Should block input when visible with fade")
        -- Should not block when fade is too low
        SettingsMenu.fadeAlpha = 0.3
        TestFramework.assert.equal(false, SettingsMenu.isBlockingInput(), "Should not block input with low fade")
    end,
    ["test get setting value"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        -- Test getting existing setting
        local value = SettingsMenu.get("masterVolume")
        TestFramework.assert.equal(1.0, value, "Should return current value for existing setting")
        -- Test getting non-existent setting
        local defaultValue = SettingsMenu.get("nonexistent")
        TestFramework.assert.equal(nil, defaultValue, "Should return nil for non-existent setting")
    end,
    ["test set setting value"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        SettingsMenu.init()
        SettingsMenu.set("masterVolume", 0.7)
        TestFramework.assert.equal(0.7, SettingsMenu.current.masterVolume, "Should set the value")
        TestFramework.assert.equal(true, SettingsMenu.unsavedChanges, "Should mark as unsaved")
    end,
    ["test settings file path"] = function()
        local SettingsMenu = Utils.require("src.ui.settings_menu")
        TestFramework.assert.equal("settings.dat", SettingsMenu.settingsFile, "Should have correct settings file path")
    end
}
-- Test runner
local function run()
    Utils.Logger.info("Running Settings Menu Tests")
    Utils.Logger.info("==================================================")
    return TestFramework.runTests(tests)
end
return {run = run}