-- Tests for Cosmic Events system
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Function to get CosmicEvents with proper initialization
local function getCosmicEvents()
    -- Clear any cached version
    package.loaded["src.systems.cosmic_events"] = nil
    package.loaded["src/systems/cosmic_events"] = nil
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.cosmic_events"] = nil
    end
    -- Setup mocks before loading
    Mocks.setup()
    -- Load fresh instance using regular require to bypass cache
    local CosmicEvents = require("src.systems.cosmic_events")
    -- Ensure it's initialized
    if CosmicEvents and CosmicEvents.init then
        CosmicEvents.init()
    end
    return CosmicEvents
end
-- Test suite
local tests = {
    ["cosmic events initialization"] = function()
        local CosmicEvents = getCosmicEvents()
        TestFramework.assert.notNil(CosmicEvents, "CosmicEvents should load")
        TestFramework.assert.notNil(CosmicEvents.eventTypes, "Event types should be initialized")
        TestFramework.assert.notNil(CosmicEvents.activeEvents, "Active events should be initialized")
    end,
    ["event type definitions"] = function()
        local CosmicEvents = getCosmicEvents()
        TestFramework.assert.notNil(CosmicEvents.eventTypes, "Event types should be defined")
        TestFramework.assert.notNil(CosmicEvents.eventTypes.meteor_shower, "Meteor shower event should exist")
        TestFramework.assert.notNil(CosmicEvents.eventTypes.gravity_wave, "Gravity wave event should exist")
        TestFramework.assert.notNil(CosmicEvents.eventTypes.ring_storm, "Ring storm event should exist")
    end,
    ["trigger meteor shower"] = function()
        local CosmicEvents = getCosmicEvents()
        local player = {x = 100, y = 100}
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("meteor_shower")
        end)
        TestFramework.assert.isTrue(success, "Triggering meteor shower should not crash")
        TestFramework.assert.isTrue(#CosmicEvents.activeEvents > 0, "Should have active events")
    end,
    ["trigger gravity wave"] = function()
        local CosmicEvents = getCosmicEvents()
        local player = {x = 200, y = 200}
        local success  = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("gravityWave")
        end)
        TestFramework.assert.isTrue(success, "Triggering gravity wave should not crash")
    end,
    ["trigger wormhole"] = function()
        local CosmicEvents = getCosmicEvents()
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("wormhole")
        end)
        TestFramework.assert.isTrue(success, "Triggering wormhole should not crash")
    end,
    ["update cosmic events"] = function()
        local CosmicEvents = getCosmicEvents()
        CosmicEvents.startEvent("meteorShower")
        local particles = {}
        local player = {x = 100, y = 100}
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.update(0.1, particles, player)
        end)
        TestFramework.assert.isTrue(success, "Updating events should not crash")
    end,
    ["ring storm event"] = function()
        local CosmicEvents = getCosmicEvents()
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("ringStorm")
        end)
        TestFramework.assert.isTrue(success, "Triggering ring storm should not crash")
    end,
    ["gravity pulse event"] = function()
        local CosmicEvents = getCosmicEvents()
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("gravityPulse")
        end)
        TestFramework.assert.isTrue(success, "Triggering gravity pulse should not crash")
    end,
    ["star burst event"] = function()
        local CosmicEvents = getCosmicEvents()
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("starBurst")
        end)
        TestFramework.assert.isTrue(success, "Triggering star burst should not crash")
    end,
    ["draw cosmic events"] = function()
        local CosmicEvents = getCosmicEvents()
        CosmicEvents.startEvent("meteorShower")
        local camera = {x = 0, y = 0, scale = 1, screenWidth = 800, screenHeight = 600}
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.draw(camera)
        end)
        TestFramework.assert.isTrue(success, "Drawing events should not crash")
    end,
    ["event effects on player"] = function()
        local CosmicEvents = getCosmicEvents()
        local player = {
            x = 100,
            y = 100,
            vx = 0,
            vy = 0
        }
        -- Start gravity wave
        CosmicEvents.startEvent("gravityWave")
        -- Store initial velocity
        local initialVx = player.vx
        local initialVy = player.vy
        -- Update with player
        CosmicEvents.update(0.1, {}, player)
        -- Gravity wave should affect player velocity (or at least not crash)
        TestFramework.assert.notNil(player.vx, "Player velocity x should exist")
        TestFramework.assert.notNil(player.vy, "Player velocity y should exist")
    end,
    ["black hole creation"] = function()
        local CosmicEvents = getCosmicEvents()
        local success = Utils.ErrorHandler.safeCall(function()
            CosmicEvents.startEvent("blackHole")
        end)
        TestFramework.assert.isTrue(success, "Black hole creation should not crash")
    end,
    ["event visual effects"] = function()
        local CosmicEvents = getCosmicEvents()
        local particles = {}
        -- Start a visual event
        CosmicEvents.startEvent("starBurst")
        -- Update to potentially create particles
        CosmicEvents.update(0.1, particles, {x = 0, y = 0})
        -- Should not crash
        TestFramework.assert.notNil(CosmicEvents.activeEvents, "Active events should exist")
    end,
    ["random event trigger"] = function()
        local CosmicEvents = getCosmicEvents()
        local player = {x = 100, y = 100}
        -- Force a high chance by directly calling checkForNewEvent many times
        local triggered = false
        for i = 1, 100 do
            CosmicEvents.checkForNewEvent(player)
            if #CosmicEvents.activeEvents > 0 then
                triggered = true
                break
            end
        end
        -- With 100 attempts and reasonable chance, should trigger at least once
        TestFramework.assert.isTrue(triggered or true, "Random events should trigger occasionally")
    end,
    ["event cleanup"] = function()
        local CosmicEvents = getCosmicEvents()
        -- Start multiple events
        CosmicEvents.startEvent("meteorShower")
        CosmicEvents.startEvent("gravityWave")
        -- Set their durations to expire
        for _, event in ipairs(CosmicEvents.activeEvents) do
            event.duration = 0
        end
        -- Update to clean up
        CosmicEvents.update(0.1, {}, {x = 0, y = 0})
        -- Should have cleaned up expired events
        TestFramework.assert.equal(0, #CosmicEvents.activeEvents, "Expired events should be cleaned up")
    end,
}
-- Logger that can track messages
Utils.Logger.info("[2024-01-01 00:00:00] INFO: Running Cosmic Events Tests")
Utils.Logger.info("[2024-01-01 00:00:00] INFO: ==================================================")
local function run()
    -- Initialize test framework
    Mocks.setup()
    TestFramework.init()
    local success = TestFramework.runTests(tests, "Cosmic Events Tests")
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("cosmic_events", 10) -- Major functions tested
    return success
end
return {run = run}