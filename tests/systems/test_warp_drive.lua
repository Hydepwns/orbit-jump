-- Comprehensive tests for Warp Drive System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Function to get WarpDrive with proper initialization
local function getWarpDrive(customMocks)
    -- AGGRESSIVELY clear any cached version from ALL possible caches
    package.loaded["src.systems.warp_drive"] = nil
    package.loaded["src/systems/warp_drive"] = nil
    package.loaded["src\\systems\\warp_drive"] = nil  -- Windows paths
    
    -- Clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.warp_drive"] = nil
        Utils.moduleCache["src/systems/warp_drive"] = nil
        Utils.moduleCache["src\\systems\\warp_drive"] = nil
    end
    
    -- Force garbage collection to clear any remaining references
    collectgarbage("collect")
    
    -- Setup mocks before loading
    Mocks.setup()
    
    -- Initialize test framework
    TestFramework.init()
    
    -- Mock Utils.require for dependencies (allow custom overrides)
    local originalUtilsRequire = Utils.require
    Utils.require = function(module)
        -- Check for custom mocks first
        if customMocks and customMocks[module] then
            return customMocks[module]
        end
        -- Default mocks
        if module == "src.systems.achievement_system" then
            return mockAchievementSystem
        elseif module == "src.audio.sound_manager" then
            return mockSoundManager
        elseif module == "src.core.camera" then
            return mockCamera
        end
        return originalUtilsRequire(module)
    end
    
    -- Load completely fresh instance, avoiding all caches
    local WarpDrive = dofile("src/systems/warp_drive.lua") or require("src.systems.warp_drive")
    
    -- Ensure it's initialized
    if WarpDrive and WarpDrive.init then
        WarpDrive.init()
    end
    
    -- DON'T restore Utils.require here - let the test control it
    
    return WarpDrive
end

-- Store original love state before any modifications
local originalLove = {}
if love then
    originalLove.timer = love.timer
    originalLove.graphics = love.graphics
end

-- Ensure love exists before mocking
if not love then
    _G.love = {}
end

-- Mock love functions (preserve existing functions where possible)
love.timer = love.timer or {}
love.timer.currentTime = love.timer.currentTime or 0
love.timer.getTime = love.timer.getTime or function()
    return love.timer.currentTime
end

-- Preserve existing graphics functions and only add what's missing
if not love.graphics then
    love.graphics = {}
end

-- Only override if functions don't exist or need specific behavior
love.graphics.getWidth = love.graphics.getWidth or function() return 800 end
love.graphics.getHeight = love.graphics.getHeight or function() return 600 end
love.graphics.circle = love.graphics.circle or function() end
love.graphics.rectangle = love.graphics.rectangle or function() end
love.graphics.printf = love.graphics.printf or function() end
love.graphics.print = love.graphics.print or function() end
love.graphics.setFont = love.graphics.setFont or function() end
love.graphics.newFont = love.graphics.newFont or function() return {} end
love.graphics.setLineWidth = love.graphics.setLineWidth or function() end
love.graphics.push = love.graphics.push or function() end
love.graphics.pop = love.graphics.pop or function() end
love.graphics.translate = love.graphics.translate or function() end
love.graphics.rotate = love.graphics.rotate or function() end

-- Function to restore original state
local function restoreOriginalLove()
    if originalLove.timer then
        love.timer = originalLove.timer
    end
    if originalLove.graphics then
        love.graphics = originalLove.graphics
    end
end

-- Mock Utils functions
Utils.distance = function(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dy*dy)
end

Utils.setColor = function() end

-- We'll get WarpDrive fresh in each test

