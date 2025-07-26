--[[
    ═══════════════════════════════════════════════════════════════════════════
    Adaptive Warp Drive: The Learning Heart of Interstellar Travel
    ═══════════════════════════════════════════════════════════════════════════
    
    This isn't just a fast travel system - it's an adaptive intelligence that
    learns from every journey you take. The warp drive studies your behavior,
    remembers your preferences, and evolves to serve you better over time.
    
    101% Philosophy: "Systems that don't just work, but improve with intimacy"
    
    Adaptive Memory Features:
    • Route Optimization: Learns your most common paths and reduces costs
    • Efficiency Learning: Adapts energy consumption based on your piloting skill
    • Preference Memory: Remembers which planets you visit most and prioritizes them
    • Emergency Recognition: Detects distress warps and provides cost relief
    • Mastery Rewards: Unlocks advanced capabilities as you demonstrate expertise
    
    The Memory Architecture:
    Every warp creates a learning opportunity. The system builds a model of
    your play style, spatial preferences, and skill progression. This model
    influences every future interaction, creating a warp drive that feels
    increasingly attuned to your unique journey through space.
--]]

local Utils = require("src.utils.utils")
local WarpDrive = {}

-- Core Warp State
WarpDrive.isUnlocked = false
WarpDrive.isWarping = false
WarpDrive.warpTarget = nil
WarpDrive.warpProgress = 0
WarpDrive.warpDuration = 2.0 -- 2 seconds for warp animation
WarpDrive.energyCost = 100 -- Base energy cost
WarpDrive.energy = 1000 -- Current energy
WarpDrive.maxEnergy = 1000
WarpDrive.energyRegenRate = 50 -- Per second

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Adaptive Memory Systems: The Soul of Learning Technology
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Adaptive Learning Memory: The system's consciousness
WarpDrive.memory = {
    -- Route Learning: Builds a map of player's spatial preferences
    routes = {},              -- {planetA_id .. "->" .. planetB_id = {uses=N, totalCost=N, avgEfficiency=N}}
    
    -- Behavioral Analysis: Understanding how the player uses warp technology
    behaviorProfile = {
        totalWarps = 0,
        emergencyWarps = 0,      -- Warps used when player is in danger
        explorationWarps = 0,    -- Warps to unexplored areas
        returnWarps = 0,         -- Warps back to familiar planets
        averageWarpDistance = 0,
        preferredWarpTimes = {}, -- Times of day/session when player warps most
        skillLevel = 0,          -- 0-1 scale of warp mastery
        lastWarpTime = 0,
        warpChains = 0           -- Multiple warps in quick succession
    },
    
    -- Planet Affinity: Which worlds does the player love?
    planetAffinity = {},      -- {planet_id = {visits=N, lastVisit=time, affinity=0-1}}
    
    -- Efficiency Learning: How well does the player plan their warps?
    efficiencyMetrics = {
        wastedEnergy = 0,        -- Energy spent on inefficient routes
        optimalRoutes = 0,       -- Times player chose the best possible route
        learningCurve = {},      -- Track improvement over time
        adaptationLevel = 0      -- How much the system should adapt (0-1)
    },
    
    -- Emergency Detection: Recognizing when player needs help
    emergencyPatterns = {
        lowHealthWarps = 0,      -- Warps when health is critical
        panicWarps = 0,          -- Rapid successive warps (fleeing behavior)
        rescueWarps = 0,         -- Warps away from dangerous situations
        lastEmergencyTime = 0
    }
}

-- Visual effects
WarpDrive.warpEffectAlpha = 0
WarpDrive.tunnelRotation = 0
WarpDrive.particles = {}

-- Selection state
WarpDrive.isSelecting = false
WarpDrive.selectedPlanet = nil
WarpDrive.selectionRadius = 50

-- Initialize with Memory Restoration
function WarpDrive.init()
    WarpDrive.isUnlocked = false
    WarpDrive.energy = WarpDrive.maxEnergy
    WarpDrive.particles = {}
    
    -- Initialize adaptive memory structures
    WarpDrive.initializeMemorySystem()
    
    -- Restore learned behavior from save data
    WarpDrive.restoreMemoryFromSave()
    
    Utils.Logger.info("🧠 Warp Drive memory system initialized - Ready to learn")
    return true
end

-- Initialize the memory system architecture
function WarpDrive.initializeMemorySystem()
    -- Ensure all memory structures exist with safe defaults
    if not WarpDrive.memory then
        WarpDrive.memory = {
            routes = {},
            behaviorProfile = {
                totalWarps = 0,
                emergencyWarps = 0,
                explorationWarps = 0,
                returnWarps = 0,
                averageWarpDistance = 0,
                preferredWarpTimes = {},
                skillLevel = 0,
                lastWarpTime = 0,
                warpChains = 0
            },
            planetAffinity = {},
            efficiencyMetrics = {
                wastedEnergy = 0,
                optimalRoutes = 0,
                learningCurve = {},
                adaptationLevel = 0
            },
            emergencyPatterns = {
                lowHealthWarps = 0,
                panicWarps = 0,
                rescueWarps = 0,
                lastEmergencyTime = 0
            }
        }
    end
