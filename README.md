# Orbit Jump

[![LÖVE](https://img.shields.io/badge/LÖVE-11.0%2B-ff69b4.svg)](https://love2d.org/)
[![Lua](https://img.shields.io/badge/Lua-5.3%2B-blue.svg)](https://www.lua.org/)
[![Tests](https://img.shields.io/badge/tests-179%2B-brightgreen.svg)](docs/testing.md)
[![Coverage](https://img.shields.io/badge/coverage-95%25%2B-brightgreen.svg)](docs/testing.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A gravity-based arcade game where players jump between planets using realistic physics. Features adaptive systems that learn from your play style.

## Features

### Core Gameplay

- **Physics-Based Movement** - Realistic orbital mechanics and multi-body gravity
- **Planet Hopping** - Jump between diverse planets with unique properties
- **Collectible Rings** - Gather resources for upgrades and score
- **Warp Drive** - Unlock instant travel with adaptive cost mechanics
- **Interactive Tutorial** - Progressive learning system with contextual help

### Adaptive Systems

- **Learning AI** - Game adapts to your playstyle and skill level
- **Emotional Feedback** - Dynamic responses that celebrate your achievements
- **Player Analytics** - Tracks progress and provides personalized insights
- **Route Memory** - Warp system learns and optimizes frequently traveled paths

### Technical Excellence

- **60 FPS Performance** - Optimized rendering with spatial indexing and LOD system
- **Zero-Allocation Design** - Smooth gameplay without garbage collection pauses
- **Modular Architecture** - Clean, maintainable codebase with 95%+ test coverage
- **Cross-Platform** - Desktop and mobile with touch gestures and accessibility features

## Requirements

- [LÖVE2D](https://love2d.org/) 11.0+

## Installation

```bash
# macOS
brew install love

# NixOS
nix profile install nixpkgs#love

# Linux
sudo apt install love2d  # Ubuntu/Debian
sudo dnf install love    # Fedora
sudo pacman -S love      # Arch

# Other systems
# Download from love2d.org
```

## Quick Start

```bash
love .
```

## Documentation

See [`docs/`](docs/) for detailed information:

- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Performance](docs/performance.md)
- [Contributing](docs/contributing.md)
- [Migration Guide](docs/migration.md)

## Controls

### Desktop

- **Jump**: Click and drag to aim, release to jump
- **Dash**: Shift / Z / X (while in space)
- **Tutorial**: T (start/resume), Escape (exit)
- **Restart**: Space (after game over)
- **Pause**: Escape

### Mobile

- **Jump**: Swipe from player
- **Dash**: Double-tap screen
- **Zoom**: Pinch gesture
- **Restart**: Tap screen
- **Pause**: Tap pause button

## Development

### Running Tests

```bash
# All tests
lua tests/run_modern_tests.lua

# Integration tests
lua tests/run_integration_tests.lua

# Specific system
lua tests/systems/warp/test_warp_core_busted.lua

orbit-jump/
├── main.lua                # Entry point
├── src/
│   ├── core/              # Core game systems
│   ├── systems/           # Game features
│   │   ├── warp_drive.lua # (facade)
│   │   ├── warp/          # (modules)
│   │   ├── player_analytics.lua
│   │   ├── analytics/
│   │   ├── emotional_feedback.lua
│   │   ├── emotion/
│   │   ├── player_system.lua
│   │   └── player/
│   ├── utils/             # Utilities
│   ├── audio/             # Sound system
│   ├── ui/                # Interface
│   └── world/             # World generation
├── assets/                # Game assets
├── tests/                 # Test suite
├── docs/                  # Documentation
└── libs/                  # External libraries
```

## Configuration

Game settings in `src/utils/config.lua`:

```lua
Config.performance.enableSpatialGrid = true
Config.progression.maxUpgradeLevel = 15
```

## License

MIT
