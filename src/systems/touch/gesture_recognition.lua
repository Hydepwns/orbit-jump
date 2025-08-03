-- Gesture Recognition Module
-- Handles touch input processing and gesture detection
local Utils = require("src.utils.utils")
local GestureDefinitions = require("src.systems.touch.gesture_definitions")
local GestureRecognition = {}
-- Touch state management
GestureRecognition.touchState = {
  touches = {},                 -- Active touch points
  gestures = {},                -- Active gestures
  lastTapTime = 0,              -- Last tap timestamp
  lastTapPosition = {x = 0, y = 0},
  longPressTimer = 0,           -- Long press timer
  longPressPosition = {x = 0, y = 0},
  pinchStartDistance = 0,       -- Initial pinch distance
  pinchStartZoom = 1.0,         -- Zoom level at pinch start
  pullbackStart = {x = 0, y = 0}, -- Pullback start position
  pullbackActive = false,       -- Is pullback currently active
  pullbackStrength = 0,         -- Current pullback strength
  pullbackAngle = 0             -- Current pullback angle
}
-- Initialize gesture recognition
function GestureRecognition.init()
  GestureRecognition.resetState()
  Utils.Logger.info("Gesture recognition initialized")
end
-- Reset touch state
function GestureRecognition.resetState()
  GestureRecognition.touchState = {
    touches = {},
    gestures = {},
    lastTapTime = 0,
    lastTapPosition = {x = 0, y = 0},
    longPressTimer = 0,
    longPressPosition = {x = 0, y = 0},
    pinchStartDistance = 0,
    pinchStartZoom = 1.0,
    pullbackStart = {x = 0, y = 0},
    pullbackActive = false,
    pullbackStrength = 0,
    pullbackAngle = 0
  }
end
-- Update gesture recognition
function GestureRecognition.update(dt)
  local state = GestureRecognition.touchState
  -- Update long press timer
  if #state.touches > 0 and not state.pullbackActive then
    state.longPressTimer = state.longPressTimer + dt
    -- Check for long press
    if state.longPressTimer >= GestureDefinitions.constants.LONG_PRESS_DURATION then
      local touch = state.touches[1]
      local distance = Utils.getDistance(touch.x, touch.y, state.longPressPosition.x, state.longPressPosition.y)
      if distance <= GestureDefinitions.constants.MAX_TAP_DISTANCE then
        GestureRecognition.triggerGesture("long_press", {
          x = touch.x,
          y = touch.y,
          duration = state.longPressTimer
        })
      end
    end
  else
    state.longPressTimer = 0
  end
  -- Update active gestures
  for i = #state.gestures, 1, -1 do
    local gesture = state.gestures[i]
    gesture.duration = gesture.duration + dt
    -- Remove expired gestures
    if gesture.duration >= GestureDefinitions.constants.GESTURE_TIMEOUT then
      table.remove(state.gestures, i)
    end
  end
end
-- Handle touch pressed
function GestureRecognition.touchpressed(id, x, y, pressure)
  local state = GestureRecognition.touchState
  -- Add touch to active touches
  state.touches[id] = {
    id = id,
    x = x,
    y = y,
    pressure = pressure or 1.0,
    startX = x,
    startY = y,
    startTime = love.timer.getTime()
  }
  -- Initialize long press tracking
  if #state.touches == 1 then
    state.longPressPosition = {x = x, y = y}
    state.longPressTimer = 0
  end
  -- Handle multi-touch gestures
  if #state.touches == 2 then
    GestureRecognition.handleMultiTouchStart()
  end
  -- Handle pullback gesture
  if #state.touches == 1 and not state.pullbackActive then
    state.pullbackStart = {x = x, y = y}
    state.pullbackActive = true
    state.pullbackStrength = 0
    state.pullbackAngle = 0
  end
