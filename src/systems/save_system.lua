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
    return true
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
    if GameState and GameState.data then
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
        
        if UpgradeSystem.upgrades then
            for id, upgrade in pairs(UpgradeSystem.upgrades) do
                saveData.upgrades[id] = {
                    currentLevel = upgrade.currentLevel or 0
                }
            end
        end
    end
    
    -- LEARNING SYSTEM INTEGRATION: Save adaptive memory data
    SaveSystem.collectLearningData(saveData)
    
    -- Get achievement data
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem then
        saveData.achievements = {}
        
        -- Save achievement unlock status
        if AchievementSystem.achievements then
            for id, achievement in pairs(AchievementSystem.achievements) do
                if achievement.unlocked then
                    saveData.achievements[id] = {
                        unlocked = true,
                        unlockedAt = achievement.unlockedAt
                    }
                end
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
        if ArtifactSystem.artifacts then
            for _, artifact in ipairs(ArtifactSystem.artifacts) do
                if artifact.discovered then
                    saveData.collectedArtifacts[artifact.id] = true
                end
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

-- Collect learning and adaptive system data
function SaveSystem.collectLearningData(saveData)
    --[[
        Learning Data Persistence: The Memory That Survives Death
        
        This function ensures that all the adaptive learning our systems have
        done survives across game sessions. The warp drive's route optimizations,
        the player analytics behavioral model, the adaptive physics preferences -
        all of it gets preserved so the game continues to feel personalized.
    --]]
    
    -- Warp Drive Memory
    local WarpDrive = Utils.require("src.systems.warp_drive")
    if WarpDrive and WarpDrive.memory then
        saveData.warpDriveMemory = WarpDrive.memory
        
        local stats = WarpDrive.getMemoryStats()
        Utils.Logger.info("💾 Saving warp memory: %d routes, %.1f%% efficiency", 
            stats.knownRoutes, stats.efficiency * 100)
    end
    
    -- Player Analytics Memory
    local PlayerAnalytics = Utils.require("src.systems.player_analytics")
    if PlayerAnalytics and PlayerAnalytics.memory then
        saveData.playerAnalytics = PlayerAnalytics.memory
        
        local profile = PlayerAnalytics.getPlayerProfile()
        Utils.Logger.info("📊 Saving analytics: skill=%.1f%%, style=%s, mood=%s",
            (profile.skillLevel or 0) * 100, 
            profile.movementStyle or "unknown",
            profile.currentMood or "neutral")
    end
    
    -- Adaptive Physics State
    local PlayerSystem = Utils.require("src.systems.player_system")
    if PlayerSystem and PlayerSystem.getAdaptivePhysicsStatus then
        local physicsStatus = PlayerSystem.getAdaptivePhysicsStatus()
        saveData.adaptivePhysics = {
            spaceDrag = physicsStatus.spaceDrag,
            cameraResponse = physicsStatus.cameraResponse,
            lastAdaptation = physicsStatus.lastAdaptation
        }
        
        Utils.Logger.info("⚙️ Saving adaptive physics: drag=%.3f, camera=%.1f",
            physicsStatus.spaceDrag, physicsStatus.cameraResponse)
    end
    
    -- Emotional Feedback Learning
    local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
    if EmotionalFeedback and EmotionalFeedback.getLearningData then
        saveData.emotionalLearning = EmotionalFeedback.getLearningData()
    end
    
    Utils.Logger.info("🧠 Learning data collected for persistence")
end

-- Save game data
function SaveSystem.save()
    local success = false
    local message = ""
    
    -- Collect save data
    local saveData = SaveSystem.collectSaveData()
    
    -- Serialize to JSON with error handling
    local json = Utils.require("libs.json")
    local success, saveString = pcall(json.encode, saveData)
    if not success then
        Utils.Logger.error("Failed to encode save data: %s", saveString)
        return false, "Failed to encode save data"
    end
    
    -- Create backup of current save before overwriting
    if love.filesystem.getInfo(SaveSystem.saveFileName) then
        local backupName = SaveSystem.saveFileName .. ".backup"
        local backupContents = love.filesystem.read(SaveSystem.saveFileName)
        if backupContents then
            love.filesystem.write(backupName, backupContents)
        end
    end
    
    -- Write to file
    success, message = love.filesystem.write(SaveSystem.saveFileName, saveString)
    
    if success then
        Utils.Logger.info("Game saved successfully")
        SaveSystem.lastAutoSave = love.timer.getTime()
        SaveSystem.showSaveIndicator = true
        SaveSystem.saveIndicatorTimer = 2.0 -- Show for 2 seconds
    else
        Utils.Logger.error("Failed to save game: %s", message)
        SaveSystem.showSaveIndicator = false
        -- Try to restore backup
        local backupName = SaveSystem.saveFileName .. ".backup"
        if love.filesystem.getInfo(backupName) then
            local backupContents = love.filesystem.read(backupName)
            if backupContents then
                love.filesystem.write(SaveSystem.saveFileName, backupContents)
                Utils.Logger.info("Restored save from backup")
            end
        end
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
    
    -- Parse JSON with error handling
    local json = Utils.require("libs.json")
    local success, saveData = pcall(json.decode, contents)
    
    if not success then
        Utils.Logger.error("Failed to parse save file: %s", saveData)
        -- Try to create backup of corrupted save
        local backupName = SaveSystem.saveFileName .. ".corrupted." .. os.time()
        love.filesystem.write(backupName, contents)
        Utils.Logger.info("Backed up corrupted save to: %s", backupName)
        return false, "Corrupted save file (backed up)"
    end
    
    -- Validate save data structure
    if type(saveData) ~= "table" then
        Utils.Logger.error("Invalid save data structure")
        return false, "Invalid save data"
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
    
    -- LEARNING SYSTEM RESTORATION: Bring back the memories
    SaveSystem.restoreLearningData(saveData)
