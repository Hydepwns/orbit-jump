-- Comprehensive tests for Warp Drive System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks before requiring WarpDrive
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock love functions
love.timer = {
    currentTime = 0,
    getTime = function()
        return love.timer.currentTime
    end
}

love.graphics = {
    getWidth = function() return 800 end,
    getHeight = function() return 600 end,
    circle = function() end,
    rectangle = function() end,
    printf = function() end,
    print = function() end,
    setFont = function() end,
    newFont = function() return {} end,
    setLineWidth = function() end,
    push = function() end,
    pop = function() end,
    translate = function() end,
    rotate = function() end
}

-- Mock Utils functions
Utils.distance = function(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dy*dy)
end

Utils.setColor = function() end

-- Require WarpDrive after mocks are set up
local WarpDrive = Utils.require("src.systems.warp_drive")

-- Mock dependencies
mockAchievementSystem = {
    warpDriveUnlocked = false,
    warpsCompleted = 0,
    onWarpDriveUnlocked = function()
        mockAchievementSystem.warpDriveUnlocked = true
    end,
    onWarpCompleted = function()
        mockAchievementSystem.warpsCompleted = mockAchievementSystem.warpsCompleted + 1
    end
}

mockSoundManager = {
    eventWarningPlayed = false,
    playEventWarning = function(self)
        self.eventWarningPlayed = true
    end
}

mockCamera = {
    shakeAmount = 0,
    shakeDuration = 0,
    shake = function(self, amount, duration)
        self.shakeAmount = amount
        self.shakeDuration = duration
    end,
    worldToScreen = function(self, x, y)
        return x, y -- Simple pass-through for tests
    end
}

-- Test helper functions
local function createTestPlayer(x, y)
    return {
        x = x or 0,
        y = y or 0,
        vx = 0,
        vy = 0,
        onPlanet = nil,
        radius = 10
    }
end

local function createTestPlanet(x, y, radius, discovered)
    return {
        x = x,
        y = y,
        radius = radius or 50,
        discovered = discovered == nil and true or discovered
    }
end

local function resetMocks()
    mockAchievementSystem.warpDriveUnlocked = false
    mockAchievementSystem.warpsCompleted = 0
    mockSoundManager.eventWarningPlayed = false
    mockCamera.shakeAmount = 0
    mockCamera.shakeDuration = 0
end

