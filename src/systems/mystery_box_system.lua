local Config = require("src.utils.config")

local MysteryBoxSystem = {
    boxes = {},
    base_spawn_chance = 0.015, -- Base spawn chance (modified by config)
    box_types = {},
    opening_animation = nil,
    rewards = {},
    last_spawn_time = 0,
    spawn_cooldown = 120, -- 2 minutes minimum between spawns
    session_boxes_spawned = 0,
    max_boxes_per_session = 3 -- Limit per 10-minute session
}

function MysteryBoxSystem:init(game_state)
    self.game_state = game_state
    self.boxes = {}
    self.opening_animation = nil
    
    -- Define box types with rarities
    self.box_types = {
        bronze = {
            rarity = 0.5,
            color = {0.7, 0.4, 0.2, 1},
            particle_color = {0.8, 0.5, 0.3},
            min_rewards = 1,
            max_rewards = 2
        },
        silver = {
            rarity = 0.35,
            color = {0.8, 0.8, 0.8, 1},
            particle_color = {0.9, 0.9, 0.9},
            min_rewards = 2,
            max_rewards = 3
        },
        gold = {
            rarity = 0.12,
            color = {1, 0.8, 0, 1},
            particle_color = {1, 0.9, 0.2},
            min_rewards = 2,
            max_rewards = 4
        },
        legendary = {
            rarity = 0.03,
            color = {0.8, 0, 1, 1},
            particle_color = {0.9, 0.2, 1},
            min_rewards = 3,
            max_rewards = 5
        }
    }
    
    -- Define possible rewards
    self.rewards = {
        {
            type = "xp_multiplier",
            name = "XP Boost",
            duration = 60,
            multiplier = 2.0,
            rarity = 0.3,
            description = "Double XP for 60 seconds!"
        },
        {
            type = "rare_skin",
            name = "Cosmic Trail",
            rarity = 0.15,
            description = "Unlocked Cosmic Trail effect!"
        },
        {
            type = "ability_cooldown",
            name = "Fast Dash",
            duration = 120,
            cooldown_reduction = 0.5,
            rarity = 0.2,
            description = "50% faster dash cooldown!"
        },
        {
            type = "ring_magnet",
            name = "Super Magnet",
            duration = 90,
            range_multiplier = 2.5,
            rarity = 0.25,
            description = "Massive ring attraction range!"
        },
        {
            type = "exclusive_planet",
            name = "Crystal Planet",
            rarity = 0.08,
            description = "Unlocked Crystal Planet type!"
        },
        {
            type = "legendary_effect",
            name = "Rainbow Aura",
            rarity = 0.02,
            description = "Legendary Rainbow Aura unlocked!"
        }
    }
end

function MysteryBoxSystem:checkForBoxSpawn(planet)
    -- Don't spawn if box already exists on this planet
    for _, box in ipairs(self.boxes) do
        if not box.collected and box.planet_id == planet.id then
            return
        end
    end
    
    -- Check session limits
    if self.session_boxes_spawned >= self.max_boxes_per_session then
        return
    end
    
    -- Check cooldown
    local current_time = love.timer.getTime()
    if current_time - self.last_spawn_time < self.spawn_cooldown then
        return
    end
    
    -- Apply config-based spawn chance modification
    local spawn_chance = self.base_spawn_chance * Config.getEventFrequencyMultiplier()
    
    -- Skip if events are disabled
    if spawn_chance == 0 then
        return
    end
    
    -- Roll for spawn
    if math.random() > spawn_chance then
        return
    end
    
    -- Select box type based on rarity
    local box_type = self:selectBoxType()
    if box_type then
        self:spawnBox(planet, box_type)
        self.last_spawn_time = current_time
        self.session_boxes_spawned = self.session_boxes_spawned + 1
    end
end

function MysteryBoxSystem:selectBoxType()
    local total_weight = 0
    for _, type_data in pairs(self.box_types) do
        total_weight = total_weight + type_data.rarity
    end
    
    local roll = math.random() * total_weight
    local current_weight = 0
    
    for type_name, type_data in pairs(self.box_types) do
        current_weight = current_weight + type_data.rarity
        if roll <= current_weight then
            return type_name
        end
    end
    
    return "bronze" -- Fallback
