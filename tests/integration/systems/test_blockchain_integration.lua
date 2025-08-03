-- Tests for Blockchain Integration
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
local BlockchainIntegration = Utils.require("src.blockchain.blockchain_integration")
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    ["blockchain initialization"] = function()
        -- Reset config to default state
        BlockchainIntegration.config.enabled = false
        BlockchainIntegration.init()
        TestFramework.assert.assertNotNil(BlockchainIntegration.eventQueue, "Event queue should be initialized")
        TestFramework.assert.assertFalse(BlockchainIntegration.config.enabled, "Should not be enabled initially")
    end,
    ["enable and disable blockchain"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        TestFramework.assert.assertTrue(BlockchainIntegration.config.enabled, "Should be enabled")
        BlockchainIntegration.disable()
        TestFramework.assert.assertFalse(BlockchainIntegration.config.enabled, "Should be disabled")
    end,
    ["queue event"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable() -- Enable blockchain to allow queuing
        local event = {
            type = BlockchainIntegration.eventTypes.ACHIEVEMENT_UNLOCKED,
            data = {
                achievementId = "first_ring",
                score = 100
            }
        }
        BlockchainIntegration.queueEvent(event.type, event.data)
        TestFramework.assert.assertTrue(#BlockchainIntegration.eventQueue > 0, "Event should be queued")
    end,
    ["generate event id"] = function()
        -- Store original timer function
        local originalGetTime = love.timer.getTime
        local timeCounter = 5500
        -- Mock timer to return incrementing values
        love.timer.getTime = function()
            timeCounter = timeCounter + 1
            return timeCounter
        end
        local id1 = BlockchainIntegration.generateEventId()
        local id2 = BlockchainIntegration.generateEventId()
        -- Restore original timer
        love.timer.getTime = originalGetTime
        TestFramework.assert.assertNotNil(id1, "Should generate first ID")
        TestFramework.assert.assertNotNil(id2, "Should generate second ID")
        TestFramework.assert.assertNotEqual(id1, id2, "IDs should be unique: " .. tostring(id1) .. " vs " .. tostring(id2))
    end,
    ["trigger achievement unlock"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        BlockchainIntegration.triggerAchievementUnlock("speed_demon", 500)
        TestFramework.assert.assertTrue(#BlockchainIntegration.eventQueue > 0, "Achievement event should be queued")
        local event = BlockchainIntegration.eventQueue[1]
        TestFramework.assert.assertEqual(BlockchainIntegration.eventTypes.ACHIEVEMENT_UNLOCKED, event.type, "Event type should match")
        TestFramework.assert.assertEqual("speed_demon", event.data.achievement, "Achievement ID should match")
        TestFramework.assert.assertEqual(500, event.data.score, "Score should match")
    end,
    ["trigger token earned"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        BlockchainIntegration.triggerTokenEarned(100, "combo_bonus")
        TestFramework.assert.assertTrue(#BlockchainIntegration.eventQueue > 0, "Token event should be queued")
        local event = BlockchainIntegration.eventQueue[1]
        TestFramework.assert.assertEqual(BlockchainIntegration.eventTypes.TOKENS_EARNED, event.type, "Event type should match")
        TestFramework.assert.assertEqual(100, event.data.amount, "Amount should match")
        TestFramework.assert.assertEqual("combo_bonus", event.data.reason, "Reason should match")
    end,
    ["trigger NFT unlock"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        local metadata = {
            name = "Origin Fragment",
            description = "A mysterious artifact",
            attributes = {rarity = "legendary"}
        }
        BlockchainIntegration.triggerNFTUnlock("origin_fragment_1", metadata)
        TestFramework.assert.assertTrue(#BlockchainIntegration.eventQueue > 0, "NFT event should be queued")
        local event = BlockchainIntegration.eventQueue[1]
        TestFramework.assert.assertEqual(BlockchainIntegration.eventTypes.NFT_UNLOCKED, event.type, "Event type should match")
        TestFramework.assert.assertEqual("origin_fragment_1", event.data.nftId, "NFT ID should match")
    end,
    ["trigger upgrade purchase"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        BlockchainIntegration.triggerUpgradePurchase("jump_power", 150, 3)
        TestFramework.assert.assertTrue(#BlockchainIntegration.eventQueue > 0, "Upgrade event should be queued")
        local event = BlockchainIntegration.eventQueue[1]
        TestFramework.assert.assertEqual(BlockchainIntegration.eventTypes.UPGRADE_PURCHASED, event.type, "Event type should match")
        TestFramework.assert.assertEqual("jump_power", event.data.upgrade, "Upgrade type should match")
        TestFramework.assert.assertEqual(150, event.data.cost, "Cost should match")
        TestFramework.assert.assertEqual(3, event.data.newLevel, "New level should match")
    end,
    ["trigger high score"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        BlockchainIntegration.triggerHighScore(10000, 15, 250)
        TestFramework.assert.assertTrue(#BlockchainIntegration.eventQueue > 0, "High score event should be queued")
        local event = BlockchainIntegration.eventQueue[1]
        TestFramework.assert.assertEqual(BlockchainIntegration.eventTypes.HIGH_SCORE_SET, event.type, "Event type should match")
        TestFramework.assert.assertEqual(10000, event.data.score, "Score should match")
        TestFramework.assert.assertEqual(15, event.data.combo, "Combo should match")
        TestFramework.assert.assertEqual(250, event.data.ringsCollected, "Rings should match")
    end,
    ["events not queued when disabled"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.disable()
        BlockchainIntegration.triggerAchievementUnlock("test", 100)
        TestFramework.assert.assertEqual(0, #BlockchainIntegration.eventQueue, "Event should not be queued when disabled")
    end,
    ["batch processing check"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        -- Add some events
        BlockchainIntegration.triggerTokenEarned(50, "test1")
        BlockchainIntegration.triggerTokenEarned(100, "test2")
        -- Set last batch time to trigger processing
        BlockchainIntegration.lastBatchTime = love.timer.getTime() - BlockchainIntegration.batchInterval - 1
        BlockchainIntegration.checkBatchProcessing()
        -- Events should be processed and cleared
        TestFramework.assert.assertEqual(0, #BlockchainIntegration.eventQueue, "Queue should be cleared after batch processing")
    end,
    ["update function"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        -- Add an event
        BlockchainIntegration.triggerTokenEarned(50, "test")
        -- Update should check batch processing
        local success = pcall(function()
            BlockchainIntegration.update(0.016)
        end)
        TestFramework.assert.assertTrue(success, "Update should not error")
    end,
    ["get status"] = function()
        BlockchainIntegration.init()
        BlockchainIntegration.enable()
        -- Add some events
        BlockchainIntegration.triggerTokenEarned(50, "test1")
        BlockchainIntegration.triggerAchievementUnlock("test2", 200)
        local status = BlockchainIntegration.getStatus()
        TestFramework.assert.assertTrue(status.enabled, "Status should show enabled")
        TestFramework.assert.assertEqual(2, status.queuedEvents, "Should show 2 queued events")
        TestFramework.assert.assertNotNil(status.lastBatchTime, "Should have last batch time")
    end
}
-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Blockchain Integration Tests")
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("blockchain_integration", 12) -- All major functions tested
    return success
end
return {run = run}