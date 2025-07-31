--[[
    Warp Core System: Core Warp Mechanics and State Management
    
    This module handles the core warp drive functionality including
    warp state, animations, particles, and the actual warping process.
--]]

local Utils = require("src.utils.utils")
local WarpCore = {}

-- Core warp state
WarpCore.isUnlocked = false
WarpCore.isWarping = false
WarpCore.warpTarget = nil
WarpCore.warpProgress = 0
WarpCore.warpDuration = 2.0 -- 2 seconds for warp animation

-- Visual effects state
WarpCore.warpEffectAlpha = 0
WarpCore.tunnelRotation = 0
WarpCore.particles = {}

-- Initialize core systems
function WarpCore.init()
    WarpCore.isUnlocked = false
    WarpCore.isWarping = false
    WarpCore.warpTarget = nil
    WarpCore.warpProgress = 0
    WarpCore.particles = {}
end

-- Unlock warp drive
function WarpCore.unlock()
    WarpCore.isUnlocked = true
    
    -- Achievement
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem and AchievementSystem.onWarpDriveUnlocked then
        AchievementSystem.onWarpDriveUnlocked()
    end
    
    Utils.Logger.info("Warp Drive unlocked!")
end

-- Start warp sequence
function WarpCore.startWarpSequence(targetPlanet)
    WarpCore.isWarping = true
    WarpCore.warpTarget = targetPlanet
    WarpCore.warpProgress = 0
    WarpCore.warpEffectAlpha = 0
end

-- Update warp animation and state
function WarpCore.update(dt, player)
    -- Update warp animation
    if WarpCore.isWarping then
        WarpCore.warpProgress = WarpCore.warpProgress + dt / WarpCore.warpDuration
        
        -- Update effect alpha
        if WarpCore.warpProgress < 0.5 then
            WarpCore.warpEffectAlpha = WarpCore.warpProgress * 2
        else
            WarpCore.warpEffectAlpha = (1 - WarpCore.warpProgress) * 2
        end
        
        -- Rotate tunnel effect
        WarpCore.tunnelRotation = WarpCore.tunnelRotation + dt * 5
        
        -- Check if warp is complete
        if WarpCore.warpProgress >= 1 then
            return true -- Warp complete
        end
    else
        -- Fade out effects when not warping
        if WarpCore.warpEffectAlpha > 0 then
            WarpCore.warpEffectAlpha = math.max(0, WarpCore.warpEffectAlpha - dt * 2)
        end
    end
    
    -- Update particles
    WarpCore.updateParticles(dt)
    
    return false -- Warp not complete
end

-- Create warp particles
function WarpCore.createWarpParticles(player, cost)
    -- More particles for higher cost warps
    local particleCount = math.floor(20 + cost / 10)
    
    for i = 1, particleCount do
        local angle = (i / particleCount) * math.pi * 2
        local speed = 100 + math.random() * 200
        
        table.insert(WarpCore.particles, {
            x = player.x,
            y = player.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 1.0,
            size = 2 + math.random() * 3,
            color = {0.5 + math.random() * 0.5, 0.7, 1}
        })
    end
end

-- Update particles
function WarpCore.updateParticles(dt)
    for i = #WarpCore.particles, 1, -1 do
        local p = WarpCore.particles[i]
        
        -- Update position
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        
        -- Update life
        p.life = p.life - dt
        
        -- Remove dead particles
        if p.life <= 0 then
            table.remove(WarpCore.particles, i)
        end
    end
end

-- Complete warp
function WarpCore.completeWarp(player)
    if not WarpCore.warpTarget then return end
    
    -- Teleport player
    player.x = WarpCore.warpTarget.x
    player.y = WarpCore.warpTarget.y
    player.vx = 0
    player.vy = 0
    
    -- Reset warp state
    WarpCore.isWarping = false
    WarpCore.warpTarget = nil
    WarpCore.warpProgress = 0
    
    -- Achievement tracking
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem and AchievementSystem.onWarpComplete then
        AchievementSystem.onWarpComplete()
    end
    
    -- Create arrival particles
    for i = 1, 30 do
        local angle = (i / 30) * math.pi * 2
        local speed = 50 + math.random() * 100
        
        table.insert(WarpCore.particles, {
            x = player.x,
            y = player.y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.5,
            size = 1 + math.random() * 2,
            color = {0.7, 0.9, 1}
        })
    end
end

-- Draw warp effects
function WarpCore.drawEffects(player)
    if WarpCore.warpEffectAlpha <= 0 and #WarpCore.particles == 0 then return end
    
    -- Draw warp tunnel effect
    if WarpCore.warpEffectAlpha > 0 then
        love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(WarpCore.tunnelRotation)
        
        -- Tunnel rings
        for i = 1, 10 do
            local radius = i * 100
            local alpha = WarpCore.warpEffectAlpha * (1 - i / 10) * 0.5
            Utils.setColor({0.5, 0.7, 1}, alpha)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", 0, 0, radius)
        end
        
        love.graphics.pop()
    end
    
    -- Draw particles
    for _, p in ipairs(WarpCore.particles) do
        Utils.setColor(p.color, p.life * 0.8)
        love.graphics.circle("fill", p.x, p.y, p.size * p.life)
    end
end

-- Draw warp progress UI
function WarpCore.drawProgressUI()
    if not WarpCore.isWarping then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Warping text
    Utils.setColor({1, 1, 1}, WarpCore.warpEffectAlpha)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("WARPING...", 0, screenHeight / 2 - 50, screenWidth, "center")
    
    -- Progress bar
    local progBarWidth = 300
    local progBarHeight = 10
    local progBarX = (screenWidth - progBarWidth) / 2
    local progBarY = screenHeight / 2
    
    -- Background
    Utils.setColor({0.2, 0.2, 0.2}, WarpCore.warpEffectAlpha * 0.5)
    love.graphics.rectangle("fill", progBarX, progBarY, progBarWidth, progBarHeight, 3)
    
    -- Progress
    Utils.setColor({0.5, 0.7, 1}, WarpCore.warpEffectAlpha)
    love.graphics.rectangle("fill", progBarX, progBarY, 
        progBarWidth * WarpCore.warpProgress, progBarHeight, 3)
    
    -- Border
    Utils.setColor({0.7, 0.9, 1}, WarpCore.warpEffectAlpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", progBarX, progBarY, progBarWidth, progBarHeight, 3)
end

-- Get core status
function WarpCore.getStatus()
    return {
        isUnlocked = WarpCore.isUnlocked,
        isWarping = WarpCore.isWarping,
        warpTarget = WarpCore.warpTarget,
        warpProgress = WarpCore.warpProgress,
        particleCount = #WarpCore.particles
    }
end

-- Play warp sound
function WarpCore.playWarpSound(cost)
    -- Adaptive sound based on warp cost
    local pitch = 0.8 + (cost / 500) * 0.4 -- Higher cost = higher pitch
    
    -- Play warp initiation sound
    -- This would be implemented with actual sound files
    Utils.Logger.debug("🔊 Playing warp sound with pitch: %.2f", pitch)
end

return WarpCore