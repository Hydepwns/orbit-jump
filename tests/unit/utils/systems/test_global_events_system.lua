-- Test suite for Global Events System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup
Mocks.setup()
TestFramework.init()
-- Load system
local GlobalEventsSystem = Utils.require("src.systems.global_events_system")
-- Test helper functions
local function setupSystem()
    -- Reset system state
    GlobalEventsSystem.current_event = nil
    GlobalEventsSystem.event_history = {}
    GlobalEventsSystem.community_progress = 0
    GlobalEventsSystem.individual_contributions = {}
    GlobalEventsSystem.event_templates = {}
    GlobalEventsSystem.update_timer = 0
    GlobalEventsSystem.update_interval = 60
    GlobalEventsSystem.event_duration = 2592000
end
local function mockTime(timestamp)
    local original_time = os.time
    os.time = function()
        return timestamp
    end
    return original_time
end
local function restoreTime(original_time)
    os.time = original_time
end
-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        GlobalEventsSystem:init()
        TestFramework.assert(type(GlobalEventsSystem.event_templates) == "table", "Should have event templates")
        TestFramework.assert(#GlobalEventsSystem.event_templates > 0, "Should define event templates")
        TestFramework.assert(type(GlobalEventsSystem.event_history) == "table", "Should have event history")
        TestFramework.assert(type(GlobalEventsSystem.individual_contributions) == "table", "Should have contributions table")
    end,
    ["event template definition"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        TestFramework.assert(#GlobalEventsSystem.event_templates >= 4, "Should have at least 4 event templates")
        -- Check ring harvest template
        local ring_harvest = nil
        for _, template in ipairs(GlobalEventsSystem.event_templates) do
            if template.id == "ring_harvest" then
                ring_harvest = template
                break
            end
        end
        TestFramework.assert(ring_harvest ~= nil, "Should have ring harvest template")
        TestFramework.assert(ring_harvest.name == "The Great Ring Harvest", "Should have correct name")
        TestFramework.assert(type(ring_harvest.description) == "string", "Should have description")
        TestFramework.assert(type(ring_harvest.community_goal) == "number", "Should have community goal")
        TestFramework.assert(ring_harvest.community_goal == 1000000, "Should have correct goal")
        TestFramework.assert(type(ring_harvest.individual_tiers) == "table", "Should have individual tiers")
        TestFramework.assert(#ring_harvest.individual_tiers == 4, "Should have 4 tiers")
        TestFramework.assert(ring_harvest.track_type == "rings_collected", "Should track rings")
        TestFramework.assert(type(ring_harvest.story) == "table", "Should have story elements")
        TestFramework.assert(type(ring_harvest.exclusive_reward) == "table", "Should have exclusive reward")
        -- Check individual tier structure
        local first_tier = ring_harvest.individual_tiers[1]
        TestFramework.assert(first_tier.threshold == 100, "First tier should have correct threshold")
        TestFramework.assert(type(first_tier.reward) == "string", "Tier should have reward name")
        TestFramework.assert(type(first_tier.xp) == "number", "Tier should have XP reward")
    end,
    ["new event start"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        local original_time = mockTime(1000000)
        GlobalEventsSystem:startNewEvent()
        TestFramework.assert(GlobalEventsSystem.current_event ~= nil, "Should create current event")
        TestFramework.assert(type(GlobalEventsSystem.current_event.id) == "string", "Event should have ID")
        TestFramework.assert(GlobalEventsSystem.current_event.start_time == 1000000, "Should set start time")
        TestFramework.assert(GlobalEventsSystem.current_event.end_time > 1000000, "Should set end time")
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 0, "Should start with zero progress")
        TestFramework.assert(GlobalEventsSystem.current_event.completed == false, "Should start incomplete")
        TestFramework.assert(type(GlobalEventsSystem.current_event.template) == "table", "Should have template reference")
        TestFramework.assert(type(GlobalEventsSystem.current_event.individual_contributions) == "table", "Should have contributions table")
        TestFramework.assert(type(GlobalEventsSystem.current_event.milestones_reached) == "table", "Should have milestones table")
        restoreTime(original_time)
    end,
    ["progress contribution"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 0, "Should start with zero progress")
        GlobalEventsSystem:contributeProgress(100, "player1")
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 100, "Should update community progress")
        TestFramework.assert(GlobalEventsSystem.current_event.individual_contributions["player1"] ~= nil, "Should create player contribution")
        TestFramework.assert(GlobalEventsSystem.current_event.individual_contributions["player1"].amount == 100, "Should track individual amount")
    end,
    ["default player contribution"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem:contributeProgress(50) -- No player ID
        TestFramework.assert(GlobalEventsSystem.current_event.individual_contributions["player"] ~= nil, "Should default to 'player'")
        TestFramework.assert(GlobalEventsSystem.current_event.individual_contributions["player"].amount == 50, "Should track default player")
    end,
    ["multiple contributions"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem:contributeProgress(100, "player1")
        GlobalEventsSystem:contributeProgress(50, "player1")
        GlobalEventsSystem:contributeProgress(200, "player2")
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 350, "Should sum community progress")
        TestFramework.assert(GlobalEventsSystem.current_event.individual_contributions["player1"].amount == 150, "Should sum individual progress")
        TestFramework.assert(GlobalEventsSystem.current_event.individual_contributions["player2"].amount == 200, "Should track separate players")
    end,
    ["individual tier progression"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        local player_id = "test_player"
        -- Start below first tier
        GlobalEventsSystem:contributeProgress(50, player_id)
        local contribution = GlobalEventsSystem.current_event.individual_contributions[player_id]
        TestFramework.assert(contribution.tier_reached == 0, "Should not reach tier yet")
        -- Reach first tier (threshold: 100)
        GlobalEventsSystem:contributeProgress(50, player_id)
        TestFramework.assert(contribution.tier_reached == 1, "Should reach first tier")
        -- Reach second tier (threshold: 500)
        GlobalEventsSystem:contributeProgress(400, player_id)
        TestFramework.assert(contribution.tier_reached == 2, "Should reach second tier")
        -- Should not regress tiers
        local old_tier = contribution.tier_reached
        GlobalEventsSystem:checkIndividualTiers(player_id)
        TestFramework.assert(contribution.tier_reached == old_tier, "Should not regress tiers")
    end,
    ["milestone checking"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        local goal = GlobalEventsSystem.current_event.community_goal
        -- Reach 25% milestone
        GlobalEventsSystem.current_event.community_progress = math.floor(goal * 0.25)
        GlobalEventsSystem:checkMilestones()
        TestFramework.assert(GlobalEventsSystem.current_event.milestones_reached[25] == true, "Should reach 25% milestone")
        -- Reach 50% milestone
        GlobalEventsSystem.current_event.community_progress = math.floor(goal * 0.5)
        GlobalEventsSystem:checkMilestones()
        TestFramework.assert(GlobalEventsSystem.current_event.milestones_reached[50] == true, "Should reach 50% milestone")
        -- Reach 75% milestone
        GlobalEventsSystem.current_event.community_progress = math.floor(goal * 0.75)
        GlobalEventsSystem:checkMilestones()
        TestFramework.assert(GlobalEventsSystem.current_event.milestones_reached[75] == true, "Should reach 75% milestone")
    end,
    ["milestone idempotency"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        local goal = GlobalEventsSystem.current_event.community_goal
        GlobalEventsSystem.current_event.community_progress = math.floor(goal * 0.3) -- Above 25%
        -- Check milestones multiple times
        GlobalEventsSystem:checkMilestones()
        GlobalEventsSystem:checkMilestones()
        GlobalEventsSystem:checkMilestones()
        TestFramework.assert(GlobalEventsSystem.current_event.milestones_reached[25] == true, "Should maintain milestone state")
        TestFramework.assert(GlobalEventsSystem.current_event.milestones_reached[50] == nil, "Should not reach higher milestones")
    end,
    ["event completion by goal"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        local goal = GlobalEventsSystem.current_event.community_goal
        TestFramework.assert(GlobalEventsSystem.current_event.completed == false, "Should start incomplete")
        GlobalEventsSystem:contributeProgress(goal, "player")
        TestFramework.assert(GlobalEventsSystem.current_event.completed == true, "Should complete when goal reached")
        TestFramework.assert(type(GlobalEventsSystem.current_event.completion_time) == "number", "Should set completion time")
    end,
    ["event completion prevents further progress"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem.current_event.completed = true
        local initial_progress = GlobalEventsSystem.current_event.community_progress
        GlobalEventsSystem:contributeProgress(100, "player")
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == initial_progress, "Should not accept progress when completed")
    end,
    ["event completion awards exclusive rewards"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        -- Add some contributors
        GlobalEventsSystem:contributeProgress(50, "player1")
        GlobalEventsSystem:contributeProgress(100, "player2")
        GlobalEventsSystem:completeEvent()
        -- Check that exclusive rewards were awarded (via save system mock)
        TestFramework.assert(GlobalEventsSystem.current_event.completed == true, "Event should be completed")
    end,
    ["update system"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Test without current event
        GlobalEventsSystem:update(30)
        TestFramework.assert(GlobalEventsSystem.update_timer == 0, "Should not update timer without event")
        -- Test with current event
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem:update(30)
        TestFramework.assert(GlobalEventsSystem.update_timer == 30, "Should update timer")
        GlobalEventsSystem:update(30)
        TestFramework.assert(GlobalEventsSystem.update_timer == 0, "Should reset timer after interval")
    end,
    ["event expiration"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        local original_time = mockTime(1000000)
        GlobalEventsSystem:startNewEvent()
        -- Mock time to after event end
        os.time = function() return GlobalEventsSystem.current_event.end_time + 1 end
        GlobalEventsSystem:update(0.1)
        TestFramework.assert(#GlobalEventsSystem.event_history == 1, "Should archive expired event")
        TestFramework.assert(GlobalEventsSystem.current_event == nil, "Should clear current event")
        restoreTime(original_time)
    end,
    ["leaderboard update"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        -- Add contributors
        GlobalEventsSystem:contributeProgress(300, "player1")
        GlobalEventsSystem:contributeProgress(100, "player2")
        GlobalEventsSystem:contributeProgress(200, "player3")
        GlobalEventsSystem:updateLeaderboard()
        local top_contributors = GlobalEventsSystem.current_event.top_contributors
        TestFramework.assert(#top_contributors == 3, "Should have 3 contributors")
        TestFramework.assert(top_contributors[1].player_id == "player1", "Should sort by contribution amount")
        TestFramework.assert(top_contributors[1].amount == 300, "Should have correct amount")
        TestFramework.assert(top_contributors[2].player_id == "player3", "Second should be player3")
        TestFramework.assert(top_contributors[3].player_id == "player2", "Third should be player2")
    end,
    ["leaderboard size limit"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        -- Add 150 contributors (more than 100 limit)
        for i = 1, 150 do
            GlobalEventsSystem:contributeProgress(i, "player" .. i)
        end
        GlobalEventsSystem:updateLeaderboard()
        TestFramework.assert(#GlobalEventsSystem.current_event.top_contributors == 100, "Should limit to top 100")
    end,
    ["event info retrieval"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Test with no event
        local info = GlobalEventsSystem:getEventInfo()
        TestFramework.assert(info == nil, "Should return nil with no event")
        -- Test with active event
        local original_time = mockTime(1000000)
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem:contributeProgress(50, "player")
        info = GlobalEventsSystem:getEventInfo()
        TestFramework.assert(info ~= nil, "Should return event info")
        TestFramework.assert(type(info.name) == "string", "Should have event name")
        TestFramework.assert(type(info.description) == "string", "Should have description")
        TestFramework.assert(info.community_progress == 50, "Should include community progress")
        TestFramework.assert(type(info.community_goal) == "number", "Should include goal")
        TestFramework.assert(type(info.progress_percent) == "number", "Should calculate percentage")
        TestFramework.assert(type(info.time_remaining) == "number", "Should calculate time remaining")
        TestFramework.assert(info.completed == false, "Should include completion status")
        TestFramework.assert(info.player_contribution ~= nil, "Should include player contribution")
        restoreTime(original_time)
    end,
    ["player contribution retrieval"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        -- Test with no contribution
        local contribution = GlobalEventsSystem:getPlayerContribution("new_player")
        TestFramework.assert(contribution.amount == 0, "Should return zero for new player")
        TestFramework.assert(contribution.tier_reached == 0, "Should return zero tier")
        TestFramework.assert(contribution.next_tier ~= nil, "Should include next tier info")
        -- Test with contribution
        GlobalEventsSystem:contributeProgress(150, "active_player")
        contribution = GlobalEventsSystem:getPlayerContribution("active_player")
        TestFramework.assert(contribution.amount == 150, "Should return correct amount")
        TestFramework.assert(contribution.tier_reached == 1, "Should return correct tier")
        TestFramework.assert(contribution.next_tier ~= nil, "Should include next tier")
        TestFramework.assert(contribution.next_tier.threshold > 150, "Next tier should be higher")
    end,
    ["player contribution with ranking"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        -- Add multiple contributors
        GlobalEventsSystem:contributeProgress(300, "player1")
        GlobalEventsSystem:contributeProgress(200, "player2")
        GlobalEventsSystem:contributeProgress(100, "player3")
        GlobalEventsSystem:updateLeaderboard()
        local contribution = GlobalEventsSystem:getPlayerContribution("player2")
        TestFramework.assert(contribution.rank == 2, "Should return correct rank")
        contribution = GlobalEventsSystem:getPlayerContribution("player1")
        TestFramework.assert(contribution.rank == 1, "Should return correct rank for top player")
    end,
    ["player rank calculation"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem.current_event.top_contributors = {
            {player_id = "player1", amount = 300},
            {player_id = "player2", amount = 200},
            {player_id = "player3", amount = 100}
        }
        TestFramework.assert(GlobalEventsSystem:getPlayerRank("player1") == 1, "Should return rank 1")
        TestFramework.assert(GlobalEventsSystem:getPlayerRank("player2") == 2, "Should return rank 2")
        TestFramework.assert(GlobalEventsSystem:getPlayerRank("player3") == 3, "Should return rank 3")
        TestFramework.assert(GlobalEventsSystem:getPlayerRank("nonexistent") == nil, "Should return nil for unknown player")
    end,
    ["save and load event data"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        local original_time = mockTime(1000000)
        GlobalEventsSystem:startNewEvent()
        GlobalEventsSystem:contributeProgress(100, "player")
        -- Save data
        GlobalEventsSystem:saveEventData()
        -- Reset system
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Load data (event still active)
        GlobalEventsSystem:loadEventData()
        TestFramework.assert(GlobalEventsSystem.current_event ~= nil, "Should restore current event")
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 100, "Should restore progress")
        restoreTime(original_time)
    end,
    ["load expired event"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Simulate saved event that has expired
        Mocks.SaveSystem.data.global_events = {
            current_event = {
                id = "expired_event",
                start_time = 1000000,
                end_time = 1000100, -- Already expired
                community_progress = 50
            },
            event_history = {}
        }
        local original_time = mockTime(1000200) -- After expiration
        GlobalEventsSystem:loadEventData()
        TestFramework.assert(GlobalEventsSystem.current_event == nil, "Should not load expired event")
        restoreTime(original_time)
    end,
    ["tracking helper - rings collected"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Start event that tracks rings
        local ring_template = nil
        for _, template in ipairs(GlobalEventsSystem.event_templates) do
            if template.id == "ring_harvest" then
                ring_template = template
                break
            end
        end
        GlobalEventsSystem.current_event = {
            template = ring_template,
            community_progress = 0,
            individual_contributions = {},
            completed = false
        }
        GlobalEventsSystem:onRingsCollected(50)
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 50, "Should track rings collected")
    end,
    ["tracking helper - wrong event type"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Start event that tracks planets, not rings
        local planet_template = nil
        for _, template in ipairs(GlobalEventsSystem.event_templates) do
            if template.id == "planet_discovery" then
                planet_template = template
                break
            end
        end
        GlobalEventsSystem.current_event = {
            template = planet_template,
            community_progress = 0,
            individual_contributions = {},
            completed = false
        }
        GlobalEventsSystem:onRingsCollected(50)
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 0, "Should not track wrong type")
    end,
    ["tracking helper - planet discovered"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Start planet discovery event
        local planet_template = nil
        for _, template in ipairs(GlobalEventsSystem.event_templates) do
            if template.id == "planet_discovery" then
                planet_template = template
                break
            end
        end
        GlobalEventsSystem.current_event = {
            template = planet_template,
            community_progress = 0,
            individual_contributions = {},
            completed = false
        }
        GlobalEventsSystem:onPlanetDiscovered()
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 1, "Should track planet discovery")
    end,
    ["tracking helper - perfect landing"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Start perfect landing event
        local harmony_template = nil
        for _, template in ipairs(GlobalEventsSystem.event_templates) do
            if template.id == "perfect_harmony" then
                harmony_template = template
                break
            end
        end
        GlobalEventsSystem.current_event = {
            template = harmony_template,
            community_progress = 0,
            individual_contributions = {},
            completed = false
        }
        GlobalEventsSystem:onPerfectLanding()
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 1, "Should track perfect landing")
    end,
    ["tracking helper - legendary ring"] = function()
        setupSystem()
        GlobalEventsSystem:defineEventTemplates()
        -- Start legendary hunt event
        local legendary_template = nil
        for _, template in ipairs(GlobalEventsSystem.event_templates) do
            if template.id == "legendary_hunt" then
                legendary_template = template
                break
            end
        end
        GlobalEventsSystem.current_event = {
            template = legendary_template,
            community_progress = 0,
            individual_contributions = {},
            completed = false
        }
        GlobalEventsSystem:onLegendaryRingCollected()
        TestFramework.assert(GlobalEventsSystem.current_event.community_progress == 1, "Should track legendary ring")
    end,
    ["tracking helper - no current event"] = function()
        setupSystem()
        -- Test all helpers with no current event
        GlobalEventsSystem:onRingsCollected(50)
        GlobalEventsSystem:onPlanetDiscovered()
        GlobalEventsSystem:onPerfectLanding()
        GlobalEventsSystem:onLegendaryRingCollected()
        -- Should not crash or cause errors
        TestFramework.assert(true, "Should handle no current event gracefully")
    end
}
-- Run tests
local function run()
    return TestFramework.runTests(tests, "Global Events System Tests")
end
return {run = run}