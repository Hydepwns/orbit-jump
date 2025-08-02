-- Comprehensive tests for Artifact System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks before requiring ArtifactSystem
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
    polygon = function() end,
    rectangle = function() end,
    printf = function() end,
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

-- Store original require for restoration
local originalUtilsRequire = Utils.require

-- Mock dependencies (using GLOBAL variables for Utils.require access)
_G.mockGameState = {
    addScore = function(score)
        _G.mockGameState.lastScoreAdded = score
    end,
    lastScoreAdded = 0
}

_G.mockUpgradeSystem = {
    lastCurrencyAdded = 0,
    addCurrency = function(amount)
        _G.mockUpgradeSystem.lastCurrencyAdded = amount
    end
}

_G.mockAchievementSystem = {
    artifactsCollected = {},
    onArtifactCollected = function(id)
        table.insert(_G.mockAchievementSystem.artifactsCollected, id)
    end,
    allArtifactsCollected = false,
    onAllArtifactsCollected = function()
        _G.mockAchievementSystem.allArtifactsCollected = true
    end
}

_G.mockSoundManager = {
    eventWarningPlayed = false,
    playEventWarning = function(self)
        self.eventWarningPlayed = true
    end
}

_G.mockWarpZones = {
    activeZones = {}
}

-- Function to get ArtifactSystem with proper initialization
local function getArtifactSystem()
    -- Clear any cached version
    package.loaded["src.systems.artifact_system"] = nil
    package.loaded["src/systems/artifact_system"] = nil
    
    -- Also clear from Utils cache (CRITICAL!)
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.artifact_system"] = nil
        -- Clear all related modules too
        Utils.moduleCache["src.core.game_state"] = nil
        Utils.moduleCache["src.systems.upgrade_system"] = nil
        Utils.moduleCache["src.systems.achievement_system"] = nil
        Utils.moduleCache["src.systems.sound_manager"] = nil
        Utils.moduleCache["src.audio.sound_manager"] = nil
        Utils.moduleCache["src.systems.warp_zones"] = nil
    end
    
    -- Setup mocks before loading
    Mocks.setup()
    
    -- Recreate our specific mocks AFTER Mocks.setup() (it might be overwriting them)
    _G.mockGameState = {
        addScore = function(score)
            _G.mockGameState.lastScoreAdded = score
        end,
        lastScoreAdded = 0
    }
    
    _G.mockUpgradeSystem = {
        lastCurrencyAdded = 0,
        addCurrency = function(amount)
            _G.mockUpgradeSystem.lastCurrencyAdded = amount
        end
    }
    
    _G.mockAchievementSystem = {
        artifactsCollected = {},
        onArtifactCollected = function(id)
            table.insert(_G.mockAchievementSystem.artifactsCollected, id)
        end,
        allArtifactsCollected = false,
        onAllArtifactsCollected = function()
            _G.mockAchievementSystem.allArtifactsCollected = true
        end
    }
    
    -- Directly populate Utils.moduleCache with our mocks
    Utils.moduleCache = Utils.moduleCache or {}
    Utils.moduleCache["src.core.game_state"] = _G.mockGameState
    Utils.moduleCache["src.systems.upgrade_system"] = _G.mockUpgradeSystem
    Utils.moduleCache["src.systems.achievement_system"] = _G.mockAchievementSystem
    Utils.moduleCache["src.systems.sound_manager"] = _G.mockSoundManager
    Utils.moduleCache["src.audio.sound_manager"] = _G.mockSoundManager
    Utils.moduleCache["src.systems.warp_zones"] = _G.mockWarpZones
    
    
    -- Load fresh instance using regular require to bypass cache
    local ArtifactSystem = require("src.systems.artifact_system")
    
    -- Ensure it's initialized
    if ArtifactSystem and ArtifactSystem.init then
        ArtifactSystem.init()
    end
    
    return ArtifactSystem
end

