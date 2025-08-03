-- Achievement UI Module
-- Handles achievement-related user interface rendering and interactions
local Utils = require("src.utils.utils")
local AchievementDefinitions = require("src.systems.achievement.achievement_definitions")
local AchievementLogic = require("src.systems.achievement.achievement_logic")
local AchievementUI = {}
-- UI state
AchievementUI.isVisible = false
AchievementUI.currentCategory = "Explorer"
AchievementUI.scrollOffset = 0
AchievementUI.selectedAchievement = nil
AchievementUI.animations = {}
-- UI constants
AchievementUI.constants = {
  PANEL_WIDTH = 400,
  PANEL_HEIGHT = 600,
  ITEM_HEIGHT = 80,
  MARGIN = 10,
  ANIMATION_DURATION = 0.3,
  NOTIFICATION_DURATION = 3.0
}
-- Initialize achievement UI
function AchievementUI.init()
  AchievementUI.isVisible = false
  AchievementUI.currentCategory = "Explorer"
  AchievementUI.scrollOffset = 0
  AchievementUI.selectedAchievement = nil
  AchievementUI.animations = {}
  Utils.Logger.info("Achievement UI initialized")
end
-- Toggle achievement panel visibility
function AchievementUI.toggle()
  AchievementUI.isVisible = not AchievementUI.isVisible
  if AchievementUI.isVisible then
    AchievementUI.scrollOffset = 0
    AchievementUI.selectedAchievement = nil
  end
end
-- Show achievement panel
function AchievementUI.show()
  AchievementUI.isVisible = true
  AchievementUI.scrollOffset = 0
  AchievementUI.selectedAchievement = nil
end
-- Hide achievement panel
function AchievementUI.hide()
  AchievementUI.isVisible = false
end
-- Update achievement UI
function AchievementUI.update(dt)
  -- Update animations
  for _, animation in pairs(AchievementUI.animations) do
    if animation.active then
      animation.time = animation.time + dt
      if animation.time >= animation.duration then
        animation.active = false
        animation.value = animation.target
      else
        local progress = animation.time / animation.duration
        animation.value = Utils.lerp(animation.start, animation.target, progress)
      end
    end
  end
end
-- Draw achievement UI
function AchievementUI.draw()
  if not AchievementUI.isVisible then
    return
  end
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  -- Draw background overlay
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
  -- Calculate panel position
  local panelX = (screenWidth - AchievementUI.constants.PANEL_WIDTH) / 2
  local panelY = (screenHeight - AchievementUI.constants.PANEL_HEIGHT) / 2
  -- Draw main panel
  AchievementUI.drawPanel(panelX, panelY)
  -- Draw category tabs
  AchievementUI.drawCategoryTabs(panelX, panelY)
  -- Draw achievement list
  AchievementUI.drawAchievementList(panelX, panelY)
  -- Draw selected achievement details
  if AchievementUI.selectedAchievement then
    AchievementUI.drawAchievementDetails(panelX, panelY)
  end
end
-- Draw main panel
function AchievementUI.drawPanel(x, y)
  love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
  love.graphics.rectangle("fill", x, y, AchievementUI.constants.PANEL_WIDTH, AchievementUI.constants.PANEL_HEIGHT, 10)
  love.graphics.setColor(0.3, 0.3, 0.5, 1)
  love.graphics.rectangle("line", x, y, AchievementUI.constants.PANEL_WIDTH, AchievementUI.constants.PANEL_HEIGHT, 10)
  -- Draw title
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(24))
  love.graphics.printf("🏆 Achievements", x, y + 20, AchievementUI.constants.PANEL_WIDTH, "center")
  -- Draw total points
  local totalPoints = AchievementLogic.getTotalPoints()
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf(string.format("Total Points: %d", totalPoints), x, y + 50, AchievementUI.constants.PANEL_WIDTH, "center")
end
-- Draw category tabs
function AchievementUI.drawCategoryTabs(panelX, panelY)
  local tabY = panelY + 80
  local tabWidth = AchievementUI.constants.PANEL_WIDTH / #AchievementDefinitions.categories
  for i, category in ipairs(AchievementDefinitions.categories) do
    local tabX = panelX + (i - 1) * tabWidth
    local isSelected = category == AchievementUI.currentCategory
    -- Tab background
    if isSelected then
      love.graphics.setColor(0.3, 0.3, 0.6, 1)
    else
      love.graphics.setColor(0.2, 0.2, 0.4, 1)
    end
    love.graphics.rectangle("fill", tabX, tabY, tabWidth, 30, 5)
    -- Tab border
    love.graphics.setColor(0.5, 0.5, 0.7, 1)
    love.graphics.rectangle("line", tabX, tabY, tabWidth, 30, 5)
    -- Tab text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf(category, tabX, tabY + 8, tabWidth, "center")
  end
