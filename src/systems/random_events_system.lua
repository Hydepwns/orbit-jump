local Config = require("src.utils.config")
local RandomEventsSystem = {
    events = {},
    active_events = {},
    base_event_chance = 0.03, -- Base event chance (modified by config)
    event_cooldown = 0,
    event_cooldown_duration = 120, -- Increased from 3s to 2 minutes
    session_events_triggered = 0,
    max_events_per_session = 2, -- Limit per 10-minute session
    last_event_time = 0
}
function RandomEventsSystem:init(game_state)
    self.game_state = game_state
    self.events = {}
    self.active_events = {}
    self.event_cooldown = 0
    -- Register event types
    self:registerEvent("ring_rain", {
        name = "Ring Rain",
        duration = 8.0,
        rarity = 0.4, -- 40% of random events
        color = {1, 0.8, 0, 1},
        message = "RING RAIN!",
        particle_color = {1, 0.9, 0.2}
    })
    self:registerEvent("gravity_well", {
        name = "Gravity Well",
        duration = 6.0,
        rarity = 0.35, -- 35% of random events
        color = {0.5, 0, 1, 1},
        message = "GRAVITY WELL!",
        particle_color = {0.6, 0.2, 1}
    })
    self:registerEvent("time_dilation", {
        name = "Time Dilation",
        duration = 5.0,
        rarity = 0.25, -- 25% of random events
        color = {0, 1, 1, 1},
        message = "TIME DILATION!",
        particle_color = {0.2, 1, 1}
    })
end
function RandomEventsSystem:registerEvent(id, config)
    self.events[id] = {
        id = id,
        name = config.name,
        duration = config.duration,
        rarity = config.rarity,
        color = config.color,
        message = config.message,
        particle_color = config.particle_color
    }
end
function RandomEventsSystem:checkForRandomEvent()
    -- Don't trigger during cooldown or if event already active
    if self.event_cooldown > 0 or next(self.active_events) ~= nil then
        return
    end
    -- Check session limits
    if self.session_events_triggered >= self.max_events_per_session then
        return
    end
    -- Check minimum time between events
    local current_time = love.timer.getTime()
    if current_time - self.last_event_time < self.event_cooldown_duration then
        return
    end
    -- Apply config-based event chance modification
    local event_chance = self.base_event_chance * Config.getEventFrequencyMultiplier()
    -- Skip if events are disabled
    if event_chance == 0 then
        return
    end
    -- Roll for event trigger
    if math.random() > event_chance then
        return
    end
    -- Select event based on rarity weights
    local event = self:selectRandomEvent()
    if event then
        self:triggerEvent(event)
        self.last_event_time = current_time
        self.session_events_triggered = self.session_events_triggered + 1
    end
end
function RandomEventsSystem:selectRandomEvent()
    local total_weight = 0
    for _, event in pairs(self.events) do
        total_weight = total_weight + event.rarity
    end
    local roll = math.random() * total_weight
    local current_weight = 0
    for _, event in pairs(self.events) do
        current_weight = current_weight + event.rarity
        if roll <= current_weight then
            return event
        end
    end
    return nil
end
function RandomEventsSystem:triggerEvent(event)
    local active_event = {
        id = event.id,
        name = event.name,
        duration = event.duration,
        time_remaining = event.duration,
        color = event.color,
        message = event.message,
        particle_color = event.particle_color,
        start_time = love.timer.getTime()
    }
    self.active_events[event.id] = active_event
    self.event_cooldown = self.event_cooldown_duration
    -- Trigger event-specific effects
    if event.id == "ring_rain" then
        self:startRingRain()
    elseif event.id == "gravity_well" then
        self:startGravityWell()
    elseif event.id == "time_dilation" then
        self:startTimeDilation()
    end
    -- Notify UI system
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification(event.message, event.color)
    end
    -- Play event sound
    if self.game_state.soundSystem and self.game_state.soundSystem.playRandomEvent then
        self.game_state.soundSystem:playRandomEvent(event.id)
    end
    -- Track in session stats
    local SessionStatsSystem = require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onRandomEventTriggered(event.id)
    end
end
function RandomEventsSystem:startRingRain()
    -- Create cascading rings
    self.ring_rain_state = {
        spawn_timer = 0,
        spawn_interval = 0.3,
        rings_per_spawn = 3,
        spawn_radius = 300
    }
