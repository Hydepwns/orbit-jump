-- Touch Gesture System Coordinator
-- Main touch gesture system that coordinates all touch gesture modules

local Utils = require("src.utils.utils")
local GestureDefinitions = require("src.systems.touch.gesture_definitions")
local GestureRecognition = require("src.systems.touch.gesture_recognition")
local GestureUI = require("src.systems.touch.gesture_ui")

local TouchGestureSystem = {}

-- System state
TouchGestureSystem.isInitialized = false
TouchGestureSystem.isEnabled = true
TouchGestureSystem.debugMode = false

-- Initialize touch gesture system
function TouchGestureSystem.init()
  if TouchGestureSystem.isInitialized then
    return true
  end
  
  -- Initialize all modules
  GestureDefinitions = GestureDefinitions or require("src.systems.touch.gesture_definitions")
  GestureRecognition = GestureRecognition or require("src.systems.touch.gesture_recognition")
  GestureUI = GestureUI or require("src.systems.touch.gesture_ui")
  
  GestureRecognition.init()
  GestureUI.init()
  
  TouchGestureSystem.isInitialized = true
  Utils.Logger.info("Touch gesture system initialized successfully")
  
  return true
end

-- Update touch gesture system
function TouchGestureSystem.update(dt)
  if not TouchGestureSystem.isInitialized or not TouchGestureSystem.isEnabled then
    return
  end
  
  GestureRecognition.update(dt)
  GestureUI.update(dt)
end

-- Draw touch gesture system
function TouchGestureSystem.draw()
  if not TouchGestureSystem.isInitialized or not TouchGestureSystem.isEnabled then
    return
  end
  
  GestureUI.draw()
  
  -- Draw debug info if enabled
  if TouchGestureSystem.debugMode then
    GestureUI.drawDebugInfo(10, 10)
  end
end

-- Handle touch input
function TouchGestureSystem.touchpressed(id, x, y, pressure)
  if not TouchGestureSystem.isInitialized or not TouchGestureSystem.isEnabled then
    return false
  end
  
  GestureRecognition.touchpressed(id, x, y, pressure)
  return true
end

function TouchGestureSystem.touchmoved(id, x, y, pressure)
  if not TouchGestureSystem.isInitialized or not TouchGestureSystem.isEnabled then
    return false
  end
  
  GestureRecognition.touchmoved(id, x, y, pressure)
  return true
end

function TouchGestureSystem.touchreleased(id, x, y)
  if not TouchGestureSystem.isInitialized or not TouchGestureSystem.isEnabled then
    return false
  end
  
  GestureRecognition.touchreleased(id, x, y)
  return true
end

-- Public API for other systems

-- Enable/disable gesture system
function TouchGestureSystem.setEnabled(enabled)
  if not TouchGestureSystem.isInitialized then
    return false
  end
  
  TouchGestureSystem.isEnabled = enabled
  
  if not enabled then
    GestureRecognition.resetState()
    GestureUI.clearEffects()
  end
  
  Utils.Logger.info("Touch gesture system %s", enabled and "enabled" or "disabled")
  return true
end

-- Check if system is enabled
function TouchGestureSystem.isEnabled()
  return TouchGestureSystem.isInitialized and TouchGestureSystem.isEnabled
end

-- Enable/disable specific gesture
function TouchGestureSystem.setGestureEnabled(gestureType, direction, enabled)
  if not TouchGestureSystem.isInitialized then
    return false
  end
  
  return GestureDefinitions.setGestureEnabled(gestureType, direction, enabled)
end

-- Check if gesture is enabled
function TouchGestureSystem.isGestureEnabled(gestureType, direction)
  if not TouchGestureSystem.isInitialized then
    return false
  end
  
  return GestureDefinitions.isGestureEnabled(gestureType, direction)
end

-- Get active gestures
function TouchGestureSystem.getActiveGestures()
  if not TouchGestureSystem.isInitialized then
    return {}
  end
  
  return GestureRecognition.getActiveGestures()
end

-- Get touch count
function TouchGestureSystem.getTouchCount()
  if not TouchGestureSystem.isInitialized then
    return 0
  end
  
  return GestureRecognition.getTouchCount()
end

-- Get pullback data
function TouchGestureSystem.getPullbackData()
  if not TouchGestureSystem.isInitialized then
    return {active = false}
  end
  
  return GestureRecognition.getPullbackData()
end

-- Get gesture configuration
function TouchGestureSystem.getGestureConfig(gestureType, direction)
  if not TouchGestureSystem.isInitialized then
    return nil
  end
  
  return GestureDefinitions.getGestureConfig(gestureType, direction)
end

-- Set gesture priority
function TouchGestureSystem.setGesturePriority(gestureType, direction, priority)
  if not TouchGestureSystem.isInitialized then
    return false
  end
  
  return GestureDefinitions.setGesturePriority(gestureType, direction, priority)
end

-- Get gesture priority
function TouchGestureSystem.getGesturePriority(gestureType, direction)
  if not TouchGestureSystem.isInitialized then
    return 1
  end
  
  return GestureDefinitions.getGesturePriority(gestureType, direction)
end

-- Set haptic intensity for gesture
function TouchGestureSystem.setHapticIntensity(gestureType, direction, intensity)
  if not TouchGestureSystem.isInitialized then
    return false
  end
  
  return GestureDefinitions.setHapticIntensity(gestureType, direction, intensity)
