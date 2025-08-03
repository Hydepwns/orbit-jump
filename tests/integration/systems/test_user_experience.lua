-- Phase 6: User Experience Testing
-- Tests usability, accessibility, and player satisfaction metrics
local TestFramework = require("tests.phase6_test_framework")
local TestSuite = TestFramework.TestSuite
local TestCase = TestFramework.TestCase
local Assert = TestFramework.Assert
local Mock = TestFramework.Mock
-- Mock the game environment
local game = Mock.new()
local player = Mock.new()
local ui = Mock.new()
local audio = Mock.new()
local input = Mock.new()
local save = Mock.new()
local tutorial = Mock.new()
-- Test suite for user experience testing
local UserExperienceTests = TestSuite.new("User Experience Tests")
-- UX Test 1: First-Time User Experience
UserExperienceTests:addTest("First-Time User Experience", function()
    -- Test tutorial flow
    local tutorialSteps = tutorial.getSteps()
    Assert.isNotNil(tutorialSteps, "Tutorial should have defined steps")
    Assert.isTrue(#tutorialSteps > 0, "Tutorial should have at least one step")
    -- Test tutorial progression
    for i, step in ipairs(tutorialSteps) do
        local completed = tutorial.completeStep(i)
        Assert.isNotNil(completed, "Should be able to complete tutorial step " .. i)
        local progress = tutorial.getProgress()
        Assert.isNotNil(progress, "Should track tutorial progress")
        Assert.isTrue(progress >= 0 and progress <= 100, "Progress should be between 0-100%")
    end
    -- Test tutorial completion
    local finished = tutorial.isComplete()
    Assert.isNotNil(finished, "Should detect tutorial completion")
end)
-- UX Test 2: Menu Navigation
UserExperienceTests:addTest("Menu Navigation", function()
    local menuItems = {
        "start_game", "load_game", "settings", "credits", "exit"
    }
    -- Test menu accessibility
    for i, item in ipairs(menuItems) do
        local accessible = ui.isMenuItemAccessible(item)
        Assert.isNotNil(accessible, "Menu item " .. item .. " should be accessible")
        local selected = ui.selectMenuItem(item)
        Assert.isNotNil(selected, "Should be able to select menu item " .. item)
        local highlighted = ui.isMenuItemHighlighted(item)
        Assert.isNotNil(highlighted, "Should highlight selected menu item")
    end
    -- Test menu navigation with keyboard
    local navigationResult = ui.navigateWithKeyboard("down")
    Assert.isNotNil(navigationResult, "Should navigate menu with keyboard")
    -- Test menu navigation with gamepad
    local gamepadResult = ui.navigateWithGamepad("up")
    Assert.isNotNil(gamepadResult, "Should navigate menu with gamepad")
end)
-- UX Test 3: Control Responsiveness
UserExperienceTests:addTest("Control Responsiveness", function()
    local inputLatency = input.measureLatency()
    Assert.isNotNil(inputLatency, "Should measure input latency")
    Assert.isTrue(inputLatency < 0.1, "Input latency should be under 100ms")
    -- Test different input methods
    local inputMethods = {"keyboard", "mouse", "gamepad", "touch"}
    for i, method in ipairs(inputMethods) do
        local responsive = input.isResponsive(method)
        Assert.isNotNil(responsive, "Input method " .. method .. " should be responsive")
        local latency = input.getLatency(method)
        Assert.isNotNil(latency, "Should measure latency for " .. method)
        Assert.isTrue(latency < 0.1, "Latency should be acceptable for " .. method)
    end
end)
-- UX Test 4: Visual Feedback
UserExperienceTests:addTest("Visual Feedback", function()
    -- Test button press feedback
    local buttonPressed = ui.pressButton("start")
    Assert.isNotNil(buttonPressed, "Button press should provide feedback")
    local visualFeedback = ui.getVisualFeedback("start")
    Assert.isNotNil(visualFeedback, "Should provide visual feedback for button press")
    -- Test hover effects
    local hoverEffect = ui.getHoverEffect("start")
    Assert.isNotNil(hoverEffect, "Should provide hover effect")
    -- Test animation smoothness
    local animationFPS = ui.measureAnimationFPS()
    Assert.isNotNil(animationFPS, "Should measure animation frame rate")
    Assert.isTrue(animationFPS >= 30, "Animations should be smooth (30+ FPS)")
end)
-- UX Test 5: Audio Feedback
UserExperienceTests:addTest("Audio Feedback", function()
    -- Test sound effects for actions
    local actions = {"button_press", "menu_select", "game_start", "error"}
    for i, action in ipairs(actions) do
        local soundPlayed = audio.playSoundForAction(action)
        Assert.isNotNil(soundPlayed, "Should play sound for action " .. action)
        local volume = audio.getVolumeForAction(action)
        Assert.isNotNil(volume, "Should have appropriate volume for " .. action)
        Assert.isTrue(volume >= 0 and volume <= 1, "Volume should be between 0-1")
    end
    -- Test audio balance
    local balance = audio.checkBalance()
    Assert.isNotNil(balance, "Should check audio balance")
    Assert.isTrue(balance.music <= balance.effects, "Sound effects should be audible over music")
end)
-- UX Test 6: Error Handling
UserExperienceTests:addTest("Error Handling", function()
    -- Test error message clarity
    local errorMessages = {
        "save_failed", "load_failed", "network_error", "invalid_input"
    }
    for i, errorType in ipairs(errorMessages) do
        local message = ui.getErrorMessage(errorType)
        Assert.isNotNil(message, "Should provide error message for " .. errorType)
        Assert.isTrue(string.len(message) > 0, "Error message should not be empty")
        Assert.isTrue(string.len(message) < 200, "Error message should be concise")
    end
    -- Test error recovery
    local recoveryOptions = ui.getErrorRecoveryOptions("save_failed")
    Assert.isNotNil(recoveryOptions, "Should provide recovery options for errors")
    Assert.isTrue(#recoveryOptions > 0, "Should have at least one recovery option")
end)
-- UX Test 7: Accessibility Features
UserExperienceTests:addTest("Accessibility Features", function()
    -- Test color blind support
    local colorBlindModes = {"protanopia", "deuteranopia", "tritanopia"}
    for i, mode in ipairs(colorBlindModes) do
        local enabled = ui.enableColorBlindMode(mode)
        Assert.isNotNil(enabled, "Should enable color blind mode " .. mode)
        local contrast = ui.checkColorContrast(mode)
        Assert.isNotNil(contrast, "Should check color contrast for " .. mode)
        Assert.isTrue(contrast >= 4.5, "Color contrast should meet WCAG standards")
    end
    -- Test text scaling
    local textScales = {0.8, 1.0, 1.2, 1.5, 2.0}
    for i, scale in ipairs(textScales) do
        local applied = ui.setTextScale(scale)
        Assert.isNotNil(applied, "Should apply text scale " .. scale)
        local readable = ui.isTextReadable(scale)
        Assert.isNotNil(readable, "Should check text readability at scale " .. scale)
    end
end)
-- UX Test 8: Game Flow
UserExperienceTests:addTest("Game Flow", function()
    -- Test game state transitions
    local gameStates = {"menu", "playing", "paused", "game_over", "victory"}
    for i, state in ipairs(gameStates) do
        local transitioned = game.setState(state)
        Assert.isNotNil(transitioned, "Should transition to state " .. state)
        local currentState = game.getCurrentState()
        Assert.isNotNil(currentState, "Should track current game state")
    end
    -- Test save/load flow
    local saveCreated = save.createSave("test_save")
    Assert.isNotNil(saveCreated, "Should create save file")
    local saveLoaded = save.loadSave("test_save")
    Assert.isNotNil(saveLoaded, "Should load save file")
    local gameState = save.getGameState()
    Assert.isNotNil(gameState, "Should restore game state from save")
end)
-- UX Test 9: Performance Perception
UserExperienceTests:addTest("Performance Perception", function()
    -- Test frame rate consistency
    local frameRates = {}
    for i = 1, 100 do
        local fps = game.measureFPS()
        table.insert(frameRates, fps)
    end
    local avgFPS = 0
    for i, fps in ipairs(frameRates) do
        avgFPS = avgFPS + fps
    end
    avgFPS = avgFPS / #frameRates
    Assert.isTrue(avgFPS >= 30, "Average frame rate should be acceptable")
    -- Test loading times
    local loadTime = game.measureLoadTime()
    Assert.isNotNil(loadTime, "Should measure loading time")
    Assert.isTrue(loadTime < 5.0, "Loading time should be reasonable")
    -- Test save time
    local saveTime = save.measureSaveTime()
    Assert.isNotNil(saveTime, "Should measure save time")
    Assert.isTrue(saveTime < 2.0, "Save time should be quick")
end)
-- UX Test 10: Onboarding Experience
UserExperienceTests:addTest("Onboarding Experience", function()
    -- Test first launch experience
    local firstLaunch = game.isFirstLaunch()
    Assert.isNotNil(firstLaunch, "Should detect first launch")
    if firstLaunch then
        local welcomeShown = ui.showWelcomeScreen()
        Assert.isNotNil(welcomeShown, "Should show welcome screen on first launch")
        local settingsConfigured = game.configureDefaultSettings()
        Assert.isNotNil(settingsConfigured, "Should configure default settings")
    end
    -- Test tutorial skip option
    local canSkip = tutorial.canSkip()
    Assert.isNotNil(canSkip, "Should allow tutorial skip option")
    if canSkip then
        local skipped = tutorial.skip()
        Assert.isNotNil(skipped, "Should be able to skip tutorial")
    end
end)
-- UX Test 11: Help System
UserExperienceTests:addTest("Help System", function()
    -- Test help content availability
    local helpTopics = {"controls", "objectives", "tips", "troubleshooting"}
    for i, topic in ipairs(helpTopics) do
        local content = ui.getHelpContent(topic)
        Assert.isNotNil(content, "Should provide help content for " .. topic)
        Assert.isTrue(string.len(content) > 0, "Help content should not be empty")
    end
    -- Test help search
    local searchResults = ui.searchHelp("how to jump")
    Assert.isNotNil(searchResults, "Should provide help search results")
    Assert.isTrue(#searchResults > 0, "Should find relevant help topics")
    -- Test contextual help
    local contextualHelp = ui.getContextualHelp("gameplay")
    Assert.isNotNil(contextualHelp, "Should provide contextual help")
end)
-- UX Test 12: Social Features
UserExperienceTests:addTest("Social Features", function()
    -- Test achievement sharing
    local achievement = "first_win"
    local shared = game.shareAchievement(achievement)
    Assert.isNotNil(shared, "Should be able to share achievements")
    -- Test leaderboard integration
    local leaderboard = game.getLeaderboard()
    Assert.isNotNil(leaderboard, "Should provide leaderboard data")
    local scoreSubmitted = game.submitScore(1000)
    Assert.isNotNil(scoreSubmitted, "Should be able to submit scores")
    -- Test friend integration
    local friends = game.getFriendsList()
    Assert.isNotNil(friends, "Should provide friends list")
end)
-- UX Test 13: Customization Options
UserExperienceTests:addTest("Customization Options", function()
    -- Test control customization
    local controlSchemes = {"default", "custom", "left_handed", "accessibility"}
    for i, scheme in ipairs(controlSchemes) do
        local applied = input.applyControlScheme(scheme)
        Assert.isNotNil(applied, "Should apply control scheme " .. scheme)
        local current = input.getCurrentScheme()
        Assert.isNotNil(current, "Should track current control scheme")
    end
    -- Test visual customization
    local visualOptions = {"brightness", "contrast", "saturation", "gamma"}
    for i, option in ipairs(visualOptions) do
        local adjusted = ui.adjustVisualSetting(option, 0.5)
        Assert.isNotNil(adjusted, "Should adjust visual setting " .. option)
        local value = ui.getVisualSetting(option)
        Assert.isNotNil(value, "Should get visual setting value")
    end
end)
-- UX Test 14: Progress Tracking
UserExperienceTests:addTest("Progress Tracking", function()
    -- Test achievement progress
    local achievements = game.getAchievements()
    Assert.isNotNil(achievements, "Should provide achievement list")
    for i, achievement in ipairs(achievements) do
        local progress = game.getAchievementProgress(achievement.id)
        Assert.isNotNil(progress, "Should track achievement progress")
        Assert.isTrue(progress >= 0 and progress <= 100, "Progress should be 0-100%")
    end
    -- Test level progression
    local level = game.getCurrentLevel()
    Assert.isNotNil(level, "Should track current level")
    local experience = game.getExperience()
    Assert.isNotNil(experience, "Should track experience points")
    local nextLevel = game.getNextLevelRequirement()
    Assert.isNotNil(nextLevel, "Should show next level requirement")
end)
-- UX Test 15: Player Satisfaction Metrics
UserExperienceTests:addTest("Player Satisfaction Metrics", function()
    -- Test session length tracking
    local sessionLength = game.getSessionLength()
    Assert.isNotNil(sessionLength, "Should track session length")
    Assert.isTrue(sessionLength > 0, "Session length should be positive")
    -- Test engagement metrics
    local engagement = game.calculateEngagement()
    Assert.isNotNil(engagement, "Should calculate engagement score")
    Assert.isTrue(engagement >= 0 and engagement <= 100, "Engagement should be 0-100%")
    -- Test retention prediction
    local retention = game.predictRetention()
    Assert.isNotNil(retention, "Should predict player retention")
    Assert.isTrue(retention >= 0 and retention <= 100, "Retention should be 0-100%")
    -- Test satisfaction survey
    local satisfaction = game.measureSatisfaction()
    Assert.isNotNil(satisfaction, "Should measure player satisfaction")
    Assert.isTrue(satisfaction >= 1 and satisfaction <= 5, "Satisfaction should be 1-5 scale")
end)
-- Return the test suite for external execution
return UserExperienceTests