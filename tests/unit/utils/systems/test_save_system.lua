-- Comprehensive tests for Save System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
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
        mockFilesystem.files[filename] = nil
        return true
    end
}
-- Install mocks
love.filesystem = mockFilesystem
-- Mock love.timer
love.timer = {
    currentTime = 0,
    getTime = function()
        return love.timer.currentTime
    end
}
-- Function to get SaveSystem with proper initialization
local function getSaveSystem()
    -- Clear any cached version
    package.loaded["src.systems.save_system"] = nil
    package.loaded["src/systems/save_system"] = nil
    -- Also clear from Utils cache
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.save_system"] = nil
    end
    -- Setup mocks before loading
    Mocks.setup()
    -- Ensure filesystem mock is set and complete
    love.filesystem = mockFilesystem
    -- Ensure all required functions exist
    love.filesystem.setIdentity = mockFilesystem.setIdentity
    love.filesystem.getSaveDirectory = mockFilesystem.getSaveDirectory
    love.filesystem.write = mockFilesystem.write
    love.filesystem.read = mockFilesystem.read
    love.filesystem.getInfo = mockFilesystem.getInfo
    love.filesystem.remove = mockFilesystem.remove
    love.timer = {
        currentTime = 100,  -- Set initial time to 100
        getTime = function()
            return love.timer.currentTime
        end
    }
    -- Mock Utils.require to return our mocks
    local originalUtilsRequire = Utils.require
    Utils.require = function(module)
        if module == "src.core.game_state" then
            return mockGameState
        elseif module == "src.systems.progression_system" then
            return mockProgressionSystem
        elseif module == "src.systems.upgrade_system" then
            return mockUpgradeSystem
        elseif module == "src.systems.achievement_system" then
            return mockAchievementSystem
        elseif module == "src.systems.map_system" then
            return mockMapSystem
        elseif module == "src.systems.artifact_system" then
            return mockArtifactSystem
        elseif module == "src.systems.warp_drive" then
            return mockWarpDrive
        elseif module == "libs.json" then
            return mockJson
        end
        return originalUtilsRequire(module)
    end
    -- Load fresh instance using regular require to bypass cache
    local SaveSystem = require("src.systems.save_system")
    -- Ensure it's initialized
    if SaveSystem and SaveSystem.init then
        SaveSystem.init()
    end
    -- Restore original Utils.require
    Utils.require = originalUtilsRequire
    return SaveSystem
