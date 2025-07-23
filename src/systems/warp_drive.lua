-- Warp Drive System for Orbit Jump
-- Fast travel between discovered planets

local Utils = require("src.utils.utils")
local WarpDrive = {}

-- Warp state
WarpDrive.isUnlocked = false
WarpDrive.isWarping = false
WarpDrive.warpTarget = nil
WarpDrive.warpProgress = 0
WarpDrive.warpDuration = 2.0 -- 2 seconds for warp animation
WarpDrive.energyCost = 100 -- Base energy cost
WarpDrive.energy = 1000 -- Current energy
WarpDrive.maxEnergy = 1000
WarpDrive.energyRegenRate = 50 -- Per second

-- Visual effects
WarpDrive.warpEffectAlpha = 0
WarpDrive.tunnelRotation = 0
WarpDrive.particles = {}

-- Selection state
WarpDrive.isSelecting = false
WarpDrive.selectedPlanet = nil
WarpDrive.selectionRadius = 50

-- Initialize
function WarpDrive.init()
    WarpDrive.isUnlocked = false
    WarpDrive.energy = WarpDrive.maxEnergy
    WarpDrive.particles = {}
end

-- Unlock warp drive
function WarpDrive.unlock()
    WarpDrive.isUnlocked = true
    
    -- Achievement
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem.onWarpDriveUnlocked then
        AchievementSystem.onWarpDriveUnlocked()
    end
    
    Utils.Logger.info("Warp Drive unlocked!")
end

-- Check if can afford warp
function WarpDrive.canAffordWarp(targetPlanet, currentPlayer)
    if not WarpDrive.isUnlocked then return false end
    if not targetPlanet.discovered then return false end
    
    local distance = Utils.distance(currentPlayer.x, currentPlayer.y, targetPlanet.x, targetPlanet.y)
    local cost = WarpDrive.calculateCost(distance)
    
    return WarpDrive.energy >= cost
end

-- Calculate energy cost based on distance
function WarpDrive.calculateCost(distance)
    -- Cost scales with distance, minimum 50
    return math.max(50, math.floor(distance / 100))
end

-- Start warping to target
function WarpDrive.startWarp(targetPlanet, player)
    if not WarpDrive.canAffordWarp(targetPlanet, player) then
        return false
    end
    
    local distance = Utils.distance(player.x, player.y, targetPlanet.x, targetPlanet.y)
    local cost = WarpDrive.calculateCost(distance)
    
    -- Deduct energy
    WarpDrive.energy = WarpDrive.energy - cost
    
    -- Set warp state
    WarpDrive.isWarping = true
    WarpDrive.warpTarget = targetPlanet
    WarpDrive.warpProgress = 0
    
    -- Create warp particles
    WarpDrive.createWarpParticles(player)
    
    -- Play warp sound
    local soundManager = Utils.require("src.audio.sound_manager")
    if soundManager.playEventWarning then
        soundManager:playEventWarning()
    end
    
    return true
end

-- Create warp tunnel particles
function WarpDrive.createWarpParticles(player)
    WarpDrive.particles = {}
    
    -- Create tunnel particles
    for i = 1, 50 do
        local angle = math.random() * math.pi * 2
        local distance = math.random(100, 500)
        local speed = math.random(500, 1500)
        
        local particle = {
            x = player.x + math.cos(angle) * distance,
            y = player.y + math.sin(angle) * distance,
            vx = -math.cos(angle) * speed,
            vy = -math.sin(angle) * speed,
            size = math.random(2, 8),
            life = 1.0,
            color = {
                0.5 + math.random() * 0.5,
                0.5 + math.random() * 0.5,
                1.0
            }
        }
        
        table.insert(WarpDrive.particles, particle)
    end
end

