-- XP UI Module
-- Handles XP-related user interface rendering and animations

local Utils = require("src.utils.utils")
local XPDefinitions = require("src.systems.xp.xp_definitions")
local XPLogic = require("src.systems.xp.xp_logic")

local XPUI = {}

-- Font cache for performance
XPUI.fontCache = {}

-- Visual state
XPUI.xpGainAnimation = {}
XPUI.levelUpAnimation = {}
XPUI.barPulsePhase = 0

-- Initialize XP UI
function XPUI.init()
  XPUI.fontCache = {}
  XPUI.xpGainAnimation = {}
  XPUI.levelUpAnimation = {}
  XPUI.barPulsePhase = 0
  
  Utils.Logger.info("XP UI initialized")
end

-- Get cached font for performance
function XPUI.getFont(size)
  if not XPUI.fontCache[size] then
    XPUI.fontCache[size] = love.graphics.newFont(size)
  end
  return XPUI.fontCache[size]
end

-- Update XP UI
function XPUI.update(dt)
  -- Update visual effects
  XPUI.barPulsePhase = XPUI.barPulsePhase + dt * XPDefinitions.ANIMATION.BAR_PULSE_SPEED
  
  -- Update XP gain animations
  for i = #XPUI.xpGainAnimation, 1, -1 do
    local anim = XPUI.xpGainAnimation[i]
    anim.timer = anim.timer + dt
    anim.bounce_phase = anim.bounce_phase + dt * XPDefinitions.ANIMATION.BOUNCE_SPEED
    
    -- Floating upward with slight bounce
    anim.y = anim.start_y - (anim.timer * XPDefinitions.ANIMATION.FLOAT_SPEED) + 
             math.sin(anim.bounce_phase) * XPDefinitions.ANIMATION.BOUNCE_AMPLITUDE
    
    -- Fade out animation
    local progress = anim.timer / anim.duration
    anim.alpha = math.max(0, 1 - progress)
    
    -- Scale animation based on importance
    local base_scale = 1.0
    if anim.importance == "high" then 
      base_scale = 1.4
    elseif anim.importance == "medium" then 
      base_scale = 1.2
    end
    anim.scale = base_scale * (1 + math.sin(anim.bounce_phase) * XPDefinitions.ANIMATION.SCALE_VARIATION)
    
    if anim.timer >= anim.duration then
      table.remove(XPUI.xpGainAnimation, i)
    end
  end
  
  -- Update level up animations
  for i = #XPUI.levelUpAnimation, 1, -1 do
    local anim = XPUI.levelUpAnimation[i]
    anim.timer = anim.timer + dt
    anim.scale = 1 + math.sin(anim.timer * 8) * 0.3
    anim.alpha = math.max(0, 1 - anim.timer / anim.duration)
    
    if anim.timer >= anim.duration then
      table.remove(XPUI.levelUpAnimation, i)
    end
  end
end

-- Create XP gain animation
function XPUI.createXPGainAnimation(amount, source, x, y)
  local importance = XPLogic.getXPImportance(amount)
  
  local animation = {
    amount = amount,
    source = source or "unknown",
    x = x or 0,
    y = y or 0,
    start_y = y or 0,
    timer = 0,
    duration = XPDefinitions.ANIMATION.XP_GAIN_DURATION,
    alpha = 1.0,
    scale = 1.0,
    bounce_phase = 0,
    importance = importance
  }
  
  table.insert(XPUI.xpGainAnimation, animation)
end

-- Create level up animation
function XPUI.createLevelUpAnimation(level, x, y)
  local animation = {
    level = level,
    x = x or love.graphics.getWidth() / 2,
    y = y or love.graphics.getHeight() / 2,
    timer = 0,
    duration = XPDefinitions.ANIMATION.LEVEL_UP_DURATION,
    alpha = 1.0,
    scale = 1.0
  }
  
  table.insert(XPUI.levelUpAnimation, animation)
end

-- Draw XP bar
function XPUI.drawXPBar(x, y, width, height)
  local progress = XPLogic.getXPProgress()
  local progressRatio = progress.progress_ratio
  
  -- Calculate pulse effect
  local pulse = math.sin(XPUI.barPulsePhase) * 0.1 + 0.9
  
  -- Background
  love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
  love.graphics.rectangle("fill", x, y, width, height, 5)
  
  -- Progress bar
  if progressRatio > 0 then
    local barColor = {0.3 * pulse, 0.7 * pulse, 0.3 * pulse, 1}
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", x, y, width * progressRatio, height, 5)
  end
  
  -- Border
  love.graphics.setColor(0.5, 0.5, 0.7, 1)
  love.graphics.rectangle("line", x, y, width, height, 5)
  
  -- Level text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(XPUI.getFont(16))
  love.graphics.printf(string.format("Level %d", progress.level), x, y + 2, width, "center")
  
  -- XP text
  love.graphics.setFont(XPUI.getFont(12))
  love.graphics.printf(string.format("%d/%d XP", progress.current, progress.total), x, y + height + 5, width, "center")
end

