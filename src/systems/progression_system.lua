-- Progression System for Orbit Jump
-- Handles persistent upgrades, achievements, and meta-progression

local Utils = require("src.utils.utils")
local ProgressionSystem = {}

-- Persistent data structure
ProgressionSystem.data = {
    totalScore = 0,
    totalRingsCollected = 0,
    totalJumps = 0,
    totalPlayTime = 0,
    highestCombo = 0,
    gamesPlayed = 0,
    achievements = {},
    upgrades = {
        jumpPower = 1,
        dashPower = 1,
        speedBoost = 1,
        ringValue = 1,
        comboMultiplier = 1,
        gravityResistance = 1
    },
    unlockables = {
        newPlanets = {},
        newRings = {},
        newParticles = {},
        newSounds = {}
    },
    blockchain = {
        walletAddress = nil,
        tokensEarned = 0,
        nftsUnlocked = {},
        lastSync = 0
    }
}

-- Achievement definitions
ProgressionSystem.achievements = {
    firstRing = { name = "First Ring", description = "Collect your first ring", score = 10, unlocked = false },
    comboMaster = { name = "Combo Master", description = "Achieve a 10x combo", score = 50, unlocked = false },
    speedDemon = { name = "Speed Demon", description = "Reach maximum speed boost", score = 100, unlocked = false },
    ringCollector = { name = "Ring Collector", description = "Collect 100 rings total", score = 200, unlocked = false },
    gravityDefier = { name = "Gravity Defier", description = "Stay in space for 30 seconds", score = 150, unlocked = false },
    planetHopper = { name = "Planet Hopper", description = "Visit all planets in one game", score = 75, unlocked = false }
}

-- Upgrade costs and effects
ProgressionSystem.upgradeCosts = {
    jumpPower = { base = 100, multiplier = 1.5 },
    dashPower = { base = 150, multiplier = 1.8 },
    speedBoost = { base = 200, multiplier = 2.0 },
    ringValue = { base = 50, multiplier = 1.3 },
    comboMultiplier = { base = 300, multiplier = 2.5 },
    gravityResistance = { base = 250, multiplier = 1.7 }
}

-- Maximum upgrade levels
ProgressionSystem.maxUpgradeLevels = {
    jumpPower = 5,
    dashPower = 5,
    speedBoost = 5,
    ringValue = 5,
    comboMultiplier = 5,
    gravityResistance = 5
}

function ProgressionSystem.init()
    ProgressionSystem.loadData()
end

function ProgressionSystem.loadData()
    local success, data  = Utils.ErrorHandler.safeCall(love.filesystem.load, "progression_data.lua")
    if success and data then
        local loadedData = data()
        if loadedData then
            ProgressionSystem.data = loadedData
        end
    end
    
    -- Ensure all required fields exist
    ProgressionSystem.data.totalScore = ProgressionSystem.data.totalScore or 0
    ProgressionSystem.data.totalRingsCollected = ProgressionSystem.data.totalRingsCollected or 0
    ProgressionSystem.data.totalJumps = ProgressionSystem.data.totalJumps or 0
    ProgressionSystem.data.totalPlayTime = ProgressionSystem.data.totalPlayTime or 0
    ProgressionSystem.data.highestCombo = ProgressionSystem.data.highestCombo or 0
    ProgressionSystem.data.gamesPlayed = ProgressionSystem.data.gamesPlayed or 0
    ProgressionSystem.data.achievements = ProgressionSystem.data.achievements or {}
    ProgressionSystem.data.upgrades = ProgressionSystem.data.upgrades or {
        jumpPower = 1,
        dashPower = 1,
        speedBoost = 1,
        ringValue = 1,
        comboMultiplier = 1,
        gravityResistance = 1
    }
    ProgressionSystem.data.unlockables = ProgressionSystem.data.unlockables or {
        newPlanets = {},
        newRings = {},
        newParticles = {},
        newSounds = {}
    }
    ProgressionSystem.data.blockchain = ProgressionSystem.data.blockchain or {
        walletAddress = nil,
        tokensEarned = 0,
        nftsUnlocked = {},
        lastSync = 0
    }
end

function ProgressionSystem.saveData()
    local dataString = "return " .. ProgressionSystem.serialize(ProgressionSystem.data)
    love.filesystem.write("progression_data.lua", dataString)
end

function ProgressionSystem.serialize(obj)
    if type(obj) == "table" then
        local result = "{"
        for k, v in pairs(obj) do
            if type(k) == "string" then
                result = result .. "[\"" .. k .. "\"]="
            else
                result = result .. "[" .. k .. "]="
            end
            result = result .. ProgressionSystem.serialize(v) .. ","
        end
        return result .. "}"
    elseif type(obj) == "string" then
        return "\"" .. obj .. "\""
    else
        return tostring(obj)
    end
