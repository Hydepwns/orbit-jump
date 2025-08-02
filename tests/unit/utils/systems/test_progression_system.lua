-- Tests for Progression System
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Function to get ProgressionSystem with proper initialization
local function getProgressionSystem()
    -- Clear any cached version
    package.loaded["src.systems.progression_system"] = nil
    package.loaded["src/systems/progression_system"] = nil
    
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.progression_system"] = nil
    end
    
    -- Setup mocks before loading
    Mocks.setup()
    
    -- Load fresh instance using regular require
    local ProgressionSystem = require("src.systems.progression_system")
    
    -- Ensure it's initialized
    if ProgressionSystem and ProgressionSystem.init then
        ProgressionSystem.init()
    end
    
    return ProgressionSystem
end

-- Get initial instance for testing
local ProgressionSystem = getProgressionSystem()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test system initialization
    ["system initialization"] = function()
        ProgressionSystem.init()
        
        TestFramework.assert.assertNotNil(ProgressionSystem.data, "Data should be initialized")
        TestFramework.assert.assertNotNil(ProgressionSystem.data.totalScore, "Total score should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.data.totalRingsCollected, "Total rings should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.data.achievements, "Achievements should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.data.upgrades, "Upgrades should exist")
    end,
    
    -- Test achievement definitions
    ["achievement definitions"] = function()
        TestFramework.assert.assertNotNil(ProgressionSystem.achievements.firstRing, "First ring achievement should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.achievements.comboMaster, "Combo master achievement should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.achievements.speedDemon, "Speed demon achievement should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.achievements.ringCollector, "Ring collector achievement should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.achievements.gravityDefier, "Gravity defier achievement should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.achievements.planetHopper, "Planet hopper achievement should exist")
    end,
    
    ["achievement properties"] = function()
        -- Reset achievement state to ensure clean test
        ProgressionSystem.achievements.firstRing.unlocked = false
        ProgressionSystem.achievements.comboMaster.unlocked = false
        
        local firstRing = ProgressionSystem.achievements.firstRing
        TestFramework.assert.assertEqual("First Ring", firstRing.name, "Achievement should have correct name")
        TestFramework.assert.assertEqual("Collect your first ring", firstRing.description, "Achievement should have description")
        TestFramework.assert.assertEqual(10, firstRing.score, "Achievement should have correct score")
        TestFramework.assert.assertFalse(firstRing.unlocked, "Achievement should start locked")
        
        local comboMaster = ProgressionSystem.achievements.comboMaster
        TestFramework.assert.assertEqual("Combo Master", comboMaster.name, "Achievement should have correct name")
        TestFramework.assert.assertEqual(50, comboMaster.score, "Achievement should have correct score")
    end,
    
    -- Test upgrade definitions
    ["upgrade definitions"] = function()
        TestFramework.assert.assertNotNil(ProgressionSystem.upgradeCosts.jumpPower, "Jump power upgrade should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.upgradeCosts.dashPower, "Dash power upgrade should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.upgradeCosts.speedBoost, "Speed boost upgrade should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.upgradeCosts.ringValue, "Ring value upgrade should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.upgradeCosts.comboMultiplier, "Combo multiplier upgrade should exist")
        TestFramework.assert.assertNotNil(ProgressionSystem.upgradeCosts.gravityResistance, "Gravity resistance upgrade should exist")
    end,
    
    ["upgrade cost properties"] = function()
        local jumpPower = ProgressionSystem.upgradeCosts.jumpPower
        TestFramework.assert.assertEqual(100, jumpPower.base, "Upgrade should have correct base cost")
        TestFramework.assert.assertEqual(1.5, jumpPower.multiplier, "Upgrade should have correct multiplier")
        
        local dashPower = ProgressionSystem.upgradeCosts.dashPower
        TestFramework.assert.assertEqual(150, dashPower.base, "Upgrade should have correct base cost")
        TestFramework.assert.assertEqual(1.8, dashPower.multiplier, "Upgrade should have correct multiplier")
    end,
    
    -- Test score tracking
    ["score tracking"] = function()
        ProgressionSystem.init()
        local initialScore = ProgressionSystem.data.totalScore
        
        ProgressionSystem.addScore(100)
        TestFramework.assert.assertEqual(initialScore + 100, ProgressionSystem.data.totalScore, "Score should increase")
        
        ProgressionSystem.addScore(50)
        TestFramework.assert.assertEqual(initialScore + 150, ProgressionSystem.data.totalScore, "Score should increase again")
    end,
    
    ["ring collection tracking"] = function()
        ProgressionSystem.init()
        local initialRings = ProgressionSystem.data.totalRingsCollected
        
        ProgressionSystem.addRings(5)
        TestFramework.assert.assertEqual(initialRings + 5, ProgressionSystem.data.totalRingsCollected, "Ring count should increase")
        
        ProgressionSystem.addRings(10)
        TestFramework.assert.assertEqual(initialRings + 15, ProgressionSystem.data.totalRingsCollected, "Ring count should increase again")
    end,
    
    ["jump tracking"] = function()
        ProgressionSystem.init()
        local initialJumps = ProgressionSystem.data.totalJumps
        
        ProgressionSystem.addJump()
        TestFramework.assert.assertEqual(initialJumps + 1, ProgressionSystem.data.totalJumps, "Jump count should increase")
        
        ProgressionSystem.addJump()
        ProgressionSystem.addJump()
        TestFramework.assert.assertEqual(initialJumps + 3, ProgressionSystem.data.totalJumps, "Jump count should increase multiple times")
    end,
    
    ["play time tracking"] = function()
        ProgressionSystem.init()
        local initialTime = ProgressionSystem.data.totalPlayTime
        
        ProgressionSystem.updatePlayTime(1.5)
        TestFramework.assert.assertEqual(initialTime + 1.5, ProgressionSystem.data.totalPlayTime, "Play time should increase")
        
        ProgressionSystem.updatePlayTime(0.5)
        TestFramework.assert.assertEqual(initialTime + 2.0, ProgressionSystem.data.totalPlayTime, "Play time should increase again")
    end,
    
    -- Test achievement unlocking
    ["achievement unlocking"] = function()
        ProgressionSystem.init()
        
        -- Reset achievement state
        ProgressionSystem.achievements.firstRing.unlocked = false
        ProgressionSystem.achievements.ringCollector.unlocked = false
        
        -- Unlock first ring achievement
        ProgressionSystem.unlockAchievement("firstRing")
        TestFramework.assert.assertTrue(ProgressionSystem.achievements.firstRing.unlocked, "First ring achievement should be unlocked")
        
        -- Unlock ring collector achievement
        ProgressionSystem.unlockAchievement("ringCollector")
        TestFramework.assert.assertTrue(ProgressionSystem.achievements.ringCollector.unlocked, "Ring collector achievement should be unlocked")
    end,
    
    ["achievement score addition"] = function()
        ProgressionSystem.init()
        local initialScore = ProgressionSystem.data.totalScore
        
        -- Reset achievement state
        ProgressionSystem.achievements.firstRing.unlocked = false
        ProgressionSystem.achievements.comboMaster.unlocked = false
        
        -- Unlock achievements and check score
        ProgressionSystem.unlockAchievement("firstRing")
        TestFramework.assert.assertEqual(initialScore + 10, ProgressionSystem.data.totalScore, "Score should increase by achievement value")
        
        ProgressionSystem.unlockAchievement("comboMaster")
        TestFramework.assert.assertEqual(initialScore + 60, ProgressionSystem.data.totalScore, "Score should increase by both achievement values")
    end,
    
    -- Test upgrade mechanics
    ["upgrade cost calculation"] = function()
        ProgressionSystem.init()
        
        -- Reset upgrade levels
        ProgressionSystem.data.upgrades.jumpPower = 1
        ProgressionSystem.data.upgrades.dashPower = 1
        
        local jumpCost = ProgressionSystem.getUpgradeCost("jumpPower")
        TestFramework.assert.assertEqual(100, jumpCost, "First level upgrade should cost base amount")
        
        local dashCost = ProgressionSystem.getUpgradeCost("dashPower")
        TestFramework.assert.assertEqual(150, dashCost, "First level upgrade should cost base amount")
    end,
    
    ["upgrade cost scaling"] = function()
        ProgressionSystem.init()
        
        -- Set upgrade to level 2
        ProgressionSystem.data.upgrades.jumpPower = 2
        
        local cost = ProgressionSystem.getUpgradeCost("jumpPower")
        local expectedCost = math.floor(100 * (1.5 ^ 1)) -- Level 2 cost
        TestFramework.assert.assertEqual(expectedCost, cost, "Upgrade cost should scale with level")
    end,
    
    ["upgrade purchase"] = function()
        ProgressionSystem.init()
        
        -- Reset upgrade state
        ProgressionSystem.data.upgrades.jumpPower = 1
        ProgressionSystem.data.totalScore = 200 -- Give enough score to purchase
        
        local initialLevel = ProgressionSystem.data.upgrades.jumpPower
        local initialScore = ProgressionSystem.data.totalScore
        
        local success = ProgressionSystem.purchaseUpgrade("jumpPower")
        
        TestFramework.assert.assertTrue(success, "Upgrade purchase should succeed")
        TestFramework.assert.assertEqual(initialLevel + 1, ProgressionSystem.data.upgrades.jumpPower, "Upgrade level should increase")
        TestFramework.assert.assertTrue(ProgressionSystem.data.totalScore < initialScore, "Score should decrease after purchase")
    end,
    
    ["upgrade purchase insufficient score"] = function()
        ProgressionSystem.init()
        
        -- Reset upgrade state
        ProgressionSystem.data.upgrades.jumpPower = 1
        ProgressionSystem.data.totalScore = 50 -- Not enough score
        
        local initialLevel = ProgressionSystem.data.upgrades.jumpPower
        local initialScore = ProgressionSystem.data.totalScore
        
        local success = ProgressionSystem.purchaseUpgrade("jumpPower")
        
        TestFramework.assert.assertFalse(success, "Upgrade purchase should fail")
        TestFramework.assert.assertEqual(initialLevel, ProgressionSystem.data.upgrades.jumpPower, "Upgrade level should not change")
        TestFramework.assert.assertEqual(initialScore, ProgressionSystem.data.totalScore, "Score should not change")
    end,
    
    ["upgrade max level"] = function()
        ProgressionSystem.init()
        
        -- Set upgrade to max level
        ProgressionSystem.data.upgrades.jumpPower = 5
        ProgressionSystem.data.totalScore = 1000
        
        local success = ProgressionSystem.purchaseUpgrade("jumpPower")
        
        TestFramework.assert.assertFalse(success, "Upgrade purchase should fail at max level")
        TestFramework.assert.assertEqual(5, ProgressionSystem.data.upgrades.jumpPower, "Upgrade level should remain at max")
    end,
    
    -- Test upgrade effects
    ["upgrade effect calculation"] = function()
        ProgressionSystem.init()
        
        -- Test jump power effect
        ProgressionSystem.data.upgrades.jumpPower = 3
        local effect = ProgressionSystem.getUpgradeEffect("jumpPower")
        TestFramework.assert.assertEqual(3, effect, "Jump power effect should match level")
        
        -- Test dash power effect
        ProgressionSystem.data.upgrades.dashPower = 2
        local dashEffect = ProgressionSystem.getUpgradeEffect("dashPower")
        TestFramework.assert.assertEqual(2, dashEffect, "Dash power effect should match level")
    end,
    
    ["upgrade multiplier calculation"] = function()
        ProgressionSystem.init()
        
        -- Test ring value multiplier
        ProgressionSystem.data.upgrades.ringValue = 3
        local multiplier = ProgressionSystem.getUpgradeMultiplier("ringValue")
        TestFramework.assert.assertEqual(3, multiplier, "Ring value multiplier should match level")
        
        -- Test combo multiplier
        ProgressionSystem.data.upgrades.comboMultiplier = 2
        local comboMultiplier = ProgressionSystem.getUpgradeMultiplier("comboMultiplier")
        TestFramework.assert.assertEqual(2, comboMultiplier, "Combo multiplier should match level")
    end,
    
    -- Test data persistence
    ["data serialization"] = function()
        ProgressionSystem.init()
        
        -- Set some test data
        ProgressionSystem.data.totalScore = 1500
        ProgressionSystem.data.totalRingsCollected = 75
        ProgressionSystem.data.upgrades.jumpPower = 3
        
        local serialized = ProgressionSystem.serialize(ProgressionSystem.data)
        TestFramework.assert.assertNotNil(serialized, "Data should serialize")
        TestFramework.assert.assertTrue(type(serialized) == "string", "Serialized data should be string")
        TestFramework.assert.assertTrue(#serialized > 0, "Serialized data should not be empty")
    end,
    
    ["data deserialization"] = function()
        ProgressionSystem.init()
        
        -- Create test data
        local testData = {
            totalScore = 2000,
            totalRingsCollected = 100,
            upgrades = {
                jumpPower = 4,
                dashPower = 2
            }
        }
        
        local serialized = ProgressionSystem.serialize(testData)
        local deserialized = load("return " .. serialized)()
        
        TestFramework.assert.assertEqual(testData.totalScore, deserialized.totalScore, "Total score should deserialize correctly")
        TestFramework.assert.assertEqual(testData.totalRingsCollected, deserialized.totalRingsCollected, "Total rings should deserialize correctly")
        TestFramework.assert.assertEqual(testData.upgrades.jumpPower, deserialized.upgrades.jumpPower, "Upgrades should deserialize correctly")
    end,
    
    -- Test achievement checking
    ["achievement checking"] = function()
        ProgressionSystem.init()
        
        -- Reset achievement state
        ProgressionSystem.achievements.firstRing.unlocked = false
        ProgressionSystem.achievements.ringCollector.unlocked = false
        
        -- Add a ring to trigger first ring achievement
        ProgressionSystem.data.totalRingsCollected = 1
        
        -- Check achievements (should unlock first ring)
        ProgressionSystem.checkAchievements()
        
        TestFramework.assert.assertTrue(ProgressionSystem.achievements.firstRing.unlocked, "First ring should be unlocked automatically")
        TestFramework.assert.assertFalse(ProgressionSystem.achievements.ringCollector.unlocked, "Ring collector should not be unlocked yet")
    end,
    
    -- Test game completion tracking
    ["game completion tracking"] = function()
        local ProgressionSystem = getProgressionSystem()
        local initialGames = ProgressionSystem.data.gamesPlayed
        
        ProgressionSystem.completeGame(500, 25, 8)
        
        TestFramework.assert.assertEqual(initialGames + 1, ProgressionSystem.data.gamesPlayed, "Games played should increase")
        TestFramework.assert.assertEqual(500, ProgressionSystem.data.totalScore, "Total score should be updated")
        TestFramework.assert.assertEqual(25, ProgressionSystem.data.totalRingsCollected, "Total rings should be updated")
        
        -- Check if highest combo was updated
        if 8 > ProgressionSystem.data.highestCombo then
            TestFramework.assert.assertEqual(8, ProgressionSystem.data.highestCombo, "Highest combo should be updated")
        end
    end,
    
    -- Test statistics
    ["statistics calculation"] = function()
        ProgressionSystem.init()
        
        -- Set some test data
        ProgressionSystem.data.totalScore = 5000
        ProgressionSystem.data.totalRingsCollected = 200
        ProgressionSystem.data.totalJumps = 100
        ProgressionSystem.data.totalPlayTime = 1800 -- 30 minutes
        ProgressionSystem.data.gamesPlayed = 10
        
        local stats = ProgressionSystem.getStatistics()
        
        TestFramework.assert.assertEqual(500, stats.averageScore, "Average score should be calculated correctly")
        TestFramework.assert.assertEqual(20, stats.averageRingsPerGame, "Average rings per game should be calculated correctly")
        TestFramework.assert.assertEqual(10, stats.averageJumpsPerGame, "Average jumps per game should be calculated correctly")
        TestFramework.assert.assertEqual(180, stats.averagePlayTimePerGame, "Average play time per game should be calculated correctly")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Progression System Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("progression_system", 20) -- All major functions tested
    
    return success
end

local result = {run = run}

-- Run tests if this file is executed directly
if arg and arg[0] and string.find(arg[0], "test_progression_system.lua") then
    run()
end

return result 