-- Test suite
local tests = {
    ["test initialization"] = function()
        WarpDrive.init()
        
        TestFramework.utils.assertFalse(WarpDrive.isUnlocked, "Warp drive should start locked")
        TestFramework.utils.assertEqual(WarpDrive.maxEnergy, WarpDrive.energy, "Energy should be at max")
        TestFramework.utils.assertEqual(0, #WarpDrive.particles, "No particles initially")
        TestFramework.utils.assertFalse(WarpDrive.isWarping, "Should not be warping initially")
        TestFramework.utils.assertFalse(WarpDrive.isSelecting, "Should not be selecting initially")
    end,
    
    ["test unlock warp drive"] = function()
        resetMocks()
        
        -- Mock achievement system
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.achievement_system" then return mockAchievementSystem
            else return oldRequire(path) end
        end
        
        WarpDrive.init()
        WarpDrive.unlock()
        
        TestFramework.utils.assertTrue(WarpDrive.isUnlocked, "Warp drive should be unlocked")
        TestFramework.utils.assertTrue(mockAchievementSystem.warpDriveUnlocked, "Achievement should be triggered")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test calculate cost"] = function()
        -- Test minimum cost
        local cost = WarpDrive.calculateCost(100)
        TestFramework.utils.assertEqual(50, cost, "Minimum cost should be 50")
        
        -- Test scaling cost
        cost = WarpDrive.calculateCost(1000)
        TestFramework.utils.assertEqual(50, cost, "Cost for 1000 distance should be 50")
        
        cost = WarpDrive.calculateCost(5000)
        TestFramework.utils.assertEqual(50, cost, "Cost for 5000 distance should be 50")
        
        cost = WarpDrive.calculateCost(10000)
        TestFramework.utils.assertEqual(100, cost, "Cost for 10000 distance should be 100")
    end,
    
    ["test can afford warp"] = function()
        WarpDrive.init()
        WarpDrive.unlock()
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(1000, 0, 50, true)
        
        -- Full energy - should afford
        TestFramework.utils.assertTrue(WarpDrive.canAffordWarp(planet, player), "Should afford warp with full energy")
        
        -- Low energy
        WarpDrive.energy = 30
        TestFramework.utils.assertFalse(WarpDrive.canAffordWarp(planet, player), "Should not afford warp with low energy")
        
        -- Not unlocked
        WarpDrive.energy = 1000
        WarpDrive.isUnlocked = false
        TestFramework.utils.assertFalse(WarpDrive.canAffordWarp(planet, player), "Should not afford warp when locked")
        
        -- Planet not discovered
        WarpDrive.isUnlocked = true
        planet.discovered = false
        TestFramework.utils.assertFalse(WarpDrive.canAffordWarp(planet, player), "Should not warp to undiscovered planet")
    end,
    
    ["test start warp"] = function()
        resetMocks()
        
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.audio.sound_manager" then return mockSoundManager
            else return oldRequire(path) end
        end
        
        WarpDrive.init()
        WarpDrive.unlock()
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(5000, 0, 50, true)
        
        local initialEnergy = WarpDrive.energy
        local success = WarpDrive.startWarp(planet, player)
        
        TestFramework.utils.assertTrue(success, "Warp should start successfully")
        TestFramework.utils.assertTrue(WarpDrive.isWarping, "Should be warping")
        TestFramework.utils.assertEqual(planet, WarpDrive.warpTarget, "Target should be set")
        TestFramework.utils.assertEqual(0, WarpDrive.warpProgress, "Progress should start at 0")
        TestFramework.utils.assertTrue(WarpDrive.energy < initialEnergy, "Energy should be consumed")
        TestFramework.utils.assertTrue(#WarpDrive.particles > 0, "Particles should be created")
        TestFramework.utils.assertTrue(mockSoundManager.eventWarningPlayed, "Sound should play")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test start warp fails when cannot afford"] = function()
        WarpDrive.init()
        WarpDrive.unlock()
        WarpDrive.energy = 10 -- Too low
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(5000, 0, 50, true)
        
        local success = WarpDrive.startWarp(planet, player)
        
        TestFramework.utils.assertFalse(success, "Warp should fail")
        TestFramework.utils.assertFalse(WarpDrive.isWarping, "Should not be warping")
        TestFramework.utils.assertEqual(10, WarpDrive.energy, "Energy should not be consumed")
    end,
    
    ["test warp particle creation"] = function()
        local player = createTestPlayer(100, 200)
        
        WarpDrive.createWarpParticles(player)
        
        TestFramework.utils.assertEqual(50, #WarpDrive.particles, "Should create 50 particles")
        
        -- Check particle properties
        local particle = WarpDrive.particles[1]
        TestFramework.utils.assertNotNil(particle.x, "Particle should have x position")
        TestFramework.utils.assertNotNil(particle.y, "Particle should have y position")
        TestFramework.utils.assertNotNil(particle.vx, "Particle should have x velocity")
        TestFramework.utils.assertNotNil(particle.vy, "Particle should have y velocity")
        TestFramework.utils.assertNotNil(particle.size, "Particle should have size")
        TestFramework.utils.assertEqual(1.0, particle.life, "Particle should have full life")
        TestFramework.utils.assertEqual(3, #particle.color, "Particle should have RGB color")
    end,
    
    ["test update energy regeneration"] = function()
        WarpDrive.init()
        WarpDrive.energy = 500 -- Half energy
        
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.utils.assertEqual(550, WarpDrive.energy, "Energy should regenerate at correct rate")
        
        -- Test max cap
        WarpDrive.energy = 990
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.utils.assertEqual(1000, WarpDrive.energy, "Energy should not exceed max")
        
        -- No regen while warping
        WarpDrive.isWarping = true
        WarpDrive.energy = 500
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.utils.assertEqual(500, WarpDrive.energy, "Energy should not regen while warping")
    end,
    
    ["test update warp progress"] = function()
        WarpDrive.init()
        WarpDrive.isWarping = true
        WarpDrive.warpProgress = 0
        WarpDrive.warpTarget = createTestPlanet(1000, 0)
        
        -- Update halfway
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.utils.assertEqual(0.5, WarpDrive.warpProgress, "Progress should increase correctly")
        TestFramework.utils.assertTrue(WarpDrive.warpEffectAlpha > 0, "Effect alpha should increase")
        TestFramework.utils.assertTrue(WarpDrive.tunnelRotation > 0, "Tunnel should rotate")
    end,
    
    ["test complete warp"] = function()
        resetMocks()
        
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.camera" then return mockCamera
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            else return oldRequire(path) end
        end
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(1000, 500, 50)
        
        WarpDrive.isWarping = true
        WarpDrive.warpTarget = planet
        
        WarpDrive.completeWarp(player)
        
        -- Check player teleported
        TestFramework.utils.assertEqual(planet.x + planet.radius + 30, player.x, "Player X should be near planet")
        TestFramework.utils.assertEqual(planet.y, player.y, "Player Y should match planet")
        TestFramework.utils.assertEqual(0, player.vx, "Velocity X should be reset")
        TestFramework.utils.assertEqual(0, player.vy, "Velocity Y should be reset")
        TestFramework.utils.assertNil(player.onPlanet, "Player should not be on planet")
        
        -- Check warp state cleared
        TestFramework.utils.assertFalse(WarpDrive.isWarping, "Should not be warping")
        TestFramework.utils.assertNil(WarpDrive.warpTarget, "Target should be cleared")
        TestFramework.utils.assertEqual(0, WarpDrive.warpProgress, "Progress should be reset")
        
        -- Check effects
        TestFramework.utils.assertEqual(15, mockCamera.shakeAmount, "Camera should shake")
        TestFramework.utils.assertEqual(1, mockAchievementSystem.warpsCompleted, "Achievement should track completion")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test toggle selection"] = function()
        WarpDrive.init()
        
        -- Can't toggle when not unlocked
        local result = WarpDrive.toggleSelection()
        TestFramework.utils.assertFalse(result, "Should not toggle when locked")
        TestFramework.utils.assertFalse(WarpDrive.isSelecting, "Should not be selecting")
        
        -- Can toggle when unlocked
        WarpDrive.unlock()
        result = WarpDrive.toggleSelection()
        TestFramework.utils.assertTrue(result, "Should toggle on")
        TestFramework.utils.assertTrue(WarpDrive.isSelecting, "Should be selecting")
        
        -- Toggle off
        result = WarpDrive.toggleSelection()
        TestFramework.utils.assertFalse(result, "Should toggle off")
        TestFramework.utils.assertFalse(WarpDrive.isSelecting, "Should not be selecting")
        
        -- Can't toggle while warping
        WarpDrive.isWarping = true
        result = WarpDrive.toggleSelection()
        TestFramework.utils.assertFalse(result, "Should not toggle while warping")
    end,
    
    ["test select planet at position"] = function()
        WarpDrive.init()
        WarpDrive.unlock()
        WarpDrive.isSelecting = true
        
        local player = createTestPlayer(0, 0)
        local planets = {
            createTestPlanet(100, 100, 50, true),
            createTestPlanet(300, 300, 40, true),
            createTestPlanet(500, 500, 60, false) -- Not discovered
        }
        
        -- Click on first planet
        local selected = WarpDrive.selectPlanetAt(110, 110, planets, player)
        
        TestFramework.utils.assertEqual(planets[1], selected, "Should select closest planet")
        TestFramework.utils.assertEqual(planets[1], WarpDrive.selectedPlanet, "Selected planet should be stored")
        
        -- Click on undiscovered planet - should not select
        selected = WarpDrive.selectPlanetAt(500, 500, planets, player)
        TestFramework.utils.assertNil(selected, "Should not select undiscovered planet")
        
        -- Click far from any planet
        selected = WarpDrive.selectPlanetAt(700, 700, planets, player)
        TestFramework.utils.assertNil(selected, "Should not select when too far")
    end,
    
    ["test auto start warp on selection"] = function()
        resetMocks()
        
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.audio.sound_manager" then return mockSoundManager
            else return oldRequire(path) end
        end
        
        WarpDrive.init()
        WarpDrive.unlock()
        WarpDrive.isSelecting = true
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(1000, 0, 50, true)
        local planets = {planet}
        
        -- Select planet - should auto-start warp
        WarpDrive.selectPlanetAt(1000, 0, planets, player)
        
        TestFramework.utils.assertTrue(WarpDrive.isWarping, "Should start warping")
        TestFramework.utils.assertFalse(WarpDrive.isSelecting, "Selection mode should end")
        TestFramework.utils.assertNil(WarpDrive.selectedPlanet, "Selected planet should be cleared")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test particle update during warp"] = function()
        WarpDrive.init()
        WarpDrive.isWarping = true
        WarpDrive.warpProgress = 0.5
        
        -- Add test particle
        WarpDrive.particles = {
            {x = 100, y = 100, vx = 10, vy = 10, life = 1.0, size = 5, color = {1, 1, 1}}
        }
        
        local player = createTestPlayer()
        WarpDrive.update(0.1, player)
        
        local particle = WarpDrive.particles[1]
        TestFramework.utils.assertEqual(101, particle.x, "Particle should move")
        TestFramework.utils.assertTrue(particle.life < 1.0, "Particle life should decrease")
        
        -- Test particle removal when dead
        particle.life = 0.05
        WarpDrive.update(0.1, player)
        
        TestFramework.utils.assertEqual(0, #WarpDrive.particles, "Dead particles should be removed")
    end,
    
    ["test effect alpha fade"] = function()
        WarpDrive.init()
        WarpDrive.warpEffectAlpha = 1.0
        WarpDrive.isWarping = false
        
        WarpDrive.update(0.5, createTestPlayer())
        
        TestFramework.utils.assertEqual(0, WarpDrive.warpEffectAlpha, "Effect should fade out when not warping")
    end,
    
    ["test get status"] = function()
        WarpDrive.init()
        WarpDrive.unlock()
        WarpDrive.energy = 500
        
        local status = WarpDrive.getStatus()
        
        TestFramework.utils.assertTrue(status.unlocked, "Status should show unlocked")
        TestFramework.utils.assertEqual(500, status.energy, "Status should show current energy")
        TestFramework.utils.assertEqual(1000, status.maxEnergy, "Status should show max energy")
        TestFramework.utils.assertFalse(status.isWarping, "Status should show not warping")
        TestFramework.utils.assertTrue(status.canWarp, "Status should show can warp")
        
        -- Test can't warp with low energy
        WarpDrive.energy = 30
        status = WarpDrive.getStatus()
        TestFramework.utils.assertFalse(status.canWarp, "Status should show cannot warp with low energy")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runSuite("Warp Drive Tests", tests)
end

return {run = run}