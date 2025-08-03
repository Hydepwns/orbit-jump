--[[
    Enhanced Tutorial System: Modular Architecture
    
    This module coordinates the tutorial system using the new modular structure
    with separate modules for configuration, state management, and rendering.
--]]

local TutorialModules = require("src.ui.tutorial.tutorial_modules")
local TutorialState = require("src.ui.tutorial.tutorial_state")
local TutorialRendering = require("src.ui.tutorial.tutorial_rendering")

local EnhancedTutorialSystem = {}

-- Initialize the tutorial system
function EnhancedTutorialSystem.init()
    TutorialState.init()
end

-- Start a tutorial module
function EnhancedTutorialSystem.startModule(moduleId)
    return TutorialState.startModule(moduleId, TutorialModules.modules)
end

-- Check if a module is completed
function EnhancedTutorialSystem.isModuleCompleted(moduleId)
    return TutorialState.isModuleCompleted(moduleId)
end

-- Progress a skill
function EnhancedTutorialSystem.progressSkill(skillName, xpGain)
    return TutorialState.progressSkill(skillName, xpGain)
end

-- Update the tutorial system
function EnhancedTutorialSystem.update(dt, player, gameState)
    -- Update tutorial state
    TutorialState.update(dt, player, gameState, TutorialModules.modules)
    
    -- Check for contextual help
    local contextualHelp = TutorialModules.checkContextualHelp(gameState, player)
    TutorialState.checkContextualHelp(dt, gameState, player, contextualHelp)
end

-- Show contextual hint
function EnhancedTutorialSystem.showContextualHint(hintId, helpData)
    TutorialState.showContextualHint(hintId, helpData)
end

-- Handle player actions
function EnhancedTutorialSystem.onPlayerAction(action, data)
    local handled = TutorialState.onPlayerAction(action, data, TutorialModules.modules)
    
    if not handled then
        -- Handle skill progression for actions not tied to current tutorial
        TutorialState.handleSkillProgression(action, data)
    end
    
    return handled
end

-- Move to next step
function EnhancedTutorialSystem.nextStep()
    TutorialState.nextStep()
end

-- Complete current module
function EnhancedTutorialSystem.completeCurrentModule()
    TutorialState.completeCurrentModule()
end

-- Check for next available module
function EnhancedTutorialSystem.checkForNextModule()
    local nextModule = TutorialModules.getNextModule(TutorialState.completedModules)
    if nextModule then
        EnhancedTutorialSystem.showModuleAvailable(nextModule.id)
    end
end

-- Show module available notification
function EnhancedTutorialSystem.showModuleAvailable(moduleId)
    TutorialState.showModuleAvailable(moduleId)
end

-- Draw the tutorial system
function EnhancedTutorialSystem.draw(player, camera, gameState)
    TutorialRendering.draw(player, camera, gameState, TutorialState, TutorialModules.modules)
end

-- Handle key press
function EnhancedTutorialSystem.handleKeyPress(key)
    return TutorialState.handleKeyPress(key, TutorialModules.modules)
end

-- Integration helpers
function EnhancedTutorialSystem.isAnyTutorialActive()
    return TutorialState.isAnyTutorialActive()
end

function EnhancedTutorialSystem.getAllCompletedModules()
    return TutorialState.getAllCompletedModules()
end

function EnhancedTutorialSystem.getSkillLevel(skillName)
    return TutorialState.getSkillLevel(skillName)
end

function EnhancedTutorialSystem.getSkillXP(skillName)
    return TutorialState.getSkillXP(skillName)
end

function EnhancedTutorialSystem.getSkillMaxXP(skillName)
    return TutorialState.getSkillMaxXP(skillName)
end

-- Module management
function EnhancedTutorialSystem.getModule(moduleId)
    return TutorialModules.getModule(moduleId)
end

function EnhancedTutorialSystem.getAllModules()
    return TutorialModules.getAllModules()
end

function EnhancedTutorialSystem.getAvailableModules()
    return TutorialModules.getAvailableModules(TutorialState.completedModules)
end

function EnhancedTutorialSystem.isModuleAvailable(moduleId)
    return TutorialModules.isModuleAvailable(moduleId, TutorialState.completedModules)
end

-- Action prompts
function EnhancedTutorialSystem.getActionPrompt(action)
    return TutorialModules.getActionPrompt(action)
end

-- Visual cues
function EnhancedTutorialSystem.getVisualCue(cueId)
    return TutorialModules.getVisualCue(cueId)
end

-- State management
function EnhancedTutorialSystem.getCurrentState()
    return TutorialState.getCurrentState()
end

function EnhancedTutorialSystem.setState(state)
    TutorialState.setState(state)
end

-- Progress management
function EnhancedTutorialSystem.saveProgress()
    TutorialState.saveProgress()
end

function EnhancedTutorialSystem.loadProgress()
    TutorialState.loadProgress()
end

-- Backward compatibility
EnhancedTutorialSystem.modules = TutorialModules.modules
EnhancedTutorialSystem.skillLevels = TutorialModules.skillLevels

return EnhancedTutorialSystem 