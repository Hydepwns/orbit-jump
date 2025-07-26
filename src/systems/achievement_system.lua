-- Achievement System for Orbit Jump
-- Provides instant gratification and progression tracking

local Utils = require("src.utils.utils")
local AchievementSystem = {}

-- Achievement definitions
AchievementSystem.achievements = {
  -- Discovery achievements
  first_planet = {
    id = "first_planet",
    name = "Baby Steps",
    description = "Discover your first planet",
    icon = "🌍",
    points = 10,
    unlocked = false,
    progress = 0,
    target = 1
  },
  planet_hopper = {
    id = "planet_hopper",
    name = "Planet Hopper",
    description = "Discover 10 planets",
    icon = "🚀",
    points = 50,
    unlocked = false,
    progress = 0,
    target = 10
  },
  space_explorer = {
    id = "space_explorer",
    name = "Space Explorer",
    description = "Discover 25 planets",
    icon = "🌌",
    points = 100,
    unlocked = false,
    progress = 0,
    target = 25
  },
  void_walker = {
    id = "void_walker",
    name = "Void Walker",
    description = "Travel 5000 units from origin",
    icon = "👻",
    points = 200,
    unlocked = false,
    progress = 0,
    target = 5000
  },

  -- Ring achievements
  ring_collector = {
    id = "ring_collector",
    name = "Ring Collector",
    description = "Collect 100 rings",
    icon = "💍",
    points = 50,
    unlocked = false,
    progress = 0,
    target = 100
  },
  power_user = {
    id = "power_user",
    name = "Power User",
    description = "Collect all 4 power ring types",
    icon = "⚡",
    points = 100,
    unlocked = false,
    progress = 0,
    target = 4,
    special = true
  },
  chain_master = {
    id = "chain_master",
    name = "Chain Master",
    description = "Complete a 5-ring chain",
    icon = "⛓️",
    points = 150,
    unlocked = false,
    progress = 0,
    target = 5
  },

  -- Skill achievements
  combo_king = {
    id = "combo_king",
    name = "Combo King",
    description = "Reach a 20x combo",
    icon = "🔥",
    points = 100,
    unlocked = false,
    progress = 0,
    target = 20
  },
  speed_demon = {
    id = "speed_demon",
    name = "Speed Demon",
    description = "Dash 50 times",
    icon = "💨",
    points = 50,
    unlocked = false,
    progress = 0,
    target = 50
  },
  perfect_landing = {
    id = "perfect_landing",
    name = "Perfect Landing",
    description = "Land on 10 planets without missing",
    icon = "🎯",
    points = 75,
    unlocked = false,
    progress = 0,
    target = 10
  },

  -- Planet type achievements
  ice_breaker = {
    id = "ice_breaker",
    name = "Ice Breaker",
    description = "Land on 5 ice planets",
    icon = "❄️",
    points = 50,
    unlocked = false,
    progress = 0,
    target = 5
  },
  lava_surfer = {
    id = "lava_surfer",
    name = "Lava Surfer",
    description = "Use 10 lava eruptions",
    icon = "🌋",
    points = 75,
    unlocked = false,
    progress = 0,
    target = 10
  },
  tech_savvy = {
    id = "tech_savvy",
    name = "Tech Savvy",
    description = "Experience 20 gravity pulses",
    icon = "🤖",
    points = 75,
    unlocked = false,
    progress = 0,
    target = 20
  },
  void_master = {
    id = "void_master",
    name = "Void Master",
    description = "Survive 5 void planets",
    icon = "🕳️",
    points = 100,
    unlocked = false,
    progress = 0,
    target = 5
  },
  constellation_artist = {
    id = "constellation_artist",
    name = "Constellation Artist",
    description = "Complete 10 ring constellations",
    icon = "✨",
    points = 75,
    unlocked = false,
    progress = 0,
    target = 10
  },
  star_maker = {
    id = "star_maker",
    name = "Star Maker",
    description = "Complete 5 Star Formation patterns",
    icon = "⭐",
    points = 50,
    unlocked = false,
    progress = 0,
    target = 5
  },
  infinity_master = {
    id = "infinity_master",
    name = "Infinity Master",
    description = "Complete the Infinite Loop pattern",
    icon = "♾️",
    points = 100,
    unlocked = false,
    progress = 0,
    target = 1
  }
}

