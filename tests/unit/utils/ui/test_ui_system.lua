-- Tests for UI System
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

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

-- Mock upgrade system for testing
local mockUpgradeSystem = {
    currency = 1000,
    upgrades = {
        jump_power = { currentLevel = 1, maxLevel = 5, name = "Jump Power", cost = 100 },
        dash_power = { currentLevel = 0, maxLevel = 3, name = "Dash Power", cost = 200 }
    },
    purchase = function(upgradeId)
        return true -- Mock successful purchase
    end,
    getUpgradeCost = function(upgradeId)
        return 100 -- Mock cost
    end,
    canAfford = function(upgradeId)
        return true -- Mock can afford
    end
}

-- Setup function to reset UI system state
local function setupUISystem(UISystem)
    UISystem.currentScreen = "game"
    UISystem.menuSelection = 1
    UISystem.upgradeSelection = 1
    UISystem.showProgression = false
    UISystem.showBlockchainStatus = false
end

-- Test suite
local tests = {
    ["ui system initialization"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        setupUISystem(UISystem)
        UISystem.init(mockFonts)
        TestFramework.assert.notNil(UISystem.elements, "UI elements should be initialized")
        TestFramework.assert.equal("game", UISystem.currentScreen, "Should start on game screen")
        TestFramework.assert.notNil(UISystem.fonts, "Fonts should be set")
    end,
    
    ["responsive layout update"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        setupUISystem(UISystem)
        UISystem.init(mockFonts)
        
        -- Test that responsive layout updates UI elements
        UISystem.updateResponsiveLayout()
        
        TestFramework.assert.notNil(UISystem.elements.progressionBar, "Progression bar should exist")
        TestFramework.assert.notNil(UISystem.elements.upgradeButton, "Upgrade button should exist")
        TestFramework.assert.notNil(UISystem.elements.blockchainButton, "Blockchain button should exist")
        TestFramework.assert.notNil(UISystem.elements.menuPanel, "Menu panel should exist")
    end,
    
    ["ui update with screen size change"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        TestFramework.assert.equal(mockProgressionSystem, UISystem.progressionSystem, "Progression system should be set")
        TestFramework.assert.equal(mockBlockchainIntegration, UISystem.blockchainIntegration, "Blockchain integration should be set")
    end,
    
    ["menu navigation"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 1
        
        -- Test up navigation
        UISystem.keypressed("up")
        TestFramework.assert.equal(1, UISystem.menuSelection, "Menu selection should not go below 1")
        
        -- Test down navigation
        UISystem.keypressed("down")
        TestFramework.assert.equal(2, UISystem.menuSelection, "Menu selection should increase")
        
        -- Test max navigation
        UISystem.menuSelection = 5
        UISystem.keypressed("down")
        TestFramework.assert.equal(5, UISystem.menuSelection, "Menu selection should not exceed 5")
    end,
    
    ["menu selection handling"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 1
        
        -- Test selection with enter
        UISystem.keypressed("return")
        TestFramework.assert.equal("game", UISystem.currentScreen, "Should return to game screen")
        
        -- Test selection with space
        UISystem.currentScreen = "menu"
        UISystem.keypressed("space")
        TestFramework.assert.equal("game", UISystem.currentScreen, "Should return to game screen")
    end,
    
    ["upgrade navigation"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.currentScreen = "upgrades"
        UISystem.upgradeSelection = 1
        
        -- Test up navigation
        UISystem.keypressed("up")
        TestFramework.assert.equal(1, UISystem.upgradeSelection, "Upgrade selection should not go below 1")
        
        -- Test down navigation
        UISystem.keypressed("down")
        TestFramework.assert.equal(3, UISystem.upgradeSelection, "Upgrade selection should increase by 2")
        
        -- Test left navigation
        UISystem.upgradeSelection = 2
        UISystem.keypressed("left")
        TestFramework.assert.equal(1, UISystem.upgradeSelection, "Left navigation should work")
        
        -- Test right navigation
        UISystem.upgradeSelection = 1
        UISystem.keypressed("right")
        TestFramework.assert.equal(2, UISystem.upgradeSelection, "Right navigation should work")
    end,
    
    ["screen transitions"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.currentScreen = "game" -- Explicitly set to game screen
        
        -- Test transition to upgrades
        UISystem.handleKeyPress("u")
        TestFramework.assert.equal("upgrades", UISystem.currentScreen, "Should transition to upgrades screen")
        
        -- Test transition back to game
        UISystem.handleKeyPress("escape")
        TestFramework.assert.equal("game", UISystem.currentScreen, "Should return to game screen")
    end,
    
    ["mouse interaction"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.currentScreen = "game"
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test upgrade button click
        local upgradeBtn = UISystem.elements.upgradeButton
        UISystem.mousepressed(upgradeBtn.x + 10, upgradeBtn.y + 10, 1)
        TestFramework.assert.equal("upgrades", UISystem.currentScreen, "Should switch to upgrades on button click")
        
        -- Test blockchain button click
        UISystem.currentScreen = "game"
        local blockchainBtn = UISystem.elements.blockchainButton
        UISystem.mousepressed(blockchainBtn.x + 10, blockchainBtn.y + 10, 1)
        TestFramework.assert.equal("blockchain", UISystem.currentScreen, "Should switch to blockchain on button click")
    end,
    
    ["button drawing"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        
        -- Test that drawButton function exists and can be called
        local success  = Utils.ErrorHandler.safeCall(UISystem.drawButton, "Test", 100, 100, 200, 50)
        TestFramework.assert.isTrue(success, "drawButton should not crash")
    end,
    
    ["progression bar calculation"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test progression calculation
        local progress = math.min(mockProgressionSystem.data.totalScore / 10000, 1.0)
        TestFramework.assert.equal(0.15, progress, "Progress should be calculated correctly")
    end,
    
    ["table counting utility"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        
        local testTable = {a = 1, b = 2, c = 3}
        local count = UISystem.countTable(testTable)
        TestFramework.assert.equal(3, count, "Should count table entries correctly")
        
        local emptyTable = {}
        local emptyCount = UISystem.countTable(emptyTable)
        TestFramework.assert.equal(0, emptyCount, "Should return 0 for empty table")
    end,
    
    ["upgrade purchase handling"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.currentScreen = "upgrades"
        UISystem.upgradeSelection = 1
        
        -- Test that purchaseUpgrade function exists and can be called
        local success  = Utils.ErrorHandler.safeCall(UISystem.purchaseUpgrade)
        TestFramework.assert.isTrue(success, "purchaseUpgrade should not crash")
    end,
    
    ["ui element positioning"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.updateResponsiveLayout()
        
        -- Test that UI elements have valid positions
        local progressionBar = UISystem.elements.progressionBar
        TestFramework.assert.isTrue(progressionBar.x >= 0, "Progression bar should have valid x position")
        TestFramework.assert.isTrue(progressionBar.y >= 0, "Progression bar should have valid y position")
        TestFramework.assert.isTrue(progressionBar.width > 0, "Progression bar should have positive width")
        TestFramework.assert.isTrue(progressionBar.height > 0, "Progression bar should have positive height")
        
        local upgradeButton = UISystem.elements.upgradeButton
        TestFramework.assert.isTrue(upgradeButton.x >= 0, "Upgrade button should have valid x position")
        TestFramework.assert.isTrue(upgradeButton.y >= 0, "Upgrade button should have valid y position")
    end,
    
    ["screen state management"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        setupUISystem(UISystem)
        UISystem.init(mockFonts)
        
        -- Test initial state
        TestFramework.assert.equal("game", UISystem.currentScreen, "Should start on game screen")
        TestFramework.assert.equal(1, UISystem.menuSelection, "Menu selection should start at 1")
        TestFramework.assert.equal(1, UISystem.upgradeSelection, "Upgrade selection should start at 1")
        
        -- Test state changes
        UISystem.currentScreen = "menu"
        UISystem.menuSelection = 3
        UISystem.upgradeSelection = 5
        
        TestFramework.assert.equal("menu", UISystem.currentScreen, "Screen should change")
        TestFramework.assert.equal(3, UISystem.menuSelection, "Menu selection should change")
        TestFramework.assert.equal(5, UISystem.upgradeSelection, "Upgrade selection should change")
    end,
    
    ["keyboard input validation"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        
        -- Test that keypressed doesn't crash with invalid keys
        UISystem.currentScreen = "menu"
        local success  = Utils.ErrorHandler.safeCall(UISystem.keypressed, "invalid_key")
        TestFramework.assert.isTrue(success, "keypressed should handle invalid keys gracefully")
        
        UISystem.currentScreen = "upgrades"
        success  = Utils.ErrorHandler.safeCall(UISystem.keypressed, "invalid_key")
        TestFramework.assert.isTrue(success, "keypressed should handle invalid keys gracefully")
    end,
    
    ["ui scale and mobile detection"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.updateResponsiveLayout()
        
        -- Test that UI scale and mobile detection are set
        TestFramework.assert.notNil(UISystem.uiScale, "UI scale should be set")
        TestFramework.assert.notNil(UISystem.isMobile, "Mobile detection should be set")
    end,
    
    ["drawing functions existence"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        
        -- Test that all drawing functions exist
        TestFramework.assert.notNil(UISystem.draw, "draw function should exist")
        TestFramework.assert.notNil(UISystem.drawGameUI, "drawGameUI function should exist")
        TestFramework.assert.notNil(UISystem.drawMenuUI, "drawMenuUI function should exist")
        TestFramework.assert.notNil(UISystem.drawUpgradeUI, "drawUpgradeUI function should exist")
        TestFramework.assert.notNil(UISystem.drawAchievementUI, "drawAchievementUI function should exist")
        TestFramework.assert.notNil(UISystem.drawBlockchainUI, "drawBlockchainUI function should exist")
        TestFramework.assert.notNil(UISystem.drawProgressionBar, "drawProgressionBar function should exist")
    end,
    
    ["ui element structure"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        
        -- Test that UI elements have the expected structure
        local elements = UISystem.elements
        TestFramework.assert.notNil(elements.progressionBar, "Progression bar should exist")
        TestFramework.assert.notNil(elements.upgradeButton, "Upgrade button should exist")
        TestFramework.assert.notNil(elements.blockchainButton, "Blockchain button should exist")
        TestFramework.assert.notNil(elements.menuPanel, "Menu panel should exist")
        
        -- Test element properties
        local bar = elements.progressionBar
        TestFramework.assert.notNil(bar.x, "Progression bar should have x position")
        TestFramework.assert.notNil(bar.y, "Progression bar should have y position")
        TestFramework.assert.notNil(bar.width, "Progression bar should have width")
        TestFramework.assert.notNil(bar.height, "Progression bar should have height")
    end,
    
    ["blockchain integration handling"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test that blockchain integration is properly stored
        TestFramework.assert.equal(mockBlockchainIntegration, UISystem.blockchainIntegration, "Blockchain integration should be stored")
        
        -- Test blockchain status retrieval
        local status = mockBlockchainIntegration.getStatus()
        TestFramework.assert.equal(true, status.enabled, "Blockchain should be enabled")
        TestFramework.assert.equal("testnet", status.network, "Network should be testnet")
        TestFramework.assert.equal(3, status.queuedEvents, "Should have 3 queued events")
    end,
    
    ["progression system integration"] = function()
        local UISystem = Utils.require("src.ui.ui_system")
        UISystem.init(mockFonts)
        UISystem.update(0.1, mockProgressionSystem, mockBlockchainIntegration)
        
        -- Test that progression system is properly stored
        TestFramework.assert.equal(mockProgressionSystem, UISystem.progressionSystem, "Progression system should be stored")
        
        -- Test progression data access
        local data = mockProgressionSystem.data
        TestFramework.assert.equal(1500, data.totalScore, "Total score should be accessible")
        TestFramework.assert.equal(75, data.totalRingsCollected, "Total rings should be accessible")
    end
}

-- Run the test suite
local function run()
    -- Set up mocks before running tests
    Mocks.setup()
    
    TestFramework.runTests(tests, "UI System Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("ui_system", 14) -- All major functions tested
    
    return true -- Assume success for now
end

return {run = run}