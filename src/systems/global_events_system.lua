local GlobalEventsSystem = {
    current_event = nil,
    event_history = {},
    community_progress = 0,
    individual_contributions = {},
    event_templates = {},
    update_timer = 0,
    update_interval = 60, -- Check progress every minute
    event_duration = 2592000, -- 30 days default
}

function GlobalEventsSystem:init()
    self.current_event = nil
    self.event_history = {}
    self.community_progress = 0
    self.individual_contributions = {}
    
    -- Define event templates
    self:defineEventTemplates()
    
    -- Start or load current event
    self:loadEventData()
    
    if not self.current_event then
        self:startNewEvent()
    end
end

function GlobalEventsSystem:defineEventTemplates()
    self.event_templates = {
        {
            id = "ring_harvest",
            name = "The Great Ring Harvest",
            description = "The galaxy needs YOUR help! Collect rings to power the Cosmic Shield.",
            community_goal = 1000000,
            individual_tiers = {
                { threshold = 100, reward = "Contributor", xp = 100 },
                { threshold = 500, reward = "Harvester", xp = 300 },
                { threshold = 1000, reward = "Ring Master", xp = 600 },
                { threshold = 5000, reward = "Cosmic Hero", xp = 1500 }
            },
            track_type = "rings_collected",
            duration = 2592000, -- 30 days
            story = {
                intro = "A massive asteroid field threatens populated sectors. We need rings to power the Cosmic Shield!",
                milestone_25 = "The shield is forming! Keep collecting - we're making great progress!",
                milestone_50 = "Halfway there! The shield is holding but needs more power!",
                milestone_75 = "Almost there! The populated sectors can see the shield glowing!",
                complete = "SUCCESS! The Cosmic Shield is fully powered. You saved millions of lives!"
            },
            exclusive_reward = {
                type = "title",
                value = "Shield Defender",
                cosmetic = "shield_aura"
            }
        },
        {
            id = "planet_discovery",
            name = "The Great Exploration",
            description = "Chart the unknown! Help map uncharted sectors of the galaxy.",
            community_goal = 50000,
            individual_tiers = {
                { threshold = 5, reward = "Scout", xp = 150 },
                { threshold = 15, reward = "Explorer", xp = 400 },
                { threshold = 30, reward = "Pathfinder", xp = 800 },
                { threshold = 50, reward = "Star Charter", xp = 1600 }
            },
            track_type = "planets_discovered",
            duration = 2592000,
            story = {
                intro = "New wormholes have opened paths to uncharted space. Be part of history!",
                milestone_25 = "Amazing discoveries! Strange new worlds with unique properties found!",
                milestone_50 = "We've mapped half the sector! Rare resources detected!",
                milestone_75 = "Nearly complete! Ancient ruins discovered on several planets!",
                complete = "EXPLORATION COMPLETE! New trade routes established. Prosperity for all!"
            },
            exclusive_reward = {
                type = "planet_skin",
                value = "Explorer's Legacy",
                cosmetic = "golden_trails"
            }
        },
        {
            id = "perfect_harmony",
            name = "The Harmony Protocol",
            description = "Achieve perfect landings to stabilize quantum fluctuations.",
            community_goal = 100000,
            individual_tiers = {
                { threshold = 10, reward = "Precise", xp = 120 },
                { threshold = 50, reward = "Harmonizer", xp = 350 },
                { threshold = 100, reward = "Quantum Pilot", xp = 700 },
                { threshold = 250, reward = "Perfect Being", xp = 1800 }
            },
            track_type = "perfect_landings",
            duration = 1814400, -- 21 days
            story = {
                intro = "Quantum instabilities detected! Perfect landings can restore harmony to spacetime.",
                milestone_25 = "The fluctuations are calming! Your precision is working!",
                milestone_50 = "Half stabilized! Reality itself seems more... stable.",
                milestone_75 = "Almost there! The quantum field is nearly harmonized!",
                complete = "HARMONY ACHIEVED! Spacetime is stable. Faster-than-light travel improved!"
            },
            exclusive_reward = {
                type = "effect",
                value = "Quantum Echo",
                cosmetic = "landing_ripples"
            }
        },
        {
            id = "legendary_hunt",
            name = "The Legendary Convergence",
            description = "Legendary rings are appearing! Collect them before they vanish!",
            community_goal = 10000,
            individual_tiers = {
                { threshold = 1, reward = "Lucky", xp = 200 },
                { threshold = 3, reward = "Fortune's Friend", xp = 500 },
                { threshold = 5, reward = "Legendary Hunter", xp = 1000 },
                { threshold = 10, reward = "Chosen One", xp = 2500 }
            },
            track_type = "legendary_rings",
            duration = 604800, -- 7 days (limited time!)
            story = {
                intro = "A rare cosmic alignment! Legendary rings manifest across the galaxy!",
                milestone_25 = "The convergence strengthens! More legendary rings detected!",
                milestone_50 = "Incredible! The legendary energy is peaking!",
                milestone_75 = "The convergence is ending soon! Last chance for legendary rings!",
                complete = "CONVERGENCE COMPLETE! The legendary power is yours to keep!"
            },
            exclusive_reward = {
                type = "legendary_effect",
                value = "Convergence Blessing",
                cosmetic = "legendary_aura"
            }
        }
    }
