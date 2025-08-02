--[[
    ═══════════════════════════════════════════════════════════════════════════
    Touch Gesture System: The Language of Touch
    ═══════════════════════════════════════════════════════════════════════════
    
    This system transforms raw touch input into meaningful gestures that enhance
    the mobile gaming experience. It recognizes complex multi-touch patterns,
    provides haptic feedback, and integrates seamlessly with existing game systems.
    
    Gesture Philosophy:
    • Intuitive: Gestures feel natural and responsive
    • Accessible: Multiple ways to perform the same action
    • Adaptive: Sensitivity adjusts to user preferences
    • Feedback: Rich haptic and visual feedback for all interactions
    
    Supported Gestures:
    • Pinch-to-zoom: Two-finger pinch for camera zoom
    • Swipe navigation: Directional swipes for movement
    • Pullback control: Touch-based pullback for jumps
    • Double-tap: Quick actions and shortcuts
    • Long press: Context menus and options
--]]

local Utils = require("src.utils.utils")
local Config = require("src.utils.config")
local TouchGestureSystem = {}

-- Gesture recognition constants
TouchGestureSystem.constants = {
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

-- Touch state management
TouchGestureSystem.touchState = {
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

-- Gesture types
TouchGestureSystem.gestureTypes = {
    TAP = "tap",
    DOUBLE_TAP = "double_tap",
    LONG_PRESS = "long_press",
    SWIPE = "swipe",
    PINCH = "pinch",
    PULLBACK = "pullback",
    ROTATE = "rotate"
}

-- Initialize touch gesture system
function TouchGestureSystem.init()
    TouchGestureSystem.resetState()
    TouchGestureSystem.loadSettings()
    
    Utils.Logger.info("Touch gesture system initialized")
end

-- Reset touch state
function TouchGestureSystem.resetState()
    TouchGestureSystem.touchState = {
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

-- Load user settings
function TouchGestureSystem.loadSettings()
    -- Load from save system if available
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.loadTouchSettings then
        local settings = SaveSystem.loadTouchSettings()
        if settings then
            TouchGestureSystem.constants.ZOOM_SENSITIVITY = settings.zoomSensitivity or TouchGestureSystem.constants.ZOOM_SENSITIVITY
            TouchGestureSystem.constants.SWIPE_SENSITIVITY = settings.swipeSensitivity or TouchGestureSystem.constants.SWIPE_SENSITIVITY
            TouchGestureSystem.constants.PULLBACK_SENSITIVITY = settings.pullbackSensitivity or TouchGestureSystem.constants.PULLBACK_SENSITIVITY
        end
    end
end

-- Handle LÖVE touch events
function TouchGestureSystem.handleTouchEvent(id, x, y, pressure, eventType)
    local currentTime = 0
    if love and love.timer and love.timer.getTime then
        currentTime = love.timer.getTime()
    end
    
    if eventType == "pressed" then
        TouchGestureSystem.handleTouchPressed(id, x, y, pressure, currentTime)
    elseif eventType == "moved" then
        TouchGestureSystem.handleTouchMoved(id, x, y, pressure, currentTime)
    elseif eventType == "released" then
        TouchGestureSystem.handleTouchReleased(id, x, y, pressure, currentTime)
    end
end

-- Handle touch press
function TouchGestureSystem.handleTouchPressed(id, x, y, pressure, time)
    local touchState = TouchGestureSystem.touchState
    
    -- Record new touch
    touchState.touches[id] = {
        x = x,
        y = y,
        startX = x,
        startY = y,
        startTime = time,
        pressure = pressure,
        moved = false,
        distance = 0
    }
    
    -- Start long press timer
    touchState.longPressTimer = time
    touchState.longPressPosition = {x = x, y = y}
    
    -- Check for multi-touch gestures
    local touchCount = TouchGestureSystem.getTouchCount()
    if touchCount == 2 then
        TouchGestureSystem.startPinchGesture(time)
    elseif touchCount == 1 then
        TouchGestureSystem.startPullbackGesture(x, y, time)
    end
    
    -- Trigger haptic feedback
    TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_LIGHT)
end

-- Handle touch movement
function TouchGestureSystem.handleTouchMoved(id, x, y, pressure, time)
    local touchState = TouchGestureSystem.touchState
    local touch = touchState.touches[id]
    
    if not touch then return end
    
    -- Update touch position
    local dx = x - touch.startX
    local dy = y - touch.startY
    local distance = Utils.vectorLength(dx, dy)
    
    touch.x = x
    touch.y = y
    touch.distance = distance
    touch.pressure = pressure
    
    -- Mark as moved if distance exceeds threshold
    if distance > TouchGestureSystem.constants.MAX_TAP_DISTANCE then
        touch.moved = true
        touchState.longPressTimer = 0 -- Cancel long press
    end
    
    -- Handle multi-touch gestures
    local touchCount = TouchGestureSystem.getTouchCount()
    if touchCount == 2 then
        TouchGestureSystem.updatePinchGesture(time)
    elseif touchCount == 1 and touchState.pullbackActive then
        TouchGestureSystem.updatePullbackGesture(x, y, time)
    end
end

-- Handle touch release
function TouchGestureSystem.handleTouchReleased(id, x, y, pressure, time)
    local touchState = TouchGestureSystem.touchState
    local touch = touchState.touches[id]
    
    if not touch then return end
    
    local duration = time - touch.startTime
    local distance = touch.distance
    
    -- Determine gesture type
    if distance < TouchGestureSystem.constants.MAX_TAP_DISTANCE and duration < TouchGestureSystem.constants.TAP_DURATION then
        -- Single tap
        TouchGestureSystem.handleTap(x, y, time)
    elseif distance > TouchGestureSystem.constants.MIN_SWIPE_DISTANCE then
        -- Swipe gesture
        TouchGestureSystem.handleSwipe(touch.startX, touch.startY, x, y, distance, duration)
    elseif duration > TouchGestureSystem.constants.LONG_PRESS_DURATION then
        -- Long press
        TouchGestureSystem.handleLongPress(x, y, time)
    end
    
    -- End pullback if active
    if touchState.pullbackActive then
        TouchGestureSystem.endPullbackGesture(x, y, time)
    end
    
    -- Remove touch
    touchState.touches[id] = nil
    
    -- Check for pinch end
    if TouchGestureSystem.getTouchCount() < 2 then
        TouchGestureSystem.endPinchGesture(time)
    end
end

-- Handle tap gesture
function TouchGestureSystem.handleTap(x, y, time)
    local touchState = TouchGestureSystem.touchState
    
    -- Check for double tap
    local timeSinceLastTap = time - touchState.lastTapTime
    local distanceFromLastTap = Utils.vectorLength(x - touchState.lastTapPosition.x, y - touchState.lastTapPosition.y)
    
    if timeSinceLastTap < TouchGestureSystem.constants.DOUBLE_TAP_DELAY and 
       distanceFromLastTap < TouchGestureSystem.constants.MAX_TAP_DISTANCE then
        -- Double tap detected
        TouchGestureSystem.handleDoubleTap(x, y, time)
    else
        -- Single tap
        TouchGestureSystem.executeTap(x, y)
    end
    
    -- Update last tap info
    touchState.lastTapTime = time
    touchState.lastTapPosition = {x = x, y = y}
    
    -- Trigger haptic feedback
    TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_MEDIUM)
end

-- Handle double tap
function TouchGestureSystem.handleDoubleTap(x, y, time)
    Utils.Logger.debug("Double tap detected at (%d, %d)", x, y)
    
    -- Double tap actions
    local GameState = Utils.require("src.core.game_state")
    if GameState and GameState.isPlayerInSpace then
        -- Double tap in space = dash
        TouchGestureSystem.executeDash()
    else
        -- Double tap on planet = quick jump
        TouchGestureSystem.executeQuickJump()
    end
    
    -- Trigger haptic feedback
    TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_HEAVY)
