-- Test suite for Rival System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup
Mocks.setup()
TestFramework.init()

-- Load system
local RivalSystem = Utils.require("src.systems.rival_system")

-- Test helper functions
local function setupSystem()
    -- Reset system state
    RivalSystem.current_rival = nil
    RivalSystem.rival_history = {}
    RivalSystem.matchmaking_pool = {}
    RivalSystem.update_timer = 0
    RivalSystem.update_interval = 60
    RivalSystem.performance_window = 300
end

local function createMockPlayerStats()
    return {
        total_score = 5000,
        perfect_landings = 25,
        max_combo = 10,
        planets_discovered = 3,
        achievements_unlocked = 5,
        legendary_rings = 2
    }
end

local function createMockRival()
    return {
        id = "test_rival",
        name = "Test Rival",
        avatar = "🎯",
        score = 6000,
        skill_level = 1.1,
        personality = "competitive",
        taunt = "Test taunt",
        defeat_message = "Test defeat message",
        is_ai = true,
        recent_scores = {6000, 5800, 6200, 5900, 6100},
        achievements = 6,
        playtime = 600
    }
end

-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        RivalSystem:init()
        
        TestFramework.assert(RivalSystem.current_rival == nil, "Should start without rival")
        TestFramework.assert(type(RivalSystem.rival_history) == "table", "History should be table")
        TestFramework.assert(type(RivalSystem.matchmaking_pool) == "table", "Pool should be table")
        TestFramework.assert(#RivalSystem.matchmaking_pool > 0, "Should create AI rivals")
        TestFramework.assert(RivalSystem.update_timer == 0, "Timer should be reset")
    end,
    
    ["ai rival creation"] = function()
        setupSystem()
        RivalSystem:createAIRivals()
        
        TestFramework.assert(#RivalSystem.matchmaking_pool == 5, "Should create 5 AI rivals")
        
        -- Check first AI rival structure
        local first_rival = RivalSystem.matchmaking_pool[1]
        TestFramework.assert(first_rival.id == "ai_rookie", "First rival should be rookie")
        TestFramework.assert(first_rival.name == "Space Cadet Sam", "Should have correct name")
        TestFramework.assert(first_rival.is_ai == true, "Should be marked as AI")
        TestFramework.assert(type(first_rival.recent_scores) == "table", "Should have recent scores")
        TestFramework.assert(#first_rival.recent_scores == 10, "Should have 10 recent scores")
        TestFramework.assert(first_rival.achievements > 0, "Should have achievements")
        TestFramework.assert(first_rival.playtime > 0, "Should have playtime")
    end,
    
    ["recent score generation"] = function()
        setupSystem()
        local scores = RivalSystem:generateRecentScores(1000, 1.0)
        
        TestFramework.assert(#scores == 10, "Should generate 10 scores")
        
        for _, score in ipairs(scores) do
            TestFramework.assert(type(score) == "number", "Each score should be number")
            TestFramework.assert(score > 0, "Scores should be positive")
            TestFramework.assert(score >= 800 and score <= 1200, "Scores should be within variance range")
        end
    end,
    
    ["performance score calculation"] = function()
        setupSystem()
        local stats = createMockPlayerStats()
        local score = RivalSystem:calculatePerformanceScore(stats)
        
        -- Expected: 5000*1.0 + 25*100 + 10*50 + 3*200 + 5*150 + 2*500 = 14900
        TestFramework.assert(score == 14900, "Should calculate correct performance score")
    end,
    
    ["rival score calculation - AI"] = function()
        setupSystem()
        local rival = createMockRival()
        local score = RivalSystem:calculateRivalScore(rival)
        
        TestFramework.assert(score == 6000, "AI rival score should match base score")
    end,
    
    ["rival score calculation - player"] = function()
        setupSystem()
        local rival = {
            id = "player_rival",
            is_ai = false,
            recent_scores = {1000, 1200, 800, 1100, 900}
        }
        
        local score = RivalSystem:calculateRivalScore(rival)
        TestFramework.assert(score == 1000, "Player rival should use average of recent scores")
    end,
    
    ["rival finding - exact match"] = function()
        setupSystem()
        RivalSystem:createAIRivals()
        
        local stats = {
            total_score = 4500,
            perfect_landings = 20,
            max_combo = 8,
            planets_discovered = 2,
            achievements_unlocked = 4,
            legendary_rings = 1
        }
        
        local rival = RivalSystem:findRival(stats)
        TestFramework.assert(rival ~= nil, "Should find a rival")
        TestFramework.assert(rival.id == "ai_challenger", "Should find Captain Nova for mid-level player")
    end,
    
    ["rival finding - no better rival fallback"] = function()
        setupSystem()
        RivalSystem:createAIRivals()
        
        -- Super high stats that beat all AI rivals
        local stats = {
            total_score = 100000,
            perfect_landings = 500,
            max_combo = 100,
            planets_discovered = 50,
            achievements_unlocked = 100,
            legendary_rings = 50
        }
        
        local rival = RivalSystem:findRival(stats)
        TestFramework.assert(rival ~= nil, "Should find closest match when no better rival")
    end,
    
    ["rival setting"] = function()
        setupSystem()
        local rival = createMockRival()
        
        RivalSystem:setRival(rival)
        
        TestFramework.assert(RivalSystem.current_rival == rival, "Should set current rival")
        TestFramework.assert(RivalSystem.current_rival.defeated == false, "Should mark as not defeated")
        TestFramework.assert(type(RivalSystem.current_rival.challenge_start) == "number", "Should set challenge start time")
    end,
    
    ["rival history tracking"] = function()
        setupSystem()
        local rival1 = createMockRival()
        rival1.id = "rival1"
        local rival2 = createMockRival()
        rival2.id = "rival2"
        
        RivalSystem:setRival(rival1)
        TestFramework.assert(#RivalSystem.rival_history == 0, "History should be empty initially")
        
        RivalSystem:setRival(rival2)
        TestFramework.assert(#RivalSystem.rival_history == 1, "Should add previous rival to history")
        TestFramework.assert(RivalSystem.rival_history[1].rival.id == "rival1", "Should store correct rival in history")
    end,
    
    ["rival defeat"] = function()
        setupSystem()
        local rival = createMockRival()
        RivalSystem:setRival(rival)
        
        TestFramework.assert(RivalSystem.current_rival.defeated == false, "Should start undefeated")
        
        RivalSystem:defeatRival()
        
        TestFramework.assert(RivalSystem.current_rival.defeated == true, "Should mark as defeated")
    end,
    
    ["rival defeat - already defeated"] = function()
        setupSystem()
        local rival = createMockRival()
        rival.defeated = true
        RivalSystem.current_rival = rival
        
        -- Should handle gracefully
        RivalSystem:defeatRival()
        TestFramework.assert(RivalSystem.current_rival.defeated == true, "Should remain defeated")
    end,
    
    ["rival defeat - no current rival"] = function()
        setupSystem()
        
        -- Should handle gracefully
        RivalSystem:defeatRival()
        TestFramework.assert(RivalSystem.current_rival == nil, "Should remain nil")
    end,
    
    ["should change rival - too easy"] = function()
        setupSystem()
        local rival = createMockRival()
        rival.score = 1000  -- Much lower than player
        RivalSystem.current_rival = rival
        
        local stats = createMockPlayerStats()  -- Score: 14900
        local should_change = RivalSystem:shouldChangeRival(stats)
        
        TestFramework.assert(should_change == true, "Should change when rival is too easy")
    end,
    
    ["should change rival - too hard"] = function()
        setupSystem()
        local rival = createMockRival()
        rival.score = 50000  -- Much higher than player
        RivalSystem.current_rival = rival
        
        local stats = createMockPlayerStats()  -- Score: 14900
        local should_change = RivalSystem:shouldChangeRival(stats)
        
        TestFramework.assert(should_change == true, "Should change when rival is too hard")
    end,
    
    ["should change rival - just right"] = function()
        setupSystem()
        local rival = createMockRival()
        rival.score = 15000  -- Close to player score (14900)
        RivalSystem.current_rival = rival
        
        local stats = createMockPlayerStats()
        local should_change = RivalSystem:shouldChangeRival(stats)
        
        TestFramework.assert(should_change == false, "Should not change when rival is appropriate")
    end,
    
    ["update - timer progression"] = function()
        setupSystem()
        RivalSystem:init()
        
        TestFramework.assert(RivalSystem.update_timer == 0, "Timer should start at 0")
        
        RivalSystem:update(30, createMockPlayerStats())
        TestFramework.assert(RivalSystem.update_timer == 30, "Timer should advance")
        
        RivalSystem:update(30, createMockPlayerStats())
        TestFramework.assert(RivalSystem.update_timer == 0, "Timer should reset after interval")
    end,
    
    ["update - rival defeat check"] = function()
        setupSystem()
        local rival = createMockRival()
        rival.score = 1000  -- Much lower than player performance
        RivalSystem:setRival(rival)
        
        local stats = createMockPlayerStats()  -- Score: 14900
        RivalSystem:update(0.1, stats)
        
        TestFramework.assert(RivalSystem.current_rival.defeated == true, "Should defeat rival when player surpasses")
    end,
    
    ["get rival info"] = function()
        setupSystem()
        
        -- No rival case
        local info = RivalSystem:getRivalInfo()
        TestFramework.assert(info == nil, "Should return nil when no rival")
        
        -- With rival case
        local rival = createMockRival()
        RivalSystem:setRival(rival)
        
        info = RivalSystem:getRivalInfo()
        TestFramework.assert(info ~= nil, "Should return info when rival exists")
        TestFramework.assert(info.name == "Test Rival", "Should include name")
        TestFramework.assert(info.avatar == "🎯", "Should include avatar")
        TestFramework.assert(info.score == 6000, "Should include score")
        TestFramework.assert(info.defeated == false, "Should include defeat status")
        TestFramework.assert(info.personality == "competitive", "Should include personality")
        TestFramework.assert(info.is_online == true, "AI rivals should be online")
    end,
    
    ["get rival progress"] = function()
        setupSystem()
        
        -- No rival case
        local progress = RivalSystem:getRivalProgress(createMockPlayerStats())
        TestFramework.assert(progress == nil, "Should return nil when no rival")
        
        -- With rival case
        local rival = createMockRival()
        RivalSystem:setRival(rival)
        
        local stats = createMockPlayerStats()  -- Score: 14900
        progress = RivalSystem:getRivalProgress(stats)
        
        TestFramework.assert(progress ~= nil, "Should return progress when rival exists")
        TestFramework.assert(progress.player_score == 14900, "Should include player score")
        TestFramework.assert(progress.rival_score == 6000, "Should include rival score")
        TestFramework.assert(progress.progress > 2, "Player should be ahead")
        TestFramework.assert(progress.difference < 0, "Difference should be negative when player ahead")
    end,
    
    ["add player to pool"] = function()
        setupSystem()
        
        local player_data = {
            id = "player123",
            name = "Test Player",
            avatar = "🎮",
            recent_scores = {1000, 1100, 900},
            achievements = 5,
            playtime = 300,
            is_online = true
        }
        
        RivalSystem:addPlayerToPool(player_data)
        
        TestFramework.assert(#RivalSystem.matchmaking_pool == 1, "Should add player to pool")
        
        local added_player = RivalSystem.matchmaking_pool[1]
        TestFramework.assert(added_player.id == "player123", "Should preserve player ID")
        TestFramework.assert(added_player.name == "Test Player", "Should preserve player name")
        TestFramework.assert(added_player.personality == "player", "Should mark as player personality")
    end,
    
    ["update player in pool"] = function()
        setupSystem()
        
        -- Add player first
        RivalSystem:addPlayerToPool({
            id = "player123",
            name = "Test Player",
            recent_scores = {1000}
        })
        
        -- Update player data
        RivalSystem:updatePlayerInPool("player123", {
            recent_scores = {1000, 1200, 900},
            is_online = false
        })
        
        local player = RivalSystem.matchmaking_pool[1]
        TestFramework.assert(#player.recent_scores == 3, "Should update recent scores")
        TestFramework.assert(player.is_online == false, "Should update online status")
        TestFramework.assert(player.name == "Test Player", "Should preserve unchanged fields")
    end,
    
    ["save and load rival data"] = function()
        setupSystem()
        
        -- Set up test data
        local rival = createMockRival()
        RivalSystem:setRival(rival)
        RivalSystem:defeatRival()
        
        -- Save data
        RivalSystem:saveRivalData()
        
        -- Reset system
        setupSystem()
        
        -- Load data
        RivalSystem:loadRivalData()
        
        TestFramework.assert(RivalSystem.current_rival ~= nil, "Should restore current rival")
        TestFramework.assert(RivalSystem.current_rival.name == "Test Rival", "Should restore rival details")
        TestFramework.assert(RivalSystem.current_rival.defeated == true, "Should restore defeat status")
        TestFramework.assert(#RivalSystem.rival_history == 0, "Should restore empty history")
    end
}

-- Run tests
local function run()
    return TestFramework.runTests(tests, "Rival System Tests")
end

return {run = run}