-- Configuration file for Orbit Jump
-- This file is used to configure the game settings and options
-- It is used to configure the blockchain, progression, game, UI, sound, and development settings
-- It is also used to configure the achievement definitions, upgrade definitions, NFT definitions, and helper functions

local Utils = require("src.utils.utils")
local Config = {}

-- Configuration validation
Config.validators = {
    blockchain = {
        enabled = function(value) return type(value) == "boolean" end,
        network = function(value) 
            local validNetworks = {"ethereum", "polygon", "bsc", "arbitrum", "optimism"}
            for _, network in ipairs(validNetworks) do
                if value == network then return true end
            end
            return false
        end,
        batchInterval = function(value) return type(value) == "number" and value > 0 end,
        gasLimit = function(value) return type(value) == "number" and value > 0 end
    },
    progression = {
        enabled = function(value) return type(value) == "boolean" end,
        saveInterval = function(value) return type(value) == "number" and value > 0 end,
        maxUpgradeLevel = function(value) return type(value) == "number" and value > 0 end
    },
    game = {
        startingScore = function(value) return type(value) == "number" and value >= 0 end,
        maxCombo = function(value) return type(value) == "number" and value > 0 end,
        ringValue = function(value) return type(value) == "number" and value > 0 end,
        jumpPower = function(value) return type(value) == "number" and value > 0 end,
        dashPower = function(value) return type(value) == "number" and value > 0 end
    },
    sound = {
        enabled = function(value) return type(value) == "boolean" end,
        masterVolume = function(value) return type(value) == "number" and value >= 0 and value <= 1 end,
        musicVolume = function(value) return type(value) == "number" and value >= 0 and value <= 1 end,
        sfxVolume = function(value) return type(value) == "number" and value >= 0 and value <= 1 end
    }
}

-- Configuration validation function
function Config.validate()
    local errors = {}
    
    for section, validators in pairs(Config.validators) do
        if Config[section] then
            for field, validator in pairs(validators) do
                if Config[section][field] ~= nil then
                    if not validator(Config[section][field]) then
                        table.insert(errors, string.format("Invalid %s.%s value: %s", section, field, tostring(Config[section][field])))
                    end
                end
            end
        end
    end
    
    if #errors > 0 then
        Utils.Logger.error("Configuration validation failed: %s", table.concat(errors, ", "))
        return false, errors
    end
    
    Utils.Logger.info("Configuration validation passed")
    return true
end

-- Hot-reload configuration from file
function Config.reload()
    local success, newConfig = Utils.ErrorHandler.safeCall(dofile, "config.lua")
    if success and newConfig then
        -- Validate new configuration
        local valid, errors = newConfig.validate()
        if valid then
            -- Update current configuration
            for section, values in pairs(newConfig) do
                if type(values) == "table" and section ~= "validators" then
                    Config[section] = values
                end
            end
            Utils.Logger.info("Configuration reloaded successfully")
            return true
        else
            Utils.Logger.error("Failed to reload configuration: validation failed")
            return false
        end
    else
        Utils.Logger.error("Failed to reload configuration: %s", newConfig or "unknown error")
        return false
    end
end

-- Blockchain Configuration
Config.blockchain = {
    enabled = false, -- Set to true to enable blockchain features
    network = "ethereum", -- ethereum, polygon, bsc, etc.
    contractAddress = nil, -- Your smart contract address
    rpcUrl = "https://mainnet.infura.io/v3/YOUR_PROJECT_ID",
    webhookUrl = nil, -- Webhook URL for blockchain events
    batchInterval = 30, -- Seconds between blockchain batch processing
    gasLimit = 300000, -- Gas limit for transactions
    gasPrice = "20000000000" -- Gas price in wei (20 gwei)
}

-- Progression Configuration
Config.progression = {
    enabled = true, -- Set to false to disable progression system
    saveInterval = 60, -- Seconds between auto-saves
    maxUpgradeLevel = 10, -- Maximum level for upgrades
    achievementNotifications = true, -- Show achievement popups
    continuousRewards = true -- Enable continuous progression rewards
}

-- Game Configuration
Config.game = {
    startingScore = 0,
    maxCombo = 100,
    ringValue = 10,
    comboBonus = 5,
    speedBoostPerCombo = 0.1,
    jumpPower = 500,
    maxJumpPower = 1500,
    dashPower = 500,
    dashCooldown = 1.0,
    dashDuration = 0.3
}

-- UI Configuration
Config.ui = {
    showProgressionBar = true,
    showBlockchainStatus = true,
    showUpgradeButtons = true,
    uiScale = 1.0,
    colors = {
        background = {0.1, 0.1, 0.15, 0.8},
        text = {1, 1, 1, 1},
        highlight = {0.3, 0.7, 1, 1},
        button = {0.2, 0.2, 0.3, 0.9},
        progress = {0.2, 0.8, 0.4, 1},
        blockchain = {0.8, 0.6, 0.2, 1}
    }
}

-- Sound Configuration
Config.sound = {
    enabled = true,
    masterVolume = 0.7,
    musicVolume = 0.5,
    sfxVolume = 0.8,
    proceduralAudio = true
}

-- Development Configuration
Config.dev = {
    debugMode = false, -- Enable debug information
    showFPS = false, -- Show FPS counter
    showHitboxes = false, -- Show collision hitboxes
    logLevel = "info", -- debug, info, warn, error
    autoSave = true -- Auto-save progression data
}

