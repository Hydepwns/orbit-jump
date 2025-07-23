-- Upgrade System for Orbit Jump
-- Spend collected points to enhance abilities

local UpgradeSystem = {}

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

-- Calculate upgrade cost
function UpgradeSystem.getUpgradeCost(upgradeId)
    local upgrade = UpgradeSystem.upgrades[upgradeId]
    if not upgrade then return 0 end
    
    if upgrade.currentLevel >= upgrade.maxLevel then
        return 0 -- Max level
    end
    
    return math.floor(upgrade.baseCost * (upgrade.costMultiplier ^ upgrade.currentLevel))
end

-- Check if can afford upgrade
function UpgradeSystem.canAfford(upgradeId)
    local cost = UpgradeSystem.getUpgradeCost(upgradeId)
    return cost > 0 and UpgradeSystem.currency >= cost
end

-- Purchase upgrade
function UpgradeSystem.purchase(upgradeId)
    local upgrade = UpgradeSystem.upgrades[upgradeId]
    if not upgrade then return false end
    
    local cost = UpgradeSystem.getUpgradeCost(upgradeId)
    if cost == 0 or UpgradeSystem.currency < cost then
        return false
    end
    
    -- Deduct cost and upgrade
    UpgradeSystem.currency = UpgradeSystem.currency - cost
    upgrade.currentLevel = upgrade.currentLevel + 1
    
    -- Play upgrade sound
    local soundManager = Utils.require("src.audio.sound_manager")
    if soundManager and soundManager.playUpgrade then
        soundManager:playUpgrade()
    end
    
    -- Log upgrade
    local Utils = require("src.utils.utils")
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
    if not upgrade or upgrade.currentLevel == 0 then
        return 1 -- Default multiplier
    end
    
    return upgrade.effect(upgrade.currentLevel)
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
    
    for id, upgrade in pairs(UpgradeSystem.upgrades) do
        saveData.upgrades[id] = upgrade.currentLevel
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
            end
        end
    end
end

-- Get total upgrades purchased
function UpgradeSystem.getTotalUpgrades()
    local total = 0
    for _, upgrade in pairs(UpgradeSystem.upgrades) do
        total = total + upgrade.currentLevel
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

return UpgradeSystem