-- Optimized Functions for Orbit Jump
-- Contains performance-optimized versions of critical functions
local Utils = require("src.utils.utils")
local OptimizedFunctions = {}
-- Optimized planet collision detection using spatial grid
function OptimizedFunctions.checkPlanetCollisions(player, planets, spatialGrid, GameState, soundManager, UpgradeSystem, MapSystem, AchievementSystem, ProgressionSystem, PlanetLore, BlockchainIntegration, Camera)
    if not GameState.isPlayerInSpace() then
        return
    end
    -- Use spatial grid to only check nearby planets
    local nearbyObjects = spatialGrid.getObjectsInRadius(player.x, player.y, 200)
    for _, obj in ipairs(nearbyObjects) do
        if obj.type == "planet" and Utils.circleCollision(player.x, player.y, player.radius, obj.x, obj.y, obj.radius) then
            -- Find planet index in main array
            local planetIndex = nil
            local planet = nil
            for i, p in ipairs(planets) do
                if p == obj then
                    planetIndex = i
                    planet = p
                    break
                end
            end
            if planetIndex and planet then
                -- Land on planet
                GameState.setPlayerOnPlanet(planetIndex)
                local dx = player.x - planet.x
                local dy = player.y - planet.y
                player.angle = Utils.atan2(dy, dx)
                -- Mark planet as discovered
                local wasDiscovered = planet.discovered
                if not planet.discovered then
                    planet.discovered = true
                    local discoveryBonus = 100 * UpgradeSystem.getEffect("exploration_bonus")
                    GameState.addScore(math.floor(discoveryBonus))
                    -- Track in map system
                    MapSystem.discoverPlanet(planet)
                    -- Achievement tracking
                    local discoveredCount = 0
                    for _, p in ipairs(planets) do
                        if p.discovered then
                            discoveredCount = discoveredCount + 1
                        end
                    end
                    AchievementSystem.onPlanetDiscovery(planet.type or "standard", discoveredCount)
                    -- Show discovery message
                    GameState.addMessage("New planet discovered!")
                    soundManager:playDiscover()
                    -- Progression tracking
                    ProgressionSystem.onPlanetDiscovered(planet.type or "standard")
                    -- Trigger lore for special planets
                    PlanetLore.triggerLore(planet)
                    -- Blockchain achievement for special planets
                    if planet.type and (planet.type == "void" or planet.type == "tech" or planet.type == "ice" or planet.type == "lava") then
                        BlockchainIntegration.triggerPlanetDiscovered(planet.type or "standard", planet.x, planet.y)
                    end
                    -- Camera shake on discovery
                    if Camera.shake then
                        Camera:shake(10, 0.3)
                    end
                else
                    GameState.addScore(1)
                    AchievementSystem.onPerfectLanding()
                end
                -- Adjust position to be on surface
                local orbitRadius = planet.radius + player.radius + 5
                player.x = planet.x + math.cos(player.angle) * orbitRadius
                player.y = planet.y + math.sin(player.angle) * orbitRadius
                -- Play landing sound
                soundManager:playLand()
                -- Quantum planets randomly teleport the player
                if planet.type == "quantum" and not wasDiscovered then
                    -- Teleport to a random nearby planet after a short delay
                    planet.quantumTeleportTimer = 2.0 -- 2 seconds until teleport
                end
                break -- Only land on one planet at a time
            end
        end
    end
end
-- Optimized ring collision detection
function OptimizedFunctions.checkRingCollisions(player, rings, spatialGrid, GameState, soundManager, RingSystem, createRingBurst)
    if player.onPlanet then
        return
    end
    -- Use spatial grid for nearby rings
    local nearbyObjects = spatialGrid.getObjectsInRadius(player.x, player.y, 150)
    for _, obj in ipairs(nearbyObjects) do
        if obj.type == "ring" and not obj.collected then
            -- Find the actual ring object
            local ring = nil
            for _, r in ipairs(rings) do
                if r == obj then
                    ring = r
                    break
                end
            end
            if ring and Utils.circleCollision(player.x, player.y, player.radius,
                                            ring.x, ring.y, ring.innerRadius) and
               not Utils.circleCollision(player.x, player.y, player.radius,
                                       ring.x, ring.y, ring.radius) then
                RingSystem.collectRing(ring, player)
                createRingBurst(ring)
                soundManager:playCollect()
            end
        end
    end
end
return OptimizedFunctions