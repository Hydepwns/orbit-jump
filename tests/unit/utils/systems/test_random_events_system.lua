-- Test suite for Random Events System
-- Tests event triggering, timing, effects, and visual feedback
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
TestFramework.init()
-- Load system
local RandomEventsSystem = Utils.require("src.systems.random_events_system")
-- Mock Love2D timer
love.timer = love.timer or {}
love.timer.getTime = function()
    return 0
end
-- Mock Love2D graphics
love.graphics = love.graphics or {}
love.graphics.push = function() end
love.graphics.pop = function() end
love.graphics.setColor = function() end
love.graphics.setLineWidth = function() end
love.graphics.circle = function() end
love.graphics.line = function() end
love.graphics.getHeight = function() return 600 end
love.graphics.getWidth = function() return 800 end
-- Mock math.pow if not available (Lua 5.1 compatibility)
math.pow = math.pow or function(x, y)
    return x ^ y
end
-- Mock random for predictable testing
local mockRandomValues = {}
local mockRandomIndex = 1
local originalRandom = math.random
local function setMockRandom(values)
    mockRandomValues = values
    mockRandomIndex = 1
    math.random = function(...)
        local args = {...}
        local value = mockRandomValues[mockRandomIndex] or 0.5
        mockRandomIndex = mockRandomIndex + 1
        -- Handle math.random() with no args (0-1)
        if #args == 0 then
            return value
        -- Handle math.random(max) (1-max)
        elseif #args == 1 then
            return math.floor(value * args[1]) + 1
        -- Handle math.random(min, max) (min-max)
        elseif #args == 2 then
            return math.floor(value * (args[2] - args[1] + 1)) + args[1]
        end
        return value
    end
end
local function restoreRandom()
    math.random = originalRandom
end
-- Test helper functions
local function setupSystem()
    -- Create fresh system instance
    local system = {}
    for k, v in pairs(RandomEventsSystem) do
        system[k] = v
    end
    -- Reset state
    system.events = {}
    system.active_events = {}
    system.event_chance = 0.05
    system.event_cooldown = 0
    system.event_cooldown_duration = 3.0
    system.ring_rain_state = nil
    system.gravity_well_state = nil
    system.time_dilation_state = nil
    -- Mock game state
    system.game_state = {
        player = {x = 100, y = 100},
        sound_system = {
            playEventSound = function() end
        },
        spawnEventRing = function() end,
        world_time_scale = 1.0,
        player_time_scale = 1.0
    }
    -- Mock UI system
    package.loaded["src.ui.ui_system"] = {
        showEventNotification = function() end,
        hideEventNotification = function() end
    }
    -- Initialize system
    system:init(system.game_state)
    return system
