-- Upgrade System for Orbit Jump
-- Spend collected points to enhance abilities
local Utils = require("src.utils.utils")
local UpgradeSystem = {}
-- Initialize currency
UpgradeSystem.currency = 0
-- Available upgrades
UpgradeSystem.upgrades = {
    -- Jump upgrades
    jump_power = {
        id = "jump_power",
        name = "Jump Power",
        description = "Increase base jump strength",
        icon = "🚀",
        maxLevel = 5,
        currentLevel = 0,
        baseCost = 50,
        costMultiplier = 1.5,
        effect = function(level)
            return 1 + (level * 0.2) -- +20% per level
        end
    },
    jump_control = {
        id = "jump_control",
        name = "Jump Control",
        description = "Better directional control when jumping",
        icon = "🎯",
        maxLevel = 3,
        currentLevel = 0,
        baseCost = 100,
        costMultiplier = 2,
        effect = function(level)
            return 1 + (level * 0.15) -- +15% per level
        end
    },
    -- Dash upgrades
    dash_power = {
        id = "dash_power",
        name = "Dash Power",
        description = "Stronger dash boost",
        icon = "💨",
        maxLevel = 5,
        currentLevel = 0,
        baseCost = 75,
        costMultiplier = 1.5,
        effect = function(level)
            return 1 + (level * 0.25) -- +25% per level
        end
    },
    dash_cooldown = {
        id = "dash_cooldown",
        name = "Dash Recharge",
        description = "Faster dash cooldown",
        icon = "⚡",
        maxLevel = 4,
        currentLevel = 0,
        baseCost = 100,
        costMultiplier = 1.8,
        effect = function(level)
            return 1 - (level * 0.15) -- -15% cooldown per level
        end
    },
    -- Ring upgrades
    ring_magnet = {
        id = "ring_magnet",
        name = "Ring Attraction",
        description = "Passive ring magnetism",
        icon = "🧲",
        maxLevel = 3,
        currentLevel = 0,
        baseCost = 150,
        costMultiplier = 2,
        effect = function(level)
            return level * 50 -- 50 unit range per level
        end
    },
    ring_value = {
        id = "ring_value",
        name = "Ring Value",
        description = "Rings worth more points",
        icon = "💎",
        maxLevel = 5,
        currentLevel = 0,
        baseCost = 100,
        costMultiplier = 1.6,
        effect = function(level)
            return 1 + (level * 0.1) -- +10% per level
        end
    },
    -- Combo upgrades
    combo_timer = {
        id = "combo_timer",
        name = "Combo Time",
        description = "Combos last longer",
        icon = "⏱️",
        maxLevel = 4,
        currentLevel = 0,
        baseCost = 80,
        costMultiplier = 1.7,
        effect = function(level)
            return 1 + (level * 0.25) -- +25% duration per level
        end
    },
    combo_multiplier = {
        id = "combo_multiplier",
        name = "Combo Power",
        description = "Higher combo multipliers",
        icon = "🔥",
        maxLevel = 3,
        currentLevel = 0,
        baseCost = 200,
        costMultiplier = 2.5,
        effect = function(level)
            return 1 + (level * 0.2) -- +20% multiplier per level
        end
    },
    -- Gravity resistance upgrade
    gravity_resist = {
        id = "gravity_resist",
        name = "Gravity Resistance",
        description = "Reduce gravity effects",
        icon = "🌌",
        maxLevel = 5,
        currentLevel = 0,
        baseCost = 120,
        costMultiplier = 1.6,
        effect = function(level)
            return 1 + (level * 0.2) -- +20% resistance per level
        end
    },
    -- Special upgrades
    shield_duration = {
        id = "shield_duration",
        name = "Shield Duration",
        description = "Shield rings last longer",
        icon = "🛡️",
        maxLevel = 3,
        currentLevel = 0,
        baseCost = 150,
        costMultiplier = 2,
        effect = function(level)
            return 1 + (level * 0.3) -- +30% duration per level
        end
    },
    exploration_bonus = {
        id = "exploration_bonus",
        name = "Explorer's Luck",
        description = "Better rewards from new planets",
        icon = "🌍",
        maxLevel = 5,
        currentLevel = 0,
        baseCost = 120,
        costMultiplier = 1.5,
        effect = function(level)
            return 1 + (level * 0.15) -- +15% discovery bonus per level
        end
    },
    warp_drive = {
        id = "warp_drive",
        name = "Warp Drive",
        description = "Fast travel to discovered planets",
        icon = "🚀",
        maxLevel = 1, -- Single unlock
        currentLevel = 0,
        baseCost = 300,
        costMultiplier = 1,
        effect = function(level)
            return level -- 0 = locked, 1 = unlocked
        end,
        onPurchase = function()
            -- Unlock warp drive when purchased
            local WarpDrive = Utils.require("src.systems.warp_drive")
            WarpDrive.unlock()
        end
    }
}
-- Currency (uses achievement points)
UpgradeSystem.currency = 500 -- Start with some points for testing
-- Add currency from achievements
function UpgradeSystem.addCurrency(amount)
    UpgradeSystem.currency = UpgradeSystem.currency + amount
    Utils.Logger.info("Added %d points to upgrade system (total: %d)", amount, UpgradeSystem.currency)