end

-- Restore memory from persistent storage
function WarpDrive.restoreMemoryFromSave()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.getData then
        local saveData = SaveSystem.getData()
        if saveData and saveData.warpDriveMemory then
            -- Restore learned behaviors and preferences
            WarpDrive.memory = Utils.mergeTables(WarpDrive.memory, saveData.warpDriveMemory)
            
            local memoryStats = WarpDrive.getMemoryStats()
            Utils.Logger.info("💾 Memory restored: %d routes, %d warps, %.1f%% efficiency",
                memoryStats.knownRoutes, memoryStats.totalWarps, memoryStats.efficiency * 100)
        end
    end
end

-- Unlock warp drive
function WarpDrive.unlock()
    WarpDrive.isUnlocked = true
    
    -- Achievement
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem.onWarpDriveUnlocked then
        AchievementSystem.onWarpDriveUnlocked()
    end
    
    Utils.Logger.info("Warp Drive unlocked!")
end

-- Adaptive Warp Affordability Check
function WarpDrive.canAffordWarp(targetPlanet, currentPlayer, gameContext)
    if not WarpDrive.isUnlocked then return false end
    if not targetPlanet.discovered then return false end
    
    local distance = Utils.distance(currentPlayer.x, currentPlayer.y, targetPlanet.x, targetPlanet.y)
    local cost = WarpDrive.calculateCost(distance, currentPlayer.x, currentPlayer.y, targetPlanet, gameContext)
    
    return WarpDrive.energy >= cost
end

-- Adaptive Cost Calculation: The Heart of Learning Economics
function WarpDrive.calculateCost(distance, sourceX, sourceY, targetPlanet, gameContext)
    --[[
        The Evolution of Warp Economics
        
        This function represents the culmination of adaptive system design.
        What started as a simple distance calculation has evolved into a
        sophisticated AI that understands your needs, rewards your mastery,
        and adapts to your play style.
        
        The algorithm considers:
        1. Base physics cost (distance energy requirements)
        2. Route familiarity (learned efficiency bonuses)
        3. Player skill level (mastery reduces costs)
        4. Emergency situations (compassionate cost relief)
        5. Exploration incentives (encouraging discovery)
        6. Behavioral patterns (adapting to your preferred play style)
    --]]
    
    -- Foundation: Physics-based cost scaling
    local baseCost = math.max(50, math.floor(distance / 100))
    
    -- If no adaptive context provided, fall back to static calculation
    if not sourceX or not targetPlanet or not gameContext then
        return baseCost
    end
    
    -- Learning Factor 1: Route Familiarity Bonus
    local routeKey = WarpDrive.generateRouteKey(sourceX, sourceY, targetPlanet)
    local routeMemory = WarpDrive.memory.routes[routeKey]
    local familiarityBonus = 1.0
    
    if routeMemory and routeMemory.uses > 0 then
        -- Reward familiar routes with increasing efficiency
        -- More uses = lower cost (max 25% reduction)
        local familiarity = math.min(routeMemory.uses / 10, 1.0)
        familiarityBonus = 1.0 - (familiarity * 0.25)
        
        Utils.Logger.debug("Route familiarity bonus: %.2f%% reduction", (1 - familiarityBonus) * 100)
    end
    
    -- Learning Factor 2: Player Mastery Scaling
    local masteryMultiplier = WarpDrive.calculateMasteryMultiplier()
    
    -- Learning Factor 3: Emergency Compassion
    local emergencyFactor = WarpDrive.detectEmergencyWarp(gameContext)
    local compassionMultiplier = 1.0
    if emergencyFactor > 0.5 then
        -- Reduce cost during emergencies (the warp drive "helps" the player)
        compassionMultiplier = 0.7 - (emergencyFactor * 0.3) -- Up to 60% reduction
        Utils.Logger.info("🆘 Emergency warp detected - applying %.0f%% cost relief", 
            (1 - compassionMultiplier) * 100)
    end
    
    -- Learning Factor 4: Exploration Incentive
    local explorationBonus = WarpDrive.calculateExplorationBonus(targetPlanet)
    
    -- Learning Factor 5: Planet Affinity
    local affinityBonus = WarpDrive.calculateAffinityBonus(targetPlanet)
    
    -- Synthesis: Combine all learning factors
    local adaptiveCost = baseCost * familiarityBonus * masteryMultiplier * 
                        compassionMultiplier * explorationBonus * affinityBonus
    
    -- Ensure reasonable bounds (never less than 25% of base cost)
    local finalCost = math.max(math.floor(baseCost * 0.25), math.floor(adaptiveCost))
    
    -- Log the learning process for transparency
    WarpDrive.logCostCalculation(baseCost, finalCost, {
        familiarity = familiarityBonus,
        mastery = masteryMultiplier,
        emergency = compassionMultiplier,
        exploration = explorationBonus,
        affinity = affinityBonus
    })
    
    return finalCost
