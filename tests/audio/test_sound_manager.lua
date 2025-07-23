-- Tests for SoundManager module
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")

-- Mock love.audio
Mocks.setup()

local SoundManager = Utils.Utils.require("src.audio.sound_manager")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["sound manager initialization"] = function()
        local soundManager = SoundManager:new()
        TestFramework.utils.assertNotNil(soundManager, "SoundManager should be created")
        TestFramework.utils.assertEqual(true, soundManager.enabled, "Sound should be enabled by default")
        TestFramework.utils.assertEqual(1.0, soundManager.masterVolume, "Master volume should be 1.0")
    end,
    
    ["sound loading"] = function()
        local soundManager = SoundManager:new()
        local success  = Utils.ErrorHandler.safeCall(function() soundManager:load() end)
        TestFramework.utils.assertTrue(success, "Sound loading should not crash")
        TestFramework.utils.assertNotNil(soundManager.sounds, "Sounds table should exist")
    end,
    
    ["play jump sound"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Should not crash when playing sounds
        local success  = Utils.ErrorHandler.safeCall(function() 
            soundManager:playJump()
        end)
        TestFramework.utils.assertTrue(success, "Playing jump sound should not crash")
    end,
    
    ["play collection sounds"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            soundManager:playCollectRing()
            soundManager:playPowerUp()
        end)
        TestFramework.utils.assertTrue(success, "Playing collection sounds should not crash")
    end,
    
    ["play movement sounds"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            soundManager:playDash()
            soundManager:playLand()
        end)
        TestFramework.utils.assertTrue(success, "Playing movement sounds should not crash")
    end,
    
    ["volume control"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        soundManager:setVolume(0.5)
        TestFramework.utils.assertEqual(0.5, soundManager.masterVolume, "Volume should be set correctly")
        
        soundManager:setVolume(2.0)
        TestFramework.utils.assertEqual(1.0, soundManager.masterVolume, "Volume should be clamped to 1.0")
        
        soundManager:setVolume(-1.0)
        TestFramework.utils.assertEqual(0.0, soundManager.masterVolume, "Volume should be clamped to 0.0")
    end,
    
    ["enable/disable sound"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        soundManager:setEnabled(false)
        TestFramework.utils.assertFalse(soundManager.enabled, "Sound should be disabled")
        
        -- Should not play when disabled
        local success  = Utils.ErrorHandler.safeCall(function()
            soundManager:playJump()
        end)
        TestFramework.utils.assertTrue(success, "Playing while disabled should not crash")
        
        soundManager:setEnabled(true)
        TestFramework.utils.assertTrue(soundManager.enabled, "Sound should be re-enabled")
    end,
    
    ["sound cleanup"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            soundManager:cleanup()
        end)
        TestFramework.utils.assertTrue(success, "Cleanup should not crash")
    end,
    
    ["toggle sound"] = function()
        local soundManager = SoundManager:new()
        local initial = soundManager.enabled
        
        soundManager:toggle()
        TestFramework.utils.assertEqual(not initial, soundManager.enabled, "Toggle should flip enabled state")
        
        soundManager:toggle()
        TestFramework.utils.assertEqual(initial, soundManager.enabled, "Toggle should flip back")
    end,
    
    ["combo sound variations"] = function()
        local soundManager = SoundManager:new()
        soundManager:load()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            for combo = 1, 20 do
                soundManager:playComboSound(combo)
            end
        end)
        TestFramework.utils.assertTrue(success, "Playing combo sounds should not crash")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Sound Manager Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("sound_manager", 8) -- All major functions tested
    
    return success
end

return {run = run}