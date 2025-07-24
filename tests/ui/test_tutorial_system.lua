-- Comprehensive tests for Tutorial System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

Mocks.setup()
TestFramework.init()

-- Test suite
local tests = {
    ["test module loading without mocks"] = function()
        -- Load the module without any mocking
        local TutorialSystem = Utils.require("src.ui.tutorial_system")
        
        -- Verify the module is loaded correctly
        TestFramework.assert.notNil(TutorialSystem, "TutorialSystem should be loaded")
        TestFramework.assert.notNil(TutorialSystem.init, "init function should exist")
        TestFramework.assert.notNil(TutorialSystem.start, "start function should exist")
        TestFramework.assert.notNil(TutorialSystem.skip, "skip function should exist")
        TestFramework.assert.notNil(TutorialSystem.complete, "complete function should exist")
        TestFramework.assert.notNil(TutorialSystem.update, "update function should exist")
        TestFramework.assert.notNil(TutorialSystem.onPlayerAction, "onPlayerAction function should exist")
    end,

    ["test basic initialization"] = function()
        -- Load the module without any mocking
        local TutorialSystem = Utils.require("src.ui.tutorial_system")
        
        -- Test basic initialization
        TutorialSystem.init()
        
        TestFramework.assert.equal(true, TutorialSystem.isActive, "Should start active if not completed")
        TestFramework.assert.equal(1, TutorialSystem.currentStep, "Should start at step 1")
        TestFramework.assert.equal(0, TutorialSystem.stepTimer, "Timer should start at 0")
    end,
}

-- Run tests
TestFramework.runTests(tests)