end

-- Generate consistent route key for memory storage
function WarpDrive.generateRouteKey(sourceX, sourceY, targetPlanet)
    -- Create a standardized key that represents this route
    local sourceKey = math.floor(sourceX / 100) .. "," .. math.floor(sourceY / 100)
    local targetKey = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    return sourceKey .. "->" .. targetKey
end

-- Adaptive Warp Initiation: Learning in Real-Time
function WarpDrive.startWarp(targetPlanet, player, gameContext)
    --[[
        The Moment of Learning: Every Warp Teaches Us Something
        
        This function has evolved from simple teleportation into a learning
        opportunity. Every warp attempt - successful or failed - provides data
        about player behavior, preferences, and skill development.
    --]]
    
    -- Enhanced affordability check with game context
    if not WarpDrive.canAffordWarp(targetPlanet, player, gameContext) then
        -- Even failed attempts teach us about player intent
        WarpDrive.learnFromFailedWarp(targetPlanet, player, gameContext)
        return false
    end
    
    local distance = Utils.distance(player.x, player.y, targetPlanet.x, targetPlanet.y)
    local cost = WarpDrive.calculateCost(distance, player.x, player.y, targetPlanet, gameContext)
    
    -- Store warp initiation data for learning
    WarpDrive.warpInitiation = {
        sourceX = player.x,
        sourceY = player.y,
        targetPlanet = targetPlanet,
        actualCost = cost,
        startTime = love.timer.getTime(),
        gameContext = gameContext
    }
    
    -- Deduct energy
    WarpDrive.energy = WarpDrive.energy - cost
    
    -- Set warp state
    WarpDrive.isWarping = true
    WarpDrive.warpTarget = targetPlanet
    WarpDrive.warpProgress = 0
    
    -- Create adaptive warp particles (intensity based on cost efficiency)
    WarpDrive.createWarpParticles(player, cost)
    
    -- Play adaptive sound (pitch/intensity based on system familiarity)
    WarpDrive.playAdaptiveWarpSound(targetPlanet, cost)
    
    Utils.Logger.info("✨ Warp initiated: cost %d, efficiency %.1f%%", 
        cost, (100 / math.max(1, cost / 50)))
    
    return true
end

-- Learn from failed warp attempts
function WarpDrive.learnFromFailedWarp(targetPlanet, player, gameContext)
    -- Track what players want but can't afford - helps with future balancing
    local distance = Utils.distance(player.x, player.y, targetPlanet.x, targetPlanet.y)
    local wouldCost = WarpDrive.calculateCost(distance, player.x, player.y, targetPlanet, gameContext)
    local energyShortfall = wouldCost - WarpDrive.energy
    
    Utils.Logger.debug("🚫 Failed warp attempt: needed %d, have %d (short %d)", 
        wouldCost, WarpDrive.energy, energyShortfall)
    
    -- This data could be used to adjust energy regeneration or provide hints
end

-- Play adaptive warp sound based on system learning
function WarpDrive.playAdaptiveWarpSound(targetPlanet, cost)
    local soundManager = Utils.require("src.audio.sound_manager")
    if not soundManager or not soundManager.playEventWarning then
        return
    end
    
    -- Vary sound based on route familiarity and cost efficiency
    local routeKey = WarpDrive.generateRouteKey(WarpDrive.warpInitiation.sourceX, 
                                               WarpDrive.warpInitiation.sourceY, targetPlanet)
    local routeMemory = WarpDrive.memory.routes[routeKey]
    
    if routeMemory and routeMemory.uses > 5 then
        -- Familiar route: confident, smooth sound
        soundManager:playEventWarning() -- TODO: Add pitch parameter when available
    else
        -- New route: more cautious, exploratory sound
        soundManager:playEventWarning() -- TODO: Add different sound variant
    end
end

