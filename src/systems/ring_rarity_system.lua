-- Ring Rarity System - The Slot Machine Dopamine Engine
-- Creates unpredictable rewards that trigger the strongest addiction patterns
local Utils = require("src.utils.utils")
local RingRaritySystem = {}
-- Rarity definitions with spawn rates
RingRaritySystem.RARITIES = {
    standard = {
        name = "Standard",
        chance = 0.85, -- 85%
        points = 10,
        xpBonus = 0,
        color = {0.5, 0.8, 1}, -- Light blue
        glowIntensity = 1.0,
        particleCount = 5,
        soundPitch = 1.0,
        screenEffect = "none"
    },
    silver = {
        name = "Silver",
        chance = 0.12, -- 12%
        points = 25,
        xpBonus = 2,
        color = {0.9, 0.9, 1}, -- Silver
        glowIntensity = 1.5,
        particleCount = 12,
        soundPitch = 1.2,
        screenEffect = "sparkle"
    },
    gold = {
        name = "Gold",
        chance = 0.025, -- 2.5%
        points = 100,
        xpBonus = 8,
        color = {1, 0.8, 0}, -- Gold
        glowIntensity = 2.0,
        particleCount = 25,
        soundPitch = 1.5,
        screenEffect = "flash"
    },
    legendary = {
        name = "Legendary",
        chance = 0.005, -- 0.5%
        points = 500,
        xpBonus = 25,
        color = {1, 0.2, 1}, -- Magenta
        glowIntensity = 3.0,
        particleCount = 50,
        soundPitch = 2.0,
        screenEffect = "fireworks"
    }
}
-- Visual effects state
RingRaritySystem.glowPhase = 0
RingRaritySystem.collectionEffects = {}
RingRaritySystem.screenEffects = {}
-- Statistics tracking
RingRaritySystem.stats = {
    standard = 0,
    silver = 0,
    gold = 0,
    legendary = 0,
    totalCollected = 0,
    lastLegendary = 0 -- Time since last legendary
}
-- Initialize ring rarity system
function RingRaritySystem.init()
    RingRaritySystem.loadStats()
    Utils.Logger.info("Ring Rarity System initialized - Legendary rings collected: %d",
                      RingRaritySystem.stats.legendary)
    return true
end
-- Update ring rarity system
function RingRaritySystem.update(dt)
    -- Update visual effects
    RingRaritySystem.glowPhase = RingRaritySystem.glowPhase + dt * 3
    -- Update collection effects
    for i = #RingRaritySystem.collectionEffects, 1, -1 do
        local effect = RingRaritySystem.collectionEffects[i]
        effect.timer = effect.timer + dt
        effect.alpha = math.max(0, 1 - effect.timer / effect.duration)
        effect.scale = 1 + effect.timer * 2
        if effect.timer >= effect.duration then
            table.remove(RingRaritySystem.collectionEffects, i)
        end
    end
    -- Update screen effects
    for i = #RingRaritySystem.screenEffects, 1, -1 do
        local effect = RingRaritySystem.screenEffects[i]
        effect.timer = effect.timer + dt
        effect.intensity = math.max(0, 1 - effect.timer / effect.duration)
        if effect.timer >= effect.duration then
            table.remove(RingRaritySystem.screenEffects, i)
        end
    end
    -- Update time since last legendary
    RingRaritySystem.stats.lastLegendary = RingRaritySystem.stats.lastLegendary + dt
end
-- Determine ring rarity when spawning
function RingRaritySystem.determineRarity()
    local roll = math.random()
    local cumulativeChance = 0
    -- Check from rarest to most common
    local rarityOrder = {"legendary", "gold", "silver", "standard"}
    for _, rarityName in ipairs(rarityOrder) do
        local rarity = RingRaritySystem.RARITIES[rarityName]
        cumulativeChance = cumulativeChance + rarity.chance
        if roll <= cumulativeChance then
            -- Apply bad luck protection for legendary rings
            if rarityName == "legendary" then
                return RingRaritySystem.applyBadLuckProtection(rarityName)
            end
            return rarityName
        end
    end
    return "standard" -- Fallback