-- Mock dependencies
mockAchievementSystem = {
    warpDriveUnlocked = false,
    warpsCompleted = 0,
    onWarpDriveUnlocked = function()
        print("🎯 mockAchievementSystem.onWarpDriveUnlocked() called!")
        mockAchievementSystem.warpDriveUnlocked = true
    end,
    onWarpCompleted = function()
        print("🎯 mockAchievementSystem.onWarpCompleted() called!")
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
        local WarpDrive = getWarpDrive()
        
        TestFramework.assert.assertFalse(WarpDrive.isUnlocked, "Warp drive should start locked")
        TestFramework.assert.assertEqual(WarpDrive.maxEnergy, WarpDrive.energy, "Energy should be at max")
        TestFramework.assert.assertEqual(0, #WarpDrive.particles, "No particles initially")
        TestFramework.assert.assertFalse(WarpDrive.isWarping, "Should not be warping initially")
        TestFramework.assert.assertFalse(WarpDrive.isSelecting, "Should not be selecting initially")
    end,
    
    ["test unlock warp drive"] = function()
        resetMocks()
        
        -- Mock Utils.require BEFORE getting WarpDrive and KEEP it mocked during the test
        local originalUtilsRequire = Utils.require
        Utils.require = function(module)
            print("Utils.require called with:", module)
            if module == "src.systems.achievement_system" then
                print("Returning mockAchievementSystem:", mockAchievementSystem)
                return mockAchievementSystem
            end
            local result = originalUtilsRequire(module)
            print("Returning original for", module, ":", result)
            return result
        end
        
        -- Get WarpDrive (this will use the original mock setup, not the custom one)
        local WarpDrive = getWarpDrive()
        
        -- Debug: Check mock state before unlock
        print("Before unlock - mockAchievementSystem.warpDriveUnlocked:", mockAchievementSystem.warpDriveUnlocked)
        
        WarpDrive.unlock()
        
        -- Debug: Check state after unlock
        print("After unlock - WarpDrive.isUnlocked:", WarpDrive.isUnlocked)
        print("After unlock - mockAchievementSystem.warpDriveUnlocked:", mockAchievementSystem.warpDriveUnlocked)
        
        TestFramework.assert.assertTrue(WarpDrive.isUnlocked, "Warp drive should be unlocked")
        TestFramework.assert.assertTrue(mockAchievementSystem.warpDriveUnlocked, "Achievement should be triggered")
        
        -- Restore
        Utils.require = originalUtilsRequire
    end,
    
    ["test calculate cost"] = function()
        local WarpDrive = getWarpDrive()
        
        -- Test minimum cost
        local cost = WarpDrive.calculateCost(100)
        TestFramework.assert.assertEqual(50, cost, "Minimum cost should be 50")
        
        -- Test scaling cost
        cost = WarpDrive.calculateCost(1000)
        TestFramework.assert.assertEqual(50, cost, "Cost for 1000 distance should be 50")
        
        cost = WarpDrive.calculateCost(5000)
        TestFramework.assert.assertEqual(50, cost, "Cost for 5000 distance should be 50")
        
        cost = WarpDrive.calculateCost(10000)
        TestFramework.assert.assertEqual(100, cost, "Cost for 10000 distance should be 100")
    end,
    
    ["test can afford warp"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.unlock()
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(1000, 0, 50, true)
        
        -- Full energy - should afford
        TestFramework.assert.assertTrue(WarpDrive.canAffordWarp(planet, player), "Should afford warp with full energy")
        
        -- Low energy
        WarpDrive.energy = 30
        TestFramework.assert.assertFalse(WarpDrive.canAffordWarp(planet, player), "Should not afford warp with low energy")
        
        -- Not unlocked
        WarpDrive.energy = 1000
        WarpDrive.isUnlocked = false
        TestFramework.assert.assertFalse(WarpDrive.canAffordWarp(planet, player), "Should not afford warp when locked")
        
        -- Planet not discovered
        WarpDrive.isUnlocked = true
        planet.discovered = false
        TestFramework.assert.assertFalse(WarpDrive.canAffordWarp(planet, player), "Should not warp to undiscovered planet")
    end,
    
    ["test start warp"] = function()
        resetMocks()
        
        -- Mock dependencies
        Utils.moduleCache["src.audio.sound_manager"] = mockSoundManager
        
        local WarpDrive = getWarpDrive()
        WarpDrive.unlock()
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(5000, 0, 50, true)
        
        local initialEnergy = WarpDrive.energy
        local success = WarpDrive.startWarp(planet, player)
        
        TestFramework.assert.assertTrue(success, "Warp should start successfully")
        TestFramework.assert.assertTrue(WarpDrive.isWarping, "Should be warping")
        TestFramework.assert.assertEqual(planet, WarpDrive.warpTarget, "Target should be set")
        TestFramework.assert.assertEqual(0, WarpDrive.warpProgress, "Progress should start at 0")
        TestFramework.assert.assertTrue(WarpDrive.energy < initialEnergy, "Energy should be consumed")
        TestFramework.assert.assertTrue(#WarpDrive.particles > 0, "Particles should be created")
        TestFramework.assert.assertTrue(mockSoundManager.eventWarningPlayed, "Sound should play")
    end,
    
    ["test start warp fails when cannot afford"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.unlock()
        WarpDrive.energy = 10 -- Too low
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(5000, 0, 50, true)
        
        local success = WarpDrive.startWarp(planet, player)
        
        TestFramework.assert.assertFalse(success, "Warp should fail")
        TestFramework.assert.assertFalse(WarpDrive.isWarping, "Should not be warping")
        TestFramework.assert.assertEqual(10, WarpDrive.energy, "Energy should not be consumed")
    end,
    
    ["test warp particle creation"] = function()
        local WarpDrive = getWarpDrive()
        local player = createTestPlayer(100, 200)
        
        WarpDrive.createWarpParticles(player)
        
        TestFramework.assert.assertEqual(50, #WarpDrive.particles, "Should create 50 particles")
        
        -- Check particle properties
        local particle = WarpDrive.particles[1]
        TestFramework.assert.assertNotNil(particle.x, "Particle should have x position")
        TestFramework.assert.assertNotNil(particle.y, "Particle should have y position")
        TestFramework.assert.assertNotNil(particle.vx, "Particle should have x velocity")
        TestFramework.assert.assertNotNil(particle.vy, "Particle should have y velocity")
        TestFramework.assert.assertNotNil(particle.size, "Particle should have size")
        TestFramework.assert.assertEqual(1.0, particle.life, "Particle should have full life")
        TestFramework.assert.assertEqual(3, #particle.color, "Particle should have RGB color")
    end,
    
    ["test update energy regeneration"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.energy = 500 -- Half energy
        
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.assert.assertEqual(550, WarpDrive.energy, "Energy should regenerate at correct rate")
        
        -- Test max cap
        WarpDrive.energy = 990
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.assert.assertEqual(1000, WarpDrive.energy, "Energy should not exceed max")
        
        -- No regen while warping
        WarpDrive.isWarping = true
        WarpDrive.energy = 500
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.assert.assertEqual(500, WarpDrive.energy, "Energy should not regen while warping")
    end,
    
    ["test update warp progress"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.isWarping = true
        WarpDrive.warpProgress = 0
        WarpDrive.warpTarget = createTestPlanet(1000, 0)
        
        -- Update halfway
        WarpDrive.update(1.0, createTestPlayer())
        
        TestFramework.assert.assertEqual(0.5, WarpDrive.warpProgress, "Progress should increase correctly")
        TestFramework.assert.assertTrue(WarpDrive.warpEffectAlpha > 0, "Effect alpha should increase")
        TestFramework.assert.assertTrue(WarpDrive.tunnelRotation > 0, "Tunnel should rotate")
    end,
    
    ["test complete warp"] = function()
        resetMocks()
        
        -- Mock Utils.require BEFORE getting WarpDrive and KEEP it mocked during the test
        local originalUtilsRequire = Utils.require
        Utils.require = function(module)
            if module == "src.core.camera" then
                return mockCamera
            elseif module == "src.systems.achievement_system" then
                return mockAchievementSystem
            end
            return originalUtilsRequire(module)
        end
        
        -- Get WarpDrive
        local WarpDrive = getWarpDrive()
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(1000, 500, 50)
        
        WarpDrive.isWarping = true
        WarpDrive.warpTarget = planet
        
        -- Debug: Check mock state before completeWarp
        print("Before completeWarp - mockAchievementSystem.warpsCompleted:", mockAchievementSystem.warpsCompleted)
        print("Before completeWarp - mockCamera.shakeAmount:", mockCamera.shakeAmount)
        
        WarpDrive.completeWarp(player)
        
        -- Debug: Check state after completeWarp
        print("After completeWarp - mockAchievementSystem.warpsCompleted:", mockAchievementSystem.warpsCompleted)
        print("After completeWarp - mockCamera.shakeAmount:", mockCamera.shakeAmount)
        
        -- Check player teleported
        TestFramework.assert.assertEqual(planet.x + planet.radius + 30, player.x, "Player X should be near planet")
        TestFramework.assert.assertEqual(planet.y, player.y, "Player Y should match planet")
        TestFramework.assert.assertEqual(0, player.vx, "Velocity X should be reset")
        TestFramework.assert.assertEqual(0, player.vy, "Velocity Y should be reset")
        TestFramework.assert.assertNil(player.onPlanet, "Player should not be on planet")
        
        -- Check warp state cleared
        TestFramework.assert.assertFalse(WarpDrive.isWarping, "Should not be warping")
        TestFramework.assert.assertNil(WarpDrive.warpTarget, "Target should be cleared")
        TestFramework.assert.assertEqual(0, WarpDrive.warpProgress, "Progress should be reset")
        
        -- Check effects
        TestFramework.assert.assertEqual(15, mockCamera.shakeAmount, "Camera should shake")
        TestFramework.assert.assertEqual(1, mockAchievementSystem.warpsCompleted, "Achievement should track completion")
        
        -- Restore
        Utils.require = originalUtilsRequire
    end,
    
    ["test toggle selection"] = function()
        local WarpDrive = getWarpDrive()
        
        -- Can't toggle when not unlocked
        local result = WarpDrive.toggleSelection()
        TestFramework.assert.assertFalse(result, "Should not toggle when locked")
        TestFramework.assert.assertFalse(WarpDrive.isSelecting, "Should not be selecting")
        
        -- Can toggle when unlocked
        WarpDrive.unlock()
        result = WarpDrive.toggleSelection()
        TestFramework.assert.assertTrue(result, "Should toggle on")
        TestFramework.assert.assertTrue(WarpDrive.isSelecting, "Should be selecting")
        
        -- Toggle off
        result = WarpDrive.toggleSelection()
        TestFramework.assert.assertFalse(result, "Should toggle off")
        TestFramework.assert.assertFalse(WarpDrive.isSelecting, "Should not be selecting")
        
        -- Can't toggle while warping
        WarpDrive.isWarping = true
        result = WarpDrive.toggleSelection()
        TestFramework.assert.assertFalse(result, "Should not toggle while warping")
    end,
    
    ["test select planet at position"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.unlock()
        WarpDrive.isSelecting = true
        WarpDrive.energy = 25  -- Not enough energy to auto-warp (cost is 50)
        
        local player = createTestPlayer(0, 0)
        local planets = {
            createTestPlanet(100, 100, 50, true),
            createTestPlanet(300, 300, 40, true),
            createTestPlanet(500, 500, 60, false) -- Not discovered
        }
        
        -- Click on first planet
        local selected = WarpDrive.selectPlanetAt(110, 110, planets, player)
        
        TestFramework.assert.assertEqual(planets[1], selected, "Should select closest planet")
        TestFramework.assert.assertEqual(planets[1], WarpDrive.selectedPlanet, "Selected planet should be stored")
        
        -- Click on undiscovered planet - should not select
        selected = WarpDrive.selectPlanetAt(500, 500, planets, player)
        TestFramework.assert.assertNil(selected, "Should not select undiscovered planet")
        
        -- Click far from any planet
        selected = WarpDrive.selectPlanetAt(700, 700, planets, player)
        TestFramework.assert.assertNil(selected, "Should not select when too far")
    end,
    
    ["test auto start warp on selection"] = function()
        resetMocks()
        
        -- Mock dependencies
        Utils.moduleCache["src.audio.sound_manager"] = mockSoundManager
        
        local WarpDrive = getWarpDrive()
        WarpDrive.unlock()
        WarpDrive.isSelecting = true
        
        local player = createTestPlayer(0, 0)
        local planet = createTestPlanet(1000, 0, 50, true)
        local planets = {planet}
        
        -- Select planet - should auto-start warp
        WarpDrive.selectPlanetAt(1000, 0, planets, player)
        
        TestFramework.assert.assertTrue(WarpDrive.isWarping, "Should start warping")
        TestFramework.assert.assertFalse(WarpDrive.isSelecting, "Selection mode should end")
        TestFramework.assert.assertNil(WarpDrive.selectedPlanet, "Selected planet should be cleared")
    end,
    
    ["test particle update during warp"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.isWarping = true
        WarpDrive.warpProgress = 0.5
        
        -- Add test particle
        WarpDrive.particles = {
            {x = 100, y = 100, vx = 10, vy = 10, life = 1.0, size = 5, color = {1, 1, 1}}
        }
        
        local player = createTestPlayer()
        WarpDrive.update(0.1, player)
        
        local particle = WarpDrive.particles[1]
        TestFramework.assert.assertEqual(101, particle.x, "Particle should move")
        TestFramework.assert.assertTrue(particle.life < 1.0, "Particle life should decrease")
        
        -- Test particle removal when dead
        particle.life = 0.05
        WarpDrive.update(0.1, player)
        
        TestFramework.assert.assertEqual(0, #WarpDrive.particles, "Dead particles should be removed")
    end,
    
    ["test effect alpha fade"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.warpEffectAlpha = 1.0
        WarpDrive.isWarping = false
        
        WarpDrive.update(0.5, createTestPlayer())
        
        TestFramework.assert.assertEqual(0, WarpDrive.warpEffectAlpha, "Effect should fade out when not warping")
    end,
    
    ["test get status"] = function()
        local WarpDrive = getWarpDrive()
        WarpDrive.unlock()
        WarpDrive.energy = 500
        
        local status = WarpDrive.getStatus()
        
        TestFramework.assert.assertTrue(status.unlocked, "Status should show unlocked")
        TestFramework.assert.assertEqual(500, status.energy, "Status should show current energy")
        TestFramework.assert.assertEqual(1000, status.maxEnergy, "Status should show max energy")
        TestFramework.assert.assertFalse(status.isWarping, "Status should show not warping")
        TestFramework.assert.assertTrue(status.canWarp, "Status should show can warp")
        
        -- Test can't warp with low energy
        WarpDrive.energy = 30
        status = WarpDrive.getStatus()
        TestFramework.assert.assertFalse(status.canWarp, "Status should show cannot warp with low energy")
    end
}

-- Run the test suite
local function run()
    -- Setup mocks and framework before running tests
    Mocks.setup()
    TestFramework.init()
    local result = TestFramework.runTests(tests, "Warp Drive Tests")
    -- Restore original love state to prevent pollution
    restoreOriginalLove()
    return result
end

return {run = run}