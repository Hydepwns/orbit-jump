-- XP System Coordinator
-- Main XP system that coordinates all XP modules

local Utils = require("src.utils.utils")
local XPDefinitions = require("src.systems.xp.xp_definitions")
local XPLogic = require("src.systems.xp.xp_logic")
local XPUI = require("src.systems.xp.xp_ui")

local XPSystem = {}

-- System state
XPSystem.isInitialized = false

-- Initialize XP system
function XPSystem.init()
  if XPSystem.isInitialized then
    return true
  end
  
  -- Initialize all modules
  XPDefinitions = XPDefinitions or require("src.systems.xp.xp_definitions")
  XPLogic = XPLogic or require("src.systems.xp.xp_logic")
  XPUI = XPUI or require("src.systems.xp.xp_ui")
  
  XPLogic.init()
  XPUI.init()
  
  -- Load saved progress
  XPLogic.loadProgress()
  
  XPSystem.isInitialized = true
  Utils.Logger.info("XP system initialized successfully")
  
  return true
end

-- Update XP system
function XPSystem.update(dt)
  if not XPSystem.isInitialized then
    return
  end
  
  XPUI.update(dt)
end

-- Draw XP system
function XPSystem.draw()
  if not XPSystem.isInitialized then
    return
  end
  
  XPUI.draw()
end

-- Public API for other systems

-- Add XP with source tracking
function XPSystem.addXP(amount, source, x, y, soundSystem)
  if not XPSystem.isInitialized then
    Utils.Logger.warning("XP system not initialized")
    return false
  end
  
  local leveledUp = XPLogic.addXP(amount, source)
  
  -- Create floating XP animation
  XPUI.createXPGainAnimation(amount, source, x or 0, y or 0)
  
  -- Play XP gain sound
  if soundSystem and soundSystem.playXPGain then
    local importance = XPLogic.getXPImportance(amount)
    soundSystem:playXPGain(amount, importance)
  end
  
  -- If leveled up, create level up animation
  if leveledUp then
    local progress = XPLogic.getXPProgress()
    XPUI.createLevelUpAnimation(progress.level, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    
    -- Play level up sound
    if soundSystem and soundSystem.playLevelUp then
      soundSystem:playLevelUp()
    end
  end
  
  return leveledUp
end

-- Get XP progress
function XPSystem.getXPProgress()
  if not XPSystem.isInitialized then
    return nil
  end
  
  return XPLogic.getXPProgress()
end

-- Get current level
function XPSystem.getCurrentLevel()
  if not XPSystem.isInitialized then
    return 1
  end
  
  local progress = XPLogic.getXPProgress()
  return progress.level
end

-- Get available rewards
function XPSystem.getAvailableRewards()
  if not XPSystem.isInitialized then
    return {}
  end
  
  return XPLogic.getAvailableRewards()
end

-- Get unlocked rewards
function XPSystem.getUnlockedRewards()
  if not XPSystem.isInitialized then
    return {}
  end
  
  return XPLogic.getUnlockedRewards()
end

-- Check if reward is available
function XPSystem.isRewardAvailable(level)
  if not XPSystem.isInitialized then
    return false
  end
  
  return XPLogic.isRewardAvailable(level)
end

-- Check if reward is unlocked
function XPSystem.isRewardUnlocked(level)
  if not XPSystem.isInitialized then
    return false
  end
  
  return XPLogic.isRewardUnlocked(level)
end

-- Get next reward
function XPSystem.getNextReward()
  if not XPSystem.isInitialized then
    return nil
  end
  
  return XPLogic.getNextReward()
end

-- Get XP value for source
function XPSystem.getXPValue(source)
  if not XPSystem.isInitialized then
    return 0
  end
  
  return XPLogic.getXPValue(source)
end

-- Get XP importance
function XPSystem.getXPImportance(amount)
  if not XPSystem.isInitialized then
    return "low"
  end
  
  return XPLogic.getXPImportance(amount)
end

-- UI Functions

-- Draw XP bar at custom position
function XPSystem.drawXPBarAt(x, y, width, height)
  if not XPSystem.isInitialized then
    return
  end
  
  XPUI.drawXPBarAt(x, y, width, height)
end

-- Draw reward notification
function XPSystem.drawRewardNotification(reward, x, y)
  if not XPSystem.isInitialized then
    return
  end
  
  XPUI.drawRewardNotification(reward, x, y)
end

-- Draw XP statistics
function XPSystem.drawXPStats(x, y)
  if not XPSystem.isInitialized then
    return
  end
  
  XPUI.drawXPStats(x, y)
end

-- Clear all animations
function XPSystem.clearAnimations()
  if not XPSystem.isInitialized then
    return
  end
  
  XPUI.clearAnimations()
end

-- Save/Load functions
function XPSystem.save()
  if not XPSystem.isInitialized then
    return false
  end
  
  return XPLogic.saveProgress()
end

function XPSystem.load()
  if not XPSystem.isInitialized then
    return false
  end
  
  return XPLogic.loadProgress()
end

function XPSystem.reset()
  if not XPSystem.isInitialized then
    return
  end
  
  XPLogic.reset()
  XPUI.clearAnimations()
end

-- Debug functions
function XPSystem.debug()
  if not XPSystem.isInitialized then
    print("XP system not initialized")
    return
  end
  
  print("=== XP System Debug ===")
  local progress = XPSystem.getXPProgress()
  print("Current Level:", progress.level)
  print("Current XP:", progress.current)
  print("XP to Next Level:", progress.total)
  print("Total XP:", progress.total_xp)
  print("Progress Ratio:", string.format("%.2f%%", progress.progress_ratio * 100))
  
  local stats = XPLogic.getStats()
  print("Unlocked Rewards:", stats.unlocked_rewards_count)
  print("Available Rewards:", stats.available_rewards_count)
  
  print("\n=== Available Rewards ===")
  local availableRewards = XPSystem.getAvailableRewards()
  for level, reward in pairs(availableRewards) do
    print(string.format("Level %d: %s (%s)", level, reward.name, reward.type))
  end
  
  print("\n=== Unlocked Rewards ===")
  local unlockedRewards = XPSystem.getUnlockedRewards()
  for level, reward in pairs(unlockedRewards) do
    print(string.format("Level %d: %s (%s)", level, reward.name, reward.type))
  end
end

-- Test functions for development
function XPSystem.testAddXP(amount, source)
  if not XPSystem.isInitialized then
    print("XP system not initialized")
    return
  end
  
  print(string.format("Adding %d XP from %s", amount, source or "test"))
  local leveledUp = XPSystem.addXP(amount, source or "test", 100, 100)
  if leveledUp then
    print("Leveled up!")
  end
end

return XPSystem 