-- Save System for Orbit Jump
-- Handles saving and loading game progress

local Utils = require("src.utils.utils")
local SaveSystem = {}

-- Save file location
SaveSystem.saveFileName = "orbit_jump_save.dat"
SaveSystem.autoSaveInterval = 60 -- seconds
SaveSystem.lastAutoSave = 0
SaveSystem.saveVersion = 1

-- UI state
SaveSystem.showSaveIndicator = false
SaveSystem.saveIndicatorTimer = 0

-- Get save directory based on OS
function SaveSystem.getSaveDirectory()
    local saveDir = love.filesystem.getSaveDirectory()
    return saveDir
end

-- Initialize save system
function SaveSystem.init()
    SaveSystem.lastAutoSave = love.timer.getTime()
    
    -- Ensure save directory exists
    love.filesystem.setIdentity("orbit_jump")
    
    Utils.Logger.info("Save system initialized. Save directory: %s", SaveSystem.getSaveDirectory())
end

-- Collect all game data to save
function SaveSystem.collectSaveData()
    local saveData = {
        version = SaveSystem.saveVersion,
        timestamp = os.time(),
        
        -- Player stats
        player = {
            totalScore = 0,
            totalRingsCollected = 0,
            totalJumps = 0,
            totalDashes = 0,
            maxCombo = 0,
            gameTime = 0
        },
        
        -- Progression
        upgrades = {},
        achievements = {},
        
        -- Discovery
        discoveredPlanets = {},
        collectedArtifacts = {},
        
        -- Currency
        currency = 0
    }
    
    -- Get player stats from GameState
    local GameState = Utils.require("src.core.game_state")
    if GameState then
        saveData.player.totalScore = GameState.data.score or 0
        saveData.player.gameTime = GameState.data.gameTime or 0
    end
    
    -- Get progression data
    local ProgressionSystem = Utils.require("src.systems.progression_system")
    if ProgressionSystem and ProgressionSystem.data then
        saveData.player.totalScore = ProgressionSystem.data.totalScore or 0
        saveData.player.totalRingsCollected = ProgressionSystem.data.totalRingsCollected or 0
        saveData.player.totalJumps = ProgressionSystem.data.totalJumps or 0
        saveData.player.totalDashes = ProgressionSystem.data.totalDashes or 0
        saveData.player.maxCombo = ProgressionSystem.data.maxCombo or 0
        saveData.player.gameTime = ProgressionSystem.data.totalPlayTime or 0
    end
    
    -- Get upgrade data
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    if UpgradeSystem then
        saveData.currency = UpgradeSystem.currency or 0
        saveData.upgrades = {}
        
        for id, upgrade in pairs(UpgradeSystem.upgrades) do
            saveData.upgrades[id] = {
                currentLevel = upgrade.currentLevel or 0
            }
        end
    end
    
    -- Get achievement data
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem then
        saveData.achievements = {}
        
        -- Save achievement unlock status
        for id, achievement in pairs(AchievementSystem.achievements) do
            if achievement.unlocked then
                saveData.achievements[id] = {
                    unlocked = true,
                    unlockedAt = achievement.unlockedAt
                }
            end
        end
        
        -- Save stats
        saveData.achievementStats = AchievementSystem.stats or {}
    end
    
    -- Get discovered planets from MapSystem
    local MapSystem = Utils.require("src.systems.map_system")
    if MapSystem and MapSystem.discoveredPlanets then
        saveData.discoveredPlanets = {}
        for id, planet in pairs(MapSystem.discoveredPlanets) do
            saveData.discoveredPlanets[id] = {
                x = planet.x,
                y = planet.y,
                type = planet.type,
                discovered = true
            }
        end
    end
    
    -- Get collected artifacts
    local ArtifactSystem = Utils.require("src.systems.artifact_system")
    if ArtifactSystem then
        saveData.collectedArtifacts = {}
        for _, artifact in ipairs(ArtifactSystem.artifacts) do
            if artifact.discovered then
                saveData.collectedArtifacts[artifact.id] = true
            end
        end
        saveData.artifactCount = ArtifactSystem.collectedCount or 0
    end
    
    -- Get warp drive status
    local WarpDrive = Utils.require("src.systems.warp_drive")
    if WarpDrive then
        saveData.warpDrive = {
            unlocked = WarpDrive.isUnlocked,
            energy = WarpDrive.energy
        }
    end
    
    return saveData
end

-- Save game data
function SaveSystem.save()
    local success = false
    local message = ""
    
    -- Collect save data
    local saveData = SaveSystem.collectSaveData()
    
    -- Serialize to JSON
    local json = Utils.require("libs.json")
    local saveString = json.encode(saveData)
    
    -- Write to file
    success, message = love.filesystem.write(SaveSystem.saveFileName, saveString)
    
    if success then
        Utils.Logger.info("Game saved successfully")
        SaveSystem.lastAutoSave = love.timer.getTime()
        SaveSystem.showSaveIndicator = true
        SaveSystem.saveIndicatorTimer = 2.0 -- Show for 2 seconds
    else
        Utils.Logger.error("Failed to save game: %s", message)
    end
    
    return success, message
end

