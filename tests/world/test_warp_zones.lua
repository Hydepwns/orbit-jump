-- Tests for Warp Zones system
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Function to get WarpZones with proper initialization
local function getWarpZones()
    -- Clear any cached version
    package.loaded["src.systems.warp_zones"] = nil
    package.loaded["src/systems/warp_zones"] = nil
    
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.warp_zones"] = nil
    end
    
    -- Setup mocks before loading
    Mocks.setup()
    
    -- Load fresh instance using regular require to bypass cache
    local WarpZones = require("src.systems.warp_zones")
    
    -- Ensure it's initialized
    if WarpZones and WarpZones.init then
        WarpZones.init()
    end
    
    return WarpZones
end

-- Test suite
local tests = {
    ["warp zones initialization"] = function()
        local WarpZones = getWarpZones()
        TestFramework.assert.notNil(WarpZones.activeZones, "Active zones should be initialized")
        TestFramework.assert.notNil(WarpZones.zoneTypes, "Zone types should be defined")
        TestFramework.assert.isNil(WarpZones.currentChallenge, "Should start with no challenge")
        TestFramework.assert.equal(0, WarpZones.portalPhase, "Portal phase should start at 0")
    end,
    
    ["warp zone types"] = function()
        local WarpZones = getWarpZones()
        
        TestFramework.assert.notNil(WarpZones.zoneTypes.ring_gauntlet, "Ring gauntlet type should exist")
        TestFramework.assert.notNil(WarpZones.zoneTypes.gravity_maze, "Gravity maze type should exist")
        TestFramework.assert.notNil(WarpZones.zoneTypes.speed_run, "Speed run type should exist")
        TestFramework.assert.notNil(WarpZones.zoneTypes.void_challenge, "Void challenge type should exist")
        TestFramework.assert.notNil(WarpZones.zoneTypes.quantum_puzzle, "Quantum puzzle type should exist")
        
        -- Check zone type properties
        local ringGauntlet = WarpZones.zoneTypes.ring_gauntlet
        TestFramework.assert.notNil(ringGauntlet.name, "Zone type should have name")
        TestFramework.assert.notNil(ringGauntlet.description, "Zone type should have description")
        TestFramework.assert.notNil(ringGauntlet.color, "Zone type should have color")
        TestFramework.assert.notNil(ringGauntlet.difficulty, "Zone type should have difficulty")
        TestFramework.assert.notNil(ringGauntlet.reward, "Zone type should have reward")
    end,
    
    ["generate warp zones"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock random to ensure generation
        local oldRandom = math.random
        math.random = function(n)
            if n == nil then return 0.005 end -- Force generation (< 0.01)
            if type(n) == "number" then return 1 end
            return oldRandom(n)
        end
        
        -- Mock player far from origin
        local player = {x = 2000, y = 2000}
        local existingPlanets = {}
        
        -- Generate zones
        WarpZones.generateAroundPlayer(player, existingPlanets)
        
        TestFramework.assert.isTrue(#WarpZones.activeZones > 0, "Should generate at least one zone")
        
        local zone = WarpZones.activeZones[1]
        TestFramework.assert.notNil(zone.x, "Zone should have x position")
        TestFramework.assert.notNil(zone.y, "Zone should have y position")
        TestFramework.assert.notNil(zone.type, "Zone should have type")
        TestFramework.assert.notNil(zone.data, "Zone should have data")
        
        math.random = oldRandom
    end,
    
    ["check player entry"] = function()
        local WarpZones = getWarpZones()
        
        -- Create a zone manually
        local zone = {
            x = 100,
            y = 100,
            radius = 50,
            type = "ring_gauntlet",
            data = WarpZones.zoneTypes.ring_gauntlet,
            discovered = false
        }
        table.insert(WarpZones.activeZones, zone)
        
        -- Mock dependencies
        Utils.moduleCache["src.systems.achievement_system"] = {
            onWarpZoneDiscovered = function() end,
            onWarpZoneCompleted = function() end
        }
        Utils.moduleCache["src.audio.sound_manager"] = {
            playEventWarning = function() end
        }
        Utils.moduleCache["src.core.game_state"] = {
            clearForChallenge = function() end,
            setPlanets = function() end,
            setRings = function() end
        }
        
        -- Player outside zone
        local player = {x = 200, y = 200}
        local entered = WarpZones.checkEntry(player)
        TestFramework.assert.isFalse(entered, "Player outside should not enter")
        
        -- Player inside zone
        player.x = 100
        player.y = 100
        entered = WarpZones.checkEntry(player)
        TestFramework.assert.isTrue(entered, "Player inside should enter zone")
        TestFramework.assert.isTrue(zone.discovered, "Zone should be discovered")
        TestFramework.assert.notNil(WarpZones.currentChallenge, "Should have current challenge")
    end,
    
    ["enter challenge"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock dependencies
        Utils.moduleCache["src.audio.sound_manager"] = {
            playEventWarning = function() end
        }
        Utils.moduleCache["src.core.game_state"] = {
            clearForChallenge = function() end,
            setPlanets = function() end,
            setRings = function() end
        }
        Utils.moduleCache["src.systems.ring_system"] = {}
        
        local zone = {
            x = 100,
            y = 100,
            type = "ring_gauntlet",
            data = WarpZones.zoneTypes.ring_gauntlet
        }
        
        local player = {x = 100, y = 100, vx = 0, vy = 0}
        
        WarpZones.enterChallenge(zone, player)
        
        TestFramework.assert.equal(zone, WarpZones.currentChallenge, "Should set current challenge")
        TestFramework.assert.notNil(WarpZones.originalPlayerPos, "Should save original position")
        TestFramework.assert.equal(30, WarpZones.challengeTimer, "Should set challenge timer")
    end,
    
    ["update portal animation"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock dependencies
        Utils.moduleCache["src.core.game_state"] = {
            getPlanets = function() return {} end
        }
        
        local player = {x = 0, y = 0}
        local initialPhase = WarpZones.portalPhase
        
        WarpZones.update(0.1, player)
        
        TestFramework.assert.isTrue(WarpZones.portalPhase > initialPhase, "Portal phase should increase")
    end,
    
    ["complete challenge success"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock dependencies
        Utils.moduleCache["src.core.game_state"] = {
            addScore = function() end,
            player = {x = 0, y = 0},
            restoreFromChallenge = function() end
        }
        Utils.moduleCache["src.systems.achievement_system"] = {
            onWarpZoneCompleted = function() end
        }
        Utils.moduleCache["src.systems.upgrade_system"] = {
            addCurrency = function() end
        }
        Utils.moduleCache["src.audio.sound_manager"] = {
            playCombo = function() end
        }
        
        -- Setup challenge
        WarpZones.currentChallenge = {
            type = "ring_gauntlet",
            data = {reward = 500}
        }
        WarpZones.originalPlayerPos = {x = 100, y = 100}
        
        WarpZones.completeChallenge(true)
        
        TestFramework.assert.isNil(WarpZones.currentChallenge, "Challenge should be cleared")
        TestFramework.assert.isNil(WarpZones.originalPlayerPos, "Original position should be cleared")
    end,
    
    ["remove distant zones"] = function()
        local WarpZones = getWarpZones()
        
        -- Clear any existing zones first
        WarpZones.activeZones = {}
        
        -- Create zones at different distances
        table.insert(WarpZones.activeZones, {
            x = 100, y = 100, radius = 50,
            type = "ring_gauntlet",
            data = WarpZones.zoneTypes.ring_gauntlet
        })
        table.insert(WarpZones.activeZones, {
            x = 6000, y = 6000, radius = 50,  -- Just over 5000 distance threshold
            type = "ring_gauntlet",
            data = WarpZones.zoneTypes.ring_gauntlet
        })
        
        TestFramework.assert.equal(2, #WarpZones.activeZones, "Should start with 2 zones")
        
        local player = {x = 1500, y = 1500}  -- Not at origin to avoid early return
        WarpZones.generateAroundPlayer(player, {})
        
        TestFramework.assert.equal(1, #WarpZones.activeZones, "Distant zone should be removed")
        TestFramework.assert.equal(100, WarpZones.activeZones[1].x, "Only nearby zone should remain")
    end,
    
    ["create ring gauntlet"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock dependencies
        local planets = nil
        local rings = nil
        
        Utils.moduleCache["src.core.game_state"] = {
            clearForChallenge = function() end,
            setPlanets = function(p) planets = p end,
            setRings = function(r) rings = r end
        }
        Utils.moduleCache["src.systems.ring_system"] = {}
        
        local player = {x = 100, y = 100, vx = 10, vy = 10}
        
        WarpZones.createRingGauntlet(player)
        
        TestFramework.assert.notNil(planets, "Should create planets")
        TestFramework.assert.equal(8, #planets, "Should create 8 boundary planets")
        TestFramework.assert.notNil(rings, "Should create rings")
        TestFramework.assert.equal(30, #rings, "Should create 30 rings")
        TestFramework.assert.equal(0, player.vx, "Player velocity should be reset")
        TestFramework.assert.equal(0, player.vy, "Player velocity should be reset")
    end,
    
    ["update challenge timer"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock dependencies
        Utils.moduleCache["src.core.game_state"] = {
            getRings = function() return {{collected = false}} end
        }
        
        WarpZones.currentChallenge = {
            type = "ring_gauntlet",
            data = {reward = 500}
        }
        WarpZones.challengeTimer = 10
        
        local player = {}
        WarpZones.updateChallenge(1.0, player)
        
        TestFramework.assert.equal(9, WarpZones.challengeTimer, "Timer should decrease")
    end,
    
    ["challenge completion detection"] = function()
        local WarpZones = getWarpZones()
        
        -- Mock dependencies
        local completeCalled = false
        WarpZones.completeChallenge = function(success)
            completeCalled = success
        end
        
        Utils.moduleCache["src.core.game_state"] = {
            getRings = function() return {{collected = true}, {collected = true}} end
        }
        
        WarpZones.currentChallenge = {
            type = "ring_gauntlet",
            data = {reward = 500}
        }
        WarpZones.challengeTimer = 5
        
        local player = {}
        WarpZones.updateChallenge(0.1, player)
        
        TestFramework.assert.isTrue(completeCalled, "Should complete challenge when all rings collected")
    end,
}

local function run()
    -- Initialize test framework
    Mocks.setup()
    TestFramework.init()
    
    local success = TestFramework.runTests(tests, "Warp Zones Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("warp_zones", 12) -- Major functions tested
    
    return success
end

return {run = run}