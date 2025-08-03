-- Camera system for Orbit Jump
-- Smooth follow camera with zoom and shake support
local Utils = require("src.utils.utils")
local Camera = {}
Camera.__index = Camera
function Camera:new()
    local success, result = pcall(function()
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
        -- Zoom parameters
        self.minZoom = 0.3
        self.maxZoom = 3.0
        self.zoomSpeed = 0.1
        self.targetScale = 1
        self.zoomSmoothSpeed = 8
        -- Bounds (optional)
        self.bounds = nil
        -- Screen dimensions cache - defer until needed
        self.screenWidth = nil
        self.screenHeight = nil
        self._dimensionsInitialized = false
        return self
    end)
    if not success then
        print("Error creating camera: " .. tostring(result))
        return nil
    end
    return result
end
-- Initialize screen dimensions when needed
function Camera:initDimensions()
    if not self._dimensionsInitialized then
        local screenWidth, screenHeight
        if love and love.graphics then
            screenWidth = love.graphics.getWidth()
            screenHeight = love.graphics.getHeight()
        else
            -- Fallback values if LÖVE graphics not available
            screenWidth = 800
            screenHeight = 600
        end
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self._dimensionsInitialized = true
    end
end
function Camera:follow(target, dt)
    if not target then return end
    -- Ensure dimensions are initialized
    self:initDimensions()
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
        -- Use the effective scale for bounds calculation
        local effectiveScale = self.scale
        local maxX = self.bounds.maxX - self.screenWidth / effectiveScale
        local maxY = self.bounds.maxY - self.screenHeight / effectiveScale
        -- Ensure we don't exceed bounds
        self.x = math.max(self.bounds.minX, math.min(maxX, self.x))
        self.y = math.max(self.bounds.minY, math.min(maxY, self.y))
    end
    -- Update smooth zoom
    if math.abs(self.targetScale - self.scale) > 0.01 then
        self.scale = self.scale + (self.targetScale - self.scale) * self.zoomSmoothSpeed * dt
    else
        self.scale = self.targetScale
    end
    -- Update shake
    if self.shakeDuration > 0 then
        self.shakeDuration = self.shakeDuration - dt
        if self.shakeDuration <= 0 then
            self.shakeIntensity = 0
            self.shakeDuration = 0
        end
    end
end
function Camera:apply()
    love.graphics.push()
    -- Ensure dimensions are initialized
    self:initDimensions()
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
    self.targetScale = math.max(self.minZoom, math.min(self.maxZoom, scale))
    -- Also set current scale immediately for immediate effect
    self.scale = self.targetScale
end
function Camera:zoom(factor)
    -- Positive factor zooms in, negative zooms out
    local newScale = self.scale * (1 + factor)
    self:setScale(newScale)
end
function Camera:zoomIn(factor)
    factor = factor or self.zoomSpeed
    self:zoom(factor)
end
function Camera:zoomOut(factor)
    factor = factor or self.zoomSpeed
    self:zoom(-factor)
end
function Camera:handleWheelMoved(x, y)
    -- y > 0 means scroll up (zoom in), y < 0 means scroll down (zoom out)
    local zoomFactor = y * self.zoomSpeed
    self:zoom(zoomFactor)
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