end
-- Draw achievement list
function AchievementUI.drawAchievementList(panelX, panelY)
  local listY = panelY + 120
  local listHeight = AchievementUI.constants.PANEL_HEIGHT - 200
  local achievements = AchievementDefinitions.getAchievementsByCategory(AchievementUI.currentCategory)
  -- Draw scrollable list
  love.graphics.setScissor(panelX, listY, AchievementUI.constants.PANEL_WIDTH, listHeight)
  local itemY = listY - AchievementUI.scrollOffset
  for _, achievement in ipairs(achievements) do
    if itemY + AchievementUI.constants.ITEM_HEIGHT > listY and itemY < listY + listHeight then
      AchievementUI.drawAchievementItem(panelX, itemY, achievement)
    end
    itemY = itemY + AchievementUI.constants.ITEM_HEIGHT + 5
  end
  love.graphics.setScissor()
end
-- Draw individual achievement item
function AchievementUI.drawAchievementItem(x, y, achievement)
  local progressData = AchievementLogic.getProgress(achievement.id)
  local isUnlocked = false
  local progress = 0
  if achievement.tiers then
    -- Tiered achievement
    isUnlocked = progressData and progressData.current_tier > 0
    progress = progressData and progressData.progress or 0
  else
    -- Legacy achievement
    isUnlocked = progressData and progressData.unlocked
    progress = progressData and progressData.progress or 0
  end
  -- Item background
  if isUnlocked then
    love.graphics.setColor(0.2, 0.4, 0.2, 0.8)
  else
    love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
  end
  love.graphics.rectangle("fill", x + 10, y, AchievementUI.constants.PANEL_WIDTH - 20, AchievementUI.constants.ITEM_HEIGHT, 5)
  -- Item border
  love.graphics.setColor(0.4, 0.4, 0.6, 1)
  love.graphics.rectangle("line", x + 10, y, AchievementUI.constants.PANEL_WIDTH - 20, AchievementUI.constants.ITEM_HEIGHT, 5)
  -- Achievement icon
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(24))
  love.graphics.printf(achievement.icon, x + 20, y + 10, 40, "center")
  -- Achievement name
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf(achievement.name, x + 70, y + 10, AchievementUI.constants.PANEL_WIDTH - 90, "left")
  -- Achievement description
  love.graphics.setFont(Utils.getFont(12))
  love.graphics.setColor(0.8, 0.8, 0.8, 1)
  love.graphics.printf(achievement.description, x + 70, y + 30, AchievementUI.constants.PANEL_WIDTH - 90, "left")
  -- Progress bar
  AchievementUI.drawProgressBar(x + 70, y + 50, achievement, progressData)
end
-- Draw progress bar
function AchievementUI.drawProgressBar(x, y, achievement, progressData)
  local barWidth = AchievementUI.constants.PANEL_WIDTH - 90
  local barHeight = 8
  -- Background
  love.graphics.setColor(0.1, 0.1, 0.2, 1)
  love.graphics.rectangle("fill", x, y, barWidth, barHeight, 4)
  -- Progress
  local progress = 0
  local target = 1
  if achievement.tiers then
    -- Tiered achievement
    progress = progressData and progressData.progress or 0
    if progressData and progressData.current_tier > 0 then
      target = achievement.tiers[progressData.current_tier].count
    else
      target = achievement.tiers[1].count
    end
  else
    -- Legacy achievement
    progress = progressData and progressData.progress or 0
    target = achievement.target
  end
  local progressRatio = math.min(progress / target, 1.0)
  if progressRatio > 0 then
    love.graphics.setColor(0.3, 0.7, 0.3, 1)
    love.graphics.rectangle("fill", x, y, barWidth * progressRatio, barHeight, 4)
  end
  -- Border
  love.graphics.setColor(0.5, 0.5, 0.7, 1)
  love.graphics.rectangle("line", x, y, barWidth, barHeight, 4)
  -- Progress text
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(10))
  love.graphics.printf(string.format("%d/%d", progress, target), x, y + barHeight + 2, barWidth, "center")
