-- Camera system for Orbit Jump
-- Smooth follow camera with zoom and shake support

local Camera = {}
Camera.__index = Camera

function Camera:new()
    local self = setmetatable({}, Camera)
    self.x = 0
    self.y = 0
    self.scale = 1
    self.rotation = 0
    
    -- Smooth follow parameters
    self.smoothSpeed = 8
    self.lookAheadFactor = 0.15
    
    -- Shake parameters
    self.shakeIntensity = 0
    self.shakeDuration = 0
    self.enableShake = true
    
    -- Bounds (optional)
    self.bounds = nil
    
    -- Screen dimensions cache
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    return self
end

function Camera:follow(target, dt)
    if not target then return end
    
    -- Calculate target position with look-ahead based on velocity
    local targetX = target.x
    local targetY = target.y
    
    -- Add look-ahead if target has velocity
    if target.vx and target.vy then
        targetX = targetX + target.vx * self.lookAheadFactor
        targetY = targetY + target.vy * self.lookAheadFactor
    end
    
    -- Center target on screen
    local desiredX = targetX - self.screenWidth / (2 * self.scale)
    local desiredY = targetY - self.screenHeight / (2 * self.scale)
    
    -- Smooth interpolation
    self.x = self.x + (desiredX - self.x) * self.smoothSpeed * dt
    self.y = self.y + (desiredY - self.y) * self.smoothSpeed * dt
    
    -- Apply bounds if set
    if self.bounds then
        self.x = math.max(self.bounds.minX, math.min(self.bounds.maxX - self.screenWidth / self.scale, self.x))
        self.y = math.max(self.bounds.minY, math.min(self.bounds.maxY - self.screenHeight / self.scale, self.y))
    end
    
    -- Update shake
    if self.shakeDuration > 0 then
        self.shakeDuration = self.shakeDuration - dt
    else
        self.shakeIntensity = 0
    end
end

function Camera:apply()
    love.graphics.push()
    
    -- Apply shake
    local shakeX = 0
    local shakeY = 0
    if self.shakeIntensity > 0 then
        shakeX = (math.random() - 0.5) * self.shakeIntensity
        shakeY = (math.random() - 0.5) * self.shakeIntensity
    end
    
    -- Center and apply transformations
    love.graphics.translate(self.screenWidth / 2, self.screenHeight / 2)
    love.graphics.scale(self.scale, self.scale)
    love.graphics.rotate(self.rotation)
    love.graphics.translate(-self.screenWidth / 2, -self.screenHeight / 2)
    
    -- Apply camera position with shake
    love.graphics.translate(-self.x + shakeX, -self.y + shakeY)
end

function Camera:clear()
    love.graphics.pop()
end

function Camera:shake(intensity, duration)
    if self.enableShake then
        self.shakeIntensity = intensity
        self.shakeDuration = duration
    end
end

function Camera:setScale(scale)
    self.scale = math.max(0.1, math.min(5, scale))
end

function Camera:zoomIn(factor)
    self:setScale(self.scale * (1 + factor))
end

function Camera:zoomOut(factor)
    self:setScale(self.scale * (1 - factor))
end

function Camera:worldToScreen(worldX, worldY)
    -- Convert world coordinates to screen coordinates
    local screenX = (worldX - self.x) * self.scale
    local screenY = (worldY - self.y) * self.scale
    return screenX, screenY
end

function Camera:screenToWorld(screenX, screenY)
    -- Convert screen coordinates to world coordinates
    local worldX = screenX / self.scale + self.x
    local worldY = screenY / self.scale + self.y
    return worldX, worldY
end

function Camera:setBounds(minX, minY, maxX, maxY)
    self.bounds = {
        minX = minX,
        minY = minY,
        maxX = maxX,
        maxY = maxY
    }
end

function Camera:removeBounds()
    self.bounds = nil
end

function Camera:resize(width, height)
    self.screenWidth = width
    self.screenHeight = height
end

function Camera:getVisibleArea()
    -- Returns the visible world area
    local x1 = self.x
    local y1 = self.y
    local x2 = self.x + self.screenWidth / self.scale
    local y2 = self.y + self.screenHeight / self.scale
    return x1, y1, x2, y2
end

return Camera