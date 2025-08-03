-- Enhanced Pullback Indicator System
-- Integrates emotional feedback and provides better angle visualization

local Utils = require("src.utils.utils")
local Config = require("src.utils.config")
local EmotionalFeedback = require("src.systems.emotional_feedback")
local EnhancedPullbackIndicator = {}

-- Configuration
EnhancedPullbackIndicator.config = {
    -- Visual settings
    powerRingMinRadius = 30,
    powerRingMaxRadius = 80,
    angleGuideSegments = 8,
    angleGuideRadius = 60,
    emotionalIntensityScale = 1.5,
    
    -- Color schemes
    colors = {
        powerRing = {1, 1, 1, 0.3},
        powerFill = {0.2, 0.8, 0.4, 0.8},
        angleGuides = {1, 1, 1, 0.2},
        directionArrow = {0.2, 0.8, 0.4, 0.8},
        emotionalGlow = {1, 0.8, 0.2, 0.6},
        powerText = {1, 1, 1, 0.9},
        angleText = {1, 1, 1, 0.7}
    },
    
    -- Emotional feedback thresholds
    emotionalThresholds = {
        low = 0.3,
        medium = 0.6,
        high = 0.8,
        max = 1.0
    }
}

-- Current state
EnhancedPullbackIndicator.state = {
    currentPower = 0,
    currentAngle = 0,
    emotionalIntensity = 0,
    lastEmotionalUpdate = 0,
    emotionalCooldown = 0.1 -- Prevent spam
}

-- Initialize the enhanced pullback indicator
function EnhancedPullbackIndicator.init()
    EnhancedPullbackIndicator.state = {
        currentPower = 0,
        currentAngle = 0,
        emotionalIntensity = 0,
        lastEmotionalUpdate = 0,
        emotionalCooldown = 0.1
    }
    
    Utils.Logger.info("Enhanced pullback indicator initialized")
end

-- Calculate pullback angle in degrees
function EnhancedPullbackIndicator.calculateAngle(mouseX, mouseY, startX, startY)
    local deltaX = mouseX - startX
    local deltaY = mouseY - startY
    local angle = math.atan2(deltaY, deltaX) * 180 / math.pi
    
    -- Normalize to 0-360 degrees
    if angle < 0 then
        angle = angle + 360
    end
    
    return angle
end

-- Get emotional feedback based on power and angle
function EnhancedPullbackIndicator.getEmotionalFeedback(power, angle)
    local emotionalState = EmotionalFeedback.emotions
    local currentMood = EmotionalFeedback.currentMood
    
    if not emotionalState or not currentMood then
        return {
            intensity = power,
            mood = "neutral",
            color = {1, 1, 1, 0.8},
            message = "Ready to jump"
        }
    end
    
    -- Calculate emotional intensity based on power and mood
    local baseIntensity = power
    local moodMultiplier = 1.0
    
    -- Adjust based on current mood
    if currentMood.type == "excited" then
        moodMultiplier = 1.2
    elseif currentMood.type == "triumphant" then
        moodMultiplier = 1.4
    elseif currentMood.type == "powerful" then
        moodMultiplier = 1.3
    elseif currentMood.type == "determined" then
        moodMultiplier = 0.9
    end
    
    local intensity = math.min(1.0, baseIntensity * moodMultiplier)
    
    -- Generate emotional color based on intensity and mood
    local color = EnhancedPullbackIndicator.getEmotionalColor(intensity, currentMood.type)
    
    -- Generate emotional message
    local message = EnhancedPullbackIndicator.getEmotionalMessage(intensity, currentMood.type, power)
    
    return {
        intensity = intensity,
        mood = currentMood.type,
        color = color,
        message = message
    }
end