end

function MysteryBoxSystem:spawnBox(planet, box_type)
    local angle = math.random() * math.pi * 2
    local distance = planet.radius + 30
    
    local box = {
        id = #self.boxes + 1,
        x = planet.x + math.cos(angle) * distance,
        y = planet.y + math.sin(angle) * distance,
        planet_id = planet.id,
        type = box_type,
        type_data = self.box_types[box_type],
        radius = 20,
        rotation = 0,
        pulse_phase = 0,
        collected = false,
        float_offset = 0,
        particle_timer = 0
    }
    
    table.insert(self.boxes, box)
    
    -- Play spawn sound
    if self.game_state.soundSystem and self.game_state.soundSystem.playMysteryBoxSpawn then
        self.game_state.soundSystem:playMysteryBoxSpawn()
    end
end

function MysteryBoxSystem:update(dt)
    -- Update boxes
    for _, box in ipairs(self.boxes) do
        if not box.collected then
            -- Rotation animation
            box.rotation = box.rotation + dt * 0.5
            
            -- Pulse animation
            box.pulse_phase = box.pulse_phase + dt * 2
            
            -- Floating animation
            box.float_offset = math.sin(box.pulse_phase) * 5
            
            -- Particle spawning
            box.particle_timer = box.particle_timer + dt
            if box.particle_timer > 0.1 then
                box.particle_timer = 0
                self:spawnBoxParticle(box)
            end
        end
    end
    
    -- Update opening animation
    if self.opening_animation then
        self:updateOpeningAnimation(dt)
    end
end

function MysteryBoxSystem:spawnBoxParticle(box)
    -- Create particle effect around box
    if self.game_state.particle_system then
        local angle = math.random() * math.pi * 2
        local speed = 20 + math.random() * 30
        self.game_state.particle_system:emit({
            x = box.x,
            y = box.y + box.float_offset,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = box.type_data.particle_color,
            lifetime = 1.0,
            size = 3
        })
    end
end

function MysteryBoxSystem:checkCollision(player)
    for _, box in ipairs(self.boxes) do
        if not box.collected then
            local dx = player.x - box.x
            local dy = player.y - (box.y + box.float_offset)
            local distance = math.sqrt(dx * dx + dy * dy)
            
            if distance < player.radius + box.radius then
                self:collectBox(box, player)
                return true
            end
        end
    end
    return false
end

function MysteryBoxSystem:collectBox(box, player)
    box.collected = true
    
    -- Start opening animation
    self.opening_animation = {
        box = box,
        timer = 0,
        duration = 2.0,
        phase = "opening",
        rewards = self:generateRewards(box),
        current_reward = 1,
        reward_display_time = 1.5
    }
    
    -- Play collect sound
    if self.game_state.soundSystem and self.game_state.soundSystem.playMysteryBoxOpen then
        self.game_state.soundSystem:playMysteryBoxOpen(box.type)
    end
    
    -- Track in session stats
    local SessionStatsSystem = require("src.systems.session_stats_system")
    if SessionStatsSystem then
        SessionStatsSystem.onMysteryBoxOpened()
    end
    
    -- Track for feedback system
    local Utils = require("src.utils.utils")
    local FeedbackSystem = Utils.require("src.systems.feedback_system")
    if FeedbackSystem then
        -- Get the first reward type for context
        local firstReward = self.opening_animation.rewards[1]
        local rewardType = firstReward and firstReward.type or "unknown"
        FeedbackSystem.onMysteryBoxOpened(box.type, rewardType)
    end
    
    -- Notify social systems
    local WeeklyChallengesSystem = require("src.systems.weekly_challenges_system")
    if WeeklyChallengesSystem then
        WeeklyChallengesSystem:onMysteryBoxOpened()
    end
    
    local AchievementSystem = require("src.systems.achievement_system")
    if AchievementSystem then
        AchievementSystem:onMysteryBoxOpened()
    end
