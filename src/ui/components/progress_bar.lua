-- Progress Bar Component for Orbit Jump UI
-- Reusable progress bar with customizable styling and animations

local Utils = require("src.utils.utils")
local ProgressBar = {}

-- Progress bar types
ProgressBar.types = {
    XP = "xp",
    HEALTH = "health",
    COOLDOWN = "cooldown",
    GENERIC = "generic"
}

-- Default progress bar configuration
ProgressBar.defaults = {
    width = 200,
    height = 8,
    cornerRadius = 2,
    showText = true,
    showPercentage = true,
    animate = true,
    pulseSpeed = 2.0,
    colors = {
        background = {0.2, 0.2, 0.3, 0.8},
        fill = {0.3, 0.7, 1.0, 0.9},
        border = {0.5, 0.8, 1.0, 0.9},
        text = {1, 1, 1, 1}
    }
}

-- Create a new progress bar
function ProgressBar.new(config)
    config = config or {}
    
    local progressBar = {
        x = config.x or 0,
        y = config.y or 0,
        width = config.width or ProgressBar.defaults.width,
        height = config.height or ProgressBar.defaults.height,
        progress = config.progress or 0, -- 0.0 to 1.0
        maxValue = config.maxValue or 100,
        currentValue = config.currentValue or 0,
        type = config.type or ProgressBar.types.GENERIC,
        showText = config.showText ~= false,
        showPercentage = config.showPercentage ~= false,
        animate = config.animate ~= false,
        pulseSpeed = config.pulseSpeed or ProgressBar.defaults.pulseSpeed,
        colors = config.colors or ProgressBar.defaults.colors,
        cornerRadius = config.cornerRadius or ProgressBar.defaults.cornerRadius,
        label = config.label or "",
        font = nil,
        animationTime = 0,
        smoothProgress = 0 -- For smooth animations
    }
    
    -- Create font for text
    progressBar.font = love.graphics.newFont(12)
    
    return progressBar
end

-- Update progress bar (call this every frame for animations)
function ProgressBar.update(progressBar, dt)
    if progressBar.animate then
        progressBar.animationTime = progressBar.animationTime + dt
        
        -- Smooth progress animation
        local targetProgress = progressBar.progress
        local diff = targetProgress - progressBar.smoothProgress
        progressBar.smoothProgress = progressBar.smoothProgress + diff * dt * 5 -- Smooth interpolation
    else
        progressBar.smoothProgress = progressBar.progress
    end
end

-- Set progress (0.0 to 1.0)
function ProgressBar.setProgress(progressBar, progress)
    progressBar.progress = math.max(0, math.min(1, progress))
end

-- Set values (current and max)
function ProgressBar.setValues(progressBar, current, max)
    progressBar.currentValue = current
    progressBar.maxValue = max
    progressBar.progress = max > 0 and current / max or 0
end

-- Set position
function ProgressBar.setPosition(progressBar, x, y)
    progressBar.x = x
    progressBar.y = y
end

-- Set size
function ProgressBar.setSize(progressBar, width, height)
    progressBar.width = width
    progressBar.height = height
end

-- Set label
function ProgressBar.setLabel(progressBar, label)
    progressBar.label = label
end

-- Draw the progress bar
function ProgressBar.draw(progressBar)
    local progress = progressBar.animate and progressBar.smoothProgress or progressBar.progress
    
    -- Calculate fill width
    local fillWidth = progressBar.width * progress
    
    -- Draw background
    Utils.setColor(progressBar.colors.background)
    love.graphics.rectangle("fill", progressBar.x, progressBar.y, progressBar.width, progressBar.height, progressBar.cornerRadius)
    
    -- Draw fill with pulse effect if animating
    if progressBar.animate and progress > 0 then
        local pulse = math.sin(progressBar.animationTime * progressBar.pulseSpeed) * 0.1 + 1.0
        local fillColor = {
            progressBar.colors.fill[1] * pulse,
            progressBar.colors.fill[2] * pulse,
            progressBar.colors.fill[3] * pulse,
            progressBar.colors.fill[4]
        }
        Utils.setColor(fillColor)
    else
        Utils.setColor(progressBar.colors.fill)
    end
    
    love.graphics.rectangle("fill", progressBar.x, progressBar.y, fillWidth, progressBar.height, progressBar.cornerRadius)
    
    -- Draw border
    Utils.setColor(progressBar.colors.border)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", progressBar.x, progressBar.y, progressBar.width, progressBar.height, progressBar.cornerRadius)
    
    -- Draw text if enabled
    if progressBar.showText then
        Utils.setColor(progressBar.colors.text)
        love.graphics.setFont(progressBar.font)
        
        local text = ""
        if progressBar.label and progressBar.label ~= "" then
            text = progressBar.label
        end
        
        if progressBar.showPercentage then
            local percentage = math.floor(progress * 100)
            if text ~= "" then
                text = text .. ": " .. percentage .. "%"
            else
                text = percentage .. "%"
            end
        end
        
        if progressBar.currentValue and progressBar.maxValue then
            local valueText = string.format("%.0f / %.0f", progressBar.currentValue, progressBar.maxValue)
            if text ~= "" then
                text = text .. " (" .. valueText .. ")"
            else
                text = valueText
            end
        end
        
        if text ~= "" then
            local textWidth = progressBar.font:getWidth(text)
            local textX = progressBar.x + (progressBar.width - textWidth) / 2
            local textY = progressBar.y - progressBar.font:getHeight() - 2
            love.graphics.print(text, textX, textY)
        end
    end
end

-- Create an XP progress bar with default styling
function ProgressBar.createXPBar(x, y, width, height)
    return ProgressBar.new({
        x = x,
        y = y,
        width = width,
        height = height,
        type = ProgressBar.types.XP,
        colors = {
            background = {0, 0, 0, 0.6},
            fill = {0.3, 0.7, 1, 0.9},
            border = {0.5, 0.8, 1, 0.9},
            text = {1, 1, 1, 1}
        },
        animate = true,
        showText = true,
        showPercentage = true
    })
end

-- Create a health bar with default styling
function ProgressBar.createHealthBar(x, y, width, height)
    return ProgressBar.new({
        x = x,
        y = y,
        width = width,
        height = height,
        type = ProgressBar.types.HEALTH,
        colors = {
            background = {0.2, 0.1, 0.1, 0.8},
            fill = {1, 0.3, 0.3, 0.9},
            border = {1, 0.5, 0.5, 0.9},
            text = {1, 1, 1, 1}
        },
        animate = true,
        showText = true,
        showPercentage = false
    })
end

-- Create a cooldown bar with default styling
function ProgressBar.createCooldownBar(x, y, width, height)
    return ProgressBar.new({
        x = x,
        y = y,
        width = width,
        height = height,
        type = ProgressBar.types.COOLDOWN,
        colors = {
            background = {0.2, 0.2, 0.2, 0.8},
            fill = {0.8, 0.8, 0.2, 0.9},
            border = {1, 1, 0.5, 0.9},
            text = {1, 1, 1, 1}
        },
        animate = false,
        showText = false
    })
end

return ProgressBar 