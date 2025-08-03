local LeaderboardSystem = {
    boards = {},
    player_ranks = {},
    update_timer = 0,
    update_interval = 30, -- Update every 30 seconds
    animation_queue = {},
}
function LeaderboardSystem:init()
    self.boards = {}
    self.player_ranks = {}
    -- Initialize different leaderboard types
    self:initializeBoards()
    -- Load saved data
    self:loadLeaderboardData()
    -- Generate initial AI players for all boards
    self:populateWithAIPlayers()
end
function LeaderboardSystem:initializeBoards()
    -- Define leaderboard categories with personality
    self.boards = {
        overall = {
            name = "Galactic Champions",
            description = "The ultimate ranking of space explorers",
            icon = "🏆",
            color = {1, 0.8, 0, 1},
            entries = {},
            player_rank = nil,
            update_frequency = "realtime"
        },
        weekly = {
            name = "Rising Stars",
            description = "This week's hottest pilots",
            icon = "⭐",
            color = {0.8, 0, 1, 1},
            entries = {},
            player_rank = nil,
            update_frequency = "daily",
            reset_time = "weekly"
        },
        speed = {
            name = "Speed Demons",
            description = "Fastest galaxy tour completions",
            icon = "⚡",
            color = {0, 1, 1, 1},
            entries = {},
            player_rank = nil,
            update_frequency = "immediate",
            special_effect = "lightning"
        },
        perfection = {
            name = "Perfect Pilots",
            description = "Masters of precision and control",
            icon = "🎯",
            color = {1, 0.4, 0.4, 1},
            entries = {},
            player_rank = nil,
            update_frequency = "realtime",
            requirement = "50+ perfect landings"
        },
        explorers = {
            name = "Void Wanderers",
            description = "Discovered the most planets",
            icon = "🌌",
            color = {0.5, 0, 1, 1},
            entries = {},
            player_rank = nil,
            update_frequency = "hourly"
        },
        collectors = {
            name = "Ring Lords",
            description = "Amassed the greatest ring fortunes",
            icon = "💍",
            color = {1, 1, 0, 1},
            entries = {},
            player_rank = nil,
            update_frequency = "realtime",
            special_badge = "ring_counter"
        }
    }
end
function LeaderboardSystem:populateWithAIPlayers()
    -- AI player templates with personalities
    local ai_templates = {
        -- Speed demons
        { name = "FlashGordon", personality = "speed", emoji = "🏃", skill = 0.9 },
        { name = "LightningBolt", personality = "speed", emoji = "⚡", skill = 0.85 },
        { name = "SonicBoom", personality = "speed", emoji = "💨", skill = 0.8 },
        -- Perfectionists
        { name = "PixelPerfect", personality = "precision", emoji = "🎯", skill = 0.95 },
        { name = "ZenMaster", personality = "precision", emoji = "🧘", skill = 0.88 },
        { name = "TheCalculator", personality = "precision", emoji = "🤖", skill = 0.82 },
        -- Explorers
        { name = "StarSeeker", personality = "explorer", emoji = "🔭", skill = 0.87 },
        { name = "VoidDancer", personality = "explorer", emoji = "🌌", skill = 0.9 },
        { name = "CosmicNomad", personality = "explorer", emoji = "🚀", skill = 0.83 },
        -- Collectors
        { name = "GoldDigger", personality = "collector", emoji = "⛏️", skill = 0.86 },
        { name = "TreasureHunter", personality = "collector", emoji = "🗝️", skill = 0.91 },
        { name = "RingKing", personality = "collector", emoji = "👑", skill = 0.94 },
        -- All-rounders
        { name = "ProGamer2024", personality = "balanced", emoji = "🎮", skill = 0.88 },
        { name = "SpaceAce", personality = "balanced", emoji = "♠️", skill = 0.92 },
        { name = "NoobMaster69", personality = "balanced", emoji = "😎", skill = 0.75 },
        { name = "xXDarkLordXx", personality = "balanced", emoji = "💀", skill = 0.84 },
        { name = "CasualCarla", personality = "balanced", emoji = "😊", skill = 0.65 },
        { name = "TryHardTim", personality = "balanced", emoji = "😤", skill = 0.89 }
    }
    -- Generate scores and add to appropriate boards
    for _, template in ipairs(ai_templates) do
        local player = self:generateAIPlayer(template)
        self:addPlayerToBoards(player)
    end