-- Active notifications
AchievementSystem.notifications = {}
AchievementSystem.notificationDuration = 3.0

-- Stats tracking
AchievementSystem.stats = {
  planetsDiscovered = 0,
  ringsCollected = 0,
  maxCombo = 0,
  totalDashes = 0,
  perfectLandings = 0,
  maxDistance = 0,
  powerRingsCollected = {},
  planetTypesVisited = {
    ice = 0,
    lava = 0,
    tech = 0,
    void = 0
  },
  lavaEruptions = 0,
  gravityPulses = 0,
  chainCompleted = 0
}

-- Save/Load functionality
function AchievementSystem.getSaveData()
  local saveData = {
    achievements = {},
    stats = AchievementSystem.stats
  }

  for id, achievement in pairs(AchievementSystem.achievements) do
    saveData.achievements[id] = {
      unlocked = achievement.unlocked,
      progress = achievement.progress
    }
  end

  return saveData
end

function AchievementSystem.loadSaveData(data)
  if not data then return end

  -- Load stats
  if data.stats then
    AchievementSystem.stats = data.stats
  end

  -- Load achievement progress
  if data.achievements then
    for id, savedAchievement in pairs(data.achievements) do
      if AchievementSystem.achievements[id] then
        AchievementSystem.achievements[id].unlocked = savedAchievement.unlocked
        AchievementSystem.achievements[id].progress = savedAchievement.progress
      end
    end
  end
end

-- Progress tracking
function AchievementSystem.updateProgress(achievementId, progress)
  local achievement = AchievementSystem.achievements[achievementId]
  if not achievement or achievement.unlocked then return end

  -- Ensure progress is not negative
  progress = math.max(0, progress)
  achievement.progress = math.min(progress, achievement.target)

  -- Check if completed
  if achievement.progress >= achievement.target then
    AchievementSystem.unlock(achievementId)
  end
end

function AchievementSystem.incrementProgress(achievementId, amount)
  local achievement = AchievementSystem.achievements[achievementId]
  if not achievement or achievement.unlocked then return end

  achievement.progress = math.min(achievement.progress + (amount or 1), achievement.target)

  -- Check if completed
  if achievement.progress >= achievement.target then
    AchievementSystem.unlock(achievementId)
  end
end

-- Check progress for dynamic achievements
function AchievementSystem.checkProgress(achievementData)
  local achievement = AchievementSystem.achievements[achievementData.id]
  if not achievement then
    -- Create dynamic achievement if it doesn't exist
    AchievementSystem.achievements[achievementData.id] = achievementData
    achievement = achievementData
  end

  if not achievement.unlocked then
    achievement.progress = achievementData.progress or 0

    -- Check if completed
    if achievement.progress >= achievement.target then
      return AchievementSystem.unlock(achievementData.id)
    end
  end

  return nil
end

-- Unlock achievement
function AchievementSystem.unlock(achievementId)
  local achievement = AchievementSystem.achievements[achievementId]
  if not achievement or achievement.unlocked then return end

  achievement.unlocked = true
  achievement.progress = achievement.target

  -- Create notification
  table.insert(AchievementSystem.notifications, {
    achievement = achievement,
    timer = AchievementSystem.notificationDuration,
    y = -100,     -- Start off-screen
    targetY = 50
  })

  -- Play sound effect if available
  local soundManager = Utils.require("src.audio.sound_manager")
  if soundManager and soundManager.playAchievement then
    soundManager:playAchievement()
  end

  -- Log the achievement
  Utils.Logger.info("Achievement unlocked: %s", achievement.name)

  -- Add points to upgrade system
  local UpgradeSystem = Utils.require("src.systems.upgrade_system")
  UpgradeSystem.addCurrency(achievement.points)

  -- Return points earned
  return achievement.points
end

-- Update notifications
function AchievementSystem.update(dt)
  for i = #AchievementSystem.notifications, 1, -1 do
    local notification = AchievementSystem.notifications[i]

    -- Animate slide in
    if notification.y < notification.targetY then
      notification.y = notification.y + (notification.targetY - notification.y) * dt * 10
    end

    -- Update timer
    notification.timer = notification.timer - dt

    -- Animate slide out
    if notification.timer < 0.5 then
      notification.targetY = -100
    end

    -- Remove when done
    if notification.timer <= 0 then
      table.remove(AchievementSystem.notifications, i)
    end
  end
