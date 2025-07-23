-- Player System for Orbit Jump
-- Handles player movement, physics, and state updates

local Utils = require("src.utils.utils")
local GameLogic = require("src.core.game_logic")
local Config = require("src.utils.config")

local PlayerSystem = {}

-- Update player state
function PlayerSystem.update(player, planets, dt)
    -- Update dash cooldown
    if player.dashCooldown > 0 then
        player.dashCooldown = player.dashCooldown - dt
    end
    
    -- Update dash state
    if player.isDashing then
        player.dashTimer = player.dashTimer - dt
        if player.dashTimer <= 0 then
            player.isDashing = false
        end
    end
    
    -- Update position based on whether on planet or in space
    if player.onPlanet and planets[player.onPlanet] then
        PlayerSystem.updateOnPlanet(player, planets[player.onPlanet], dt)
    else
        PlayerSystem.updateInSpace(player, planets, dt)
    end
    
    -- Update trail
    PlayerSystem.updateTrail(player)
    
    -- Check boundaries
    PlayerSystem.checkBoundaries(player)
    
    -- Update camera scale based on speed
    local speed = Utils.distance(0, 0, player.vx, player.vy)
    local targetScale = 1.0 - math.min(speed / 2000, 0.3)
    if player.camera then
        player.camera.scale = Utils.lerp(player.camera.scale, targetScale, dt * 2)
    end
end

-- Update player when on planet
function PlayerSystem.updateOnPlanet(player, planet, dt)
    -- Update angle based on planet's angular velocity
    player.angle = player.angle + (planet.angularVelocity or 0.5) * dt
    
    -- Update position to stay on planet surface
    local orbitRadius = planet.radius + player.radius + 5
    player.x = planet.x + math.cos(player.angle) * orbitRadius
    player.y = planet.y + math.sin(player.angle) * orbitRadius
    
    -- Reset velocity while on planet
    player.vx = 0
    player.vy = 0
end

-- Update player when in space
function PlayerSystem.updateInSpace(player, planets, dt)
    -- Apply gravity from all planets
    local gravX, gravY = 0, 0
    for _, planet in ipairs(planets) do
        local gx, gy = GameLogic.calculateGravity(
            player.x, player.y, 
            planet.x, planet.y, 
            planet.radius
        )
        gravX = gravX + gx
        gravY = gravY + gy
    end
    
    -- Apply forces
    player.vx = player.vx + gravX * dt
    player.vy = player.vy + gravY * dt
    
    -- Apply drag if not dashing
    if not player.isDashing then
        local drag = 0.99
        player.vx = player.vx * drag
        player.vy = player.vy * drag
    end
    
    -- Update position
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
end

-- Update player trail effect
function PlayerSystem.updateTrail(player)
    -- Add new trail point
    table.insert(player.trail, {
        x = player.x,
        y = player.y,
        life = 1.0,
        isDashing = player.isDashing
    })
    
    -- Update existing trail points
    for i = #player.trail, 1, -1 do
        local point = player.trail[i]
        point.life = point.life - 0.02
        
        if point.life <= 0 then
            table.remove(player.trail, i)
        end
    end
    
    -- Limit trail length
    while #player.trail > 50 do
        table.remove(player.trail, 1)
    end
end

-- Check if player is out of bounds
function PlayerSystem.checkBoundaries(player)
    local maxDistance = 5000
    local distance = Utils.distance(0, 0, player.x, player.y)
    
    if distance > maxDistance then
        -- Wrap around or handle boundary
        local angle = math.atan2(player.y, player.x)
        player.x = math.cos(angle) * maxDistance
        player.y = math.sin(angle) * maxDistance
        
        -- Reverse velocity
        player.vx = -player.vx * 0.5
        player.vy = -player.vy * 0.5
    end
end

-- Handle jump action
function PlayerSystem.jump(player, pullPower, pullAngle, gameState, soundManager)
    if not player.onPlanet then
        return false
    end
    
    -- Calculate jump velocity
    local jumpPower = math.min(pullPower * 3, Config.game.maxJumpPower)
    local jumpVx, jumpVy = GameLogic.calculateJumpVelocityFromAngle(pullAngle, jumpPower)
    
    -- Apply speed boost if active
    local RingSystem = require("src.systems.ring_system")
    if RingSystem.isActive("speed") then
        jumpVx, jumpVy = GameLogic.applySpeedBoost(jumpVx, jumpVy)
    end
    
    -- Set player state
    player.vx = jumpVx
    player.vy = jumpVy
    player.onPlanet = false
    
    -- Play sound
    if soundManager then
        soundManager:playJump()
    end
    
    -- Track jump
    if gameState then
        gameState.jumps = (gameState.jumps or 0) + 1
    end
    
    return true
end

-- Handle dash action
function PlayerSystem.dash(player, targetX, targetY, soundManager)
    -- Check if can dash
    if player.onPlanet or player.dashCooldown > 0 then
        return false
    end
    
    -- Check if multi-jump is active (skip check during tutorial)
    local TutorialSystem = require("src.ui.tutorial_system")
    local RingSystem = require("src.systems.ring_system")
    if not TutorialSystem.isActive and not RingSystem.isActive("multijump") then
        return false
    end
    
    -- Calculate dash direction
    local dx = targetX - player.x
    local dy = targetY - player.y
    local nx, ny = Utils.normalize(dx, dy)
    
    -- Apply dash
    local dashPower = Config.game.dashPower or 500
    player.vx = nx * dashPower
    player.vy = ny * dashPower
    player.isDashing = true
    player.dashTimer = 0.3
    player.dashCooldown = 1.0
    
    -- Play sound
    if soundManager then
        soundManager:playDash()
    end
    
    -- Create dash effect
    PlayerSystem.createDashEffect(player)
    
    return true
end

-- Create visual effect for dash
function PlayerSystem.createDashEffect(player)
    local ParticleSystem = require("src.systems.particle_system")
    if ParticleSystem then
        for i = 1, 10 do
            local angle = (i / 10) * math.pi * 2
            local vx = math.cos(angle) * 100
            local vy = math.sin(angle) * 100
            ParticleSystem.create(
                player.x, player.y,
                vx, vy,
                {0.8, 0.9, 1, 0.8},
                0.5,
                3
            )
        end
    end
end

return PlayerSystem