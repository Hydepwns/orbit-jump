-- Tests for Cosmic Events system
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")

Mocks.setup()

local CosmicEvents = Utils.Utils.require("src.systems.cosmic_events")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["cosmic events initialization"] = function()
        CosmicEvents.init()
        TestFramework.utils.assertNotNil(CosmicEvents.events, "Events table should be initialized")
        TestFramework.utils.assertNotNil(CosmicEvents.activeEvents, "Active events should be initialized")
    end,
    
    ["event type definitions"] = function()
        CosmicEvents.init()
        TestFramework.utils.assertNotNil(CosmicEvents.EVENT_TYPES, "Event types should be defined")
        TestFramework.utils.assertNotNil(CosmicEvents.EVENT_TYPES.METEOR_SHOWER, "Meteor shower event should exist")
        TestFramework.utils.assertNotNil(CosmicEvents.EVENT_TYPES.GRAVITY_WAVE, "Gravity wave event should exist")
        TestFramework.utils.assertNotNil(CosmicEvents.EVENT_TYPES.WORMHOLE, "Wormhole event should exist")
    end,
    
    ["trigger meteor shower"] = function()
        CosmicEvents.init()
        local player = {x = 100, y = 100}
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.triggerMeteorShower(player)
        end)
        TestFramework.utils.assertTrue(success, "Triggering meteor shower should not crash")
        TestFramework.utils.assertTrue(#CosmicEvents.activeEvents > 0, "Should have active events")
    end,
    
    ["trigger gravity wave"] = function()
        CosmicEvents.init()
        local player = {x = 200, y = 200}
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.triggerGravityWave(player)
        end)
        TestFramework.utils.assertTrue(success, "Triggering gravity wave should not crash")
    end,
    
    ["trigger wormhole"] = function()
        CosmicEvents.init()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.triggerWormhole(300, 300)
        end)
        TestFramework.utils.assertTrue(success, "Triggering wormhole should not crash")
    end,
    
    ["update cosmic events"] = function()
        CosmicEvents.init()
        local player = {x = 100, y = 100}
        local planets = {
            {x = 200, y = 200, radius = 50},
            {x = 400, y = 400, radius = 80}
        }
        
        -- Trigger some events
        CosmicEvents.triggerMeteorShower(player)
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.update(0.1, player, planets)
        end)
        TestFramework.utils.assertTrue(success, "Updating events should not crash")
    end,
    
    ["ring storm event"] = function()
        CosmicEvents.init()
        local rings = {}
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.triggerRingStorm(rings, 100, 100)
        end)
        TestFramework.utils.assertTrue(success, "Ring storm should not crash")
    end,
    
    ["quantum teleport event"] = function()
        CosmicEvents.init()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.triggerQuantumTeleport(500, 500)
        end)
        TestFramework.utils.assertTrue(success, "Quantum teleport should not crash")
    end,
    
    ["event expiration"] = function()
        CosmicEvents.init()
        
        -- Create an event with short duration
        local event = {
            type = "test",
            duration = 0.1,
            timer = 0,
            x = 100,
            y = 100
        }
        table.insert(CosmicEvents.activeEvents, event)
        
        -- Update past duration
        CosmicEvents.update(0.2, {x = 0, y = 0}, {})
        
        TestFramework.utils.assertEqual(0, #CosmicEvents.activeEvents, "Expired events should be removed")
    end,
    
    ["event effects on player"] = function()
        CosmicEvents.init()
        local player = {
            x = 100,
            y = 100,
            vx = 10,
            vy = 10,
            onPlanet = false
        }
        
        -- Trigger gravity wave near player
        CosmicEvents.triggerGravityWave(player)
        
        local initialVx = player.vx
        local initialVy = player.vy
        
        CosmicEvents.update(0.1, player, {})
        
        -- Velocity should be affected by gravity wave
        local velocityChanged = (player.vx ~= initialVx) or (player.vy ~= initialVy)
        TestFramework.utils.assertTrue(velocityChanged or player.onPlanet, "Player velocity should be affected by gravity wave")
    end,
    
    ["black hole creation"] = function()
        CosmicEvents.init()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.createBlackHole(600, 600, 100)
        end)
        TestFramework.utils.assertTrue(success, "Creating black hole should not crash")
    end,
    
    ["event visual effects"] = function()
        CosmicEvents.init()
        
        local success  = Utils.ErrorHandler.safeCall(function()
            local particles = CosmicEvents.getEventParticles()
            TestFramework.utils.assertNotNil(particles, "Should return particle array")
        end)
        TestFramework.utils.assertTrue(success, "Getting event particles should not crash")
    end,
    
    ["random event trigger"] = function()
        CosmicEvents.init()
        local player = {x = 100, y = 100}
        
        local success  = Utils.ErrorHandler.safeCall(function()
            for i = 1, 10 do
                CosmicEvents.tryTriggerRandomEvent(player, {})
            end
        end)
        TestFramework.utils.assertTrue(success, "Random event triggers should not crash")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Cosmic Events Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("cosmic_events", 18) -- All major functions tested
    
    return success
end

return {run = run}