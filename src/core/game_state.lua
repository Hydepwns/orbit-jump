-- Game State Manager for Orbit Jump
-- Centralizes all game state management for consistency

local Utils = require("src.utils.utils")
-- Cache commonly used modules
local TutorialSystem = Utils.require("src.ui.tutorial_system")
local WorldGenerator = Utils.require("src.systems.world_generator")
local PlayerSystem = Utils.require("src.systems.player_system")
local ParticleSystem = Utils.require("src.systems.particle_system")
local CollisionSystem = Utils.require("src.systems.collision_system")
local RingSystem = Utils.require("src.systems.ring_system")

local GameState = {}

-- Game states
GameState.STATES = {
    PLAYING = "playing",
    GAME_OVER = "gameOver",
    PAUSED = "paused",
    MENU = "menu"
}

-- Current state
GameState.current = GameState.STATES.PLAYING

-- Game data
GameState.data = {
    score = 0,
    combo = 0,
    comboTimer = 0,
    screenWidth = 800,
    screenHeight = 600,
    gameTime = 0,
    isMouseDown = false,
    mouseStartX = 0,
    mouseStartY = 0,
    pullPower = 0,
    maxPullDistance = 250,
    isCharging = false
}

-- Player state
GameState.player = {
    x = 0,
    y = 0,
    vx = 0,
    vy = 0,
    radius = 10,
    onPlanet = 1,
    angle = 0,
    jumpPower = 300,
    dashPower = 500,
    isDashing = false,
    dashTimer = 0,
    dashCooldown = 0,
    trail = {},
    speedBoost = 1.0
}

-- Game objects
GameState.objects = {
    planets = {},
    rings = {},
    particles = {}
}

-- UI state
GameState.ui = {
    currentScreen = "game",
    showProgression = true,
    showBlockchainStatus = false,
    menuSelection = 1,
    upgradeSelection = 1
}

-- Configuration
GameState.config = {
    gravity = 15000,
    ringCount = 15,
    maxCombo = 100,
    comboTimeout = 3.0
}

-- Performance optimizations
GameState.spatialGrid = nil
GameState.particlePool = nil

-- State validation
function GameState.validateState()
    local errors = {}
    
    -- Validate player state
    if not GameState.player.x or not GameState.player.y then
        table.insert(errors, "Player position is invalid")
    end
    
    if GameState.player.radius <= 0 then
        table.insert(errors, "Player radius must be positive")
    end
    
    -- Validate game data
    if GameState.data.score < 0 then
        table.insert(errors, "Score cannot be negative")
    end
    
    if GameState.data.combo < 0 then
        table.insert(errors, "Combo cannot be negative")
    end
    
    -- Validate screen dimensions
    if GameState.data.screenWidth <= 0 or GameState.data.screenHeight <= 0 then
        table.insert(errors, "Screen dimensions must be positive")
    end
    
    if #errors > 0 then
        Utils.Logger.error("Game state validation failed: %s", table.concat(errors, ", "))
        return false, errors
    end
    
    return true
end

function GameState.init(screenWidth, screenHeight)
    Utils.Logger.info("Initializing game state with screen dimensions: %dx%d", screenWidth, screenHeight)
    
    GameState.data.screenWidth = screenWidth
    GameState.data.screenHeight = screenHeight
    
    -- Initialize performance optimizations
    GameState.spatialGrid = Utils.SpatialGrid.new(100)
    GameState.particlePool = Utils.ObjectPool.new(
        function() return {x=0, y=0, vx=0, vy=0, lifetime=0, maxLifetime=1, size=2, color=Utils.colors.particle} end,
        function(particle) 
            particle.x, particle.y, particle.vx, particle.vy = 0, 0, 0, 0
            particle.lifetime = 0
        end
    )
    
    GameState.reset()
    
    local valid, errors = GameState.validateState()
    if not valid then
        Utils.Logger.error("Game state initialization failed")
        return false
    end
    
    Utils.Logger.info("Game state initialized successfully")
    return true
end

