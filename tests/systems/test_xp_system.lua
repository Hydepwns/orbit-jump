-- Test suite for XP System
-- Tests experience gain, level progression, rewards, and visual feedback
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()
TestFramework.init()

-- Load system
local XPSystem = Utils.require("src.systems.xp_system")

-- Mock Love2D filesystem for save/load testing
local mockFileData = {}
love.filesystem = love.filesystem or {}
love.filesystem.write = function(filename, data)
    mockFileData[filename] = data
    return true
end
love.filesystem.read = function(filename)
    return mockFileData[filename]
end
love.filesystem.getInfo = function(filename)
    return mockFileData[filename] and {type = "file"} or nil
end

-- Mock Love2D timer
love.timer = love.timer or {}
love.timer.getTime = function()
    return 0
end

-- Mock math.pow if not available (Lua 5.1 compatibility)
math.pow = math.pow or function(x, y)
    return x ^ y
end

-- Mock Utils serialize/deserialize
Utils.serialize = function(data)
    return TestFramework.serialize(data)
end
Utils.deserialize = function(str)
    local fn = loadstring("return " .. str)
    return fn and fn() or nil
end

-- Test helper functions
local function setupSystem()
    -- Reset XP system state
    XPSystem.currentXP = 0
    XPSystem.currentLevel = 1
    XPSystem.xpToNextLevel = 100
    XPSystem.totalXP = 0
    XPSystem.unlockedRewards = {}
    XPSystem.availableRewards = {}
    XPSystem.xpGainAnimation = {}
    XPSystem.levelUpAnimation = {}
    XPSystem.barPulsePhase = 0
    
    -- Clear mock file data
    mockFileData = {}
end

