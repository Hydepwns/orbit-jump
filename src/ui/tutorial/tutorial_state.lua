--[[
    Tutorial State Management for Orbit Jump
    
    This module handles tutorial state, progression tracking, and skill development.
--]]

local TutorialState = {}

-- Tutorial state
TutorialState.isActive = false
TutorialState.currentModule = nil
TutorialState.currentStep = 1
TutorialState.stepTimer = 0
TutorialState.completedModules = {}
TutorialState.fadeAlpha = 0
TutorialState.pulsePhase = 0
TutorialState.contextualHints = {}
TutorialState.skillProgression = {}

-- Initialize tutorial state
function TutorialState.init()
    TutorialState.isActive = false
    TutorialState.currentModule = nil
    TutorialState.currentStep = 1
    TutorialState.stepTimer = 0
    TutorialState.completedModules = {}
    TutorialState.fadeAlpha = 0
    TutorialState.pulsePhase = 0
    TutorialState.contextualHints = {}
    TutorialState.skillProgression = {}
    
    -- Load saved progress
    TutorialState.loadProgress()
end

-- Start a tutorial module
function TutorialState.startModule(moduleId, modules)
    if not modules or not modules[moduleId] then
        return false
    end
    
    TutorialState.currentModule = modules[moduleId]
    TutorialState.currentStep = 1
    TutorialState.stepTimer = 0
    TutorialState.isActive = true
    TutorialState.fadeAlpha = 0
    
    return true
end

-- Check if a module is completed
function TutorialState.isModuleCompleted(moduleId)
    return TutorialState.completedModules[moduleId] == true
end

-- Progress a skill
function TutorialState.progressSkill(skillName, xpGain)
    if not TutorialState.skillProgression[skillName] then
        TutorialState.skillProgression[skillName] = {
            level = 0,
            xp = 0,
            maxXp = 100
        }
    end
    
    local skill = TutorialState.skillProgression[skillName]
    skill.xp = skill.xp + xpGain
    
    -- Level up if enough XP
    while skill.xp >= skill.maxXp do
        skill.xp = skill.xp - skill.maxXp
        skill.level = skill.level + 1
        skill.maxXp = skill.maxXp + 50 -- Increase XP requirement for next level
    end
    
    return skill.level
end

-- Update tutorial state
function TutorialState.update(dt, player, gameState, modules)
    if not TutorialState.isActive or not TutorialState.currentModule then
        return
    end
    
    -- Update animation timers
    TutorialState.stepTimer = TutorialState.stepTimer + dt
    TutorialState.pulsePhase = TutorialState.pulsePhase + dt * 2
    
    -- Fade in effect
    if TutorialState.fadeAlpha < 1 then
        TutorialState.fadeAlpha = math.min(1, TutorialState.fadeAlpha + dt * 2)
    end
    
    -- Get current step
    local step = TutorialState.currentModule.steps[TutorialState.currentStep]
    if not step then
        TutorialState.completeCurrentModule()
        return
    end
    
    -- Check step condition
    if step.condition then
        local conditionMet = step.condition(player, gameState)
        if conditionMet then
            if step.duration > 0 then
                -- Step has a duration, wait for it
                if TutorialState.stepTimer >= step.duration then
                    TutorialState.nextStep()
                end
            else
                -- Step requires interaction, wait for player action
                -- This will be handled by the action system
            end
        end
    end
end

-- Check for contextual help
function TutorialState.checkContextualHelp(dt, gameState, player, contextualHelp)
    if not contextualHelp then
        return
    end
    
    -- Update existing hints
    for hintId, hint in pairs(TutorialState.contextualHints) do
        hint.timer = hint.timer + dt
        if hint.timer >= hint.duration then
            TutorialState.contextualHints[hintId] = nil
        end
    end
    
    -- Check for new hints
    for hintId, hint in pairs(contextualHelp) do
        if hint.condition and hint.condition(player, gameState) then
            if not TutorialState.contextualHints[hintId] then
                TutorialState.contextualHints[hintId] = {
                    title = hint.title,
                    text = hint.text,
                    duration = hint.duration,
                    timer = 0
                }
            end
        end
    end
end

-- Show contextual hint
function TutorialState.showContextualHint(hintId, helpData)
    if helpData then
        TutorialState.contextualHints[hintId] = {
            title = helpData.title,
            text = helpData.text,
            duration = helpData.duration or 3,
            timer = 0
        }
    end
end

-- Handle player actions
function TutorialState.onPlayerAction(action, data, modules)
    if not TutorialState.isActive or not TutorialState.currentModule then
        return false
    end
    
    local step = TutorialState.currentModule.steps[TutorialState.currentStep]
    if not step then
        return false
    end
    
    -- Check if this action matches the current step
    if step.action == action then
        -- Award XP for completing the action
        if step.xpReward then
            TutorialState.progressSkill(step.skill or "general", step.xpReward)
        end
        
        -- Move to next step
        TutorialState.nextStep()
        return true
    end
    
    return false
end

