-- Unit tests for Warp Navigation System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"

local Utils = require("src.utils.utils")
Utils.require("tests.busted")

-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()

-- Mock Utils.distance function
local originalDistance = Utils.distance
Utils.distance = function(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Load WarpNavigation
local WarpNavigation = require("src.systems.warp.warp_navigation")

describe("Warp Navigation System", function()
    before_each(function()
        -- Reset navigation state
        WarpNavigation.isSelecting = false
        WarpNavigation.selectedPlanet = nil
        WarpNavigation.selectionRadius = 50
    end)
    
    describe("Distance Calculation", function()
        it("should calculate distance between two points", function()
            local distance = WarpNavigation.calculateDistance(0, 0, 3, 4)
            
            assert.equals(5, distance)
        end)
        
        it("should handle same position", function()
            local distance = WarpNavigation.calculateDistance(100, 200, 100, 200)
            
            assert.equals(0, distance)
        end)
        
        it("should handle negative coordinates", function()
            local distance = WarpNavigation.calculateDistance(-1, -1, 2, 3)
            
            assert.equals(5, distance)
        end)
        
        it("should calculate large distances correctly", function()
            local distance = WarpNavigation.calculateDistance(0, 0, 1000, 1000)
            
            assert.near(1414.21, distance, 0.1) -- √2 * 1000
        end)
    end)
    
    describe("Warp Affordability", function()
        local mockPlayer, mockPlanet, mockCalculateCost
        
        before_each(function()
            mockPlayer = {x = 100, y = 100}
            mockPlanet = {x = 200, y = 200, discovered = true}
            mockCalculateCost = function(distance, px, py, planet)
                return math.floor(distance / 10) -- Simple cost calculation
            end
        end)
        
        it("should return false if warp drive is not unlocked", function()
            local canAfford = WarpNavigation.canAffordWarp(mockPlanet, mockPlayer, 1000, mockCalculateCost, false)
            
            assert.is_false(canAfford)
        end)
        
        it("should return false if planet is not discovered", function()
            mockPlanet.discovered = false
            
            local canAfford = WarpNavigation.canAffordWarp(mockPlanet, mockPlayer, 1000, mockCalculateCost, true)
            
            assert.is_false(canAfford)
        end)
        
        it("should return true if player has enough energy", function()
            local canAfford = WarpNavigation.canAffordWarp(mockPlanet, mockPlayer, 1000, mockCalculateCost, true)
            
            assert.is_true(canAfford)
        end)
        
        it("should return false if player lacks energy", function()
            local canAfford = WarpNavigation.canAffordWarp(mockPlanet, mockPlayer, 5, mockCalculateCost, true)
            
            assert.is_false(canAfford)
        end)
        
        it("should use cost calculation function correctly", function()
            local costCallCount = 0
            local testCostFn = function(distance, px, py, planet)
                costCallCount = costCallCount + 1
                return 50 -- Fixed cost
            end
            
            WarpNavigation.canAffordWarp(mockPlanet, mockPlayer, 100, testCostFn, true)
            
            assert.equals(1, costCallCount)
        end)
    end)
    
    describe("Selection Mode Toggle", function()
        it("should toggle selection mode when unlocked and not warping", function()
            local result = WarpNavigation.toggleSelection(true, false)
            
            assert.is_true(result)
            assert.is_true(WarpNavigation.isSelecting)
        end)
        
        it("should not toggle when warp drive is locked", function()
            local result = WarpNavigation.toggleSelection(false, false)
            
            assert.is_false(result)
            assert.is_false(WarpNavigation.isSelecting)
        end)
        
        it("should not toggle when already warping", function()
            local result = WarpNavigation.toggleSelection(true, true)
            
            assert.is_false(result)
            assert.is_false(WarpNavigation.isSelecting)
        end)
        
        it("should toggle off when called again", function()
            WarpNavigation.toggleSelection(true, false) -- Turn on
            local result = WarpNavigation.toggleSelection(true, false) -- Turn off
            
            assert.is_false(result)
            assert.is_false(WarpNavigation.isSelecting)
        end)
        
        it("should clear selected planet when toggling", function()
            WarpNavigation.selectedPlanet = {id = "test"}
            
            WarpNavigation.toggleSelection(true, false)
            
            assert.is_nil(WarpNavigation.selectedPlanet)
        end)
    end)
    
    describe("Planet Selection", function()
        local mockPlanets, mockPlayer, mockCanAfford, mockStartWarp
        
        before_each(function()
            mockPlanets = {
                {x = 100, y = 100, discovered = true, radius = 20, id = "planet1"},
                {x = 200, y = 200, discovered = true, radius = 30, id = "planet2"},
                {x = 300, y = 100, discovered = false, radius = 25, id = "planet3"} -- Not discovered
            }
            mockPlayer = {x = 50, y = 50}
            mockCanAfford = function() return true end
            mockStartWarp = spy()
            
            -- Enable selection mode
            WarpNavigation.isSelecting = true
        end)
        
        it("should return nil when not in selection mode", function()
            WarpNavigation.isSelecting = false
            
            local result = WarpNavigation.selectPlanetAt(100, 100, mockPlanets, mockPlayer, mockCanAfford, mockStartWarp)
            
            assert.is_nil(result)
        end)
        
        it("should select closest discovered planet within range", function()
            local result = WarpNavigation.selectPlanetAt(105, 105, mockPlanets, mockPlayer, mockCanAfford, mockStartWarp)
            
            assert.is_not_nil(result)
            assert.equals("planet1", result.id)
        end)
        
        it("should not select undiscovered planets", function()
            local result = WarpNavigation.selectPlanetAt(300, 100, mockPlanets, mockPlayer, mockCanAfford, mockStartWarp)
            
            assert.is_nil(result)
        end)
        
        it("should not select planets outside selection radius", function()
            WarpNavigation.selectionRadius = 10 -- Very small radius
            
            local result = WarpNavigation.selectPlanetAt(150, 150, mockPlanets, mockPlayer, mockCanAfford, mockStartWarp)
            
            assert.is_nil(result)
        end)
        
        it("should consider planet radius in selection", function()
            -- Click just outside selection radius but within planet radius
            local result = WarpNavigation.selectPlanetAt(130, 130, mockPlanets, mockPlayer, mockCanAfford, mockStartWarp)
            
            -- Should still select planet1 due to its radius
            assert.is_not_nil(result)
        end)
        
        it("should select closer planet when multiple are in range", function()
            -- Add another planet closer to click position
            table.insert(mockPlanets, {x = 110, y = 110, discovered = true, radius = 15, id = "planet4"})
            
            local result = WarpNavigation.selectPlanetAt(105, 105, mockPlanets, mockPlayer, mockCanAfford, mockStartWarp)
            
            assert.equals("planet1", result.id) -- Still closest to click
        end)
    end)
    
    describe("Selection State Management", function()
        it("should initialize with correct default values", function()
            assert.is_false(WarpNavigation.isSelecting)
            assert.is_nil(WarpNavigation.selectedPlanet)
            assert.equals(50, WarpNavigation.selectionRadius)
        end)
        
        it("should maintain selection state independently", function()
            WarpNavigation.isSelecting = true
            WarpNavigation.selectedPlanet = {id = "test"}
            
            assert.is_true(WarpNavigation.isSelecting)
            assert.is_not_nil(WarpNavigation.selectedPlanet)
        end)
        
        it("should allow selection radius modification", function()
            WarpNavigation.selectionRadius = 100
            
            assert.equals(100, WarpNavigation.selectionRadius)
        end)
    end)
    
    describe("Edge Cases", function()
        it("should handle empty planet list", function()
            WarpNavigation.isSelecting = true
            
            local result = WarpNavigation.selectPlanetAt(100, 100, {}, {}, function() return true end, spy())
            
            assert.is_nil(result)
        end)
        
        it("should handle nil planet list", function()
            WarpNavigation.isSelecting = true
            
            assert.has_error(function()
                WarpNavigation.selectPlanetAt(100, 100, nil, {}, function() return true end, spy())
            end)
        end)
        
        it("should handle zero selection radius", function()
            WarpNavigation.selectionRadius = 0
            WarpNavigation.isSelecting = true
            
            local planets = {{x = 100, y = 100, discovered = true, radius = 20}}
            local result = WarpNavigation.selectPlanetAt(100, 100, planets, {}, function() return true end, spy())
            
            -- Should still work due to planet radius
            assert.is_not_nil(result)
        end)
        
        it("should handle cost calculation function errors", function()
            local errorCostFn = function() error("Cost calculation failed") end
            
            assert.has_error(function()
                WarpNavigation.canAffordWarp({discovered = true, x = 100, y = 100}, {x = 0, y = 0}, 1000, errorCostFn, true)
            end)
        end)
    end)
    
    describe("Integration Scenarios", function()
        it("should handle complete selection workflow", function()
            local planets = {{x = 100, y = 100, discovered = true, radius = 20, id = "target"}}
            local startWarpSpy = spy()
            
            -- Start selection mode
            WarpNavigation.toggleSelection(true, false)
            assert.is_true(WarpNavigation.isSelecting)
            
            -- Select a planet
            local result = WarpNavigation.selectPlanetAt(100, 100, planets, {}, function() return true end, startWarpSpy)
            
            assert.is_not_nil(result)
            assert.equals("target", result.id)
        end)
        
        it("should respect energy constraints", function()
            local planet = {x = 1000, y = 1000, discovered = true} -- Far away
            local player = {x = 0, y = 0}
            local expensiveCostFn = function() return 9999 end -- Very expensive
            
            local canAfford = WarpNavigation.canAffordWarp(planet, player, 100, expensiveCostFn, true)
            
            assert.is_false(canAfford)
        end)
    end)
end)