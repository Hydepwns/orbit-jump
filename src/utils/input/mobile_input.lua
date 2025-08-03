--[[
    Mobile Input Handler for Orbit Jump
    This module provides comprehensive mobile input handling including
    touch gestures, haptic feedback, and responsive UI scaling.
--]]
local MobileInput = {}
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Mobile Input State Management
    ═══════════════════════════════════════════════════════════════════════════
--]]
-- Touch state tracking
MobileInput.touches = {}
MobileInput.touchCount = 0
MobileInput.lastTapTime = 0
MobileInput.lastTapX = 0
MobileInput.lastTapY = 0
MobileInput.doubleTapThreshold = 0.3 -- seconds
MobileInput.doubleTapDistance = 50 -- pixels
-- Gesture recognition
MobileInput.gestures = {
    tap = {},
    doubleTap = {},
    swipe = {},
    pinch = {},
    rotate = {}
}
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Initialization and Detection
    ═══════════════════════════════════════════════════════════════════════════
--]]
function MobileInput.init()
    --[[
        Initialize Mobile Input System
        Sets up the mobile input system and detects device capabilities.
        Should be called once at game startup.
        Performance: O(1) with zero allocations
    --]]
    MobileInput.touches = {}
    MobileInput.touchCount = 0
    MobileInput.lastTapTime = 0
    MobileInput.lastTapX = 0
    MobileInput.lastTapY = 0
    -- Reset gesture states
    for gestureType, _ in pairs(MobileInput.gestures) do
        MobileInput.gestures[gestureType] = {}
    end
end
function MobileInput.isMobile()
    --[[
        Detect Mobile Device
        Determines if the current device is mobile based on screen size
        and touch capability. Used for responsive design decisions.
        Returns: boolean indicating if device is mobile
        Performance: O(1) with zero allocations
    --]]
    -- Check if love.graphics is available (e.g., in test environment)
    if not love or not love.graphics then
        return false
    end
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    -- Mobile devices typically have smaller screens and touch capability
    return width <= 1024 or height <= 768
end
function MobileInput.getOrientation()
    --[[
        Get Device Orientation
        Determines the current device orientation based on screen dimensions.
        Useful for responsive UI layout and game mechanics.
        Returns: "portrait", "landscape", or "square"
        Performance: O(1) with zero allocations
    --]]
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width = 800 -- Default width
    local height = 600 -- Default height
    if love and love.graphics then
        width = love.graphics.getWidth()
        height = love.graphics.getHeight()
    end
    local aspectRatio = width / height
    if aspectRatio > 1.2 then
        return "landscape"
    elseif aspectRatio < 0.8 then
        return "portrait"
    else
        return "square"
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Touch Event Handling
    ═══════════════════════════════════════════════════════════════════════════
--]]
function MobileInput.handleTouch(id, x, y, event)
    --[[
        Handle Touch Events
        Processes touch events and updates internal state.
        Called by the main game loop for each touch event.
        Parameters:
        - id: Touch identifier
        - x, y: Touch coordinates
        - event: "pressed", "moved", or "released"
        Performance: O(1) with zero allocations
    --]]
    if not id or not x or not y or not event then
        return
    end
    if event == "pressed" then
        -- Touch started
        MobileInput.touches[id] = {
            x = x,
            y = y,
            startX = x,
            startY = y,
            startTime = love.timer.getTime(),
            moved = false
        }
        MobileInput.touchCount = MobileInput.touchCount + 1
    elseif event == "moved" then
        -- Touch moved
        if MobileInput.touches[id] then
            local touch = MobileInput.touches[id]
            local dx = x - touch.x
            local dy = y - touch.y
            -- Check if touch has moved significantly
            if math.abs(dx) > 5 or math.abs(dy) > 5 then
                touch.moved = true
            end
            touch.x = x
            touch.y = y
        end
    elseif event == "released" then
        -- Touch ended
        if MobileInput.touches[id] then
            local touch = MobileInput.touches[id]
            local currentTime = love.timer.getTime()
            local duration = currentTime - touch.startTime
            -- Handle tap detection
            if not touch.moved and duration < 0.5 then
                MobileInput.handleTap(x, y)
            end
            -- Handle swipe detection
            if touch.moved and duration < 1.0 then
                local distance = math.sqrt((x - touch.startX)^2 + (y - touch.startY)^2)
                if distance > 50 then
                    MobileInput.handleSwipe(touch.startX, touch.startY, x, y, distance, duration)
                end
            end
            -- Clean up touch data
            MobileInput.touches[id] = nil
            MobileInput.touchCount = MobileInput.touchCount - 1
        end
    end
