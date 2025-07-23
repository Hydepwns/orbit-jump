-- Cosmic Events System for Orbit Jump
-- Dynamic events that create challenges and opportunities

local Utils = Utils.Utils.require("src.utils.utils")
local CosmicEvents = {}

-- Event types
CosmicEvents.eventTypes = {
    meteor_shower = {
        name = "Meteor Shower",
        duration = 15,
        probability = 0.02,
        warning = 3,
        description = "Dodge incoming meteors!",
        color = {1, 0.5, 0.2}
    },
    gravity_wave = {
        name = "Gravity Wave",
        duration = 10,
        probability = 0.015,
        warning = 2,
        description = "Gravity goes haywire!",
        color = {0.5, 0.2, 1}
    },
    time_rift = {
        name = "Time Rift",
        duration = 8,
        probability = 0.01,
        warning = 2,
        description = "Time slows down!",
        color = {0.2, 0.8, 1}
    },
    ring_storm = {
        name = "Ring Storm",
        duration = 12,
        probability = 0.025,
        warning = 3,
        description = "Rings everywhere!",
        color = {1, 0.8, 0.2}
    },
    void_surge = {
        name = "Void Surge",
        duration = 6,
        probability = 0.008,
        warning = 4,
        description = "The void hungers!",
        color = {0.5, 0, 0.5}
    }
}

-- Active events
CosmicEvents.activeEvents = {}
CosmicEvents.eventCooldown = 0
CosmicEvents.minimumCooldown = 20

-- Meteor shower data
CosmicEvents.meteors = {}
CosmicEvents.meteorSpawnTimer = 0

-- Ring storm data
CosmicEvents.stormRings = {}

-- Initialize
function CosmicEvents.init()
    CosmicEvents.activeEvents = {}
    CosmicEvents.eventCooldown = CosmicEvents.minimumCooldown
    CosmicEvents.meteors = {}
    CosmicEvents.stormRings = {}
end

-- Update events
function CosmicEvents.update(dt, player, Camera)
    -- Update cooldown
    if CosmicEvents.eventCooldown > 0 then
        CosmicEvents.eventCooldown = CosmicEvents.eventCooldown - dt
    else
        -- Check for new events
        CosmicEvents.checkForNewEvent(player)
    end
    
    -- Update active events
    for i = #CosmicEvents.activeEvents, 1, -1 do
        local event = CosmicEvents.activeEvents[i]
        
        -- Update timer
        if event.warningTime > 0 then
            event.warningTime = event.warningTime - dt
        else
            event.active = true
            event.timer = event.timer - dt
            
            -- Update specific event
            if event.type == "meteor_shower" then
                CosmicEvents.updateMeteorShower(dt, player, Camera)
            elseif event.type == "ring_storm" then
                CosmicEvents.updateRingStorm(dt, player)
            end
        end
        
        -- Remove expired events
        if event.timer <= 0 then
            CosmicEvents.endEvent(event)
            table.remove(CosmicEvents.activeEvents, i)
        end
    end
    
    -- Update meteors
    CosmicEvents.updateMeteors(dt, player)
    
    -- Update storm rings
    CosmicEvents.updateStormRings(dt, player)
end

-- Check for new events
function CosmicEvents.checkForNewEvent(player)
    -- Safety check for player
    if not player or not player.x or not player.y then
        return
    end
    
    -- Don't spawn events too close to origin
    local distFromOrigin = math.sqrt(player.x^2 + player.y^2)
    if distFromOrigin < 500 then return end
    
    -- Roll for each event type
    for eventType, eventData in pairs(CosmicEvents.eventTypes) do
        if math.random() < eventData.probability * love.timer.getDelta() then
            CosmicEvents.startEvent(eventType)
            CosmicEvents.eventCooldown = CosmicEvents.minimumCooldown
            break
        end
    end
end

-- Start an event
function CosmicEvents.startEvent(eventType)
    local eventData = CosmicEvents.eventTypes[eventType]
    if not eventData then return end
    
    local event = {
        type = eventType,
        timer = eventData.duration,
        warningTime = eventData.warning,
        active = false,
        data = eventData
    }
    
    table.insert(CosmicEvents.activeEvents, event)
    
    -- Play warning sound
    local soundManager = Utils.Utils.require("src.audio.sound_manager")
    if soundManager and soundManager.playEventWarning then
        soundManager:playEventWarning()
    end
    
    Utils.Logger.info("Cosmic event started: %s", eventData.name)
end

