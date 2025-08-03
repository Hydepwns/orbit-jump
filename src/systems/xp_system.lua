--[[
    XP and Progression System - Always Visible Progress
    Psychological Design:
    - Continuous progress feedback (no wasted time feeling)
    - Frequent reward intervals (2-minute unlock cycle)
    - Escalating but manageable difficulty curve
    - Multiple XP sources prevent monotony
    Phase 5A Balance Improvements:
    - Gentler progression curve: 15%→12%→8%→5% per level tier
    - Extended rewards fill gaps at levels 32, 35, 38, 42, 45, 48, 50
    - Rebalanced XP sources for better effort/reward ratio
    - Particle effects for major XP gains
    Performance Features:
    - Font caching system
    - Efficient animation updates
    - Prestige multiplier integration
--]]
local Utils = require("src.utils.utils")
local XPSystem = {}
-- XP and level state
XPSystem.currentXP = 0
XPSystem.currentLevel = 1
XPSystem.xpToNextLevel = 100
XPSystem.totalXP = 0
-- Font cache for performance
XPSystem.fontCache = {}
-- Visual state
XPSystem.xpGainAnimation = {}
XPSystem.levelUpAnimation = {}
XPSystem.barPulsePhase = 0
-- XP sources and values (Rebalanced for better progression)
XPSystem.XP_VALUES = {
    ring_collect = 2,
    perfect_landing = 8, -- Increased from 5
    combo_ring = 6, -- Increased from 4 - Base value, multiplied by combo count
    discovery_new_planet = 35, -- Increased from 25
    streak_milestone = 15, -- Increased from 10 - Multiplied by streak count
    near_miss = 1, -- Almost got a ring
    long_jump = 3, -- Impressive distance
    precision_landing = 12, -- Increased from 8 - Very accurate landing
    exploration_bonus = 20 -- Increased from 15 - Visiting new areas
}
-- Level unlock rewards (Extended with new rewards to fill gaps)
XPSystem.LEVEL_REWARDS = {
    [3] = {type = "ability", name = "Double Jump", description = "Jump twice in one sequence"},
    [5] = {type = "cosmetic", name = "Blue Trail", description = "Cosmic blue player trail"},
    [7] = {type = "ability", name = "Ring Magnet", description = "Expanded ring collection radius"},
    [10] = {type = "cosmetic", name = "Gold Trail", description = "Shimmering gold player trail"},
    [12] = {type = "ability", name = "Slow Motion", description = "Bullet-time aiming mode"},
    [15] = {type = "cosmetic", name = "Rainbow Trail", description = "Prismatic rainbow player trail"},
    [18] = {type = "ability", name = "Ghost Trail", description = "See your last 3 jump paths"},
    [20] = {type = "cosmetic", name = "Neon Planet Theme", description = "Cyberpunk planet visuals"},
    [22] = {type = "ability", name = "Precision Indicator", description = "Landing accuracy feedback"},
    [25] = {type = "ability", name = "Planet Preview", description = "See next planet properties"},
    [28] = {type = "cosmetic", name = "Stellar Aura", description = "Glowing aura around player"},
    [30] = {type = "cosmetic", name = "Legendary Trail", description = "Ultimate player trail effect"},
    [32] = {type = "cosmetic", name = "Particle Intensity", description = "Enhanced particle trail effects"},
    [35] = {type = "ability", name = "Advanced Stats", description = "Detailed performance analytics"},
    [38] = {type = "cosmetic", name = "Custom Colors", description = "Personalized color palette"},
    [40] = {type = "ability", name = "Streak Mastery", description = "Enhanced streak recovery options"},
    [42] = {type = "cosmetic", name = "Elite Badge", description = "Elite player status indicator"},
    [45] = {type = "cosmetic", name = "Master Aura", description = "Prestigious mastery aura effect"},
    [48] = {type = "cosmetic", name = "Legend Icon", description = "Legendary status display"},
    [50] = {type = "ability", name = "Prestige Unlock", description = "Access to Prestige System!"}
}
-- Unlocked rewards tracking
XPSystem.unlockedRewards = {}
XPSystem.availableRewards = {}
-- Get cached font for performance
function XPSystem.getFont(size)
    if not XPSystem.fontCache[size] then
        XPSystem.fontCache[size] = love.graphics.newFont(size)
    end
    return XPSystem.fontCache[size]