end
-- Bad luck protection for legendary rings
function RingRaritySystem.applyBadLuckProtection(baseRarity)
    -- Increase legendary chance if it's been too long
    local timeSinceLastLegendary = RingRaritySystem.stats.lastLegendary
    local badLuckThreshold = 300 -- 5 minutes
    if baseRarity ~= "legendary" and timeSinceLastLegendary > badLuckThreshold then
        -- Force a legendary ring if player has been unlucky too long
        local forcedChance = math.min(0.1, (timeSinceLastLegendary - badLuckThreshold) / 600)
        if math.random() < forcedChance then
            Utils.Logger.info("Bad luck protection triggered - forced legendary ring")
            return "legendary"
        end
    end
    return baseRarity
end
-- Apply rarity properties to a ring
function RingRaritySystem.applyRarityToRing(ring, rarityName)
    rarityName = rarityName or "standard"
    local rarity = RingRaritySystem.RARITIES[rarityName]
    if not rarity then
        rarityName = "standard"
        rarity = RingRaritySystem.RARITIES.standard
    end
    -- Apply rarity properties
    ring.rarity = rarityName
    ring.rarityData = rarity
    ring.points = rarity.points
    ring.color = rarity.color
    ring.glowIntensity = rarity.glowIntensity
    ring.originalRadius = ring.radius
    return ring
end
-- Handle ring collection with rarity effects
function RingRaritySystem.onRingCollected(ring, player, gameState)
    if not ring.rarity then
        ring.rarity = "standard"
        ring.rarityData = RingRaritySystem.RARITIES.standard
    end
    local rarity = ring.rarityData
    -- Update statistics
    RingRaritySystem.stats[ring.rarity] = RingRaritySystem.stats[ring.rarity] + 1
    RingRaritySystem.stats.totalCollected = RingRaritySystem.stats.totalCollected + 1
    if ring.rarity == "legendary" then
        RingRaritySystem.stats.lastLegendary = 0 -- Reset timer
    end
    -- Award bonus XP
    if rarity.xpBonus > 0 then
        local XPSystem = Utils.require("src.systems.xp_system")
        if XPSystem then
            XPSystem.addXP(rarity.xpBonus, "rare_ring", ring.x, ring.y)
        end
    end
    -- Create collection effect
    RingRaritySystem.createCollectionEffect(ring, rarity)
    -- Create screen effect for rare rings
    if rarity.screenEffect ~= "none" then
        RingRaritySystem.createScreenEffect(rarity.screenEffect, rarity)
    end
    -- Play enhanced sound
    RingRaritySystem.playRaritySound(rarity)
    -- Show rarity notification
    RingRaritySystem.showRarityNotification(ring, rarity)
    -- Save statistics
    RingRaritySystem.saveStats()
    Utils.Logger.info("Collected %s ring worth %d points (+%d XP)",
                      ring.rarity, rarity.points, rarity.xpBonus)
    return rarity.points
end
-- Create collection effect
function RingRaritySystem.createCollectionEffect(ring, rarity)
    table.insert(RingRaritySystem.collectionEffects, {
        x = ring.x,
        y = ring.y,
        rarity = rarity,
        timer = 0,
        duration = 2.0,
        alpha = 1.0,
        scale = 1.0,
        particleCount = rarity.particleCount
    })
end
-- Create screen effect
function RingRaritySystem.createScreenEffect(effectType, rarity)
    local duration = 0.5
    if effectType == "flash" then duration = 0.8 end
    if effectType == "fireworks" then duration = 2.0 end
    table.insert(RingRaritySystem.screenEffects, {
        type = effectType,
        rarity = rarity,
        timer = 0,
        duration = duration,
        intensity = 1.0
    })
end
-- Play rarity-specific sound
function RingRaritySystem.playRaritySound(rarity)
    -- This would integrate with the sound system
    -- For now, just log the intended sound
    Utils.Logger.debug("Playing %s ring sound at pitch %.1f", rarity.name, rarity.soundPitch)
