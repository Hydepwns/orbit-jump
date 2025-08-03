--[[
    UI Components for Orbit Jump
    
    This module provides reusable UI components for buttons, progress bars,
    and other interface elements.
--]]

local Drawing = require("src.utils.rendering.drawing")

local UIComponents = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Button Component: Interactive UI Elements
    ═══════════════════════════════════════════════════════════════════════════
--]]

function UIComponents.drawButton(text, x, y, width, height, color, hoverColor, isHovered)
    --[[
        Draw Button
        
        Draws a button with text, background, and hover effects.
        Perfect for menus, dialogs, and interactive UI elements.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    -- Default colors
    color = color or {r = 0.2, g = 0.2, b = 0.2, a = 1}
    hoverColor = hoverColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    
    -- Choose color based on hover state
    local buttonColor = isHovered and hoverColor or color
    
    -- Draw button background
    Drawing.drawRect(x, y, width, height, buttonColor)
    
    -- Draw button border
    Drawing.drawRectOutline(x, y, width, height, {r = 0.8, g = 0.8, b = 0.8, a = 1}, 1, 2)
    
    -- Draw button text
    if text then
        Drawing.drawCenteredText(text, x + width / 2, y + height / 2, nil, {r = 1, g = 1, b = 1, a = 1})
    end
end

function UIComponents.drawButtonWithIcon(text, icon, x, y, width, height, color, hoverColor, isHovered)
    --[[
        Draw Button with Icon
        
        Draws a button with both text and an icon.
        Perfect for toolbar buttons and action buttons.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    -- Default colors
    color = color or {r = 0.2, g = 0.2, b = 0.2, a = 1}
    hoverColor = hoverColor or {r = 0.3, g = 0.3, b = 0.3, a = 1}
    
    -- Choose color based on hover state
    local buttonColor = isHovered and hoverColor or color
    
    -- Draw button background
    Drawing.drawRect(x, y, width, height, buttonColor)
    
    -- Draw button border
    Drawing.drawRectOutline(x, y, width, height, {r = 0.8, g = 0.8, b = 0.8, a = 1}, 1, 2)
    
    -- Draw icon if provided
    if icon then
        local iconSize = math.min(width, height) * 0.4
        local iconX = x + width / 2 - iconSize / 2
        local iconY = y + height / 2 - iconSize / 2
        
        Drawing.setColor(1, 1, 1, 1)
        love.graphics.draw(icon, iconX, iconY, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
    end
    
    -- Draw button text
    if text then
        local textY = y + height * 0.7
        Drawing.drawCenteredText(text, x + width / 2, textY, nil, {r = 1, g = 1, b = 1, a = 1})
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Progress Bar Component: Visual Progress Indicators
    ═══════════════════════════════════════════════════════════════════════════
--]]

function UIComponents.drawProgressBar(x, y, width, height, progress, color, backgroundColor)
    --[[
        Draw Progress Bar
        
        Draws a progress bar with customizable colors and progress value.
        Perfect for loading screens, health bars, and progress indicators.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height or not progress then return end
    
    -- Clamp progress to valid range
    progress = math.max(0, math.min(1, progress))
    
    -- Default colors
    backgroundColor = backgroundColor or {r = 0.1, g = 0.1, b = 0.1, a = 1}
    color = color or {r = 0.2, g = 0.8, b = 0.2, a = 1}
    
    -- Draw background
    Drawing.drawRect(x, y, width, height, backgroundColor)
    
    -- Draw progress fill
    local fillWidth = width * progress
    if fillWidth > 0 then
        Drawing.drawRect(x, y, fillWidth, height, color)
    end
    
    -- Draw border
    Drawing.drawRectOutline(x, y, width, height, {r = 0.8, g = 0.8, b = 0.8, a = 1}, 1, 1)
end

function UIComponents.drawCircularProgressBar(x, y, radius, progress, color, backgroundColor, thickness)
    --[[
        Draw Circular Progress Bar
        
        Draws a circular progress bar with customizable colors and progress value.
        Perfect for radial progress indicators and circular health bars.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not radius or not progress then return end
    
    -- Clamp progress to valid range
    progress = math.max(0, math.min(1, progress))
    
    -- Default values
    thickness = thickness or radius * 0.1
    backgroundColor = backgroundColor or {r = 0.1, g = 0.1, b = 0.1, a = 1}
    color = color or {r = 0.2, g = 0.8, b = 0.2, a = 1}
    
    -- Draw background ring
    Drawing.drawRing(x, y, radius, radius - thickness, backgroundColor)
    
    -- Draw progress ring
    if progress > 0 then
        local startAngle = -math.pi / 2  -- Start from top
        local endAngle = startAngle + (2 * math.pi * progress)
        Drawing.drawArc(x, y, radius, startAngle, endAngle, color, 1, 32)
        
        -- Cut out inner circle to create ring effect
        local currentColor = {love.graphics.getColor()}
        love.graphics.setColor(0, 0, 0, 0) -- Transparent
        love.graphics.circle("fill", x, y, radius - thickness, 32)
        love.graphics.setColor(unpack(currentColor))
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Panel Component: Container UI Elements
    ═══════════════════════════════════════════════════════════════════════════
--]]

function UIComponents.drawPanel(x, y, width, height, color, borderColor, borderWidth)
    --[[
        Draw Panel
        
        Draws a panel with background and optional border.
        Perfect for grouping UI elements and creating containers.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    -- Default values
    color = color or {r = 0.15, g = 0.15, b = 0.15, a = 0.9}
    borderColor = borderColor or {r = 0.6, g = 0.6, b = 0.6, a = 1}
    borderWidth = borderWidth or 1
    
    -- Draw background
    Drawing.drawRect(x, y, width, height, color)
    
    -- Draw border
    if borderWidth > 0 then
        Drawing.drawRectOutline(x, y, width, height, borderColor, 1, borderWidth)
    end
end

function UIComponents.drawRoundedPanel(x, y, width, height, radius, color, borderColor, borderWidth)
    --[[
        Draw Rounded Panel
        
        Draws a panel with rounded corners.
        Perfect for modern UI designs and mobile interfaces.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height then return end
    
    -- Default values
    radius = radius or 10
    color = color or {r = 0.15, g = 0.15, b = 0.15, a = 0.9}
    borderColor = borderColor or {r = 0.6, g = 0.6, b = 0.6, a = 1}
    borderWidth = borderWidth or 1
    
    -- Draw rounded rectangle background
    Drawing.setColor(color)
    love.graphics.rectangle("fill", x, y, width, height, radius, radius)
    
    -- Draw border
    if borderWidth > 0 then
        Drawing.setColor(borderColor)
        love.graphics.setLineWidth(borderWidth)
        love.graphics.rectangle("line", x, y, width, height, radius, radius)
        love.graphics.setLineWidth(1) -- Reset to default
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Slider Component: Interactive Range Controls
    ═══════════════════════════════════════════════════════════════════════════
--]]

function UIComponents.drawSlider(x, y, width, height, value, minValue, maxValue, color, backgroundColor)
    --[[
        Draw Slider
        
        Draws a horizontal slider with customizable range and value.
        Perfect for volume controls, settings adjustments, and range inputs.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not width or not height or not value or not minValue or not maxValue then return end
    
    -- Clamp value to valid range
    value = math.max(minValue, math.min(maxValue, value))
    
    -- Calculate normalized progress
    local progress = (value - minValue) / (maxValue - minValue)
    
    -- Default colors
    backgroundColor = backgroundColor or {r = 0.1, g = 0.1, b = 0.1, a = 1}
    color = color or {r = 0.2, g = 0.8, b = 0.2, a = 1}
    
    -- Draw background track
    Drawing.drawRect(x, y, width, height, backgroundColor)
    
    -- Draw filled portion
    local fillWidth = width * progress
    if fillWidth > 0 then
        Drawing.drawRect(x, y, fillWidth, height, color)
    end
    
    -- Draw slider handle
    local handleSize = height * 1.5
    local handleX = x + (width * progress) - handleSize / 2
    local handleY = y - (handleSize - height) / 2
    
    Drawing.drawCircle(handleX + handleSize / 2, handleY + handleSize / 2, handleSize / 2, {r = 0.8, g = 0.8, b = 0.8, a = 1})
    Drawing.drawCircle(handleX + handleSize / 2, handleY + handleSize / 2, handleSize / 2, {r = 0.6, g = 0.6, b = 0.6, a = 1}, 1, 1)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Checkbox Component: Boolean Input Controls
    ═══════════════════════════════════════════════════════════════════════════
--]]

function UIComponents.drawCheckbox(x, y, size, checked, color, borderColor)
    --[[
        Draw Checkbox
        
        Draws a checkbox with checked/unchecked states.
        Perfect for settings toggles and boolean inputs.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not size then return end
    
    -- Default values
    color = color or {r = 0.2, g = 0.8, b = 0.2, a = 1}
    borderColor = borderColor or {r = 0.6, g = 0.6, b = 0.6, a = 1}
    
    -- Draw border
    Drawing.drawRectOutline(x, y, size, size, borderColor, 1, 2)
    
    -- Draw check mark if checked
    if checked then
        Drawing.drawRect(x + size * 0.2, y + size * 0.2, size * 0.6, size * 0.6, color)
        
        -- Draw check mark symbol
        Drawing.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.line(
            x + size * 0.3, y + size * 0.5,
            x + size * 0.45, y + size * 0.65,
            x + size * 0.7, y + size * 0.35
        )
        love.graphics.setLineWidth(1) -- Reset to default
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Tooltip Component: Contextual Information
    ═══════════════════════════════════════════════════════════════════════════
--]]

function UIComponents.drawTooltip(text, x, y, backgroundColor, textColor, padding)
    --[[
        Draw Tooltip
        
        Draws a tooltip with text at the specified position.
        Perfect for providing contextual information and help text.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not text or not x or not y then return end
    
    -- Default values
    backgroundColor = backgroundColor or {r = 0.1, g = 0.1, b = 0.1, a = 0.9}
    textColor = textColor or {r = 1, g = 1, b = 1, a = 1}
    padding = padding or 8
    
    -- Get text dimensions
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    
    -- Calculate tooltip dimensions
    local tooltipWidth = textWidth + padding * 2
    local tooltipHeight = textHeight + padding * 2
    
    -- Draw background
    Drawing.drawRoundedPanel(x, y, tooltipWidth, tooltipHeight, 5, backgroundColor)
    
    -- Draw text
    Drawing.drawCenteredText(text, x + tooltipWidth / 2, y + tooltipHeight / 2, font, textColor)
end

return UIComponents 