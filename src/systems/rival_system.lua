local RivalSystem = {
    current_rival = nil,
    rival_history = {},
    matchmaking_pool = {},
    update_timer = 0,
    update_interval = 60, -- Check for new rival every 60 seconds
    performance_window = 300, -- Track last 5 minutes of performance
}
function RivalSystem:init()
    self.current_rival = nil
    self.rival_history = {}
    self.matchmaking_pool = {}
    self.update_timer = 0
    -- Initialize with some AI rivals for immediate engagement
    self:createAIRivals()
    -- Load saved rival data
    self:loadRivalData()
end
function RivalSystem:createAIRivals()
    -- Create AI rivals with different skill levels and personalities
    local ai_rivals = {
        {
            id = "ai_rookie",
            name = "Space Cadet Sam",
            avatar = "🚀",
            score = 1000,
            skill_level = 0.8,
            personality = "friendly",
            taunt = "Great job! You're getting better!",
            defeat_message = "Wow, you beat me! Time to practice more!"
        },
        {
            id = "ai_challenger",
            name = "Captain Nova",
            avatar = "⭐",
            score = 5000,
            skill_level = 1.1,
            personality = "competitive",
            taunt = "Think you can keep up with me?",
            defeat_message = "Not bad! You've earned my respect."
        },
        {
            id = "ai_expert",
            name = "Void Walker X",
            avatar = "👾",
            score = 10000,
            skill_level = 1.3,
            personality = "mysterious",
            taunt = "The void calls... can you answer?",
            defeat_message = "Impressive... you understand the void."
        },
        {
            id = "ai_master",
            name = "Nebula Queen",
            avatar = "👑",
            score = 25000,
            skill_level = 1.5,
            personality = "regal",
            taunt = "Many have tried, few have succeeded.",
            defeat_message = "A new champion rises. Well done."
        },
        {
            id = "ai_legend",
            name = "The Eternal",
            avatar = "∞",
            score = 50000,
            skill_level = 2.0,
            personality = "philosophical",
            taunt = "Time is but a circle... can you break it?",
            defeat_message = "The cycle continues... through you."
        }
    }
    for _, rival in ipairs(ai_rivals) do
        rival.is_ai = true
        rival.recent_scores = self:generateRecentScores(rival.score, rival.skill_level)
        rival.achievements = math.floor(rival.score / 1000)
        rival.playtime = rival.score / 10
        table.insert(self.matchmaking_pool, rival)
    end
end
function RivalSystem:generateRecentScores(base_score, skill_level)
    local scores = {}
    for i = 1, 10 do
        local variance = 0.1 + (1 - skill_level) * 0.2
        local score = base_score * (1 + (math.random() - 0.5) * variance)
        table.insert(scores, math.floor(score))
    end
    return scores
end
function RivalSystem:findRival(player_stats)
    -- Calculate player's performance score
    local player_score = self:calculatePerformanceScore(player_stats)
    -- Find rival ~5% better than player
    local target_score = player_score * 1.05
    local best_match = nil
    local best_diff = math.huge
    for _, rival in ipairs(self.matchmaking_pool) do
        local rival_score = self:calculateRivalScore(rival)
        local diff = math.abs(rival_score - target_score)
        -- Prefer rivals slightly better than player
        if rival_score > player_score and diff < best_diff then
            best_match = rival
            best_diff = diff
        end
    end
    -- If no better rival found, pick closest match
    if not best_match then
        for _, rival in ipairs(self.matchmaking_pool) do
            local rival_score = self:calculateRivalScore(rival)
            local diff = math.abs(rival_score - player_score)
            if diff < best_diff then
                best_match = rival
                best_diff = diff
            end
        end
    end
    return best_match
end
function RivalSystem:calculatePerformanceScore(stats)
    -- Weighted score based on various metrics
    local score = 0
    score = score + stats.total_score * 1.0
    score = score + stats.perfect_landings * 100
    score = score + stats.max_combo * 50
    score = score + stats.planets_discovered * 200
    score = score + stats.achievements_unlocked * 150
    score = score + stats.legendary_rings * 500
    return score
