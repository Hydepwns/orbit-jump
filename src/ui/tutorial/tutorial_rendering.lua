--[[
    Tutorial Rendering for Orbit Jump
    This module handles all tutorial-related rendering including visual cues,
    UI elements, and progress indicators.
--]]
local Drawing = require("src.utils.rendering.drawing")
local UIComponents = require("src.utils.rendering.ui_components")
local TutorialRendering = {}
-- Draw main tutorial interface
function TutorialRendering.draw(player, camera, gameState, tutorialState, modules)
    if not tutorialState.isActive or not tutorialState.currentModule then
        return
    end
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    -- Get current step
    local step = tutorialState.currentModule.steps[tutorialState.currentStep]
    if not step then
        return
    end
    -- Draw visual cues
    TutorialRendering.drawVisualCues(step, player, camera, gameState, tutorialState)
    -- Draw tutorial box
    TutorialRendering.drawTutorialBox(step, tutorialState.currentModule, screenWidth, screenHeight, tutorialState)
    -- Draw progress indicators
    TutorialRendering.drawProgressIndicators(tutorialState.currentModule, screenWidth, screenHeight, tutorialState)
    -- Draw contextual hints
    TutorialRendering.drawContextualHints(tutorialState.contextualHints)
end
-- Draw visual cues for current step
function TutorialRendering.drawVisualCues(step, player, camera, gameState, tutorialState)
    if not step.visualCues then
        return
    end
    for _, cueId in ipairs(step.visualCues) do
        local cue = TutorialRendering.getVisualCue(cueId)
        if cue then
            TutorialRendering.drawVisualCue(cue, step, player, camera, gameState, tutorialState)
        end
    end
end
-- Draw individual visual cue
function TutorialRendering.drawVisualCue(cue, step, player, camera, gameState, tutorialState)
    if cue.type == "highlight" then
        TutorialRendering.drawHighlight(cue, step, player, camera, gameState, tutorialState)
    elseif cue.type == "guide" then
        TutorialRendering.drawGuide(cue, step, player, camera, gameState, tutorialState)
    elseif cue.type == "preview" then
        TutorialRendering.drawPreview(cue, step, player, camera, gameState, tutorialState)
    elseif cue.type == "indicator" then
        TutorialRendering.drawIndicator(cue, step, player, camera, gameState, tutorialState)
    elseif cue.type == "field" then
        TutorialRendering.drawField(cue, step, player, camera, gameState, tutorialState)
    end
end
-- Draw highlight effect
function TutorialRendering.drawHighlight(cue, step, player, camera, gameState, tutorialState)
    local target = cue.target
    local pulse = cue.pulse and math.sin(tutorialState.pulsePhase * 2) * 0.3 + 1 or 1
    if target == "player" and player then
        local x, y = camera:worldToScreen(player.x, player.y)
        local radius = (player.radius or 20) * pulse
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], 0.3)
        love.graphics.circle("fill", x, y, radius + 10)
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", x, y, radius + 10)
        love.graphics.setLineWidth(1)
    elseif target == "nearest_planet" and gameState.nearestPlanet then
        local planet = gameState.nearestPlanet
        local x, y = camera:worldToScreen(planet.x, planet.y)
        local radius = planet.radius * pulse
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], 0.3)
        love.graphics.circle("fill", x, y, radius + 15)
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", x, y, radius + 15)
        love.graphics.setLineWidth(1)
    end
