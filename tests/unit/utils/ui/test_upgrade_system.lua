-- Tests for Upgrade System
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Function to get UpgradeSystem with proper initialization
local function getUpgradeSystem()
    -- Clear any cached version
    package.loaded["src.systems.upgrade_system"] = nil
    package.loaded["src/systems/upgrade_system"] = nil
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.upgrade_system"] = nil
    end
    -- Setup mocks before loading
    Mocks.setup()
    -- Load fresh instance using regular require to bypass cache
    local UpgradeSystem = require("src.systems.upgrade_system")
    -- Ensure it's initialized
    if UpgradeSystem and UpgradeSystem.init then
        UpgradeSystem.init()
    end
    return UpgradeSystem
end
-- Reset function to ensure clean state between tests
local function resetUpgradeSystem(UpgradeSystem)
    if not UpgradeSystem then return end
    if UpgradeSystem.init then
        UpgradeSystem.init()
    end
    if UpgradeSystem.reset then
        UpgradeSystem.reset()
    end
    -- Ensure all upgrades start at level 0
    if UpgradeSystem.upgrades then
        for _, upgrade in pairs(UpgradeSystem.upgrades) do
            upgrade.currentLevel = 0
        end
    end
    if UpgradeSystem.playerUpgrades then
        for id, _ in pairs(UpgradeSystem.playerUpgrades) do
            UpgradeSystem.playerUpgrades[id] = 0
        end
    end
