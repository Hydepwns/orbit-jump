--[[
    ═══════════════════════════════════════════════════════════════════════════
    Streak Logic - Core Streak Calculation & Tracking
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles the core logic for streak calculation, tracking, and
    milestone detection. It's separated from visual effects and UI to maintain
    clean separation of concerns.
--]]

local Utils = require("src.utils.utils")

local StreakLogic = {}

-- Streak state management
StreakLogic.perfectLandingStreak = 0
StreakLogic.maxPerfectStreak = 0
StreakLogic.streakBroken = false
StreakLogic.streakBreakTimer = 0
StreakLogic.streakSavedByGrace = false
StreakLogic.graceTimer = 0
StreakLogic.lastLandingWasPerfect = false

-- Perfect landing detection parameters
StreakLogic.PERFECT_LANDING_RADIUS = 15 -- pixels from planet center
StreakLogic.BASE_GRACE_PERIOD = 3.0 -- base seconds to save streak with perfect landing
StreakLogic.streak_shield_active = false -- One-time protection per session

-- Streak thresholds and rewards (Enhanced with more milestones)
StreakLogic.STREAK_THRESHOLDS = {
    {count = 5, name = "Ring Magnet", bonus = "ring_magnet", duration = 12},
    {count = 10, name = "Double Points", bonus = "double_points", duration = 18},
    {count = 15, name = "Slow Motion", bonus = "slow_motion", duration = 10},
    {count = 20, name = "Triple Rings", bonus = "triple_rings", duration = 15},
    {count = 25, name = "God Mode", bonus = "invincible_landing", duration = 25},
    {count = 30, name = "Legendary", bonus = "all_bonuses", duration = 30},
    {count = 35, name = "Perfect Combo", bonus = "perfect_combo", duration = 20},
    {count = 40, name = "Streak Shield", bonus = "streak_shield", duration = 300}, -- 5 minutes
    {count = 45, name = "Master Focus", bonus = "master_focus", duration = 15},
    {count = 50, name = "Infinity Mode", bonus = "infinity_mode", duration = 60},
    {count = 75, name = "Legendary Status", bonus = "legendary_status", duration = 600}, -- 10 minutes
    {count = 100, name = "Grandmaster", bonus = "grandmaster", duration = 1800} -- 30 minutes
}

-- Active bonuses
StreakLogic.activeBonuses = {}

-- Reset streak system (for game restart)
function StreakLogic.reset()
    StreakLogic.perfectLandingStreak = 0
    StreakLogic.streakBroken = false
    StreakLogic.streakBreakTimer = 0
    StreakLogic.streakSavedByGrace = false
    StreakLogic.graceTimer = 0
    StreakLogic.lastLandingWasPerfect = false
    
    -- Clear safety timer
    StreakLogic.streakBrokenResetTimer = nil
    
    -- Clear all active bonuses
    StreakLogic.activeBonuses = {}
    
    -- Reset shield state
    StreakLogic.streak_shield_active = false
    
    Utils.Logger.info("Streak logic reset - all state cleared")
end

-- Get current streak count
function StreakLogic.getCurrentStreak()
    return StreakLogic.perfectLandingStreak
end

-- Get max streak achieved
function StreakLogic.getMaxStreak()
    return StreakLogic.maxPerfectStreak
end

-- Check if streak is active
function StreakLogic.isStreakActive()
    return StreakLogic.perfectLandingStreak > 0 and not StreakLogic.streakBroken
end

-- Check if in grace period
function StreakLogic.isInGracePeriod()
    return StreakLogic.graceTimer > 0
end

-- Get grace period time remaining
function StreakLogic.getGracePeriodRemaining()
    return math.max(0, StreakLogic.graceTimer)
end

-- Calculate adaptive grace period based on player level
function StreakLogic.getGracePeriod()
    local XPSystem = Utils.require("src.systems.xp_system")
    if not XPSystem then return StreakLogic.BASE_GRACE_PERIOD end
    
    local Config = Utils.require("src.utils.config")
    local modifier = Config and Config.getStreakGracePeriodModifier() or 1.0
    
    local level = XPSystem.getCurrentLevel()
    local basePeriod
    if level <= 10 then
        basePeriod = 4.0 -- New players get extra time
    elseif level <= 25 then
        basePeriod = 3.0 -- Standard grace period
    else
        basePeriod = 2.5 -- Veterans get tighter timing
    end
    
    return basePeriod * modifier
end

-- Check if landing is perfect
function StreakLogic.isPerfectLanding(player, planet)
    if not player or not planet then return false end
    
    local distance = Utils.getDistance(player.x, player.y, planet.x, planet.y)
    return distance <= StreakLogic.PERFECT_LANDING_RADIUS
