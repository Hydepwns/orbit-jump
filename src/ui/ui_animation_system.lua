-- UI Animation System for Orbit Jump
-- Centralized, modular system for all UI animations and effects
local Utils = require("src.utils.utils")
local UIAnimationSystem = {}
-- Animation state
UIAnimationSystem.animations = {}
UIAnimationSystem.nextId = 1
-- Animation types
UIAnimationSystem.TYPES = {
    FLASH = "flash",
    FLOAT = "float",
    PULSE = "pulse",
    FADE = "fade",
    SHAKE = "shake"
}
-- Default animation settings
UIAnimationSystem.DEFAULTS = {
    FLASH_DURATION = 0.3,
    FLOAT_DURATION = 1.0,
    PULSE_FREQUENCY = 1.5,
    PULSE_AMPLITUDE = 0.1,
    FADE_DURATION = 0.5,
    SHAKE_DURATION = 0.2
}
-- Initialize the animation system
function UIAnimationSystem.init()
    UIAnimationSystem.animations = {}
    UIAnimationSystem.nextId = 1
    Utils.Logger.info("UI Animation System initialized")
end
-- Create a new animation
function UIAnimationSystem.createAnimation(animationType, config)
    local id = UIAnimationSystem.nextId
    UIAnimationSystem.nextId = UIAnimationSystem.nextId + 1
    local animation = {
        id = id,
        type = animationType,
        startTime = love.timer.getTime(),
        duration = config.duration or UIAnimationSystem.DEFAULTS.FLASH_DURATION,
        position = config.position or {x = 0, y = 0},
        size = config.size or {width = 100, height = 50},
        text = config.text or "",
        color = config.color or {1, 1, 1, 1},
        bounds = config.bounds or nil, -- Screen bounds for positioning
        pulseFrequency = config.pulseFrequency or UIAnimationSystem.DEFAULTS.PULSE_FREQUENCY,
        pulseAmplitude = config.pulseAmplitude or UIAnimationSystem.DEFAULTS.PULSE_AMPLITUDE,
        shakeIntensity = config.shakeIntensity or 1.0,
        callback = config.callback or nil
    }
    UIAnimationSystem.animations[id] = animation
    return id
end
-- Create a flash animation (for streak broken, level up, etc.)
function UIAnimationSystem.createFlashAnimation(text, config)
    config = config or {}
    config.duration = config.duration or UIAnimationSystem.DEFAULTS.FLASH_DURATION
    config.text = text
    config.type = UIAnimationSystem.TYPES.FLASH
    return UIAnimationSystem.createAnimation(UIAnimationSystem.TYPES.FLASH, config)
end
-- Create a floating UI element with constrained bounds
function UIAnimationSystem.createFloatingUI(config)
    config = config or {}
    config.type = UIAnimationSystem.TYPES.FLOAT
    config.duration = config.duration or UIAnimationSystem.DEFAULTS.FLOAT_DURATION
    -- Ensure bounds are set for floating UI
    if not config.bounds then
        local screenWidth, screenHeight = love.graphics.getDimensions()
        config.bounds = {
            minX = 10,
            minY = 10,
            maxX = screenWidth - 10,
            maxY = screenHeight - 10
        }
    end
    return UIAnimationSystem.createAnimation(UIAnimationSystem.TYPES.FLOAT, config)
end
-- Create a pulse animation (for learning indicator, etc.)
function UIAnimationSystem.createPulseAnimation(config)
    config = config or {}
    config.type = UIAnimationSystem.TYPES.PULSE
    config.duration = math.huge -- Pulse animations run indefinitely
    return UIAnimationSystem.createAnimation(UIAnimationSystem.TYPES.PULSE, config)
end
-- Update all animations
function UIAnimationSystem.update(dt)
    local currentTime = love.timer.getTime()
    local toRemove = {}
    for id, animation in pairs(UIAnimationSystem.animations) do
        local elapsed = currentTime - animation.startTime
        -- Check if animation should be removed
        if elapsed >= animation.duration then
            table.insert(toRemove, id)
            -- Call callback if provided
            if animation.callback then
                animation.callback()
            end
        end
    end
    -- Remove finished animations
    for _, id in ipairs(toRemove) do
        UIAnimationSystem.animations[id] = nil
    end
end
-- Get animation progress (0 to 1)
function UIAnimationSystem.getProgress(animation)
    local currentTime = love.timer.getTime()
    local elapsed = currentTime - animation.startTime
    return math.min(elapsed / animation.duration, 1.0)
end
-- Get constrained position for floating UI
function UIAnimationSystem.getConstrainedPosition(animation)
    local x, y = animation.position.x, animation.position.y
    if animation.bounds then
        x = math.max(animation.bounds.minX, math.min(animation.bounds.maxX - animation.size.width, x))
        y = math.max(animation.bounds.minY, math.min(animation.bounds.maxY - animation.size.height, y))
    end
    return x, y
end
-- Draw all animations
function UIAnimationSystem.draw()
    for _, animation in pairs(UIAnimationSystem.animations) do
        UIAnimationSystem.drawAnimation(animation)
    end
end
-- Draw a specific animation
function UIAnimationSystem.drawAnimation(animation)
    local progress = UIAnimationSystem.getProgress(animation)
    if animation.type == UIAnimationSystem.TYPES.FLASH then
        UIAnimationSystem.drawFlashAnimation(animation, progress)
    elseif animation.type == UIAnimationSystem.TYPES.FLOAT then
        UIAnimationSystem.drawFloatAnimation(animation, progress)
    elseif animation.type == UIAnimationSystem.TYPES.PULSE then
        UIAnimationSystem.drawPulseAnimation(animation, progress)
    elseif animation.type == UIAnimationSystem.TYPES.FADE then
        UIAnimationSystem.drawFadeAnimation(animation, progress)
    elseif animation.type == UIAnimationSystem.TYPES.SHAKE then
        UIAnimationSystem.drawShakeAnimation(animation, progress)
    end
