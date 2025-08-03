-- Daily Streak System for login rewards and retention
local DailyStreakSystem = {}
local streak_data = {
    current_streak = 0,
    longest_streak = 0,
    last_login_date = nil,
    streak_freezes = 3, -- 3 free streak freezes per month
    freeze_reset_date = nil,
    total_logins = 0,
    rewards_claimed = {},
    milestone_rewards_claimed = {}
}
-- Daily rewards that compound
local DAILY_REWARDS = {
    {day = 1, rings = 100, xp = 50, special = nil},
    {day = 2, rings = 200, xp = 100, special = nil},
    {day = 3, rings = 300, xp = 150, special = "bronze_ring_magnet"}, -- 5 minute ring magnet
    {day = 4, rings = 400, xp = 200, special = nil},
    {day = 5, rings = 500, xp = 250, special = "silver_cosmetic"}, -- Random silver cosmetic
    {day = 6, rings = 600, xp = 300, special = nil},
    {day = 7, rings = 1000, xp = 500, special = "exclusive_planet_skin"}, -- Weekly exclusive
    {day = 14, rings = 2000, xp = 1000, special = "gold_cosmetic"}, -- 2 week milestone
    {day = 30, rings = 5000, xp = 2500, special = "legendary_effect"}, -- Monthly legendary
    {day = 50, rings = 10000, xp = 5000, special = "prestige_boost"}, -- 50 day milestone
    {day = 100, rings = 25000, xp = 10000, special = "ultimate_reward"} -- 100 day ultimate
}
-- Visual calendar configuration
local CALENDAR_CONFIG = {
    start_x = 100,
    start_y = 150,
    cell_size = 60,
    cell_padding = 5,
    days_per_row = 7
}
function DailyStreakSystem.init()
    -- Load saved streak data
    DailyStreakSystem.loadData()
    -- Check if freeze reset is needed (monthly)
    DailyStreakSystem.checkFreezeReset()
end
function DailyStreakSystem.checkDailyLogin()
    local current_date = os.date("*t")
    local today_string = string.format("%d-%02d-%02d", current_date.year, current_date.month, current_date.day)
    -- First login ever
    if not streak_data.last_login_date then
        streak_data.current_streak = 1
        streak_data.longest_streak = 1
        streak_data.last_login_date = today_string
        streak_data.total_logins = 1
        DailyStreakSystem.saveData()
        return DailyStreakSystem.getRewardForDay(1)
    end
    -- Check if already logged in today
    if streak_data.last_login_date == today_string then
        return nil -- Already claimed today
    end
    -- Calculate days since last login
    local last_date = DailyStreakSystem.parseDate(streak_data.last_login_date)
    local days_diff = DailyStreakSystem.daysBetween(last_date, current_date)
    if days_diff == 1 then
        -- Consecutive day login
        streak_data.current_streak = streak_data.current_streak + 1
        streak_data.longest_streak = math.max(streak_data.longest_streak, streak_data.current_streak)
    elseif days_diff > 1 then
        -- Streak broken, check for freeze
        if streak_data.streak_freezes > 0 and days_diff <= 3 then
            -- Use a freeze to maintain streak
            streak_data.streak_freezes = streak_data.streak_freezes - 1
            streak_data.current_streak = streak_data.current_streak + 1
            streak_data.longest_streak = math.max(streak_data.longest_streak, streak_data.current_streak)
            -- Notify about freeze usage
            return {
                freeze_used = true,
                freezes_remaining = streak_data.streak_freezes,
                reward = DailyStreakSystem.getRewardForDay(streak_data.current_streak)
            }
        else
            -- Streak broken
            streak_data.current_streak = 1
        end
    end
    -- Update login tracking
    streak_data.last_login_date = today_string
    streak_data.total_logins = streak_data.total_logins + 1
    -- Save updated data
    DailyStreakSystem.saveData()
    -- Return today's reward
    return DailyStreakSystem.getRewardForDay(streak_data.current_streak)
