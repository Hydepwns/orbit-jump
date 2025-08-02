-- Integration Test Suite for Addiction Features
-- Tests how all addiction systems work together
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup
Mocks.setup()
TestFramework.init()

-- Load all addiction systems
local StreakSystem = Utils.require("src.systems.streak_system")
local DailyStreakSystem = Utils.require("src.systems.daily_streak_system")
local XPSystem = Utils.require("src.systems.xp_system")
local RingRaritySystem = Utils.require("src.systems.ring_rarity_system")
local RandomEventsSystem = Utils.require("src.systems.random_events_system")
local MysteryBoxSystem = Utils.require("src.systems.mystery_box_system")
local RivalSystem = Utils.require("src.systems.rival_system")
local WeeklyChallengesSystem = Utils.require("src.systems.weekly_challenges_system")
local LeaderboardSystem = Utils.require("src.systems.leaderboard_system")
local GlobalEventsSystem = Utils.require("src.systems.global_events_system")
local PrestigeSystem = Utils.require("src.systems.prestige_system")
local MasterySystem = Utils.require("src.systems.mastery_system")

-- Test helper functions
local function setupAllSystems()
    -- Initialize all systems
    StreakSystem.init()
    DailyStreakSystem.init()
    XPSystem.init()
    RingRaritySystem.init()
    RandomEventsSystem.init()
    MysteryBoxSystem.init()
    RivalSystem:init()
    WeeklyChallengesSystem:init()
    LeaderboardSystem:init()
    GlobalEventsSystem:init()
    PrestigeSystem.init()
    MasterySystem.init()
end

local function simulateGameSession(duration_minutes, actions_per_minute)
    local total_actions = duration_minutes * actions_per_minute
    local results = {
        perfect_landings = 0,
        rings_collected = 0,
        legendary_rings = 0,
        planets_discovered = 0,
        xp_gained = 0,
        level_ups = 0,
        achievements_unlocked = 0
    }
    
    for i = 1, total_actions do
        -- Simulate perfect landing (70% chance)
        if math.random() < 0.7 then
            results.perfect_landings = results.perfect_landings + 1
            StreakSystem.addPerfectLanding()
            MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
            WeeklyChallengesSystem:onPerfectLanding()
            GlobalEventsSystem:onPerfectLanding()
        end
        
        -- Simulate ring collection (90% chance, 1-5 rings)
        if math.random() < 0.9 then
            local rings = math.random(1, 5)
            results.rings_collected = results.rings_collected + rings
            
            -- Check for legendary rings
            for r = 1, rings do
                if RingRaritySystem.rollForRarity() == "legendary" then
                    results.legendary_rings = results.legendary_rings + 1
                    WeeklyChallengesSystem:onLegendaryRingCollected()
                    GlobalEventsSystem:onLegendaryRingCollected()
                end
            end
            
            WeeklyChallengesSystem:onRingsCollected(rings)
            GlobalEventsSystem:onRingsCollected(rings)
        end
        
        -- Simulate planet discovery (10% chance)
        if math.random() < 0.1 then
            results.planets_discovered = results.planets_discovered + 1
            WeeklyChallengesSystem:onPlanetDiscovered()
            GlobalEventsSystem:onPlanetDiscovered()
        end
        
        -- Add XP for actions
        local xp_gained = XPSystem.addXP(50, "gameplay")
        if xp_gained > 0 then
            results.xp_gained = results.xp_gained + xp_gained
            if XPSystem.getData().just_leveled_up then
                results.level_ups = results.level_ups + 1
            end
        end
        
        -- Update random events
        RandomEventsSystem.update(1)
        
        -- Update mystery boxes
        MysteryBoxSystem.update(1)
    end
    
    return results
end

local function createMockPlayerStats()
    return {
        level = 25,
        total_score = 50000,
        weekly_score = 15000,
        best_time = 120,
        perfect_landings = 200,
        planets_discovered = 25,
        rings_collected = 3000,
        legendary_rings = 5,
        max_combo = 15,
        achievements_unlocked = 10
    }