function GameState.reset()
    Utils.Logger.info("Resetting game state")
    
    GameState.current = GameState.STATES.PLAYING
    GameState.data.score = 0
    GameState.data.combo = 0
    GameState.data.comboTimer = 0
    GameState.data.gameTime = 0
    GameState.data.isMouseDown = false
    GameState.data.pullPower = 0
    GameState.data.isCharging = false
    
    -- Reset player (only if planets are available)
    if GameState.objects.planets and #GameState.objects.planets > 0 then
        GameState.player.x = GameState.objects.planets[1].x + GameState.objects.planets[1].radius + 20
        GameState.player.y = GameState.objects.planets[1].y
        GameState.player.onPlanet = 1
        
        -- Calculate initial angle
        local planet = GameState.objects.planets[GameState.player.onPlanet]
        GameState.player.angle = Utils.atan2(GameState.player.y - planet.y, GameState.player.x - planet.x)
    else
        -- Default position if planets not set yet
        GameState.player.x = GameState.data.screenWidth / 2
        GameState.player.y = GameState.data.screenHeight / 2
        GameState.player.onPlanet = nil
        GameState.player.angle = 0
    end
    
    GameState.player.vx = 0
    GameState.player.vy = 0
    GameState.player.isDashing = false
    GameState.player.dashTimer = 0
    GameState.player.dashCooldown = 0
    GameState.player.trail = {}
    GameState.player.speedBoost = 1.0
    
    -- Clear objects
    GameState.objects.rings = {}
    GameState.objects.particles = {}
end

function GameState.update(dt)
    GameState.data.gameTime = GameState.data.gameTime + dt
    
    -- Update combo timer
    if GameState.data.comboTimer > 0 then
        GameState.data.comboTimer = GameState.data.comboTimer - dt
        if GameState.data.comboTimer <= 0 then
            GameState.data.combo = 0
            GameState.player.speedBoost = 1.0
        end
    end
    
    -- Auto-reset if player is stuck in space for too long
    if GameState.player.onPlanet == nil or GameState.player.onPlanet == false then
        -- Check if player velocity is very low (essentially stuck)
        local speed = math.sqrt(GameState.player.vx^2 + GameState.player.vy^2)
        if speed < 50 then
            GameState.player.stuckTimer = (GameState.player.stuckTimer or 0) + dt
            if GameState.player.stuckTimer > 3 then -- Reset after 3 seconds of being stuck
                GameState.resetPlayerToNearestPlanet()
                GameState.player.stuckTimer = 0
                
                -- Show hint in tutorial
                -- TutorialSystem is already loaded at the top
                if TutorialSystem.isActive then
                    Utils.Logger.info("Player was stuck and auto-reset. Press R to manually reset when stuck.")
                end
            end
        else
            GameState.player.stuckTimer = 0
        end
    else
        GameState.player.stuckTimer = 0
    end
    
    -- Generate new planets as player explores
    -- WorldGenerator is already loaded at the top
    if GameState.player and not GameState.player.onPlanet then
        local newPlanets = WorldGenerator.generateAroundPosition(
            GameState.player.x, GameState.player.y,
            GameState.objects.planets,
            2000  -- Generation radius
        )
        -- Add new planets to our list
        for _, planet in ipairs(newPlanets) do
            table.insert(GameState.objects.planets, planet)
        end
    end
    
    -- Update player using PlayerSystem
    -- PlayerSystem is already loaded at the top
    PlayerSystem.update(GameState.player, GameState.objects.planets, dt)
    
    -- Update particles
    -- ParticleSystem is already loaded at the top
    ParticleSystem.update(dt)
    GameState.objects.particles = ParticleSystem.getParticles()
    
    -- Update spatial grid for collisions
    -- CollisionSystem is already loaded at the top
    CollisionSystem.updateSpatialGrid(
        GameState.spatialGrid,
        GameState.objects.planets,
        GameState.objects.rings
    )
    
    -- Check collisions
    CollisionSystem.checkPlanetCollisions(
        GameState.player,
        GameState.objects.planets,
        GameState.spatialGrid,
        GameState,
        GameState.soundManager
    )
    
    local collectedRings = CollisionSystem.checkRingCollisions(
        GameState.player,
        GameState.objects.rings,
        GameState.spatialGrid,
        GameState,
        GameState.soundManager
    )
    
    -- Check ring completion
    -- RingSystem is already loaded at the top
    if #collectedRings > 0 then
        local allCollected = true
        for _, ring in ipairs(GameState.objects.rings) do
            if not ring.collected then
                allCollected = false
                break
            end
        end
        
        if allCollected then
            -- Generate new rings
            GameState.objects.rings = RingSystem.generateRings(GameState.objects.planets)
        end
    end
end

function GameState.setState(newState)
    GameState.current = newState
end

function GameState.isState(state)
    return GameState.current == state
end

function GameState.isPlaying()
    return GameState.isState(GameState.STATES.PLAYING)
end

function GameState.isGameOver()
    return GameState.isState(GameState.STATES.GAME_OVER)
end

function GameState.isPaused()
    return GameState.isState(GameState.STATES.PAUSED)
end

function GameState.isMenu()
    return GameState.isState(GameState.STATES.MENU)