end

-- Restore learning and adaptive system data
function SaveSystem.restoreLearningData(saveData)
    --[[
        Memory Resurrection: Bringing Back the System's Soul
        
        This is where the magic of persistent learning comes alive. All the
        behavioral patterns, route optimizations, and adaptive preferences
        that the systems learned during previous sessions are restored,
        making the game feel like it truly remembers the player.
    --]]
    
    -- Restore Warp Drive Memory
    if saveData.warpDriveMemory then
        local WarpDrive = Utils.require("src.systems.warp_drive")
        if WarpDrive then
            WarpDrive.memory = saveData.warpDriveMemory
            
            local stats = WarpDrive.getMemoryStats()
            Utils.Logger.info("🧠 Restored warp memory: %d routes, %.1f%% efficiency", 
                stats.knownRoutes, stats.efficiency * 100)
        end
    end
    
    -- Restore Player Analytics Memory
    if saveData.playerAnalytics then
        local PlayerAnalytics = Utils.require("src.systems.player_analytics")
        if PlayerAnalytics then
            PlayerAnalytics.memory = saveData.playerAnalytics
            
            local profile = PlayerAnalytics.getPlayerProfile()
            Utils.Logger.info("📊 Restored analytics: skill=%.1f%%, style=%s",
                (profile.skillLevel or 0) * 100,
                profile.movementStyle or "unknown")
        end
    end
    
    -- Restore Adaptive Physics State
    if saveData.adaptivePhysics then
        local PlayerSystem = Utils.require("src.systems.player_system")
        if PlayerSystem then
            -- Restore the adaptive parameters
            -- Note: The actual AdaptivePhysics table is local to PlayerSystem,
            -- so we'll need to add a restoration function there
            PlayerSystem.restoreAdaptivePhysics(saveData.adaptivePhysics)
            
            Utils.Logger.info("⚙️ Restored adaptive physics: drag=%.3f, camera=%.1f",
                saveData.adaptivePhysics.spaceDrag or 0.99,
                saveData.adaptivePhysics.cameraResponse or 2.0)
        end
    end
    
    -- Restore Emotional Feedback Learning
    if saveData.emotionalLearning then
        local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
        if EmotionalFeedback and EmotionalFeedback.restoreLearningData then
            EmotionalFeedback.restoreLearningData(saveData.emotionalLearning)
        end
    end
    
    Utils.Logger.info("🧠 Learning data restored - Systems remember you")
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

--[[
    Self-Healing Helper Functions
    
    These functions implement the various recovery strategies that make
    the save system resilient to corruption, disk errors, and other failures.
--]]

-- Validate save data integrity
function SaveSystem.validateSaveData(data)
    if not data then return false end
    if type(data) ~= "table" then return false end
    if not data.version then return false end
    if not data.player then return false end
    
    -- Calculate data completeness
    local requiredFields = {"version", "timestamp", "player", "currency"}
    local validFields = 0
    
    for _, field in ipairs(requiredFields) do
        if data[field] ~= nil then
            validFields = validFields + 1
        end
    end
    
    local completeness = validFields / #requiredFields
    
    -- Accept saves with 80% completeness (configurable)
    if completeness >= 0.8 then
        Utils.Logger.info("Save data %.0f%% complete - accepting", completeness * 100)
        return true
    else
        Utils.Logger.warn("Save data only %.0f%% complete - rejecting", completeness * 100)
        return false
    end
end

-- Repair incomplete save data
function SaveSystem.repairSaveData(data)
    --[[
        Data Healing: Fill in missing pieces with sensible defaults
        
        This ensures that even partially corrupted saves result in a
        playable game state.
    --]]
    
    -- Ensure all expected fields exist
    data.version = data.version or SaveSystem.saveVersion
    data.timestamp = data.timestamp or os.time()
    
    -- Repair player data
    data.player = data.player or {}
    data.player.totalScore = data.player.totalScore or 0
    data.player.totalRingsCollected = data.player.totalRingsCollected or 0
    data.player.totalJumps = data.player.totalJumps or 0
    data.player.totalDashes = data.player.totalDashes or 0
    data.player.maxCombo = data.player.maxCombo or 0
    data.player.gameTime = data.player.gameTime or 0
    
    -- Repair other systems
    data.currency = data.currency or 0
    data.upgrades = data.upgrades or {}
    data.achievements = data.achievements or {}
    data.discoveredPlanets = data.discoveredPlanets or {}
    
    Utils.Logger.info("Save data repaired and normalized")
    return data
