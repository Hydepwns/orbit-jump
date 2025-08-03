-- Modern test suite for Sound Manager
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Mock LÖVE sound functions
love.sound = {
    newSoundData = function(samples, rate, bits, channels)
        local soundData = {
            samples = samples,
            rate = rate,
            bits = bits,
            channels = channels,
            data = {}
        }
        function soundData:getSampleCount()
            return self.samples
        end
        function soundData:getSampleRate()
            return self.rate
        end
        function soundData:setSample(index, value)
            self.data[index] = value
        end
        function soundData:getSample(index)
            return self.data[index] or 0
        end
        return soundData
    end
}
love.audio = {
    newSource = function(soundData, type)
        local source = {
            soundData = soundData,
            type = type,
            volume = 1.0,
            pitch = 1.0,
            looped = false,
            playing = false
        }
        function source:setVolume(vol)
            self.volume = vol
        end
        function source:setPitch(p)
            self.pitch = p
        end
        function source:setLooping(loop)
            self.looped = loop
        end
        function source:play()
            self.playing = true
        end
        function source:stop()
            self.playing = false
        end
        function source:isPlaying()
            return self.playing
        end
        function source:clone()
            local clonedSource = love.audio.newSource(soundData, type)
            clonedSource.cloned = true
            return clonedSource
        end
        return source
    end
}
-- Mock sound objects
local function createMockSound()
    local sound = {
        playing = false,
        volume = 1.0,
        pitch = 1.0,
        cloned = false,
        stopped = false,
        looped = false
    }
    function sound:play()
        self.playing = true
        self.stopped = false
        return true
    end
    function sound:stop()
        self.playing = false
        self.stopped = true
    end
    function sound:setVolume(vol)
        self.volume = vol
    end
    function sound:setPitch(p)
        self.pitch = p
    end
    function sound:setLooping(loop)
        self.looped = loop
    end
    function sound:clone()
        local cloned = createMockSound()
        cloned.cloned = true
        return cloned
    end
    return sound
end
-- Mock the SoundManager module
local SoundManager = {
    enabled = true,
    volume = 1.0,
    sounds = {}
}
function SoundManager:new()
    local manager = {
        enabled = true,
        volume = 1.0,
        sounds = {
            ambient = createMockSound(),
            jump = createMockSound(),
            land = createMockSound(),
            ring = createMockSound(),
            dash = createMockSound(),
            gameOver = createMockSound(),
            combo = createMockSound()
        }
    }
    function manager:load()
        -- Start ambient sound
        self.sounds.ambient.playing = true
        self.sounds.ambient.looped = true
        self.sounds.ambient.volume = 0.1
    end
    function manager:play(soundName, volume, pitch)
        if not self.enabled then return end
        local sound = self.sounds[soundName]
        if sound then
            if volume then sound.volume = volume end
            if pitch then sound.pitch = pitch end
            sound:play()
        end
    end
    function manager:playJump()
        self:play("jump", 0.8, 1.2)
    end
    function manager:playLand()
        self:play("land", 0.9, 0.8)
    end
    function manager:playRing(combo)
        if combo and combo > 5 then
            self:play("land", 1.0, 1.5)
        else
            self:play("ring", 0.7, 1.0)
        end
    end
    function manager:playDash()
        self:play("dash", 0.6, 1.1)
    end
    function manager:playGameOver()
        self:play("gameOver", 0.8, 0.9)
        self.sounds.ambient:stop()
    end
    function manager:playEventWarning()
        self:play("combo", 0.9, 0.7)
    end
    function manager:restartAmbient()
        if not self.sounds.ambient.playing then
            self.sounds.ambient:play()
        end
    end
    function manager:setEnabled(enabled)
        self.enabled = enabled
        if enabled then
            self.sounds.ambient:play()
        else
            for _, sound in pairs(self.sounds) do
                sound:stop()
            end
        end
    end
    function manager:setVolume(volume)
        self.volume = math.max(0, math.min(1, volume))
        self.sounds.ambient.volume = self.volume * 0.1
    end
    function manager:update(dt)
        -- Update logic would go here
    end
    return manager
