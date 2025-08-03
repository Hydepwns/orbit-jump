--[[
    Tutorial Modules Configuration for Orbit Jump
    This module contains all tutorial module definitions with progressive
    skill introduction and context-sensitive help.
--]]
local TutorialModules = {}
-- Tutorial modules with progressive skill introduction
TutorialModules.modules = {
    basic_movement = {
        id = "basic_movement",
        name = "Basic Movement",
        description = "Learn the fundamentals of space travel",
        prerequisite = nil,
        steps = {
            {
                id = "welcome",
                title = "Welcome, Space Explorer!",
                text = "You're about to embark on an incredible journey through the cosmos.\nLet's start with the basics of movement.",
                duration = 3,
                condition = function() return true end,
                interactionRequired = false,
                visualCues = {"welcome_animation"}
            },
            {
                id = "planet_introduction",
                title = "Your Starting Planet",
                text = "You begin your journey on this planet.\nNotice how your character stands on the surface.",
                duration = 3,
                condition = function(player) return player.onPlanet end,
                interactionRequired = false,
                highlight = "player",
                visualCues = {"planet_highlight", "gravity_indication"}
            },
            {
                id = "jump_preparation",
                title = "Preparing to Jump",
                text = "To jump, you need to pull back like a slingshot.\nThe further you pull, the more powerful your jump!",
                duration = 0,
                condition = function(player) return player.onPlanet end,
                interactionRequired = true,
                action = "mouse_drag",
                highlight = "player",
                showPullIndicator = true,
                visualCues = {"pullback_guide", "power_meter"}
            },
            {
                id = "first_jump",
                title = "Execute Your Jump!",
                text = "Great! Now release to launch yourself into space!",
                duration = 0,
                condition = function(player) return player.isPullingBack end,
                interactionRequired = true,
                action = "jump",
                highlight = "player",
                visualCues = {"trajectory_preview", "release_prompt"}
            },
            {
                id = "jump_feedback",
                title = "Excellent Launch!",
                text = "You're now flying through space!\nNotice how your momentum carries you forward.",
                duration = 4,
                condition = function(player) return not player.onPlanet and player.velocity and (player.velocity.x^2 + player.velocity.y^2) > 100 end,
                interactionRequired = false,
                highlight = "player",
                visualCues = {"velocity_indicator", "momentum_trail"}
            }
        }
    },
    space_navigation = {
        id = "space_navigation",
        name = "Space Navigation",
        description = "Master the art of controlling your flight",
        prerequisite = "basic_movement",
        steps = {
            {
                id = "dash_introduction",
                title = "Mid-Air Control",
                text = "While in space, you can dash once per jump to adjust your trajectory.\nTry pressing SHIFT, Z, or X to dash!",
                duration = 0,
                condition = function(player) return not player.onPlanet and player.dashesLeft > 0 end,
                interactionRequired = true,
                action = "dash",
                highlight = "player",
                visualCues = {"dash_indicator", "direction_arrow"}
            },
            {
                id = "dash_success",
                title = "Perfect Dash!",
                text = "Excellent! You've successfully used your dash ability.\nThis gives you precise control over your trajectory.",
                duration = 3,
                condition = function(player) return player.dashUsed end,
                interactionRequired = false,
                highlight = "player",
                visualCues = {"dash_trail", "momentum_indicator"}
            },
            {
                id = "momentum_conservation",
                title = "Momentum Conservation",
                text = "Notice how your momentum is preserved in space.\nYou'll keep moving in the same direction unless acted upon.",
                duration = 4,
                condition = function(player) return not player.onPlanet and not player.dashUsed end,
                interactionRequired = false,
                highlight = "player",
                visualCues = {"momentum_vector", "velocity_display"}
            }
        }
    },
    planet_interaction = {
        id = "planet_interaction",
        name = "Planet Interaction",
        description = "Learn to land on and interact with planets",
        prerequisite = "space_navigation",
        steps = {
            {
                id = "planet_approach",
                title = "Approaching a Planet",
                text = "You're approaching another planet!\nNotice how its gravity begins to affect your trajectory.",
                duration = 3,
                condition = function(player, gameState)
                    return not player.onPlanet and gameState.nearestPlanet and
                           gameState.nearestPlanet.distance < 200
                end,
                interactionRequired = false,
                highlight = "nearest_planet",
                visualCues = {"gravity_field", "approach_trajectory"}
            },
            {
                id = "landing_preparation",
                title = "Preparing to Land",
                text = "To land safely, you need to reduce your velocity.\nUse your dash to slow down as you approach.",
                duration = 0,
                condition = function(player, gameState)
                    return not player.onPlanet and gameState.nearestPlanet and
                           gameState.nearestPlanet.distance < 100
                end,
                interactionRequired = true,
                action = "dash_to_land",
                highlight = "nearest_planet",
                visualCues = {"landing_zone", "velocity_meter"}
            },
            {
                id = "successful_landing",
                title = "Perfect Landing!",
                text = "You've successfully landed on a new planet!\nEach planet has unique properties and challenges.",
                duration = 4,
                condition = function(player) return player.onPlanet and player.landedOnNewPlanet end,
                interactionRequired = false,
                highlight = "player",
                visualCues = {"landing_effect", "planet_info"}
            }
        }
    },
    advanced_techniques = {
        id = "advanced_techniques",
        name = "Advanced Techniques",
        description = "Master advanced movement and timing",
        prerequisite = "planet_interaction",
        steps = {
            {
                id = "gravity_assist",
                title = "Gravity Assist",
                text = "You can use planets' gravity to gain speed!\nFly close to a planet to slingshot around it.",
                duration = 0,
                condition = function(player, gameState)
                    return not player.onPlanet and gameState.nearestPlanet and
                           gameState.nearestPlanet.distance < 150 and
                           player.velocity and (player.velocity.x^2 + player.velocity.y^2) > 200
                end,
                interactionRequired = true,
                action = "gravity_assist",
                highlight = "nearest_planet",
                visualCues = {"gravity_assist_path", "speed_indicator"}
            },
            {
                id = "precise_timing",
                title = "Precise Timing",
                text = "Timing is crucial for advanced maneuvers.\nPractice your timing to master complex trajectories.",
                duration = 3,
                condition = function(player) return player.successfulGravityAssist end,
                interactionRequired = false,
                highlight = "player",
                visualCues = {"timing_indicator", "success_effect"}
            }
        }
    }
}
-- Skill progression definitions
TutorialModules.skillLevels = {
    movement = { level = 0, xp = 0, maxXp = 100 },
    navigation = { level = 0, xp = 0, maxXp = 150 },
    timing = { level = 0, xp = 0, maxXp = 200 },
    precision = { level = 0, xp = 0, maxXp = 250 }
}
-- Contextual help definitions
TutorialModules.contextualHelp = {
    stuck_in_space = {
        title = "Need Help?",
        text = "Press T to access tutorials or use your dash to reach a planet.",
        condition = function(player, gameState)
            return not player.onPlanet and not player.dashesLeft and
                   gameState.nearestPlanet and gameState.nearestPlanet.distance > 300
        end,
        duration = 5
    },
    low_energy = {
        title = "Low Energy",
        text = "Your energy is running low. Land on a planet to recharge.",
        condition = function(player) return player.energy and player.energy < 20 end,
        duration = 3
    },
    high_velocity = {
        title = "High Velocity",
        text = "You're moving very fast! Be careful when approaching planets.",
        condition = function(player) return player.velocity and (player.velocity.x^2 + player.velocity.y^2) > 500 end,
        duration = 2
    }
}
-- Action prompts
TutorialModules.actionPrompts = {
    mouse_drag = "Click and drag to pull back",
    jump = "Release to jump",
    dash = "Press SHIFT, Z, or X to dash",
    dash_to_land = "Use dash to slow down for landing",
    gravity_assist = "Fly close to the planet for gravity assist"
}
-- Visual cue definitions
TutorialModules.visualCues = {
    welcome_animation = {
        type = "animation",
        duration = 3,
        effect = "fade_in"
    },
    planet_highlight = {
        type = "highlight",
        target = "planet",
        color = {0.2, 0.8, 1.0},
        pulse = true
    },
    pullback_guide = {
        type = "guide",
        target = "player",
        direction = "backward",
        color = {1.0, 0.8, 0.2}
    },
    trajectory_preview = {
        type = "preview",
        target = "trajectory",
        color = {0.8, 1.0, 0.2},
        dashed = true
    },
    dash_indicator = {
        type = "indicator",
        target = "player",
        icon = "dash",
        color = {0.2, 1.0, 0.8}
    },
    gravity_field = {
        type = "field",
        target = "planet",
        color = {0.8, 0.2, 1.0},
        alpha = 0.3
    }
}
-- Utility functions
function TutorialModules.getModule(moduleId)
    return TutorialModules.modules[moduleId]
