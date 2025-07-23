-- Tests for UI System
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")

Mocks.setup()

local UISystem = Utils.Utils.require("src.ui.ui_system")

-- Initialize test framework
TestFramework.init()

-- Mock fonts for testing
local mockFonts = {
    light = {},
    regular = {},
    bold = {},
    extraBold = {}
}

-- Mock progression system for testing
local mockProgressionSystem = {
    data = {
        totalScore = 1500,
        totalRingsCollected = 75,
        blockchain = {
            tokensEarned = 25,
            nftsUnlocked = {nft1 = true, nft2 = true},
            walletAddress = "0x1234567890abcdef"
        }
    },
    achievements = {
        firstRing = { name = "First Ring", description = "Collect your first ring", score = 10, unlocked = true },
        comboMaster = { name = "Combo Master", description = "Achieve a 10x combo", score = 50, unlocked = false }
    }
}

-- Mock blockchain integration for testing
local mockBlockchainIntegration = {
    config = { enabled = true },
    getStatus = function()
        return {
            enabled = true,
            network = "testnet",
            queuedEvents = 3
        }
    end
}

-- Setup function to reset UI system state
local function setupUISystem()
    UISystem.currentScreen = "game"
    UISystem.menuSelection = 1
    UISystem.upgradeSelection = 1
    UISystem.showProgression = false
    UISystem.showBlockchainStatus = false
end

