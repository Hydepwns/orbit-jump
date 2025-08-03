--[[
    Hot Reload System for Orbit Jump
    Enables live code reloading during development without restarting the game.
    Monitors file changes and reloads affected modules automatically.
--]]
local Utils = require("src.utils.utils")
local HotReload = {}
-- Configuration
HotReload.config = {
    enabled = false,
    checkInterval = 0.5, -- Check for changes every 500ms
    watchPaths = {
        "src/systems/",
        "src/ui/",
        "src/utils/",
        -- Don't watch core/ to avoid breaking the game loop
    },
    -- Modules that should never be reloaded
    blacklist = {
        "src.utils.utils",
        "src.utils.hot_reload",
        "src.core.game",
        "src.core.game_state",
    }
}
-- Runtime state
HotReload.state = {
    lastCheck = 0,
    fileTimestamps = {},
    reloadCount = 0,
    reloadHistory = {},
    watchers = {} -- Module-specific reload handlers
}
-- Initialize hot reload system
function HotReload.init()
    if not love.filesystem.getInfo then
        Utils.Logger.warn("Hot reload not available - LÖVE2D version too old")
        return false
    end
    Utils.Logger.info("Hot reload system initialized")
    -- Scan initial timestamps
    HotReload.scanFiles()
    return true
end
-- Enable/disable hot reload
function HotReload.setEnabled(enabled)
    HotReload.config.enabled = enabled
    if enabled then
        Utils.Logger.info("Hot reload enabled - Press F5 to manually reload")
        HotReload.scanFiles() -- Rescan on enable
    else
        Utils.Logger.info("Hot reload disabled")
    end
end
-- Register a reload handler for a specific module
function HotReload.registerHandler(moduleName, handler)
    HotReload.state.watchers[moduleName] = handler
    Utils.Logger.debug("Registered reload handler for: %s", moduleName)
end
-- Update hot reload system
function HotReload.update(dt)
    if not HotReload.config.enabled then
        return
    end
    local now = love.timer.getTime()
    if now - HotReload.state.lastCheck < HotReload.config.checkInterval then
        return
    end
    HotReload.state.lastCheck = now
    -- Check for changed files
    local changedModules = HotReload.checkForChanges()
    -- Reload changed modules
    for _, moduleName in ipairs(changedModules) do
        HotReload.reloadModule(moduleName)
    end
end
-- Scan all watched files and store timestamps
function HotReload.scanFiles()
    HotReload.state.fileTimestamps = {}
    for _, watchPath in ipairs(HotReload.config.watchPaths) do
        HotReload.scanDirectory(watchPath)
    end
end
-- Recursively scan a directory
function HotReload.scanDirectory(path)
    local items = love.filesystem.getDirectoryItems(path)
    for _, item in ipairs(items) do
        local fullPath = path .. item
        local info = love.filesystem.getInfo(fullPath)
        if info then
            if info.type == "file" and item:match("%.lua$") then
                -- Store file timestamp
                HotReload.state.fileTimestamps[fullPath] = info.modtime or 0
            elseif info.type == "directory" then
                -- Recurse into subdirectory
                HotReload.scanDirectory(fullPath .. "/")
            end
        end
    end
end
-- Check for changed files
function HotReload.checkForChanges()
    local changedModules = {}
    for filePath, oldTime in pairs(HotReload.state.fileTimestamps) do
        local info = love.filesystem.getInfo(filePath)
        if info and info.modtime then
            if info.modtime > oldTime then
                -- File has changed
                HotReload.state.fileTimestamps[filePath] = info.modtime
                -- Convert file path to module name
                local moduleName = HotReload.filePathToModuleName(filePath)
                -- Check if module is blacklisted
                if not HotReload.isBlacklisted(moduleName) then
                    table.insert(changedModules, moduleName)
                    Utils.Logger.info("Detected change in: %s", filePath)
                end
            end
        end
    end
    return changedModules
end
-- Convert file path to module name
function HotReload.filePathToModuleName(filePath)
    -- Remove .lua extension and convert slashes to dots
    local moduleName = filePath:gsub("%.lua$", ""):gsub("/", ".")
    return moduleName
end
-- Check if module is blacklisted
function HotReload.isBlacklisted(moduleName)
    for _, blacklisted in ipairs(HotReload.config.blacklist) do
        if moduleName == blacklisted then
            return true
        end
    end
    return false
