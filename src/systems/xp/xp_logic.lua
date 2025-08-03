-- XP Logic Module
-- Handles XP progression, leveling up, and reward management

local Utils = require("src.utils.utils")
local XPDefinitions = require("src.systems.xp.xp_definitions")

local XPLogic = {}

-- XP and level state
XPLogic.currentXP = 0
XPLogic.currentLevel = 1
XPLogic.xpToNextLevel = 100
XPLogic.totalXP = 0

-- Unlocked rewards tracking
XPLogic.unlockedRewards = {}
XPLogic.availableRewards = {}

-- Initialize XP logic
function XPLogic.init()
  XPLogic.currentXP = 0
  XPLogic.currentLevel = 1
  XPLogic.xpToNextLevel = 100
  XPLogic.totalXP = 0
  XPLogic.unlockedRewards = {}
  XPLogic.availableRewards = {}
  
  XPLogic.calculateXPToNextLevel()
  XPLogic.checkAvailableRewards()
  
  Utils.Logger.info("XP Logic initialized - Level: %d, XP: %d/%d", 
                    XPLogic.currentLevel, XPLogic.currentXP, XPLogic.xpToNextLevel)
end

-- Reset XP logic (for game restart)
function XPLogic.reset()
  XPLogic.currentXP = 0
  XPLogic.currentLevel = 1
  XPLogic.xpToNextLevel = 100
  XPLogic.totalXP = 0
  XPLogic.unlockedRewards = {}
  XPLogic.availableRewards = {}
  
  XPLogic.calculateXPToNextLevel()
  XPLogic.checkAvailableRewards()
  
  Utils.Logger.info("XP Logic reset")
end

-- Calculate XP required for next level
function XPLogic.calculateXPToNextLevel()
  XPLogic.xpToNextLevel = XPDefinitions.calculateXPForLevel(XPLogic.currentLevel + 1)
end

-- Check available rewards
function XPLogic.checkAvailableRewards()
  XPLogic.availableRewards = {}
  
  for level, reward in pairs(XPDefinitions.LEVEL_REWARDS) do
    if level <= XPLogic.currentLevel and not XPLogic.unlockedRewards[level] then
      XPLogic.availableRewards[level] = reward
    end
  end
end

-- Add XP with source tracking
function XPLogic.addXP(amount, source)
  if not amount or amount <= 0 then 
    Utils.Logger.warn("Invalid XP amount: %s", tostring(amount))
    return false
  end
  
  -- Apply prestige multiplier with error handling
  local multiplier = 1.0
  local PrestigeSystem = Utils.require("src.systems.prestige_system")
  if PrestigeSystem and PrestigeSystem.getXPMultiplier then
    local success, result = pcall(PrestigeSystem.getXPMultiplier)
    if success and result then
      multiplier = result
    else
      Utils.Logger.warn("Failed to get prestige multiplier: %s", tostring(result))
    end
  end
  
  amount = amount * multiplier
  
  -- Add XP
  XPLogic.currentXP = XPLogic.currentXP + amount
  XPLogic.totalXP = XPLogic.totalXP + amount
  
  -- Track in session stats
  local SessionStatsSystem = Utils.require("src.systems.session_stats_system")
  if SessionStatsSystem then
    SessionStatsSystem.onXPGained(amount, source or "unknown")
  end
  
  -- Check for level up
  local leveledUp = false
  while XPLogic.currentXP >= XPLogic.xpToNextLevel do
    XPLogic.levelUp()
    leveledUp = true
  end
  
  -- Save progress
  XPLogic.saveProgress()
  
  return leveledUp
end

-- Level up
function XPLogic.levelUp()
  XPLogic.currentLevel = XPLogic.currentLevel + 1
  XPLogic.currentXP = XPLogic.currentXP - XPLogic.xpToNextLevel
  
  XPLogic.calculateXPToNextLevel()
  XPLogic.checkAvailableRewards()
  
  -- Check for new rewards
  local newReward = XPDefinitions.getLevelReward(XPLogic.currentLevel)
  if newReward then
    XPLogic.unlockedRewards[XPLogic.currentLevel] = newReward
    XPLogic.availableRewards[XPLogic.currentLevel] = newReward
    
    Utils.Logger.info("Level up! New level: %d, Reward: %s", XPLogic.currentLevel, newReward.name)
    
    -- Trigger level up event
    XPLogic.triggerLevelUpEvent(XPLogic.currentLevel, newReward)
  else
    Utils.Logger.info("Level up! New level: %d", XPLogic.currentLevel)
  end