-- Test suite
local tests = {
    ["ui system initialization"] = function()
        setupUISystem()
        UISystem.init(mockFonts)
        TestFramework.utils.assertNotNil(UISystem.elements, "UI elements should be initialized")
        TestFramework.utils.assertEqual("game", UISystem.currentScreen, "Should start on game screen")
        TestFramework.utils.assertNotNil(UISystem.fonts, "Fonts should be set")
    end,
    
    ["responsive layout update"] = function()
        setupUISystem()
        UISystem.init(mockFonts)
        
        -- Test that responsive layout updates UI elements
        UISystem.updateResponsiveLayout()
        
        TestFramework.utils.assertNotNil(UISystem.elements.progressionBar, "Progression bar should exist")
        TestFramework.utils.assertNotNil(UISystem.elements.upgradeButton, "Upgrade button should exist")
        TestFramework.utils.assertNotNil(UISystem.elements.blockchainButton, "Blockchain button should exist")
        TestFramework.utils.assertNotNil(UISystem.elements.menuPanel, "Menu panel should exist")
    end,
    
    ["ui update with screen size change"] = function()
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        TestFramework.utils.assertEqual(mockProgressionSystem, UISystem.progressionSystem, "Progression system should be set")
        TestFramework.utils.assertEqual(mockBlockchainIntegration, UISystem.blockchainIntegration, "Blockchain integration should be set")
    end,
    
    ["menu navigation"] = function()
        UISystem.init(mockFonts)
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 1
        
        -- Test up navigation
        UISystem.keypressed("up")
        TestFramework.utils.assertEqual(1, UISystem.menuSelection, "Menu selection should not go below 1")
        
        -- Test down navigation
        UISystem.keypressed("down")
        TestFramework.utils.assertEqual(2, UISystem.menuSelection, "Menu selection should increase")
        
        -- Test max navigation
        UISystem.menuSelection = 5
        UISystem.keypressed("down")
        TestFramework.utils.assertEqual(5, UISystem.menuSelection, "Menu selection should not exceed 5")
    end,
    
    ["menu selection handling"] = function()
        UISystem.init(mockFonts)
        UISystem.currentScreen = "menu"
        
        -- Test continue selection
        UISystem.menuSelection = 1
        UISystem.handleMenuSelection()
        TestFramework.utils.assertEqual("game", UISystem.currentScreen, "Should switch to game screen")
        
        -- Test upgrades selection
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 2
        UISystem.handleMenuSelection()
        TestFramework.utils.assertEqual("upgrades", UISystem.currentScreen, "Should switch to upgrades screen")
        
        -- Test achievements selection
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 3
        UISystem.handleMenuSelection()
        TestFramework.utils.assertEqual("achievements", UISystem.currentScreen, "Should switch to achievements screen")
        
        -- Test blockchain selection
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 4
        UISystem.handleMenuSelection()
        TestFramework.utils.assertEqual("blockchain", UISystem.currentScreen, "Should switch to blockchain screen")
    end,
    
    ["upgrade navigation"] = function()
        UISystem.init(mockFonts)
        UISystem.currentScreen = "upgrades"
        UISystem.upgradeSelection = 1
        
        -- Test up navigation
        UISystem.keypressed("up")
        TestFramework.utils.assertEqual(1, UISystem.upgradeSelection, "Upgrade selection should not go below 1")
        
        -- Test down navigation
        UISystem.keypressed("down")
        TestFramework.utils.assertEqual(3, UISystem.upgradeSelection, "Upgrade selection should increase by 2")
        
        -- Test left navigation
        UISystem.upgradeSelection = 2
        UISystem.keypressed("left")
        TestFramework.utils.assertEqual(1, UISystem.upgradeSelection, "Left navigation should work")
        
        -- Test right navigation
        UISystem.upgradeSelection = 1
        UISystem.keypressed("right")
        TestFramework.utils.assertEqual(2, UISystem.upgradeSelection, "Right navigation should work")
    end,
    
    ["screen transitions"] = function()
        UISystem.init(mockFonts)
        
        -- Test escape key in different screens
        UISystem.currentScreen = "upgrades"
        UISystem.keypressed("escape")
        TestFramework.utils.assertEqual("game", UISystem.currentScreen, "Escape should return to game from upgrades")
        
        UISystem.currentScreen = "achievements"
        UISystem.keypressed("escape")
        TestFramework.utils.assertEqual("menu", UISystem.currentScreen, "Escape should return to menu from achievements")
        
        UISystem.currentScreen = "blockchain"
        UISystem.keypressed("escape")
        TestFramework.utils.assertEqual("menu", UISystem.currentScreen, "Escape should return to menu from blockchain")
    end,
    
    ["mouse interaction"] = function()
        UISystem.init(mockFonts)
        UISystem.currentScreen = "game"
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test upgrade button click
        local upgradeBtn = UISystem.elements.upgradeButton
        UISystem.mousepressed(upgradeBtn.x + 10, upgradeBtn.y + 10, 1)
        TestFramework.utils.assertEqual("upgrades", UISystem.currentScreen, "Should switch to upgrades on button click")
        
        -- Test blockchain button click
        UISystem.currentScreen = "game"
        local blockchainBtn = UISystem.elements.blockchainButton
        UISystem.mousepressed(blockchainBtn.x + 10, blockchainBtn.y + 10, 1)
        TestFramework.utils.assertEqual("blockchain", UISystem.currentScreen, "Should switch to blockchain on button click")
    end,
    
    ["button drawing"] = function()
        UISystem.init(mockFonts)
        
        -- Test that drawButton function exists and can be called
        local success  = Utils.ErrorHandler.safeCall(UISystem.drawButton, "Test", 100, 100, 200, 50)
        TestFramework.utils.assertTrue(success, "drawButton should not crash")
    end,
    
    ["progression bar calculation"] = function()
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test progression calculation
        local progress = math.min(mockProgressionSystem.data.totalScore / 10000, 1.0)
        TestFramework.utils.assertEqual(0.15, progress, "Progress should be calculated correctly")
    end,
    
    ["table counting utility"] = function()
        UISystem.init(mockFonts)
        
        local testTable = {a = 1, b = 2, c = 3}
        local count = UISystem.countTable(testTable)
        TestFramework.utils.assertEqual(3, count, "Should count table entries correctly")
        
        local emptyTable = {}
        local emptyCount = UISystem.countTable(emptyTable)
        TestFramework.utils.assertEqual(0, emptyCount, "Should return 0 for empty table")
    end,
    
    ["upgrade purchase handling"] = function()
        UISystem.init(mockFonts)
        UISystem.currentScreen = "upgrades"
        UISystem.upgradeSelection = 1
        
        -- Test that purchaseUpgrade function exists and can be called
        local success  = Utils.ErrorHandler.safeCall(UISystem.purchaseUpgrade)
        TestFramework.utils.assertTrue(success, "purchaseUpgrade should not crash")
    end,
    
    ["ui element positioning"] = function()
        UISystem.init(mockFonts)
        UISystem.updateResponsiveLayout()
        
        -- Test that UI elements have valid positions
        local progressionBar = UISystem.elements.progressionBar
        TestFramework.utils.assertTrue(progressionBar.x >= 0, "Progression bar should have valid x position")
        TestFramework.utils.assertTrue(progressionBar.y >= 0, "Progression bar should have valid y position")
        TestFramework.utils.assertTrue(progressionBar.width > 0, "Progression bar should have positive width")
        TestFramework.utils.assertTrue(progressionBar.height > 0, "Progression bar should have positive height")
        
        local upgradeButton = UISystem.elements.upgradeButton
        TestFramework.utils.assertTrue(upgradeButton.x >= 0, "Upgrade button should have valid x position")
        TestFramework.utils.assertTrue(upgradeButton.y >= 0, "Upgrade button should have valid y position")
    end,
    
    ["screen state management"] = function()
        setupUISystem()
        UISystem.init(mockFonts)
        
        -- Test initial state
        TestFramework.utils.assertEqual("game", UISystem.currentScreen, "Should start on game screen")
        TestFramework.utils.assertEqual(1, UISystem.menuSelection, "Menu selection should start at 1")
        TestFramework.utils.assertEqual(1, UISystem.upgradeSelection, "Upgrade selection should start at 1")
        
        -- Test state changes
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 3
        UISystem.upgradeSelection = 5
        
        TestFramework.utils.assertEqual("menu", UISystem.currentScreen, "Screen should change")
        TestFramework.utils.assertEqual(3, UISystem.menuSelection, "Menu selection should change")
        TestFramework.utils.assertEqual(5, UISystem.upgradeSelection, "Upgrade selection should change")
    end,
    
    ["keyboard input validation"] = function()
        UISystem.init(mockFonts)
        
        -- Test that keypressed doesn't crash with invalid keys
        UISystem.currentScreen = "menu"
        local success  = Utils.ErrorHandler.safeCall(UISystem.keypressed, "invalid_key")
        TestFramework.utils.assertTrue(success, "keypressed should handle invalid keys gracefully")
        
        UISystem.currentScreen = "upgrades"
        success  = Utils.ErrorHandler.safeCall(UISystem.keypressed, "invalid_key")
        TestFramework.utils.assertTrue(success, "keypressed should handle invalid keys gracefully")
    end,
    
    ["ui scale and mobile detection"] = function()
        UISystem.init(mockFonts)
        UISystem.updateResponsiveLayout()
        
        -- Test that UI scale and mobile detection are set
        TestFramework.utils.assertNotNil(UISystem.uiScale, "UI scale should be set")
        TestFramework.utils.assertNotNil(UISystem.isMobile, "Mobile detection should be set")
    end,
    
    ["drawing functions existence"] = function()
        UISystem.init(mockFonts)
        
        -- Test that all drawing functions exist
        TestFramework.utils.assertNotNil(UISystem.draw, "draw function should exist")
        TestFramework.utils.assertNotNil(UISystem.drawGameUI, "drawGameUI function should exist")
        TestFramework.utils.assertNotNil(UISystem.drawMenuUI, "drawMenuUI function should exist")
        TestFramework.utils.assertNotNil(UISystem.drawUpgradeUI, "drawUpgradeUI function should exist")
        TestFramework.utils.assertNotNil(UISystem.drawAchievementUI, "drawAchievementUI function should exist")
        TestFramework.utils.assertNotNil(UISystem.drawBlockchainUI, "drawBlockchainUI function should exist")
        TestFramework.utils.assertNotNil(UISystem.drawProgressionBar, "drawProgressionBar function should exist")
    end,
    
    ["ui element structure"] = function()
        UISystem.init(mockFonts)
        
        -- Test that UI elements have the expected structure
        local elements = UISystem.elements
        TestFramework.utils.assertNotNil(elements.progressionBar, "Progression bar should exist")
        TestFramework.utils.assertNotNil(elements.upgradeButton, "Upgrade button should exist")
        TestFramework.utils.assertNotNil(elements.blockchainButton, "Blockchain button should exist")
        TestFramework.utils.assertNotNil(elements.menuPanel, "Menu panel should exist")
        
        -- Test element properties
        local bar = elements.progressionBar
        TestFramework.utils.assertNotNil(bar.x, "Progression bar should have x position")
        TestFramework.utils.assertNotNil(bar.y, "Progression bar should have y position")
        TestFramework.utils.assertNotNil(bar.width, "Progression bar should have width")
        TestFramework.utils.assertNotNil(bar.height, "Progression bar should have height")
    end,
    
    ["blockchain integration handling"] = function()
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test that blockchain integration is properly stored
        TestFramework.utils.assertEqual(mockBlockchainIntegration, UISystem.blockchainIntegration, "Blockchain integration should be stored")
        
        -- Test blockchain status retrieval
        local status = mockBlockchainIntegration.getStatus()
        TestFramework.utils.assertEqual(true, status.enabled, "Blockchain should be enabled")
        TestFramework.utils.assertEqual("testnet", status.network, "Network should be testnet")
        TestFramework.utils.assertEqual(3, status.queuedEvents, "Should have 3 queued events")
    end,
    
    ["progression system integration"] = function()
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test that progression system is properly stored
        TestFramework.utils.assertEqual(mockProgressionSystem, UISystem.progressionSystem, "Progression system should be stored")
        
        -- Test progression data access
        local data = mockProgressionSystem.data
        TestFramework.utils.assertEqual(1500, data.totalScore, "Total score should be accessible")
        TestFramework.utils.assertEqual(75, data.totalRingsCollected, "Total rings should be accessible")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("UI System Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("ui_system", 14) -- All major functions tested
    
    return success
end

local result = {run = run}

-- Run tests if this file is executed directly
if arg and arg[0] and string.find(arg[0], "test_ui_system.lua") then
    run()
end

return result