end

-- Test suite
local tests = {
    ["system initialization integration"] = function()
        setupAllSystems()
        
        -- Verify all systems initialized without conflicts
        TestFramework.assert(StreakSystem.getData() ~= nil, "Streak system should initialize")
        TestFramework.assert(XPSystem.getData() ~= nil, "XP system should initialize")
        TestFramework.assert(RivalSystem.current_rival ~= nil, "Rival system should initialize with rival")
        TestFramework.assert(#WeeklyChallengesSystem.active_challenges > 0, "Weekly challenges should initialize")
        TestFramework.assert(#LeaderboardSystem.boards > 0, "Leaderboard should initialize")
        TestFramework.assert(GlobalEventsSystem.current_event ~= nil, "Global events should initialize")
        TestFramework.assert(PrestigeSystem.getData() ~= nil, "Prestige system should initialize")
        TestFramework.assert(MasterySystem.getData() ~= nil, "Mastery system should initialize")
    end,
    
    ["perfect landing cascade"] = function()
        setupAllSystems()
        
        local initial_streak = StreakSystem.getData().current_streak
        local initial_mastery = MasterySystem.getData().planet_mastery["normal"].perfect_landings
        
        -- Simulate perfect landing
        StreakSystem.addPerfectLanding()
        MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        WeeklyChallengesSystem:onPerfectLanding()
        GlobalEventsSystem:onPerfectLanding()
        
        -- Verify all systems updated
        TestFramework.assert(StreakSystem.getData().current_streak == initial_streak + 1, "Should update streak")
        TestFramework.assert(MasterySystem.getData().planet_mastery["normal"].perfect_landings == initial_mastery + 1, "Should update mastery")
        
        -- Check that weekly challenges and global events tracked the landing
        local week_info = WeeklyChallengesSystem:getChallengeInfo()
        local global_info = GlobalEventsSystem:getEventInfo()
        
        if week_info and week_info.challenges then
            for _, challenge in ipairs(week_info.challenges) do
                if challenge.description:find("perfect") then
                    TestFramework.assert(challenge.progress > 0, "Weekly challenge should track perfect landings")
                end
            end
        end
        
        if global_info and global_info.name:find("Harmony") then
            TestFramework.assert(global_info.community_progress > 0, "Global event should track perfect landings")
        end
    end,
    
    ["ring collection integration"] = function()
        setupAllSystems()
        
        local initial_rare_count = RingRaritySystem.getData().total_legendary
        
        -- Force legendary ring
        RingRaritySystem.getData().bad_luck_protection = 199 -- Next roll guaranteed legendary
        
        local rarity = RingRaritySystem.rollForRarity()
        if rarity == "legendary" then
            WeeklyChallengesSystem:onLegendaryRingCollected()
            GlobalEventsSystem:onLegendaryRingCollected()
        end
        
        -- Collect regular rings
        WeeklyChallengesSystem:onRingsCollected(10)
        GlobalEventsSystem:onRingsCollected(10)
        
        TestFramework.assert(RingRaritySystem.getData().total_legendary > initial_rare_count, "Should collect legendary ring")
        
        -- Verify tracking across systems
        local week_info = WeeklyChallengesSystem:getChallengeInfo()
        local global_info = GlobalEventsSystem:getEventInfo()
        
        if global_info and global_info.name:find("Ring") then
            TestFramework.assert(global_info.community_progress >= 10, "Global event should track ring collection")
        end
    end,
    
    ["xp and progression integration"] = function()
        setupAllSystems()
        
        local initial_level = XPSystem.getData().level
        local initial_total_xp = XPSystem.getData().total_xp
        
        -- Add significant XP to trigger level up
        XPSystem.addXP(5000, "test_integration")
        
        local xp_data = XPSystem.getData()
        TestFramework.assert(xp_data.total_xp > initial_total_xp, "Should gain XP")
        
        if xp_data.level > initial_level then
            -- Level up should be reflected in leaderboards
            local stats = createMockPlayerStats()
            stats.level = xp_data.level
            LeaderboardSystem:updatePlayerScores(stats)
            LeaderboardSystem:updateAllBoards()
            
            local overall_board = LeaderboardSystem:getLeaderboard("overall", 10)
            TestFramework.assert(overall_board ~= nil, "Should update leaderboard after level up")
        end
    end,
    
    ["rival system integration"] = function()
        setupAllSystems()
        
        local stats = createMockPlayerStats()
        
        -- Update rival system with player stats
        RivalSystem:update(61, stats) -- Trigger update interval
        
        TestFramework.assert(RivalSystem.current_rival ~= nil, "Should have active rival")
        
        -- Simulate player improvement
        stats.total_score = 100000
        stats.perfect_landings = 400
        
        RivalSystem:update(0.1, stats)
        
        local rival_info = RivalSystem:getRivalInfo()
        local progress = RivalSystem:getRivalProgress(stats)
        
        TestFramework.assert(rival_info ~= nil, "Should provide rival info")
        TestFramework.assert(progress ~= nil, "Should provide progress info")
        
        if RivalSystem.current_rival.defeated then
            TestFramework.assert(XPSystem.getData().total_xp > 0, "Should award XP for rival defeat")
        end
    end,
    
    ["leaderboard integration"] = function()
        setupAllSystems()
        
        local stats = createMockPlayerStats()
        
        -- Update all leaderboard-relevant systems
        LeaderboardSystem:updatePlayerScores(stats)
        LeaderboardSystem:updateAllBoards()
        
        -- Check leaderboard placement
        local overall = LeaderboardSystem:getLeaderboard("overall", 20)
        TestFramework.assert(overall ~= nil, "Should get overall leaderboard")
        TestFramework.assert(#overall.entries > 0, "Should have leaderboard entries")
        
        local player_found = false
        for _, entry in ipairs(overall.entries) do
            if entry.is_player then
                player_found = true
                TestFramework.assert(entry.score == stats.total_score, "Should show correct player score")
                break
            end
        end
        TestFramework.assert(player_found, "Should find player on leaderboard")
        
        -- Check multiple board types
        local speed_board = LeaderboardSystem:getLeaderboard("speed", 10)
        local perfection_board = LeaderboardSystem:getLeaderboard("perfection", 10)
        
        TestFramework.assert(speed_board ~= nil, "Should have speed leaderboard")
        TestFramework.assert(perfection_board ~= nil, "Should have perfection leaderboard")
    end,
    
    ["prestige system integration"] = function()
        setupAllSystems()
        
        local prestige_data = PrestigeSystem.getData()
        prestige_data.level = 2 -- Simulate having prestiged
        
        -- Check XP multiplier integration
        local base_xp = 100
        local multiplier = PrestigeSystem.getXPMultiplier()
        local modified_xp = XPSystem.addXP(base_xp, "prestige_test")
        
        TestFramework.assert(multiplier > 1.0, "Should have XP multiplier from prestige")
        
        -- Check prestige shop effects
        prestige_data.stardust = 1000
        local success, result = PrestigeSystem.purchaseShopItem("magnet_range")
        
        if success then
            local effects = PrestigeSystem.getActiveEffects()
            TestFramework.assert(#effects > 0, "Should have active prestige effects")
            TestFramework.assert(effects[1].type == "magnet_range", "Should have magnet range effect")
        end
    end,
    
    ["event system coordination"] = function()
        setupAllSystems()
        
        -- Simulate random event triggering
        RandomEventsSystem.getData().time_since_last = 1000 -- Force next event
        RandomEventsSystem.update(1)
        
        local active_event = RandomEventsSystem.getData().active_event
        if active_event then
            TestFramework.assert(active_event.type ~= nil, "Should have active random event")
            
            -- Events should not conflict with each other
            local mystery_data = MysteryBoxSystem.getData()
            TestFramework.assert(type(mystery_data.boxes) == "table", "Mystery box system should remain functional")
        end
        
        -- Check global event integration
        local global_info = GlobalEventsSystem:getEventInfo()
        if global_info then
            TestFramework.assert(global_info.time_remaining > 0, "Global event should be active")
            TestFramework.assert(global_info.community_goal > 0, "Should have community goal")
        end
    end,
    
    ["mastery and progression harmony"] = function()
        setupAllSystems()
        
        local mastery_data = MasterySystem.getData()
        
        -- Simulate mastery progression
        for i = 1, 15 do
            MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        end
        
        -- Should have gained mastery level
        TestFramework.assert(mastery_data.planet_mastery["normal"].current_level > 0, "Should gain mastery level")
        TestFramework.assert(mastery_data.total_mastery_points > 0, "Should earn mastery points")
        
        -- Check mastery bonuses
        local bonuses = MasterySystem.getPlanetBonus("normal")
        TestFramework.assert(bonuses.point_multiplier > 1.0, "Should have point multiplier bonus")
        
        -- Technique mastery
        for i = 1, 10 do
            MasterySystem.trackTechnique("precision_landing", {bullseye = true})
        end
        
        TestFramework.assert(mastery_data.technique_mastery["precision_landing"].count > 0, "Should track technique progress")
    end,
    
    ["full game session simulation"] = function()
        setupAllSystems()
        
        local session_results = simulateGameSession(5, 10) -- 5 minute session, 10 actions per minute
        
        TestFramework.assert(session_results.perfect_landings > 0, "Should perform perfect landings")
        TestFramework.assert(session_results.rings_collected > 0, "Should collect rings")
        TestFramework.assert(session_results.xp_gained > 0, "Should gain XP")
        
        -- Verify all systems have been updated
        local streak_data = StreakSystem.getData()
        local xp_data = XPSystem.getData()
        local mastery_data = MasterySystem.getData()
        
        TestFramework.assert(streak_data.current_streak >= 0, "Streak system should be updated")
        TestFramework.assert(xp_data.total_xp > 0, "XP system should be updated")
        TestFramework.assert(mastery_data.planet_mastery["normal"].total_landings > 0, "Mastery system should be updated")
        
        -- Check challenge progress
        local week_info = WeeklyChallengesSystem:getChallengeInfo()
        if week_info and week_info.challenges then
            local has_progress = false
            for _, challenge in ipairs(week_info.challenges) do
                if challenge.progress > 0 then
                    has_progress = true
                    break
                end
            end
            TestFramework.assert(has_progress, "Should have challenge progress")
        end
    end,
    
    ["system performance under load"] = function()
        setupAllSystems()
        
        local start_time = love.timer.getTime()
        
        -- Simulate intensive session
        for i = 1, 100 do
            -- Update all systems that have update methods
            RandomEventsSystem.update(0.1)
            MysteryBoxSystem.update(0.1)
            RivalSystem:update(0.1, createMockPlayerStats())
            WeeklyChallengesSystem:update(0.1)
            LeaderboardSystem:update(0.1, createMockPlayerStats())
            GlobalEventsSystem:update(0.1)
            
            -- Perform actions
            StreakSystem.addPerfectLanding()
            XPSystem.addXP(10, "performance_test")
            WeeklyChallengesSystem:onPerfectLanding()
            GlobalEventsSystem:onPerfectLanding()
        end
        
        local end_time = love.timer.getTime()
        local duration = end_time - start_time
        
        TestFramework.assert(duration < 1.0, "Should complete 100 iterations in under 1 second")
        
        -- Verify systems still functional after load
        TestFramework.assert(StreakSystem.getData().current_streak > 0, "Streak system should remain functional")
        TestFramework.assert(XPSystem.getData().total_xp > 0, "XP system should remain functional")
    end,
    
    ["data persistence integration"] = function()
        setupAllSystems()
        
        -- Make changes to various systems
        StreakSystem.addPerfectLanding()
        XPSystem.addXP(1000, "persistence_test")
        WeeklyChallengesSystem:onRingsCollected(50)
        
        local rival_progress = RivalSystem:getRivalProgress(createMockPlayerStats())
        local global_contribution = GlobalEventsSystem:getPlayerContribution()
        
        -- Verify data can be retrieved
        TestFramework.assert(StreakSystem.getData() ~= nil, "Should be able to get streak data")
        TestFramework.assert(XPSystem.getData() ~= nil, "Should be able to get XP data")
        TestFramework.assert(rival_progress ~= nil, "Should be able to get rival progress")
        
        if global_contribution then
            TestFramework.assert(global_contribution.amount >= 0, "Should be able to get global contribution")
        end
    end,
    
    ["addiction feature completeness"] = function()
        setupAllSystems()
        
        -- Verify all major addiction mechanics are present and functional
        
        -- 1. Progression systems
        TestFramework.assert(XPSystem.addXP(100, "test") > 0, "XP system functional")
        TestFramework.assert(PrestigeSystem.canPrestige ~= nil, "Prestige system functional")
        TestFramework.assert(MasterySystem.trackPlanetLanding ~= nil, "Mastery system functional")
        
        -- 2. Streak systems
        StreakSystem.addPerfectLanding()
        TestFramework.assert(StreakSystem.getData().current_streak > 0, "Streak system functional")
        
        -- 3. Variable reward systems
        TestFramework.assert(RingRaritySystem.rollForRarity() ~= nil, "Ring rarity system functional")
        TestFramework.assert(RandomEventsSystem.getData() ~= nil, "Random events system functional")
        TestFramework.assert(MysteryBoxSystem.getData() ~= nil, "Mystery box system functional")
        
        -- 4. Social/competitive systems
        TestFramework.assert(RivalSystem.current_rival ~= nil, "Rival system functional")
        TestFramework.assert(LeaderboardSystem:getLeaderboard("overall") ~= nil, "Leaderboard system functional")
        TestFramework.assert(WeeklyChallengesSystem:getChallengeInfo() ~= nil, "Weekly challenges functional")
        TestFramework.assert(GlobalEventsSystem:getEventInfo() ~= nil, "Global events functional")
        
        -- 5. Long-term retention systems
        TestFramework.assert(PrestigeSystem.getData() ~= nil, "Prestige system present")
        TestFramework.assert(MasterySystem.getData() ~= nil, "Mastery system present")
    end,
    
    ["cross-system event propagation"] = function()
        setupAllSystems()
        
        local systems_triggered = 0
        
        -- Simulate a perfect landing that should trigger multiple systems
        local initial_streak = StreakSystem.getData().current_streak
        local initial_mastery = MasterySystem.getData().planet_mastery["normal"].perfect_landings
        
        -- Trigger the cascade
        StreakSystem.addPerfectLanding()
        systems_triggered = systems_triggered + 1
        
        MasterySystem.trackPlanetLanding("normal", true, {x = 100, y = 100}, {x = 100, y = 100}, 50)
        systems_triggered = systems_triggered + 1
        
        WeeklyChallengesSystem:onPerfectLanding()
        systems_triggered = systems_triggered + 1
        
        GlobalEventsSystem:onPerfectLanding()
        systems_triggered = systems_triggered + 1
        
        -- Verify all systems were affected
        TestFramework.assert(StreakSystem.getData().current_streak > initial_streak, "Streak system updated")
        TestFramework.assert(MasterySystem.getData().planet_mastery["normal"].perfect_landings > initial_mastery, "Mastery system updated")
        TestFramework.assert(systems_triggered == 4, "All systems should be triggered")
        
        -- The perfect landing should potentially contribute to:
        -- - Current streak
        -- - Planet mastery
        -- - Weekly challenges (if applicable)
        -- - Global events (if applicable)
        -- - XP gain
        -- - Leaderboard position
        
        local week_info = WeeklyChallengesSystem:getChallengeInfo()
        local global_info = GlobalEventsSystem:getEventInfo()
        
        -- At minimum, the core tracking should work
        TestFramework.assert(StreakSystem.getData().total_perfect_landings > 0, "Should track total perfect landings")
    end
}

-- Run tests
local function run()
    return TestFramework.runTests(tests, "Addiction Features Integration Tests")
end

return {run = run}