end
function LeaderboardSystem:generateAIPlayer(template)
    local base_score = 10000 * template.skill
    local variance = 0.2
    return {
        id = "ai_" .. template.name,
        name = template.name,
        emoji = template.emoji,
        personality = template.personality,
        is_ai = true,
        scores = {
            overall = math.floor(base_score * (1 + (math.random() - 0.5) * variance)),
            weekly = math.floor(base_score * 0.3 * (1 + (math.random() - 0.5) * variance)),
            speed = template.personality == "speed" and math.floor(90 + template.skill * 30) or math.floor(120 + (1 - template.skill) * 60),
            perfection = template.personality == "precision" and math.floor(100 * template.skill) or math.floor(50 * template.skill),
            explorers = template.personality == "explorer" and math.floor(50 * template.skill) or math.floor(25 * template.skill),
            collectors = template.personality == "collector" and math.floor(5000 * template.skill) or math.floor(2500 * template.skill)
        },
        status = self:generateStatus(template.personality),
        last_seen = os.time() - math.random(0, 3600), -- Within last hour
        trending = math.random() > 0.7 -- 30% chance of trending
    }
end
function LeaderboardSystem:generateStatus(personality)
    local statuses = {
        speed = {
            "Gotta go fast! 🏃",
            "Breaking sound barriers 💨",
            "Speed is life ⚡",
            "Can't stop won't stop 🚀"
        },
        precision = {
            "Perfection is the goal 🎯",
            "Every landing counts ✨",
            "Precision over speed 🧘",
            "Calculated movements only 📐"
        },
        explorer = {
            "To infinity and beyond! 🌌",
            "New worlds await 🔭",
            "The void calls to me 👻",
            "Charting the unknown 🗺️"
        },
        collector = {
            "All rings must be mine! 💍",
            "Collecting is life 💎",
            "Ring hoarder and proud 🏆",
            "Never enough rings! 🤑"
        },
        balanced = {
            "Just vibing in space 😎",
            "Another day, another planet 🌍",
            "Living my best space life ✨",
            "GG everyone! 🎮"
        }
    }
    local pool = statuses[personality] or statuses.balanced
    return pool[math.random(#pool)]
end
function LeaderboardSystem:addPlayerToBoards(player)
    -- Add to each board based on scores
    for board_id, board in pairs(self.boards) do
        if player.scores[board_id] and player.scores[board_id] > 0 then
            table.insert(board.entries, {
                player_id = player.id,
                name = player.name,
                emoji = player.emoji,
                score = player.scores[board_id],
                is_ai = player.is_ai,
                status = player.status,
                last_seen = player.last_seen,
                trending = player.trending,
                rank_change = 0
            })
        end
    end
end
function LeaderboardSystem:update(dt, player_stats)
    self.update_timer = self.update_timer + dt
    -- Process animation queue
    self:updateAnimations(dt)
    -- Periodic updates
    if self.update_timer >= self.update_interval then
        self.update_timer = 0
        -- Update player scores
        self:updatePlayerScores(player_stats)
        -- Sort and update ranks
        self:updateAllBoards()
        -- Check for rank changes
        self:checkRankChanges()
        -- Update AI player activity
        self:updateAIActivity()
    end
end
function LeaderboardSystem:updatePlayerScores(player_stats)
    local player_id = "player"
    -- Calculate scores for each board
    local scores = {
        overall = player_stats.total_score or 0,
        weekly = player_stats.weekly_score or 0,
        speed = player_stats.best_time or 999,
        perfection = player_stats.perfect_landings or 0,
        explorers = player_stats.planets_discovered or 0,
        collectors = player_stats.rings_collected or 0
    }
    -- Update or add player entry
    for board_id, board in pairs(self.boards) do
        local found = false
        for i, entry in ipairs(board.entries) do
            if entry.player_id == player_id then
                local old_score = entry.score
                entry.score = scores[board_id]
                entry.last_seen = os.time()
                entry.score_change = entry.score - old_score
                found = true
                break
            end
        end
        if not found and scores[board_id] > 0 then
            table.insert(board.entries, {
                player_id = player_id,
                name = "You",
                emoji = "🎮",
                score = scores[board_id],
                is_ai = false,
                status = "Playing right now! 🎯",
                last_seen = os.time(),
                trending = true,
                rank_change = 0
            })
        end
    end
end
function LeaderboardSystem:updateAllBoards()
    for board_id, board in pairs(self.boards) do
        -- Store old ranks
        local old_ranks = {}
        for i, entry in ipairs(board.entries) do
            old_ranks[entry.player_id] = i
        end
        -- Sort by score
        if board_id == "speed" then
            -- Lower is better for speed
            table.sort(board.entries, function(a, b) return a.score < b.score end)
        else
            -- Higher is better for others
            table.sort(board.entries, function(a, b) return a.score > b.score end)
        end
        -- Update rank changes
        for i, entry in ipairs(board.entries) do
            local old_rank = old_ranks[entry.player_id]
            if old_rank then
                entry.rank_change = old_rank - i
            end
            -- Update player rank
            if entry.player_id == "player" then
                board.player_rank = i
            end
        end
    end
end
function LeaderboardSystem:checkRankChanges()
    local player_id = "player"
    for board_id, board in pairs(self.boards) do
        for i, entry in ipairs(board.entries) do
            if entry.player_id == player_id and entry.rank_change ~= 0 then
                -- Player rank changed!
                if entry.rank_change > 0 then
                    self:onRankImproved(board_id, i, entry.rank_change)
                else
                    self:onRankDeclined(board_id, i, entry.rank_change)
                end
            end
        end
    end
end
function LeaderboardSystem:onRankImproved(board_id, new_rank, change)
    local board = self.boards[board_id]
    -- Special messages for reaching top positions
    local message = ""
    if new_rank == 1 then
        message = "NEW #1 on " .. board.name .. "! 👑"
    elseif new_rank <= 3 then
        message = "Top 3 on " .. board.name .. "! 🏆"
    elseif new_rank <= 10 then
        message = "Top 10 on " .. board.name .. "! ⭐"
    else
        message = "Climbed " .. change .. " ranks on " .. board.name .. "! 📈"
    end
    -- Show notification
    local UISystem = require("src.ui.ui_system")
    if UISystem then
        UISystem.showEventNotification(message, board.color)
    end
    -- Add animation
    table.insert(self.animation_queue, {
        type = "rank_up",
        board_id = board_id,
        rank = new_rank,
        timer = 0,
        duration = 2.0
    })
end
function LeaderboardSystem:updateAIActivity()
    -- Simulate AI player activity
    for _, board in pairs(self.boards) do
        for _, entry in ipairs(board.entries) do
            if entry.is_ai then
                -- Random score changes
                if math.random() > 0.8 then
                    local change = math.random(-5, 10)
                    if board.name == "speed" then
                        entry.score = math.max(30, entry.score - change * 0.1)
                    else
                        entry.score = entry.score + change
                    end
                end
                -- Update last seen
                if math.random() > 0.5 then
                    entry.last_seen = os.time() - math.random(0, 3600)
                end
                -- Update trending
                entry.trending = math.random() > 0.7
                -- Occasionally change status
                if math.random() > 0.9 then
                    local player = nil
                    for _, p in ipairs(self.player_pool or {}) do
                        if p.id == entry.player_id then
                            player = p
                            break
                        end
                    end
                    if player then
                        entry.status = self:generateStatus(player.personality)
                    end
                end
            end
        end
    end
end
function LeaderboardSystem:updateAnimations(dt)
    for i = #self.animation_queue, 1, -1 do
        local anim = self.animation_queue[i]
        anim.timer = anim.timer + dt
        if anim.timer >= anim.duration then
            table.remove(self.animation_queue, i)
        end
    end
end
function LeaderboardSystem:getLeaderboard(board_id, range)
    local board = self.boards[board_id]
    if not board then return nil end
    range = range or 20 -- Default to top 20
    local result = {
        name = board.name,
        description = board.description,
        icon = board.icon,
        color = board.color,
        player_rank = board.player_rank,
        entries = {}
    }
    -- Get entries around player if they're not in top range
    local start_index = 1
    local end_index = math.min(range, #board.entries)
    if board.player_rank and board.player_rank > range - 3 then
        -- Show players around the player
        start_index = math.max(1, board.player_rank - 3)
        end_index = math.min(#board.entries, board.player_rank + 3)
    end
    for i = start_index, end_index do
        local entry = board.entries[i]
        if entry then
            table.insert(result.entries, {
                rank = i,
                player_id = entry.player_id,
                name = entry.name,
                emoji = entry.emoji,
                score = entry.score,
                is_ai = entry.is_ai,
                is_player = entry.player_id == "player",
                status = entry.status,
                last_seen = entry.last_seen,
                trending = entry.trending,
                rank_change = entry.rank_change
            })
        end
    end
    return result
end
function LeaderboardSystem:getPlayerComparison(board_id)
    local board = self.boards[board_id]
    if not board or not board.player_rank then return nil end
    local player_entry = board.entries[board.player_rank]
    if not player_entry then return nil end
    local comparison = {
        player_rank = board.player_rank,
        player_score = player_entry.score,
        ahead = nil,
        behind = nil
    }
    -- Get player ahead
    if board.player_rank > 1 then
        local ahead = board.entries[board.player_rank - 1]
        comparison.ahead = {
            name = ahead.name,
            emoji = ahead.emoji,
            score = ahead.score,
            difference = math.abs(ahead.score - player_entry.score),
            catchable = math.abs(ahead.score - player_entry.score) < player_entry.score * 0.1
        }
    end
    -- Get player behind
    if board.player_rank < #board.entries then
        local behind = board.entries[board.player_rank + 1]
        comparison.behind = {
            name = behind.name,
            emoji = behind.emoji,
            score = behind.score,
            difference = math.abs(player_entry.score - behind.score),
            catching_up = behind.trending and behind.rank_change > 0
        }
    end
    return comparison
end
function LeaderboardSystem:saveLeaderboardData()
    local save_data = {
        boards = {},
        player_ranks = self.player_ranks
    }
    -- Save limited data to avoid huge save files
    for board_id, board in pairs(self.boards) do
        save_data.boards[board_id] = {
            player_rank = board.player_rank,
            top_10 = {}
        }
        -- Save top 10 entries
        for i = 1, math.min(10, #board.entries) do
            table.insert(save_data.boards[board_id].top_10, board.entries[i])
        end
    end
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem then
        SaveSystem.data.leaderboards = save_data
        SaveSystem.save()
    end
end
function LeaderboardSystem:loadLeaderboardData()
    local SaveSystem = require("src.systems.save_system")
    if SaveSystem and SaveSystem.data.leaderboards then
        local save_data = SaveSystem.data.leaderboards
        -- Restore player ranks
        for board_id, board_data in pairs(save_data.boards or {}) do
            if self.boards[board_id] then
                self.boards[board_id].player_rank = board_data.player_rank
            end
        end
        self.player_ranks = save_data.player_ranks or {}
    end
end
return LeaderboardSystem