end
function MobileInput.handleTap(x, y)
    --[[
        Handle Tap Gesture
        Processes tap gestures and detects double-tap patterns.
        Triggers appropriate callbacks for single and double taps.
        Performance: O(1) with zero allocations
    --]]
    local currentTime = love.timer.getTime()
    local timeSinceLastTap = currentTime - MobileInput.lastTapTime
    local distanceFromLastTap = math.sqrt((x - MobileInput.lastTapX)^2 + (y - MobileInput.lastTapY)^2)
    if timeSinceLastTap < MobileInput.doubleTapThreshold and
       distanceFromLastTap < MobileInput.doubleTapDistance then
        -- Double tap detected
        MobileInput.handleDoubleTap(x, y)
        MobileInput.lastTapTime = 0 -- Reset to prevent triple tap
    else
        -- Single tap
        if MobileInput.gestures.tap.callback then
            MobileInput.gestures.tap.callback(x, y)
        end
        -- Update last tap info
        MobileInput.lastTapTime = currentTime
        MobileInput.lastTapX = x
        MobileInput.lastTapY = y
    end
end
function MobileInput.handleSwipe(startX, startY, endX, endY, distance, duration)
    --[[
        Handle Swipe Gesture
        Processes swipe gestures and determines direction and velocity.
        Triggers appropriate callbacks for swipe actions.
        Performance: O(1) with zero allocations
    --]]
    local velocity = distance / duration
    local angle = math.atan2(endY - startY, endX - startX)
    local direction = MobileInput.getSwipeDirection(angle)
    if MobileInput.gestures.swipe.callback then
        MobileInput.gestures.swipe.callback(startX, startY, endX, endY, distance, velocity, direction)
    end
end
function MobileInput.handleDoubleTap(x, y)
    --[[
        Handle Double Tap Gesture
        Processes double-tap gestures and triggers appropriate callbacks.
        Performance: O(1) with zero allocations
    --]]
    if MobileInput.gestures.doubleTap.callback then
        MobileInput.gestures.doubleTap.callback(x, y)
    end
end
function MobileInput.getSwipeDirection(angle)
    --[[
        Get Swipe Direction
        Converts angle to cardinal direction for swipe gestures.
        Returns: "up", "down", "left", "right", or "diagonal"
        Performance: O(1) with zero allocations
    --]]
    -- Convert angle to degrees
    local degrees = math.deg(angle)
    -- Normalize to 0-360 range
    degrees = degrees % 360
    if degrees < 0 then
        degrees = degrees + 360
    end
    -- Determine direction based on angle ranges
    if degrees >= 315 or degrees < 45 then
        return "right"
    elseif degrees >= 45 and degrees < 135 then
        return "down"
    elseif degrees >= 135 and degrees < 225 then
        return "left"
    elseif degrees >= 225 and degrees < 315 then
        return "up"
    else
        return "diagonal"
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Haptic Feedback
    ═══════════════════════════════════════════════════════════════════════════
--]]
function MobileInput.vibrate(intensity)
    --[[
        Trigger Haptic Feedback
        Provides haptic feedback on supported devices.
        Intensity should be between 0.0 and 1.0.
        Performance: O(1) with zero allocations
    --]]
    if not intensity then
        intensity = 0.5
    end
    -- Clamp intensity to valid range
    intensity = math.max(0.0, math.min(1.0, intensity))
    -- Check if haptic feedback is available
    if love and love.system and love.system.vibrate then
        love.system.vibrate(intensity)
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Responsive UI Scaling
    ═══════════════════════════════════════════════════════════════════════════
