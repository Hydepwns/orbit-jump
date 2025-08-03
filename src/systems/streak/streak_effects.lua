--[[
    ═══════════════════════════════════════════════════════════════════════════
    Streak Effects - Visual Effects & Particle System
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles all visual effects, particles, and animations related
    to the streak system, including perfect landing effects, streak break effects,
    and bonus activation animations.
--]]

local Utils = require("src.utils.utils")

local StreakEffects = {}

-- Visual effects state
StreakEffects.streakGlowPhase = 0
StreakEffects.bonusEffectTimer = 0
StreakEffects.breakEffectTimer = 0
StreakEffects.shakeIntensity = 0
StreakEffects.shieldGlowPhase = 0
StreakEffects.shieldActive = false

-- Effect configuration
StreakEffects.config = {
    glow_intensity = 0.8,
    shake_decay = 0.95,
    particle_lifetime = 2.0,
    effect_fade_speed = 0.1
}

-- Particle systems
StreakEffects.particles = {
    perfect_landing = {},
    streak_break = {},
    bonus_activation = {},
    grace_period = {}
}

-- Initialize streak effects
function StreakEffects.init()
    StreakEffects.reset()
    Utils.Logger.info("✨ Streak effects system initialized")
end

-- Reset all effects
function StreakEffects.reset()
    StreakEffects.streakGlowPhase = 0
    StreakEffects.bonusEffectTimer = 0
    StreakEffects.breakEffectTimer = 0
    StreakEffects.shakeIntensity = 0
    StreakEffects.shieldGlowPhase = 0
    StreakEffects.shieldActive = false
    
    -- Clear all particles
    for _, particleSystem in pairs(StreakEffects.particles) do
        particleSystem = {}
    end
    
    Utils.Logger.info("✨ Streak effects reset")
end

-- Update effects (called every frame)
function StreakEffects.update(dt)
    -- Update glow phase
    StreakEffects.streakGlowPhase = StreakEffects.streakGlowPhase + dt * 2
    
    -- Update bonus effect timer
    if StreakEffects.bonusEffectTimer > 0 then
        StreakEffects.bonusEffectTimer = StreakEffects.bonusEffectTimer - dt
    end
    
    -- Update break effect timer
    if StreakEffects.breakEffectTimer > 0 then
        StreakEffects.breakEffectTimer = StreakEffects.breakEffectTimer - dt
    end
    
    -- Update shake intensity
    if StreakEffects.shakeIntensity > 0 then
        StreakEffects.shakeIntensity = StreakEffects.shakeIntensity * StreakEffects.config.shake_decay
        if StreakEffects.shakeIntensity < 0.1 then
            StreakEffects.shakeIntensity = 0
        end
    end
    
    -- Update shield glow
    if StreakEffects.shieldActive then
        StreakEffects.shieldGlowPhase = StreakEffects.shieldGlowPhase + dt * 3
    end
    
    -- Update particles
    StreakEffects.updateParticles(dt)
end

-- Create perfect landing effect
function StreakEffects.createPerfectLandingEffect(x, y, streak)
    -- Create particle burst
    StreakEffects.createParticleBurst(x, y, {
        count = math.min(20, streak * 2),
        color = {1, 1, 0.5, 1}, -- Golden
        speed = 100,
        lifetime = 1.5,
        size = {2, 4}
    })
    
    -- Set bonus effect timer
    StreakEffects.bonusEffectTimer = 0.5
    
    -- Add screen shake for high streaks
    if streak >= 10 then
        StreakEffects.shakeIntensity = math.min(5, streak * 0.2)
    end
    
    Utils.Logger.info("✨ Perfect landing effect created (streak: %d)", streak)
end

-- Create streak break effect
function StreakEffects.createStreakBreakEffect(x, y, brokenStreak)
    -- Create red particle burst
    StreakEffects.createParticleBurst(x, y, {
        count = math.min(30, brokenStreak * 3),
        color = {1, 0.2, 0.2, 1}, -- Red
        speed = 150,
        lifetime = 2.0,
        size = {3, 6}
    })
    
    -- Set break effect timer
    StreakEffects.breakEffectTimer = 1.0
    
    -- Add dramatic screen shake
    StreakEffects.shakeIntensity = math.min(8, brokenStreak * 0.3)
    
    Utils.Logger.info("💥 Streak break effect created (broken streak: %d)", brokenStreak)