end
-- Show rarity notification
function RingRaritySystem.showRarityNotification(ring, rarity)
    if rarity.name == "Standard" then return end -- Don't show for common rings
    -- This would create a popup notification
    Utils.Logger.info("RARE RING: %s! (+%d points, +%d XP)",
                      rarity.name, rarity.points, rarity.xpBonus)
end
-- Draw ring with rarity effects
function RingRaritySystem.drawRing(ring, camera)
    if not ring.rarity then return end
    local rarity = ring.rarityData or RingRaritySystem.RARITIES.standard
    local screenX, screenY = camera:worldToScreen(ring.x, ring.y)
    -- Enhanced glow for rare rings
    if rarity.glowIntensity > 1.0 then
        local pulse = math.sin(RingRaritySystem.glowPhase + ring.x * 0.01) * 0.3 + 1
        local glowRadius = ring.radius * rarity.glowIntensity * pulse
        -- Outer glow
        Utils.setColor(rarity.color, 0.3 * pulse)
        love.graphics.circle("fill", screenX, screenY, glowRadius)
        -- Inner glow
        Utils.setColor(rarity.color, 0.6 * pulse)
        love.graphics.circle("fill", screenX, screenY, glowRadius * 0.7)
    end
    -- Main ring with rarity color
    Utils.setColor(rarity.color, 0.9)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", screenX, screenY, ring.radius)
    love.graphics.setLineWidth(1)
    -- Sparkle effect for rare rings
    if rarity.glowIntensity >= 2.0 then
        RingRaritySystem.drawSparkles(screenX, screenY, ring.radius, rarity)
    end
end
-- Draw sparkle effects around rare rings
function RingRaritySystem.drawSparkles(x, y, radius, rarity)
    local sparkleCount = math.floor(rarity.glowIntensity * 3)
    for i = 1, sparkleCount do
        local angle = (i / sparkleCount) * math.pi * 2 + RingRaritySystem.glowPhase
        local sparkleRadius = radius + 15 + math.sin(RingRaritySystem.glowPhase * 2 + i) * 10
        local sparkleX = x + math.cos(angle) * sparkleRadius
        local sparkleY = y + math.sin(angle) * sparkleRadius
        local alpha = (math.sin(RingRaritySystem.glowPhase * 3 + i) + 1) / 2
        Utils.setColor(rarity.color, alpha * 0.8)
        love.graphics.circle("fill", sparkleX, sparkleY, 2)
    end
end
-- Draw collection effects
function RingRaritySystem.drawCollectionEffects(camera)
    for _, effect in ipairs(RingRaritySystem.collectionEffects) do
        local screenX, screenY = camera:worldToScreen(effect.x, effect.y)
        -- Expanding ring effect
        Utils.setColor(effect.rarity.color, effect.alpha * 0.6)
        love.graphics.setLineWidth(3)
        love.graphics.circle("line", screenX, screenY, 50 * effect.scale)
        love.graphics.setLineWidth(1)
        -- Particle burst
        local particleRadius = 30 * effect.scale
        for i = 1, effect.particleCount do
            local angle = (i / effect.particleCount) * math.pi * 2
            local px = screenX + math.cos(angle) * particleRadius
            local py = screenY + math.sin(angle) * particleRadius
            Utils.setColor(effect.rarity.color, effect.alpha)
            love.graphics.circle("fill", px, py, 3)
        end
    end
end
-- Draw screen effects
function RingRaritySystem.drawScreenEffects(screenWidth, screenHeight)
    for _, effect in ipairs(RingRaritySystem.screenEffects) do
        if effect.type == "sparkle" then
            RingRaritySystem.drawSparkleScreen(screenWidth, screenHeight, effect)
        elseif effect.type == "flash" then
            RingRaritySystem.drawFlashScreen(screenWidth, screenHeight, effect)
        elseif effect.type == "fireworks" then
            RingRaritySystem.drawFireworksScreen(screenWidth, screenHeight, effect)
        end
    end