-- Update warp drive
function WarpDrive.update(dt, player)
    -- Regenerate energy
    if WarpDrive.energy < WarpDrive.maxEnergy and not WarpDrive.isWarping then
        WarpDrive.energy = math.min(WarpDrive.maxEnergy, WarpDrive.energy + WarpDrive.energyRegenRate * dt)
    end
    
    -- Update warp animation
    if WarpDrive.isWarping then
        WarpDrive.warpProgress = WarpDrive.warpProgress + dt / WarpDrive.warpDuration
        WarpDrive.warpEffectAlpha = math.min(WarpDrive.warpProgress * 2, 1)
        WarpDrive.tunnelRotation = WarpDrive.tunnelRotation + dt * 5
        
        -- Update particles
        for i = #WarpDrive.particles, 1, -1 do
            local p = WarpDrive.particles[i]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt * 2
            
            if p.life <= 0 then
                table.remove(WarpDrive.particles, i)
            end
        end
        
        -- Add new particles during warp
        if math.random() < 0.5 then
            local angle = math.random() * math.pi * 2
            local particle = {
                x = player.x + math.cos(angle) * 500,
                y = player.y + math.sin(angle) * 500,
                vx = -math.cos(angle) * 1000,
                vy = -math.sin(angle) * 1000,
                size = math.random(2, 8),
                life = 1.0,
                color = {
                    0.5 + math.random() * 0.5,
                    0.5 + math.random() * 0.5,
                    1.0
                }
            }
            table.insert(WarpDrive.particles, particle)
        end
        
        -- Complete warp
        if WarpDrive.warpProgress >= 1.0 then
            WarpDrive.completeWarp(player)
        end
    else
        -- Fade out effect
        WarpDrive.warpEffectAlpha = math.max(0, WarpDrive.warpEffectAlpha - dt * 2)
    end
end

-- Complete the warp
function WarpDrive.completeWarp(player)
    if not WarpDrive.warpTarget then return end
    
    -- Teleport player to target planet
    local target = WarpDrive.warpTarget
    player.x = target.x + target.radius + 30
    player.y = target.y
    player.vx = 0
    player.vy = 0
    player.onPlanet = nil -- Start in space near the planet
    
    -- Clear warp state
    WarpDrive.isWarping = false
    WarpDrive.warpTarget = nil
    WarpDrive.warpProgress = 0
    
    -- Camera shake
    local Camera = Utils.require("src.core.camera")
    if Camera.shake then
        Camera:shake(15, 0.3)
    end
    
    -- Achievement tracking
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem.onWarpCompleted then
        AchievementSystem.onWarpCompleted()
    end
end

-- Toggle planet selection mode
function WarpDrive.toggleSelection()
    if not WarpDrive.isUnlocked then return false end
    if WarpDrive.isWarping then return false end
    
    WarpDrive.isSelecting = not WarpDrive.isSelecting
    WarpDrive.selectedPlanet = nil
    
    return WarpDrive.isSelecting
end

-- Handle planet selection
function WarpDrive.selectPlanetAt(worldX, worldY, planets, player)
    if not WarpDrive.isSelecting then return nil end
    
    -- Find closest discovered planet to click position
    local closestPlanet = nil
    local closestDistance = WarpDrive.selectionRadius
    
    for _, planet in ipairs(planets) do
        if planet.discovered then
            local dist = Utils.distance(worldX, worldY, planet.x, planet.y)
            if dist < closestDistance and dist < planet.radius + WarpDrive.selectionRadius then
                closestPlanet = planet
                closestDistance = dist
            end
        end
    end
    
    if closestPlanet then
        WarpDrive.selectedPlanet = closestPlanet
        
        -- Auto-start warp if we can afford it
        if WarpDrive.canAffordWarp(closestPlanet, player) then
            WarpDrive.startWarp(closestPlanet, player)
            WarpDrive.isSelecting = false
            WarpDrive.selectedPlanet = nil
        end
    end
    
    return closestPlanet
end

-- Draw warp effects
function WarpDrive.draw(player)
    if WarpDrive.warpEffectAlpha <= 0 and #WarpDrive.particles == 0 then return end
    
    -- Draw warp tunnel effect
    if WarpDrive.warpEffectAlpha > 0 then
        love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(WarpDrive.tunnelRotation)
        
        -- Tunnel rings
        for i = 1, 10 do
            local radius = i * 100
            local alpha = WarpDrive.warpEffectAlpha * (1 - i / 10) * 0.5
            Utils.setColor({0.5, 0.7, 1}, alpha)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", 0, 0, radius)
        end
        
        love.graphics.pop()
    end
    
    -- Draw particles
    for _, p in ipairs(WarpDrive.particles) do
        Utils.setColor(p.color, p.life * 0.8)
        love.graphics.circle("fill", p.x, p.y, p.size * p.life)
    end
