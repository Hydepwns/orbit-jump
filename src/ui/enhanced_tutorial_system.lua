-- Enhanced Tutorial System for Orbit Jump
-- Advanced interactive tutorials with progressive skill introduction and context-sensitive help
local Utils = require("src.utils.utils")

local EnhancedTutorialSystem = {}

-- Enhanced tutorial state
EnhancedTutorialSystem.isActive = false
EnhancedTutorialSystem.currentModule = nil
EnhancedTutorialSystem.currentStep = 1
EnhancedTutorialSystem.stepTimer = 0
EnhancedTutorialSystem.completedModules = {}
EnhancedTutorialSystem.fadeAlpha = 0
EnhancedTutorialSystem.pulsePhase = 0
EnhancedTutorialSystem.contextualHints = {}
EnhancedTutorialSystem.skillProgression = {}

-- Tutorial modules with progressive skill introduction
EnhancedTutorialSystem.modules = {
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
                text = "Well done! Dashing gives you precise control over your flight path.\nUse it to reach distant planets or collect rings.",
                duration = 3,
                condition = function(player) return not player.onPlanet and player.dashesLeft == 0 end,
                interactionRequired = false,
                visualCues = {"dash_trail_highlight"}
            },
            {
                id = "landing_preparation",
                title = "Preparing to Land",
                text = "Try to land on another planet to continue your journey.\nLook for the gravitational pull indicators!",
                duration = 0,
                condition = function(player) return not player.onPlanet end,
                interactionRequired = true,
                action = "land",
                highlight = "nearest_planet",
                visualCues = {"gravity_wells", "landing_zones"}
            }
        }
    },
    
    ring_collection = {
        id = "ring_collection",
        name = "Ring Collection",
        description = "Learn to collect rings and build combos",
        prerequisite = "space_navigation",
        steps = {
            {
                id = "ring_introduction",
                title = "Cosmic Rings",
                text = "These glowing rings are scattered throughout space.\nFly through them to earn points!",
                duration = 4,
                condition = function() return true end,
                interactionRequired = false,
                highlight = "nearest_ring",
                visualCues = {"ring_pulse", "collection_preview"}
            },
            {
                id = "first_ring_collection",
                title = "Collect Your First Ring",
                text = "Aim for that ring and fly through it!\nTime your jumps to hit multiple rings in sequence.",
                duration = 0,
                condition = function() return true end,
                interactionRequired = true,
                action = "collect_ring",
                highlight = "nearest_ring",
                visualCues = {"optimal_trajectory", "ring_glow"}
            },
            {
                id = "combo_introduction",
                title = "Chain Combos",
                text = "Collect rings quickly in succession to build combos!\nThe faster you collect, the higher your multiplier.",
                duration = 5,
                condition = function() return true end,
                interactionRequired = false,
                visualCues = {"combo_meter", "chain_indicators"}
            }
        }
    },
    
    advanced_techniques = {
        id = "advanced_techniques",
        name = "Advanced Techniques",
        description = "Master advanced movement and exploration",
        prerequisite = "ring_collection",
        steps = {
            {
                id = "map_system",
                title = "Galactic Map",
                text = "Press TAB to open your map and see discovered planets.\nUse it to plan your exploration routes!",
                duration = 0,
                condition = function() return true end,
                interactionRequired = true,
                action = "map",
                visualCues = {"map_button_highlight"}
            },
            {
                id = "upgrade_system",
                title = "Character Upgrades",
                text = "Press U to access the upgrade shop.\nSpend your points to improve your abilities!",
                duration = 0,
                condition = function() return true end,
                interactionRequired = true,
                action = "upgrades",
                visualCues = {"upgrade_button_highlight", "currency_display"}
            },
            {
                id = "exploration_mastery",
                title = "Master Explorer",
                text = "You now know all the basics!\nExplore the infinite galaxy and discover its secrets.",
                duration = 4,
                condition = function() return true end,
                interactionRequired = false,
                visualCues = {"completion_celebration"}
            }
        }
    }
}

