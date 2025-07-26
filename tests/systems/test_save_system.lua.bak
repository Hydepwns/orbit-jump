-- Comprehensive tests for Save System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks before requiring SaveSystem
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Mock love.filesystem
mockFilesystem = {
    files = {},
    saveDirectory = "/mock/save/dir",
    
    setIdentity = function(identity)
        -- Mock implementation
    end,
    
    getSaveDirectory = function()
        return mockFilesystem.saveDirectory
    end,
    
    write = function(filename, data)
        mockFilesystem.files[filename] = data
        return true, nil
    end,
    
    read = function(filename)
        local data = mockFilesystem.files[filename]
        if data then
            return data, #data
        else
            return nil, "File not found"
        end
    end,
    
    getInfo = function(filename)
        if mockFilesystem.files[filename] then
            return {
                size = #mockFilesystem.files[filename],
                type = "file"
            }
        else
            return nil
        end
    end,
    
    remove = function(filename)
        if mockFilesystem.files[filename] then
            mockFilesystem.files[filename] = nil
            return true
        else
            return false
        end
    end
}

-- Replace love.filesystem with mock
love.filesystem = mockFilesystem

-- Mock love.timer
love.timer = {
    currentTime = 0,
    getTime = function()
        return love.timer.currentTime
    end
}

-- Require SaveSystem after mocks are set up
local SaveSystem = Utils.require("src.systems.save_system")

-- Mock dependencies
local mockGameState = {
    data = {
        score = 1000,
        gameTime = 300
    }
}

local mockProgressionSystem = {
    data = {
        totalScore = 5000,
        totalRingsCollected = 100,
        totalJumps = 50,
        totalDashes = 25,
        maxCombo = 10,
        totalPlayTime = 3600
    }
}

local mockUpgradeSystem = {
    currency = 500,
    upgrades = {
        jump_power = { currentLevel = 2 },
        dash_distance = { currentLevel = 1 },
        warp_drive = { currentLevel = 0 }
    }
}

local mockAchievementSystem = {
    achievements = {
        first_ring = { unlocked = true, unlockedAt = 1234567890 },
        combo_master = { unlocked = false },
        speed_demon = { unlocked = true, unlockedAt = 1234567900 }
    },
    stats = {
        ringsCollected = 100,
        jumpsPerformed = 50
    }
}

local mockMapSystem = {
    discoveredPlanets = {
        planet_1 = { x = 100, y = 200, type = "ice", discovered = true },
        planet_2 = { x = 300, y = 400, type = "lava", discovered = true }
    }
}

local mockArtifactSystem = {
    artifacts = {
        { id = "artifact_1", discovered = true },
        { id = "artifact_2", discovered = false },
        { id = "artifact_3", discovered = true }
    },
    collectedCount = 2
}

local mockWarpDrive = {
    isUnlocked = true,
    energy = 75,
    maxEnergy = 100,
    unlock = function() end
}

-- Mock JSON library
local mockJson = {
    encode = function(data)
        -- Simple JSON encoding for testing
        return "MOCK_JSON:" .. tostring(data)
    end,
    
    decode = function(str)
        -- Return predefined test data
        if string.find(str, "MOCK_JSON:") then
            return {
                version = 1,
                timestamp = 1234567890,
                player = {
                    totalScore = 5000,
                    totalRingsCollected = 100,
                    totalJumps = 50,
                    totalDashes = 25,
                    maxCombo = 10,
                    gameTime = 3600
                },
                currency = 500,
                upgrades = {
                    jump_power = { currentLevel = 2 },
                    dash_distance = { currentLevel = 1 }
                },
                achievements = {
                    first_ring = { unlocked = true, unlockedAt = 1234567890 }
                },
                achievementStats = { ringsCollected = 100 },
                discoveredPlanets = {
                    planet_1 = { x = 100, y = 200, type = "ice", discovered = true }
                },
                collectedArtifacts = { artifact_1 = true, artifact_3 = true },
                artifactCount = 2,
                warpDrive = { unlocked = true, energy = 75 }
            }
        else
            error("Invalid JSON")
        end
    end
}