end

-- Handle swipe gesture
function TouchGestureSystem.handleSwipe(startX, startY, endX, endY, distance, duration)
    local dx = endX - startX
    local dy = endY - startY
    local angle = Utils.atan2(dy, dx) * 180 / math.pi
    
    Utils.Logger.debug("Swipe detected: distance=%.1f, angle=%.1f, duration=%.2f", distance, angle, duration)
    
    -- Determine swipe direction
    local direction = TouchGestureSystem.getSwipeDirection(angle)
    
    -- Execute swipe action
    TouchGestureSystem.executeSwipe(direction, distance, duration)
    
    -- Trigger haptic feedback
    TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_MEDIUM)
end

-- Handle long press
function TouchGestureSystem.handleLongPress(x, y, time)
    Utils.Logger.debug("Long press detected at (%d, %d)", x, y)
    
    -- Long press actions
    TouchGestureSystem.executeLongPress(x, y)
    
    -- Trigger haptic feedback
    TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_HEAVY)
end

-- Start pinch gesture
function TouchGestureSystem.startPinchGesture(time)
    local touchState = TouchGestureSystem.touchState
    local touches = TouchGestureSystem.getTouchPositions()
    
    if #touches >= 2 then
        local distance = Utils.vectorLength(touches[2].x - touches[1].x, touches[2].y - touches[1].y)
        touchState.pinchStartDistance = distance
        
        -- Get current zoom level
        local Camera = Utils.require("src.core.camera")
        if Camera and Camera.getZoom then
            local success, zoom = pcall(Camera.getZoom, Camera)
            if success then
                touchState.pinchStartZoom = zoom or 1.0
            else
                touchState.pinchStartZoom = 1.0
            end
        else
            touchState.pinchStartZoom = 1.0
        end
        
        Utils.Logger.debug("Pinch gesture started: distance=%.1f", distance)
    end