-- Mobile Configuration
Config.mobile = {
    enabled = false, -- Auto-detect mobile devices
    touchSensitivity = 1.5, -- Multiplier for touch sensitivity
    minSwipeDistance = 20, -- Minimum distance for swipe detection
    maxSwipeDistance = 200, -- Maximum swipe distance for power
    uiScale = 1.2, -- UI scaling factor for mobile
    buttonSize = 60, -- Minimum touch target size
    hapticFeedback = true, -- Enable vibration feedback
    autoPause = true, -- Pause when app goes to background
    orientation = "landscape" -- Preferred orientation
}

-- Responsive UI Configuration
Config.responsive = {
    enabled = true,
    breakpoints = {
        mobile = 768,
        tablet = 1024,
        desktop = 1200
    },
    scaling = {
        mobile = 0.8,
        tablet = 0.9,
        desktop = 1.0
    },
    fontSizes = {
        mobile = { regular = 14, bold = 16, light = 12, extraBold = 20 },
        tablet = { regular = 16, bold = 18, light = 14, extraBold = 24 },
        desktop = { regular = 16, bold = 16, light = 16, extraBold = 24 }
    }
}

-- Blockchain Event Types
Config.blockchainEvents = {
    ACHIEVEMENT_UNLOCKED = "achievement_unlocked",
    UPGRADE_PURCHASED = "upgrade_purchased",
    TOKENS_EARNED = "tokens_earned",
    NFT_UNLOCKED = "nft_unlocked",
    HIGH_SCORE_SET = "high_score_set",
    COMBO_MASTERED = "combo_mastered",
    RING_COLLECTION_MILESTONE = "ring_collection_milestone",
    GAME_COMPLETED = "game_completed"
}

-- Achievement Definitions
Config.achievements = {
    firstRing = { name = "First Ring", description = "Collect your first ring", score = 10, tokens = 5 },
    comboMaster = { name = "Combo Master", description = "Achieve a 10x combo", score = 50, tokens = 25 },
    speedDemon = { name = "Speed Demon", description = "Reach maximum speed boost", score = 100, tokens = 50 },
    ringCollector = { name = "Ring Collector", description = "Collect 100 rings total", score = 200, tokens = 100 },
    gravityDefier = { name = "Gravity Defier", description = "Stay in space for 30 seconds", score = 150, tokens = 75 },
    planetHopper = { name = "Planet Hopper", description = "Visit all planets in one game", score = 75, tokens = 40 },
    highScorer = { name = "High Scorer", description = "Score 1000 points in one game", score = 300, tokens = 150 },
    dashMaster = { name = "Dash Master", description = "Use dash 50 times", score = 125, tokens = 60 }
}

-- Upgrade Definitions
Config.upgrades = {
    jumpPower = { 
        name = "Jump Power", 
        description = "Increase jump strength",
        baseCost = 100, 
        costMultiplier = 1.5,
        effectMultiplier = 1.2
    },
    dashPower = { 
        name = "Dash Power", 
        description = "Increase dash strength",
        baseCost = 150, 
        costMultiplier = 1.8,
        effectMultiplier = 1.25
    },
    speedBoost = { 
        name = "Speed Boost", 
        description = "Increase speed multiplier",
        baseCost = 200, 
        costMultiplier = 2.0,
        effectMultiplier = 1.15
    },
    ringValue = { 
        name = "Ring Value", 
        description = "Increase ring point value",
        baseCost = 50, 
        costMultiplier = 1.3,
        effectMultiplier = 1.1
    },
    comboMultiplier = { 
        name = "Combo Multiplier", 
        description = "Increase combo bonus",
        baseCost = 300, 
        costMultiplier = 2.5,
        effectMultiplier = 1.3
    },
    gravityResistance = { 
        name = "Gravity Resistance", 
        description = "Reduce gravity effects",
        baseCost = 250, 
        costMultiplier = 1.7,
        effectMultiplier = 0.9
    }
}

-- NFT Definitions
Config.nfts = {
    firstAchievement = {
        id = "first_achievement",
        name = "First Steps",
        description = "Unlocked your first achievement",
        rarity = "common",
        imageUrl = "https://example.com/nft1.png"
    },
    comboMaster = {
        id = "combo_master",
        name = "Combo Master",
        description = "Achieved a 10x combo",
        rarity = "rare",
        imageUrl = "https://example.com/nft2.png"
    },
    ringCollector = {
        id = "ring_collector",
        name = "Ring Collector",
        description = "Collected 100 rings",
        rarity = "epic",
        imageUrl = "https://example.com/nft3.png"
    },
    speedDemon = {
        id = "speed_demon",
        name = "Speed Demon",
        description = "Reached maximum speed",
        rarity = "legendary",
        imageUrl = "https://example.com/nft4.png"
    }
}

-- Helper functions
function Config.getBlockchainConfig()
    return Config.blockchain
end

function Config.getProgressionConfig()
    return Config.progression
end

function Config.getGameConfig()
    return Config.game
end

function Config.getUIConfig()
    return Config.ui
end

function Config.getSoundConfig()
    return Config.sound
end

function Config.getDevConfig()
    return Config.dev
end

function Config.isBlockchainEnabled()
    return Config.blockchain.enabled
end

function Config.isProgressionEnabled()
    return Config.progression.enabled
end

function Config.isDebugMode()
    return Config.dev.debugMode
end

return Config 