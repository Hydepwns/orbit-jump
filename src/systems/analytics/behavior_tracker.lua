--[[
    Behavior Tracker: Player Movement and Action Tracking
    
    This module handles tracking and analyzing player behaviors including
    movement patterns, jump characteristics, and play style identification.
--]]

local Utils = require("src.utils.utils")
local BehaviorTracker = {}

-- Movement tracking data
BehaviorTracker.movementProfile = {
    preferredJumpPower = 0,      -- Average power they use
    jumpPowerVariance = 0,       -- How consistent are they?
    averageJumpDistance = 0,     -- Spatial preference
    riskTolerance = 0,           -- 0-1: conservative to adventurous
    planningTime = 0,            -- Average time between landing and jumping
    totalJumps = 0,
    totalDistance = 0,
    
    -- Movement Efficiency
    wastedMovement = 0,          -- Movement that doesn't advance goals
    efficientPaths = 0,          -- Direct routes taken
    creativePaths = 0,           -- Interesting non-optimal routes
    
    -- Spatial Awareness
    collisionRate = 0,           -- How often they hit things
    nearMissRate = 0,            -- How often they almost hit things
    spatialMastery = 0           -- Overall movement skill (0-1)
}

-- Exploration tracking data
BehaviorTracker.explorationProfile = {
    explorationStyle = "unknown", -- "methodical", "chaotic", "balanced"
    newPlanetAttempts = 0,       -- Tries to reach undiscovered planets
    newPlanetSuccesses = 0,      -- Actually makes it to them
    explorationEfficiency = 0,   -- Success rate
    
    -- Discovery Patterns
    averageTimeToRevisit = 0,    -- How long before returning to planets
    planetVisitDistribution = {},-- How evenly they visit different areas
    explorationRadius = 0,       -- How far from start they typically go
    
    -- Learning Curve
    discoveryMomentum = 0,       -- How discovery rate changes over time
    comfortZoneSize = 0,         -- Size of area they stay within
    expansionRate = 0            -- How quickly they expand their territory
}

-- Initialize behavior tracking
function BehaviorTracker.init()
    BehaviorTracker.initializeMovementProfile()
    BehaviorTracker.initializeExplorationProfile()
end

-- Initialize movement profile with defaults
function BehaviorTracker.initializeMovementProfile()
    if not BehaviorTracker.movementProfile then
        BehaviorTracker.movementProfile = {
            preferredJumpPower = 0, jumpPowerVariance = 0, averageJumpDistance = 0,
            riskTolerance = 0.5, planningTime = 0, totalJumps = 0, totalDistance = 0,
            wastedMovement = 0, efficientPaths = 0, creativePaths = 0,
            collisionRate = 0, nearMissRate = 0, spatialMastery = 0
        }
    end
end

-- Initialize exploration profile with defaults
function BehaviorTracker.initializeExplorationProfile()
    if not BehaviorTracker.explorationProfile then
        BehaviorTracker.explorationProfile = {
            explorationStyle = "unknown",
            newPlanetAttempts = 0,
            newPlanetSuccesses = 0,
            explorationEfficiency = 0,
            averageTimeToRevisit = 0,
            planetVisitDistribution = {},
            explorationRadius = 0,
            discoveryMomentum = 0,
            comfortZoneSize = 0,
            expansionRate = 0
        }
    end
end

-- Track player jump behavior
function BehaviorTracker.onPlayerJump(jumpPower, jumpAngle, startX, startY, targetX, targetY, planningTime)
    local movement = BehaviorTracker.movementProfile
    
    -- Update basic statistics
    movement.totalJumps = movement.totalJumps + 1
    
    -- Calculate jump distance
    local jumpDistance = Utils.distance(startX, startY, targetX, targetY)
    movement.totalDistance = movement.totalDistance + jumpDistance
    movement.averageJumpDistance = movement.totalDistance / movement.totalJumps
    
    -- Update power preferences
    if movement.preferredJumpPower == 0 then
        movement.preferredJumpPower = jumpPower
    else
        -- Moving average
        movement.preferredJumpPower = movement.preferredJumpPower * 0.95 + jumpPower * 0.05
    end
    
    -- Calculate variance (standard deviation approximation)
    local powerDiff = math.abs(jumpPower - movement.preferredJumpPower)
    movement.jumpPowerVariance = movement.jumpPowerVariance * 0.95 + powerDiff * 0.05
    
    -- Update planning time
    if planningTime and planningTime > 0 then
        if movement.planningTime == 0 then
            movement.planningTime = planningTime
        else
            movement.planningTime = movement.planningTime * 0.9 + planningTime * 0.1
        end
    end
    
    -- Analyze risk tolerance
    BehaviorTracker.analyzeRiskTolerance(jumpPower, jumpDistance, startX, startY)
    
    -- Update movement skill
    BehaviorTracker.updateMovementSkill(jumpPower, jumpDistance, planningTime)
    
    Utils.Logger.debug("🦘 Jump tracked: power=%.2f, distance=%.0f, planning=%.2f",
        jumpPower, jumpDistance, planningTime or 0)
end

-- Analyze risk-taking behavior
function BehaviorTracker.analyzeRiskTolerance(jumpPower, jumpDistance, startX, startY)
    local movement = BehaviorTracker.movementProfile
    
    -- High power + long distance = risk-taking
    local riskFactor = (jumpPower / 100) * (jumpDistance / 500)
    
    -- Update risk tolerance with moving average
    movement.riskTolerance = movement.riskTolerance * 0.9 + math.min(1, riskFactor) * 0.1
    
    -- Track if this was an efficient or creative path
    if jumpDistance < 300 and jumpPower < 50 then
        movement.efficientPaths = movement.efficientPaths + 1
    elseif jumpPower > 80 or jumpDistance > 600 then
        movement.creativePaths = movement.creativePaths + 1
    end