end

-- Enhanced save with multiple strategies
function SaveSystem.saveWithRecovery()
    local saveData = SaveSystem.collectSaveData()
    local json = Utils.require("libs.json")
    
    -- Strategy 1: Try normal save
    local success, saveString = pcall(json.encode, saveData)
    if success then
        -- Create rolling backup before save
        SaveSystem.createRollingBackup()
        
        -- Atomic save with temp file
        local tempFile = SaveSystem.saveFileName .. ".tmp"
        local writeSuccess = love.filesystem.write(tempFile, saveString)
        
        if writeSuccess then
            -- Verify temp file
            local verifyData = love.filesystem.read(tempFile)
            if verifyData == saveString then
                -- Atomic rename
                love.filesystem.remove(SaveSystem.saveFileName)
                love.filesystem.write(SaveSystem.saveFileName, verifyData)
                love.filesystem.remove(tempFile)
                
                SaveSystem.lastAutoSave = love.timer.getTime()
                SaveSystem.showSaveIndicator = true
                SaveSystem.saveIndicatorTimer = 2.0
                
                return true, "Save successful"
            end
        end
    end
    
    -- Strategy 2: Try compressed save
    if not success then
        Utils.Logger.warn("Primary save failed, trying compressed save")
        local compressedData = love.data.compress("string", "zlib", saveString or json.encode(saveData))
        if compressedData then
            local compressedFile = SaveSystem.saveFileName .. ".gz"
            writeSuccess = love.filesystem.write(compressedFile, compressedData)
            if writeSuccess then
                return true, "Compressed save successful"
            end
        end
    end
    
    -- Strategy 3: Emergency minimal save
    Utils.Logger.error("All save strategies failed, attempting minimal save")
    local minimalData = {
        version = saveData.version,
        timestamp = os.time(),
        player = {
            totalScore = saveData.player.totalScore or 0,
            currency = saveData.currency or 0
        }
    }
    
    local minimalString = json.encode(minimalData)
    love.filesystem.write(SaveSystem.saveFileName .. ".minimal", minimalString)
    
    return false, "Emergency save only"
end

-- Create rolling backup
function SaveSystem.createRollingBackup()
    -- Keep up to 3 rolling backups
    for i = 3, 2, -1 do
        local oldName = SaveSystem.saveFileName .. ".backup" .. (i-1)
        local newName = SaveSystem.saveFileName .. ".backup" .. i
        
        if love.filesystem.getInfo(oldName) then
            local data = love.filesystem.read(oldName)
            if data then
                love.filesystem.write(newName, data)
            end
        end
    end
    
    -- Create new backup1 from current save
    if love.filesystem.getInfo(SaveSystem.saveFileName) then
        local currentData = love.filesystem.read(SaveSystem.saveFileName)
        if currentData then
            love.filesystem.write(SaveSystem.saveFileName .. ".backup1", currentData)
        end
    end
end

-- Load with multiple recovery strategies
function SaveSystem.loadWithRecovery()
    local json = Utils.require("libs.json")
    
    -- Try primary save
    local contents = love.filesystem.read(SaveSystem.saveFileName)
    if contents then
        local success, saveData = pcall(json.decode, contents)
        if success and SaveSystem.validateSaveData(saveData) then
            return true, SaveSystem.repairSaveData(saveData)
        end
    end
    
    -- Try compressed save
    local compressedFile = SaveSystem.saveFileName .. ".gz"
    if love.filesystem.getInfo(compressedFile) then
        local compressedData = love.filesystem.read(compressedFile)
        if compressedData then
            local decompressed = love.data.decompress("string", "zlib", compressedData)
            if decompressed then
                local success, saveData = pcall(json.decode, decompressed)
                if success and SaveSystem.validateSaveData(saveData) then
                    Utils.Logger.info("Loaded from compressed save")
                    return true, SaveSystem.repairSaveData(saveData)
                end
            end
        end
    end
    
    -- Try backups
    for i = 1, 3 do
        local backupFile = SaveSystem.saveFileName .. ".backup" .. i
        if love.filesystem.getInfo(backupFile) then
            local backupContents = love.filesystem.read(backupFile)
            if backupContents then
                local success, saveData = pcall(json.decode, backupContents)
                if success and SaveSystem.validateSaveData(saveData) then
                    Utils.Logger.info("Loaded from backup #%d", i)
                    return true, SaveSystem.repairSaveData(saveData)
                end
            end
        end
    end
    
    -- Try minimal save
    local minimalFile = SaveSystem.saveFileName .. ".minimal"
    if love.filesystem.getInfo(minimalFile) then
        local minimalContents = love.filesystem.read(minimalFile)
        if minimalContents then
            local success, saveData = pcall(json.decode, minimalContents)
            if success then
                Utils.Logger.warn("Loaded minimal save - some progress lost")
                return true, SaveSystem.repairSaveData(saveData)
            end
        end
    end
    
    return false, nil
end

return SaveSystem