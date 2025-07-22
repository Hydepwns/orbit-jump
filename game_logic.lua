-- Game logic module - extracted from main.lua for testing
local GameLogic = {}

function GameLogic.calculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx*dx + dy*dy), dx, dy
end

function GameLogic.normalizeVector(x, y)
    local length = math.sqrt(x*x + y*y)
    if length == 0 then
        return 0, 0
    end
    return x / length, y / length
end

function GameLogic.calculateGravity(playerX, playerY, planetX, planetY, planetRadius)
    local distance, dx, dy = GameLogic.calculateDistance(playerX, playerY, planetX, planetY)
    
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
    local distance = GameLogic.calculateDistance(playerX, playerY, ringX, ringY)
    return distance < ringRadius and distance > ringInnerRadius - playerRadius
end

function GameLogic.checkPlanetCollision(playerX, playerY, playerRadius, planetX, planetY, planetRadius)
    local distance = GameLogic.calculateDistance(playerX, playerY, planetX, planetY)
    return distance <= planetRadius + playerRadius
end

function GameLogic.calculateJumpVelocity(playerX, playerY, planetX, planetY, jumpPower, tangentVx, tangentVy)
    local nx, ny = GameLogic.normalizeVector(playerX - planetX, playerY - planetY)
    return nx * jumpPower + tangentVx, ny * jumpPower + tangentVy
end

function GameLogic.calculateTangentVelocity(angle, rotationSpeed, radius)
    local tangentX = -math.sin(angle) * rotationSpeed * radius
    local tangentY = math.cos(angle) * rotationSpeed * radius
    return tangentX, tangentY
end

function GameLogic.applySpeedBoost(vx, vy, boost)
    local currentSpeed = math.sqrt(vx*vx + vy*vy)
    if currentSpeed == 0 then
        return vx, vy
    end
    return (vx / currentSpeed) * currentSpeed * boost, (vy / currentSpeed) * currentSpeed * boost
end

function GameLogic.isOutOfBounds(x, y, screenWidth, screenHeight, margin)
    margin = margin or 100
    return x < -margin or x > screenWidth + margin or 
           y < -margin or y > screenHeight + margin
end

function GameLogic.calculateComboBonus(combo)
    return 10 + (combo * 5)
end

function GameLogic.calculateSpeedBoost(combo)
    return 1.0 + (combo * 0.1)
end

return GameLogic