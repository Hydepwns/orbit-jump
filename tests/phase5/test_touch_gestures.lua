-- Tests for Touch Gesture System
-- Verifies touch gesture recognition, multi-touch handling, and gesture execution

local TestFramework = require("tests.test_framework")
local Utils = require("src.utils.utils")

local TouchGestureTests = {
    ["touch gesture system initialization"] = function()
        -- Test that touch gesture system can be loaded and initialized
        local TouchGestureSystem = Utils.require("src.systems.touch_gesture_system")
        TestFramework.utils.assertNotNil(TouchGestureSystem, "Touch gesture system should be available")
        
        -- Test initialization
        local success = pcall(function()
            TouchGestureSystem.init()
        end)
        TestFramework.utils.assertTrue(success, "Touch gesture system should initialize without errors")
        
        -- Test state reset
        TestFramework.utils.assertNotNil(TouchGestureSystem.touchState, "Touch state should be initialized")
        TestFramework.utils.assertNotNil(TouchGestureSystem.touchState.touches, "Touches should be initialized")
        TestFramework.utils.assertNotNil(TouchGestureSystem.touchState.gestures, "Gestures should be initialized")
    end,
    
    ["touch event handling"] = function()
        -- Test touch event handling without errors
        local TouchGestureSystem = Utils.require("src.systems.touch_gesture_system")
        
        -- Test touch press
        local success = pcall(function()
            TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "pressed")
        end)
        TestFramework.utils.assertTrue(success, "Touch press should work without crashing")
        
        -- Test touch move
        success = pcall(function()
            TouchGestureSystem.handleTouchEvent(1, 150, 250, 1.0, "moved")
        end)
        TestFramework.utils.assertTrue(success, "Touch move should work without crashing")
        
        -- Test touch release
        success = pcall(function()
            TouchGestureSystem.handleTouchEvent(1, 150, 250, 1.0, "released")
        end)
        TestFramework.utils.assertTrue(success, "Touch release should work without crashing")
    end,
    
    ["gesture recognition"] = function()
        -- Test basic gesture recognition
        local TouchGestureSystem = Utils.require("src.systems.touch_gesture_system")
        
        -- Test tap detection
        TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "pressed")
        TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "released")
        
        -- Test swipe detection
        TouchGestureSystem.handleTouchEvent(2, 100, 200, 1.0, "pressed")
        TouchGestureSystem.handleTouchEvent(2, 200, 200, 1.0, "moved")
        TouchGestureSystem.handleTouchEvent(2, 200, 200, 1.0, "released")
        
        -- Verify touch count
        local touchCount = TouchGestureSystem.getTouchCount()
        TestFramework.utils.assertEqual(0, touchCount, "Touch count should be 0 after release")
    end,
    
    ["multi-touch handling"] = function()
        -- Test multi-touch gesture handling
        local TouchGestureSystem = Utils.require("src.systems.touch_gesture_system")
        
        -- Simulate two-finger touch
        TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "pressed")
        TouchGestureSystem.handleTouchEvent(2, 200, 200, 1.0, "pressed")
        
        local touchCount = TouchGestureSystem.getTouchCount()
        TestFramework.utils.assertEqual(2, touchCount, "Should detect 2 touches")
        
        -- Test touch positions
        local positions = TouchGestureSystem.getTouchPositions()
        TestFramework.utils.assertEqual(2, #positions, "Should return 2 touch positions")
        
        -- Release touches
        TouchGestureSystem.handleTouchEvent(1, 100, 200, 1.0, "released")
        TouchGestureSystem.handleTouchEvent(2, 200, 200, 1.0, "released")
        
        touchCount = TouchGestureSystem.getTouchCount()
        TestFramework.utils.assertEqual(0, touchCount, "Touch count should be 0 after release")
    end,
    
    ["configuration integration"] = function()
        -- Test that configuration is properly integrated
        local Config = Utils.require("src.utils.config")
        TestFramework.utils.assertNotNil(Config.mobile.gestures, "Mobile gestures config should exist")
        TestFramework.utils.assertNotNil(Config.mobile.sensitivity, "Mobile sensitivity config should exist")
        
        -- Test gesture settings
        TestFramework.utils.assertTrue(Config.mobile.gestures.enabled, "Gestures should be enabled by default")
        TestFramework.utils.assertTrue(Config.mobile.gestures.pinchToZoom, "Pinch-to-zoom should be enabled")
        TestFramework.utils.assertTrue(Config.mobile.gestures.swipeNavigation, "Swipe navigation should be enabled")
        TestFramework.utils.assertTrue(Config.mobile.gestures.pullbackControl, "Pullback control should be enabled")
    end,
    
    ["debug functionality"] = function()
        -- Test debug functionality
        local TouchGestureSystem = Utils.require("src.systems.touch_gesture_system")
        
        -- Test status function
        local status = TouchGestureSystem.getStatus()
        TestFramework.utils.assertNotNil(status, "Status should be available")
        TestFramework.utils.assertNotNil(status.touchCount, "Touch count should be in status")
        TestFramework.utils.assertNotNil(status.pullbackActive, "Pullback active should be in status")
        
        -- Test debug draw (should not crash)
        local success = pcall(function()
            TouchGestureSystem.drawDebug()
        end)
        TestFramework.utils.assertTrue(success, "Debug draw should work without crashing")
    end
}

return TouchGestureTests 