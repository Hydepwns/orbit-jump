-- Save System for Orbit Jump - Registry Pattern Implementation
-- Handles saving and loading game progress without tight coupling
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
-- Registry of saveable systems - this is the key architectural change
SaveSystem.saveables = {}
SaveSystem.dependencies = {}
-- Get save directory based on OS
function SaveSystem.getSaveDirectory()
    local saveDir = love.filesystem.getSaveDirectory()
    return saveDir
end
-- Initialize save system with dependency injection support
function SaveSystem.init(dependencies)
    SaveSystem.dependencies = dependencies or {}
    SaveSystem.lastAutoSave = love.timer.getTime()
    -- Ensure save directory exists
    love.filesystem.setIdentity("orbit_jump")
    Utils.Logger.info("Save system initialized. Save directory: %s", SaveSystem.getSaveDirectory())
    Utils.Logger.info("Registered %d saveable systems", Utils.tableLength(SaveSystem.saveables))
    return true
end
-- Register a system for saving/loading
function SaveSystem.registerSaveable(name, system)
    if not system.serialize then
        Utils.Logger.error("System %s does not implement serialize() method", name)
        return false
    end
    if not system.deserialize then
        Utils.Logger.error("System %s does not implement deserialize() method", name)
        return false
    end
    SaveSystem.saveables[name] = system
    Utils.Logger.info("Registered saveable system: %s", name)
    return true
end
-- Unregister a system (useful for testing)
function SaveSystem.unregisterSaveable(name)
    SaveSystem.saveables[name] = nil
end
-- Collect all game data using registry pattern - no hard dependencies!
function SaveSystem.collectSaveData()
    local saveData = {
        version = SaveSystem.saveVersion,
        timestamp = os.time(),
        systems = {} -- All system data goes here
    }
    -- Collect data from all registered systems
    for name, system in pairs(SaveSystem.saveables) do
        local success, systemData = Utils.ErrorHandler.safeCall(function()
            return system:serialize()
        end)
        if success and systemData then
            saveData.systems[name] = systemData
            Utils.Logger.debug("Collected save data for system: %s", name)
        else
            Utils.Logger.error("Failed to collect save data for system %s: %s", name, systemData or "unknown error")
        end
    end
    return saveData
end
-- This function is no longer needed - learning data is collected via registry pattern
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
-- Apply loaded save data using registry pattern - no hard dependencies!
function SaveSystem.applySaveData(saveData)
    -- Handle legacy save format for backward compatibility
    if not saveData.systems and saveData.player then
        Utils.Logger.info("Loading legacy save format")
        SaveSystem.applyLegacySaveData(saveData)
        return
    end
    -- Apply data to all registered systems
    if saveData.systems then
        for name, systemData in pairs(saveData.systems) do
            local system = SaveSystem.saveables[name]
            if system then
                local success, errorMsg = Utils.ErrorHandler.safeCall(function()
                    system:deserialize(systemData)
                end)
                if success then
                    Utils.Logger.debug("Restored save data for system: %s", name)
                else
                    Utils.Logger.error("Failed to restore save data for system %s: %s", name, errorMsg or "unknown error")
                end
            else
                Utils.Logger.warn("No system registered for save data: %s", name)
            end
        end
    end
end
-- Legacy save data support for backward compatibility
function SaveSystem.applyLegacySaveData(saveData)
    Utils.Logger.info("Applying legacy save format - consider using 'Upgrade Save' in settings")
    -- Try to apply legacy data to registered systems if they support it
    for name, system in pairs(SaveSystem.saveables) do
        if system.deserializeLegacy then
            local success, errorMsg = Utils.ErrorHandler.safeCall(function()
                system:deserializeLegacy(saveData)
            end)
            if not success then
                Utils.Logger.error("Failed to apply legacy data to system %s: %s", name, errorMsg or "unknown error")
            end
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
-- Get save info - works with both new and legacy formats
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
    -- Handle both new and legacy save formats
    local score = 0
    local playtime = 0
    if saveData.systems and saveData.systems.progression then
        local prog = saveData.systems.progression
        score = prog.totalScore or 0
        playtime = prog.totalPlayTime or 0
    elseif saveData.player then
        score = saveData.player.totalScore or 0
        playtime = saveData.player.gameTime or 0
    end
    return {
        timestamp = saveData.timestamp,
        version = saveData.version,
        score = score,
        playtime = playtime,
        format = saveData.systems and "registry" or "legacy"
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