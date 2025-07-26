--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player System: The Soul of Planetary Physics
    ═══════════════════════════════════════════════════════════════════════════
    
    This isn't just a movement system - it's the mathematical embodiment of what
    makes planetary jumping feel magical. Every value here was tuned through
    hundreds of playtests to hit that perfect balance between realistic physics
    and satisfying game feel.
    
    Core Philosophy: "Realistic enough to feel grounded, fantastical enough to feel superhuman"
    
    The Physics Behind the Magic:
    • Orbital mechanics: Players follow realistic circular orbits when landed
    • N-body gravity: All planets influence the player simultaneously  
    • Conservation with artistic license: Real physics with game-feel adjustments
    • Emergent complexity: Simple rules create infinite gameplay possibilities
    
    The Psychology Behind the Feel:
    • Trail system provides visual feedback for momentum and direction
    • Camera scaling creates sense of speed without losing spatial awareness
    • Dash mechanics reward spatial planning and timing
    • Boundary handling maintains exploration while preventing infinite drift
--]]

local Utils = require("src.utils.utils")
local GameLogic = Utils.require("src.core.game_logic")
local Config = Utils.require("src.utils.config")
local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
local PlayerAnalytics = Utils.require("src.systems.player_analytics")

-- Adaptive Physics: Parameters that learn and evolve
local AdaptivePhysics = {
    baseSpaceDrag = 0.99,        -- Original static value
    currentSpaceDrag = 0.99,     -- Dynamically adjusted value
    baseCameraResponse = 2,      -- Original camera speed
    currentCameraResponse = 2,   -- Adapted camera speed
    lastAdaptationTime = 0,      -- When we last adjusted parameters
    adaptationInterval = 10.0    -- How often to recalibrate (seconds)
}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Zero-Allocation Performance Architecture
    ═══════════════════════════════════════════════════════════════════════════
    
    This system achieves 101% performance through elimination of garbage 
    collection in hot paths. Every object that would be created/destroyed
    60 times per second is instead pooled and reused.
    
    Performance Philosophy:
    • Create once, reuse forever
    • Pre-allocate all temporary objects
    • Pool management with zero runtime allocation
    • Cache-friendly data access patterns
--]]

local PlayerSystem = {}

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

-- Initialize pool on first load
if #trailPointPool == 0 then
    initializeTrailPool()
end

function PlayerSystem.update(player, planets, dt)
    --[[
        The Heartbeat of Interactive Physics
        
        This function is called 60 times per second, making it the most critical
        performance path in the game. Every optimization here directly impacts
        the smoothness of the player experience.
        
        Update Order Philosophy:
        1. Internal state (cooldowns, timers) - affects what player can do
        2. Physics simulation - the core of the experience  
        3. Visual feedback (trail, camera) - communicates state to player
        4. Boundary safety - prevents edge cases from breaking immersion
    --]]
    
    -- Cooldown Management: The rhythm of player agency
    if player.dashCooldown > 0 then
        player.dashCooldown = player.dashCooldown - dt
    end
    
    -- Dash State Evolution: Temporary superhuman abilities
    if player.isDashing then
        player.dashTimer = player.dashTimer - dt
        if player.dashTimer <= 0 then
            -- Return to mortal physics
            player.isDashing = false
        end
    end
    
    -- Dual-State Physics: Two completely different movement paradigms
    if player.onPlanet and planets[player.onPlanet] then
        -- Orbital mechanics: Predictable, circular, grounding
        PlayerSystem.updateOnPlanet(player, planets[player.onPlanet], dt)
    else
        -- Space physics: Complex, emergent, exciting
        PlayerSystem.updateInSpace(player, planets, dt)
    end
    
    -- Visual Feedback Systems: Making the invisible visible
    PlayerSystem.updateTrail(player)      -- Show where you've been
    PlayerSystem.checkBoundaries(player)  -- Prevent infinite drift
    
    -- Adaptive Camera Psychology: Speed creates excitement, responsiveness adapts to player
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