-- End an event
function CosmicEvents.endEvent(event)
    if event.type == "meteor_shower" then
        -- Clear remaining meteors
        CosmicEvents.meteors = {}
    elseif event.type == "ring_storm" then
        -- Convert storm rings to regular rings
        local GameState = Utils.Utils.require("src.core.game_state")
        for _, ring in ipairs(CosmicEvents.stormRings) do
            if not ring.collected then
                table.insert(GameState.getRings(), ring)
            end
        end
        CosmicEvents.stormRings = {}
    end
end

-- Update meteor shower
function CosmicEvents.updateMeteorShower(dt, player, Camera)
    CosmicEvents.meteorSpawnTimer = CosmicEvents.meteorSpawnTimer - dt
    
    if CosmicEvents.meteorSpawnTimer <= 0 then
        -- Spawn new meteor
        local screenWidth, screenHeight = love.graphics.getDimensions()
        local x1, y1, x2, y2 = Camera:getVisibleArea()
        
        -- Spawn from edges
        local side = math.random(4)
        local meteor = {
            radius = 15 + math.random(10),
            damage = true
        }
        
        if side == 1 then -- Top
            meteor.x = math.random(x1, x2)
            meteor.y = y1 - 50
            meteor.vx = math.random(-100, 100)
            meteor.vy = math.random(200, 400)
        elseif side == 2 then -- Right
            meteor.x = x2 + 50
            meteor.y = math.random(y1, y2)
            meteor.vx = math.random(-400, -200)
            meteor.vy = math.random(-100, 100)
        elseif side == 3 then -- Bottom
            meteor.x = math.random(x1, x2)
            meteor.y = y2 + 50
            meteor.vx = math.random(-100, 100)
            meteor.vy = math.random(-400, -200)
        else -- Left
            meteor.x = x1 - 50
            meteor.y = math.random(y1, y2)
            meteor.vx = math.random(200, 400)
            meteor.vy = math.random(-100, 100)
        end
        
        -- Add trail effect
        meteor.trail = {}
        
        table.insert(CosmicEvents.meteors, meteor)
        CosmicEvents.meteorSpawnTimer = 0.5 + math.random() * 0.5
    end
end

-- Update meteors
function CosmicEvents.updateMeteors(dt, player)
    for i = #CosmicEvents.meteors, 1, -1 do
        local meteor = CosmicEvents.meteors[i]
        
        -- Update position
        meteor.x = meteor.x + meteor.vx * dt
        meteor.y = meteor.y + meteor.vy * dt
        
        -- Update trail
        table.insert(meteor.trail, 1, {
            x = meteor.x,
            y = meteor.y,
            life = 1.0
        })
        
        -- Update trail life
        for j = #meteor.trail, 1, -1 do
            meteor.trail[j].life = meteor.trail[j].life - dt * 3
            if meteor.trail[j].life <= 0 then
                table.remove(meteor.trail, j)
            end
        end
        
        -- Check collision with player
        if meteor.damage and Utils.circleCollision(
            player.x, player.y, player.radius,
            meteor.x, meteor.y, meteor.radius
        ) then
            -- Damage player (unless shielded)
            if not player.hasShield then
                local GameState = Utils.Utils.require("src.core.game_state")
                GameState.setState(GameState.STATES.GAME_OVER)
            else
                player.hasShield = false
                meteor.damage = false -- Can't damage twice
            end
        end
        
        -- Remove if too far
        local Camera = Utils.Utils.require("src.core.camera")
        local x1, y1, x2, y2 = Camera:getVisibleArea()
        if meteor.x < x1 - 200 or meteor.x > x2 + 200 or
           meteor.y < y1 - 200 or meteor.y > y2 + 200 then
            table.remove(CosmicEvents.meteors, i)
        end
    end
end

-- Update ring storm
function CosmicEvents.updateRingStorm(dt, player)
    -- Spawn rings around player
    if math.random() < 0.1 then
        local angle = math.random() * math.pi * 2
        local distance = 100 + math.random(300)
        
        local ring = {
            x = player.x + math.cos(angle) * distance,
            y = player.y + math.sin(angle) * distance,
            radius = 25,
            innerRadius = 15,
            rotation = 0,
            rotationSpeed = math.random(-2, 2),
            pulsePhase = 0,
            collected = false,
            value = 20,
            color = {1, 0.8, 0.2, 0.9},
            type = "storm",
            lifetime = 5
        }
        
        table.insert(CosmicEvents.stormRings, ring)
    end
end

