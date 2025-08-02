-- Enhanced Ring System for Orbit Jump
-- Manages special ring types and their effects
local Utils = require("src.utils.utils")
local RingRaritySystem = Utils.require("src.systems.ring_rarity_system")
local RingSystem = {}
-- Initialize the ring system
function RingSystem.init()
    -- Initialize rarity system
    RingRaritySystem.init()
    return true
end
-- Ring type definitions
RingSystem.types = {
    standard = {
        value = 10,
        color = {0.3, 0.7, 1, 0.8},
        effect = nil
    },
    power_shield = {
        value = 20,
        color = {0.2, 1, 0.2, 0.9},
        effect = "shield",
        duration = 5,
        rarity = 0.1
    },
    power_magnet = {
        value = 20,
        color = {1, 0.2, 1, 0.9},
        effect = "magnet",
        duration = 8,
        magnetRange = 150,
        rarity = 0.1
    },
    power_slowmo = {
        value = 25,
        color = {0.2, 0.8, 1, 0.9},
        effect = "slowmo",
        duration = 3,
        timeScale = 0.5,
        rarity = 0.08
    },
    power_multijump = {
        value = 30,
        color = {1, 1, 0.2, 0.9},
        effect = "multijump",
        duration = 10,
        extraJumps = 1,
        rarity = 0.08
    },
    warp = {
        value = 15,
        color = {0.5, 0.2, 1, 0.9},
        effect = "warp",
        rarity = 0.05,
        innerGlow = true
    },
    ghost = {
        value = 40,
        color = {0.8, 0.8, 0.8, 0.5},
        effect = "ghost",
        phaseTime = 2,
        phaseSpeed = 2,
        rarity = 0.05
    },
    chain = {
        value = 5,
        color = {1, 0.7, 0.2, 0.9},
        effect = "chain",
        chainBonus = 50,
        rarity = 0.15
    }
}
-- Active power-ups
RingSystem.activePowers = {}
RingSystem.warpPairs = {}
RingSystem.chainSequence = {}
RingSystem.currentChain = 1
function RingSystem.generateRing(x, y, planetType)
    local ring = {
        x = x,
        y = y,
        radius = 25 + math.random(0, 10),
        innerRadius = 15 + math.random(0, 5),
        rotation = math.random() * math.pi * 2,
        rotationSpeed = (math.random() - 0.5) * 2,
        pulsePhase = math.random() * math.pi * 2,
        collected = false
    }
    
    -- Determine ring type based on rarity
    local roll = math.random()
    local cumulativeRarity = 0
    
    for typeName, typeData in pairs(RingSystem.types) do
        if typeData.rarity then
            cumulativeRarity = cumulativeRarity + typeData.rarity
            if roll < cumulativeRarity then
                ring.type = typeName
                ring.value = typeData.value
                ring.color = typeData.color
                ring.effect = typeData.effect
                
                -- Special properties
                if typeName == "ghost" then
                    ring.phaseTimer = 0
                elseif typeName == "warp" then
                    -- Create warp pair if needed
                    if not RingSystem.warpPairs[ring] then
                        ring.pairId = tostring(love.timer.getTime()) .. math.random()
                    end
                elseif typeName == "chain" then
                    -- Assign chain number
                    ring.chainNumber = #RingSystem.chainSequence + 1
                    table.insert(RingSystem.chainSequence, ring)
                end
                
                return ring
            end
        end
    end
    
    -- Default to standard ring
    ring.type = "standard"
    ring.value = RingSystem.types.standard.value
    ring.color = RingSystem.types.standard.color
    
    -- Planet-specific ring modifications
    if planetType == "ice" then
        ring.color = {0.6, 0.8, 1, 0.8}
        ring.value = ring.value * 2
    elseif planetType == "lava" then
        ring.color = {1, 0.6, 0.2, 0.8}
        ring.value = ring.value * 3
    elseif planetType == "tech" then
        ring.color = {0.2, 1, 0.8, 0.8}
        ring.value = ring.value * 2.5
    elseif planetType == "void" then
        ring.color = {0.5, 0.3, 0.7, 0.6}
        ring.value = ring.value * 4
    end
    
    -- ADDICTION ENGINE: Apply rarity system to ring
    if RingRaritySystem then
        local rarity = RingRaritySystem.determineRarity()
        RingRaritySystem.applyRarityToRing(ring, rarity)
    end
    
    return ring
