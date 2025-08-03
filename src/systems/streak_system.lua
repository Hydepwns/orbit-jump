--[[
    Perfect Landing Streak System - The Addiction Engine
    
    This system creates psychological engagement through:
    - Fear of losing progress (loss aversion)
    - Escalating rewards (variable ratio reinforcement)
    - Grace period mechanics (hope and recovery)
    - Visual/audio feedback (dopamine triggers)
    
    Phase 5A Enhancements:
    - Adaptive grace periods based on player skill level
    - Extended milestone rewards up to 100+ streaks
    - Enhanced visual effects with particle integration
    - Screen edge glow for high-streak intensity
    
    Performance Optimizations:
    - Font caching to prevent repeated font creation
    - Efficient backwards iteration for cleanup
    - Minimal string formatting operations
--]]
local Utils = require("src.utils.utils")

local StreakSystem = {}

-- Streak state management
StreakSystem.perfectLandingStreak = 0
StreakSystem.maxPerfectStreak = 0
StreakSystem.streakBroken = false
StreakSystem.streakBreakTimer = 0
StreakSystem.streakSavedByGrace = false
StreakSystem.graceTimer = 0
StreakSystem.lastLandingWasPerfect = false

-- Font cache for performance
StreakSystem.fontCache = {}

-- Visual effects state
StreakSystem.streakGlowPhase = 0
StreakSystem.bonusEffectTimer = 0
StreakSystem.breakEffectTimer = 0
StreakSystem.shakeIntensity = 0
StreakSystem.shieldGlowPhase = 0
StreakSystem.shieldActive = false

