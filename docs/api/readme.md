# api reference

comprehensive api documentation for orbit jump's core systems and modules.

## core systems

### game systems

- [player](player.md) - player movement, state, and abilities
- [warp](warp.md) - warp drive and interstellar travel
- [analytics](analytics.md) - player behavior tracking
- [emotion](emotion.md) - emotional feedback system
- [achievement](achievement.md) - achievement tracking and rewards
- [progression](progression.md) - player progression and upgrades

### world systems

- [world-generator](world-generator.md) - procedural world generation
- [planet](planet.md) - planet types and behaviors
- [ring](ring.md) - collectible ring system
- [collision](collision.md) - physics and collision detection
- [particle](particle.md) - particle effects system

### core modules

- [game](game.md) - main game loop and state
- [renderer](renderer.md) - rendering pipeline
- [camera](camera.md) - camera system and controls
- [save](save.md) - save/load functionality

### ui systems

- [ui](ui.md) - user interface framework
- [pause-menu](pause-menu.md) - pause menu interface
- [settings](settings.md) - settings menu
- [tutorial](tutorial.md) - tutorial system

### utilities

- [utils](utils.md) - common utility functions
- [constants](constants.md) - game constants
- [config](config.md) - configuration management
- [event-bus](event-bus.md) - event system

## module structure

each api documentation file follows this structure:

```markdown
# module name

brief description of the module's purpose.

## overview

detailed explanation of what the module does and how it fits
into the overall architecture.

## api

### functions

#### module.functionname(param1, param2)
description of what the function does.

**parameters:**
- `param1` (type) - description
- `param2` (type) - description

**returns:**
- (type) - description

**example:**
```lua
local result = module.functionname(value1, value2)
```

### properties

#### module.propertyname

description of the property.

- **type:** type
- **default:** default value
- **access:** read/write or read-only

```

## usage patterns

common patterns for using the apis:

### initialization
most systems require initialization:
```lua
System.init()
```

### update loops

systems that need per-frame updates:

```lua
function update(dt)
    System.update(dt)
end
```

### event handling

systems that respond to events:

```lua
System.onEvent(eventType, params)
```

### state management

systems with save/restore:

```lua
local state = System.saveState()
System.restoreState(state)
```

## best practices

1. **always initialize** - call init() before using a system
2. **check return values** - many functions return success/failure
3. **use proper types** - lua is dynamic but apis expect specific types
4. **handle errors** - use pcall for potentially failing operations
5. **respect lifecycles** - init → use → cleanup pattern

## version compatibility

this documentation covers orbit jump version 1.0.0+

apis marked as:

- **stable** - safe to use, won't change
- **experimental** - may change in future versions
- **deprecated** - will be removed, use alternatives
- **internal** - not for public use
