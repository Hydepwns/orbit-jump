-- Test suite for Leaderboard System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup
Mocks.setup()
TestFramework.init()
-- Load system
local LeaderboardSystem = Utils.require("src.systems.leaderboard_system")
-- Test helper functions
local function setupSystem()
    -- Reset system state
    LeaderboardSystem.boards = {}
    LeaderboardSystem.player_ranks = {}
    LeaderboardSystem.update_timer = 0
    LeaderboardSystem.update_interval = 30
    LeaderboardSystem.animation_queue = {}
end
local function createMockPlayerStats()
    return {
        total_score = 15000,
        weekly_score = 5000,
        best_time = 120,
        perfect_landings = 35,
        planets_discovered = 12,
        rings_collected = 2500
    }
end
-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        LeaderboardSystem:init()
        TestFramework.assert(type(LeaderboardSystem.boards) == "table", "Should have boards table")
        TestFramework.assert(type(LeaderboardSystem.player_ranks) == "table", "Should have player ranks table")
        TestFramework.assert(LeaderboardSystem.update_timer == 0, "Timer should be reset")
        -- Check that boards were initialized
        TestFramework.assert(LeaderboardSystem.boards.overall ~= nil, "Should have overall board")
        TestFramework.assert(LeaderboardSystem.boards.weekly ~= nil, "Should have weekly board")
        TestFramework.assert(LeaderboardSystem.boards.speed ~= nil, "Should have speed board")
        TestFramework.assert(LeaderboardSystem.boards.perfection ~= nil, "Should have perfection board")
        TestFramework.assert(LeaderboardSystem.boards.explorers ~= nil, "Should have explorers board")
        TestFramework.assert(LeaderboardSystem.boards.collectors ~= nil, "Should have collectors board")
    end,
    ["board initialization"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        TestFramework.assert(#LeaderboardSystem.boards == 6, "Should have 6 leaderboard categories")
        -- Check overall board structure
        local overall = LeaderboardSystem.boards.overall
        TestFramework.assert(overall.name == "Galactic Champions", "Should have correct name")
        TestFramework.assert(overall.description == "The ultimate ranking of space explorers", "Should have description")
        TestFramework.assert(overall.icon == "🏆", "Should have icon")
        TestFramework.assert(type(overall.color) == "table", "Should have color")
        TestFramework.assert(type(overall.entries) == "table", "Should have entries array")
        TestFramework.assert(overall.update_frequency == "realtime", "Should have update frequency")
        -- Check speed board (different sorting)
        local speed = LeaderboardSystem.boards.speed
        TestFramework.assert(speed.name == "Speed Demons", "Should have speed board")
        TestFramework.assert(speed.special_effect == "lightning", "Should have special effects")
    end,
    ["AI player generation"] = function()
        setupSystem()
        local template = {
            name = "TestBot",
            personality = "speed",
            emoji = "🤖",
            skill = 0.8
        }
        local player = LeaderboardSystem:generateAIPlayer(template)
        TestFramework.assert(player.id == "ai_TestBot", "Should generate correct ID")
        TestFramework.assert(player.name == "TestBot", "Should preserve name")
        TestFramework.assert(player.emoji == "🤖", "Should preserve emoji")
        TestFramework.assert(player.personality == "speed", "Should preserve personality")
        TestFramework.assert(player.is_ai == true, "Should mark as AI")
        TestFramework.assert(type(player.scores) == "table", "Should have scores table")
        TestFramework.assert(type(player.status) == "string", "Should have status")
        TestFramework.assert(type(player.last_seen) == "number", "Should have last seen time")
        TestFramework.assert(type(player.trending) == "boolean", "Should have trending flag")
        -- Check score generation
        TestFramework.assert(player.scores.overall > 0, "Should have overall score")
        TestFramework.assert(player.scores.weekly > 0, "Should have weekly score")
        TestFramework.assert(player.scores.speed > 0, "Should have speed score")
        -- Speed personality should have better speed score
        TestFramework.assert(player.scores.speed < 120, "Speed personality should have good speed score")
    end,
    ["status generation"] = function()
        setupSystem()
        local speed_status = LeaderboardSystem:generateStatus("speed")
        TestFramework.assert(type(speed_status) == "string", "Should return string status")
        TestFramework.assert(#speed_status > 0, "Status should not be empty")
        local precision_status = LeaderboardSystem:generateStatus("precision")
        TestFramework.assert(type(precision_status) == "string", "Should return precision status")
        local unknown_status = LeaderboardSystem:generateStatus("unknown")
        TestFramework.assert(type(unknown_status) == "string", "Should handle unknown personality")
    end,
    ["AI population"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        LeaderboardSystem:populateWithAIPlayers()
        -- Check that boards have entries
        for board_id, board in pairs(LeaderboardSystem.boards) do
            TestFramework.assert(#board.entries > 0, "Board " .. board_id .. " should have AI players")
        end
        -- Check entry structure
        local first_entry = LeaderboardSystem.boards.overall.entries[1]
        TestFramework.assert(type(first_entry.player_id) == "string", "Entry should have player ID")
        TestFramework.assert(type(first_entry.name) == "string", "Entry should have name")
        TestFramework.assert(type(first_entry.emoji) == "string", "Entry should have emoji")
        TestFramework.assert(type(first_entry.score) == "number", "Entry should have score")
        TestFramework.assert(first_entry.is_ai == true, "Entry should be marked as AI")
        TestFramework.assert(first_entry.rank_change == 0, "Entry should start with no rank change")
    end,
    ["player score update"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local stats = createMockPlayerStats()
        LeaderboardSystem:updatePlayerScores(stats)
        -- Check that player was added to boards
        for board_id, board in pairs(LeaderboardSystem.boards) do
            local found = false
            for _, entry in ipairs(board.entries) do
                if entry.player_id == "player" then
                    found = true
                    TestFramework.assert(entry.name == "You", "Player should be named 'You'")
                    TestFramework.assert(entry.is_ai == false, "Player should not be AI")
                    TestFramework.assert(entry.score > 0, "Player should have score on " .. board_id)
                    break
                end
            end
            TestFramework.assert(found, "Player should be found on " .. board_id .. " board")
        end
    end,
    ["player score update - existing entry"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        -- Add initial player entry
        local initial_stats = {total_score = 1000, weekly_score = 500, best_time = 150, perfect_landings = 10, planets_discovered = 5, rings_collected = 100}
        LeaderboardSystem:updatePlayerScores(initial_stats)
        local old_score = LeaderboardSystem.boards.overall.entries[1].score
        -- Update with better stats
        local updated_stats = createMockPlayerStats()
        LeaderboardSystem:updatePlayerScores(updated_stats)
        local player_entry = nil
        for _, entry in ipairs(LeaderboardSystem.boards.overall.entries) do
            if entry.player_id == "player" then
                player_entry = entry
                break
            end
        end
        TestFramework.assert(player_entry ~= nil, "Should find player entry")
        TestFramework.assert(player_entry.score == 15000, "Should update score")
        TestFramework.assert(player_entry.score_change ~= nil, "Should track score change")
    end,
    ["board sorting - higher is better"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        -- Add test entries to overall board
        local board = LeaderboardSystem.boards.overall
        board.entries = {
            {player_id = "p1", name = "Player1", score = 1000},
            {player_id = "p2", name = "Player2", score = 3000},
            {player_id = "p3", name = "Player3", score = 2000}
        }
        LeaderboardSystem:updateAllBoards()
        TestFramework.assert(board.entries[1].score == 3000, "Highest score should be first")
        TestFramework.assert(board.entries[2].score == 2000, "Medium score should be second")
        TestFramework.assert(board.entries[3].score == 1000, "Lowest score should be third")
    end,
    ["board sorting - lower is better for speed"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        -- Add test entries to speed board
        local board = LeaderboardSystem.boards.speed
        board.entries = {
            {player_id = "p1", name = "Player1", score = 150},
            {player_id = "p2", name = "Player2", score = 90},
            {player_id = "p3", name = "Player3", score = 120}
        }
        LeaderboardSystem:updateAllBoards()
        TestFramework.assert(board.entries[1].score == 90, "Fastest time should be first")
        TestFramework.assert(board.entries[2].score == 120, "Medium time should be second")
        TestFramework.assert(board.entries[3].score == 150, "Slowest time should be third")
    end,
    ["rank change tracking"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local board = LeaderboardSystem.boards.overall
        board.entries = {
            {player_id = "p1", name = "Player1", score = 3000},
            {player_id = "p2", name = "Player2", score = 2000},
            {player_id = "p3", name = "Player3", score = 1000}
        }
        -- First sort to establish ranks
        LeaderboardSystem:updateAllBoards()
        -- Change scores
        board.entries[3].score = 4000  -- Player3 jumps to first
        -- Resort and check rank changes
        LeaderboardSystem:updateAllBoards()
        TestFramework.assert(board.entries[1].player_id == "p3", "Player3 should be first")
        TestFramework.assert(board.entries[1].rank_change == 2, "Player3 should have +2 rank change")
        TestFramework.assert(board.entries[2].rank_change == -1, "Player1 should have -1 rank change")
        TestFramework.assert(board.entries[3].rank_change == -1, "Player2 should have -1 rank change")
    end,
    ["player rank tracking"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local board = LeaderboardSystem.boards.overall
        board.entries = {
            {player_id = "ai1", name = "AI1", score = 3000},
            {player_id = "player", name = "You", score = 2000},
            {player_id = "ai2", name = "AI2", score = 1000}
        }
        LeaderboardSystem:updateAllBoards()
        TestFramework.assert(board.player_rank == 2, "Player should be ranked 2nd")
    end,
    ["update system"] = function()
        setupSystem()
        LeaderboardSystem:init()
        local stats = createMockPlayerStats()
        -- Update without triggering interval
        LeaderboardSystem:update(15, stats)
        TestFramework.assert(LeaderboardSystem.update_timer == 15, "Should update timer")
        -- Update to trigger interval
        LeaderboardSystem:update(15, stats)
        TestFramework.assert(LeaderboardSystem.update_timer == 0, "Should reset timer after interval")
    end,
    ["rank improvement notification"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        -- Test reaching #1
        LeaderboardSystem:onRankImproved("overall", 1, 5)
        -- Should trigger notification (tested via mock system)
        -- Test top 3
        LeaderboardSystem:onRankImproved("weekly", 3, 2)
        -- Test top 10
        LeaderboardSystem:onRankImproved("speed", 8, 3)
        -- Check animation queue
        TestFramework.assert(#LeaderboardSystem.animation_queue == 3, "Should add animations for rank improvements")
        local first_anim = LeaderboardSystem.animation_queue[1]
        TestFramework.assert(first_anim.type == "rank_up", "Should be rank up animation")
        TestFramework.assert(first_anim.board_id == "overall", "Should reference correct board")
        TestFramework.assert(first_anim.rank == 1, "Should reference correct rank")
    end,
    ["animation updates"] = function()
        setupSystem()
        -- Add test animation
        table.insert(LeaderboardSystem.animation_queue, {
            type = "rank_up",
            board_id = "overall",
            rank = 1,
            timer = 0,
            duration = 1.0
        })
        -- Update animation
        LeaderboardSystem:updateAnimations(0.5)
        TestFramework.assert(LeaderboardSystem.animation_queue[1].timer == 0.5, "Should update animation timer")
        -- Complete animation
        LeaderboardSystem:updateAnimations(0.6)
        TestFramework.assert(#LeaderboardSystem.animation_queue == 0, "Should remove completed animation")
    end,
    ["AI activity simulation"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        LeaderboardSystem:populateWithAIPlayers()
        local original_scores = {}
        for _, entry in ipairs(LeaderboardSystem.boards.overall.entries) do
            if entry.is_ai then
                original_scores[entry.player_id] = entry.score
            end
        end
        -- Update AI activity multiple times to trigger changes
        for i = 1, 20 do
            LeaderboardSystem:updateAIActivity()
        end
        -- Check that some scores changed
        local changes = 0
        for _, entry in ipairs(LeaderboardSystem.boards.overall.entries) do
            if entry.is_ai and original_scores[entry.player_id] ~= entry.score then
                changes = changes + 1
            end
        end
        TestFramework.assert(changes > 0, "Some AI scores should have changed")
    end,
    ["leaderboard retrieval"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        LeaderboardSystem:populateWithAIPlayers()
        local leaderboard = LeaderboardSystem:getLeaderboard("overall", 10)
        TestFramework.assert(leaderboard ~= nil, "Should return leaderboard")
        TestFramework.assert(leaderboard.name == "Galactic Champions", "Should have correct name")
        TestFramework.assert(leaderboard.description ~= nil, "Should have description")
        TestFramework.assert(leaderboard.icon == "🏆", "Should have icon")
        TestFramework.assert(type(leaderboard.color) == "table", "Should have color")
        TestFramework.assert(type(leaderboard.entries) == "table", "Should have entries")
        TestFramework.assert(#leaderboard.entries <= 10, "Should limit to requested range")
        -- Check entry structure
        if #leaderboard.entries > 0 then
            local entry = leaderboard.entries[1]
            TestFramework.assert(entry.rank == 1, "First entry should have rank 1")
            TestFramework.assert(type(entry.player_id) == "string", "Should have player ID")
            TestFramework.assert(type(entry.name) == "string", "Should have name")
            TestFramework.assert(type(entry.score) == "number", "Should have score")
            TestFramework.assert(type(entry.is_ai) == "boolean", "Should have AI flag")
        end
    end,
    ["leaderboard retrieval - nonexistent board"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local leaderboard = LeaderboardSystem:getLeaderboard("nonexistent")
        TestFramework.assert(leaderboard == nil, "Should return nil for nonexistent board")
    end,
    ["leaderboard retrieval - player context"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        LeaderboardSystem:populateWithAIPlayers()
        -- Add player to middle of pack
        local stats = createMockPlayerStats()
        LeaderboardSystem:updatePlayerScores(stats)
        LeaderboardSystem:updateAllBoards()
        local board = LeaderboardSystem.boards.overall
        if board.player_rank and board.player_rank > 10 then
            local leaderboard = LeaderboardSystem:getLeaderboard("overall", 10)
            -- Should show entries around player
            local player_found = false
            for _, entry in ipairs(leaderboard.entries) do
                if entry.is_player then
                    player_found = true
                    break
                end
            end
            TestFramework.assert(player_found, "Should include player in results when they're not in top range")
        end
    end,
    ["player comparison"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local board = LeaderboardSystem.boards.overall
        board.entries = {
            {player_id = "ai1", name = "AI1", score = 3000, emoji = "🤖"},
            {player_id = "player", name = "You", score = 2000, emoji = "🎮"},
            {player_id = "ai2", name = "AI2", score = 1000, emoji = "🎯", trending = true, rank_change = 1}
        }
        board.player_rank = 2
        local comparison = LeaderboardSystem:getPlayerComparison("overall")
        TestFramework.assert(comparison ~= nil, "Should return comparison")
        TestFramework.assert(comparison.player_rank == 2, "Should include player rank")
        TestFramework.assert(comparison.player_score == 2000, "Should include player score")
        -- Check ahead comparison
        TestFramework.assert(comparison.ahead ~= nil, "Should have player ahead")
        TestFramework.assert(comparison.ahead.name == "AI1", "Should identify correct player ahead")
        TestFramework.assert(comparison.ahead.score == 3000, "Should include ahead player score")
        TestFramework.assert(comparison.ahead.difference == 1000, "Should calculate correct difference")
        TestFramework.assert(type(comparison.ahead.catchable) == "boolean", "Should determine if catchable")
        -- Check behind comparison
        TestFramework.assert(comparison.behind ~= nil, "Should have player behind")
        TestFramework.assert(comparison.behind.name == "AI2", "Should identify correct player behind")
        TestFramework.assert(comparison.behind.score == 1000, "Should include behind player score")
        TestFramework.assert(comparison.behind.difference == 1000, "Should calculate correct difference")
        TestFramework.assert(comparison.behind.catching_up == true, "Should detect trending player behind")
    end,
    ["player comparison - first place"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local board = LeaderboardSystem.boards.overall
        board.entries = {
            {player_id = "player", name = "You", score = 3000},
            {player_id = "ai1", name = "AI1", score = 2000}
        }
        board.player_rank = 1
        local comparison = LeaderboardSystem:getPlayerComparison("overall")
        TestFramework.assert(comparison.ahead == nil, "Should have no player ahead when in first")
        TestFramework.assert(comparison.behind ~= nil, "Should have player behind")
    end,
    ["player comparison - last place"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local board = LeaderboardSystem.boards.overall
        board.entries = {
            {player_id = "ai1", name = "AI1", score = 3000},
            {player_id = "player", name = "You", score = 2000}
        }
        board.player_rank = 2
        local comparison = LeaderboardSystem:getPlayerComparison("overall")
        TestFramework.assert(comparison.ahead ~= nil, "Should have player ahead")
        TestFramework.assert(comparison.behind == nil, "Should have no player behind when in last")
    end,
    ["player comparison - no player rank"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        local comparison = LeaderboardSystem:getPlayerComparison("overall")
        TestFramework.assert(comparison == nil, "Should return nil when player has no rank")
    end,
    ["save and load leaderboard data"] = function()
        setupSystem()
        LeaderboardSystem:initializeBoards()
        LeaderboardSystem:populateWithAIPlayers()
        -- Set player rank
        LeaderboardSystem.boards.overall.player_rank = 5
        LeaderboardSystem.player_ranks["test"] = 3
        -- Save data
        LeaderboardSystem:saveLeaderboardData()
        -- Reset system
        setupSystem()
        LeaderboardSystem:initializeBoards()
        -- Load data
        LeaderboardSystem:loadLeaderboardData()
        TestFramework.assert(LeaderboardSystem.boards.overall.player_rank == 5, "Should restore player rank")
        TestFramework.assert(LeaderboardSystem.player_ranks["test"] == 3, "Should restore player ranks data")
    end
}
-- Run tests
local function run()
    return TestFramework.runTests(tests, "Leaderboard System Tests")
end
return {run = run}