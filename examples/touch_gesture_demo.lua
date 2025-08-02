-- Touch Gesture System Demo
-- Demonstrates the touch gesture features implemented for Orbit Jump

local Utils = require("src.utils.utils")
local TouchGestureSystem = require("src.systems.touch_gesture_system")
local Config = require("src.utils.config")

print("🎮 Touch Gesture System Demo")
print("============================")

-- Initialize the touch gesture system
print("1. Initializing touch gesture system...")
TouchGestureSystem.init()
print("   ✅ Touch gesture system initialized")

-- Show configuration
print("\n2. Configuration:")
print("   - Pinch-to-zoom: " .. (Config.mobile.gestures.pinchToZoom and "✅ Enabled" or "❌ Disabled"))
print("   - Swipe navigation: " .. (Config.mobile.gestures.swipeNavigation and "✅ Enabled" or "❌ Disabled"))
print("   - Pullback control: " .. (Config.mobile.gestures.pullbackControl and "✅ Enabled" or "❌ Disabled"))
print("   - Double-tap dash: " .. (Config.mobile.gestures.doubleTapDash and "✅ Enabled" or "❌ Disabled"))
print("   - Long press menu: " .. (Config.mobile.gestures.longPressMenu and "✅ Enabled" or "❌ Disabled"))

-- Demonstrate touch event handling
print("\n3. Simulating touch events...")

-- Simulate a tap
print("   📱 Simulating tap at (100, 200)...")
TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "pressed")
TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "released")

-- Simulate a swipe
print("   📱 Simulating swipe from (100, 200) to (300, 200)...")
TouchGestureSystem.handleTouchEvent(2, 100, 200, 1.0, "pressed")
TouchGestureSystem.handleTouchEvent(2, 200, 200, 1.0, "moved")
TouchGestureSystem.handleTouchEvent(2, 300, 200, 1.0, "released")

-- Simulate two-finger pinch
print("   📱 Simulating two-finger pinch...")
TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "pressed")
TouchGestureSystem.handleTouchEvent(2, 200, 200, 1.0, "pressed")
TouchGestureSystem.handleTouchEvent(1, 150, 200, 1.0, "moved")
TouchGestureSystem.handleTouchEvent(2, 250, 200, 1.0, "moved")
TouchGestureSystem.handleTouchEvent(1, 150, 200, 1.0, "released")
TouchGestureSystem.handleTouchEvent(2, 250, 200, 1.0, "released")

-- Show system status
print("\n4. System Status:")
local status = TouchGestureSystem.getStatus()
print("   - Active touches: " .. status.touchCount)
print("   - Pullback active: " .. (status.pullbackActive and "Yes" or "No"))
print("   - Pullback strength: " .. string.format("%.2f", status.pullbackStrength))
print("   - Pullback angle: " .. string.format("%.1f°", status.pullbackAngle))

-- Demonstrate gesture constants
print("\n5. Gesture Constants:")
print("   - Tap duration: " .. TouchGestureSystem.constants.TAP_DURATION .. "s")
print("   - Long press duration: " .. TouchGestureSystem.constants.LONG_PRESS_DURATION .. "s")
print("   - Double tap delay: " .. TouchGestureSystem.constants.DOUBLE_TAP_DELAY .. "s")
print("   - Min swipe distance: " .. TouchGestureSystem.constants.MIN_SWIPE_DISTANCE .. "px")
print("   - Max tap distance: " .. TouchGestureSystem.constants.MAX_TAP_DISTANCE .. "px")
print("   - Pinch min distance: " .. TouchGestureSystem.constants.PINCH_MIN_DISTANCE .. "px")

-- Show supported gesture types
print("\n6. Supported Gesture Types:")
for _, gestureType in ipairs({
    TouchGestureSystem.gestureTypes.TAP,
    TouchGestureSystem.gestureTypes.DOUBLE_TAP,
    TouchGestureSystem.gestureTypes.LONG_PRESS,
    TouchGestureSystem.gestureTypes.SWIPE,
    TouchGestureSystem.gestureTypes.PINCH,
    TouchGestureSystem.gestureTypes.PULLBACK,
    TouchGestureSystem.gestureTypes.ROTATE
}) do
    print("   - " .. gestureType)
end

print("\n🎉 Touch Gesture System Demo Complete!")
print("The system is ready for mobile integration in Orbit Jump.") 