-- Test helper functions
local function createTestPlayer(x, y)
    return {
        x = x or 0,
        y = y or 0
    }
end

local function createTestPlanet(x, y, type, discovered)
    return {
        x = x,
        y = y,
        type = type,
        discovered = discovered == nil and true or discovered
    }
end

local function resetMocks()
    _G.mockGameState.lastScoreAdded = 0
    _G.mockUpgradeSystem.lastCurrencyAdded = 0
    _G.mockAchievementSystem.artifactsCollected = {}
    _G.mockAchievementSystem.allArtifactsCollected = false
    _G.mockSoundManager.eventWarningPlayed = false
    _G.mockWarpZones.activeZones = {}
    
    -- Ensure mocks stay in cache
    Utils.moduleCache = Utils.moduleCache or {}
    Utils.moduleCache["src.core.game_state"] = _G.mockGameState
    Utils.moduleCache["src.systems.upgrade_system"] = _G.mockUpgradeSystem
    Utils.moduleCache["src.systems.achievement_system"] = _G.mockAchievementSystem
    Utils.moduleCache["src.systems.sound_manager"] = _G.mockSoundManager
    Utils.moduleCache["src.audio.sound_manager"] = _G.mockSoundManager
    Utils.moduleCache["src.systems.warp_zones"] = _G.mockWarpZones
end

