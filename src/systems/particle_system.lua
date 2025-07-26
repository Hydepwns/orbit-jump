--[[
    Particle System: Visual Poetry in Motion
    
    Particles are the emotional language of games - they transform mechanical
    events into visceral experiences. This system doesn't just emit particles;
    it tells stories through motion, color, and behavior.
    
    Design Philosophy:
    - Particles should enhance emotional moments, not obscure gameplay
    - Each effect has meaning: celebration, loss, discovery, achievement
    - Performance matters: 1000 particles at 60fps through clever pooling
    - Less is often more: One perfect particle beats ten mediocre ones
--]]

local Utils = require("src.utils.utils")

local ParticleSystem = {}

-- Emotional profiles: Each tells a different story
ParticleSystem.EMOTION_PROFILES = {
    joy = {
        color = {1.0, 0.9, 0.3, 1.0},        -- Golden sparkles
        count = 20,
        behavior = "rise_and_dance",         -- Particles rise with joy
        lifetime = 2.0,
        speed = 150,
        gravity = -100,                       -- Anti-gravity for uplifting feeling
        message = "Your success brings light to the cosmos"
    },
    achievement = {
        color = {1.0, 1.0, 1.0, 1.0},        -- Pure white celebration
        count = 50,
        behavior = "radial_celebration",     -- Exploding outward
        lifetime = 3.0,
        speed = 300,
        gravity = 50,
        message = "The universe celebrates with you"
    },
    discovery = {
        color = "prismatic",                 -- Rainbow shifting colors
        count = 30,
        behavior = "exploratory_spread",     -- Curious wandering
        lifetime = 2.5,
        speed = 100,
        gravity = 0,                          -- Float in wonder
        message = "New worlds await"
    },
    loss = {
        color = {0.3, 0.5, 0.9, 0.8},        -- Gentle blue
        count = 15,
        behavior = "gentle_fall",            -- Falling like tears
        lifetime = 2.0,
        speed = 50,
        gravity = 150,
        message = "Even in loss, beauty remains"
    },
    power = {
        color = {0.9, 0.3, 1.0, 1.0},        -- Electric purple
        count = 25,
        behavior = "spiral_energy",          -- Spiraling with power
        lifetime = 1.5,
        speed = 250,
        gravity = 0,
        message = "Power courses through you"
    }
}

-- Particle storage
ParticleSystem.particles = {}
ParticleSystem.particlePool = nil
ParticleSystem.maxParticles = 1000

-- Initialize particle system
function ParticleSystem.init()
    -- Create object pool for particles
    ParticleSystem.particlePool = Utils.ObjectPool.new(
        function()
            return {
                x = 0, y = 0,
                vx = 0, vy = 0,
                lifetime = 0,
                maxLifetime = 1,
                size = 2,
                color = {1, 1, 1, 1},
                type = "default"
            }
        end,
        function(particle)
            -- Reset particle to default state
            particle.x = 0
            particle.y = 0
            particle.vx = 0
            particle.vy = 0
            particle.lifetime = 0
            particle.maxLifetime = 1
            particle.size = 2
            particle.color = {1, 1, 1, 1}
            particle.type = "default"
        end
    )
    
    ParticleSystem.particles = {}
    return true
end

-- Create a new particle
function ParticleSystem.create(x, y, vx, vy, color, lifetime, size, particleType)
    -- Check particle limit
    if #ParticleSystem.particles >= ParticleSystem.maxParticles then
        -- Remove oldest particle
        local oldest = table.remove(ParticleSystem.particles, 1)
        if oldest and ParticleSystem.particlePool then
            ParticleSystem.particlePool:returnObject(oldest)
        end
    end
    
    -- Get particle from pool or create new
    local particle
    if ParticleSystem.particlePool then
        particle = ParticleSystem.particlePool:get()
    else
        particle = {}
    end
    
    -- Set particle properties
    particle.x = x
    particle.y = y
    particle.vx = vx or 0
    particle.vy = vy or 0
    particle.lifetime = lifetime or 1
    particle.maxLifetime = lifetime or 1
    particle.size = size or 2
    particle.color = color or {1, 1, 1, 1}
    particle.type = particleType or "default"
    
    table.insert(ParticleSystem.particles, particle)
    return particle
end