end
-- Mock dependencies
local mockGameState = {
    data = {
        score = 0,  -- GameState tracks current game score, ProgressionSystem tracks total
        gameTime = 3600
    }
}
local mockProgressionSystem = {
    currency = 500,
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
        dash_distance = { currentLevel = 1 }
    }
}
local mockAchievementSystem = {
    achievements = {
        first_ring = { id = "first_ring", unlocked = true, unlockedAt = 1234567890 },
        combo_master = { id = "combo_master", unlocked = false }
    },
    stats = {
        ringsCollected = 100
    }
}
local mockMapSystem = {
    discoveredPlanets = {
        planet_1 = { x = 100, y = 200, type = "ice", discovered = true },
        planet_2 = { x = 300, y = 400, type = "lava", discovered = false }
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
            error("Decode error")
        end
    end
}
-- Test suite
local tests = {
    ["test initialization"] = function()
        local SaveSystem = getSaveSystem()
        TestFramework.assert.assertEqual(100, SaveSystem.lastAutoSave, "Last auto save time should be set")
        TestFramework.assert.assertNotNil(SaveSystem.saveFileName, "Save file name should be set")
        TestFramework.assert.assertEqual(60, SaveSystem.autoSaveInterval, "Auto save interval should be 60 seconds")
    end,
    ["test collect save data"] = function()
        local SaveSystem = getSaveSystem()
        -- Clear any existing registrations
        SaveSystem.saveables = {}
        -- Register mock systems using the new registry pattern
        local mockSystem = {
            serialize = function(self)
                return {
                    totalScore = 5000,
                    totalRingsCollected = 100,
                    totalJumps = 50,
                    totalDashes = 25,
                    maxCombo = 10,
                    totalPlayTime = 3600
                }
            end,
            deserialize = function(self, data) end
        }
        SaveSystem.registerSaveable("progression", mockSystem)
        local saveData = SaveSystem.collectSaveData()
        TestFramework.assert.assertNotNil(saveData, "Save data should be collected")
        TestFramework.assert.assertEqual(1, saveData.version, "Save version should be 1")
        TestFramework.assert.assertNotNil(saveData.timestamp, "Timestamp should be set")
        -- Check progression data in new registry format
        TestFramework.assert.assertNotNil(saveData.systems, "Save data should have systems table")
        TestFramework.assert.assertNotNil(saveData.systems.progression, "Progression data should be saved")
        TestFramework.assert.assertEqual(5000, saveData.systems.progression.totalScore, "Total score should be saved")
        TestFramework.assert.assertEqual(100, saveData.systems.progression.totalRingsCollected, "Rings collected should be saved")
        TestFramework.assert.assertEqual(50, saveData.systems.progression.totalJumps, "Total jumps should be saved")
        TestFramework.assert.assertEqual(25, saveData.systems.progression.totalDashes, "Total dashes should be saved")
        TestFramework.assert.assertEqual(10, saveData.systems.progression.maxCombo, "Max combo should be saved")
        TestFramework.assert.assertEqual(3600, saveData.systems.progression.totalPlayTime, "Game time should be saved")
        -- Test that only registered systems are included (no others)
        local systemCount = 0
        for _ in pairs(saveData.systems) do
            systemCount = systemCount + 1
        end
        TestFramework.assert.assertEqual(1, systemCount, "Should only have 1 registered system")
    end,
    ["test save function"] = function()
        local SaveSystem = getSaveSystem()
        -- Mock Utils.require
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then return mockGameState
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            elseif path == "src.systems.map_system" then return mockMapSystem
            elseif path == "src.systems.artifact_system" then return mockArtifactSystem
            elseif path == "src.systems.warp_drive" then return mockWarpDrive
            elseif path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        -- Clear any existing save
        mockFilesystem.files = {}
        -- Ensure write function is working
        love.filesystem.write = mockFilesystem.write
        -- Set timer
        love.timer.currentTime = 200
        local success = SaveSystem.save()
        TestFramework.assert.assertTrue(success, "Save should succeed")
        TestFramework.assert.assertNotNil(mockFilesystem.files[SaveSystem.saveFileName], "Save file should be created")
        TestFramework.assert.assertEqual(200, SaveSystem.lastAutoSave, "Last auto save time should be updated")
        TestFramework.assert.assertTrue(SaveSystem.showSaveIndicator, "Save indicator should be shown")
        TestFramework.assert.assertEqual(2.0, SaveSystem.saveIndicatorTimer, "Save indicator timer should be set")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test save failure"] = function()
        local SaveSystem = getSaveSystem()
        -- Mock Utils.require
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then return mockGameState
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            elseif path == "src.systems.map_system" then return mockMapSystem
            elseif path == "src.systems.artifact_system" then return mockArtifactSystem
            elseif path == "src.systems.warp_drive" then return mockWarpDrive
            elseif path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        -- Store original write function
        local originalWrite = love.filesystem.write
        -- Mock filesystem to fail
        love.filesystem.write = function(filename, data)
            return false, "Write failed"
        end
        local success = SaveSystem.save()
        TestFramework.assert.assertFalse(success, "Save should fail when write fails")
        -- Restore
        love.filesystem.write = originalWrite
        Utils.require = oldRequire
    end,
    ["test load function"] = function()
        local SaveSystem = getSaveSystem()
        -- Setup save file
        mockFilesystem.files[SaveSystem.saveFileName] = "MOCK_JSON:test"
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then return mockGameState
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            elseif path == "src.systems.map_system" then return mockMapSystem
            elseif path == "src.systems.artifact_system" then return mockArtifactSystem
            elseif path == "src.systems.warp_drive" then return mockWarpDrive
            elseif path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        local success = SaveSystem.load()
        TestFramework.assert.assertTrue(success, "Load should succeed")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test load no save file"] = function()
        local SaveSystem = getSaveSystem()
        -- Clear save files
        mockFilesystem.files = {}
        local success = SaveSystem.load()
        TestFramework.assert.assertFalse(success, "Load should fail when no save file exists")
    end,
    ["test load corrupted save"] = function()
        local SaveSystem = getSaveSystem()
        -- Create corrupted save file
        mockFilesystem.files[SaveSystem.saveFileName] = "CORRUPTED DATA"
        local badJson = {
            decode = function(str)
                error("Decode error")
            end
        }
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return badJson
            else return oldRequire(path) end
        end
        local success = SaveSystem.load()
        TestFramework.assert.assertFalse(success, "Load should fail with corrupted data")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test auto save"] = function()
        local SaveSystem = getSaveSystem()
        -- Set last auto save time
        love.timer.currentTime = 0
        SaveSystem.lastAutoSave = 0
        SaveSystem.autoSaveInterval = 60
        -- Update before interval - should not save
        love.timer.currentTime = 30
        SaveSystem.update(1)
        TestFramework.assert.assertEqual(0, SaveSystem.lastAutoSave, "Should not auto save before interval")
        -- Update after interval - should save
        love.timer.currentTime = 61
        -- Ensure write function is working
        love.filesystem.write = mockFilesystem.write
        mockFilesystem.files = {}
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then return mockGameState
            elseif path == "src.systems.progression_system" then return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then return mockAchievementSystem
            elseif path == "src.systems.map_system" then return mockMapSystem
            elseif path == "src.systems.artifact_system" then return mockArtifactSystem
            elseif path == "src.systems.warp_drive" then return mockWarpDrive
            elseif path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        SaveSystem.update(1)
        TestFramework.assert.assertEqual(61, SaveSystem.lastAutoSave, "Should auto save after interval")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test save indicator update"] = function()
        local SaveSystem = getSaveSystem()
        SaveSystem.showSaveIndicator = true
        SaveSystem.saveIndicatorTimer = 1.0
        SaveSystem.update(0.5)
        TestFramework.assert.assertEqual(0.5, SaveSystem.saveIndicatorTimer, "Save indicator timer should decrease")
        TestFramework.assert.assertTrue(SaveSystem.showSaveIndicator, "Save indicator should still be shown")
        SaveSystem.update(0.6)
        TestFramework.assert.assertTrue(SaveSystem.saveIndicatorTimer <= 0, "Save indicator timer should be zero or negative")
        TestFramework.assert.assertFalse(SaveSystem.showSaveIndicator, "Save indicator should be hidden")
    end,
    ["test delete save"] = function()
        local SaveSystem = getSaveSystem()
        -- Create save file
        mockFilesystem.files[SaveSystem.saveFileName] = "test save data"
        local success = SaveSystem.deleteSave()
        TestFramework.assert.assertTrue(success, "Delete should succeed")
        TestFramework.assert.assertNil(mockFilesystem.files[SaveSystem.saveFileName], "Save file should be deleted")
    end,
    ["test has save"] = function()
        local SaveSystem = getSaveSystem()
        -- No save file
        mockFilesystem.files = {}
        TestFramework.assert.assertFalse(SaveSystem.hasSave(), "Should return false when no save exists")
        -- With save file
        mockFilesystem.files[SaveSystem.saveFileName] = "test save"
        TestFramework.assert.assertTrue(SaveSystem.hasSave(), "Should return true when save exists")
    end,
    ["test get save info"] = function()
        local SaveSystem = getSaveSystem()
        -- No save file
        mockFilesystem.files = {}
        local info = SaveSystem.getSaveInfo()
        TestFramework.assert.assertNil(info, "Should return nil when no save exists")
        -- With save file
        mockFilesystem.files[SaveSystem.saveFileName] = "MOCK_JSON:test"
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "libs.json" then return mockJson
            else return oldRequire(path) end
        end
        info = SaveSystem.getSaveInfo()
        TestFramework.assert.assertNotNil(info, "Should return save info")
        TestFramework.assert.assertEqual(1234567890, info.timestamp, "Should return timestamp")
        TestFramework.assert.assertEqual(5000, info.score, "Should return total score")
        TestFramework.assert.assertEqual(3600, info.playtime, "Should return playtime")
        TestFramework.assert.assertEqual(1, info.version, "Should return version")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test version mismatch handling"] = function()
        local SaveSystem = getSaveSystem()
        local versionMismatchJson = {
            decode = function(str)
                return {
                    version = 999,  -- Future version
                    timestamp = 1234567890
                }
            end
        }
        mockFilesystem.files[SaveSystem.saveFileName] = "test"
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "external.json" then return versionMismatchJson
            else return oldRequire(path) end
        end
        local success = SaveSystem.load()
        TestFramework.assert.assertFalse(success, "Should fail to load save with mismatched version")
        -- Restore
        Utils.require = oldRequire
    end,
}
local function run()
    -- Initialize test framework
    Mocks.setup()
    TestFramework.init()
    local success = TestFramework.runTests(tests, "Save System Tests")
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("save_system", 13) -- All major functions tested
    return success
end
return {run = run}