-- Handle skill progression
function TutorialState.handleSkillProgression(action, data)
    local skillGains = {
        jump = { skill = "movement", xp = 10 },
        dash = { skill = "navigation", xp = 15 },
        land = { skill = "precision", xp = 20 },
        gravity_assist = { skill = "timing", xp = 25 }
    }
    
    local gain = skillGains[action]
    if gain then
        return TutorialState.progressSkill(gain.skill, gain.xp)
    end
    
    return 0
end

-- Move to next step
function TutorialState.nextStep()
    if not TutorialState.currentModule then
        return
    end
    
    TutorialState.currentStep = TutorialState.currentStep + 1
    TutorialState.stepTimer = 0
    
    -- Check if module is complete
    if TutorialState.currentStep > #TutorialState.currentModule.steps then
        TutorialState.completeCurrentModule()
    end
end

-- Complete current module
function TutorialState.completeCurrentModule()
    if not TutorialState.currentModule then
        return
    end
    
    local moduleId = TutorialState.currentModule.id
    TutorialState.completedModules[moduleId] = true
    
    -- Award completion XP
    TutorialState.progressSkill("general", 50)
    
    -- Save progress
    TutorialState.saveProgress()
    
    -- Check for next available module
    TutorialState.checkForNextModule()
end

-- Check for next available module
function TutorialState.checkForNextModule()
    -- This will be implemented by the main tutorial system
    -- to check for available modules and potentially auto-start them
end

-- Show module available notification
function TutorialState.showModuleAvailable(moduleId)
    -- This can be used to show notifications when new modules become available
    TutorialState.showContextualHint("module_available", {
        title = "New Tutorial Available!",
        text = "Press T to access new tutorials",
        duration = 5
    })
end

-- Get current state
function TutorialState.getCurrentState()
    return {
        isActive = TutorialState.isActive,
        currentModule = TutorialState.currentModule,
        currentStep = TutorialState.currentStep,
        stepTimer = TutorialState.stepTimer,
        completedModules = TutorialState.completedModules,
        fadeAlpha = TutorialState.fadeAlpha,
        pulsePhase = TutorialState.pulsePhase,
        contextualHints = TutorialState.contextualHints,
        skillProgression = TutorialState.skillProgression
    }
end

-- Set current state
function TutorialState.setState(state)
    if state then
        TutorialState.isActive = state.isActive or false
        TutorialState.currentModule = state.currentModule
        TutorialState.currentStep = state.currentStep or 1
        TutorialState.stepTimer = state.stepTimer or 0
        TutorialState.completedModules = state.completedModules or {}
        TutorialState.fadeAlpha = state.fadeAlpha or 0
        TutorialState.pulsePhase = state.pulsePhase or 0
        TutorialState.contextualHints = state.contextualHints or {}
        TutorialState.skillProgression = state.skillProgression or {}
    end
end

-- Save progress
function TutorialState.saveProgress()
    local saveData = {
        completedModules = TutorialState.completedModules,
        skillProgression = TutorialState.skillProgression
    }
    
    -- Use the serialization module if available
    local Serialization = require("src.utils.data.serialization")
    if Serialization then
        local serialized = Serialization.serialize(saveData)
        love.filesystem.write("enhanced_tutorial_progress.dat", serialized)
    end
end

-- Load progress
function TutorialState.loadProgress()
    if love.filesystem.getInfo("enhanced_tutorial_progress.dat") then
        local data = love.filesystem.read("enhanced_tutorial_progress.dat")
        
        -- Use the serialization module if available
        local Serialization = require("src.utils.data.serialization")
        if Serialization then
            local saveData = Serialization.deserialize(data)
            if saveData then
                TutorialState.completedModules = saveData.completedModules or {}
                TutorialState.skillProgression = saveData.skillProgression or {}
            end
        end
    end
end

-- Handle key press
function TutorialState.handleKeyPress(key, modules)
    if key == "t" and not TutorialState.isActive then
        -- Check for available modules
        for moduleId, module in pairs(modules or {}) do
            if not TutorialState.isModuleCompleted(moduleId) then
                if not module.prerequisite or TutorialState.isModuleCompleted(module.prerequisite) then
                    TutorialState.startModule(moduleId, modules)
                    return true
                end
            end
        end
    end
    
    if TutorialState.isActive and key == "escape" then
        TutorialState.isActive = false
        return true
    end
    
    return false
end

-- Integration helpers
function TutorialState.isAnyTutorialActive()
    return TutorialState.isActive
end

function TutorialState.getAllCompletedModules()
    return TutorialState.completedModules
end

function TutorialState.getSkillLevel(skillName)
    local skill = TutorialState.skillProgression[skillName]
    return skill and skill.level or 0
end

function TutorialState.getSkillXP(skillName)
    local skill = TutorialState.skillProgression[skillName]
    return skill and skill.xp or 0
end

function TutorialState.getSkillMaxXP(skillName)
    local skill = TutorialState.skillProgression[skillName]
    return skill and skill.maxXp or 100
end

return TutorialState 