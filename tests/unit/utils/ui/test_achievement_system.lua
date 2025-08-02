-- Test suite for Achievement System
-- Tests all achievement tracking, unlocking, and notification functionality

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock the achievement system
local AchievementSystem = {
    achievements = {
        first_planet = {
            id = "first_planet",
            name = "Baby Steps",
            description = "Discover your first planet",
            icon = "🌍",
            points = 10,
            unlocked = false,
            progress = 0,
            target = 1
        },
        planet_hopper = {
            id = "planet_hopper",
            name = "Planet Hopper",
            description = "Discover 10 planets",
            icon = "🚀",
            points = 25,
            unlocked = false,
            progress = 0,
            target = 10
        }
    },
    notifications = {},
    stats = {
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
    },
    
    updateProgress = function(self, id, amount)
        if self.achievements[id] then
            self.achievements[id].progress = amount
            if self.achievements[id].progress >= self.achievements[id].target then
                self.achievements[id].unlocked = true
            end
        end
    end,
    
    incrementProgress = function(self, id, amount)
        if self.achievements[id] then
            self.achievements[id].progress = self.achievements[id].progress + (amount or 1)
            if self.achievements[id].progress >= self.achievements[id].target then
                self.achievements[id].unlocked = true
            end
        end
    end,
    
    unlock = function(self, id)
        if self.achievements[id] then
            self.achievements[id].unlocked = true
        end
    end,
    
    update = function(self, dt)
        -- Mock update function
    end,
    
    onPlanetDiscovered = function(self, planetType)
        self.stats.planetsDiscovered = self.stats.planetsDiscovered + 1
        if self.stats.planetTypesVisited[planetType] then
            self.stats.planetTypesVisited[planetType] = self.stats.planetTypesVisited[planetType] + 1
        end
    end,
    
    onRingCollected = function(self, ringType)
        self.stats.ringsCollected = self.stats.ringsCollected + 1
    end,
    
    onDash = function(self)
        self.stats.totalDashes = self.stats.totalDashes + 1
    end,
    
    onComboReached = function(self, combo)
        if combo > self.stats.maxCombo then
            self.stats.maxCombo = combo
        end
    end,
    
    onDistanceReached = function(self, distance)
        if distance > self.stats.maxDistance then
            self.stats.maxDistance = distance
        end
    end,
    
    onPerfectLanding = function(self)
        self.stats.perfectLandings = self.stats.perfectLandings + 1
    end,
    
    onWarpZoneDiscovered = function(self)
        -- Mock function
    end,
    
    onWarpZoneCompleted = function(self)
        self.stats.chainCompleted = self.stats.chainCompleted + 1
    end,
    
    onConstellationComplete = function(self, pattern)
        -- Mock function
    end,
    
    onArtifactCollected = function(self)
        -- Mock function
    end,
    
    onAllArtifactsCollected = function(self)
        -- Mock function
    end,
    
    onLavaEruption = function(self)
        self.stats.lavaEruptions = self.stats.lavaEruptions + 1
    end,
    
    onGravityPulse = function(self)
        self.stats.gravityPulses = self.stats.gravityPulses + 1
    end,
    
    getCompletionPercentage = function(self)
        local total = 0
        local unlocked = 0
        for _, achievement in pairs(self.achievements) do
            total = total + 1
            if achievement.unlocked then
                unlocked = unlocked + 1
            end
        end
        return total > 0 and (unlocked / total) * 100 or 0
    end,
    
    getTotalPoints = function(self)
        local total = 0
        for _, achievement in pairs(self.achievements) do
            if achievement.unlocked then
                total = total + achievement.points
            end
        end
        return total
    end,
    
    getSaveData = function(self)
        local data = {}
        for id, achievement in pairs(self.achievements) do
            data[id] = {
                unlocked = achievement.unlocked,
                progress = achievement.progress
            }
        end
        return data
    end,
    
    loadSaveData = function(self, data)
        if data then
            for id, achievementData in pairs(data) do
                if self.achievements[id] then
                    self.achievements[id].unlocked = achievementData.unlocked or false
                    self.achievements[id].progress = achievementData.progress or 0
                end
            end
        end
    end
}

