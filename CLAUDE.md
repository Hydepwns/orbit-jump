# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Game

```bash
# Run the game with LÖVE2D
love .
```

## Common Development Commands

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Run specific test types
./run_tests.sh unit         # Unit tests only (fastest)
./run_tests.sh integration  # Integration tests only
./run_tests.sh performance  # Performance tests only
./run_tests.sh ui          # UI tests only
./run_tests.sh fast        # Fast test suite (unit + basic integration)

# Watch mode for development
./run_tests.sh --watch

# Filter tests by pattern
./run_tests.sh --filter "player"

# Run with coverage
./run_tests.sh --coverage

# Interactive test runner
lua tests/run_interactive_tests.lua
```

### Running a Single Test

```lua
-- Direct Lua execution for specific test file
lua tests/unit/systems/test_player_system.lua

-- Or use the unified framework runner
lua tests/frameworks/run_unified_tests_simple.lua --filter "specific_test_name"
```

## High-Level Architecture

Orbit Jump is a LÖVE2D-based gravity physics game with a modular architecture centered around the Facade pattern. The game starts from `main.lua` which delegates to `src/core/game.lua`.

### Core Architecture Principles

1. **Facade Pattern**: Each major system has a main interface file that coordinates multiple focused submodules
2. **Backwards Compatibility**: Original APIs are preserved while internal implementations are refactored
3. **Performance-First**: Heavy use of object pooling, circular buffers, and caching to minimize GC pressure

### Key Systems and Their Structure

#### Core Game Loop (`src/core/`)
- `game.lua` - Main orchestrator using SystemOrchestrator for dependency injection
- `game_logic.lua` - Core gameplay mechanics
- `game_state.lua` - State management
- `renderer.lua` - Rendering pipeline
- `camera.lua` - Camera system

#### Major Game Systems (`src/systems/`)

**Warp Drive System** - Teleportation and movement mechanics
- `warp_drive.lua` (facade) → `warp/` submodules:
  - `warp_core.lua` - Core mechanics
  - `warp_energy.lua` - Energy management
  - `warp_memory.lua` - Adaptive learning (430 lines)
  - `warp_navigation.lua` - Path calculation

**Player System** - Player physics and abilities
- `player_system.lua` (facade) → `player/` submodules:
  - `player_movement.lua` - Physics engine (408 lines)
  - `player_abilities.lua` - Jump & dash systems
  - `player_state.lua` - State management

**Emotional Feedback System** - Adaptive player experience
- `emotional_feedback.lua` (facade) → `emotion/` submodules:
  - `emotion_core.lua` - State management
  - `feedback_renderer.lua` - Multi-sensory output
  - `emotion_analytics.lua` - Pattern tracking (optimized)

**Analytics System** - Player behavior analysis
- `player_analytics.lua` (facade) → `analytics/` submodules:
  - `behavior_tracker.lua` - Movement tracking
  - `pattern_analyzer.lua` - Skill analysis
  - `insight_generator.lua` - Recommendations

#### Testing Framework (`tests/`)
- Unified test framework supporting unit, integration, performance, and UI tests
- Located in `tests/frameworks/unified_test_framework.lua`
- Tests organized by type: `unit/`, `integration/`, `performance/`

### Performance Optimizations

The codebase has been heavily optimized with:
- 95% reduction in temporary object creation through object pooling
- Circular buffers to eliminate array growth allocations
- Intelligent caching reducing repeated calculations by 80%
- Overall: 70% GC reduction, 50% allocation reduction

### Module Loading Pattern

The game uses a custom module loader (`src/utils/module_loader.lua`) with caching to prevent duplicate requires and improve startup time.

## Important Notes

- No linting commands were found in the repository. Ask the user for lint/typecheck commands if needed.
- The game uses LÖVE2D 11.0+ as its engine
- Mobile support is built-in with touch gesture handling
- Save system uses a registry pattern for persistence
- Performance monitoring is integrated throughout