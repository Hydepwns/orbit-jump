-- Test file for Config System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    ["test configuration structure"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.notNil(Config.blockchain, "Blockchain config should exist")
        TestFramework.assert.notNil(Config.progression, "Progression config should exist")
        TestFramework.assert.notNil(Config.game, "Game config should exist")
        TestFramework.assert.notNil(Config.ui, "UI config should exist")
        TestFramework.assert.notNil(Config.sound, "Sound config should exist")
        TestFramework.assert.notNil(Config.dev, "Dev config should exist")
        TestFramework.assert.notNil(Config.mobile, "Mobile config should exist")
        TestFramework.assert.notNil(Config.responsive, "Responsive config should exist")
    end,
    ["test blockchain configuration defaults"] = function()
        -- Force reload to get fresh config
        package.loaded["src.utils.config"] = nil
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(false, Config.blockchain.enabled, "Blockchain should be disabled by default")
        TestFramework.assert.equal("ethereum", Config.blockchain.network, "Default network should be ethereum")
        TestFramework.assert.equal(30, Config.blockchain.batchInterval, "Default batch interval should be 30")
        TestFramework.assert.equal(300000, Config.blockchain.gasLimit, "Default gas limit should be 300000")
        TestFramework.assert.equal("20000000000", Config.blockchain.gasPrice, "Default gas price should be 20 gwei")
    end,
    ["test blockchain configuration validation"] = function()
        local Config = Utils.require("src.utils.config")
        local validators = Config.validators.blockchain
        -- Test enabled validator
        TestFramework.assert.equal(true, validators.enabled(true), "Should accept boolean true")
        TestFramework.assert.equal(true, validators.enabled(false), "Should accept boolean false")
        TestFramework.assert.equal(false, validators.enabled("true"), "Should reject string")
        TestFramework.assert.equal(false, validators.enabled(1), "Should reject number")
        -- Test network validator
        TestFramework.assert.equal(true, validators.network("ethereum"), "Should accept ethereum")
        TestFramework.assert.equal(true, validators.network("polygon"), "Should accept polygon")
        TestFramework.assert.equal(true, validators.network("bsc"), "Should accept bsc")
        TestFramework.assert.equal(true, validators.network("arbitrum"), "Should accept arbitrum")
        TestFramework.assert.equal(true, validators.network("optimism"), "Should accept optimism")
        TestFramework.assert.equal(false, validators.network("invalid"), "Should reject invalid network")
        -- Test batch interval validator
        TestFramework.assert.equal(true, validators.batchInterval(30), "Should accept positive number")
        TestFramework.assert.equal(false, validators.batchInterval(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.batchInterval(-1), "Should reject negative")
        TestFramework.assert.equal(false, validators.batchInterval("30"), "Should reject string")
        -- Test gas limit validator
        TestFramework.assert.equal(true, validators.gasLimit(300000), "Should accept positive number")
        TestFramework.assert.equal(false, validators.gasLimit(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.gasLimit(-1), "Should reject negative")
    end,
    ["test progression configuration defaults"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(true, Config.progression.enabled, "Progression should be enabled by default")
        TestFramework.assert.equal(60, Config.progression.saveInterval, "Default save interval should be 60")
        TestFramework.assert.equal(10, Config.progression.maxUpgradeLevel, "Default max upgrade level should be 10")
        TestFramework.assert.equal(true, Config.progression.achievementNotifications, "Achievement notifications should be enabled")
        TestFramework.assert.equal(true, Config.progression.continuousRewards, "Continuous rewards should be enabled")
    end,
    ["test progression configuration validation"] = function()
        local Config = Utils.require("src.utils.config")
        local validators = Config.validators.progression
        -- Test enabled validator
        TestFramework.assert.equal(true, validators.enabled(true), "Should accept boolean true")
        TestFramework.assert.equal(true, validators.enabled(false), "Should accept boolean false")
        TestFramework.assert.equal(false, validators.enabled("true"), "Should reject string")
        -- Test save interval validator
        TestFramework.assert.equal(true, validators.saveInterval(60), "Should accept positive number")
        TestFramework.assert.equal(false, validators.saveInterval(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.saveInterval(-1), "Should reject negative")
        -- Test max upgrade level validator
        TestFramework.assert.equal(true, validators.maxUpgradeLevel(10), "Should accept positive number")
        TestFramework.assert.equal(false, validators.maxUpgradeLevel(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.maxUpgradeLevel(-1), "Should reject negative")
    end,
    ["test game configuration defaults"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(0, Config.game.startingScore, "Starting score should be 0")
        TestFramework.assert.equal(100, Config.game.maxCombo, "Max combo should be 100")
        TestFramework.assert.equal(10, Config.game.ringValue, "Ring value should be 10")
        TestFramework.assert.equal(5, Config.game.comboBonus, "Combo bonus should be 5")
        TestFramework.assert.equal(0.1, Config.game.speedBoostPerCombo, "Speed boost per combo should be 0.1")
        TestFramework.assert.equal(500, Config.game.jumpPower, "Jump power should be 500")
        TestFramework.assert.equal(1500, Config.game.maxJumpPower, "Max jump power should be 1500")
        TestFramework.assert.equal(500, Config.game.dashPower, "Dash power should be 500")
        TestFramework.assert.equal(1.0, Config.game.dashCooldown, "Dash cooldown should be 1.0")
        TestFramework.assert.equal(0.3, Config.game.dashDuration, "Dash duration should be 0.3")
    end,
    ["test game configuration validation"] = function()
        local Config = Utils.require("src.utils.config")
        local validators = Config.validators.game
        -- Test starting score validator
        TestFramework.assert.equal(true, validators.startingScore(0), "Should accept zero")
        TestFramework.assert.equal(true, validators.startingScore(100), "Should accept positive")
        TestFramework.assert.equal(false, validators.startingScore(-1), "Should reject negative")
        -- Test max combo validator
        TestFramework.assert.equal(true, validators.maxCombo(100), "Should accept positive number")
        TestFramework.assert.equal(false, validators.maxCombo(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.maxCombo(-1), "Should reject negative")
        -- Test ring value validator
        TestFramework.assert.equal(true, validators.ringValue(10), "Should accept positive number")
        TestFramework.assert.equal(false, validators.ringValue(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.ringValue(-1), "Should reject negative")
        -- Test jump power validator
        TestFramework.assert.equal(true, validators.jumpPower(500), "Should accept positive number")
        TestFramework.assert.equal(false, validators.jumpPower(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.jumpPower(-1), "Should reject negative")
        -- Test dash power validator
        TestFramework.assert.equal(true, validators.dashPower(500), "Should accept positive number")
        TestFramework.assert.equal(false, validators.dashPower(0), "Should reject zero")
        TestFramework.assert.equal(false, validators.dashPower(-1), "Should reject negative")
    end,
    ["test sound configuration defaults"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(true, Config.sound.enabled, "Sound should be enabled by default")
        TestFramework.assert.equal(0.7, Config.sound.masterVolume, "Master volume should be 0.7")
        TestFramework.assert.equal(0.5, Config.sound.musicVolume, "Music volume should be 0.5")
        TestFramework.assert.equal(0.8, Config.sound.sfxVolume, "SFX volume should be 0.8")
        TestFramework.assert.equal(true, Config.sound.proceduralAudio, "Procedural audio should be enabled")
    end,
    ["test sound configuration validation"] = function()
        local Config = Utils.require("src.utils.config")
        local validators = Config.validators.sound
        -- Test enabled validator
        TestFramework.assert.equal(true, validators.enabled(true), "Should accept boolean true")
        TestFramework.assert.equal(true, validators.enabled(false), "Should accept boolean false")
        TestFramework.assert.equal(false, validators.enabled("true"), "Should reject string")
        -- Test volume validators
        TestFramework.assert.equal(true, validators.masterVolume(0.5), "Should accept valid range")
        TestFramework.assert.equal(true, validators.masterVolume(0), "Should accept 0")
        TestFramework.assert.equal(true, validators.masterVolume(1), "Should accept 1")
        TestFramework.assert.equal(false, validators.masterVolume(-0.1), "Should reject negative")
        TestFramework.assert.equal(false, validators.masterVolume(1.1), "Should reject above 1")
        TestFramework.assert.equal(true, validators.musicVolume(0.5), "Should accept valid range")
        TestFramework.assert.equal(false, validators.musicVolume(1.5), "Should reject above 1")
        TestFramework.assert.equal(true, validators.sfxVolume(0.8), "Should accept valid range")
        TestFramework.assert.equal(false, validators.sfxVolume(-0.5), "Should reject negative")
    end,
    ["test ui configuration"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(true, Config.ui.showProgressionBar, "Should show progression bar")
        TestFramework.assert.equal(true, Config.ui.showBlockchainStatus, "Should show blockchain status")
        TestFramework.assert.equal(true, Config.ui.showUpgradeButtons, "Should show upgrade buttons")
        TestFramework.assert.equal(1.0, Config.ui.uiScale, "UI scale should be 1.0")
        -- Test colors
        TestFramework.assert.notNil(Config.ui.colors, "Colors should exist")
        TestFramework.assert.equal(4, #Config.ui.colors.background, "Background color should have 4 components")
        TestFramework.assert.equal(4, #Config.ui.colors.text, "Text color should have 4 components")
        TestFramework.assert.equal(4, #Config.ui.colors.highlight, "Highlight color should have 4 components")
    end,
    ["test dev configuration"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(false, Config.dev.debugMode, "Debug mode should be disabled by default")
        TestFramework.assert.equal(false, Config.dev.showFPS, "Show FPS should be disabled by default")
        TestFramework.assert.equal(false, Config.dev.showHitboxes, "Show hitboxes should be disabled by default")
        TestFramework.assert.equal("info", Config.dev.logLevel, "Log level should be info")
        TestFramework.assert.equal(true, Config.dev.autoSave, "Auto save should be enabled")
    end,
    ["test mobile configuration"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(false, Config.mobile.enabled, "Mobile should be disabled by default")
        TestFramework.assert.equal(1.5, Config.mobile.touchSensitivity, "Touch sensitivity should be 1.5")
        TestFramework.assert.equal(20, Config.mobile.minSwipeDistance, "Min swipe distance should be 20")
        TestFramework.assert.equal(200, Config.mobile.maxSwipeDistance, "Max swipe distance should be 200")
        TestFramework.assert.equal(1.2, Config.mobile.uiScale, "Mobile UI scale should be 1.2")
        TestFramework.assert.equal(60, Config.mobile.buttonSize, "Button size should be 60")
        TestFramework.assert.equal(true, Config.mobile.hapticFeedback, "Haptic feedback should be enabled")
        TestFramework.assert.equal(true, Config.mobile.autoPause, "Auto pause should be enabled")
        TestFramework.assert.equal("landscape", Config.mobile.orientation, "Orientation should be landscape")
    end,
    ["test responsive configuration"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(true, Config.responsive.enabled, "Responsive should be enabled")
        TestFramework.assert.equal(768, Config.responsive.breakpoints.mobile, "Mobile breakpoint should be 768")
        TestFramework.assert.equal(1024, Config.responsive.breakpoints.tablet, "Tablet breakpoint should be 1024")
        TestFramework.assert.equal(1200, Config.responsive.breakpoints.desktop, "Desktop breakpoint should be 1200")
        TestFramework.assert.equal(0.8, Config.responsive.scaling.mobile, "Mobile scaling should be 0.8")
        TestFramework.assert.equal(0.9, Config.responsive.scaling.tablet, "Tablet scaling should be 0.9")
        TestFramework.assert.equal(1.0, Config.responsive.scaling.desktop, "Desktop scaling should be 1.0")
    end,
    ["test configuration validation success"] = function()
        local Config = Utils.require("src.utils.config")
        local valid, errors = Config.validate()
        TestFramework.assert.equal(true, valid, "Default configuration should be valid")
        TestFramework.assert.equal(nil, errors, "Default configuration should have no errors")
    end,
    ["test configuration validation with invalid values"] = function()
        local Config = Utils.require("src.utils.config")
        -- Save original values
        local originalNetwork = Config.blockchain.network
        local originalBatchInterval = Config.blockchain.batchInterval
        -- Set invalid values
        Config.blockchain.network = "invalid_network"
        Config.blockchain.batchInterval = -1
        local valid, errors = Config.validate()
        TestFramework.assert.equal(false, valid, "Invalid configuration should fail validation")
        TestFramework.assert.notNil(errors, "Invalid configuration should have errors")
        TestFramework.assert.greaterThan(0, #errors, "Should have at least one error")
        -- Restore original values
        Config.blockchain.network = originalNetwork
        Config.blockchain.batchInterval = originalBatchInterval
    end,
    ["test helper functions"] = function()
        local Config = Utils.require("src.utils.config")
        -- Test getters
        local blockchainConfig = Config.getBlockchainConfig()
        TestFramework.assert.equal(Config.blockchain, blockchainConfig, "Should return blockchain config")
        local progressionConfig = Config.getProgressionConfig()
        TestFramework.assert.equal(Config.progression, progressionConfig, "Should return progression config")
        local gameConfig = Config.getGameConfig()
        TestFramework.assert.equal(Config.game, gameConfig, "Should return game config")
        local uiConfig = Config.getUIConfig()
        TestFramework.assert.equal(Config.ui, uiConfig, "Should return UI config")
        local soundConfig = Config.getSoundConfig()
        TestFramework.assert.equal(Config.sound, soundConfig, "Should return sound config")
        local devConfig = Config.getDevConfig()
        TestFramework.assert.equal(Config.dev, devConfig, "Should return dev config")
    end,
    ["test boolean helper functions"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.equal(false, Config.isBlockchainEnabled(), "Blockchain should be disabled")
        TestFramework.assert.equal(true, Config.isProgressionEnabled(), "Progression should be enabled")
        TestFramework.assert.equal(false, Config.isDebugMode(), "Debug mode should be disabled")
    end,
    ["test achievement definitions"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.notNil(Config.achievements, "Achievements should exist")
        TestFramework.assert.notNil(Config.achievements.firstRing, "First ring achievement should exist")
        TestFramework.assert.equal("First Ring", Config.achievements.firstRing.name, "Should have correct name")
        TestFramework.assert.equal("Collect your first ring", Config.achievements.firstRing.description, "Should have correct description")
        TestFramework.assert.equal(10, Config.achievements.firstRing.score, "Should have correct score")
        TestFramework.assert.equal(5, Config.achievements.firstRing.tokens, "Should have correct tokens")
        -- Test a few more achievements
        TestFramework.assert.notNil(Config.achievements.comboMaster, "Combo master achievement should exist")
        TestFramework.assert.notNil(Config.achievements.speedDemon, "Speed demon achievement should exist")
        TestFramework.assert.notNil(Config.achievements.ringCollector, "Ring collector achievement should exist")
    end,
    ["test upgrade definitions"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.notNil(Config.upgrades, "Upgrades should exist")
        TestFramework.assert.notNil(Config.upgrades.jumpPower, "Jump power upgrade should exist")
        TestFramework.assert.equal("Jump Power", Config.upgrades.jumpPower.name, "Should have correct name")
        TestFramework.assert.equal("Increase jump strength", Config.upgrades.jumpPower.description, "Should have correct description")
        TestFramework.assert.equal(100, Config.upgrades.jumpPower.baseCost, "Should have correct base cost")
        TestFramework.assert.equal(1.5, Config.upgrades.jumpPower.costMultiplier, "Should have correct cost multiplier")
        TestFramework.assert.equal(1.2, Config.upgrades.jumpPower.effectMultiplier, "Should have correct effect multiplier")
    end,
    ["test nft definitions"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.notNil(Config.nfts, "NFTs should exist")
        TestFramework.assert.notNil(Config.nfts.firstAchievement, "First achievement NFT should exist")
        TestFramework.assert.equal("first_achievement", Config.nfts.firstAchievement.id, "Should have correct ID")
        TestFramework.assert.equal("First Steps", Config.nfts.firstAchievement.name, "Should have correct name")
        TestFramework.assert.equal("common", Config.nfts.firstAchievement.rarity, "Should have correct rarity")
        TestFramework.assert.notNil(Config.nfts.firstAchievement.imageUrl, "Should have image URL")
    end,
    ["test blockchain events"] = function()
        local Config = Utils.require("src.utils.config")
        TestFramework.assert.notNil(Config.blockchainEvents, "Blockchain events should exist")
        TestFramework.assert.equal("achievement_unlocked", Config.blockchainEvents.ACHIEVEMENT_UNLOCKED)
        TestFramework.assert.equal("upgrade_purchased", Config.blockchainEvents.UPGRADE_PURCHASED)
        TestFramework.assert.equal("tokens_earned", Config.blockchainEvents.TOKENS_EARNED)
        TestFramework.assert.equal("nft_unlocked", Config.blockchainEvents.NFT_UNLOCKED)
        TestFramework.assert.equal("high_score_set", Config.blockchainEvents.HIGH_SCORE_SET)
        TestFramework.assert.equal("combo_mastered", Config.blockchainEvents.COMBO_MASTERED)
        TestFramework.assert.equal("ring_collection_milestone", Config.blockchainEvents.RING_COLLECTION_MILESTONE)
        TestFramework.assert.equal("game_completed", Config.blockchainEvents.GAME_COMPLETED)
    end,
    ["test config reload functionality"] = function()
        local Config = Utils.require("src.utils.config")
        -- Mock dofile to return a valid config
        local originalDofile = dofile
        _G.dofile = function(filename)
            if filename == "config.lua" then
                -- Return a minimal valid config
                return {
                    blockchain = Config.blockchain,
                    progression = Config.progression,
                    game = Config.game,
                    ui = Config.ui,
                    sound = Config.sound,
                    dev = Config.dev,
                    mobile = Config.mobile,
                    responsive = Config.responsive,
                    validators = Config.validators,
                    validate = Config.validate
                }
            end
            return originalDofile(filename)
        end
        -- Test successful reload
        local success = Config.reload()
        TestFramework.assert.equal(true, success, "Should successfully reload valid config")
        -- Restore original dofile
        _G.dofile = originalDofile
    end,
    ["test config reload with invalid config"] = function()
        local Config = Utils.require("src.utils.config")
        -- Mock dofile to return invalid config
        local originalDofile = dofile
        _G.dofile = function(filename)
            if filename == "config.lua" then
                -- Return a mock config object with the validate function
                local mockConfig = {
                    blockchain = {
                        enabled = false,
                        network = "invalid_network", -- Invalid network
                        batchInterval = -1 -- Invalid interval
                    },
                    validators = Config.validators,
                    validate = function()
                        -- Mock validation that always fails for invalid config
                        local errors = {
                            "Invalid blockchain.network value: invalid_network",
                            "Invalid blockchain.batchInterval value: -1"
                        }
                        return false, errors
                    end
                }
                return mockConfig
            end
            return originalDofile(filename)
        end
        -- Test failed reload
        local success = Config.reload()
        TestFramework.assert.equal(false, success, "Should fail to reload invalid config")
        -- Restore original dofile
        _G.dofile = originalDofile
    end,
    ["test config reload with file error"] = function()
        local Config = Utils.require("src.utils.config")
        -- Mock dofile to throw error
        local originalDofile = dofile
        _G.dofile = function(filename)
            if filename == "config.lua" then
                error("File not found")
            end
            return originalDofile(filename)
        end
        -- Test failed reload
        local success = Config.reload()
        TestFramework.assert.equal(false, success, "Should fail to reload when file error occurs")
        -- Restore original dofile
        _G.dofile = originalDofile
    end
}
-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "Config Tests")
end
return {run = run}