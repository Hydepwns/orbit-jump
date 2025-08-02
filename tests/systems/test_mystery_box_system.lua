-- Test suite for Mystery Box System
-- Tests box spawning, collection, rewards, and animations
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()
TestFramework.init()

-- Load system
local MysteryBoxSystem = Utils.require("src.systems.mystery_box_system")

-- Mock Love2D graphics and timer
love.graphics = love.graphics or {}
love.graphics.push = function() end
love.graphics.pop = function() end
love.graphics.translate = function() end
love.graphics.rotate = function() end
love.graphics.scale = function() end
love.graphics.setColor = function() end
love.graphics.setFont = function() end
love.graphics.circle = function() end
love.graphics.rectangle = function() end
love.graphics.print = function() end
love.graphics.getFont = function()
    return {
        getWidth = function() return 100 end
    }
end
love.graphics.getWidth = function() return 800 end
love.graphics.getHeight = function() return 600 end

love.timer = love.timer or {}
love.timer.getTime = function() return 0 end

-- Mock math.pow if not available (Lua 5.1 compatibility)
math.pow = math.pow or function(x, y)
    return x ^ y
end

-- Mock random for predictable testing
local mockRandomValues = {}
local mockRandomIndex = 1
local originalRandom = math.random

local function setMockRandom(values)
    mockRandomValues = values
    mockRandomIndex = 1
    math.random = function(...)
        local args = {...}
        local value = mockRandomValues[mockRandomIndex] or 0.5
        mockRandomIndex = mockRandomIndex + 1
        
        -- Handle math.random() with no args (0-1)
        if #args == 0 then
            return value
        -- Handle math.random(max) (1-max)
        elseif #args == 1 then
            return math.floor(value * args[1]) + 1
        -- Handle math.random(min, max) (min-max)
        elseif #args == 2 then
            return math.floor(value * (args[2] - args[1] + 1)) + args[1]
        end
        
        return value
    end
end

local function restoreRandom()
    math.random = originalRandom
end

-- Test helper functions
local function setupSystem()
    -- Create fresh system instance
    local system = {}
    for k, v in pairs(MysteryBoxSystem) do
        system[k] = v
    end
    
    -- Reset state
    system.boxes = {}
    system.spawn_chance = 0.02
    system.opening_animation = nil
    system.box_types = {}
    system.rewards = {}
    
    -- Mock game state
    system.game_state = {
        sound_system = {
            playBoxSpawn = function() end,
            playBoxCollect = function() end,
            playRewardSound = function() end
        },
        particle_system = {
            emit = function() end
        },
        progression_system = {
            unlockSkin = function() end,
            unlockLegendaryEffect = function() end
        },
        world_generator = {
            unlockPlanetType = function() end
        },
        player = {
            radius = 15,
            temp_cooldown_reduction = nil,
            cooldown_reduction_timer = nil,
            temp_magnet_range_boost = nil,
            magnet_boost_timer = nil
        }
    }
    
    -- Mock external systems
    package.loaded["src.systems.weekly_challenges_system"] = {
        onMysteryBoxOpened = function() end
    }
    package.loaded["src.systems.achievement_system"] = {
        onMysteryBoxOpened = function() end
    }
    package.loaded["src.systems.xp_system"] = {
        addTemporaryMultiplier = function() end
    }
    package.loaded["src.ui.ui_system"] = {
        showEventNotification = function() end
    }
    
    -- Initialize system
    system:init(system.game_state)
    
    return system
end

local function createMockPlanet(x, y, radius, id)
    return {
        x = x or 100,
        y = y or 100,
        radius = radius or 50,
        id = id or 1
    }
end

local function createMockPlayer(x, y, radius)
    return {
        x = x or 100,
        y = y or 100,
        radius = radius or 15
    }
end

