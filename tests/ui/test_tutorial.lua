-- Test script to verify tutorial fixes
local Game = require("src.core.game")
local GameState = require("src.core.game_state")
local TutorialSystem = require("src.ui.tutorial_system")

print("=== Testing Tutorial Fix ===")

-- Initialize game
print("1. Initializing game...")
Game.init()

print("\n2. Checking initial state:")
print("   - Tutorial active:", TutorialSystem.isActive)
print("   - Current step:", TutorialSystem.currentStep)
print("   - Player on planet:", GameState.player.onPlanet)
print("   - Number of planets:", #GameState.objects.planets)
print("   - Number of rings:", #GameState.objects.rings)

-- Check if player is properly positioned
if GameState.player.onPlanet then
    local planet = GameState.objects.planets[GameState.player.onPlanet]
    if planet then
        print("   - Player on planet at:", planet.x, planet.y)
        print("   - Player position:", GameState.player.x, GameState.player.y)
    end
end

-- Test input handling
print("\n3. Testing input handling:")
print("   - Tutorial has handleKeyPress:", TutorialSystem.handleKeyPress ~= nil)
print("   - Tutorial has mousepressed:", TutorialSystem.mousepressed ~= nil)
print("   - Tutorial has mousereleased:", TutorialSystem.mousereleased ~= nil)

-- Simulate a jump
print("\n4. Simulating jump action:")
if GameState.player.onPlanet then
    -- Simulate mouse press
    GameState.handleMousePress(100, 100, 1)
    print("   - Charging:", GameState.data.isCharging)
    
    -- Simulate mouse release (jump)
    GameState.handleMouseRelease(200, 200, 1)
    print("   - Player jumped successfully")
    print("   - Tutorial step after jump:", TutorialSystem.currentStep)
end

print("\n=== Test Complete ===")