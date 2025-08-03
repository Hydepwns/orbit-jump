-- Test suite for Ring Rarity System
-- Tests rarity distribution, bad luck protection, visual effects, and statistics
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
TestFramework.init()
-- Load system
local RingRaritySystem = Utils.require("src.systems.ring_rarity_system")
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
-- Mock Utils serialize/deserialize
Utils.serialize = function(data)
    return TestFramework.serialize(data)
end
Utils.deserialize = function(str)
    local fn = loadstring("return " .. str)
    return fn and fn() or nil
end
-- Mock random for predictable testing
local mockRandomValues = {}
local mockRandomIndex = 1
local originalRandom = math.random
local function setMockRandom(values)
    mockRandomValues = values
    mockRandomIndex = 1
    math.random = function()
        local value = mockRandomValues[mockRandomIndex] or 0.5
        mockRandomIndex = mockRandomIndex + 1
        return value
    end
end
local function restoreRandom()
    math.random = originalRandom
end
-- Mock math.pow if not available (Lua 5.1 compatibility)
math.pow = math.pow or function(x, y)
    return x ^ y
end
-- Test helper functions
local function setupSystem()
    -- Reset ring rarity system state
    RingRaritySystem.glowPhase = 0
    RingRaritySystem.collectionEffects = {}
    RingRaritySystem.screenEffects = {}
    RingRaritySystem.stats = {
        standard = 0,
        silver = 0,
        gold = 0,
        legendary = 0,
        totalCollected = 0,
        lastLegendary = 0
    }
    -- Clear mock file data
    mockFileData = {}
    -- Reset random
    restoreRandom()
end
local function createMockRing(x, y, radius)
    return {x = x, y = y, radius = radius or 10}
end
local function createMockPlayer()
    return {x = 100, y = 100}
end
local function createMockGameState()
    return {score = 0}