end
-- Initialize XP system
function XPSystem.init()
    XPSystem.loadProgress()
    XPSystem.calculateXPToNextLevel()
    XPSystem.checkAvailableRewards()
    XPSystem.fontCache = {}
    Utils.Logger.info("XP System initialized - Level: %d, XP: %d/%d",
                      XPSystem.currentLevel, XPSystem.currentXP, XPSystem.xpToNextLevel)
    return true
end
-- Reset XP system (for game restart)
function XPSystem.reset()
    -- Clear all animations
    XPSystem.xpGainAnimation = {}
    XPSystem.levelUpAnimation = {}
    -- Reset visual state
    XPSystem.barPulsePhase = 0
    Utils.Logger.info("XP system reset - all animations cleared")
end
-- Update XP system
function XPSystem.update(dt)
    -- Update visual effects
    XPSystem.barPulsePhase = XPSystem.barPulsePhase + dt * 2
    -- Update XP gain animations (Enhanced)
    for i = #XPSystem.xpGainAnimation, 1, -1 do
        local anim = XPSystem.xpGainAnimation[i]
        anim.timer = anim.timer + dt
        anim.bounce_phase = anim.bounce_phase + dt * 6
        -- Floating upward with slight bounce
        anim.y = anim.start_y - (anim.timer * 60) + math.sin(anim.bounce_phase) * 5
        -- Fade out animation
        local progress = anim.timer / anim.duration
        anim.alpha = math.max(0, 1 - progress)
        -- Scale animation based on importance
        local base_scale = 1.0
        if anim.importance == "high" then base_scale = 1.4
        elseif anim.importance == "medium" then base_scale = 1.2
        end
        anim.scale = base_scale * (1 + math.sin(anim.bounce_phase) * 0.1)
        if anim.timer >= anim.duration then
            table.remove(XPSystem.xpGainAnimation, i)
        end
    end
    -- Update level up animations
    for i = #XPSystem.levelUpAnimation, 1, -1 do
        local anim = XPSystem.levelUpAnimation[i]
        anim.timer = anim.timer + dt
        anim.scale = 1 + math.sin(anim.timer * 8) * 0.3
        anim.alpha = math.max(0, 1 - anim.timer / anim.duration)
        if anim.timer >= anim.duration then
            table.remove(XPSystem.levelUpAnimation, i)
        end
    end
end
-- Add XP with source tracking
function XPSystem.addXP(amount, source, x, y, soundSystem)
    if not amount or amount <= 0 then
        Utils.Logger.warn("Invalid XP amount: %s", tostring(amount))
        return
    end
    -- Apply prestige multiplier with error handling
    local multiplier = 1.0
    local PrestigeSystem = Utils.require("src.systems.prestige_system")
    if PrestigeSystem and PrestigeSystem.getXPMultiplier then
        local success, result = pcall(PrestigeSystem.getXPMultiplier)
        if success and result then
            multiplier = result
        else
            Utils.Logger.warn("Failed to get prestige multiplier: %s", tostring(result))
        end
    end
    amount = amount * multiplier
    -- Add XP
    XPSystem.currentXP = XPSystem.currentXP + amount
    XPSystem.totalXP = XPSystem.totalXP + amount
    -- Create floating XP animation
    XPSystem.createXPGainAnimation(amount, source, x or 0, y or 0)
    -- Play XP gain sound
    if soundSystem and soundSystem.playXPGain then
        local importance = XPSystem.getXPImportance(amount)
        soundSystem:playXPGain(amount, importance)
    end
    -- Track in session stats
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onXPGained(amount, source or "unknown")
    end
    -- Check for level up
    while XPSystem.currentXP >= XPSystem.xpToNextLevel do
        XPSystem.levelUp(soundSystem)
    end
    -- Save progress
    XPSystem.saveProgress()
    Utils.Logger.info("XP gained: +%d (%s) - Level %d: %d/%d XP",
                      amount, source or "unknown", XPSystem.currentLevel,
                      XPSystem.currentXP, XPSystem.xpToNextLevel)