-- Update all particles with behavior-driven physics
function ParticleSystem.update(dt)
    for i = #ParticleSystem.particles, 1, -1 do
        local particle = ParticleSystem.particles[i]
        
        -- Apply behavior-specific physics
        if particle.behavior == "rise_and_dance" then
            -- Joy particles dance upward with oscillation
            particle.x = particle.x + particle.vx * dt + math.sin(particle.lifetime * 5) * 20 * dt
            particle.y = particle.y + particle.vy * dt
            particle.vy = particle.vy - 100 * dt  -- Anti-gravity
            
        elseif particle.behavior == "radial_celebration" then
            -- Achievement particles explode outward with decreasing speed
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.vx = particle.vx * 0.95  -- Rapid deceleration
            particle.vy = particle.vy * 0.95
            
        elseif particle.behavior == "exploratory_spread" then
            -- Discovery particles wander with brownian motion
            particle.x = particle.x + particle.vx * dt + (math.random() - 0.5) * 50 * dt
            particle.y = particle.y + particle.vy * dt + (math.random() - 0.5) * 50 * dt
            
        elseif particle.behavior == "gentle_fall" then
            -- Loss particles fall gently with air resistance
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.vy = particle.vy + 150 * dt  -- Gentle gravity
            particle.vx = particle.vx * 0.92      -- Heavy air resistance
            particle.vy = particle.vy * 0.98
            
        elseif particle.behavior == "spiral_energy" then
            -- Power particles spiral with increasing intensity
            local age = 1 - (particle.lifetime / particle.maxLifetime)
            local spiralSpeed = age * 10
            particle.x = particle.x + particle.vx * dt + math.cos(spiralSpeed) * 30 * dt
            particle.y = particle.y + particle.vy * dt + math.sin(spiralSpeed) * 30 * dt
            
        else
            -- Default physics for backwards compatibility
            particle.x = particle.x + particle.vx * dt
            particle.y = particle.y + particle.vy * dt
            particle.vy = particle.vy + (particle.gravity or 200) * dt
            particle.vx = particle.vx * 0.98
            particle.vy = particle.vy * 0.98
        end
        
        -- Update lifetime and alpha fade
        particle.lifetime = particle.lifetime - dt
        
        -- Fade out based on remaining lifetime
        if particle.color and particle.color[4] then
            local fadeRatio = particle.lifetime / particle.maxLifetime
            particle.color[4] = particle.originalAlpha * fadeRatio
        end
        
        -- Handle prismatic color shift for discovery particles
        if particle.colorType == "prismatic" then
            local hue = (love.timer.getTime() * 2 + i * 0.1) % 1
            local r, g, b = Utils.hslToRgb(hue, 0.8, 0.6)
            particle.color[1] = r
            particle.color[2] = g
            particle.color[3] = b
        end
        
        -- Remove dead particles
        if particle.lifetime <= 0 then
            table.remove(ParticleSystem.particles, i)
            if ParticleSystem.particlePool then
                ParticleSystem.particlePool:returnObject(particle)
            end
        end
    end
end

-- Create burst effect
function ParticleSystem.burst(x, y, count, color, speed, lifetime)
    count = count or 10
    speed = speed or 200
    lifetime = lifetime or 1
    
    for i = 1, count do
        local angle = (i / count) * math.pi * 2 + math.random() * 0.5
        local vel = speed * (0.5 + math.random() * 0.5)
        local vx = math.cos(angle) * vel
        local vy = math.sin(angle) * vel
        
        ParticleSystem.create(
            x + math.random(-5, 5),
            y + math.random(-5, 5),
            vx, vy,
            color,
            lifetime * (0.5 + math.random() * 0.5),
            2 + math.random() * 2
        )
    end
end

-- Create trail effect
function ParticleSystem.trail(x, y, vx, vy, color, count)
    count = count or 3
    
    for i = 1, count do
        local spread = 20
        local pvx = vx * -0.5 + math.random(-spread, spread)
        local pvy = vy * -0.5 + math.random(-spread, spread)
        
        ParticleSystem.create(
            x + math.random(-5, 5),
            y + math.random(-5, 5),
            pvx, pvy,
            color,
            0.3 + math.random() * 0.3,
            1 + math.random() * 2
        )
    end
end

-- Create sparkle effect
function ParticleSystem.sparkle(x, y, color)
    local count = 5
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 50 + math.random() * 100
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        ParticleSystem.create(
            x, y,
            vx, vy,
            color or {1, 1, 0.8, 1},
            0.5 + math.random() * 0.5,
            1 + math.random() * 2,
            "sparkle"
        )
    end
end

-- Get all particles (for rendering)
function ParticleSystem.getParticles()
    return ParticleSystem.particles
end

-- Get all particles (alias for getParticles for compatibility)
function ParticleSystem.get()
    return ParticleSystem.particles
end