-- Test suite
local tests = {
    ["test initialization"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- Check all artifacts are not discovered
        for _, artifact in ipairs(ArtifactSystem.artifacts) do
            TestFramework.assert.assertFalse(artifact.discovered, "Artifacts should start undiscovered")
        end
        
        TestFramework.assert.assertEqual(0, #ArtifactSystem.spawnedArtifacts, "No artifacts should be spawned initially")
        TestFramework.assert.assertEqual(0, ArtifactSystem.collectedCount, "Collected count should be 0")
        TestFramework.assert.assertEqual(0, #ArtifactSystem.notificationQueue, "Notification queue should be empty")
    end,
    
    ["test artifact definitions"] = function()
        -- Check all artifacts have required fields
        for _, artifact in ipairs(ArtifactSystem.artifacts) do
            TestFramework.assert.assertNotNil(artifact.id, "Artifact should have id")
            TestFramework.assert.assertNotNil(artifact.name, "Artifact should have name")
            TestFramework.assert.assertNotNil(artifact.description, "Artifact should have description")
            TestFramework.assert.assertNotNil(artifact.hint, "Artifact should have hint")
            TestFramework.assert.assertNotNil(artifact.color, "Artifact should have color")
            TestFramework.assert.assertEqual(3, #artifact.color, "Color should have 3 components")
        end
        
        -- Check unique IDs
        local ids = {}
        for _, artifact in ipairs(ArtifactSystem.artifacts) do
            TestFramework.assert.assertNil(ids[artifact.id], "Artifact IDs should be unique")
            ids[artifact.id] = true
        end
    end,
    
    ["test spawn origin fragment near center"] = function()
        local ArtifactSystem = getArtifactSystem()
        local player = createTestPlayer(100, 100) -- Near origin
        local planets = {}
        
        -- Force random to return value that triggers spawn
        local oldRandom = math.random
        math.random = function()
            return 0.005 -- Below 0.01 threshold
        end
        
        ArtifactSystem.spawnArtifacts(player, planets)
        
        -- Check if origin fragment spawned
        local spawned = false
        for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
            if artifact.id == "origin_fragment_1" then
                spawned = true
                TestFramework.assert.assertTrue(math.abs(artifact.x) <= 500, "Should spawn within range")
                TestFramework.assert.assertTrue(math.abs(artifact.y) <= 500, "Should spawn within range")
            end
        end
        
        TestFramework.assert.assertTrue(spawned, "Origin fragment should spawn near center")
        
        -- Restore
        math.random = oldRandom
    end,
    
    ["test spawn ice planet artifact"] = function()
        local ArtifactSystem = getArtifactSystem()
        local player = createTestPlayer(2500, 0)
        local planets = {
            createTestPlanet(2500, 0, "ice", true)
        }
        
        -- Force spawn
        local oldRandom = math.random
        local callCount = 0
        math.random = function(min, max)
            callCount = callCount + 1
            if min == nil then
                return 0.01 -- Trigger spawn
            else
                return (min + max) / 2 -- Return middle value for position
            end
        end
        
        ArtifactSystem.spawnArtifacts(player, planets)
        
        -- Check if ice artifact spawned
        local spawned = false
        for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
            if artifact.id == "origin_fragment_2" then
                spawned = true
                -- Should spawn near ice planet
                local dist = Utils.distance(artifact.x, artifact.y, planets[1].x, planets[1].y)
                TestFramework.assert.assertTrue(dist <= 300, "Should spawn near ice planet")
            end
        end
        
        TestFramework.assert.assertTrue(spawned, "Ice artifact should spawn near ice planet")
        
        -- Restore
        math.random = oldRandom
    end,
    
    ["test spawn tech planet artifact"] = function()
        local ArtifactSystem = getArtifactSystem()
        local player = createTestPlayer(0, 0)
        local planets = {
            createTestPlanet(500, 500, "tech", true)
        }
        
        -- Force spawn
        local oldRandom = math.random
        math.random = function(min, max)
            if min == nil then
                return 0.01
            else
                return (min + max) / 2
            end
        end
        
        ArtifactSystem.spawnArtifacts(player, planets)
        
        -- Check if tech artifact spawned
        local spawned = false
        for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
            if artifact.id == "origin_fragment_3" then
                spawned = true
            end
        end
        
        TestFramework.assert.assertTrue(spawned, "Tech artifact should spawn near tech planet")
        
        -- Restore
        math.random = oldRandom
    end,
    
    ["test is artifact spawned"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- Add test artifact
        table.insert(ArtifactSystem.spawnedArtifacts, {
            id = "test_artifact",
            x = 100,
            y = 100
        })
        
        TestFramework.assert.assertTrue(
            ArtifactSystem.isArtifactSpawned("test_artifact"),
            "Should find spawned artifact"
        )
        
        TestFramework.assert.assertFalse(
            ArtifactSystem.isArtifactSpawned("non_existent"),
            "Should not find non-existent artifact"
        )
    end,
    
    ["test artifact collection"] = function()
        resetMocks()
        local ArtifactSystem = getArtifactSystem()
        
        -- Create and add artifact
        local artifactDef = ArtifactSystem.artifacts[1]
        local artifact = {
            x = 100,
            y = 100,
            id = artifactDef.id,
            definition = artifactDef,
            collected = false,
            glowRadius = 50,
            particles = {}
        }
        table.insert(ArtifactSystem.spawnedArtifacts, artifact)
        
        -- Collect it
        ArtifactSystem.collectArtifact(artifact, 1)
        
        TestFramework.assert.assertTrue(artifact.collected, "Artifact should be marked collected")
        TestFramework.assert.assertTrue(artifactDef.discovered, "Artifact definition should be marked discovered")
        TestFramework.assert.assertEqual(1, ArtifactSystem.collectedCount, "Collected count should increase")
        TestFramework.assert.assertEqual(0, #ArtifactSystem.spawnedArtifacts, "Artifact should be removed from spawned list")
        TestFramework.assert.assertEqual(1, #ArtifactSystem.notificationQueue, "Notification should be added")
        TestFramework.assert.assertEqual(1000, _G.mockGameState.lastScoreAdded, "Score should be awarded")
        TestFramework.assert.assertEqual(100, _G.mockUpgradeSystem.lastCurrencyAdded, "Currency should be awarded")
        TestFramework.assert.assertTrue(_G.mockSoundManager.eventWarningPlayed, "Sound should play")
        TestFramework.assert.assertEqual(artifactDef.id, _G.mockAchievementSystem.artifactsCollected[1], "Achievement should track collection")
    end,
    
    ["test collection triggers all artifacts achievement"] = function()
        resetMocks()
        local ArtifactSystem = getArtifactSystem()
        
        -- Set collected count to max - 1
        ArtifactSystem.collectedCount = #ArtifactSystem.artifacts - 1
        
        -- Collect final artifact
        local artifactDef = ArtifactSystem.artifacts[1]
        local artifact = {
            x = 100,
            y = 100,
            id = artifactDef.id,
            definition = artifactDef,
            collected = false,
            glowRadius = 50,
            particles = {}
        }
        table.insert(ArtifactSystem.spawnedArtifacts, artifact)
        
        ArtifactSystem.collectArtifact(artifact, 1)
        
        TestFramework.assert.assertTrue(_G.mockAchievementSystem.allArtifactsCollected, "Should trigger all artifacts achievement")
    end,
    
    ["test update with player nearby"] = function()
        resetMocks()
        local ArtifactSystem = getArtifactSystem()
        
        -- Add artifact
        local artifactDef = ArtifactSystem.artifacts[1]
        local artifact = {
            x = 100,
            y = 100,
            id = artifactDef.id,
            definition = artifactDef,
            collected = false,
            glowRadius = 50,
            particles = {}
        }
        table.insert(ArtifactSystem.spawnedArtifacts, artifact)
        
        -- Player far away - should not collect
        local player = createTestPlayer(200, 200)
        ArtifactSystem.update(0.1, player, {})
        TestFramework.assert.assertEqual(1, #ArtifactSystem.spawnedArtifacts, "Artifact should not be collected when far")
        
        -- Player close - should collect
        player.x = 110
        player.y = 110
        
        ArtifactSystem.update(0.1, player, {})
        TestFramework.assert.assertEqual(0, #ArtifactSystem.spawnedArtifacts, "Artifact should be collected when close")
        TestFramework.assert.assertEqual(1, ArtifactSystem.collectedCount, "Collected count should increase")
    end,
    
    ["test particle effects update"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- Add artifact
        local artifact = {
            x = 100,
            y = 100,
            collected = false,
            glowRadius = 50,
            particles = {}
        }
        table.insert(ArtifactSystem.spawnedArtifacts, artifact)
        
        -- Update to trigger particle creation
        ArtifactSystem.particleTimer = 0.11 -- Above threshold
        local player = createTestPlayer(500, 500)
        ArtifactSystem.update(0.01, player, {}) -- Small dt to minimize life decrease
        
        TestFramework.assert.assertTrue(#artifact.particles > 0, "Particles should be created")
        
        local particle = artifact.particles[1]
        TestFramework.assert.assertTrue(math.abs(particle.x - 100) < 1, "Particle should start near artifact X position")
        TestFramework.assert.assertTrue(math.abs(particle.y - 100) < 1, "Particle should start near artifact Y position")
        TestFramework.assert.assertTrue(particle.life >= 0.99, "Particle should have nearly full life")
        
        -- Update particle
        local oldX = particle.x
        ArtifactSystem.update(0.1, createTestPlayer(500, 500), {})
        
        TestFramework.assert.assertTrue(particle.x ~= oldX or particle.y ~= 100, "Particle should move")
        TestFramework.assert.assertTrue(particle.life < 1.0, "Particle life should decrease")
    end,
    
    ["test notification system"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- Add notification
        local artifact = ArtifactSystem.artifacts[1]
        table.insert(ArtifactSystem.notificationQueue, {
            artifact = artifact,
            time = love.timer.getTime()
        })
        ArtifactSystem.notificationTimer = 5
        
        -- Update timer
        ArtifactSystem.update(1, createTestPlayer(0, 0), {})
        TestFramework.assert.assertEqual(4, ArtifactSystem.notificationTimer, "Timer should decrease")
        
        -- Update until expired
        ArtifactSystem.update(5, createTestPlayer(0, 0), {})
        TestFramework.assert.assertEqual(0, #ArtifactSystem.notificationQueue, "Notification should be removed when expired")
    end,
    
    ["test visual effects update"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        local oldPhase = ArtifactSystem.pulsePhase
        ArtifactSystem.update(0.5, createTestPlayer(0, 0), {})
        
        TestFramework.assert.assertTrue(ArtifactSystem.pulsePhase > oldPhase, "Pulse phase should increase")
    end,
    
    ["test get artifact by id"] = function()
        local ArtifactSystem = getArtifactSystem()
        local artifact = ArtifactSystem.getArtifact("origin_fragment_1")
        TestFramework.assert.assertNotNil(artifact, "Should find artifact by ID")
        TestFramework.assert.assertEqual("Origin Fragment I", artifact.name, "Should return correct artifact")
        
        local nonExistent = ArtifactSystem.getArtifact("fake_id")
        TestFramework.assert.assertNil(nonExistent, "Should return nil for non-existent ID")
    end,
    
    ["test get discovered artifacts"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- No artifacts discovered initially
        local discovered = ArtifactSystem.getDiscoveredArtifacts()
        TestFramework.assert.assertEqual(0, #discovered, "No artifacts should be discovered initially")
        
        -- Mark some as discovered
        ArtifactSystem.artifacts[1].discovered = true
        ArtifactSystem.artifacts[3].discovered = true
        
        discovered = ArtifactSystem.getDiscoveredArtifacts()
        TestFramework.assert.assertEqual(2, #discovered, "Should return only discovered artifacts")
        TestFramework.assert.assertEqual("origin_fragment_1", discovered[1].id, "Should return correct artifacts")
    end,
    
    ["test final truth spawn condition"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- Set collected count to trigger final artifact
        ArtifactSystem.collectedCount = #ArtifactSystem.artifacts - 1
        
        -- Force spawn check
        local oldRandom = math.random
        math.random = function() return 0 end
        
        ArtifactSystem.spawnArtifacts(createTestPlayer(0, 0), {})
        
        -- Check if final artifact spawned
        local spawned = false
        for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
            if artifact.id == "final_truth" then
                spawned = true
                TestFramework.assert.assertEqual(0, artifact.x, "Final artifact should spawn at origin X")
                TestFramework.assert.assertEqual(-5000, artifact.y, "Final artifact should spawn far above")
            end
        end
        
        TestFramework.assert.assertTrue(spawned, "Final artifact should spawn when all others collected")
        
        -- Restore
        math.random = oldRandom
    end,
    
    ["test warp zone artifact spawn"] = function()
        local ArtifactSystem = getArtifactSystem()
        
        -- Mock warp zones
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.warp_zones" then
                return {
                    activeZones = {{x = 1000, y = 1000}}
                }
            else
                return oldRequire(path)
            end
        end
        
        -- Force spawn
        local oldRandom = math.random
        math.random = function(min, max)
            if min == nil then
                return 0.01
            else
                return (min + max) / 2
            end
        end
        
        ArtifactSystem.spawnArtifacts(createTestPlayer(0, 0), {})
        
        -- Check if explorer log 2 spawned near warp zone
        local spawned = false
        for _, artifact in ipairs(ArtifactSystem.spawnedArtifacts) do
            if artifact.id == "explorer_log_2" then
                spawned = true
                local dist = Utils.distance(artifact.x, artifact.y, 1000, 1000)
                TestFramework.assert.assertTrue(dist <= 400, "Should spawn near warp zone")
            end
        end
        
        TestFramework.assert.assertTrue(spawned, "Explorer log should spawn near warp zone")
        
        -- Restore
        Utils.require = oldRequire
        math.random = oldRandom
    end
}

-- Run the test suite
local function run()
    local result = TestFramework.runTests(tests, "Artifact System Tests")
    -- Restore original Utils.require
    Utils.require = originalUtilsRequire
    return result
end

return {run = run}