end
-- Draw guide effect
function TutorialRendering.drawGuide(cue, step, player, camera, gameState, tutorialState)
    if cue.target == "player" and player and step.showPullIndicator then
        local x, y = camera:worldToScreen(player.x, player.y)
        local pulse = math.sin(tutorialState.pulsePhase * 3) * 0.5 + 0.5
        -- Draw pullback guide
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], pulse)
        love.graphics.setLineWidth(3)
        local guideLength = 60
        local guideAngle = math.pi -- Pull back direction
        local endX = x + math.cos(guideAngle) * guideLength
        local endY = y + math.sin(guideAngle) * guideLength
        love.graphics.line(x, y, endX, endY)
        -- Draw arrow head
        local arrowSize = 8
        local arrowAngle1 = guideAngle + math.pi * 0.75
        local arrowAngle2 = guideAngle - math.pi * 0.75
        love.graphics.line(endX, endY,
                          endX + math.cos(arrowAngle1) * arrowSize,
                          endY + math.sin(arrowAngle1) * arrowSize)
        love.graphics.line(endX, endY,
                          endX + math.cos(arrowAngle2) * arrowSize,
                          endY + math.sin(arrowAngle2) * arrowSize)
        love.graphics.setLineWidth(1)
    end
end
-- Draw preview effect
function TutorialRendering.drawPreview(cue, step, player, camera, gameState, tutorialState)
    if cue.target == "trajectory" and player and player.isPullingBack then
        local x, y = camera:worldToScreen(player.x, player.y)
        local pullback = player.pullback or {x = 0, y = 0}
        -- Calculate trajectory
        local velocityX = -pullback.x * 0.1
        local velocityY = -pullback.y * 0.1
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], 0.6)
        love.graphics.setLineWidth(2)
        -- Draw dashed trajectory
        local segments = 20
        local segmentLength = 10
        local gapLength = 5
        local currentX, currentY = x, y
        for i = 1, segments do
            local nextX = currentX + velocityX * segmentLength
            local nextY = currentY + velocityY * segmentLength
            love.graphics.line(currentX, currentY, nextX, nextY)
            currentX = nextX + velocityX * gapLength
            currentY = nextY + velocityY * gapLength
        end
        love.graphics.setLineWidth(1)
    end
end
-- Draw indicator effect
function TutorialRendering.drawIndicator(cue, step, player, camera, gameState, tutorialState)
    if cue.target == "player" and player then
        local x, y = camera:worldToScreen(player.x, player.y)
        local pulse = math.sin(tutorialState.pulsePhase * 4) * 0.5 + 0.5
        -- Draw dash indicator
        if cue.icon == "dash" then
            Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], pulse)
            love.graphics.setLineWidth(3)
            local size = 15
            love.graphics.line(x - size, y - size, x + size, y + size)
            love.graphics.line(x - size, y + size, x + size, y - size)
            love.graphics.setLineWidth(1)
        end
    end
end
-- Draw field effect
function TutorialRendering.drawField(cue, step, player, camera, gameState, tutorialState)
    if cue.target == "planet" and gameState.nearestPlanet then
        local planet = gameState.nearestPlanet
        local x, y = camera:worldToScreen(planet.x, planet.y)
        local radius = planet.radius + 50
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], cue.alpha or 0.3)
        love.graphics.circle("fill", x, y, radius)
        Drawing.setColor(cue.color[1], cue.color[2], cue.color[3], (cue.alpha or 0.3) * 2)
        love.graphics.setLineWidth(1)
        love.graphics.circle("line", x, y, radius)
        love.graphics.setLineWidth(1)
    end