end

-- Create streak saved effect
function StreakEffects.createStreakSavedEffect(x, y)
    -- Create green particle burst
    StreakEffects.createParticleBurst(x, y, {
        count = 25,
        color = {0.2, 1, 0.2, 1}, -- Green
        speed = 120,
        lifetime = 1.8,
        size = {2, 5}
    })
    
    -- Add screen shake
    StreakEffects.shakeIntensity = 3
    
    Utils.Logger.info("🛡️ Streak saved effect created")
end

-- Create new record effect
function StreakEffects.createNewRecordEffect(x, y, newRecord)
    -- Create rainbow particle burst
    StreakEffects.createParticleBurst(x, y, {
        count = 40,
        color = {1, 0.5, 1, 1}, -- Purple
        speed = 200,
        lifetime = 2.5,
        size = {4, 8}
    })
    
    -- Add dramatic screen shake
    StreakEffects.shakeIntensity = 10
    
    Utils.Logger.info("🏆 New record effect created: %d", newRecord)
end

-- Create bonus activation effect
function StreakEffects.createBonusActivationEffect(x, y, bonusName)
    local colors = {
        ring_magnet = {0.5, 0.8, 1, 1},      -- Blue
        double_points = {1, 0.8, 0.2, 1},    -- Gold
        slow_motion = {0.8, 0.2, 1, 1},      -- Purple
        triple_rings = {0.2, 1, 0.8, 1},     -- Cyan
        invincible_landing = {1, 1, 1, 1},   -- White
        all_bonuses = {1, 0.5, 0, 1},        -- Orange
        perfect_combo = {1, 0.2, 0.8, 1},    -- Pink
        streak_shield = {0.2, 0.8, 1, 1},    -- Light blue
        master_focus = {0.8, 1, 0.2, 1},     -- Lime
        infinity_mode = {1, 0.2, 0.2, 1},    -- Red
        legendary_status = {1, 0.8, 0.5, 1}, -- Peach
        grandmaster = {0.5, 0.2, 1, 1}       -- Violet
    }
    
    local color = colors[bonusName] or {1, 1, 1, 1}
    
    -- Create bonus-specific particle burst
    StreakEffects.createParticleBurst(x, y, {
        count = 35,
        color = color,
        speed = 180,
        lifetime = 2.0,
        size = {3, 7}
    })
    
    -- Add screen shake
    StreakEffects.shakeIntensity = 4
    
    Utils.Logger.info("🎁 Bonus activation effect created: %s", bonusName)
end

-- Create particle burst
function StreakEffects.createParticleBurst(x, y, config)
    local particles = {}
    
    for i = 1, config.count do
        local angle = (i / config.count) * math.pi * 2
        local speed = config.speed + math.random(-20, 20)
        
        local particle = {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = config.lifetime,
            maxLife = config.lifetime,
            color = config.color,
            size = math.random(config.size[1], config.size[2])
        }
        
        table.insert(particles, particle)
    end
    
    -- Store particles in appropriate system
    if config.color[2] > 0.8 and config.color[1] > 0.8 then -- Green
        StreakEffects.particles.grace_period = particles
    elseif config.color[1] > 0.8 and config.color[2] < 0.3 then -- Red
        StreakEffects.particles.streak_break = particles
    else
        StreakEffects.particles.perfect_landing = particles
    end
end

-- Update all particles
function StreakEffects.updateParticles(dt)
    for systemName, particles in pairs(StreakEffects.particles) do
        for i = #particles, 1, -1 do
            local particle = particles[i]
            
            -- Update position
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            
            -- Update life
            particle.life = particle.life - dt
            
            -- Remove dead particles
            if particle.life <= 0 then
                table.remove(particles, i)
            end
        end
    end
end