end

-- Handle player landing on planet
function StreakLogic.onPlayerLanding(player, planet, gameState)
    local isPerfect = StreakLogic.isPerfectLanding(player, planet)
    
    if isPerfect then
        StreakLogic.handlePerfectLanding(gameState)
    else
        StreakLogic.handleImperfectLanding(gameState)
    end
    
    StreakLogic.lastLandingWasPerfect = isPerfect
    return isPerfect
end

-- Handle perfect landing
function StreakLogic.handlePerfectLanding(gameState)
    -- If we're in grace period, save the streak dramatically
    if StreakLogic.graceTimer > 0 then
        StreakLogic.streakSavedByGrace = true
        StreakLogic.graceTimer = 0
        
        -- Track in session stats
        local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
        if SessionStatsSystem then
            SessionStatsSystem.onGracePeriodSave()
        end
        
        Utils.Logger.info("STREAK SAVED! Grace period perfect landing")
    end
    
    -- Increment streak
    StreakLogic.perfectLandingStreak = StreakLogic.perfectLandingStreak + 1
    
    -- Track in session stats
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onPerfectLanding()
        SessionStatsSystem.onStreakUpdate(StreakLogic.perfectLandingStreak)
    end
    
    -- Update max streak if needed
    if StreakLogic.perfectLandingStreak > StreakLogic.maxPerfectStreak then
        StreakLogic.maxPerfectStreak = StreakLogic.perfectLandingStreak
        StreakLogic.saveMaxStreak()
    end
    
    -- Check for streak milestone rewards
    StreakLogic.checkStreakMilestones(gameState)
    
    -- Notify social systems
    local WeeklyChallengesSystem = Utils.require("src.systems.weekly_challenges_system")
    if WeeklyChallengesSystem then
        WeeklyChallengesSystem:onPerfectLanding()
    end
    
    local GlobalEventsSystem = Utils.require("src.systems.global_events_system")
    if GlobalEventsSystem then
        GlobalEventsSystem:onPerfectLanding()
    end
    
    Utils.Logger.info("Perfect landing! Streak: %d", StreakLogic.perfectLandingStreak)
end

-- Handle imperfect landing
function StreakLogic.handleImperfectLanding(gameState)
    -- Check if streak shield is active
    if StreakLogic.streak_shield_active then
        StreakLogic.streak_shield_active = false
        Utils.Logger.info("Streak shield consumed - streak protected")
        return
    end
    
    -- Start grace period if we have a streak
    if StreakLogic.perfectLandingStreak > 0 and not StreakLogic.streakBroken then
        StreakLogic.graceTimer = StreakLogic.getGracePeriod()
        StreakLogic.streakBroken = true
        StreakLogic.streakBreakTimer = 0
        
        -- Track in session stats
        local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
        if SessionStatsSystem then
            SessionStatsSystem.onStreakBreak()
        end
        
        Utils.Logger.info("Streak broken! Grace period started: %.1f seconds", StreakLogic.graceTimer)
    end
end

-- Update streak system (called every frame)
function StreakLogic.update(dt)
    -- Update grace period timer
    if StreakLogic.graceTimer > 0 then
        StreakLogic.graceTimer = StreakLogic.graceTimer - dt
        
        -- If grace period expires, break the streak
        if StreakLogic.graceTimer <= 0 then
            StreakLogic.breakStreak()
        end
    end
    
    -- Update streak break timer
    if StreakLogic.streakBroken then
        StreakLogic.streakBreakTimer = StreakLogic.streakBreakTimer + dt
    end
    
    -- Update active bonuses
    StreakLogic.updateActiveBonuses(dt)
end

-- Break the streak
function StreakLogic.breakStreak()
    if StreakLogic.perfectLandingStreak > 0 then
        local brokenStreak = StreakLogic.perfectLandingStreak
        StreakLogic.perfectLandingStreak = 0
        StreakLogic.streakBroken = false
        StreakLogic.streakBreakTimer = 0
        StreakLogic.graceTimer = 0
        StreakLogic.streakSavedByGrace = false
        
        -- Clear all active bonuses
        StreakLogic.activeBonuses = {}
        
        -- Track in session stats
        local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
        if SessionStatsSystem then
            SessionStatsSystem.onStreakLost(brokenStreak)
        end
        
        Utils.Logger.info("Streak lost! Final count: %d", brokenStreak)
    end
end

