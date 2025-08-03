-- Test suite for Daily Streak System
-- Tests daily login tracking, rewards, streak freezes, and calendar functionality
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
TestFramework.init()
-- Mock TSerial for save/load
_G.TSerial = {
    pack = function(data)
        -- Simple serialization for testing
        return "return " .. TestFramework.serialize(data)
    end,
    unpack = function(str)
        local fn = loadstring(str)
        return fn and fn() or nil
    end
}
-- Load system
local DailyStreakSystem = Utils.require("src.systems.daily_streak_system")
-- Mock Love2D filesystem
local mockFileData = {}
love.filesystem = love.filesystem or {}
love.filesystem.write = function(filename, data)
    mockFileData[filename] = data
    return true
end
love.filesystem.read = function(filename)
    return mockFileData[filename]
end
love.filesystem.getInfo = function(filename)
    return mockFileData[filename] and {type = "file"} or nil
end
-- Mock os.date and os.time for consistent testing
local mockDate = {year = 2024, month = 1, day = 1, hour = 12, min = 0, sec = 0}
local originalDate = os.date
local originalTime = os.time
local function setMockDate(year, month, day)
    mockDate = {year = year, month = month, day = day, hour = 12, min = 0, sec = 0}
end
os.date = function(format, time)
    if format == "*t" then
        return mockDate
    end
    return originalDate(format, time)
end
os.time = function(date)
    if date then
        return originalTime(date)
    end
    return originalTime(mockDate)
end
-- Mock math.pow if not available (Lua 5.1 compatibility)
math.pow = math.pow or function(x, y)
    return x ^ y
end
-- Test helper functions
local function setupSystem()
    -- Clear mock file data
    mockFileData = {}
    -- Reset to January 1, 2024
    setMockDate(2024, 1, 1)
    -- Initialize system
    DailyStreakSystem.init()
end
local function getStreakData()
    return DailyStreakSystem.getData()