end

-- Update pinch gesture
function TouchGestureSystem.updatePinchGesture(time)
    local touchState = TouchGestureSystem.touchState
    local touches = TouchGestureSystem.getTouchPositions()
    
    if #touches >= 2 and touchState.pinchStartDistance > 0 then
        local currentDistance = Utils.vectorLength(touches[2].x - touches[1].x, touches[2].y - touches[1].y)
        local scale = currentDistance / touchState.pinchStartDistance
        local newZoom = touchState.pinchStartZoom * scale
        
        -- Apply zoom with sensitivity
        local zoomDelta = (newZoom - touchState.pinchStartZoom) * TouchGestureSystem.constants.ZOOM_SENSITIVITY
        local finalZoom = math.max(0.5, math.min(3.0, touchState.pinchStartZoom + zoomDelta))
        
        -- Update camera zoom
        local Camera = Utils.require("src.core.camera")
        if Camera and Camera.setZoom then
            local success = pcall(Camera.setZoom, Camera, finalZoom)
            if not success then
                Utils.Logger.warn("Failed to set camera zoom: %s", finalZoom)
            end
        end
        
        Utils.Logger.debug("Pinch zoom: scale=%.2f, zoom=%.2f", scale, finalZoom)
    end
end

-- End pinch gesture
function TouchGestureSystem.endPinchGesture(time)
    local touchState = TouchGestureSystem.touchState
    touchState.pinchStartDistance = 0
    touchState.pinchStartZoom = 1.0
    
    Utils.Logger.debug("Pinch gesture ended")
end

-- Start pullback gesture
function TouchGestureSystem.startPullbackGesture(x, y, time)
    local touchState = TouchGestureSystem.touchState
    touchState.pullbackStart = {x = x, y = y}
    touchState.pullbackActive = true
    touchState.pullbackStrength = 0
    touchState.pullbackAngle = 0
    
    Utils.Logger.debug("Pullback gesture started at (%d, %d)", x, y)
end