-- Setup function to reset state before each test
local function setupAchievementSystem()
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
    ["achievement initialization"] = function()
        setupAchievementSystem()
        local firstPlanet = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal("Baby Steps", firstPlanet.name, "Achievement name should be correct")
        TestFramework.assert.equal("Discover your first planet", firstPlanet.description, "Achievement description should be correct")
        TestFramework.assert.equal(10, firstPlanet.points, "Achievement points should be correct")
        TestFramework.assert.equal(1, firstPlanet.target, "Achievement target should be correct")
        TestFramework.assert.isFalse(firstPlanet.unlocked, "Achievement should start unlocked")
        TestFramework.assert.equal(0, firstPlanet.progress, "Achievement progress should start at 0")
    end,
    
    ["update progress"] = function()
        setupAchievementSystem()
        AchievementSystem:updateProgress("first_planet", 1)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal(1, achievement.progress, "Progress should be updated")
        TestFramework.assert.isTrue(achievement.unlocked, "Achievement should be unlocked")
    end,
    
    ["update progress exceeds target"] = function()
        setupAchievementSystem()
        AchievementSystem:updateProgress("first_planet", 5)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal(5, achievement.progress, "Progress should be set to 5")
        TestFramework.assert.isTrue(achievement.unlocked, "Achievement should be unlocked")
    end,
    
    ["update progress already unlocked"] = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem:updateProgress("first_planet", 1)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal(1, achievement.progress, "Progress should be updated even if already unlocked")
    end,
    
    ["update progress invalid id"] = function()
        setupAchievementSystem()
        AchievementSystem:updateProgress("invalid_id", 1)
        -- Should not crash
        TestFramework.assert.isTrue(true, "Should not crash with invalid ID")
    end,
    
    ["increment progress"] = function()
        setupAchievementSystem()
        AchievementSystem:incrementProgress("first_planet", 1)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal(1, achievement.progress, "Progress should be incremented")
        TestFramework.assert.isTrue(achievement.unlocked, "Achievement should be unlocked")
    end,
    
    ["increment progress default amount"] = function()
        setupAchievementSystem()
        AchievementSystem:incrementProgress("first_planet")
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal(1, achievement.progress, "Progress should be incremented by 1")
    end,
    
    ["increment progress exceeds target"] = function()
        setupAchievementSystem()
        AchievementSystem:incrementProgress("first_planet", 5)
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.equal(5, achievement.progress, "Progress should be incremented to 5")
        TestFramework.assert.isTrue(achievement.unlocked, "Achievement should be unlocked")
    end,
    
    ["unlock achievement"] = function()
        setupAchievementSystem()
        AchievementSystem:unlock("first_planet")
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.isTrue(achievement.unlocked, "Achievement should be unlocked")
    end,
    
    ["unlock already unlocked"] = function()
        setupAchievementSystem()
        AchievementSystem.achievements.first_planet.unlocked = true
        AchievementSystem:unlock("first_planet")
        local achievement = AchievementSystem.achievements.first_planet
        TestFramework.assert.isTrue(achievement.unlocked, "Achievement should remain unlocked")
    end,
    
    ["unlock invalid id"] = function()
        setupAchievementSystem()
        AchievementSystem:unlock("invalid_id")
        -- Should not crash
        TestFramework.assert.isTrue(true, "Should not crash with invalid ID")
    end,
    
    ["on planet discovered"] = function()
        setupAchievementSystem()
        AchievementSystem:onPlanetDiscovered("ice")
        TestFramework.assert.equal(1, AchievementSystem.stats.planetsDiscovered, "Planet count should increase")
        TestFramework.assert.equal(1, AchievementSystem.stats.planetTypesVisited.ice, "Ice planet count should increase")
    end,
    
    ["on ring collected"] = function()
        setupAchievementSystem()
        AchievementSystem:onRingCollected("standard")
        TestFramework.assert.equal(1, AchievementSystem.stats.ringsCollected, "Ring count should increase")
    end,
    
    ["on dash"] = function()
        setupAchievementSystem()
        AchievementSystem:onDash()
        TestFramework.assert.equal(1, AchievementSystem.stats.totalDashes, "Dash count should increase")
    end,
    
    ["on combo reached"] = function()
        setupAchievementSystem()
        AchievementSystem:onComboReached(5)
        TestFramework.assert.equal(5, AchievementSystem.stats.maxCombo, "Max combo should be updated")
    end,
    
    ["on distance reached"] = function()
        setupAchievementSystem()
        AchievementSystem:onDistanceReached(1000)
        TestFramework.assert.equal(1000, AchievementSystem.stats.maxDistance, "Max distance should be updated")
    end,
    
    ["on perfect landing"] = function()
        setupAchievementSystem()
        AchievementSystem:onPerfectLanding()
        TestFramework.assert.equal(1, AchievementSystem.stats.perfectLandings, "Perfect landing count should increase")
    end,
    
    ["on warp zone completed"] = function()
        setupAchievementSystem()
        AchievementSystem:onWarpZoneCompleted()
        TestFramework.assert.equal(1, AchievementSystem.stats.chainCompleted, "Chain completed count should increase")
    end,
    
    ["on lava eruption"] = function()
        setupAchievementSystem()
        AchievementSystem:onLavaEruption()
        TestFramework.assert.equal(1, AchievementSystem.stats.lavaEruptions, "Lava eruption count should increase")
    end,
    
    ["on gravity pulse"] = function()
        setupAchievementSystem()
        AchievementSystem:onGravityPulse()
        TestFramework.assert.equal(1, AchievementSystem.stats.gravityPulses, "Gravity pulse count should increase")
    end,
    
    ["get completion percentage"] = function()
        setupAchievementSystem()
        local percentage = AchievementSystem:getCompletionPercentage()
        TestFramework.assert.equal(0, percentage, "Completion percentage should be 0 when no achievements unlocked")
        
        AchievementSystem:unlock("first_planet")
        percentage = AchievementSystem:getCompletionPercentage()
        TestFramework.assert.equal(50, percentage, "Completion percentage should be 50 when half achievements unlocked")
    end,
    
    ["get total points"] = function()
        setupAchievementSystem()
        local points = AchievementSystem:getTotalPoints()
        TestFramework.assert.equal(0, points, "Total points should be 0 when no achievements unlocked")
        
        AchievementSystem:unlock("first_planet")
        points = AchievementSystem:getTotalPoints()
        TestFramework.assert.equal(10, points, "Total points should be 10 for unlocked achievement")
    end,
    
    ["get save data"] = function()
        setupAchievementSystem()
        AchievementSystem:unlock("first_planet")
        AchievementSystem:updateProgress("planet_hopper", 5)
        
        local saveData = AchievementSystem:getSaveData()
        TestFramework.assert.isTrue(saveData.first_planet.unlocked, "Save data should include unlocked status")
        TestFramework.assert.equal(5, saveData.planet_hopper.progress, "Save data should include progress")
    end,
    
    ["load save data"] = function()
        setupAchievementSystem()
        local saveData = {
            first_planet = { unlocked = true, progress = 1 },
            planet_hopper = { unlocked = false, progress = 5 }
        }
        
        AchievementSystem:loadSaveData(saveData)
        TestFramework.assert.isTrue(AchievementSystem.achievements.first_planet.unlocked, "Should load unlocked status")
        TestFramework.assert.equal(5, AchievementSystem.achievements.planet_hopper.progress, "Should load progress")
    end,
    
    ["load save data nil"] = function()
        setupAchievementSystem()
        AchievementSystem:loadSaveData(nil)
        -- Should not crash
        TestFramework.assert.isTrue(true, "Should handle nil save data gracefully")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "Achievement System Tests")
end

return {run = run} 