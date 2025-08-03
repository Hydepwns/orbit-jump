--[[
    ═══════════════════════════════════════════════════════════════════════════
    Streak System - Main Coordinator
    ═══════════════════════════════════════════════════════════════════════════
    This is the main coordinator for the streak system, orchestrating the
    streak logic, visual effects, and UI components. It provides a clean
    interface for other systems to interact with the streak functionality.
    Refactored from the original monolithic streak_system.lua to use a modular
    architecture with separate logic, effects, and UI components.
--]]
local Utils = require("src.utils.utils")
-- Import the new modular components
local StreakLogic = require("src.systems.streak.streak_logic")
local StreakEffects = require("src.systems.streak.streak_effects")
local StreakSystem = {}
-- System state
StreakSystem.isActive = false
StreakSystem.lastUpdateTime = 0
-- Font cache for performance
StreakSystem.fontCache = {}
-- Initialize streak system
function StreakSystem.init()
    StreakSystem.isActive = true
    StreakSystem.lastUpdateTime = love.timer.getTime()
    -- Initialize sub-systems
    StreakLogic.init()
    StreakEffects.init()
    -- Initialize font cache
    StreakSystem.initializeFontCache()
    Utils.Logger.info("🔥 Streak System initialized with modular architecture")
    return true
end
-- Initialize font cache for performance
function StreakSystem.initializeFontCache()
    local fontSizes = {16, 20, 24, 32, 48, 64}
    for _, size in ipairs(fontSizes) do
        local success, font = pcall(love.graphics.newFont, size)
        if success then
            StreakSystem.fontCache[size] = font
        else
            Utils.Logger.warning("Failed to create font size %d", size)
        end
    end
    Utils.Logger.info("📝 Font cache initialized with %d fonts", #fontSizes)
end
-- Get cached font for performance with error handling
function StreakSystem.getFont(size)
    if not size or size <= 0 then
        return love.graphics.getFont()
    end
    local font = StreakSystem.fontCache[size]
    if font then
        return font
    end
    -- Fallback: create font on demand
    local success, newFont = pcall(love.graphics.newFont, size)
    if success then
        StreakSystem.fontCache[size] = newFont
        return newFont
    else
        Utils.Logger.warning("Failed to create font size %d, using default", size)
        return love.graphics.getFont()
    end
end
-- Update streak system (called every frame)
function StreakSystem.update(dt)
    if not StreakSystem.isActive then return end
    -- Update streak logic
    StreakLogic.update(dt)
    -- Update visual effects
    StreakEffects.update(dt)
    StreakSystem.lastUpdateTime = love.timer.getTime()
end
-- Handle player landing on planet
function StreakSystem.onPlayerLanding(player, planet, gameState)
    if not StreakSystem.isActive then return false end
    local isPerfect = StreakLogic.onPlayerLanding(player, planet, gameState)
    -- Create visual effects based on landing result
    if isPerfect then
        local currentStreak = StreakLogic.getCurrentStreak()
        StreakEffects.createPerfectLandingEffect(player.x, player.y, currentStreak)
        -- Check if this is a new record
        if currentStreak > StreakLogic.getMaxStreak() then
            StreakEffects.createNewRecordEffect(player.x, player.y, currentStreak)
        end
        -- Check for bonus activation
        local activeBonuses = StreakLogic.getActiveBonuses()
        for bonusName, bonusData in pairs(activeBonuses) do
            if bonusData.timeRemaining == bonusData.duration then -- Just activated
                StreakEffects.createBonusActivationEffect(player.x, player.y, bonusName)
            end
        end
        -- Handle shield activation
        if StreakLogic.isBonusActive("streak_shield") then
            StreakEffects.activateShield()
        end
    else
        -- Handle imperfect landing
        if StreakLogic.isInGracePeriod() then
            -- Player is in grace period - create saved effect
            StreakEffects.createStreakSavedEffect(player.x, player.y)
        else
            -- Streak is broken - create break effect
            local brokenStreak = StreakLogic.getCurrentStreak()
            if brokenStreak > 0 then
                StreakEffects.createStreakBreakEffect(player.x, player.y, brokenStreak)
            end
        end
    end
    return isPerfect
end
-- Draw streak system
function StreakSystem.draw()
    if not StreakSystem.isActive then return end
    -- Draw visual effects
    StreakEffects.draw()
    -- Draw streak UI
    StreakSystem.drawStreakUI()
end
-- Draw streak UI
function StreakSystem.drawStreakUI()
    local currentStreak = StreakLogic.getCurrentStreak()
    local maxStreak = StreakLogic.getMaxStreak()
    if currentStreak <= 0 then return end
    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    -- Draw streak counter
    local font = StreakSystem.getFont(32)
    love.graphics.setFont(font)
    local streakText = string.format("STREAK: %d", currentStreak)
    local textWidth = font:getWidth(streakText)
    local textHeight = font:getHeight()
    -- Position in top-right corner
    local x = screenWidth - textWidth - 20
    local y = 20
    -- Draw background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x - 10, y - 5, textWidth + 20, textHeight + 10, 5)
    -- Draw text
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.print(streakText, x, y)
    -- Draw grace period indicator
    if StreakLogic.isInGracePeriod() then
        local graceTime = StreakLogic.getGracePeriodRemaining()
        local graceText = string.format("GRACE: %.1f", graceTime)
        local graceFont = StreakSystem.getFont(20)
        love.graphics.setFont(graceFont)
        local graceWidth = graceFont:getWidth(graceText)
        local graceHeight = graceFont:getHeight()
        local graceX = screenWidth - graceWidth - 20
        local graceY = y + textHeight + 10
        -- Draw grace background
        love.graphics.setColor(0, 0.5, 0, 0.7)
        love.graphics.rectangle("fill", graceX - 10, graceY - 5, graceWidth + 20, graceHeight + 10, 5)
        -- Draw grace text
        love.graphics.setColor(0.2, 1, 0.2, 1)
        love.graphics.print(graceText, graceX, graceY)
    end
    -- Draw active bonuses
    StreakSystem.drawActiveBonuses(screenWidth, screenHeight)
    -- Reset color and font
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.getFont())
end
-- Draw active bonuses
function StreakSystem.drawActiveBonuses(screenWidth, screenHeight)
    local activeBonuses = StreakLogic.getActiveBonuses()
    local bonusCount = 0
    for bonusName, bonusData in pairs(activeBonuses) do
        bonusCount = bonusCount + 1
        local font = StreakSystem.getFont(16)
        love.graphics.setFont(font)
        local bonusText = string.format("%s: %.1f", bonusData.name, bonusData.timeRemaining)
        local textWidth = font:getWidth(bonusText)
        local textHeight = font:getHeight()
        -- Position bonuses in bottom-left corner
        local x = 20
        local y = screenHeight - 100 - (bonusCount - 1) * 25
        -- Draw background
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", x - 10, y - 5, textWidth + 20, textHeight + 10, 5)
        -- Draw text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(bonusText, x, y)
    end
