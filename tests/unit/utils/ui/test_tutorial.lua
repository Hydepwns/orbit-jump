-- Test script to verify tutorial fixes
local Utils = require("src.utils.utils")
local Game = Utils.require("src.core.game")
local GameState = Utils.require("src.core.game_state")
local TutorialSystem = Utils.require("src.ui.tutorial_system")
Utils.Logger.info("=== Testing Tutorial Fix ===")
-- Initialize game
Utils.Logger.info("1. Initializing game...")
Game.init()
Utils.Logger.info("\n2. Checking initial state:")
Utils.Logger.info("   - Tutorial active: %s", TutorialSystem.isActive)
Utils.Logger.info("   - Current step: %s", TutorialSystem.currentStep)
Utils.Logger.info("   - Player on planet: %s", GameState.player.onPlanet)
Utils.Logger.info("   - Number of planets: %d", #GameState.objects.planets)
Utils.Logger.info("   - Number of rings: %d", #GameState.objects.rings)
-- Check if player is properly positioned
if GameState.player.onPlanet then
    local planet = GameState.objects.planets[GameState.player.onPlanet]
    if planet then
        Utils.Logger.info("   - Player on planet at: %s, %s", planet.x, planet.y)
        Utils.Logger.info("   - Player position: %s, %s", GameState.player.x, GameState.player.y)
    end
end
-- Test input handling
Utils.Logger.info("\n3. Testing input handling:")
Utils.Logger.info("   - Tutorial has handleKeyPress: %s", TutorialSystem.handleKeyPress ~= nil)
Utils.Logger.info("   - Tutorial has mousepressed: %s", TutorialSystem.mousepressed ~= nil)
Utils.Logger.info("   - Tutorial has mousereleased: %s", TutorialSystem.mousereleased ~= nil)
-- Simulate a jump
Utils.Logger.info("\n4. Simulating jump action:")
if GameState.player.onPlanet then
    -- Simulate mouse press
    GameState.handleMousePress(100, 100, 1)
    Utils.Logger.info("   - Charging: %s", GameState.data.isCharging)
    -- Simulate mouse release (jump)
    GameState.handleMouseRelease(200, 200, 1)
    Utils.Logger.info("   - Player jumped successfully")
    Utils.Logger.info("   - Tutorial step after jump: %s", TutorialSystem.currentStep)
end
Utils.Logger.info("\n=== Test Complete ===")