-- Context-sensitive help system
EnhancedTutorialSystem.contextualHelp = {
    difficulty_detected = {
        trigger = function(gameState, player)
            -- Detect if player is struggling with basic jumps
            return gameState.failedJumps and gameState.failedJumps > 3
        end,
        help = {
            title = "Having Trouble Jumping?",
            text = "Try pulling back further for stronger jumps.\nAim for the trajectory indicator!",
            duration = 5,
            visualCues = {"enhanced_pullback_guide"}
        }
    },
    
    missed_rings = {
        trigger = function(gameState, player)
            return gameState.missedRings and gameState.missedRings > 5
        end,
        help = {
            title = "Ring Collection Tips",
            text = "Use your dash to fine-tune your trajectory.\nLook for the glowing trail to guide your path!",
            duration = 4,
            visualCues = {"trajectory_assistance"}
        }
    },
    
    exploration_encouragement = {
        trigger = function(gameState, player)
            return gameState.planetsVisited and gameState.planetsVisited > 10 and not gameState.usedMap
        end,
        help = {
            title = "Explore More Efficiently",
            text = "Press TAB to open your map!\nIt shows undiscovered areas worth exploring.",
            duration = 6,
            visualCues = {"map_highlight", "undiscovered_indicators"}
        }
    }
}

-- Skill progression tracking
EnhancedTutorialSystem.skillLevels = {
    jumping = { level = 0, maxLevel = 3, xp = 0, xpToNext = 5 },
    dashing = { level = 0, maxLevel = 3, xp = 0, xpToNext = 3 },
    ring_collection = { level = 0, maxLevel = 5, xp = 0, xpToNext = 10 },
    exploration = { level = 0, maxLevel = 4, xp = 0, xpToNext = 8 }
}

-- Initialize enhanced tutorial system
function EnhancedTutorialSystem.init()
    Utils.Logger.info("Initializing Enhanced Tutorial System")
    
    -- Load saved progress
    local saveData = EnhancedTutorialSystem.loadProgress()
    if saveData then
        EnhancedTutorialSystem.completedModules = saveData.completedModules or {}
        EnhancedTutorialSystem.skillProgression = saveData.skillProgression or {}
    end
    
    -- Start tutorial if no modules completed
    if #EnhancedTutorialSystem.completedModules == 0 then
        EnhancedTutorialSystem.startModule("basic_movement")
    end
    
    return true
end

-- Start a tutorial module
function EnhancedTutorialSystem.startModule(moduleId)
    local module = EnhancedTutorialSystem.modules[moduleId]
    if not module then
        Utils.Logger.error("Tutorial module not found: %s", moduleId)
        return false
    end
    
    -- Check prerequisite
    if module.prerequisite and not EnhancedTutorialSystem.isModuleCompleted(module.prerequisite) then
        Utils.Logger.warn("Prerequisite not met for module: %s", moduleId)
        return false
    end
    
    EnhancedTutorialSystem.isActive = true
    EnhancedTutorialSystem.currentModule = moduleId
    EnhancedTutorialSystem.currentStep = 1
    EnhancedTutorialSystem.stepTimer = 0
    EnhancedTutorialSystem.fadeAlpha = 0
    
    Utils.Logger.info("Started tutorial module: %s", moduleId)
    return true
end

-- Check if module is completed
function EnhancedTutorialSystem.isModuleCompleted(moduleId)
    for _, completed in ipairs(EnhancedTutorialSystem.completedModules) do
        if completed == moduleId then
            return true
        end
    end
    return false
end

-- Progress skill level
function EnhancedTutorialSystem.progressSkill(skillName, xpGain)
    local skill = EnhancedTutorialSystem.skillLevels[skillName]
    if not skill or skill.level >= skill.maxLevel then
        return false
    end
    
    skill.xp = skill.xp + (xpGain or 1)
    
    -- Check for level up
    if skill.xp >= skill.xpToNext then
        skill.level = skill.level + 1
        skill.xp = 0
        skill.xpToNext = math.floor(skill.xpToNext * 1.5) -- Increase XP requirement
        
        Utils.Logger.info("Skill level up: %s is now level %d", skillName, skill.level)
        return true -- Level up occurred
    end
    
    return false
end

