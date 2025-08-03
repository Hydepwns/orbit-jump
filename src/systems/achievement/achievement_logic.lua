-- Achievement Logic Module
-- Handles achievement progress tracking, unlocking, and tier management
local Utils = require("src.utils.utils")
local AchievementDefinitions = require("src.systems.achievement.achievement_definitions")
local AchievementLogic = {}
-- Achievement progress state
AchievementLogic.progress = {}
AchievementLogic.categories = {}
AchievementLogic.total_points = 0
AchievementLogic.visited_planets = {}
-- Initialize achievement logic
function AchievementLogic.init()
  AchievementLogic.progress = {}
  AchievementLogic.categories = {}
  AchievementLogic.total_points = 0
  AchievementLogic.visited_planets = {}
  -- Initialize progress for all achievements
  for _, achievement in ipairs(AchievementDefinitions.achievements) do
    if achievement.tiers then
      -- Tiered achievement
      AchievementLogic.progress[achievement.id] = {
        current_tier = 0,
        progress = 0,
        unlocked_tiers = {},
        total_points_earned = 0
      }
    else
      -- Legacy achievement
      AchievementLogic.progress[achievement.id] = {
        unlocked = false,
        progress = 0,
        points_earned = 0
      }
    end
  end
  Utils.Logger.info("Achievement logic initialized")
end
-- Update achievement progress
function AchievementLogic.updateProgress(achievementId, progress, data)
  local achievement = AchievementDefinitions.getAchievement(achievementId)
  if not achievement then
    Utils.Logger.warning("Attempted to update non-existent achievement: %s", achievementId)
    return false
  end
  if achievement.tiers then
    return AchievementLogic.updateTieredProgress(achievement, progress, data)
  else
    return AchievementLogic.updateLegacyProgress(achievement, progress, data)
  end
end
-- Update tiered achievement progress
function AchievementLogic.updateTieredProgress(achievement, progress, data)
  local progressData = AchievementLogic.progress[achievement.id]
  if not progressData then
    progressData = {
      current_tier = 0,
      progress = 0,
      unlocked_tiers = {},
      total_points_earned = 0
    }
    AchievementLogic.progress[achievement.id] = progressData
  end
  progressData.progress = progress
  -- Check for new tier unlocks
  local newTiersUnlocked = {}
  for i, tier in ipairs(achievement.tiers) do
    if progress >= tier.count and not progressData.unlocked_tiers[i] then
      progressData.unlocked_tiers[i] = true
      progressData.current_tier = i
      progressData.total_points_earned = progressData.total_points_earned + tier.points
      AchievementLogic.total_points = AchievementLogic.total_points + tier.points
      table.insert(newTiersUnlocked, {
        achievement = achievement,
        tier = tier,
        tier_index = i
      })
      Utils.Logger.info("Achievement tier unlocked: %s - %s", achievement.name, tier.name)
    end
  end
  -- Trigger unlock events
  for _, unlock in ipairs(newTiersUnlocked) do
    AchievementLogic.triggerUnlockEvent(unlock.achievement, unlock.tier, unlock.tier_index)
  end
  return #newTiersUnlocked > 0
end
-- Update legacy achievement progress
function AchievementLogic.updateLegacyProgress(achievement, progress, data)
  local progressData = AchievementLogic.progress[achievement.id]
  if not progressData then
    progressData = {
      unlocked = false,
      progress = 0,
      points_earned = 0
    }
    AchievementLogic.progress[achievement.id] = progressData
  end
  progressData.progress = progress
  -- Check for unlock
  if progress >= achievement.target and not progressData.unlocked then
    progressData.unlocked = true
    progressData.points_earned = achievement.points
    AchievementLogic.total_points = AchievementLogic.total_points + achievement.points
    Utils.Logger.info("Legacy achievement unlocked: %s", achievement.name)
    AchievementLogic.triggerUnlockEvent(achievement, nil, nil)
    return true
  end
  return false
end
-- Trigger achievement unlock event
function AchievementLogic.triggerUnlockEvent(achievement, tier, tierIndex)
  -- This will be handled by the notification system
  local eventData = {
    type = "achievement_unlocked",
    achievement = achievement,
    tier = tier,
    tier_index = tierIndex,
    points = tier and tier.points or achievement.points
  }
  -- Emit event for other systems to handle
  if Utils.EventEmitter then
    Utils.EventEmitter.emit("achievement_unlocked", eventData)
  end
end
-- Get achievement progress
function AchievementLogic.getProgress(achievementId)
  return AchievementLogic.progress[achievementId]
end
-- Get total points earned
function AchievementLogic.getTotalPoints()
  return AchievementLogic.total_points
end
-- Get unlocked achievements count
function AchievementLogic.getUnlockedCount()
  local count = 0
  for _, progressData in pairs(AchievementLogic.progress) do
    if progressData.unlocked or (progressData.unlocked_tiers and #progressData.unlocked_tiers > 0) then
      count = count + 1
    end
  end
  return count
end
-- Get achievements by completion status
function AchievementLogic.getAchievementsByStatus(completed)
  local achievements = {}
  for _, achievement in ipairs(AchievementDefinitions.achievements) do
    local progressData = AchievementLogic.progress[achievement.id]
    local isCompleted = false
    if achievement.tiers then
      -- Tiered achievement
      isCompleted = progressData and progressData.current_tier > 0
    else
      -- Legacy achievement
      isCompleted = progressData and progressData.unlocked
    end
    if isCompleted == completed then
      table.insert(achievements, {
        achievement = achievement,
        progress = progressData
      })
    end
  end
  return achievements
end
-- Save achievement progress
function AchievementLogic.saveProgress()
  local saveData = {
    progress = AchievementLogic.progress,
    total_points = AchievementLogic.total_points,
    visited_planets = AchievementLogic.visited_planets
  }
  return Utils.saveData("achievements", saveData)
end
-- Load achievement progress
function AchievementLogic.loadProgress()
  local saveData = Utils.loadData("achievements")
  if saveData then
    AchievementLogic.progress = saveData.progress or {}
    AchievementLogic.total_points = saveData.total_points or 0
    AchievementLogic.visited_planets = saveData.visited_planets or {}
    Utils.Logger.info("Achievement progress loaded - Total points: %d", AchievementLogic.total_points)
    return true
  end
  return false
end
-- Reset all achievement progress
function AchievementLogic.resetProgress()
  AchievementLogic.progress = {}
  AchievementLogic.total_points = 0
  AchievementLogic.visited_planets = {}
  AchievementLogic.init()
  Utils.Logger.info("Achievement progress reset")
end
return AchievementLogic