end
-- Draw tutorial box
function TutorialRendering.drawTutorialBox(step, module, screenWidth, screenHeight, tutorialState)
    local boxWidth = 500
    local boxHeight = 200
    local boxX = (screenWidth - boxWidth) / 2
    local boxY = screenHeight - boxHeight - 50
    -- Background
    Drawing.setColor(0.1, 0.1, 0.3, 0.9 * tutorialState.fadeAlpha)
    love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 10)
    -- Border
    Drawing.setColor(0.5, 0.7, 1, tutorialState.fadeAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 10)
    love.graphics.setLineWidth(1)
    -- Title
    Drawing.setColor(1, 1, 1, tutorialState.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf(step.title, boxX + 20, boxY + 20, boxWidth - 40, "center")
    -- Text
    Drawing.setColor(0.9, 0.9, 0.9, tutorialState.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf(step.text, boxX + 20, boxY + 60, boxWidth - 40, "left")
    -- Action prompt
    if step.action then
        local prompt = TutorialRendering.getActionPrompt(step.action)
        Drawing.setColor(0.8, 1, 0.8, tutorialState.fadeAlpha)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(prompt, boxX + 20, boxY + 140, boxWidth - 40, "center")
    end
end
-- Draw progress indicators
function TutorialRendering.drawProgressIndicators(module, screenWidth, screenHeight, tutorialState)
    local barWidth = 400
    local barHeight = 8
    local barX = (screenWidth - barWidth) / 2
    local barY = screenHeight - 100
    -- Progress bar background
    Drawing.setColor(0.2, 0.2, 0.4, tutorialState.fadeAlpha)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 4)
    -- Progress bar fill
    local progress = tutorialState.currentStep / #module.steps
    local fillWidth = barWidth * progress
    Drawing.setColor(0.3, 0.8, 1, tutorialState.fadeAlpha)
    love.graphics.rectangle("fill", barX, barY, fillWidth, barHeight, 4)
    -- Progress bar border
    Drawing.setColor(0.5, 0.7, 1, tutorialState.fadeAlpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 4)
    -- Step indicators
    local stepSize = 12
    local stepSpacing = (barWidth - stepSize) / (#module.steps - 1)
    for i = 1, #module.steps do
        local stepX = barX + (i - 1) * stepSpacing
        local stepY = barY - 20
        if i < tutorialState.currentStep then
            -- Completed step
            Drawing.setColor(0.3, 0.8, 1, tutorialState.fadeAlpha)
            love.graphics.circle("fill", stepX + stepSize/2, stepY + stepSize/2, stepSize/2)
        elseif i == tutorialState.currentStep then
            -- Current step
            local pulse = math.sin(tutorialState.pulsePhase * 2) * 0.3 + 1
            Drawing.setColor(1, 1, 1, tutorialState.fadeAlpha)
            love.graphics.circle("fill", stepX + stepSize/2, stepY + stepSize/2, stepSize/2 * pulse)
        else
            -- Future step
            Drawing.setColor(0.4, 0.4, 0.5, tutorialState.fadeAlpha)
            love.graphics.circle("line", stepX + stepSize/2, stepY + stepSize/2, stepSize/2)
        end
    end
    -- Module name
    Drawing.setColor(0.8, 0.9, 1, tutorialState.fadeAlpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf(module.name, 0, barY - 45, screenWidth, "center")
end
-- Draw contextual hints
function TutorialRendering.drawContextualHints(contextualHints)
    local y = 20
    for hintId, hint in pairs(contextualHints or {}) do
        local alpha = math.min(1, hint.duration - hint.timer) * 0.8
        -- Hint background
        Drawing.setColor(0.1, 0.1, 0.3, alpha)
        love.graphics.rectangle("fill", 20, y, 400, 60, 8)
        -- Hint border
        Drawing.setColor(0.5, 0.7, 1, alpha)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 20, y, 400, 60, 8)
        -- Hint text
        Drawing.setColor(1, 1, 1, alpha)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf(hint.title, 30, y + 5, 380, "left")
        Drawing.setColor(0.8, 0.8, 0.8, alpha)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.printf(hint.text, 30, y + 25, 380, "left")
        y = y + 70
    end
end
-- Get action prompt
function TutorialRendering.getActionPrompt(action)
    local prompts = {
        mouse_drag = "Click and drag to pull back",
        jump = "Release to jump",
        dash = "Press SHIFT, Z, or X to dash",
        dash_to_land = "Use dash to slow down for landing",
        gravity_assist = "Fly close to the planet for gravity assist"
    }
    return prompts[action] or "Perform the required action"
end
-- Get visual cue definition
function TutorialRendering.getVisualCue(cueId)
    local cues = {
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
    return cues[cueId]
end
return TutorialRendering