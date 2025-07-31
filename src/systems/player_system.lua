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
    
    REFACTORED: This module now acts as a facade, coordinating between:
    - PlayerMovement: Physics simulation and movement mechanics
    - PlayerAbilities: Jump, dash, and power-up systems
    - PlayerState: State management, analytics, and persistence
--]]

local Utils = require("src.utils.utils")
local PlayerMovement = require("src.systems.player.player_movement")
local PlayerAbilities = require("src.systems.player.player_abilities")
local PlayerState = require("src.systems.player.player_state")

local PlayerSystem = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    System Initialization and Coordination
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerSystem.init()
    -- Initialize all subsystems
    PlayerMovement.init()
    PlayerAbilities.init()
    PlayerState.init()
    
    Utils.Logger.info("🚀 Player System initialized - Ready for physics magic")
    return true
end

function PlayerSystem.update(player, planets, dt, gameState)
    --[[
        The Heartbeat of Interactive Physics
        
        Coordinates updates across all player subsystems while maintaining
        backwards compatibility with the original interface.
    --]]
    
    -- Update ability cooldowns and timers
    PlayerAbilities.updateCooldowns(player, dt)
    
    -- Update power-ups
    PlayerAbilities.updatePowerUps(player, dt)
    
    -- Update movement and physics
    PlayerMovement.updateMovement(player, planets, dt)
    
    -- Update health and energy systems
    PlayerState.updateHealthEnergy(player, dt)
    
    -- Update session statistics and analytics
    PlayerState.updateSessionStats(player, gameState, dt)
end

function PlayerSystem.updateOnPlanet(player, planet, dt)
    -- Delegate to PlayerMovement for backwards compatibility
    PlayerMovement.updateOnPlanet(player, planet, dt)
end

function PlayerSystem.updateInSpace(player, planets, dt)
    -- Delegate to PlayerMovement for backwards compatibility
    PlayerMovement.updateInSpace(player, planets, dt)
end

function PlayerSystem.updateTrail(player)
    -- Delegate to PlayerMovement for backwards compatibility
    PlayerMovement.updateTrail(player)
end

function PlayerSystem.checkBoundaries(player)
    -- Delegate to PlayerMovement for backwards compatibility
    PlayerMovement.checkBoundaries(player)
end

function PlayerSystem.jump(player, pullPower, pullAngle, gameState, soundManager, planningTime)
    -- Delegate to PlayerAbilities for backwards compatibility
    return PlayerAbilities.jump(player, pullPower, pullAngle, gameState, soundManager, planningTime)
end

function PlayerSystem.dash(player, targetX, targetY, soundManager)
    -- Delegate to PlayerAbilities for backwards compatibility
    return PlayerAbilities.dash(player, targetX, targetY, soundManager)
end

function PlayerSystem.detectEmergencyDash(player, targetX, targetY)
    -- Delegate to PlayerAbilities for backwards compatibility
    return PlayerAbilities.detectEmergencyDash(player, targetX, targetY)
end

function PlayerSystem.createDashEffect(player)
    -- Delegate to PlayerAbilities for backwards compatibility
    PlayerAbilities.createDashEffect(player)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Backwards Compatibility: Legacy Function Wrappers
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerSystem.updateAdaptivePhysics()
    -- Delegate to PlayerMovement for backwards compatibility
    PlayerMovement.updateAdaptivePhysics()
end

function PlayerSystem.calculateAdaptiveDrag(profile)
    -- Delegate to PlayerMovement for backwards compatibility
    return PlayerMovement.calculateAdaptiveDrag(profile)
end

function PlayerSystem.calculateAdaptiveCameraSpeed(profile)
    -- Delegate to PlayerMovement for backwards compatibility
    return PlayerMovement.calculateAdaptiveCameraSpeed(profile)
end

function PlayerSystem.predictLandingPosition(player, vx, vy)
    -- Delegate to PlayerMovement for backwards compatibility
    return PlayerMovement.predictLandingPosition(player, vx, vy)
end

function PlayerSystem.getAdaptivePhysicsStatus()
    -- Delegate to PlayerMovement for backwards compatibility
    return PlayerMovement.getAdaptivePhysicsStatus()
end

function PlayerSystem.restoreAdaptivePhysics(physicsData)
    -- Delegate to PlayerMovement for backwards compatibility
    PlayerMovement.restoreAdaptivePhysics(physicsData)
end

function PlayerSystem.onPlanetLanding(player, planet, gameState)
    -- Delegate to PlayerState for backwards compatibility
    PlayerState.onPlanetLanding(player, planet, gameState)
end

return PlayerSystem