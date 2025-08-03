-- Resolution Manager for Orbit Jump
-- Handles dynamic resolution changes, UI scaling, and aspect ratio management
local Utils = require("src.utils.utils")
local Config = require("src.utils.config")
local ResolutionManager = {}
-- Current state
ResolutionManager.current = {
    width = 800,
    height = 600,
    fullscreen = false,
    vsync = true,
    msaa = 0,
    scale = 1.0,
    offsetX = 0,
    offsetY = 0
}
-- Target resolution (what we want to render at)
ResolutionManager.target = {
    width = 800,
    height = 600
}
-- Callbacks for when resolution changes
ResolutionManager.callbacks = {}
-- Initialize resolution manager
function ResolutionManager.init()
    -- Load saved resolution settings
    local saveSystem = Utils.require("src.systems.save_system")
    if saveSystem and saveSystem.loadResolution then
        local saved = saveSystem.loadResolution()
        if saved then
            ResolutionManager.current = saved
        end
    end
    -- Auto-detect best resolution if enabled
    if Config.resolution.autoDetect then
        ResolutionManager.autoDetectBestResolution()
    end
    -- Apply current resolution
    ResolutionManager.applyResolution()
    Utils.Logger.info("Resolution manager initialized: %dx%d",
        ResolutionManager.current.width, ResolutionManager.current.height)
end
-- Auto-detect best resolution
function ResolutionManager.autoDetectBestResolution()
    if not love.window then return end
    local desktopWidth, desktopHeight = love.window.getDesktopDimensions()
    if not desktopWidth or not desktopHeight then return end
    -- Find the best matching resolution
    local bestResolution = nil
    local bestScore = 0
    for _, resolution in ipairs(Config.resolution.available) do
        local score = 0
        -- Prefer resolutions close to desktop size
        local widthDiff = math.abs(resolution.width - desktopWidth)
        local heightDiff = math.abs(resolution.height - desktopHeight)
        score = score + (1000 / (widthDiff + heightDiff + 1))
        -- Prefer common resolutions
        if resolution.width == 1920 and resolution.height == 1080 then
            score = score + 500
        elseif resolution.width == 1280 and resolution.height == 720 then
            score = score + 300
        elseif resolution.width == 1366 and resolution.height == 768 then
            score = score + 200
        end
        -- Prefer 16:9 aspect ratio
        local aspect = resolution.width / resolution.height
        if math.abs(aspect - 16/9) < 0.1 then
            score = score + 100
        end
        if score > bestScore then
            bestScore = score
            bestResolution = resolution
        end
    end
    if bestResolution then
        ResolutionManager.current.width = bestResolution.width
        ResolutionManager.current.height = bestResolution.height
        Utils.Logger.info("Auto-detected resolution: %dx%d",
            bestResolution.width, bestResolution.height)
    end
end
-- Apply current resolution settings
function ResolutionManager.applyResolution()
    if not love.window then return end
    local success = love.window.setMode(
        ResolutionManager.current.width,
        ResolutionManager.current.height,
        {
            fullscreen = ResolutionManager.current.fullscreen,
            vsync = ResolutionManager.current.vsync,
            msaa = ResolutionManager.current.msaa,
            resizable = true,
            borderless = false,
            centered = true
        }
    )
    if success then
        -- Update target resolution
        ResolutionManager.target.width = ResolutionManager.current.width
        ResolutionManager.target.height = ResolutionManager.current.height
        -- Calculate scaling and offsets
        ResolutionManager.calculateScaling()
        -- Notify systems of resolution change
        ResolutionManager.notifyResolutionChange()
        Utils.Logger.info("Resolution applied: %dx%d (scale: %.2f)",
            ResolutionManager.current.width, ResolutionManager.current.height,
            ResolutionManager.current.scale)
    else
        Utils.Logger.error("Failed to apply resolution: %dx%d",
            ResolutionManager.current.width, ResolutionManager.current.height)
    end
