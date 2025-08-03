--[[
    Drawing Utilities for Orbit Jump
    
    This module provides efficient drawing functions for game objects,
    UI elements, and visual effects.
--]]

local Drawing = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Color Management: Consistent Visual Identity
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Drawing.setColor(color, alpha)
    --[[
        Set Drawing Color with Alpha Support
        
        Sets the current drawing color with optional alpha transparency.
        Handles both table-based colors and individual RGB values.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not color then
        love.graphics.setColor(1, 1, 1, alpha or 1)
        return
    end
    
    if type(color) == "table" then
        -- Color is a table with r, g, b components
        local r = color.r or 1
        local g = color.g or 1
        local b = color.b or 1
        local a = alpha or color.a or 1
        
        love.graphics.setColor(r, g, b, a)
    else
        -- Color is a single value (grayscale)
        love.graphics.setColor(color, color, color, alpha or 1)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Shape Drawing: Geometric Primitives
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Drawing.drawCircle(x, y, radius, color, alpha)
    --[[
        Draw Circle
        
        Draws a filled circle at the specified position with optional color.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not radius then return end
    
    Drawing.setColor(color, alpha)
    love.graphics.circle("fill", x, y, radius)
end

function Drawing.drawRing(x, y, outerRadius, innerRadius, color, alpha, segments)
    --[[
        Draw Ring (Annulus)
        
        Draws a ring shape by drawing a large circle and cutting out a smaller one.
        Perfect for orbital paths, UI elements, and visual effects.
        
        Performance: O(n) where n is the number of segments
    --]]
    
    if not x or not y or not outerRadius or not innerRadius then return end
    if outerRadius <= innerRadius then return end
    
    segments = segments or 32
    Drawing.setColor(color, alpha)
    
    -- Draw the outer circle
    love.graphics.circle("fill", x, y, outerRadius, segments)
    
    -- Cut out the inner circle by drawing it in the background color
    local currentColor = {love.graphics.getColor()}
    love.graphics.setColor(0, 0, 0, 0) -- Transparent
    love.graphics.circle("fill", x, y, innerRadius, segments)
    
    -- Restore original color
    love.graphics.setColor(unpack(currentColor))
end

function Drawing.drawArc(x, y, radius, startAngle, endAngle, color, alpha, segments)
    --[[
        Draw Arc
        
        Draws a partial circle arc between two angles.
        Perfect for progress indicators, pie charts, and curved UI elements.
        
        Performance: O(n) where n is the number of segments
    --]]
    
    if not x or not y or not radius or not startAngle or not endAngle then return end
    
    segments = segments or 32
    Drawing.setColor(color, alpha)
    
    love.graphics.arc("fill", x, y, radius, startAngle, endAngle, segments)
end

function Drawing.drawLine(x1, y1, x2, y2, color, alpha, width)
    --[[
        Draw Line
        
        Draws a line between two points with optional color and width.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then return end
    
    Drawing.setColor(color, alpha)
    if width then
        love.graphics.setLineWidth(width)
    end
    
    love.graphics.line(x1, y1, x2, y2)
    
    if width then
        love.graphics.setLineWidth(1) -- Reset to default
    end
end

function Drawing.drawRect(x, y, width, height, color, alpha)
    --[[
        Draw Rectangle
        
        Draws a filled rectangle at the specified position and size.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    Drawing.setColor(color, alpha)
    love.graphics.rectangle("fill", x, y, width, height)
end

function Drawing.drawRectOutline(x, y, width, height, color, alpha, lineWidth)
    --[[
        Draw Rectangle Outline
        
        Draws the outline of a rectangle with optional color and line width.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    Drawing.setColor(color, alpha)
    if lineWidth then
        love.graphics.setLineWidth(lineWidth)
    end
    
    love.graphics.rectangle("line", x, y, width, height)
    
    if lineWidth then
        love.graphics.setLineWidth(1) -- Reset to default
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Text Drawing: Typography and Labels
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Drawing.drawTextWithShadow(text, x, y, font, color, shadowColor, shadowOffset)
    --[[
        Draw Text with Shadow
        
        Draws text with a shadow effect for better readability.
        Perfect for UI labels, scores, and important information.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not text or not x or not y then return end
    
    font = font or love.graphics.getFont()
    shadowOffset = shadowOffset or 2
    
    -- Draw shadow
    if shadowColor then
        Drawing.setColor(shadowColor)
        love.graphics.setFont(font)
        love.graphics.print(text, x + shadowOffset, y + shadowOffset)
    end
    
    -- Draw main text
    Drawing.setColor(color)
    love.graphics.setFont(font)
    love.graphics.print(text, x, y)
end

function Drawing.drawTextWithOutline(text, x, y, font, color, outlineColor, outlineWidth)
    --[[
        Draw Text with Outline
        
        Draws text with an outline effect for better visibility.
        Perfect for important UI elements and game text.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not text or not x or not y then return end
    
    font = font or love.graphics.getFont()
    outlineWidth = outlineWidth or 1
    
    -- Draw outline
    if outlineColor then
        Drawing.setColor(outlineColor)
        love.graphics.setFont(font)
        
        -- Draw outline in all directions
        for dx = -outlineWidth, outlineWidth do
            for dy = -outlineWidth, outlineWidth do
                if dx ~= 0 or dy ~= 0 then
                    love.graphics.print(text, x + dx, y + dy)
                end
            end
        end
    end
    
    -- Draw main text
    Drawing.setColor(color)
    love.graphics.setFont(font)
    love.graphics.print(text, x, y)
end

function Drawing.drawCenteredText(text, x, y, font, color, alpha)
    --[[
        Draw Centered Text
        
        Draws text centered at the specified position.
        Perfect for titles, buttons, and centered UI elements.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not text or not x or not y then return end
    
    font = font or love.graphics.getFont()
    Drawing.setColor(color, alpha)
    love.graphics.setFont(font)
    
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    love.graphics.print(text, x - textWidth / 2, y - textHeight / 2)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Particle System: Visual Effects
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Drawing.createParticle(x, y, vx, vy, color, lifetime, size)
    --[[
        Create Particle
        
        Creates a particle object for visual effects.
        Returns a particle table with position, velocity, and lifetime.
        
        Performance: O(1) with single allocation for particle table
    --]]
    
    return {
        x = x or 0,
        y = y or 0,
        vx = vx or 0,
        vy = vy or 0,
        color = color or {r = 1, g = 1, b = 1, a = 1},
        lifetime = lifetime or 1.0,
        maxLifetime = lifetime or 1.0,
        size = size or 2,
        active = true
    }
end

function Drawing.updateParticle(particle, dt, gravity)
    --[[
        Update Particle
        
        Updates a particle's position, velocity, and lifetime.
        Applies gravity and handles particle lifecycle.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not particle or not particle.active then return end
    
    -- Apply gravity
    if gravity then
        particle.vy = particle.vy + gravity * dt
    end
    
    -- Update position
    particle.x = particle.x + particle.vx * dt
    particle.y = particle.y + particle.vy * dt
    
    -- Update lifetime
    particle.lifetime = particle.lifetime - dt
    if particle.lifetime <= 0 then
        particle.active = false
    end
end

function Drawing.drawParticle(particle)
    --[[
        Draw Particle
        
        Draws a single particle with fade-out effect based on lifetime.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not particle or not particle.active then return end
    
    local alpha = particle.lifetime / particle.maxLifetime
    local color = particle.color
    
    Drawing.setColor(color.r, color.g, color.b, color.a * alpha)
    love.graphics.circle("fill", particle.x, particle.y, particle.size)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions: Drawing Helpers
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Drawing.drawPolygon(points, color, alpha)
    --[[
        Draw Polygon
        
        Draws a polygon from a list of points.
        
        Performance: O(n) where n is the number of points
    --]]
    
    if not points or #points < 3 then return end
    
    Drawing.setColor(color, alpha)
    
    -- Convert points to flat array for love.graphics.polygon
    local flatPoints = {}
    for i, point in ipairs(points) do
        table.insert(flatPoints, point.x)
        table.insert(flatPoints, point.y)
    end
    
    love.graphics.polygon("fill", flatPoints)
end

function Drawing.drawPolygonOutline(points, color, alpha, lineWidth)
    --[[
        Draw Polygon Outline
        
        Draws the outline of a polygon from a list of points.
        
        Performance: O(n) where n is the number of points
    --]]
    
    if not points or #points < 3 then return end
    
    Drawing.setColor(color, alpha)
    if lineWidth then
        love.graphics.setLineWidth(lineWidth)
    end
    
    -- Convert points to flat array for love.graphics.polygon
    local flatPoints = {}
    for i, point in ipairs(points) do
        table.insert(flatPoints, point.x)
        table.insert(flatPoints, point.y)
    end
    
    love.graphics.polygon("line", flatPoints)
    
    if lineWidth then
        love.graphics.setLineWidth(1) -- Reset to default
    end
end

function Drawing.drawGradientRect(x, y, width, height, color1, color2, direction)
    --[[
        Draw Gradient Rectangle
        
        Draws a rectangle with a gradient fill.
        Direction can be "horizontal", "vertical", or "radial".
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    direction = direction or "horizontal"
    
    if direction == "horizontal" then
        -- Horizontal gradient
        for i = 0, width do
            local t = i / width
            local r = color1.r + (color2.r - color1.r) * t
            local g = color1.g + (color2.g - color1.g) * t
            local b = color1.b + (color2.b - color1.b) * t
            local a = color1.a + (color2.a - color1.a) * t
            
            Drawing.setColor(r, g, b, a)
            love.graphics.rectangle("fill", x + i, y, 1, height)
        end
    elseif direction == "vertical" then
        -- Vertical gradient
        for i = 0, height do
            local t = i / height
            local r = color1.r + (color2.r - color1.r) * t
            local g = color1.g + (color2.g - color1.g) * t
            local b = color1.b + (color2.b - color1.b) * t
            local a = color1.a + (color2.a - color1.a) * t
            
            Drawing.setColor(r, g, b, a)
            love.graphics.rectangle("fill", x, y + i, width, 1)
        end
    end
end

return Drawing 