-- Draw all effects
function StreakEffects.draw()
    -- Draw particles
    StreakEffects.drawParticles()
    
    -- Draw streak glow
    if StreakEffects.streakGlowPhase > 0 then
        StreakEffects.drawStreakGlow()
    end
    
    -- Draw bonus effects
    if StreakEffects.bonusEffectTimer > 0 then
        StreakEffects.drawBonusEffects()
    end
    
    -- Draw break effects
    if StreakEffects.breakEffectTimer > 0 then
        StreakEffects.drawBreakEffects()
    end
    
    -- Draw shield effects
    if StreakEffects.shieldActive then
        StreakEffects.drawShieldEffects()
    end
end

-- Draw particles
function StreakEffects.drawParticles()
    for systemName, particles in pairs(StreakEffects.particles) do
        for _, particle in ipairs(particles) do
            local alpha = particle.life / particle.maxLife
            local color = {
                particle.color[1],
                particle.color[2],
                particle.color[3],
                particle.color[4] * alpha
            }
            
            love.graphics.setColor(unpack(color))
            love.graphics.circle("fill", particle.x, particle.y, particle.size)
        end
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw streak glow
function StreakEffects.drawStreakGlow()
    local intensity = math.sin(StreakEffects.streakGlowPhase) * 0.5 + 0.5
    local alpha = intensity * StreakEffects.config.glow_intensity
    
    love.graphics.setColor(1, 1, 0.5, alpha)
    
    -- Draw screen edge glow
    local glowSize = 50
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), glowSize)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - glowSize, love.graphics.getWidth(), glowSize)
    love.graphics.rectangle("fill", 0, 0, glowSize, love.graphics.getHeight())
    love.graphics.rectangle("fill", love.graphics.getWidth() - glowSize, 0, glowSize, love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw bonus effects
function StreakEffects.drawBonusEffects()
    local alpha = StreakEffects.bonusEffectTimer / 0.5
    love.graphics.setColor(1, 1, 0.5, alpha * 0.3)
    
    -- Draw bonus flash
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw break effects
function StreakEffects.drawBreakEffects()
    local alpha = StreakEffects.breakEffectTimer / 1.0
    love.graphics.setColor(1, 0.2, 0.2, alpha * 0.2)
    
    -- Draw break flash
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw shield effects
function StreakEffects.drawShieldEffects()
    local intensity = math.sin(StreakEffects.shieldGlowPhase) * 0.5 + 0.5
    local alpha = intensity * 0.4
    
    love.graphics.setColor(0.2, 0.8, 1, alpha)
    
    -- Draw shield glow around screen
    local glowSize = 30
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), glowSize)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - glowSize, love.graphics.getWidth(), glowSize)
    love.graphics.rectangle("fill", 0, 0, glowSize, love.graphics.getHeight())
    love.graphics.rectangle("fill", love.graphics.getWidth() - glowSize, 0, glowSize, love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1, 1)
end

-- Get screen shake offset
function StreakEffects.getScreenShake()
    if StreakEffects.shakeIntensity <= 0 then
        return 0, 0
    end
    
    local shakeX = math.random(-StreakEffects.shakeIntensity, StreakEffects.shakeIntensity)
    local shakeY = math.random(-StreakEffects.shakeIntensity, StreakEffects.shakeIntensity)
    
    return shakeX, shakeY
end

-- Activate shield effects
function StreakEffects.activateShield()
    StreakEffects.shieldActive = true
    StreakEffects.shieldGlowPhase = 0
    Utils.Logger.info("🛡️ Shield effects activated")
end

-- Deactivate shield effects
function StreakEffects.deactivateShield()
    StreakEffects.shieldActive = false
    Utils.Logger.info("🛡️ Shield effects deactivated")
end

-- Get effect statistics
function StreakEffects.getEffectStats()
    local totalParticles = 0
    for _, particles in pairs(StreakEffects.particles) do
        totalParticles = totalParticles + #particles
    end
    
    return {
        total_particles = totalParticles,
        shake_intensity = StreakEffects.shakeIntensity,
        shield_active = StreakEffects.shieldActive,
        bonus_effect_timer = StreakEffects.bonusEffectTimer,
        break_effect_timer = StreakEffects.breakEffectTimer
    }
end

-- Clear all effects
function StreakEffects.clearAllEffects()
    StreakEffects.reset()
    Utils.Logger.info("✨ All streak effects cleared")
end

return StreakEffects 