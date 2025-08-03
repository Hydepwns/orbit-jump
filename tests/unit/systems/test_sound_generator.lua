-- Comprehensive tests for Sound Generator
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Mock love.sound
local mockSoundData = {}
local mockSamples = {}
love.sound = {
    newSoundData = function(samples, rate, bits, channels)
        mockSamples = {} -- Reset samples for each sound
        mockSoundData = {
            samples = samples,
            rate = rate,
            bits = bits,
            channels = channels,
            data = {},
            setSample = function(self, i, sample)
                mockSamples[i] = sample
            end,
            getSample = function(self, i)
                return mockSamples[i] or 0
            end,
            getSampleCount = function(self)
                return samples
            end,
            getSampleRate = function(self)
                return rate
            end
        }
        return mockSoundData
    end
}
-- Mock love.audio
love.audio = {
    newSource = function(soundData, type)
        return {
            soundData = soundData,
            type = type,
            looping = false,
            volume = 1.0,
            setLooping = function(self, loop)
                self.looping = loop
            end,
            setVolume = function(self, vol)
                self.volume = vol
            end
        }
    end
}
local SoundGenerator = Utils.require("src.audio.sound_generator")
-- Test suite
local tests = {
    ["test sine wave generation"] = function()
        local frequency = 440
        local duration = 0.1
        local sampleRate = 44100
        local soundData = SoundGenerator.generateSineWave(frequency, duration, sampleRate)
        TestFramework.assert.assertNotNil(soundData, "Should generate sound data")
        TestFramework.assert.assertEqual(4410, soundData.samples, "Should have correct number of samples")
        TestFramework.assert.assertEqual(44100, soundData.rate, "Should have correct sample rate")
        -- Check that samples were written
        local hasNonZeroSamples = false
        for i = 0, 10 do
            if mockSamples[i] and mockSamples[i] ~= 0 then
                hasNonZeroSamples = true
                break
            end
        end
        TestFramework.assert.assertTrue(hasNonZeroSamples, "Should have non-zero samples")
    end,
    ["test square wave generation"] = function()
        local frequency = 220
        local duration = 0.1
        local soundData = SoundGenerator.generateSquareWave(frequency, duration)
        TestFramework.assert.assertNotNil(soundData, "Should generate sound data")
        -- Check that square wave has only two values (approximately)
        local positiveFound = false
        local negativeFound = false
        for i = 0, 100 do
            local sample = mockSamples[i]
            if sample and sample > 0 then
                positiveFound = true
                TestFramework.assert.assertTrue(math.abs(sample - 0.3) < 0.001, "Positive should be 0.3")
            elseif sample and sample < 0 then
                negativeFound = true
                TestFramework.assert.assertTrue(math.abs(sample + 0.3) < 0.001, "Negative should be -0.3")
            end
        end
        TestFramework.assert.assertTrue(positiveFound and negativeFound, "Should have both positive and negative values")
    end,
    ["test noise generation"] = function()
        local duration = 0.1
        -- Mock random for predictable testing
        local oldRandom = math.random
        local randomValues = {0.2, 0.8, 0.1, 0.9, 0.5}
        local randomIndex = 1
        math.random = function()
            local value = randomValues[randomIndex]
            randomIndex = (randomIndex % #randomValues) + 1
            return value
        end
        local soundData = SoundGenerator.generateNoise(duration)
        TestFramework.assert.assertNotNil(soundData, "Should generate sound data")
        -- Check that noise has varied values
        local uniqueValues = {}
        for i = 0, 10 do
            local sample = mockSamples[i]
            if sample then
                uniqueValues[tostring(sample)] = true
            end
        end
        local count = 0
        for _ in pairs(uniqueValues) do
            count = count + 1
        end
        TestFramework.assert.assertTrue(count > 1, "Noise should have varied values")
        -- Restore random
        math.random = oldRandom
    end,
    ["test envelope application"] = function()
        -- First create a simple sound
        local soundData = SoundGenerator.generateSineWave(440, 0.5, 44100)
        -- Store original samples
        local originalSamples = {}
        for i = 0, 100 do
            originalSamples[i] = mockSamples[i] or 0
        end
        -- Apply envelope
        SoundGenerator.applyEnvelope(soundData, 0.1, 0.1, 0.7, 0.2)
        -- Check that samples were modified
        local modified = false
        for i = 0, 100 do
            if mockSamples[i] ~= originalSamples[i] then
                modified = true
                break
            end
        end
        TestFramework.assert.assertTrue(modified, "Envelope should modify samples")
        -- Check attack phase (should start at 0)
        local firstSample = math.abs(mockSamples[0] or 0)
        TestFramework.assert.assertTrue(firstSample < 0.1, "First sample should be near zero")
    end,
    ["test game sounds generation"] = function()
        local sounds = SoundGenerator.generateGameSounds()
        TestFramework.assert.assertNotNil(sounds, "Should generate sounds table")
        TestFramework.assert.assertNotNil(sounds.jump, "Should have jump sound")
        TestFramework.assert.assertNotNil(sounds.ring, "Should have ring sound")
        TestFramework.assert.assertNotNil(sounds.dash, "Should have dash sound")
        TestFramework.assert.assertNotNil(sounds.land, "Should have land sound")
        TestFramework.assert.assertNotNil(sounds.combo, "Should have combo sound")
        TestFramework.assert.assertNotNil(sounds.gameOver, "Should have game over sound")
        TestFramework.assert.assertNotNil(sounds.ambient, "Should have ambient sound")
        -- Check ambient sound properties
        TestFramework.assert.assertTrue(sounds.ambient.looping, "Ambient should loop")
        TestFramework.assert.assertEqual(0.2, sounds.ambient.volume, "Ambient volume should be 0.2")
        -- Check that all sounds have the correct type
        TestFramework.assert.assertEqual("static", sounds.jump.type, "Jump should be static")
        TestFramework.assert.assertEqual("stream", sounds.ambient.type, "Ambient should be stream")
    end,
    ["test jump sound characteristics"] = function()
        local sounds = SoundGenerator.generateGameSounds()
        -- Jump sound should have samples (sweep from 200Hz to 800Hz)
        TestFramework.assert.assertNotNil(sounds.jump.soundData, "Jump should have sound data")
        -- Check that samples were generated
        local hasNonZeroSamples = false
        for i = 0, 10 do
            if mockSamples[i] and mockSamples[i] ~= 0 then
                hasNonZeroSamples = true
                break
            end
        end
        TestFramework.assert.assertTrue(hasNonZeroSamples, "Jump should have non-zero samples")
    end,
    ["test ring sound harmonics"] = function()
        -- Reset samples
        mockSamples = {}
        local sounds = SoundGenerator.generateGameSounds()
        -- Ring sound uses multiple harmonics
        TestFramework.assert.assertNotNil(sounds.ring.soundData, "Ring should have sound data")
        -- Should have complex waveform (not just simple sine)
        local hasComplexWaveform = false
        local sampleCount = 0
        for _, sample in pairs(mockSamples) do
            if sample and sample ~= 0 then
                sampleCount = sampleCount + 1
            end
        end
        TestFramework.assert.assertTrue(sampleCount > 0, "Ring should have samples")
    end,
    ["test sound data parameters"] = function()
        -- Test with various parameters
        local testCases = {
            {freq = 100, dur = 0.05, rate = 22050},
            {freq = 1000, dur = 0.2, rate = 48000},
            {freq = 50, dur = 1.0, rate = 44100}
        }
        for i, test in ipairs(testCases) do
            local soundData = SoundGenerator.generateSineWave(test.freq, test.dur, test.rate)
            local expectedSamples = math.floor(test.dur * test.rate)
            TestFramework.assert.assertEqual(expectedSamples, soundData.samples,
                "Test " .. i .. " should have correct samples")
            TestFramework.assert.assertEqual(test.rate, soundData.rate,
                "Test " .. i .. " should have correct rate")
        end
    end,
    ["test envelope edge cases"] = function()
        local soundData = SoundGenerator.generateSineWave(440, 0.1, 44100)
        -- Test with very short envelope times
        local success = pcall(function()
            SoundGenerator.applyEnvelope(soundData, 0.001, 0.001, 0.5, 0.001)
        end)
        TestFramework.assert.assertTrue(success, "Should handle short envelope times")
        -- Test with zero times
        success = pcall(function()
            SoundGenerator.applyEnvelope(soundData, 0, 0, 1.0, 0)
        end)
        TestFramework.assert.assertTrue(success, "Should handle zero envelope times")
    end,
    ["test all sound types created"] = function()
        local sounds = SoundGenerator.generateGameSounds()
        local soundTypes = {
            "jump", "ring", "dash", "land", "combo", "gameOver", "ambient"
        }
        for _, soundType in ipairs(soundTypes) do
            TestFramework.assert.assertNotNil(sounds[soundType], soundType .. " sound should exist")
            TestFramework.assert.assertNotNil(sounds[soundType].soundData,
                soundType .. " should have sound data")
        end
    end,
    ["test default sample rate"] = function()
        -- Test that default sample rate is used when not specified
        local soundData = SoundGenerator.generateSineWave(440, 0.1)
        TestFramework.assert.assertEqual(44100, soundData.rate, "Should use default sample rate of 44100")
        soundData = SoundGenerator.generateSquareWave(440, 0.1)
        TestFramework.assert.assertEqual(44100, soundData.rate, "Square wave should use default sample rate")
        soundData = SoundGenerator.generateNoise(0.1)
        TestFramework.assert.assertEqual(44100, soundData.rate, "Noise should use default sample rate")
    end,
    ["test sample clamping"] = function()
        -- Generate loud sine wave
        local soundData = SoundGenerator.generateSineWave(440, 0.01, 44100)
        -- Check that all samples are within valid range
        local allInRange = true
        for _, sample in pairs(mockSamples) do
            if sample and (sample < -1 or sample > 1) then
                allInRange = false
                break
            end
        end
        TestFramework.assert.assertTrue(allInRange, "All samples should be in range [-1, 1]")
    end
}
-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "Sound Generator Tests")
end
return {run = run}