# Orbit Jump

[![LÖVE](https://img.shields.io/badge/LÖVE-11.0%2B-ff69b4.svg)](https://love2d.org/)
[![Lua](https://img.shields.io/badge/Lua-5.3%2B-blue.svg)](https://www.lua.org/)
[![LuaRocks](https://img.shields.io/badge/LuaRocks-1.0.0--2-orange.svg)](https://luarocks.org/modules/hydepwns/orbit-jump)
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

### Via LuaRocks (Recommended)

```bash
# Install via LuaRocks
luarocks install orbit-jump

# Run the game
love orbit-jump
```

**Note**: LÖVE2D must be installed separately via your system package manager.

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/Hydepwns/orbit-jump.git
cd orbit-jump

# Install LÖVE2D
# macOS
brew install love

# NixOS
nix profile install nixpkgs#love

# Linux
sudo apt install love2d  # Ubuntu/Debian
sudo dnf install love    # Fedora
sudo pacman -S love      # Arch

# Run the game
love .
```

### Using the Installation Script

```bash
# Show installation options
lua install.lua --help

# Install via LuaRocks
lua install.lua --luarocks

# Show manual installation instructions
lua install.lua --manual
```

### Package Validation

```bash
# Validate package structure for LuaRocks publishing
lua scripts/publishing/test_package.lua
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
- [LuaRocks Publishing](docs/publishing.md)

## License

MIT
