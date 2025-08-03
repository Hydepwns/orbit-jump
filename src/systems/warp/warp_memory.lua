--[[
    ═══════════════════════════════════════════════════════════════════════════
    Warp Memory: Adaptive Learning and Route Optimization
    ═══════════════════════════════════════════════════════════════════════════
    This module handles all adaptive learning features of the warp drive,
    including route memory, behavioral analysis, and optimization.
--]]
local Utils = require("src.utils.utils")
local WarpMemory = {}
-- Initialize memory structures
function WarpMemory.init()
    return {
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
end
-- Generate consistent route key for memory storage
function WarpMemory.generateRouteKey(sourceX, sourceY, targetPlanet)
    local sourceKey = math.floor(sourceX / 100) .. "," .. math.floor(sourceY / 100)
    local targetKey = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    return sourceKey .. "->" .. targetKey
end
-- Calculate route familiarity bonus
function WarpMemory.getRouteFamiliarity(memory, sourceX, sourceY, targetPlanet)
    local routeKey = WarpMemory.generateRouteKey(sourceX, sourceY, targetPlanet)
    local routeMemory = memory.routes[routeKey]
    if routeMemory and routeMemory.uses > 0 then
        -- More uses = lower cost (max 25% reduction)
        local familiarity = math.min(routeMemory.uses / 10, 1.0)
        return 1.0 - (familiarity * 0.25)
    end
    return 1.0 -- No familiarity bonus
end
-- Calculate player mastery level
function WarpMemory.getMasteryMultiplier(memory)
    local behavior = memory.behaviorProfile
    if behavior.totalWarps == 0 then
        return 1.0 -- No experience yet
    end
    -- Skill factors that indicate mastery
    local efficiencyRatio = memory.efficiencyMetrics.optimalRoutes / math.max(1, behavior.totalWarps)
    local emergencyRatio = behavior.emergencyWarps / behavior.totalWarps
    local explorationRatio = behavior.explorationWarps / behavior.totalWarps
    -- Masters are efficient, rarely panic, and explore confidently
    local masteryScore = (efficiencyRatio * 0.5) + ((1 - emergencyRatio) * 0.3) + (explorationRatio * 0.2)
    -- Convert to cost multiplier: masters pay less (minimum 75% of base cost)
    local multiplier = 1.0 - (masteryScore * 0.25)
    -- Update stored skill level
    behavior.skillLevel = masteryScore
    return math.max(0.75, multiplier)
end
-- Detect emergency warp situations
function WarpMemory.detectEmergency(memory, gameContext)
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
    local timeSinceLastWarp = currentTime - memory.behaviorProfile.lastWarpTime
    if timeSinceLastWarp < 5.0 then -- Less than 5 seconds
        emergencyScore = emergencyScore + 0.3
    end
    -- Factor 3: Current environmental dangers
    if gameContext.nearbyDangers and #gameContext.nearbyDangers > 0 then
        emergencyScore = emergencyScore + 0.4
    end
    return math.min(1.0, emergencyScore)
end
-- Calculate exploration bonus
function WarpMemory.getExplorationBonus(memory, targetPlanet)
    local planetId = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    local affinity = memory.planetAffinity[planetId]
    if not affinity or affinity.visits == 0 then
        return 0.85 -- First visit: 15% cost reduction
    elseif affinity.visits < 3 then
        return 0.90 -- Early visits: 10% cost reduction
    else
        return 1.0 -- Well-known planet: no exploration bonus
    end
end
-- Calculate affinity bonus
function WarpMemory.getAffinityBonus(memory, targetPlanet)
    local planetId = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    local affinity = memory.planetAffinity[planetId]
    if not affinity then
        return 1.0
    end
    -- High-affinity planets get cost reductions
    local affinityBonus = 1.0 - (affinity.affinity * 0.15) -- Up to 15% reduction
    return math.max(0.85, affinityBonus)
end
-- Learn from completed warp
function WarpMemory.learnFromWarp(memory, sourceX, sourceY, targetPlanet, actualCost, gameContext)
    local currentTime = love.timer.getTime()
    local behavior = memory.behaviorProfile
    local routeKey = WarpMemory.generateRouteKey(sourceX, sourceY, targetPlanet)
    local planetId = targetPlanet.id or (targetPlanet.x .. "," .. targetPlanet.y)
    -- Update route memory
    if not memory.routes[routeKey] then
        memory.routes[routeKey] = {uses = 0, totalCost = 0, avgEfficiency = 0}
    end
    local route = memory.routes[routeKey]
    route.uses = route.uses + 1
    route.totalCost = route.totalCost + actualCost
    route.avgEfficiency = route.totalCost / route.uses
    -- Update behavior profile
    behavior.totalWarps = behavior.totalWarps + 1
    -- Analyze warp type
    local emergencyLevel = WarpMemory.detectEmergency(memory, gameContext)
    if emergencyLevel > 0.5 then
        behavior.emergencyWarps = behavior.emergencyWarps + 1
        memory.emergencyPatterns.lastEmergencyTime = currentTime
    end
    -- Check for warp chaining
    if currentTime - behavior.lastWarpTime < 10.0 then
        behavior.warpChains = behavior.warpChains + 1
    end
    behavior.lastWarpTime = currentTime
    -- Update planet affinity
    if not memory.planetAffinity[planetId] then
        memory.planetAffinity[planetId] = {visits = 0, lastVisit = 0, affinity = 0}
    end
    local planetAffinity = memory.planetAffinity[planetId]
    planetAffinity.visits = planetAffinity.visits + 1
    planetAffinity.lastVisit = currentTime
    -- Calculate affinity based on visit frequency
    local totalPlanetVisits = 0
    for _, affinity in pairs(memory.planetAffinity) do
        totalPlanetVisits = totalPlanetVisits + affinity.visits
    end
    planetAffinity.affinity = planetAffinity.visits / math.max(1, totalPlanetVisits)
    -- Update efficiency metrics
    WarpMemory.updateEfficiencyMetrics(memory, actualCost, gameContext)
    Utils.Logger.debug("🧠 Learned from warp: route %s, cost %d, emergency %.1f",
        routeKey, actualCost, emergencyLevel)
end
-- Update efficiency metrics
function WarpMemory.updateEfficiencyMetrics(memory, actualCost, gameContext)
    local metrics = memory.efficiencyMetrics
    -- Analyze if this was an optimal route choice
    local wasOptimal = actualCost <= 100 -- Simplified logic
    if wasOptimal then
        metrics.optimalRoutes = metrics.optimalRoutes + 1
    end
    -- Track learning curve
    local currentTime = love.timer.getTime()
    table.insert(metrics.learningCurve, {
        time = currentTime,
        cost = actualCost,
        optimal = wasOptimal
    })
    -- Keep only recent history
    if #metrics.learningCurve > 50 then
        table.remove(metrics.learningCurve, 1)
    end
    -- Update adaptation level
    WarpMemory.calculateAdaptationLevel(memory)
end
-- Calculate adaptation level
function WarpMemory.calculateAdaptationLevel(memory)
    local curve = memory.efficiencyMetrics.learningCurve
    if #curve < 10 then
        return -- Not enough data
    end
    -- Analyze improvement trend
    local recentCosts = {}
    for i = math.max(1, #curve - 9), #curve do
        table.insert(recentCosts, curve[i].cost)
    end
    -- Calculate if costs are trending downward
    local totalChange = 0
    for i = 2, #recentCosts do
        totalChange = totalChange + (recentCosts[i-1] - recentCosts[i])
    end
    local improvementRate = totalChange / (#recentCosts - 1)
    local adaptationLevel = math.max(0, math.min(1, improvementRate / 20))
    memory.efficiencyMetrics.adaptationLevel = adaptationLevel
end
-- Consolidate memory
function WarpMemory.consolidate(memory)
    Utils.Logger.info("🧠 Consolidating warp drive memory...")
    -- Compress old route data
    local activeRoutes = {}
    for routeKey, routeData in pairs(memory.routes) do
        if routeData.uses >= 3 then -- Keep frequently used routes
            activeRoutes[routeKey] = routeData
        end
    end
    memory.routes = activeRoutes
    -- Archive old learning curve data
    local curve = memory.efficiencyMetrics.learningCurve
    if #curve > 30 then
        local summarizedCurve = {}
        for i = math.max(1, #curve - 29), #curve do
            table.insert(summarizedCurve, curve[i])
        end
        memory.efficiencyMetrics.learningCurve = summarizedCurve
    end
    -- Recalculate skill level
    WarpMemory.recalculateSkillLevel(memory)
end
-- Recalculate skill level
function WarpMemory.recalculateSkillLevel(memory)
    local behavior = memory.behaviorProfile
    local metrics = memory.efficiencyMetrics
    if behavior.totalWarps == 0 then
        behavior.skillLevel = 0
        return
    end
    -- Multiple factors contribute to skill
    local efficiencyScore = metrics.optimalRoutes / behavior.totalWarps
    local experienceScore = math.min(1.0, behavior.totalWarps / 50)
    local emergencyHandling = 1.0 - (behavior.emergencyWarps / behavior.totalWarps)
    local explorationCourage = math.min(1.0, behavior.explorationWarps / math.max(1, behavior.totalWarps * 0.3))
    behavior.skillLevel = (efficiencyScore * 0.4) + (experienceScore * 0.3) +
                         (emergencyHandling * 0.2) + (explorationCourage * 0.1)
end
-- Get memory statistics
function WarpMemory.getStats(memory)
    local behavior = memory.behaviorProfile
    local metrics = memory.efficiencyMetrics
    return {
        totalWarps = behavior.totalWarps,
        knownRoutes = Utils.tableLength(memory.routes),
        activeRoutes = Utils.tableLength(memory.routes),
        efficiency = metrics.optimalRoutes / math.max(1, behavior.totalWarps),
        skillLevel = behavior.skillLevel,
        adaptationLevel = metrics.adaptationLevel,
        favoritePlanets = Utils.tableLength(memory.planetAffinity),
        emergencyRate = behavior.emergencyWarps / math.max(1, behavior.totalWarps)
    }
end
-- Get memory statistics (alias for compatibility)
function WarpMemory.getMemoryStats()
    -- Get the current memory instance
    local memory = WarpMemory.memory or WarpMemory.init()
    return WarpMemory.getStats(memory)
end
return WarpMemory