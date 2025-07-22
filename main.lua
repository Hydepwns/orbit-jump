-- Orbit Jump - A gravity-based jumping game
local GameLogic = require("game_logic")
local soundManager = require("sound_manager")

local planets = {}
local player = {}
local rings = {}
local particles = {}
local gameState = "playing" -- playing, gameOver
local score = 0
local combo = 0
local comboTimer = 0
local screenWidth, screenHeight = love.graphics.getDimensions()

-- Font variables
local fonts = {
    regular = nil,
    bold = nil,
    light = nil,
    extraBold = nil
}

-- Input handling variables
local isMouseDown = false
local mouseStartX, mouseStartY = 0, 0
local pullPower = 0
local maxPullDistance = 150

function love.load()
    love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
    
    -- Load Monaspace Argon fonts
    fonts.regular = love.graphics.newFont("assets/fonts/MonaspaceArgon-Regular.otf", 16)
    fonts.bold = love.graphics.newFont("assets/fonts/MonaspaceArgon-Bold.otf", 16)
    fonts.light = love.graphics.newFont("assets/fonts/MonaspaceArgon-Light.otf", 16)
    fonts.extraBold = love.graphics.newFont("assets/fonts/MonaspaceArgon-ExtraBold.otf", 24)
    
    -- Set default font
    love.graphics.setFont(fonts.regular)
    
    -- Initialize sound
    soundManager:load()
    
    -- Initialize planets
    planets = {
        {x = screenWidth/2, y = screenHeight/2 - 200, radius = 80, rotationSpeed = 0.5, color = {0.8, 0.3, 0.3}},
        {x = screenWidth/2 - 250, y = screenHeight/2 + 100, radius = 60, rotationSpeed = -0.7, color = {0.3, 0.8, 0.3}},
        {x = screenWidth/2 + 250, y = screenHeight/2 + 100, radius = 70, rotationSpeed = 0.9, color = {0.3, 0.3, 0.8}},
    }
    
    -- Initialize player
    player = {
        x = planets[1].x + planets[1].radius + 20,
        y = planets[1].y,
        vx = 0,
        vy = 0,
        radius = 10,
        onPlanet = 1, -- Which planet the player is orbiting (nil if in space)
        angle = 0, -- Angle on the current planet
        jumpPower = 300,
        dashPower = 500,
        isDashing = false,
        dashTimer = 0,
        dashCooldown = 0,
        trail = {}, -- For visual effect
        speedBoost = 1.0
    }
    
    -- Calculate initial angle
    if player.onPlanet then
        local planet = planets[player.onPlanet]
        player.angle = math.atan2(player.y - planet.y, player.x - planet.x)
    end
    
    -- Initialize rings
    generateRings()
end