end

-- Trigger level up event
function XPLogic.triggerLevelUpEvent(level, reward)
  local eventData = {
    type = "level_up",
    level = level,
    reward = reward,
    xp_remaining = XPLogic.currentXP,
    xp_to_next = XPLogic.xpToNextLevel
  }
  
  -- Emit event for other systems to handle
  if Utils.EventEmitter then
    Utils.EventEmitter.emit("level_up", eventData)
  end
end

-- Get current XP progress
function XPLogic.getXPProgress()
  return {
    current = XPLogic.currentXP,
    total = XPLogic.xpToNextLevel,
    level = XPLogic.currentLevel,
    total_xp = XPLogic.totalXP,
    progress_ratio = XPLogic.currentXP / XPLogic.xpToNextLevel
  }
end

-- Get available rewards
function XPLogic.getAvailableRewards()
  return XPLogic.availableRewards
end

-- Get unlocked rewards
function XPLogic.getUnlockedRewards()
  return XPLogic.unlockedRewards
end

-- Check if reward is available
function XPLogic.isRewardAvailable(level)
  return XPLogic.availableRewards[level] ~= nil
end

-- Check if reward is unlocked
function XPLogic.isRewardUnlocked(level)
  return XPLogic.unlockedRewards[level] ~= nil
end

-- Get next reward
function XPLogic.getNextReward()
  local nextLevel = XPLogic.currentLevel + 1
  return XPDefinitions.getLevelReward(nextLevel)
end

-- Get XP value for source
function XPLogic.getXPValue(source)
  return XPDefinitions.getXPValue(source)
end

-- Get XP importance
function XPLogic.getXPImportance(amount)
  return XPDefinitions.getXPImportance(amount)
end

-- Save XP progress
function XPLogic.saveProgress()
  local saveData = {
    currentXP = XPLogic.currentXP,
    currentLevel = XPLogic.currentLevel,
    xpToNextLevel = XPLogic.xpToNextLevel,
    totalXP = XPLogic.totalXP,
    unlockedRewards = XPLogic.unlockedRewards,
    availableRewards = XPLogic.availableRewards
  }
  
  return Utils.saveData("xp_system", saveData)
end

-- Load XP progress
function XPLogic.loadProgress()
  local saveData = Utils.loadData("xp_system")
  if saveData then
    XPLogic.currentXP = saveData.currentXP or 0
    XPLogic.currentLevel = saveData.currentLevel or 1
    XPLogic.xpToNextLevel = saveData.xpToNextLevel or 100
    XPLogic.totalXP = saveData.totalXP or 0
    XPLogic.unlockedRewards = saveData.unlockedRewards or {}
    XPLogic.availableRewards = saveData.availableRewards or {}
    
    XPLogic.calculateXPToNextLevel()
    XPLogic.checkAvailableRewards()
    
    Utils.Logger.info("XP progress loaded - Level: %d, XP: %d/%d", 
                      XPLogic.currentLevel, XPLogic.currentXP, XPLogic.xpToNextLevel)
    return true
  end
  
  return false
end

-- Get XP statistics
function XPLogic.getStats()
  return {
    current_level = XPLogic.currentLevel,
    current_xp = XPLogic.currentXP,
    xp_to_next = XPLogic.xpToNextLevel,
    total_xp = XPLogic.totalXP,
    progress_ratio = XPLogic.currentXP / XPLogic.xpToNextLevel,
    unlocked_rewards_count = Utils.tableLength(XPLogic.unlockedRewards),
    available_rewards_count = Utils.tableLength(XPLogic.availableRewards)
  }
end

return XPLogic 