end
-- Calculate scaling and offsets for different scaling modes
function ResolutionManager.calculateScaling()
    local currentWidth, currentHeight = love.graphics.getDimensions()
    local targetWidth, targetHeight = ResolutionManager.target.width, ResolutionManager.target.height
    if Config.resolution.scaling.mode == "fit" then
        -- Fit mode: scale to fit while maintaining aspect ratio
        local scaleX = currentWidth / targetWidth
        local scaleY = currentHeight / targetHeight
        ResolutionManager.current.scale = math.min(scaleX, scaleY)
        -- Center the game
        ResolutionManager.current.offsetX = (currentWidth - targetWidth * ResolutionManager.current.scale) / 2
        ResolutionManager.current.offsetY = (currentHeight - targetHeight * ResolutionManager.current.scale) / 2
    elseif Config.resolution.scaling.mode == "stretch" then
        -- Stretch mode: fill entire screen
        ResolutionManager.current.scale = 1.0
        ResolutionManager.current.offsetX = 0
        ResolutionManager.current.offsetY = 0
    elseif Config.resolution.scaling.mode == "crop" then
        -- Crop mode: scale to fill, crop excess
        local scaleX = currentWidth / targetWidth
        local scaleY = currentHeight / targetHeight
        ResolutionManager.current.scale = math.max(scaleX, scaleY)
        -- Center the game
        ResolutionManager.current.offsetX = (currentWidth - targetWidth * ResolutionManager.current.scale) / 2
        ResolutionManager.current.offsetY = (currentHeight - targetHeight * ResolutionManager.current.scale) / 2
    end
    -- Apply scale limits
    ResolutionManager.current.scale = math.max(
        Config.resolution.scaling.minScale,
        math.min(Config.resolution.scaling.maxScale, ResolutionManager.current.scale)
    )
end
-- Set resolution
function ResolutionManager.setResolution(width, height, fullscreen)
    if not love.window then return false end
    -- Validate resolution
    local valid = false
    for _, resolution in ipairs(Config.resolution.available) do
        if resolution.width == width and resolution.height == height then
            valid = true
            break
        end
    end
    if not valid then
        Utils.Logger.warn("Invalid resolution: %dx%d", width, height)
        return false
    end
    -- Update current settings
    ResolutionManager.current.width = width
    ResolutionManager.current.height = height
    ResolutionManager.current.fullscreen = fullscreen or false
    -- Apply the new resolution
    ResolutionManager.applyResolution()
    -- Save settings
    ResolutionManager.saveSettings()
    return true
end
-- Toggle fullscreen
function ResolutionManager.toggleFullscreen()
    ResolutionManager.current.fullscreen = not ResolutionManager.current.fullscreen
    ResolutionManager.applyResolution()
    ResolutionManager.saveSettings()
end
-- Get current resolution info
function ResolutionManager.getCurrentResolution()
    return {
        width = ResolutionManager.current.width,
        height = ResolutionManager.current.height,
        fullscreen = ResolutionManager.current.fullscreen,
        scale = ResolutionManager.current.scale,
        offsetX = ResolutionManager.current.offsetX,
        offsetY = ResolutionManager.current.offsetY
    }
end
-- Get available resolutions
function ResolutionManager.getAvailableResolutions()
    return Config.resolution.available
end
-- Register callback for resolution changes
function ResolutionManager.onResolutionChange(callback)
    table.insert(ResolutionManager.callbacks, callback)
end
-- Notify systems of resolution change
function ResolutionManager.notifyResolutionChange()
    for _, callback in ipairs(ResolutionManager.callbacks) do
        if type(callback) == "function" then
            callback(ResolutionManager.current)
        end
    end
end
-- Save resolution settings
function ResolutionManager.saveSettings()
    local saveSystem = Utils.require("src.systems.save_system")
    if saveSystem and saveSystem.saveResolution then
        saveSystem.saveResolution(ResolutionManager.current)
    end
end
-- Handle window resize
function ResolutionManager.handleResize(width, height)
    if not Config.resolution.scaling.enabled then return end
    ResolutionManager.calculateScaling()
    ResolutionManager.notifyResolutionChange()
    Utils.Logger.info("Window resized to %dx%d (scale: %.2f)",
        width, height, ResolutionManager.current.scale)
end
-- Draw resolution info (for debug)
function ResolutionManager.drawDebug()
    if not Config.dev.debugMode then return end
    local info = string.format(
        "Resolution: %dx%d (%.1fx scale)\nOffset: %.0f, %.0f\nFullscreen: %s",
        ResolutionManager.current.width,
        ResolutionManager.current.height,
        ResolutionManager.current.scale,
        ResolutionManager.current.offsetX,
        ResolutionManager.current.offsetY,
        ResolutionManager.current.fullscreen and "Yes" or "No"
    )
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.print(info, 10, 10)
end
-- Cycle through resolutions
function ResolutionManager.cycleResolution()
    local currentIndex = 1
    for i, resolution in ipairs(Config.resolution.available) do
        if resolution.width == ResolutionManager.current.width and
           resolution.height == ResolutionManager.current.height then
            currentIndex = i
            break
        end
    end
    local nextIndex = (currentIndex % #Config.resolution.available) + 1
    local nextResolution = Config.resolution.available[nextIndex]
    ResolutionManager.setResolution(nextResolution.width, nextResolution.height)
end
return ResolutionManager