end
-- Draw achievement details
function AchievementUI.drawAchievementDetails(panelX, panelY)
  local detailX = panelX + AchievementUI.constants.PANEL_WIDTH + 20
  local detailY = panelY
  -- Detail panel background
  love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
  love.graphics.rectangle("fill", detailX, detailY, 300, AchievementUI.constants.PANEL_HEIGHT, 10)
  love.graphics.setColor(0.3, 0.3, 0.5, 1)
  love.graphics.rectangle("line", detailX, detailY, 300, AchievementUI.constants.PANEL_HEIGHT, 10)
  -- Achievement details
  local achievement = AchievementUI.selectedAchievement
  local progressData = AchievementLogic.getProgress(achievement.id)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setFont(Utils.getFont(20))
  love.graphics.printf(achievement.name, detailX + 10, detailY + 20, 280, "center")
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.printf(achievement.icon, detailX + 10, detailY + 50, 280, "center")
  love.graphics.setFont(Utils.getFont(14))
  love.graphics.printf(achievement.description, detailX + 10, detailY + 90, 280, "left")
  -- Show tier information for tiered achievements
  if achievement.tiers then
    AchievementUI.drawTierDetails(detailX, detailY, achievement, progressData)
  end
end
-- Draw tier details
function AchievementUI.drawTierDetails(x, y, achievement, progressData)
  love.graphics.setFont(Utils.getFont(16))
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("Tiers:", x + 10, y + 150, 280, "left")
  local tierY = y + 180
  for i, tier in ipairs(achievement.tiers) do
    local isUnlocked = progressData and progressData.unlocked_tiers[i]
    local isCurrent = progressData and progressData.current_tier == i
    -- Tier background
    if isUnlocked then
      love.graphics.setColor(tier.color[1], tier.color[2], tier.color[3], 0.3)
    else
      love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
    end
    love.graphics.rectangle("fill", x + 10, tierY, 280, 40, 5)
    -- Tier border
    if isCurrent then
      love.graphics.setColor(1, 1, 0, 1)
    else
      love.graphics.setColor(0.4, 0.4, 0.6, 1)
    end
    love.graphics.rectangle("line", x + 10, tierY, 280, 40, 5)
    -- Tier text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(Utils.getFont(14))
    love.graphics.printf(string.format("%s - %d points", tier.name, tier.points), x + 20, tierY + 10, 260, "left")
    love.graphics.setFont(Utils.getFont(12))
    love.graphics.printf(string.format("Target: %d", tier.count), x + 20, tierY + 25, 260, "left")
    tierY = tierY + 45
  end
end
-- Handle mouse input
function AchievementUI.mousepressed(x, y, button)
  if not AchievementUI.isVisible then
    return false
  end
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  local panelX = (screenWidth - AchievementUI.constants.PANEL_WIDTH) / 2
  local panelY = (screenHeight - AchievementUI.constants.PANEL_HEIGHT) / 2
  -- Check if click is outside panel
  if x < panelX or x > panelX + AchievementUI.constants.PANEL_WIDTH or
     y < panelY or y > panelY + AchievementUI.constants.PANEL_HEIGHT then
    AchievementUI.hide()
    return true
  end
  -- Handle category tab clicks
  local tabY = panelY + 80
  local tabWidth = AchievementUI.constants.PANEL_WIDTH / #AchievementDefinitions.categories
  for i, category in ipairs(AchievementDefinitions.categories) do
    local tabX = panelX + (i - 1) * tabWidth
    if x >= tabX and x <= tabX + tabWidth and y >= tabY and y <= tabY + 30 then
      AchievementUI.currentCategory = category
      AchievementUI.scrollOffset = 0
      return true
    end
  end
  return true
end
-- Handle scroll input
function AchievementUI.wheelmoved(x, y)
  if not AchievementUI.isVisible then
    return false
  end
  AchievementUI.scrollOffset = math.max(0, AchievementUI.scrollOffset - y * 20)
  return true
end
return AchievementUI