end
-- Handle level up
function XPSystem.levelUp(soundSystem)
    XPSystem.currentXP = XPSystem.currentXP - XPSystem.xpToNextLevel
    XPSystem.currentLevel = XPSystem.currentLevel + 1
    -- Calculate new XP requirement (progressive scaling)
    XPSystem.calculateXPToNextLevel()
    -- Create level up animation
    XPSystem.createLevelUpAnimation()
    -- Play level up sound
    if soundSystem and soundSystem.playLevelUp then
        soundSystem:playLevelUp(XPSystem.currentLevel)
    end
    -- Track in session stats
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onLevelUp()
    end
    -- Track for feedback system
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        FeedbackSystem.onLevelUp(XPSystem.currentLevel)
    end
    -- Check for reward unlock
    local reward = XPSystem.LEVEL_REWARDS[XPSystem.currentLevel]
    if reward then
        XPSystem.unlockReward(reward)
    end
    -- Check for other available rewards
    XPSystem.checkAvailableRewards()
    Utils.Logger.info("LEVEL UP! Now level %d - Next level requires %d XP",
                      XPSystem.currentLevel, XPSystem.xpToNextLevel)
end
-- Calculate XP required for next level (Improved progression curve)
function XPSystem.calculateXPToNextLevel()
    -- Adaptive scaling for better progression feel
    local baseXP = 100
    local scaling
    if XPSystem.currentLevel <= 10 then
        scaling = 1.15 -- 15% increase (quick early progress)
    elseif XPSystem.currentLevel <= 25 then
        scaling = 1.12 -- 12% increase (steady progression)
    elseif XPSystem.currentLevel <= 50 then
        scaling = 1.08 -- 8% increase (manageable late game)
    else
        scaling = 1.05 -- 5% increase (prestige preparation)
    end
    XPSystem.xpToNextLevel = math.floor(baseXP * (scaling ^ (XPSystem.currentLevel - 1)))
end
-- Unlock reward
function XPSystem.unlockReward(reward)
    table.insert(XPSystem.unlockedRewards, {
        level = XPSystem.currentLevel,
        reward = reward,
        unlockTime = love.timer.getTime()
    })
    XPSystem.createRewardUnlockAnimation(reward)
    Utils.Logger.info("Reward unlocked at level %d: %s - %s",
                      XPSystem.currentLevel, reward.name, reward.description)
end
-- Check for available rewards
function XPSystem.checkAvailableRewards()
    XPSystem.availableRewards = {}
    -- Find next few rewards
    local levelsToCheck = 5
    for level = XPSystem.currentLevel + 1, XPSystem.currentLevel + levelsToCheck do
        local reward = XPSystem.LEVEL_REWARDS[level]
        if reward then
            local xpNeeded = XPSystem.calculateXPNeededForLevel(level)
            table.insert(XPSystem.availableRewards, {
                level = level,
                reward = reward,
                xpNeeded = xpNeeded
            })
        end
    end
end
-- Calculate XP needed to reach specific level (Updated for new scaling)
function XPSystem.calculateXPNeededForLevel(targetLevel)
    if targetLevel <= XPSystem.currentLevel then return 0 end
    local xpNeeded = XPSystem.xpToNextLevel - XPSystem.currentXP
    -- Add XP for levels between current and target using adaptive scaling
    for level = XPSystem.currentLevel + 1, targetLevel - 1 do
        local baseXP = 100
        local scaling
        if level <= 10 then
            scaling = 1.15
        elseif level <= 25 then
            scaling = 1.12
        elseif level <= 50 then
            scaling = 1.08
        else
            scaling = 1.05
        end
        xpNeeded = xpNeeded + math.floor(baseXP * (scaling ^ (level - 1)))
    end
    return xpNeeded
