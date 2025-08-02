--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player Abilities: Jump, dash, and power-up mechanics
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles all player abilities including jumps, dashes, power-ups,
    and ability cooldowns. It manages the "superhuman" aspects of player control.
--]]

local Utils = require("src.utils.utils")
local GameLogic = Utils.require("src.core.game_logic")
local Config = Utils.require("src.utils.config")
local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")

local PlayerAbilities = {}

-- Pre-allocated dash effect variables (zero allocation during dash)
local DASH_PARTICLE_COUNT = 10
local DASH_PARTICLE_SPEED = 100
local DASH_PARTICLE_LIFETIME = 0.5
local DASH_PARTICLE_SIZE = 3
local DASH_COLOR = {0.8, 0.9, 1, 0.8}  -- Pre-allocated, never changed

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Ability System Initialization
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerAbilities.init()
    Utils.Logger.info("⚡ Player Abilities initialized")
    return true
end

function PlayerAbilities.updateCooldowns(player, dt)
    --[[Cooldown Management: The rhythm of player agency--]]
    
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
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Jump Mechanics: The Moment of Liberation
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerAbilities.jump(player, pullPower, pullAngle, gameState, soundManager, planningTime)
    --[[
        The Moment of Liberation: From Orbital Safety to Spacefaring Adventure
        
        This function transforms player input into physics while learning about
        player behavior and preferences for adaptive improvements.
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
    
    -- Check for random events on jump
    local RandomEventsSystem = Utils.require("src.systems.random_events_system")
    if RandomEventsSystem then
        RandomEventsSystem:checkForRandomEvent()
    end
    
    -- Calculate predicted landing position for learning
    local PlayerMovement = Utils.require("src.systems.player.player_movement")
    local predictedX, predictedY = PlayerMovement.predictLandingPosition(player, jumpVx, jumpVy)
    
    -- LEARNING: Feed jump data to analytics system
    local PlayerAnalytics = Utils.require("src.systems.player_analytics")
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
    EmotionalFeedback.processEvent("jump", {
        pullPower = pullPower,
        success = true,
        isFirstJump = isFirstJump
    })
    
    -- Enhanced Analytics: Track player behavior for balancing insights
    if gameState then
        gameState.jumps = (gameState.jumps or 0) + 1
        
        -- Store jump for post-flight analysis
        gameState.lastJumpContext = jumpContext
        gameState.lastJumpTime = jumpStartTime
    end
    
    -- Adaptive Physics: Trigger recalibration if needed
    PlayerMovement.updateAdaptivePhysics()
    
    return true  -- Success: Player is now in flight
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Dash Mechanics: Superhuman Power Activation
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerAbilities.dash(player, targetX, targetY, soundManager)
    --[[Handle dash action with emergency detection and feedback--]]
    
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
    local isEmergencyDash = PlayerAbilities.detectEmergencyDash(player, targetX, targetY)
    
    -- Emotional Feedback: Make dashing feel powerful and heroic
    EmotionalFeedback.processEvent("dash", {
        emergency = isEmergencyDash,
        success = true
    })
    
    -- Create dash effect (enhanced with emotional intensity)
    PlayerAbilities.createDashEffect(player)
    
    return true
end

function PlayerAbilities.detectEmergencyDash(player, targetX, targetY)
    --[[
        Emergency Dash Detection: Recognizing Heroic Moments
        
        This function detects when a dash is being used as an emergency
        maneuver rather than casual movement. Emergency dashes feel more
        heroic and deserve enhanced emotional feedback.
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

function PlayerAbilities.createDashEffect(player)
    --[[
        Zero-Allocation Dash Effects: Visual Impact Without Performance Cost
        
        Creates a satisfying particle burst without allocating any temporary objects.
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
    Power-Up System Integration
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerAbilities.applyPowerUp(player, powerUpType, duration)
    --[[Apply temporary power-up effects to player--]]
    
    if not player.powerUps then
        player.powerUps = {}
    end
    
    -- Add or refresh power-up
    player.powerUps[powerUpType] = {
        duration = duration or 10.0,  -- Default 10 seconds
        startTime = love.timer.getTime()
    }
    
    Utils.Logger.info("⚡ Power-up applied: %s for %.1fs", powerUpType, duration or 10.0)
end

function PlayerAbilities.updatePowerUps(player, dt)
    --[[Update power-up timers and remove expired ones--]]
    
    if not player.powerUps then
        return
    end
    
    local currentTime = love.timer.getTime()
    local expiredPowerUps = {}
    
    for powerUpType, powerUp in pairs(player.powerUps) do
        local elapsed = currentTime - powerUp.startTime
        if elapsed >= powerUp.duration then
            table.insert(expiredPowerUps, powerUpType)
        end
    end
    
    -- Remove expired power-ups
    for _, powerUpType in ipairs(expiredPowerUps) do
        player.powerUps[powerUpType] = nil
        Utils.Logger.info("⚡ Power-up expired: %s", powerUpType)
    end
end

function PlayerAbilities.hasPowerUp(player, powerUpType)
    --[[Check if player currently has a specific power-up--]]
    
    if not player.powerUps or not player.powerUps[powerUpType] then
        return false
    end
    
    local currentTime = love.timer.getTime()
    local powerUp = player.powerUps[powerUpType]
    local elapsed = currentTime - powerUp.startTime
    
    return elapsed < powerUp.duration
end

function PlayerAbilities.getPowerUpTimeRemaining(player, powerUpType)
    --[[Get remaining time for a power-up--]]
    
    if not PlayerAbilities.hasPowerUp(player, powerUpType) then
        return 0
    end
    
    local currentTime = love.timer.getTime()
    local powerUp = player.powerUps[powerUpType]
    local elapsed = currentTime - powerUp.startTime
    
    return math.max(0, powerUp.duration - elapsed)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Ability State Management
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerAbilities.canJump(player)
    --[[Check if player can currently jump--]]
    return player.onPlanet ~= false and player.onPlanet ~= nil
end

function PlayerAbilities.canDash(player)
    --[[Check if player can currently dash--]]
    
    if player.onPlanet or player.dashCooldown > 0 then
        return false
    end
    
    -- Check if multi-jump is active (skip check during tutorial)
    local TutorialSystem = Utils.require("src.ui.tutorial_system")
    local RingSystem = Utils.require("src.systems.ring_system")
    
    return TutorialSystem.isActive or RingSystem.isActive("multijump")
end

function PlayerAbilities.getAbilityStatus(player)
    --[[Get current status of all player abilities--]]
    
    return {
        canJump = PlayerAbilities.canJump(player),
        canDash = PlayerAbilities.canDash(player),
        dashCooldown = player.dashCooldown or 0,
        isDashing = player.isDashing or false,
        dashTimer = player.dashTimer or 0,
        powerUps = player.powerUps or {}
    }
end

function PlayerAbilities.resetAbilities(player)
    --[[Reset all ability states (useful for respawn/restart)--]]
    
    player.dashCooldown = 0
    player.isDashing = false
    player.dashTimer = 0
    player.powerUps = {}
    
    Utils.Logger.info("⚡ Player abilities reset")
end

return PlayerAbilities