end

function ProgressionSystem.addScore(score)
    ProgressionSystem.data.totalScore = ProgressionSystem.data.totalScore + score
    ProgressionSystem.checkAchievements()
    ProgressionSystem.saveData()
end

function ProgressionSystem.addRings(count)
    ProgressionSystem.data.totalRingsCollected = ProgressionSystem.data.totalRingsCollected + count
    ProgressionSystem.checkAchievements()
    ProgressionSystem.saveData()
end

function ProgressionSystem.addJump()
    ProgressionSystem.data.totalJumps = ProgressionSystem.data.totalJumps + 1
    ProgressionSystem.checkAchievements()
    ProgressionSystem.saveData()
end

function ProgressionSystem.updatePlayTime(dt)
    ProgressionSystem.data.totalPlayTime = ProgressionSystem.data.totalPlayTime + dt
    ProgressionSystem.saveData()
end

function ProgressionSystem.setHighestCombo(combo)
    if combo > ProgressionSystem.data.highestCombo then
        ProgressionSystem.data.highestCombo = combo
        ProgressionSystem.checkAchievements()
        ProgressionSystem.saveData()
    end
end

function ProgressionSystem.incrementGamesPlayed()
    ProgressionSystem.data.gamesPlayed = ProgressionSystem.data.gamesPlayed + 1
    ProgressionSystem.saveData()
end

function ProgressionSystem.checkAchievements()
    local achievements = ProgressionSystem.achievements
    
    -- Check first ring
    if ProgressionSystem.data.totalRingsCollected >= 1 and not achievements.firstRing.unlocked then
        achievements.firstRing.unlocked = true
        ProgressionSystem.unlockAchievement("firstRing")
    end
    
    -- Check combo master
    if ProgressionSystem.data.highestCombo >= 10 and not achievements.comboMaster.unlocked then
        achievements.comboMaster.unlocked = true
        ProgressionSystem.unlockAchievement("comboMaster")
    end
    
    -- Check ring collector
    if ProgressionSystem.data.totalRingsCollected >= 100 and not achievements.ringCollector.unlocked then
        achievements.ringCollector.unlocked = true
        ProgressionSystem.unlockAchievement("ringCollector")
    end
end

function ProgressionSystem.unlockAchievement(achievementId)
    local achievement = ProgressionSystem.achievements[achievementId]
    if achievement and not achievement.unlocked then
        achievement.unlocked = true
        ProgressionSystem.data.achievements[achievementId] = true
        ProgressionSystem.addScore(achievement.score)
        ProgressionSystem.saveData()
        
        -- Could trigger blockchain event here
        ProgressionSystem.triggerBlockchainEvent("achievement_unlocked", {
            achievement = achievementId,
            score = achievement.score
        })
    end
end

function ProgressionSystem.getUpgradeCost(upgradeType)
    local currentLevel = ProgressionSystem.data.upgrades[upgradeType] or 1
    local cost = ProgressionSystem.upgradeCosts[upgradeType]
    if cost then
        return math.floor(cost.base * (cost.multiplier ^ (currentLevel - 1)))
    end
    return 0
end

function ProgressionSystem.canAffordUpgrade(upgradeType)
    return ProgressionSystem.data.totalScore >= ProgressionSystem.getUpgradeCost(upgradeType)
end

function ProgressionSystem.purchaseUpgrade(upgradeType)
    -- Check if already at max level
    local currentLevel = ProgressionSystem.data.upgrades[upgradeType] or 1
    local maxLevel = ProgressionSystem.maxUpgradeLevels[upgradeType] or 5
    
    if currentLevel >= maxLevel then
        return false
    end
    
    if ProgressionSystem.canAffordUpgrade(upgradeType) then
        local cost = ProgressionSystem.getUpgradeCost(upgradeType)
        ProgressionSystem.data.totalScore = ProgressionSystem.data.totalScore - cost
        ProgressionSystem.data.upgrades[upgradeType] = ProgressionSystem.data.upgrades[upgradeType] + 1
        ProgressionSystem.saveData()
        
        -- Trigger blockchain event
        ProgressionSystem.triggerBlockchainEvent("upgrade_purchased", {
            upgrade = upgradeType,
            cost = cost,
            newLevel = ProgressionSystem.data.upgrades[upgradeType]
        })
        
        return true
    end
    return false
end

function ProgressionSystem.getUpgradeMultiplier(upgradeType)
    return ProgressionSystem.data.upgrades[upgradeType] or 1