-- Load game data
function SaveSystem.load()
    -- Check if save file exists
    if not love.filesystem.getInfo(SaveSystem.saveFileName) then
        Utils.Logger.info("No save file found")
        return false, "No save file found"
    end
    
    -- Read save file
    local contents, sizeOrError = love.filesystem.read(SaveSystem.saveFileName)
    if not contents then
        Utils.Logger.error("Failed to read save file: %s", sizeOrError)
        return false, sizeOrError
    end
    
    -- Parse JSON
    local json = Utils.require("libs.json")
    local success, saveData  = Utils.ErrorHandler.safeCall(json.decode, contents)
    
    if not success then
        Utils.Logger.error("Failed to parse save file: %s", saveData)
        return false, "Corrupted save file"
    end
    
    -- Check version compatibility
    if saveData.version ~= SaveSystem.saveVersion then
        Utils.Logger.warn("Save file version mismatch: %d vs %d", saveData.version, SaveSystem.saveVersion)
        -- Could implement migration here
    end
    
    -- Apply save data
    SaveSystem.applySaveData(saveData)
    
    Utils.Logger.info("Game loaded successfully from %s", os.date("%c", saveData.timestamp))
    return true
end

-- Apply loaded save data to game systems
function SaveSystem.applySaveData(saveData)
    -- Restore progression data
    local ProgressionSystem = Utils.require("src.systems.progression_system")
    if ProgressionSystem and saveData.player then
        ProgressionSystem.data.totalScore = saveData.player.totalScore or 0
        ProgressionSystem.data.totalRingsCollected = saveData.player.totalRingsCollected or 0
        ProgressionSystem.data.totalJumps = saveData.player.totalJumps or 0
        ProgressionSystem.data.totalDashes = saveData.player.totalDashes or 0
        ProgressionSystem.data.maxCombo = saveData.player.maxCombo or 0
        ProgressionSystem.data.totalPlayTime = saveData.player.gameTime or 0
    end
    
    -- Restore upgrades
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    if UpgradeSystem and saveData.upgrades then
        UpgradeSystem.currency = saveData.currency or 0
        
        for id, upgradeData in pairs(saveData.upgrades) do
            if UpgradeSystem.upgrades[id] then
                UpgradeSystem.upgrades[id].currentLevel = upgradeData.currentLevel or 0
                
                -- Trigger onPurchase callbacks for unlocked upgrades
                if id == "warp_drive" and upgradeData.currentLevel > 0 then
                    local WarpDrive = Utils.require("src.systems.warp_drive")
                    WarpDrive.unlock()
                end
            end
        end
    end
    
    -- Restore achievements
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem and saveData.achievements then
        for id, achievementData in pairs(saveData.achievements) do
            if AchievementSystem.achievements[id] and achievementData.unlocked then
                AchievementSystem.achievements[id].unlocked = true
                AchievementSystem.achievements[id].unlockedAt = achievementData.unlockedAt
            end
        end
        
        -- Restore stats
        if saveData.achievementStats then
            AchievementSystem.stats = saveData.achievementStats
        end
    end
    
    -- Restore discovered planets
    local MapSystem = Utils.require("src.systems.map_system")
    if MapSystem and saveData.discoveredPlanets then
        MapSystem.discoveredPlanets = saveData.discoveredPlanets
    end
    
    -- Restore collected artifacts
    local ArtifactSystem = Utils.require("src.systems.artifact_system")
    if ArtifactSystem and saveData.collectedArtifacts then
        for artifactId, _ in pairs(saveData.collectedArtifacts) do
            for _, artifact in ipairs(ArtifactSystem.artifacts) do
                if artifact.id == artifactId then
                    artifact.discovered = true
                end
            end
        end
        ArtifactSystem.collectedCount = saveData.artifactCount or 0
    end
    
    -- Restore warp drive
    if saveData.warpDrive then
        local WarpDrive = Utils.require("src.systems.warp_drive")
        if WarpDrive then
            WarpDrive.isUnlocked = saveData.warpDrive.unlocked or false
            WarpDrive.energy = saveData.warpDrive.energy or WarpDrive.maxEnergy
        end
    end
end

-- Auto-save update
function SaveSystem.update(dt)
    local currentTime = love.timer.getTime()
    
    -- Check if it's time to auto-save
    if currentTime - SaveSystem.lastAutoSave >= SaveSystem.autoSaveInterval then
        SaveSystem.save()
    end
    
    -- Update save indicator
    if SaveSystem.showSaveIndicator then
        SaveSystem.saveIndicatorTimer = SaveSystem.saveIndicatorTimer - dt
        if SaveSystem.saveIndicatorTimer <= 0 then
            SaveSystem.showSaveIndicator = false
        end
    end
end

-- Draw save indicator
function SaveSystem.drawUI()
    if SaveSystem.showSaveIndicator then
        local alpha = math.min(SaveSystem.saveIndicatorTimer, 1.0)
        
        -- Draw save icon/text
        Utils.setColor({1, 1, 1}, alpha)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.printf("💾 Game Saved", love.graphics.getWidth() - 150, 20, 140, "right")
    end
end

-- Delete save file
function SaveSystem.deleteSave()
    local success = love.filesystem.remove(SaveSystem.saveFileName)
    if success then
        Utils.Logger.info("Save file deleted")
    else
        Utils.Logger.error("Failed to delete save file")
    end
    return success
end

-- Check if save exists
function SaveSystem.hasSave()
    return love.filesystem.getInfo(SaveSystem.saveFileName) ~= nil
end

-- Get save info
function SaveSystem.getSaveInfo()
    if not SaveSystem.hasSave() then
        return nil
    end
    
    local contents = love.filesystem.read(SaveSystem.saveFileName)
    if not contents then
        return nil
    end
    
    local json = Utils.require("libs.json")
    local success, saveData  = Utils.ErrorHandler.safeCall(json.decode, contents)
    
    if not success then
        return nil
    end
    
    return {
        timestamp = saveData.timestamp,
        version = saveData.version,
        score = saveData.player and saveData.player.totalScore or 0,
        playtime = saveData.player and saveData.player.gameTime or 0
    }
end

return SaveSystem