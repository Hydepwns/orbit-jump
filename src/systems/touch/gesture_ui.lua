-- Gesture UI Module
-- Handles visual feedback and haptic responses for touch gestures

local Utils = require("src.utils.utils")
local GestureDefinitions = require("src.systems.touch.gesture_definitions")
local GestureRecognition = require("src.systems.touch.gesture_recognition")

local GestureUI = {}

-- Visual feedback state
GestureUI.visualEffects = {
  pullbackIndicator = {
    visible = false,
    x = 0,
    y = 0,
    strength = 0,
    angle = 0,
    alpha = 0
  },
  gestureFeedback = {},
  touchPoints = {}
}

-- Animation state
GestureUI.animations = {
  pullbackPulse = 0,
  feedbackFade = 0
}

-- Initialize gesture UI
function GestureUI.init()
  GestureUI.visualEffects = {
    pullbackIndicator = {
      visible = false,
      x = 0,
      y = 0,
      strength = 0,
      angle = 0,
      alpha = 0
    },
    gestureFeedback = {},
    touchPoints = {}
  }
  
  GestureUI.animations = {
    pullbackPulse = 0,
    feedbackFade = 0
  }
  
  Utils.Logger.info("Gesture UI initialized")
end

-- Update gesture UI
function GestureUI.update(dt)
  -- Update animations
  GestureUI.animations.pullbackPulse = GestureUI.animations.pullbackPulse + dt * 4
  GestureUI.animations.feedbackFade = GestureUI.animations.feedbackFade + dt
  
  -- Update pullback indicator
  local pullbackData = GestureRecognition.getPullbackData()
  if pullbackData.active then
    GestureUI.visualEffects.pullbackIndicator.visible = true
    GestureUI.visualEffects.pullbackIndicator.x = pullbackData.startX
    GestureUI.visualEffects.pullbackIndicator.y = pullbackData.startY
    GestureUI.visualEffects.pullbackIndicator.strength = pullbackData.strength
    GestureUI.visualEffects.pullbackIndicator.angle = pullbackData.angle
    GestureUI.visualEffects.pullbackIndicator.alpha = math.min(1.0, pullbackData.strength / 100)
  else
    GestureUI.visualEffects.pullbackIndicator.visible = false
    GestureUI.visualEffects.pullbackIndicator.alpha = 0
  end
  
  -- Update gesture feedback animations
  for i = #GestureUI.visualEffects.gestureFeedback, 1, -1 do
    local feedback = GestureUI.visualEffects.gestureFeedback[i]
    feedback.time = feedback.time + dt
    
    -- Fade out animation
    local progress = feedback.time / feedback.duration
    feedback.alpha = math.max(0, 1 - progress)
    feedback.scale = 1 + progress * 0.5
    
    -- Remove expired feedback
    if feedback.time >= feedback.duration then
      table.remove(GestureUI.visualEffects.gestureFeedback, i)
    end
  end
  
  -- Update touch point indicators
  GestureUI.updateTouchPoints()
end

-- Update touch point indicators
function GestureUI.updateTouchPoints()
  local touchState = GestureRecognition.touchState
  GestureUI.visualEffects.touchPoints = {}
  
  for id, touch in pairs(touchState.touches) do
    table.insert(GestureUI.visualEffects.touchPoints, {
      x = touch.x,
      y = touch.y,
      pressure = touch.pressure,
      id = id
    })
  end
end

-- Add gesture feedback
function GestureUI.addGestureFeedback(gestureType, x, y, data)
  local feedback = {
    type = gestureType,
    x = x,
    y = y,
    data = data,
    time = 0,
    duration = 1.0,
    alpha = 1.0,
    scale = 1.0
  }
  
  table.insert(GestureUI.visualEffects.gestureFeedback, feedback)
  
  -- Trigger haptic feedback
  GestureUI.triggerHapticFeedback(gestureType, data.direction)
end