-- Streak thresholds and rewards (Enhanced with more milestones)
StreakSystem.STREAK_THRESHOLDS = {
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
StreakSystem.activeBonuses = {}

-- Perfect landing detection parameters
StreakSystem.PERFECT_LANDING_RADIUS = 15 -- pixels from planet center
StreakSystem.BASE_GRACE_PERIOD = 3.0 -- base seconds to save streak with perfect landing
StreakSystem.streak_shield_active = false -- One-time protection per session

-- Reset streak system (for game restart)
function StreakSystem.reset()
    StreakSystem.perfectLandingStreak = 0
    StreakSystem.streakBroken = false
    StreakSystem.streakBreakTimer = 0
    StreakSystem.streakSavedByGrace = false
    StreakSystem.graceTimer = 0
    StreakSystem.lastLandingWasPerfect = false
    
    -- Clear all visual effects
    StreakSystem.streakGlowPhase = 0
    StreakSystem.bonusEffectTimer = 0
    StreakSystem.breakEffectTimer = 0
    StreakSystem.shakeIntensity = 0
    StreakSystem.shieldGlowPhase = 0
    StreakSystem.shieldActive = false
    
    -- Clear safety timer
    StreakSystem.streakBrokenResetTimer = nil
    
    -- Clear all active bonuses
    StreakSystem.activeBonuses = {}
    
    -- Reset shield state
    StreakSystem.streak_shield_active = false
    
    Utils.Logger.info("Streak system reset - all effects cleared")
end

-- Get cached font for performance with error handling
function StreakSystem.getFont(size)
    if not size or size <= 0 then
        size = 12 -- Default font size
    end
    
    if not StreakSystem.fontCache[size] then
        local success, font = pcall(love.graphics.newFont, size)
        if success then
            StreakSystem.fontCache[size] = font
        else
            Utils.Logger.warn("Failed to create font size %d: %s", size, tostring(font))
            -- Fallback to default font
            StreakSystem.fontCache[size] = love.graphics.getFont()
        end
    end
    return StreakSystem.fontCache[size]
end

-- Initialize streak system
function StreakSystem.init()
    StreakSystem.perfectLandingStreak = 0
    StreakSystem.maxPerfectStreak = StreakSystem.loadMaxStreak()
    StreakSystem.streakBroken = false
    StreakSystem.activeBonuses = {}
    StreakSystem.fontCache = {}
    
    Utils.Logger.info("Streak System initialized - Max streak: %d", StreakSystem.maxPerfectStreak)
    return true
end

-- Update streak system
function StreakSystem.update(dt, gameState)
    -- Update visual effects
    StreakSystem.streakGlowPhase = StreakSystem.streakGlowPhase + dt * 4
    StreakSystem.bonusEffectTimer = math.max(0, StreakSystem.bonusEffectTimer - dt)
    StreakSystem.breakEffectTimer = math.max(0, StreakSystem.breakEffectTimer - dt)
    StreakSystem.shakeIntensity = math.max(0, StreakSystem.shakeIntensity - dt * 3)
    StreakSystem.shieldGlowPhase = StreakSystem.shieldGlowPhase + dt * 6
    
    -- Reset streak broken state when effect finishes
    if StreakSystem.breakEffectTimer <= 0 and StreakSystem.streakBroken then
        StreakSystem.streakBroken = false
        StreakSystem.shakeIntensity = 0  -- Clear shake immediately when effect ends
    end
    
    -- Safety check: If streak broken but no timer, reset after a reasonable delay
    if StreakSystem.streakBroken and StreakSystem.breakEffectTimer <= 0 then
        -- Add a small delay to prevent immediate reset
        if not StreakSystem.streakBrokenResetTimer then
            StreakSystem.streakBrokenResetTimer = 1.0 -- 1 second safety delay
        else
            StreakSystem.streakBrokenResetTimer = StreakSystem.streakBrokenResetTimer - dt
            if StreakSystem.streakBrokenResetTimer <= 0 then
                StreakSystem.streakBroken = false
                StreakSystem.streakBrokenResetTimer = nil
                StreakSystem.shakeIntensity = 0
                Utils.Logger.warn("Streak broken state reset by safety timer")
            end
        end
    else
        StreakSystem.streakBrokenResetTimer = nil
    end
    
    -- Update grace period timer
    if StreakSystem.graceTimer > 0 then
        StreakSystem.graceTimer = StreakSystem.graceTimer - dt
        if StreakSystem.graceTimer <= 0 and not StreakSystem.streakSavedByGrace then
            -- Grace period expired without perfect landing - break streak
            StreakSystem.breakStreak("grace_expired", gameState)
        end
    end
    
    -- Update active bonuses
    for bonusType, bonus in pairs(StreakSystem.activeBonuses) do
        bonus.duration = bonus.duration - dt
        if bonus.duration <= 0 then
            StreakSystem.deactivateBonus(bonusType)
        end
    end
    
    -- Apply active bonus effects to game state
    StreakSystem.applyBonusEffects(gameState)
end

-- Check if landing qualifies as perfect
function StreakSystem.isPerfectLanding(player, planet)
    if not player or not planet then return false end
    
    -- Calculate distance from planet center
    local dx = player.x - planet.x
    local dy = player.y - planet.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Perfect landing is within radius of planet center
    local planetRadius = planet.radius or 50
    local centerDistance = math.abs(distance - planetRadius)
    
    return centerDistance <= StreakSystem.PERFECT_LANDING_RADIUS
end

-- Calculate adaptive grace period based on player level
function StreakSystem.getGracePeriod()
    local XPSystem = Utils.require("src.systems.xp_system")
    if not XPSystem then return StreakSystem.BASE_GRACE_PERIOD end
    
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

-- Handle player landing on planet
function StreakSystem.onPlayerLanding(player, planet, gameState)
    local isPerfect = StreakSystem.isPerfectLanding(player, planet)
    
    if isPerfect then
        StreakSystem.handlePerfectLanding(gameState)
    else
        StreakSystem.handleImperfectLanding(gameState)
    end
    
    StreakSystem.lastLandingWasPerfect = isPerfect
end

-- Handle perfect landing
function StreakSystem.handlePerfectLanding(gameState)
    -- If we're in grace period, save the streak dramatically
    if StreakSystem.graceTimer > 0 then
        StreakSystem.streakSavedByGrace = true
        StreakSystem.graceTimer = 0
        StreakSystem.createStreakSavedEffect()
        
        -- Play streak saved sound
        if gameState and gameState.soundSystem and gameState.soundSystem.playStreakSaved then
            gameState.soundSystem:playStreakSaved()
        end
        
        -- Track in session stats
        local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
        if SessionStatsSystem then
            SessionStatsSystem.onGracePeriodSave()
        end
        
        Utils.Logger.info("STREAK SAVED! Grace period perfect landing")
    end
    
    -- Increment streak
    StreakSystem.perfectLandingStreak = StreakSystem.perfectLandingStreak + 1
    
    -- Play perfect landing sound
    if gameState and gameState.soundSystem and gameState.soundSystem.playPerfectLanding then
        gameState.soundSystem:playPerfectLanding(StreakSystem.perfectLandingStreak)
    end
    
    -- Track in session stats
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onPerfectLanding()
        SessionStatsSystem.onStreakUpdate(StreakSystem.perfectLandingStreak)
    end
    
    -- Update max streak if needed
    if StreakSystem.perfectLandingStreak > StreakSystem.maxPerfectStreak then
        StreakSystem.maxPerfectStreak = StreakSystem.perfectLandingStreak
        StreakSystem.saveMaxStreak()
        StreakSystem.createNewRecordEffect()
    end
    
    -- Check for streak milestone rewards
    StreakSystem.checkStreakMilestones(gameState)
    
    -- Create perfect landing visual effect
    StreakSystem.createPerfectLandingEffect()
    
    -- Notify social systems
    local WeeklyChallengesSystem = Utils.require("src.systems.weekly_challenges_system")
    if WeeklyChallengesSystem then
        WeeklyChallengesSystem:onPerfectLanding()
    end
    
    local GlobalEventsSystem = Utils.require("src.systems.global_events_system")
    if GlobalEventsSystem then
        GlobalEventsSystem:onPerfectLanding()
    end
    
    -- Track for leaderboards
    StreakSystem.perfectLandings = (StreakSystem.perfectLandings or 0) + 1
    
    Utils.Logger.info("Perfect landing! Streak: %d", StreakSystem.perfectLandingStreak)
end

-- Handle imperfect landing
function StreakSystem.handleImperfectLanding(gameState)
    if StreakSystem.perfectLandingStreak > 0 then
        -- Check for streak shield activation
        if StreakSystem.activeBonuses.streak_shield and not StreakSystem.streak_shield_active then
            StreakSystem.streak_shield_active = true
            StreakSystem.createStreakShieldEffect()
            Utils.Logger.info("STREAK SHIELD ACTIVATED! One-time miss forgiven")
            return -- Skip grace period, streak continues
        end
        
        -- Start grace period for streak recovery
        local gracePeriod = StreakSystem.getGracePeriod()
        StreakSystem.graceTimer = gracePeriod
        StreakSystem.streakSavedByGrace = false
        StreakSystem.createGracePeriodEffect()
        
        -- Play grace period sound
        if gameState and gameState.soundSystem and gameState.soundSystem.playGracePeriod then
            gameState.soundSystem:playGracePeriod()
        end
        
        -- Track in session stats
        local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
        if SessionStatsSystem then
            SessionStatsSystem.onImperfectLanding()
        end
        
        -- Track for feedback system
        local FeedbackSystem = Utils.require("src.systems.feedback_system")
        if FeedbackSystem then
            FeedbackSystem.onGracePeriodUsed(false) -- Grace period started, not yet resolved
        end
        
        Utils.Logger.info("Imperfect landing - Grace period started: %.1fs", gracePeriod)
    end
end

-- Break the streak (dramatic effect)
function StreakSystem.breakStreak(reason, gameState)
    if StreakSystem.perfectLandingStreak == 0 then return end
    
    local brokenStreak = StreakSystem.perfectLandingStreak
    StreakSystem.perfectLandingStreak = 0
    StreakSystem.streakBroken = true
    StreakSystem.shakeIntensity = 1.0
    
    -- Clear all visual effects immediately
    StreakSystem.streakGlowPhase = 0
    StreakSystem.bonusEffectTimer = 0
    StreakSystem.shieldActive = false
    StreakSystem.shieldGlowPhase = 0
    StreakSystem.graceTimer = 0
    StreakSystem.streakSavedByGrace = false
    
    -- Use the new UI animation system for streak break effect
    local UIAnimationSystem = Utils.require("src.ui.ui_animation_system")
    if UIAnimationSystem then
        UIAnimationSystem.createFlashAnimation("STREAK BROKEN!", {
            duration = 0.3,  -- Quick flash
            color = {1, 0, 0, 1}  -- Red color
        })
    else
        -- Fallback to old system if animation system not available
        StreakSystem.breakEffectTimer = 0.3
    end
    
    -- Play streak break sound
    if gameState and gameState.soundSystem and gameState.soundSystem.playStreakBreak then
        gameState.soundSystem:playStreakBreak(brokenStreak)
    end
    
    -- Track in session stats
    local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onStreakLost(brokenStreak)
    end
    
    -- Track for feedback system
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        FeedbackSystem.onStreakBroken(brokenStreak)
    end
    
    -- Deactivate all bonuses
    for bonusType, _ in pairs(StreakSystem.activeBonuses) do
        StreakSystem.deactivateBonus(bonusType)
    end
    
    -- Deactivate shield
    StreakSystem.shieldActive = false
    
    Utils.Logger.info("STREAK BROKEN! Lost streak of %d (%s)", brokenStreak, reason)
end

-- Check for streak milestone rewards
function StreakSystem.checkStreakMilestones(gameState)
    for _, threshold in ipairs(StreakSystem.STREAK_THRESHOLDS) do
        if StreakSystem.perfectLandingStreak == threshold.count then
            StreakSystem.activateBonus(threshold.bonus, threshold.duration, threshold.name)
            StreakSystem.createMilestoneEffect(threshold)
            
            -- Play streak milestone sound
            if gameState and gameState.soundSystem and gameState.soundSystem.playStreakMilestone then
                gameState.soundSystem:playStreakMilestone(threshold.count)
            end
            
            -- Track in session stats
            local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
            if SessionStatsSystem then
                SessionStatsSystem.onBonusActivated(threshold.bonus)
            end
            
            -- Add bonus XP for reaching milestone
            local XPSystem = Utils.require("src.systems.xp_system")
            if XPSystem then
                XPSystem.giveStreakMilestoneXP(threshold.count, 0, 0, gameState.soundSystem)
            end
            
            Utils.Logger.info("Streak milestone reached! %s activated for %ds", threshold.name, threshold.duration)
            break
        end
    end
end

-- Activate streak bonus
function StreakSystem.activateBonus(bonusType, duration, name)
    StreakSystem.activeBonuses[bonusType] = {
        duration = duration,
        name = name,
        startTime = love.timer.getTime()
    }
    
    StreakSystem.bonusEffectTimer = 2.0 -- Visual effect duration
end

-- Deactivate streak bonus
function StreakSystem.deactivateBonus(bonusType)
    if StreakSystem.activeBonuses[bonusType] then
        Utils.Logger.info("Bonus expired: %s", StreakSystem.activeBonuses[bonusType].name)
        StreakSystem.activeBonuses[bonusType] = nil
    end
end

-- Apply bonus effects to game state
function StreakSystem.applyBonusEffects(gameState)
    if not gameState then return end
    
    -- Ring Magnet - increase collection radius
    if StreakSystem.activeBonuses.ring_magnet then
        gameState.ringMagnetActive = true
        gameState.ringMagnetRadius = 80 -- Increased collection radius
    else
        gameState.ringMagnetActive = false
    end
    
    -- Double Points - multiply score gains
    if StreakSystem.activeBonuses.double_points then
        gameState.scoreMultiplier = 2.0
    elseif StreakSystem.activeBonuses.triple_rings then
        gameState.scoreMultiplier = 3.0
    elseif StreakSystem.activeBonuses.all_bonuses then
        gameState.scoreMultiplier = 5.0
    else
        gameState.scoreMultiplier = 1.0
    end
    
    -- Slow Motion
    if StreakSystem.activeBonuses.slow_motion or StreakSystem.activeBonuses.all_bonuses then
        gameState.timeScale = 0.6 -- Slow down time
    else
        gameState.timeScale = 1.0
    end
    
    -- Invincible Landing - perfect landings are more forgiving
    if StreakSystem.activeBonuses.invincible_landing or StreakSystem.activeBonuses.all_bonuses or StreakSystem.activeBonuses.infinity_mode then
        gameState.perfectLandingRadius = StreakSystem.PERFECT_LANDING_RADIUS * 2
    else
        gameState.perfectLandingRadius = StreakSystem.PERFECT_LANDING_RADIUS
    end
    
    -- Perfect Combo - perfect landings add to combo multiplier  
    if StreakSystem.activeBonuses.perfect_combo or StreakSystem.activeBonuses.infinity_mode then
        gameState.perfectLandingComboBonus = true
    else
        gameState.perfectLandingComboBonus = false
    end
    
    -- Master Focus - time dilation during grace period
    if StreakSystem.activeBonuses.master_focus or StreakSystem.activeBonuses.infinity_mode then
        if StreakSystem.graceTimer > 0 then
            gameState.timeScale = 0.4 -- Slower than regular slow motion
        end
    end
    
    -- Legendary Status - permanent visual effects
    if StreakSystem.activeBonuses.legendary_status or StreakSystem.activeBonuses.grandmaster then
        gameState.legendaryStatusActive = true
    else
        gameState.legendaryStatusActive = false
    end
    
    -- Grandmaster - ultimate status with all bonuses
    if StreakSystem.activeBonuses.grandmaster then
        gameState.scoreMultiplier = 10.0 -- Ultimate multiplier
        gameState.ringMagnetRadius = 120 -- Massive collection radius
        gameState.grandmasterActive = true
    end
end

-- Enhanced Visual Effects Functions
function StreakSystem.createPerfectLandingEffect()
    -- Get the particle system
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then return end
    
    -- Create emotional burst based on streak level
    local intensity = math.min(1.0, StreakSystem.perfectLandingStreak / 25)
    local emotionType
    
    if StreakSystem.perfectLandingStreak >= 50 then
        emotionType = "power"
    elseif StreakSystem.perfectLandingStreak >= 20 then
        emotionType = "achievement"
    elseif StreakSystem.perfectLandingStreak >= 5 then
        emotionType = "joy"
    else
        -- Simple sparkle for small streaks
        ParticleSystem.sparkle(0, 0, {1, 1, 0.8, 1})
        return
    end
    
    ParticleSystem.createEmotionalBurst(0, 0, emotionType, intensity)
end

function StreakSystem.createStreakSavedEffect()
    -- Dramatic "STREAK SAVED!" effect with particles
    StreakSystem.bonusEffectTimer = 1.2  -- Reduced from 2.0 to 1.2 seconds
    
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem then
        -- Create relief/joy particles
        ParticleSystem.createEmotionalBurst(0, 0, "joy", 1.0, "STREAK SAVED!")
    end
end

function StreakSystem.createNewRecordEffect()
    -- "NEW RECORD!" celebration with maximum particles
    StreakSystem.bonusEffectTimer = 1.8  -- Reduced from 3.0 to 1.8 seconds
    
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem then
        -- Create massive achievement celebration
        ParticleSystem.createEmotionalBurst(0, 0, "achievement", 1.0, "NEW RECORD!")
    end
end

function StreakSystem.createGracePeriodEffect()
    -- Warning indicators that streak is in danger
end

function StreakSystem.createMilestoneEffect(threshold)
    -- Celebration for reaching streak milestone with themed particles
    StreakSystem.bonusEffectTimer = 1.5  -- Reduced from 3.0 to 1.5 seconds
    
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if ParticleSystem then
        local emotionType = "achievement"
        local intensity = math.min(1.0, threshold.count / 50)
        
        -- Special effects for major milestones
        if threshold.count >= 100 then
            emotionType = "power"
            intensity = 1.0
        elseif threshold.count >= 50 then
            emotionType = "discovery"
            intensity = 1.0
        end
        
        ParticleSystem.createEmotionalBurst(0, 0, emotionType, intensity, threshold.name .. " ACTIVATED!")
    end
end

function StreakSystem.createStreakShieldEffect()
    -- Visual effect for streak shield activation
    StreakSystem.bonusEffectTimer = 1.5  -- Reduced from 2.5 to 1.5 seconds
    StreakSystem.shieldGlowPhase = 0
    StreakSystem.shieldActive = true
end

-- Draw streak UI and effects
function StreakSystem.draw(screenWidth, screenHeight)
    -- Calculate positions
    local centerX = screenWidth / 2
    local topY = 20
    
    -- Draw streak counter
    StreakSystem.drawStreakCounter(centerX, topY)
    
    -- Draw active bonuses
    StreakSystem.drawActiveBonuses(screenWidth - 200, 20)
    
    -- Draw grace period warning
    if StreakSystem.graceTimer > 0 then
        StreakSystem.drawGracePeriodWarning(centerX, topY + 60)
    end
    
    -- Draw streak break effect
    -- Now handled by UIAnimationSystem
    
    -- Draw bonus activation effect
    if StreakSystem.bonusEffectTimer > 0 then
        StreakSystem.drawBonusEffect(screenWidth, screenHeight)
    end
    
    -- Draw streak shield effect
    if StreakSystem.shieldActive then
        StreakSystem.drawStreakShieldEffect(screenWidth, screenHeight)
    end
end

-- Draw the main streak counter with enhanced effects
function StreakSystem.drawStreakCounter(centerX, topY)
    local streak = StreakSystem.perfectLandingStreak
    if streak == 0 then return end
    
    -- Get screen dimensions for edge glow
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Enhanced pulsing glow effect based on streak level
    local pulse = math.sin(StreakSystem.streakGlowPhase) * 0.3 + 1
    local baseGlow = 0.6 * pulse
    local streakIntensity = math.min(1.0, streak / 50) -- Scale up to streak 50
    local glowAlpha = baseGlow * (0.5 + streakIntensity * 0.5)
    
    -- Screen edge glow effect for high streaks
    if streak >= 10 then
        local edgeIntensity = math.min(0.4, streak / 100) * pulse * 0.5
        local edgeColor = {1, 1, 0}
        
        -- Modify color based on streak milestone
        if streak >= 50 then
            edgeColor = {1, 0.3, 1} -- Purple for ultimate streaks
        elseif streak >= 25 then
            edgeColor = {1, 0.5, 0} -- Orange for high streaks
        end
        
        -- Draw screen edge glow
        Utils.setColor(edgeColor, edgeIntensity)
        love.graphics.setLineWidth(8)
        love.graphics.rectangle("line", 2, 2, screenWidth - 4, screenHeight - 4, 10)
        love.graphics.setLineWidth(1)
    end
    
    -- Enhanced background glow with multiple layers
    local glowRadius = 50 * pulse * (1 + streakIntensity * 0.5)
    
    -- Outer glow layer
    Utils.setColor({1, 1, 0}, glowAlpha * 0.2)
    love.graphics.circle("fill", centerX, topY + 15, glowRadius * 1.5)
    
    -- Middle glow layer
    Utils.setColor({1, 1, 0}, glowAlpha * 0.3)
    love.graphics.circle("fill", centerX, topY + 15, glowRadius * 1.2)
    
    -- Inner glow layer
    Utils.setColor({1, 1, 0}, glowAlpha * 0.4)
    love.graphics.circle("fill", centerX, topY + 15, glowRadius)
    
    -- Pulsing border with dynamic thickness
    local borderThickness = 3 + math.floor(streakIntensity * 3)
    Utils.setColor({1, 1, 0}, glowAlpha)
    love.graphics.setLineWidth(borderThickness)
    love.graphics.circle("line", centerX, topY + 15, glowRadius)
    love.graphics.setLineWidth(1)
    
    -- Enhanced streak number with scaling
    local fontSize = 24 + math.floor(streakIntensity * 8)
    Utils.setColor({1, 1, 1}, 1.0)
    love.graphics.setFont(StreakSystem.getFont(fontSize))
    local streakText = tostring(streak)
    local textWidth = love.graphics.getFont():getWidth(streakText)
    love.graphics.print(streakText, centerX - textWidth/2, topY + 5 - streakIntensity * 3)
    
    -- Enhanced "PERFECT STREAK" label with dynamic text
    local labelColor = {1, 1, 0}
    local labelText = "PERFECT STREAK"
    
    -- Special labels for high streaks
    if streak >= 100 then
        labelText = "GRANDMASTER STREAK"
        labelColor = {1, 0.3, 1}
    elseif streak >= 50 then
        labelText = "LEGENDARY STREAK" 
        labelColor = {1, 0.5, 0}
    elseif streak >= 25 then
        labelText = "EPIC STREAK"
        labelColor = {1, 0.8, 0}
    end
    
    Utils.setColor(labelColor, 0.9)
    love.graphics.setFont(StreakSystem.getFont(12))
    local labelWidth = love.graphics.getFont():getWidth(labelText)
    love.graphics.print(labelText, centerX - labelWidth/2, topY + 35)
    
    -- Max streak indicator with better formatting
    if StreakSystem.maxPerfectStreak > streak then
        Utils.setColor({0.8, 0.8, 0.8}, 0.8)
        love.graphics.setFont(StreakSystem.getFont(10))
        local maxText = string.format("Personal Best: %d", StreakSystem.maxPerfectStreak)
        local maxWidth = love.graphics.getFont():getWidth(maxText)
        love.graphics.print(maxText, centerX - maxWidth/2, topY + 52)
    end
end

-- Draw active bonus indicators
function StreakSystem.drawActiveBonuses(x, y)
    local offsetY = 0
    
    for bonusType, bonus in pairs(StreakSystem.activeBonuses) do
        -- Bonus background
        Utils.setColor({0, 0, 0}, 0.7)
        love.graphics.rectangle("fill", x, y + offsetY, 180, 25, 5)
        
        -- Bonus border (color-coded)
        local borderColor = StreakSystem.getBonusColor(bonusType)
        Utils.setColor(borderColor, 0.9)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y + offsetY, 180, 25, 5)
        love.graphics.setLineWidth(1)
        
        -- Bonus name
        Utils.setColor({1, 1, 1}, 1.0)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print(bonus.name, x + 5, y + offsetY + 2)
        
        -- Time remaining bar
        local timeRatio = bonus.duration / 15 -- Normalize to expected duration
        Utils.setColor(borderColor, 0.8)
        love.graphics.rectangle("fill", x + 5, y + offsetY + 18, 170 * timeRatio, 3)
        
        -- Time remaining text
        Utils.setColor({0.9, 0.9, 0.9}, 0.8)
        love.graphics.setFont(love.graphics.newFont(10))
        love.graphics.print(string.format("%.1fs", bonus.duration), x + 140, y + offsetY + 2)
        
        offsetY = offsetY + 30
    end
