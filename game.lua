-- Extracted game module for better testing
local GameLogic = require("game_logic")

local Game = {}

-- Game state variables
Game.planets = {}
Game.player = {}
Game.rings = {}
Game.particles = {}
Game.gameState = "playing"
Game.score = 0
Game.combo = 0
Game.comboTimer = 0
Game.screenWidth = 800
Game.screenHeight = 600

-- Input handling variables
Game.isMouseDown = false
Game.mouseStartX = 0
Game.mouseStartY = 0
Game.pullPower = 0
Game.maxPullDistance = 150

function Game.init(width, height)
    Game.screenWidth = width or 800
    Game.screenHeight = height or 600
    
    -- Initialize planets
    Game.planets = {
        {x = Game.screenWidth/2, y = Game.screenHeight/2 - 200, radius = 80, rotationSpeed = 0.5, color = {0.8, 0.3, 0.3}},
        {x = Game.screenWidth/2 - 250, y = Game.screenHeight/2 + 100, radius = 60, rotationSpeed = -0.7, color = {0.3, 0.8, 0.3}},
        {x = Game.screenWidth/2 + 250, y = Game.screenHeight/2 + 100, radius = 70, rotationSpeed = 0.9, color = {0.3, 0.3, 0.8}},
    }
    
    -- Initialize player
    Game.player = {
        x = Game.planets[1].x + Game.planets[1].radius + 20,
        y = Game.planets[1].y,
        vx = 0,
        vy = 0,
        radius = 10,
        onPlanet = 1,
        angle = 0,
        jumpPower = 300,
        dashPower = 500,
        isDashing = false,
        dashTimer = 0,
        dashCooldown = 0,
        trail = {},
        speedBoost = 1.0
    }
    
    -- Calculate initial angle
    if Game.player.onPlanet then
        local planet = Game.planets[Game.player.onPlanet]
        Game.player.angle = math.atan2(Game.player.y - planet.y, Game.player.x - planet.x)
    end
    
    -- Initialize rings
    Game.generateRings()
    
    -- Reset other state
    Game.particles = {}
    Game.gameState = "playing"
    Game.score = 0
    Game.combo = 0
    Game.comboTimer = 0
    Game.isMouseDown = false
    Game.pullPower = 0
end

function Game.generateRings()
    Game.rings = {}
    local ringCount = 15
    
    for i = 1, ringCount do
        local ring = {
            x = math.random(100, Game.screenWidth - 100),
            y = math.random(100, Game.screenHeight - 100),
            radius = 30,
            innerRadius = 20,
            collected = false,
            rotation = 0,
            rotationSpeed = math.random(-2, 2),
            pulsePhase = math.random() * math.pi * 2,
            color = {math.random() * 0.5 + 0.5, math.random() * 0.5 + 0.5, math.random() * 0.5 + 0.5}
        }
        
        -- Ensure rings aren't too close to planets
        local validPosition = false
        while not validPosition do
            validPosition = true
            for _, planet in ipairs(Game.planets) do
                local distance = GameLogic.calculateDistance(ring.x, ring.y, planet.x, planet.y)
                if distance < planet.radius + 50 then
                    ring.x = math.random(100, Game.screenWidth - 100)
                    ring.y = math.random(100, Game.screenHeight - 100)
                    validPosition = false
                    break
                end
            end
        end
        
        table.insert(Game.rings, ring)
    end
end

function Game.createParticle(x, y, vx, vy, color, lifetime)
    table.insert(Game.particles, {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        color = color,
        lifetime = lifetime,
        maxLifetime = lifetime,
        size = math.random(2, 5)
    })
end

function Game.createRingBurst(ring)
    for i = 1, 20 do
        local angle = (i / 20) * math.pi * 2
        local speed = math.random(100, 300)
        Game.createParticle(
            ring.x + math.cos(angle) * ring.innerRadius,
            ring.y + math.sin(angle) * ring.innerRadius,
            math.cos(angle) * speed,
            math.sin(angle) * speed,
            ring.color,
            math.random() * 0.5 + 0.5
        )
    end
end

function Game.updatePlayer(dt)
    -- Update dash cooldown
    if Game.player.dashCooldown > 0 then
        Game.player.dashCooldown = Game.player.dashCooldown - dt
    end
    
    -- Update dash state
    if Game.player.isDashing then
        Game.player.dashTimer = Game.player.dashTimer - dt
        if Game.player.dashTimer <= 0 then
            Game.player.isDashing = false
        end
    end
    
    if Game.player.onPlanet then
        -- Player is orbiting a planet
        local planet = Game.planets[Game.player.onPlanet]
        Game.player.angle = Game.player.angle + planet.rotationSpeed * dt * Game.player.speedBoost
        
        -- Keep player on planet surface
        local orbitRadius = planet.radius + Game.player.radius + 5
        Game.player.x, Game.player.y = GameLogic.calculateOrbitPosition(
            planet.x, planet.y, Game.player.angle, orbitRadius
        )
        
        -- Reset velocity when on planet
        Game.player.vx = 0
        Game.player.vy = 0
    else
        -- Player is in space - apply gravity from all planets
        for i, planet in ipairs(Game.planets) do
            local gx, gy = GameLogic.calculateGravity(
                Game.player.x, Game.player.y, planet.x, planet.y, planet.radius
            )
            Game.player.vx = Game.player.vx + gx * dt
            Game.player.vy = Game.player.vy + gy * dt
        end
        
        -- Update position with speed boost
        local speedMultiplier = Game.player.isDashing and 2.0 or 1.0
        Game.player.x = Game.player.x + Game.player.vx * dt * speedMultiplier
        Game.player.y = Game.player.y + Game.player.vy * dt * speedMultiplier
        
        -- Check if out of bounds
        if GameLogic.isOutOfBounds(Game.player.x, Game.player.y, Game.screenWidth, Game.screenHeight) then
            Game.gameState = "gameOver"
        end
    end