-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        local success = XPSystem.init()
        
        TestFramework.assert.isTrue(success, "Init should return true")
        TestFramework.assert.equal(1, XPSystem.currentLevel, "Should start at level 1")
        TestFramework.assert.equal(0, XPSystem.currentXP, "Should start with 0 XP")
        TestFramework.assert.equal(100, XPSystem.xpToNextLevel, "Level 1 should require 100 XP")
        TestFramework.assert.isTrue(type(XPSystem.unlockedRewards) == "table", "Unlocked rewards should be initialized")
        TestFramework.assert.isTrue(type(XPSystem.availableRewards) == "table", "Available rewards should be initialized")
    end,
    
    ["add XP basic"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.addXP(50, "test", 0, 0)
        
        TestFramework.assert.equal(50, XPSystem.currentXP, "Should have 50 XP")
        TestFramework.assert.equal(50, XPSystem.totalXP, "Total XP should be 50")
        TestFramework.assert.equal(1, XPSystem.currentLevel, "Should still be level 1")
    end,
    
    ["add XP triggers level up"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.addXP(100, "test", 0, 0)
        
        TestFramework.assert.equal(2, XPSystem.currentLevel, "Should be level 2")
        TestFramework.assert.equal(0, XPSystem.currentXP, "XP should reset to 0")
        TestFramework.assert.equal(100, XPSystem.totalXP, "Total XP should be 100")
    end,
    
    ["add XP overflow"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.addXP(150, "test", 0, 0)
        
        TestFramework.assert.equal(2, XPSystem.currentLevel, "Should be level 2")
        TestFramework.assert.equal(50, XPSystem.currentXP, "Should have 50 overflow XP")
        TestFramework.assert.equal(150, XPSystem.totalXP, "Total XP should be 150")
    end,
    
    ["multiple level ups"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Enough XP for multiple levels
        XPSystem.addXP(300, "test", 0, 0)
        
        TestFramework.assert.isTrue(XPSystem.currentLevel >= 3, "Should be at least level 3")
        TestFramework.assert.equal(300, XPSystem.totalXP, "Total XP should be 300")
    end,
    
    ["XP requirement scaling"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Level 1: 100 XP
        local level1XP = XPSystem.xpToNextLevel
        TestFramework.assert.equal(100, level1XP, "Level 1 should require 100 XP")
        
        -- Level up and check scaling
        XPSystem.currentLevel = 2
        XPSystem.calculateXPToNextLevel()
        local level2XP = XPSystem.xpToNextLevel
        TestFramework.assert.equal(115, level2XP, "Level 2 should require 115 XP (15% increase)")
        
        -- Check level 5
        XPSystem.currentLevel = 5
        XPSystem.calculateXPToNextLevel()
        local level5XP = XPSystem.xpToNextLevel
        TestFramework.assert.isTrue(level5XP > 150, "Level 5 should require more XP")
    end,
    
    ["level rewards at specific levels"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Check level 3 reward exists
        local level3Reward = XPSystem.LEVEL_REWARDS[3]
        TestFramework.assert.isTrue(level3Reward ~= nil, "Level 3 should have a reward")
        TestFramework.assert.equal("ability", level3Reward.type, "Level 3 reward should be ability")
        TestFramework.assert.equal("Double Jump", level3Reward.name, "Level 3 reward should be Double Jump")
        
        -- Check level 10 reward
        local level10Reward = XPSystem.LEVEL_REWARDS[10]
        TestFramework.assert.isTrue(level10Reward ~= nil, "Level 10 should have a reward")
        TestFramework.assert.equal("cosmetic", level10Reward.type, "Level 10 reward should be cosmetic")
    end,
    
    ["unlock reward on level up"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Level up to 3 (which has a reward)
        XPSystem.currentLevel = 2
        XPSystem.currentXP = 114 -- Almost level 3
        XPSystem.calculateXPToNextLevel()
        
        local unlockedBefore = #XPSystem.unlockedRewards
        
        -- Add XP to trigger level 3
        XPSystem.addXP(10, "test", 0, 0)
        
        TestFramework.assert.equal(3, XPSystem.currentLevel, "Should be level 3")
        TestFramework.assert.equal(unlockedBefore + 1, #XPSystem.unlockedRewards, "Should unlock reward")
        
        local latestUnlock = XPSystem.unlockedRewards[#XPSystem.unlockedRewards]
        TestFramework.assert.equal("Double Jump", latestUnlock.reward.name, "Should unlock Double Jump")
    end,
    
    ["check available rewards"] = function()
        setupSystem()
        XPSystem.init()
        XPSystem.currentLevel = 2
        
        XPSystem.checkAvailableRewards()
        
        TestFramework.assert.isTrue(#XPSystem.availableRewards > 0, "Should have available rewards")
        
        -- Check first available reward
        local firstAvailable = XPSystem.availableRewards[1]
        TestFramework.assert.equal(3, firstAvailable.level, "First available should be level 3")
        TestFramework.assert.isTrue(firstAvailable.reward ~= nil, "Should have reward data")
        TestFramework.assert.isTrue(firstAvailable.xpNeeded > 0, "Should show XP needed")
    end,
    
    ["calculate XP needed for future level"] = function()
        setupSystem()
        XPSystem.init()
        XPSystem.currentLevel = 1
        XPSystem.currentXP = 25
        
        -- Calculate XP needed for level 3
        local xpNeeded = XPSystem.calculateXPNeededForLevel(3)
        
        -- Need: 75 to finish level 1, plus 115 for level 2
        TestFramework.assert.equal(75 + 115, xpNeeded, "Should calculate correct XP needed")
    end,
    
    ["XP animations created"] = function()
        setupSystem()
        XPSystem.init()
        
        TestFramework.assert.equal(0, #XPSystem.xpGainAnimation, "Should start with no animations")
        
        XPSystem.addXP(50, "ring_collect", 100, 200)
        
        TestFramework.assert.equal(1, #XPSystem.xpGainAnimation, "Should create animation")
        
        local anim = XPSystem.xpGainAnimation[1]
        TestFramework.assert.equal(50, anim.amount, "Animation should show amount")
        TestFramework.assert.equal("ring_collect", anim.source, "Animation should show source")
        TestFramework.assert.equal(100, anim.x, "Animation should have x position")
        TestFramework.assert.equal(200, anim.y, "Animation should have y position")
    end,
    
    ["level up animation created"] = function()
        setupSystem()
        XPSystem.init()
        
        TestFramework.assert.equal(0, #XPSystem.levelUpAnimation, "Should start with no animations")
        
        -- Trigger level up
        XPSystem.addXP(100, "test", 0, 0)
        
        TestFramework.assert.equal(1, #XPSystem.levelUpAnimation, "Should create level up animation")
        
        local anim = XPSystem.levelUpAnimation[1]
        TestFramework.assert.equal(2, anim.level, "Animation should show new level")
    end,
    
    ["animation update"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Create animations
        XPSystem.addXP(50, "test", 0, 0)
        
        local anim = XPSystem.xpGainAnimation[1]
        local initialY = anim.y
        
        -- Update animations
        XPSystem.update(0.1)
        
        TestFramework.assert.isTrue(anim.y < initialY, "Animation should float upward")
        TestFramework.assert.isTrue(anim.timer > 0, "Timer should advance")
        TestFramework.assert.isTrue(anim.alpha < 1.0, "Alpha should decrease")
    end,
    
    ["animation cleanup"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Create animation with short duration
        XPSystem.xpGainAnimation = {{
            timer = 0,
            duration = 0.5,
            y = 100,
            alpha = 1.0
        }}
        
        -- Update past duration
        XPSystem.update(0.6)
        
        TestFramework.assert.equal(0, #XPSystem.xpGainAnimation, "Animation should be removed")
    end,
    
    ["XP source colors"] = function()
        setupSystem()
        
        local ringColor = XPSystem.getXPSourceColor("ring_collect")
        TestFramework.assert.equal(0, ringColor[1], "Ring collect R should be 0")
        TestFramework.assert.equal(1, ringColor[2], "Ring collect G should be 1")
        TestFramework.assert.equal(1, ringColor[3], "Ring collect B should be 1")
        
        local perfectColor = XPSystem.getXPSourceColor("perfect_landing")
        TestFramework.assert.equal(1, perfectColor[1], "Perfect landing R should be 1")
        TestFramework.assert.equal(1, perfectColor[2], "Perfect landing G should be 1")
        TestFramework.assert.equal(0, perfectColor[3], "Perfect landing B should be 0")
        
        local unknownColor = XPSystem.getXPSourceColor("unknown_source")
        TestFramework.assert.equal(1, unknownColor[1], "Unknown R should be 1")
        TestFramework.assert.equal(1, unknownColor[2], "Unknown G should be 1")
        TestFramework.assert.equal(1, unknownColor[3], "Unknown B should be 1")
    end,
    
    ["helper XP functions"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.giveRingXP(0, 0)
        TestFramework.assert.equal(2, XPSystem.currentXP, "Ring should give 2 XP")
        
        XPSystem.givePerfectLandingXP(0, 0)
        TestFramework.assert.equal(7, XPSystem.currentXP, "Perfect landing should give 5 XP")
        
        XPSystem.giveComboXP(3, 0, 0)
        TestFramework.assert.equal(19, XPSystem.currentXP, "3x combo should give 12 XP")
        
        XPSystem.giveDiscoveryXP(0, 0)
        TestFramework.assert.equal(44, XPSystem.currentXP, "Discovery should give 25 XP")
        
        XPSystem.giveStreakMilestoneXP(5, 0, 0)
        TestFramework.assert.equal(94, XPSystem.currentXP, "5 streak milestone should give 50 XP")
    end,
    
    ["save and load progress"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Build some progress
        XPSystem.currentLevel = 5
        XPSystem.currentXP = 75
        XPSystem.totalXP = 500
        XPSystem.unlockedRewards = {{
            level = 3,
            reward = {name = "Test Reward"},
            unlockTime = 0
        }}
        
        -- Save
        XPSystem.saveProgress()
        
        -- Reset and load
        setupSystem()
        XPSystem.loadProgress()
        
        TestFramework.assert.equal(5, XPSystem.currentLevel, "Level should persist")
        TestFramework.assert.equal(75, XPSystem.currentXP, "Current XP should persist")
        TestFramework.assert.equal(500, XPSystem.totalXP, "Total XP should persist")
        TestFramework.assert.equal(1, #XPSystem.unlockedRewards, "Unlocked rewards should persist")
    end,
    
    ["load missing save data"] = function()
        setupSystem()
        mockFileData = {} -- Clear save data
        
        XPSystem.loadProgress()
        
        TestFramework.assert.equal(0, XPSystem.currentXP, "Should default to 0 XP")
        TestFramework.assert.equal(1, XPSystem.currentLevel, "Should default to level 1")
    end,
    
    ["getter functions"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.currentLevel = 7
        XPSystem.currentXP = 123
        XPSystem.xpToNextLevel = 200
        XPSystem.totalXP = 999
        
        TestFramework.assert.equal(7, XPSystem.getCurrentLevel(), "Should return current level")
        TestFramework.assert.equal(123, XPSystem.getCurrentXP(), "Should return current XP")
        TestFramework.assert.equal(200, XPSystem.getXPToNextLevel(), "Should return XP to next level")
        TestFramework.assert.equal(999, XPSystem.getTotalXP(), "Should return total XP")
    end,
    
    ["has unlocked reward"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.unlockedRewards = {
            {reward = {name = "Double Jump"}},
            {reward = {name = "Blue Trail"}}
        }
        
        TestFramework.assert.isTrue(XPSystem.hasUnlockedReward("Double Jump"), "Should have Double Jump")
        TestFramework.assert.isTrue(XPSystem.hasUnlockedReward("Blue Trail"), "Should have Blue Trail")
        TestFramework.assert.isFalse(XPSystem.hasUnlockedReward("Gold Trail"), "Should not have Gold Trail")
    end,
    
    ["negative XP protection"] = function()
        setupSystem()
        XPSystem.init()
        
        XPSystem.currentXP = 50
        XPSystem.addXP(-100, "test", 0, 0) -- Try to add negative XP
        
        TestFramework.assert.equal(50, XPSystem.currentXP, "Should not decrease XP")
    end,
    
    ["prestige multiplier integration"] = function()
        setupSystem()
        XPSystem.init()
        
        -- Mock prestige system
        local mockPrestige = {
            getXPMultiplier = function() return 2.0 end
        }
        package.loaded["src.systems.prestige_system"] = mockPrestige
        
        XPSystem.addXP(50, "test", 0, 0)
        
        TestFramework.assert.equal(100, XPSystem.currentXP, "Should apply 2x multiplier")
        
        -- Cleanup
        package.loaded["src.systems.prestige_system"] = nil
    end,
    
    ["visual effect timers"] = function()
        setupSystem()
        XPSystem.init()
        
        local initialPhase = XPSystem.barPulsePhase
        
        XPSystem.update(1.0)
        
        TestFramework.assert.isTrue(XPSystem.barPulsePhase > initialPhase, "Bar pulse should animate")
    end,
    
    ["reward type distribution"] = function()
        setupSystem()
        
        local abilityCount = 0
        local cosmeticCount = 0
        
        for level, reward in pairs(XPSystem.LEVEL_REWARDS) do
            if reward.type == "ability" then
                abilityCount = abilityCount + 1
            elseif reward.type == "cosmetic" then
                cosmeticCount = cosmeticCount + 1
            end
        end
        
        TestFramework.assert.isTrue(abilityCount > 0, "Should have ability rewards")
        TestFramework.assert.isTrue(cosmeticCount > 0, "Should have cosmetic rewards")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "XP System Tests")
end

return {run = run}