end
function RandomEventsSystem:updateRingRain(dt)
    if not self.ring_rain_state then return end
    self.ring_rain_state.spawn_timer = self.ring_rain_state.spawn_timer + dt
    if self.ring_rain_state.spawn_timer >= self.ring_rain_state.spawn_interval then
        self.ring_rain_state.spawn_timer = 0
        -- Spawn rings in a cascade pattern
        local player = self.game_state.player
        if player then
            for i = 1, self.ring_rain_state.rings_per_spawn do
                local angle = math.random() * math.pi * 2
                local distance = 100 + math.random() * self.ring_rain_state.spawn_radius
                local x = player.x + math.cos(angle) * distance
                local y = player.y + math.sin(angle) * distance
                -- Create special event ring
                if self.game_state.spawnEventRing then
                    self.game_state.spawnEventRing(x, y, "gold", {
                        velocity_y = 50 + math.random() * 100,
                        particle_trail = true,
                        particle_color = {1, 0.9, 0.2}
                    })
                end
            end
        end
    end
end
function RandomEventsSystem:startGravityWell()
    -- Enhance ring attraction
    self.gravity_well_state = {
        attraction_multiplier = 3.0,
        attraction_range_multiplier = 2.5
    }
    -- Apply to existing player magnetism
    if self.game_state.player then
        self.game_state.player.temp_magnet_boost = self.gravity_well_state.attraction_multiplier
        self.game_state.player.temp_magnet_range_boost = self.gravity_well_state.attraction_range_multiplier
    end
end
function RandomEventsSystem:startTimeDilation()
    -- Slow everything except player input
    self.time_dilation_state = {
        world_time_scale = 0.3,
        player_time_scale = 1.0
    }
    -- Apply time scaling
    self.game_state.world_time_scale = self.time_dilation_state.world_time_scale
    self.game_state.player_time_scale = self.time_dilation_state.player_time_scale
end
function RandomEventsSystem:update(dt)
    -- Update cooldown
    if self.event_cooldown > 0 then
        self.event_cooldown = math.max(0, self.event_cooldown - dt)
    end
    -- Update active events
    local events_to_remove = {}
    for id, event in pairs(self.active_events) do
        event.time_remaining = event.time_remaining - dt
        -- Update event-specific logic
        if id == "ring_rain" then
            self:updateRingRain(dt)
        end
        -- Check if event has ended
        if event.time_remaining <= 0 then
            table.insert(events_to_remove, id)
        end
    end
    -- Remove ended events
    for _, id in ipairs(events_to_remove) do
        self:endEvent(id)
    end
end
function RandomEventsSystem:endEvent(event_id)
    local event = self.active_events[event_id]
    if not event then return end
    -- Clean up event-specific effects
    if event_id == "ring_rain" then
        self.ring_rain_state = nil
    elseif event_id == "gravity_well" then
        if self.game_state.player then
            self.game_state.player.temp_magnet_boost = nil
            self.game_state.player.temp_magnet_range_boost = nil
        end
        self.gravity_well_state = nil
    elseif event_id == "time_dilation" then
        self.game_state.world_time_scale = 1.0
        self.game_state.player_time_scale = 1.0
        self.time_dilation_state = nil
    end
    self.active_events[event_id] = nil
    -- Notify UI
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.hideEventNotification()
    end
end
function RandomEventsSystem:draw()
    -- Draw event-specific visuals
    for id, event in pairs(self.active_events) do
        if id == "gravity_well" then
            self:drawGravityWell(event)
        elseif id == "time_dilation" then
            self:drawTimeDilation(event)
        end
    end
end
function RandomEventsSystem:drawGravityWell(event)
    local player = self.game_state.player
    if not player then return end
    -- Draw pulsing gravity field effect
    local pulse = math.sin(love.timer.getTime() * 3) * 0.3 + 0.7
    local radius = 200 * pulse
    love.graphics.push()
    love.graphics.setColor(event.particle_color[1], event.particle_color[2], event.particle_color[3], 0.3 * pulse)
    love.graphics.setLineWidth(3)
    for i = 1, 3 do
        local r = radius * (1 + i * 0.3)
        love.graphics.circle("line", player.x, player.y, r)
    end
    love.graphics.pop()
end
function RandomEventsSystem:drawTimeDilation(event)
    -- Draw time distortion effect
    local time = love.timer.getTime()
    love.graphics.push()
    love.graphics.setColor(event.particle_color[1], event.particle_color[2], event.particle_color[3], 0.1)
    -- Draw warping lines
    for i = 1, 20 do
        local y = (i - 1) * (love.graphics.getHeight() / 19)
        local wave = math.sin(time * 2 + i * 0.5) * 20
        love.graphics.line(0, y + wave, love.graphics.getWidth(), y - wave)
    end
    love.graphics.pop()
end
function RandomEventsSystem:isEventActive(event_id)
    return self.active_events[event_id] ~= nil
end
function RandomEventsSystem:getActiveEventInfo()
    for _, event in pairs(self.active_events) do
        return {
            name = event.name,
            time_remaining = event.time_remaining,
            progress = 1 - (event.time_remaining / event.duration)
        }
    end
    return nil
end
return RandomEventsSystem