-- Update pullback gesture
function TouchGestureSystem.updatePullbackGesture(x, y, time)
    local touchState = TouchGestureSystem.touchState
    local dx = x - touchState.pullbackStart.x
    local dy = y - touchState.pullbackStart.y
    local distance = Utils.vectorLength(dx, dy)
    local angle = Utils.atan2(dy, dx) * 180 / math.pi
    
    -- Calculate pullback strength (0-1)
    local maxDistance = 200 -- Maximum pullback distance
    local strength = math.min(distance / maxDistance, 1.0) * TouchGestureSystem.constants.PULLBACK_SENSITIVITY
    
    touchState.pullbackStrength = strength
    touchState.pullbackAngle = angle
    
    -- Update pullback indicator
    local EnhancedPullbackIndicator = Utils.require("src.systems.enhanced_pullback_indicator")
    if EnhancedPullbackIndicator and EnhancedPullbackIndicator.updateTouchPullback then
        EnhancedPullbackIndicator.updateTouchPullback(strength, angle, x, y)
    end
    
    -- Trigger haptic feedback based on strength
    if strength > 0.5 then
        TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_HEAVY)
    elseif strength > 0.2 then
        TouchGestureSystem.triggerHaptic(TouchGestureSystem.constants.HAPTIC_MEDIUM)
    end
end

-- End pullback gesture
function TouchGestureSystem.endPullbackGesture(x, y, time)
    local touchState = TouchGestureSystem.touchState
    
    if touchState.pullbackActive and touchState.pullbackStrength > 0.1 then
        -- Execute jump with calculated strength and angle
        TouchGestureSystem.executeJump(touchState.pullbackStrength, touchState.pullbackAngle)
        
        Utils.Logger.debug("Pullback jump: strength=%.2f, angle=%.1f", 
            touchState.pullbackStrength, touchState.pullbackAngle)
    end
    
    -- Reset pullback state
    touchState.pullbackActive = false
    touchState.pullbackStrength = 0
    touchState.pullbackAngle = 0
    
    -- Clear pullback indicator
    local EnhancedPullbackIndicator = Utils.require("src.systems.enhanced_pullback_indicator")
    if EnhancedPullbackIndicator and EnhancedPullbackIndicator.clearTouchPullback then
        EnhancedPullbackIndicator.clearTouchPullback()
    end
end

-- Get number of active touches
function TouchGestureSystem.getTouchCount()
    local count = 0
    for _ in pairs(TouchGestureSystem.touchState.touches) do
        count = count + 1
    end
    return count
end

-- Get touch positions as array
function TouchGestureSystem.getTouchPositions()
    local positions = {}
    for id, touch in pairs(TouchGestureSystem.touchState.touches) do
        table.insert(positions, {x = touch.x, y = touch.y, id = id})
    end
    return positions
end

-- Get swipe direction from angle
function TouchGestureSystem.getSwipeDirection(angle)
    -- Normalize angle to 0-360
    angle = angle % 360
    if angle < 0 then angle = angle + 360 end
    
    -- Determine direction
    if angle >= 315 or angle < 45 then
        return "right"
    elseif angle >= 45 and angle < 135 then
        return "down"
    elseif angle >= 135 and angle < 225 then
        return "left"
    else
        return "up"
    end
end

-- Execute tap action
function TouchGestureSystem.executeTap(x, y)
    -- Convert touch to mouse click for compatibility
    if love and love.mousepressed then
        love.mousepressed(x, y, 1)
    end
end

-- Execute dash action
function TouchGestureSystem.executeDash()
    local PlayerSystem = Utils.require("src.systems.player_system")
    if PlayerSystem and PlayerSystem.dash then
        PlayerSystem.dash()
    end
end

-- Execute quick jump
function TouchGestureSystem.executeQuickJump()
    local PlayerSystem = Utils.require("src.systems.player_system")
    if PlayerSystem and PlayerSystem.quickJump then
        PlayerSystem.quickJump()
    end
end

-- Execute swipe action
function TouchGestureSystem.executeSwipe(direction, distance, duration)
    local PlayerSystem = Utils.require("src.systems.player_system")
    if PlayerSystem and PlayerSystem.handleSwipe then
        PlayerSystem.handleSwipe(direction, distance, duration)
    end
end

