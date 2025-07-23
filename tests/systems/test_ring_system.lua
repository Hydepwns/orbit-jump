-- Tests for Ring System
package.path = package.path .. ";../../?.lua"

local Utils = Utils.Utils.require("src.utils.utils")
local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")
local RingSystem = Utils.Utils.require("src.systems.ring_system")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test ring type definitions
    ["ring type definitions"] = function()
        TestFramework.utils.assertNotNil(RingSystem.types.standard, "Standard ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.power_shield, "Power shield ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.power_magnet, "Power magnet ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.power_slowmo, "Power slowmo ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.power_multijump, "Power multijump ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.warp, "Warp ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.ghost, "Ghost ring type should exist")
        TestFramework.utils.assertNotNil(RingSystem.types.chain, "Chain ring type should exist")
    end,
    
    ["ring type properties"] = function()
        local standard = RingSystem.types.standard
        TestFramework.utils.assertEqual(10, standard.value, "Standard ring should have correct value")
        TestFramework.utils.assertNotNil(standard.color, "Standard ring should have color")
        TestFramework.utils.assertNil(standard.effect, "Standard ring should have no effect")
        
        local powerShield = RingSystem.types.power_shield
        TestFramework.utils.assertEqual(20, powerShield.value, "Power shield ring should have correct value")
        TestFramework.utils.assertEqual("shield", powerShield.effect, "Power shield ring should have shield effect")
        TestFramework.utils.assertEqual(5, powerShield.duration, "Power shield ring should have correct duration")
        TestFramework.utils.assertEqual(0.1, powerShield.rarity, "Power shield ring should have correct rarity")
    end,
    
    -- Test ring initialization
    ["ring initialization"] = function()
        RingSystem.reset()
        
        TestFramework.utils.assertEqual(0, #RingSystem.activePowers, "Active powers should start empty")
        TestFramework.utils.assertEqual(0, #RingSystem.warpPairs, "Warp pairs should start empty")
        TestFramework.utils.assertEqual(0, #RingSystem.chainSequence, "Chain sequence should start empty")
        TestFramework.utils.assertEqual(1, RingSystem.currentChain, "Current chain should start at 1")
    end,
    
    -- Test ring collection mechanics
    ["standard ring collection"] = function()
        RingSystem.reset()
        
        local ring = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "standard",
            collected = false
        }
        
        local player = Mocks.gameState.player
        local value = RingSystem.collectRing(ring, player)
        
        TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
        TestFramework.utils.assertEqual(10, value, "Standard ring should return correct value")
        TestFramework.utils.assertFalse(RingSystem.isActive("shield"), "Standard ring should not activate powers")
    end,
    
    ["power shield ring collection"] = function()
        RingSystem.reset()
        
        local ring = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "power_shield",
            effect = "shield",
            collected = false
        }
        
        local player = Mocks.gameState.player
        local value = RingSystem.collectRing(ring, player)
        
        TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
        TestFramework.utils.assertEqual(20, value, "Power shield ring should return correct value")
        TestFramework.utils.assertTrue(RingSystem.isActive("shield"), "Shield power should be active")
        TestFramework.utils.assertTrue(player.hasShield, "Player should have shield")
    end,
    
    ["power magnet ring collection"] = function()
        RingSystem.reset()
        
        local ring = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "power_magnet",
            effect = "magnet",
            collected = false
        }
        
        local player = Mocks.gameState.player
        local value = RingSystem.collectRing(ring, player)
        
        TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
        TestFramework.utils.assertEqual(20, value, "Power magnet ring should return correct value")
        TestFramework.utils.assertTrue(RingSystem.isActive("magnet"), "Magnet power should be active")
        TestFramework.utils.assertEqual(150, player.magnetRange, "Player should have magnet range")
    end,
    
    ["power slowmo ring collection"] = function()
        RingSystem.reset()
        
        local ring = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "power_slowmo",
            effect = "slowmo",
            collected = false
        }
        
        local player = Mocks.gameState.player
        local value = RingSystem.collectRing(ring, player)
        
        TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
        TestFramework.utils.assertEqual(25, value, "Power slowmo ring should return correct value")
        TestFramework.utils.assertTrue(RingSystem.isActive("slowmo"), "Slowmo power should be active")
    end,
    
    ["power multijump ring collection"] = function()
        RingSystem.reset()
        
        local ring = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "power_multijump",
            effect = "multijump",
            collected = false
        }
        
        local player = Mocks.gameState.player
        player.extraJumps = 0
        local value = RingSystem.collectRing(ring, player)
        
        TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
        TestFramework.utils.assertEqual(30, value, "Power multijump ring should return correct value")
        TestFramework.utils.assertTrue(RingSystem.isActive("multijump"), "Multijump power should be active")
        TestFramework.utils.assertEqual(1, player.extraJumps, "Player should have extra jumps")
    end,
    
    -- Test power duration and expiration
    ["power duration expiration"] = function()
        RingSystem.reset()
        
        -- Activate a power
        RingSystem.activatePower("shield", 2.0)
        TestFramework.utils.assertTrue(RingSystem.isActive("shield"), "Shield should be active")
        
        -- Update with time less than duration
        RingSystem.updatePowers(1.0)
        TestFramework.utils.assertTrue(RingSystem.isActive("shield"), "Shield should still be active")
        
        -- Update with time greater than duration
        RingSystem.updatePowers(2.0)
        TestFramework.utils.assertFalse(RingSystem.isActive("shield"), "Shield should be expired")
    end,
    
    -- Test time scale effects
    ["time scale effects"] = function()
        RingSystem.reset()
        
        -- No slowmo active
        TestFramework.utils.assertEqual(1.0, RingSystem.getTimeScale(), "Time scale should be 1.0 without slowmo")
        
        -- Activate slowmo
        RingSystem.activatePower("slowmo", 5.0)
        TestFramework.utils.assertEqual(0.5, RingSystem.getTimeScale(), "Time scale should be 0.5 with slowmo")
        
        -- Deactivate slowmo
        RingSystem.activePowers.slowmo = nil
        TestFramework.utils.assertEqual(1.0, RingSystem.getTimeScale(), "Time scale should return to 1.0")
    end,
    
    -- Test warp ring mechanics
    ["warp ring mechanics"] = function()
        RingSystem.reset()
        
        -- Create warp pair
        local ring1 = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "warp",
            effect = "warp",
            pairId = 1,
            collected = false
        }
        
        local ring2 = {
            x = 800,
            y = 600,
            radius = 30,
            innerRadius = 15,
            type = "warp",
            effect = "warp",
            pairId = 1,
            collected = false
        }
        
        -- Mock GameState to return rings
        local originalGetRings = RingSystem.findWarpPair
        RingSystem.findWarpPair = function(ring)
            if ring == ring1 then return ring2 end
            if ring == ring2 then return ring1 end
            return nil
        end
        
        local player = Mocks.gameState.player
        player.x = 500
        player.y = 300
        
        local value = RingSystem.collectRing(ring1, player)
        
        TestFramework.utils.assertTrue(ring1.collected, "First ring should be collected")
        TestFramework.utils.assertTrue(ring2.collected, "Second ring should be collected")
        TestFramework.utils.assertEqual(800, player.x, "Player should be teleported to second ring")
        TestFramework.utils.assertEqual(600, player.y, "Player should be teleported to second ring")
        TestFramework.utils.assertEqual(15, value, "Warp ring should return correct value")
        
        -- Restore original function
        RingSystem.findWarpPair = originalGetRings
    end,
    
    -- Test chain ring mechanics
    ["chain ring mechanics"] = function()
        RingSystem.reset()
        
        -- Create chain sequence
        RingSystem.chainSequence = {
            {chainNumber = 1, x = 500, y = 300},
            {chainNumber = 2, x = 600, y = 300},
            {chainNumber = 3, x = 700, y = 300}
        }
        RingSystem.currentChain = 1
        
        -- Collect first ring in sequence
        local ring1 = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "chain",
            effect = "chain",
            chainNumber = 1,
            collected = false
        }
        
        local player = Mocks.gameState.player
        local value1 = RingSystem.collectRing(ring1, player)
        
        TestFramework.utils.assertEqual(2, RingSystem.currentChain, "Chain should advance to next number")
        TestFramework.utils.assertEqual(5, value1, "Chain ring should return base value")
        
        -- Collect second ring in sequence
        local ring2 = {
            x = 600,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "chain",
            effect = "chain",
            chainNumber = 2,
            collected = false
        }
        
        local value2 = RingSystem.collectRing(ring2, player)
        
        TestFramework.utils.assertEqual(3, RingSystem.currentChain, "Chain should advance to next number")
        TestFramework.utils.assertEqual(5, value2, "Chain ring should return base value")
        
        -- Collect third ring (completing chain)
        local ring3 = {
            x = 700,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "chain",
            effect = "chain",
            chainNumber = 3,
            collected = false
        }
        
        local value3 = RingSystem.collectRing(ring3, player)
        
        TestFramework.utils.assertEqual(4, RingSystem.currentChain, "Chain should advance after completion")
        TestFramework.utils.assertEqual(50, value3, "Completed chain should return bonus value")
    end,
    
    ["chain ring wrong order"] = function()
        RingSystem.reset()
        
        RingSystem.chainSequence = {
            {chainNumber = 1, x = 500, y = 300},
            {chainNumber = 2, x = 600, y = 300}
        }
        RingSystem.currentChain = 1
        
        -- Try to collect second ring first (wrong order)
        local ring2 = {
            x = 600,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "chain",
            effect = "chain",
            chainNumber = 2,
            collected = false
        }
        
        local player = Mocks.gameState.player
        local value = RingSystem.collectRing(ring2, player)
        
        TestFramework.utils.assertEqual(1, RingSystem.currentChain, "Chain should reset to 1")
        TestFramework.utils.assertEqual(5, value, "Chain ring should return base value")
    end,
    
    -- Test ring update mechanics
    ["ring update mechanics"] = function()
        RingSystem.reset()
        
        local ring = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            rotation = 0,
            rotationSpeed = 2.0,
            pulsePhase = 0,
            collected = false,
            type = "standard"
        }
        
        local dt = 0.1
        RingSystem.updateRing(ring, dt)
        
        TestFramework.utils.assertEqual(0.2, ring.rotation, "Ring should rotate")
        TestFramework.utils.assertEqual(0.2, ring.pulsePhase, "Ring should pulse")
    end,
    
    -- Test magnet effect application
    ["magnet effect application"] = function()
        RingSystem.reset()
        
        local player = Mocks.gameState.player
        player.magnetRange = 100
        
        local rings = {
            {
                x = 450, -- Within magnet range
                y = 300,
                radius = 30,
                innerRadius = 15,
                collected = false,
                visible = true
            },
            {
                x = 350, -- Outside magnet range
                y = 300,
                radius = 30,
                innerRadius = 15,
                collected = false,
                visible = true
            }
        }
        
        RingSystem.applyMagnetEffect(player, rings)
        
        -- Ring within range should move toward player
        TestFramework.utils.assertTrue(rings[1].x > 450, "Ring should move toward player")
        TestFramework.utils.assertEqual(300, rings[2].x, "Ring outside range should not move")
    end,
    
    -- Test ring generation
    ["ring generation"] = function()
        RingSystem.reset()
        
        local planets = {
            {x = 400, y = 300, radius = 80},
            {x = 600, y = 300, radius = 60}
        }
        
        local rings = RingSystem.generateRings(planets, 10)
        
        TestFramework.utils.assertEqual(10, #rings, "Should generate correct number of rings")
        
        for _, ring in ipairs(rings) do
            TestFramework.utils.assertNotNil(ring.x, "Ring should have x position")
            TestFramework.utils.assertNotNil(ring.y, "Ring should have y position")
            TestFramework.utils.assertNotNil(ring.radius, "Ring should have radius")
            TestFramework.utils.assertNotNil(ring.innerRadius, "Ring should have inner radius")
            TestFramework.utils.assertFalse(ring.collected, "Ring should start uncollected")
            TestFramework.utils.assertNotNil(ring.type, "Ring should have type")
        end
    end,
    
    -- Test ring type distribution
    ["ring type distribution"] = function()
        RingSystem.reset()
        
        local planets = {{x = 400, y = 300, radius = 80}}
        local rings = RingSystem.generateRings(planets, 100)
        
        local typeCounts = {}
        for _, ring in ipairs(rings) do
            typeCounts[ring.type] = (typeCounts[ring.type] or 0) + 1
        end
        
        -- Should have mostly standard rings
        TestFramework.utils.assertTrue(typeCounts.standard > 50, "Should have many standard rings")
        
        -- Should have some special rings
        TestFramework.utils.assertTrue(typeCounts.power_shield > 0, "Should have some power shield rings")
        TestFramework.utils.assertTrue(typeCounts.power_magnet > 0, "Should have some power magnet rings")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Ring System Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("ring_system", 15) -- All major functions tested
    
    return success
end

return {run = run} 