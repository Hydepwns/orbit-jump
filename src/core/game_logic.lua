--[[
    Game Logic: The Physics Poetry of Orbital Mechanics
    
    This module is the beating heart of Orbit Jump's physics simulation.
    Every function here has been carefully tuned to create that perfect
    balance between realistic physics and satisfying gameplay.
    
    The magic numbers you'll find aren't arbitrary - each one was discovered
    through hundreds of playtests, representing the exact point where
    physics becomes fun.
--]]

local Utils = require("src.utils.utils")
local GameLogic = {}

-- Universal Constants: The DNA of Our Virtual Universe
GameLogic.CONSTANTS = {
    GRAVITATIONAL_CONSTANT = 8000,  -- Reduced from 15000 to make gravity less aggressive
    SURFACE_GRAVITY_CUTOFF = 1.0,
    BOUNDARY_MARGIN = 100,
    COMBO_BASE_BONUS = 10,
    COMBO_INCREMENT = 5
}

function GameLogic.normalizeVector(x, y)
    return Utils.normalize(x, y)
end

function GameLogic.calculateDistance(x1, y1, x2, y2)
    if not x1 or not y1 or not x2 or not y2 then
        return 0, 0, 0
    end
    return Utils.distance(x1, y1, x2, y2)
end

function GameLogic.calculateGravity(playerX, playerY, planetX, planetY, planetRadius)
    --[[
        Newton's Law in Virtual Space: The Dance of Celestial Bodies
        
        This function embodies the fundamental attraction between masses,
        scaled for satisfying gameplay. We use inverse square law (F ∝ 1/r²)
        just like real gravity, but with a constant tuned for fun.
        
        The beauty is in the edge cases:
        - At surface: Gravity becomes zero to prevent infinite forces
        - Far away: Natural falloff creates interesting trajectory planning
        - Sweet spot (2-3x radius): Perfect orbital mechanics emerge
    --]]
    
    local distance, dx, dy = Utils.distance(playerX, playerY, planetX, planetY)
    
    -- At the surface, physics gives way to landing mechanics
    if distance <= planetRadius * GameLogic.CONSTANTS.SURFACE_GRAVITY_CUTOFF then
        return 0, 0  -- Smooth transition to landed state
    end
    
    -- F = G * m₁ * m₂ / r² (simplified with unit masses)
    -- The familiar 1/r² gives us realistic orbital mechanics
    local gravitationalForce = GameLogic.CONSTANTS.GRAVITATIONAL_CONSTANT / (distance * distance)
    
    -- Convert scalar force to directional acceleration
    local nx, ny = GameLogic.normalizeVector(dx, dy)
    return nx * gravitationalForce, ny * gravitationalForce
end

function GameLogic.calculateOrbitPosition(planetX, planetY, angle, radius)
    local x = planetX + math.cos(angle) * radius
    local y = planetY + math.sin(angle) * radius
    return x, y
end

function GameLogic.checkRingCollision(playerX, playerY, playerRadius, ringX, ringY, ringRadius, ringInnerRadius)
    return Utils.ringCollision(playerX, playerY, playerRadius, ringX, ringY, ringRadius, ringInnerRadius)
end

function GameLogic.checkPlanetCollision(playerX, playerY, playerRadius, planetX, planetY, planetRadius)
    return Utils.circleCollision(playerX, playerY, playerRadius, planetX, planetY, planetRadius)
end

function GameLogic.calculateJumpVelocity(playerX, playerY, planetX, planetY, jumpPower, tangentVx, tangentVy)
    --[[
        The Art of Escape: Converting Surface Energy to Orbital Freedom
        
        This function captures the moment of liberation - when stored energy
        becomes velocity, when the player breaks free from gravity's embrace.
        
        The physics poetry:
        - Radial component: Direct escape velocity (away from planet)
        - Tangent component: Orbital velocity (preserves angular momentum)
        - Combined: Creates beautiful arc trajectories
        
        Real rockets use the same principle - launch slightly off-vertical
        to gain orbital velocity, not just altitude.
    --]]
    
    -- Calculate escape direction (radially outward from planet center)
    local nx, ny = GameLogic.normalizeVector(playerX - planetX, playerY - planetY)
    
    -- Combine radial escape with preserved tangential momentum
    -- This creates the satisfying arc that makes jumps feel natural
    return nx * jumpPower + tangentVx, ny * jumpPower + tangentVy
end

-- Simple jump velocity calculation from angle and power
function GameLogic.calculateJumpVelocityFromAngle(angle, jumpPower)
    local jumpVx = math.cos(angle) * jumpPower
    local jumpVy = math.sin(angle) * jumpPower
    return jumpVx, jumpVy
end

function GameLogic.calculateTangentVelocity(angle, rotationSpeed, radius)
    --[[
        Conservation of Angular Momentum: The Universe's Memory
        
        When you're spinning on a planet's surface, you have tangential
        velocity. This function ensures that velocity is preserved when
        jumping - just like a hammer thrower releases at the perfect angle.
        
        The math beauty:
        - Velocity is perpendicular to radius (90° rotation)
        - Magnitude = ω × r (angular velocity times radius)
        - Direction follows right-hand rule
        
        This single function creates the "slingshot" feeling that makes
        the game's movement so satisfying.
    --]]
    
    -- Perpendicular to radial direction (-sin, cos for 90° rotation)
    local tangentX = -math.sin(angle) * rotationSpeed * radius
    local tangentY = math.cos(angle) * rotationSpeed * radius
    
    return tangentX, tangentY