end

-- Update movement skill assessment
function BehaviorTracker.updateMovementSkill(jumpPower, jumpDistance, planningTime)
    local movement = BehaviorTracker.movementProfile
    
    -- Factors that indicate skill:
    -- 1. Consistent jump power (low variance)
    -- 2. Appropriate planning time (not too fast, not too slow)
    -- 3. Efficient path selection
    -- 4. Low collision rate
    
    local consistencyScore = 1.0 - math.min(1.0, movement.jumpPowerVariance / 30)
    local planningScore = 0
    
    if planningTime then
        -- Optimal planning time is 1-3 seconds
        if planningTime >= 1 and planningTime <= 3 then
            planningScore = 1.0
        elseif planningTime < 1 then
            planningScore = planningTime -- Too fast
        else
            planningScore = math.max(0, 1.0 - (planningTime - 3) / 10) -- Too slow
        end
    end
    
    local efficiencyScore = 0
    if movement.totalJumps > 0 then
        local totalPaths = movement.efficientPaths + movement.creativePaths + movement.wastedMovement
        if totalPaths > 0 then
            efficiencyScore = (movement.efficientPaths + movement.creativePaths * 0.5) / totalPaths
        end
    end
    
    -- Weighted combination
    local newMastery = (consistencyScore * 0.3 + planningScore * 0.3 + 
                       efficiencyScore * 0.2 + (1 - movement.collisionRate) * 0.2)
    
    -- Update with moving average
    movement.spatialMastery = movement.spatialMastery * 0.95 + newMastery * 0.05
end

-- Track planet discovery
function BehaviorTracker.onPlanetDiscovered(planet, discoveryMethod, attemptsToReach)
    local exploration = BehaviorTracker.explorationProfile
    
    exploration.newPlanetSuccesses = exploration.newPlanetSuccesses + 1
    if attemptsToReach then
        exploration.newPlanetAttempts = exploration.newPlanetAttempts + attemptsToReach
    end
    
    -- Update efficiency
    if exploration.newPlanetAttempts > 0 then
        exploration.explorationEfficiency = exploration.newPlanetSuccesses / exploration.newPlanetAttempts
    end
    
    -- Analyze exploration style
    BehaviorTracker.analyzeExplorationStyle(planet, discoveryMethod, attemptsToReach)
    
    Utils.Logger.info("🌍 Planet discovered: %s via %s after %d attempts",
        planet.name or "Unknown", discoveryMethod or "jump", attemptsToReach or 1)
end

-- Analyze exploration patterns
function BehaviorTracker.analyzeExplorationStyle(planet, discoveryMethod, attempts)
    local exploration = BehaviorTracker.explorationProfile
    
    -- Update planet visit distribution
    local planetId = planet.id or (planet.x .. "," .. planet.y)
    exploration.planetVisitDistribution[planetId] = 
        (exploration.planetVisitDistribution[planetId] or 0) + 1
    
    -- Determine exploration style based on attempts
    if attempts == 1 then
        -- First try success = methodical
        if exploration.explorationStyle == "unknown" then
            exploration.explorationStyle = "methodical"
        end
    elseif attempts > 5 then
        -- Many attempts = chaotic explorer
        if exploration.explorationStyle == "unknown" then
            exploration.explorationStyle = "chaotic"
        end
    else
        -- Balanced approach
        if exploration.explorationStyle == "unknown" then
            exploration.explorationStyle = "balanced"
        end
    end
end

-- Classify movement style
function BehaviorTracker.classifyMovementStyle()
    local movement = BehaviorTracker.movementProfile
    
    if movement.totalJumps < 10 then
        return "learning"
    end
    
    if movement.jumpPowerVariance < 10 and movement.planningTime > 2 then
        return "methodical"
    elseif movement.riskTolerance > 0.7 and movement.creativePaths > movement.efficientPaths then
        return "adventurous"
    elseif movement.efficientPaths > movement.creativePaths * 2 then
        return "efficient"
    else
        return "balanced"
    end
end

-- Get behavior summary
function BehaviorTracker.getSummary()
    return {
        movement = {
            style = BehaviorTracker.classifyMovementStyle(),
            totalJumps = BehaviorTracker.movementProfile.totalJumps,
            averageDistance = BehaviorTracker.movementProfile.averageJumpDistance,
            mastery = BehaviorTracker.movementProfile.spatialMastery,
            riskTolerance = BehaviorTracker.movementProfile.riskTolerance
        },
        exploration = {
            style = BehaviorTracker.explorationProfile.explorationStyle,
            planetsDiscovered = BehaviorTracker.explorationProfile.newPlanetSuccesses,
            efficiency = BehaviorTracker.explorationProfile.explorationEfficiency,
            radius = BehaviorTracker.explorationProfile.explorationRadius
        }
    }
end

-- Save behavior data
function BehaviorTracker.saveState()
    return {
        movementProfile = BehaviorTracker.movementProfile,
        explorationProfile = BehaviorTracker.explorationProfile
    }
end

-- Restore behavior data
function BehaviorTracker.restoreState(state)
    if state then
        if state.movementProfile then
            BehaviorTracker.movementProfile = state.movementProfile
        end
        if state.explorationProfile then
            BehaviorTracker.explorationProfile = state.explorationProfile
        end
    end
end

return BehaviorTracker