-- Achievement System Coordinator
-- Main achievement system that coordinates all achievement modules

local Utils = require("src.utils.utils")
local AchievementDefinitions = require("src.systems.achievement.achievement_definitions")
local AchievementLogic = require("src.systems.achievement.achievement_logic")
local AchievementUI = require("src.systems.achievement.achievement_ui")

local AchievementSystem = {}

-- System state
AchievementSystem.isInitialized = false
AchievementSystem.notifications = {}

-- Initialize achievement system
function AchievementSystem.init()
  if AchievementSystem.isInitialized then
    return true
  end
  
  -- Initialize all modules
  AchievementDefinitions = AchievementDefinitions or require("src.systems.achievement.achievement_definitions")
  AchievementLogic = AchievementLogic or require("src.systems.achievement.achievement_logic")
  AchievementUI = AchievementUI or require("src.systems.achievement.achievement_ui")
  
  AchievementLogic.init()
  AchievementUI.init()
  
  -- Load saved progress
  AchievementLogic.loadProgress()
  
  AchievementSystem.isInitialized = true
  Utils.Logger.info("Achievement system initialized successfully")
  
  return true
end

-- Update achievement system
function AchievementSystem.update(dt)
  if not AchievementSystem.isInitialized then
    return
  end
  
  AchievementUI.update(dt)
  AchievementSystem.updateNotifications(dt)
end

-- Draw achievement system
function AchievementSystem.draw()
  if not AchievementSystem.isInitialized then
    return
  end
  
  AchievementUI.draw()
  AchievementSystem.drawNotifications()
end

-- Handle input
function AchievementSystem.mousepressed(x, y, button)
  if not AchievementSystem.isInitialized then
    return false
  end
  
  return AchievementUI.mousepressed(x, y, button)
end

function AchievementSystem.wheelmoved(x, y)
  if not AchievementSystem.isInitialized then
    return false
  end
  
  return AchievementUI.wheelmoved(x, y)
end

-- Public API for other systems

-- Update achievement progress
function AchievementSystem.updateProgress(achievementId, progress, data)
  if not AchievementSystem.isInitialized then
    Utils.Logger.warning("Achievement system not initialized")
    return false
  end
  
  local unlocked = AchievementLogic.updateProgress(achievementId, progress, data)
  
  if unlocked then
    AchievementSystem.addNotification(achievementId)
  end
  
  return unlocked
end

-- Get achievement progress
function AchievementSystem.getProgress(achievementId)
  if not AchievementSystem.isInitialized then
    return nil
  end
  
  return AchievementLogic.getProgress(achievementId)
end

-- Get total points
function AchievementSystem.getTotalPoints()
  if not AchievementSystem.isInitialized then
    return 0
  end
  
  return AchievementLogic.getTotalPoints()
end

-- Get unlocked count
function AchievementSystem.getUnlockedCount()
  if not AchievementSystem.isInitialized then
    return 0
  end
  
  return AchievementLogic.getUnlockedCount()
end

-- Get achievements by status
function AchievementSystem.getAchievementsByStatus(completed)
  if not AchievementSystem.isInitialized then
    return {}
  end
  
  return AchievementLogic.getAchievementsByStatus(completed)
end

-- UI Controls
function AchievementSystem.toggleUI()
  if not AchievementSystem.isInitialized then
    return
  end
  
  AchievementUI.toggle()
end

function AchievementSystem.showUI()
  if not AchievementSystem.isInitialized then
    return
  end
  
  AchievementUI.show()
end

function AchievementSystem.hideUI()
  if not AchievementSystem.isInitialized then
    return
  end
  
  AchievementUI.hide()
end

function AchievementSystem.isUIVisible()
  if not AchievementSystem.isInitialized then
    return false
  end
  
  return AchievementUI.isVisible
end

-- Notification system
function AchievementSystem.addNotification(achievementId)
  local achievement = AchievementDefinitions.getAchievement(achievementId)
  if not achievement then
    return
  end
  
  local notification = {
    achievement = achievement,
    time = 0,
    duration = 3.0,
    alpha = 1.0,
    y_offset = 0
  }
  
  table.insert(AchievementSystem.notifications, notification)
  
  -- Limit number of notifications
  if #AchievementSystem.notifications > 3 then
    table.remove(AchievementSystem.notifications, 1)
  end
end

function AchievementSystem.updateNotifications(dt)
  for i = #AchievementSystem.notifications, 1, -1 do
    local notification = AchievementSystem.notifications[i]
    notification.time = notification.time + dt
    
    -- Fade out in last second
    if notification.time > notification.duration - 1.0 then
      notification.alpha = 1.0 - (notification.time - (notification.duration - 1.0))
    end
    
    -- Remove expired notifications
    if notification.time >= notification.duration then
      table.remove(AchievementSystem.notifications, i)
    end
  end
end

function AchievementSystem.drawNotifications()
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  local notificationY = screenHeight - 200
  
  for i, notification in ipairs(AchievementSystem.notifications) do
    local y = notificationY - (i - 1) * 80 + notification.y_offset
    
    -- Notification background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9 * notification.alpha)
    love.graphics.rectangle("fill", screenWidth - 350, y, 340, 70, 10)
    
    love.graphics.setColor(0.3, 0.7, 0.3, notification.alpha)
    love.graphics.rectangle("line", screenWidth - 350, y, 340, 70, 10)
    
    -- Achievement icon
    love.graphics.setColor(1, 1, 1, notification.alpha)
    love.graphics.setFont(Utils.getFont(24))
    love.graphics.printf(notification.achievement.icon, screenWidth - 340, y + 10, 40, "center")
    
    -- Achievement name
    love.graphics.setFont(Utils.getFont(16))
    love.graphics.printf(notification.achievement.name, screenWidth - 290, y + 10, 280, "left")
    
    -- Achievement description
    love.graphics.setFont(Utils.getFont(12))
    love.graphics.setColor(0.8, 0.8, 0.8, notification.alpha)
    love.graphics.printf(notification.achievement.description, screenWidth - 290, y + 30, 280, "left")
    
    -- Unlocked text
    love.graphics.setColor(0.3, 0.7, 0.3, notification.alpha)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf("UNLOCKED!", screenWidth - 290, y + 50, 280, "right")
  end
end

-- Save/Load functions
function AchievementSystem.save()
  if not AchievementSystem.isInitialized then
    return false
  end
  
  return AchievementLogic.saveProgress()
end

function AchievementSystem.load()
  if not AchievementSystem.isInitialized then
    return false
  end
  
  return AchievementLogic.loadProgress()
end

function AchievementSystem.reset()
  if not AchievementSystem.isInitialized then
    return
  end
  
  AchievementLogic.resetProgress()
  AchievementSystem.notifications = {}
end

-- Debug functions
function AchievementSystem.debug()
  if not AchievementSystem.isInitialized then
    print("Achievement system not initialized")
    return
  end
  
  print("=== Achievement System Debug ===")
  print("Total Points:", AchievementSystem.getTotalPoints())
  print("Unlocked Count:", AchievementSystem.getUnlockedCount())
  print("Total Achievements:", #AchievementDefinitions.achievements)
  
  local completed = AchievementSystem.getAchievementsByStatus(true)
  local incomplete = AchievementSystem.getAchievementsByStatus(false)
  
  print("Completed:", #completed)
  print("Incomplete:", #incomplete)
  
  print("\n=== Recent Progress ===")
  for achievementId, progress in pairs(AchievementLogic.progress) do
    if achievementId ~= "visited_planets" then
      print(string.format("%s: %d", achievementId, progress.progress or 0))
    end
  end
end

return AchievementSystem 