-- Trigger haptic feedback
function GestureUI.triggerHapticFeedback(gestureType, direction)
  local intensity = GestureDefinitions.getHapticIntensity(gestureType, direction)
  
  -- Check if haptic feedback is available
  if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
    -- This would need platform-specific haptic API implementation
    -- For now, we'll just log the haptic event
    Utils.Logger.debug("Haptic feedback: %s (intensity: %.2f)", gestureType, intensity)
  end
end

-- Draw gesture UI
function GestureUI.draw()
  -- Draw pullback indicator
  GestureUI.drawPullbackIndicator()
  
  -- Draw gesture feedback
  GestureUI.drawGestureFeedback()
  
  -- Draw touch points
  GestureUI.drawTouchPoints()
end

-- Draw pullback indicator
function GestureUI.drawPullbackIndicator()
  local indicator = GestureUI.visualEffects.pullbackIndicator
  
  if not indicator.visible or indicator.alpha <= 0 then
    return
  end
  
  local pulse = math.sin(GestureUI.animations.pullbackPulse) * 0.2 + 0.8
  
  -- Draw pullback line
  love.graphics.setColor(0.3, 0.7, 0.3, indicator.alpha * pulse)
  love.graphics.setLineWidth(3)
  
  local endX = indicator.x + math.cos(indicator.angle) * indicator.strength
  local endY = indicator.y + math.sin(indicator.angle) * indicator.strength
  
  love.graphics.line(indicator.x, indicator.y, endX, endY)
  love.graphics.setLineWidth(1)
  
  -- Draw pullback circle
  love.graphics.setColor(0.3, 0.7, 0.3, indicator.alpha * 0.5)
  love.graphics.circle("fill", indicator.x, indicator.y, 10)
  
  -- Draw strength indicator
  if indicator.strength > 0 then
    love.graphics.setColor(1, 1, 1, indicator.alpha)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf(string.format("%.0f", indicator.strength), 
                         indicator.x - 20, indicator.y - 10, 40, "center")
  end
end

-- Draw gesture feedback
function GestureUI.drawGestureFeedback()
  for _, feedback in ipairs(GestureUI.visualEffects.gestureFeedback) do
    love.graphics.push()
    love.graphics.translate(feedback.x, feedback.y)
    love.graphics.scale(feedback.scale, feedback.scale)
    
    -- Draw feedback based on gesture type
    if feedback.type == "tap" then
      GestureUI.drawTapFeedback(feedback)
    elseif feedback.type == "double_tap" then
      GestureUI.drawDoubleTapFeedback(feedback)
    elseif feedback.type == "long_press" then
      GestureUI.drawLongPressFeedback(feedback)
    elseif feedback.type == "swipe" then
      GestureUI.drawSwipeFeedback(feedback)
    elseif feedback.type == "pinch" then
      GestureUI.drawPinchFeedback(feedback)
    elseif feedback.type == "pullback" then
      GestureUI.drawPullbackFeedback(feedback)
    end
    
    love.graphics.pop()
  end
end

-- Draw tap feedback
function GestureUI.drawTapFeedback(feedback)
  love.graphics.setColor(0.3, 0.7, 0.3, feedback.alpha)
  love.graphics.circle("line", 0, 0, 30)
  
  love.graphics.setColor(1, 1, 1, feedback.alpha)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf("TAP", -30, -10, 60, "center")
end

-- Draw double tap feedback
function GestureUI.drawDoubleTapFeedback(feedback)
  love.graphics.setColor(0.7, 0.3, 0.7, feedback.alpha)
  love.graphics.circle("line", 0, 0, 35)
  
  love.graphics.setColor(1, 1, 1, feedback.alpha)
  love.graphics.setFont(Utils.getFont(14))
  love.graphics.printf("DOUBLE", -40, -15, 80, "center")
  love.graphics.printf("TAP", -40, 0, 80, "center")
end

-- Draw long press feedback
function GestureUI.drawLongPressFeedback(feedback)
  love.graphics.setColor(0.7, 0.7, 0.3, feedback.alpha)
  love.graphics.circle("fill", 0, 0, 25)
  
  love.graphics.setColor(0.2, 0.2, 0.2, feedback.alpha)
  love.graphics.setFont(Utils.getFont(12))
  love.graphics.printf("HOLD", -25, -8, 50, "center")