end
function RingSystem.updateRing(ring, dt)
    if ring.collected then return end
    
    -- Apply time scaling for events (time dilation effect)
    local GameState = require("src.core.game_state")
    local scaledDt = dt * (GameState.world_time_scale or 1.0)
    
    -- Apply velocity if present (for event rings)
    if ring.vx or ring.vy then
        ring.x = ring.x + (ring.vx or 0) * scaledDt
        ring.y = ring.y + (ring.vy or 0) * scaledDt
    end
    
    -- Standard rotation and pulse
    ring.rotation = ring.rotation + ring.rotationSpeed * scaledDt
    ring.pulsePhase = ring.pulsePhase + scaledDt * 2
    
    -- Special animations
    if ring.type == "ghost" then
        ring.phaseTimer = ring.phaseTimer + dt * RingSystem.types.ghost.phaseSpeed
        local alpha = (math.sin(ring.phaseTimer) + 1) * 0.5
        ring.visible = alpha > 0.3
        ring.color[4] = alpha * 0.8
    elseif ring.type == "warp" then
        -- Warp rings spin faster
        ring.rotation = ring.rotation + dt * 3
    elseif ring.type == "chain" then
        -- Chain rings pulse in sequence
        if ring.chainNumber == RingSystem.currentChain then
            ring.pulsePhase = ring.pulsePhase + dt * 4
        end
    end
