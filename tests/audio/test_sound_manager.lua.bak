-- Comprehensive tests for Sound Manager
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock sound objects
local function createMockSound()
    local sound = {
        playing = false,
        volume = 1.0,
        pitch = 1.0,
        cloned = false,
        stopped = false
    }
    
    function sound:play()
        self.playing = true
    end
    
    function sound:stop()
        self.playing = false
        self.stopped = true
    end
    
    function sound:isPlaying()
        return self.playing
    end
    
    function sound:setVolume(vol)
        self.volume = vol
    end
    
    function sound:setPitch(p)
        self.pitch = p
    end
    
    function sound:clone()
        local clonedSound = createMockSound()
        clonedSound.cloned = true
        return clonedSound
    end
    
    return sound
end

-- Create shared mock sounds
local mockSounds = {}

local function resetMockSounds()
    mockSounds = {
        jump = createMockSound(),
        ring = createMockSound(),
        combo = createMockSound(),
        dash = createMockSound(),
        land = createMockSound(),
        gameOver = createMockSound(),
        ambient = createMockSound()
    }
end

-- Mock SoundGenerator
local mockSoundGenerator = {
    generateGameSounds = function()
        return mockSounds
    end
}

-- Test suite
local tests = {
    ["test initialization"] = function()
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        
        TestFramework.utils.assertNotNil(soundManager, "SoundManager should be created")
        TestFramework.utils.assertTrue(soundManager.enabled, "Sound should be enabled by default")
        TestFramework.utils.assertEqual(1.0, soundManager.volume, "Volume should be 1.0")
        TestFramework.utils.assertNotNil(soundManager.sounds, "Sounds table should exist")
    end,
    
    ["test sound loading"] = function()
        resetMockSounds()
        
        -- Replace SoundGenerator in Utils module cache
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        TestFramework.utils.assertNotNil(soundManager.sounds.jump, "Jump sound should be loaded")
        TestFramework.utils.assertNotNil(soundManager.sounds.ring, "Ring sound should be loaded")
        TestFramework.utils.assertNotNil(soundManager.sounds.combo, "Combo sound should be loaded")
        TestFramework.utils.assertNotNil(soundManager.sounds.ambient, "Ambient sound should be loaded")
        TestFramework.utils.assertTrue(mockSounds.ambient.playing, "Ambient sound should start playing")
    end,
    
    ["test basic play function"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Reset jump sound
        mockSounds.jump.playing = false
        
        soundManager:play("jump", 0.5, 1.5)
        
        TestFramework.utils.assertTrue(mockSounds.jump.playing, "Jump sound should be playing")
        TestFramework.utils.assertEqual(0.5, mockSounds.jump.volume, "Volume should be set")
        TestFramework.utils.assertEqual(1.5, mockSounds.jump.pitch, "Pitch should be set")
    end,
    
    ["test play with cloning"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Make jump sound already playing
        mockSounds.jump.playing = true
        
        local result = soundManager:play("jump")
        
        TestFramework.utils.assertNotNil(result, "Should return cloned sound")
        TestFramework.utils.assertTrue(result.cloned, "Should return a cloned sound when original is playing")
    end,
    
    ["test play when disabled"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        soundManager.enabled = false
        
        mockSounds.jump.playing = false
        soundManager:play("jump")
        
        TestFramework.utils.assertFalse(mockSounds.jump.playing, "Sound should not play when disabled")
    end,
    
    ["test play nonexistent sound"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Should not crash
        local success = pcall(function()
            soundManager:play("nonexistent")
        end)
        
        TestFramework.utils.assertTrue(success, "Playing nonexistent sound should not crash")
    end,
    
    ["test jump sound"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        mockSounds.jump.playing = false
        soundManager:playJump()
        
        TestFramework.utils.assertTrue(mockSounds.jump.playing, "Jump sound should play")
        TestFramework.utils.assertEqual(0.7, mockSounds.jump.volume, "Jump volume should be 0.7")
    end,
    
    ["test ring collect sound"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Test basic ring collect
        mockSounds.ring.playing = false
        soundManager:playRingCollect(0)
        
        TestFramework.utils.assertTrue(mockSounds.ring.playing, "Ring sound should play")
        TestFramework.utils.assertEqual(0.8, mockSounds.ring.volume, "Ring volume should be 0.8")
        TestFramework.utils.assertEqual(1.0, mockSounds.ring.pitch, "Ring pitch should be 1.0 for combo 0")
        
        -- Test with combo
        mockSounds.ring.playing = false
        soundManager:playRingCollect(3)
        TestFramework.utils.assertEqual(1.3, mockSounds.ring.pitch, "Ring pitch should increase with combo")
        
        -- Test combo milestone
        mockSounds.combo.playing = false
        soundManager:playRingCollect(5)
        TestFramework.utils.assertTrue(mockSounds.combo.playing, "Combo sound should play at milestone")
        
        -- Test pitch clamping
        mockSounds.ring.playing = false
        soundManager:playRingCollect(15)
        TestFramework.utils.assertEqual(2.0, mockSounds.ring.pitch, "Ring pitch should be clamped to 2.0")
    end,
    
    ["test dash sound"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        mockSounds.dash.playing = false
        soundManager:playDash()
        
        TestFramework.utils.assertTrue(mockSounds.dash.playing, "Dash sound should play")
        TestFramework.utils.assertEqual(0.6, mockSounds.dash.volume, "Dash volume should be 0.6")
    end,
    
    ["test land sound"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        mockSounds.land.playing = false
        soundManager:playLand()
        
        TestFramework.utils.assertTrue(mockSounds.land.playing, "Land sound should play")
        TestFramework.utils.assertEqual(0.5, mockSounds.land.volume, "Land volume should be 0.5")
    end,
    
    ["test game over sound"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        mockSounds.gameOver.playing = false
        mockSounds.ambient.playing = true
        
        soundManager:playGameOver()
        
        TestFramework.utils.assertTrue(mockSounds.gameOver.playing, "Game over sound should play")
        TestFramework.utils.assertEqual(0.8, mockSounds.gameOver.volume, "Game over volume should be 0.8")
        TestFramework.utils.assertTrue(mockSounds.ambient.stopped, "Ambient sound should stop")
    end,
    
    ["test event warning"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        mockSounds.combo.playing = false
        soundManager:playEventWarning()
        
        TestFramework.utils.assertTrue(mockSounds.combo.playing, "Warning should use combo sound")
        TestFramework.utils.assertEqual(0.9, mockSounds.combo.volume, "Warning volume should be 0.9")
        TestFramework.utils.assertEqual(0.7, mockSounds.combo.pitch, "Warning pitch should be 0.7")
    end,
    
    ["test restart ambient"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Stop ambient first
        mockSounds.ambient.playing = false
        
        soundManager:restartAmbient()
        
        TestFramework.utils.assertTrue(mockSounds.ambient.playing, "Ambient should restart")
        
        -- Test when already playing
        soundManager:restartAmbient()
        TestFramework.utils.assertTrue(mockSounds.ambient.playing, "Ambient should remain playing")
    end,
    
    ["test set enabled"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Start with sounds playing
        mockSounds.jump.playing = true
        mockSounds.ambient.playing = true
        
        soundManager:setEnabled(false)
        
        TestFramework.utils.assertFalse(soundManager.enabled, "Should be disabled")
        TestFramework.utils.assertTrue(mockSounds.jump.stopped, "All sounds should stop")
        TestFramework.utils.assertTrue(mockSounds.ambient.stopped, "Ambient should stop")
        
        -- Re-enable
        mockSounds.ambient.playing = false
        mockSounds.ambient.stopped = false
        soundManager:setEnabled(true)
        
        TestFramework.utils.assertTrue(soundManager.enabled, "Should be enabled")
        TestFramework.utils.assertTrue(mockSounds.ambient.playing, "Ambient should restart")
    end,
    
    ["test set volume"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        soundManager:setVolume(0.5)
        TestFramework.utils.assertEqual(0.5, soundManager.volume, "Volume should be set")
        TestFramework.utils.assertEqual(0.1, mockSounds.ambient.volume, "Ambient volume should be 0.2 * 0.5")
        
        -- Test clamping
        soundManager:setVolume(2.0)
        TestFramework.utils.assertEqual(1.0, soundManager.volume, "Volume should be clamped to 1.0")
        
        soundManager:setVolume(-1.0)
        TestFramework.utils.assertEqual(0.0, soundManager.volume, "Volume should be clamped to 0.0")
    end,
    
    ["test volume affects playback"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        soundManager:setVolume(0.5)
        
        mockSounds.jump.playing = false
        soundManager:play("jump", 0.8)
        
        TestFramework.utils.assertEqual(0.4, mockSounds.jump.volume, "Sound volume should be 0.8 * 0.5")
    end,
    
    ["test update function"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Should not crash
        local success = pcall(function()
            soundManager:update(0.016)
        end)
        
        TestFramework.utils.assertTrue(success, "Update should not crash")
    end,
    
    ["test no sounds loaded"] = function()
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        -- Don't call load()
        
        -- Should handle gracefully
        local success = pcall(function()
            soundManager:playJump()
            soundManager:setVolume(0.5)
            soundManager:setEnabled(false)
        end)
        
        TestFramework.utils.assertTrue(success, "Should handle no sounds gracefully")
    end,
    
    ["test master volume property"] = function()
        resetMockSounds()
        Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
        
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        
        -- Check that 'masterVolume' field doesn't exist in the actual implementation
        -- The implementation uses 'volume' not 'masterVolume'
        TestFramework.utils.assertNil(soundManager.masterVolume, "Implementation uses 'volume' not 'masterVolume'")
        TestFramework.utils.assertEqual(1.0, soundManager.volume, "Volume field should be used")
    end
}

-- Run the test suite
local function run()
    -- Setup mock before running tests
    Utils.moduleCache["src.audio.sound_generator"] = mockSoundGenerator
    
    local success = TestFramework.runSuite("Sound Manager Tests", tests)
    
    -- Clean up
    Utils.moduleCache["src.audio.sound_generator"] = nil
    
    return success
end

return {run = run}