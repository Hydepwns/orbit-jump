# Orbit Jump

A gravity-based arcade game where players jump between planets and dash through rings to build combos.

## Requirements

- [LÖVE2D](https://love2d.org/) 11.0+
- [Monaspace Argon](https://monaspace.githubnext.com/) fonts (included in assets/fonts/)

## Installation

### NixOS

```bash
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

| Action | Control |
|--------|---------|
| Jump | Click/tap and drag to aim, release to jump |
| Dash | Shift / Z / X (while in space) |
| Restart | Space (after game over) |
| Toggle Sound | M |
| Quit | Escape |

## Development

### Running Tests

```bash
lua tests/run_tests.lua
```

### Project Structure

```bash
orbit-jump/
├── main.lua              # Game entry point
├── game_logic.lua        # Core mechanics
├── sound_generator.lua   # Procedural audio
├── sound_manager.lua     # Audio system
├── game.lua             # Game state management
├── assets/              # Fonts and resources
│   ├── fonts/           # Monaspace Argon
│   ├── sounds/          # Audio files
│   └── sprites/         # Graphics
└── tests/               # Test suite
```

## Typography

This game uses the [Monaspace Argon](https://monaspace.githubnext.com/) font family for a modern, developer-friendly typography experience. The fonts are included in the `assets/fonts/` directory and include:

- **Regular**: Default UI text
- **Bold**: Score and combo displays
- **Light**: UI hints and instructions
- **ExtraBold**: Game over screen

## License

MIT