function generateRings()
    rings = {}
    local ringCount = 15
    
    for i = 1, ringCount do
        local ring = {
            x = math.random(100, screenWidth - 100),
            y = math.random(100, screenHeight - 100),
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
            for _, planet in ipairs(planets) do
                local dx = ring.x - planet.x
                local dy = ring.y - planet.y
                local distance = math.sqrt(dx*dx + dy*dy)
                if distance < planet.radius + 50 then
                    ring.x = math.random(100, screenWidth - 100)
                    ring.y = math.random(100, screenHeight - 100)
                    validPosition = false
                    break
                end
            end
        end
        
        table.insert(rings, ring)
    end
end

function createParticle(x, y, vx, vy, color, lifetime)
    table.insert(particles, {
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

function createRingBurst(ring)
    for i = 1, 20 do
        local angle = (i / 20) * math.pi * 2
        local speed = math.random(100, 300)
        createParticle(
            ring.x + math.cos(angle) * ring.innerRadius,
            ring.y + math.sin(angle) * ring.innerRadius,
            math.cos(angle) * speed,
            math.sin(angle) * speed,
            ring.color,
            math.random() * 0.5 + 0.5
        )
    end
end

function love.update(dt)
    if gameState == "playing" then
        updatePlayer(dt)
        updatePlanets(dt)
        updateRings(dt)
        updateParticles(dt)
        checkCollisions()
        checkRingCollisions()
        
        -- Update combo timer
        if combo > 0 then
            comboTimer = comboTimer - dt
            if comboTimer <= 0 then
                combo = 0
                player.speedBoost = 1.0
            end
        end
        
        -- Update trail
        table.insert(player.trail, 1, {x = player.x, y = player.y, life = 1, isDashing = player.isDashing})
        for i = #player.trail, 1, -1 do
            player.trail[i].life = player.trail[i].life - dt * 3
            if player.trail[i].life <= 0 then
                table.remove(player.trail, i)
            end
        end
        
        -- Check if all rings collected
        local allCollected = true
        for _, ring in ipairs(rings) do
            if not ring.collected then
                allCollected = false
                break
            end
        end
        
        if allCollected then
            generateRings()
            score = score + 100 * combo
        end
    end
    
    -- Update sound manager
    soundManager:update(dt)
end

function updateRings(dt)
    for _, ring in ipairs(rings) do
        if not ring.collected then
            ring.rotation = ring.rotation + ring.rotationSpeed * dt
            ring.pulsePhase = ring.pulsePhase + dt * 2
        end
    end
end

function updateParticles(dt)
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.lifetime = p.lifetime - dt
        
        -- Apply gravity effect
        p.vy = p.vy + 200 * dt
        
        if p.lifetime <= 0 then
            table.remove(particles, i)
        end
    end
end

function checkRingCollisions()
    for _, ring in ipairs(rings) do
        if not ring.collected then
            local dx = player.x - ring.x
            local dy = player.y - ring.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance < ring.radius and distance > ring.innerRadius - player.radius then
                ring.collected = true
                score = score + 10 + (combo * 5)
                combo = combo + 1
                comboTimer = 3.0
                player.speedBoost = 1.0 + (combo * 0.1)
                
                -- Create particle burst
                createRingBurst(ring)
                
                -- Play sound
                soundManager:playRingCollect(combo)
                
                -- If player is in space, give a speed boost
                if not player.onPlanet then
                    local currentSpeed = math.sqrt(player.vx^2 + player.vy^2)
                    if currentSpeed > 0 then
                        player.vx = (player.vx / currentSpeed) * currentSpeed * 1.2
                        player.vy = (player.vy / currentSpeed) * currentSpeed * 1.2
                    end
                end
            end
        end
    end
end

function updatePlayer(dt)
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
    
    if player.onPlanet then
        -- Player is orbiting a planet
        local planet = planets[player.onPlanet]
        player.angle = player.angle + planet.rotationSpeed * dt * player.speedBoost
        
        -- Keep player on planet surface
        local orbitRadius = planet.radius + player.radius + 5
        player.x = planet.x + math.cos(player.angle) * orbitRadius
        player.y = planet.y + math.sin(player.angle) * orbitRadius
        
        -- Reset velocity when on planet
        player.vx = 0
        player.vy = 0
    else
        -- Player is in space - apply gravity from all planets
        for i, planet in ipairs(planets) do
            local dx = planet.x - player.x
            local dy = planet.y - player.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance > planet.radius then
                -- Gravity strength
                local gravity = 15000 / (distance * distance)
                local gx = (dx / distance) * gravity
                local gy = (dy / distance) * gravity
                
                player.vx = player.vx + gx * dt
                player.vy = player.vy + gy * dt
            end
        end
        
        -- Update position with speed boost
        player.x = player.x + player.vx * dt * (player.isDashing and 2.0 or 1.0)
        player.y = player.y + player.vy * dt * (player.isDashing and 2.0 or 1.0)
        
        -- Check if out of bounds
        if player.x < -100 or player.x > screenWidth + 100 or 
           player.y < -100 or player.y > screenHeight + 100 then
            gameState = "gameOver"
            soundManager:playGameOver()
        end
    end
end

function updatePlanets(dt)
    -- Just visual rotation for now
    for i, planet in ipairs(planets) do
        -- Could add moving planets later
    end
end

function checkCollisions()
    if not player.onPlanet then
        for i, planet in ipairs(planets) do
            local dx = player.x - planet.x
            local dy = player.y - planet.y
            local distance = math.sqrt(dx*dx + dy*dy)
            
            if distance <= planet.radius + player.radius then
                -- Land on planet
                player.onPlanet = i
                player.angle = math.atan2(dy, dx)
                score = score + 1
                
                -- Adjust position to be on surface
                local orbitRadius = planet.radius + player.radius + 5
                player.x = planet.x + math.cos(player.angle) * orbitRadius
                player.y = planet.y + math.sin(player.angle) * orbitRadius
                
                -- Play landing sound
                soundManager:playLand()
            end
        end
    end
end

function jump()
    if player.onPlanet and gameState == "playing" then
        local planet = planets[player.onPlanet]
        
        -- Calculate jump direction (away from planet center)
        local dx = player.x - planet.x
        local dy = player.y - planet.y
        local dist = math.sqrt(dx*dx + dy*dy)
        
        -- Add tangential velocity based on rotation
        local tangentX = -math.sin(player.angle) * planet.rotationSpeed * (planet.radius + player.radius + 5)
        local tangentY = math.cos(player.angle) * planet.rotationSpeed * (planet.radius + player.radius + 5)
        
        -- Jump velocity with speed boost
        local jumpStrength = (player.jumpPower + pullPower * 2) * player.speedBoost
        player.vx = (dx / dist) * jumpStrength + tangentX
        player.vy = (dy / dist) * jumpStrength + tangentY
        
        player.onPlanet = nil
        
        -- Play jump sound
        soundManager:playJump()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        if gameState == "gameOver" then
            love.load()
            gameState = "playing"
            score = 0
            soundManager:restartAmbient()
        else
            isMouseDown = true
            mouseStartX = x
            mouseStartY = y
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 and isMouseDown then
        isMouseDown = false
        jump()
        pullPower = 0
    end
end

function love.mousemoved(x, y)
    if isMouseDown and gameState == "playing" then
        local dx = mouseStartX - x
        local dy = mouseStartY - y
        local distance = math.sqrt(dx*dx + dy*dy)
        pullPower = math.min(distance, maxPullDistance)
    end
end

function love.touchpressed(id, x, y)
    love.mousepressed(x, y, 1)
end

function love.touchreleased(id, x, y)
    love.mousereleased(x, y, 1)
end

function love.touchmoved(id, x, y)
    love.mousemoved(x, y)
end

function love.keypressed(key)
    if key == "space" then
        if gameState == "gameOver" then
            love.load()
            gameState = "playing"
            score = 0
            combo = 0
            soundManager:restartAmbient()
        else
            jump()
        end
    elseif key == "lshift" or key == "rshift" or key == "z" or key == "x" then
        dash()
    elseif key == "m" then
        -- Toggle mute
        soundManager:setEnabled(not soundManager.enabled)
    elseif key == "escape" then
        love.event.quit()
    end
end

function dash()
    if not player.onPlanet and player.dashCooldown <= 0 and not player.isDashing then
        player.isDashing = true
        player.dashTimer = 0.3
        player.dashCooldown = 1.0
        
        -- Apply dash boost in current direction
        local currentSpeed = math.sqrt(player.vx^2 + player.vy^2)
        if currentSpeed > 0 then
            player.vx = (player.vx / currentSpeed) * player.dashPower
            player.vy = (player.vy / currentSpeed) * player.dashPower
        end
        
        -- Create dash particles
        for i = 1, 10 do
            createParticle(
                player.x + math.random(-5, 5),
                player.y + math.random(-5, 5),
                -player.vx * 0.2 + math.random(-50, 50),
                -player.vy * 0.2 + math.random(-50, 50),
                {1, 0.8, 0.2},
                0.5
            )
        end
        
        -- Play dash sound
        soundManager:playDash()
    end
end

function love.draw()
    -- Draw stars background
    love.graphics.setColor(1, 1, 1, 0.3)
    for i = 1, 50 do
        local x = (i * 73) % screenWidth
        local y = (i * 137) % screenHeight
        love.graphics.circle("fill", x, y, 1)
    end
    
    -- Draw trail
    for i, point in ipairs(player.trail) do
        if point.isDashing then
            love.graphics.setColor(1, 0.8, 0.2, point.life * 0.6)
            love.graphics.circle("fill", point.x, point.y, player.radius * point.life * 0.8)
        else
            love.graphics.setColor(1, 1, 1, point.life * 0.3)
            love.graphics.circle("fill", point.x, point.y, player.radius * point.life * 0.5)
        end
    end
    
    -- Draw rings
    for _, ring in ipairs(rings) do
        if not ring.collected then
            local pulse = math.sin(ring.pulsePhase) * 0.1 + 1
            love.graphics.setColor(ring.color[1], ring.color[2], ring.color[3], 0.8)
            love.graphics.setLineWidth(3)
            
            -- Draw rotating ring segments
            local segments = 8
            for i = 1, segments do
                local angle1 = (i-1) / segments * math.pi * 2 + ring.rotation
                local angle2 = i / segments * math.pi * 2 + ring.rotation
                local gap = 0.1
                
                love.graphics.arc("line", "open", ring.x, ring.y, ring.radius * pulse, 
                    angle1 + gap, angle2 - gap)
                love.graphics.arc("line", "open", ring.x, ring.y, ring.innerRadius * pulse, 
                    angle1 + gap, angle2 - gap)
            end
        end
    end
    
    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = p.lifetime / p.maxLifetime
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.circle("fill", p.x, p.y, p.size * alpha)
    end
    
    -- Draw planets
    for i, planet in ipairs(planets) do
        love.graphics.setColor(planet.color)
        love.graphics.circle("fill", planet.x, planet.y, planet.radius)
        
        -- Draw rotation indicator
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(2)
        local indicatorAngle = love.timer.getTime() * planet.rotationSpeed
        local ix = planet.x + math.cos(indicatorAngle) * planet.radius * 0.8
        local iy = planet.y + math.sin(indicatorAngle) * planet.radius * 0.8
        love.graphics.line(planet.x, planet.y, ix, iy)
    end
    
    -- Draw player
    if player.isDashing then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.circle("fill", player.x, player.y, player.radius * 1.2)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("fill", player.x, player.y, player.radius)
    end
    
    -- Draw dash cooldown indicator
    if player.dashCooldown > 0 and not player.onPlanet then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
        love.graphics.arc("line", "open", player.x, player.y, player.radius + 5, 
            0, math.pi * 2 * (1 - player.dashCooldown / 1.0))
    end
    
    -- Draw pull indicator
    if isMouseDown and player.onPlanet then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(3)
        local mx, my = love.mouse.getPosition()
        love.graphics.line(player.x, player.y, mx, my)
        
        -- Power indicator
        local powerPercent = pullPower / maxPullDistance
        love.graphics.setColor(1, powerPercent, 0)
        love.graphics.circle("fill", mx, my, 5 + powerPercent * 10)
    end
    
    -- Draw UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(fonts.bold)
    love.graphics.print("Score: " .. score, 10, 10)
    
    -- Draw combo
    if combo > 0 then
        local comboAlpha = math.min(comboTimer / 3.0, 1)
        love.graphics.setColor(1, 1, 0, comboAlpha)
        love.graphics.setFont(fonts.bold)
        love.graphics.print("Combo x" .. combo, 10, 35)
        love.graphics.setFont(fonts.regular)
        love.graphics.print("Speed x" .. string.format("%.1f", player.speedBoost), 10, 60)
    end
    
    -- Draw controls hint
    love.graphics.setFont(fonts.light)
    if player.onPlanet then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf("Pull and release to jump!", 0, screenHeight - 30, screenWidth, "center")
    else
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.printf("Press Shift/Z/X to dash!", 0, screenHeight - 30, screenWidth, "center")
    end
    
    if gameState == "gameOver" then
        love.graphics.setFont(fonts.extraBold)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf("GAME OVER", 0, screenHeight/2 - 50, screenWidth, "center")
        love.graphics.setFont(fonts.bold)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Score: " .. score, 0, screenHeight/2, screenWidth, "center")
        love.graphics.setFont(fonts.regular)
        love.graphics.printf("Click or Press Space to Restart", 0, screenHeight/2 + 50, screenWidth, "center")
    end
    
    -- Draw sound status
    if not soundManager.enabled then
        love.graphics.setFont(fonts.light)
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.print("Sound: OFF (Press M to toggle)", 10, screenHeight - 20)
    end
end