end
-- Handle touch moved
function GestureRecognition.touchmoved(id, x, y, pressure)
  local state = GestureRecognition.touchState
  local touch = state.touches[id]
  if not touch then
    return
  end
  -- Update touch position
  touch.x = x
  touch.y = y
  touch.pressure = pressure or 1.0
  -- Handle multi-touch gestures
  if #state.touches == 2 then
    GestureRecognition.handleMultiTouchMove()
  end
  -- Handle pullback gesture
  if #state.touches == 1 and state.pullbackActive then
    GestureRecognition.updatePullback(x, y)
  end
  -- Reset long press if moved too far
  if #state.touches == 1 then
    local distance = Utils.getDistance(x, y, state.longPressPosition.x, state.longPressPosition.y)
    if distance > GestureDefinitions.constants.MAX_TAP_DISTANCE then
      state.longPressTimer = 0
    end
  end
end
-- Handle touch released
function GestureRecognition.touchreleased(id, x, y)
  local state = GestureRecognition.touchState
  local touch = state.touches[id]
  if not touch then
    return
  end
  local duration = love.timer.getTime() - touch.startTime
  local distance = Utils.getDistance(x, y, touch.startX, touch.startY)
  -- Handle single touch release
  if #state.touches == 1 then
    -- Check for tap
    if duration <= GestureDefinitions.constants.TAP_DURATION and
       distance <= GestureDefinitions.constants.MAX_TAP_DISTANCE then
      -- Check for double tap
      local timeSinceLastTap = love.timer.getTime() - state.lastTapTime
      local distanceFromLastTap = Utils.getDistance(x, y, state.lastTapPosition.x, state.lastTapPosition.y)
      if timeSinceLastTap <= GestureDefinitions.constants.DOUBLE_TAP_DELAY and
         distanceFromLastTap <= GestureDefinitions.constants.MAX_TAP_DISTANCE then
        GestureRecognition.triggerGesture("double_tap", {
          x = x,
          y = y,
          duration = duration
        })
        state.lastTapTime = 0 -- Reset to prevent triple tap
      else
        GestureRecognition.triggerGesture("tap", {
          x = x,
          y = y,
          duration = duration
        })
        state.lastTapTime = love.timer.getTime()
        state.lastTapPosition = {x = x, y = y}
      end
    end
    -- Handle pullback release
    if state.pullbackActive then
      GestureRecognition.triggerGesture("pullback", {
        x = x,
        y = y,
        strength = state.pullbackStrength,
        angle = state.pullbackAngle,
        duration = duration
      })
      state.pullbackActive = false
      state.pullbackStrength = 0
      state.pullbackAngle = 0
    end
  end
  -- Handle multi-touch release
  if #state.touches == 2 then
    GestureRecognition.handleMultiTouchEnd()
  end
  -- Remove touch from active touches
  state.touches[id] = nil
  -- Reset long press if no touches remain
  if #state.touches == 0 then
    state.longPressTimer = 0
  end
end
-- Handle multi-touch start
function GestureRecognition.handleMultiTouchStart()
  local state = GestureRecognition.touchState
  if #state.touches ~= 2 then
    return
  end
  local touch1, touch2
  for _, touch in pairs(state.touches) do
    if not touch1 then
      touch1 = touch
    else
      touch2 = touch
      break
    end
  end
  if touch1 and touch2 then
    -- Calculate initial pinch distance
    state.pinchStartDistance = Utils.getDistance(touch1.x, touch1.y, touch2.x, touch2.y)
    state.pinchStartZoom = 1.0
  end
end
-- Handle multi-touch move
function GestureRecognition.handleMultiTouchMove()
  local state = GestureRecognition.touchState
  if #state.touches ~= 2 then
    return
  end
  local touch1, touch2
  for _, touch in pairs(state.touches) do
    if not touch1 then
      touch1 = touch
    else
      touch2 = touch
      break
    end
  end
  if touch1 and touch2 then
    local currentDistance = Utils.getDistance(touch1.x, touch1.y, touch2.x, touch2.y)
    -- Check for pinch gesture
    if math.abs(currentDistance - state.pinchStartDistance) > GestureDefinitions.constants.PINCH_MIN_DISTANCE then
      local zoomDelta = (currentDistance - state.pinchStartDistance) * GestureDefinitions.constants.ZOOM_SENSITIVITY
      GestureRecognition.triggerGesture("pinch", {
        x = (touch1.x + touch2.x) / 2,
        y = (touch1.y + touch2.y) / 2,
        zoom = 1.0 + zoomDelta,
        zoomDelta = zoomDelta,
        distance = currentDistance
      })
    end
    -- Check for rotate gesture
    local angle1 = math.atan2(touch1.y - touch2.y, touch1.x - touch2.x)
    local angle2 = math.atan2(touch2.y - touch1.y, touch2.x - touch1.x)
    local rotation = math.deg(angle1 - angle2)
    if math.abs(rotation) > 5 then
      GestureRecognition.triggerGesture("rotate", {
        x = (touch1.x + touch2.x) / 2,
        y = (touch1.y + touch2.y) / 2,
        rotation = rotation,
        angle = angle1
      })
    end
  end
