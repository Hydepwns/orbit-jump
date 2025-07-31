# player api

comprehensive api reference for the player system, including movement, state management, and abilities.

## overview

the player system manages all aspects of the player character including physics-based movement, orbital mechanics, state tracking, and ability management. it consists of three main modules working together:

- **player_system** - main interface and coordination
- **player_movement** - physics and movement calculations  
- **player_state** - state management and persistence
- **player_abilities** - special abilities like dash

## player_system

main player system interface.

### functions

#### PlayerSystem.init()

initializes the player system and all subsystems.

**returns:**

- `boolean` - true if initialization successful

**example:**

```lua
PlayerSystem.init()
```

#### PlayerSystem.update(dt, player)

updates player physics, movement, and abilities.

**parameters:**

- `dt` (number) - delta time in seconds
- `player` (table) - player object to update

**example:**

```lua
function update(dt)
    PlayerSystem.update(dt, gameState.player)
end
```

#### PlayerSystem.draw(player)

renders the player and related effects.

**parameters:**

- `player` (table) - player object to draw

**example:**

```lua
function draw()
    PlayerSystem.draw(gameState.player)
end
```

#### PlayerSystem.handleMousePressed(x, y, button, player, planets)

handles mouse press events for jump initiation.

**parameters:**

- `x` (number) - mouse x position
- `y` (number) - mouse y position  
- `button` (number) - mouse button (1=left, 2=right)
- `player` (table) - player object
- `planets` (table) - array of planet objects

**returns:**

- `boolean` - true if event was handled

#### PlayerSystem.handleMouseReleased(x, y, button, player, camera)

handles mouse release events for jump execution.

**parameters:**

- `x` (number) - mouse x position
- `y` (number) - mouse y position
- `button` (number) - mouse button
- `player` (table) - player object
- `camera` (table) - camera object for world coordinates

**returns:**

- `boolean` - true if jump was executed

### properties

#### PlayerSystem.isJumping

whether the player is currently jumping.

- **type:** boolean
- **access:** read-only

## player_movement

handles physics calculations and movement mechanics.

### functions

#### PlayerMovement.createPlayer(x, y)

creates a new player object at the specified position.

**parameters:**

- `x` (number) - initial x position
- `y` (number) - initial y position

**returns:**

- `table` - new player object

**example:**

```lua
local player = PlayerMovement.createPlayer(500, 400)
```

#### PlayerMovement.update(dt, player, planets, gameState)

updates player physics including gravity and collisions.

**parameters:**

- `dt` (number) - delta time
- `player` (table) - player object
- `planets` (table) - array of planets for gravity
- `gameState` (table) - current game state

#### PlayerMovement.calculateGravity(player, planets)

calculates gravitational forces from all planets.

**parameters:**

- `player` (table) - player object
- `planets` (table) - array of planet objects

**returns:**

- `number, number` - gravity force x and y components

#### PlayerMovement.applyOrbitalVelocity(player, targetX, targetY, pullPower)

applies velocity for orbital jump.

**parameters:**

- `player` (table) - player object
- `targetX` (number) - target x position
- `targetY` (number) - target y position
- `pullPower` (number) - jump power (0-100)

## player_state

manages player state and persistence.

### functions

#### PlayerState.saveState(player)

saves current player state for persistence.

**parameters:**

- `player` (table) - player object to save

**returns:**

- `table` - serializable state data

#### PlayerState.loadState(state)

restores player from saved state.

**parameters:**

- `state` (table) - saved state data

**returns:**

- `table` - restored player object

#### PlayerState.recordJump(player)

records jump statistics for analytics.

**parameters:**

- `player` (table) - player object

#### PlayerState.hasLandedOn(player, planet)

checks if player has previously landed on a planet.

**parameters:**

- `player` (table) - player object
- `planet` (table) - planet to check

**returns:**

- `boolean` - true if player has landed on this planet

## player_abilities

manages special player abilities like dash.

### functions

#### PlayerAbilities.init()

initializes the abilities system.

#### PlayerAbilities.update(dt)

updates ability cooldowns and states.

**parameters:**

- `dt` (number) - delta time

#### PlayerAbilities.dash(player)

executes a dash ability if available.

**parameters:**

- `player` (table) - player object

**returns:**

- `boolean` - true if dash was executed

#### PlayerAbilities.canDash()

checks if dash ability is available.

**returns:**

- `boolean` - true if player can dash

### properties

#### PlayerAbilities.dashCooldown

current dash cooldown time remaining.

- **type:** number
- **access:** read-only

#### PlayerAbilities.maxDashes

maximum number of consecutive dashes.

- **type:** number  
- **default:** 1
- **access:** read/write

## player object structure

```lua
player = {
    -- position
    x = 0,
    y = 0,
    
    -- velocity
    vx = 0,
    vy = 0,
    
    -- physics
    mass = 1,
    radius = 10,
    
    -- state
    isJumping = false,
    currentPlanet = nil,
    rotationSpeed = 0,
    
    -- visuals
    trail = {},
    color = {1, 1, 1},
    
    -- stats
    jumps = 0,
    landings = 0,
    planetsVisited = {},
    
    -- abilities
    dashesRemaining = 1
}
```

## events

the player system emits these events via the event bus:

- `player.jump` - when player initiates jump
- `player.land` - when player lands on planet
- `player.dash` - when player uses dash ability
- `player.death` - when player dies

## usage example

```lua
-- initialization
local PlayerSystem = require("src.systems.player_system")
PlayerSystem.init()

-- create player
local player = PlayerSystem.createPlayer(500, 400)

-- game loop
function update(dt)
    PlayerSystem.update(dt, player)
end

function draw()
    PlayerSystem.draw(player)
end

-- input handling
function mousepressed(x, y, button)
    PlayerSystem.handleMousePressed(x, y, button, player, planets)
end

function mousereleased(x, y, button)
    PlayerSystem.handleMouseReleased(x, y, button, player, camera)
end
```

## performance notes

- trail rendering is optimized with vertex batching
- gravity calculations use squared distance optimization
- state updates are minimal during non-jumping phases
- ability cooldowns use simple timers

## version history

- **1.0.0** - initial api
- **1.1.0** - added dash ability system
- **1.2.0** - improved orbital mechanics
