-- Prestige System for Galaxy-wide progression resets with permanent benefits
local PrestigeSystem = {}
local prestige = {
    level = 0,
    stardust = 0,
    total_stardust_earned = 0,
    unlocked_benefits = {},
    visual_layers = {},
    nightmare_mode_unlocked = false,
    prestige_shop_items = {},
    lifetime_stats = {
        total_prestiges = 0,
        total_levels_gained = 0,
        total_rings_collected = 0,
        perfect_landings = 0
    }
}
-- Prestige benefits configuration
local PRESTIGE_BENEFITS = {
    xp_multiplier = 0.1, -- +10% XP per prestige level
    stardust_per_level = 10, -- Stardust earned when prestiging
    unlock_nightmare_at = 1, -- First prestige unlocks nightmare mode
    max_prestige_level = 10
}
-- Prestige shop items
local PRESTIGE_SHOP = {
    {
        id = "magnet_range",
        name = "Cosmic Magnetism",
        description = "Increase ring magnet range by 20%",
        cost = 100,
        max_purchases = 5,
        effect = function()
            -- Will be applied in game.lua
            return {type = "magnet_range", value = 0.2}
        end
    },
    {
        id = "perfect_window",
        name = "Precision Master",
        description = "Increase perfect landing window by 15%",
        cost = 150,
        max_purchases = 3,
        effect = function()
            return {type = "perfect_window", value = 0.15}
        end
    },
    {
        id = "ring_multiplier",
        name = "Ring Baron",
        description = "All rings worth 10% more points",
        cost = 200,
        max_purchases = 5,
        effect = function()
            return {type = "ring_multiplier", value = 0.1}
        end
    },
    {
        id = "starting_boost",
        name = "Head Start",
        description = "Start each game with 100 bonus points",
        cost = 50,
        max_purchases = 10,
        effect = function()
            return {type = "starting_boost", value = 100}
        end
    },
    {
        id = "combo_keeper",
        name = "Combo Shield",
        description = "Keep combo for 1 extra miss",
        cost = 300,
        max_purchases = 1,
        effect = function()
            return {type = "combo_shield", value = 1}
        end
    }
}
-- Visual layers for prestige levels
local VISUAL_LAYERS = {
    {level = 1, name = "Stardust Trail", color = {0.8, 0.8, 1, 0.5}},
    {level = 2, name = "Nebula Aura", color = {0.9, 0.7, 1, 0.4}},
    {level = 3, name = "Galaxy Swirl", color = {0.7, 0.9, 1, 0.6}},
    {level = 5, name = "Cosmic Crown", color = {1, 0.9, 0.7, 0.7}},
    {level = 7, name = "Universe Echo", color = {1, 1, 1, 0.8}},
    {level = 10, name = "Infinity Halo", color = {1, 0.8, 1, 0.9}}
}
function PrestigeSystem.init()
    -- Initialize prestige shop
    for _, item in ipairs(PRESTIGE_SHOP) do
        prestige.prestige_shop_items[item.id] = {
            purchased = 0,
            active = false
        }
    end
    -- Load saved prestige data
    PrestigeSystem.loadData()
end
function PrestigeSystem.canPrestige(player_level)
    -- Can prestige at max level (50) and haven't reached max prestige
    return player_level >= 50 and prestige.level < PRESTIGE_BENEFITS.max_prestige_level