end
-- Handle multi-touch end
function GestureRecognition.handleMultiTouchEnd()
  local state = GestureRecognition.touchState
  -- Reset pinch state
  state.pinchStartDistance = 0
  state.pinchStartZoom = 1.0
end
-- Update pullback gesture
function GestureRecognition.updatePullback(x, y)
  local state = GestureRecognition.touchState
  local dx = x - state.pullbackStart.x
  local dy = y - state.pullbackStart.y
  local distance = math.sqrt(dx * dx + dy * dy)
  state.pullbackStrength = distance * GestureDefinitions.constants.PULLBACK_SENSITIVITY
  state.pullbackAngle = math.atan2(dy, dx)
  -- Trigger pullback update
  GestureRecognition.triggerGesture("pullback_update", {
    x = x,
    y = y,
    strength = state.pullbackStrength,
    angle = state.pullbackAngle,
    distance = distance
  })
end
-- Detect swipe gesture
function GestureRecognition.detectSwipe(startX, startY, endX, endY, duration)
  local distance = Utils.getDistance(endX, endY, startX, startY)
  if distance < GestureDefinitions.constants.MIN_SWIPE_DISTANCE then
    return nil
  end
  local dx = endX - startX
  local dy = endY - startY
  local angle = math.deg(math.atan2(dy, dx))
  -- Determine swipe direction
  local direction
  if angle >= -22.5 and angle < 22.5 then
    direction = "right"
  elseif angle >= 22.5 and angle < 67.5 then
    direction = "down_right"
  elseif angle >= 67.5 and angle < 112.5 then
    direction = "down"
  elseif angle >= 112.5 and angle < 157.5 then
    direction = "down_left"
  elseif angle >= 157.5 or angle < -157.5 then
    direction = "left"
  elseif angle >= -157.5 and angle < -112.5 then
    direction = "up_left"
  elseif angle >= -112.5 and angle < -67.5 then
    direction = "up"
  else
    direction = "up_right"
  end
  return {
    type = "swipe",
    direction = direction,
    x = endX,
    y = endY,
    distance = distance,
    angle = angle,
    duration = duration
  }
end
-- Trigger gesture event
function GestureRecognition.triggerGesture(gestureType, data)
  if not GestureDefinitions.isGestureEnabled(gestureType, data.direction) then
    return
  end
  local gesture = {
    type = gestureType,
    data = data,
    time = love.timer.getTime(),
    duration = 0,
    priority = GestureDefinitions.getGesturePriority(gestureType, data.direction)
  }
  table.insert(GestureRecognition.touchState.gestures, gesture)
  -- Emit gesture event
  if Utils.EventEmitter then
    Utils.EventEmitter.emit("gesture_detected", gesture)
  end
  Utils.Logger.debug("Gesture detected: %s", gestureType)
end
-- Get active gestures
function GestureRecognition.getActiveGestures()
  return GestureRecognition.touchState.gestures
end
-- Get touch count
function GestureRecognition.getTouchCount()
  return #GestureRecognition.touchState.touches
end
-- Get pullback data
function GestureRecognition.getPullbackData()
  local state = GestureRecognition.touchState
  if state.pullbackActive then
    return {
      active = true,
      strength = state.pullbackStrength,
      angle = state.pullbackAngle,
      startX = state.pullbackStart.x,
      startY = state.pullbackStart.y
    }
  end
  return {active = false}
end
-- Clear all gestures
function GestureRecognition.clearGestures()
  GestureRecognition.touchState.gestures = {}
end
return GestureRecognition