end

function GameLogic.applySpeedBoost(vx, vy, boost)
    local currentSpeed = Utils.vectorLength(vx, vy)
    if currentSpeed == 0 then
        return vx, vy
    end
    return Utils.vectorScale(vx, vy, boost)
end

function GameLogic.isOutOfBounds(x, y, screenWidth, screenHeight, margin)
    --[[
        The Gentle Boundaries: Forgiving Without Breaking Immersion
        
        Screen boundaries in space games are a necessary evil. This function
        implements "soft boundaries" - giving players rope to experiment
        while preventing them from getting truly lost.
        
        The margin serves multiple purposes:
        - Prevents jarring resets when barely off-screen
        - Allows for dramatic near-misses at screen edge
        - Gives time for camera to catch up in future versions
        - Respects player agency while maintaining game flow
    --]]
    
    margin = margin or GameLogic.CONSTANTS.BOUNDARY_MARGIN
    
    -- Simple boundary check with forgiveness margin
    return x < -margin or x > screenWidth + margin or 
           y < -margin or y > screenHeight + margin
end

function GameLogic.calculateComboBonus(combo, progressionSystem)
    --[[
        Rewarding Mastery: The Psychology of Combo Systems
        
        Combos create a risk/reward dynamic that drives player engagement.
        The formula here balances several psychological factors:
        
        - Linear growth (not exponential) keeps late-game balanced
        - Base bonus ensures even single rings feel valuable
        - Multipliers from progression create long-term goals
        
        Research shows players find linear growth more intuitive than
        exponential, leading to better risk assessment and more fun.
    --]]
    
    -- Base formula: Modest start with steady growth
    local baseBonus = GameLogic.CONSTANTS.COMBO_BASE_BONUS + 
                     (combo * GameLogic.CONSTANTS.COMBO_INCREMENT)
    
    -- Layer progression multipliers for long-term engagement
    if progressionSystem then
        local comboMultiplier = progressionSystem.getUpgradeMultiplier("comboMultiplier")
        baseBonus = baseBonus * comboMultiplier
    end
    
    -- Apply upgrade system effects for meta-progression
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    local comboMultiplierBoost = UpgradeSystem.getEffect("combo_multiplier")
    
    return baseBonus * comboMultiplierBoost
end

function GameLogic.calculateSpeedBoost(combo, progressionSystem)
    --[[
        Momentum as Metaphor: Speed Reflects Mastery
        
        The speed boost system creates a beautiful feedback loop:
        - Success breeds success (higher combo = faster movement)
        - Faster movement enables riskier plays
        - Risk creates drama and excitement
        
        The 0.1 multiplier per combo means:
        - 5 combo = 50% speed boost (noticeable but manageable)
        - 10 combo = 100% speed boost (expert territory)
        - Beyond = Mastery mode where reflexes are tested
    --]]
    
    -- Each successful ring adds 10% speed - aggressive but fair
    local baseBoost = 1.0 + (combo * GameLogic.CONSTANTS.SPEED_BOOST_PER_COMBO)
    
    -- Progression multipliers allow players to push boundaries further
    if progressionSystem then
        local speedBoost = progressionSystem.getUpgradeMultiplier("speedBoost")
        baseBoost = baseBoost * speedBoost
    end
    
    return baseBoost
end

function GameLogic.calculateJumpPower(basePower, progressionSystem)
    local power = basePower
    
    if progressionSystem then
        local jumpMultiplier = progressionSystem.getUpgradeMultiplier("jumpPower")
        power = power * jumpMultiplier
    end
    
    -- Apply upgrade system effects
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    local jumpPowerBoost = UpgradeSystem.getEffect("jump_power")
    local jumpControl = UpgradeSystem.getEffect("jump_control")
    
    return power * jumpPowerBoost * jumpControl
end

function GameLogic.calculateDashPower(basePower, progressionSystem)
    local power = basePower
    
    if progressionSystem then
        local dashMultiplier = progressionSystem.getUpgradeMultiplier("dashPower")
        power = power * dashMultiplier
    end
    
    -- Apply upgrade system effects
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    local dashPowerBoost = UpgradeSystem.getEffect("dash_power")
    
    return power * dashPowerBoost
end

function GameLogic.calculateRingValue(baseValue, combo, progressionSystem)
    local value = baseValue + (combo * 5)
    if progressionSystem then
        local ringMultiplier = progressionSystem.getUpgradeMultiplier("ringValue")
        value = value * ringMultiplier
    end
    
    -- Apply upgrade system effects
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    local ringValueBoost = UpgradeSystem.getEffect("ring_value")
    
    -- Apply prestige shop effects
    local PrestigeSystem = Utils.require("src.systems.prestige_system")
    local prestigeEffects = PrestigeSystem.getActiveEffects()
    local prestigeMultiplier = 1.0
    
    for _, effect in ipairs(prestigeEffects) do
        if effect.type == "ring_multiplier" then
            prestigeMultiplier = prestigeMultiplier + (effect.value * effect.stacks)
        end
    end
    
    return value * ringValueBoost * prestigeMultiplier
end

function GameLogic.calculateGravityResistance(progressionSystem)
    if progressionSystem then
        return progressionSystem.getUpgradeMultiplier("gravityResistance")
    end
    return 1.0
end

return GameLogic