-- Tests for Upgrade System
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

Mocks.setup()

local UpgradeSystem = Utils.require("src.systems.upgrade_system")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["upgrade system initialization"] = function()
        UpgradeSystem.init()
        TestFramework.utils.assertNotNil(UpgradeSystem.upgrades, "Upgrades should be initialized")
        TestFramework.utils.assertNotNil(UpgradeSystem.playerUpgrades, "Player upgrades should be initialized")
    end,
    
    ["upgrade definitions"] = function()
        UpgradeSystem.init()
        
        -- Check core upgrades exist
        TestFramework.utils.assertNotNil(UpgradeSystem.upgrades.jump_power, "Jump power upgrade should exist")
        TestFramework.utils.assertNotNil(UpgradeSystem.upgrades.dash_cooldown, "Dash cooldown upgrade should exist")
        TestFramework.utils.assertNotNil(UpgradeSystem.upgrades.ring_magnet, "Ring magnet upgrade should exist")
        TestFramework.utils.assertNotNil(UpgradeSystem.upgrades.combo_multiplier, "Combo multiplier upgrade should exist")
    end,
    
    ["upgrade properties"] = function()
        UpgradeSystem.init()
        
        local jumpPower = UpgradeSystem.upgrades.jump_power
        TestFramework.utils.assertEqual("Jump Power", jumpPower.name, "Upgrade should have correct name")
        TestFramework.utils.assertNotNil(jumpPower.description, "Upgrade should have description")
        TestFramework.utils.assertEqual(5, jumpPower.maxLevel, "Upgrade should have max level")
        TestFramework.utils.assertNotNil(jumpPower.baseCost, "Upgrade should have base cost")
        TestFramework.utils.assertNotNil(jumpPower.effect, "Upgrade should have effect function")
    end,
    
    ["get upgrade level"] = function()
        UpgradeSystem.init()
        
        -- Reset player upgrades
        UpgradeSystem.playerUpgrades = {}
        
        local level = UpgradeSystem.getLevel("jump_power")
        TestFramework.utils.assertEqual(0, level, "Upgrade should start at level 0")
        
        UpgradeSystem.playerUpgrades.jump_power = 3
        level = UpgradeSystem.getLevel("jump_power")
        TestFramework.utils.assertEqual(3, level, "Upgrade level should match stored value")
    end,
    
    ["calculate upgrade cost"] = function()
        UpgradeSystem.init()
        UpgradeSystem.playerUpgrades = {}
        
        -- Level 0 to 1 cost
        local cost = UpgradeSystem.getCost("jump_power")
        local expected = UpgradeSystem.upgrades.jump_power.baseCost
        TestFramework.utils.assertEqual(expected, cost, "First upgrade should cost base amount")
        
        -- Higher level cost
        UpgradeSystem.playerUpgrades.jump_power = 2
        cost = UpgradeSystem.getCost("jump_power")
        TestFramework.utils.assertTrue(cost > expected, "Higher level upgrades should cost more")
    end,
    
    ["can afford upgrade"] = function()
        UpgradeSystem.init()
        UpgradeSystem.playerUpgrades = {}
        
        local cost = UpgradeSystem.getCost("jump_power")
        
        -- Not enough currency
        local canAfford = UpgradeSystem.canAfford("jump_power", cost - 10)
        TestFramework.utils.assertFalse(canAfford, "Should not afford with insufficient currency")
        
        -- Exactly enough
        canAfford = UpgradeSystem.canAfford("jump_power", cost)
        TestFramework.utils.assertTrue(canAfford, "Should afford with exact amount")
        
        -- More than enough
        canAfford = UpgradeSystem.canAfford("jump_power", cost + 100)
        TestFramework.utils.assertTrue(canAfford, "Should afford with excess currency")
    end,
    
    ["purchase upgrade"] = function()
        UpgradeSystem.init()
        UpgradeSystem.playerUpgrades = {}
        
        local initialLevel = UpgradeSystem.getLevel("jump_power")
        local cost = UpgradeSystem.getCost("jump_power")
        
        local success = UpgradeSystem.purchase("jump_power", cost)
        TestFramework.utils.assertTrue(success, "Purchase should succeed with enough currency")
        TestFramework.utils.assertEqual(initialLevel + 1, UpgradeSystem.getLevel("jump_power"), "Level should increase")
    end,
    
    ["purchase upgrade at max level"] = function()
        UpgradeSystem.init()
        
        -- Set to max level
        UpgradeSystem.playerUpgrades.jump_power = UpgradeSystem.upgrades.jump_power.maxLevel
        
        local success = UpgradeSystem.purchase("jump_power", 99999)
        TestFramework.utils.assertFalse(success, "Should not purchase at max level")
    end,
    
    ["get upgrade effect"] = function()
        UpgradeSystem.init()
        UpgradeSystem.playerUpgrades = {}
        
        -- Level 0 effect
        local effect = UpgradeSystem.getEffect("jump_power")
        TestFramework.utils.assertEqual(1.0, effect, "Level 0 should have base effect")
        
        -- Level 3 effect
        UpgradeSystem.playerUpgrades.jump_power = 3
        effect = UpgradeSystem.getEffect("jump_power")
        TestFramework.utils.assertTrue(effect > 1.0, "Higher levels should have stronger effect")
    end,
    
    ["apply all upgrade effects"] = function()
        UpgradeSystem.init()
        UpgradeSystem.playerUpgrades = {
            jump_power = 2,
            dash_cooldown = 1,
            gravity_resist = 3
        }
        
        local player = {
            jumpPower = 300,
            dashCooldown = 1.0,
            gravityMultiplier = 1.0
        }
        
        UpgradeSystem.applyEffects(player)
        
        TestFramework.utils.assertTrue(player.jumpPower > 300, "Jump power should be increased")
        TestFramework.utils.assertTrue(player.dashCooldown < 1.0, "Dash cooldown should be reduced")
        TestFramework.utils.assertTrue(player.gravityMultiplier < 1.0, "Gravity should be reduced")
    end,
    
    ["save and load upgrades"] = function()
        UpgradeSystem.init()
        
        -- Set some upgrades
        UpgradeSystem.playerUpgrades = {
            jump_power = 3,
            ring_magnet = 2,
            combo_multiplier = 1
        }
        
        -- Save
        local saveData = UpgradeSystem.getSaveData()
        TestFramework.utils.assertNotNil(saveData, "Should return save data")
        
        -- Reset and load
        UpgradeSystem.playerUpgrades = {}
        UpgradeSystem.loadSaveData(saveData)
        
        TestFramework.utils.assertEqual(3, UpgradeSystem.getLevel("jump_power"), "Jump power should be restored")
        TestFramework.utils.assertEqual(2, UpgradeSystem.getLevel("ring_magnet"), "Ring magnet should be restored")
        TestFramework.utils.assertEqual(1, UpgradeSystem.getLevel("combo_multiplier"), "Combo multiplier should be restored")
    end,
    
    ["get total upgrades purchased"] = function()
        UpgradeSystem.init()
        
        UpgradeSystem.playerUpgrades = {
            jump_power = 3,
            dash_cooldown = 2,
            ring_magnet = 1
        }
        
        local total = UpgradeSystem.getTotalUpgrades()
        TestFramework.utils.assertEqual(6, total, "Should count all upgrade levels")
    end,
    
    ["reset all upgrades"] = function()
        UpgradeSystem.init()
        
        UpgradeSystem.playerUpgrades = {
            jump_power = 5,
            dash_cooldown = 3
        }
        
        UpgradeSystem.reset()
        
        TestFramework.utils.assertEqual(0, UpgradeSystem.getLevel("jump_power"), "Jump power should be reset")
        TestFramework.utils.assertEqual(0, UpgradeSystem.getLevel("dash_cooldown"), "Dash cooldown should be reset")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Upgrade System Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("upgrade_system", 12) -- All major functions tested
    
    return success
end

return {run = run}