end
-- Visual effect functions (Enhanced animations)
function XPSystem.createXPGainAnimation(amount, source, x, y)
    local Config = Utils.require("src.utils.config")
    -- Check if XP gain animations are enabled
    if Config and Config.addiction and not Config.addiction.xp_gain_animations then
        return
    end
    -- Create the text animation
    table.insert(XPSystem.xpGainAnimation, {
        amount = amount,
        source = source,
        x = x + math.random(-10, 10), -- Add slight randomness
        y = y,
        start_y = y,
        timer = 0,
        duration = 2.5, -- Slightly longer duration
        alpha = 1.0,
        scale = 1.0,
        color = XPSystem.getXPSourceColor(source),
        bounce_phase = 0,
        importance = XPSystem.getXPImportance(amount) -- For size scaling
    })
    -- Add particle burst for higher importance XP gains
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem then
        local importance = XPSystem.getXPImportance(amount)
        if importance == "high" then
            -- Major XP gain - create joy burst
            ParticleSystem.createEmotionalBurst(x, y, "joy", 0.7, source)
        elseif importance == "medium" then
            -- Medium XP gain - create sparkles
            ParticleSystem.sparkle(x, y, XPSystem.getXPSourceColor(source))
        end
    end
end
function XPSystem.createLevelUpAnimation()
    local Config = Utils.require("src.utils.config")
    -- Check if level up celebrations are enabled
    if Config and Config.addiction and not Config.addiction.level_up_celebrations then
        return
    end
    -- Use the new UI animation system for level up effect
    local UIAnimationSystem = Utils.require("src.ui.ui_animation_system")
    if UIAnimationSystem then
        UIAnimationSystem.createFlashAnimation("LEVEL " .. XPSystem.currentLevel .. "!", {
            duration = 1.0,  -- Quick flash
            color = {1, 1, 0, 1}  -- Yellow color
        })
    else
        -- Fallback to old system if animation system not available
        table.insert(XPSystem.levelUpAnimation, {
            level = XPSystem.currentLevel,
            timer = 0,
            duration = 1.0,  -- Reduced from 3.0 to 1.0 second for quick flash
            scale = 1.0,
            alpha = 1.0
        })
    end
    -- Add massive particle celebration for level ups
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem then
        -- Create achievement burst at center of screen
        ParticleSystem.createEmotionalBurst(0, 0, "achievement", 1.0, "LEVEL UP!")
    end
end
function XPSystem.createRewardUnlockAnimation(reward)
    -- This will be handled by a separate notification system
end
-- Get color for XP source (Enhanced color scheme)
function XPSystem.getXPSourceColor(source)
    local colors = {
        ring_collect = {0.2, 0.8, 1}, -- Bright Cyan
        perfect_landing = {1, 0.9, 0.2}, -- Bright Gold
        combo_ring = {1, 0.6, 0}, -- Vibrant Orange
        discovery_new_planet = {0.3, 1, 0.3}, -- Bright Green
        streak_milestone = {1, 0.2, 0.8}, -- Hot Pink
        near_miss = {0.8, 0.8, 0.8}, -- Light Gray
        long_jump = {0.4, 0.6, 1}, -- Sky Blue
        precision_landing = {1, 1, 1}, -- Pure White
        exploration_bonus = {1, 0.8, 0} -- Pure Gold
    }
    return colors[source] or {1, 1, 1}
end
-- Get XP importance level for visual scaling
function XPSystem.getXPImportance(amount)
    if amount >= 30 then return "high" -- Discovery, big milestones
    elseif amount >= 15 then return "medium" -- Streaks, precision
    else return "low" -- Regular rings, combos
    end
end
-- Draw XP system UI
function XPSystem.draw(screenWidth, screenHeight)
    XPSystem.drawXPBar(screenWidth, screenHeight)
    XPSystem.drawXPGainAnimations()
    XPSystem.drawLevelUpAnimations(screenWidth, screenHeight)
    XPSystem.drawUpcomingRewards(screenWidth, screenHeight)
