-- Tests for Config System
package.path = package.path .. ";../../?.lua"

local TestFramework = require("tests.test_framework")
local Mocks = require("tests.mocks")
local Config = require("src.utils.config")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test configuration structure
    ["configuration structure"] = function()
        TestFramework.utils.assertNotNil(Config.blockchain, "Blockchain config should exist")
        TestFramework.utils.assertNotNil(Config.progression, "Progression config should exist")
        TestFramework.utils.assertNotNil(Config.game, "Game config should exist")
        TestFramework.utils.assertNotNil(Config.ui, "UI config should exist")
        TestFramework.utils.assertNotNil(Config.sound, "Sound config should exist")
        TestFramework.utils.assertNotNil(Config.dev, "Dev config should exist")
        TestFramework.utils.assertNotNil(Config.mobile, "Mobile config should exist")
        TestFramework.utils.assertNotNil(Config.responsive, "Responsive config should exist")
    end,
    
    -- Test blockchain configuration
    ["blockchain configuration"] = function()
        TestFramework.utils.assertNotNil(Config.blockchain.enabled, "Blockchain enabled should exist")
        TestFramework.utils.assertNotNil(Config.blockchain.network, "Blockchain network should exist")
        TestFramework.utils.assertNotNil(Config.blockchain.batchInterval, "Blockchain batch interval should exist")
        TestFramework.utils.assertNotNil(Config.blockchain.gasLimit, "Blockchain gas limit should exist")
        TestFramework.utils.assertEqual("ethereum", Config.blockchain.network, "Default network should be ethereum")
        TestFramework.utils.assertEqual(30, Config.blockchain.batchInterval, "Default batch interval should be 30")
        TestFramework.utils.assertEqual(300000, Config.blockchain.gasLimit, "Default gas limit should be 300000")
    end,
    
    ["blockchain configuration validation"] = function()
        local validators = Config.validators.blockchain
        
        TestFramework.utils.assertTrue(validators.enabled(true), "Enabled validator should accept true")
        TestFramework.utils.assertTrue(validators.enabled(false), "Enabled validator should accept false")
        TestFramework.utils.assertFalse(validators.enabled("true"), "Enabled validator should reject string")
        
        TestFramework.utils.assertTrue(validators.network("ethereum"), "Network validator should accept ethereum")
        TestFramework.utils.assertTrue(validators.network("polygon"), "Network validator should accept polygon")
        TestFramework.utils.assertTrue(validators.network("bsc"), "Network validator should accept bsc")
        TestFramework.utils.assertFalse(validators.network("invalid"), "Network validator should reject invalid network")
        
        TestFramework.utils.assertTrue(validators.batchInterval(30), "Batch interval validator should accept positive number")
        TestFramework.utils.assertFalse(validators.batchInterval(0), "Batch interval validator should reject zero")
        TestFramework.utils.assertFalse(validators.batchInterval(-1), "Batch interval validator should reject negative")
        
        TestFramework.utils.assertTrue(validators.gasLimit(300000), "Gas limit validator should accept positive number")
        TestFramework.utils.assertFalse(validators.gasLimit(0), "Gas limit validator should reject zero")
        TestFramework.utils.assertFalse(validators.gasLimit(-1), "Gas limit validator should reject negative")
    end,
    
    -- Test progression configuration
    ["progression configuration"] = function()
        TestFramework.utils.assertNotNil(Config.progression.enabled, "Progression enabled should exist")
        TestFramework.utils.assertNotNil(Config.progression.saveInterval, "Progression save interval should exist")
        TestFramework.utils.assertNotNil(Config.progression.maxUpgradeLevel, "Progression max upgrade level should exist")
        TestFramework.utils.assertEqual(60, Config.progression.saveInterval, "Default save interval should be 60")
        TestFramework.utils.assertEqual(10, Config.progression.maxUpgradeLevel, "Default max upgrade level should be 10")
    end,
    
    ["progression configuration validation"] = function()
        local validators = Config.validators.progression
        
        TestFramework.utils.assertTrue(validators.enabled(true), "Enabled validator should accept true")
        TestFramework.utils.assertTrue(validators.enabled(false), "Enabled validator should accept false")
        TestFramework.utils.assertFalse(validators.enabled("true"), "Enabled validator should reject string")
        
        TestFramework.utils.assertTrue(validators.saveInterval(60), "Save interval validator should accept positive number")
        TestFramework.utils.assertFalse(validators.saveInterval(0), "Save interval validator should reject zero")
        TestFramework.utils.assertFalse(validators.saveInterval(-1), "Save interval validator should reject negative")
        
        TestFramework.utils.assertTrue(validators.maxUpgradeLevel(10), "Max upgrade level validator should accept positive number")
        TestFramework.utils.assertFalse(validators.maxUpgradeLevel(0), "Max upgrade level validator should reject zero")
        TestFramework.utils.assertFalse(validators.maxUpgradeLevel(-1), "Max upgrade level validator should reject negative")
    end,
    
    -- Test game configuration
    ["game configuration"] = function()
        TestFramework.utils.assertNotNil(Config.game.startingScore, "Game starting score should exist")
        TestFramework.utils.assertNotNil(Config.game.maxCombo, "Game max combo should exist")
        TestFramework.utils.assertNotNil(Config.game.ringValue, "Game ring value should exist")
        TestFramework.utils.assertNotNil(Config.game.jumpPower, "Game jump power should exist")
        TestFramework.utils.assertNotNil(Config.game.dashPower, "Game dash power should exist")
        TestFramework.utils.assertEqual(0, Config.game.startingScore, "Default starting score should be 0")
        TestFramework.utils.assertEqual(100, Config.game.maxCombo, "Default max combo should be 100")
        TestFramework.utils.assertEqual(10, Config.game.ringValue, "Default ring value should be 10")
        TestFramework.utils.assertEqual(300, Config.game.jumpPower, "Default jump power should be 300")
        TestFramework.utils.assertEqual(500, Config.game.dashPower, "Default dash power should be 500")
    end,
    
    ["game configuration validation"] = function()
        local validators = Config.validators.game
        
        TestFramework.utils.assertTrue(validators.startingScore(0), "Starting score validator should accept zero")
        TestFramework.utils.assertTrue(validators.startingScore(100), "Starting score validator should accept positive")
        TestFramework.utils.assertFalse(validators.startingScore(-1), "Starting score validator should reject negative")
        
        TestFramework.utils.assertTrue(validators.maxCombo(100), "Max combo validator should accept positive number")
        TestFramework.utils.assertFalse(validators.maxCombo(0), "Max combo validator should reject zero")
        TestFramework.utils.assertFalse(validators.maxCombo(-1), "Max combo validator should reject negative")
        
        TestFramework.utils.assertTrue(validators.ringValue(10), "Ring value validator should accept positive number")
        TestFramework.utils.assertFalse(validators.ringValue(0), "Ring value validator should reject zero")
        TestFramework.utils.assertFalse(validators.ringValue(-1), "Ring value validator should reject negative")
        
        TestFramework.utils.assertTrue(validators.jumpPower(300), "Jump power validator should accept positive number")
        TestFramework.utils.assertFalse(validators.jumpPower(0), "Jump power validator should reject zero")
        TestFramework.utils.assertFalse(validators.jumpPower(-1), "Jump power validator should reject negative")
        
        TestFramework.utils.assertTrue(validators.dashPower(500), "Dash power validator should accept positive number")
        TestFramework.utils.assertFalse(validators.dashPower(0), "Dash power validator should reject zero")
        TestFramework.utils.assertFalse(validators.dashPower(-1), "Dash power validator should reject negative")
    end,
    
    -- Test sound configuration
    ["sound configuration"] = function()
        TestFramework.utils.assertNotNil(Config.sound.enabled, "Sound enabled should exist")
        TestFramework.utils.assertNotNil(Config.sound.masterVolume, "Sound master volume should exist")
        TestFramework.utils.assertNotNil(Config.sound.musicVolume, "Sound music volume should exist")
        TestFramework.utils.assertNotNil(Config.sound.sfxVolume, "Sound sfx volume should exist")
        TestFramework.utils.assertEqual(0.7, Config.sound.masterVolume, "Default master volume should be 0.7")
        TestFramework.utils.assertEqual(0.5, Config.sound.musicVolume, "Default music volume should be 0.5")
        TestFramework.utils.assertEqual(0.8, Config.sound.sfxVolume, "Default sfx volume should be 0.8")
    end,
    
    ["sound configuration validation"] = function()
        local validators = Config.validators.sound
        
        TestFramework.utils.assertTrue(validators.enabled(true), "Enabled validator should accept true")
        TestFramework.utils.assertTrue(validators.enabled(false), "Enabled validator should accept false")
        TestFramework.utils.assertFalse(validators.enabled("true"), "Enabled validator should reject string")
        
        TestFramework.utils.assertTrue(validators.masterVolume(0.5), "Master volume validator should accept valid range")
        TestFramework.utils.assertTrue(validators.masterVolume(0), "Master volume validator should accept 0")
        TestFramework.utils.assertTrue(validators.masterVolume(1), "Master volume validator should accept 1")
        TestFramework.utils.assertFalse(validators.masterVolume(-0.1), "Master volume validator should reject negative")
        TestFramework.utils.assertFalse(validators.masterVolume(1.1), "Master volume validator should reject above 1")
        
        TestFramework.utils.assertTrue(validators.musicVolume(0.5), "Music volume validator should accept valid range")
        TestFramework.utils.assertTrue(validators.musicVolume(0), "Music volume validator should accept 0")
        TestFramework.utils.assertTrue(validators.musicVolume(1), "Music volume validator should accept 1")
        TestFramework.utils.assertFalse(validators.musicVolume(-0.1), "Music volume validator should reject negative")
        TestFramework.utils.assertFalse(validators.musicVolume(1.1), "Music volume validator should reject above 1")
        
        TestFramework.utils.assertTrue(validators.sfxVolume(0.5), "SFX volume validator should accept valid range")
        TestFramework.utils.assertTrue(validators.sfxVolume(0), "SFX volume validator should accept 0")
        TestFramework.utils.assertTrue(validators.sfxVolume(1), "SFX volume validator should accept 1")
        TestFramework.utils.assertFalse(validators.sfxVolume(-0.1), "SFX volume validator should reject negative")
        TestFramework.utils.assertFalse(validators.sfxVolume(1.1), "SFX volume validator should reject above 1")
    end,
    
    -- Test configuration validation
    ["configuration validation success"] = function()
        local valid, errors = Config.validate()
        
        TestFramework.utils.assertTrue(valid, "Default configuration should be valid")
        TestFramework.utils.assertNil(errors, "Default configuration should have no errors")
    end,
    
    ["configuration validation with invalid values"] = function()
        -- Temporarily modify config to test validation
        local originalNetwork = Config.blockchain.network
        local originalBatchInterval = Config.blockchain.batchInterval
        
        Config.blockchain.network = "invalid_network"
        Config.blockchain.batchInterval = -1
        
        local valid, errors = Config.validate()
        
        TestFramework.utils.assertFalse(valid, "Invalid configuration should fail validation")
        TestFramework.utils.assertNotNil(errors, "Invalid configuration should have errors")
        TestFramework.utils.assertTrue(#errors > 0, "Should have at least one error")
        
        -- Restore original values
        Config.blockchain.network = originalNetwork
        Config.blockchain.batchInterval = originalBatchInterval
    end,
    
    -- Test helper functions
    ["get blockchain config"] = function()
        local blockchainConfig = Config.getBlockchainConfig()
        
        TestFramework.utils.assertNotNil(blockchainConfig, "Should return blockchain config")
        TestFramework.utils.assertEqual(Config.blockchain, blockchainConfig, "Should return the blockchain config")
    end,
    
    ["get progression config"] = function()
        local progressionConfig = Config.getProgressionConfig()
        
        TestFramework.utils.assertNotNil(progressionConfig, "Should return progression config")
        TestFramework.utils.assertEqual(Config.progression, progressionConfig, "Should return the progression config")
    end,
    
    ["get game config"] = function()
        local gameConfig = Config.getGameConfig()
        
        TestFramework.utils.assertNotNil(gameConfig, "Should return game config")
        TestFramework.utils.assertEqual(Config.game, gameConfig, "Should return the game config")
    end,
    
    ["get UI config"] = function()
        local uiConfig = Config.getUIConfig()
        
        TestFramework.utils.assertNotNil(uiConfig, "Should return UI config")
        TestFramework.utils.assertEqual(Config.ui, uiConfig, "Should return the UI config")
    end,
    
    ["get sound config"] = function()
        local soundConfig = Config.getSoundConfig()
        
        TestFramework.utils.assertNotNil(soundConfig, "Should return sound config")
        TestFramework.utils.assertEqual(Config.sound, soundConfig, "Should return the sound config")
    end,
    
    ["get dev config"] = function()
        local devConfig = Config.getDevConfig()
        
        TestFramework.utils.assertNotNil(devConfig, "Should return dev config")
        TestFramework.utils.assertEqual(Config.dev, devConfig, "Should return the dev config")
    end,
    
    -- Test boolean helper functions
    ["is blockchain enabled"] = function()
        local enabled = Config.isBlockchainEnabled()
        
        TestFramework.utils.assertNotNil(enabled, "Should return boolean value")
        TestFramework.utils.assertEqual(Config.blockchain.enabled, enabled, "Should return blockchain enabled state")
    end,
    
    ["is progression enabled"] = function()
        local enabled = Config.isProgressionEnabled()
        
        TestFramework.utils.assertNotNil(enabled, "Should return boolean value")
        TestFramework.utils.assertEqual(Config.progression.enabled, enabled, "Should return progression enabled state")
    end,
    
    ["is debug mode"] = function()
        local debugMode = Config.isDebugMode()
        
        TestFramework.utils.assertNotNil(debugMode, "Should return boolean value")
        TestFramework.utils.assertEqual(Config.dev.debugMode, debugMode, "Should return debug mode state")
    end,
    
    -- Test achievement definitions
    ["achievement definitions"] = function()
        TestFramework.utils.assertNotNil(Config.achievements, "Achievements should exist")
        TestFramework.utils.assertNotNil(Config.achievements.firstRing, "First ring achievement should exist")
        TestFramework.utils.assertNotNil(Config.achievements.comboMaster, "Combo master achievement should exist")
        TestFramework.utils.assertNotNil(Config.achievements.speedDemon, "Speed demon achievement should exist")
        TestFramework.utils.assertNotNil(Config.achievements.ringCollector, "Ring collector achievement should exist")
        
        TestFramework.utils.assertEqual("First Ring", Config.achievements.firstRing.name, "First ring achievement should have correct name")
        TestFramework.utils.assertEqual(10, Config.achievements.firstRing.score, "First ring achievement should have correct score")
        TestFramework.utils.assertEqual(5, Config.achievements.firstRing.tokens, "First ring achievement should have correct tokens")
    end,
    
    -- Test upgrade definitions
    ["upgrade definitions"] = function()
        TestFramework.utils.assertNotNil(Config.upgrades, "Upgrades should exist")
        TestFramework.utils.assertNotNil(Config.upgrades.jumpPower, "Jump power upgrade should exist")
        TestFramework.utils.assertNotNil(Config.upgrades.dashPower, "Dash power upgrade should exist")
        TestFramework.utils.assertNotNil(Config.upgrades.speedBoost, "Speed boost upgrade should exist")
        
        TestFramework.utils.assertEqual("Jump Power", Config.upgrades.jumpPower.name, "Jump power upgrade should have correct name")
        TestFramework.utils.assertEqual(100, Config.upgrades.jumpPower.baseCost, "Jump power upgrade should have correct base cost")
        TestFramework.utils.assertEqual(1.5, Config.upgrades.jumpPower.costMultiplier, "Jump power upgrade should have correct cost multiplier")
        TestFramework.utils.assertEqual(1.2, Config.upgrades.jumpPower.effectMultiplier, "Jump power upgrade should have correct effect multiplier")
    end,
    
    -- Test NFT definitions
    ["NFT definitions"] = function()
        TestFramework.utils.assertNotNil(Config.nfts, "NFTs should exist")
        TestFramework.utils.assertNotNil(Config.nfts.firstAchievement, "First achievement NFT should exist")
        TestFramework.utils.assertNotNil(Config.nfts.comboMaster, "Combo master NFT should exist")
        TestFramework.utils.assertNotNil(Config.nfts.ringCollector, "Ring collector NFT should exist")
        TestFramework.utils.assertNotNil(Config.nfts.speedDemon, "Speed demon NFT should exist")
        
        TestFramework.utils.assertEqual("first_achievement", Config.nfts.firstAchievement.id, "First achievement NFT should have correct ID")
        TestFramework.utils.assertEqual("First Steps", Config.nfts.firstAchievement.name, "First achievement NFT should have correct name")
        TestFramework.utils.assertEqual("common", Config.nfts.firstAchievement.rarity, "First achievement NFT should have correct rarity")
    end,
    
    -- Test blockchain events
    ["blockchain events"] = function()
        TestFramework.utils.assertNotNil(Config.blockchainEvents, "Blockchain events should exist")
        TestFramework.utils.assertEqual("achievement_unlocked", Config.blockchainEvents.ACHIEVEMENT_UNLOCKED, "Achievement unlocked event should be correct")
        TestFramework.utils.assertEqual("upgrade_purchased", Config.blockchainEvents.UPGRADE_PURCHASED, "Upgrade purchased event should be correct")
        TestFramework.utils.assertEqual("tokens_earned", Config.blockchainEvents.TOKENS_EARNED, "Tokens earned event should be correct")
        TestFramework.utils.assertEqual("nft_unlocked", Config.blockchainEvents.NFT_UNLOCKED, "NFT unlocked event should be correct")
    end,
    
    -- Test mobile configuration
    ["mobile configuration"] = function()
        TestFramework.utils.assertNotNil(Config.mobile.enabled, "Mobile enabled should exist")
        TestFramework.utils.assertNotNil(Config.mobile.touchSensitivity, "Touch sensitivity should exist")
        TestFramework.utils.assertNotNil(Config.mobile.minSwipeDistance, "Min swipe distance should exist")
        TestFramework.utils.assertNotNil(Config.mobile.maxSwipeDistance, "Max swipe distance should exist")
        TestFramework.utils.assertNotNil(Config.mobile.uiScale, "UI scale should exist")
        TestFramework.utils.assertNotNil(Config.mobile.buttonSize, "Button size should exist")
        TestFramework.utils.assertNotNil(Config.mobile.hapticFeedback, "Haptic feedback should exist")
        TestFramework.utils.assertNotNil(Config.mobile.autoPause, "Auto pause should exist")
        TestFramework.utils.assertNotNil(Config.mobile.orientation, "Orientation should exist")
        
        TestFramework.utils.assertEqual(1.5, Config.mobile.touchSensitivity, "Default touch sensitivity should be 1.5")
        TestFramework.utils.assertEqual(20, Config.mobile.minSwipeDistance, "Default min swipe distance should be 20")
        TestFramework.utils.assertEqual(200, Config.mobile.maxSwipeDistance, "Default max swipe distance should be 200")
        TestFramework.utils.assertEqual(1.2, Config.mobile.uiScale, "Default UI scale should be 1.2")
        TestFramework.utils.assertEqual(60, Config.mobile.buttonSize, "Default button size should be 60")
        TestFramework.utils.assertEqual("landscape", Config.mobile.orientation, "Default orientation should be landscape")
    end,
    
    -- Test responsive configuration
    ["responsive configuration"] = function()
        TestFramework.utils.assertNotNil(Config.responsive.enabled, "Responsive enabled should exist")
        TestFramework.utils.assertNotNil(Config.responsive.breakpoints, "Breakpoints should exist")
        TestFramework.utils.assertNotNil(Config.responsive.scaling, "Scaling should exist")
        TestFramework.utils.assertNotNil(Config.responsive.fontSizes, "Font sizes should exist")
        
        TestFramework.utils.assertEqual(768, Config.responsive.breakpoints.mobile, "Mobile breakpoint should be 768")
        TestFramework.utils.assertEqual(1024, Config.responsive.breakpoints.tablet, "Tablet breakpoint should be 1024")
        TestFramework.utils.assertEqual(1200, Config.responsive.breakpoints.desktop, "Desktop breakpoint should be 1200")
        
        TestFramework.utils.assertEqual(0.8, Config.responsive.scaling.mobile, "Mobile scaling should be 0.8")
        TestFramework.utils.assertEqual(0.9, Config.responsive.scaling.tablet, "Tablet scaling should be 0.9")
        TestFramework.utils.assertEqual(1.0, Config.responsive.scaling.desktop, "Desktop scaling should be 1.0")
    end,
    
    -- Test UI configuration
    ["UI configuration"] = function()
        TestFramework.utils.assertNotNil(Config.ui.showProgressionBar, "Show progression bar should exist")
        TestFramework.utils.assertNotNil(Config.ui.showBlockchainStatus, "Show blockchain status should exist")
        TestFramework.utils.assertNotNil(Config.ui.showUpgradeButtons, "Show upgrade buttons should exist")
        TestFramework.utils.assertNotNil(Config.ui.uiScale, "UI scale should exist")
        TestFramework.utils.assertNotNil(Config.ui.colors, "Colors should exist")
        
        TestFramework.utils.assertEqual(1.0, Config.ui.uiScale, "Default UI scale should be 1.0")
        TestFramework.utils.assertNotNil(Config.ui.colors.background, "Background color should exist")
        TestFramework.utils.assertNotNil(Config.ui.colors.text, "Text color should exist")
        TestFramework.utils.assertNotNil(Config.ui.colors.highlight, "Highlight color should exist")
        TestFramework.utils.assertNotNil(Config.ui.colors.button, "Button color should exist")
        TestFramework.utils.assertNotNil(Config.ui.colors.progress, "Progress color should exist")
        TestFramework.utils.assertNotNil(Config.ui.colors.blockchain, "Blockchain color should exist")
    end,
    
    -- Test development configuration
    ["development configuration"] = function()
        TestFramework.utils.assertNotNil(Config.dev.debugMode, "Debug mode should exist")
        TestFramework.utils.assertNotNil(Config.dev.showFPS, "Show FPS should exist")
        TestFramework.utils.assertNotNil(Config.dev.showHitboxes, "Show hitboxes should exist")
        TestFramework.utils.assertNotNil(Config.dev.logLevel, "Log level should exist")
        TestFramework.utils.assertNotNil(Config.dev.autoSave, "Auto save should exist")
        
        TestFramework.utils.assertEqual("info", Config.dev.logLevel, "Default log level should be info")
        TestFramework.utils.assertTrue(Config.dev.autoSave, "Default auto save should be true")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Config System Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = require("tests.test_coverage")
    TestCoverage.updateModule("config", 8) -- All major functions tested
    
    return success
end

return {run = run} 