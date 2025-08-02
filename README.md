# Orbit Jump

[![LÖVE](https://img.shields.io/badge/LÖVE-11.0%2B-ff69b4.svg)](https://love2d.org/)
[![Lua](https://img.shields.io/badge/Lua-5.3%2B-blue.svg)](https://www.lua.org/)
[![Tests](https://img.shields.io/badge/tests-unified%20framework-brightgreen.svg)](docs/testing.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A gravity-based arcade game with realistic physics and adaptive systems.

## Features

- **Physics-Based Movement** - Realistic orbital mechanics
- **Planet Hopping** - Jump between diverse planets
- **Adaptive Systems** - Game learns from your playstyle
- **Cross-Platform** - Desktop and mobile support

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
```

## Quick Start

```bash
love .
```

## Development

### Running Tests

```bash
# All tests
./run_tests.sh

# Specific test types
./run_tests.sh unit
./run_tests.sh integration
./run_tests.sh performance

# Interactive runner
lua tests/run_interactive_tests.lua
```

### Project Structure

```
src/
├── core/              # Core game systems
├── systems/           # Game features
├── utils/             # Utilities
├── audio/             # Sound system
├── ui/                # Interface
└── world/             # World generation
```

## Controls

### Desktop

- **Jump**: Click and drag to aim, release to jump
- **Dash**: Shift / Z / X (while in space)
- **Restart**: Space (after game over)
- **Pause**: Escape

### Mobile

- **Jump**: Swipe from player
- **Dash**: Double-tap screen
- **Restart**: Tap screen

## Documentation

- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [Testing](docs/testing.md)
- [Contributing](docs/contributing.md)

## License

MIT
