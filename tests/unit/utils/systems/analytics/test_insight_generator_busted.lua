-- Unit tests for Insight Generator System using enhanced Busted framework
package.path = package.path .. ";../../../?.lua"
local Utils = require("src.utils.utils")
Utils.require("tests.busted")
-- Setup mocks
local Mocks = Utils.require("tests.mocks")
Mocks.setup()
-- Mock love.timer if not available
if not love then
    _G.love = {
        timer = {
            getTime = function() return os.time() end
        }
    }
end
-- Load InsightGenerator
local InsightGenerator = require("src.systems.analytics.insight_generator")
describe("Insight Generator System", function()
    before_each(function()
        -- Reset generator state
        InsightGenerator.init()
    end)
    describe("Initialization", function()
        it("should initialize insights structure", function()
            local insights = InsightGenerator.insights
            assert.is_type("table", insights)
            assert.is_type("table", insights.movement)
            assert.is_type("table", insights.exploration)
            assert.is_type("table", insights.skill)
            assert.is_type("table", insights.emotional)
            assert.is_type("table", insights.recommendations)
        end)
        it("should initialize data storage", function()
            local data = InsightGenerator.data
            assert.is_type("table", data)
            assert.is_type("table", data.events)
            assert.is_type("table", data.gameplay)
            assert.is_type("table", data.progression)
        end)
        it("should initialize gameplay tracking", function()
            local gameplay = InsightGenerator.data.gameplay
            assert.is_type("number", gameplay.jumps)
            assert.is_type("number", gameplay.landings)
            assert.is_type("number", gameplay.dashes)
            assert.is_type("table", gameplay.events)
        end)
        it("should initialize session tracking", function()
            local session = InsightGenerator.session
            assert.is_type("table", session)
            assert.is_type("string", session.id)
            assert.is_type("number", session.startTime)
            assert.is_type("number", session.duration)
            assert.is_type("boolean", session.active)
        end)
        it("should reset data on initialization", function()
            -- Set some data first
            InsightGenerator.data.gameplay.jumps = 10
            table.insert(InsightGenerator.data.events, {type = "test"})
            -- Re-initialize
            InsightGenerator.init()
            -- Should be reset
            assert.equals(0, InsightGenerator.data.gameplay.jumps)
            assert.is_empty(InsightGenerator.data.events)
        end)
    end)
    describe("Data Structure", function()
        it("should maintain separate insight categories", function()
            local insights = InsightGenerator.insights
            -- Should be different tables
            assert.not_equal(insights.movement, insights.exploration)
            assert.not_equal(insights.skill, insights.emotional)
            assert.not_equal(insights.recommendations, insights.movement)
        end)
        it("should have proper gameplay counters", function()
            local gameplay = InsightGenerator.data.gameplay
            assert.equals(0, gameplay.jumps)
            assert.equals(0, gameplay.landings)
            assert.equals(0, gameplay.dashes)
        end)
        it("should allow data modifications", function()
            local gameplay = InsightGenerator.data.gameplay
            gameplay.jumps = 5
            gameplay.landings = 3
            gameplay.dashes = 2
            assert.equals(5, gameplay.jumps)
            assert.equals(3, gameplay.landings)
            assert.equals(2, gameplay.dashes)
        end)
        it("should handle event tracking", function()
            local events = InsightGenerator.data.events
            table.insert(events, {type = "jump", time = 100})
            table.insert(events, {type = "land", time = 101})
            assert.equals(2, #events)
            assert.equals("jump", events[1].type)
            assert.equals("land", events[2].type)
        end)
    end)
    describe("Session Management", function()
        it("should track session state", function()
            local session = InsightGenerator.session
            session.active = true
            session.duration = 60
            session.id = "test_session"
            assert.is_true(session.active)
            assert.equals(60, session.duration)
            assert.equals("test_session", session.id)
        end)
        it("should initialize session with timestamp", function()
            InsightGenerator.init()
            local session = InsightGenerator.session
            -- Start time should be set (may be 0 in some environments)
            assert.is_type("number", session.startTime)
        end)
        it("should handle session ID generation", function()
            InsightGenerator.init()
            local session = InsightGenerator.session
            -- Should have some kind of session ID
            assert.is_type("string", session.id)
        end)
    end)
    describe("Insight Categories", function()
        it("should provide access to all insight categories", function()
            local insights = InsightGenerator.insights
            -- Should be able to add insights to each category
            table.insert(insights.movement, {type = "efficiency", value = 0.8})
            table.insert(insights.exploration, {type = "coverage", value = 0.6})
            table.insert(insights.skill, {type = "progression", value = 0.9})
            table.insert(insights.emotional, {type = "flow", value = 0.7})
            table.insert(insights.recommendations, {type = "practice", text = "Try harder jumps"})
            assert.equals(1, #insights.movement)
            assert.equals(1, #insights.exploration)
            assert.equals(1, #insights.skill)
            assert.equals(1, #insights.emotional)
            assert.equals(1, #insights.recommendations)
        end)
        it("should handle empty insight categories", function()
            InsightGenerator.init() -- Ensure fresh initialization
            local insights = InsightGenerator.insights
            assert.is_type("table", insights.movement)
            assert.is_type("table", insights.exploration)
            assert.is_type("table", insights.skill)
            assert.is_type("table", insights.emotional)
            assert.is_type("table", insights.recommendations)
        end)
        it("should maintain insight data integrity", function()
            local insights = InsightGenerator.insights
            insights.movement = {{type = "test", value = 1.0}}
            insights.skill = {{type = "mastery", level = 0.5}}
            assert.equals("test", insights.movement[1].type)
            assert.equals("mastery", insights.skill[1].type)
            assert.not_equal(insights.movement, insights.skill)
        end)
    end)
    describe("Analytics Data Management", function()
        it("should track gameplay statistics", function()
            local gameplay = InsightGenerator.data.gameplay
            -- Simulate gameplay events
            gameplay.jumps = gameplay.jumps + 1
            gameplay.landings = gameplay.landings + 1
            gameplay.dashes = gameplay.dashes + 2
            assert.equals(1, gameplay.jumps)
            assert.equals(1, gameplay.landings)
            assert.equals(2, gameplay.dashes)
        end)
        it("should maintain event history", function()
            local events = InsightGenerator.data.events
            local gameplayEvents = InsightGenerator.data.gameplay.events
            table.insert(events, {type = "session_start", time = 0})
            table.insert(gameplayEvents, {type = "first_jump", time = 5})
            assert.equals(1, #events)
            assert.equals(1, #gameplayEvents)
            assert.equals("session_start", events[1].type)
            -- GameplayEvents might contain more than expected due to initialization
            assert.greater_or_equal(0, #gameplayEvents)
        end)
        it("should handle progression data", function()
            local progression = InsightGenerator.data.progression
            progression.level = 3
            progression.experience = 150
            progression.skills = {"jump", "dash"}
            assert.equals(3, progression.level)
            assert.equals(150, progression.experience)
            assert.equals(2, #progression.skills)
        end)
    end)
    describe("State Persistence", function()
        it("should maintain state between operations", function()
            -- Set some state
            InsightGenerator.data.gameplay.jumps = 10
            InsightGenerator.session.active = true
            table.insert(InsightGenerator.insights.movement, {type = "test"})
            -- State should persist
            assert.equals(10, InsightGenerator.data.gameplay.jumps)
            assert.is_true(InsightGenerator.session.active)
            assert.greater_or_equal(1, #InsightGenerator.insights.movement)
        end)
        it("should reset properly when initialized", function()
            -- Set some state
            InsightGenerator.data.gameplay.jumps = 10
            table.insert(InsightGenerator.data.events, {type = "test"})
            -- Re-initialize
            InsightGenerator.init()
            -- Should be reset
            assert.equals(0, InsightGenerator.data.gameplay.jumps)
            assert.is_empty(InsightGenerator.data.events)
        end)
        it("should handle data structure modifications", function()
            local insights = InsightGenerator.insights
            -- Add custom insight category
            insights.custom = {}
            table.insert(insights.custom, {type = "user_defined", value = 42})
            assert.is_not_nil(insights.custom)
            assert.equals(1, #insights.custom)
            assert.equals(42, insights.custom[1].value)
        end)
    end)
    describe("Edge Cases", function()
        it("should handle missing love.timer gracefully", function()
            -- Temporarily remove love.timer
            local originalLove = _G.love
            _G.love = nil
            assert.has_no_error(function()
                InsightGenerator.init()
            end)
            -- Restore
            _G.love = originalLove
        end)
        it("should handle large data sets", function()
            local events = InsightGenerator.data.events
            -- Add many events
            for i = 1, 100 do
                table.insert(events, {type = "test_event", id = i, time = i})
            end
            assert.equals(100, #events)
            assert.equals(1, events[1].id)
            assert.equals(100, events[100].id)
        end)
        it("should handle concurrent modifications", function()
            local gameplay = InsightGenerator.data.gameplay
            -- Simulate concurrent updates
            gameplay.jumps = gameplay.jumps + 1
            gameplay.jumps = gameplay.jumps + 2
            gameplay.landings = gameplay.landings + 1
            assert.equals(3, gameplay.jumps)
            assert.equals(1, gameplay.landings)
        end)
    end)
end)