end

function GameState.addScore(points)
    GameState.data.score = GameState.data.score + points
end

function GameState.addCombo()
    GameState.data.combo = GameState.data.combo + 1
    GameState.data.comboTimer = GameState.config.comboTimeout
end

function GameState.setCombo(newCombo)
    GameState.data.combo = newCombo
    GameState.data.comboTimer = GameState.config.comboTimeout
end

function GameState.getCombo()
    return GameState.data.combo
end

function GameState.getScore()
    return GameState.data.score
end

function GameState.getGameTime()
    return GameState.data.gameTime
end

function GameState.setPlayerPosition(x, y)
    GameState.player.x = x
    GameState.player.y = y
end

function GameState.getPlayerPosition()
    return GameState.player.x, GameState.player.y
end

function GameState.setPlayerVelocity(vx, vy)
    GameState.player.vx = vx
    GameState.player.vy = vy
end

function GameState.getPlayerVelocity()
    return GameState.player.vx, GameState.player.vy
end

function GameState.setPlayerOnPlanet(planetIndex)
    GameState.player.onPlanet = planetIndex
end

function GameState.getPlayerOnPlanet()
    return GameState.player.onPlanet
end

function GameState.setPlayerAngle(angle)
    GameState.player.angle = angle
end

function GameState.getPlayerAngle()
    return GameState.player.angle
end

function GameState.setSpeedBoost(boost)
    GameState.player.speedBoost = boost
end

function GameState.getSpeedBoost()
    return GameState.player.speedBoost
end

function GameState.setMouseDown(down, x, y)
    GameState.data.isMouseDown = down
    if down then
        GameState.data.mouseStartX = x
        GameState.data.mouseStartY = y
    end
end

function GameState.isMouseDown()
    return GameState.data.isMouseDown
end

function GameState.setPullPower(power)
    GameState.data.pullPower = power
end

function GameState.getPullPower()
    return GameState.data.pullPower
end

function GameState.getMaxPullDistance()
    return GameState.data.maxPullDistance
end

function GameState.setPlanets(planets)
    GameState.objects.planets = planets
    -- Initialize player position if this is the first time planets are set
    if planets and #planets > 0 and GameState.player.onPlanet == nil then
        GameState.initializePlayerPosition()
    end
end

function GameState.getPlanets()
    return GameState.objects.planets
end

function GameState.setRings(rings)
    GameState.objects.rings = rings
end

function GameState.getRings()
    return GameState.objects.rings
end

function GameState.addParticle(particle)
    table.insert(GameState.objects.particles, particle)
end

function GameState.getParticles()
    return GameState.objects.particles
end

function GameState.removeParticle(index)
    table.remove(GameState.objects.particles, index)
end

function GameState.setUIScreen(screen)
    GameState.ui.currentScreen = screen
end

function GameState.getUIScreen()
    return GameState.ui.currentScreen
end

function GameState.isUIScreen(screen)
    return GameState.ui.currentScreen == screen
end

function GameState.setConfig(key, value)
    GameState.config[key] = value
end

function GameState.getConfig(key)
    return GameState.config[key]
end

-- Utility functions for common state checks
function GameState.canJump()
    return GameState.isPlaying() and GameState.player.onPlanet ~= nil
end

function GameState.canDash()
    return GameState.isPlaying() and 
           GameState.player.onPlanet == nil and 
           GameState.player.dashCooldown <= 0 and 
           not GameState.player.isDashing
end

function GameState.isPlayerInSpace()
    return GameState.player.onPlanet == nil
end

function GameState.isPlayerOnPlanet()
    return GameState.player.onPlanet ~= nil
end

function GameState.initializePlayerPosition()
    if GameState.objects.planets and #GameState.objects.planets > 0 then
        local planet = GameState.objects.planets[1]
        GameState.player.x = planet.x + planet.radius + 20
        GameState.player.y = planet.y
        GameState.player.onPlanet = 1
        GameState.player.angle = Utils.atan2(GameState.player.y - planet.y, GameState.player.x - planet.x)
    end
end