end

-- Draw UI
function WarpDrive.drawUI(player, planets, camera)
    if not WarpDrive.isUnlocked then return end
    
    -- Draw energy bar
    local screenWidth = love.graphics.getWidth()
    local barWidth = 200
    local barHeight = 20
    local barX = screenWidth - barWidth - 20
    local barY = 100
    
    -- Background
    Utils.setColor({0, 0, 0}, 0.5)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 5)
    
    -- Energy fill
    local energyPercent = WarpDrive.energy / WarpDrive.maxEnergy
    Utils.setColor({0.2, 0.5, 1}, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth * energyPercent, barHeight, 5)
    
    -- Border
    Utils.setColor({0.5, 0.7, 1}, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 5)
    
    -- Text
    Utils.setColor({1, 1, 1}, 0.9)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("Warp Energy", barX, barY - 20, barWidth, "center")
    love.graphics.printf(math.floor(WarpDrive.energy) .. " / " .. WarpDrive.maxEnergy, 
        barX, barY + 2, barWidth, "center")
    
    -- Selection mode indicator
    if WarpDrive.isSelecting then
        Utils.setColor({1, 1, 0}, 0.8)
        love.graphics.printf("SELECT WARP DESTINATION", 0, 150, screenWidth, "center")
        
        -- Draw selection circles on discovered planets
        for _, planet in ipairs(planets) do
            if planet.discovered then
                local screenX, screenY = camera:worldToScreen(planet.x, planet.y)
                
                -- Check if can afford
                local canAfford = WarpDrive.canAffordWarp(planet, player)
                
                if canAfford then
                    Utils.setColor({0, 1, 0}, 0.5)
                else
                    Utils.setColor({1, 0, 0}, 0.3)
                end
                
                -- Pulsing selection circle
                local pulse = math.sin(love.timer.getTime() * 3) * 5 + planet.radius + 20
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", screenX, screenY, pulse)
                
                -- Cost indicator
                if planet == WarpDrive.selectedPlanet then
                    local distance = Utils.distance(player.x, player.y, planet.x, planet.y)
                    local cost = WarpDrive.calculateCost(distance)
                    
                    Utils.setColor({1, 1, 1}, 0.9)
                    love.graphics.setFont(love.graphics.newFont(10))
                    love.graphics.print("Cost: " .. cost, screenX + planet.radius + 10, screenY)
                end
            end
        end
    end
    
    -- Warp progress
    if WarpDrive.isWarping then
        Utils.setColor({1, 1, 1}, WarpDrive.warpEffectAlpha)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("WARPING...", 0, love.graphics.getHeight() / 2 - 50, screenWidth, "center")
        
        -- Progress bar
        local progBarWidth = 300
        local progBarX = (screenWidth - progBarWidth) / 2
        local progBarY = love.graphics.getHeight() / 2
        
        Utils.setColor({0, 0, 0}, 0.5 * WarpDrive.warpEffectAlpha)
        love.graphics.rectangle("fill", progBarX, progBarY, progBarWidth, 10)
        
        Utils.setColor({0.5, 0.7, 1}, WarpDrive.warpEffectAlpha)
        love.graphics.rectangle("fill", progBarX, progBarY, progBarWidth * WarpDrive.warpProgress, 10)
    end
end

-- Get upgrade status for UI
function WarpDrive.getStatus()
    return {
        unlocked = WarpDrive.isUnlocked,
        energy = WarpDrive.energy,
        maxEnergy = WarpDrive.maxEnergy,
        isWarping = WarpDrive.isWarping,
        canWarp = WarpDrive.energy >= 50 -- Minimum cost
    }
end

return WarpDrive