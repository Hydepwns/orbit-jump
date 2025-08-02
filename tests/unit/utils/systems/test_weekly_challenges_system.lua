-- Test suite for Weekly Challenges System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup
Mocks.setup()
TestFramework.init()

-- Load system
local WeeklyChallengesSystem = Utils.require("src.systems.weekly_challenges_system")

-- Test helper functions
local function setupSystem()
    -- Reset system state
    WeeklyChallengesSystem.active_challenges = {}
    WeeklyChallengesSystem.completed_challenges = {}
    WeeklyChallengesSystem.current_week = 0
    WeeklyChallengesSystem.challenge_templates = {}
    WeeklyChallengesSystem.story_context = {}
    WeeklyChallengesSystem.refresh_timer = 0
    WeeklyChallengesSystem.refresh_interval = 604800
    WeeklyChallengesSystem.weekly_story = nil
end

local function mockCurrentWeek(week)
    -- Mock os.time to return specific week
    local original_time = os.time
    os.time = function()
        return 1704067200 + (week * 604800) + 86400 -- Add a day offset
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
        WeeklyChallengesSystem:init()
        
        TestFramework.assert(type(WeeklyChallengesSystem.active_challenges) == "table", "Should have active challenges table")
        TestFramework.assert(type(WeeklyChallengesSystem.completed_challenges) == "table", "Should have completed challenges table")
        TestFramework.assert(WeeklyChallengesSystem.current_week >= 0, "Should set current week")
        TestFramework.assert(#WeeklyChallengesSystem.challenge_templates > 0, "Should define challenge templates")
        TestFramework.assert(#WeeklyChallengesSystem.story_context > 0, "Should define story contexts")
        TestFramework.assert(#WeeklyChallengesSystem.active_challenges > 0, "Should generate weekly challenges")
    end,
    
    ["challenge template definition"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        
        TestFramework.assert(#WeeklyChallengesSystem.challenge_templates >= 9, "Should have at least 9 templates")
        
        -- Check first template structure
        local template = WeeklyChallengesSystem.challenge_templates[1]
        TestFramework.assert(type(template.id) == "string", "Template should have ID")
        TestFramework.assert(type(template.name) == "string", "Template should have name")
        TestFramework.assert(type(template.description) == "string", "Template should have description")
        TestFramework.assert(type(template.type) == "string", "Template should have type")
        TestFramework.assert(type(template.base_target) == "number", "Template should have base target")
        TestFramework.assert(type(template.difficulty) == "string", "Template should have difficulty")
        TestFramework.assert(type(template.reward_xp) == "number", "Template should have XP reward")
        TestFramework.assert(type(template.reward_currency) == "number", "Template should have currency reward")
    end,
    
    ["story context definition"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineStoryContexts()
        
        TestFramework.assert(#WeeklyChallengesSystem.story_context == 4, "Should have 4 story contexts")
        
        local context = WeeklyChallengesSystem.story_context[1]
        TestFramework.assert(type(context.week_title) == "string", "Context should have title")
        TestFramework.assert(type(context.description) == "string", "Context should have description")
        TestFramework.assert(type(context.challenges_focus) == "table", "Context should have focus areas")
    end,
    
    ["current week calculation"] = function()
        setupSystem()
        local original_time = mockCurrentWeek(10)
        
        local week = WeeklyChallengesSystem:getCurrentWeek()
        TestFramework.assert(week == 10, "Should calculate correct week number")
        
        restoreTime(original_time)
    end,
    
    ["challenge creation from template"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem.current_week = 5
        
        local template = WeeklyChallengesSystem.challenge_templates[1]
        local challenge = WeeklyChallengesSystem:createChallengeFromTemplate(template)
        
        TestFramework.assert(type(challenge.id) == "string", "Should have unique ID")
        TestFramework.assert(challenge.id:find("week_5"), "ID should include week number")
        TestFramework.assert(challenge.template_id == template.id, "Should preserve template ID")
        TestFramework.assert(challenge.name == template.name, "Should preserve name")
        TestFramework.assert(type(challenge.target) == "number", "Should have numeric target")
        TestFramework.assert(challenge.progress == 0, "Should start with zero progress")
        TestFramework.assert(challenge.completed == false, "Should start incomplete")
        TestFramework.assert(challenge.week == 5, "Should store week number")
    end,
    
    ["challenge target variance"] = function()
        setupSystem()
        WeeklyChallengesSystem.current_week = 1
        
        local template = {
            id = "test",
            name = "Test",
            description = "Test {target}",
            type = "test",
            base_target = 100,
            target_variance = 0.2,
            difficulty = "medium",
            reward_xp = 100,
            reward_currency = 50
        }
        
        -- Generate multiple challenges to test variance
        local targets = {}
        for i = 1, 50 do
            local challenge = WeeklyChallengesSystem:createChallengeFromTemplate(template)
            table.insert(targets, challenge.target)
        end
        
        -- Check that some variance occurred
        local min_target = math.min(table.unpack(targets))
        local max_target = math.max(table.unpack(targets))
        TestFramework.assert(max_target > min_target, "Should have target variance")
        TestFramework.assert(min_target >= 80, "Should not go below 20% variance")
        TestFramework.assert(max_target <= 120, "Should not go above 20% variance")
    end,
    
    ["weekly challenge generation"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem:defineStoryContexts()
        WeeklyChallengesSystem.current_week = 2
        
        WeeklyChallengesSystem:generateWeeklyChallenges()
        
        TestFramework.assert(#WeeklyChallengesSystem.active_challenges == 3, "Should generate 3 challenges")
        TestFramework.assert(WeeklyChallengesSystem.weekly_story ~= nil, "Should set weekly story")
        
        -- Check that all challenges have week context
        for _, challenge in ipairs(WeeklyChallengesSystem.active_challenges) do
            TestFramework.assert(challenge.week == 2, "All challenges should have correct week")
            TestFramework.assert(type(challenge.story_context) == "string", "Should have story context")
        end
        
        -- Check difficulty variety
        local difficulties = {}
        for _, challenge in ipairs(WeeklyChallengesSystem.active_challenges) do
            difficulties[challenge.difficulty] = true
        end
        TestFramework.assert(difficulties.easy or difficulties.medium or difficulties.hard, "Should have varied difficulties")
    end,
    
    ["time remaining calculation"] = function()
        setupSystem()
        local remaining = WeeklyChallengesSystem:getTimeRemaining()
        
        TestFramework.assert(type(remaining) == "number", "Should return numeric time")
        TestFramework.assert(remaining > 0, "Should have positive time remaining")
        TestFramework.assert(remaining <= 604800, "Should not exceed one week")
    end,
    
    ["progress update"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem.current_week = 1
        
        -- Create test challenge
        local challenge = WeeklyChallengesSystem:createChallengeFromTemplate(WeeklyChallengesSystem.challenge_templates[1])
        challenge.type = "collect_rings"
        challenge.target = 100
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        -- Update progress
        local updated = WeeklyChallengesSystem:updateProgress("collect_rings", 25)
        
        TestFramework.assert(updated ~= nil, "Should return updated challenge")
        TestFramework.assert(challenge.progress == 25, "Should update progress")
        TestFramework.assert(challenge.completed == false, "Should remain incomplete")
        
        -- Complete challenge
        WeeklyChallengesSystem:updateProgress("collect_rings", 75)
        TestFramework.assert(challenge.progress == 100, "Should reach target")
        TestFramework.assert(challenge.completed == true, "Should mark as completed")
    end,
    
    ["progress clamping"] = function()
        setupSystem()
        WeeklyChallengesSystem.current_week = 1
        
        local challenge = {
            type = "test",
            target = 50,
            progress = 0,
            completed = false
        }
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        -- Try to exceed target
        WeeklyChallengesSystem:updateProgress("test", 75)
        TestFramework.assert(challenge.progress == 50, "Should clamp progress to target")
    end,
    
    ["challenge completion"] = function()
        setupSystem()
        
        local challenge = {
            id = "test_challenge",
            name = "Test Challenge",
            completed = false,
            reward_xp = 500,
            reward_currency = 100,
            story_complete = "Test completion story"
        }
        
        WeeklyChallengesSystem:completeChallenge(challenge)
        
        TestFramework.assert(challenge.completed == true, "Should mark as completed")
        TestFramework.assert(type(challenge.completion_time) == "number", "Should set completion time")
    end,
    
    ["duplicate completion prevention"] = function()
        setupSystem()
        
        local challenge = {
            completed = true,
            completion_time = 123456
        }
        
        WeeklyChallengesSystem:completeChallenge(challenge)
        TestFramework.assert(challenge.completion_time == 123456, "Should not change completion time")
    end,
    
    ["week change handling"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem:defineStoryContexts()
        WeeklyChallengesSystem.current_week = 5
        
        -- Set up active challenges
        local completed_challenge = {id = "old1", completed = true}
        local incomplete_challenge = {id = "old2", completed = false}
        WeeklyChallengesSystem.active_challenges = {completed_challenge, incomplete_challenge}
        
        local original_time = mockCurrentWeek(6)
        
        WeeklyChallengesSystem:onWeekChange()
        
        TestFramework.assert(WeeklyChallengesSystem.current_week == 6, "Should update current week")
        TestFramework.assert(#WeeklyChallengesSystem.completed_challenges == 1, "Should archive completed challenges")
        TestFramework.assert(WeeklyChallengesSystem.completed_challenges[1].id == "old1", "Should archive correct challenge")
        TestFramework.assert(#WeeklyChallengesSystem.active_challenges == 3, "Should generate new challenges")
        
        restoreTime(original_time)
    end,
    
    ["update system"] = function()
        setupSystem()
        WeeklyChallengesSystem:init()
        local initial_week = WeeklyChallengesSystem.current_week
        
        -- Update without week change
        WeeklyChallengesSystem:update(30)
        TestFramework.assert(WeeklyChallengesSystem.refresh_timer == 30, "Should update timer")
        
        -- Mock week change
        local original_time = mockCurrentWeek(initial_week + 1)
        WeeklyChallengesSystem:update(0.1)
        TestFramework.assert(WeeklyChallengesSystem.current_week == initial_week + 1, "Should detect week change")
        
        restoreTime(original_time)
    end,
    
    ["challenge info retrieval"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem:defineStoryContexts()
        WeeklyChallengesSystem:generateWeeklyChallenges()
        
        local info = WeeklyChallengesSystem:getChallengeInfo()
        
        TestFramework.assert(type(info.week_title) == "string", "Should have week title")
        TestFramework.assert(type(info.week_description) == "string", "Should have week description")
        TestFramework.assert(type(info.challenges) == "table", "Should have challenges array")
        TestFramework.assert(type(info.time_remaining) == "number", "Should have time remaining")
        TestFramework.assert(#info.challenges == #WeeklyChallengesSystem.active_challenges, "Should include all challenges")
        
        -- Check challenge info structure
        if #info.challenges > 0 then
            local challenge_info = info.challenges[1]
            TestFramework.assert(type(challenge_info.name) == "string", "Challenge should have name")
            TestFramework.assert(type(challenge_info.description) == "string", "Challenge should have description")
            TestFramework.assert(type(challenge_info.progress) == "number", "Challenge should have progress")
            TestFramework.assert(type(challenge_info.target) == "number", "Challenge should have target")
            TestFramework.assert(type(challenge_info.percentage) == "number", "Challenge should have percentage")
            TestFramework.assert(type(challenge_info.completed) == "boolean", "Challenge should have completion status")
        end
    end,
    
    ["helper function - rings collected"] = function()
        setupSystem()
        local challenge = {type = "collect_rings", target = 100, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onRingsCollected(50)
        TestFramework.assert(challenge.progress == 50, "Should update ring collection progress")
    end,
    
    ["helper function - legendary ring"] = function()
        setupSystem()
        local challenge = {type = "collect_legendary", target = 5, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onLegendaryRingCollected()
        TestFramework.assert(challenge.progress == 1, "Should increment legendary ring count")
    end,
    
    ["helper function - planet discovered"] = function()
        setupSystem()
        local challenge = {type = "discover_planets", target = 10, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onPlanetDiscovered()
        TestFramework.assert(challenge.progress == 1, "Should increment planet discovery count")
    end,
    
    ["helper function - void planet visited"] = function()
        setupSystem()
        local challenge = {type = "visit_void_planets", target = 5, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onVoidPlanetVisited()
        TestFramework.assert(challenge.progress == 1, "Should increment void planet count")
    end,
    
    ["helper function - perfect landing"] = function()
        setupSystem()
        local challenge = {type = "perfect_landings", target = 50, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onPerfectLanding()
        TestFramework.assert(challenge.progress == 1, "Should increment perfect landing count")
    end,
    
    ["helper function - combo reached"] = function()
        setupSystem()
        local challenge = {type = "max_combo", target = 30, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        -- Test progressive combo updates
        WeeklyChallengesSystem:onComboReached(15)
        TestFramework.assert(challenge.progress == 15, "Should set combo progress")
        
        WeeklyChallengesSystem:onComboReached(10)  -- Lower combo
        TestFramework.assert(challenge.progress == 15, "Should not decrease progress")
        
        WeeklyChallengesSystem:onComboReached(25)  -- Higher combo
        TestFramework.assert(challenge.progress == 25, "Should increase to higher combo")
    end,
    
    ["helper function - dash sequence"] = function()
        setupSystem()
        local challenge = {type = "dash_sequences", target = 100, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onDashSequence()
        TestFramework.assert(challenge.progress == 1, "Should increment dash sequence count")
    end,
    
    ["helper function - mystery box opened"] = function()
        setupSystem()
        local challenge = {type = "open_mystery_boxes", target = 10, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onMysteryBoxOpened()
        TestFramework.assert(challenge.progress == 1, "Should increment mystery box count")
    end,
    
    ["helper function - random event experienced"] = function()
        setupSystem()
        local challenge = {type = "experience_events", target = 20, progress = 0, completed = false}
        WeeklyChallengesSystem.active_challenges = {challenge}
        
        WeeklyChallengesSystem:onRandomEventExperienced()
        TestFramework.assert(challenge.progress == 1, "Should increment event experience count")
    end,
    
    ["save and load progress"] = function()
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem:defineStoryContexts()
        WeeklyChallengesSystem.current_week = 10
        WeeklyChallengesSystem:generateWeeklyChallenges()
        
        -- Update some progress
        WeeklyChallengesSystem:updateProgress(WeeklyChallengesSystem.active_challenges[1].type, 25)
        
        -- Save progress
        WeeklyChallengesSystem:saveProgress()
        
        -- Reset system
        setupSystem()
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem:defineStoryContexts()
        WeeklyChallengesSystem.current_week = 10
        WeeklyChallengesSystem:generateWeeklyChallenges()
        
        -- Load progress
        WeeklyChallengesSystem:loadProgress()
        
        TestFramework.assert(WeeklyChallengesSystem.active_challenges[1].progress == 25, "Should restore progress")
    end,
    
    ["load progress - different week"] = function()
        setupSystem()
        
        -- Simulate saved data from different week
        Mocks.SaveSystem.data.weekly_challenges = {
            current_week = 5,
            active_challenges = {{progress = 50}},
            completed_challenges = {{id = "old"}}
        }
        
        WeeklyChallengesSystem:defineChallengeTemplates()
        WeeklyChallengesSystem:defineStoryContexts()
        WeeklyChallengesSystem.current_week = 6  -- Different week
        WeeklyChallengesSystem:generateWeeklyChallenges()
        
        WeeklyChallengesSystem:loadProgress()
        
        -- Should not load active challenges from different week
        TestFramework.assert(WeeklyChallengesSystem.active_challenges[1].progress == 0, "Should not load old week challenges")
        
        -- Should still load completed challenges history
        TestFramework.assert(#WeeklyChallengesSystem.completed_challenges == 1, "Should load completed challenges")
    end
}

-- Run tests
local function run()
    return TestFramework.runTests(tests, "Weekly Challenges System Tests")
end

return {run = run}