end
function RivalSystem:calculateRivalScore(rival)
    if rival.is_ai then
        return rival.score
    end
    -- For real players, calculate based on recent performance
    local total = 0
    for _, score in ipairs(rival.recent_scores or {}) do
        total = total + score
    end
    return total / math.max(1, #(rival.recent_scores or {}))
end
function RivalSystem:setRival(rival)
    -- Save previous rival to history (with bounds checking)
    if self.current_rival then
        table.insert(self.rival_history, {
            rival = self.current_rival,
            timestamp = love.timer.getTime(),
            defeated = self.current_rival.defeated or false
        })
        -- Limit history to last 50 rivals
        local MAX_RIVAL_HISTORY = 50
        if #self.rival_history > MAX_RIVAL_HISTORY then
            -- Remove oldest entries
            local toRemove = #self.rival_history - MAX_RIVAL_HISTORY
            for i = 1, toRemove do
                table.remove(self.rival_history, 1)
            end
        end
    end
    self.current_rival = rival
    self.current_rival.defeated = false
    self.current_rival.challenge_start = love.timer.getTime()
    -- Show notification
    self:showRivalNotification("New Rival: " .. rival.name)
    -- Play rival encounter sound
    local SoundManager = require("src.audio.sound_manager")
    if SoundManager then
        SoundManager:playRivalEncounter()
    end
end
function RivalSystem:update(dt, player_stats)
    self.update_timer = self.update_timer + dt
    -- Periodically check for new rival
    if self.update_timer >= self.update_interval then
        self.update_timer = 0
        -- Find new rival if current one is defeated or too easy/hard
        if not self.current_rival or self.current_rival.defeated or
           self:shouldChangeRival(player_stats) then
            local new_rival = self:findRival(player_stats)
            if new_rival and new_rival ~= self.current_rival then
                self:setRival(new_rival)
            end
        end
    end
    -- Check if player surpassed rival
    if self.current_rival and not self.current_rival.defeated then
        local player_score = self:calculatePerformanceScore(player_stats)
        local rival_score = self:calculateRivalScore(self.current_rival)
        if player_score > rival_score then
            self:defeatRival()
        end
    end
end
function RivalSystem:shouldChangeRival(player_stats)
    if not self.current_rival then return true end
    local player_score = self:calculatePerformanceScore(player_stats)
    local rival_score = self:calculateRivalScore(self.current_rival)
    -- Change if rival is too easy (player is 20% better)
    if player_score > rival_score * 1.2 then
        return true
    end
    -- Change if rival is too hard (rival is 30% better)
    if rival_score > player_score * 1.3 then
        return true
    end
    return false
end
function RivalSystem:defeatRival()
    if not self.current_rival or self.current_rival.defeated then return end
    self.current_rival.defeated = true
    -- Show victory notification
    self:showRivalNotification("Rival Defeated: " .. self.current_rival.name .. "!")
    -- Show rival's defeat message
    if self.current_rival.defeat_message then
        self:showRivalMessage(self.current_rival.defeat_message)
    end
    -- Award bonus XP
    local XPSystem = require("src.systems.xp_system")
    if XPSystem then
        XPSystem.addXP(500, "rival_defeated", 0, 0)
    end
    -- Update achievement progress
    local AchievementSystem = require("src.systems.achievement_system")
    if AchievementSystem then
        AchievementSystem:onRivalDefeated()
    end
    -- Play victory sound
    local SoundManager = require("src.audio.sound_manager")
    if SoundManager then
        SoundManager:playRivalDefeat()
    end
end
function RivalSystem:showRivalNotification(message)
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification(message, {1, 0.5, 0, 1})
    end
end
function RivalSystem:showRivalMessage(message)
    -- Show rival's message in chat/notification area
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification(self.current_rival.name .. ": " .. message, {0.8, 0.8, 0.8, 1})
    end
end
function RivalSystem:getRivalInfo()
    if not self.current_rival then return nil end
    return {
        name = self.current_rival.name,
        avatar = self.current_rival.avatar,
        score = self:calculateRivalScore(self.current_rival),
        defeated = self.current_rival.defeated,
        personality = self.current_rival.personality,
        is_online = self.current_rival.is_online or self.current_rival.is_ai
    }
end
function RivalSystem:getRivalProgress(player_stats)
    if not self.current_rival then return nil end
    local player_score = self:calculatePerformanceScore(player_stats)
    local rival_score = self:calculateRivalScore(self.current_rival)
    return {
        player_score = player_score,
        rival_score = rival_score,
        progress = player_score / rival_score,
        difference = rival_score - player_score
    }
end
function RivalSystem:addPlayerToPool(player_data)
    -- Add real player to matchmaking pool
    local player = {
        id = player_data.id,
        name = player_data.name,
        avatar = player_data.avatar or "🎮",
        recent_scores = player_data.recent_scores or {},
        achievements = player_data.achievements or 0,
        playtime = player_data.playtime or 0,
        is_online = player_data.is_online or false,
        personality = "player"
    }
    table.insert(self.matchmaking_pool, player)
end
function RivalSystem:updatePlayerInPool(player_id, data)
    for _, player in ipairs(self.matchmaking_pool) do
        if player.id == player_id then
            for key, value in pairs(data) do
                player[key] = value
            end
            break
        end
    end
end
function RivalSystem:saveRivalData()
    local save_data = {
        current_rival = self.current_rival,
        rival_history = self.rival_history
    }
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem then
        SaveSystem.data.rivals = save_data
        SaveSystem.save()
    end
end
function RivalSystem:loadRivalData()
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem and SaveSystem.data.rivals then
        local save_data = SaveSystem.data.rivals
        if save_data.current_rival then
            self.current_rival = save_data.current_rival
        end
        if save_data.rival_history then
            self.rival_history = save_data.rival_history
        end
    end
end
return RivalSystem