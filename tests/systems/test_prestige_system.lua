-- Test suite for Prestige System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup
Mocks.setup()
TestFramework.init()

-- Load system
local PrestigeSystem = Utils.require("src.systems.prestige_system")

-- Test helper functions
local function setupSystem()
    -- Reset prestige data by accessing the internal prestige table
    local prestige_data = PrestigeSystem.getData()
    prestige_data.level = 0
    prestige_data.stardust = 0
    prestige_data.total_stardust_earned = 0
    prestige_data.unlocked_benefits = {}
    prestige_data.visual_layers = {}
    prestige_data.nightmare_mode_unlocked = false
    prestige_data.prestige_shop_items = {}
    prestige_data.lifetime_stats = {
        total_prestiges = 0,
        total_levels_gained = 0,
        total_rings_collected = 0,
        perfect_landings = 0
    }
end

local function createMockPlayerStats(level)
    return {
        level = level or 50,
        total_score = 100000,
        rings_collected = 5000,
        perfect_landings = 200
    }
end

-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(data.level == 0, "Should start at prestige level 0")
        TestFramework.assert(data.stardust == 0, "Should start with 0 stardust")
        TestFramework.assert(data.total_stardust_earned == 0, "Should start with 0 total stardust")
        TestFramework.assert(#data.visual_layers == 0, "Should start with no visual layers")
        TestFramework.assert(data.nightmare_mode_unlocked == false, "Should start without nightmare mode")
        TestFramework.assert(type(data.prestige_shop_items) == "table", "Should initialize shop items")
        TestFramework.assert(type(data.lifetime_stats) == "table", "Should have lifetime stats")
        
        -- Check that shop items are initialized
        TestFramework.assert(data.prestige_shop_items["magnet_range"] ~= nil, "Should initialize magnet range item")
        TestFramework.assert(data.prestige_shop_items["magnet_range"].purchased == 0, "Shop items should start unpurchased")
        TestFramework.assert(data.prestige_shop_items["magnet_range"].active == false, "Shop items should start inactive")
    end,
    
    ["can prestige - valid level"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        TestFramework.assert(PrestigeSystem.canPrestige(50) == true, "Should allow prestige at level 50")
        TestFramework.assert(PrestigeSystem.canPrestige(51) == true, "Should allow prestige above level 50")
    end,
    
    ["can prestige - invalid level"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        TestFramework.assert(PrestigeSystem.canPrestige(49) == false, "Should not allow prestige below level 50")
        TestFramework.assert(PrestigeSystem.canPrestige(1) == false, "Should not allow prestige at low level")
    end,
    
    ["can prestige - max prestige reached"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        -- Set to max prestige level
        local data = PrestigeSystem.getData()
        data.level = 10 -- Max prestige level
        
        TestFramework.assert(PrestigeSystem.canPrestige(50) == false, "Should not allow prestige when at max level")
    end,
    
    ["prestige now - success"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local stats = createMockPlayerStats(50)
        local success, result = PrestigeSystem.prestigeNow(stats)
        
        TestFramework.assert(success == true, "Should succeed prestige")
        TestFramework.assert(type(result) == "table", "Should return result data")
        TestFramework.assert(result.new_level == 1, "Should set prestige level to 1")
        TestFramework.assert(result.stardust_earned == 500, "Should earn 500 stardust (50 * 10)")
        TestFramework.assert(result.total_stardust == 500, "Should have 500 total stardust")
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(data.level == 1, "Should update prestige level")
        TestFramework.assert(data.stardust == 500, "Should update stardust")
        TestFramework.assert(data.total_stardust_earned == 500, "Should track total earned")
        TestFramework.assert(data.nightmare_mode_unlocked == true, "Should unlock nightmare mode")
        TestFramework.assert(data.lifetime_stats.total_prestiges == 1, "Should update lifetime stats")
    end,
    
    ["prestige now - failure"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local stats = createMockPlayerStats(30) -- Below level 50
        local success, error_msg = PrestigeSystem.prestigeNow(stats)
        
        TestFramework.assert(success == false, "Should fail prestige")
        TestFramework.assert(type(error_msg) == "string", "Should return error message")
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(data.level == 0, "Should not change prestige level")
        TestFramework.assert(data.stardust == 0, "Should not change stardust")
    end,
    
    ["multiple prestiges"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        -- First prestige
        local stats = createMockPlayerStats(50)
        PrestigeSystem.prestigeNow(stats)
        
        -- Second prestige
        PrestigeSystem.prestigeNow(stats)
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(data.level == 2, "Should reach prestige level 2")
        TestFramework.assert(data.stardust == 1000, "Should have 1000 stardust (500 + 500)")
        TestFramework.assert(data.total_stardust_earned == 1000, "Should track total earned")
        TestFramework.assert(data.lifetime_stats.total_prestiges == 2, "Should update lifetime prestiges")
    end,
    
    ["visual layer unlocking"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local stats = createMockPlayerStats(50)
        local success, result = PrestigeSystem.prestigeNow(stats)
        
        TestFramework.assert(success == true, "Should succeed prestige")
        TestFramework.assert(result.unlocked_visual ~= nil, "Should unlock visual layer")
        TestFramework.assert(result.unlocked_visual.name == "Stardust Trail", "Should unlock correct visual for level 1")
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(#data.visual_layers == 1, "Should have one visual layer")
        TestFramework.assert(data.visual_layers[1].level == 1, "Visual layer should be for level 1")
    end,
    
    ["xp multiplier calculation"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        -- Level 0
        TestFramework.assert(PrestigeSystem.getXPMultiplier() == 1.0, "Should have 1.0x multiplier at level 0")
        
        -- Level 1
        local data = PrestigeSystem.getData()
        data.level = 1
        TestFramework.assert(PrestigeSystem.getXPMultiplier() == 1.1, "Should have 1.1x multiplier at level 1")
        
        -- Level 5
        data.level = 5
        TestFramework.assert(PrestigeSystem.getXPMultiplier() == 1.5, "Should have 1.5x multiplier at level 5")
    end,
    
    ["shop item purchase - success"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        -- Give some stardust
        local data = PrestigeSystem.getData()
        data.stardust = 200
        
        local success, result = PrestigeSystem.purchaseShopItem("magnet_range")
        
        TestFramework.assert(success == true, "Should succeed purchase")
        TestFramework.assert(type(result) == "table", "Should return result")
        TestFramework.assert(result.item.name == "Cosmic Magnetism", "Should return correct item")
        TestFramework.assert(result.remaining_stardust == 100, "Should deduct cost (200 - 100)")
        TestFramework.assert(type(result.effect) == "table", "Should return effect")
        TestFramework.assert(result.effect.type == "magnet_range", "Should have correct effect type")
        
        TestFramework.assert(data.stardust == 100, "Should update stardust")
        TestFramework.assert(data.prestige_shop_items["magnet_range"].purchased == 1, "Should increment purchase count")
        TestFramework.assert(data.prestige_shop_items["magnet_range"].active == true, "Should mark as active")
    end,
    
    ["shop item purchase - insufficient funds"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        -- Give insufficient stardust
        local data = PrestigeSystem.getData()
        data.stardust = 50 -- Need 100 for magnet_range
        
        local success, error_msg = PrestigeSystem.purchaseShopItem("magnet_range")
        
        TestFramework.assert(success == false, "Should fail purchase")
        TestFramework.assert(error_msg == "Not enough stardust", "Should return correct error")
        TestFramework.assert(data.stardust == 50, "Should not change stardust")
        TestFramework.assert(data.prestige_shop_items["magnet_range"].purchased == 0, "Should not increment purchase")
    end,
    
    ["shop item purchase - max purchases reached"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        data.stardust = 1000
        data.prestige_shop_items["magnet_range"].purchased = 5 -- Max purchases
        
        local success, error_msg = PrestigeSystem.purchaseShopItem("magnet_range")
        
        TestFramework.assert(success == false, "Should fail purchase")
        TestFramework.assert(error_msg == "Max purchases reached", "Should return correct error")
        TestFramework.assert(data.stardust == 1000, "Should not change stardust")
    end,
    
    ["shop item purchase - nonexistent item"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        data.stardust = 1000
        
        local success, error_msg = PrestigeSystem.purchaseShopItem("nonexistent_item")
        
        TestFramework.assert(success == false, "Should fail purchase")
        TestFramework.assert(error_msg == "Item not found", "Should return correct error")
        TestFramework.assert(data.stardust == 1000, "Should not change stardust")
    end,
    
    ["multiple shop purchases"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        data.stardust = 1000
        
        -- Purchase magnet_range twice
        PrestigeSystem.purchaseShopItem("magnet_range") -- Cost: 100
        PrestigeSystem.purchaseShopItem("magnet_range") -- Cost: 100
        
        TestFramework.assert(data.stardust == 800, "Should deduct both purchases")
        TestFramework.assert(data.prestige_shop_items["magnet_range"].purchased == 2, "Should track multiple purchases")
        
        -- Purchase different item
        PrestigeSystem.purchaseShopItem("perfect_window") -- Cost: 150
        
        TestFramework.assert(data.stardust == 650, "Should deduct different item cost")
        TestFramework.assert(data.prestige_shop_items["perfect_window"].purchased == 1, "Should track different item")
    end,
    
    ["active effects retrieval"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        data.stardust = 1000
        
        -- Purchase some items
        PrestigeSystem.purchaseShopItem("magnet_range")
        PrestigeSystem.purchaseShopItem("magnet_range")
        PrestigeSystem.purchaseShopItem("ring_multiplier")
        
        local effects = PrestigeSystem.getActiveEffects()
        
        TestFramework.assert(#effects == 2, "Should return 2 active effects")
        
        -- Find magnet effect
        local magnet_effect = nil
        for _, effect in ipairs(effects) do
            if effect.type == "magnet_range" then
                magnet_effect = effect
                break
            end
        end
        
        TestFramework.assert(magnet_effect ~= nil, "Should include magnet range effect")
        TestFramework.assert(magnet_effect.stacks == 2, "Should track multiple purchases as stacks")
        TestFramework.assert(magnet_effect.value == 0.2, "Should preserve effect value")
    end,
    
    ["active effects - no purchases"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local effects = PrestigeSystem.getActiveEffects()
        TestFramework.assert(#effects == 0, "Should return no effects when nothing purchased")
    end,
    
    ["nightmare mode check"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        TestFramework.assert(PrestigeSystem.getNightmareModeActive() == false, "Should start without nightmare mode")
        
        -- Unlock nightmare mode
        local data = PrestigeSystem.getData()
        data.nightmare_mode_unlocked = true
        
        TestFramework.assert(PrestigeSystem.getNightmareModeActive() == true, "Should return true when unlocked")
    end,
    
    ["data access"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(type(data) == "table", "Should return prestige data")
        TestFramework.assert(type(data.level) == "number", "Should include level")
        TestFramework.assert(type(data.stardust) == "number", "Should include stardust")
        TestFramework.assert(type(data.prestige_shop_items) == "table", "Should include shop items")
        TestFramework.assert(type(data.lifetime_stats) == "table", "Should include lifetime stats")
    end,
    
    ["prestige progression limits"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        local stats = createMockPlayerStats(50)
        
        -- Prestige to max level
        for i = 1, 10 do
            local success, result = PrestigeSystem.prestigeNow(stats)
            TestFramework.assert(success == true, "Should succeed prestige " .. i)
        end
        
        TestFramework.assert(data.level == 10, "Should reach max prestige level")
        
        -- Try to prestige beyond max
        local success, error_msg = PrestigeSystem.prestigeNow(stats)
        TestFramework.assert(success == false, "Should fail prestige beyond max")
        TestFramework.assert(data.level == 10, "Should remain at max level")
    end,
    
    ["stardust accumulation"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local stats1 = createMockPlayerStats(50)
        local stats2 = createMockPlayerStats(60)
        
        PrestigeSystem.prestigeNow(stats1) -- 500 stardust
        PrestigeSystem.prestigeNow(stats2) -- 600 stardust
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(data.stardust == 1100, "Should accumulate stardust from both prestiges")
        TestFramework.assert(data.total_stardust_earned == 1100, "Should track total earned")
        
        -- Spend some stardust
        PrestigeSystem.purchaseShopItem("magnet_range") -- Cost 100
        
        TestFramework.assert(data.stardust == 1000, "Should reduce current stardust")
        TestFramework.assert(data.total_stardust_earned == 1100, "Should not affect total earned")
    end,
    
    ["visual layer progression"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local stats = createMockPlayerStats(50)
        local data = PrestigeSystem.getData()
        
        -- Prestige to different levels to unlock different visuals
        PrestigeSystem.prestigeNow(stats) -- Level 1 - Stardust Trail
        TestFramework.assert(#data.visual_layers == 1, "Should have 1 visual layer")
        TestFramework.assert(data.visual_layers[1].name == "Stardust Trail", "Should unlock Stardust Trail")
        
        PrestigeSystem.prestigeNow(stats) -- Level 2 - Nebula Aura  
        TestFramework.assert(#data.visual_layers == 2, "Should have 2 visual layers")
        TestFramework.assert(data.visual_layers[2].name == "Nebula Aura", "Should unlock Nebula Aura")
        
        PrestigeSystem.prestigeNow(stats) -- Level 3 - Galaxy Swirl
        TestFramework.assert(#data.visual_layers == 3, "Should have 3 visual layers")
        TestFramework.assert(data.visual_layers[3].name == "Galaxy Swirl", "Should unlock Galaxy Swirl")
        
        -- Skip to level 5
        PrestigeSystem.prestigeNow(stats) -- Level 4 - no visual
        PrestigeSystem.prestigeNow(stats) -- Level 5 - Cosmic Crown
        TestFramework.assert(#data.visual_layers == 4, "Should have 4 visual layers")
        TestFramework.assert(data.visual_layers[4].name == "Cosmic Crown", "Should unlock Cosmic Crown")
    end,
    
    ["shop item effects structure"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        data.stardust = 1000
        
        -- Test each shop item
        local success, result = PrestigeSystem.purchaseShopItem("magnet_range")
        TestFramework.assert(result.effect.type == "magnet_range", "Magnet range should have correct type")
        TestFramework.assert(result.effect.value == 0.2, "Magnet range should have correct value")
        
        success, result = PrestigeSystem.purchaseShopItem("perfect_window")
        TestFramework.assert(result.effect.type == "perfect_window", "Perfect window should have correct type")
        TestFramework.assert(result.effect.value == 0.15, "Perfect window should have correct value")
        
        success, result = PrestigeSystem.purchaseShopItem("ring_multiplier")
        TestFramework.assert(result.effect.type == "ring_multiplier", "Ring multiplier should have correct type")
        TestFramework.assert(result.effect.value == 0.1, "Ring multiplier should have correct value")
        
        success, result = PrestigeSystem.purchaseShopItem("starting_boost")
        TestFramework.assert(result.effect.type == "starting_boost", "Starting boost should have correct type")
        TestFramework.assert(result.effect.value == 100, "Starting boost should have correct value")
        
        success, result = PrestigeSystem.purchaseShopItem("combo_keeper")
        TestFramework.assert(result.effect.type == "combo_shield", "Combo keeper should have correct type")
        TestFramework.assert(result.effect.value == 1, "Combo keeper should have correct value")
    end,
    
    ["lifetime stats tracking"] = function()
        setupSystem()
        PrestigeSystem.init()
        
        local data = PrestigeSystem.getData()
        TestFramework.assert(data.lifetime_stats.total_prestiges == 0, "Should start with 0 prestiges")
        
        local stats = createMockPlayerStats(50)
        PrestigeSystem.prestigeNow(stats)
        
        TestFramework.assert(data.lifetime_stats.total_prestiges == 1, "Should track first prestige")
        
        PrestigeSystem.prestigeNow(stats)
        
        TestFramework.assert(data.lifetime_stats.total_prestiges == 2, "Should track second prestige")
    end
}

-- Run tests
local function run()
    return TestFramework.runTests(tests, "Prestige System Tests")
end

return {run = run}