end
-- Draw sparkle screen effect
function RingRaritySystem.drawSparkleScreen(screenWidth, screenHeight, effect)
    local alpha = effect.intensity * 0.4
    Utils.setColor(effect.rarity.color, alpha)
    -- Random sparkles across screen
    for i = 1, 20 do
        local x = math.random(0, screenWidth)
        local y = math.random(0, screenHeight)
        local size = math.random(2, 6)
        love.graphics.circle("fill", x, y, size)
    end
end
-- Draw flash screen effect
function RingRaritySystem.drawFlashScreen(screenWidth, screenHeight, effect)
    local alpha = effect.intensity * 0.3
    Utils.setColor(effect.rarity.color, alpha)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
end
-- Draw fireworks screen effect
function RingRaritySystem.drawFireworksScreen(screenWidth, screenHeight, effect)
    -- Multiple explosion points
    local explosions = 3
    for i = 1, explosions do
        local centerX = screenWidth * (0.2 + i * 0.3)
        local centerY = screenHeight * 0.3
        local radius = 100 * effect.intensity
        -- Radiating lines
        for j = 1, 12 do
            local angle = (j / 12) * math.pi * 2
            local lineLength = radius * (0.5 + math.sin(effect.timer * 10 + j) * 0.5)
            local endX = centerX + math.cos(angle) * lineLength
            local endY = centerY + math.sin(angle) * lineLength
            Utils.setColor(effect.rarity.color, effect.intensity * 0.8)
            love.graphics.setLineWidth(3)
            love.graphics.line(centerX, centerY, endX, endY)
            love.graphics.setLineWidth(1)
        end
    end
end
-- Draw rarity statistics UI
function RingRaritySystem.drawStats(x, y)
    local offsetY = 0
    -- Title
    Utils.setColor({1, 1, 1}, 0.9)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.print("Ring Collection Stats", x, y + offsetY)
    offsetY = offsetY + 25
    -- Statistics for each rarity
    for _, rarityName in ipairs({"standard", "silver", "gold", "legendary"}) do
        local rarity = RingRaritySystem.RARITIES[rarityName]
        local count = RingRaritySystem.stats[rarityName]
        local percentage = RingRaritySystem.stats.totalCollected > 0 and
                          (count / RingRaritySystem.stats.totalCollected * 100) or 0
        -- Rarity color
        Utils.setColor(rarity.color, 0.8)
        love.graphics.setFont(love.graphics.newFont(12))
        love.graphics.print(string.format("%s: %d (%.1f%%)",
                           rarity.name, count, percentage), x, y + offsetY)
        offsetY = offsetY + 18
    end
    -- Total
    offsetY = offsetY + 5
    Utils.setColor({1, 1, 1}, 0.7)
    love.graphics.print(string.format("Total: %d rings", RingRaritySystem.stats.totalCollected),
                       x, y + offsetY)
    -- Time since last legendary
    if RingRaritySystem.stats.legendary > 0 then
        offsetY = offsetY + 18
        local timeSinceText = string.format("Last legendary: %.0fs ago", RingRaritySystem.stats.lastLegendary)
        Utils.setColor({1, 0.2, 1}, 0.7)
        love.graphics.print(timeSinceText, x, y + offsetY)
    end
end
-- Save/Load statistics
function RingRaritySystem.saveStats()
    local saveData = Utils.serialize(RingRaritySystem.stats)
    love.filesystem.write("ring_rarity_stats.dat", saveData)
end
function RingRaritySystem.loadStats()
    if love.filesystem.getInfo("ring_rarity_stats.dat") then
        local data = love.filesystem.read("ring_rarity_stats.dat")
        local loadedStats = Utils.deserialize(data)
        if loadedStats then
            for key, value in pairs(loadedStats) do
                RingRaritySystem.stats[key] = value
            end
        end
    end
end
-- Getters
function RingRaritySystem.getStats()
    return RingRaritySystem.stats
end
function RingRaritySystem.getRarityChance(rarityName)
    local rarity = RingRaritySystem.RARITIES[rarityName]
    return rarity and rarity.chance or 0
end
function RingRaritySystem.getRarityData(rarityName)
    return RingRaritySystem.RARITIES[rarityName]
end
return RingRaritySystem