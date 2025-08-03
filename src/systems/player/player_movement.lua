--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player Movement: Physics and movement mechanics
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles the core physics simulation for player movement,
    including orbital mechanics, space physics, and adaptive systems.
--]]

local Utils = require("src.utils.utils")
local GameLogic = Utils.require("src.core.game_logic")
local Config = Utils.require("src.utils.config")

local PlayerMovement = {}

-- Adaptive physics system for player movement
local AdaptivePhysics = {
    baseSpaceDrag = 0.995,       -- Reduced from 0.99 to 0.995 (less drag)
    currentSpaceDrag = 0.995,    -- Dynamically adjusted value
    baseCameraResponse = 2.0,    -- How quickly camera follows player
    currentCameraResponse = 2.0, -- Dynamically adjusted value
    adaptationRate = 0.1,        -- How quickly physics adapt to player
    adaptationInterval = 5.0,    -- How often to adapt physics (seconds)
    learningEnabled = true       -- Master switch for adaptive features
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Zero-Allocation Trail System
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Zero-Allocation Trail System: Pre-allocated pool of trail points
local TRAIL_POOL_SIZE = 100  -- Generous buffer for smooth trails
local MAX_ACTIVE_TRAIL_POINTS = 50

-- Pre-allocated trail point pool - created once, never collected
local trailPointPool = {}
local poolIndex = 1

-- Initialize the trail point pool (called once during system startup)
local function initializeTrailPool()
    for i = 1, TRAIL_POOL_SIZE do
        trailPointPool[i] = {
            x = 0,
            y = 0,
            life = 0,
            isDashing = false,
            active = false
        }
    end
    Utils.Logger.info("🚀 Zero-allocation trail system initialized: %d pooled points", TRAIL_POOL_SIZE)
end

-- Get next available trail point from pool (zero allocation)
local function getPooledTrailPoint()
    local point = trailPointPool[poolIndex]
    poolIndex = poolIndex + 1
    if poolIndex > TRAIL_POOL_SIZE then
        poolIndex = 1  -- Circular buffer
    end
    return point
end

-- Initialize pool
if #trailPointPool == 0 then
    initializeTrailPool()
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Core Movement Physics
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerMovement.init()
    -- Reset adaptive physics to defaults
    AdaptivePhysics.currentSpaceDrag = AdaptivePhysics.baseSpaceDrag
    AdaptivePhysics.currentCameraResponse = AdaptivePhysics.baseCameraResponse
    AdaptivePhysics.lastAdaptationTime = 0
    
    Utils.Logger.info("🏃 Player Movement initialized")
    return true
end

function PlayerMovement.updateMovement(player, planets, dt)
    -- Dual-State Physics: Two completely different movement paradigms
    if player.onPlanet and planets[player.onPlanet] then
        -- Orbital mechanics: Predictable, circular, grounding
        PlayerMovement.updateOnPlanet(player, planets[player.onPlanet], dt)
    else
        -- Space physics: Complex, emergent, exciting
        PlayerMovement.updateInSpace(player, planets, dt)
    end
    
    -- Visual Feedback Systems: Making the invisible visible
    PlayerMovement.updateTrail(player)      -- Show where you've been
    PlayerMovement.checkBoundaries(player)  -- Prevent infinite drift
    
    -- Adaptive Camera Psychology: Speed creates excitement, responsiveness adapts to player
    PlayerMovement.updateCamera(player, dt)
end

function PlayerMovement.updateOnPlanet(player, planet, dt)
    --[[
        Orbital Mechanics: The Safety of Predictable Motion
        
        When landed on a planet, the player enters a completely different physics
        regime. This creates moments of calm planning between the chaos of space flight.
    --]]
    
    local SURFACE_CLEARANCE = 5  -- Pixels between player and planet surface
    local DEFAULT_ANGULAR_VELOCITY = 0.5  -- Radians per second when planet has no preference
    
    -- Planetary rotation: Each world turns at its own pace
    player.angle = player.angle + (planet.angularVelocity or DEFAULT_ANGULAR_VELOCITY) * dt
    
    -- Orbital positioning: Maintain perfect circular orbit
    local orbitRadius = planet.radius + player.radius + SURFACE_CLEARANCE
    player.x = planet.x + math.cos(player.angle) * orbitRadius
    player.y = planet.y + math.sin(player.angle) * orbitRadius
    
    -- Velocity reset: On-planet state has no momentum
    player.vx = 0
    player.vy = 0
end

function PlayerMovement.updateInSpace(player, planets, dt)
    --[[
        N-Body Gravitational Physics: Where Complexity Becomes Emergent Fun
        
        Every frame, we calculate the combined gravitational influence of all planets.
        This creates complex, emergent trajectories that make each jump unique.
    --]]
    
    -- Gravitational Accumulation: Sum influences from all celestial bodies
    local gravX, gravY = 0, 0
    for _, planet in ipairs(planets) do
        local gx, gy = GameLogic.calculateGravity(
            player.x, player.y,
            planet.x, planet.y,
            planet.radius
        )
        gravX = gravX + gx
        gravY = gravY + gy
    end
    
    -- Force Integration: Newton's second law in action (F = ma, where m = 1)
    player.vx = player.vx + gravX * dt
    player.vy = player.vy + gravY * dt
    
    -- Adaptive Atmospheric Drag: Learning to serve the player better
    if not player.isDashing then
        -- Use adaptive drag that adjusts to player skill and preferences
        local spaceDrag = AdaptivePhysics.currentSpaceDrag
        
        -- Note: This is artistic license - real space has no drag
        -- But it prevents runaway velocities that break game feel
        player.vx = player.vx * spaceDrag
        player.vy = player.vy * spaceDrag
    end
    -- When dashing: No drag = temporary superhuman movement
    
    -- Position Integration: Velocity becomes motion
    -- Apply time scaling for events (time dilation effect)
    local GameState = require("src.core.game_state")
    local scaledDt = dt * (GameState.player_time_scale or 1.0)
    player.x = player.x + player.vx * scaledDt
    player.y = player.y + player.vy * scaledDt
end

function PlayerMovement.updateTrail(player)
    --[[
        Zero-Allocation Trail System: Smooth Visuals Without Garbage Collection
    --]]
    
    -- Add new trail point using pooled object (zero allocation)
    local newPoint = getPooledTrailPoint()
    newPoint.x = player.x
    newPoint.y = player.y
    newPoint.life = 1.0
    newPoint.isDashing = player.isDashing
    newPoint.active = true
    
    -- Ensure we have a trail array (but don't modify its structure)
    if not player.trail then
        player.trail = {}
    end
    
    -- Find insertion point without table.insert (avoids array reallocation)
    local insertIndex = #player.trail + 1
    if insertIndex > MAX_ACTIVE_TRAIL_POINTS then
        -- Reuse oldest slot instead of growing array
        insertIndex = 1
        for i = 1, #player.trail do
            if player.trail[i].life < player.trail[insertIndex].life then
                insertIndex = i
            end
        end
    end
    player.trail[insertIndex] = newPoint
    
    -- Update existing trail points in-place (zero allocation)
    local TRAIL_DECAY_RATE = 0.02  -- Life lost per frame
    for i = 1, #player.trail do
        local point = player.trail[i]
        if point and point.active then
            point.life = point.life - TRAIL_DECAY_RATE
            
            if point.life <= 0 then
                -- Deactivate instead of removing (avoids table operations)
                point.active = false
            end
        end
    end
    
    -- Maintain trail length without table operations
    local activeCount = 0
    for i = 1, #player.trail do
        if player.trail[i] and player.trail[i].active then
            activeCount = activeCount + 1
        end
    end
    
    -- If too many active points, deactivate the oldest
    if activeCount > MAX_ACTIVE_TRAIL_POINTS then
        local oldestIndex = 1
        local oldestLife = math.huge
        for i = 1, #player.trail do
            local point = player.trail[i]
            if point and point.active and point.life < oldestLife then
                oldestLife = point.life
                oldestIndex = i
            end
        end
        if player.trail[oldestIndex] then
            player.trail[oldestIndex].active = false
        end
    end
end

function PlayerMovement.updateCamera(player, dt)
    --[[Adaptive Camera Psychology: Speed creates excitement, responsiveness adapts to player--]]
    
    local speed = Utils.distance(0, 0, player.vx, player.vy)
    local SPEED_SCALE_FACTOR = 2000    -- Tuned: When zoom-out starts feeling natural
    local MAX_SCALE_REDUCTION = 0.3    -- Tuned: Maximum zoom before losing detail
    
    -- Use adaptive camera response that learns player preferences
    local cameraResponseSpeed = AdaptivePhysics.currentCameraResponse
    
    local targetScale = 1.0 - math.min(speed / SPEED_SCALE_FACTOR, MAX_SCALE_REDUCTION)
    if player.camera then
        -- Adaptive interpolation prevents jarring camera jumps while serving player preference
        player.camera.scale = Utils.lerp(player.camera.scale, targetScale, dt * cameraResponseSpeed)
    end
end

function PlayerMovement.checkBoundaries(player)
    --[[Boundary handling maintains exploration while preventing infinite drift--]]
    
    local maxDistance = 5000
    local distance = Utils.distance(0, 0, player.x, player.y)
    
    if distance > maxDistance then
        -- Wrap around or handle boundary
        local angle = Utils.atan2(player.y, player.x)
        player.x = math.cos(angle) * maxDistance
        player.y = math.sin(angle) * maxDistance
        
        -- Reverse velocity
        player.vx = -player.vx * 0.5
        player.vy = -player.vy * 0.5
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Adaptive Physics Engine
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerMovement.updateAdaptivePhysics()
    local currentTime = love.timer.getTime()
    
    -- Safety check: ensure lastAdaptationTime is initialized
    if not AdaptivePhysics.lastAdaptationTime then
        AdaptivePhysics.lastAdaptationTime = currentTime
        return
    end
    
    -- Only recalibrate periodically to avoid constant adjustments
    if currentTime - AdaptivePhysics.lastAdaptationTime < AdaptivePhysics.adaptationInterval then
        return
    end
    
    AdaptivePhysics.lastAdaptationTime = currentTime
    
    -- Get player profile from analytics
    local PlayerAnalytics = Utils.require("src.systems.player_analytics")
    local profile = PlayerAnalytics.getPlayerProfile()
    if not profile then
        return -- Analytics not ready yet
    end
    
    -- Adapt space drag based on player skill and style
    AdaptivePhysics.currentSpaceDrag = PlayerMovement.calculateAdaptiveDrag(profile)
    
    -- Adapt camera responsiveness based on player preferences
    AdaptivePhysics.currentCameraResponse = PlayerMovement.calculateAdaptiveCameraSpeed(profile)
    
    Utils.Logger.debug("⚙️ Physics adapted: drag=%.3f, camera=%.1f", 
        AdaptivePhysics.currentSpaceDrag, AdaptivePhysics.currentCameraResponse)
end

function PlayerMovement.calculateAdaptiveDrag(profile)
    --[[
        Adaptive Drag Philosophy:
        
        Beginners benefit from higher drag (more control, less chaos)
        Experts prefer lower drag (more momentum, more skill expression)
    --]]
    
    local baseDrag = AdaptivePhysics.baseSpaceDrag
    
    -- Factor 1: Skill Level (access from metrics)
    local skillLevel = profile.metrics and profile.metrics.skillLevel or 0.5  -- Default to medium skill
    local skillFactor = (1.0 - skillLevel) * 0.005  -- Up to 0.5% drag increase
    
    -- Factor 2: Risk Tolerance (not implemented yet, default to neutral)
    local riskTolerance = profile.metrics and profile.metrics.riskTolerance or 0.5
    local riskFactor = (1.0 - riskTolerance) * 0.003  -- Up to 0.3% drag increase
    
    -- Factor 3: Current Mood (check if emotional insights exist)
    local moodFactor = 0
    local currentMood = profile.insights and profile.insights.emotional and 
                       profile.insights.emotional[1] and profile.insights.emotional[1].currentMood
    
    if currentMood == "frustrated" then
        moodFactor = 0.002  -- More drag when frustrated = easier control
    elseif currentMood == "confident" then
        moodFactor = -0.001  -- Less drag when confident = more expression
    end
    
    -- Combine factors (never go below 0.985 or above 0.995 for game balance)
    local adaptiveDrag = baseDrag + skillFactor + riskFactor + moodFactor
    return Utils.clamp(adaptiveDrag, 0.985, 0.995)
end

function PlayerMovement.calculateAdaptiveCameraSpeed(profile)
    --[[
        Adaptive Camera Philosophy:
        
        Fast camera = responsive, good for skilled players
        Slow camera = smooth, good for beginners
    --]]
    
    local baseCameraSpeed = AdaptivePhysics.baseCameraResponse
    
    -- Factor 1: Skill Level
    local skillLevel = profile.metrics and profile.metrics.skillLevel or 0.5  -- Default to medium skill
    local skillFactor = skillLevel * 0.5  -- Up to 0.5 speed increase
    
    -- Factor 2: Current Mood
    local moodFactor = 0
    local currentMood = profile.insights and profile.insights.emotional and 
                       profile.insights.emotional[1] and profile.insights.emotional[1].currentMood
    
    if currentMood == "frustrated" then
        moodFactor = -0.3  -- Slower camera when frustrated = less chaos
    elseif currentMood == "confident" then
        moodFactor = 0.2   -- Faster camera when confident = more dynamic
    elseif currentMood == "focused" then
        moodFactor = 0.1   -- Slightly faster when focused
    end
    
    -- Factor 3: Movement Style
    local movementFactor = 0
    local movementStyle = profile.playstyle and profile.playstyle.movement
    
    if movementStyle == "adventurous" then
        movementFactor = 0.3  -- Fast camera for adventurous players
    elseif movementStyle == "methodical" then
        movementFactor = -0.2  -- Slower camera for methodical players
    end
    
    -- Combine factors (keep within reasonable bounds)
    local adaptiveSpeed = baseCameraSpeed + skillFactor + moodFactor + movementFactor
    return Utils.clamp(adaptiveSpeed, 1.0, 4.0)
end

function PlayerMovement.predictLandingPosition(player, vx, vy)
    --[[Simplified Landing Prediction for analytics--]]
    
    -- Simple ballistic prediction (ignoring complex gravity interactions)
    local timeToLand = 3.0  -- Assume 3 seconds flight time on average
    local predictedX = player.x + vx * timeToLand
    local predictedY = player.y + vy * timeToLand
    
    return predictedX, predictedY
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    State Management
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerMovement.getAdaptivePhysicsStatus()
    return {
        spaceDrag = AdaptivePhysics.currentSpaceDrag,
        cameraResponse = AdaptivePhysics.currentCameraResponse,
        baseDrag = AdaptivePhysics.baseSpaceDrag,
        baseCameraResponse = AdaptivePhysics.baseCameraResponse,
        lastAdaptation = AdaptivePhysics.lastAdaptationTime,
        isAdapting = AdaptivePhysics.currentSpaceDrag ~= AdaptivePhysics.baseSpaceDrag
    }
end

function PlayerMovement.restoreAdaptivePhysics(physicsData)
    if physicsData then
        AdaptivePhysics.currentSpaceDrag = physicsData.spaceDrag or AdaptivePhysics.baseSpaceDrag
        AdaptivePhysics.currentCameraResponse = physicsData.cameraResponse or AdaptivePhysics.baseCameraResponse
        AdaptivePhysics.lastAdaptationTime = physicsData.lastAdaptation or 0
        
        Utils.Logger.info("🔄 Adaptive physics state restored from save")
    end
end

return PlayerMovement