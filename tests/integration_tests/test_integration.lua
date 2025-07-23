-- Integration Tests for Orbit Jump
-- Tests system interactions and full game flow

package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")
local GameState = Utils.require("src.core.game_state")
local GameLogic = Utils.require("src.core.game_logic")
local RingSystem = Utils.require("src.systems.ring_system")
local ProgressionSystem = Utils.require("src.systems.progression_system")
local WorldGenerator = Utils.require("src.systems.world_generator")
local Utils = require("src.utils.utils")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test complete game session flow
    ["complete game session"] = function()
        -- Initialize all systems
        GameState.init(800, 600)
        ProgressionSystem.init()
        RingSystem.reset()
        WorldGenerator.reset()
        
        -- Verify initial state
        TestFramework.utils.assertEqual(0, GameState.getScore(), "Game should start with 0 score")
        TestFramework.utils.assertEqual(0, GameState.getCombo(), "Game should start with 0 combo")
        TestFramework.utils.assertNotNil(GameState.player, "Player should be initialized")
        
        -- Simulate ring collection
        local ring = {
            x = GameState.player.x + 50,
            y = GameState.player.y,
            radius = 30,
            innerRadius = 15,
            type = "standard",
            collected = false
        }
        
        local value = RingSystem.collectRing(ring, GameState.player)
        GameState.addScore(value)
        GameState.addCombo()
        
        TestFramework.utils.assertEqual(10, GameState.getScore(), "Score should increase after ring collection")
        TestFramework.utils.assertEqual(1, GameState.getCombo(), "Combo should increase after ring collection")
        TestFramework.utils.assertTrue(ring.collected, "Ring should be marked as collected")
    end,
    
    ["progression system integration"] = function()
        -- Initialize systems
        ProgressionSystem.init()
        GameState.init(800, 600)
        
        -- Set up some progression data
        ProgressionSystem.data.totalScore = 500
        ProgressionSystem.data.upgrades.jumpPower = 2
        ProgressionSystem.data.upgrades.ringValue = 3
        
        -- Test upgrade effects on game mechanics
        local baseJumpPower = 300
        local actualJumpPower = GameLogic.calculateJumpPower(baseJumpPower, ProgressionSystem)
        
        TestFramework.utils.assertTrue(actualJumpPower > baseJumpPower, "Upgrades should affect jump power")
        
        -- Test ring value calculation with upgrades
        local baseRingValue = 10
        local actualRingValue = GameLogic.calculateRingValue(baseRingValue, 0, ProgressionSystem)
        
        TestFramework.utils.assertTrue(actualRingValue > baseRingValue, "Upgrades should affect ring values")
    end,
    
    ["world generation and discovery"] = function()
        -- Initialize systems
        WorldGenerator.reset()
        GameState.init(800, 600)
        
        -- Generate planets around player
        local player = GameState.player
        local existingPlanets = GameState.getPlanets()
        local newPlanets = WorldGenerator.generateAroundPosition(player.x, player.y, existingPlanets, 1000)
        
        TestFramework.utils.assertTrue(#newPlanets > 0, "Should generate new planets")
        
        -- Test planet discovery
        for _, planet in ipairs(newPlanets) do
            TestFramework.utils.assertFalse(planet.discovered, "Planets should start undiscovered")
            
            WorldGenerator.discoverPlanet(planet)
            TestFramework.utils.assertTrue(planet.discovered, "Planets should be marked as discovered")
        end
        
        -- Add planets to game state
        for _, planet in ipairs(newPlanets) do
            table.insert(existingPlanets, planet)
        end
        GameState.setPlanets(existingPlanets)
        
        TestFramework.utils.assertEqual(#existingPlanets, #GameState.getPlanets(), "Planets should be added to game state")
    end,
    
    ["ring system with progression"] = function()
        -- Initialize systems
        RingSystem.reset()
        ProgressionSystem.init()
        GameState.init(800, 600)
        
        -- Set up upgrades
        ProgressionSystem.data.upgrades.ringValue = 2
        ProgressionSystem.data.upgrades.comboMultiplier = 2
        
        -- Create a power ring
        local powerRing = {
            x = 500,
            y = 300,
            radius = 30,
            innerRadius = 15,
            type = "power_shield",
            effect = "shield",
            collected = false
        }
        
        local player = GameState.player
        local value = RingSystem.collectRing(powerRing, player)
        
        -- Test that progression affects ring value
        TestFramework.utils.assertTrue(value > 20, "Ring value should be affected by upgrades")
        
        -- Test that power is activated
        TestFramework.utils.assertTrue(RingSystem.isActive("shield"), "Shield power should be active")
        TestFramework.utils.assertTrue(player.hasShield, "Player should have shield")
    end,
    
    ["achievement system integration"] = function()
        -- Initialize systems
        ProgressionSystem.init()
        GameState.init(800, 600)
        
        -- Reset achievement state
        ProgressionSystem.achievements.firstRing.unlocked = false
        ProgressionSystem.achievements.ringCollector.unlocked = false
        
        -- Simulate first ring collection
        ProgressionSystem.addRings(1)
        ProgressionSystem.checkAchievements()
        
        TestFramework.utils.assertTrue(ProgressionSystem.achievements.firstRing.unlocked, "First ring achievement should be unlocked")
        
        -- Simulate collecting many rings
        ProgressionSystem.addRings(99) -- Total 100 rings
        ProgressionSystem.checkAchievements()
        
        TestFramework.utils.assertTrue(ProgressionSystem.achievements.ringCollector.unlocked, "Ring collector achievement should be unlocked")
    end,
    
    ["upgrade system integration"] = function()
        -- Initialize systems
        ProgressionSystem.init()
        GameState.init(800, 600)
        
        -- Give player enough score to purchase upgrades
        ProgressionSystem.data.totalScore = 1000
        
        -- Test upgrade purchase
        local initialLevel = ProgressionSystem.data.upgrades.jumpPower
        local success = ProgressionSystem.purchaseUpgrade("jumpPower")
        
        TestFramework.utils.assertTrue(success, "Upgrade purchase should succeed")
        TestFramework.utils.assertEqual(initialLevel + 1, ProgressionSystem.data.upgrades.jumpPower, "Upgrade level should increase")
        TestFramework.utils.assertTrue(ProgressionSystem.data.totalScore < 1000, "Score should decrease after purchase")
        
        -- Test upgrade effects on game mechanics
        local basePower = 300
        local upgradedPower = GameLogic.calculateJumpPower(basePower, ProgressionSystem)
        
        TestFramework.utils.assertTrue(upgradedPower > basePower, "Upgrade should increase jump power")
    end,
    
    ["particle system integration"] = function()
        -- Initialize systems
        GameState.init(800, 600)
        
        -- Create particles
        local particle1 = {
            x = 400,
            y = 300,
            vx = 10,
            vy = -10,
            lifetime = 1.0,
            maxLifetime = 1.0,
            size = 5,
            color = {1, 1, 1, 1}
        }
        
        local particle2 = {
            x = 500,
            y = 400,
            vx = -5,
            vy = 5,
            lifetime = 0.5,
            maxLifetime = 0.5,
            size = 3,
            color = {1, 0, 0, 1}
        }
        
        GameState.addParticle(particle1)
        GameState.addParticle(particle2)
        
        TestFramework.utils.assertEqual(2, #GameState.getParticles(), "Should have 2 particles")
        
        -- Update particles
        local dt = 0.1
        GameState.update(dt)
        
        -- Check that particles moved
        TestFramework.utils.assertTrue(particle1.x > 400, "Particle should move")
        TestFramework.utils.assertTrue(particle1.y < 300, "Particle should move")
        
        -- Check that short-lived particle is removed
        local particles = GameState.getParticles()
        local foundShortParticle = false
        for _, p in ipairs(particles) do
            if p == particle2 then
                foundShortParticle = true
                break
            end
        end
        TestFramework.utils.assertFalse(foundShortParticle, "Short-lived particle should be removed")
    end,
    
    ["camera and player interaction"] = function()
        -- Initialize systems
        GameState.init(800, 600)
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        
        -- Set player position
        GameState.player.x = 1000
        GameState.player.y = 800
        
        -- Test camera following
        local dt = 0.1
        camera:follow(GameState.player, dt)
        
        -- Camera should move toward player
        TestFramework.utils.assertTrue(camera.x > 0, "Camera should move toward player")
        TestFramework.utils.assertTrue(camera.y > 0, "Camera should move toward player")
    end,
    
    ["sound system integration"] = function()
        -- Initialize systems
        local SoundManager = Utils.require("src.audio.sound_manager")
        local soundManager = SoundManager:new()
        soundManager:load()
        
        -- Test sound playing (should not crash with mocks)
        local success  = Utils.ErrorHandler.safeCall(function()
            soundManager:playJump()
            soundManager:playCollectRing()
            soundManager:playDash()
        end)
        
        TestFramework.utils.assertTrue(success, "Sound system should work without crashing")
    end,
    
    ["performance monitoring integration"] = function()
        -- Initialize systems
        local PerformanceMonitor = Utils.require("src.performance.performance_monitor")
        PerformanceMonitor.init({
            enabled = true,
            showOnScreen = false,
            trackMemory = true,
            trackCollisions = true
        })
        
        -- Test performance tracking
        PerformanceMonitor.startTimer("test")
        PerformanceMonitor.endTimer("test")
        
        local stats = PerformanceMonitor.getStats()
        TestFramework.utils.assertNotNil(stats, "Performance stats should be available")
        TestFramework.utils.assertNotNil(stats.test, "Timer should be tracked")
    end,
    
    ["mobile input integration"] = function()
        -- Initialize systems
        Utils.MobileInput.init()
        
        -- Test mobile detection
        local isMobile = Utils.MobileInput.isMobile()
        TestFramework.utils.assertTrue(type(isMobile) == "boolean", "Mobile detection should return boolean")
        
        -- Test touch handling
        local success  = Utils.ErrorHandler.safeCall(function()
            Utils.MobileInput.handleTouch(1, 400, 300, "pressed")
            Utils.MobileInput.handleTouch(1, 400, 300, "released")
        end)
        
        TestFramework.utils.assertTrue(success, "Touch handling should work without crashing")
    end,
    
    ["save and load integration"] = function()
        -- Initialize systems
        ProgressionSystem.init()
        
        -- Set some test data
        ProgressionSystem.data.totalScore = 5000
        ProgressionSystem.data.totalRingsCollected = 250
        ProgressionSystem.data.upgrades.jumpPower = 3
        ProgressionSystem.data.upgrades.dashPower = 2
        
        -- Save data
        local saveSuccess  = Utils.ErrorHandler.safeCall(function()
            ProgressionSystem.saveData()
        end)
        
        TestFramework.utils.assertTrue(saveSuccess, "Data saving should work")
        
        -- Modify data
        ProgressionSystem.data.totalScore = 0
        ProgressionSystem.data.totalRingsCollected = 0
        
        -- Load data (should restore original values)
        local loadSuccess  = Utils.ErrorHandler.safeCall(function()
            ProgressionSystem.loadData()
        end)
        
        TestFramework.utils.assertTrue(loadSuccess, "Data loading should work")
    end,
    
    ["error handling integration"] = function()
        -- Test that systems handle errors gracefully
        local success1  = Utils.ErrorHandler.safeCall(function()
            GameState.init(-100, -100) -- Invalid dimensions
        end)
        
        -- Should handle invalid input gracefully
        TestFramework.utils.assertTrue(success1, "System should handle invalid input gracefully")
        
        -- Test safe function calls
        local success2, result = Utils.ErrorHandler.safeCall(function()
            return "success"
        end)
        
        TestFramework.utils.assertTrue(success2, "Safe call should succeed")
        TestFramework.utils.assertEqual("success", result, "Safe call should return result")
        
        local success3, error = Utils.ErrorHandler.safeCall(function()
            error("test error")
        end)
        
        TestFramework.utils.assertFalse(success3, "Safe call should handle errors")
        TestFramework.utils.assertNotNil(error, "Error should be returned")
    end,
    
    ["full game loop simulation"] = function()
        -- Initialize all systems
        GameState.init(800, 600)
        ProgressionSystem.init()
        RingSystem.reset()
        WorldGenerator.reset()
        
        -- Simulate a complete game session
        local gameTime = 0
        local maxGameTime = 10 -- Simulate 10 seconds of gameplay
        
        while gameTime < maxGameTime do
            local dt = 0.016 -- 60 FPS
            
            -- Update all systems
            GameState.update(dt)
            ProgressionSystem.updatePlayTime(dt)
            RingSystem.updatePowers(dt)
            
            -- Simulate player actions
            if gameTime > 1 and gameTime < 2 then
                -- Jump
                GameState.player.onPlanet = nil
                GameState.player.vx = 200
                GameState.player.vy = 0
                ProgressionSystem.addJump()
            end
            
            if gameTime > 3 and gameTime < 4 then
                -- Collect a ring
                local ring = {
                    x = GameState.player.x + 30,
                    y = GameState.player.y,
                    radius = 30,
                    innerRadius = 15,
                    type = "standard",
                    collected = false
                }
                
                local value = RingSystem.collectRing(ring, GameState.player)
                GameState.addScore(value)
                GameState.addCombo()
                ProgressionSystem.addRings(1)
            end
            
            if gameTime > 5 and gameTime < 6 then
                -- Dash
                GameState.player.isDashing = true
                GameState.player.dashTimer = 0.3
            end
            
            gameTime = gameTime + dt
        end
        
        -- Verify game state after simulation
        TestFramework.utils.assertTrue(GameState.getScore() > 0, "Score should increase during gameplay")
        TestFramework.utils.assertTrue(ProgressionSystem.data.totalPlayTime > 0, "Play time should be tracked")
        TestFramework.utils.assertTrue(ProgressionSystem.data.totalJumps > 0, "Jumps should be tracked")
        TestFramework.utils.assertTrue(ProgressionSystem.data.totalRingsCollected > 0, "Rings should be tracked")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Integration Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("integration", 15) -- Integration test coverage
    
    return success
end

return {run = run} 