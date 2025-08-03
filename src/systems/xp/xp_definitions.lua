-- XP Definitions Module
-- Contains all XP-related constants, values, and level rewards

local XPDefinitions = {}

-- XP sources and values (Rebalanced for better progression)
XPDefinitions.XP_VALUES = {
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
XPDefinitions.LEVEL_REWARDS = {
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

-- Level progression curve
XPDefinitions.LEVEL_CURVE = {
    BASE_XP = 100,
    TIER_1_MULTIPLIER = 1.12, -- 12% increase per level (levels 1-15)
    TIER_2_MULTIPLIER = 1.08, -- 8% increase per level (levels 16-30)
    TIER_3_MULTIPLIER = 1.05, -- 5% increase per level (levels 31-50)
    TIER_1_END = 15,
    TIER_2_END = 30,
    TIER_3_END = 50
}

-- Animation constants
XPDefinitions.ANIMATION = {
    XP_GAIN_DURATION = 2.0,
    LEVEL_UP_DURATION = 3.0,
    BAR_PULSE_SPEED = 2.0,
    BOUNCE_SPEED = 6.0,
    FLOAT_SPEED = 60,
    BOUNCE_AMPLITUDE = 5,
    SCALE_VARIATION = 0.1
}

-- Visual constants
XPDefinitions.VISUAL = {
    BAR_HEIGHT = 20,
    BAR_WIDTH = 300,
    BAR_BORDER = 2,
    TEXT_MARGIN = 10,
    ICON_SIZE = 24
}

-- Get XP value for a source
function XPDefinitions.getXPValue(source)
    return XPDefinitions.XP_VALUES[source] or 0
end

-- Get level reward
function XPDefinitions.getLevelReward(level)
    return XPDefinitions.LEVEL_REWARDS[level]
end

-- Calculate XP required for next level
function XPDefinitions.calculateXPForLevel(level)
    if level <= 1 then
        return XPDefinitions.LEVEL_CURVE.BASE_XP
    end
    
    local xp = XPDefinitions.LEVEL_CURVE.BASE_XP
    
    for i = 2, level do
        if i <= XPDefinitions.LEVEL_CURVE.TIER_1_END then
            xp = xp * XPDefinitions.LEVEL_CURVE.TIER_1_MULTIPLIER
        elseif i <= XPDefinitions.LEVEL_CURVE.TIER_2_END then
            xp = xp * XPDefinitions.LEVEL_CURVE.TIER_2_MULTIPLIER
        elseif i <= XPDefinitions.LEVEL_CURVE.TIER_3_END then
            xp = xp * XPDefinitions.LEVEL_CURVE.TIER_3_MULTIPLIER
        else
            xp = xp * XPDefinitions.LEVEL_CURVE.TIER_3_MULTIPLIER
        end
    end
    
    return math.floor(xp)
end

-- Get XP importance level
function XPDefinitions.getXPImportance(amount)
    if amount >= 20 then
        return "high"
    elseif amount >= 10 then
        return "medium"
    else
        return "low"
    end
end

-- Get all available rewards
function XPDefinitions.getAvailableRewards()
    local rewards = {}
    for level, reward in pairs(XPDefinitions.LEVEL_REWARDS) do
        table.insert(rewards, {
            level = level,
            reward = reward
        })
    end
    table.sort(rewards, function(a, b) return a.level < b.level end)
    return rewards
end

-- Get rewards by type
function XPDefinitions.getRewardsByType(rewardType)
    local rewards = {}
    for level, reward in pairs(XPDefinitions.LEVEL_REWARDS) do
        if reward.type == rewardType then
            table.insert(rewards, {
                level = level,
                reward = reward
            })
        end
    end
    table.sort(rewards, function(a, b) return a.level < b.level end)
    return rewards
end

return XPDefinitions 