end
-- Draw the main XP bar (always visible)
function XPSystem.drawXPBar(screenWidth, screenHeight)
    -- Position at top of screen
    local barWidth = 400
    local barHeight = 8
    local barX = (screenWidth - barWidth) / 2
    local barY = 5
    -- Background
    Utils.setColor({0, 0, 0}, 0.6)
    love.graphics.rectangle("fill", barX - 2, barY - 2, barWidth + 4, barHeight + 4, 3)
    -- XP bar background
    Utils.setColor({0.2, 0.2, 0.3}, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 2)
    -- XP bar fill
    local fillRatio = XPSystem.currentXP / XPSystem.xpToNextLevel
    local pulse = math.sin(XPSystem.barPulsePhase) * 0.2 + 1
    Utils.setColor({0.3, 0.7, 1}, 0.9 * pulse)
    love.graphics.rectangle("fill", barX, barY, barWidth * fillRatio, barHeight, 2)
    -- XP bar border
    Utils.setColor({0.5, 0.8, 1}, 0.9)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 2)
    love.graphics.setLineWidth(1)
    -- Level indicator
    Utils.setColor({1, 1, 1}, 1.0)
    love.graphics.setFont(love.graphics.newFont(12))
    local levelText = string.format("Level %d", XPSystem.currentLevel)
    love.graphics.print(levelText, barX - 60, barY - 2)
    -- XP text
    local xpText = string.format("%d / %d XP", XPSystem.currentXP, XPSystem.xpToNextLevel)
    local textWidth = love.graphics.getFont():getWidth(xpText)
    love.graphics.print(xpText, barX + barWidth/2 - textWidth/2, barY - 2)
    -- Next level indicator
    love.graphics.print(string.format("Level %d", XPSystem.currentLevel + 1),
                       barX + barWidth + 10, barY - 2)
end
-- Draw floating XP gain animations (Enhanced visuals)
function XPSystem.drawXPGainAnimations()
    for _, anim in ipairs(XPSystem.xpGainAnimation) do
        love.graphics.push()
        love.graphics.translate(anim.x, anim.y)
        love.graphics.scale(anim.scale, anim.scale)
        -- Glow effect for high importance XP
        if anim.importance == "high" then
            Utils.setColor(anim.color, anim.alpha * 0.3)
            love.graphics.setFont(love.graphics.newFont(18))
            local text = string.format("+%d XP", anim.amount)
            local width = love.graphics.getFont():getWidth(text)
            -- Draw glow
            for dx = -2, 2 do
                for dy = -2, 2 do
                    love.graphics.print(text, dx - width/2, dy - 9)
                end
            end
        end
        -- Main XP text
        Utils.setColor(anim.color, anim.alpha)
        local font_size = anim.importance == "high" and 18 or (anim.importance == "medium" and 16 or 14)
        love.graphics.setFont(love.graphics.newFont(font_size))
        local text = string.format("+%d XP", anim.amount)
        local width = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, -width/2, -9)
        -- Source label with better formatting
        if anim.source then
            Utils.setColor({1, 1, 1}, anim.alpha * 0.8)
            love.graphics.setFont(love.graphics.newFont(10))
            local source_text = anim.source:gsub("_", " "):upper()
            local source_width = love.graphics.getFont():getWidth(source_text)
            love.graphics.print(source_text, -source_width/2, 8)
        end
        love.graphics.pop()
    end
end
-- Draw level up animations
function XPSystem.drawLevelUpAnimations(screenWidth, screenHeight)
    for _, anim in ipairs(XPSystem.levelUpAnimation) do
        local centerX = screenWidth / 2
        local centerY = screenHeight / 2
        -- "LEVEL UP!" text
        Utils.setColor({1, 1, 0}, anim.alpha)
        love.graphics.push()
        love.graphics.translate(centerX, centerY)
        love.graphics.scale(anim.scale, anim.scale)
        love.graphics.setFont(love.graphics.newFont(36))
        local text = string.format("LEVEL %d!", anim.level)
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, -textWidth/2, -18)
        love.graphics.pop()
        -- Glow effect
        Utils.setColor({1, 1, 0}, anim.alpha * 0.3)
        love.graphics.circle("fill", centerX, centerY, 100 * anim.scale)
    end