end
-- Reload a specific module
function HotReload.reloadModule(moduleName)
    Utils.Logger.info("Reloading module: %s", moduleName)
    -- Store old module reference
    local oldModule = package.loaded[moduleName]
    -- Clear from package cache
    package.loaded[moduleName] = nil
    -- Clear from Utils module cache if it exists
    if Utils.clearModuleFromCache then
        Utils.clearModuleFromCache(moduleName)
    end
    -- Try to reload the module
    local success, newModule = pcall(require, moduleName)
    if success then
        -- Reload successful
        HotReload.state.reloadCount = HotReload.state.reloadCount + 1
        -- Add to history
        table.insert(HotReload.state.reloadHistory, {
            moduleName = moduleName,
            timestamp = love.timer.getTime(),
            success = true
        })
        -- Call module-specific handler if registered
        local handler = HotReload.state.watchers[moduleName]
        if handler then
            local handlerSuccess = Utils.ErrorHandler.safeCall(function()
                handler(oldModule, newModule)
            end, {
                onError = function(err)
                    Utils.Logger.error("Hot reload handler failed for %s: %s", moduleName, err)
                end
            })
        end
        -- Special handling for certain module types
        HotReload.handleSpecialReload(moduleName, oldModule, newModule)
        Utils.Logger.info("Successfully reloaded: %s", moduleName)
        -- Show notification if UI is available
        if _G.NotificationSystem then
            _G.NotificationSystem.show("Module reloaded: " .. moduleName, 2)
        end
    else
        -- Reload failed - restore old module
        package.loaded[moduleName] = oldModule
        Utils.Logger.error("Failed to reload %s: %s", moduleName, newModule)
        -- Add to history
        table.insert(HotReload.state.reloadHistory, {
            moduleName = moduleName,
            timestamp = love.timer.getTime(),
            success = false,
            error = tostring(newModule)
        })
        -- Show error notification
        if _G.NotificationSystem then
            _G.NotificationSystem.show("Reload failed: " .. moduleName, 3, "error")
        end
    end
    -- Limit history size
    while #HotReload.state.reloadHistory > 50 do
        table.remove(HotReload.state.reloadHistory, 1)
    end
end
-- Handle special reload cases
function HotReload.handleSpecialReload(moduleName, oldModule, newModule)
    -- Systems with init functions
    if newModule and type(newModule.init) == "function" then
        Utils.Logger.debug("Re-initializing module: %s", moduleName)
        Utils.ErrorHandler.safeCall(newModule.init, {
            onError = function(err)
                Utils.Logger.error("Failed to reinitialize %s: %s", moduleName, err)
            end
        })
    end
    -- UI components might need to refresh
    if moduleName:match("^src%.ui%.") then
        if _G.UISystem and _G.UISystem.refresh then
            _G.UISystem.refresh()
        end
    end
    -- Shader modules need special handling
    if moduleName:match("shader") and newModule and newModule.reload then
        newModule.reload()
    end
end
-- Manual reload (F5)
function HotReload.keypressed(key)
    if key == "f5" and HotReload.config.enabled then
        Utils.Logger.info("Manual hot reload triggered")
        -- Force rescan and check
        HotReload.scanFiles()
        local changedModules = HotReload.checkForChanges()
        if #changedModules == 0 then
            Utils.Logger.info("No changes detected")
            if _G.NotificationSystem then
                _G.NotificationSystem.show("No changes detected", 1)
            end
        else
            -- Reload all changed modules
            for _, moduleName in ipairs(changedModules) do
                HotReload.reloadModule(moduleName)
            end
        end
    end
end
-- Get reload statistics
function HotReload.getStats()
    -- Get recent reloads
    local recent = {}
    local now = love.timer.getTime()
    for i = #HotReload.state.reloadHistory, 1, -1 do
        local entry = HotReload.state.reloadHistory[i]
        if now - entry.timestamp < 60 then -- Last minute
            table.insert(recent, entry)
        end
        if #recent >= 5 then break end
    end
    return {
        enabled = HotReload.config.enabled,
        reloadCount = HotReload.state.reloadCount,
        recentReloads = recent
    }
end
-- Export hot reload API
return HotReload