end
-- Test suite
local tests = {
    ["upgrade system initialization"] = function()
        local UpgradeSystem = getUpgradeSystem()
        TestFramework.assert.notNil(UpgradeSystem, "UpgradeSystem should load")
        TestFramework.assert.notNil(UpgradeSystem.upgrades, "Upgrades should be initialized")
        TestFramework.assert.notNil(UpgradeSystem.playerUpgrades, "Player upgrades should be initialized")
    end,
    ["upgrade definitions"] = function()
        local UpgradeSystem = getUpgradeSystem()
        -- Check core upgrades exist
        TestFramework.assert.notNil(UpgradeSystem.upgrades.jump_power, "Jump power upgrade should exist")
        TestFramework.assert.notNil(UpgradeSystem.upgrades.dash_cooldown, "Dash cooldown upgrade should exist")
        TestFramework.assert.notNil(UpgradeSystem.upgrades.ring_magnet, "Ring magnet upgrade should exist")
        TestFramework.assert.notNil(UpgradeSystem.upgrades.combo_multiplier, "Combo multiplier upgrade should exist")
    end,
    ["upgrade properties"] = function()
        local UpgradeSystem = getUpgradeSystem()
        local jumpPower = UpgradeSystem.upgrades.jump_power
        TestFramework.assert.equal("Jump Power", jumpPower.name, "Upgrade should have correct name")
        TestFramework.assert.notNil(jumpPower.description, "Upgrade should have description")
        TestFramework.assert.equal(5, jumpPower.maxLevel, "Upgrade should have max level")
        TestFramework.assert.notNil(jumpPower.baseCost, "Upgrade should have base cost")
        TestFramework.assert.notNil(jumpPower.effect, "Upgrade should have effect function")
    end,
    ["get upgrade level"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        local level = UpgradeSystem.getLevel("jump_power")
        TestFramework.assert.equal(0, level, "Upgrade should start at level 0")
        UpgradeSystem.playerUpgrades.jump_power = 3
        level = UpgradeSystem.getLevel("jump_power")
        TestFramework.assert.equal(3, level, "Upgrade level should match stored value")
    end,
    ["calculate upgrade cost"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        -- Level 0 to 1 cost
        local cost = UpgradeSystem.getCost("jump_power")
        local expected = UpgradeSystem.upgrades.jump_power.baseCost
        TestFramework.assert.equal(expected, cost, "First upgrade should cost base amount")
        -- Higher level cost
        UpgradeSystem.playerUpgrades.jump_power = 2
        cost = UpgradeSystem.getCost("jump_power")
        TestFramework.assert.isTrue(cost > expected, "Higher level upgrades should cost more")
    end,
    ["can afford upgrade"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        local cost = UpgradeSystem.getCost("jump_power")
        -- Not enough currency
        local canAfford = UpgradeSystem.canAfford("jump_power", cost - 10)
        TestFramework.assert.isFalse(canAfford, "Should not afford with insufficient currency")
        -- Exactly enough
        canAfford = UpgradeSystem.canAfford("jump_power", cost)
        TestFramework.assert.isTrue(canAfford, "Should afford with exact amount")
        -- More than enough
        canAfford = UpgradeSystem.canAfford("jump_power", cost + 100)
        TestFramework.assert.isTrue(canAfford, "Should afford with excess currency")
    end,
    ["purchase upgrade"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        local initialLevel = UpgradeSystem.getLevel("jump_power")
        local cost = UpgradeSystem.getCost("jump_power")
        local success = UpgradeSystem.purchase("jump_power", cost)
        TestFramework.assert.isTrue(success, "Purchase should succeed with enough currency")
        TestFramework.assert.equal(initialLevel + 1, UpgradeSystem.getLevel("jump_power"), "Level should increase")
    end,
    ["purchase upgrade at max level"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        -- Set to max level
        UpgradeSystem.playerUpgrades.jump_power = UpgradeSystem.upgrades.jump_power.maxLevel
        local success = UpgradeSystem.purchase("jump_power", 99999)
        TestFramework.assert.isFalse(success, "Should not purchase at max level")
    end,
    ["get upgrade effect"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        -- Level 0 effect
        local effect = UpgradeSystem.getEffect("jump_power")
        TestFramework.assert.equal(1.0, effect, "Level 0 should have base effect")
        -- Level 3 effect
        UpgradeSystem.playerUpgrades.jump_power = 3
        effect = UpgradeSystem.getEffect("jump_power")
        TestFramework.assert.isTrue(effect > 1.0, "Higher levels should have stronger effect")
    end,
    ["apply all upgrade effects"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
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
        TestFramework.assert.isTrue(player.jumpPower > 300, "Jump power should be increased")
        TestFramework.assert.isTrue(player.dashCooldown < 1.0, "Dash cooldown should be reduced")
        TestFramework.assert.isTrue(player.gravityMultiplier < 1.0, "Gravity should be reduced")
    end,
    ["save and load upgrades"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        -- Set some upgrades
        UpgradeSystem.playerUpgrades = {
            jump_power = 3,
            ring_magnet = 2,
            combo_multiplier = 1
        }
        -- Save
        local saveData = UpgradeSystem.getSaveData()
        TestFramework.assert.notNil(saveData, "Should return save data")
        -- Reset and load
        UpgradeSystem.playerUpgrades = {}
        UpgradeSystem.loadSaveData(saveData)
        TestFramework.assert.equal(3, UpgradeSystem.getLevel("jump_power"), "Jump power should be restored")
        TestFramework.assert.equal(2, UpgradeSystem.getLevel("ring_magnet"), "Ring magnet should be restored")
        TestFramework.assert.equal(1, UpgradeSystem.getLevel("combo_multiplier"), "Combo multiplier should be restored")
    end,
    ["get total upgrades purchased"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        UpgradeSystem.playerUpgrades = {
            jump_power = 3,
            dash_cooldown = 2,
            ring_magnet = 1
        }
        local total = UpgradeSystem.getTotalUpgrades()
        TestFramework.assert.equal(6, total, "Should count all upgrade levels")
    end,
    ["reset all upgrades"] = function()
        local UpgradeSystem = getUpgradeSystem()
        resetUpgradeSystem(UpgradeSystem)
        UpgradeSystem.playerUpgrades = {
            jump_power = 5,
            dash_cooldown = 3
        }
        UpgradeSystem.reset()
        TestFramework.assert.equal(0, UpgradeSystem.getLevel("jump_power"), "Jump power should be reset")
        TestFramework.assert.equal(0, UpgradeSystem.getLevel("dash_cooldown"), "Dash cooldown should be reset")
    end,
}
local function run()
    -- Initialize test framework
    Mocks.setup()
    TestFramework.init()
    local success = TestFramework.runTests(tests, "Upgrade System Tests")
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("upgrade_system", 12) -- All major functions tested
    return success
end
return {run = run}