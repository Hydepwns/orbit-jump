# Orbit Jump

A gravity-based arcade game where players jump between planets and dash through rings to build combos. Built with a modern modular architecture featuring comprehensive progression systems, blockchain integration, and extensive test coverage.

## Requirements

- [LÖVE2D](https://love2d.org/) 11.0+

## Installation

```bash
# macos
brew install love

# NixOS
# Install LÖVE2D using nix profile
nix profile install nixpkgs#love

# Verify installation
love --version
```

### Other Systems

Download LÖVE2D from [love2d.org](https://love2d.org/)

## Quick Start

```bash
love .
```

## Controls

### Desktop Controls

| Action | Control |
|--------|---------|
| Jump | Click and drag to aim, release to jump |
| Dash | Shift / Z / X (while in space) |
| Restart | Space (after game over) |
| Toggle Sound | M |
| Open Upgrades | Click "Upgrades" button |
| Open Blockchain | Click "Blockchain" button |
| Quit | Escape |

### Mobile Controls

| Action | Control |
|--------|---------|
| Jump | Swipe from player to set direction and power |
| Dash | Double-tap screen (while in space) |
| Restart | Tap screen (after game over) |
| Pause | Tap pause button (top right) |
| Open Upgrades | Tap "Upgrades" button |
| Open Blockchain | Tap "Blockchain" button |

## Development

### Running Tests

The project includes comprehensive test coverage (99.2%+) with organized test suites:

```bash
# Run all tests
lua tests/run_tests.lua

# Test specific categories
lua tests/core/test_game_logic.lua      # Core game logic
lua tests/systems/test_ring_system.lua  # Game systems
lua tests/utils/test_utils.lua          # Utilities
```

### Architecture

This project follows a modular architecture with clear separation of concerns:

```bash
orbit-jump/
├── main.lua                     # Minimal entry point (30 lines)
├── src/                         # Source code organized by domain
│   ├── core/                    # Core game systems
│   │   ├── game.lua            # Main game controller
│   │   ├── game_logic.lua      # Game mechanics & physics
│   │   ├── game_state.lua      # Centralized state management
│   │   └── constants.lua       # Game constants
│   ├── systems/                # Game systems
│   │   ├── collision_system.lua
│   │   ├── particle_system.lua
│   │   ├── progression_system.lua
│   │   ├── ring_system.lua
│   │   └── upgrade_system.lua
│   ├── utils/                  # Utilities & helpers
│   │   ├── utils.lua           # Math & general utilities
│   │   ├── camera.lua          # Camera system
│   │   ├── renderer.lua        # Rendering engine
│   │   ├── config.lua          # Configuration management
│   │   ├── error_handler.lua   # Error handling
│   │   └── module_loader.lua   # Module loading utilities
│   ├── audio/                  # Audio systems
│   │   ├── sound_manager.lua   # Audio management
│   │   └── sound_generator.lua # Procedural audio generation
│   ├── ui/                     # User interface
│   │   ├── ui_system.lua       # UI framework
│   │   ├── achievement_system.lua
│   │   ├── pause_menu.lua
│   │   └── settings_menu.lua
│   ├── world/                  # World generation & cosmic systems
│   │   ├── world_generator.lua # Planet & world generation
│   │   ├── cosmic_events.lua   # Dynamic cosmic events
│   │   ├── warp_zones.lua      # Teleportation system
│   │   └── planet_lore.lua     # Planet lore & narratives
│   ├── performance/            # Performance monitoring
│   │   └── performance_monitor.lua
│   ├── dev/                    # Development tools
│   │   └── dev_tools.lua       # Debug console & tools
│   └── blockchain/             # Blockchain integration
│       └── blockchain_integration.lua
├── assets/                     # Game assets
│   ├── fonts/                  # Monaspace Argon font family
│   ├── sounds/                 # Audio files
│   └── sprites/                # Graphics assets
├── tests/                      # Comprehensive test suite (99.2% coverage)
│   ├── core/                   # Core system tests
│   ├── systems/                # Game system tests
│   ├── utils/                  # Utility tests
│   ├── audio/                  # Audio system tests
│   ├── ui/                     # UI system tests
│   ├── world/                  # World generation tests
│   ├── performance/            # Performance tests
│   ├── dev/                    # Development tool tests
│   ├── blockchain/             # Blockchain tests
│   ├── integration_tests/      # Integration tests
│   ├── mocks/                  # Test mocks
│   ├── test_framework.lua      # Custom test framework
│   ├── test_coverage.lua       # Coverage tracking
│   └── run_tests.lua          # Organized test runner
├── docs/                       # Documentation
└── libs/                       # External libraries
```

### 📱 Mobile Optimization

- **Responsive Design**: Adapts to different screen sizes
- **Touch Controls**: Swipe and tap controls for mobile
- **On-Screen Controls**: Visual dash button and pause controls
- **Enhanced Feedback**: Power meters and visual indicators
- **Haptic Feedback**: Vibration support
- **Auto-Pause**: Pauses when app goes to background

### 🚀 Progression System

- **Persistent Progress**: Score, rings, and achievements saved between sessions
- **Upgrade System**: Purchase permanent upgrades with total score
  - Jump Power: Increase jump strength
  - Dash Power: Boost dash effectiveness
  - Speed Boost: Enhance speed multipliers
  - Ring Value: Increase points per ring
  - Combo Multiplier: Boost combo bonuses
  - Gravity Resistance: Reduce gravity effects
- **Achievements**: Unlock achievements for milestones
- **Continuous Building**: Progress builds over time

### ⛓️ Blockchain Integration

- **Web3 Events**: Game events trigger blockchain transactions
- **Token Rewards**: Earn tokens for achievements and milestones
- **NFT Unlocks**: Special achievements unlock unique NFTs
- **Smart Contract Ready**: Integrates with Ethereum/Polygon
- **Batch Processing**: Efficient event batching for lower gas costs
- **Configurable**: Easy to enable/disable

### 🎮 Enhanced Gameplay

- **Progression-Based Mechanics**: Game mechanics scale with upgrades
- **Persistent Stats**: Track playtime, jumps, and highest combos
- **Milestone Rewards**: Special rewards for milestones
- **Meta-Progression**: Unlock new content as you progress
- **Dynamic World**: Procedurally generated planets with lore
- **Cosmic Events**: Special events affecting gameplay and rewards

### 🔧 Performance Optimizations

- **Spatial Grid Collision**: Efficient collision detection with spatial partitioning
- **Culling System**: Only render visible objects
- **Batch Rendering**: Optimized particle rendering
- **Object Pooling**: Memory-efficient particle management
- **Performance Monitoring**: Real-time performance tracking

## Configuration

The game uses a centralized configuration system in `src/utils/config.lua`:

```lua
-- Enable blockchain features
Config.blockchain.enabled = true
Config.blockchain.network = "polygon"  -- or "ethereum", "bsc"
Config.blockchain.webhookUrl = "https://your-webhook.com/events"

-- Customize progression
Config.progression.maxUpgradeLevel = 15
Config.progression.continuousRewards = true

-- Performance settings
Config.performance.enableSpatialGrid = true
Config.performance.enableCulling = true
Config.performance.enableBatchRendering = true
```

## License

MIT
