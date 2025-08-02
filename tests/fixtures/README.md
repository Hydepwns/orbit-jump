# Standalone Tests

This directory contains standalone test files that are meant to be run independently of the main game, not as part of the automated test suite.

## Files

### font_test.lua
A standalone Love2D application for testing the Monaspace Argon fonts used in Orbit Jump.

**Usage:**
```bash
cd orbit-jump
love standalone_tests/font_test.lua
```

This will open a window displaying all the font variants (Regular, Bold, Light, ExtraBold) to verify they load correctly and render properly.

**Controls:**
- ESC: Exit the font test

## Why Standalone?

These files define their own Love2D callbacks (like `love.keypressed`, `love.draw`, etc.) which would conflict with the main game's callbacks if included in the regular test suite. By keeping them separate, we avoid duplicate field warnings from the Lua Language Server while still maintaining useful testing utilities.

## Adding New Standalone Tests

When creating new standalone tests:

1. Place them in this directory
2. Make sure they're self-contained Love2D applications
3. Include clear usage instructions in this README
4. Avoid naming conflicts with main game modules

The `standalone_tests` directory is excluded from Lua Language Server diagnostics via `.luarc.json` to prevent false positive warnings about duplicate Love2D callbacks.