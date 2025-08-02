-- Test suite for Streak System
-- Tests perfect landing detection, streak management, bonuses, and visual effects
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()
TestFramework.init()

-- Load system
local StreakSystem = Utils.require("src.systems.streak_system")

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

-- Test helper functions
local function setupSystem()
    -- Reset streak system state
    StreakSystem.perfectLandingStreak = 0
    StreakSystem.maxPerfectStreak = 0
    StreakSystem.streakBroken = false
    StreakSystem.streakBreakTimer = 0
    StreakSystem.streakSavedByGrace = false
    StreakSystem.graceTimer = 0
    StreakSystem.lastLandingWasPerfect = false
    StreakSystem.activeBonuses = {}
    StreakSystem.perfectLandings = 0
    
    -- Reset visual effects
    StreakSystem.streakGlowPhase = 0
    StreakSystem.bonusEffectTimer = 0
    StreakSystem.breakEffectTimer = 0
    StreakSystem.shakeIntensity = 0
    
    -- Clear mock file data
    mockFileData = {}
end

local function createMockPlayer(x, y)
    return {x = x, y = y}
end

local function createMockPlanet(x, y, radius)
    return {x = x, y = y, radius = radius or 50}
end

local function createMockGameState()
    return {
        ringMagnetActive = false,
        ringMagnetRadius = 40,
        scoreMultiplier = 1.0,
        timeScale = 1.0,
        perfectLandingRadius = StreakSystem.PERFECT_LANDING_RADIUS
    }
end

