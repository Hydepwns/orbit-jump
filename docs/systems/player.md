# Player System

The Player System handles all player-related mechanics including movement, abilities, and state management.

## Architecture

The player system uses a modular architecture with a facade pattern:

- **player_system.lua** - Main interface (158 lines)
- **player_movement.lua** - Physics simulation (408 lines)
- **player_abilities.lua** - Jump & dash systems (387 lines)
- **player_state.lua** - State management (430 lines)

## Core Mechanics

### Movement Physics

- **Orbital Motion**: Realistic planetary orbits using circular physics
- **N-body Gravity**: All planets influence the player simultaneously
- **Momentum Conservation**: Realistic physics with game-feel adjustments

### Jump System

- **Aim & Power**: Mouse-based targeting with visual feedback
- **Trajectory Prediction**: Shows estimated path before jumping
- **Skill Progression**: System learns and adapts to player skill

### Dash Ability

- **Emergency Escape**: Quick directional movement with cooldown
- **Strategic Use**: Affects momentum and can chain with jumps
- **Visual Effects**: Particle trail and screen effects

## API Reference

### Basic Interface

```lua
local PlayerSystem = require("src.systems.player_system")

-- Initialize the system
PlayerSystem.init()

-- Update player (called every frame)
PlayerSystem.update(player, planets, dt, gameState)

-- Trigger jump
PlayerSystem.jump(player, targetX, targetY, power)

-- Trigger dash
PlayerSystem.dash(player, direction)
```

### Module Access

```lua
-- Direct module access for advanced usage
local PlayerMovement = require("src.systems.player.player_movement")
local PlayerAbilities = require("src.systems.player.player_abilities")
local PlayerState = require("src.systems.player.player_state")

-- Update specific subsystems
PlayerMovement.updateMovement(player, planets, dt)
PlayerAbilities.updateCooldowns(player, dt)
PlayerState.trackState(player, gameState)
```

## Configuration

Key player parameters (in `src/systems/player/`):

```lua
-- Movement constants
GRAVITY_CONSTANT = 1000
JUMP_BASE_POWER = 300
DASH_SPEED = 500
DASH_COOLDOWN = 2.0

-- Physics tuning
ORBITAL_DAMPING = 0.02
LANDING_THRESHOLD = 5.0
```

## Performance

The player system is highly optimized:

- **Zero Allocation Paths**: Critical update loops avoid memory allocation
- **Object Pooling**: Reuses particle and effect objects
- **Efficient Collision**: Spatial partitioning for planet detection

## Testing

Run player system tests:

```bash
# All player tests
lua tests/systems/player/test_player_movement_busted.lua
lua tests/systems/player/test_player_abilities_busted.lua
lua tests/systems/player/test_player_state_busted.lua

# Integration tests
lua tests/final_integration_test.lua
```

## Debugging

Enable debug visualization:

```lua
-- In player_movement.lua
local DEBUG_TRAILS = true  -- Show movement trails
local DEBUG_GRAVITY = true  -- Show gravity vectors
local DEBUG_COLLISIONS = true  -- Highlight collision areas
```
