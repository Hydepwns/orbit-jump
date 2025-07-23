-- Test suite for Achievement System
-- Tests all achievement tracking, unlocking, and notification functionality

local TestFramework = require("tests.test_framework")
local AchievementSystem = require("src.systems.achievement_system")

-- Initialize test framework
TestFramework.init()

-- Mock dependencies
local mockSoundManager = {
    playAchievement = function() end
}
local mockUpgradeSystem = {
    addCurrency = function() end
}

-- Setup function to reset state before each test
local function setupAchievementSystem()
    -- Mock the sound manager
    package.loaded["src.audio.sound_manager"] = mockSoundManager
    package.loaded["src.systems.upgrade_system"] = mockUpgradeSystem
    
    -- Reset achievement system state
    for _, achievement in pairs(AchievementSystem.achievements) do
        achievement.unlocked = false
        achievement.progress = 0
    end
    
    AchievementSystem.notifications = {}
    AchievementSystem.stats = {
        planetsDiscovered = 0,
        ringsCollected = 0,
        maxCombo = 0,
        totalDashes = 0,
        perfectLandings = 0,
        maxDistance = 0,
        powerRingsCollected = {},
        planetTypesVisited = {
            ice = 0,
            lava = 0,
            tech = 0,
            void = 0
        },
        lavaEruptions = 0,
        gravityPulses = 0,
        chainCompleted = 0
    }
end