-- Clear all particles
function ParticleSystem.clear()
    if ParticleSystem.particlePool then
        for _, particle in ipairs(ParticleSystem.particles) do
            ParticleSystem.particlePool:returnObject(particle)
        end
    end
    ParticleSystem.particles = {}
end

-- Get particle count
function ParticleSystem.getCount()
    return #ParticleSystem.particles
end

--[[
    Emotional Burst: Create particles that express feelings
    
    This is the crown jewel of the particle system - particles that don't
    just look pretty, but convey emotional states. Use this for moments
    that matter: first warp, personal bests, close calls, achievements.
    
    @param x, y - Epicenter of the emotion
    @param emotionType - "joy", "achievement", "discovery", "loss", "power"
    @param intensity - 0.0 to 1.0, scales the effect
    @param customMessage - Optional override for the emotional message
--]]
function ParticleSystem.createEmotionalBurst(x, y, emotionType, intensity, customMessage)
    intensity = intensity or 1.0
    
    local profile = ParticleSystem.EMOTION_PROFILES[emotionType]
    if not profile then
        Utils.Logger.warn("Unknown emotion type: %s", emotionType)
        return
    end
    
    -- Scale particle count by intensity
    local count = math.floor(profile.count * intensity)
    
    -- Create particles with emotional behavior
    for i = 1, count do
        local angle, speed, vx, vy
        
        if profile.behavior == "rise_and_dance" then
            -- Joy: Particles rise with slight spread
            angle = -math.pi/2 + (math.random() - 0.5) * math.pi/3
            speed = profile.speed * (0.7 + math.random() * 0.3)
            
        elseif profile.behavior == "radial_celebration" then
            -- Achievement: Perfect radial burst
            angle = (i / count) * math.pi * 2
            speed = profile.speed * (0.8 + math.random() * 0.2)
            
        elseif profile.behavior == "exploratory_spread" then
            -- Discovery: Random curious directions
            angle = math.random() * math.pi * 2
            speed = profile.speed * (0.5 + math.random() * 0.5)
            
        elseif profile.behavior == "gentle_fall" then
            -- Loss: Gentle downward with spread
            angle = math.pi/2 + (math.random() - 0.5) * math.pi/4
            speed = profile.speed * (0.8 + math.random() * 0.2)
            
        elseif profile.behavior == "spiral_energy" then
            -- Power: Outward spiral setup
            angle = (i / count) * math.pi * 2
            speed = profile.speed
        end
        
        vx = math.cos(angle) * speed
        vy = math.sin(angle) * speed
        
        -- Get particle from pool
        local particle
        if ParticleSystem.particlePool then
            particle = ParticleSystem.particlePool:get()
        else
            particle = {}
        end
        
        -- Set emotional particle properties
        particle.x = x + (math.random() - 0.5) * 10
        particle.y = y + (math.random() - 0.5) * 10
        particle.vx = vx
        particle.vy = vy
        particle.lifetime = profile.lifetime * (0.7 + math.random() * 0.3)
        particle.maxLifetime = particle.lifetime
        particle.size = 2 + math.random() * 3 * intensity
        particle.behavior = profile.behavior
        particle.gravity = profile.gravity
        particle.emotionType = emotionType
        
        -- Handle color
        if profile.color == "prismatic" then
            particle.colorType = "prismatic"
            particle.color = {1, 1, 1, 1}  -- Will be updated each frame
        else
            particle.color = {}
            for j = 1, 4 do
                particle.color[j] = profile.color[j] or 1
            end
        end
        particle.originalAlpha = particle.color[4]
        
        table.insert(ParticleSystem.particles, particle)
    end
    
    -- Log the emotional moment (for analytics/achievements)
    if Utils.Logger then
        Utils.Logger.info("Emotional moment: %s at intensity %.2f - %s", 
                         emotionType, intensity, 
                         customMessage or profile.message)
    end
end

-- Helper function for HSL to RGB conversion (for prismatic colors)
if not Utils.hslToRgb then
    Utils.hslToRgb = function(h, s, l)
        local r, g, b
        
        if s == 0 then
            r, g, b = l, l, l
        else
            local function hue2rgb(p, q, t)
                if t < 0 then t = t + 1 end
                if t > 1 then t = t - 1 end
                if t < 1/6 then return p + (q - p) * 6 * t end
                if t < 1/2 then return q end
                if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
                return p
            end
            
            local q = l < 0.5 and l * (1 + s) or l + s - l * s
            local p = 2 * l - q
            r = hue2rgb(p, q, h + 1/3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1/3)
        end
        
        return r, g, b
    end
end

return ParticleSystem