-- Get emotional color based on intensity and mood
function EnhancedPullbackIndicator.getEmotionalColor(intensity, mood)
    local colors = EnhancedPullbackIndicator.config.colors
    
    if intensity > EnhancedPullbackIndicator.config.emotionalThresholds.high then
        -- High intensity - warm colors
        if mood == "triumphant" then
            return {1, 0.8, 0.2, 0.9} -- Gold
        elseif mood == "powerful" then
            return {1, 0.4, 0.8, 0.9} -- Magenta
        else
            return {1, 0.6, 0.2, 0.9} -- Orange
        end
    elseif intensity > EnhancedPullbackIndicator.config.emotionalThresholds.medium then
        -- Medium intensity - energetic colors
        if mood == "excited" then
            return {0.2, 0.8, 1, 0.8} -- Cyan
        else
            return {0.2, 1, 0.4, 0.8} -- Green
        end
    else
        -- Low intensity - calm colors
        return {0.8, 0.8, 1, 0.6} -- Light blue
    end
end

-- Get emotional message based on intensity and mood
function EnhancedPullbackIndicator.getEmotionalMessage(intensity, mood, power)
    local powerPercent = math.floor(power * 100)
    
    if intensity > EnhancedPullbackIndicator.config.emotionalThresholds.high then
        if mood == "triumphant" then
            return string.format("EPIC JUMP! (%d%%)", powerPercent)
        elseif mood == "powerful" then
            return string.format("UNLEASH POWER! (%d%%)", powerPercent)
        else
            return string.format("AMAZING! (%d%%)", powerPercent)
        end
    elseif intensity > EnhancedPullbackIndicator.config.emotionalThresholds.medium then
        if mood == "excited" then
            return string.format("EXCITING! (%d%%)", powerPercent)
        else
            return string.format("GREAT! (%d%%)", powerPercent)
        end
    else
        return string.format("Power: %d%%", powerPercent)
    end
end

-- Draw enhanced pullback indicator
function EnhancedPullbackIndicator.draw(player, mouseX, mouseY, mouseStartX, mouseStartY, pullPower, maxPullDistance)
    if not player or not player.onPlanet then return end
    
    local powerPercent = pullPower / maxPullDistance
    local angle = EnhancedPullbackIndicator.calculateAngle(mouseX, mouseY, mouseStartX, mouseStartY)
    
    -- Update state
    EnhancedPullbackIndicator.state.currentPower = powerPercent
    EnhancedPullbackIndicator.state.currentAngle = angle
    
    -- Get emotional feedback
    local emotionalFeedback = EnhancedPullbackIndicator.getEmotionalFeedback(powerPercent, angle)
    
    -- Draw power ring with emotional intensity
    EnhancedPullbackIndicator.drawPowerRing(player, powerPercent, emotionalFeedback)
    
    -- Draw angle guides
    EnhancedPullbackIndicator.drawAngleGuides(player, angle)
    
    -- Draw direction arrow with emotional feedback
    EnhancedPullbackIndicator.drawDirectionArrow(player, mouseX, mouseY, mouseStartX, mouseStartY, powerPercent, emotionalFeedback)
    
    -- Draw power meter with emotional feedback
    EnhancedPullbackIndicator.drawPowerMeter(powerPercent, emotionalFeedback)
    
    -- Draw angle indicator
    EnhancedPullbackIndicator.drawAngleIndicator(angle, emotionalFeedback)
end

-- Draw power ring with emotional intensity
function EnhancedPullbackIndicator.drawPowerRing(player, powerPercent, emotionalFeedback)
    local config = EnhancedPullbackIndicator.config
    local radius = config.powerRingMinRadius + powerPercent * (config.powerRingMaxRadius - config.powerRingMinRadius)
    
    -- Draw base ring
    Utils.setColor(config.colors.powerRing)
    love.graphics.circle("line", player.x, player.y, radius)
    
    -- Draw emotional glow
    if emotionalFeedback.intensity > config.emotionalThresholds.medium then
        local glowRadius = radius + 5 + emotionalFeedback.intensity * 10
        Utils.setColor(emotionalFeedback.color, 0.3)
        love.graphics.circle("line", player.x, player.y, glowRadius)
    end
    
    -- Draw power fill ring
    if powerPercent > 0 then
        Utils.setColor(emotionalFeedback.color)
        love.graphics.setLineWidth(3)
        love.graphics.arc("line", player.x, player.y, radius, -math.pi/2, -math.pi/2 + powerPercent * 2 * math.pi)
        love.graphics.setLineWidth(1)
    end