end
function DailyStreakSystem.getRewardForDay(day)
    local reward = nil
    -- Find the appropriate reward tier
    for i = #DAILY_REWARDS, 1, -1 do
        if day >= DAILY_REWARDS[i].day then
            reward = DAILY_REWARDS[i]
            break
        end
    end
    -- Default to day 1 reward if nothing found
    if not reward then
        reward = DAILY_REWARDS[1]
    end
    -- Scale rewards based on actual streak day
    local day_multiplier = math.floor(day / 7) + 1 -- Extra bonus every week
    return {
        day = day,
        rings = reward.rings * day_multiplier,
        xp = reward.xp * day_multiplier,
        special = reward.special,
        is_milestone = (day == 7 or day == 14 or day == 30 or day == 50 or day == 100)
    }
end
function DailyStreakSystem.draw()
    -- Draw streak counter
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.print("🔥 " .. streak_data.current_streak, 10, 50)
    -- Draw freeze indicators
    if streak_data.streak_freezes > 0 then
        love.graphics.setColor(0.5, 0.8, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        for i = 1, streak_data.streak_freezes do
            love.graphics.print("❄", 10 + (i - 1) * 20, 80)
        end
    end
end
function DailyStreakSystem.drawCalendar()
    -- Background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    -- Title
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(love.graphics.newFont(36))
    love.graphics.printf("DAILY STREAK CALENDAR", 0, 30, love.graphics.getWidth(), "center")
    -- Current streak info
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("Current Streak: " .. streak_data.current_streak .. " days", 0, 80, love.graphics.getWidth(), "center")
    love.graphics.printf("Longest Streak: " .. streak_data.longest_streak .. " days", 0, 105, love.graphics.getWidth(), "center")
    -- Calendar grid
    local x = CALENDAR_CONFIG.start_x
    local y = CALENDAR_CONFIG.start_y
    -- Draw upcoming rewards
    love.graphics.setFont(love.graphics.newFont(14))
    for day = 1, 30 do
        local cell_x = x + ((day - 1) % CALENDAR_CONFIG.days_per_row) * (CALENDAR_CONFIG.cell_size + CALENDAR_CONFIG.cell_padding)
        local cell_y = y + math.floor((day - 1) / CALENDAR_CONFIG.days_per_row) * (CALENDAR_CONFIG.cell_size + CALENDAR_CONFIG.cell_padding)
        -- Determine cell state
        if day <= streak_data.current_streak then
            -- Completed day
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.rectangle("fill", cell_x, cell_y, CALENDAR_CONFIG.cell_size, CALENDAR_CONFIG.cell_size)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print("✓", cell_x + 20, cell_y + 20)
        elseif day == streak_data.current_streak + 1 then
            -- Today
            love.graphics.setColor(1, 0.8, 0, 1)
            love.graphics.rectangle("line", cell_x, cell_y, CALENDAR_CONFIG.cell_size, CALENDAR_CONFIG.cell_size, 5)
            love.graphics.setColor(1, 1, 1, 1)
        else
            -- Future day
            love.graphics.setColor(0.3, 0.3, 0.3, 1)
            love.graphics.rectangle("line", cell_x, cell_y, CALENDAR_CONFIG.cell_size, CALENDAR_CONFIG.cell_size)
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
        end
        -- Day number
        love.graphics.print(day, cell_x + 5, cell_y + 5)
        -- Special reward indicators
        local reward = DailyStreakSystem.getRewardForDay(day)
        if reward.special then
            love.graphics.setColor(1, 0.8, 0, 1)
            love.graphics.print("★", cell_x + 40, cell_y + 40)
        end
    end
    -- Reward preview for next day
    local next_reward = DailyStreakSystem.getRewardForDay(streak_data.current_streak + 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("Tomorrow's Reward:", 0, 450, love.graphics.getWidth(), "center")
    love.graphics.setFont(love.graphics.newFont(16))
    local reward_text = next_reward.rings .. " Rings, " .. next_reward.xp .. " XP"
    if next_reward.special then
        reward_text = reward_text .. "\n+ " .. DailyStreakSystem.getSpecialRewardName(next_reward.special)
    end
    love.graphics.printf(reward_text, 0, 480, love.graphics.getWidth(), "center")
    -- Freeze info
    love.graphics.setColor(0.5, 0.8, 1, 1)
    love.graphics.setFont(love.graphics.newFont(14))
    love.graphics.printf("Streak Freezes: " .. streak_data.streak_freezes .. "/3 (Reset monthly)",
        0, love.graphics.getHeight() - 40, love.graphics.getWidth(), "center")
end
function DailyStreakSystem.drawRewardNotification(reward)
    -- Animated reward popup
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 - 150, 400, 300)
    -- Title
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("DAILY REWARD!", love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 - 130, 400, "center")
    -- Day counter
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Day " .. reward.day, love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 - 80, 400, "center")
    -- Rewards
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.printf("+" .. reward.rings .. " Rings", love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 - 30, 400, "center")
    love.graphics.printf("+" .. reward.xp .. " XP", love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2, 400, "center")
    -- Special reward
    if reward.special then
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.printf("★ " .. DailyStreakSystem.getSpecialRewardName(reward.special),
            love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 + 40, 400, "center")
    end
    -- Milestone celebration
    if reward.is_milestone then
        love.graphics.setColor(1, 1, 0, 1)
        love.graphics.setFont(love.graphics.newFont(28))
        love.graphics.printf("MILESTONE ACHIEVED!", love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 + 80, 400, "center")
    end
end
function DailyStreakSystem.getSpecialRewardName(reward_id)
    local names = {
        bronze_ring_magnet = "Bronze Ring Magnet (5 min)",
        silver_cosmetic = "Silver Trail Effect",
        exclusive_planet_skin = "Exclusive Planet Skin",
        gold_cosmetic = "Gold Particle Effect",
        legendary_effect = "Legendary Landing Effect",
        prestige_boost = "Double Prestige Points (24h)",
        ultimate_reward = "Ultimate Champion Set"
    }
    return names[reward_id] or "Special Reward"
end
function DailyStreakSystem.checkFreezeReset()
    local current_date = os.date("*t")
    local current_month = string.format("%d-%02d", current_date.year, current_date.month)
    if streak_data.freeze_reset_date ~= current_month then
        streak_data.streak_freezes = 3
        streak_data.freeze_reset_date = current_month
        DailyStreakSystem.saveData()
    end
end
function DailyStreakSystem.parseDate(date_string)
    local year, month, day = date_string:match("(%d+)-(%d+)-(%d+)")
    return {year = tonumber(year), month = tonumber(month), day = tonumber(day)}
end
function DailyStreakSystem.daysBetween(date1, date2)
    local time1 = os.time(date1)
    local time2 = os.time(date2)
    return math.floor(math.abs(time2 - time1) / (24 * 60 * 60))
end
function DailyStreakSystem.saveData()
    local save_data = {
        streak_data = streak_data
    }
    love.filesystem.write("daily_streak_save.lua", TSerial.pack(save_data))
end
function DailyStreakSystem.loadData()
    if love.filesystem.getInfo("daily_streak_save.lua") then
        local contents = love.filesystem.read("daily_streak_save.lua")
        local save_data = TSerial.unpack(contents)
        if save_data and save_data.streak_data then
            streak_data = save_data.streak_data
        end
    end
end
function DailyStreakSystem.getData()
    return streak_data
end
function DailyStreakSystem.getCurrentStreak()
    return streak_data.current_streak
end
function DailyStreakSystem.getStreakFreezes()
    return streak_data.streak_freezes
end
return DailyStreakSystem