-- Create adaptive warp tunnel particles
function WarpDrive.createWarpParticles(player, cost)
    WarpDrive.particles = {}
    
    -- Safety check for warp target
    if not WarpDrive.warpTarget then
        Utils.Logger.warn("Cannot create warp particles: no warp target set")
        return
    end
    
    -- Adaptive particle count based on warp efficiency
    local baseCost = math.max(50, math.floor(Utils.distance(player.x, player.y, WarpDrive.warpTarget.x, WarpDrive.warpTarget.y) / 100))
    local efficiency = cost / baseCost  -- Lower cost = higher efficiency = more particles
    local particleCount = math.floor(50 * (2.0 - efficiency)) -- More efficient = more spectacular
    
    -- Create tunnel particles with adaptive intensity
    for i = 1, particleCount do
        local angle = math.random() * math.pi * 2
        local distance = math.random(100, 500)
        local speed = math.random(500, 1500)
        
        local particle = {
            x = player.x + math.cos(angle) * distance,
            y = player.y + math.sin(angle) * distance,
            vx = -math.cos(angle) * speed,
            vy = -math.sin(angle) * speed,
            size = math.random(2, 8),
            life = 1.0,
            color = {
                0.5 + math.random() * 0.5,
                0.5 + math.random() * 0.5,
                1.0
            }
        }
        
        table.insert(WarpDrive.particles, particle)
    end
end

-- Update warp drive
function WarpDrive.update(dt, player)
    -- Regenerate energy
    if WarpDrive.energy < WarpDrive.maxEnergy and not WarpDrive.isWarping then
        WarpDrive.energy = math.min(WarpDrive.maxEnergy, WarpDrive.energy + WarpDrive.energyRegenRate * dt)
    end
    
    -- Update warp animation
    if WarpDrive.isWarping then
        WarpDrive.warpProgress = WarpDrive.warpProgress + dt / WarpDrive.warpDuration
        WarpDrive.warpEffectAlpha = math.min(WarpDrive.warpProgress * 2, 1)
        WarpDrive.tunnelRotation = WarpDrive.tunnelRotation + dt * 5
        
        -- Update particles
        for i = #WarpDrive.particles, 1, -1 do
            local p = WarpDrive.particles[i]
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.life = p.life - dt * 2
            
            if p.life <= 0 then
                table.remove(WarpDrive.particles, i)
            end
        end
        
        -- Add new particles during warp
        if math.random() < 0.5 then
            local angle = math.random() * math.pi * 2
            local particle = {
                x = player.x + math.cos(angle) * 500,
                y = player.y + math.sin(angle) * 500,
                vx = -math.cos(angle) * 1000,
                vy = -math.sin(angle) * 1000,
                size = math.random(2, 8),
                life = 1.0,
                color = {
                    0.5 + math.random() * 0.5,
                    0.5 + math.random() * 0.5,
                    1.0
                }
            }
            table.insert(WarpDrive.particles, particle)
        end
        
        -- Complete warp
        if WarpDrive.warpProgress >= 1.0 then
            WarpDrive.completeWarp(player)
        end
    else
        -- Fade out effect
        WarpDrive.warpEffectAlpha = math.max(0, WarpDrive.warpEffectAlpha - dt * 2)
    end
end

-- Complete the warp with learning integration
function WarpDrive.completeWarp(player)
    if not WarpDrive.warpTarget then return end
    
    -- Teleport player to target planet
    local target = WarpDrive.warpTarget
    player.x = target.x + target.radius + 30
    player.y = target.y
    player.vx = 0
    player.vy = 0
    player.onPlanet = nil -- Start in space near the planet
    
    -- CRITICAL: Learn from this completed warp
    if WarpDrive.warpInitiation then
        WarpDrive.learnFromWarp(
            WarpDrive.warpInitiation.sourceX,
            WarpDrive.warpInitiation.sourceY,
            WarpDrive.warpInitiation.targetPlanet,
            WarpDrive.warpInitiation.actualCost,
            WarpDrive.warpInitiation.gameContext
        )
        
        -- Save learning progress periodically
        if WarpDrive.memory.behaviorProfile.totalWarps % 5 == 0 then
            WarpDrive.saveMemoryState()
        end
    end
    
    -- Clear warp state
    WarpDrive.isWarping = false
    WarpDrive.warpTarget = nil
    WarpDrive.warpProgress = 0
    WarpDrive.warpInitiation = nil
    
    -- Adaptive camera shake based on warp mastery
    local Camera = Utils.require("src.core.camera")
    if Camera.shake then
        local masteryLevel = WarpDrive.memory.behaviorProfile.skillLevel
        local shakeIntensity = 15 * (1.0 - masteryLevel * 0.5) -- Masters get smoother warps
        Camera:shake(shakeIntensity, 0.3)
    end
    
    -- Achievement tracking
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem.onWarpCompleted then
        AchievementSystem.onWarpCompleted()
    end
    
    Utils.Logger.info("✨ Warp completed - System learned from journey")
end

