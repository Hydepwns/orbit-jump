-- Comprehensive tests for Tutorial System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
TestFramework.init()
-- Test suite
local tests = {
    ["test module loading without mocks"] = function()
        -- Clear any cached module first
        package.loaded["src.ui.tutorial_system"] = nil
        package.loaded["src/ui/tutorial_system"] = nil
        if Utils.moduleCache then
            Utils.moduleCache["src.ui.tutorial_system"] = nil
        end
        -- Setup mocks before loading
        Mocks.setup()
        -- Load the module without any mocking
        local TutorialSystem = require("src.ui.tutorial_system")
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
        -- Clear any cached module first
        package.loaded["src.ui.tutorial_system"] = nil
        package.loaded["src/ui/tutorial_system"] = nil
        -- Load the module without any mocking
        local TutorialSystem = require("src.ui.tutorial_system")
        -- Verify it's loaded
        TestFramework.assert.notNil(TutorialSystem, "TutorialSystem should be loaded")
        TestFramework.assert.equal("function", type(TutorialSystem.init), "init should be a function")
        -- Test basic initialization
        TutorialSystem.init()
        TestFramework.assert.equal(true, TutorialSystem.isActive, "Should start active if not completed")
        TestFramework.assert.equal(1, TutorialSystem.currentStep, "Should start at step 1")
        TestFramework.assert.equal(0, TutorialSystem.stepTimer, "Timer should start at 0")
    end,
}
-- Test runner
local function run()
    Utils.Logger.info("Running Tutorial System Tests")
    Utils.Logger.info("==================================================")
    return TestFramework.runTests(tests)
end
return {run = run}