-- Check for streak milestones and activate bonuses
function StreakLogic.checkStreakMilestones(gameState)
    for _, threshold in ipairs(StreakLogic.STREAK_THRESHOLDS) do
        if StreakLogic.perfectLandingStreak == threshold.count then
            StreakLogic.activateStreakBonus(threshold, gameState)
            break -- Only activate one bonus per landing
        end
    end
end

-- Activate a streak bonus
function StreakLogic.activateStreakBonus(threshold, gameState)
    -- Add bonus to active list
    StreakLogic.activeBonuses[threshold.bonus] = {
        name = threshold.name,
        duration = threshold.duration,
        timeRemaining = threshold.duration,
        activatedAt = love.timer.getTime()
    }
    
    -- Special handling for streak shield
    if threshold.bonus == "streak_shield" then
        StreakLogic.streak_shield_active = true
    end
    
    -- Track in session stats
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onStreakBonusActivated(threshold.bonus, threshold.count)
    end
    
    Utils.Logger.info("Streak bonus activated: %s (streak: %d)", threshold.name, threshold.count)
end

-- Update active bonuses
function StreakLogic.updateActiveBonuses(dt)
    local expiredBonuses = {}
    
    for bonus, data in pairs(StreakLogic.activeBonuses) do
        data.timeRemaining = data.timeRemaining - dt
        
        if data.timeRemaining <= 0 then
            table.insert(expiredBonuses, bonus)
        end
    end
    
    -- Remove expired bonuses
    for _, bonus in ipairs(expiredBonuses) do
        StreakLogic.activeBonuses[bonus] = nil
        
        -- Special handling for streak shield
        if bonus == "streak_shield" then
            StreakLogic.streak_shield_active = false
        end
        
        Utils.Logger.info("Streak bonus expired: %s", bonus)
    end
end

-- Check if a specific bonus is active
function StreakLogic.isBonusActive(bonusName)
    return StreakLogic.activeBonuses[bonusName] ~= nil
end

-- Get all active bonuses
function StreakLogic.getActiveBonuses()
    return StreakLogic.activeBonuses
end

-- Get bonus time remaining
function StreakLogic.getBonusTimeRemaining(bonusName)
    local bonus = StreakLogic.activeBonuses[bonusName]
    return bonus and bonus.timeRemaining or 0
end

-- Get next milestone
function StreakLogic.getNextMilestone()
    for _, threshold in ipairs(StreakLogic.STREAK_THRESHOLDS) do
        if StreakLogic.perfectLandingStreak < threshold.count then
            return threshold
        end
    end
    return nil -- All milestones achieved
end

-- Get progress to next milestone
function StreakLogic.getProgressToNextMilestone()
    local nextMilestone = StreakLogic.getNextMilestone()
    if not nextMilestone then return 1.0 end
    
    local prevMilestone = 0
    for _, threshold in ipairs(StreakLogic.STREAK_THRESHOLDS) do
        if threshold.count < nextMilestone.count then
            prevMilestone = threshold.count
        else
            break
        end
    end
    
    local progress = (StreakLogic.perfectLandingStreak - prevMilestone) / (nextMilestone.count - prevMilestone)
    return math.max(0, math.min(1, progress))
end

-- Save max streak to persistent storage
function StreakLogic.saveMaxStreak()
    -- This would save to persistent storage
    -- For now, just log the achievement
    Utils.Logger.info("New max streak record: %d", StreakLogic.maxPerfectStreak)
end

-- Load max streak from persistent storage
function StreakLogic.loadMaxStreak()
    -- This would load from persistent storage
    -- For now, just return the current value
    return StreakLogic.maxPerfectStreak
end

-- Get streak statistics
function StreakLogic.getStreakStats()
    return {
        current_streak = StreakLogic.perfectLandingStreak,
        max_streak = StreakLogic.maxPerfectStreak,
        is_active = StreakLogic.isStreakActive(),
        is_broken = StreakLogic.streakBroken,
        grace_timer = StreakLogic.graceTimer,
        active_bonuses = StreakLogic.activeBonuses,
        next_milestone = StreakLogic.getNextMilestone(),
        progress = StreakLogic.getProgressToNextMilestone()
    }
end

-- Force break streak (for testing or special events)
function StreakLogic.forceBreakStreak()
    StreakLogic.breakStreak()
end

-- Force set streak (for testing or special events)
function StreakLogic.forceSetStreak(count)
    StreakLogic.perfectLandingStreak = math.max(0, count)
    if StreakLogic.perfectLandingStreak > StreakLogic.maxPerfectStreak then
        StreakLogic.maxPerfectStreak = StreakLogic.perfectLandingStreak
    end
end

return StreakLogic 