-- Toggle planet selection mode
function WarpDrive.toggleSelection()
    if not WarpDrive.isUnlocked then return false end
    if WarpDrive.isWarping then return false end
    
    WarpDrive.isSelecting = not WarpDrive.isSelecting
    WarpDrive.selectedPlanet = nil
    
    return WarpDrive.isSelecting
end

-- Handle planet selection
function WarpDrive.selectPlanetAt(worldX, worldY, planets, player)
    if not WarpDrive.isSelecting then return nil end
    
    -- Find closest discovered planet to click position
    local closestPlanet = nil
    local closestDistance = WarpDrive.selectionRadius
    
    for _, planet in ipairs(planets) do
        if planet.discovered then
            local dist = Utils.distance(worldX, worldY, planet.x, planet.y)
            if dist < closestDistance and dist < planet.radius + WarpDrive.selectionRadius then
                closestPlanet = planet
                closestDistance = dist
            end
        end
    end
    
    if closestPlanet then
        WarpDrive.selectedPlanet = closestPlanet
        
        -- Auto-start warp if we can afford it
        if WarpDrive.canAffordWarp(closestPlanet, player) then
            WarpDrive.startWarp(closestPlanet, player)
            WarpDrive.isSelecting = false
            WarpDrive.selectedPlanet = nil
        end
    end
    
    return closestPlanet
end

-- Draw warp effects
function WarpDrive.draw(player)
    if WarpDrive.warpEffectAlpha <= 0 and #WarpDrive.particles == 0 then return end
    
    -- Draw warp tunnel effect
    if WarpDrive.warpEffectAlpha > 0 then
        love.graphics.push()
        love.graphics.translate(player.x, player.y)
        love.graphics.rotate(WarpDrive.tunnelRotation)
        
        -- Tunnel rings
        for i = 1, 10 do
            local radius = i * 100
            local alpha = WarpDrive.warpEffectAlpha * (1 - i / 10) * 0.5
            Utils.setColor({0.5, 0.7, 1}, alpha)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", 0, 0, radius)
        end
        
        love.graphics.pop()
    end
    
    -- Draw particles
    for _, p in ipairs(WarpDrive.particles) do
        Utils.setColor(p.color, p.life * 0.8)
        love.graphics.circle("fill", p.x, p.y, p.size * p.life)
    end
end

-- Draw UI
function WarpDrive.drawUI(player, planets, camera)
    if not WarpDrive.isUnlocked then return end
    
    -- Draw energy bar
    local screenWidth = love.graphics.getWidth()
    local barWidth = 200
    local barHeight = 20
    local barX = screenWidth - barWidth - 20
    local barY = 100
    
    -- Background
    Utils.setColor({0, 0, 0}, 0.5)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 5)
    
    -- Energy fill
    local energyPercent = WarpDrive.energy / WarpDrive.maxEnergy
    Utils.setColor({0.2, 0.5, 1}, 0.8)
    love.graphics.rectangle("fill", barX, barY, barWidth * energyPercent, barHeight, 5)
    
    -- Border
    Utils.setColor({0.5, 0.7, 1}, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 5)
    
    -- Text
    Utils.setColor({1, 1, 1}, 0.9)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("Warp Energy", barX, barY - 20, barWidth, "center")
    love.graphics.printf(math.floor(WarpDrive.energy) .. " / " .. WarpDrive.maxEnergy, 
        barX, barY + 2, barWidth, "center")
    
    -- Selection mode indicator
    if WarpDrive.isSelecting then
        Utils.setColor({1, 1, 0}, 0.8)
        love.graphics.printf("SELECT WARP DESTINATION", 0, 150, screenWidth, "center")
        
        -- Draw selection circles on discovered planets
        for _, planet in ipairs(planets) do
            if planet.discovered then
                local screenX, screenY = camera:worldToScreen(planet.x, planet.y)
                
                -- Check if can afford
                local canAfford = WarpDrive.canAffordWarp(planet, player)
                
                if canAfford then
                    Utils.setColor({0, 1, 0}, 0.5)
                else
                    Utils.setColor({1, 0, 0}, 0.3)
                end
                
                -- Pulsing selection circle
                local pulse = math.sin(love.timer.getTime() * 3) * 5 + planet.radius + 20
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", screenX, screenY, pulse)
                
                -- Cost indicator
                if planet == WarpDrive.selectedPlanet then
                    local distance = Utils.distance(player.x, player.y, planet.x, planet.y)
                    local cost = WarpDrive.calculateCost(distance)
                    
                    Utils.setColor({1, 1, 1}, 0.9)
                    love.graphics.setFont(love.graphics.newFont(10))
                    love.graphics.print("Cost: " .. cost, screenX + planet.radius + 10, screenY)
                end
            end
        end
    end
    
    -- Warp progress
    if WarpDrive.isWarping then
        Utils.setColor({1, 1, 1}, WarpDrive.warpEffectAlpha)
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("WARPING...", 0, love.graphics.getHeight() / 2 - 50, screenWidth, "center")
        
        -- Progress bar
        local progBarWidth = 300
        local progBarX = (screenWidth - progBarWidth) / 2
        local progBarY = love.graphics.getHeight() / 2
        
        Utils.setColor({0, 0, 0}, 0.5 * WarpDrive.warpEffectAlpha)
        love.graphics.rectangle("fill", progBarX, progBarY, progBarWidth, 10)
        
        Utils.setColor({0.5, 0.7, 1}, WarpDrive.warpEffectAlpha)
        love.graphics.rectangle("fill", progBarX, progBarY, progBarWidth * WarpDrive.warpProgress, 10)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Adaptive Learning Algorithms: The Mind of the Machine
    ═══════════════════════════════════════════════════════════════════════════
    
    These functions implement the cognitive layer of the warp drive - algorithms
    that analyze, learn, and adapt. Each function represents a different aspect
    of machine intelligence: pattern recognition, predictive modeling, behavioral
    analysis, and adaptive decision making.
