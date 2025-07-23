-- Tests for Blockchain Integration
package.path = package.path .. ";../../?.lua"

local TestFramework = require("tests.test_framework")
local Mocks = require("tests.mocks")

Mocks.setup()

local BlockchainIntegration = require("src.blockchain.blockchain_integration")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["blockchain initialization"] = function()
        BlockchainIntegration.init()
        TestFramework.utils.assertNotNil(BlockchainIntegration.events, "Events queue should be initialized")
        TestFramework.utils.assertFalse(BlockchainIntegration.connected, "Should not be connected initially")
    end,
    
    ["connect to blockchain"] = function()
        BlockchainIntegration.init()
        
        local success = pcall(function()
            BlockchainIntegration.connect("test-wallet-address")
        end)
        TestFramework.utils.assertTrue(success, "Connection attempt should not crash")
    end,
    
    ["track game event"] = function()
        BlockchainIntegration.init()
        
        local event = {
            type = "ring_collected",
            timestamp = os.time(),
            data = {
                ringType = "power",
                value = 100
            }
        }
        
        BlockchainIntegration.trackEvent(event)
        TestFramework.utils.assertTrue(#BlockchainIntegration.events > 0, "Event should be tracked")
    end,
    
    ["mint NFT achievement"] = function()
        BlockchainIntegration.init()
        
        local achievement = {
            id = "first_1000_rings",
            name = "Ring Master",
            description = "Collected 1000 rings",
            rarity = "rare"
        }
        
        local success = pcall(function()
            BlockchainIntegration.mintAchievementNFT(achievement)
        end)
        TestFramework.utils.assertTrue(success, "NFT minting should not crash")
    end,
    
    ["record high score"] = function()
        BlockchainIntegration.init()
        
        local success = pcall(function()
            BlockchainIntegration.recordHighScore(50000, "player123")
        end)
        TestFramework.utils.assertTrue(success, "Recording high score should not crash")
    end,
    
    ["token rewards calculation"] = function()
        BlockchainIntegration.init()
        
        local score = 10000
        local combo = 50
        local tokens = BlockchainIntegration.calculateTokenRewards(score, combo)
        
        TestFramework.utils.assertTrue(tokens > 0, "Should calculate positive token rewards")
        TestFramework.utils.assertTrue(tokens >= score / 1000, "Token rewards should scale with score")
    end,
    
    ["claim token rewards"] = function()
        BlockchainIntegration.init()
        
        local tokens = 100
        local success = pcall(function()
            BlockchainIntegration.claimTokens(tokens, "player123")
        end)
        TestFramework.utils.assertTrue(success, "Claiming tokens should not crash")
    end,
    
    ["leaderboard integration"] = function()
        BlockchainIntegration.init()
        
        -- Submit some scores
        BlockchainIntegration.submitToLeaderboard("player1", 5000)
        BlockchainIntegration.submitToLeaderboard("player2", 8000)
        BlockchainIntegration.submitToLeaderboard("player3", 3000)
        
        local leaderboard = BlockchainIntegration.getLeaderboard(10)
        TestFramework.utils.assertNotNil(leaderboard, "Should return leaderboard data")
    end,
    
    ["verify NFT ownership"] = function()
        BlockchainIntegration.init()
        
        local hasNFT = BlockchainIntegration.checkNFTOwnership("player123", "achievement_nft_001")
        TestFramework.utils.assertNotNil(hasNFT, "Should return ownership status")
    end,
    
    ["transaction history"] = function()
        BlockchainIntegration.init()
        
        -- Create some transactions
        BlockchainIntegration.trackEvent({type = "token_earned", amount = 50})
        BlockchainIntegration.trackEvent({type = "nft_minted", id = "nft_001"})
        
        local history = BlockchainIntegration.getTransactionHistory("player123")
        TestFramework.utils.assertNotNil(history, "Should return transaction history")
    end,
    
    ["gas fee estimation"] = function()
        BlockchainIntegration.init()
        
        local fee = BlockchainIntegration.estimateGasFee("mint_nft")
        TestFramework.utils.assertTrue(fee >= 0, "Gas fee should be non-negative")
    end,
    
    ["blockchain sync status"] = function()
        BlockchainIntegration.init()
        
        local status = BlockchainIntegration.getSyncStatus()
        TestFramework.utils.assertNotNil(status, "Should return sync status")
        TestFramework.utils.assertNotNil(status.connected, "Status should have connected field")
        TestFramework.utils.assertNotNil(status.pendingTransactions, "Status should have pending transactions")
    end,
    
    ["smart contract interaction"] = function()
        BlockchainIntegration.init()
        
        local success = pcall(function()
            BlockchainIntegration.callSmartContract("GameRewards", "claimDailyBonus", {})
        end)
        TestFramework.utils.assertTrue(success, "Smart contract call should not crash")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Blockchain Integration Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = require("tests.test_coverage")
    TestCoverage.updateModule("blockchain_integration", 12) -- All major functions tested
    
    return success
end

return {run = run}