end

-- Draw angle guides
function EnhancedPullbackIndicator.drawAngleGuides(player, angle)
    local config = EnhancedPullbackIndicator.config
    local segments = config.angleGuideSegments
    
    Utils.setColor(config.colors.angleGuides)
    love.graphics.setLineWidth(1)
    
    for i = 0, segments - 1 do
        local guideAngle = i * (360 / segments) * math.pi / 180
        local startX = player.x + math.cos(guideAngle) * (config.angleGuideRadius - 10)
        local startY = player.y + math.sin(guideAngle) * (config.angleGuideRadius - 10)
        local endX = player.x + math.cos(guideAngle) * config.angleGuideRadius
        local endY = player.y + math.sin(guideAngle) * config.angleGuideRadius
        
        love.graphics.line(startX, startY, endX, endY)
    end
    
    -- Highlight current angle
    local currentAngleRad = angle * math.pi / 180
    local highlightX = player.x + math.cos(currentAngleRad) * config.angleGuideRadius
    local highlightY = player.y + math.sin(currentAngleRad) * config.angleGuideRadius
    
    Utils.setColor({1, 1, 1, 0.8})
    love.graphics.circle("fill", highlightX, highlightY, 3)
end

-- Draw direction arrow with emotional feedback
function EnhancedPullbackIndicator.drawDirectionArrow(player, mouseX, mouseY, mouseStartX, mouseStartY, powerPercent, emotionalFeedback)
    if powerPercent <= 0 then return end
    
    local swipeX = mouseX - mouseStartX
    local swipeY = mouseY - mouseStartY
    local swipeDistance = Utils.vectorLength(swipeX, swipeY)
    
    if swipeDistance <= 0 then return end
    
    local jumpDirectionX = -swipeX / swipeDistance
    local jumpDirectionY = -swipeY / swipeDistance
    
    -- Calculate arrow length based on power and emotional intensity
    local baseLength = 40
    local powerLength = powerPercent * 30
    local emotionalLength = emotionalFeedback.intensity * 20
    local arrowLength = baseLength + powerLength + emotionalLength
    
    local arrowEndX = player.x + jumpDirectionX * arrowLength
    local arrowEndY = player.y + jumpDirectionY * arrowLength
    
    -- Calculate line width and arrowhead size
    local lineWidth = 4 + emotionalFeedback.intensity * 4
    local arrowheadSize = 12 + emotionalFeedback.intensity * 8
    
    -- Draw arrow shaft with emotional color
    Utils.setColor(emotionalFeedback.color)
    love.graphics.setLineWidth(lineWidth)
    love.graphics.setLineJoin("miter")
    
    -- Draw the main arrow shaft
    love.graphics.line(player.x, player.y, arrowEndX, arrowEndY)
    
    -- Calculate arrowhead points for a proper triangle
    local perpX = -jumpDirectionY
    local perpY = jumpDirectionX
    
    -- Arrowhead base (where it connects to the shaft)
    local arrowheadBaseX = arrowEndX - jumpDirectionX * (arrowheadSize * 0.3)
    local arrowheadBaseY = arrowEndY - jumpDirectionY * (arrowheadSize * 0.3)
    
    -- Arrowhead side points
    local arrowheadLeftX = arrowheadBaseX + perpX * arrowheadSize * 0.6
    local arrowheadLeftY = arrowheadBaseY + perpY * arrowheadSize * 0.6
    local arrowheadRightX = arrowheadBaseX - perpX * arrowheadSize * 0.6
    local arrowheadRightY = arrowheadBaseY - perpY * arrowheadSize * 0.6
    
    -- Draw arrowhead as a filled triangle for better visual connection
    love.graphics.setLineWidth(1)
    love.graphics.polygon("fill", arrowEndX, arrowEndY, arrowheadLeftX, arrowheadLeftY, arrowheadRightX, arrowheadRightY)
    
    -- Draw arrowhead outline to match shaft
    love.graphics.setLineWidth(lineWidth * 0.8)
    love.graphics.polygon("line", arrowEndX, arrowEndY, arrowheadLeftX, arrowheadLeftY, arrowheadRightX, arrowheadRightY)
    
    -- Reset line settings
    love.graphics.setLineWidth(1)
    love.graphics.setLineJoin("miter")