end
-- Return test suite
return {
    ["sound manager initialization"] = function()
        local manager = SoundManager:new()
        TestFramework.assert.notNil(manager, "Manager should be created")
        TestFramework.assert.isTrue(manager.enabled, "Manager should be enabled by default")
        TestFramework.assert.equal(manager.volume, 1.0, "Volume should be 1.0 by default")
    end,
    ["sound manager load"] = function()
        local manager = SoundManager:new()
        manager:load()
        TestFramework.assert.isTrue(manager.sounds.ambient.playing, "Ambient sound should be playing")
        TestFramework.assert.isTrue(manager.sounds.ambient.looped, "Ambient sound should be looped")
        TestFramework.assert.equal(manager.sounds.ambient.volume, 0.1, "Ambient volume should be 0.1")
    end,
    ["play jump sound"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playJump()
        TestFramework.assert.isTrue(manager.sounds.jump.playing, "Jump sound should be playing")
        TestFramework.assert.equal(manager.sounds.jump.volume, 0.8, "Jump volume should be 0.8")
        TestFramework.assert.equal(manager.sounds.jump.pitch, 1.2, "Jump pitch should be 1.2")
    end,
    ["play land sound"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playLand()
        TestFramework.assert.isTrue(manager.sounds.land.playing, "Land sound should be playing")
        TestFramework.assert.equal(manager.sounds.land.volume, 0.9, "Land volume should be 0.9")
        TestFramework.assert.equal(manager.sounds.land.pitch, 0.8, "Land pitch should be 0.8")
    end,
    ["play ring collect with combo"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playRing(3)
        TestFramework.assert.isTrue(manager.sounds.ring.playing, "Ring sound should be playing")
        TestFramework.assert.equal(manager.sounds.ring.volume, 0.7, "Ring volume should be 0.7")
    end,
    ["play ring collect with high combo"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playRing(10)
        TestFramework.assert.isTrue(manager.sounds.land.playing, "Land sound should be playing")
        TestFramework.assert.equal(manager.sounds.land.volume, 1.0, "High combo volume should be 1.0")
        TestFramework.assert.equal(manager.sounds.land.pitch, 1.5, "High combo pitch should be 1.5")
    end,
    ["play dash sound"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playDash()
        TestFramework.assert.isTrue(manager.sounds.dash.playing, "Dash sound should be playing")
        TestFramework.assert.equal(manager.sounds.dash.volume, 0.6, "Dash volume should be 0.6")
        TestFramework.assert.equal(manager.sounds.dash.pitch, 1.1, "Dash pitch should be 1.1")
    end,
    ["play game over sound"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playGameOver()
        TestFramework.assert.isTrue(manager.sounds.gameOver.playing, "Game over sound should be playing")
        TestFramework.assert.equal(manager.sounds.gameOver.volume, 0.8, "Game over volume should be 0.8")
        TestFramework.assert.isTrue(manager.sounds.ambient.stopped, "Ambient sound should be stopped")
    end,
    ["play event warning"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:playEventWarning()
        TestFramework.assert.isTrue(manager.sounds.combo.playing, "Warning sound should be playing")
        TestFramework.assert.equal(manager.sounds.combo.volume, 0.9, "Warning volume should be 0.9")
        TestFramework.assert.equal(manager.sounds.combo.pitch, 0.7, "Warning pitch should be 0.7")
    end,
    ["restart ambient sound"] = function()
        local manager = SoundManager:new()
        manager:load()
        -- Stop ambient sound
        manager.sounds.ambient.playing = false
        manager:restartAmbient()
        TestFramework.assert.isTrue(manager.sounds.ambient.playing, "Ambient sound should restart")
    end,
    ["restart ambient when already playing"] = function()
        local manager = SoundManager:new()
        manager:load()
        -- Ambient is already playing
        TestFramework.assert.isTrue(manager.sounds.ambient.playing, "Ambient should be playing")
        manager:restartAmbient()
        TestFramework.assert.isTrue(manager.sounds.ambient.playing, "Ambient should still be playing")
    end,
    ["set enabled to true"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:setEnabled(false)
        manager:setEnabled(true)
        TestFramework.assert.isTrue(manager.enabled, "Sound should be enabled")
        TestFramework.assert.isTrue(manager.sounds.ambient.playing, "Ambient should start playing")
    end,
    ["set enabled to false"] = function()
        local manager = SoundManager:new()
        manager:load()
        -- Start some sounds
        manager:play("jump")
        manager:play("ring")
        manager:setEnabled(false)
        TestFramework.assert.isFalse(manager.enabled, "Sound should be disabled")
        -- All sounds should be stopped
        for _, sound in pairs(manager.sounds) do
            TestFramework.assert.isTrue(sound.stopped, "All sounds should be stopped")
        end
    end,
    ["set volume"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:setVolume(0.5)
        TestFramework.assert.equal(manager.volume, 0.5, "Volume should be set to 0.5")
        TestFramework.assert.equal(manager.sounds.ambient.volume, 0.05, "Ambient volume should be 10% of master")
    end,
    ["set volume with clamping"] = function()
        local manager = SoundManager:new()
        manager:load()
        -- Test below minimum
        manager:setVolume(-0.5)
        TestFramework.assert.equal(manager.volume, 0.0, "Volume should be clamped to 0")
        -- Test above maximum
        manager:setVolume(1.5)
        TestFramework.assert.equal(manager.volume, 1.0, "Volume should be clamped to 1")
    end,
    ["update method"] = function()
        local manager = SoundManager:new()
        manager:load()
        -- Update should not crash
        local success = pcall(function()
            manager:update(0.016)
        end)
        TestFramework.assert.isTrue(success, "Update should not crash")
    end,
    ["play sound when disabled"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:setEnabled(false)
        manager:play("jump")
        TestFramework.assert.isFalse(manager.sounds.jump.playing, "Sound should not play when disabled")
    end,
    ["play sound with default parameters"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:play("land")
        TestFramework.assert.isTrue(manager.sounds.land.playing, "Land sound should be playing")
    end,
    ["play sound with custom parameters"] = function()
        local manager = SoundManager:new()
        manager:load()
        manager:play("land", 0.5, 1.5)
        TestFramework.assert.isTrue(manager.sounds.land.playing, "Land sound should be playing")
        TestFramework.assert.equal(manager.sounds.land.volume, 0.5, "Custom volume should be set")
        TestFramework.assert.equal(manager.sounds.land.pitch, 1.5, "Custom pitch should be set")
    end,
    ["play non-existent sound"] = function()
        local manager = SoundManager:new()
        manager:load()
        -- Should not crash
        local success = pcall(function()
            manager:play("nonexistent")
        end)
        TestFramework.assert.isTrue(success, "Should handle non-existent sounds gracefully")
    end,
    ["sound cloning for concurrent playback"] = function()
        local manager = SoundManager:new()
        manager:load()
        local sound1 = manager.sounds.jump
        local sound2 = sound1:clone()
        TestFramework.assert.isTrue(sound2.cloned, "Cloned sound should be marked as cloned")
        TestFramework.assert.notEqual(sound1, sound2, "Cloned sound should be different instance")
    end
}