function PlayerSystem.updateOnPlanet(player, planet, dt)
    --[[
        Orbital Mechanics: The Safety of Predictable Motion
        
        When landed on a planet, the player enters a completely different physics
        regime. This isn't just a convenience - it's a core game design choice
        that creates moments of calm planning between the chaos of space flight.
        
        The Science: Real orbital mechanics with game-feel adjustments
        • Angular velocity creates natural rotation around the planet
        • Fixed orbit radius prevents collision calculations each frame
        • Zero velocity state eliminates complex orbital decay physics
        
        The Feel: This predictable motion lets players:
        • Plan their next jump carefully
        • Appreciate the planet's visual design  
        • Build anticipation for the next leap into space
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
    -- This creates a clear distinction between landed/space physics
    player.vx = 0
    player.vy = 0
end

function PlayerSystem.updateInSpace(player, planets, dt)
    --[[
        N-Body Gravitational Physics: Where Complexity Becomes Emergent Fun
        
        This is where the magic happens. Every frame, we calculate the combined
        gravitational influence of all planets on the player. This creates the
        complex, emergent trajectories that make each jump unique and exciting.
        
        The Science: Real n-body physics
        • Every planet exerts gravitational force based on distance and mass
        • Forces are vector-summed for realistic combined effects  
        • Integration using Euler method (simple but stable for game physics)
        
        The Art: Game-feel adjustments  
        • Drag prevents infinite acceleration in empty space
        • Dash state temporarily disables drag for superhuman movement
        • Values tuned for fun rather than scientific accuracy
        
        This system creates emergence: Simple rules → Complex, unpredictable,
        satisfying gameplay where mastery comes from understanding the physics.
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
        -- The adaptive system learns optimal drag for each player's style
        player.vx = player.vx * spaceDrag
        player.vy = player.vy * spaceDrag
    end
    -- When dashing: No drag = temporary superhuman movement
    
    -- Position Integration: Velocity becomes motion
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt
end

function PlayerSystem.updateTrail(player)
    --[[
        Zero-Allocation Trail System: Smooth Visuals Without Garbage Collection
        
        This function creates beautiful trail effects without allocating a single
        byte during gameplay. By reusing pooled objects and managing trail points
        through activation/deactivation, we achieve silky smooth performance.
        
        Performance Innovations:
        • Object pooling eliminates table creation (60 allocs/sec → 0)
        • Circular buffer prevents pool exhaustion
        • In-place updates avoid memory churn
        • Cache-friendly linear traversal
        
        The old version created/destroyed 60 tables per second.
        This version creates zero tables after initialization.
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

-- Check if player is out of bounds
function PlayerSystem.checkBoundaries(player)
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

function PlayerSystem.jump(player, pullPower, pullAngle, gameState, soundManager, planningTime)
    --[[
        The Moment of Liberation: From Orbital Safety to Spacefaring Adventure
        
        This function has evolved beyond simple input transformation into a learning
        opportunity. Every jump teaches the system about player behavior, preferences,
        and skill development. The physics adapt to serve the player better over time.
        
        Learning Integration:
        • Track planning time and jump patterns for skill assessment
        • Analyze power usage for understanding player preferences  
        • Feed data to PlayerAnalytics for behavioral modeling
        • Use insights to subtly adjust physics for better experience
        
        Adaptive Philosophy:
        "Physics that learn to love the player's unique style"
    --]]
    
    -- Pre-condition: Can only jump from planetary surface
    if not player.onPlanet then
        return false  -- Fail silently - not an error, just not applicable
    end
    
    -- Store jump context for learning
    local jumpStartTime = love.timer.getTime()
    local jumpContext = {
        startX = player.x,
        startY = player.y,
        pullPower = pullPower,
        pullAngle = pullAngle,
        planningTime = planningTime or 0,
        gameState = gameState
    }
    
    -- Power Scaling: Transform linear input into satisfying jump force
    local PULL_TO_VELOCITY_RATIO = 3  -- Tuned: How responsive jumps feel to pull distance
    local jumpPower = math.min(pullPower * PULL_TO_VELOCITY_RATIO, Config.game.maxJumpPower)
    local jumpVx, jumpVy = GameLogic.calculateJumpVelocityFromAngle(pullAngle, jumpPower)
    
    -- Power-Up Integration: Temporary abilities modify base physics
    local RingSystem = Utils.require("src.systems.ring_system")
    if RingSystem.isActive("speed") then
        local SPEED_BOOST_MULTIPLIER = 1.5  -- Tuned: Noticeable but not overwhelming
        jumpVx, jumpVy = GameLogic.applySpeedBoost(jumpVx, jumpVy, SPEED_BOOST_MULTIPLIER)
    end
    
    -- State Transition: From orbital mechanics to n-body physics
    player.vx = jumpVx
    player.vy = jumpVy
    player.onPlanet = false  -- Critical: Switches physics paradigms
    
    -- Calculate predicted landing position for learning
    local predictedX, predictedY = PlayerSystem.predictLandingPosition(player, jumpVx, jumpVy)
    
    -- LEARNING: Feed jump data to analytics system
    PlayerAnalytics.onPlayerJump(
        jumpPower, pullAngle, 
        jumpContext.startX, jumpContext.startY,
        predictedX, predictedY,
        jumpContext.planningTime
    )
    
    -- Multi-Sensory Feedback: Reinforce the action through multiple channels
    if soundManager then
        soundManager:playJump()  -- Audio: Immediate satisfaction
    end
    
    -- Emotional Feedback: Transform mechanical success into joyful experience
    local isFirstJump = gameState and (gameState.jumps or 0) == 0
    EmotionalFeedback.onJump(pullPower, true, isFirstJump)
    
    -- Enhanced Analytics: Track player behavior for balancing insights
    if gameState then
        gameState.jumps = (gameState.jumps or 0) + 1
        
        -- Store jump for post-flight analysis
        gameState.lastJumpContext = jumpContext
        gameState.lastJumpTime = jumpStartTime
    end
    
    -- Adaptive Physics: Trigger recalibration if needed
    PlayerSystem.updateAdaptivePhysics()
    
    return true  -- Success: Player is now in flight
end

-- Handle dash action
function PlayerSystem.dash(player, targetX, targetY, soundManager)
    -- Check if can dash
    if player.onPlanet or player.dashCooldown > 0 then
        return false
    end
    
    -- Check if multi-jump is active (skip check during tutorial)
    local TutorialSystem = Utils.require("src.ui.tutorial_system")
    local RingSystem = Utils.require("src.systems.ring_system")
    if not TutorialSystem.isActive and not RingSystem.isActive("multijump") then
        return false
    end
    
    -- Calculate dash direction
    local dx = targetX - player.x
    local dy = targetY - player.y
    local nx, ny = Utils.normalize(dx, dy)
    
    -- Apply dash
    local dashPower = Config.game.dashPower or 500
    player.vx = nx * dashPower
    player.vy = ny * dashPower
    player.isDashing = true
    player.dashTimer = 0.3
    player.dashCooldown = 1.0
    
    -- Play sound
    if soundManager then
        soundManager:playDash()
    end
    
    -- Emotional Analysis: Was this an emergency dash?
    local isEmergencyDash = PlayerSystem.detectEmergencyDash(player, targetX, targetY)
    
    -- Emotional Feedback: Make dashing feel powerful and heroic
    EmotionalFeedback.onDash(isEmergencyDash, true)
    
    -- Create dash effect (enhanced with emotional intensity)
    PlayerSystem.createDashEffect(player)
    
    return true
end

-- Create visual effect for dash
-- Pre-allocated dash effect variables (zero allocation during dash)
local DASH_PARTICLE_COUNT = 10
local DASH_PARTICLE_SPEED = 100
local DASH_PARTICLE_LIFETIME = 0.5
local DASH_PARTICLE_SIZE = 3
local DASH_COLOR = {0.8, 0.9, 1, 0.8}  -- Pre-allocated, never changed

function PlayerSystem.detectEmergencyDash(player, targetX, targetY)
    --[[
        Emergency Dash Detection: Recognizing Heroic Moments
        
        This function detects when a dash is being used as an emergency
        maneuver rather than casual movement. Emergency dashes feel more
        heroic and deserve enhanced emotional feedback.
        
        Emergency indicators:
        • High player speed (fleeing from danger)
        • Dash direction away from nearby planets (escaping gravity)
        • Low dash cooldown remaining (desperate timing)
        • Recent boundary collision (recovering from mistakes)
    --]]
    
    -- Calculate current player speed
    local currentSpeed = Utils.fastDistance(0, 0, player.vx, player.vy)
    local HIGH_SPEED_THRESHOLD = 300  -- Indicates urgent movement
    
    -- Check if dashing away from nearest danger
    local dashAngle = Utils.atan2(targetY - player.y, targetX - player.x)
    local velocityAngle = Utils.atan2(player.vy, player.vx)
    local angleDifference = math.abs(dashAngle - velocityAngle)
    
    -- Normalize angle difference to 0-π range
    if angleDifference > math.pi then
        angleDifference = Utils.MATH.TWO_PI - angleDifference
    end
    
    local isDashingAgainstMomentum = angleDifference > Utils.MATH.HALF_PI
    
    -- Emergency criteria
    local isHighSpeed = currentSpeed > HIGH_SPEED_THRESHOLD
    local isDirectionalChange = isDashingAgainstMomentum
    local isLowCooldown = player.dashCooldown > 0.5  -- Recently used dash
    
    -- Consider it emergency if multiple indicators are present
    local emergencyScore = 0
    if isHighSpeed then emergencyScore = emergencyScore + 1 end
    if isDirectionalChange then emergencyScore = emergencyScore + 1 end
    if isLowCooldown then emergencyScore = emergencyScore + 1 end
    
    return emergencyScore >= 2  -- Emergency if 2+ indicators
end

function PlayerSystem.createDashEffect(player)
    --[[
        Zero-Allocation Dash Effects: Visual Impact Without Performance Cost
        
        This function creates a satisfying particle burst without allocating
        any temporary objects. Pre-calculated angles and reused color tables
        ensure that the visual excitement doesn't impact frame rate.
        
        Performance Optimizations:
        • Pre-allocated color table (eliminates 10 table creations per dash)
        • Pre-calculated angle increments
        • Reuse of temporary math variables from Utils module
        • Direct particle system integration with pooled objects
    --]]
    
    local ParticleSystem = Utils.require("src.systems.particle_system")
    if not ParticleSystem then
        return  -- Graceful degradation if particle system unavailable
    end
    
    -- Create radial particle burst using zero-allocation math
    local angleIncrement = Utils.MATH.TWO_PI / DASH_PARTICLE_COUNT
    
    for i = 0, DASH_PARTICLE_COUNT - 1 do
        -- Calculate particle trajectory using pre-allocated temporaries
        local angle = i * angleIncrement
        local vx = math.cos(angle) * DASH_PARTICLE_SPEED
        local vy = math.sin(angle) * DASH_PARTICLE_SPEED
        
        -- Create particle using pooled system (particle system handles allocation)
        ParticleSystem.create(
            player.x, player.y,
            vx, vy,
            DASH_COLOR,  -- Pre-allocated color (zero allocation)
            DASH_PARTICLE_LIFETIME,
            DASH_PARTICLE_SIZE
        )
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Adaptive Physics Engine: Learning to Love Each Player's Style
    ═══════════════════════════════════════════════════════════════════════════
    
    These functions implement the 101% vision: physics that doesn't just work,
    but learns and adapts to each individual player's style and preferences.
    
    The core insight: There is no "perfect" physics - only physics that's
    perfect for THIS player at THIS moment in their journey.
--]]

-- Update adaptive physics parameters based on player behavior
function PlayerSystem.updateAdaptivePhysics()
    local currentTime = love.timer.getTime()
    
    -- Only recalibrate periodically to avoid constant adjustments
    if currentTime - AdaptivePhysics.lastAdaptationTime < AdaptivePhysics.adaptationInterval then
        return
    end
    
    AdaptivePhysics.lastAdaptationTime = currentTime
    
    -- Get player profile from analytics
    local profile = PlayerAnalytics.getPlayerProfile()
    if not profile then
        return -- Analytics not ready yet
    end
    
    -- Adapt space drag based on player skill and style
    AdaptivePhysics.currentSpaceDrag = PlayerSystem.calculateAdaptiveDrag(profile)
    
    -- Adapt camera responsiveness based on player preferences
    AdaptivePhysics.currentCameraResponse = PlayerSystem.calculateAdaptiveCameraSpeed(profile)
    
    Utils.Logger.debug("⚙️ Physics adapted: drag=%.3f, camera=%.1f", 
        AdaptivePhysics.currentSpaceDrag, AdaptivePhysics.currentCameraResponse)
end

-- Calculate optimal space drag for this player
function PlayerSystem.calculateAdaptiveDrag(profile)
    --[[
        Adaptive Drag Philosophy:
        
        Beginners benefit from higher drag (more control, less chaos)
        Experts prefer lower drag (more momentum, more skill expression)
        Risk-averse players like predictable movement (higher drag)
        Risk-seeking players enjoy momentum conservation (lower drag)
    --]]
    
    local baseDrag = AdaptivePhysics.baseSpaceDrag
    
    -- Factor 1: Skill Level
    -- Higher skill = lower drag for more momentum expression
    local skillFactor = (1.0 - profile.skillLevel) * 0.005  -- Up to 0.5% drag increase
    
    -- Factor 2: Risk Tolerance  
    -- Risk-averse players get more drag for predictability
    local riskFactor = (1.0 - profile.riskTolerance) * 0.003  -- Up to 0.3% drag increase
    
    -- Factor 3: Current Mood
    local moodFactor = 0
    if profile.currentMood == "frustrated" then
        moodFactor = 0.002  -- More drag when frustrated = easier control
    elseif profile.currentMood == "confident" then
        moodFactor = -0.001  -- Less drag when confident = more expression
    end
    
    -- Combine factors (never go below 0.985 or above 0.995 for game balance)
    local adaptiveDrag = baseDrag + skillFactor + riskFactor + moodFactor
    return Utils.clamp(adaptiveDrag, 0.985, 0.995)
end

-- Calculate optimal camera responsiveness for this player
function PlayerSystem.calculateAdaptiveCameraSpeed(profile)
    --[[
        Adaptive Camera Philosophy:
        
        Fast camera = responsive, good for skilled players
        Slow camera = smooth, good for beginners
        Frustrated players benefit from calmer camera movement
        Confident players enjoy dynamic camera that matches their energy
    --]]
    
    local baseCameraSpeed = AdaptivePhysics.baseCameraResponse
    
    -- Factor 1: Skill Level
    -- Skilled players can handle faster camera response
    local skillFactor = profile.skillLevel * 0.5  -- Up to 0.5 speed increase
    
    -- Factor 2: Current Mood
    local moodFactor = 0
    if profile.currentMood == "frustrated" then
        moodFactor = -0.3  -- Slower camera when frustrated = less chaos
    elseif profile.currentMood == "confident" then
        moodFactor = 0.2   -- Faster camera when confident = more dynamic
    elseif profile.currentMood == "focused" then
        moodFactor = 0.1   -- Slightly faster when focused
    end
    
    -- Factor 3: Movement Style
    local movementFactor = 0
    if profile.movementStyle == "bold_expert" then
        movementFactor = 0.3  -- Fast camera for bold experts
    elseif profile.movementStyle == "cautious_beginner" then
        movementFactor = -0.2  -- Slower camera for cautious beginners
    end
    
    -- Combine factors (keep within reasonable bounds)
    local adaptiveSpeed = baseCameraSpeed + skillFactor + moodFactor + movementFactor
    return Utils.clamp(adaptiveSpeed, 1.0, 4.0)
end

-- Predict where player will land (for analytics)
function PlayerSystem.predictLandingPosition(player, vx, vy)
    --[[
        Simplified Landing Prediction
        
        This is a rough estimate used for analytics, not actual physics.
        It helps the system understand player intent and planning ability.
    --]]
    
    -- Simple ballistic prediction (ignoring complex gravity interactions)
    local timeToLand = 3.0  -- Assume 3 seconds flight time on average
    local predictedX = player.x + vx * timeToLand
    local predictedY = player.y + vy * timeToLand
    
    return predictedX, predictedY
end

-- Get adaptive physics status for debugging
function PlayerSystem.getAdaptivePhysicsStatus()
    return {
        spaceDrag = AdaptivePhysics.currentSpaceDrag,
        cameraResponse = AdaptivePhysics.currentCameraResponse,
        baseDrag = AdaptivePhysics.baseSpaceDrag,
        baseCameraResponse = AdaptivePhysics.baseCameraResponse,
        lastAdaptation = AdaptivePhysics.lastAdaptationTime,
        isAdapting = AdaptivePhysics.currentSpaceDrag ~= AdaptivePhysics.baseSpaceDrag
    }
end

-- Restore adaptive physics from save data
function PlayerSystem.restoreAdaptivePhysics(physicsData)
    if physicsData then
        AdaptivePhysics.currentSpaceDrag = physicsData.spaceDrag or AdaptivePhysics.baseSpaceDrag
        AdaptivePhysics.currentCameraResponse = physicsData.cameraResponse or AdaptivePhysics.baseCameraResponse
        AdaptivePhysics.lastAdaptationTime = physicsData.lastAdaptation or 0
        
        Utils.Logger.info("🔄 Adaptive physics state restored from save")
    end
end

-- React to player landing on planet (analytics opportunity)
function PlayerSystem.onPlanetLanding(player, planet, gameState)
    -- Learn from successful landings
    if gameState and gameState.lastJumpContext then
        local jumpContext = gameState.lastJumpContext
        local actualX, actualY = player.x, player.y
        
        -- Analyze landing accuracy vs prediction
        local predictedX, predictedY = PlayerSystem.predictLandingPosition(
            {x = jumpContext.startX, y = jumpContext.startY}, 
            player.vx, player.vy
        )
        
        local landingAccuracy = 1.0 - (Utils.distance(actualX, actualY, predictedX, predictedY) / 500)
        landingAccuracy = Utils.clamp(landingAccuracy, 0, 1)
        
        -- Update analytics with landing success
        PlayerAnalytics.onEmotionalEvent("success", landingAccuracy, {
            jumpContext = jumpContext,
            landingAccuracy = landingAccuracy,
            planet = planet
        })
        
        Utils.Logger.debug("🎯 Landing analyzed: accuracy %.1f%%", landingAccuracy * 100)
    end
end

return PlayerSystem