end

-- Draw power meter with emotional feedback
function EnhancedPullbackIndicator.drawPowerMeter(powerPercent, emotionalFeedback)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local meterWidth = 250
    local meterHeight = 25
    local meterX = (screenWidth - meterWidth) / 2
    local meterY = screenHeight - 120
    
    -- Draw background
    Utils.setColor({0, 0, 0, 0.7})
    love.graphics.rectangle("fill", meterX, meterY, meterWidth, meterHeight, 5)
    
    -- Draw power fill with emotional color
    if powerPercent > 0 then
        Utils.setColor(emotionalFeedback.color)
        love.graphics.rectangle("fill", meterX, meterY, meterWidth * powerPercent, meterHeight, 5)
    end
    
    -- Draw border
    Utils.setColor({1, 1, 1, 0.5})
    love.graphics.rectangle("line", meterX, meterY, meterWidth, meterHeight, 5)
    
    -- Draw emotional message
    local font = love.graphics.getFont()
    local fontSize = 14
    if emotionalFeedback.intensity > EnhancedPullbackIndicator.config.emotionalThresholds.high then
        fontSize = 16
    end
    
    love.graphics.setFont(love.graphics.newFont(fontSize))
    Utils.setColor(emotionalFeedback.color)
    love.graphics.printf(emotionalFeedback.message, meterX, meterY - 25, meterWidth, "center")
    
    -- Restore font
    love.graphics.setFont(font)
end

-- Draw angle indicator
function EnhancedPullbackIndicator.drawAngleIndicator(angle, emotionalFeedback)
    local screenWidth, screenHeight = love.graphics.getDimensions()
    local indicatorX = screenWidth - 100
    local indicatorY = screenHeight - 120
    
    -- Draw angle background
    Utils.setColor({0, 0, 0, 0.7})
    love.graphics.rectangle("fill", indicatorX, indicatorY, 80, 40, 5)
    
    -- Draw angle text
    local font = love.graphics.getFont()
    love.graphics.setFont(love.graphics.newFont(12))
    Utils.setColor(emotionalFeedback.color)
    love.graphics.printf(string.format("%.0f°", angle), indicatorX, indicatorY + 5, 80, "center")
    
    -- Draw angle label
    Utils.setColor({1, 1, 1, 0.7})
    love.graphics.printf("ANGLE", indicatorX, indicatorY + 20, 80, "center")
    
    -- Restore font
    love.graphics.setFont(font)
end

-- Update emotional feedback
function EnhancedPullbackIndicator.update(dt)
    local currentTime = love.timer.getTime()
    
    -- Update emotional cooldown
    if EnhancedPullbackIndicator.state.lastEmotionalUpdate > 0 then
        EnhancedPullbackIndicator.state.lastEmotionalUpdate = EnhancedPullbackIndicator.state.lastEmotionalUpdate - dt
    end
    
    -- Process emotional events based on pullback state
    if EnhancedPullbackIndicator.state.currentPower > 0 and EnhancedPullbackIndicator.state.lastEmotionalUpdate <= 0 then
        local power = EnhancedPullbackIndicator.state.currentPower
        
        -- Trigger emotional events based on power level
        if power > EnhancedPullbackIndicator.config.emotionalThresholds.high then
            EmotionalFeedback.processEvent("jump", {
                pullPower = power,
                success = true,
                isFirstJump = false
            })
        elseif power > EnhancedPullbackIndicator.config.emotionalThresholds.medium then
            EmotionalFeedback.processEvent("jump", {
                pullPower = power,
                success = true,
                isFirstJump = false
            })
        end
        
        EnhancedPullbackIndicator.state.lastEmotionalUpdate = EnhancedPullbackIndicator.config.emotionalCooldown
    end
end

return EnhancedPullbackIndicator 