--]]

-- Calculate player mastery level and associated cost multiplier
function WarpDrive.calculateMasteryMultiplier()
    local behavior = WarpDrive.memory.behaviorProfile
    
    if behavior.totalWarps == 0 then
        return 1.0 -- No experience yet
    end
    
    -- Skill factors that indicate mastery:
    local efficiencyRatio = WarpDrive.memory.efficiencyMetrics.optimalRoutes / math.max(1, behavior.totalWarps)
    local emergencyRatio = behavior.emergencyWarps / behavior.totalWarps
    local explorationRatio = behavior.explorationWarps / behavior.totalWarps
    
    -- Masters are efficient, rarely panic, and explore confidently
    local masteryScore = (efficiencyRatio * 0.5) + ((1 - emergencyRatio) * 0.3) + (explorationRatio * 0.2)
    
    -- Convert to cost multiplier: masters pay less (minimum 75% of base cost)
    local multiplier = 1.0 - (masteryScore * 0.25)
    
    -- Update stored skill level for UI and other systems
    behavior.skillLevel = masteryScore
    
    return math.max(0.75, multiplier)
end

-- Detect emergency warp situations
function WarpDrive.detectEmergencyWarp(gameContext)
    if not gameContext then return 0 end
    
    local emergencyScore = 0
    local currentTime = love.timer.getTime()
    
    -- Factor 1: Player health/energy state
    if gameContext.player then
        local healthRatio = (gameContext.player.health or 100) / 100
        if healthRatio < 0.3 then
            emergencyScore = emergencyScore + 0.4 -- Critical health
        elseif healthRatio < 0.6 then
            emergencyScore = emergencyScore + 0.2 -- Low health
        end
    end
    
    -- Factor 2: Recent warp frequency (panic warping)
    local timeSinceLastWarp = currentTime - WarpDrive.memory.behaviorProfile.lastWarpTime
    if timeSinceLastWarp < 5.0 then -- Less than 5 seconds
        emergencyScore = emergencyScore + 0.3
    end
    
    -- Factor 3: Current environmental dangers
    if gameContext.nearbyDangers and #gameContext.nearbyDangers > 0 then
        emergencyScore = emergencyScore + 0.4
    end
    
    return math.min(1.0, emergencyScore)
end

-- Calculate exploration bonus for new/rarely visited planets
function WarpDrive.calculateExplorationBonus(targetPlanet)
    local planetId = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    local affinity = WarpDrive.memory.planetAffinity[planetId]
    
    if not affinity or affinity.visits == 0 then
        -- First visit: 15% cost reduction to encourage exploration
        return 0.85
    elseif affinity.visits < 3 then
        -- Early visits: 10% cost reduction
        return 0.90
    else
        -- Well-known planet: no exploration bonus
        return 1.0
    end
end

-- Calculate affinity bonus for beloved planets
function WarpDrive.calculateAffinityBonus(targetPlanet)
    local planetId = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    local affinity = WarpDrive.memory.planetAffinity[planetId]
    
    if not affinity then
        return 1.0
    end
    
    -- High-affinity planets get cost reductions (the warp drive "likes" going there)
    local affinityBonus = 1.0 - (affinity.affinity * 0.15) -- Up to 15% reduction
    return math.max(0.85, affinityBonus)
end