-- Draw XP gain animations
function XPUI.drawXPGainAnimations()
  for _, anim in ipairs(XPUI.xpGainAnimation) do
    love.graphics.push()
    love.graphics.translate(anim.x, anim.y)
    love.graphics.scale(anim.scale, anim.scale)
    
    -- XP amount text
    love.graphics.setColor(0.3, 0.7, 0.3, anim.alpha)
    love.graphics.setFont(XPUI.getFont(20))
    love.graphics.printf("+" .. anim.amount, -50, -10, 100, "center")
    
    -- Source text
    love.graphics.setColor(0.8, 0.8, 0.8, anim.alpha)
    love.graphics.setFont(XPUI.getFont(12))
    love.graphics.printf(anim.source, -50, 10, 100, "center")
    
    love.graphics.pop()
  end
end

-- Draw level up animations
function XPUI.drawLevelUpAnimations()
  for _, anim in ipairs(XPUI.levelUpAnimation) do
    love.graphics.push()
    love.graphics.translate(anim.x, anim.y)
    love.graphics.scale(anim.scale, anim.scale)
    
    -- Level up background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9 * anim.alpha)
    love.graphics.rectangle("fill", -100, -50, 200, 100, 10)
    
    love.graphics.setColor(0.3, 0.7, 0.3, anim.alpha)
    love.graphics.rectangle("line", -100, -50, 200, 100, 10)
    
    -- Level up text
    love.graphics.setColor(1, 1, 1, anim.alpha)
    love.graphics.setFont(XPUI.getFont(24))
    love.graphics.printf("LEVEL UP!", -100, -30, 200, "center")
    
    love.graphics.setFont(XPUI.getFont(20))
    love.graphics.printf("Level " .. anim.level, -100, 0, 200, "center")
    
    love.graphics.pop()
  end
end

-- Draw XP UI
function XPUI.draw()
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  
  -- Draw XP bar in top-left corner
  local barX = 20
  local barY = 20
  local barWidth = XPDefinitions.VISUAL.BAR_WIDTH
  local barHeight = XPDefinitions.VISUAL.BAR_HEIGHT
  
  XPUI.drawXPBar(barX, barY, barWidth, barHeight)
  
  -- Draw animations
  XPUI.drawXPGainAnimations()
  XPUI.drawLevelUpAnimations()
end

-- Draw XP bar at custom position
function XPUI.drawXPBarAt(x, y, width, height)
  XPUI.drawXPBar(x, y, width or XPDefinitions.VISUAL.BAR_WIDTH, height or XPDefinitions.VISUAL.BAR_HEIGHT)
end

-- Draw reward notification
function XPUI.drawRewardNotification(reward, x, y)
  if not reward then return end
  
  local width = 300
  local height = 80
  
  -- Background
  love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
  love.graphics.rectangle("fill", x, y, width, height, 10)
  
  love.graphics.setColor(0.3, 0.7, 0.3, 1)
  love.graphics.rectangle("line", x, y, width, height, 10)
  
  -- Reward icon
  local icon = "🎁"
  if reward.type == "ability" then
    icon = "⚡"
  elseif reward.type == "cosmetic" then
    icon = "✨"
  end
  
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(XPUI.getFont(24))
  love.graphics.printf(icon, x + 10, y + 10, 40, "center")
  
  -- Reward name
  love.graphics.setFont(XPUI.getFont(16))
  love.graphics.printf(reward.name, x + 60, y + 10, width - 70, "left")
  
  -- Reward description
  love.graphics.setFont(XPUI.getFont(12))
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.printf(reward.description, x + 60, y + 30, width - 70, "left")
  
  -- Reward type
  love.graphics.setColor(0.5, 0.7, 0.5, 1)
  love.graphics.setFont(XPUI.getFont(10))
  love.graphics.printf(string.upper(reward.type), x + 60, y + 50, width - 70, "left")
end

-- Draw XP statistics
function XPUI.drawXPStats(x, y)
  local stats = XPLogic.getStats()
  local width = 250
  local height = 150
  
  -- Background
  love.graphics.setColor(0.1, 0.1, 0.2, 0.8)
  love.graphics.rectangle("fill", x, y, width, height, 5)
  
  love.graphics.setColor(0.5, 0.5, 0.7, 1)
  love.graphics.rectangle("line", x, y, width, height, 5)
  
  -- Title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(XPUI.getFont(16))
  love.graphics.printf("XP Statistics", x, y + 10, width, "center")
  
  -- Stats
  love.graphics.setFont(XPUI.getFont(12))
  local lineY = y + 35
  local lineHeight = 18
  
  love.graphics.printf(string.format("Level: %d", stats.current_level), x + 10, lineY, width - 20, "left")
  lineY = lineY + lineHeight
  
  love.graphics.printf(string.format("Current XP: %d", stats.current_xp), x + 10, lineY, width - 20, "left")
  lineY = lineY + lineHeight
  
  love.graphics.printf(string.format("Total XP: %d", stats.total_xp), x + 10, lineY, width - 20, "left")
  lineY = lineY + lineHeight
  
  love.graphics.printf(string.format("Progress: %.1f%%", stats.progress_ratio * 100), x + 10, lineY, width - 20, "left")
  lineY = lineY + lineHeight
  
  love.graphics.printf(string.format("Rewards: %d/%d", stats.unlocked_rewards_count, stats.unlocked_rewards_count + stats.available_rewards_count), x + 10, lineY, width - 20, "left")
end

-- Clear all animations
function XPUI.clearAnimations()
  XPUI.xpGainAnimation = {}
  XPUI.levelUpAnimation = {}
  XPUI.barPulsePhase = 0
end

return XPUI 