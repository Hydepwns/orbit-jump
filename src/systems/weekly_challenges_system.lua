local WeeklyChallengesSystem = {
    active_challenges = {},
    completed_challenges = {},
    current_week = 0,
    challenge_templates = {},
    story_context = {},
    refresh_timer = 0,
    refresh_interval = 604800, -- 7 days in seconds
}
function WeeklyChallengesSystem:init()
    self.active_challenges = {}
    self.completed_challenges = {}
    self.current_week = self:getCurrentWeek()
    -- Define challenge templates with narrative context
    self:defineChallengeTemplates()
    self:defineStoryContexts()
    -- Generate this week's challenges
    self:generateWeeklyChallenges()
    -- Load saved progress
    self:loadProgress()
end
function WeeklyChallengesSystem:defineChallengeTemplates()
    self.challenge_templates = {
        -- Collection challenges
        {
            id = "ring_shortage",
            name = "The Great Ring Shortage",
            description = "Collect {target} rings this week",
            type = "collect_rings",
            base_target = 1000,
            target_variance = 0.2,
            difficulty = "medium",
            reward_xp = 500,
            reward_currency = 100,
            story_intro = "A mysterious cosmic storm has scattered rings across the galaxy...",
            story_complete = "Thanks to your efforts, the ring balance has been restored!"
        },
        {
            id = "legendary_hunt",
            name = "The Legendary Hunt",
            description = "Find {target} legendary rings",
            type = "collect_legendary",
            base_target = 5,
            target_variance = 0,
            difficulty = "hard",
            reward_xp = 1000,
            reward_currency = 250,
            story_intro = "Ancient legends speak of golden rings with immense power...",
            story_complete = "The legendary rings have been secured. Their power is yours!"
        },
        -- Exploration challenges
        {
            id = "planet_explorer",
            name = "Uncharted Territories",
            description = "Discover {target} new planets",
            type = "discover_planets",
            base_target = 15,
            target_variance = 0.3,
            difficulty = "medium",
            reward_xp = 600,
            reward_currency = 150,
            story_intro = "New sectors have opened up for exploration. Be the first to chart them!",
            story_complete = "Your exploration data will help future travelers navigate safely."
        },
        {
            id = "void_expedition",
            name = "Into the Void",
            description = "Visit {target} void planets without failing",
            type = "visit_void_planets",
            base_target = 5,
            target_variance = 0,
            difficulty = "hard",
            reward_xp = 800,
            reward_currency = 200,
            story_intro = "The void whispers secrets to those brave enough to enter...",
            story_complete = "You've mastered the void. Its secrets are now yours."
        },
        -- Skill challenges
        {
            id = "precision_master",
            name = "Precision Protocol",
            description = "Achieve {target} perfect landings",
            type = "perfect_landings",
            base_target = 50,
            target_variance = 0.2,
            difficulty = "medium",
            reward_xp = 700,
            reward_currency = 175,
            story_intro = "The Galactic Navigation Authority needs pilots with perfect precision...",
            story_complete = "Your precision skills have earned you elite pilot status!"
        },
        {
            id = "combo_crisis",
            name = "The Combo Cascade",
            description = "Reach a {target}x combo",
            type = "max_combo",
            base_target = 30,
            target_variance = 0.15,
            difficulty = "hard",
            reward_xp = 900,
            reward_currency = 225,
            story_intro = "Scientists believe sustained combos can open dimensional rifts...",
            story_complete = "Incredible! Your combo mastery has proven the theory correct!"
        },
        {
            id = "speed_trials",
            name = "Velocity Trials",
            description = "Complete {target} dash sequences",
            type = "dash_sequences",
            base_target = 100,
            target_variance = 0.25,
            difficulty = "easy",
            reward_xp = 400,
            reward_currency = 80,
            story_intro = "The annual Velocity Trials have begun. Show your speed!",
            story_complete = "Your incredible speed has made you a champion of the trials!"
        },
        -- Event challenges
        {
            id = "mystery_collector",
            name = "Box of Mysteries",
            description = "Open {target} mystery boxes",
            type = "open_mystery_boxes",
            base_target = 10,
            target_variance = 0,
            difficulty = "medium",
            reward_xp = 750,
            reward_currency = 200,
            story_intro = "Strange boxes have appeared across the galaxy. What secrets do they hold?",
            story_complete = "The mysteries have been revealed, granting you ancient knowledge!"
        },
        {
            id = "event_master",
            name = "Chaos Controller",
            description = "Experience {target} random events",
            type = "experience_events",
            base_target = 20,
            target_variance = 0.2,
            difficulty = "medium",
            reward_xp = 650,
            reward_currency = 160,
            story_intro = "Cosmic anomalies are increasing. Help us study these phenomena!",
            story_complete = "Your data on cosmic events has advanced our understanding greatly!"
        }
    }
