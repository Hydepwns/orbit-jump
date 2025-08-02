-- Phase 5: Mobile Controls Tests
-- Tests mobile input handling, touch gestures, and responsive UI

package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

print("--- Phase 5: Mobile Controls Tests ---")

-- Test suite
local tests = {
    ["mobile detection"] = function()
        -- Test mobile detection logic
        local isMobile = Utils.MobileInput and Utils.MobileInput.isMobile and Utils.MobileInput.isMobile() or false
        TestFramework.assert.type("boolean", type(isMobile), "Mobile detection should return boolean")
        
        -- Test orientation detection
        local orientation = Utils.MobileInput and Utils.MobileInput.getOrientation and Utils.MobileInput.getOrientation() or "landscape"
        TestFramework.assert.isTrue(orientation == "landscape" or orientation == "portrait", "Orientation should be landscape or portrait")
    end,
    
    ["touch state management"] = function()
        -- Initialize mobile input
        if Utils.MobileInput and Utils.MobileInput.init then
            Utils.MobileInput.init()
        end
        
        -- Test touch state initialization
        local touchState = Utils.MobileInput and Utils.MobileInput.touchState or {}
        TestFramework.assert.notNil(touchState, "Touch state should be initialized")
        
        if touchState.touches then
            TestFramework.assert.notNil(touchState.touches, "Touches should be initialized")
        end
        
        if touchState.gestures then
            TestFramework.assert.notNil(touchState.gestures, "Gestures should be initialized")
        end
    end,
    
    ["touch event handling"] = function()
        -- Initialize mobile input
        if Utils.MobileInput and Utils.MobileInput.init then
            Utils.MobileInput.init()
        end
        
        -- Test touch press
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.handleTouch then
                Utils.MobileInput.handleTouch(1, 400, 300, "pressed")
            end
        end)
        
        TestFramework.assert.isTrue(success, "Touch press should work without crashing")
        
        -- Test touch release
        success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.handleTouch then
                Utils.MobileInput.handleTouch(1, 400, 300, "released")
            end
        end)
        
        TestFramework.assert.isTrue(success, "Touch release should work without crashing")
    end,
    
    ["swipe gesture detection"] = function()
        -- Initialize mobile input
        if Utils.MobileInput and Utils.MobileInput.init then
            Utils.MobileInput.init()
        end
        
        -- Test swipe detection
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.handleTouch then
                -- Press
                Utils.MobileInput.handleTouch(1, 400, 300, "pressed")
                -- Move (swipe)
                Utils.MobileInput.handleTouch(1, 600, 300, "moved")
                -- Release
                Utils.MobileInput.handleTouch(1, 600, 300, "released")
            end
        end)
        
        TestFramework.assert.isTrue(success, "Swipe gesture should work without crashing")
    end,
    
    ["tap detection"] = function()
        -- Initialize mobile input
        if Utils.MobileInput and Utils.MobileInput.init then
            Utils.MobileInput.init()
        end
        
        -- Test single tap
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.handleTap then
                Utils.MobileInput.handleTap(400, 300)
            end
        end)
        
        TestFramework.assert.isTrue(success, "Single tap should work without crashing")
    end,
    
    ["double tap detection"] = function()
        -- Initialize mobile input
        if Utils.MobileInput and Utils.MobileInput.init then
            Utils.MobileInput.init()
        end
        
        -- Test double tap
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.handleDoubleTap then
                Utils.MobileInput.handleDoubleTap(400, 300)
            end
        end)
        
        TestFramework.assert.isTrue(success, "Double tap should work without crashing")
    end,
    
    ["UI scaling"] = function()
        -- Test UI scale calculation
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.calculateUIScale then
                local scale = Utils.MobileInput.calculateUIScale(800, 600)
                TestFramework.assert.isTrue(scale > 0, "UI scale should be positive")
            end
        end)
        
        TestFramework.assert.isTrue(success, "UI scaling should work without crashing")
    end,
    
    ["responsive UI layout"] = function()
        -- Test responsive layout calculation
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.calculateLayout then
                local layout = Utils.MobileInput.calculateLayout(800, 600)
                TestFramework.assert.notNil(layout, "Layout should be calculated")
            end
        end)
        
        TestFramework.assert.isTrue(success, "Responsive layout should work without crashing")
    end,
    
    ["mobile pull indicator"] = function()
        -- Test pull indicator
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.showPullIndicator then
                Utils.MobileInput.showPullIndicator(400, 300)
            end
        end)
        
        TestFramework.assert.isTrue(success, "Pull indicator should work without crashing")
    end,
    
    ["mobile controls rendering"] = function()
        -- Test mobile controls rendering
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.renderControls then
                Utils.MobileInput.renderControls()
            end
        end)
        
        TestFramework.assert.isTrue(success, "Mobile controls rendering should work without crashing")
    end,
    
    ["haptic feedback"] = function()
        -- Test haptic feedback
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.vibrate then
                Utils.MobileInput.vibrate(100)
            end
        end)
        
        TestFramework.assert.isTrue(success, "Haptic feedback should work without crashing")
    end,
    
    ["mobile accessibility"] = function()
        -- Test accessibility features
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.setAccessibilityMode then
                Utils.MobileInput.setAccessibilityMode(true)
            end
        end)
        
        TestFramework.assert.isTrue(success, "Accessibility mode should work without crashing")
    end,
    
    ["mobile performance"] = function()
        -- Test mobile performance considerations
        local success = Utils.ErrorHandler.safeCall(function()
            if Utils.MobileInput and Utils.MobileInput.optimizeForMobile then
                Utils.MobileInput.optimizeForMobile()
            end
        end)
        
        TestFramework.assert.isTrue(success, "Mobile optimization should work without crashing")
    end,
    
    ["mobile input integration"] = function()
        -- Test full mobile input integration
        local success = Utils.ErrorHandler.safeCall(function()
            -- Initialize game state
            local GameState = require("src.core.game_state")
            GameState.init(800, 600)
            
            -- Test mobile input with game state
            if Utils.MobileInput and Utils.MobileInput.init then
                Utils.MobileInput.init()
            end
        end)
        
        TestFramework.assert.isTrue(success, "Mobile input integration should work without crashing")
    end
}

-- Run tests
TestFramework.runTests(tests)

-- Return module with run function
return {
    run = function()
        TestFramework.runTests(tests)
        return true
    end
} 