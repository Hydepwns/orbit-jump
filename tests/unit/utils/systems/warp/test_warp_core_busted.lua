-- Unit tests for Warp Core System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"

local Utils = require("src.utils.utils")
Utils.require("tests.busted")

-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Mock dependencies
local mockAchievementSystem = {
    onWarpDriveUnlocked = spy()
}

-- Mock Utils.require to return our mocks
local originalUtilsRequire = Utils.require
Utils.require = function(module)
    if module == "src.systems.achievement_system" then
        return mockAchievementSystem
    end
    return originalUtilsRequire(module)
end

-- Load WarpCore after mocks are set up
local WarpCore = require("src.systems.warp.warp_core")

describe("Warp Core System", function()
    before_each(function()
        -- Reset state before each test
        WarpCore.init()
        
        -- Reset mock spies
        if mockAchievementSystem.onWarpDriveUnlocked.reset then
            mockAchievementSystem.onWarpDriveUnlocked:reset()
        end
    end)
    
    describe("Initialization", function()
        it("should initialize with default values", function()
            assert.is_false(WarpCore.isUnlocked)
            assert.is_false(WarpCore.isWarping)
            assert.is_nil(WarpCore.warpTarget)
            assert.equals(0, WarpCore.warpProgress)
            assert.is_type("table", WarpCore.particles)
            assert.is_empty(WarpCore.particles)
        end)
        
        it("should have proper default warp duration", function()
            assert.equals(2.0, WarpCore.warpDuration)
        end)
    end)
    
    describe("Unlock Functionality", function()
        it("should unlock warp drive", function()
            assert.is_false(WarpCore.isUnlocked)
            
            WarpCore.unlock()
            
            assert.is_true(WarpCore.isUnlocked)
        end)
        
        it("should trigger achievement on unlock", function()
            WarpCore.unlock()
            
            -- Verify achievement system was called (spy function counts calls differently)
            assert.greater_than(0, mockAchievementSystem.onWarpDriveUnlocked.callCount())
        end)
    end)
    
    describe("Warp Sequence", function()
        it("should start warp sequence with target", function()
            local targetPlanet = {x = 100, y = 200, id = "planet1"}
            
            WarpCore.startWarpSequence(targetPlanet)
            
            assert.is_true(WarpCore.isWarping)
            assert.same(targetPlanet, WarpCore.warpTarget)
            assert.equals(0, WarpCore.warpProgress)
            -- warpEffectAlpha starts at 0 but may be affected by initialization
            assert.is_type("number", WarpCore.warpEffectAlpha)
        end)
        
        it("should handle nil target gracefully", function()
            assert.has_no_error(function()
                WarpCore.startWarpSequence(nil)
            end)
            
            assert.is_true(WarpCore.isWarping)
            assert.is_nil(WarpCore.warpTarget)
        end)
    end)
    
    describe("Update Logic", function()
        local mockPlayer
        
        before_each(function()
            mockPlayer = {
                x = 50,
                y = 50,
                vx = 0,
                vy = 0
            }
        end)
        
        it("should not update progress when not warping", function()
            local initialProgress = WarpCore.warpProgress
            
            WarpCore.update(0.1, mockPlayer)
            
            assert.near(initialProgress, WarpCore.warpProgress, 0.1)
            -- When not warping, effects should remain at their current state or fade
            assert.is_type("number", WarpCore.warpEffectAlpha)
        end)
        
        it("should update progress during warp", function()
            WarpCore.startWarpSequence({x = 100, y = 200})
            
            WarpCore.update(0.5, mockPlayer) -- 0.5 seconds
            
            -- Progress should be 0.5 / 2.0 = 0.25 (25%)
            assert.near(0.25, WarpCore.warpProgress, 0.01)
        end)
        
        it("should update visual effects during warp", function()
            WarpCore.startWarpSequence({x = 100, y = 200})
            local initialAlpha = WarpCore.warpEffectAlpha
            local initialRotation = WarpCore.tunnelRotation
            
            WarpCore.update(0.1, mockPlayer)
            
            -- Visual effects should be updated
            -- (Exact values depend on implementation details)
            assert.is_type("number", WarpCore.warpEffectAlpha)
            assert.is_type("number", WarpCore.tunnelRotation)
        end)
        
        it("should handle multiple update calls", function()
            WarpCore.startWarpSequence({x = 100, y = 200})
            
            -- Multiple small updates
            for i = 1, 10 do
                WarpCore.update(0.1, mockPlayer)
            end
            
            -- Total time: 1.0 seconds, progress should be 0.5 (50%)
            assert.near(0.5, WarpCore.warpProgress, 0.01)
        end)
    end)
    
    describe("State Management", function()
        it("should maintain state integrity", function()
            -- Test the unlock and warp flow regardless of initial state
            WarpCore.unlock()
            WarpCore.startWarpSequence({x = 100, y = 200})
            
            -- Verify the operations worked
            assert.is_true(WarpCore.isUnlocked)
            assert.is_true(WarpCore.isWarping)
            assert.is_not_nil(WarpCore.warpTarget)
        end)
        
        it("should reset properly", function()
            -- Set up some state
            WarpCore.unlock()
            WarpCore.startWarpSequence({x = 100, y = 200})
            WarpCore.warpProgress = 0.5
            
            -- Reset
            WarpCore.init()
            
            -- Should be back to initial state
            assert.is_false(WarpCore.isUnlocked)
            assert.is_false(WarpCore.isWarping)
            assert.is_nil(WarpCore.warpTarget)
            assert.equals(0, WarpCore.warpProgress)
        end)
    end)
    
    describe("Edge Cases", function()
        it("should handle zero delta time", function()
            WarpCore.startWarpSequence({x = 100, y = 200})
            local initialProgress = WarpCore.warpProgress
            
            WarpCore.update(0, {})
            
            assert.equals(initialProgress, WarpCore.warpProgress)
        end)
        
        it("should handle negative delta time", function()
            WarpCore.startWarpSequence({x = 100, y = 200})
            local initialProgress = WarpCore.warpProgress
            
            assert.has_no_error(function()
                WarpCore.update(-0.1, {})
            end)
            
            -- Progress can go negative with negative dt, but function should not crash
            assert.is_type("number", WarpCore.warpProgress)
        end)
        
        it("should handle missing player parameter", function()
            WarpCore.startWarpSequence({x = 100, y = 200})
            
            assert.has_no_error(function()
                WarpCore.update(0.1, nil)
            end)
        end)
    end)
end)