end

-- Draw swipe feedback
function GestureUI.drawSwipeFeedback(feedback)
  local direction = feedback.data.direction or "unknown"
  
  love.graphics.setColor(0.3, 0.3, 0.7, feedback.alpha)
  love.graphics.circle("line", 0, 0, 30)
  
  love.graphics.setColor(1, 1, 1, feedback.alpha)
  love.graphics.setFont(Utils.getFont(12))
  love.graphics.printf(string.upper(direction), -30, -8, 60, "center")
end

-- Draw pinch feedback
function GestureUI.drawPinchFeedback(feedback)
  local zoom = feedback.data.zoom or 1.0
  local zoomText = string.format("%.1fx", zoom)
  
  love.graphics.setColor(0.7, 0.3, 0.3, feedback.alpha)
  love.graphics.circle("line", 0, 0, 30)
  
  love.graphics.setColor(1, 1, 1, feedback.alpha)
  love.graphics.setFont(Utils.getFont(12))
  love.graphics.printf("PINCH", -30, -15, 60, "center")
  love.graphics.printf(zoomText, -30, 0, 60, "center")
end

-- Draw pullback feedback
function GestureUI.drawPullbackFeedback(feedback)
  local strength = feedback.data.strength or 0
  
  love.graphics.setColor(0.3, 0.7, 0.3, feedback.alpha)
  love.graphics.circle("line", 0, 0, 30)
  
  love.graphics.setColor(1, 1, 1, feedback.alpha)
  love.graphics.setFont(Utils.getFont(12))
  love.graphics.printf("PULL", -30, -15, 60, "center")
  love.graphics.printf(string.format("%.0f", strength), -30, 0, 60, "center")
end

-- Draw touch points
function GestureUI.drawTouchPoints()
  for _, touch in ipairs(GestureUI.visualEffects.touchPoints) do
    -- Draw touch point
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("fill", touch.x, touch.y, 8)
    
    -- Draw touch point border
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.circle("line", touch.x, touch.y, 8)
    
    -- Draw touch ID
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.setFont(Utils.getFont(10))
    love.graphics.printf(tostring(touch.id), touch.x - 10, touch.y - 5, 20, "center")
  end
end

-- Draw gesture debug info
function GestureUI.drawDebugInfo(x, y)
  local touchCount = GestureRecognition.getTouchCount()
  local activeGestures = GestureRecognition.getActiveGestures()
  local pullbackData = GestureRecognition.getPullbackData()
  
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.setFont(Utils.getFont(12))
  
  local lineY = y
  love.graphics.printf(string.format("Touch Count: %d", touchCount), x, lineY, 200, "left")
  lineY = lineY + 20
  
  love.graphics.printf(string.format("Active Gestures: %d", #activeGestures), x, lineY, 200, "left")
  lineY = lineY + 20
  
  if pullbackData.active then
    love.graphics.printf(string.format("Pullback: %.1f @ %.1f°", pullbackData.strength, math.deg(pullbackData.angle)), x, lineY, 200, "left")
    lineY = lineY + 20
  end
  
  -- Draw recent gestures
  for i, gesture in ipairs(activeGestures) do
    if i <= 5 then -- Limit to 5 recent gestures
      love.graphics.printf(string.format("[%s] %s", gesture.type, gesture.data.direction or ""), x, lineY, 200, "left")
      lineY = lineY + 15
    end
  end
end

-- Clear all visual effects
function GestureUI.clearEffects()
  GestureUI.visualEffects.gestureFeedback = {}
  GestureUI.visualEffects.touchPoints = {}
  GestureUI.visualEffects.pullbackIndicator.visible = false
end

-- Set pullback indicator visibility
function GestureUI.setPullbackIndicatorVisible(visible)
  GestureUI.visualEffects.pullbackIndicator.visible = visible
end

-- Get visual effects state
function GestureUI.getVisualEffectsState()
  return GestureUI.visualEffects
end

return GestureUI 