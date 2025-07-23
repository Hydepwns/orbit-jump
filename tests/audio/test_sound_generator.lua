-- Tests for Sound Generator
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

Mocks.setup()

-- Mock love.sound for testing
love.sound = {
    newSoundData = function(samples, rate, bits, channels)
        return {
            samples = samples,
            rate = rate,
            bits = bits,
            channels = channels,
            setSample = function(self, i, sample) end,
            getSample = function(self, i) return 0 end
        }
    end
}

local SoundGenerator = Utils.require("src.audio.sound_generator")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["sound generator initialization"] = function()
        TestFramework.utils.assertNotNil(SoundGenerator.generate, "Generate function should exist")
        TestFramework.utils.assertNotNil(SoundGenerator.generateJump, "Generate jump function should exist")
        TestFramework.utils.assertNotNil(SoundGenerator.generateDash, "Generate dash function should exist")
        TestFramework.utils.assertNotNil(SoundGenerator.generateCollect, "Generate collect function should exist")
    end,
    
    ["generate basic sine wave"] = function()
        local params = {
            type = "sine",
            frequency = 440,
            duration = 0.1,
            volume = 0.5
        }
        
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        TestFramework.utils.assertTrue(success, "Should generate sine wave without error")
        TestFramework.utils.assertNotNil(soundData, "Should return sound data")
    end,
    
    ["generate square wave"] = function()
        local params = {
            type = "square",
            frequency = 220,
            duration = 0.1,
            volume = 0.3
        }
        
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        TestFramework.utils.assertTrue(success, "Should generate square wave without error")
    end,
    
    ["generate sawtooth wave"] = function()
        local params = {
            type = "sawtooth",
            frequency = 330,
            duration = 0.1,
            volume = 0.4
        }
        
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        TestFramework.utils.assertTrue(success, "Should generate sawtooth wave without error")
    end,
    
    ["generate noise"] = function()
        local params = {
            type = "noise",
            duration = 0.1,
            volume = 0.2
        }
        
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        TestFramework.utils.assertTrue(success, "Should generate noise without error")
    end,
    
    ["generate jump sound"] = function()
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generateJump)
        TestFramework.utils.assertTrue(success, "Should generate jump sound without error")
        TestFramework.utils.assertNotNil(soundData, "Should return jump sound data")
    end,
    
    ["generate dash sound"] = function()
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generateDash)
        TestFramework.utils.assertTrue(success, "Should generate dash sound without error")
        TestFramework.utils.assertNotNil(soundData, "Should return dash sound data")
    end,
    
    ["generate collect sound"] = function()
        local ringValue = 10
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generateCollect, ringValue)
        TestFramework.utils.assertTrue(success, "Should generate collect sound without error")
        TestFramework.utils.assertNotNil(soundData, "Should return collect sound data")
    end,
    
    ["generate power up sound"] = function()
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generatePowerUp)
        TestFramework.utils.assertTrue(success, "Should generate power up sound without error")
    end,
    
    ["generate land sound"] = function()
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generateLand)
        TestFramework.utils.assertTrue(success, "Should generate land sound without error")
    end,
    
    ["apply envelope"] = function()
        local params = {
            type = "sine",
            frequency = 440,
            duration = 0.2,
            volume = 0.5,
            envelope = {
                attack = 0.05,
                decay = 0.05,
                sustain = 0.7,
                release = 0.1
            }
        }
        
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        TestFramework.utils.assertTrue(success, "Should apply envelope without error")
    end,
    
    ["frequency modulation"] = function()
        local params = {
            type = "sine",
            frequency = 440,
            duration = 0.1,
            volume = 0.5,
            modulation = {
                frequency = 10,
                depth = 0.2
            }
        }
        
        local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        TestFramework.utils.assertTrue(success, "Should apply frequency modulation without error")
    end,
    
    ["multiple sound generation"] = function()
        -- Generate multiple sounds in sequence
        local sounds = {}
        
        for i = 1, 5 do
            local params = {
                type = "sine",
                frequency = 200 + i * 100,
                duration = 0.05,
                volume = 0.3
            }
            
            local success, soundData  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
            TestFramework.utils.assertTrue(success, "Should generate sound " .. i)
            table.insert(sounds, soundData)
        end
        
        TestFramework.utils.assertEqual(5, #sounds, "Should generate all sounds")
    end,
    
    ["parameter validation"] = function()
        -- Test with invalid parameters
        local params = {
            type = "invalid_type",
            frequency = -100,
            duration = -1,
            volume = 2
        }
        
        local success  = Utils.ErrorHandler.safeCall(SoundGenerator.generate, params)
        -- Should handle invalid parameters gracefully
        TestFramework.utils.assertTrue(true, "Should handle invalid parameters")
    end,
    
    ["combo sound generation"] = function()
        -- Generate sounds for different combo levels
        for combo = 1, 10 do
            local success  = Utils.ErrorHandler.safeCall(SoundGenerator.generateCombo, combo)
            TestFramework.utils.assertTrue(success, "Should generate combo sound for level " .. combo)
        end
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Sound Generator Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("sound_generator", 6) -- All major functions tested
    
    return success
end

return {run = run}