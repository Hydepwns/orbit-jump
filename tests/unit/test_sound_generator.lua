-- Modern Sound Generator Tests
-- Tests for sound generation system

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")
local SoundGenerator = Utils.require("src.audio.sound_generator")

local tests = {
    -- Basic sound generation
    ["should generate sine wave"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should generate sine wave sound data")
        ModernTestFramework.assert.equal(4410, soundData:getSampleCount(), "Should have correct sample count")
        ModernTestFramework.assert.equal(44100, soundData:getSampleRate(), "Should have correct sample rate")
    end,
    
    ["should generate sine wave with default sample rate"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        
        ModernTestFramework.assert.notNil(soundData, "Should generate sine wave with default sample rate")
        ModernTestFramework.assert.equal(44100, soundData:getSampleRate(), "Should use default sample rate")
    end,
    
    ["should generate square wave"] = function()
        local soundData = SoundGenerator.generateSquareWave(440, 0.1, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should generate square wave sound data")
        ModernTestFramework.assert.equal(4410, soundData:getSampleCount(), "Should have correct sample count")
    end,
    
    ["should generate noise"] = function()
        local soundData = SoundGenerator.generateNoise(0.1, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should generate noise sound data")
        ModernTestFramework.assert.equal(4410, soundData:getSampleCount(), "Should have correct sample count")
    end,
    
    ["should generate multiple sounds independently"] = function()
        local sineData = SoundGenerator.generateSineWave(440, 0.1)
        local squareData = SoundGenerator.generateSquareWave(440, 0.1)
        local noiseData = SoundGenerator.generateNoise(0.1)
        
        ModernTestFramework.assert.notNil(sineData, "Should generate sine wave")
        ModernTestFramework.assert.notNil(squareData, "Should generate square wave")
        ModernTestFramework.assert.notNil(noiseData, "Should generate noise")
        ModernTestFramework.assert.notEqual(sineData, squareData, "Should generate different sound data")
    end,
    
    -- Envelope application
    ["should apply envelope"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        local envelopeData = SoundGenerator.applyEnvelope(soundData, 0.01, 0.02, 0.5, 0.01)
        
        ModernTestFramework.assert.notNil(envelopeData, "Should apply envelope to sound data")
        ModernTestFramework.assert.equal(soundData:getSampleCount(), envelopeData:getSampleCount(), "Should preserve sample count")
    end,
    
    -- Game sounds generation
    ["should generate game sounds"] = function()
        local sounds = SoundGenerator.generateGameSounds()
        
        ModernTestFramework.assert.notNil(sounds, "Should generate game sounds")
        ModernTestFramework.assert.notNil(sounds.jump, "Should have jump sound")
        ModernTestFramework.assert.notNil(sounds.ring, "Should have ring sound")
        ModernTestFramework.assert.notNil(sounds.dash, "Should have dash sound")
        ModernTestFramework.assert.notNil(sounds.land, "Should have land sound")
        ModernTestFramework.assert.notNil(sounds.combo, "Should have combo sound")
        ModernTestFramework.assert.notNil(sounds.gameOver, "Should have game over sound")
        ModernTestFramework.assert.notNil(sounds.ambient, "Should have ambient sound")
    end,
    
    -- Sound properties validation
    ["should validate sound data structure"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        
        ModernTestFramework.assert.notNil(soundData.getSampleCount, "Should have getSampleCount method")
        ModernTestFramework.assert.notNil(soundData.getSampleRate, "Should have getSampleRate method")
        ModernTestFramework.assert.notNil(soundData.getSample, "Should have getSample method")
        ModernTestFramework.assert.notNil(soundData.setSample, "Should have setSample method")
    end,
    
    -- Frequency accuracy tests
    ["should generate correct frequency sine wave"] = function()
        local freq = 440
        local duration = 0.1
        local soundData = SoundGenerator.generateSineWave(freq, duration, 44100)
        
        -- Check for zero crossings (should be approximately freq * duration)
        local zeroCrossings = 0
        local prevSample = soundData:getSample(0)
        
        for i = 1, soundData:getSampleCount() - 1 do
            local sample = soundData:getSample(i)
            if (prevSample < 0 and sample >= 0) or (prevSample >= 0 and sample < 0) then
                zeroCrossings = zeroCrossings + 1
            end
            prevSample = sample
        end
        
        local expectedCrossings = freq * duration
        ModernTestFramework.assert.approx(expectedCrossings, zeroCrossings, 2, "Should have approximately correct zero crossings")
    end,
    
    ["should generate correct frequency square wave"] = function()
        local freq = 440
        local duration = 0.1
        local soundData = SoundGenerator.generateSquareWave(freq, duration, 44100)
        
        -- Check for transitions (should be approximately freq * duration * 2)
        local transitions = 0
        local prevSample = soundData:getSample(0)
        
        for i = 1, soundData:getSampleCount() - 1 do
            local sample = soundData:getSample(i)
            if (prevSample < 0 and sample >= 0) or (prevSample >= 0 and sample < 0) then
                transitions = transitions + 1
            end
            prevSample = sample
        end
        
        local expectedTransitions = freq * duration * 2
        ModernTestFramework.assert.approx(expectedTransitions, transitions, 4, "Should have approximately correct transitions")
    end,
    
    -- Edge cases
    ["should handle zero duration"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should handle zero duration")
        ModernTestFramework.assert.equal(0, soundData:getSampleCount(), "Should have zero samples for zero duration")
    end,
    
    ["should handle very short duration"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.001, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should handle very short duration")
        ModernTestFramework.assert.approx(4, soundData:getSampleCount(), 1, "Should have few samples for short duration")
    end,
    
    ["should handle high frequency"] = function()
        local soundData = SoundGenerator.generateSineWave(2000, 0.1, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should handle high frequency")
        ModernTestFramework.assert.equal(4410, soundData:getSampleCount(), "Should have correct sample count")
    end,
    
    ["should handle low frequency"] = function()
        local soundData = SoundGenerator.generateSineWave(20, 0.1, 44100)
        
        ModernTestFramework.assert.notNil(soundData, "Should handle low frequency")
        ModernTestFramework.assert.equal(4410, soundData:getSampleCount(), "Should have correct sample count")
    end,
    
    -- Envelope edge cases
    ["should handle envelope with zero attack"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        local envelopeData = SoundGenerator.applyEnvelope(soundData, 0, 0.02, 0.5, 0.01)
        
        ModernTestFramework.assert.notNil(envelopeData, "Should handle zero attack time")
    end,
    
    ["should handle envelope with zero decay"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        local envelopeData = SoundGenerator.applyEnvelope(soundData, 0.01, 0, 0.5, 0.01)
        
        ModernTestFramework.assert.notNil(envelopeData, "Should handle zero decay time")
    end,
    
    ["should handle envelope with zero release"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        local envelopeData = SoundGenerator.applyEnvelope(soundData, 0.01, 0.02, 0.5, 0)
        
        ModernTestFramework.assert.notNil(envelopeData, "Should handle zero release time")
    end
}

return tests 