-- Update enhanced tutorial system
function EnhancedTutorialSystem.update(dt, player, gameState)
    if not EnhancedTutorialSystem.isActive then
        -- Check for contextual help triggers
        EnhancedTutorialSystem.checkContextualHelp(dt, gameState, player)
        return
    end
    
    -- Update visual effects
    EnhancedTutorialSystem.pulsePhase = EnhancedTutorialSystem.pulsePhase + dt * 3
    EnhancedTutorialSystem.fadeAlpha = math.min(EnhancedTutorialSystem.fadeAlpha + dt * 2, 1)
    
    local module = EnhancedTutorialSystem.modules[EnhancedTutorialSystem.currentModule]
    if not module then
        EnhancedTutorialSystem.completeCurrentModule()
        return
    end
    
    local step = module.steps[EnhancedTutorialSystem.currentStep]
    if not step then
        EnhancedTutorialSystem.completeCurrentModule()
        return
    end
    
    -- Check step condition
    if step.condition and not step.condition(player, gameState) then
        return
    end
    
    -- Update step timer for non-interactive steps
    if not step.interactionRequired and step.duration > 0 then
        EnhancedTutorialSystem.stepTimer = EnhancedTutorialSystem.stepTimer + dt
        
        if EnhancedTutorialSystem.stepTimer >= step.duration then
            EnhancedTutorialSystem.nextStep()
        end
    end
end

-- Check for contextual help triggers
function EnhancedTutorialSystem.checkContextualHelp(dt, gameState, player)
    for helpId, helpData in pairs(EnhancedTutorialSystem.contextualHelp) do
        if helpData.trigger(gameState, player) and not EnhancedTutorialSystem.contextualHints[helpId] then
            EnhancedTutorialSystem.showContextualHint(helpId, helpData.help)
        end
    end
    
    -- Update active contextual hints
    for hintId, hint in pairs(EnhancedTutorialSystem.contextualHints) do
        hint.timer = hint.timer + dt
        if hint.timer >= hint.duration then
            EnhancedTutorialSystem.contextualHints[hintId] = nil
        end
    end
end

-- Show contextual hint
function EnhancedTutorialSystem.showContextualHint(hintId, helpData)
    EnhancedTutorialSystem.contextualHints[hintId] = {
        title = helpData.title,
        text = helpData.text,
        duration = helpData.duration,
        timer = 0,
        visualCues = helpData.visualCues or {}
    }
    
    Utils.Logger.info("Showing contextual help: %s", hintId)
end

-- Handle player actions
function EnhancedTutorialSystem.onPlayerAction(action, data)
    if not EnhancedTutorialSystem.isActive then
        -- Progress skills even outside tutorial
        EnhancedTutorialSystem.handleSkillProgression(action, data)
        return
    end
    
    local module = EnhancedTutorialSystem.modules[EnhancedTutorialSystem.currentModule]
    if not module then return end
    
    local step = module.steps[EnhancedTutorialSystem.currentStep]
    if step and step.action == action then
        EnhancedTutorialSystem.nextStep()
    end
    
    -- Always progress skills
    EnhancedTutorialSystem.handleSkillProgression(action, data)
end

-- Handle skill progression from actions
function EnhancedTutorialSystem.handleSkillProgression(action, data)
    if action == "jump" then
        EnhancedTutorialSystem.progressSkill("jumping")
    elseif action == "dash" then
        EnhancedTutorialSystem.progressSkill("dashing")
    elseif action == "collect_ring" then
        EnhancedTutorialSystem.progressSkill("ring_collection")
    elseif action == "land" then
        EnhancedTutorialSystem.progressSkill("exploration")
    end
end

-- Move to next step
function EnhancedTutorialSystem.nextStep()
    EnhancedTutorialSystem.currentStep = EnhancedTutorialSystem.currentStep + 1
    EnhancedTutorialSystem.stepTimer = 0
    EnhancedTutorialSystem.fadeAlpha = 0
    
    local module = EnhancedTutorialSystem.modules[EnhancedTutorialSystem.currentModule]
    if not module or EnhancedTutorialSystem.currentStep > #module.steps then
        EnhancedTutorialSystem.completeCurrentModule()
    end