end

function ProgressionSystem.getUpgradeEffect(upgradeType)
    -- Return the current level of the upgrade (which represents its effect)
    return ProgressionSystem.data.upgrades[upgradeType] or 0
end

-- Blockchain integration functions
function ProgressionSystem.triggerBlockchainEvent(eventType, data)
    -- This would integrate with a blockchain service
    -- For now, we'll just log the event
    Utils.Logger.info("Blockchain Event: %s %s", eventType, ProgressionSystem.serialize(data))
    
    -- Could send to webhook, API, or local blockchain node
    ProgressionSystem.data.blockchain.lastSync = love.timer.getTime()
end

function ProgressionSystem.setWalletAddress(address)
    ProgressionSystem.data.blockchain.walletAddress = address
    ProgressionSystem.saveData()
end

function ProgressionSystem.addTokens(amount)
    ProgressionSystem.data.blockchain.tokensEarned = ProgressionSystem.data.blockchain.tokensEarned + amount
    ProgressionSystem.saveData()
    
    ProgressionSystem.triggerBlockchainEvent("tokens_earned", {
        amount = amount,
        total = ProgressionSystem.data.blockchain.tokensEarned
    })
end

function ProgressionSystem.unlockNFT(nftId, metadata)
    ProgressionSystem.data.blockchain.nftsUnlocked[nftId] = {
        unlockedAt = love.timer.getTime(),
        metadata = metadata
    }
    ProgressionSystem.saveData()
    
    ProgressionSystem.triggerBlockchainEvent("nft_unlocked", {
        nftId = nftId,
        metadata = metadata
    })
end

-- Continuous progression rewards
function ProgressionSystem.calculateContinuousRewards()
    local rewards = {
        tokens = 0,
        experience = 0,
        unlockables = {}
    }
    
    -- Base rewards for playing
    rewards.tokens = math.floor(ProgressionSystem.data.totalScore / 1000)
    rewards.experience = ProgressionSystem.data.totalPlayTime * 10
    
    -- Unlock new content based on progression
    if ProgressionSystem.data.totalRingsCollected >= 50 and not ProgressionSystem.data.unlockables.newPlanets.gasGiant then
        ProgressionSystem.data.unlockables.newPlanets.gasGiant = true
        table.insert(rewards.unlockables, "gasGiant")
    end
    
    if ProgressionSystem.data.highestCombo >= 20 and not ProgressionSystem.data.unlockables.newRings.rainbow then
        ProgressionSystem.data.unlockables.newRings.rainbow = true
        table.insert(rewards.unlockables, "rainbowRing")
    end
    
    return rewards
end

-- Game completion tracking
function ProgressionSystem.completeGame(score, ringsCollected, highestCombo)
    ProgressionSystem.addScore(score)
    ProgressionSystem.addRings(ringsCollected)
    ProgressionSystem.setHighestCombo(highestCombo)
    ProgressionSystem.incrementGamesPlayed()
    
    -- Calculate and award continuous rewards
    local rewards = ProgressionSystem.calculateContinuousRewards()
    if rewards.tokens > 0 then
        ProgressionSystem.addTokens(rewards.tokens)
    end
    
    return rewards
end

-- Statistics calculation
function ProgressionSystem.getStatistics()
    local gamesPlayed = ProgressionSystem.data.gamesPlayed
    if gamesPlayed == 0 then
        return {
            averageScore = 0,
            averageRingsPerGame = 0,
            averageJumpsPerGame = 0,
            averagePlayTimePerGame = 0,
            totalPlayTime = 0,
            totalScore = 0,
            totalRingsCollected = 0,
            totalJumps = 0,
            highestCombo = 0,
            gamesPlayed = 0
        }
    end
    
    return {
        averageScore = math.floor(ProgressionSystem.data.totalScore / gamesPlayed),
        averageRingsPerGame = math.floor(ProgressionSystem.data.totalRingsCollected / gamesPlayed),
        averageJumpsPerGame = math.floor(ProgressionSystem.data.totalJumps / gamesPlayed),
        averagePlayTimePerGame = math.floor(ProgressionSystem.data.totalPlayTime / gamesPlayed),
        totalPlayTime = ProgressionSystem.data.totalPlayTime,
        totalScore = ProgressionSystem.data.totalScore,
        totalRingsCollected = ProgressionSystem.data.totalRingsCollected,
        totalJumps = ProgressionSystem.data.totalJumps,
        highestCombo = ProgressionSystem.data.highestCombo,
        gamesPlayed = gamesPlayed
    }
end

return ProgressionSystem 