end
-- Get current streak count
function StreakSystem.getCurrentStreak()
    return StreakLogic.getCurrentStreak()
end
-- Get max streak achieved
function StreakSystem.getMaxStreak()
    return StreakLogic.getMaxStreak()
end
-- Check if streak is active
function StreakSystem.isStreakActive()
    return StreakLogic.isStreakActive()
end
-- Check if in grace period
function StreakSystem.isInGracePeriod()
    return StreakLogic.isInGracePeriod()
end
-- Get grace period time remaining
function StreakSystem.getGracePeriodRemaining()
    return StreakLogic.getGracePeriodRemaining()
end
-- Check if a specific bonus is active
function StreakSystem.isBonusActive(bonusName)
    return StreakLogic.isBonusActive(bonusName)
end
-- Get all active bonuses
function StreakSystem.getActiveBonuses()
    return StreakLogic.getActiveBonuses()
end
-- Get bonus time remaining
function StreakSystem.getBonusTimeRemaining(bonusName)
    return StreakLogic.getBonusTimeRemaining(bonusName)
end
-- Get next milestone
function StreakSystem.getNextMilestone()
    return StreakLogic.getNextMilestone()
end
-- Get progress to next milestone
function StreakSystem.getProgressToNextMilestone()
    return StreakLogic.getProgressToNextMilestone()
end
-- Get streak statistics
function StreakSystem.getStreakStats()
    return StreakLogic.getStreakStats()
end
-- Get effect statistics
function StreakSystem.getEffectStats()
    return StreakEffects.getEffectStats()
end
-- Get screen shake offset
function StreakSystem.getScreenShake()
    return StreakEffects.getScreenShake()
end
-- Reset streak system
function StreakSystem.reset()
    StreakLogic.reset()
    StreakEffects.reset()
    Utils.Logger.info("🔄 Streak system reset")
end
-- Shutdown streak system
function StreakSystem.shutdown()
    StreakSystem.isActive = false
    Utils.Logger.info("🛑 Streak system shutdown")
end
-- Force break streak (for testing or special events)
function StreakSystem.forceBreakStreak()
    StreakLogic.forceBreakStreak()
    Utils.Logger.info("🔧 Streak force broken")
end
-- Force set streak (for testing or special events)
function StreakSystem.forceSetStreak(count)
    StreakLogic.forceSetStreak(count)
    Utils.Logger.info("🔧 Streak force set to %d", count)
end
-- Get system statistics
function StreakSystem.getSystemStats()
    return {
        is_active = StreakSystem.isActive,
        last_update = StreakSystem.lastUpdateTime,
        font_cache_size = table.getn(StreakSystem.fontCache),
        streak_stats = StreakLogic.getStreakStats(),
        effect_stats = StreakEffects.getEffectStats()
    }
end
-- Clear all effects
function StreakSystem.clearAllEffects()
    StreakEffects.clearAllEffects()
    Utils.Logger.info("✨ All streak effects cleared")
end
return StreakSystem