-- Reset player to nearest planet when stuck in space
function GameState.resetPlayerToNearestPlanet()
    if not GameState.objects.planets or #GameState.objects.planets == 0 then
        return
    end
    
    -- Find nearest planet
    local nearestPlanet = nil
    local nearestDist = math.huge
    local nearestIndex = 1
    
    for i, planet in ipairs(GameState.objects.planets) do
        local dist = Utils.distance(GameState.player.x, GameState.player.y, planet.x, planet.y)
        if dist < nearestDist then
            nearestDist = dist
            nearestPlanet = planet
            nearestIndex = i
        end
    end
    
    if nearestPlanet then
        -- Calculate angle to planet
        local angle = Utils.atan2(GameState.player.y - nearestPlanet.y, GameState.player.x - nearestPlanet.x)
        
        -- Place player on planet surface
        local orbitRadius = nearestPlanet.radius + GameState.player.radius + 5
        GameState.player.x = nearestPlanet.x + math.cos(angle) * orbitRadius
        GameState.player.y = nearestPlanet.y + math.sin(angle) * orbitRadius
        GameState.player.angle = angle
        GameState.player.onPlanet = nearestIndex
        GameState.player.vx = 0
        GameState.player.vy = 0
        GameState.player.isDashing = false
        GameState.player.dashTimer = 0
        GameState.player.dashCooldown = 0
        
        Utils.Logger.info("Reset player to nearest planet")
    end
end

-- Challenge state management
GameState.challengeBackup = nil

-- Clear game objects for challenge
function GameState.clearForChallenge()
    -- Backup current state
    GameState.challengeBackup = {
        planets = Utils.deepCopy(GameState.objects.planets),
        rings = Utils.deepCopy(GameState.objects.rings),
        score = GameState.data.score,
        combo = GameState.data.combo
    }
    
    -- Clear current objects
    GameState.objects.planets = {}
    GameState.objects.rings = {}
    GameState.objects.particles = {}
end

-- Restore from challenge
function GameState.restoreFromChallenge()
    if GameState.challengeBackup then
        GameState.objects.planets = GameState.challengeBackup.planets
        GameState.objects.rings = GameState.challengeBackup.rings
        -- Keep score and combo earned during challenge
        GameState.challengeBackup = nil
    end
end

-- Input handling
function GameState.handleKeyPress(key)
    if not GameState.isPlaying() then
        return
    end
    
    -- Handle debug keys
    if key == "f1" then
        if GameState.camera then
            GameState.camera.scale = 1.0
        end
    elseif key == "f2" then
        -- Debug: Add rings
        -- RingSystem is already loaded at the top
        GameState.objects.rings = RingSystem.generateRings(GameState.objects.planets)
    elseif key == "r" then
        -- Reset player position if stuck in space
        if GameState.player.onPlanet == nil or GameState.player.onPlanet == false then
            GameState.resetPlayerToNearestPlanet()
        end
    end
end

function GameState.handleMousePress(x, y, button)
    if not GameState.isPlaying() then
        return
    end
    
    if button == 1 and GameState.player.onPlanet then
        -- Start jump charge
        GameState.data.mouseStartX = x
        GameState.data.mouseStartY = y
        GameState.data.isCharging = true
    end
end

function GameState.handleMouseMove(x, y)
    if not GameState.isPlaying() then
        return
    end
    
    -- Update pull power during charging
    if GameState.data.isCharging and GameState.player.onPlanet and GameState.data.mouseStartX then
        local dx = GameState.data.mouseStartX - x
        local dy = GameState.data.mouseStartY - y
        local pullPower = math.min(Utils.distance(0, 0, dx, dy), GameState.data.maxPullDistance)
        GameState.setPullPower(pullPower)
    end
end

function GameState.handleMouseRelease(x, y, button)
    if not GameState.isPlaying() then
        return
    end
    
    if button == 1 then
        if GameState.data.isCharging and GameState.player.onPlanet then
            -- Calculate jump
            local dx = GameState.data.mouseStartX - x
            local dy = GameState.data.mouseStartY - y
            local pullPower = math.min(Utils.distance(0, 0, dx, dy), GameState.data.maxPullDistance)
            local pullAngle = Utils.atan2(dy, dx)
            
            -- Execute jump
            -- PlayerSystem is already loaded at the top
            PlayerSystem.jump(
                GameState.player,
                pullPower,
                pullAngle,
                GameState,
                GameState.soundManager
            )
            
            -- Notify tutorial system of jump action
            -- TutorialSystem is already loaded at the top
            TutorialSystem.onPlayerAction("jump")
        elseif not GameState.player.onPlanet then
            -- Try dash
            -- PlayerSystem is already loaded at the top
            PlayerSystem.dash(
                GameState.player,
                x, y,
                GameState.soundManager
            )
            
            -- Notify tutorial system of dash action
            -- TutorialSystem is already loaded at the top
            TutorialSystem.onPlayerAction("dash")
        end
        
        GameState.data.isCharging = false
        GameState.data.mouseStartX = nil
        GameState.data.mouseStartY = nil
        GameState.data.pullPower = 0
    end
end

return GameState 