end
function TutorialModules.getAllModules()
    return TutorialModules.modules
end
function TutorialModules.getAvailableModules(completedModules)
    local available = {}
    for moduleId, module in pairs(TutorialModules.modules) do
        if not completedModules[moduleId] then
            if not module.prerequisite or completedModules[module.prerequisite] then
                table.insert(available, module)
            end
        end
    end
    return available
end
function TutorialModules.getNextModule(completedModules)
    local available = TutorialModules.getAvailableModules(completedModules)
    if #available > 0 then
        return available[1]
    end
    return nil
end
function TutorialModules.isModuleAvailable(moduleId, completedModules)
    if completedModules[moduleId] then
        return false
    end
    local module = TutorialModules.modules[moduleId]
    if not module then
        return false
    end
    if not module.prerequisite then
        return true
    end
    return completedModules[module.prerequisite] == true
end
function TutorialModules.getActionPrompt(action)
    return TutorialModules.actionPrompts[action] or "Perform the required action"
end
function TutorialModules.getVisualCue(cueId)
    return TutorialModules.visualCues[cueId]
end
function TutorialModules.checkContextualHelp(gameState, player)
    local activeHints = {}
    for hintId, hint in pairs(TutorialModules.contextualHelp) do
        if hint.condition(player, gameState) then
            table.insert(activeHints, {
                id = hintId,
                title = hint.title,
                text = hint.text,
                duration = hint.duration
            })
        end
    end
    return activeHints
end
return TutorialModules