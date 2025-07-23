-- Collision System for Orbit Jump
-- Handles all collision detection and response

local Utils = require("src.utils.utils")
local GameLogic = require("src.core.game_logic")

local CollisionSystem = {}

-- Check collisions with planets
function CollisionSystem.checkPlanetCollisions(player, planets, spatialGrid, gameState, soundManager)
    if not player or player.onPlanet then
        return
    end
    
    -- Use spatial grid if available, otherwise brute force
    local nearbyPlanets = planets or {}
    if spatialGrid and spatialGrid.getObjectsInRadius and planets then
        nearbyPlanets = spatialGrid:getObjectsInRadius(
            player.x, player.y, 
            player.radius + 200  -- Check slightly larger radius
        )
    end
    
    for _, planet in ipairs(nearbyPlanets) do
        if Utils.circleCollision(
            player.x, player.y, player.radius,
            planet.x, planet.y, planet.radius
        ) then
            CollisionSystem.handlePlanetLanding(player, planet, gameState, soundManager)
            return planet  -- Return the planet we landed on
        end
    end
    
    return nil
end

-- Handle landing on a planet
function CollisionSystem.handlePlanetLanding(player, planet, gameState, soundManager)
    -- Calculate landing angle
    local dx = player.x - planet.x
    local dy = player.y - planet.y
    player.angle = Utils.atan2(dy, dx)
    
    -- Set player state - find planet index
    local gameState = require("src.core.game_state")
    local planets = gameState.getPlanets()
    for i, p in ipairs(planets) do
        if p == planet then
            player.onPlanet = i  -- Set to planet index, not boolean
            break
        end
    end
    
    -- Adjust position to planet surface
    local orbitRadius = planet.radius + player.radius + 5
    player.x = planet.x + math.cos(player.angle) * orbitRadius
    player.y = planet.y + math.sin(player.angle) * orbitRadius
    
    -- Reset velocity
    player.vx = 0
    player.vy = 0
    
    -- Handle special planet types
    if planet.type == "quantum" then
        CollisionSystem.handleQuantumTeleport(player, planet, gameState)
    end
    
    -- Play landing sound
    if soundManager and soundManager.playLand then
        soundManager:playLand()
    end
    
    -- Track planet discovery
    CollisionSystem.trackPlanetDiscovery(planet, gameState)
end

-- Handle quantum planet teleportation
function CollisionSystem.handleQuantumTeleport(player, planet, gameState)
    local CosmicEvents = require("src.systems.cosmic_events")
    local WarpDrive = require("src.systems.warp_drive")
    
    -- Create quantum effect
    if CosmicEvents then
        CosmicEvents.triggerQuantumTeleport(planet.x, planet.y)
    end
    
    -- Find random distant planet
    local planets = gameState.getPlanets()
    local targetPlanet = nil
    local maxAttempts = 10
    
    for i = 1, maxAttempts do
        local candidate = planets[math.random(#planets)]
        local distance = Utils.distance(planet.x, planet.y, candidate.x, candidate.y)
        
        if distance > 1000 and candidate ~= planet then
            targetPlanet = candidate
            break
        end
    end
    
    if targetPlanet then
        -- Teleport player
        player.x = targetPlanet.x + targetPlanet.radius + player.radius + 10
        player.y = targetPlanet.y
        player.currentPlanet = targetPlanet.id or 1
        
        -- Create warp effect
        if WarpDrive then
            WarpDrive.createWarpEffect(planet.x, planet.y, targetPlanet.x, targetPlanet.y)
        end
    end
end

-- Track planet discovery for progression
function CollisionSystem.trackPlanetDiscovery(planet, gameState)
    local ProgressionSystem = require("src.systems.progression_system")
    local AchievementSystem = require("src.systems.achievement_system")
    local MapSystem = require("src.systems.map_system")
    local PlanetLore = require("src.systems.planet_lore")
    
    -- Mark planet as discovered
    if not planet.discovered then
        planet.discovered = true
        
        -- Update progression
        if ProgressionSystem and ProgressionSystem.onPlanetDiscovered then
            ProgressionSystem.onPlanetDiscovered(planet)
        end
        
        -- Check achievements
        if AchievementSystem and AchievementSystem.onPlanetDiscovered then
            AchievementSystem.onPlanetDiscovered(planet.type)
        end
        
        -- Map system will automatically track discovered planets in its update
        
        -- Show lore
        if PlanetLore and planet.lore then
            PlanetLore.showLore(planet)
        end
        
        -- Add discovery bonus
        if gameState then
            gameState.addScore(100)
        end
    end
end

-- Check collisions with rings
function CollisionSystem.checkRingCollisions(player, rings, spatialGrid, gameState, soundManager)
    if not player or player.onPlanet then
        return {}
    end
    
    -- Use spatial grid if available
    local nearbyRings = rings or {}
    if spatialGrid and spatialGrid.getObjectsInRadius and rings then
        nearbyRings = spatialGrid:getObjectsInRadius(
            player.x, player.y,
            player.radius + 50
        )
    end
    
    local RingSystem = require("src.systems.ring_system")
    local collectedRings = {}
    
    for _, ring in ipairs(nearbyRings) do
        if not ring.collected and Utils.circleCollision(
            player.x, player.y, player.radius,
            ring.x, ring.y, ring.radius
        ) then
            -- Collect ring
            local value = RingSystem.collectRing(ring, gameState)
            
            -- Update score and combo
            if gameState and gameState.addScore then
                gameState.addScore(value)
                if gameState.addCombo then
                    gameState.addCombo()
                end
            end
            
            -- Create visual effect
            CollisionSystem.createRingBurst(ring, player)
            
            -- Play sound
            if soundManager then
                soundManager:playCollectRing()
            end
            
            table.insert(collectedRings, ring)
        end
    end
    
    return collectedRings
end

-- Create particle burst when collecting ring
function CollisionSystem.createRingBurst(ring, player)
    local ParticleSystem = require("src.systems.particle_system")
    if not ParticleSystem then return end
    
    local burstCount = 20
    for i = 1, burstCount do
        local angle = (i / burstCount) * math.pi * 2
        local speed = 100 + math.random() * 200
        local vx = math.cos(angle) * speed
        local vy = math.sin(angle) * speed
        
        -- Add some player velocity influence
        if player then
            vx = vx + player.vx * 0.2
            vy = vy + player.vy * 0.2
        end
        
        ParticleSystem.create(
            ring.x, ring.y,
            vx, vy,
            ring.color or {1, 0.8, 0, 1},
            0.5 + math.random() * 0.5,
            2 + math.random() * 2
        )
    end
end

-- Check if player is inside a ring (for special ring types)
function CollisionSystem.isPlayerInRing(player, ring)
    local distance = Utils.distance(player.x, player.y, ring.x, ring.y)
    return distance < ring.outerRadius and distance > ring.innerRadius - player.radius
end

-- Update spatial grid with current positions
function CollisionSystem.updateSpatialGrid(spatialGrid, planets, rings)
    if not spatialGrid then return end
    
    -- Clear grid
    spatialGrid:clear()
    
    -- Add planets
    for _, planet in ipairs(planets) do
        spatialGrid:addObject(planet.x, planet.y, planet)
    end
    
    -- Add rings
    for _, ring in ipairs(rings) do
        if not ring.collected then
            spatialGrid:addObject(ring.x, ring.y, ring)
        end
    end
end

return CollisionSystem