end
function PrestigeSystem.prestigeNow(player_stats)
    if not PrestigeSystem.canPrestige(player_stats.level) then
        return false, "Cannot prestige yet"
    end
    -- Calculate stardust earned
    local stardust_earned = PRESTIGE_BENEFITS.stardust_per_level * player_stats.level
    prestige.stardust = prestige.stardust + stardust_earned
    prestige.total_stardust_earned = prestige.total_stardust_earned + stardust_earned
    -- Update prestige level
    prestige.level = prestige.level + 1
    prestige.lifetime_stats.total_prestiges = prestige.level
    -- Unlock nightmare mode at first prestige
    if prestige.level >= PRESTIGE_BENEFITS.unlock_nightmare_at then
        prestige.nightmare_mode_unlocked = true
    end
    -- Add visual layers
    for _, layer in ipairs(VISUAL_LAYERS) do
        if layer.level == prestige.level then
            table.insert(prestige.visual_layers, layer)
        end
    end
    -- Save prestige data
    PrestigeSystem.saveData()
    -- Track for feedback system
    local Utils = require("src.utils.utils")
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        FeedbackSystem.recordEvent("prestige_unlock", {
            prestige_level = prestige.level,
            player_level = player_stats.level,
            stardust_earned = stardust_earned,
            nightmare_mode_unlocked = prestige.nightmare_mode_unlocked
        })
    end
    return true, {
        new_level = prestige.level,
        stardust_earned = stardust_earned,
        total_stardust = prestige.stardust,
        unlocked_visual = prestige.visual_layers[#prestige.visual_layers]
    }
end
function PrestigeSystem.getXPMultiplier()
    return 1 + (prestige.level * PRESTIGE_BENEFITS.xp_multiplier)
end
function PrestigeSystem.purchaseShopItem(item_id)
    local item = nil
    for _, shop_item in ipairs(PRESTIGE_SHOP) do
        if shop_item.id == item_id then
            item = shop_item
            break
        end
    end
    if not item then
        return false, "Item not found"
    end
    local purchased = prestige.prestige_shop_items[item_id].purchased
    -- Check if can purchase
    if purchased >= item.max_purchases then
        return false, "Max purchases reached"
    end
    if prestige.stardust < item.cost then
        return false, "Not enough stardust"
    end
    -- Make purchase
    prestige.stardust = prestige.stardust - item.cost
    prestige.prestige_shop_items[item_id].purchased = purchased + 1
    prestige.prestige_shop_items[item_id].active = true
    -- Save data
    PrestigeSystem.saveData()
    return true, {
        item = item,
        effect = item.effect(),
        remaining_stardust = prestige.stardust
    }
end
function PrestigeSystem.getActiveEffects()
    local effects = {}
    for _, item in ipairs(PRESTIGE_SHOP) do
        local purchase_data = prestige.prestige_shop_items[item.id]
        if purchase_data.active and purchase_data.purchased > 0 then
            local effect = item.effect()
            effect.stacks = purchase_data.purchased
            table.insert(effects, effect)
        end
    end
    return effects
end
function PrestigeSystem.draw()
    -- Draw prestige visual layers
    for _, layer in ipairs(prestige.visual_layers) do
        love.graphics.setColor(layer.color)
        -- Draw background effect based on layer type
        if layer.name == "Stardust Trail" then
            -- Particle trail effect
            local time = love.timer.getTime()
            for i = 1, 20 do
                local x = love.graphics.getWidth() * (i / 20)
                local y = love.graphics.getHeight() / 2 + math.sin(time + i) * 50
                love.graphics.circle("fill", x, y, 2)
            end
        elseif layer.name == "Nebula Aura" then
            -- Swirling nebula effect
            love.graphics.push()
            love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
            love.graphics.rotate(love.timer.getTime() * 0.1)
            love.graphics.rectangle("fill", -300, -2, 600, 4)
            love.graphics.pop()
        elseif layer.name == "Galaxy Swirl" then
            -- Spiral galaxy effect
            local segments = 50
            for i = 1, segments do
                local angle = (i / segments) * math.pi * 4
                local radius = (i / segments) * 200
                local x = love.graphics.getWidth() / 2 + math.cos(angle + love.timer.getTime() * 0.5) * radius
                local y = love.graphics.getHeight() / 2 + math.sin(angle + love.timer.getTime() * 0.5) * radius
                love.graphics.circle("fill", x, y, 3)
            end
        end
    end
    -- Draw prestige level indicator
    if prestige.level > 0 then
        love.graphics.setColor(1, 0.9, 0, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.print("★" .. prestige.level, love.graphics.getWidth() - 100, 10)
        -- Draw stardust counter
        love.graphics.setColor(0.8, 0.8, 1, 1)
        love.graphics.setFont(love.graphics.newFont(18))
        love.graphics.print("✦ " .. prestige.stardust, love.graphics.getWidth() - 100, 40)
    end
end
function PrestigeSystem.drawPrestigeMenu()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    -- Title
    love.graphics.setColor(1, 0.9, 0, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("GALAXY PRESTIGE", 0, 50, love.graphics.getWidth(), "center")
    -- Current prestige level
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Prestige Level: " .. prestige.level .. " / " .. PRESTIGE_BENEFITS.max_prestige_level,
        0, 120, love.graphics.getWidth(), "center")
    -- Benefits
    love.graphics.printf("Current Benefits:", 100, 180, love.graphics.getWidth() - 200, "left")
    love.graphics.setFont(love.graphics.newFont(18))
    local y = 220
    love.graphics.printf("• +" .. (prestige.level * 10) .. "% XP Gain", 120, y, love.graphics.getWidth() - 240, "left")
    y = y + 30
    if prestige.nightmare_mode_unlocked then
        love.graphics.printf("• Nightmare Mode Unlocked (3x rewards)", 120, y, love.graphics.getWidth() - 240, "left")
        y = y + 30
    end
    for _, layer in ipairs(prestige.visual_layers) do
        love.graphics.printf("• " .. layer.name .. " Visual Effect", 120, y, love.graphics.getWidth() - 240, "left")
        y = y + 30
    end
    -- Prestige button or info
    if PrestigeSystem.canPrestige(50) then -- Assuming we're at max level
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 100, 400, 200, 50)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("PRESTIGE NOW", love.graphics.getWidth() / 2 - 100, 410, 200, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.printf("Reset to Level 1, Keep All Cosmetics, Earn " .. (50 * PRESTIGE_BENEFITS.stardust_per_level) .. " Stardust",
            0, 470, love.graphics.getWidth(), "center")
    end
end
function PrestigeSystem.drawPrestigeShop()
    -- Shop UI
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", 100, 100, love.graphics.getWidth() - 200, love.graphics.getHeight() - 200)
    -- Title
    love.graphics.setColor(0.8, 0.8, 1, 1)
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.printf("PRESTIGE SHOP", 100, 120, love.graphics.getWidth() - 200, "center")
    -- Stardust display
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Stardust: ✦ " .. prestige.stardust, 100, 170, love.graphics.getWidth() - 200, "center")
    -- Shop items
    local y = 220
    love.graphics.setFont(love.graphics.newFont(18))
    for _, item in ipairs(PRESTIGE_SHOP) do
        local purchase_data = prestige.prestige_shop_items[item.id]
        local can_afford = prestige.stardust >= item.cost
        local can_purchase = purchase_data.purchased < item.max_purchases
        -- Item background
        if can_afford and can_purchase then
            love.graphics.setColor(0.2, 0.3, 0.4, 1)
        else
            love.graphics.setColor(0.1, 0.1, 0.1, 1)
        end
        love.graphics.rectangle("fill", 120, y, love.graphics.getWidth() - 240, 80)
        -- Item name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(item.name, 140, y + 10)
        -- Item description
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.setFont(love.graphics.newFont(14))
        love.graphics.print(item.description, 140, y + 35)
        -- Purchase info
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("Cost: ✦ " .. item.cost, love.graphics.getWidth() - 340, y + 10)
        love.graphics.print(purchase_data.purchased .. "/" .. item.max_purchases, love.graphics.getWidth() - 340, y + 35)
        y = y + 90
    end
end
function PrestigeSystem.getNightmareModeActive()
    return prestige.nightmare_mode_unlocked
end
function PrestigeSystem.saveData()
    local save_data = {
        prestige = prestige
    }
    love.filesystem.write("prestige_save.lua", TSerial.pack(save_data))
end
function PrestigeSystem.loadData()
    if love.filesystem.getInfo("prestige_save.lua") then
        local contents = love.filesystem.read("prestige_save.lua")
        local save_data = TSerial.unpack(contents)
        if save_data and save_data.prestige then
            prestige = save_data.prestige
            -- Reinitialize shop items if needed
            for _, item in ipairs(PRESTIGE_SHOP) do
                if not prestige.prestige_shop_items[item.id] then
                    prestige.prestige_shop_items[item.id] = {
                        purchased = 0,
                        active = false
                    }
                end
            end
        end
    end
end
function PrestigeSystem.getData()
    return prestige
end
return PrestigeSystem