end
-- Calculate upgrade cost
function UpgradeSystem.getUpgradeCost(upgradeId)
    local upgrade = UpgradeSystem.upgrades[upgradeId]
    if not upgrade then return 0 end
    -- Get the current level (check playerUpgrades first for backward compatibility)
    local level = upgrade.currentLevel
    if UpgradeSystem.playerUpgrades and UpgradeSystem.playerUpgrades[upgradeId] then
        level = UpgradeSystem.playerUpgrades[upgradeId]
    end
    if level >= upgrade.maxLevel then
        return 0 -- Max level
    end
    -- For level 0, return base cost. For higher levels, apply multiplier
    if level == 0 then
        return upgrade.baseCost
    else
        return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ level))
    end
end
-- Alias for getUpgradeCost (for backward compatibility)
function UpgradeSystem.getCost(upgradeId)
    return UpgradeSystem.getUpgradeCost(upgradeId)
end
-- Get upgrade level
function UpgradeSystem.getLevel(upgradeId)
    local upgrade = UpgradeSystem.upgrades[upgradeId]
    if not upgrade then return 0 end
    -- Check playerUpgrades first (for backward compatibility with tests)
    if UpgradeSystem.playerUpgrades and UpgradeSystem.playerUpgrades[upgradeId] then
        return UpgradeSystem.playerUpgrades[upgradeId]
    end
    return upgrade.currentLevel
end
-- Initialize upgrade system
function UpgradeSystem.init()
    -- Initialize currency if not set
    if not UpgradeSystem.currency then
        UpgradeSystem.currency = 0
    end
    -- Initialize player upgrades tracking (for backward compatibility)
    if not UpgradeSystem.playerUpgrades then
        UpgradeSystem.playerUpgrades = {}
        -- Initialize from current levels
        for id, upgrade in pairs(UpgradeSystem.upgrades) do
            UpgradeSystem.playerUpgrades[id] = upgrade.currentLevel
        end
    end
    return true
end
-- Check if can afford upgrade
function UpgradeSystem.canAfford(upgradeId, availableCurrency)
    local cost = UpgradeSystem.getUpgradeCost(upgradeId)
    local currency = availableCurrency or UpgradeSystem.currency
    return cost > 0 and currency >= cost
end
-- Purchase upgrade
function UpgradeSystem.purchase(upgradeId, availableCurrency)
    local upgrade = UpgradeSystem.upgrades[upgradeId]
    if not upgrade then return false end
    -- Get the current level (check playerUpgrades first for backward compatibility)
    local currentLevel = upgrade.currentLevel
    if UpgradeSystem.playerUpgrades and UpgradeSystem.playerUpgrades[upgradeId] then
        currentLevel = UpgradeSystem.playerUpgrades[upgradeId]
    end
    -- Check if already at max level
    if currentLevel >= upgrade.maxLevel then
        return false
    end
    local cost = UpgradeSystem.getUpgradeCost(upgradeId)
    local currency = availableCurrency or UpgradeSystem.currency
    if cost == 0 or currency < cost then
        return false
    end
    -- Deduct cost and upgrade
    if not availableCurrency then
        UpgradeSystem.currency = UpgradeSystem.currency - cost
    end
    upgrade.currentLevel = upgrade.currentLevel + 1
    -- Update playerUpgrades for backward compatibility
    if UpgradeSystem.playerUpgrades then
        UpgradeSystem.playerUpgrades[upgradeId] = upgrade.currentLevel
    end
    -- Play upgrade sound
    local soundManager = Utils.require("src.audio.sound_manager")
    if soundManager and soundManager.playUpgrade then
        soundManager:playUpgrade()
    end
    -- Log upgrade
    Utils.Logger.info("Purchased upgrade: %s level %d", upgrade.name, upgrade.currentLevel)
    -- Call onPurchase callback if it exists
    if upgrade.onPurchase then
        upgrade.onPurchase()
    end
    return true