end

-- Complete current module
function EnhancedTutorialSystem.completeCurrentModule()
    if EnhancedTutorialSystem.currentModule then
        table.insert(EnhancedTutorialSystem.completedModules, EnhancedTutorialSystem.currentModule)
        Utils.Logger.info("Completed tutorial module: %s", EnhancedTutorialSystem.currentModule)
    end
    
    EnhancedTutorialSystem.isActive = false
    EnhancedTutorialSystem.currentModule = nil
    EnhancedTutorialSystem.saveProgress()
    
    -- Check for next available module
    EnhancedTutorialSystem.checkForNextModule()
end

-- Check for next available module
function EnhancedTutorialSystem.checkForNextModule()
    for moduleId, module in pairs(EnhancedTutorialSystem.modules) do
        if not EnhancedTutorialSystem.isModuleCompleted(moduleId) then
            if not module.prerequisite or EnhancedTutorialSystem.isModuleCompleted(module.prerequisite) then
                -- Show notification about available module
                EnhancedTutorialSystem.showModuleAvailable(moduleId)
                break
            end
        end
    end
end

-- Show module available notification
function EnhancedTutorialSystem.showModuleAvailable(moduleId)
    local module = EnhancedTutorialSystem.modules[moduleId]
    if module then
        EnhancedTutorialSystem.showContextualHint("module_available", {
            title = "New Tutorial Available!",
            text = string.format("Ready to learn: %s\n%s\nPress T to start!", module.name, module.description),
            duration = 8
        })
    end
end

