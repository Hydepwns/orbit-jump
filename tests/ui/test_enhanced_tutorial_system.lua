-- Comprehensive tests for Enhanced Tutorial System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

Mocks.setup()
TestFramework.init()

-- Test suite
local tests = {
    ["test enhanced tutorial system loading"] = function()
        -- Clear any cached module first
        package.loaded["src.ui.enhanced_tutorial_system"] = nil
        if Utils.moduleCache then
            Utils.moduleCache["src.ui.enhanced_tutorial_system"] = nil
        end
        
        -- Setup mocks before loading
        Mocks.setup()
        
        -- Load the enhanced tutorial system
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Verify the module is loaded correctly
        TestFramework.assert.notNil(EnhancedTutorialSystem, "EnhancedTutorialSystem should be loaded")
        TestFramework.assert.equal("function", type(EnhancedTutorialSystem.init), "init should be a function")
        TestFramework.assert.equal("function", type(EnhancedTutorialSystem.startModule), "startModule should be a function")
        TestFramework.assert.equal("function", type(EnhancedTutorialSystem.update), "update should be a function")
        TestFramework.assert.equal("function", type(EnhancedTutorialSystem.draw), "draw should be a function")
        TestFramework.assert.equal("function", type(EnhancedTutorialSystem.onPlayerAction), "onPlayerAction should be a function")
    end,

    ["test tutorial modules structure"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Test that modules are properly defined
        TestFramework.assert.notNil(EnhancedTutorialSystem.modules, "modules should exist")
        TestFramework.assert.equal("table", type(EnhancedTutorialSystem.modules), "modules should be a table")
        
        -- Test basic_movement module
        local basicMovement = EnhancedTutorialSystem.modules.basic_movement
        TestFramework.assert.notNil(basicMovement, "basic_movement module should exist")
        TestFramework.assert.equal("basic_movement", basicMovement.id, "basic_movement should have correct id")
        TestFramework.assert.notNil(basicMovement.steps, "basic_movement should have steps")
        TestFramework.assert.equal("table", type(basicMovement.steps), "steps should be a table")
        TestFramework.assert.isTrue(#basicMovement.steps > 0, "basic_movement should have at least one step")
        
        -- Test space_navigation module has prerequisite
        local spaceNavigation = EnhancedTutorialSystem.modules.space_navigation
        TestFramework.assert.notNil(spaceNavigation, "space_navigation module should exist")
        TestFramework.assert.equal("basic_movement", spaceNavigation.prerequisite, "space_navigation should require basic_movement")
        
        -- Test step structure
        local firstStep = basicMovement.steps[1]
        TestFramework.assert.notNil(firstStep.id, "step should have id")
        TestFramework.assert.notNil(firstStep.title, "step should have title")
        TestFramework.assert.notNil(firstStep.text, "step should have text")
        TestFramework.assert.notNil(firstStep.condition, "step should have condition function")
        TestFramework.assert.equal("function", type(firstStep.condition), "condition should be a function")
    end,

    ["test module initialization"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Reset state
        EnhancedTutorialSystem.isActive = false
        EnhancedTutorialSystem.completedModules = {}
        EnhancedTutorialSystem.currentModule = nil
        
        -- Test initialization
        local result = EnhancedTutorialSystem.init()
        TestFramework.assert.isTrue(result, "init should return true")
        
        -- Should start with basic_movement if no modules completed
        TestFramework.assert.isTrue(EnhancedTutorialSystem.isActive, "should be active after init")
        TestFramework.assert.equal("basic_movement", EnhancedTutorialSystem.currentModule, "should start with basic_movement")
        TestFramework.assert.equal(1, EnhancedTutorialSystem.currentStep, "should start at step 1")
    end,

    ["test module completion and progression"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Reset state
        EnhancedTutorialSystem.isActive = false
        EnhancedTutorialSystem.completedModules = {}
        EnhancedTutorialSystem.currentModule = nil
        
        -- Complete basic_movement module
        EnhancedTutorialSystem.completedModules = {"basic_movement"}
        TestFramework.assert.isTrue(EnhancedTutorialSystem.isModuleCompleted("basic_movement"), "basic_movement should be completed")
        TestFramework.assert.isFalse(EnhancedTutorialSystem.isModuleCompleted("space_navigation"), "space_navigation should not be completed")
        
        -- Test that space_navigation can now be started
        local canStart = EnhancedTutorialSystem.startModule("space_navigation")
        TestFramework.assert.isTrue(canStart, "should be able to start space_navigation after completing basic_movement")
        TestFramework.assert.equal("space_navigation", EnhancedTutorialSystem.currentModule, "current module should be space_navigation")
    end,

    ["test prerequisite checking"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Reset state
        EnhancedTutorialSystem.completedModules = {}
        
        -- Try to start space_navigation without completing basic_movement
        local canStart = EnhancedTutorialSystem.startModule("space_navigation")
        TestFramework.assert.isFalse(canStart, "should not be able to start space_navigation without prerequisite")
        
        -- Complete prerequisite and try again
        EnhancedTutorialSystem.completedModules = {"basic_movement"}
        canStart = EnhancedTutorialSystem.startModule("space_navigation")
        TestFramework.assert.isTrue(canStart, "should be able to start space_navigation with prerequisite")
    end,

    ["test player action handling"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Reset state and start tutorial
        EnhancedTutorialSystem.isActive = true
        EnhancedTutorialSystem.currentModule = "basic_movement"
        EnhancedTutorialSystem.currentStep = 3 -- jump_preparation step
        
        local module = EnhancedTutorialSystem.modules.basic_movement
        local step = module.steps[3] -- jump_preparation
        
        -- Test that the step requires mouse_drag action
        TestFramework.assert.equal("mouse_drag", step.action, "jump_preparation should require mouse_drag action")
        
        -- Trigger the action
        EnhancedTutorialSystem.onPlayerAction("mouse_drag")
        
        -- Should advance to next step
        TestFramework.assert.equal(4, EnhancedTutorialSystem.currentStep, "should advance to next step after correct action")
    end,

    ["test skill progression"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Reset skill levels
        EnhancedTutorialSystem.skillLevels = {
            jumping = { level = 0, maxLevel = 3, xp = 0, xpToNext = 5 }
        }
        
        -- Test skill progression
        local levelUp = EnhancedTutorialSystem.progressSkill("jumping", 3)
        TestFramework.assert.isFalse(levelUp, "should not level up with insufficient XP")
        TestFramework.assert.equal(3, EnhancedTutorialSystem.skillLevels.jumping.xp, "XP should be accumulated")
        
        -- Add more XP to trigger level up
        levelUp = EnhancedTutorialSystem.progressSkill("jumping", 2)
        TestFramework.assert.isTrue(levelUp, "should level up when XP threshold is reached")
        TestFramework.assert.equal(1, EnhancedTutorialSystem.skillLevels.jumping.level, "level should increase")
        TestFramework.assert.equal(0, EnhancedTutorialSystem.skillLevels.jumping.xp, "XP should reset after level up")
    end,

    ["test contextual help triggers"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Reset contextual hints
        EnhancedTutorialSystem.contextualHints = {}
        
        -- Create mock game state and player
        local mockPlayer = { x = 0, y = 0 }
        local mockGameState = { failedJumps = 4 } -- Trigger difficulty_detected
        
        -- Test contextual help detection
        EnhancedTutorialSystem.checkContextualHelp(0.1, mockGameState, mockPlayer)
        
        -- Should have triggered difficulty_detected help
        TestFramework.assert.notNil(EnhancedTutorialSystem.contextualHints.difficulty_detected, "difficulty_detected hint should be triggered")
        
        local hint = EnhancedTutorialSystem.contextualHints.difficulty_detected
        TestFramework.assert.equal("Having Trouble Jumping?", hint.title, "hint should have correct title")
        TestFramework.assert.equal(0.1, hint.timer, "hint timer should be updated with dt")
    end,

    ["test update function"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Test update when not active
        EnhancedTutorialSystem.isActive = false
        EnhancedTutorialSystem.contextualHints = {}
        
        local mockPlayer = { x = 0, y = 0 }
        local mockGameState = { failedJumps = 4 }
        
        EnhancedTutorialSystem.update(0.1, mockPlayer, mockGameState)
        -- Should check contextual help even when not active
        TestFramework.assert.notNil(EnhancedTutorialSystem.contextualHints.difficulty_detected, "should check contextual help when inactive")
        
        -- Test update when active
        EnhancedTutorialSystem.isActive = true
        EnhancedTutorialSystem.currentModule = "basic_movement"
        EnhancedTutorialSystem.currentStep = 1
        EnhancedTutorialSystem.fadeAlpha = 0
        EnhancedTutorialSystem.pulsePhase = 0
        
        EnhancedTutorialSystem.update(0.5, mockPlayer, mockGameState)
        
        -- Should update visual effects
        TestFramework.assert.isTrue(EnhancedTutorialSystem.fadeAlpha > 0, "fadeAlpha should increase")
        TestFramework.assert.isTrue(EnhancedTutorialSystem.pulsePhase > 0, "pulsePhase should increase")
    end,

    ["test serialization and deserialization"] = function()
        -- Test data serialization
        local testData = {
            completedModules = {"basic_movement", "space_navigation"},
            skillProgression = {
                jumping = { level = 2, xp = 3 }
            }
        }
        
        local serialized = Utils.serialize(testData)
        TestFramework.assert.equal("string", type(serialized), "serialize should return string")
        TestFramework.assert.isTrue(string.len(serialized) > 0, "serialized string should not be empty")
        
        local deserialized = Utils.deserialize(serialized)
        TestFramework.assert.notNil(deserialized, "deserialize should return data")
        TestFramework.assert.equal("table", type(deserialized), "deserialized data should be table")
        TestFramework.assert.equal(2, #deserialized.completedModules, "should preserve completed modules")
        TestFramework.assert.equal("basic_movement", deserialized.completedModules[1], "should preserve module order")
        TestFramework.assert.equal(2, deserialized.skillProgression.jumping.level, "should preserve skill levels")
    end,

    ["test input handling"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Test tutorial start with 't' key when not active
        EnhancedTutorialSystem.isActive = false
        EnhancedTutorialSystem.completedModules = {}
        
        local handled = EnhancedTutorialSystem.handleKeyPress("t")
        TestFramework.assert.isTrue(handled, "should handle 't' key to start tutorial")
        TestFramework.assert.isTrue(EnhancedTutorialSystem.isActive, "should become active after pressing 't'")
        
        -- Test escape key to exit tutorial
        local handled = EnhancedTutorialSystem.handleKeyPress("escape")
        TestFramework.assert.isTrue(handled, "should handle escape key")
        TestFramework.assert.isFalse(EnhancedTutorialSystem.isActive, "should become inactive after escape")
    end,

    ["test integration helpers"] = function()
        local EnhancedTutorialSystem = require("src.ui.enhanced_tutorial_system")
        
        -- Test isAnyTutorialActive
        EnhancedTutorialSystem.isActive = true
        TestFramework.assert.isTrue(EnhancedTutorialSystem.isAnyTutorialActive(), "should return true when active")
        
        EnhancedTutorialSystem.isActive = false
        TestFramework.assert.isFalse(EnhancedTutorialSystem.isAnyTutorialActive(), "should return false when inactive")
        
        -- Test getAllCompletedModules
        EnhancedTutorialSystem.completedModules = {"basic_movement", "space_navigation"}
        local completed = EnhancedTutorialSystem.getAllCompletedModules()
        TestFramework.assert.equal(2, #completed, "should return all completed modules")
        TestFramework.assert.equal("basic_movement", completed[1], "should return correct modules")
        
        -- Test getSkillLevel
        EnhancedTutorialSystem.skillLevels = {
            jumping = { level = 3, maxLevel = 3, xp = 0, xpToNext = 5 }
        }
        TestFramework.assert.equal(3, EnhancedTutorialSystem.getSkillLevel("jumping"), "should return correct skill level")
        TestFramework.assert.equal(0, EnhancedTutorialSystem.getSkillLevel("nonexistent"), "should return 0 for nonexistent skill")
    end
}

-- Test runner
local function run()
    Utils.Logger.info("Running Enhanced Tutorial System Tests")
    Utils.Logger.info("================================================")
    return TestFramework.runTests(tests)
end

return {run = run}