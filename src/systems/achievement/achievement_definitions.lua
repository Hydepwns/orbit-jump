-- Achievement Definitions Module
-- Contains all achievement data, tiers, and configurations

local AchievementDefinitions = {}

-- Tiered achievement definitions
AchievementDefinitions.achievements = {
  -- Explorer Category with Tiers
  {
    id = "planet_explorer",
    name = "Planet Explorer",
    category = "Explorer",
    description = "Visit unique planets",
    icon = "🌍",
    tiers = {
      {name = "Bronze", count = 10, points = 10, color = {0.7, 0.4, 0.2, 1}},
      {name = "Silver", count = 50, points = 25, color = {0.8, 0.8, 0.8, 1}},
      {name = "Gold", count = 100, points = 50, color = {1, 0.8, 0, 1}},
      {name = "Platinum", count = 250, points = 100, color = {0.8, 0.8, 1, 1}},
      {name = "Diamond", count = 500, points = 250, color = {0.8, 0.4, 1, 1}, reward = {type = "title", value = "Universe Explorer"}}
    }
  },
  
  -- Collector Category with Tiers
  {
    id = "ring_baron",
    name = "Ring Baron",
    category = "Collector",
    description = "Collect rings",
    icon = "💍",
    tiers = {
      {name = "Bronze", count = 100, points = 10, color = {0.7, 0.4, 0.2, 1}},
      {name = "Silver", count = 1000, points = 25, color = {0.8, 0.8, 0.8, 1}},
      {name = "Gold", count = 5000, points = 50, color = {1, 0.8, 0, 1}},
      {name = "Platinum", count = 10000, points = 100, color = {0.8, 0.8, 1, 1}},
      {name = "Diamond", count = 50000, points = 250, color = {0.8, 0.4, 1, 1}, reward = {type = "title", value = "Ring Baron"}}
    }
  },
  
  -- Perfectionist Category with Tiers
  {
    id = "combo_virtuoso",
    name = "Combo Virtuoso",
    category = "Perfectionist",
    description = "Achieve perfect combos",
    icon = "🔥",
    tiers = {
      {name = "Bronze", count = 5, points = 10, color = {0.7, 0.4, 0.2, 1}},
      {name = "Silver", count = 25, points = 25, color = {0.8, 0.8, 0.8, 1}},
      {name = "Gold", count = 50, points = 50, color = {1, 0.8, 0, 1}},
      {name = "Platinum", count = 100, points = 100, color = {0.8, 0.8, 1, 1}},
      {name = "Diamond", count = 250, points = 250, color = {0.8, 0.4, 1, 1}, reward = {type = "title", value = "Flawless"}}
    }
  },
  
  -- Legacy single-tier achievements (keeping for compatibility)
  {
    id = "first_planet",
    name = "Baby Steps",
    description = "Discover your first planet",
    icon = "🌍",
    points = 10,
    unlocked = false,
    progress = 0,
    target = 1
  },
  {
    id = "planet_hopper",
    name = "Planet Hopper",
    description = "Discover 10 planets",
    icon = "🚀",
    points = 50,
    unlocked = false,
    progress = 0,
    target = 10
  },
  {
    id = "space_explorer",
    name = "Space Explorer",
    description = "Discover 25 planets",
    icon = "🌌",
    points = 100,
    unlocked = false,
    progress = 0,
    target = 25
  },
  {
    id = "void_walker",
    name = "Void Walker",
    description = "Travel 5000 units from origin",
    icon = "👻",
    points = 200,
    unlocked = false,
    progress = 0,
    target = 5000
  }
}

-- Achievement categories
AchievementDefinitions.categories = {
  "Explorer",
  "Collector", 
  "Perfectionist",
  "Legacy"
}

-- Get achievement by ID
function AchievementDefinitions.getAchievement(id)
  for _, achievement in ipairs(AchievementDefinitions.achievements) do
    if achievement.id == id then
      return achievement
    end
  end
  return nil
end

-- Get achievements by category
function AchievementDefinitions.getAchievementsByCategory(category)
  local categoryAchievements = {}
  for _, achievement in ipairs(AchievementDefinitions.achievements) do
    if achievement.category == category then
      table.insert(categoryAchievements, achievement)
    end
  end
  return categoryAchievements
end

-- Get all tiered achievements
function AchievementDefinitions.getTieredAchievements()
  local tieredAchievements = {}
  for _, achievement in ipairs(AchievementDefinitions.achievements) do
    if achievement.tiers then
      table.insert(tieredAchievements, achievement)
    end
  end
  return tieredAchievements
end

-- Get all legacy achievements
function AchievementDefinitions.getLegacyAchievements()
  local legacyAchievements = {}
  for _, achievement in ipairs(AchievementDefinitions.achievements) do
    if not achievement.tiers then
      table.insert(legacyAchievements, achievement)
    end
  end
  return legacyAchievements
end

return AchievementDefinitions 