end

-- Draw notifications
function AchievementSystem.draw()
  for _, notification in ipairs(AchievementSystem.notifications) do
    local achievement = notification.achievement
    local alpha = math.min(notification.timer, 1)

    -- Background
    love.graphics.setColor(0, 0, 0, alpha * 0.8)
    love.graphics.rectangle("fill",
      love.graphics.getWidth() / 2 - 200,
      notification.y,
      400, 80, 10)

    -- Border glow
    love.graphics.setColor(1, 0.8, 0.2, alpha * 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",
      love.graphics.getWidth() / 2 - 200,
      notification.y,
      400, 80, 10)

    -- Icon background
    love.graphics.setColor(1, 0.8, 0.2, alpha * 0.3)
    love.graphics.circle("fill",
      love.graphics.getWidth() / 2 - 150,
      notification.y + 40, 30)

    -- Achievement text
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.print("ACHIEVEMENT UNLOCKED!",
      love.graphics.getWidth() / 2 - 60,
      notification.y + 10)

    love.graphics.print(achievement.name,
      love.graphics.getWidth() / 2 - 60,
      notification.y + 30)

    love.graphics.setColor(0.8, 0.8, 0.8, alpha)
    love.graphics.print(achievement.description,
      love.graphics.getWidth() / 2 - 60,
      notification.y + 50)

    -- Points
    love.graphics.setColor(1, 0.8, 0.2, alpha)
    love.graphics.print("+" .. achievement.points .. " pts",
      love.graphics.getWidth() / 2 + 120,
      notification.y + 30)
  end
end

-- Event handlers
function AchievementSystem.onPlanetDiscovered(planetType)
  AchievementSystem.stats.planetsDiscovered = AchievementSystem.stats.planetsDiscovered + 1

  -- Update achievements
  AchievementSystem.updateProgress("first_planet", AchievementSystem.stats.planetsDiscovered)
  AchievementSystem.updateProgress("planet_hopper", AchievementSystem.stats.planetsDiscovered)
  AchievementSystem.updateProgress("space_explorer", AchievementSystem.stats.planetsDiscovered)

  -- Planet type specific
  if planetType then
    AchievementSystem.stats.planetTypesVisited[planetType] =
        (AchievementSystem.stats.planetTypesVisited[planetType] or 0) + 1

    if planetType == "ice" then
      AchievementSystem.updateProgress("ice_breaker", AchievementSystem.stats.planetTypesVisited.ice)
    elseif planetType == "void" then
      AchievementSystem.updateProgress("void_master", AchievementSystem.stats.planetTypesVisited.void)
    end
  end
end

function AchievementSystem.onRingCollected(ringType)
  AchievementSystem.stats.ringsCollected = AchievementSystem.stats.ringsCollected + 1
  AchievementSystem.updateProgress("ring_collector", AchievementSystem.stats.ringsCollected)

  -- Track power rings
  if ringType and string.find(ringType, "power_") then
    AchievementSystem.stats.powerRingsCollected[ringType] = true
    local count = 0
    for _ in pairs(AchievementSystem.stats.powerRingsCollected) do
      count = count + 1
    end
    AchievementSystem.updateProgress("power_user", count)
  end
end

function AchievementSystem.onComboReached(combo)
  if combo > AchievementSystem.stats.maxCombo then
    AchievementSystem.stats.maxCombo = combo
    AchievementSystem.updateProgress("combo_king", combo)
  end
end

function AchievementSystem.onDash()
  AchievementSystem.stats.totalDashes = AchievementSystem.stats.totalDashes + 1
  AchievementSystem.updateProgress("speed_demon", AchievementSystem.stats.totalDashes)
end

function AchievementSystem.onPerfectLanding()
  AchievementSystem.stats.perfectLandings = AchievementSystem.stats.perfectLandings + 1
  AchievementSystem.updateProgress("perfect_landing", AchievementSystem.stats.perfectLandings)
end