end
-- Draw upcoming rewards preview
function XPSystem.drawUpcomingRewards(screenWidth, screenHeight)
    local startY = 70
    local rewardHeight = 25
    for i, upcoming in ipairs(XPSystem.availableRewards) do
        if i > 3 then break end -- Show only next 3 rewards
        local y = startY + (i - 1) * rewardHeight
        local alpha = 0.7 - (i - 1) * 0.1 -- Fade out further rewards
        -- Reward background
        Utils.setColor({0, 0, 0}, alpha * 0.5)
        love.graphics.rectangle("fill", 10, y, 250, rewardHeight - 2, 3)
        -- Reward border
        local borderColor = upcoming.reward.type == "ability" and {0.5, 1, 0.5} or {1, 0.5, 1}
        Utils.setColor(borderColor, alpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", 10, y, 250, rewardHeight - 2, 3)
        love.graphics.setLineWidth(1)
        -- Reward text
        Utils.setColor({1, 1, 1}, alpha)
        love.graphics.setFont(love.graphics.newFont(11))
        local rewardText = string.format("Level %d: %s", upcoming.level, upcoming.reward.name)
        love.graphics.print(rewardText, 15, y + 2)
        -- XP needed
        Utils.setColor({0.8, 0.8, 0.8}, alpha * 0.8)
        love.graphics.setFont(love.graphics.newFont(9))
        local xpText = string.format("%d XP needed", upcoming.xpNeeded)
        love.graphics.print(xpText, 15, y + 12)
    end
end
-- Helper functions for game systems
function XPSystem.giveRingXP(x, y, soundSystem)
    XPSystem.addXP(XPSystem.XP_VALUES.ring_collect, "ring_collect", x, y, soundSystem)
end
function XPSystem.givePerfectLandingXP(x, y, soundSystem)
    XPSystem.addXP(XPSystem.XP_VALUES.perfect_landing, "perfect_landing", x, y, soundSystem)
end
function XPSystem.giveComboXP(comboCount, x, y, soundSystem)
    local xp = XPSystem.XP_VALUES.combo_ring * comboCount
    XPSystem.addXP(xp, "combo_ring", x, y, soundSystem)
end
function XPSystem.giveDiscoveryXP(x, y, soundSystem)
    XPSystem.addXP(XPSystem.XP_VALUES.discovery_new_planet, "discovery_new_planet", x, y, soundSystem)
end
function XPSystem.giveStreakMilestoneXP(streakCount, x, y, soundSystem)
    local xp = XPSystem.XP_VALUES.streak_milestone * streakCount
    XPSystem.addXP(xp, "streak_milestone", x, y, soundSystem)
end
-- Save/Load progress
function XPSystem.saveProgress()
    local saveData = {
        currentXP = XPSystem.currentXP,
        currentLevel = XPSystem.currentLevel,
        totalXP = XPSystem.totalXP,
        unlockedRewards = XPSystem.unlockedRewards
    }
    local serialized = Utils.serialize(saveData)
    love.filesystem.write("xp_progress.dat", serialized)
end
function XPSystem.loadProgress()
    if love.filesystem.getInfo("xp_progress.dat") then
        local data = love.filesystem.read("xp_progress.dat")
        local saveData = Utils.deserialize(data)
        if saveData then
            XPSystem.currentXP = saveData.currentXP or 0
            XPSystem.currentLevel = saveData.currentLevel or 1
            XPSystem.totalXP = saveData.totalXP or 0
            XPSystem.unlockedRewards = saveData.unlockedRewards or {}
        end
    end
end
-- Getters
function XPSystem.getCurrentLevel()
    return XPSystem.currentLevel
end
function XPSystem.getCurrentXP()
    return XPSystem.currentXP
end
function XPSystem.getXPToNextLevel()
    return XPSystem.xpToNextLevel
end
function XPSystem.getTotalXP()
    return XPSystem.totalXP
end
function XPSystem.getUnlockedRewards()
    return XPSystem.unlockedRewards
end
function XPSystem.hasUnlockedReward(rewardName)
    for _, unlock in ipairs(XPSystem.unlockedRewards) do
        if unlock.reward.name == rewardName then
            return true
        end
    end
    return false
end
return XPSystem