-- Learn from completed warp
function WarpDrive.learnFromWarp(sourceX, sourceY, targetPlanet, actualCost, gameContext)
    --[[
        Post-Warp Learning: Crystallizing Experience into Wisdom
        
        Every warp is a learning opportunity. This function analyzes what just
        happened and updates the system's understanding of the player's behavior,
        preferences, and skill development.
    --]]
    
    local currentTime = love.timer.getTime()
    local behavior = WarpDrive.memory.behaviorProfile
    local routeKey = WarpDrive.generateRouteKey(sourceX, sourceY, targetPlanet)
    local planetId = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    
    -- Update route memory
    if not WarpDrive.memory.routes[routeKey] then
        WarpDrive.memory.routes[routeKey] = {uses = 0, totalCost = 0, avgEfficiency = 0}
    end
    local route = WarpDrive.memory.routes[routeKey]
    route.uses = route.uses + 1
    route.totalCost = route.totalCost + actualCost
    route.avgEfficiency = route.totalCost / route.uses
    
    -- Update behavior profile
    behavior.totalWarps = behavior.totalWarps + 1
    
    -- Analyze warp type
    local emergencyLevel = WarpDrive.detectEmergencyWarp(gameContext)
    if emergencyLevel > 0.5 then
        behavior.emergencyWarps = behavior.emergencyWarps + 1
        WarpDrive.memory.emergencyPatterns.lastEmergencyTime = currentTime
    end
    
    -- Check for warp chaining (multiple warps in quick succession)
    if currentTime - behavior.lastWarpTime < 10.0 then
        behavior.warpChains = behavior.warpChains + 1
    end
    behavior.lastWarpTime = currentTime
    
    -- Update planet affinity
    if not WarpDrive.memory.planetAffinity[planetId] then
        WarpDrive.memory.planetAffinity[planetId] = {visits = 0, lastVisit = 0, affinity = 0}
    end
    local planetAffinity = WarpDrive.memory.planetAffinity[planetId]
    planetAffinity.visits = planetAffinity.visits + 1
    planetAffinity.lastVisit = currentTime
    
    -- Calculate affinity based on visit frequency and recency
    local totalPlanetVisits = 0
    for _, affinity in pairs(WarpDrive.memory.planetAffinity) do
        totalPlanetVisits = totalPlanetVisits + affinity.visits
    end
    planetAffinity.affinity = planetAffinity.visits / math.max(1, totalPlanetVisits)
    
    -- Update efficiency metrics
    WarpDrive.updateEfficiencyMetrics(actualCost, gameContext)
    
    -- Trigger memory consolidation if we have enough data
    if behavior.totalWarps % 10 == 0 then
        WarpDrive.consolidateMemory()
    end
    
    Utils.Logger.debug("🧠 Learned from warp: route %s, cost %d, emergency %.1f", 
        routeKey, actualCost, emergencyLevel)
end

-- Update efficiency learning metrics
function WarpDrive.updateEfficiencyMetrics(actualCost, gameContext)
    local metrics = WarpDrive.memory.efficiencyMetrics
    
    -- Analyze if this was an optimal route choice
    -- (This is simplified - in a full implementation, you'd compare against
    --  all possible routes to determine optimality)
    local wasOptimal = actualCost <= 100 -- Placeholder logic
    if wasOptimal then
        metrics.optimalRoutes = metrics.optimalRoutes + 1
    end
    
    -- Track learning curve over time
    local currentTime = love.timer.getTime()
    table.insert(metrics.learningCurve, {
        time = currentTime,
        cost = actualCost,
        optimal = wasOptimal
    })
    
    -- Keep only recent history (last 50 warps)
    if #metrics.learningCurve > 50 then
        table.remove(metrics.learningCurve, 1)
    end
    
    -- Update adaptation level based on improvement trend
    WarpDrive.calculateAdaptationLevel()
end

