-- Game logic module - extracted from main.lua for testing
local Utils = Utils.Utils.require("src.utils.utils")
local GameLogic = {}

function GameLogic.normalizeVector(x, y)
    return Utils.normalize(x, y)
end

function GameLogic.calculateGravity(playerX, playerY, planetX, planetY, planetRadius)
    local distance, dx, dy = Utils.distance(playerX, playerY, planetX, planetY)
    
    if distance <= planetRadius then
        return 0, 0
    end
    
    local gravity = 15000 / (distance * distance)
    local nx, ny = GameLogic.normalizeVector(dx, dy)
    return nx * gravity, ny * gravity
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
    local nx, ny = GameLogic.normalizeVector(playerX - planetX, playerY - planetY)
    return nx * jumpPower + tangentVx, ny * jumpPower + tangentVy
end

-- Simple jump velocity calculation from angle and power
function GameLogic.calculateJumpVelocityFromAngle(angle, jumpPower)
    local jumpVx = math.cos(angle) * jumpPower
    local jumpVy = math.sin(angle) * jumpPower
    return jumpVx, jumpVy
end

function GameLogic.calculateTangentVelocity(angle, rotationSpeed, radius)
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
    margin = margin or 100
    return x < -margin or x > screenWidth + margin or 
           y < -margin or y > screenHeight + margin
end

function GameLogic.calculateComboBonus(combo, progressionSystem)
    local baseBonus = 10 + (combo * 5)
    if progressionSystem then
        local comboMultiplier = progressionSystem.getUpgradeMultiplier("comboMultiplier")
        baseBonus = baseBonus * comboMultiplier
    end
    
    -- Apply upgrade system effects
    local UpgradeSystem = Utils.Utils.require("src.systems.upgrade_system")
    local comboMultiplierBoost = UpgradeSystem.getEffect("combo_multiplier")
    
    return baseBonus * comboMultiplierBoost
end

function GameLogic.calculateSpeedBoost(combo, progressionSystem)
    local baseBoost = 1.0 + (combo * 0.1)
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
    local UpgradeSystem = Utils.Utils.require("src.systems.upgrade_system")
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
    local UpgradeSystem = Utils.Utils.require("src.systems.upgrade_system")
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
    local UpgradeSystem = Utils.Utils.require("src.systems.upgrade_system")
    local ringValueBoost = UpgradeSystem.getEffect("ring_value")
    
    return value * ringValueBoost
end

function GameLogic.calculateGravityResistance(progressionSystem)
    if progressionSystem then
        return progressionSystem.getUpgradeMultiplier("gravityResistance")
    end
    return 1.0
end

return GameLogic