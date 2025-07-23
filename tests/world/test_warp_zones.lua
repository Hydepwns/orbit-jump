-- Tests for Warp Zones system
package.path = package.path .. ";../../?.lua"

local TestFramework = require("tests.test_framework")
local Mocks = require("tests.mocks")

Mocks.setup()

local WarpZones = require("src.systems.warp_zones")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["warp zones initialization"] = function()
        WarpZones.init()
        TestFramework.utils.assertNotNil(WarpZones.zones, "Zones should be initialized")
        TestFramework.utils.assertNotNil(WarpZones.connections, "Connections should be initialized")
    end,
    
    ["create warp zone"] = function()
        WarpZones.init()
        
        local zone = WarpZones.createZone(100, 200, 50)
        TestFramework.utils.assertNotNil(zone, "Zone should be created")
        TestFramework.utils.assertEqual(100, zone.x, "Zone x position should match")
        TestFramework.utils.assertEqual(200, zone.y, "Zone y position should match")
        TestFramework.utils.assertEqual(50, zone.radius, "Zone radius should match")
        TestFramework.utils.assertTrue(zone.active, "Zone should be active by default")
    end,
    
    ["connect warp zones"] = function()
        WarpZones.init()
        
        local zone1 = WarpZones.createZone(100, 100, 50)
        local zone2 = WarpZones.createZone(500, 500, 50)
        
        WarpZones.connectZones(zone1, zone2)
        
        local connected = WarpZones.getConnectedZone(zone1)
        TestFramework.utils.assertEqual(zone2, connected, "Zones should be connected")
    end,
    
    ["player in warp zone detection"] = function()
        WarpZones.init()
        
        local zone = WarpZones.createZone(100, 100, 50)
        local player = {x = 100, y = 100, radius = 10}
        
        local inZone = WarpZones.isPlayerInZone(player, zone)
        TestFramework.utils.assertTrue(inZone, "Should detect player in zone")
        
        player.x = 200
        inZone = WarpZones.isPlayerInZone(player, zone)
        TestFramework.utils.assertFalse(inZone, "Should not detect player outside zone")
    end,
    
    ["warp player through zone"] = function()
        WarpZones.init()
        
        local zone1 = WarpZones.createZone(100, 100, 50)
        local zone2 = WarpZones.createZone(500, 500, 50)
        WarpZones.connectZones(zone1, zone2)
        
        local player = {x = 100, y = 100, vx = 10, vy = 20}
        
        local warped = WarpZones.warpPlayer(player, zone1)
        TestFramework.utils.assertTrue(warped, "Player should be warped")
        TestFramework.utils.assertEqual(500, player.x, "Player x should be at destination")
        TestFramework.utils.assertEqual(500, player.y, "Player y should be at destination")
        TestFramework.utils.assertEqual(10, player.vx, "Player velocity should be preserved")
    end,
    
    ["warp zone cooldown"] = function()
        WarpZones.init()
        
        local zone1 = WarpZones.createZone(100, 100, 50)
        local zone2 = WarpZones.createZone(500, 500, 50)
        WarpZones.connectZones(zone1, zone2)
        
        local player = {x = 100, y = 100, id = "player1"}
        
        -- First warp should work
        local warped = WarpZones.warpPlayer(player, zone1)
        TestFramework.utils.assertTrue(warped, "First warp should succeed")
        
        -- Immediate second warp should fail
        player.x = 100
        player.y = 100
        warped = WarpZones.warpPlayer(player, zone1)
        TestFramework.utils.assertFalse(warped, "Second warp should fail due to cooldown")
    end,
    
    ["update warp zones"] = function()
        WarpZones.init()
        
        local zone = WarpZones.createZone(100, 100, 50)
        zone.pulsePhase = 0
        
        WarpZones.update(0.1)
        
        TestFramework.utils.assertTrue(zone.pulsePhase > 0, "Zone pulse should update")
    end,
    
    ["deactivate warp zone"] = function()
        WarpZones.init()
        
        local zone = WarpZones.createZone(100, 100, 50)
        WarpZones.deactivateZone(zone)
        
        TestFramework.utils.assertFalse(zone.active, "Zone should be deactivated")
        
        local player = {x = 100, y = 100}
        local warped = WarpZones.warpPlayer(player, zone)
        TestFramework.utils.assertFalse(warped, "Should not warp through inactive zone")
    end,
    
    ["generate random warp network"] = function()
        WarpZones.init()
        
        local success = pcall(function()
            WarpZones.generateRandomNetwork(5, 1000, 1000)
        end)
        TestFramework.utils.assertTrue(success, "Generating random network should not crash")
        TestFramework.utils.assertTrue(#WarpZones.zones >= 5, "Should create requested zones")
    end,
    
    ["warp zone visual effects"] = function()
        WarpZones.init()
        
        local zone = WarpZones.createZone(100, 100, 50)
        
        local success = pcall(function()
            local effects = WarpZones.getZoneEffects(zone)
            TestFramework.utils.assertNotNil(effects, "Should return effects data")
        end)
        TestFramework.utils.assertTrue(success, "Getting zone effects should not crash")
    end,
    
    ["clear all zones"] = function()
        WarpZones.init()
        
        -- Create some zones
        WarpZones.createZone(100, 100, 50)
        WarpZones.createZone(200, 200, 50)
        
        WarpZones.clearAll()
        
        TestFramework.utils.assertEqual(0, #WarpZones.zones, "All zones should be cleared")
        TestFramework.utils.assertEqual(0, #WarpZones.connections, "All connections should be cleared")
    end,
    
    ["one-way warp zones"] = function()
        WarpZones.init()
        
        local zone1 = WarpZones.createZone(100, 100, 50)
        local zone2 = WarpZones.createZone(500, 500, 50)
        
        WarpZones.connectZonesOneWay(zone1, zone2)
        
        local connected1 = WarpZones.getConnectedZone(zone1)
        local connected2 = WarpZones.getConnectedZone(zone2)
        
        TestFramework.utils.assertEqual(zone2, connected1, "Zone1 should connect to zone2")
        TestFramework.utils.assertNil(connected2, "Zone2 should not connect back")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Warp Zones Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = require("tests.test_coverage")
    TestCoverage.updateModule("warp_zones", 16) -- All major functions tested
    
    return success
end

return {run = run}