end

function MysteryBoxSystem:generateRewards(box)
    local num_rewards = math.random(box.type_data.min_rewards, box.type_data.max_rewards)
    local selected_rewards = {}
    
    -- Higher tier boxes have better reward chances
    local rarity_bonus = 1.0
    if box.type == "silver" then
        rarity_bonus = 1.5
    elseif box.type == "gold" then
        rarity_bonus = 2.0
    elseif box.type == "legendary" then
        rarity_bonus = 3.0
    end
    
    for i = 1, num_rewards do
        local reward = self:selectReward(rarity_bonus)
        if reward then
            table.insert(selected_rewards, reward)
        end
    end
    
    return selected_rewards
end

function MysteryBoxSystem:selectReward(rarity_bonus)
    local total_weight = 0
    for _, reward in ipairs(self.rewards) do
        total_weight = total_weight + (reward.rarity * rarity_bonus)
    end
    
    local roll = math.random() * total_weight
    local current_weight = 0
    
    for _, reward in ipairs(self.rewards) do
        current_weight = current_weight + (reward.rarity * rarity_bonus)
        if roll <= current_weight then
            return {
                type = reward.type,
                name = reward.name,
                description = reward.description,
                duration = reward.duration,
                multiplier = reward.multiplier,
                cooldown_reduction = reward.cooldown_reduction,
                range_multiplier = reward.range_multiplier
            }
        end
    end
    
    return nil
end

function MysteryBoxSystem:updateOpeningAnimation(dt)
    local anim = self.opening_animation
    if not anim then return end
    
    anim.timer = anim.timer + dt
    
    if anim.phase == "opening" then
        if anim.timer >= anim.duration then
            anim.phase = "revealing"
            anim.timer = 0
            
            -- Apply first reward
            if anim.rewards[anim.current_reward] then
                self:applyReward(anim.rewards[anim.current_reward])
            end
        end
    elseif anim.phase == "revealing" then
        if anim.timer >= anim.reward_display_time then
            anim.current_reward = anim.current_reward + 1
            anim.timer = 0
            
            if anim.current_reward <= #anim.rewards then
                -- Apply next reward
                self:applyReward(anim.rewards[anim.current_reward])
            else
                -- Animation complete
                self.opening_animation = nil
            end
        end
    end
end

function MysteryBoxSystem:applyReward(reward)
    -- Apply reward effects based on type
    if reward.type == "xp_multiplier" then
        local XPSystem = require("src.systems.xp_system")
        XPSystem.addTemporaryMultiplier(reward.multiplier, reward.duration)
    elseif reward.type == "rare_skin" then
        -- Unlock skin in progression system
        if self.game_state.progression_system then
            self.game_state.progression_system:unlockSkin(reward.name)
        end
    elseif reward.type == "ability_cooldown" then
        -- Apply cooldown reduction
        if self.game_state.player then
            self.game_state.player.temp_cooldown_reduction = reward.cooldown_reduction
            self.game_state.player.cooldown_reduction_timer = reward.duration
        end
    elseif reward.type == "ring_magnet" then
        -- Apply magnet boost
        if self.game_state.player then
            self.game_state.player.temp_magnet_range_boost = reward.range_multiplier
            self.game_state.player.magnet_boost_timer = reward.duration
        end
    elseif reward.type == "exclusive_planet" then
        -- Unlock planet type
        if self.game_state.world_generator then
            self.game_state.world_generator:unlockPlanetType(reward.name)
        end
    elseif reward.type == "legendary_effect" then
        -- Unlock legendary effect
        if self.game_state.progression_system then
            self.game_state.progression_system:unlockLegendaryEffect(reward.name)
        end
    end
    
    -- Show reward notification
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification(reward.description, {1, 1, 0, 1})
    end
    
    -- Play reward sound
    if self.game_state.sound_system then
        self.game_state.sound_system:playRewardSound()
    end
end

