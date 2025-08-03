-- Button Component for Orbit Jump UI
-- Reusable button component with consistent styling and behavior

local Utils = require("src.utils.utils")
local Button = {}

-- Button state
Button.states = {
    NORMAL = "normal",
    HOVERED = "hovered",
    PRESSED = "pressed",
    DISABLED = "disabled"
}

-- Default button configuration
Button.defaults = {
    width = 100,
    height = 30,
    padding = 10,
    cornerRadius = 5,
    fontSize = 14,
    colors = {
        normal = {0.2, 0.2, 0.3, 0.8},
        hovered = {0.3, 0.3, 0.4, 0.9},
        pressed = {0.1, 0.1, 0.2, 1.0},
        disabled = {0.1, 0.1, 0.1, 0.5},
        text = {1, 1, 1, 1},
        textDisabled = {0.5, 0.5, 0.5, 1}
    }
}

-- Create a new button
function Button.new(config)
    config = config or {}
    
    local button = {
        x = config.x or 0,
        y = config.y or 0,
        width = config.width or Button.defaults.width,
        height = config.height or Button.defaults.height,
        text = config.text or "Button",
        state = Button.states.NORMAL,
        enabled = config.enabled ~= false,
        onClick = config.onClick or function() end,
        onHover = config.onHover or function() end,
        colors = config.colors or Button.defaults.colors,
        fontSize = config.fontSize or Button.defaults.fontSize,
        cornerRadius = config.cornerRadius or Button.defaults.cornerRadius,
        padding = config.padding or Button.defaults.padding,
        font = nil,
        isHovered = false,
        isPressed = false
    }
    
    -- Create font for this button
    button.font = love.graphics.newFont(button.fontSize)
    
    return button
end

-- Update button state based on mouse position
function Button.update(button, mouseX, mouseY, mousePressed)
    if not button.enabled then
        button.state = Button.states.DISABLED
        return
    end
    
    -- Check if mouse is over button
    local isOver = mouseX >= button.x and mouseX <= button.x + button.width and
                   mouseY >= button.y and mouseY <= button.y + button.height
    
    -- Update hover state
    if isOver ~= button.isHovered then
        button.isHovered = isOver
        if button.onHover then
            button.onHover(button, isOver)
        end
    end
    
    -- Update state based on mouse interaction
    if isOver then
        if mousePressed then
            button.state = Button.states.PRESSED
            button.isPressed = true
        else
            if button.isPressed then
                -- Button was released while hovering
                button.onClick(button)
            end
            button.state = Button.states.HOVERED
            button.isPressed = false
        end
    else
        button.state = Button.states.NORMAL
        button.isPressed = false
    end
end

-- Draw the button
function Button.draw(button)
    -- Get color based on state
    local color = button.colors[button.state] or button.colors.normal
    local textColor = button.enabled and button.colors.text or button.colors.textDisabled
    
    -- Draw background
    Utils.setColor(color)
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, button.cornerRadius)
    
    -- Draw border
    Utils.setColor({1, 1, 1, 0.3})
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", button.x, button.y, button.width, button.height, button.cornerRadius)
    
    -- Draw text
    Utils.setColor(textColor)
    love.graphics.setFont(button.font)
    local textWidth = button.font:getWidth(button.text)
    local textX = button.x + (button.width - textWidth) / 2
    local textY = button.y + (button.height - button.font:getHeight()) / 2
    love.graphics.print(button.text, textX, textY)
end

-- Check if button contains a point
function Button.contains(button, x, y)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Set button position
function Button.setPosition(button, x, y)
    button.x = x
    button.y = y
end

-- Set button size
function Button.setSize(button, width, height)
    button.width = width
    button.height = height
end

-- Set button text
function Button.setText(button, text)
    button.text = text
end

-- Enable/disable button
function Button.setEnabled(button, enabled)
    button.enabled = enabled
end

-- Set button colors
function Button.setColors(button, colors)
    for state, color in pairs(colors) do
        button.colors[state] = color
    end
end

return Button 