end
-- Get upgrade effect value
function UpgradeSystem.getEffect(upgradeId)
    local upgrade = UpgradeSystem.upgrades[upgradeId]
    if not upgrade then
        return 1 -- Default multiplier
    end
    -- Get the current level (check playerUpgrades first for backward compatibility)
    local level = upgrade.currentLevel
    if UpgradeSystem.playerUpgrades and UpgradeSystem.playerUpgrades[upgradeId] then
        level = UpgradeSystem.playerUpgrades[upgradeId]
    end
    if level == 0 then
        return 1 -- Default multiplier for level 0
    end
    return upgrade.effect(level)
end
-- Add currency (from achievements)
function UpgradeSystem.addCurrency(amount)
    UpgradeSystem.currency = UpgradeSystem.currency + amount
end
-- Save/Load
function UpgradeSystem.getSaveData()
    local saveData = {
        currency = UpgradeSystem.currency,
        upgrades = {}
    }
    -- Use playerUpgrades if available (for backward compatibility with tests)
    if UpgradeSystem.playerUpgrades then
        for id, level in pairs(UpgradeSystem.playerUpgrades) do
            saveData.upgrades[id] = level
        end
    else
        -- Fall back to current levels
        for id, upgrade in pairs(UpgradeSystem.upgrades) do
            saveData.upgrades[id] = upgrade.currentLevel
        end
    end
    return saveData
end
function UpgradeSystem.loadSaveData(data)
    if not data then return end
    UpgradeSystem.currency = data.currency or 0
    if data.upgrades then
        for id, level in pairs(data.upgrades) do
            if UpgradeSystem.upgrades[id] then
                UpgradeSystem.upgrades[id].currentLevel = level
                -- Also update playerUpgrades for backward compatibility
                if UpgradeSystem.playerUpgrades then
                    UpgradeSystem.playerUpgrades[id] = level
                end
            end
        end
    end
end
-- Get total upgrades purchased
function UpgradeSystem.getTotalUpgrades()
    local total = 0
    -- Use playerUpgrades if available (for backward compatibility with tests)
    if UpgradeSystem.playerUpgrades then
        for _, level in pairs(UpgradeSystem.playerUpgrades) do
            total = total + level
        end
    else
        -- Fall back to current levels
        for _, upgrade in pairs(UpgradeSystem.upgrades) do
            total = total + upgrade.currentLevel
        end
    end
    return total
end
-- Get completion percentage
function UpgradeSystem.getCompletionPercentage()
    local current = 0
    local max = 0
    for _, upgrade in pairs(UpgradeSystem.upgrades) do
        current = current + upgrade.currentLevel
        max = max + upgrade.maxLevel
    end
    return (current / max) * 100
end
-- Reset all upgrades to level 0
function UpgradeSystem.reset()
    for _, upgrade in pairs(UpgradeSystem.upgrades) do
        upgrade.currentLevel = 0
    end
    UpgradeSystem.currency = 0
    if UpgradeSystem.playerUpgrades then
        for id, _ in pairs(UpgradeSystem.playerUpgrades) do
            UpgradeSystem.playerUpgrades[id] = 0
        end
    end
    return true
end
-- Apply all upgrade effects to game state
function UpgradeSystem.applyEffects(gameState)
    if not gameState then return false end
    -- Apply jump power
    local jumpPower = UpgradeSystem.getEffect("jump_power")
    if gameState.jumpPower then
        gameState.jumpPower = gameState.jumpPower * jumpPower
    end
    -- Apply dash cooldown
    local dashCooldown = UpgradeSystem.getEffect("dash_cooldown")
    if gameState.dashCooldown then
        gameState.dashCooldown = gameState.dashCooldown * dashCooldown
    end
    -- Apply gravity resistance (if it exists)
    local gravityResist = UpgradeSystem.getEffect("gravity_resist")
    if gameState.gravityMultiplier then
        -- Gravity resistance reduces gravity (lower multiplier = less gravity)
        -- gravityResist = 1.6 for level 3, so we reduce gravity by 60% * 0.1 = 6%
        gameState.gravityMultiplier = gameState.gravityMultiplier * (1 - (gravityResist - 1) * 0.1)
    end
    return true
end
return UpgradeSystem