end
-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        local success = RingRaritySystem.init()
        TestFramework.assert.isTrue(success, "Init should return true")
        TestFramework.assert.equal(0, RingRaritySystem.stats.legendary, "Should start with 0 legendary")
        TestFramework.assert.equal(0, RingRaritySystem.stats.totalCollected, "Should start with 0 total")
    end,
    ["rarity definitions"] = function()
        setupSystem()
        -- Check all rarities exist
        TestFramework.assert.isNotNil(RingRaritySystem.RARITIES.standard, "Standard rarity should exist")
        TestFramework.assert.isNotNil(RingRaritySystem.RARITIES.silver, "Silver rarity should exist")
        TestFramework.assert.isNotNil(RingRaritySystem.RARITIES.gold, "Gold rarity should exist")
        TestFramework.assert.isNotNil(RingRaritySystem.RARITIES.legendary, "Legendary rarity should exist")
        -- Check chance distribution
        local totalChance = 0
        for _, rarity in pairs(RingRaritySystem.RARITIES) do
            totalChance = totalChance + rarity.chance
        end
        TestFramework.assert.equal(1.0, totalChance, "Total chances should equal 100%")
    end,
    ["rarity properties"] = function()
        setupSystem()
        local standard = RingRaritySystem.RARITIES.standard
        TestFramework.assert.equal(10, standard.points, "Standard should give 10 points")
        TestFramework.assert.equal(0, standard.xpBonus, "Standard should give no XP bonus")
        local legendary = RingRaritySystem.RARITIES.legendary
        TestFramework.assert.equal(500, legendary.points, "Legendary should give 500 points")
        TestFramework.assert.equal(25, legendary.xpBonus, "Legendary should give 25 XP bonus")
        TestFramework.assert.equal(0.005, legendary.chance, "Legendary should have 0.5% chance")
    end,
    ["determine rarity - standard"] = function()
        setupSystem()
        -- Mock random to return value that should give standard
        setMockRandom({0.9}) -- Above 0.15 cumulative = standard
        local rarity = RingRaritySystem.determineRarity()
        TestFramework.assert.equal("standard", rarity, "Should return standard rarity")
    end,
    ["determine rarity - silver"] = function()
        setupSystem()
        -- Mock random to return value that should give silver
        setMockRandom({0.88}) -- Between 0.855 and 0.975
        local rarity = RingRaritySystem.determineRarity()
        TestFramework.assert.equal("silver", rarity, "Should return silver rarity")
    end,
    ["determine rarity - gold"] = function()
        setupSystem()
        -- Mock random to return value that should give gold
        setMockRandom({0.01}) -- Between 0.005 and 0.03
        local rarity = RingRaritySystem.determineRarity()
        TestFramework.assert.equal("gold", rarity, "Should return gold rarity")
    end,
    ["determine rarity - legendary"] = function()
        setupSystem()
        -- Mock random to return value that should give legendary
        setMockRandom({0.003}) -- Less than 0.005
        local rarity = RingRaritySystem.determineRarity()
        TestFramework.assert.equal("legendary", rarity, "Should return legendary rarity")
    end,
    ["bad luck protection - not triggered"] = function()
        setupSystem()
        RingRaritySystem.stats.lastLegendary = 100 -- Not enough time
        setMockRandom({0.9}) -- Would normally be standard
        local rarity = RingRaritySystem.applyBadLuckProtection("standard")
        TestFramework.assert.equal("standard", rarity, "Should not force legendary")
    end,
    ["bad luck protection - triggered"] = function()
        setupSystem()
        RingRaritySystem.stats.lastLegendary = 400 -- Over 5 minute threshold
        setMockRandom({0.05}) -- Low enough to trigger protection
        local rarity = RingRaritySystem.applyBadLuckProtection("standard")
        TestFramework.assert.equal("legendary", rarity, "Should force legendary after bad luck")
    end,
    ["apply rarity to ring"] = function()
        setupSystem()
        local ring = createMockRing(100, 100, 15)
        RingRaritySystem.applyRarityToRing(ring, "gold")
        TestFramework.assert.equal("gold", ring.rarity, "Ring should have gold rarity")
        TestFramework.assert.isNotNil(ring.rarityData, "Ring should have rarity data")
        TestFramework.assert.equal(100, ring.points, "Ring should have gold points")
        TestFramework.assert.deepEqual({1, 0.8, 0}, ring.color, "Ring should have gold color")
        TestFramework.assert.equal(2.0, ring.glowIntensity, "Ring should have gold glow")
    end,
    ["apply invalid rarity defaults to standard"] = function()
        setupSystem()
        local ring = createMockRing(100, 100)
        RingRaritySystem.applyRarityToRing(ring, "invalid_rarity")
        TestFramework.assert.equal("standard", ring.rarity, "Should default to standard")
    end,
    ["ring collection statistics"] = function()
        setupSystem()
        RingRaritySystem.init()
        local ring = createMockRing(100, 100)
        ring.rarity = "silver"
        ring.rarityData = RingRaritySystem.RARITIES.silver
        local player = createMockPlayer()
        local gameState = createMockGameState()
        RingRaritySystem.onRingCollected(ring, player, gameState)
        TestFramework.assert.equal(1, RingRaritySystem.stats.silver, "Silver count should increase")
        TestFramework.assert.equal(1, RingRaritySystem.stats.totalCollected, "Total should increase")
    end,
    ["legendary ring resets timer"] = function()
        setupSystem()
        RingRaritySystem.init()
        RingRaritySystem.stats.lastLegendary = 500 -- Been a while
        local ring = createMockRing(100, 100)
        ring.rarity = "legendary"
        ring.rarityData = RingRaritySystem.RARITIES.legendary
        RingRaritySystem.onRingCollected(ring, createMockPlayer(), createMockGameState())
        TestFramework.assert.equal(0, RingRaritySystem.stats.lastLegendary, "Timer should reset")
    end,
    ["collection effects created"] = function()
        setupSystem()
        RingRaritySystem.init()
        local ring = createMockRing(150, 200)
        ring.rarity = "gold"
        ring.rarityData = RingRaritySystem.RARITIES.gold
        TestFramework.assert.equal(0, #RingRaritySystem.collectionEffects, "Should start empty")
        RingRaritySystem.onRingCollected(ring, createMockPlayer(), createMockGameState())
        TestFramework.assert.equal(1, #RingRaritySystem.collectionEffects, "Should create effect")
        local effect = RingRaritySystem.collectionEffects[1]
        TestFramework.assert.equal(150, effect.x, "Effect should have ring x position")
        TestFramework.assert.equal(200, effect.y, "Effect should have ring y position")
        TestFramework.assert.equal(25, effect.particleCount, "Should have gold particle count")
    end,
    ["screen effects for rare rings"] = function()
        setupSystem()
        RingRaritySystem.init()
        local ring = createMockRing(100, 100)
        ring.rarity = "legendary"
        ring.rarityData = RingRaritySystem.RARITIES.legendary
        RingRaritySystem.onRingCollected(ring, createMockPlayer(), createMockGameState())
        TestFramework.assert.equal(1, #RingRaritySystem.screenEffects, "Should create screen effect")
        local effect = RingRaritySystem.screenEffects[1]
        TestFramework.assert.equal("fireworks", effect.type, "Legendary should create fireworks")
        TestFramework.assert.equal(2.0, effect.duration, "Fireworks should last 2 seconds")
    end,
    ["no screen effect for standard rings"] = function()
        setupSystem()
        RingRaritySystem.init()
        local ring = createMockRing(100, 100)
        ring.rarity = "standard"
        ring.rarityData = RingRaritySystem.RARITIES.standard
        RingRaritySystem.onRingCollected(ring, createMockPlayer(), createMockGameState())
        TestFramework.assert.equal(0, #RingRaritySystem.screenEffects, "Standard should not create screen effect")
    end,
    ["update animations"] = function()
        setupSystem()
        RingRaritySystem.init()
        -- Create effects
        RingRaritySystem.collectionEffects = {{
            timer = 0,
            duration = 1.0,
            alpha = 1.0,
            scale = 1.0
        }}
        RingRaritySystem.screenEffects = {{
            timer = 0,
            duration = 1.0,
            intensity = 1.0
        }}
        -- Update
        RingRaritySystem.update(0.5)
        local collectionEffect = RingRaritySystem.collectionEffects[1]
        TestFramework.assert.equal(0.5, collectionEffect.timer, "Timer should advance")
        TestFramework.assert.equal(0.5, collectionEffect.alpha, "Alpha should decrease")
        TestFramework.assert.equal(2.0, collectionEffect.scale, "Scale should increase")
        local screenEffect = RingRaritySystem.screenEffects[1]
        TestFramework.assert.equal(0.5, screenEffect.timer, "Screen timer should advance")
        TestFramework.assert.equal(0.5, screenEffect.intensity, "Intensity should decrease")
    end,
    ["effect cleanup"] = function()
        setupSystem()
        RingRaritySystem.init()
        -- Create expired effects
        RingRaritySystem.collectionEffects = {{
            timer = 0,
            duration = 0.5,
            alpha = 1.0
        }}
        RingRaritySystem.screenEffects = {{
            timer = 0,
            duration = 0.5,
            intensity = 1.0
        }}
        -- Update past duration
        RingRaritySystem.update(0.6)
        TestFramework.assert.equal(0, #RingRaritySystem.collectionEffects, "Collection effect should be removed")
        TestFramework.assert.equal(0, #RingRaritySystem.screenEffects, "Screen effect should be removed")
    end,
    ["last legendary timer"] = function()
        setupSystem()
        RingRaritySystem.init()
        RingRaritySystem.stats.lastLegendary = 100
        RingRaritySystem.update(5.0)
        TestFramework.assert.equal(105, RingRaritySystem.stats.lastLegendary, "Timer should increase")
    end,
    ["save and load statistics"] = function()
        setupSystem()
        RingRaritySystem.init()
        -- Set some stats
        RingRaritySystem.stats = {
            standard = 50,
            silver = 10,
            gold = 3,
            legendary = 1,
            totalCollected = 64,
            lastLegendary = 123.5
        }
        -- Save
        RingRaritySystem.saveStats()
        -- Reset and load
        RingRaritySystem.stats = {
            standard = 0,
            silver = 0,
            gold = 0,
            legendary = 0,
            totalCollected = 0,
            lastLegendary = 0
        }
        RingRaritySystem.loadStats()
        TestFramework.assert.equal(50, RingRaritySystem.stats.standard, "Standard count should persist")
        TestFramework.assert.equal(10, RingRaritySystem.stats.silver, "Silver count should persist")
        TestFramework.assert.equal(3, RingRaritySystem.stats.gold, "Gold count should persist")
        TestFramework.assert.equal(1, RingRaritySystem.stats.legendary, "Legendary count should persist")
        TestFramework.assert.equal(64, RingRaritySystem.stats.totalCollected, "Total should persist")
        TestFramework.assert.equal(123.5, RingRaritySystem.stats.lastLegendary, "Timer should persist")
    end,
    ["getter functions"] = function()
        setupSystem()
        RingRaritySystem.init()
        RingRaritySystem.stats.legendary = 5
        local stats = RingRaritySystem.getStats()
        TestFramework.assert.equal(5, stats.legendary, "Should return stats table")
        local standardChance = RingRaritySystem.getRarityChance("standard")
        TestFramework.assert.equal(0.85, standardChance, "Should return standard chance")
        local legendaryChance = RingRaritySystem.getRarityChance("legendary")
        TestFramework.assert.equal(0.005, legendaryChance, "Should return legendary chance")
        local invalidChance = RingRaritySystem.getRarityChance("invalid")
        TestFramework.assert.equal(0, invalidChance, "Should return 0 for invalid rarity")
        local goldData = RingRaritySystem.getRarityData("gold")
        TestFramework.assert.isNotNil(goldData, "Should return gold rarity data")
        TestFramework.assert.equal("Gold", goldData.name, "Should have correct name")
    end,
    ["point values scale correctly"] = function()
        setupSystem()
        local standard = RingRaritySystem.RARITIES.standard
        local silver = RingRaritySystem.RARITIES.silver
        local gold = RingRaritySystem.RARITIES.gold
        local legendary = RingRaritySystem.RARITIES.legendary
        TestFramework.assert.isTrue(silver.points > standard.points, "Silver worth more than standard")
        TestFramework.assert.isTrue(gold.points > silver.points, "Gold worth more than silver")
        TestFramework.assert.isTrue(legendary.points > gold.points, "Legendary worth more than gold")
    end,
    ["visual properties scale with rarity"] = function()
        setupSystem()
        local standard = RingRaritySystem.RARITIES.standard
        local legendary = RingRaritySystem.RARITIES.legendary
        TestFramework.assert.isTrue(legendary.glowIntensity > standard.glowIntensity, "Legendary should glow more")
        TestFramework.assert.isTrue(legendary.particleCount > standard.particleCount, "Legendary should have more particles")
        TestFramework.assert.isTrue(legendary.soundPitch > standard.soundPitch, "Legendary should have higher pitch")
    end,
    ["rarity distribution test"] = function()
        setupSystem()
        restoreRandom() -- Use real random for distribution test
        local results = {
            standard = 0,
            silver = 0,
            gold = 0,
            legendary = 0
        }
        -- Run many iterations to test distribution
        local iterations = 10000
        for i = 1, iterations do
            local rarity = RingRaritySystem.determineRarity()
            results[rarity] = results[rarity] + 1
        end
        -- Check distribution is roughly correct (with 20% tolerance)
        local standardPercent = results.standard / iterations
        TestFramework.assert.isTrue(math.abs(standardPercent - 0.85) < 0.1, "Standard distribution roughly 85%")
        local silverPercent = results.silver / iterations
        TestFramework.assert.isTrue(math.abs(silverPercent - 0.12) < 0.05, "Silver distribution roughly 12%")
        local goldPercent = results.gold / iterations
        TestFramework.assert.isTrue(math.abs(goldPercent - 0.025) < 0.02, "Gold distribution roughly 2.5%")
        local legendaryPercent = results.legendary / iterations
        TestFramework.assert.isTrue(legendaryPercent < 0.02, "Legendary distribution less than 2%")
    end
}
-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Ring Rarity System Tests")
    restoreRandom() -- Ensure random is restored
    return success
end
return {run = run}