end
function WeeklyChallengesSystem:defineStoryContexts()
    -- Weekly rotating story themes
    self.story_context = {
        {
            week_title = "The Cosmic Storm Saga",
            description = "A massive cosmic storm threatens the galaxy's stability",
            challenges_focus = {"collection", "survival"}
        },
        {
            week_title = "The Explorer's Guild",
            description = "Join the prestigious Explorer's Guild in charting new territories",
            challenges_focus = {"exploration", "discovery"}
        },
        {
            week_title = "The Precision Games",
            description = "The galaxy's greatest pilots compete in skill challenges",
            challenges_focus = {"skill", "precision"}
        },
        {
            week_title = "The Mystery of the Ancients",
            description = "Ancient artifacts and mysterious phenomena appear across space",
            challenges_focus = {"mystery", "events"}
        }
    }
end
function WeeklyChallengesSystem:getCurrentWeek()
    -- Calculate week number since game launch
    local launch_time = 1704067200 -- Jan 1, 2024
    local current_time = os.time()
    return math.floor((current_time - launch_time) / 604800)
end
function WeeklyChallengesSystem:generateWeeklyChallenges()
    self.active_challenges = {}
    -- Get this week's story context
    local context_index = (self.current_week % #self.story_context) + 1
    local weekly_context = self.story_context[context_index]
    -- Select 3 challenges that fit the story
    local selected_challenges = {}
    local used_types = {}
    -- Ensure variety in challenge types
    local challenge_pools = {
        easy = {},
        medium = {},
        hard = {}
    }
    for _, template in ipairs(self.challenge_templates) do
        table.insert(challenge_pools[template.difficulty], template)
    end
    -- Select one of each difficulty
    for difficulty, pool in pairs(challenge_pools) do
        if #pool > 0 then
            local index = (self.current_week + #selected_challenges) % #pool + 1
            local template = pool[index]
            -- Create challenge instance
            local challenge = self:createChallengeFromTemplate(template)
            challenge.week = self.current_week
            challenge.story_context = weekly_context.week_title
            table.insert(selected_challenges, challenge)
        end
    end
    self.active_challenges = selected_challenges
    self.weekly_story = weekly_context
end
function WeeklyChallengesSystem:createChallengeFromTemplate(template)
    -- Apply variance to target
    local variance = template.target_variance
    local target = template.base_target
    if variance > 0 then
        target = math.floor(target * (1 + (math.random() - 0.5) * variance))
    end
    return {
        id = template.id .. "_week_" .. self.current_week,
        template_id = template.id,
        name = template.name,
        description = template.description:gsub("{target}", tostring(target)),
        type = template.type,
        target = target,
        progress = 0,
        completed = false,
        difficulty = template.difficulty,
        reward_xp = template.reward_xp,
        reward_currency = template.reward_currency,
        story_intro = template.story_intro,
        story_complete = template.story_complete,
        time_remaining = self:getTimeRemaining()
    }
end
function WeeklyChallengesSystem:getTimeRemaining()
    local seconds_in_week = 604800
    local week_progress = os.time() % seconds_in_week
    return seconds_in_week - week_progress
end
function WeeklyChallengesSystem:update(dt)
    self.refresh_timer = self.refresh_timer + dt
    -- Check if week has changed
    local current_week = self:getCurrentWeek()
    if current_week ~= self.current_week then
        self:onWeekChange()
    end
    -- Update time remaining for active challenges
    for _, challenge in ipairs(self.active_challenges) do
        challenge.time_remaining = self:getTimeRemaining()
    end
end
function WeeklyChallengesSystem:onWeekChange()
    -- Archive completed challenges
    for _, challenge in ipairs(self.active_challenges) do
        if challenge.completed then
            table.insert(self.completed_challenges, challenge)
        end
    end
    -- Generate new challenges
    self.current_week = self:getCurrentWeek()
    self:generateWeeklyChallenges()
    -- Show notification
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification("New Weekly Challenges Available!", {0, 1, 1, 1})
    end
    -- Save progress
    self:saveProgress()
end
function WeeklyChallengesSystem:updateProgress(challenge_type, amount)
    for _, challenge in ipairs(self.active_challenges) do
        if challenge.type == challenge_type and not challenge.completed then
            challenge.progress = math.min(challenge.progress + amount, challenge.target)
            -- Check completion
            if challenge.progress >= challenge.target then
                self:completeChallenge(challenge)
            end
            return challenge
        end
    end
end
function WeeklyChallengesSystem:completeChallenge(challenge)
    if challenge.completed then return end
    challenge.completed = true
    challenge.completion_time = os.time()
    -- Award rewards
    local XPSystem = require("src.systems.xp_system")
    if XPSystem then
        XPSystem.addXP(challenge.reward_xp, "weekly_challenge", 0, 0)
    end
    local UpgradeSystem = require("src.systems.upgrade_system")
    if UpgradeSystem then
        UpgradeSystem.addCurrency(challenge.reward_currency)
    end
    -- Show completion notification with story
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification("Challenge Complete: " .. challenge.name, {1, 0.8, 0, 1})
        -- Show story completion after a delay
        love.timer.sleep(2)
        UISystem.showEventNotification(challenge.story_complete, {0.8, 0.8, 0.8, 1})
    end
    -- Update achievements
    local AchievementSystem = require("src.systems.achievement_system")
    if AchievementSystem then
        AchievementSystem:onWeeklyChallengeComplete()
    end
    -- Save progress
    self:saveProgress()
end
function WeeklyChallengesSystem:getChallengeInfo()
    local challenges = {}
    for _, challenge in ipairs(self.active_challenges) do
        table.insert(challenges, {
            name = challenge.name,
            description = challenge.description,
            progress = challenge.progress,
            target = challenge.target,
            percentage = challenge.progress / challenge.target,
            completed = challenge.completed,
            difficulty = challenge.difficulty,
            reward_xp = challenge.reward_xp,
            reward_currency = challenge.reward_currency,
            time_remaining = challenge.time_remaining,
            story_intro = challenge.story_intro
        })
    end
    return {
        week_title = self.weekly_story and self.weekly_story.week_title or "Weekly Challenges",
        week_description = self.weekly_story and self.weekly_story.description or "",
        challenges = challenges,
        time_remaining = self:getTimeRemaining()
    }
end
function WeeklyChallengesSystem:saveProgress()
    local save_data = {
        current_week = self.current_week,
        active_challenges = self.active_challenges,
        completed_challenges = self.completed_challenges
    }
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem then
        SaveSystem.data.weekly_challenges = save_data
        SaveSystem.save()
    end
end
function WeeklyChallengesSystem:loadProgress()
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem and SaveSystem.data.weekly_challenges then
        local save_data = SaveSystem.data.weekly_challenges
        -- Only load if same week
        if save_data.current_week == self.current_week then
            self.active_challenges = save_data.active_challenges or self.active_challenges
        end
        self.completed_challenges = save_data.completed_challenges or {}
    end
end
-- Helper functions for tracking different challenge types
function WeeklyChallengesSystem:onRingsCollected(count)
    self:updateProgress("collect_rings", count)
end
function WeeklyChallengesSystem:onLegendaryRingCollected()
    self:updateProgress("collect_legendary", 1)
end
function WeeklyChallengesSystem:onPlanetDiscovered()
    self:updateProgress("discover_planets", 1)
end
function WeeklyChallengesSystem:onVoidPlanetVisited()
    self:updateProgress("visit_void_planets", 1)
end
function WeeklyChallengesSystem:onPerfectLanding()
    self:updateProgress("perfect_landings", 1)
end
function WeeklyChallengesSystem:onComboReached(combo)
    local challenge = self:updateProgress("max_combo", 0)
    if challenge and combo > challenge.progress then
        challenge.progress = combo
    end
end
function WeeklyChallengesSystem:onDashSequence()
    self:updateProgress("dash_sequences", 1)
end
function WeeklyChallengesSystem:onMysteryBoxOpened()
    self:updateProgress("open_mystery_boxes", 1)
end
function WeeklyChallengesSystem:onRandomEventExperienced()
    self:updateProgress("experience_events", 1)
end
return WeeklyChallengesSystem