end

function GlobalEventsSystem:startNewEvent()
    -- Select next event (rotate or random)
    local event_index = (os.time() % #self.event_templates) + 1
    local template = self.event_templates[event_index]
    
    self.current_event = {
        id = template.id .. "_" .. os.time(),
        template = template,
        start_time = os.time(),
        end_time = os.time() + template.duration,
        community_progress = 0,
        community_goal = template.community_goal,
        milestones_reached = {},
        completed = false,
        individual_contributions = {},
        top_contributors = {}
    }
    
    -- Show event start notification
    self:showEventNotification(
        "GLOBAL EVENT: " .. template.name,
        template.story.intro
    )
    
    -- Play event fanfare
    local SoundManager = require("src.audio.sound_manager")
    if SoundManager then
        SoundManager:playGlobalEventStart()
    end
end

function GlobalEventsSystem:update(dt)
    if not self.current_event then return end
    
    self.update_timer = self.update_timer + dt
    
    -- Check if event has ended
    if os.time() > self.current_event.end_time then
        self:endCurrentEvent()
        return
    end
    
    -- Periodic progress updates
    if self.update_timer >= self.update_interval then
        self.update_timer = 0
        self:checkMilestones()
        self:updateLeaderboard()
    end
end

function GlobalEventsSystem:contributeProgress(amount, player_id)
    if not self.current_event or self.current_event.completed then return end
    
    -- Update community progress
    self.current_event.community_progress = self.current_event.community_progress + amount
    
    -- Update individual contribution
    player_id = player_id or "player"
    if not self.current_event.individual_contributions[player_id] then
        self.current_event.individual_contributions[player_id] = {
            amount = 0,
            tier_reached = 0,
            rewards_claimed = {}
        }
    end
    
    local contribution = self.current_event.individual_contributions[player_id]
    contribution.amount = contribution.amount + amount
    
    -- Check individual tier progression
    self:checkIndividualTiers(player_id)
    
    -- Check if community goal reached
    if self.current_event.community_progress >= self.current_event.community_goal then
        self:completeEvent()
    end
end

function GlobalEventsSystem:checkIndividualTiers(player_id)
    local contribution = self.current_event.individual_contributions[player_id]
    local template = self.current_event.template
    
    for i, tier in ipairs(template.individual_tiers) do
        if contribution.amount >= tier.threshold and contribution.tier_reached < i then
            contribution.tier_reached = i
            
            -- Award tier rewards
            local XPSystem = require("src.systems.xp_system")
            if XPSystem then
                XPSystem.addXP(tier.xp, "global_event_tier", 0, 0)
            end
            
            -- Show tier notification
            local UISystem = require("src.ui.ui_system")
            if UISystem then
                UISystem.showEventNotification(
                    "Event Tier Reached: " .. tier.reward,
                    "+" .. tier.xp .. " XP"
                )
            end
        end
    end
end

function GlobalEventsSystem:checkMilestones()
    local progress_percent = (self.current_event.community_progress / self.current_event.community_goal) * 100
    local template = self.current_event.template
    
    -- Check 25%, 50%, 75% milestones
    local milestones = {25, 50, 75}
    for _, milestone in ipairs(milestones) do
        if progress_percent >= milestone and not self.current_event.milestones_reached[milestone] then
            self.current_event.milestones_reached[milestone] = true
            
            -- Show milestone story
            local story_key = "milestone_" .. milestone
            if template.story[story_key] then
                self:showEventNotification(
                    milestone .. "% Complete!",
                    template.story[story_key]
                )
            end
        end
    end
end

function GlobalEventsSystem:completeEvent()
    if self.current_event.completed then return end
    
    self.current_event.completed = true
    self.current_event.completion_time = os.time()
    
    local template = self.current_event.template
    
    -- Show completion notification
    self:showEventNotification(
        "GLOBAL EVENT COMPLETE!",
        template.story.complete
    )
    
    -- Award exclusive rewards to all participants
    for player_id, contribution in pairs(self.current_event.individual_contributions) do
        if contribution.amount > 0 then
            self:awardExclusiveReward(player_id, template.exclusive_reward)
        end
    end
    
    -- Update achievements
    local AchievementSystem = require("src.systems.achievement_system")
    if AchievementSystem then
        AchievementSystem:onGlobalEventComplete()
    end
    
    -- Play celebration
    local SoundManager = require("src.audio.sound_manager")
    if SoundManager then
        SoundManager:playGlobalEventComplete()
    end
end

function GlobalEventsSystem:endCurrentEvent()
    -- Archive event
    table.insert(self.event_history, self.current_event)
    
    -- Start new event after a delay
    self.current_event = nil
    
    -- Wait before starting next event
    love.timer.sleep(3600) -- 1 hour break
    self:startNewEvent()
end

function GlobalEventsSystem:awardExclusiveReward(player_id, reward)
    -- Store exclusive cosmetics
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem then
        SaveSystem.data.exclusive_rewards = SaveSystem.data.exclusive_rewards or {}
        table.insert(SaveSystem.data.exclusive_rewards, {
            type = reward.type,
            value = reward.value,
            cosmetic = reward.cosmetic,
            earned_date = os.time(),
            event_id = self.current_event.id
        })
        SaveSystem.save()
    end
end

function GlobalEventsSystem:showEventNotification(title, message)
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification(title, {1, 0.8, 0, 1})
        
        if message then
            love.timer.sleep(2)
            UISystem.showEventNotification(message, {0.8, 0.8, 0.8, 1})
        end
    end
end

function GlobalEventsSystem:updateLeaderboard()
    -- Sort contributors
    local contributors = {}
    for player_id, contribution in pairs(self.current_event.individual_contributions) do
        table.insert(contributors, {
            player_id = player_id,
            amount = contribution.amount,
            tier = contribution.tier_reached
        })
    end
    
    table.sort(contributors, function(a, b) return a.amount > b.amount end)
    
    -- Keep top 100
    self.current_event.top_contributors = {}
    for i = 1, math.min(100, #contributors) do
        table.insert(self.current_event.top_contributors, contributors[i])
    end
end

function GlobalEventsSystem:getEventInfo()
    if not self.current_event then return nil end
    
    local time_remaining = self.current_event.end_time - os.time()
    local progress_percent = (self.current_event.community_progress / self.current_event.community_goal) * 100
    
    return {
        name = self.current_event.template.name,
        description = self.current_event.template.description,
        community_progress = self.current_event.community_progress,
        community_goal = self.current_event.community_goal,
        progress_percent = progress_percent,
        time_remaining = time_remaining,
        completed = self.current_event.completed,
        player_contribution = self:getPlayerContribution(),
        top_contributors = self.current_event.top_contributors
    }
end

function GlobalEventsSystem:getPlayerContribution(player_id)
    if not self.current_event then return nil end
    
    player_id = player_id or "player"
    local contribution = self.current_event.individual_contributions[player_id]
    
    if not contribution then
        return {
            amount = 0,
            tier_reached = 0,
            next_tier = self.current_event.template.individual_tiers[1]
        }
    end
    
    local next_tier = nil
    if contribution.tier_reached < #self.current_event.template.individual_tiers then
        next_tier = self.current_event.template.individual_tiers[contribution.tier_reached + 1]
    end
    
    return {
        amount = contribution.amount,
        tier_reached = contribution.tier_reached,
        next_tier = next_tier,
        rank = self:getPlayerRank(player_id)
    }
end

function GlobalEventsSystem:getPlayerRank(player_id)
    for i, contributor in ipairs(self.current_event.top_contributors or {}) do
        if contributor.player_id == player_id then
            return i
        end
    end
    return nil
end

function GlobalEventsSystem:saveEventData()
    local save_data = {
        current_event = self.current_event,
        event_history = self.event_history
    }
    
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem then
        SaveSystem.data.global_events = save_data
        SaveSystem.save()
    end
end

function GlobalEventsSystem:loadEventData()
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem and SaveSystem.data.global_events then
        local save_data = SaveSystem.data.global_events
        
        -- Load current event if still active
        if save_data.current_event and os.time() < save_data.current_event.end_time then
            self.current_event = save_data.current_event
        end
        
        self.event_history = save_data.event_history or {}
    end
end

-- Event tracking helpers
function GlobalEventsSystem:onRingsCollected(count)
    if self.current_event and self.current_event.template.track_type == "rings_collected" then
        self:contributeProgress(count)
    end
end

function GlobalEventsSystem:onPlanetDiscovered()
    if self.current_event and self.current_event.template.track_type == "planets_discovered" then
        self:contributeProgress(1)
    end
end

function GlobalEventsSystem:onPerfectLanding()
    if self.current_event and self.current_event.template.track_type == "perfect_landings" then
        self:contributeProgress(1)
    end
end

function GlobalEventsSystem:onLegendaryRingCollected()
    if self.current_event and self.current_event.template.track_type == "legendary_rings" then
        self:contributeProgress(1)
    end
end

return GlobalEventsSystem