end
function RingSystem.collectRing(ring, player)
    if ring.collected then return 0 end
    
    ring.collected = true
    
    -- Track constellation patterns
    local success, RingConstellations  = Utils.ErrorHandler.safeCall(require, "src.systems.ring_constellations")
    if success and RingConstellations.onRingCollected then
        RingConstellations.onRingCollected(ring, player)
    end
    
    -- Notify social systems
    local WeeklyChallengesSystem = Utils.safeRequire("src.systems.weekly_challenges_system")
    if WeeklyChallengesSystem then
        WeeklyChallengesSystem:onRingsCollected(1)
        if ring.rarity == "legendary" then
            WeeklyChallengesSystem:onLegendaryRingCollected()
        end
    end
    
    local GlobalEventsSystem = Utils.safeRequire("src.systems.global_events_system")
    if GlobalEventsSystem then
        GlobalEventsSystem:onRingsCollected(1)
        if ring.rarity == "legendary" then
            GlobalEventsSystem:onLegendaryRingCollected()
        end
    end
    
    -- Apply ring effects
    local typeData = RingSystem.types[ring.type]
    
    if ring.effect == "shield" then
        local shieldDuration = typeData and typeData.duration or 5
        -- Try to get upgrade effect, but don't fail if upgrade system doesn't exist
        local upgradeMultiplier = 1
        local success, upgradeSystem  = Utils.ErrorHandler.safeCall(require, "upgrade_system")
        if success and upgradeSystem then
            upgradeMultiplier = upgradeSystem.getEffect and upgradeSystem.getEffect("shield_duration") or 1
        end
        RingSystem.activatePower("shield", shieldDuration * upgradeMultiplier)
        player.hasShield = true
    elseif ring.effect == "magnet" then
        local duration = typeData and typeData.duration or 8
        RingSystem.activatePower("magnet", duration)
        player.magnetRange = typeData and typeData.magnetRange or 150
    elseif ring.effect == "slowmo" then
        local duration = typeData and typeData.duration or 3
        RingSystem.activatePower("slowmo", duration)
    elseif ring.effect == "multijump" then
        local duration = typeData and typeData.duration or 10
        RingSystem.activatePower("multijump", duration)
        local extraJumps = typeData and typeData.extraJumps or 1
        player.extraJumps = (player.extraJumps or 0) + extraJumps
    elseif ring.effect == "warp" then
        -- Teleport to paired ring
        local pair = RingSystem.findWarpPair(ring)
        if pair and not pair.collected then
            player.x = pair.x
            player.y = pair.y
            pair.collected = true
        end
    elseif ring.effect == "chain" then
        -- Check if collected in correct order
        if ring.chainNumber == RingSystem.currentChain then
            RingSystem.currentChain = RingSystem.currentChain + 1
            
            -- Bonus for completing chain
            if RingSystem.currentChain > #RingSystem.chainSequence then
                -- Track achievement
                local success, achievementSystem  = Utils.ErrorHandler.safeCall(require, "achievement_system")
                if success and achievementSystem and achievementSystem.onChainCompleted then
                    achievementSystem.onChainCompleted(#RingSystem.chainSequence)
                end
                return ring.value * 10 -- Massive bonus!
            end
        else
            -- Reset chain if wrong order
            RingSystem.currentChain = 1
        end
    end
    
    -- ADDICTION ENGINE: Apply rarity system bonuses
    local baseValue = ring.value or (RingSystem.types[ring.type] and RingSystem.types[ring.type].value) or 5
    if RingRaritySystem and RingRaritySystem.onRingCollected then
        return RingRaritySystem.onRingCollected(ring, player, nil) or baseValue
    end
    
    -- Return ring value (with fallback to type value or default)
    return baseValue
end
function RingSystem.activatePower(power, duration)
    RingSystem.activePowers[power] = {
        duration = duration,
        startTime = love.timer.getTime()
    }
end
function RingSystem.updatePowers(dt)
    local currentTime = love.timer.getTime()
    
    for power, data in pairs(RingSystem.activePowers) do
        if currentTime - data.startTime > data.duration then
            RingSystem.activePowers[power] = nil
            
            -- Deactivate effects
            local GameState = Utils.require("src.core.game_state")
            if power == "shield" and GameState and GameState.player then
                GameState.player.hasShield = false
            elseif power == "magnet" and GameState and GameState.player then
                GameState.player.magnetRange = nil
            elseif power == "multijump" and GameState and GameState.player then
                GameState.player.extraJumps = 0
            end
        end
    end
end
function RingSystem.isActive(power)
    return RingSystem.activePowers[power] ~= nil
end
function RingSystem.getTimeScale()
    if RingSystem.isActive("slowmo") then
        return RingSystem.types.power_slowmo.timeScale
    end
    return 1.0
end
function RingSystem.findWarpPair(ring)
    -- GameState needs to be passed in or required
    local GameState = Utils.require("src.core.game_state")
    for _, r in pairs(GameState.getRings()) do
        if r ~= ring and r.type == "warp" and r.pairId == ring.pairId then
            return r
        end
    end
    return nil
end
function RingSystem.applyMagnetEffect(player, rings)
    if not player.magnetRange then return end
    
    for _, ring in ipairs(rings) do
        if not ring.collected then
            local dist = Utils.distance(player.x, player.y, ring.x, ring.y)
            if dist < player.magnetRange then
                -- Pull ring towards player
                local pullStrength = (1 - dist / player.magnetRange) * 200
                local dx = player.x - ring.x
                local dy = player.y - ring.y
                local nx, ny = Utils.normalize(dx, dy)
                
                ring.x = ring.x + nx * pullStrength * love.timer.getDelta()
                ring.y = ring.y + ny * pullStrength * love.timer.getDelta()
            end
        end
    end
end
function RingSystem.reset()
    RingSystem.activePowers = {}
    RingSystem.warpPairs = {}
    RingSystem.chainSequence = {}
    RingSystem.currentChain = 1
    
    -- Generate initial rings
    local GameState = Utils.require("src.core.game_state")
    local planets = GameState.getPlanets()
    if planets and #planets > 0 then
        local rings = RingSystem.generateRings(planets)
        GameState.setRings(rings)
    end
    return true
end
-- Generate rings around planets
function RingSystem.generateRings(planets, count)
    local rings = {}
    count = count or 10  -- Default to 10 rings if not specified
    
    for i = 1, count do
        -- Select a random planet
        local planet = planets[math.random(#planets)]
        if planet then
            -- Generate ring at random position around planet
            local angle = math.random() * math.pi * 2
            local distance = planet.radius + 50 + math.random(0, 100)
            local x = planet.x + math.cos(angle) * distance
            local y = planet.y + math.sin(angle) * distance
            
            local ring = RingSystem.generateRing(x, y, planet.type)
            table.insert(rings, ring)
        end
    end
    
    return rings
end
return RingSystem