-- Update storm rings
function CosmicEvents.updateStormRings(dt, player)
    local RingSystem = Utils.Utils.require("src.systems.ring_system")
    
    for i = #CosmicEvents.stormRings, 1, -1 do
        local ring = CosmicEvents.stormRings[i]
        
        -- Update ring
        ring.rotation = ring.rotation + ring.rotationSpeed * dt
        ring.pulsePhase = ring.pulsePhase + dt * 2
        ring.lifetime = ring.lifetime - dt
        
        -- Fade out
        if ring.lifetime < 1 then
            ring.color[4] = ring.lifetime
        end
        
        -- Check collection
        if not ring.collected and Utils.ringCollision(
            player.x, player.y, player.radius,
            ring.x, ring.y, ring.radius, ring.innerRadius
        ) then
            ring.collected = true
            -- Add bonus points during storm
            local GameState = Utils.Utils.require("src.core.game_state")
            GameState.addScore(ring.value * 2)
            GameState.addCombo()
        end
        
        -- Remove expired
        if ring.lifetime <= 0 or ring.collected then
            table.remove(CosmicEvents.stormRings, i)
        end
    end
end

-- Get active event modifiers
function CosmicEvents.getGravityModifier()
    for _, event in ipairs(CosmicEvents.activeEvents) do
        if event.active and event.type == "gravity_wave" then
            -- Oscillating gravity
            return 1 + math.sin(love.timer.getTime() * 3) * 0.5
        end
    end
    return 1
end

function CosmicEvents.getTimeModifier()
    for _, event in ipairs(CosmicEvents.activeEvents) do
        if event.active and event.type == "time_rift" then
            return 0.5 -- Half speed
        end
    end
    return 1
end

function CosmicEvents.isVoidSurgeActive()
    for _, event in ipairs(CosmicEvents.activeEvents) do
        if event.active and event.type == "void_surge" then
            return true
        end
    end
    return false
end

-- Draw events
function CosmicEvents.draw()
    -- Draw meteors
    for _, meteor in ipairs(CosmicEvents.meteors) do
        -- Draw trail
        for i, point in ipairs(meteor.trail) do
            Utils.setColor({1, 0.5, 0.2}, point.life * 0.5)
            local size = meteor.radius * point.life * 0.8
            love.graphics.circle("fill", point.x, point.y, size)
        end
        
        -- Draw meteor
        Utils.setColor({1, 0.4, 0.1})
        love.graphics.circle("fill", meteor.x, meteor.y, meteor.radius)
        Utils.setColor({1, 0.6, 0.2})
        love.graphics.circle("line", meteor.x, meteor.y, meteor.radius)
    end
    
    -- Draw storm rings
    for _, ring in ipairs(CosmicEvents.stormRings) do
        if not ring.collected then
            local pulse = math.sin(ring.pulsePhase) * 0.1 + 1
            Utils.setColor(ring.color)
            love.graphics.setLineWidth(3)
            
            -- Sparkly effect
            for i = 1, 8 do
                local angle = (i / 8) * math.pi * 2 + ring.rotation
                local sparkle = math.sin(ring.pulsePhase * 3 + i) * 0.5 + 0.5
                Utils.setColor({ring.color[1], ring.color[2], ring.color[3]}, ring.color[4] * sparkle)
                
                love.graphics.arc("line", "open", ring.x, ring.y, ring.radius * pulse,
                    angle - 0.2, angle + 0.2)
            end
        end
    end
end

-- Draw UI warnings
function CosmicEvents.drawUI()
    local screenWidth = love.graphics.getWidth()
    local y = 150
    
    for _, event in ipairs(CosmicEvents.activeEvents) do
        if event.warningTime > 0 then
            -- Warning phase
            local flash = math.sin(love.timer.getTime() * 10) * 0.5 + 0.5
            Utils.setColor(event.data.color[1], event.data.color[2], event.data.color[3], flash)
            
            love.graphics.setFont(love.graphics.getFont())
            love.graphics.printf("⚠ " .. event.data.name .. " INCOMING! ⚠", 
                0, y, screenWidth, "center")
            
            Utils.setColor({1, 1, 1}, flash * 0.8)
            love.graphics.printf(event.data.description,
                0, y + 20, screenWidth, "center")
        elseif event.active then
            -- Active phase
            Utils.setColor(event.data.color)
            love.graphics.printf(event.data.name .. " ACTIVE",
                0, y, screenWidth, "center")
            
            -- Progress bar
            local barWidth = 200
            local barX = (screenWidth - barWidth) / 2
            local progress = event.timer / event.data.duration
            
            Utils.setColor({0, 0, 0}, 0.5)
            love.graphics.rectangle("fill", barX, y + 25, barWidth, 6)
            
            Utils.setColor(event.data.color)
            love.graphics.rectangle("fill", barX, y + 25, barWidth * progress, 6)
        end
        
        y = y + 50
    end
end

return CosmicEvents