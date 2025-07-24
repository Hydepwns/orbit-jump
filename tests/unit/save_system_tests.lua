-- Modern Save System Tests
-- Tests for save/load functionality with proper mocking

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")
local SaveSystem = Utils.require("src.systems.save_system")

local tests = {
    -- Save system initialization
    ["should initialize save system"] = function()
        ModernTestFramework.utils.resetCalls()
        
        SaveSystem.init()
        
        ModernTestFramework.assert.called("filesystemSetIdentity", 1, "Should set filesystem identity")
    end,
    
    ["should get save directory"] = function()
        local saveDir = SaveSystem.getSaveDirectory()
        ModernTestFramework.assert.notNil(saveDir, "Should return save directory")
        ModernTestFramework.assert.contains("/", saveDir, "Save directory should contain path separator")
    end,
    
    -- Save data collection
    ["should collect save data with player stats"] = function()
        -- Mock GameState
        local mockGameState = {
            data = {
                score = 1000,
                gameTime = 300
            }
        }
        
        -- Mock ProgressionSystem
        local mockProgressionSystem = {
            data = {
                totalScore = 5000,
                totalRingsCollected = 25,
                totalJumps = 15,
                totalDashes = 8,
                maxCombo = 6,
                totalPlayTime = 1200
            }
        }
        
        -- Mock UpgradeSystem
        local mockUpgradeSystem = {
            currency = 500,
            upgrades = {
                jump_power = { currentLevel = 3 },
                dash_power = { currentLevel = 2 }
            }
        }
        
        -- Mock AchievementSystem
        local mockAchievementSystem = {
            achievements = {
                first_planet = { unlocked = true },
                combo_master = { unlocked = false }
            }
        }
        
        -- Override requires
        local originalRequire = Utils.require
        Utils.require = function(path)
            if path == "src.core.game_state" then
                return mockGameState
            elseif path == "src.systems.progression_system" then
                return mockProgressionSystem
            elseif path == "src.systems.upgrade_system" then
                return mockUpgradeSystem
            elseif path == "src.systems.achievement_system" then
                return mockAchievementSystem
            else
                return originalRequire(path)
            end
        end
        
        local saveData = SaveSystem.collectSaveData()
        
        -- Restore original require
        Utils.require = originalRequire
        
        ModernTestFramework.assert.notNil(saveData, "Should return save data")
        ModernTestFramework.assert.equal(1, saveData.version, "Should have correct version")
        ModernTestFramework.assert.notNil(saveData.timestamp, "Should have timestamp")
        ModernTestFramework.assert.notNil(saveData.player, "Should have player data")
        ModernTestFramework.assert.notNil(saveData.upgrades, "Should have upgrades data")
        ModernTestFramework.assert.notNil(saveData.achievements, "Should have achievements data")
    end,
    
    ["should handle missing systems gracefully"] = function()
        -- Override requires to return nil
        local originalRequire = Utils.require
        Utils.require = function(path)
            return nil
        end
        
        local saveData = SaveSystem.collectSaveData()
        
        -- Restore original require
        Utils.require = originalRequire
        
        ModernTestFramework.assert.notNil(saveData, "Should return save data even with missing systems")
        ModernTestFramework.assert.equal(0, saveData.player.totalScore, "Should have default values")
    end,
    
    -- Save functionality
    ["should save game data successfully"] = function()
        ModernTestFramework.utils.resetCalls()
        
        local success, message = SaveSystem.save()
        
        ModernTestFramework.assert.isTrue(success, "Should save successfully")
        ModernTestFramework.assert.called("filesystemWrite", 1, "Should write to filesystem")
    end,
    
    ["should handle save failure gracefully"] = function()
        -- Mock filesystem to fail
        local originalWrite = love.filesystem.write
        love.filesystem.write = function() return false, "Mock error" end
        
        local success, message = SaveSystem.save()
        
        -- Restore original function
        love.filesystem.write = originalWrite
        
        ModernTestFramework.assert.isFalse(success, "Should handle save failure")
        ModernTestFramework.assert.notNil(message, "Should return error message")
    end,
    
    -- Load functionality
    ["should load game data successfully"] = function()
        -- Mock filesystem to return valid save data
        local mockSaveData = {
            version = 1,
            timestamp = os.time(),
            player = {
                totalScore = 1000,
                totalRingsCollected = 25,
                totalJumps = 15,
                totalDashes = 8,
                maxCombo = 6,
                gameTime = 300
            },
            upgrades = {
                jump_power = { currentLevel = 3 },
                dash_power = { currentLevel = 2 }
            },
            achievements = {
                first_planet = { unlocked = true }
            },
            currency = 500
        }
        
        local originalRead = love.filesystem.read
        local originalGetInfo = love.filesystem.getInfo
        
        love.filesystem.read = function() 
            return Utils.require("libs.json").encode(mockSaveData), nil 
        end
        love.filesystem.getInfo = function() 
            return { size = 1024, type = "file" } 
        end
        
        local success = SaveSystem.load()
        
        -- Restore original functions
        love.filesystem.read = originalRead
        love.filesystem.getInfo = originalGetInfo
        
        ModernTestFramework.assert.isTrue(success, "Should load successfully")
    end,
    
    ["should handle missing save file"] = function()
        local originalGetInfo = love.filesystem.getInfo
        love.filesystem.getInfo = function() return nil end
        
        local success, message = SaveSystem.load()
        
        -- Restore original function
        love.filesystem.getInfo = originalGetInfo
        
        ModernTestFramework.assert.isFalse(success, "Should handle missing save file")
        ModernTestFramework.assert.contains("No save file", message, "Should return appropriate message")
    end,
    
    ["should handle corrupted save file"] = function()
        local originalRead = love.filesystem.read
        local originalGetInfo = love.filesystem.getInfo
        
        love.filesystem.read = function() return "invalid json", nil end
        love.filesystem.getInfo = function() return { size = 1024, type = "file" } end
        
        local success, message = SaveSystem.load()
        
        -- Restore original functions
        love.filesystem.read = originalRead
        love.filesystem.getInfo = originalGetInfo
        
        ModernTestFramework.assert.isFalse(success, "Should handle corrupted save file")
        ModernTestFramework.assert.contains("Corrupted", message, "Should return corruption message")
    end,
    
    ["should handle version mismatch"] = function()
        -- Mock filesystem to return old version save data
        local mockSaveData = {
            version = 0, -- Old version
            timestamp = os.time(),
            player = { totalScore = 1000 }
        }
        
        local originalRead = love.filesystem.read
        local originalGetInfo = love.filesystem.getInfo
        
        love.filesystem.read = function() 
            return Utils.require("libs.json").encode(mockSaveData), nil 
        end
        love.filesystem.getInfo = function() 
            return { size = 1024, type = "file" } 
        end
        
        local success = SaveSystem.load()
        
        -- Restore original functions
        love.filesystem.read = originalRead
        love.filesystem.getInfo = originalGetInfo
        
        ModernTestFramework.assert.isTrue(success, "Should load with version mismatch")
    end,
    
    -- Auto-save functionality
    ["should auto-save when interval is reached"] = function()
        SaveSystem.lastAutoSave = 0 -- Reset to force auto-save
        ModernTestFramework.utils.resetCalls()
        
        -- Set up game state
        _G.Game = {
            state = {player = {x = 100, y = 100}},
            getSaveData = function() return {player = {x = 100, y = 100}} end
        }
        
        SaveSystem.update(60) -- 60 seconds elapsed
        
        ModernTestFramework.assert.calledAtLeast("filesystemWrite", 1, "Should auto-save when interval reached")
    end,
    
    ["should not auto-save before interval"] = function()
        SaveSystem.lastAutoSave = os.time() -- Set to current time
        ModernTestFramework.utils.resetCalls()
        
        SaveSystem.update(30) -- 30 seconds elapsed
        
        ModernTestFramework.assert.called("filesystemWrite", 0, "Should not auto-save before interval")
    end,
    
    -- Save indicator
    ["should show save indicator after saving"] = function()
        SaveSystem.showSaveIndicator = false
        SaveSystem.saveIndicatorTimer = 0
        
        SaveSystem.save()
        
        ModernTestFramework.assert.isTrue(SaveSystem.showSaveIndicator, "Should show save indicator")
        ModernTestFramework.assert.isTrue(SaveSystem.saveIndicatorTimer > 0, "Should set indicator timer")
    end,
    
    ["should update save indicator timer"] = function()
        SaveSystem.showSaveIndicator = true
        SaveSystem.saveIndicatorTimer = 2.0
        
        SaveSystem.update(1.0) -- 1 second elapsed
        
        ModernTestFramework.assert.isTrue(SaveSystem.saveIndicatorTimer < 2.0, "Should decrease indicator timer")
    end,
    
    ["should hide save indicator when timer expires"] = function()
        SaveSystem.showSaveIndicator = true
        SaveSystem.saveIndicatorTimer = 0.5
        
        SaveSystem.update(1.0) -- 1 second elapsed
        
        ModernTestFramework.assert.isFalse(SaveSystem.showSaveIndicator, "Should hide indicator when timer expires")
    end,
    
    -- Save validation
    ["should validate save data structure"] = function()
        local saveData = SaveSystem.collectSaveData()
        
        ModernTestFramework.assert.notNil(saveData.version, "Should have version")
        ModernTestFramework.assert.notNil(saveData.timestamp, "Should have timestamp")
        ModernTestFramework.assert.notNil(saveData.player, "Should have player data")
        ModernTestFramework.assert.type("table", saveData.player, "Player data should be table")
        ModernTestFramework.assert.type("table", saveData.upgrades, "Upgrades data should be table")
        ModernTestFramework.assert.type("table", saveData.achievements, "Achievements data should be table")
    end,
    
    ["should handle save data migration"] = function()
        -- This test would verify that old save formats are properly migrated
        -- For now, we'll just test that the system doesn't crash with old data
        
        local oldSaveData = {
            version = 0,
            score = 1000, -- Old format
            rings = 25     -- Old format
        }
        
        -- Mock filesystem to return old format
        local originalRead = love.filesystem.read
        local originalGetInfo = love.filesystem.getInfo
        
        love.filesystem.read = function() 
            return Utils.require("libs.json").encode(oldSaveData), nil 
        end
        love.filesystem.getInfo = function() 
            return { size = 1024, type = "file" } 
        end
        
        local success = SaveSystem.load()
        
        -- Restore original functions
        love.filesystem.read = originalRead
        love.filesystem.getInfo = originalGetInfo
        
        ModernTestFramework.assert.isTrue(success, "Should handle old save format")
    end
}

return tests 