-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        local success = StreakSystem.init()
        
        TestFramework.assert.isTrue(success, "Init should return true")
        TestFramework.assert.equal(0, StreakSystem.perfectLandingStreak, "Streak should start at 0")
        TestFramework.assert.equal(0, StreakSystem.maxPerfectStreak, "Max streak should start at 0")
        TestFramework.assert.isFalse(StreakSystem.streakBroken, "Streak should not be broken initially")
        TestFramework.assert.isTrue(type(StreakSystem.activeBonuses) == "table", "Active bonuses should be initialized")
    end,
    
    ["perfect landing detection - center hit"] = function()
        setupSystem()
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100) -- Exactly on planet edge
        
        local isPerfect = StreakSystem.isPerfectLanding(player, planet)
        TestFramework.assert.isTrue(isPerfect, "Landing on edge should be perfect")
    end,
    
    ["perfect landing detection - within radius"] = function()
        setupSystem()
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(145, 100) -- 5 pixels from perfect
        
        local isPerfect = StreakSystem.isPerfectLanding(player, planet)
        TestFramework.assert.isTrue(isPerfect, "Landing within radius should be perfect")
    end,
    
    ["perfect landing detection - outside radius"] = function()
        setupSystem()
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(130, 100) -- 20 pixels from perfect
        
        local isPerfect = StreakSystem.isPerfectLanding(player, planet)
        TestFramework.assert.isFalse(isPerfect, "Landing outside radius should not be perfect")
    end,
    
    ["perfect landing increments streak"] = function()
        setupSystem()
        StreakSystem.init()
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100)
        local gameState = createMockGameState()
        
        StreakSystem.onPlayerLanding(player, planet, gameState)
        
        TestFramework.assert.equal(1, StreakSystem.perfectLandingStreak, "Streak should increment")
        TestFramework.assert.isTrue(StreakSystem.lastLandingWasPerfect, "Last landing should be marked perfect")
    end,
    
    ["multiple perfect landings"] = function()
        setupSystem()
        StreakSystem.init()
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100)
        local gameState = createMockGameState()
        
        -- Three perfect landings
        StreakSystem.onPlayerLanding(player, planet, gameState)
        StreakSystem.onPlayerLanding(player, planet, gameState)
        StreakSystem.onPlayerLanding(player, planet, gameState)
        
        TestFramework.assert.equal(3, StreakSystem.perfectLandingStreak, "Streak should be 3")
    end,
    
    ["imperfect landing starts grace period"] = function()
        setupSystem()
        StreakSystem.init()
        StreakSystem.perfectLandingStreak = 5 -- Existing streak
        
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(130, 100) -- Imperfect landing
        local gameState = createMockGameState()
        
        StreakSystem.onPlayerLanding(player, planet, gameState)
        
        TestFramework.assert.equal(5, StreakSystem.perfectLandingStreak, "Streak should be preserved")
        TestFramework.assert.isTrue(StreakSystem.graceTimer > 0, "Grace timer should be active")
        TestFramework.assert.isTrue(StreakSystem.graceTimer >= 2.5, "Grace timer should be at least 2.5s")
    end,
    
    ["grace period saves streak"] = function()
        setupSystem()
        StreakSystem.init()
        StreakSystem.perfectLandingStreak = 10
        StreakSystem.graceTimer = 2.0 -- Active grace period
        
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100) -- Perfect landing during grace
        local gameState = createMockGameState()
        
        StreakSystem.onPlayerLanding(player, planet, gameState)
        
        TestFramework.assert.equal(11, StreakSystem.perfectLandingStreak, "Streak should continue")
        TestFramework.assert.equal(0, StreakSystem.graceTimer, "Grace timer should be cleared")
        TestFramework.assert.isTrue(StreakSystem.streakSavedByGrace, "Streak should be marked as saved")
    end,
    
    ["grace period expires breaks streak"] = function()
        setupSystem()
        StreakSystem.init()
        StreakSystem.perfectLandingStreak = 15
        StreakSystem.graceTimer = 0.1
        
        local gameState = createMockGameState()
        
        -- Update until grace expires
        StreakSystem.update(0.2, gameState)
        
        TestFramework.assert.equal(0, StreakSystem.perfectLandingStreak, "Streak should be broken")
        TestFramework.assert.isTrue(StreakSystem.streakBroken, "Streak should be marked broken")
        TestFramework.assert.isTrue(StreakSystem.breakEffectTimer > 0, "Break effect should trigger")
    end,
    
    ["max streak tracking"] = function()
        setupSystem()
        StreakSystem.init()
        
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100)
        local gameState = createMockGameState()
        
        -- Build streak to 5
        for i = 1, 5 do
            StreakSystem.onPlayerLanding(player, planet, gameState)
        end
        
        TestFramework.assert.equal(5, StreakSystem.maxPerfectStreak, "Max streak should update")
        
        -- Break and rebuild smaller streak
        StreakSystem.breakStreak("test")
        StreakSystem.onPlayerLanding(player, planet, gameState)
        StreakSystem.onPlayerLanding(player, planet, gameState)
        
        TestFramework.assert.equal(2, StreakSystem.perfectLandingStreak, "Current streak should be 2")
        TestFramework.assert.equal(5, StreakSystem.maxPerfectStreak, "Max streak should remain 5")
    end,
    
    ["streak milestone bonuses"] = function()
        setupSystem()
        StreakSystem.init()
        
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100)
        local gameState = createMockGameState()
        
        -- Build streak to 5 (first milestone)
        for i = 1, 5 do
            StreakSystem.onPlayerLanding(player, planet, gameState)
        end
        
        TestFramework.assert.isTrue(StreakSystem.activeBonuses.ring_magnet ~= nil, "Ring magnet bonus should activate")
        TestFramework.assert.equal("Ring Magnet", StreakSystem.activeBonuses.ring_magnet.name, "Bonus name should match")
    end,
    
    ["multiple milestone bonuses"] = function()
        setupSystem()
        StreakSystem.init()
        
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100)
        local gameState = createMockGameState()
        
        -- Build streak to 10
        for i = 1, 10 do
            StreakSystem.onPlayerLanding(player, planet, gameState)
        end
        
        TestFramework.assert.isTrue(StreakSystem.activeBonuses.double_points ~= nil, "Double points bonus should activate")
        TestFramework.assert.equal(10, StreakSystem.perfectLandingStreak, "Streak should be 10")
    end,
    
    ["bonus duration countdown"] = function()
        setupSystem()
        StreakSystem.init()
        
        -- Manually activate a bonus
        StreakSystem.activateBonus("test_bonus", 5.0, "Test Bonus")
        
        local gameState = createMockGameState()
        
        -- Update for 2 seconds
        StreakSystem.update(2.0, gameState)
        
        TestFramework.assert.isTrue(StreakSystem.activeBonuses.test_bonus ~= nil, "Bonus should still be active")
        TestFramework.assert.equal(3.0, StreakSystem.activeBonuses.test_bonus.duration, "Duration should decrease")
        
        -- Update for 4 more seconds (total 6)
        StreakSystem.update(4.0, gameState)
        
        TestFramework.assert.isTrue(StreakSystem.activeBonuses.test_bonus == nil, "Bonus should expire")
    end,
    
    ["bonus effects - ring magnet"] = function()
        setupSystem()
        StreakSystem.init()
        
        local gameState = createMockGameState()
        
        -- Activate ring magnet
        StreakSystem.activateBonus("ring_magnet", 10.0, "Ring Magnet")
        StreakSystem.applyBonusEffects(gameState)
        
        TestFramework.assert.isTrue(gameState.ringMagnetActive, "Ring magnet should be active")
        TestFramework.assert.equal(80, gameState.ringMagnetRadius, "Ring magnet radius should increase")
    end,
    
    ["bonus effects - double points"] = function()
        setupSystem()
        StreakSystem.init()
        
        local gameState = createMockGameState()
        
        -- Activate double points
        StreakSystem.activateBonus("double_points", 10.0, "Double Points")
        StreakSystem.applyBonusEffects(gameState)
        
        TestFramework.assert.equal(2.0, gameState.scoreMultiplier, "Score multiplier should be 2x")
    end,
    
    ["bonus effects - slow motion"] = function()
        setupSystem()
        StreakSystem.init()
        
        local gameState = createMockGameState()
        
        -- Activate slow motion
        StreakSystem.activateBonus("slow_motion", 10.0, "Slow Motion")
        StreakSystem.applyBonusEffects(gameState)
        
        TestFramework.assert.equal(0.6, gameState.timeScale, "Time should slow down")
    end,
    
    ["bonus effects - all bonuses"] = function()
        setupSystem()
        StreakSystem.init()
        
        local gameState = createMockGameState()
        
        -- Activate legendary bonus
        StreakSystem.activateBonus("all_bonuses", 30.0, "Legendary")
        StreakSystem.applyBonusEffects(gameState)
        
        TestFramework.assert.equal(5.0, gameState.scoreMultiplier, "Score multiplier should be 5x")
        TestFramework.assert.equal(0.6, gameState.timeScale, "Time should slow down")
        TestFramework.assert.equal(StreakSystem.PERFECT_LANDING_RADIUS * 2, gameState.perfectLandingRadius, "Landing radius should double")
    end,
    
    ["breaking streak clears bonuses"] = function()
        setupSystem()
        StreakSystem.init()
        
        -- Activate multiple bonuses
        StreakSystem.activateBonus("ring_magnet", 10.0, "Ring Magnet")
        StreakSystem.activateBonus("double_points", 10.0, "Double Points")
        
        -- Break streak
        StreakSystem.perfectLandingStreak = 10
        StreakSystem.breakStreak("test")
        
        TestFramework.assert.equal(0, StreakSystem.perfectLandingStreak, "Streak should be 0")
        TestFramework.assert.isTrue(StreakSystem.activeBonuses.ring_magnet == nil, "Ring magnet should be cleared")
        TestFramework.assert.isTrue(StreakSystem.activeBonuses.double_points == nil, "Double points should be cleared")
    end,
    
    ["save and load max streak"] = function()
        setupSystem()
        StreakSystem.init()
        
        -- Set max streak
        StreakSystem.maxPerfectStreak = 25
        StreakSystem.saveMaxStreak()
        
        -- Reset and load
        StreakSystem.maxPerfectStreak = 0
        local loaded = StreakSystem.loadMaxStreak()
        
        TestFramework.assert.equal(25, loaded, "Should load saved max streak")
    end,
    
    ["load missing max streak"] = function()
        setupSystem()
        mockFileData = {} -- Clear save data
        
        local loaded = StreakSystem.loadMaxStreak()
        TestFramework.assert.equal(0, loaded, "Should return 0 for missing data")
    end,
    
    ["visual effect timers"] = function()
        setupSystem()
        StreakSystem.init()
        
        -- Set effect timers
        StreakSystem.bonusEffectTimer = 2.0
        StreakSystem.breakEffectTimer = 3.0
        StreakSystem.shakeIntensity = 1.0
        
        local gameState = createMockGameState()
        
        -- Update for 1 second
        StreakSystem.update(1.0, gameState)
        
        TestFramework.assert.equal(1.0, StreakSystem.bonusEffectTimer, "Bonus effect timer should decrease")
        TestFramework.assert.equal(2.0, StreakSystem.breakEffectTimer, "Break effect timer should decrease")
        TestFramework.assert.isTrue(StreakSystem.shakeIntensity < 1.0, "Shake intensity should decrease")
    end,
    
    ["streak info getters"] = function()
        setupSystem()
        StreakSystem.init()
        StreakSystem.perfectLandingStreak = 7
        StreakSystem.maxPerfectStreak = 20
        
        TestFramework.assert.equal(7, StreakSystem.getCurrentStreak(), "Should return current streak")
        TestFramework.assert.equal(20, StreakSystem.getMaxStreak(), "Should return max streak")
        TestFramework.assert.isTrue(StreakSystem.isOnStreak(), "Should be on streak")
        
        StreakSystem.perfectLandingStreak = 0
        TestFramework.assert.isFalse(StreakSystem.isOnStreak(), "Should not be on streak")
    end,
    
    ["active bonus checking"] = function()
        setupSystem()
        StreakSystem.init()
        
        TestFramework.assert.isFalse(StreakSystem.hasActiveBonus("ring_magnet"), "Should not have bonus")
        
        StreakSystem.activateBonus("ring_magnet", 10.0, "Ring Magnet")
        
        TestFramework.assert.isTrue(StreakSystem.hasActiveBonus("ring_magnet"), "Should have bonus")
        
        local bonuses = StreakSystem.getActiveBonuses()
        TestFramework.assert.isTrue(bonuses.ring_magnet ~= nil, "Should return active bonuses")
    end,
    
    ["bonus color mapping"] = function()
        setupSystem()
        
        local ringColor = StreakSystem.getBonusColor("ring_magnet")
        TestFramework.assert.isTrue(type(ringColor) == "table", "Should return color table")
        TestFramework.assert.equal(3, #ringColor, "Color should have 3 components")
        
        local unknownColor = StreakSystem.getBonusColor("unknown_bonus")
        TestFramework.assert.equal(1, unknownColor[1], "Unknown bonus should return white")
        TestFramework.assert.equal(1, unknownColor[2], "Unknown bonus should return white")
        TestFramework.assert.equal(1, unknownColor[3], "Unknown bonus should return white")
    end,
    
    ["perfect landing tracking"] = function()
        setupSystem()
        StreakSystem.init()
        StreakSystem.perfectLandings = 0
        
        local planet = createMockPlanet(100, 100, 50)
        local player = createMockPlayer(150, 100)
        local gameState = createMockGameState()
        
        -- Make 3 perfect landings
        StreakSystem.onPlayerLanding(player, planet, gameState)
        StreakSystem.onPlayerLanding(player, planet, gameState)
        StreakSystem.onPlayerLanding(player, planet, gameState)
        
        TestFramework.assert.equal(3, StreakSystem.perfectLandings, "Should track total perfect landings")
    end,
    
    ["streak thresholds configuration"] = function()
        setupSystem()
        
        TestFramework.assert.equal(12, #StreakSystem.STREAK_THRESHOLDS, "Should have 12 streak thresholds")
        
        -- Check progression
        local counts = {}
        for _, threshold in ipairs(StreakSystem.STREAK_THRESHOLDS) do
            table.insert(counts, threshold.count)
        end
        
        TestFramework.assert.equal(5, counts[1], "First threshold should be 5")
        TestFramework.assert.equal(10, counts[2], "Second threshold should be 10")
        TestFramework.assert.equal(15, counts[3], "Third threshold should be 15")
        TestFramework.assert.equal(20, counts[4], "Fourth threshold should be 20")
        TestFramework.assert.equal(25, counts[5], "Fifth threshold should be 25")
        TestFramework.assert.equal(30, counts[6], "Sixth threshold should be 30")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "Streak System Tests")
end

return {run = run}