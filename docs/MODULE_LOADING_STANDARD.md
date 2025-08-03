# Module Loading Standards for Orbit Jump

## Overview

This document establishes the standardized module loading patterns for the Orbit Jump codebase to ensure consistency, prevent circular dependencies, and enable proper caching.

## Standard Pattern: Utils.require

Always use `Utils.require()` instead of the native `require()` function:

```lua
-- ✅ Good
local PlayerSystem = Utils.require("src.systems.player_system")

-- ❌ Bad
local PlayerSystem = require("src.systems.player_system")
```

### Benefits

1. **Caching**: Prevents duplicate module loading
2. **Error Handling**: Built-in error handling with fallbacks
3. **Logging**: Automatic logging of module load failures
4. **Hot Reload Support**: Foundation for future hot-reload capability

## Module Path Conventions

### Path Format

Always use dot notation for module paths:

```lua
-- ✅ Good
Utils.require("src.systems.player.player_movement")

-- ❌ Bad
Utils.require("src/systems/player/player_movement")
```

### Path Structure

```
src.category.module_name
src.category.subcategory.module_name
```

Examples:
- `src.core.game`
- `src.systems.player_system`
- `src.systems.player.player_movement`
- `src.ui.components.button`
- `src.utils.math_utils`

## Module Structure

### Standard Module Template

```lua
--[[
    Module Name: Brief Description
    
    Longer description of what this module does,
    its responsibilities, and key features.
--]]

local Utils = require("src.utils.utils")

-- Load dependencies
local Dependency1 = Utils.require("src.category.dependency1")
local Dependency2 = Utils.require("src.category.dependency2")

-- Module table
local ModuleName = {}

-- Constants
ModuleName.CONSTANT_NAME = 100

-- Private variables
local privateVariable = 0
local privateTable = {}

-- Forward declarations for private functions
local privateFunction1
local privateFunction2

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Public API
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Initialize the module
function ModuleName.init()
    -- Initialization code
end

-- Public function with documentation
function ModuleName.publicFunction(param1, param2)
    -- Implementation
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Private Implementation
    ═══════════════════════════════════════════════════════════════════════════
--]]

-- Private function implementation
privateFunction1 = function()
    -- Implementation
end

privateFunction2 = function()
    -- Implementation
end

-- Return the module table
return ModuleName
```

## Dependency Management

### Avoiding Circular Dependencies

1. **Layer Architecture**: Higher layers depend on lower layers
   ```
   UI → Systems → Core → Utils
   ```

2. **Dependency Injection**: Pass dependencies instead of requiring them
   ```lua
   -- Instead of requiring GameState inside PlayerSystem
   function PlayerSystem.update(dt, gameState)
       -- Use passed gameState
   end
   ```

3. **Event Bus**: Use events for cross-system communication
   ```lua
   EventBus.emit("player.jumped", {height = 100})
   ```

### Lazy Loading

For optional or rarely-used dependencies:

```lua
local HeavyModule

function ModuleName.useHeavyFeature()
    -- Load only when needed
    if not HeavyModule then
        HeavyModule = Utils.require("src.systems.heavy_module")
    end
    
    HeavyModule.doSomething()
end
```

## Global Access

### When to Use Globals

Only these should be global:
- `Game` - Main game instance
- `GameState` - Current game state
- `GameCamera` - Active camera
- `Utils` - Utility functions
- `Config` - Configuration

### Setting Globals

```lua
-- Only in main initialization
_G.GameCamera = Camera:new()
_G.GameState = GameState

-- Never in regular modules
_G.MyModule = MyModule  -- ❌ Bad
```

## Module Categories

### Core (`src/core/`)
Foundation modules that other systems depend on:
- `game.lua` - Main game loop
- `game_state.lua` - State management
- `renderer.lua` - Rendering pipeline
- `camera.lua` - Camera system

### Systems (`src/systems/`)
Game mechanics and features:
- `player_system.lua` - Player mechanics
- `collision_system.lua` - Physics
- `particle_system.lua` - Visual effects

### UI (`src/ui/`)
User interface components:
- `components/` - Reusable UI components
- `screens/` - Full screen UIs
- `debug/` - Debug interfaces

### Utils (`src/utils/`)
Shared utilities and helpers:
- Must be stateless when possible
- No dependencies on game systems
- Pure functions preferred

## Migration Guide

### Finding Direct requires

```bash
# Find all direct require calls
grep -r "require(" src/ | grep -v "Utils.require"
```

### Migration Steps

1. Replace `require` with `Utils.require`
2. Convert paths to dot notation
3. Check for circular dependencies
4. Test module loading

### Example Migration

```lua
-- Old
local PlayerSystem = require("src/systems/player_system")
local math_utils = require("src.utils.math_utils")

-- New
local PlayerSystem = Utils.require("src.systems.player_system")
local MathUtils = Utils.require("src.utils.math_utils")
```

## Testing Module Loading

```lua
-- Test module can be loaded
local success, module = pcall(Utils.require, "src.systems.my_module")
assert(success, "Module should load without errors")
assert(type(module) == "table", "Module should return a table")

-- Test module has expected interface
assert(type(module.init) == "function", "Module should have init function")
```

## Common Issues

### Issue 1: Module Not Found
```
Error: Failed to load module 'src.systems.missing'
```
**Solution**: Check file path and name match exactly

### Issue 2: Circular Dependency
```
Error: Loop detected in module loading
```
**Solution**: Refactor to use dependency injection or events

### Issue 3: Global Pollution
```
Warning: Module sets global variable
```
**Solution**: Return module table instead of setting global

## Best Practices

1. **One Module Per File**: Each file should export exactly one module
2. **Consistent Naming**: File name should match module name
3. **Clear Dependencies**: List all dependencies at the top
4. **No Side Effects**: Module loading shouldn't modify state
5. **Document Exports**: Clearly document public API

## Performance Considerations

1. **Load Once**: Modules are cached after first load
2. **Minimize Dependencies**: Fewer dependencies = faster load
3. **Lazy Load**: Defer loading heavy modules until needed
4. **Batch Loading**: Load related modules together

## Future Enhancements

The standardized loading pattern enables:
- Hot module reloading during development
- Dependency graph visualization
- Automatic circular dependency detection
- Module load time profiling
- Selective module reloading for testing