-- Test suite
local tests = {
    ["test initialization"] = function()
        -- Mock require to return our mocks
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        
        love.timer.currentTime = 100
        SaveSystem.init()
        
        TestFramework.utils.assertEqual(100, SaveSystem.lastAutoSave, "Last auto save time should be set")
        TestFramework.utils.assertEqual("/mock/save/dir", SaveSystem.getSaveDirectory(), "Save directory should be correct")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test collect save data"] = function()
        -- Mock all dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then return mockGameState
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            elseif path == "src.systems.map_system" then return mockMapSystem
            elseif path == "src.systems.artifact_system" then return mockArtifactSystem
            elseif path == "src.systems.warp_drive" then return mockWarpDrive
            else return oldRequire(path) end
        end
        
        local saveData = SaveSystem.collectSaveData()
        
        TestFramework.utils.assertNotNil(saveData, "Save data should be collected")
        TestFramework.utils.assertEqual(1, saveData.version, "Save version should be 1")
        TestFramework.utils.assertNotNil(saveData.timestamp, "Timestamp should be set")
        
        -- Check player data
        TestFramework.utils.assertEqual(5000, saveData.player.totalScore, "Total score should be saved")
        TestFramework.utils.assertEqual(100, saveData.player.totalRingsCollected, "Rings collected should be saved")
        TestFramework.utils.assertEqual(50, saveData.player.totalJumps, "Total jumps should be saved")
        TestFramework.utils.assertEqual(25, saveData.player.totalDashes, "Total dashes should be saved")
        TestFramework.utils.assertEqual(10, saveData.player.maxCombo, "Max combo should be saved")
        TestFramework.utils.assertEqual(3600, saveData.player.gameTime, "Game time should be saved")
        
        -- Check currency and upgrades
        TestFramework.utils.assertEqual(500, saveData.currency, "Currency should be saved")
        TestFramework.utils.assertNotNil(saveData.upgrades.jump_power, "Jump power upgrade should be saved")
        TestFramework.utils.assertEqual(2, saveData.upgrades.jump_power.currentLevel, "Jump power level should be correct")
        
        -- Check achievements
        TestFramework.utils.assertNotNil(saveData.achievements.first_ring, "Achievement should be saved")
        TestFramework.utils.assertTrue(saveData.achievements.first_ring.unlocked, "Achievement should be unlocked")
        TestFramework.utils.assertNil(saveData.achievements.combo_master, "Locked achievements should not be saved")
        
        -- Check discovered planets
        TestFramework.utils.assertNotNil(saveData.discoveredPlanets.planet_1, "Discovered planet should be saved")
        TestFramework.utils.assertEqual(100, saveData.discoveredPlanets.planet_1.x, "Planet X coordinate should be saved")
        
        -- Check artifacts
        TestFramework.utils.assertTrue(saveData.collectedArtifacts.artifact_1, "Collected artifact should be saved")
        TestFramework.utils.assertNil(saveData.collectedArtifacts.artifact_2, "Uncollected artifact should not be saved")
        TestFramework.utils.assertEqual(2, saveData.artifactCount, "Artifact count should be saved")
        
        -- Check warp drive
        TestFramework.utils.assertTrue(saveData.warpDrive.unlocked, "Warp drive unlock status should be saved")
        TestFramework.utils.assertEqual(75, saveData.warpDrive.energy, "Warp drive energy should be saved")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test save function"] = function()
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            elseif path == "src.core.game_state" then return mockGameState
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            elseif path == "src.systems.map_system" then return mockMapSystem
            elseif path == "src.systems.artifact_system" then return mockArtifactSystem
            elseif path == "src.systems.warp_drive" then return mockWarpDrive
            else return oldRequire(path) end
        end
        
        -- Clear existing saves
        mockFilesystem.files = {}
        
        love.timer.currentTime = 200
        local success, message = SaveSystem.save()
        
        TestFramework.utils.assertTrue(success, "Save should succeed")
        TestFramework.utils.assertNil(message, "No error message should be returned")
        TestFramework.utils.assertTrue(SaveSystem.showSaveIndicator, "Save indicator should be shown")
        TestFramework.utils.assertEqual(2.0, SaveSystem.saveIndicatorTimer, "Save indicator timer should be set")
        TestFramework.utils.assertEqual(200, SaveSystem.lastAutoSave, "Last auto save time should be updated")
        
        -- Check that file was written
        TestFramework.utils.assertNotNil(mockFilesystem.files[SaveSystem.saveFileName], "Save file should be created")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test save failure"] = function()
        -- Mock filesystem to fail
        mockFilesystem.write = function()
            return false, "Write failed"
        end
        
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        
        local success, message = SaveSystem.save()
        
        TestFramework.utils.assertFalse(success, "Save should fail")
        TestFramework.utils.assertEqual("Write failed", message, "Error message should be returned")
        TestFramework.utils.assertFalse(SaveSystem.showSaveIndicator, "Save indicator should not be shown on failure")
        
        -- Restore
        mockFilesystem.write = function(filename, data)
            mockFilesystem.files[filename] = data
            return true, nil
        end
        Utils.require = oldRequire
    end,
    
    ["test load function"] = function()
        -- Setup save file
        mockFilesystem.files[SaveSystem.saveFileName] = "MOCK_JSON:test"
        
        -- Mock dependencies
        local progressionDataRestored = false
        local upgradesRestored = false
        local achievementsRestored = false
        
        local testProgressionSystem = {
            data = {}
        }
        
        local testUpgradeSystem = {
            currency = 0,
            upgrades = {
                jump_power = { currentLevel = 0 },
                warp_drive = { currentLevel = 0 }
            }
        }
        
        local testAchievementSystem = {
            achievements = {
                first_ring = { unlocked = false }
            },
            stats = {}
        }
        
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            elseif path == "src.systems.progression_system" then return testProgressionSystem
            elseif path == "src.systems.upgrade_system" then return testUpgradeSystem
            elseif path == "src.systems.achievement_system" then return testAchievementSystem
            elseif path == "src.systems.map_system" then return { discoveredPlanets = {} }
            elseif path == "src.systems.artifact_system" then return { artifacts = {}, collectedCount = 0 }
            elseif path == "src.systems.warp_drive" then return { isUnlocked = false, energy = 0 }
            else return oldRequire(path) end
        end
        
        local success, error = SaveSystem.load()
        
        TestFramework.utils.assertTrue(success, "Load should succeed")
        
        -- Check that data was restored
        TestFramework.utils.assertEqual(5000, testProgressionSystem.data.totalScore, "Score should be restored")
        TestFramework.utils.assertEqual(100, testProgressionSystem.data.totalRingsCollected, "Rings collected should be restored")
        TestFramework.utils.assertEqual(500, testUpgradeSystem.currency, "Currency should be restored")
        TestFramework.utils.assertEqual(2, testUpgradeSystem.upgrades.jump_power.currentLevel, "Upgrade level should be restored")
        TestFramework.utils.assertTrue(testAchievementSystem.achievements.first_ring.unlocked, "Achievement should be restored")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test load no save file"] = function()
        -- Clear save files
        mockFilesystem.files = {}
        
        local success, error = SaveSystem.load()
        
        TestFramework.utils.assertFalse(success, "Load should fail when no save exists")
        TestFramework.utils.assertEqual("No save file found", error, "Should return no save file error")
    end,
    
    ["test load corrupted save"] = function()
        -- Create corrupted save file
        mockFilesystem.files[SaveSystem.saveFileName] = "CORRUPTED DATA"
        
        local badJson = {
            decode = function() error("Invalid JSON") end
        }
        
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return badJson
            else return oldRequire(path) end
        end
        
        local success, error = SaveSystem.load()
        
        TestFramework.utils.assertFalse(success, "Load should fail with corrupted save")
        TestFramework.utils.assertEqual("Corrupted save file", error, "Should return corrupted save error")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test auto save"] = function()
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        
        -- Set last auto save time
        love.timer.currentTime = 0
        SaveSystem.lastAutoSave = 0
        SaveSystem.autoSaveInterval = 60
        
        -- Update before interval - should not save
        love.timer.currentTime = 30
        SaveSystem.update(1)
        TestFramework.utils.assertEqual(0, SaveSystem.lastAutoSave, "Should not auto save before interval")
        
        -- Update after interval - should save
        love.timer.currentTime = 61
        SaveSystem.update(1)
        TestFramework.utils.assertEqual(61, SaveSystem.lastAutoSave, "Should auto save after interval")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test save indicator update"] = function()
        SaveSystem.showSaveIndicator = true
        SaveSystem.saveIndicatorTimer = 1.0
        
        SaveSystem.update(0.5)
        TestFramework.utils.assertEqual(0.5, SaveSystem.saveIndicatorTimer, "Save indicator timer should decrease")
        TestFramework.utils.assertTrue(SaveSystem.showSaveIndicator, "Save indicator should still be shown")
        
        SaveSystem.update(0.6)
        TestFramework.utils.assertFalse(SaveSystem.showSaveIndicator, "Save indicator should be hidden after timer expires")
    end,
    
    ["test delete save"] = function()
        -- Create save file
        mockFilesystem.files[SaveSystem.saveFileName] = "test save data"
        
        local success = SaveSystem.deleteSave()
        
        TestFramework.utils.assertTrue(success, "Delete should succeed")
        TestFramework.utils.assertNil(mockFilesystem.files[SaveSystem.saveFileName], "Save file should be deleted")
    end,
    
    ["test has save"] = function()
        -- No save file
        mockFilesystem.files = {}
        TestFramework.utils.assertFalse(SaveSystem.hasSave(), "Should return false when no save exists")
        
        -- With save file
        mockFilesystem.files[SaveSystem.saveFileName] = "test save"
        TestFramework.utils.assertTrue(SaveSystem.hasSave(), "Should return true when save exists")
    end,
    
    ["test get save info"] = function()
        -- No save file
        mockFilesystem.files = {}
        TestFramework.utils.assertNil(SaveSystem.getSaveInfo(), "Should return nil when no save exists")
        
        -- With save file
        mockFilesystem.files[SaveSystem.saveFileName] = "MOCK_JSON:test"
        
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        
        local info = SaveSystem.getSaveInfo()
        
        TestFramework.utils.assertNotNil(info, "Should return save info")
        TestFramework.utils.assertEqual(1234567890, info.timestamp, "Should return correct timestamp")
        TestFramework.utils.assertEqual(1, info.version, "Should return correct version")
        TestFramework.utils.assertEqual(5000, info.score, "Should return correct score")
        TestFramework.utils.assertEqual(3600, info.playtime, "Should return correct playtime")
        
        -- Restore
        Utils.require = oldRequire
    end,
    
    ["test version mismatch handling"] = function()
        -- Create save with different version
        local versionMismatchJson = {
            decode = function()
                return {
                    version = 2,  -- Different version
                    timestamp = 1234567890,
                    player = { totalScore = 1000 }
                }
            end
        }
        
        mockFilesystem.files[SaveSystem.saveFileName] = "test"
        
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return versionMismatchJson
            elseif path == "src.systems.progression_system" then return { data = {} }
            else return oldRequire(path) end
        end
        
        -- Should still load despite version mismatch (with warning)
        local success = SaveSystem.load()
        TestFramework.utils.assertTrue(success, "Should still load with version mismatch")
        
        -- Restore
        Utils.require = oldRequire
    end
}

-- Run the test suite
local function run()
    return TestFramework.runSuite("Save System Tests", tests)
end

return {run = run}