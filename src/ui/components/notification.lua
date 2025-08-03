-- Notification Component for Orbit Jump UI
-- Reusable notification system for displaying messages and events

local Utils = require("src.utils.utils")
local Notification = {}

-- Notification types
Notification.types = {
    INFO = "info",
    SUCCESS = "success",
    WARNING = "warning",
    ERROR = "error",
    ACHIEVEMENT = "achievement",
    LEVEL_UP = "level_up"
}

-- Default notification configuration
Notification.defaults = {
    width = 300,
    height = 60,
    cornerRadius = 8,
    fontSize = 14,
    duration = 3.0,
    fadeIn = 0.3,
    fadeOut = 0.5,
    colors = {
        info = {0.2, 0.4, 0.8, 0.9},
        success = {0.2, 0.6, 0.2, 0.9},
        warning = {0.8, 0.6, 0.2, 0.9},
        error = {0.8, 0.2, 0.2, 0.9},
        achievement = {0.8, 0.4, 0.8, 0.9},
        level_up = {0.4, 0.8, 0.4, 0.9}
    },
    textColors = {
        info = {1, 1, 1, 1},
        success = {1, 1, 1, 1},
        warning = {1, 1, 1, 1},
        error = {1, 1, 1, 1},
        achievement = {1, 1, 1, 1},
        level_up = {1, 1, 1, 1}
    }
}

-- Create a new notification
function Notification.new(config)
    config = config or {}
    
    local notification = {
        x = config.x or 0,
        y = config.y or 0,
        width = config.width or Notification.defaults.width,
        height = config.height or Notification.defaults.height,
        message = config.message or "",
        type = config.type or Notification.types.INFO,
        duration = config.duration or Notification.defaults.duration,
        fadeIn = config.fadeIn or Notification.defaults.fadeIn,
        fadeOut = config.fadeOut or Notification.defaults.fadeOut,
        colors = config.colors or Notification.defaults.colors,
        textColors = config.textColors or Notification.defaults.textColors,
        cornerRadius = config.cornerRadius or Notification.defaults.cornerRadius,
        fontSize = config.fontSize or Notification.defaults.fontSize,
        font = nil,
        timer = 0,
        alpha = 0,
        isActive = true,
        onComplete = config.onComplete or function() end
    }
    
    -- Create font for text
    notification.font = love.graphics.newFont(notification.fontSize)
    
    return notification
end

-- Update notification (call this every frame)
function Notification.update(notification, dt)
    if not notification.isActive then
        return
    end
    
    notification.timer = notification.timer + dt
    
    -- Handle fade in
    if notification.timer <= notification.fadeIn then
        notification.alpha = notification.timer / notification.fadeIn
    -- Handle fade out
    elseif notification.timer >= notification.duration - notification.fadeOut then
        local fadeOutProgress = (notification.timer - (notification.duration - notification.fadeOut)) / notification.fadeOut
        notification.alpha = 1 - fadeOutProgress
    else
        notification.alpha = 1
    end
    
    -- Check if notification is complete
    if notification.timer >= notification.duration then
        notification.isActive = false
        notification.onComplete(notification)
    end
end

-- Draw the notification
function Notification.draw(notification)
    if not notification.isActive then
        return
    end
    
    -- Get colors based on type
    local bgColor = notification.colors[notification.type] or notification.colors.info
    local textColor = notification.textColors[notification.type] or notification.textColors.info
    
    -- Apply alpha
    local finalBgColor = {bgColor[1], bgColor[2], bgColor[3], bgColor[4] * notification.alpha}
    local finalTextColor = {textColor[1], textColor[2], textColor[3], textColor[4] * notification.alpha}
    
    -- Draw background
    Utils.setColor(finalBgColor)
    love.graphics.rectangle("fill", notification.x, notification.y, notification.width, notification.height, notification.cornerRadius)
    
    -- Draw border
    Utils.setColor({1, 1, 1, 0.3 * notification.alpha})
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", notification.x, notification.y, notification.width, notification.height, notification.cornerRadius)
    
    -- Draw text
    Utils.setColor(finalTextColor)
    love.graphics.setFont(notification.font)
    
    -- Word wrap text
    local wrappedText = Utils.wordWrap(notification.message, notification.font, notification.width - 20)
    local lineHeight = notification.font:getHeight()
    local totalHeight = #wrappedText * lineHeight
    local startY = notification.y + (notification.height - totalHeight) / 2
    
    for i, line in ipairs(wrappedText) do
        local textWidth = notification.font:getWidth(line)
        local textX = notification.x + (notification.width - textWidth) / 2
        local textY = startY + (i - 1) * lineHeight
        love.graphics.print(line, textX, textY)
    end
end

-- Set notification position
function Notification.setPosition(notification, x, y)
    notification.x = x
    notification.y = y
end

-- Set notification message
function Notification.setMessage(notification, message)
    notification.message = message
end

-- Set notification type
function Notification.setType(notification, type)
    notification.type = type
end

-- Check if notification is active
function Notification.isActive(notification)
    return notification.isActive
end

-- Create a notification manager
function Notification.createManager()
    local manager = {
        notifications = {},
        maxNotifications = 5,
        spacing = 10
    }
    
    -- Add a notification
    function manager:add(config)
        -- Remove oldest notification if we're at max capacity
        if #self.notifications >= self.maxNotifications then
            table.remove(self.notifications, 1)
        end
        
        -- Create new notification
        local notification = Notification.new(config)
        
        -- Position notification
        local screenWidth = love.graphics.getWidth()
        local y = 10 + (#self.notifications * (notification.height + self.spacing))
        notification.x = screenWidth - notification.width - 10
        notification.y = y
        
        -- Add to list
        table.insert(self.notifications, notification)
        
        return notification
    end
    
    -- Update all notifications
    function manager:update(dt)
        for i = #self.notifications, 1, -1 do
            local notification = self.notifications[i]
            notification:update(dt)
            
            -- Remove completed notifications
            if not notification:isActive() then
                table.remove(self.notifications, i)
            end
        end
    end
    
    -- Draw all notifications
    function manager:draw()
        for _, notification in ipairs(self.notifications) do
            notification:draw()
        end
    end
    
    -- Clear all notifications
    function manager:clear()
        self.notifications = {}
    end
    
    -- Get notification count
    function manager:getCount()
        return #self.notifications
    end
    
    return manager
end

-- Helper functions for common notification types
function Notification.showInfo(message, duration)
    return Notification.new({
        message = message,
        type = Notification.types.INFO,
        duration = duration
    })
end

function Notification.showSuccess(message, duration)
    return Notification.new({
        message = message,
        type = Notification.types.SUCCESS,
        duration = duration
    })
end

function Notification.showWarning(message, duration)
    return Notification.new({
        message = message,
        type = Notification.types.WARNING,
        duration = duration
    })
end

function Notification.showError(message, duration)
    return Notification.new({
        message = message,
        type = Notification.types.ERROR,
        duration = duration
    })
end

function Notification.showAchievement(message, duration)
    return Notification.new({
        message = message,
        type = Notification.types.ACHIEVEMENT,
        duration = duration
    })
end

function Notification.showLevelUp(message, duration)
    return Notification.new({
        message = message,
        type = Notification.types.LEVEL_UP,
        duration = duration
    })
end

return Notification 