-- Calculate how much the system should adapt to the player
function WarpDrive.calculateAdaptationLevel()
    local curve = WarpDrive.memory.efficiencyMetrics.learningCurve
    if #curve < 10 then
        return -- Not enough data yet
    end
    
    -- Analyze improvement trend in recent warps
    local recentCosts = {}
    for i = math.max(1, #curve - 9), #curve do
        table.insert(recentCosts, curve[i].cost)
    end
    
    -- Calculate if costs are trending downward (improvement)
    local totalChange = 0
    for i = 2, #recentCosts do
        totalChange = totalChange + (recentCosts[i-1] - recentCosts[i])
    end
    
    -- Positive change = costs decreasing = player improving
    local improvementRate = totalChange / (#recentCosts - 1)
    
    -- Convert to adaptation level (0 = no adaptation, 1 = maximum adaptation)
    local adaptationLevel = math.max(0, math.min(1, improvementRate / 20))
    WarpDrive.memory.efficiencyMetrics.adaptationLevel = adaptationLevel
end

-- Consolidate memory (compress old data, extract patterns)
function WarpDrive.consolidateMemory()
    --[[
        Memory Consolidation: From Data to Wisdom
        
        Like a sleeping brain consolidating the day's experiences into long-term
        memory, this function processes accumulated data to extract meaningful
        patterns and optimize storage.
    --]]
    
    Utils.Logger.info("🧠 Consolidating warp drive memory...")
    
    -- Compress old route data (keep frequently used routes, archive others)
    local activeRoutes = {}
    local currentTime = love.timer.getTime()
    
    for routeKey, routeData in pairs(WarpDrive.memory.routes) do
        if routeData.uses >= 3 then -- Keep frequently used routes
            activeRoutes[routeKey] = routeData
        end
    end
    WarpDrive.memory.routes = activeRoutes
    
    -- Archive old learning curve data
    local curve = WarpDrive.memory.efficiencyMetrics.learningCurve
    if #curve > 30 then
        -- Keep recent data, summarize old data
        local summarizedCurve = {}
        for i = math.max(1, #curve - 29), #curve do
            table.insert(summarizedCurve, curve[i])
        end
        WarpDrive.memory.efficiencyMetrics.learningCurve = summarizedCurve
    end
    
    -- Update skill level based on all available data
    WarpDrive.recalculateSkillLevel()
    
    local stats = WarpDrive.getMemoryStats()
    Utils.Logger.info("🧠 Memory consolidated: %d active routes, %.1f%% efficiency",
        stats.activeRoutes, stats.efficiency * 100)
end

-- Recalculate overall skill level
function WarpDrive.recalculateSkillLevel()
    local behavior = WarpDrive.memory.behaviorProfile
    local metrics = WarpDrive.memory.efficiencyMetrics
    
    if behavior.totalWarps == 0 then
        behavior.skillLevel = 0
        return
    end
    
    -- Multiple factors contribute to skill assessment
    local efficiencyScore = metrics.optimalRoutes / behavior.totalWarps
    local experienceScore = math.min(1.0, behavior.totalWarps / 50) -- Caps at 50 warps
    local emergencyHandling = 1.0 - (behavior.emergencyWarps / behavior.totalWarps)
    local explorationCourage = math.min(1.0, behavior.explorationWarps / math.max(1, behavior.totalWarps * 0.3))
    
    -- Weighted combination
    behavior.skillLevel = (efficiencyScore * 0.4) + (experienceScore * 0.3) + 
                         (emergencyHandling * 0.2) + (explorationCourage * 0.1)
end

-- Get memory statistics for debugging and UI
function WarpDrive.getMemoryStats()
    local behavior = WarpDrive.memory.behaviorProfile
    local metrics = WarpDrive.memory.efficiencyMetrics
    
    return {
        totalWarps = behavior.totalWarps,
        knownRoutes = Utils.tableLength(WarpDrive.memory.routes),
        activeRoutes = Utils.tableLength(WarpDrive.memory.routes),
        efficiency = metrics.optimalRoutes / math.max(1, behavior.totalWarps),
        skillLevel = behavior.skillLevel,
        adaptationLevel = metrics.adaptationLevel,
        favoriteplanets = Utils.tableLength(WarpDrive.memory.planetAffinity),
        emergencyRate = behavior.emergencyWarps / math.max(1, behavior.totalWarps)
    }
end

-- Log detailed cost calculation for transparency
function WarpDrive.logCostCalculation(baseCost, finalCost, factors)
    if Utils.Logger.currentLevel <= Utils.Logger.levels.DEBUG then
        local reduction = ((baseCost - finalCost) / baseCost) * 100
        Utils.Logger.debug("📊 Warp cost: %d → %d (%.1f%% reduction)", baseCost, finalCost, reduction)
        Utils.Logger.debug("  Factors: fam=%.2f mas=%.2f emer=%.2f expl=%.2f aff=%.2f",
            factors.familiarity, factors.mastery, factors.emergency, 
            factors.exploration, factors.affinity)
    end
end

-- Save memory state for persistence
function WarpDrive.saveMemoryState()
    local SaveSystem = Utils.require("src.systems.save_system")
    if SaveSystem and SaveSystem.setData then
        SaveSystem.setData("warpDriveMemory", WarpDrive.memory)
        Utils.Logger.debug("💾 Warp drive memory saved")
    end
end

-- Get enhanced upgrade status for UI (includes learning info)
function WarpDrive.getStatus()
    local memoryStats = WarpDrive.getMemoryStats()
    
    return {
        unlocked = WarpDrive.isUnlocked,
        energy = WarpDrive.energy,
        maxEnergy = WarpDrive.maxEnergy,
        isWarping = WarpDrive.isWarping,
        canWarp = WarpDrive.energy >= 50,
        
        -- Learning status
        memory = memoryStats,
        isLearning = memoryStats.totalWarps > 0,
        adaptationActive = memoryStats.adaptationLevel > 0.1,
        masteryLevel = memoryStats.skillLevel
    }
end

return WarpDrive