-- Enhanced drawing system
function EnhancedTutorialSystem.draw(player, camera, gameState)
    -- Draw contextual hints
    EnhancedTutorialSystem.drawContextualHints()
    
    if not EnhancedTutorialSystem.isActive then return end
    
    local module = EnhancedTutorialSystem.modules[EnhancedTutorialSystem.currentModule]
    if not module then return end
    
    local step = module.steps[EnhancedTutorialSystem.currentStep]
    if not step then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Draw enhanced overlay
    Utils.setColor({0, 0, 0}, 0.6 * EnhancedTutorialSystem.fadeAlpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    
    -- Draw enhanced highlights and visual cues
    EnhancedTutorialSystem.drawVisualCues(step, player, camera, gameState)
    
    -- Draw enhanced tutorial box
    EnhancedTutorialSystem.drawTutorialBox(step, module, screenWidth, screenHeight)
    
    -- Draw progress indicators
    EnhancedTutorialSystem.drawProgressIndicators(module, screenWidth, screenHeight)
end

-- Draw visual cues
function EnhancedTutorialSystem.drawVisualCues(step, player, camera, gameState)
    if not step.visualCues then return end
    
    local pulse = math.sin(EnhancedTutorialSystem.pulsePhase) * 0.2 + 1
    
    for _, cue in ipairs(step.visualCues) do
        if cue == "welcome_animation" then
            -- Sparkle effect for welcome
            EnhancedTutorialSystem.drawSparkleEffect()
        elseif cue == "pullback_guide" and step.showPullIndicator then
            EnhancedTutorialSystem.drawEnhancedPullbackGuide(player, camera, pulse)
        elseif cue == "trajectory_preview" then
            EnhancedTutorialSystem.drawTrajectoryPreview(player, camera)
        end
    end
    
    -- Enhanced highlighting
    if step.highlight then
        EnhancedTutorialSystem.drawEnhancedHighlight(step.highlight, player, camera, gameState, pulse)
    end
end

-- Draw sparkle effect for welcome animation
function EnhancedTutorialSystem.drawSparkleEffect()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Create sparkles around the screen
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2 + EnhancedTutorialSystem.pulsePhase
        local radius = 100 + math.sin(EnhancedTutorialSystem.pulsePhase + i) * 20
        local x = screenWidth / 2 + math.cos(angle) * radius
        local y = screenHeight / 2 + math.sin(angle) * radius
        
        local alpha = (math.sin(EnhancedTutorialSystem.pulsePhase * 2 + i) + 1) / 2
        Utils.setColor({1, 1, 0.8}, alpha * EnhancedTutorialSystem.fadeAlpha * 0.8)
        love.graphics.circle("fill", x, y, 3 + math.sin(EnhancedTutorialSystem.pulsePhase + i) * 2)
    end
end

-- Draw trajectory preview
function EnhancedTutorialSystem.drawTrajectoryPreview(player, camera)
    if not player or not player.isPullingBack then return end
    
    local mouseX, mouseY = love.mouse.getPosition()
    local worldMouseX, worldMouseY = camera:screenToWorld(mouseX, mouseY)
    
    -- Calculate trajectory
    local dx = player.x - worldMouseX
    local dy = player.y - worldMouseY
    local power = math.min(Utils.distance(0, 0, dx, dy) / 100, 5)
    
    -- Draw trajectory line
    Utils.setColor({1, 1, 0}, 0.6 * EnhancedTutorialSystem.fadeAlpha)
    love.graphics.setLineWidth(3)
    
    local steps = 20
    local prevX, prevY = player.x, player.y
    
    for i = 1, steps do
        local t = i / steps
        local x = player.x + dx * power * t
        local y = player.y + dy * power * t + 0.5 * 100 * t * t -- Simple gravity simulation
        
        local screenX, screenY = camera:worldToScreen(x, y)
        local prevScreenX, prevScreenY = camera:worldToScreen(prevX, prevY)
        
        love.graphics.line(prevScreenX, prevScreenY, screenX, screenY)
        prevX, prevY = x, y
    end
    
    love.graphics.setLineWidth(1)
end

-- Draw enhanced highlight
function EnhancedTutorialSystem.drawEnhancedHighlight(highlightType, player, camera, gameState, pulse)
    if highlightType == "player" and player then
        local screenX, screenY = camera:worldToScreen(player.x, player.y)
        
        -- Multi-layered glow
        for i = 1, 4 do
            local radius = (40 + i * 8) * pulse
            local alpha = (0.6 - i * 0.1) * EnhancedTutorialSystem.fadeAlpha
            Utils.setColor({1, 1, 0}, alpha)
            love.graphics.circle("line", screenX, screenY, radius)
        end
        
    elseif highlightType == "nearest_ring" then
        -- Find and highlight nearest ring
        local rings = gameState and gameState.getRings and gameState.getRings() or {}
        local nearestRing = nil
        local nearestDist = math.huge
        
        for _, ring in ipairs(rings) do
            if not ring.collected and player then
                local dist = Utils.distance(player.x, player.y, ring.x, ring.y)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestRing = ring
                end
            end
        end
        
        if nearestRing then
            local ringX, ringY = camera:worldToScreen(nearestRing.x, nearestRing.y)
            Utils.setColor({1, 0.8, 0}, 0.7 * EnhancedTutorialSystem.fadeAlpha)
            love.graphics.circle("line", ringX, ringY, (nearestRing.radius + 10) * pulse)
            love.graphics.circle("line", ringX, ringY, (nearestRing.radius + 20) * pulse)
        end
        
    elseif highlightType == "nearest_planet" then
        -- Find and highlight nearest planet
        local planets = gameState and gameState.getPlanets and gameState.getPlanets() or {}
        local nearestPlanet = nil
        local nearestDist = math.huge
        
        for _, planet in ipairs(planets) do
            if player then
                local dist = Utils.distance(player.x, player.y, planet.x, planet.y)
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlanet = planet
                end
            end
        end
        
        if nearestPlanet then
            local planetX, planetY = camera:worldToScreen(nearestPlanet.x, nearestPlanet.y)
            Utils.setColor({0.5, 1, 0.5}, 0.6 * EnhancedTutorialSystem.fadeAlpha)
            love.graphics.circle("line", planetX, planetY, (nearestPlanet.radius + 15) * pulse)
            love.graphics.circle("line", planetX, planetY, (nearestPlanet.radius + 25) * pulse)
        end
    end
end

-- Draw enhanced pullback guide
function EnhancedTutorialSystem.drawEnhancedPullbackGuide(player, camera, pulse)
    if not player or not player.onPlanet then return end
    
    local screenX, screenY = camera:worldToScreen(player.x, player.y)
    
    -- Multi-layered glow effect
    for i = 1, 3 do
        local alpha = (0.4 - i * 0.1) * EnhancedTutorialSystem.fadeAlpha
        Utils.setColor({1, 1, 0}, alpha)
        love.graphics.circle("line", screenX, screenY, (40 + i * 10) * pulse)
    end
    
    -- Animated directional indicators
    local angleStep = math.pi / 4
    for i = 0, 7 do
        local angle = i * angleStep + EnhancedTutorialSystem.pulsePhase * 0.5
        local radius = 80 * pulse
        local endX = screenX + math.cos(angle) * radius
        local endY = screenY + math.sin(angle) * radius
        
        Utils.setColor({1, 1, 0}, 0.6 * EnhancedTutorialSystem.fadeAlpha)
        love.graphics.circle("fill", endX, endY, 3)
    end
end

-- Draw enhanced tutorial box
function EnhancedTutorialSystem.drawTutorialBox(step, module, screenWidth, screenHeight)
    local boxWidth = math.min(700, screenWidth - 40)
    local boxHeight = 180
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = 80
    
    -- Enhanced background with gradient effect
    Utils.setColor({0, 0, 0.1}, 0.9 * EnhancedTutorialSystem.fadeAlpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 15)
    
    -- Multiple border layers for depth
    for i = 1, 3 do
        Utils.setColor({0.3 + i * 0.2, 0.6 + i * 0.1, 1}, (0.8 - i * 0.2) * EnhancedTutorialSystem.fadeAlpha)
        love.graphics.setLineWidth(4 - i)
        love.graphics.rectangle("line", boxX - i, boxY - i, boxWidth + i * 2, boxHeight + i * 2, 15)
    end
    
    -- Module indicator
    Utils.setColor({0.7, 0.9, 1}, EnhancedTutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf(module.name, boxX, boxY + 10, boxWidth, "center")
    
    -- Step title
    Utils.setColor({1, 1, 1}, EnhancedTutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf(step.title, boxX, boxY + 35, boxWidth, "center")
    
    -- Step text with better formatting
    Utils.setColor({0.9, 0.9, 0.9}, EnhancedTutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(step.text, boxX + 20, boxY + 75, boxWidth - 40, "center")
    
    -- Interaction prompt
    if step.interactionRequired then
        Utils.setColor({1, 1, 0}, EnhancedTutorialSystem.fadeAlpha * (0.7 + math.sin(EnhancedTutorialSystem.pulsePhase * 2) * 0.3))
        love.graphics.setFont(love.graphics.newFont(14))
        
        local actionText = EnhancedTutorialSystem.getActionPrompt(step.action)
        love.graphics.printf(actionText, boxX, boxY + boxHeight - 35, boxWidth, "center")
    end
end

-- Get action prompt text
function EnhancedTutorialSystem.getActionPrompt(action)
    local prompts = {
        mouse_drag = "Click and drag to pull back",
        jump = "Release to jump!",
        dash = "Press SHIFT, Z, or X to dash",
        land = "Try to land on a planet",
        collect_ring = "Fly through the glowing ring",
        map = "Press TAB to open map",
        upgrades = "Press U for upgrades"
    }
    return prompts[action] or "Perform the required action"
end

-- Draw progress indicators
function EnhancedTutorialSystem.drawProgressIndicators(module, screenWidth, screenHeight)
    if not module then return end
    
    -- Module progress bar
    local barWidth = 300
    local barHeight = 8
    local barX = (screenWidth - barWidth) / 2
    local barY = 40
    
    -- Background bar
    Utils.setColor({0.2, 0.2, 0.3}, EnhancedTutorialSystem.fadeAlpha)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4)
    
    -- Progress bar
    local progress = EnhancedTutorialSystem.currentStep / #module.steps
    Utils.setColor({0.4, 0.8, 1}, EnhancedTutorialSystem.fadeAlpha)
    love.graphics.rectangle("fill", barX, barY, barWidth * progress, barHeight, 4)
    
    -- Step indicators
    local stepSize = 8
    local totalStepWidth = #module.steps * stepSize + (#module.steps - 1) * 6
    local startX = (screenWidth - totalStepWidth) / 2
    local stepY = barY + barHeight + 15
    
    for i = 1, #module.steps do
        local x = startX + (i - 1) * (stepSize + 6)
        
        if i < EnhancedTutorialSystem.currentStep then
            -- Completed step
            Utils.setColor({0.4, 0.8, 1}, EnhancedTutorialSystem.fadeAlpha)
            love.graphics.circle("fill", x + stepSize/2, stepY + stepSize/2, stepSize/2)
        elseif i == EnhancedTutorialSystem.currentStep then
            -- Current step
            local pulse = math.sin(EnhancedTutorialSystem.pulsePhase * 2) * 0.3 + 1
            Utils.setColor({1, 1, 1}, EnhancedTutorialSystem.fadeAlpha)
            love.graphics.circle("fill", x + stepSize/2, stepY + stepSize/2, stepSize/2 * pulse)
        else
            -- Future step
            Utils.setColor({0.4, 0.4, 0.5}, EnhancedTutorialSystem.fadeAlpha)
            love.graphics.circle("line", x + stepSize/2, stepY + stepSize/2, stepSize/2)
        end
    end
    
    -- Module name
    Utils.setColor({0.8, 0.9, 1}, EnhancedTutorialSystem.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(module.name, 0, barY - 25, screenWidth, "center")
end

-- Draw contextual hints
function EnhancedTutorialSystem.drawContextualHints()
    local y = 20
    for hintId, hint in pairs(EnhancedTutorialSystem.contextualHints) do
        local alpha = math.min(1, hint.duration - hint.timer) * 0.8
        
        -- Hint background
        Utils.setColor({0.1, 0.1, 0.3}, alpha)
        love.graphics.rectangle("fill", 20, y, 400, 60, 8)
        
        -- Hint border
        Utils.setColor({0.5, 0.7, 1}, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 20, y, 400, 60, 8)
        
        -- Hint text
        Utils.setColor({1, 1, 1}, alpha)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(hint.title, 30, y + 5, 380, "left")
        
        Utils.setColor({0.8, 0.8, 0.8}, alpha)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(hint.text, 30, y + 25, 380, "left")
        
        y = y + 70
    end
end

-- Save and load progress
function EnhancedTutorialSystem.saveProgress()
    local saveData = {
        completedModules = EnhancedTutorialSystem.completedModules,
        skillProgression = EnhancedTutorialSystem.skillProgression
    }
    
    local serialized = Utils.serialize(saveData)
    love.filesystem.write("enhanced_tutorial_progress.dat", serialized)
end

function EnhancedTutorialSystem.loadProgress()
    if love.filesystem.getInfo("enhanced_tutorial_progress.dat") then
        local data = love.filesystem.read("enhanced_tutorial_progress.dat")
        return Utils.deserialize(data)
    end
    return nil
end

-- Input handlers
function EnhancedTutorialSystem.handleKeyPress(key)
    if key == "t" and not EnhancedTutorialSystem.isActive then
        -- Check for available modules
        for moduleId, module in pairs(EnhancedTutorialSystem.modules) do
            if not EnhancedTutorialSystem.isModuleCompleted(moduleId) then
                if not module.prerequisite or EnhancedTutorialSystem.isModuleCompleted(module.prerequisite) then
                    EnhancedTutorialSystem.startModule(moduleId)
                    return true
                end
            end
        end
    end
    
    if EnhancedTutorialSystem.isActive and key == "escape" then
        EnhancedTutorialSystem.isActive = false
        return true
    end
    
    return false
end

-- Integration helpers
function EnhancedTutorialSystem.isAnyTutorialActive()
    return EnhancedTutorialSystem.isActive
end

function EnhancedTutorialSystem.getAllCompletedModules()
    return EnhancedTutorialSystem.completedModules
end

function EnhancedTutorialSystem.getSkillLevel(skillName)
    local skill = EnhancedTutorialSystem.skillLevels[skillName]
    return skill and skill.level or 0
end

return EnhancedTutorialSystem