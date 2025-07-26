-- Event Bus System for Orbit Jump
-- Decoupled event handling system

local EventBus = {}

-- Storage for event listeners
EventBus.listeners = {}
EventBus.oneTimeListeners = {}

-- Initialize the event bus
function EventBus.init()
    EventBus.listeners = {}
    EventBus.oneTimeListeners = {}
    return true
end

-- Subscribe to an event
function EventBus.on(eventName, callback, priority)
    priority = priority or 0
    
    if not EventBus.listeners[eventName] then
        EventBus.listeners[eventName] = {}
    end
    
    table.insert(EventBus.listeners[eventName], {
        callback = callback,
        priority = priority
    })
    
    -- Sort by priority (higher priority first)
    table.sort(EventBus.listeners[eventName], function(a, b)
        return a.priority > b.priority
    end)
    
    -- Return unsubscribe function
    return function()
        EventBus.off(eventName, callback)
    end
end

-- Subscribe to an event once
function EventBus.once(eventName, callback, priority)
    priority = priority or 0
    
    if not EventBus.oneTimeListeners[eventName] then
        EventBus.oneTimeListeners[eventName] = {}
    end
    
    table.insert(EventBus.oneTimeListeners[eventName], {
        callback = callback,
        priority = priority
    })
    
    -- Sort by priority
    table.sort(EventBus.oneTimeListeners[eventName], function(a, b)
        return a.priority > b.priority
    end)
end

-- Unsubscribe from an event
function EventBus.off(eventName, callback)
    if EventBus.listeners[eventName] then
        for i = #EventBus.listeners[eventName], 1, -1 do
            if EventBus.listeners[eventName][i].callback == callback then
                table.remove(EventBus.listeners[eventName], i)
            end
        end
        
        -- Clean up empty listener arrays
        if #EventBus.listeners[eventName] == 0 then
            EventBus.listeners[eventName] = nil
        end
    end
    
    -- Also check one-time listeners
    if EventBus.oneTimeListeners[eventName] then
        for i = #EventBus.oneTimeListeners[eventName], 1, -1 do
            if EventBus.oneTimeListeners[eventName][i].callback == callback then
                table.remove(EventBus.oneTimeListeners[eventName], i)
            end
        end
        
        if #EventBus.oneTimeListeners[eventName] == 0 then
            EventBus.oneTimeListeners[eventName] = nil
        end
    end
end

-- Emit an event
function EventBus.emit(eventName, data)
    local results = {}
    
    -- Call one-time listeners first
    if EventBus.oneTimeListeners[eventName] then
        local oneTimeListeners = EventBus.oneTimeListeners[eventName]
        EventBus.oneTimeListeners[eventName] = nil
        
        for _, listener in ipairs(oneTimeListeners) do
            local success, result = pcall(listener.callback, data)
            if success then
                table.insert(results, result)
            else
                print("EventBus: Error in one-time listener for " .. eventName .. ": " .. result)
            end
        end
    end
    
    -- Call regular listeners
    if EventBus.listeners[eventName] then
        for _, listener in ipairs(EventBus.listeners[eventName]) do
            local success, result = pcall(listener.callback, data)
            if success then
                table.insert(results, result)
            else
                print("EventBus: Error in listener for " .. eventName .. ": " .. result)
            end
        end
    end
    
    return results
end

-- Clear all listeners for an event
function EventBus.clear(eventName)
    if eventName then
        EventBus.listeners[eventName] = nil
        EventBus.oneTimeListeners[eventName] = nil
    else
        -- Clear all events
        EventBus.listeners = {}
        EventBus.oneTimeListeners = {}
    end
end

-- Get listener count for an event
function EventBus.getListenerCount(eventName)
    local count = 0
    
    if EventBus.listeners[eventName] then
        count = count + #EventBus.listeners[eventName]
    end
    
    if EventBus.oneTimeListeners[eventName] then
        count = count + #EventBus.oneTimeListeners[eventName]
    end
    
    return count
end

-- Common game events
EventBus.events = {
    -- Player events
    PLAYER_DAMAGE = "player:damage",
    PLAYER_DEATH = "player:death",
    PLAYER_SHIELD_BREAK = "player:shield_break",
    PLAYER_SHIELD_GAIN = "player:shield_gain",
    PLAYER_JUMP = "player:jump",
    PLAYER_LAND = "player:land",
    PLAYER_WARP = "player:warp",
    
    -- Game state events
    GAME_START = "game:start",
    GAME_PAUSE = "game:pause",
    GAME_RESUME = "game:resume",
    GAME_OVER = "game:over",
    LEVEL_COMPLETE = "level:complete",
    
    -- Collectible events
    RING_COLLECTED = "ring:collected",
    POWERUP_COLLECTED = "powerup:collected",
    ARTIFACT_COLLECTED = "artifact:collected",
    
    -- Combat events
    ENEMY_KILLED = "enemy:killed",
    METEOR_HIT = "meteor:hit",
    
    -- UI events
    MENU_OPEN = "menu:open",
    MENU_CLOSE = "menu:close",
    SETTING_CHANGED = "setting:changed",
    
    -- Achievement events
    ACHIEVEMENT_UNLOCKED = "achievement:unlocked",
    PROGRESS_UPDATE = "progress:update",
    
    -- Performance events
    FPS_WARNING = "performance:fps_warning",
    MEMORY_WARNING = "performance:memory_warning"
}

return EventBus