end
-- Test suite
local tests = {
    ["initialization"] = function()
        setupSystem()
        local data = getStreakData()
        TestFramework.assert.equal(0, data.current_streak, "Streak should start at 0")
        TestFramework.assert.equal(0, data.longest_streak, "Longest streak should start at 0")
        TestFramework.assert.isTrue(data.last_login_date == nil, "No last login date initially")
        TestFramework.assert.equal(3, data.streak_freezes, "Should have 3 freezes")
        TestFramework.assert.equal(0, data.total_logins, "Total logins should be 0")
    end,
    ["first login"] = function()
        setupSystem()
        local reward = DailyStreakSystem.checkDailyLogin()
        local data = getStreakData()
        TestFramework.assert.isTrue(reward ~= nil, "Should receive reward on first login")
        TestFramework.assert.equal(1, reward.day, "Should be day 1 reward")
        TestFramework.assert.equal(100, reward.rings, "Day 1 should give 100 rings")
        TestFramework.assert.equal(50, reward.xp, "Day 1 should give 50 XP")
        TestFramework.assert.equal(1, data.current_streak, "Streak should be 1")
        TestFramework.assert.equal(1, data.longest_streak, "Longest streak should be 1")
        TestFramework.assert.equal("2024-01-01", data.last_login_date, "Login date should be saved")
        TestFramework.assert.equal(1, data.total_logins, "Total logins should be 1")
    end,
    ["same day login"] = function()
        setupSystem()
        -- First login
        DailyStreakSystem.checkDailyLogin()
        -- Try to login again same day
        local reward = DailyStreakSystem.checkDailyLogin()
        TestFramework.assert.isTrue(reward ~= nil, "Should not get reward for same day login")
        TestFramework.assert.equal(1, getStreakData().current_streak, "Streak should remain 1")
    end,
    ["consecutive day login"] = function()
        setupSystem()
        -- Day 1
        DailyStreakSystem.checkDailyLogin()
        -- Day 2
        setMockDate(2024, 1, 2)
        local reward = DailyStreakSystem.checkDailyLogin()
        local data = getStreakData()
        TestFramework.assert.isTrue(reward ~= nil, "Should receive reward")
        TestFramework.assert.equal(2, reward.day, "Should be day 2")
        TestFramework.assert.equal(200, reward.rings, "Day 2 base rings")
        TestFramework.assert.equal(2, data.current_streak, "Streak should be 2")
        TestFramework.assert.equal(2, data.longest_streak, "Longest streak should update")
    end,
    ["build 7 day streak"] = function()
        setupSystem()
        -- Build streak to day 7
        for day = 1, 7 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        local data = getStreakData()
        TestFramework.assert.equal(7, data.current_streak, "Should have 7 day streak")
        TestFramework.assert.equal(7, data.total_logins, "Should have 7 total logins")
    end,
    ["day 7 milestone reward"] = function()
        setupSystem()
        -- Build to day 7
        for day = 1, 6 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Day 7
        setMockDate(2024, 1, 7)
        local reward = DailyStreakSystem.checkDailyLogin()
        TestFramework.assert.equal(7, reward.day, "Should be day 7")
        TestFramework.assert.equal(1000, reward.rings, "Day 7 base rings")
        TestFramework.assert.equal("exclusive_planet_skin", reward.special, "Should have special reward")
        TestFramework.assert.isTrue(reward.is_milestone, "Should be marked as milestone")
    end,
    ["streak broken - 2 days gap"] = function()
        setupSystem()
        -- Build 5 day streak
        for day = 1, 5 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Skip day 6, login day 7 (2 day gap)
        setMockDate(2024, 1, 7)
        local reward = DailyStreakSystem.checkDailyLogin()
        local data = getStreakData()
        TestFramework.assert.isTrue(reward ~= nil, "Should receive reward")
        TestFramework.assert.equal(1, reward.day, "Should reset to day 1")
        TestFramework.assert.equal(1, data.current_streak, "Streak should reset to 1")
        TestFramework.assert.equal(5, data.longest_streak, "Longest streak should remain 5")
    end,
    ["streak freeze - 2 day gap"] = function()
        setupSystem()
        -- Build 10 day streak
        for day = 1, 10 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        local freezes_before = getStreakData().streak_freezes
        -- Skip day 11, login day 12 (2 day gap, within freeze limit)
        setMockDate(2024, 1, 12)
        local result = DailyStreakSystem.checkDailyLogin()
        local data = getStreakData()
        TestFramework.assert.isTrue(result ~= nil, "Should receive result")
        TestFramework.assert.isTrue(result.freeze_used, "Should use freeze")
        TestFramework.assert.equal(freezes_before - 1, result.freezes_remaining, "Should have one less freeze")
        TestFramework.assert.equal(11, data.current_streak, "Streak should continue to 11")
        TestFramework.assert.equal(freezes_before - 1, data.streak_freezes, "Freezes should decrease")
    end,
    ["streak freeze - 3 day gap"] = function()
        setupSystem()
        -- Build 5 day streak
        for day = 1, 5 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Skip 3 days (still within freeze limit)
        setMockDate(2024, 1, 9)
        local result = DailyStreakSystem.checkDailyLogin()
        local data = getStreakData()
        TestFramework.assert.isTrue(result.freeze_used, "Should use freeze for 3 day gap")
        TestFramework.assert.equal(6, data.current_streak, "Streak should continue")
    end,
    ["streak broken - 4 day gap exceeds freeze"] = function()
        setupSystem()
        -- Build 5 day streak
        for day = 1, 5 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Skip 4 days (exceeds freeze limit)
        setMockDate(2024, 1, 10)
        local reward = DailyStreakSystem.checkDailyLogin()
        local data = getStreakData()
        TestFramework.assert.equal(1, reward.day, "Should reset to day 1")
        TestFramework.assert.equal(1, data.current_streak, "Streak should reset")
        TestFramework.assert.equal(3, data.streak_freezes, "Freezes should not be used")
    end,
    ["no freezes available"] = function()
        setupSystem()
        -- Use all freezes
        local data = getStreakData()
        data.streak_freezes = 0
        -- Build streak
        for day = 1, 5 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Skip a day
        setMockDate(2024, 1, 7)
        local reward = DailyStreakSystem.checkDailyLogin()
        data = getStreakData()
        TestFramework.assert.equal(1, reward.day, "Should reset without freezes")
        TestFramework.assert.equal(1, data.current_streak, "Streak should reset")
    end,
    ["monthly freeze reset"] = function()
        setupSystem()
        -- Use a freeze in January
        for day = 1, 5 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Skip a day and use freeze
        setMockDate(2024, 1, 7)
        DailyStreakSystem.checkDailyLogin()
        local january_freezes = getStreakData().streak_freezes
        TestFramework.assert.equal(2, january_freezes, "Should have used 1 freeze")
        -- Move to February
        setMockDate(2024, 2, 1)
        DailyStreakSystem.checkFreezeReset()
        local february_freezes = getStreakData().streak_freezes
        TestFramework.assert.equal(3, february_freezes, "Freezes should reset monthly")
    end,
    ["reward scaling"] = function()
        setupSystem()
        -- Day 1
        local day1 = DailyStreakSystem.getRewardForDay(1)
        TestFramework.assert.equal(100, day1.rings, "Day 1 base rings")
        -- Day 8 (week 2, 2x multiplier)
        local day8 = DailyStreakSystem.getRewardForDay(8)
        TestFramework.assert.equal(200, day8.rings, "Day 8 should have 2x multiplier")
        -- Day 15 (week 3, 3x multiplier)
        local day15 = DailyStreakSystem.getRewardForDay(15)
        TestFramework.assert.equal(900, day15.rings, "Day 15 should have 3x multiplier")
    end,
    ["special rewards"] = function()
        setupSystem()
        -- Check special reward days
        local day3 = DailyStreakSystem.getRewardForDay(3)
        TestFramework.assert.equal("bronze_ring_magnet", day3.special, "Day 3 special reward")
        local day7 = DailyStreakSystem.getRewardForDay(7)
        TestFramework.assert.equal("exclusive_planet_skin", day7.special, "Day 7 special reward")
        local day30 = DailyStreakSystem.getRewardForDay(30)
        TestFramework.assert.equal("legendary_effect", day30.special, "Day 30 special reward")
    end,
    ["milestone detection"] = function()
        setupSystem()
        local milestones = {7, 14, 30, 50, 100}
        for _, day in ipairs(milestones) do
            local reward = DailyStreakSystem.getRewardForDay(day)
            TestFramework.assert.isTrue(reward.is_milestone, "Day " .. day .. " should be milestone")
        end
        local non_milestones = {1, 5, 15, 25, 99}
        for _, day in ipairs(non_milestones) do
            local reward = DailyStreakSystem.getRewardForDay(day)
            TestFramework.assert.isFalse(reward.is_milestone, "Day " .. day .. " should not be milestone")
        end
    end,
    ["save and load data"] = function()
        setupSystem()
        -- Build some streak data
        for day = 1, 5 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        -- Save current state
        local data_before = getStreakData()
        DailyStreakSystem.saveData()
        -- Clear and reload
        DailyStreakSystem.init()
        DailyStreakSystem.loadData()
        local data_after = getStreakData()
        TestFramework.assert.equal(data_before.current_streak, data_after.current_streak, "Streak should persist")
        TestFramework.assert.equal(data_before.total_logins, data_after.total_logins, "Total logins should persist")
    end,
    ["date parsing"] = function()
        setupSystem()
        local parsed = DailyStreakSystem.parseDate("2024-01-15")
        TestFramework.assert.equal(2024, parsed.year, "Should parse year")
        TestFramework.assert.equal(1, parsed.month, "Should parse month")
        TestFramework.assert.equal(15, parsed.day, "Should parse day")
    end,
    ["days between calculation"] = function()
        setupSystem()
        local date1 = {year = 2024, month = 1, day = 1}
        local date2 = {year = 2024, month = 1, day = 5}
        local days = DailyStreakSystem.daysBetween(date1, date2)
        TestFramework.assert.equal(4, days, "Should calculate 4 days between")
    end,
    ["special reward names"] = function()
        setupSystem()
        local name = DailyStreakSystem.getSpecialRewardName("bronze_ring_magnet")
        TestFramework.assert.equal("Bronze Ring Magnet (5 min)", name, "Should return correct name")
        local unknown = DailyStreakSystem.getSpecialRewardName("unknown_reward")
        TestFramework.assert.equal("Special Reward", unknown, "Should handle unknown rewards")
    end,
    ["getter functions"] = function()
        setupSystem()
        -- Build streak
        for day = 1, 3 do
            setMockDate(2024, 1, day)
            DailyStreakSystem.checkDailyLogin()
        end
        TestFramework.assert.equal(3, DailyStreakSystem.getCurrentStreak(), "Should return current streak")
        TestFramework.assert.equal(3, DailyStreakSystem.getStreakFreezes(), "Should return freezes")
    end,
    ["very long streaks"] = function()
        setupSystem()
        -- Test day 100+
        local day150 = DailyStreakSystem.getRewardForDay(150)
        TestFramework.assert.isTrue(day150 ~= nil, "Should handle streaks beyond 100 days")
        TestFramework.assert.isTrue(day150.rings > 10000, "Should have high rewards for long streaks")
    end
}
-- Run the test suite
local function run()
    -- Restore original os functions after tests
    local success = TestFramework.runTests(tests, "Daily Streak System Tests")
    os.date = originalDate
    os.time = originalTime
    return success
end
return {run = run}