function AchievementSystem.onDistanceReached(distance)
  if distance > AchievementSystem.stats.maxDistance then
    AchievementSystem.stats.maxDistance = distance
    AchievementSystem.updateProgress("void_walker", distance)
  end
end

function AchievementSystem.onLavaEruption()
  AchievementSystem.stats.lavaEruptions = AchievementSystem.stats.lavaEruptions + 1
  AchievementSystem.updateProgress("lava_surfer", AchievementSystem.stats.lavaEruptions)
end

function AchievementSystem.onGravityPulse()
  AchievementSystem.stats.gravityPulses = AchievementSystem.stats.gravityPulses + 1
  AchievementSystem.updateProgress("tech_savvy", AchievementSystem.stats.gravityPulses)
end

function AchievementSystem.onChainCompleted(length)
  if length > AchievementSystem.stats.chainCompleted then
    AchievementSystem.stats.chainCompleted = length
    AchievementSystem.updateProgress("chain_master", length)
  end
end

function AchievementSystem.onWarpZoneDiscovered()
  AchievementSystem.stats.warpsDiscovered = (AchievementSystem.stats.warpsDiscovered or 0) + 1
  -- Check for secret finder achievement (discover 5 warp zones)
  if AchievementSystem.stats.warpsDiscovered >= 5 then
    AchievementSystem.checkProgress({
      id = "secret_finder",
      name = "Secret Finder",
      description = "Discover 5 warp zones",
      icon = "🔍",
      points = 100,
      progress = AchievementSystem.stats.warpsDiscovered,
      target = 5
    })
  end
end

function AchievementSystem.onWarpZoneCompleted(zoneType)
  AchievementSystem.stats.warpsCompleted = (AchievementSystem.stats.warpsCompleted or 0) + 1
  AchievementSystem.stats.warpTypes = AchievementSystem.stats.warpTypes or {}
  AchievementSystem.stats.warpTypes[zoneType] = true

  -- Check for warp master achievement (complete 10 warp zones)
  if AchievementSystem.stats.warpsCompleted >= 10 then
    AchievementSystem.checkProgress({
      id = "warp_master",
      name = "Warp Master",
      description = "Complete 10 warp zone challenges",
      icon = "🌌",
      points = 200,
      progress = AchievementSystem.stats.warpsCompleted,
      target = 10
    })
  end
end

function AchievementSystem.onArtifactCollected(artifactId)
  AchievementSystem.stats.artifactsCollected = (AchievementSystem.stats.artifactsCollected or 0) + 1

  -- Check for artifact collector achievement
  if AchievementSystem.stats.artifactsCollected >= 5 then
    AchievementSystem.checkProgress({
      id = "artifact_collector",
      name = "Artifact Collector",
      description = "Collect 5 ancient artifacts",
      icon = "💎",
      points = 150,
      progress = AchievementSystem.stats.artifactsCollected,
      target = 5
    })
  end
end

function AchievementSystem.onAllArtifactsCollected()
  AchievementSystem.checkProgress({
    id = "lore_master",
    name = "Lore Master",
    description = "Discover the complete truth",
    icon = "📜",
    points = 500,
    progress = 1,
    target = 1
  })
end

-- Get total points
function AchievementSystem.getTotalPoints()
  local total = 0
  for _, achievement in pairs(AchievementSystem.achievements) do
    if achievement.unlocked then
      total = total + achievement.points
    end
  end
  return total
end

-- Get completion percentage
function AchievementSystem.getCompletionPercentage()
  local unlocked = 0
  local total = 0
  for _, achievement in pairs(AchievementSystem.achievements) do
    total = total + 1
    if achievement.unlocked then
      unlocked = unlocked + 1
    end
  end
  return (unlocked / total) * 100
end

-- Track constellation completion
function AchievementSystem.onConstellationComplete(patternId)
  -- Track overall constellation completions
  AchievementSystem.incrementProgress("constellation_artist", 1)

  -- Track specific patterns
  if patternId == "star" then
    AchievementSystem.incrementProgress("star_maker", 1)
  elseif patternId == "infinity" then
    AchievementSystem.incrementProgress("infinity_master", 1)
  end

  Utils.Logger.info("Constellation completed: %s", patternId)
end

return AchievementSystem