end

-- Get haptic intensity for gesture
function TouchGestureSystem.getHapticIntensity(gestureType, direction)
  if not TouchGestureSystem.isInitialized then
    return 0.3
  end
  
  return GestureDefinitions.getHapticIntensity(gestureType, direction)
end

-- Get all enabled gestures
function TouchGestureSystem.getEnabledGestures()
  if not TouchGestureSystem.isInitialized then
    return {}
  end
  
  return GestureDefinitions.getEnabledGestures()
end

-- Get gestures by type
function TouchGestureSystem.getGesturesByType(gestureType)
  if not TouchGestureSystem.isInitialized then
    return {}
  end
  
  return GestureDefinitions.getGesturesByType(gestureType)
end

-- Get gestures by priority
function TouchGestureSystem.getGesturesByPriority(priority)
  if not TouchGestureSystem.isInitialized then
    return {}
  end
  
  return GestureDefinitions.getGesturesByPriority(priority)
end

-- UI Functions

-- Set pullback indicator visibility
function TouchGestureSystem.setPullbackIndicatorVisible(visible)
  if not TouchGestureSystem.isInitialized then
    return
  end
  
  GestureUI.setPullbackIndicatorVisible(visible)
end

-- Add gesture feedback
function TouchGestureSystem.addGestureFeedback(gestureType, x, y, data)
  if not TouchGestureSystem.isInitialized then
    return
  end
  
  GestureUI.addGestureFeedback(gestureType, x, y, data)
end

-- Clear all visual effects
function TouchGestureSystem.clearVisualEffects()
  if not TouchGestureSystem.isInitialized then
    return
  end
  
  GestureUI.clearEffects()
end

-- Get visual effects state
function TouchGestureSystem.getVisualEffectsState()
  if not TouchGestureSystem.isInitialized then
    return {}
  end
  
  return GestureUI.getVisualEffectsState()
end

-- Debug Functions

-- Enable/disable debug mode
function TouchGestureSystem.setDebugMode(enabled)
  if not TouchGestureSystem.isInitialized then
    return false
  end
  
  TouchGestureSystem.debugMode = enabled
  Utils.Logger.info("Touch gesture debug mode %s", enabled and "enabled" or "disabled")
  return true
end

-- Check if debug mode is enabled
function TouchGestureSystem.isDebugMode()
  return TouchGestureSystem.debugMode
end

-- Clear all gestures
function TouchGestureSystem.clearGestures()
  if not TouchGestureSystem.isInitialized then
    return
  end
  
  GestureRecognition.clearGestures()
  GestureUI.clearEffects()
end

-- Reset system state
function TouchGestureSystem.reset()
  if not TouchGestureSystem.isInitialized then
    return
  end
  
  GestureRecognition.resetState()
  GestureUI.clearEffects()
  Utils.Logger.info("Touch gesture system reset")
end

-- Debug functions
function TouchGestureSystem.debug()
  if not TouchGestureSystem.isInitialized then
    print("Touch gesture system not initialized")
    return
  end
  
  print("=== Touch Gesture System Debug ===")
  print("Initialized:", TouchGestureSystem.isInitialized)
  print("Enabled:", TouchGestureSystem.isEnabled)
  print("Debug Mode:", TouchGestureSystem.debugMode)
  
  local touchCount = TouchGestureSystem.getTouchCount()
  print("Touch Count:", touchCount)
  
  local activeGestures = TouchGestureSystem.getActiveGestures()
  print("Active Gestures:", #activeGestures)
  
  local pullbackData = TouchGestureSystem.getPullbackData()
  print("Pullback Active:", pullbackData.active)
  if pullbackData.active then
    print("  Strength:", pullbackData.strength)
    print("  Angle:", math.deg(pullbackData.angle))
  end
  
  local enabledGestures = TouchGestureSystem.getEnabledGestures()
  print("Enabled Gestures:", #enabledGestures)
  for _, gesture in ipairs(enabledGestures) do
    print(string.format("  %s (priority: %d)", gesture.name, gesture.config.priority))
  end
  
  print("\n=== Recent Gestures ===")
  for i, gesture in ipairs(activeGestures) do
    if i <= 10 then
      print(string.format("  %d. [%s] %s at (%.1f, %.1f)", 
                         i, gesture.type, gesture.data.direction or "", 
                         gesture.data.x or 0, gesture.data.y or 0))
    end
  end
end

-- Test functions for development
function TouchGestureSystem.testGesture(gestureType, x, y, data)
  if not TouchGestureSystem.isInitialized then
    print("Touch gesture system not initialized")
    return
  end
  
  TouchGestureSystem.addGestureFeedback(gestureType, x or 100, y or 100, data or {})
  print(string.format("Test gesture triggered: %s", gestureType))
end

function TouchGestureSystem.testPullback(x, y, strength, angle)
  if not TouchGestureSystem.isInitialized then
    print("Touch gesture system not initialized")
    return
  end
  
  -- Simulate pullback data
  local pullbackData = {
    active = true,
    strength = strength or 50,
    angle = angle or 0,
    startX = x or 100,
    startY = y or 100
  }
  
  print(string.format("Test pullback: strength=%.1f, angle=%.1f°", strength or 50, math.deg(angle or 0)))
end

return TouchGestureSystem 