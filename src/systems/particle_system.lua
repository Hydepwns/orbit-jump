-- Particle System for Orbit Jump
-- Manages all particle effects in the game

local Utils = require("src.utils.utils")

local ParticleSystem = {}

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

-- Update all particles
function ParticleSystem.update(dt)
    local gravity = 200  -- Particle gravity
    
    for i = #ParticleSystem.particles, 1, -1 do
        local particle = ParticleSystem.particles[i]
        
        -- Update position
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt
        
        -- Apply gravity
        particle.vy = particle.vy + gravity * dt
        
        -- Apply drag
        particle.vx = particle.vx * 0.98
        particle.vy = particle.vy * 0.98
        
        -- Update lifetime
        particle.lifetime = particle.lifetime - dt
        
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

return ParticleSystem