end

function Game.updateRings(dt)
    for _, ring in ipairs(Game.rings) do
        if not ring.collected then
            ring.rotation = ring.rotation + ring.rotationSpeed * dt
            ring.pulsePhase = ring.pulsePhase + dt * 2
        end
    end
end

function Game.updateParticles(dt)
    for i = #Game.particles, 1, -1 do
        local p = Game.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.lifetime = p.lifetime - dt
        
        -- Apply gravity effect
        p.vy = p.vy + 200 * dt
        
        if p.lifetime <= 0 then
            table.remove(Game.particles, i)
        end
    end
end

function Game.checkCollisions()
    if not Game.player.onPlanet then
        for i, planet in ipairs(Game.planets) do
            if GameLogic.checkPlanetCollision(
                Game.player.x, Game.player.y, Game.player.radius,
                planet.x, planet.y, planet.radius
            ) then
                -- Land on planet
                Game.player.onPlanet = i
                Game.player.angle = math.atan2(
                    Game.player.y - planet.y, 
                    Game.player.x - planet.x
                )
                Game.score = Game.score + 1
                
                -- Adjust position to be on surface
                local orbitRadius = planet.radius + Game.player.radius + 5
                Game.player.x, Game.player.y = GameLogic.calculateOrbitPosition(
                    planet.x, planet.y, Game.player.angle, orbitRadius
                )
            end
        end
    end
end

function Game.checkRingCollisions()
    for _, ring in ipairs(Game.rings) do
        if not ring.collected then
            if GameLogic.checkRingCollision(
                Game.player.x, Game.player.y, Game.player.radius,
                ring.x, ring.y, ring.radius, ring.innerRadius
            ) then
                ring.collected = true
                Game.score = Game.score + GameLogic.calculateComboBonus(Game.combo)
                Game.combo = Game.combo + 1
                Game.comboTimer = 3.0
                Game.player.speedBoost = GameLogic.calculateSpeedBoost(Game.combo)
                
                -- Create particle burst
                Game.createRingBurst(ring)
                
                -- If player is in space, give a speed boost
                if not Game.player.onPlanet then
                    Game.player.vx, Game.player.vy = GameLogic.applySpeedBoost(
                        Game.player.vx, Game.player.vy, 1.2
                    )
                end
            end
        end
    end
end

function Game.jump()
    if Game.player.onPlanet and Game.gameState == "playing" then
        local planet = Game.planets[Game.player.onPlanet]
        
        -- Add tangential velocity based on rotation
        local tangentX, tangentY = GameLogic.calculateTangentVelocity(
            Game.player.angle, planet.rotationSpeed, 
            planet.radius + Game.player.radius + 5
        )
        
        -- Jump velocity with speed boost
        local jumpStrength = (Game.player.jumpPower + Game.pullPower * 2) * Game.player.speedBoost
        Game.player.vx, Game.player.vy = GameLogic.calculateJumpVelocity(
            Game.player.x, Game.player.y, planet.x, planet.y, 
            jumpStrength, tangentX, tangentY
        )
        
        Game.player.onPlanet = nil
    end
end

function Game.dash()
    if not Game.player.onPlanet and Game.player.dashCooldown <= 0 and not Game.player.isDashing then
        Game.player.isDashing = true
        Game.player.dashTimer = 0.3
        Game.player.dashCooldown = 1.0
        
        -- Apply dash boost in current direction
        Game.player.vx, Game.player.vy = GameLogic.applySpeedBoost(
            Game.player.vx, Game.player.vy, Game.player.dashPower / math.sqrt(Game.player.vx^2 + Game.player.vy^2)
        )
        
        -- Create dash particles
        for i = 1, 10 do
            Game.createParticle(
                Game.player.x + math.random(-5, 5),
                Game.player.y + math.random(-5, 5),
                -Game.player.vx * 0.2 + math.random(-50, 50),
                -Game.player.vy * 0.2 + math.random(-50, 50),
                {1, 0.8, 0.2},
                0.5
            )
        end
    end
end

function Game.update(dt)
    if Game.gameState == "playing" then
        Game.updatePlayer(dt)
        Game.updateRings(dt)
        Game.updateParticles(dt)
        Game.checkCollisions()
        Game.checkRingCollisions()
        
        -- Update combo timer
        if Game.combo > 0 then
            Game.comboTimer = Game.comboTimer - dt
            if Game.comboTimer <= 0 then
                Game.combo = 0
                Game.player.speedBoost = 1.0
            end
        end
        
        -- Update trail
        table.insert(Game.player.trail, 1, {
            x = Game.player.x, 
            y = Game.player.y, 
            life = 1, 
            isDashing = Game.player.isDashing
        })
        
        for i = #Game.player.trail, 1, -1 do
            Game.player.trail[i].life = Game.player.trail[i].life - dt * 3
            if Game.player.trail[i].life <= 0 then
                table.remove(Game.player.trail, i)
            end
        end
        
        -- Check if all rings collected
        local allCollected = true
        for _, ring in ipairs(Game.rings) do
            if not ring.collected then
                allCollected = false
                break
            end
        end
        
        if allCollected then
            Game.generateRings()
            Game.score = Game.score + 100 * Game.combo
        end
    end
end

return Game