end
-- Draw flash animation (streak broken, level up)
function UIAnimationSystem.drawFlashAnimation(animation, progress)
    local alpha = 1.0 - progress
    -- Screen flash effect (only for first 50% of duration)
    if progress < 0.5 then
        local flashAlpha = alpha * 0.3
        Utils.setColor({1, 0, 0}, flashAlpha)
        local screenWidth, screenHeight = love.graphics.getDimensions()
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    end
    -- Text effect (only for first 70% of duration)
    if progress < 0.7 and animation.text then
        local textAlpha = alpha
        local screenWidth, screenHeight = love.graphics.getDimensions()
        -- Use cached font to prevent repeated font creation
        local font = love.graphics.newFont(48)
        love.graphics.setFont(font)
        local textWidth = font:getWidth(animation.text)
        local textX = screenWidth/2 - textWidth/2
        local textY = screenHeight/2 - 24
        -- Text shadow
        Utils.setColor({0, 0, 0}, textAlpha * 0.8)
        love.graphics.print(animation.text, textX + 3, textY + 3)
        -- Main text
        Utils.setColor({1, 0, 0}, textAlpha)
        love.graphics.print(animation.text, textX, textY)
    end
end
-- Draw float animation (constrained UI elements)
function UIAnimationSystem.drawFloatAnimation(animation, progress)
    local x, y = UIAnimationSystem.getConstrainedPosition(animation)
    local alpha = 1.0 - progress
    -- Draw background
    Utils.setColor(animation.color[1], animation.color[2], animation.color[3], alpha * animation.color[4])
    love.graphics.rectangle("fill", x, y, animation.size.width, animation.size.height, 5)
    -- Draw border
    Utils.setColor(animation.color[1], animation.color[2], animation.color[3], alpha * 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, animation.size.width, animation.size.height, 5)
    love.graphics.setLineWidth(1)
    -- Draw text if provided
    if animation.text then
        Utils.setColor({1, 1, 1}, alpha)
        local font = love.graphics.newFont(12)
        love.graphics.setFont(font)
        love.graphics.print(animation.text, x + 8, y + 8)
    end
end
-- Draw pulse animation (learning indicator, etc.)
function UIAnimationSystem.drawPulseAnimation(animation, progress)
    local x, y = UIAnimationSystem.getConstrainedPosition(animation)
    local currentTime = love.timer.getTime()
    -- Calculate pulse effect
    local pulseAlpha = 0.3 + animation.pulseAmplitude * math.sin(currentTime * animation.pulseFrequency)
    local pulseScale = 1.0 + animation.pulseAmplitude * 0.1 * math.sin(currentTime * animation.pulseFrequency * 2)
    -- Draw background with pulse
    Utils.setColor(animation.color[1], animation.color[2], animation.color[3], pulseAlpha)
    love.graphics.rectangle("fill", x, y, animation.size.width, animation.size.height, 5)
    -- Draw border
    Utils.setColor(animation.color[1], animation.color[2], animation.color[3], 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, animation.size.width, animation.size.height, 5)
    love.graphics.setLineWidth(1)
    -- Draw text if provided
    if animation.text then
        Utils.setColor({1, 1, 1}, 1.0)
        local font = love.graphics.newFont(12)
        love.graphics.setFont(font)
        love.graphics.print(animation.text, x + 8, y + 8)
    end
end
-- Draw fade animation
function UIAnimationSystem.drawFadeAnimation(animation, progress)
    local x, y = UIAnimationSystem.getConstrainedPosition(animation)
    local alpha = 1.0 - progress
    Utils.setColor(animation.color[1], animation.color[2], animation.color[3], alpha * animation.color[4])
    love.graphics.rectangle("fill", x, y, animation.size.width, animation.size.height, 5)
    if animation.text then
        Utils.setColor({1, 1, 1}, alpha)
        local font = love.graphics.newFont(12)
        love.graphics.setFont(font)
        love.graphics.print(animation.text, x + 8, y + 8)
    end
end
-- Draw shake animation
function UIAnimationSystem.drawShakeAnimation(animation, progress)
    local x, y = UIAnimationSystem.getConstrainedPosition(animation)
    local currentTime = love.timer.getTime()
    -- Calculate shake offset
    local shakeX = math.sin(currentTime * 20) * animation.shakeIntensity * (1.0 - progress) * 5
    local shakeY = math.cos(currentTime * 15) * animation.shakeIntensity * (1.0 - progress) * 5
    love.graphics.push()
    love.graphics.translate(shakeX, shakeY)
    Utils.setColor(animation.color[1], animation.color[2], animation.color[3], animation.color[4])
    love.graphics.rectangle("fill", x, y, animation.size.width, animation.size.height, 5)
    if animation.text then
        Utils.setColor({1, 1, 1}, 1.0)
        local font = love.graphics.newFont(12)
        love.graphics.setFont(font)
        love.graphics.print(animation.text, x + 8, y + 8)
    end
    love.graphics.pop()
end
-- Remove all animations
function UIAnimationSystem.clear()
    UIAnimationSystem.animations = {}
end
-- Remove specific animation
function UIAnimationSystem.remove(id)
    UIAnimationSystem.animations[id] = nil
end
-- Get animation count
function UIAnimationSystem.getCount()
    local count = 0
    for _ in pairs(UIAnimationSystem.animations) do
        count = count + 1
    end
    return count
end
return UIAnimationSystem