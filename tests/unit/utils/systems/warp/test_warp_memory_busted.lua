-- Unit tests for Warp Memory System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"

local Utils = require("src.utils.utils")
Utils.require("tests.busted")

-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Load WarpMemory
local WarpMemory = require("src.systems.warp.warp_memory")

describe("Warp Memory System", function()
    local mockMemory
    
    before_each(function()
        -- Initialize fresh memory for each test
        mockMemory = WarpMemory.init()
    end)
    
    describe("Initialization", function()
        it("should initialize proper memory structure", function()
            local memory = WarpMemory.init()
            
            assert.is_type("table", memory)
            assert.is_type("table", memory.routes)
            assert.is_type("table", memory.behaviorProfile)
            assert.is_type("table", memory.planetAffinity)
            assert.is_type("table", memory.efficiencyMetrics)
            assert.is_type("table", memory.emergencyPatterns)
        end)
        
        it("should initialize behavior profile with default values", function()
            local memory = WarpMemory.init()
            local profile = memory.behaviorProfile
            
            assert.equals(0, profile.totalWarps)
            assert.equals(0, profile.emergencyWarps)
            assert.equals(0, profile.explorationWarps)
            assert.equals(0, profile.returnWarps)
            assert.equals(0, profile.averageWarpDistance)
            assert.equals(0, profile.skillLevel)
        end)
        
        it("should initialize efficiency metrics", function()
            local memory = WarpMemory.init()
            local metrics = memory.efficiencyMetrics
            
            assert.equals(0, metrics.wastedEnergy)
            assert.equals(0, metrics.optimalRoutes)
            assert.is_type("table", metrics.learningCurve)
            assert.equals(0, metrics.adaptationLevel)
        end)
    end)
    
    describe("Route Key Generation", function()
        it("should generate consistent route keys", function()
            local targetPlanet = {id = "planet1", x = 100, y = 200}
            
            local key = WarpMemory.generateRouteKey(50, 75, targetPlanet)
            
            assert.is_type("string", key)
            assert.contains(key, "->")
            assert.contains(key, "planet1")
        end)
        
        it("should handle planets without IDs", function()
            local targetPlanet = {x = 300, y = 400}
            
            local key = WarpMemory.generateRouteKey(100, 200, targetPlanet)
            
            assert.is_type("string", key)
            assert.contains(key, "->")
            -- Should use coordinates when no ID
            assert.contains(key, "300")
            assert.contains(key, "400")
        end)
        
        it("should generate different keys for different routes", function()
            local planet1 = {id = "planet1"}
            local planet2 = {id = "planet2"}
            
            local key1 = WarpMemory.generateRouteKey(0, 0, planet1)
            local key2 = WarpMemory.generateRouteKey(0, 0, planet2)
            
            assert.not_equal(key1, key2)
        end)
        
        it("should generate same keys for same routes", function()
            local planet = {id = "test_planet"}
            
            local key1 = WarpMemory.generateRouteKey(100, 100, planet)
            local key2 = WarpMemory.generateRouteKey(100, 100, planet)
            
            assert.equals(key1, key2)
        end)
    end)
    
    describe("Memory Data Integrity", function()
        it("should maintain separate memory instances", function()
            local memory1 = WarpMemory.init()
            local memory2 = WarpMemory.init()
            
            memory1.behaviorProfile.totalWarps = 5
            
            assert.equals(5, memory1.behaviorProfile.totalWarps)
            assert.equals(0, memory2.behaviorProfile.totalWarps)
        end)
        
        it("should handle empty route data", function()
            local memory = WarpMemory.init()
            
            assert.is_empty(memory.routes)
            assert.is_empty(memory.planetAffinity)
        end)
        
        it("should provide access to all memory components", function()
            local memory = WarpMemory.init()
            
            -- Should be able to access all main components
            assert.is_not_nil(memory.routes)
            assert.is_not_nil(memory.behaviorProfile)
            assert.is_not_nil(memory.planetAffinity)
            assert.is_not_nil(memory.efficiencyMetrics)
            assert.is_not_nil(memory.emergencyPatterns)
        end)
    end)
    
    describe("Route Key Edge Cases", function()
        it("should handle zero coordinates", function()
            local planet = {id = "origin"}
            
            local key = WarpMemory.generateRouteKey(0, 0, planet)
            
            assert.is_type("string", key)
            assert.contains(key, "0,0->")
        end)
        
        it("should handle negative coordinates", function()
            local planet = {id = "negative_zone"}
            
            local key = WarpMemory.generateRouteKey(-100, -200, planet)
            
            assert.is_type("string", key)
            -- Should handle negative coordinates properly
            assert.is_not_nil(key)
        end)
        
        it("should handle large coordinates", function()
            local planet = {id = "far_planet"}
            
            local key = WarpMemory.generateRouteKey(99999, 88888, planet)
            
            assert.is_type("string", key)
            assert.is_not_nil(key)
        end)
        
        it("should handle fractional coordinates", function()
            local planet = {id = "precise_planet"}
            
            local key = WarpMemory.generateRouteKey(123.456, 789.123, planet)
            
            assert.is_type("string", key)
            -- Should floor coordinates
            assert.contains(key, "1,7->")
        end)
        
        it("should handle missing planet data gracefully", function()
            local planet = {} -- Empty planet
            
            -- This might fail if the implementation doesn't handle nil values
            assert.has_error(function()
                WarpMemory.generateRouteKey(100, 200, planet)
            end, "Should handle missing planet data appropriately")
        end)
    end)
    
    describe("Memory Structure Validation", function()
        it("should have proper table structures", function()
            local memory = WarpMemory.init()
            
            -- Behavior profile should have all expected fields
            local profile = memory.behaviorProfile
            assert.is_type("number", profile.totalWarps)
            assert.is_type("number", profile.emergencyWarps)
            assert.is_type("number", profile.explorationWarps)
            assert.is_type("number", profile.returnWarps)
            assert.is_type("number", profile.averageWarpDistance)
            assert.is_type("table", profile.preferredWarpTimes)
            assert.is_type("number", profile.skillLevel)
            assert.is_type("number", profile.lastWarpTime)
            assert.is_type("number", profile.warpChains)
        end)
        
        it("should have emergency patterns structure", function()
            local memory = WarpMemory.init()
            local emergency = memory.emergencyPatterns
            
            assert.is_type("number", emergency.lowHealthWarps)
            assert.is_type("number", emergency.panicWarps)
            assert.is_type("number", emergency.rescueWarps)
            assert.is_type("number", emergency.lastEmergencyTime)
        end)
        
        it("should initialize all counters to zero", function()
            local memory = WarpMemory.init()
            
            assert.equals(0, memory.behaviorProfile.totalWarps)
            assert.equals(0, memory.emergencyPatterns.lowHealthWarps)
            assert.equals(0, memory.efficiencyMetrics.wastedEnergy)
        end)
    end)
end)