function MysteryBoxSystem:draw()
    -- Draw boxes
    for _, box in ipairs(self.boxes) do
        if not box.collected then
            self:drawBox(box)
        end
    end
    
    -- Draw opening animation
    if self.opening_animation then
        self:drawOpeningAnimation()
    end
end

function MysteryBoxSystem:drawBox(box)
    love.graphics.push()
    love.graphics.translate(box.x, box.y + box.float_offset)
    love.graphics.rotate(box.rotation)
    
    -- Outer glow
    local glow_size = 1 + math.sin(box.pulse_phase) * 0.2
    love.graphics.setColor(box.type_data.color[1], box.type_data.color[2], box.type_data.color[3], 0.3)
    love.graphics.circle("fill", 0, 0, box.radius * glow_size * 1.5)
    
    -- Box body
    love.graphics.setColor(box.type_data.color)
    love.graphics.rectangle("fill", -box.radius, -box.radius, box.radius * 2, box.radius * 2, 5)
    
    -- Inner shine
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.rectangle("fill", -box.radius * 0.7, -box.radius * 0.7, box.radius * 0.5, box.radius * 0.5, 3)
    
    -- Question mark
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.print("?", -5, -10)
    
    love.graphics.pop()
end

function MysteryBoxSystem:drawOpeningAnimation()
    local anim = self.opening_animation
    if not anim then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    if anim.phase == "opening" then
        -- Enhanced opening effect with rarity-specific visuals
        local effects_scale = Config.getVisualEffectsScale()
        local progress = anim.timer / anim.duration
        local scale = 1 + (progress * 3 * effects_scale)
        local alpha = (1 - progress * 0.5) * effects_scale
        
        -- Create particle burst effect during opening
        if progress > 0.5 and not anim.particles_spawned then
            anim.particles_spawned = true
            local ParticleSystem = require("src.systems.particle_system")
            if ParticleSystem then
                local intensity = 0.8
                if anim.box.type == "legendary" then

                    ParticleSystem.createEmotionalBurst(anim.box.x, anim.box.y, "power", intensity)
                elseif anim.box.type == "gold" then
                    ParticleSystem.createEmotionalBurst(anim.box.x, anim.box.y, "achievement", intensity)
                else
                    ParticleSystem.createEmotionalBurst(anim.box.x, anim.box.y, "joy", intensity * 0.7)
                end
            end
        end
        
        -- Multi-layered expansion effect
        love.graphics.push()
        love.graphics.translate(anim.box.x, anim.box.y)
        
        -- Outer energy ring
        love.graphics.push()
        love.graphics.scale(scale * 1.5, scale * 1.5)
        love.graphics.rotate(anim.timer * 3)
        love.graphics.setColor(anim.box.type_data.color[1], anim.box.type_data.color[2], anim.box.type_data.color[3], alpha * 0.3)
        love.graphics.circle("line", 0, 0, anim.box.radius)
        love.graphics.pop()
        
        -- Main expanding box
        love.graphics.push()
        love.graphics.scale(scale, scale)
        love.graphics.rotate(anim.timer * 5)
        love.graphics.setColor(anim.box.type_data.color[1], anim.box.type_data.color[2], anim.box.type_data.color[3], alpha)
        love.graphics.rectangle("fill", -anim.box.radius, -anim.box.radius, anim.box.radius * 2, anim.box.radius * 2, 5)
        love.graphics.pop()
        
        love.graphics.pop()
        
        -- Enhanced opening text with rarity-specific styling
        local textColor = anim.box.type_data.color
        love.graphics.setColor(textColor[1], textColor[2], textColor[3], 1)
        love.graphics.setFont(love.graphics.newFont(24))
        local text = "OPENING " .. anim.box.type:upper() .. " BOX..."
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, screenWidth/2 - textWidth/2, screenHeight/2 + 100)
        
        -- Progress indicator
        love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
        love.graphics.rectangle("fill", screenWidth/2 - 150, screenHeight/2 + 140, 300, 8, 4)
        love.graphics.setColor(textColor[1], textColor[2], textColor[3], 0.9)
        love.graphics.rectangle("fill", screenWidth/2 - 150, screenHeight/2 + 140, 300 * progress, 8, 4)
        
    elseif anim.phase == "revealing" then
        -- Enhanced reward reveal with rarity-specific effects
        local reward = anim.rewards[anim.current_reward]
        if reward then
            local reveal_progress = anim.timer / anim.reward_display_time
            local panel_alpha = math.min(1, reveal_progress * 2)
            
            -- Enhanced background panel with rarity glow
            local panelColor = anim.box.type_data.color
            love.graphics.setColor(panelColor[1] * 0.2, panelColor[2] * 0.2, panelColor[3] * 0.2, 0.9)
            love.graphics.rectangle("fill", screenWidth/2 - 280, screenHeight/2 - 120, 560, 240, 15)
            
            -- Glowing border
            love.graphics.setColor(panelColor[1], panelColor[2], panelColor[3], panel_alpha * 0.8)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", screenWidth/2 - 280, screenHeight/2 - 120, 560, 240, 15)
            love.graphics.setLineWidth(1)
            
            -- Rarity indicator
            love.graphics.setColor(panelColor[1], panelColor[2], panelColor[3], panel_alpha)
            love.graphics.setFont(love.graphics.newFont(16))
            local rarityText = anim.box.type:upper() .. " REWARD"
            local rarityWidth = love.graphics.getFont():getWidth(rarityText)
            love.graphics.print(rarityText, screenWidth/2 - rarityWidth/2, screenHeight/2 - 100)
            
            -- Reward name with dynamic scaling
            local nameScale = 1 + math.sin(love.timer.getTime() * 4) * 0.1
            love.graphics.push()
            love.graphics.translate(screenWidth/2, screenHeight/2 - 40)
            love.graphics.scale(nameScale, nameScale)
            love.graphics.setColor(1, 1, 0.8, panel_alpha)
            love.graphics.setFont(love.graphics.newFont(20))
            local nameWidth = love.graphics.getFont():getWidth(reward.name)
            love.graphics.print(reward.name, -nameWidth/2, -10)
            love.graphics.pop()
            
            -- Reward description
            love.graphics.setColor(1, 1, 1, panel_alpha * 0.9)
            love.graphics.setFont(love.graphics.newFont(14))
            local descWidth = love.graphics.getFont():getWidth(reward.description)
            love.graphics.print(reward.description, screenWidth/2 - descWidth/2, screenHeight/2 + 10)
            
            -- Enhanced progress bar with glow
            love.graphics.setColor(0.2, 0.2, 0.2, panel_alpha)
            love.graphics.rectangle("fill", screenWidth/2 - 120, screenHeight/2 + 60, 240, 12, 6)
            
            local progress = anim.timer / anim.reward_display_time
            love.graphics.setColor(panelColor[1], panelColor[2], panelColor[3], panel_alpha)
            love.graphics.rectangle("fill", screenWidth/2 - 120, screenHeight/2 + 60, 240 * progress, 12, 6)
            
            -- Progress glow effect
            if progress > 0 then
                love.graphics.setColor(panelColor[1], panelColor[2], panelColor[3], panel_alpha * 0.3)
                love.graphics.rectangle("fill", screenWidth/2 - 125, screenHeight/2 + 58, (240 * progress) + 10, 16, 8)
            end
            
            -- Reward counter for multiple rewards
            if #anim.rewards > 1 then
                love.graphics.setColor(0.8, 0.8, 0.8, panel_alpha * 0.7)
                love.graphics.setFont(love.graphics.newFont(12))
                local counterText = string.format("Reward %d of %d", anim.current_reward, #anim.rewards)
                local counterWidth = love.graphics.getFont():getWidth(counterText)
                love.graphics.print(counterText, screenWidth/2 - counterWidth/2, screenHeight/2 + 85)
            end
        end
    end
end

function MysteryBoxSystem:getActiveBoxCount()
    local count = 0
    for _, box in ipairs(self.boxes) do
        if not box.collected then
            count = count + 1
        end
    end
    return count
end

return MysteryBoxSystem