-- Execute long press action
function TouchGestureSystem.executeLongPress(x, y)
    -- Show context menu or options
    local UISystem = Utils.require("src.ui.ui_system")
    if UISystem and UISystem.showContextMenu then
        UISystem.showContextMenu(x, y)
    end
end

-- Execute jump with strength and angle
function TouchGestureSystem.executeJump(strength, angle)
    local PlayerSystem = Utils.require("src.systems.player_system")
    if PlayerSystem and PlayerSystem.jumpWithStrength then
        PlayerSystem.jumpWithStrength(strength, angle)
    end
end

-- Trigger haptic feedback
function TouchGestureSystem.triggerHaptic(intensity)
    if Config.mobile and Config.mobile.hapticFeedback then
        -- Platform-specific haptic feedback
        if love and love.system and love.system.vibrate then
            love.system.vibrate(intensity)
        end
        
        Utils.Logger.debug("Haptic feedback: intensity=%.2f", intensity)
    end
end

-- Update system (called each frame)
function TouchGestureSystem.update(dt)
    local touchState = TouchGestureSystem.touchState
    local currentTime = 0
    if love and love.timer and love.timer.getTime then
        currentTime = love.timer.getTime()
    end
    
    -- Handle long press timer
    if touchState.longPressTimer > 0 and 
       currentTime - touchState.longPressTimer > TouchGestureSystem.constants.LONG_PRESS_DURATION then
        TouchGestureSystem.handleLongPress(touchState.longPressPosition.x, touchState.longPressPosition.y, currentTime)
        touchState.longPressTimer = 0
    end
    
    -- Update active gestures
    TouchGestureSystem.updateActiveGestures(dt)
end

-- Update active gestures
function TouchGestureSystem.updateActiveGestures(dt)
    local touchState = TouchGestureSystem.touchState
    
    -- Update pullback visual feedback
    if touchState.pullbackActive then
        local EnhancedPullbackIndicator = Utils.require("src.systems.enhanced_pullback_indicator")
        if EnhancedPullbackIndicator and EnhancedPullbackIndicator.updateTouchPullback then
            local touch = next(touchState.touches)
            if touch then
                EnhancedPullbackIndicator.updateTouchPullback(
                    touchState.pullbackStrength, 
                    touchState.pullbackAngle, 
                    touch.x, 
                    touch.y
                )
            end
        end
    end
end

-- Draw debug information
function TouchGestureSystem.drawDebug()
    if not Config.debug or not Config.debug.showTouchGestures then
        return
    end
    
    -- Check if love.graphics is available
    if not love or not love.graphics then
        return
    end
    
    local touchState = TouchGestureSystem.touchState
    
    -- Draw touch points
    for id, touch in pairs(touchState.touches) do
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.circle("fill", touch.x, touch.y, 10)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("T" .. id, touch.x - 5, touch.y - 5)
    end
    
    -- Draw pullback indicator
    if touchState.pullbackActive then
        love.graphics.setColor(1, 0, 0, 0.6)
        love.graphics.line(touchState.pullbackStart.x, touchState.pullbackStart.y, 
                          touchState.touches[next(touchState.touches)].x, 
                          touchState.touches[next(touchState.touches)].y)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    -- Draw gesture info
    love.graphics.setColor(1, 1, 1, 1)
    local info = string.format("Touches: %d | Pullback: %.2f | Angle: %.1f", 
        TouchGestureSystem.getTouchCount(), 
        touchState.pullbackStrength, 
        touchState.pullbackAngle)
    love.graphics.print(info, 10, 10)
end

-- Get system status for debugging
function TouchGestureSystem.getStatus()
    return {
        touchCount = TouchGestureSystem.getTouchCount(),
        pullbackActive = TouchGestureSystem.touchState.pullbackActive,
        pullbackStrength = TouchGestureSystem.touchState.pullbackStrength,
        pullbackAngle = TouchGestureSystem.touchState.pullbackAngle,
        lastTapTime = TouchGestureSystem.touchState.lastTapTime,
        longPressTimer = TouchGestureSystem.touchState.longPressTimer
    }
end

return TouchGestureSystem 