-- Test suite
local tests = {
    ["initialization"] = function()
        local system = setupSystem()
        
        TestFramework.assert.isTrue(type(system.boxes) == "table", "Boxes should be initialized")
        TestFramework.assert.equal(0.02, system.spawn_chance, "Should have 2% spawn chance")
        TestFramework.assert.isTrue(system.opening_animation == nil, "Should start with no animation")
        
        -- Check box types are registered
        TestFramework.assert.isTrue(system.box_types.bronze ~= nil, "Bronze box type should exist")
        TestFramework.assert.isTrue(system.box_types.silver ~= nil, "Silver box type should exist")
        TestFramework.assert.isTrue(system.box_types.gold ~= nil, "Gold box type should exist")
        TestFramework.assert.isTrue(system.box_types.legendary ~= nil, "Legendary box type should exist")
        
        -- Check rewards are defined
        TestFramework.assert.isTrue(#system.rewards > 0, "Should have reward definitions")
    end,
    
    ["box type properties"] = function()
        local system = setupSystem()
        
        local bronze = system.box_types.bronze
        TestFramework.assert.equal(0.5, bronze.rarity, "Bronze should have 50% rarity weight")
        TestFramework.assert.equal(1, bronze.min_rewards, "Bronze should have min 1 reward")
        TestFramework.assert.equal(2, bronze.max_rewards, "Bronze should have max 2 rewards")
        
        local legendary = system.box_types.legendary
        TestFramework.assert.equal(0.03, legendary.rarity, "Legendary should have 3% rarity weight")
        TestFramework.assert.equal(3, legendary.min_rewards, "Legendary should have min 3 rewards")
        TestFramework.assert.equal(5, legendary.max_rewards, "Legendary should have max 5 rewards")
    end,
    
    ["reward definitions"] = function()
        local system = setupSystem()
        
        -- Check that rewards have required properties
        for _, reward in ipairs(system.rewards) do
            TestFramework.assert.isTrue(reward.type ~= nil, "Reward should have type")
            TestFramework.assert.isTrue(reward.name ~= nil, "Reward should have name")
            TestFramework.assert.isTrue(reward.rarity ~= nil, "Reward should have rarity")
            TestFramework.assert.isTrue(reward.description ~= nil, "Reward should have description")
        end
        
        -- Check specific reward types exist
        local hasXPMultiplier = false
        local hasRareSkin = false
        for _, reward in ipairs(system.rewards) do
            if reward.type == "xp_multiplier" then hasXPMultiplier = true end
            if reward.type == "rare_skin" then hasRareSkin = true end
        end
        TestFramework.assert.isTrue(hasXPMultiplier, "Should have XP multiplier rewards")
        TestFramework.assert.isTrue(hasRareSkin, "Should have rare skin rewards")
    end,
    
    ["box spawn chance - no spawn"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        
        -- Mock random above threshold
        setMockRandom({0.05}) -- Above 2% threshold
        
        system:checkForBoxSpawn(planet)
        
        TestFramework.assert.equal(0, #system.boxes, "Should not spawn box above threshold")
        restoreRandom()
    end,
    
    ["box spawn chance - spawn"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        
        -- Mock random below threshold plus box type selection
        setMockRandom({0.01, 0.3}) -- Below 2% threshold, select bronze
        
        system:checkForBoxSpawn(planet)
        
        TestFramework.assert.equal(1, #system.boxes, "Should spawn box below threshold")
        restoreRandom()
    end,
    
    ["prevent duplicate boxes on planet"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        
        -- Spawn first box
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        
        -- Try to spawn second box on same planet
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        
        TestFramework.assert.equal(1, #system.boxes, "Should not spawn duplicate box on same planet")
        restoreRandom()
    end,
    
    ["box type selection"] = function()
        local system = setupSystem()
        
        -- Test bronze selection (highest weight)
        setMockRandom({0.3}) -- Should select bronze
        local boxType = system:selectBoxType()
        TestFramework.assert.equal("bronze", boxType, "Should select bronze with low roll")
        
        -- Test legendary selection (lowest weight)
        setMockRandom({0.99}) -- Should select legendary
        boxType = system:selectBoxType()
        TestFramework.assert.equal("legendary", boxType, "Should select legendary with high roll")
        
        restoreRandom()
    end,
    
    ["box spawning position"] = function()
        local system = setupSystem()
        local planet = createMockPlanet(200, 300, 40)
        
        setMockRandom({0.01, 0.5, 0.0}) -- Spawn, select type, angle = 0
        
        system:checkForBoxSpawn(planet)
        
        local box = system.boxes[1]
        TestFramework.assert.isTrue(box ~= nil, "Box should be spawned")
        TestFramework.assert.equal(1, box.planet_id, "Box should have planet ID")
        TestFramework.assert.equal("bronze", box.type, "Box should have selected type")
        TestFramework.assert.isTrue(box.x > planet.x, "Box should be positioned away from planet center")
        
        restoreRandom()
    end,
    
    ["box animation updates"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        
        -- Spawn a box
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        
        local box = system.boxes[1]
        local initialRotation = box.rotation
        local initialPulse = box.pulse_phase
        
        -- Update animations
        system:update(1.0)
        
        TestFramework.assert.isTrue(box.rotation > initialRotation, "Box should rotate")
        TestFramework.assert.isTrue(box.pulse_phase > initialPulse, "Box should pulse")
        TestFramework.assert.isTrue(box.float_offset ~= 0, "Box should float")
        
        restoreRandom()
    end,
    
    ["particle spawning"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        
        local particlesEmitted = 0
        system.game_state.particle_system.emit = function()
            particlesEmitted = particlesEmitted + 1
        end
        
        -- Spawn a box
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        
        -- Update past particle timer threshold
        system:update(0.15) -- Above 0.1s threshold
        
        TestFramework.assert.isTrue(particlesEmitted > 0, "Should emit particles")
        restoreRandom()
    end,
    
    ["collision detection - hit"] = function()
        local system = setupSystem()
        local planet = createMockPlanet(100, 100)
        local player = createMockPlayer(100, 100) -- Same position as planet
        
        -- Spawn box near planet
        setMockRandom({0.01, 0.3, 0.0}) -- Spawn at angle 0
        system:checkForBoxSpawn(planet)
        
        local collision = system:checkCollision(player)
        
        TestFramework.assert.isTrue(collision, "Should detect collision with nearby box")
        TestFramework.assert.isTrue(system.boxes[1].collected, "Box should be marked collected")
        restoreRandom()
    end,
    
    ["collision detection - miss"] = function()
        local system = setupSystem()
        local planet = createMockPlanet(100, 100)
        local player = createMockPlayer(500, 500) -- Far from planet
        
        -- Spawn box
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        
        local collision = system:checkCollision(player)
        
        TestFramework.assert.isFalse(collision, "Should not detect collision when far away")
        TestFramework.assert.isFalse(system.boxes[1].collected, "Box should not be collected")
        restoreRandom()
    end,
    
    ["box collection starts animation"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        local player = createMockPlayer()
        
        -- Spawn and collect box
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        
        system:collectBox(system.boxes[1], player)
        
        TestFramework.assert.isTrue(system.opening_animation ~= nil, "Should start opening animation")
        TestFramework.assert.equal("opening", system.opening_animation.phase, "Should be in opening phase")
        TestFramework.assert.isTrue(#system.opening_animation.rewards > 0, "Should have generated rewards")
        
        restoreRandom()
    end,
    
    ["reward generation by box type"] = function()
        local system = setupSystem()
        
        -- Test bronze box rewards
        local bronzeBox = {type = "bronze", type_data = system.box_types.bronze}
        setMockRandom({1, 0.5}) -- Min rewards, select first reward
        local rewards = system:generateRewards(bronzeBox)
        
        TestFramework.assert.isTrue(#rewards >= 1, "Bronze should generate at least 1 reward")
        TestFramework.assert.isTrue(#rewards <= 2, "Bronze should generate at most 2 rewards")
        
        -- Test legendary box rewards
        local legendaryBox = {type = "legendary", type_data = system.box_types.legendary}
        setMockRandom({3, 0.5, 0.5, 0.5}) -- Max rewards, select rewards
        rewards = system:generateRewards(legendaryBox)
        
        TestFramework.assert.isTrue(#rewards >= 3, "Legendary should generate at least 3 rewards")
        TestFramework.assert.isTrue(#rewards <= 5, "Legendary should generate at most 5 rewards")
        
        restoreRandom()
    end,
    
    ["reward selection with rarity bonus"] = function()
        local system = setupSystem()
        
        -- Legendary boxes should have better chance at rare rewards
        local reward = system:selectReward(3.0) -- 3x rarity bonus
        TestFramework.assert.isTrue(reward ~= nil, "Should select a reward")
        TestFramework.assert.isTrue(reward.type ~= nil, "Reward should have type")
        TestFramework.assert.isTrue(reward.name ~= nil, "Reward should have name")
    end,
    
    ["opening animation phases"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        local player = createMockPlayer()
        
        -- Spawn and collect box
        setMockRandom({0.01, 0.3, 1}) -- Spawn, type, min rewards
        system:checkForBoxSpawn(planet)
        system:collectBox(system.boxes[1], player)
        
        TestFramework.assert.equal("opening", system.opening_animation.phase, "Should start in opening phase")
        
        -- Update past opening duration
        system:update(2.5) -- Beyond 2.0s opening duration
        
        TestFramework.assert.equal("revealing", system.opening_animation.phase, "Should move to revealing phase")
        
        -- Update past reward display time
        system:update(2.0) -- Beyond 1.5s reveal duration
        
        TestFramework.assert.isTrue(system.opening_animation == nil, "Should complete animation")
        
        restoreRandom()
    end,
    
    ["reward application - xp multiplier"] = function()
        local system = setupSystem()
        
        local multiplierApplied = false
        package.loaded["src.systems.xp_system"].addTemporaryMultiplier = function(mult, dur)
            multiplierApplied = true
            TestFramework.assert.equal(2.0, mult, "Should apply correct multiplier")
            TestFramework.assert.equal(60, dur, "Should apply correct duration")
        end
        
        local reward = {
            type = "xp_multiplier",
            multiplier = 2.0,
            duration = 60,
            description = "Double XP!"
        }
        
        system:applyReward(reward)
        
        TestFramework.assert.isTrue(multiplierApplied, "Should apply XP multiplier")
    end,
    
    ["reward application - ability cooldown"] = function()
        local system = setupSystem()
        
        local reward = {
            type = "ability_cooldown",
            cooldown_reduction = 0.5,
            duration = 120,
            description = "Faster cooldown!"
        }
        
        system:applyReward(reward)
        
        TestFramework.assert.equal(0.5, system.game_state.player.temp_cooldown_reduction, "Should apply cooldown reduction")
        TestFramework.assert.equal(120, system.game_state.player.cooldown_reduction_timer, "Should set timer")
    end,
    
    ["reward application - ring magnet"] = function()
        local system = setupSystem()
        
        local reward = {
            type = "ring_magnet",
            range_multiplier = 2.5,
            duration = 90,
            description = "Super magnet!"
        }
        
        system:applyReward(reward)
        
        TestFramework.assert.equal(2.5, system.game_state.player.temp_magnet_range_boost, "Should apply magnet boost")
        TestFramework.assert.equal(90, system.game_state.player.magnet_boost_timer, "Should set timer")
    end,
    
    ["reward application - rare skin"] = function()
        local system = setupSystem()
        
        local skinUnlocked = false
        system.game_state.progression_system.unlockSkin = function(name)
            skinUnlocked = true
            TestFramework.assert.equal("Cosmic Trail", name, "Should unlock correct skin")
        end
        
        local reward = {
            type = "rare_skin",
            name = "Cosmic Trail",
            description = "New skin!"
        }
        
        system:applyReward(reward)
        
        TestFramework.assert.isTrue(skinUnlocked, "Should unlock skin")
    end,
    
    ["social system notifications"] = function()
        local system = setupSystem()
        local planet = createMockPlanet()
        local player = createMockPlayer()
        
        local challengeNotified = false
        local achievementNotified = false
        
        package.loaded["src.systems.weekly_challenges_system"].onMysteryBoxOpened = function()
            challengeNotified = true
        end
        
        package.loaded["src.systems.achievement_system"].onMysteryBoxOpened = function()
            achievementNotified = true
        end
        
        -- Spawn and collect box
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet)
        system:collectBox(system.boxes[1], player)
        
        TestFramework.assert.isTrue(challengeNotified, "Should notify weekly challenges")
        TestFramework.assert.isTrue(achievementNotified, "Should notify achievement system")
        
        restoreRandom()
    end,
    
    ["active box count"] = function()
        local system = setupSystem()
        local planet1 = createMockPlanet(100, 100, 50, 1)
        local planet2 = createMockPlanet(300, 300, 50, 2)
        
        TestFramework.assert.equal(0, system:getActiveBoxCount(), "Should start with 0 boxes")
        
        -- Spawn two boxes
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet1)
        
        setMockRandom({0.01, 0.3})
        system:checkForBoxSpawn(planet2)
        
        TestFramework.assert.equal(2, system:getActiveBoxCount(), "Should have 2 active boxes")
        
        -- Collect one box
        system.boxes[1].collected = true
        
        TestFramework.assert.equal(1, system:getActiveBoxCount(), "Should have 1 active box after collection")
        
        restoreRandom()
    end,
    
    ["box type distribution test"] = function()
        local system = setupSystem()
        restoreRandom() -- Use real random for distribution test
        
        local results = {bronze = 0, silver = 0, gold = 0, legendary = 0}
        
        -- Run many iterations to test distribution
        local iterations = 1000
        for i = 1, iterations do
            local boxType = system:selectBoxType()
            results[boxType] = results[boxType] + 1
        end
        
        -- Check distribution is roughly correct (with tolerance)
        local bronzePercent = results.bronze / iterations
        TestFramework.assert.isTrue(math.abs(bronzePercent - 0.5) < 0.1, "Bronze distribution roughly 50%")
        
        local silverPercent = results.silver / iterations
        TestFramework.assert.isTrue(math.abs(silverPercent - 0.35) < 0.1, "Silver distribution roughly 35%")
        
        local legendaryPercent = results.legendary / iterations
        TestFramework.assert.isTrue(legendaryPercent < 0.1, "Legendary distribution less than 10%")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Mystery Box System Tests")
    restoreRandom() -- Ensure random is restored
    return success
end

return {run = run}