-- Test suite
local tests = {
    -- Test achievement initialization
    achievementInitialization = function()
        setupAchievementSystem()
        local firstPlanet = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(firstPlanet.name, "Baby Steps")
        TestFramework.utils.assertEqual(firstPlanet.description, "Discover your first planet")
        TestFramework.utils.assertEqual(firstPlanet.points, 10)
        TestFramework.utils.assertEqual(firstPlanet.target, 1)
        TestFramework.utils.assertFalse(firstPlanet.unlocked)
        TestFramework.utils.assertEqual(firstPlanet.progress, 0)
    end,
    
    -- Test progress tracking
    updateProgress = function()
        setupAchievementSystem()
        AchievementSystem.updateProgress("first_planet", 1)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 1)
        TestFramework.utils.assertTrue(achievement.unlocked)
    end,
    
    ["updateProgress exceeds target"] = function()
        setupAchievementSystem()
        AchievementSystem.updateProgress("first_planet", 5)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 1) -- Should be capped at target
        TestFramework.utils.assertTrue(achievement.unlocked)
    end,
    
    ["updateProgress already unlocked"] = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem.updateProgress("first_planet", 1)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 0) -- Should not change
    end,
    
    ["updateProgress invalid id"] = function()
        setupAchievementSystem()
        AchievementSystem.updateProgress("invalid_id", 1)
        -- Should not crash and should not affect any achievements
        TestFramework.utils.assertTrue(true) -- Test passes if no error
    end,
    
    -- Test increment progress
    incrementProgress = function()
        setupAchievementSystem()
        AchievementSystem.incrementProgress("planet_hopper", 5)
        local achievement = AchievementSystem.achievements.planet_hopper
        TestFramework.utils.assertEqual(achievement.progress, 5)
        TestFramework.utils.assertFalse(achievement.unlocked) -- Not enough for target of 10
    end,
    
    ["incrementProgress default amount"] = function()
        setupAchievementSystem()
        AchievementSystem.incrementProgress("first_planet")
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 1)
        TestFramework.utils.assertTrue(achievement.unlocked)
    end,
    
    ["incrementProgress exceeds target"] = function()
        setupAchievementSystem()
        AchievementSystem.incrementProgress("first_planet", 5)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 1) -- Should be capped at target
        TestFramework.utils.assertTrue(achievement.unlocked)
    end,
    
    -- Test achievement unlocking
    unlockAchievement = function()
        setupAchievementSystem()
        local points = AchievementSystem.unlock("first_planet")
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertTrue(achievement.unlocked)
        TestFramework.utils.assertEqual(achievement.progress, 1)
        TestFramework.utils.assertEqual(points, 10)
        TestFramework.utils.assertEqual(#AchievementSystem.notifications, 1)
    end,
    
    ["unlock already unlocked"] = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        local points = AchievementSystem.unlock("first_planet")
        TestFramework.utils.assertNil(points) -- Should return nil for already unlocked
    end,
    
    ["unlock invalid id"] = function()
        setupAchievementSystem()
        local points = AchievementSystem.unlock("invalid_id")
        TestFramework.utils.assertNil(points)
    end,
    
    -- Test notification system
    notificationCreation = function()
        setupAchievementSystem()
        AchievementSystem.unlock("first_planet")
        TestFramework.utils.assertEqual(#AchievementSystem.notifications, 1)
        
        local notification = AchievementSystem.notifications[1]
        TestFramework.utils.assertEqual(notification.achievement.id, "first_planet")
        TestFramework.utils.assertEqual(notification.timer, 3.0)
        TestFramework.utils.assertEqual(notification.y, -100)
        TestFramework.utils.assertEqual(notification.targetY, 50)
    end,
    
    notificationUpdate = function()
        setupAchievementSystem()
        AchievementSystem.unlock("first_planet")
        local notification = AchievementSystem.notifications[1]
        
        -- Test animation
        local initialY = notification.y
        AchievementSystem.update(0.1)
        TestFramework.utils.assertTrue(notification.y > initialY) -- Should move toward target
        
        -- Test timer countdown
        local initialTimer = notification.timer
        AchievementSystem.update(0.1)
        TestFramework.utils.assertTrue(notification.timer < initialTimer)
    end,
    
    notificationRemoval = function()
        setupAchievementSystem()
        AchievementSystem.unlock("first_planet")
        TestFramework.utils.assertEqual(#AchievementSystem.notifications, 1)
        
        -- Fast forward past duration
        for i = 1, 50 do
            AchievementSystem.update(0.1)
        end
        
        TestFramework.utils.assertEqual(#AchievementSystem.notifications, 0)
    end,
    
    -- Test event handlers
    onPlanetDiscovered = function()
        setupAchievementSystem()
        AchievementSystem.onPlanetDiscovered("ice")
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetsDiscovered, 1)
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetTypesVisited.ice, 1)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.first_planet.unlocked)
        TestFramework.utils.assertEqual(AchievementSystem.achievements.planet_hopper.progress, 1)
    end,
    
    ["onPlanetDiscovered multiple"] = function()
        setupAchievementSystem()
        AchievementSystem.onPlanetDiscovered("ice")
        AchievementSystem.onPlanetDiscovered("lava")
        AchievementSystem.onPlanetDiscovered("tech")
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetsDiscovered, 3)
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetTypesVisited.ice, 1)
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetTypesVisited.lava, 1)
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetTypesVisited.tech, 1)
    end,
    
    onRingCollected = function()
        setupAchievementSystem()
        AchievementSystem.onRingCollected("power_shield")
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.ringsCollected, 1)
        TestFramework.utils.assertEqual(AchievementSystem.achievements.ring_collector.progress, 1)
        TestFramework.utils.assertTrue(AchievementSystem.stats.powerRingsCollected.power_shield)
    end,
    
    ["onRingCollected power rings"] = function()
        setupAchievementSystem()
        AchievementSystem.onRingCollected("power_shield")
        AchievementSystem.onRingCollected("power_magnet")
        AchievementSystem.onRingCollected("power_slowmo")
        AchievementSystem.onRingCollected("power_multijump")
        
        TestFramework.utils.assertEqual(AchievementSystem.achievements.power_user.progress, 4)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.power_user.unlocked)
    end,
    
    onComboReached = function()
        setupAchievementSystem()
        AchievementSystem.onComboReached(25)
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.maxCombo, 25)
        TestFramework.utils.assertEqual(AchievementSystem.achievements.combo_king.progress, 20) -- Target is 20
        TestFramework.utils.assertTrue(AchievementSystem.achievements.combo_king.unlocked)
    end,
    
    ["onComboReached lower combo"] = function()
        setupAchievementSystem()
        AchievementSystem.onComboReached(25)
        AchievementSystem.onComboReached(15) -- Lower combo should not update max
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.maxCombo, 25)
        TestFramework.utils.assertEqual(AchievementSystem.achievements.combo_king.progress, 20) -- Target is 20
    end,
    
    onDash = function()
        setupAchievementSystem()
        for i = 1, 50 do
            AchievementSystem.onDash()
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.totalDashes, 50)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.speed_demon.unlocked)
    end,
    
    onPerfectLanding = function()
        setupAchievementSystem()
        for i = 1, 10 do
            AchievementSystem.onPerfectLanding()
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.perfectLandings, 10)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.perfect_landing.unlocked)
    end,
    
    onDistanceReached = function()
        setupAchievementSystem()
        AchievementSystem.onDistanceReached(6000)
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.maxDistance, 6000)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.void_walker.unlocked)
    end,
    
    ["onDistanceReached lower distance"] = function()
        setupAchievementSystem()
        AchievementSystem.onDistanceReached(6000)
        AchievementSystem.onDistanceReached(3000) -- Lower distance should not update max
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.maxDistance, 6000)
    end,
    
    onLavaEruption = function()
        setupAchievementSystem()
        for i = 1, 10 do
            AchievementSystem.onLavaEruption()
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.lavaEruptions, 10)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.lava_surfer.unlocked)
    end,
    
    onGravityPulse = function()
        setupAchievementSystem()
        for i = 1, 20 do
            AchievementSystem.onGravityPulse()
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.gravityPulses, 20)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.tech_savvy.unlocked)
    end,
    
    onChainCompleted = function()
        setupAchievementSystem()
        AchievementSystem.onChainCompleted(5)
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.chainCompleted, 5)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.chain_master.unlocked)
    end,
    
    ["onChainCompleted shorter chain"] = function()
        setupAchievementSystem()
        AchievementSystem.onChainCompleted(5)
        AchievementSystem.onChainCompleted(3) -- Shorter chain should not update max
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.chainCompleted, 5)
    end,
    
    -- Test save/load functionality
    getSaveData = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem.achievements.first_planet.progress = 1
        AchievementSystem.stats.planetsDiscovered = 5
        
        local saveData = AchievementSystem.getSaveData()
        
        TestFramework.utils.assertTrue(saveData.achievements.first_planet.unlocked)
        TestFramework.utils.assertEqual(saveData.achievements.first_planet.progress, 1)
        TestFramework.utils.assertEqual(saveData.stats.planetsDiscovered, 5)
    end,
    
    loadSaveData = function()
        setupAchievementSystem()
        local saveData = {
            achievements = {
                first_planet = { unlocked = true, progress = 1 },
                planet_hopper = { unlocked = false, progress = 5 }
            },
            stats = { planetsDiscovered = 10 }
        }
        
        AchievementSystem.loadSaveData(saveData)
        
        TestFramework.utils.assertTrue(AchievementSystem.achievements.first_planet.unlocked)
        TestFramework.utils.assertEqual(AchievementSystem.achievements.first_planet.progress, 1)
        TestFramework.utils.assertFalse(AchievementSystem.achievements.planet_hopper.unlocked)
        TestFramework.utils.assertEqual(AchievementSystem.achievements.planet_hopper.progress, 5)
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetsDiscovered, 10)
    end,
    
    ["loadSaveData nil"] = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem.stats.planetsDiscovered = 5
        
        AchievementSystem.loadSaveData(nil)
        
        -- Should not crash and should not change existing state
        TestFramework.utils.assertTrue(AchievementSystem.achievements.first_planet.unlocked)
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetsDiscovered, 5)
    end,
    
    ["loadSaveData partial"] = function()
        setupAchievementSystem()
        local saveData = {
            stats = { planetsDiscovered = 10 }
            -- Missing achievements section
        }
        
        AchievementSystem.loadSaveData(saveData)
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetsDiscovered, 10)
        -- Achievements should remain unchanged
        TestFramework.utils.assertFalse(AchievementSystem.achievements.first_planet.unlocked)
    end,
    
    -- Test utility functions
    getTotalPoints = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem.achievements.planet_hopper.unlocked = true
        
        local total = AchievementSystem.getTotalPoints()
        TestFramework.utils.assertEqual(total, 60) -- 10 + 50
    end,
    
    ["getTotalPoints no unlocked"] = function()
        setupAchievementSystem()
        local total = AchievementSystem.getTotalPoints()
        TestFramework.utils.assertEqual(total, 0)
    end,
    
    getCompletionPercentage = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem.achievements.planet_hopper.unlocked = true
        
        local percentage = AchievementSystem.getCompletionPercentage()
        -- Should be 2 out of total achievements (approximately 20+ achievements)
        TestFramework.utils.assertTrue(percentage > 0)
        TestFramework.utils.assertTrue(percentage < 20)
    end,
    
    ["getCompletionPercentage all unlocked"] = function()
        setupAchievementSystem()
        for _, achievement in pairs(AchievementSystem.achievements) do
            achievement.unlocked = true
        end
        
        local percentage = AchievementSystem.getCompletionPercentage()
        TestFramework.utils.assertEqual(percentage, 100)
    end,
    
    -- Test special achievements
    onWarpZoneDiscovered = function()
        setupAchievementSystem()
        for i = 1, 5 do
            AchievementSystem.onWarpZoneDiscovered()
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.warpsDiscovered, 5)
    end,
    
    onWarpZoneCompleted = function()
        setupAchievementSystem()
        for i = 1, 10 do
            AchievementSystem.onWarpZoneCompleted("time_trial")
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.warpsCompleted, 10)
        TestFramework.utils.assertTrue(AchievementSystem.stats.warpTypes.time_trial)
    end,
    
    onArtifactCollected = function()
        setupAchievementSystem()
        for i = 1, 5 do
            AchievementSystem.onArtifactCollected("artifact_" .. i)
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.artifactsCollected, 5)
    end,
    
    onAllArtifactsCollected = function()
        setupAchievementSystem()
        AchievementSystem.onAllArtifactsCollected()
        -- This should trigger the lore master achievement
        TestFramework.utils.assertTrue(true) -- Test passes if no error
    end,
    
    onConstellationComplete = function()
        setupAchievementSystem()
        AchievementSystem.onConstellationComplete("star")
        AchievementSystem.onConstellationComplete("infinity")
        
        TestFramework.utils.assertEqual(AchievementSystem.achievements.constellation_artist.progress, 2) -- Called twice
        TestFramework.utils.assertEqual(AchievementSystem.achievements.star_maker.progress, 1) -- Called once for star
        TestFramework.utils.assertEqual(AchievementSystem.achievements.infinity_master.progress, 1) -- Called once for infinity
    end,
    
    -- Test planet type specific achievements
    ["ice planet achievement"] = function()
        setupAchievementSystem()
        for i = 1, 5 do
            AchievementSystem.onPlanetDiscovered("ice")
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetTypesVisited.ice, 5)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.ice_breaker.unlocked)
    end,
    
    ["void planet achievement"] = function()
        setupAchievementSystem()
        for i = 1, 5 do
            AchievementSystem.onPlanetDiscovered("void")
        end
        
        TestFramework.utils.assertEqual(AchievementSystem.stats.planetTypesVisited.void, 5)
        TestFramework.utils.assertTrue(AchievementSystem.achievements.void_master.unlocked)
    end,
    
    -- Test edge cases
    ["invalid achievement id"] = function()
        setupAchievementSystem()
        AchievementSystem.updateProgress("nonexistent", 1)
        AchievementSystem.incrementProgress("nonexistent", 1)
        AchievementSystem.unlock("nonexistent")
        
        -- Should not crash
        TestFramework.utils.assertTrue(true)
    end,
    
    ["negative progress"] = function()
        setupAchievementSystem()
        AchievementSystem.updateProgress("first_planet", -1)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 0) -- Should not go negative, but should be 0
    end,
    
    ["zero progress"] = function()
        setupAchievementSystem()
        AchievementSystem.updateProgress("first_planet", 0)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.utils.assertEqual(achievement.progress, 0)
        TestFramework.utils.assertFalse(achievement.unlocked)
    end,
    
    -- Test notification animation edge cases
    ["notification animation edge cases"] = function()
        setupAchievementSystem()
        AchievementSystem.unlock("first_planet")
        local notification = AchievementSystem.notifications[1]
        
        -- Test with very small dt
        AchievementSystem.update(0.001)
        TestFramework.utils.assertTrue(notification.y > -100)
        
        -- Test with large dt
        AchievementSystem.update(1.0)
        TestFramework.utils.assertTrue(notification.timer <= 2.0)
    end,
    
    ["multiple notifications"] = function()
        setupAchievementSystem()
        AchievementSystem.unlock("first_planet")
        AchievementSystem.unlock("planet_hopper")
        
        TestFramework.utils.assertEqual(#AchievementSystem.notifications, 2)
        
        -- Both should animate independently
        AchievementSystem.update(0.1)
        -- Check that both notifications exist and are animating
        TestFramework.utils.assertTrue(AchievementSystem.notifications[1].y > -100)
        TestFramework.utils.assertTrue(AchievementSystem.notifications[2].y > -100)
    end
}

-- Run the test suite
local function runTests()
    return TestFramework.runSuite("Achievement System Tests", tests)
end

-- Export for use in main test runner
local result = {run = runTests}

-- Run tests if this file is executed directly
if arg and arg[0] and string.find(arg[0], "test_achievement_system.lua") then
    runTests()
end

return result 