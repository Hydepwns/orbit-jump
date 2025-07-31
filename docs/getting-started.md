# Getting Started

## Prerequisites

- [LÖVE 2D](https://love2d.org/) game engine
- Lua 5.3+ (for development and testing)

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Hydepwns/orbit-jump.git
   cd orbit-jump
   ```

2. **Run the game:**

   ```bash
   love .
   ```

## Game Controls

- **Mouse**: Aim jump direction and power
- **Click/Space**: Jump to targeted planet
- **Dash**: Right-click or Shift (when available)
- **ESC**: Pause menu

## Game Mechanics

### Planetary Jumping

- **Orbital Physics**: Players orbit planets using realistic physics
- **Jump Targeting**: Aim and power system for precise jumps
- **Gravity Wells**: Multi-body gravity affects trajectory

### Warp Drive

- **Unlockable**: Advanced travel system for long distances
- **Adaptive Learning**: System learns your preferred routes
- **Energy Management**: Strategic use of warp energy

### Progression

- **Ring Collection**: Collect rings for points and upgrades
- **Skill Tracking**: System adapts to your play style
- **Emotional Feedback**: Game responds to your emotional state

## Configuration

Game settings are stored in `conf.lua`. Key settings:

- **Window size**: Default 1024x768
- **Physics**: 60 FPS with realistic gravity
- **Audio**: Optional sound effects and music

## Troubleshooting

### Common Issues

**Game won't start:**

- Ensure LÖVE 2D is properly installed
- Check that all files are present

**Performance issues:**

- Lower window resolution in `conf.lua`
- Disable particle effects if needed

**Controls not working:**

- Check if other applications are intercepting inputs
- Try keyboard controls if mouse fails

## Next Steps

- Read the [Architecture Guide](architecture.md) to understand the system design
- Check out [Testing](testing.md) to run the test suite
- See [Contributing](contributing.md) if you want to help develop the game