end

-- Draw grace period warning
function StreakSystem.drawGracePeriodWarning(centerX, y)
    local alpha = math.sin(StreakSystem.graceTimer * 8) * 0.5 + 0.5 -- Flashing effect
    
    -- Warning background
    Utils.setColor({1, 0.5, 0}, alpha * 0.3)
    love.graphics.rectangle("fill", centerX - 100, y, 200, 30, 5)
    
    -- Warning border
    Utils.setColor({1, 0.5, 0}, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", centerX - 100, y, 200, 30, 5)
    love.graphics.setLineWidth(1)
    
    -- Warning text
    Utils.setColor({1, 1, 1}, alpha)
    love.graphics.setFont(love.graphics.newFont(14))
    local warningText = string.format("SAVE STREAK! %.1fs", StreakSystem.graceTimer)
    local textWidth = love.graphics.getFont():getWidth(warningText)
    love.graphics.print(warningText, centerX - textWidth/2, y + 8)
end

-- Draw bonus activation effect
function StreakSystem.drawBonusEffect(screenWidth, screenHeight)
    local alpha = StreakSystem.bonusEffectTimer / 1.5  -- Updated to match shorter duration
    
    -- Get player position for localized effects
    local GameState = require("src.core.game_state")
    local player = GameState.player
    if not player then return end
    
    -- Bonus activation - create magical particle effect around player
    if StreakSystem.bonusEffectTimer > 0.7 then
        local effectRadius = 100 + alpha * 50
        local particleCount = 12
        
        -- Draw magical sparkles around the player
        for i = 1, particleCount do
            local angle = (i / particleCount) * 2 * math.pi + (StreakSystem.bonusEffectTimer * 3)
            local distance = effectRadius * (0.5 + math.sin(StreakSystem.bonusEffectTimer * 4 + i) * 0.3)
            local x = player.x + math.cos(angle) * distance
            local y = player.y + math.sin(angle) * distance
            
            -- Sparkle colors: gold, cyan, magenta
            local colors = {
                {1, 0.8, 0.2, alpha * 0.8},  -- Gold
                {0.2, 1, 1, alpha * 0.6},    -- Cyan
                {1, 0.2, 1, alpha * 0.7}     -- Magenta
            }
            local color = colors[(i % 3) + 1]
            
            Utils.setColor(color)
            love.graphics.circle("fill", x, y, 3 + alpha * 2)
        end
        
        -- Draw magical aura around player
        Utils.setColor({1, 0.8, 0.2, alpha * 0.3})  -- Golden aura
        love.graphics.circle("line", player.x, player.y, effectRadius)
        love.graphics.circle("line", player.x, player.y, effectRadius * 0.7)
    end
end

-- Draw streak shield effect
function StreakSystem.drawStreakShieldEffect(screenWidth, screenHeight)
    if not StreakSystem.shieldActive then return end
    
    local alpha = math.sin(StreakSystem.shieldGlowPhase) * 0.3 + 0.5
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    
    -- Shield barrier effect around screen edges
    Utils.setColor({0, 1, 1}, alpha * 0.2)
    love.graphics.setLineWidth(8)
    love.graphics.rectangle("line", 5, 5, screenWidth - 10, screenHeight - 10, 20)
    love.graphics.setLineWidth(1)
    
    -- Shield icon in corner
    Utils.setColor({0, 1, 1}, alpha)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.print("🛡️ STREAK SHIELD ACTIVE", 20, screenHeight - 40)
end

-- Get color for bonus type
function StreakSystem.getBonusColor(bonusType)
    local colors = {
        ring_magnet = {0.5, 1, 0.5}, -- Green
        double_points = {1, 1, 0}, -- Yellow
        slow_motion = {0.5, 0.5, 1}, -- Blue
        triple_rings = {1, 0.5, 1}, -- Magenta
        invincible_landing = {1, 0.5, 0}, -- Orange
        all_bonuses = {1, 0, 1}, -- Purple
        perfect_combo = {1, 0.8, 0.2}, -- Gold
        streak_shield = {0, 1, 1}, -- Cyan
        master_focus = {0.8, 0.2, 1}, -- Violet
        infinity_mode = {1, 1, 1}, -- White
        legendary_status = {1, 0.2, 0.8}, -- Hot Pink
        grandmaster = {1, 0.5, 0} -- Orange-Gold
    }
    return colors[bonusType] or {1, 1, 1}
end

-- Save/Load streak data
function StreakSystem.saveMaxStreak()
    love.filesystem.write("max_streak.dat", tostring(StreakSystem.maxPerfectStreak))
end

function StreakSystem.loadMaxStreak()
    if love.filesystem.getInfo("max_streak.dat") then
        local data = love.filesystem.read("max_streak.dat")
        return tonumber(data) or 0
    end
    return 0
end

-- Get current streak info
function StreakSystem.getCurrentStreak()
    return StreakSystem.perfectLandingStreak
end

function StreakSystem.getMaxStreak()
    return StreakSystem.maxPerfectStreak
end

function StreakSystem.isOnStreak()
    return StreakSystem.perfectLandingStreak > 0
end

function StreakSystem.hasActiveBonus(bonusType)
    return StreakSystem.activeBonuses[bonusType] ~= nil
end

function StreakSystem.getActiveBonuses()
    return StreakSystem.activeBonuses
end

-- Debug function to check and fix stuck streak broken state
function StreakSystem.debugStreakState()
    local state = {
        perfectLandingStreak = StreakSystem.perfectLandingStreak,
        streakBroken = StreakSystem.streakBroken,
        breakEffectTimer = StreakSystem.breakEffectTimer,
        streakBrokenResetTimer = StreakSystem.streakBrokenResetTimer,
        shakeIntensity = StreakSystem.shakeIntensity
    }
    
    -- If streak is broken but timer is 0, force reset
    if StreakSystem.streakBroken and StreakSystem.breakEffectTimer <= 0 then
        Utils.Logger.warn("Detected stuck streak broken state, forcing reset")
        StreakSystem.streakBroken = false
        StreakSystem.shakeIntensity = 0
        StreakSystem.streakBrokenResetTimer = nil
        state.fixed = true
    end
    
    return state
end

return StreakSystem