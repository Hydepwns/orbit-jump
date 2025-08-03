-- Unit tests for Behavior Tracker System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Load BehaviorTracker
local BehaviorTracker = require("src.systems.analytics.behavior_tracker")
describe("Behavior Tracker System", function()
    before_each(function()
        -- Reset tracking state before each test
        if BehaviorTracker.init then
            BehaviorTracker.init()
        end
    end)
    describe("Movement Profile", function()
        it("should have movement profile structure", function()
            local profile = BehaviorTracker.movementProfile
            assert.is_type("table", profile)
            assert.is_type("number", profile.preferredJumpPower)
            assert.is_type("number", profile.jumpPowerVariance)
            assert.is_type("number", profile.averageJumpDistance)
            assert.is_type("number", profile.riskTolerance)
            assert.is_type("number", profile.planningTime)
            assert.is_type("number", profile.totalJumps)
            assert.is_type("number", profile.totalDistance)
        end)
        it("should have movement efficiency metrics", function()
            local profile = BehaviorTracker.movementProfile
            assert.is_type("number", profile.wastedMovement)
            assert.is_type("number", profile.efficientPaths)
            assert.is_type("number", profile.creativePaths)
        end)
        it("should have spatial awareness metrics", function()
            local profile = BehaviorTracker.movementProfile
            assert.is_type("number", profile.collisionRate)
            assert.is_type("number", profile.nearMissRate)
            assert.is_type("number", profile.spatialMastery)
        end)
        it("should initialize with default values", function()
            local profile = BehaviorTracker.movementProfile
            -- Most metrics should start at 0
            assert.equals(0, profile.preferredJumpPower)
            assert.equals(0, profile.totalJumps)
            assert.equals(0, profile.totalDistance)
            assert.equals(0, profile.wastedMovement)
        end)
    end)
    describe("Exploration Profile", function()
        it("should have exploration profile structure", function()
            local profile = BehaviorTracker.explorationProfile
            assert.is_type("table", profile)
            assert.is_type("string", profile.explorationStyle)
            assert.is_type("number", profile.newPlanetAttempts)
            assert.is_type("number", profile.newPlanetSuccesses)
            assert.is_type("number", profile.explorationEfficiency)
        end)
        it("should have discovery pattern metrics", function()
            local profile = BehaviorTracker.explorationProfile
            assert.is_type("number", profile.averageTimeToRevisit)
            assert.is_type("table", profile.planetVisitDistribution)
            assert.is_type("number", profile.explorationRadius)
        end)
        it("should have learning curve metrics", function()
            local profile = BehaviorTracker.explorationProfile
            assert.is_type("number", profile.discoveryMomentum)
            assert.is_type("number", profile.comfortZoneSize)
            assert.is_type("number", profile.expansionRate)
        end)
        it("should initialize with default exploration style", function()
            local profile = BehaviorTracker.explorationProfile
            assert.equals("unknown", profile.explorationStyle)
            assert.equals(0, profile.newPlanetAttempts)
            assert.equals(0, profile.newPlanetSuccesses)
        end)
    end)
    describe("Data Integrity", function()
        it("should maintain separate profile structures", function()
            local movementProfile = BehaviorTracker.movementProfile
            local explorationProfile = BehaviorTracker.explorationProfile
            -- Should be different objects
            assert.not_equal(movementProfile, explorationProfile)
            -- Should have different field sets
            assert.is_not_nil(movementProfile.totalJumps)
            assert.is_nil(movementProfile.explorationStyle)
            assert.is_not_nil(explorationProfile.explorationStyle)
            assert.is_nil(explorationProfile.totalJumps)
        end)
        it("should handle profile modifications", function()
            local profile = BehaviorTracker.movementProfile
            local originalJumps = profile.totalJumps
            profile.totalJumps = originalJumps + 1
            assert.equals(originalJumps + 1, profile.totalJumps)
        end)
        it("should allow exploration style changes", function()
            local profile = BehaviorTracker.explorationProfile
            profile.explorationStyle = "methodical"
            assert.equals("methodical", profile.explorationStyle)
        end)
    end)
    describe("Profile Access", function()
        it("should provide read access to movement metrics", function()
            local profile = BehaviorTracker.movementProfile
            -- Should be able to read all metrics without errors
            local _ = profile.preferredJumpPower
            local _ = profile.riskTolerance
            local _ = profile.spatialMastery
            local _ = profile.collisionRate
            -- If we get here, all accesses succeeded
            assert.is_true(true)
        end)
        it("should provide read access to exploration metrics", function()
            local profile = BehaviorTracker.explorationProfile
            -- Should be able to read all metrics without errors
            local _ = profile.explorationStyle
            local _ = profile.explorationEfficiency
            local _ = profile.discoveryMomentum
            local _ = profile.planetVisitDistribution
            -- If we get here, all accesses succeeded
            assert.is_true(true)
        end)
        it("should handle missing fields gracefully", function()
            local profile = BehaviorTracker.movementProfile
            -- Accessing non-existent field should return nil
            assert.is_nil(profile.nonExistentField)
        end)
    end)
    describe("Metric Ranges", function()
        it("should have risk tolerance in valid range", function()
            local profile = BehaviorTracker.movementProfile
            -- Risk tolerance should be 0-1 range
            assert.is_true(profile.riskTolerance >= 0)
            assert.is_true(profile.riskTolerance <= 1)
        end)
        it("should have spatial mastery in valid range", function()
            local profile = BehaviorTracker.movementProfile
            -- Spatial mastery should be 0-1 range
            assert.is_true(profile.spatialMastery >= 0)
            assert.is_true(profile.spatialMastery <= 1)
        end)
        it("should have non-negative counters", function()
            local profile = BehaviorTracker.movementProfile
            assert.greater_or_equal(0, profile.totalJumps)
            assert.greater_or_equal(0, profile.totalDistance)
            assert.greater_or_equal(0, profile.wastedMovement)
            assert.greater_or_equal(0, profile.efficientPaths)
        end)
        it("should have non-negative exploration counters", function()
            local profile = BehaviorTracker.explorationProfile
            assert.greater_or_equal(0, profile.newPlanetAttempts)
            assert.greater_or_equal(0, profile.newPlanetSuccesses)
            assert.greater_or_equal(0, profile.explorationRadius)
        end)
    end)
end)