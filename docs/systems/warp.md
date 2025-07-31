# warp system

the warp system enables instant travel between discovered planets through an adaptive, learning-based mechanics system.

## overview

the warp drive is a late-game system that learns from player behavior to provide increasingly efficient interstellar travel. it consists of four main subsystems working in harmony:

- **warp core** - handles state management, animations, and the actual warping process
- **warp energy** - manages energy consumption and regeneration
- **warp memory** - implements adaptive learning and route optimization
- **warp navigation** - provides targeting interface and path calculation

## architecture

```
warp_drive.lua (main interface)
    ├── warp_core.lua (mechanics & state)
    ├── warp_energy.lua (resource management)
    ├── warp_memory.lua (adaptive learning)
    └── warp_navigation.lua (targeting & ui)
```

## adaptive learning mechanics

the warp system learns from player behavior over time:

### cost calculation factors

1. **base physics cost** - distance-based foundation (50-500 energy)
2. **route familiarity** - frequently used routes become cheaper (up to 30% discount)
3. **player mastery** - overall skill reduces costs (up to 20% reduction)
4. **emergency compassion** - system detects distress and reduces costs (up to 60% relief)
5. **exploration incentive** - new destinations cost less to encourage discovery
6. **planet affinity** - develops preferences for certain planet types

### memory persistence

the system maintains persistent memory across sessions:

- route history and frequency
- player skill metrics
- emergency pattern recognition
- exploration achievements

## api reference

### core functions

```lua
-- initialize the warp system
WarpDrive.init()

-- unlock warp capability
WarpDrive.unlock()

-- check if player can afford warp
local canWarp = WarpDrive.canAffordWarp(targetPlanet, player, gameContext)

-- calculate adaptive cost
local cost = WarpDrive.calculateCost(distance, sourceX, sourceY, targetPlanet, gameContext)

-- initiate warp sequence
local success = WarpDrive.startWarp(targetPlanet, player, gameContext)

-- update warp systems (call each frame)
WarpDrive.update(dt, player)

-- render warp effects
WarpDrive.draw(player)
WarpDrive.drawUI(player, planets, camera)
```

### status and state

```lua
-- get comprehensive status
local status = WarpDrive.getStatus()
-- returns: {
--   unlocked = boolean,
--   isWarping = boolean,
--   energy = number,
--   maxEnergy = number,
--   totalWarps = number,
--   knownRoutes = number,
--   efficiency = number,
--   skillLevel = string
-- }

-- save/restore state
local state = WarpDrive.saveState()
WarpDrive.restoreState(state)
```

## visual effects

the warp system provides rich visual feedback:

- **particle effects** - energy particles during charging and arrival
- **tunnel animation** - rotating rings during warp sequence
- **progress indicator** - shows warp completion status
- **energy bar** - displays available warp energy

## integration points

### achievement system

- tracks first warp unlock
- monitors total warps completed
- recognizes exploration milestones

### analytics system

- records warp patterns
- analyzes route preferences
- identifies player behavior trends

### emotion system

- detects emergency situations
- provides contextual feedback
- adjusts difficulty dynamically

## configuration

key parameters in `warp_core.lua`:

- `warpDuration = 2.0` - animation duration in seconds
- `maxParticles = 50` - visual effect limit

energy settings in `warp_energy.lua`:

- `maxEnergy = 1000` - maximum stored energy
- `regenRate = 50/sec` - passive regeneration
- `baseCostMultiplier = 0.1` - distance to cost ratio

## performance considerations

- particle pooling for effect optimization
- lazy loading of subsystems
- memory state saved asynchronously
- visual effects scale with performance mode

## example usage

```lua
-- basic warp implementation
function onWarpButtonPressed()
    if WarpDrive.isUnlocked() and not WarpDrive.isWarping() then
        local planet = getSelectedPlanet()
        if planet and WarpDrive.canAffordWarp(planet, player, game) then
            WarpDrive.startWarp(planet, player, game)
        end
    end
end

-- in game update loop
function update(dt)
    WarpDrive.update(dt, player)
end

-- in render loop
function draw()
    WarpDrive.draw(player)
    WarpDrive.drawUI(player, planets, camera)
end
```

## troubleshooting

**warp not available**

- ensure `WarpDrive.unlock()` has been called
- check if player has discovered target planet
- verify sufficient energy available

**high warp costs**

- build route familiarity through repeated use
- increase overall mastery level
- check for emergency detection false positives

**visual glitches**

- verify particle limit not exceeded
- check performance mode settings
- ensure proper draw order in render loop