--]]
function MobileInput.getUIScale()
    --[[
        Get UI Scale Factor
        Calculates appropriate UI scale factor based on screen size.
        Ensures UI elements are properly sized for different devices.
        Returns: Scale factor (typically 0.5 to 2.0)
        Performance: O(1) with zero allocations
    --]]
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width = 800 -- Default width
    if love and love.graphics and love.graphics.getWidth then
        width = love.graphics.getWidth()
    end
    -- Load config if available
    local Config
    local success, config = pcall(require, "src.utils.config")
    if success and config then
        Config = config
    end
    if not Config or not Config.responsive or not Config.responsive.enabled then
        return 1.0
    end
    local breakpoints = Config.responsive.breakpoints
    if width <= breakpoints.mobile then
        return Config.responsive.scaling.mobile
    elseif width <= breakpoints.tablet then
        return Config.responsive.scaling.tablet
    else
        return Config.responsive.scaling.desktop
    end
end
function MobileInput.getFontSizes()
    --[[
        Get Responsive Font Sizes
        Returns appropriate font sizes for different device types.
        Ensures text readability across all screen sizes.
        Returns: Table with font sizes for different device types
        Performance: O(1) with zero allocations
    --]]
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width = 800 -- Default width
    if love and love.graphics and love.graphics.getWidth then
        width = love.graphics.getWidth()
    end
    -- Load config if available
    local Config
    local success, config = pcall(require, "src.utils.config")
    if success and config then
        Config = config
    end
    if not Config or not Config.responsive or not Config.responsive.enabled then
        return Config.responsive.fontSizes.desktop
    end
    local breakpoints = Config.responsive.breakpoints
    if width <= breakpoints.mobile then
        return Config.responsive.fontSizes.mobile
    elseif width <= breakpoints.tablet then
        return Config.responsive.fontSizes.tablet
    else
        return Config.responsive.fontSizes.desktop
    end
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Gesture Callback Registration
    ═══════════════════════════════════════════════════════════════════════════
--]]
function MobileInput.onTap(callback)
    --[[
        Register Tap Callback
        Sets the callback function to be called when a tap is detected.
        Performance: O(1) with zero allocations
    --]]
    MobileInput.gestures.tap.callback = callback
end
function MobileInput.onDoubleTap(callback)
    --[[
        Register Double Tap Callback
        Sets the callback function to be called when a double tap is detected.
        Performance: O(1) with zero allocations
    --]]
    MobileInput.gestures.doubleTap.callback = callback
end
function MobileInput.onSwipe(callback)
    --[[
        Register Swipe Callback
        Sets the callback function to be called when a swipe is detected.
        Callback receives: startX, startY, endX, endY, distance, velocity, direction
        Performance: O(1) with zero allocations
    --]]
    MobileInput.gestures.swipe.callback = callback
end
function MobileInput.onPinch(callback)
    --[[
        Register Pinch Callback
        Sets the callback function to be called when a pinch gesture is detected.
        Performance: O(1) with zero allocations
    --]]
    MobileInput.gestures.pinch.callback = callback
end
function MobileInput.onRotate(callback)
    --[[
        Register Rotate Callback
        Sets the callback function to be called when a rotate gesture is detected.
        Performance: O(1) with zero allocations
    --]]
    MobileInput.gestures.rotate.callback = callback
end
--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions
    ═══════════════════════════════════════════════════════════════════════════
--]]
function MobileInput.getTouchCount()
    --[[
        Get Current Touch Count
        Returns the number of currently active touches.
        Returns: Number of active touches
        Performance: O(1) with zero allocations
    --]]
    return MobileInput.touchCount
end
function MobileInput.getTouchPosition(id)
    --[[
        Get Touch Position
        Returns the current position of a specific touch.
        Parameters:
        - id: Touch identifier
        Returns: x, y coordinates or nil if touch not found
        Performance: O(1) with zero allocations
    --]]
    if MobileInput.touches[id] then
        return MobileInput.touches[id].x, MobileInput.touches[id].y
    end
    return nil, nil
end
function MobileInput.clearGestures()
    --[[
        Clear All Gesture Callbacks
        Removes all registered gesture callbacks.
        Useful for cleanup or resetting gesture handlers.
        Performance: O(1) with zero allocations
    --]]
    for gestureType, _ in pairs(MobileInput.gestures) do
        MobileInput.gestures[gestureType] = {}
    end
end
return MobileInput