end
-- Test suite
local tests = {
    ["initialization"] = function()
        local system = setupSystem()
        TestFramework.assert.isTrue(type(system.events) == "table", "Events should be initialized")
        TestFramework.assert.isTrue(type(system.active_events) == "table", "Active events should be initialized")
        TestFramework.assert.equal(0.05, system.event_chance, "Should have 5% event chance")
        TestFramework.assert.equal(3.0, system.event_cooldown_duration, "Should have 3s cooldown")
        TestFramework.assert.equal(0, system.event_cooldown, "Should start with no cooldown")
    end,
    ["event registration"] = function()
        local system = setupSystem()
        -- Check default events are registered
        TestFramework.assert.isTrue(system.events.ring_rain ~= nil, "Ring rain should be registered")
        TestFramework.assert.isTrue(system.events.gravity_well ~= nil, "Gravity well should be registered")
        TestFramework.assert.isTrue(system.events.time_dilation ~= nil, "Time dilation should be registered")
        -- Check event properties
        local ringRain = system.events.ring_rain
        TestFramework.assert.equal("Ring Rain", ringRain.name, "Ring rain should have correct name")
        TestFramework.assert.equal(8.0, ringRain.duration, "Ring rain should have 8s duration")
        TestFramework.assert.equal(0.4, ringRain.rarity, "Ring rain should have 40% rarity weight")
    end,
    ["custom event registration"] = function()
        local system = setupSystem()
        system:registerEvent("test_event", {
            name = "Test Event",
            duration = 10.0,
            rarity = 0.5,
            color = {1, 0, 0, 1},
            message = "TEST!",
            particle_color = {1, 0.5, 0}
        })
        TestFramework.assert.isTrue(system.events.test_event ~= nil, "Custom event should be registered")
        TestFramework.assert.equal("Test Event", system.events.test_event.name, "Custom event should have correct name")
        TestFramework.assert.equal(10.0, system.events.test_event.duration, "Custom event should have correct duration")
    end,
    ["event trigger chance - no trigger"] = function()
        local system = setupSystem()
        -- Mock random to be above threshold (no trigger)
        setMockRandom({0.1}) -- Above 0.05 threshold
        system:checkForRandomEvent()
        TestFramework.assert.equal(0, #system.active_events, "Should not trigger event above threshold")
        restoreRandom()
    end,
    ["event trigger chance - trigger"] = function()
        local system = setupSystem()
        -- Mock random to trigger event and select ring_rain
        setMockRandom({0.03, 0.2}) -- Below 0.05 threshold, then select first event
        system:checkForRandomEvent()
        TestFramework.assert.isTrue(system.active_events.ring_rain ~= nil, "Should trigger ring rain event")
        restoreRandom()
    end,
    ["cooldown prevents triggering"] = function()
        local system = setupSystem()
        system.event_cooldown = 1.0 -- Set cooldown
        setMockRandom({0.01}) -- Below threshold but should be blocked
        system:checkForRandomEvent()
        TestFramework.assert.equal(0, #system.active_events, "Should not trigger during cooldown")
        restoreRandom()
    end,
    ["active event prevents triggering"] = function()
        local system = setupSystem()
        -- Set an active event
        system.active_events.test = {time_remaining = 5.0}
        setMockRandom({0.01}) -- Below threshold but should be blocked
        system:checkForRandomEvent()
        TestFramework.assert.isTrue(system.active_events.ring_rain == nil, "Should not trigger with active event")
        restoreRandom()
    end,
    ["event selection by rarity weight"] = function()
        local system = setupSystem()
        -- Test multiple selections to verify distribution
        local selections = {}
        for i = 1, 100 do
            setMockRandom({0.01, i / 100}) -- Trigger event, vary selection
            system.active_events = {} -- Clear previous
            system.event_cooldown = 0
            system:checkForRandomEvent()
            for eventId, _ in pairs(system.active_events) do
                selections[eventId] = (selections[eventId] or 0) + 1
                break -- Only count first event
            end
        end
        -- Ring rain has highest weight (0.4), should be selected most
        TestFramework.assert.isTrue(selections.ring_rain > selections.gravity_well, "Ring rain should be most common")
        TestFramework.assert.isTrue(selections.gravity_well > selections.time_dilation, "Gravity well should be more common than time dilation")
        restoreRandom()
    end,
    ["ring rain event trigger"] = function()
        local system = setupSystem()
        local event = system.events.ring_rain
        system:triggerEvent(event)
        TestFramework.assert.isTrue(system.active_events.ring_rain ~= nil, "Ring rain should be active")
        TestFramework.assert.equal(8.0, system.active_events.ring_rain.time_remaining, "Should have correct duration")
        TestFramework.assert.equal(3.0, system.event_cooldown, "Should set cooldown")
        TestFramework.assert.isTrue(system.ring_rain_state ~= nil, "Should initialize ring rain state")
    end,
    ["gravity well event trigger"] = function()
        local system = setupSystem()
        local event = system.events.gravity_well
        system:triggerEvent(event)
        TestFramework.assert.isTrue(system.active_events.gravity_well ~= nil, "Gravity well should be active")
        TestFramework.assert.isTrue(system.gravity_well_state ~= nil, "Should initialize gravity well state")
        TestFramework.assert.equal(3.0, system.game_state.player.temp_magnet_boost, "Should boost magnet strength")
        TestFramework.assert.equal(2.5, system.game_state.player.temp_magnet_range_boost, "Should boost magnet range")
    end,
    ["time dilation event trigger"] = function()
        local system = setupSystem()
        local event = system.events.time_dilation
        system:triggerEvent(event)
        TestFramework.assert.isTrue(system.active_events.time_dilation ~= nil, "Time dilation should be active")
        TestFramework.assert.isTrue(system.time_dilation_state ~= nil, "Should initialize time dilation state")
        TestFramework.assert.equal(0.3, system.game_state.world_time_scale, "Should slow world time")
        TestFramework.assert.equal(1.0, system.game_state.player_time_scale, "Should keep normal player time")
    end,
    ["ring rain spawning"] = function()
        local system = setupSystem()
        -- Track spawned rings
        local spawnedRings = {}
        system.game_state.spawnEventRing = function(x, y, rarity, options)
            table.insert(spawnedRings, {x = x, y = y, rarity = rarity, options = options})
        end
        -- Start ring rain
        system:startRingRain()
        -- Update to trigger spawning
        system:updateRingRain(0.5) -- Above spawn interval
        TestFramework.assert.isTrue(#spawnedRings > 0, "Should spawn rings during ring rain")
        TestFramework.assert.equal("gold", spawnedRings[1].rarity, "Should spawn gold rings")
        TestFramework.assert.isTrue(spawnedRings[1].options.particle_trail, "Should have particle trail")
    end,
    ["event duration and cleanup"] = function()
        local system = setupSystem()
        -- Trigger ring rain event
        local event = system.events.ring_rain
        system:triggerEvent(event)
        -- Update past duration
        system:update(9.0) -- Beyond 8s duration
        TestFramework.assert.isTrue(system.active_events.ring_rain == nil, "Event should be cleaned up")
        TestFramework.assert.isTrue(system.ring_rain_state == nil, "Event state should be cleaned up")
    end,
    ["gravity well cleanup"] = function()
        local system = setupSystem()
        -- Trigger gravity well
        local event = system.events.gravity_well
        system:triggerEvent(event)
        -- Update past duration
        system:update(7.0) -- Beyond 6s duration
        TestFramework.assert.isTrue(system.active_events.gravity_well == nil, "Gravity well should be cleaned up")
        TestFramework.assert.isTrue(system.gravity_well_state == nil, "Gravity well state should be cleaned up")
        TestFramework.assert.isTrue(system.game_state.player.temp_magnet_boost == nil, "Player boost should be removed")
    end,
    ["time dilation cleanup"] = function()
        local system = setupSystem()
        -- Trigger time dilation
        local event = system.events.time_dilation
        system:triggerEvent(event)
        -- Update past duration
        system:update(6.0) -- Beyond 5s duration
        TestFramework.assert.isTrue(system.active_events.time_dilation == nil, "Time dilation should be cleaned up")
        TestFramework.assert.isTrue(system.time_dilation_state == nil, "Time dilation state should be cleaned up")
        TestFramework.assert.equal(1.0, system.game_state.world_time_scale, "World time should be restored")
        TestFramework.assert.equal(1.0, system.game_state.player_time_scale, "Player time should be restored")
    end,
    ["cooldown decreases over time"] = function()
        local system = setupSystem()
        system.event_cooldown = 2.0
        system:update(1.0)
        TestFramework.assert.equal(1.0, system.event_cooldown, "Cooldown should decrease")
        system:update(1.5)
        TestFramework.assert.equal(0, system.event_cooldown, "Cooldown should reach zero")
    end,
    ["event time remaining updates"] = function()
        local system = setupSystem()
        local event = system.events.ring_rain
        system:triggerEvent(event)
        local initialTime = system.active_events.ring_rain.time_remaining
        system:update(2.0)
        TestFramework.assert.equal(initialTime - 2.0, system.active_events.ring_rain.time_remaining, "Time remaining should decrease")
    end,
    ["is event active check"] = function()
        local system = setupSystem()
        TestFramework.assert.isFalse(system:isEventActive("ring_rain"), "Should not be active initially")
        local event = system.events.ring_rain
        system:triggerEvent(event)
        TestFramework.assert.isTrue(system:isEventActive("ring_rain"), "Should be active after trigger")
    end,
    ["get active event info"] = function()
        local system = setupSystem()
        local info = system:getActiveEventInfo()
        TestFramework.assert.isTrue(info == nil, "Should return nil with no active events")
        local event = system.events.ring_rain
        system:triggerEvent(event)
        info = system:getActiveEventInfo()
        TestFramework.assert.isTrue(info ~= nil, "Should return info with active event")
        TestFramework.assert.equal("Ring Rain", info.name, "Should return correct event name")
        TestFramework.assert.equal(8.0, info.time_remaining, "Should return correct time remaining")
        TestFramework.assert.equal(0, info.progress, "Should return correct progress")
    end,
    ["event progress calculation"] = function()
        local system = setupSystem()
        local event = system.events.gravity_well
        system:triggerEvent(event)
        -- Update halfway through duration
        system:update(3.0) -- Half of 6s duration
        local info = system:getActiveEventInfo()
        TestFramework.assert.isTrue(info.progress > 0.4 and info.progress < 0.6, "Progress should be around 50%")
    end,
    ["ring rain spawn timing"] = function()
        local system = setupSystem()
        local spawnCount = 0
        system.game_state.spawnEventRing = function()
            spawnCount = spawnCount + 1
        end
        system:startRingRain()
        -- Update less than spawn interval
        system:updateRingRain(0.1)
        TestFramework.assert.equal(0, spawnCount, "Should not spawn before interval")
        -- Update past spawn interval
        system:updateRingRain(0.3)
        TestFramework.assert.isTrue(spawnCount > 0, "Should spawn after interval")
    end,
    ["multiple events cleanup"] = function()
        local system = setupSystem()
        -- Manually add multiple events (bypassing normal restrictions for testing)
        system.active_events.test1 = {time_remaining = 1.0}
        system.active_events.test2 = {time_remaining = 2.0}
        system.active_events.test3 = {time_remaining = 3.0}
        -- Update past first event duration
        system:update(1.5)
        TestFramework.assert.isTrue(system.active_events.test1 == nil, "First event should be removed")
        TestFramework.assert.isTrue(system.active_events.test2 ~= nil, "Second event should remain")
        TestFramework.assert.isTrue(system.active_events.test3 ~= nil, "Third event should remain")
    end,
    ["event notification integration"] = function()
        local system = setupSystem()
        local notificationShown = false
        local notificationHidden = false
        -- Mock UI system calls
        package.loaded["src.ui.ui_system"] = {
            showEventNotification = function(message, color)
                notificationShown = true
                TestFramework.assert.equal("RING RAIN!", message, "Should show correct message")
            end,
            hideEventNotification = function()
                notificationHidden = true
            end
        }
        local event = system.events.ring_rain
        system:triggerEvent(event)
        TestFramework.assert.isTrue(notificationShown, "Should show notification on trigger")
        system:update(9.0) -- End event
        TestFramework.assert.isTrue(notificationHidden, "Should hide notification on end")
    end
}
-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Random Events System Tests")
    restoreRandom() -- Ensure random is restored
    return success
end
return {run = run}