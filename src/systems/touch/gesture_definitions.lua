-- Gesture Definitions Module
-- Contains all gesture-related constants and configurations
local GestureDefinitions = {}
-- Gesture recognition constants
GestureDefinitions.constants = {
  -- Timing thresholds
  TAP_DURATION = 0.3,           -- Maximum time for a tap
  LONG_PRESS_DURATION = 0.8,    -- Time to trigger long press
  DOUBLE_TAP_DELAY = 0.5,       -- Time between taps for double tap
  GESTURE_TIMEOUT = 2.0,        -- Maximum time for gesture completion
  -- Distance thresholds
  MIN_SWIPE_DISTANCE = 50,      -- Minimum distance for swipe
  MAX_TAP_DISTANCE = 20,        -- Maximum movement for tap
  PINCH_MIN_DISTANCE = 30,      -- Minimum distance for pinch detection
  -- Sensitivity settings
  ZOOM_SENSITIVITY = 0.01,      -- Pinch-to-zoom sensitivity
  SWIPE_SENSITIVITY = 1.0,      -- Swipe sensitivity multiplier
  PULLBACK_SENSITIVITY = 1.5,   -- Pullback control sensitivity
  -- Haptic feedback
  HAPTIC_LIGHT = 0.3,           -- Light haptic intensity
  HAPTIC_MEDIUM = 0.6,          -- Medium haptic intensity
  HAPTIC_HEAVY = 0.9            -- Heavy haptic intensity
}
-- Gesture types
GestureDefinitions.gestureTypes = {
  TAP = "tap",
  DOUBLE_TAP = "double_tap",
  LONG_PRESS = "long_press",
  SWIPE = "swipe",
  PINCH = "pinch",
  PULLBACK = "pullback",
  ROTATE = "rotate"
}
-- Swipe directions
GestureDefinitions.swipeDirections = {
  UP = "up",
  DOWN = "down",
  LEFT = "left",
  RIGHT = "right",
  UP_LEFT = "up_left",
  UP_RIGHT = "up_right",
  DOWN_LEFT = "down_left",
  DOWN_RIGHT = "down_right"
}
-- Gesture priorities
GestureDefinitions.priorities = {
  HIGH = 3,
  MEDIUM = 2,
  LOW = 1
}
-- Gesture configurations
GestureDefinitions.gestures = {
  -- Basic gestures
  tap = {
    type = "tap",
    priority = 1,
    haptic = "light",
    enabled = true
  },
  double_tap = {
    type = "double_tap",
    priority = 2,
    haptic = "medium",
    enabled = true
  },
  long_press = {
    type = "long_press",
    priority = 2,
    haptic = "medium",
    enabled = true
  },
  -- Navigation gestures
  swipe_up = {
    type = "swipe",
    direction = "up",
    priority = 2,
    haptic = "light",
    enabled = true
  },
  swipe_down = {
    type = "swipe",
    direction = "down",
    priority = 2,
    haptic = "light",
    enabled = true
  },
  swipe_left = {
    type = "swipe",
    direction = "left",
    priority = 2,
    haptic = "light",
    enabled = true
  },
  swipe_right = {
    type = "swipe",
    direction = "right",
    priority = 2,
    haptic = "light",
    enabled = true
  },
  -- Game-specific gestures
  pullback = {
    type = "pullback",
    priority = 3,
    haptic = "medium",
    enabled = true
  },
  pinch_zoom = {
    type = "pinch",
    priority = 2,
    haptic = "light",
    enabled = true
  },
  rotate = {
    type = "rotate",
    priority = 1,
    haptic = "light",
    enabled = true
  }
}
-- Get gesture configuration
function GestureDefinitions.getGestureConfig(gestureType, direction)
  if direction then
    return GestureDefinitions.gestures[gestureType .. "_" .. direction]
  else
    return GestureDefinitions.gestures[gestureType]
  end
end
-- Check if gesture is enabled
function GestureDefinitions.isGestureEnabled(gestureType, direction)
  local config = GestureDefinitions.getGestureConfig(gestureType, direction)
  return config and config.enabled
end
-- Get gesture priority
function GestureDefinitions.getGesturePriority(gestureType, direction)
  local config = GestureDefinitions.getGestureConfig(gestureType, direction)
  return config and config.priority or GestureDefinitions.priorities.LOW
end
-- Get haptic intensity for gesture
function GestureDefinitions.getHapticIntensity(gestureType, direction)
  local config = GestureDefinitions.getGestureConfig(gestureType, direction)
  if not config then
    return GestureDefinitions.constants.HAPTIC_LIGHT
  end
  if config.haptic == "light" then
    return GestureDefinitions.constants.HAPTIC_LIGHT
  elseif config.haptic == "medium" then
    return GestureDefinitions.constants.HAPTIC_MEDIUM
  elseif config.haptic == "heavy" then
    return GestureDefinitions.constants.HAPTIC_HEAVY
  else
    return GestureDefinitions.constants.HAPTIC_LIGHT
  end
end
-- Get all enabled gestures
function GestureDefinitions.getEnabledGestures()
  local enabled = {}
  for gestureName, config in pairs(GestureDefinitions.gestures) do
    if config.enabled then
      table.insert(enabled, {
        name = gestureName,
        config = config
      })
    end
  end
  return enabled
end
-- Get gestures by type
function GestureDefinitions.getGesturesByType(gestureType)
  local gestures = {}
  for gestureName, config in pairs(GestureDefinitions.gestures) do
    if config.type == gestureType then
      table.insert(gestures, {
        name = gestureName,
        config = config
      })
    end
  end
  return gestures
end
-- Get gestures by priority
function GestureDefinitions.getGesturesByPriority(priority)
  local gestures = {}
  for gestureName, config in pairs(GestureDefinitions.gestures) do
    if config.priority == priority then
      table.insert(gestures, {
        name = gestureName,
        config = config
      })
    end
  end
  return gestures
end
-- Enable/disable gesture
function GestureDefinitions.setGestureEnabled(gestureType, direction, enabled)
  local config = GestureDefinitions.getGestureConfig(gestureType, direction)
  if config then
    config.enabled = enabled
    return true
  end
  return false
end
-- Set gesture priority
function GestureDefinitions.setGesturePriority(gestureType, direction, priority)
  local config = GestureDefinitions.getGestureConfig(gestureType, direction)
  if config and GestureDefinitions.priorities[priority] then
    config.priority = GestureDefinitions.priorities[priority]
    return true
  end
  return false
end
-- Set haptic intensity for gesture
function GestureDefinitions.setHapticIntensity(gestureType, direction, intensity)
  local config = GestureDefinitions.getGestureConfig(gestureType, direction)
  if config then
    config.haptic = intensity
    return true
  end
  return false
end
-- Get all gesture types
function GestureDefinitions.getAllGestureTypes()
  return GestureDefinitions.gestureTypes
end
-- Get all swipe directions
function GestureDefinitions.getAllSwipeDirections()
  return GestureDefinitions.swipeDirections
end
-- Get all priorities
function GestureDefinitions.getAllPriorities()
  return GestureDefinitions.priorities
end
return GestureDefinitions