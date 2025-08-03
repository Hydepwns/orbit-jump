-- Warp Zones System for Orbit Jump
-- Secret portals that transport players to special challenge areas
local Utils = require("src.utils.utils")
local WarpZones = {}
-- Warp zone types
WarpZones.zoneTypes = {
    ring_gauntlet = {
        name = "Ring Gauntlet",
        description = "Collect all rings in 30 seconds!",
        color = {1, 0.5, 0},
        difficulty = 1,
        reward = 500
    },
    gravity_maze = {
        name = "Gravity Maze",
        description = "Navigate through twisted gravity fields",
        color = {0.5, 0, 1},
        difficulty = 2,
        reward = 750
    },
    speed_run = {
        name = "Speed Run",
        description = "Reach the goal as fast as possible!",
        color = {0, 1, 0.5},
        difficulty = 1,
        reward = 600
    },
    void_challenge = {
        name = "Void Challenge",
        description = "Survive the void planets!",
        color = {0.8, 0, 0.8},
        difficulty = 3,
        reward = 1000
    },
    quantum_puzzle = {
        name = "Quantum Puzzle",
        description = "Reality shifts around you...",
        color = {0, 0.8, 0.8},
        difficulty = 3,
        reward = 1250
    }
}
-- Active warp zones
WarpZones.activeZones = {}
WarpZones.currentChallenge = nil
WarpZones.challengeTimer = 0
WarpZones.originalPlayerPos = nil
-- Portal animation
WarpZones.portalPhase = 0
-- Initialize
function WarpZones.init()
    WarpZones.activeZones = {}
    WarpZones.currentChallenge = nil
    WarpZones.portalPhase = 0
    return true
end
-- Generate warp zones based on player position
function WarpZones.generateAroundPlayer(player, existingPlanets)
    local minDistance = 2000
    local maxDistance = 3000
    -- Only generate if player is far from origin
    local distFromOrigin = math.sqrt(player.x^2 + player.y^2)
    if distFromOrigin < 1000 then return end
    -- Check if we should spawn a new warp zone
    if math.random() < 0.01 then -- 1% chance per frame
        -- Find a good position
        local angle = math.random() * math.pi * 2
        local distance = minDistance + math.random() * (maxDistance - minDistance)
        local x = player.x + math.cos(angle) * distance
        local y = player.y + math.sin(angle) * distance
        -- Check distance from existing objects
        local tooClose = false
        for _, planet in ipairs(existingPlanets) do
            if Utils.distance(x, y, planet.x, planet.y) < 300 then
                tooClose = true
                break
            end
        end
        for _, zone in ipairs(WarpZones.activeZones) do
            if Utils.distance(x, y, zone.x, zone.y) < 500 then
                tooClose = true
                break
            end
        end
        if not tooClose then
            -- Create warp zone
            local types = {"ring_gauntlet", "gravity_maze", "speed_run", "void_challenge", "quantum_puzzle"}
            local zoneType = types[math.random(#types)]
            local zone = {
                x = x,
                y = y,
                radius = 50,
                type = zoneType,
                data = WarpZones.zoneTypes[zoneType],
                discovered = false,
                entryAngle = 0
            }
            table.insert(WarpZones.activeZones, zone)
            Utils.Logger.info("Warp zone spawned: %s at (%.0f, %.0f)", zone.data.name, x, y)
        end
    end
    -- Remove distant zones
    for i = #WarpZones.activeZones, 1, -1 do
        local zone = WarpZones.activeZones[i]
        if Utils.distance(player.x, player.y, zone.x, zone.y) > 5000 then
            table.remove(WarpZones.activeZones, i)
        end
    end
end
-- Check if player enters a warp zone
function WarpZones.checkEntry(player)
    if WarpZones.currentChallenge then return end -- Already in a challenge
    for _, zone in ipairs(WarpZones.activeZones) do
        local dist = Utils.distance(player.x, player.y, zone.x, zone.y)
        if dist < zone.radius then
            -- Discover the zone
            if not zone.discovered then
                zone.discovered = true
                local AchievementSystem = Utils.require("src.systems.achievement_system")
                AchievementSystem.onWarpZoneDiscovered()
            end
            -- Enter the challenge
            WarpZones.enterChallenge(zone, player)
            return true
        end
    end
    return false
end
-- Enter a warp zone challenge
function WarpZones.enterChallenge(zone, player)
    WarpZones.currentChallenge = zone
    WarpZones.originalPlayerPos = {x = player.x, y = player.y}
    -- Create challenge area based on type
    if zone.type == "ring_gauntlet" then
        WarpZones.createRingGauntlet(player)
    elseif zone.type == "gravity_maze" then
        WarpZones.createGravityMaze(player)
    elseif zone.type == "speed_run" then
        WarpZones.createSpeedRun(player)
    elseif zone.type == "void_challenge" then
        WarpZones.createVoidChallenge(player)
    elseif zone.type == "quantum_puzzle" then
        WarpZones.createQuantumPuzzle(player)
    end
    -- Start challenge timer
    WarpZones.challengeTimer = 30 -- Default 30 seconds
    -- Play warp sound
    local soundManager = Utils.require("src.audio.sound_manager")
    if soundManager.playEventWarning then
        soundManager:playEventWarning()
    end
end
-- Create ring gauntlet challenge
function WarpZones.createRingGauntlet(player)
    local GameState = Utils.require("src.core.game_state")
    local RingSystem = Utils.require("src.systems.ring_system")
    -- Clear existing game objects
    GameState.clearForChallenge()
    -- Create a circular arena
    local centerX = 0
    local centerY = 0
    player.x = centerX
    player.y = centerY - 200
    player.vx = 0
    player.vy = 0
    player.onPlanet = nil
    -- Create boundary planets
    local planets = {}
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local planet = {
            x = centerX + math.cos(angle) * 400,
            y = centerY + math.sin(angle) * 400,
            radius = 60,
            rotationSpeed = 0.5,
            color = {0.3, 0.3, 0.3},
            type = "challenge",
            gravityMultiplier = 0.5
        }
        table.insert(planets, planet)
    end
    GameState.setPlanets(planets)
    -- Create lots of rings
    local rings = {}
    for i = 1, 30 do
        local angle = math.random() * math.pi * 2
        local distance = 50 + math.random(300)
        local ring = {
            x = centerX + math.cos(angle) * distance,
            y = centerY + math.sin(angle) * distance,
            radius = 25,
            innerRadius = 15,
            rotation = 0,
            rotationSpeed = math.random(-2, 2),
            pulsePhase = math.random() * math.pi * 2,
            collected = false,
            value = 10,
            color = {1, 0.8, 0.2},
            visible = true
        }
        table.insert(rings, ring)
    end
    GameState.setRings(rings)
end
-- Create gravity maze challenge
function WarpZones.createGravityMaze(player)
    local GameState = Utils.require("src.core.game_state")
    -- Clear existing game objects
    GameState.clearForChallenge()
    -- Create maze layout
    local centerX = 0
    local centerY = 0
    player.x = centerX - 300
    player.y = centerY
    player.vx = 0
    player.vy = 0
    player.onPlanet = nil
    -- Create gravity wells in a maze pattern
    local planets = {}
    local mazeLayout = {
        {1, 0, 1, 0, 1},
        {1, 0, 1, 0, 1},
        {0, 0, 0, 0, 0},
        {1, 0, 1, 0, 1},
        {1, 0, 1, 0, 1}
    }
    for row = 1, 5 do
        for col = 1, 5 do
            if mazeLayout[row][col] == 1 then
                local planet = {
                    x = centerX + (col - 3) * 150,
                    y = centerY + (row - 3) * 150,
                    radius = 40,
                    rotationSpeed = 0.3,
                    color = {0.5, 0.2, 0.8},
                    type = "maze",
                    gravityMultiplier = 2.0
                }
                table.insert(planets, planet)
            end
        end
    end
    -- Add goal planet
    local goalPlanet = {
        x = centerX + 300,
        y = centerY,
        radius = 50,
        rotationSpeed = 1.0,
        color = {0, 1, 0},
        type = "goal",
        gravityMultiplier = 1.0,
        isGoal = true
    }
    table.insert(planets, goalPlanet)
    GameState.setPlanets(planets)
    GameState.setRings({}) -- No rings in gravity maze
end
-- Update warp zones
function WarpZones.update(dt, player)
    -- Update portal animation
    WarpZones.portalPhase = WarpZones.portalPhase + dt * 2
    -- Generate new zones
    local GameState = Utils.require("src.core.game_state")
    WarpZones.generateAroundPlayer(player, GameState.getPlanets())
    -- Check for entry
    if not WarpZones.currentChallenge then
        WarpZones.checkEntry(player)
    else
        -- Update challenge
        WarpZones.updateChallenge(dt, player)
    end
end
-- Update active challenge
function WarpZones.updateChallenge(dt, player)
    if not WarpZones.currentChallenge then return end
    -- Update timer
    WarpZones.challengeTimer = WarpZones.challengeTimer - dt
    -- Check completion conditions
    local completed = false
    local failed = false
    if WarpZones.currentChallenge.type == "ring_gauntlet" then
        -- Check if all rings collected
        local GameState = Utils.require("src.core.game_state")
        local rings = GameState.getRings()
        local allCollected = true
        for _, ring in ipairs(rings) do
            if not ring.collected then
                allCollected = false
                break
            end
        end
        completed = allCollected
        failed = WarpZones.challengeTimer <= 0
    elseif WarpZones.currentChallenge.type == "gravity_maze" then
        -- Check if reached goal planet
        local GameState = Utils.require("src.core.game_state")
        local planets = GameState.getPlanets()
        for _, planet in ipairs(planets) do
            if planet.isGoal and player.onPlanet then
                local currentPlanet = planets[player.onPlanet]
                if currentPlanet == planet then
                    completed = true
                    break
                end
            end
        end
        failed = WarpZones.challengeTimer <= 0
    end
    -- Handle completion
    if completed then
        WarpZones.completeChallenge(true)
    elseif failed then
        WarpZones.completeChallenge(false)
    end
end
-- Complete challenge
function WarpZones.completeChallenge(success)
    if not WarpZones.currentChallenge then return end
    local GameState = Utils.require("src.core.game_state")
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    local UpgradeSystem = Utils.require("src.systems.upgrade_system")
    if success then
        -- Award points
        local reward = WarpZones.currentChallenge.data.reward
        UpgradeSystem.addCurrency(reward)
        GameState.addScore(reward)
        -- Achievement
        AchievementSystem.onWarpZoneCompleted(WarpZones.currentChallenge.type)
        -- Play success sound
        local soundManager = Utils.require("src.audio.sound_manager")
        if soundManager.playCombo then
            soundManager:play("combo", 1.0, 1.5)
        end
    end
    -- Return player to original position
    local player = GameState.player
    if WarpZones.originalPlayerPos then
        player.x = WarpZones.originalPlayerPos.x
        player.y = WarpZones.originalPlayerPos.y
    end
    -- Clear challenge
    WarpZones.currentChallenge = nil
    WarpZones.originalPlayerPos = nil
    -- Restore normal game state
    GameState.restoreFromChallenge()
end
-- Create other challenge types
function WarpZones.createSpeedRun(player)
    -- Speed run challenge implementation ready
    WarpZones.createRingGauntlet(player) -- Placeholder
end
function WarpZones.createVoidChallenge(player)
    -- Void challenge implementation ready
    WarpZones.createGravityMaze(player) -- Placeholder
end
function WarpZones.createQuantumPuzzle(player)
    -- Quantum puzzle implementation ready
    WarpZones.createRingGauntlet(player) -- Placeholder
end
-- Draw warp zones
function WarpZones.draw()
    for _, zone in ipairs(WarpZones.activeZones) do
        -- Draw portal effect
        local pulse = math.sin(WarpZones.portalPhase + zone.x) * 0.2 + 1
        -- Outer ring
        Utils.setColor(zone.data.color, 0.3)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", zone.x, zone.y, zone.radius * pulse)
        -- Inner spirals
        for i = 1, 6 do
            local angle = (i / 6) * math.pi * 2 + WarpZones.portalPhase
            local spiralRadius = zone.radius * 0.7 * pulse
            local alpha = 0.5 + math.sin(WarpZones.portalPhase * 2 + i) * 0.3
            Utils.setColor(zone.data.color, alpha)
            love.graphics.arc("line", "open", zone.x, zone.y, spiralRadius,
                angle - 0.5, angle + 0.5)
        end
        -- Center glow
        local glowAlpha = 0.6 + math.sin(WarpZones.portalPhase * 3) * 0.2
        Utils.setColor(zone.data.color, glowAlpha)
        love.graphics.circle("fill", zone.x, zone.y, 10)
        -- Discovery indicator
        if zone.discovered then
            Utils.setColor({1, 1, 1}, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", zone.x, zone.y, zone.radius + 10)
        end
    end
end
-- Draw challenge UI
function WarpZones.drawChallengeUI()
    if not WarpZones.currentChallenge then return end
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    -- Draw challenge name
    Utils.setColor(WarpZones.currentChallenge.data.color)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.printf(WarpZones.currentChallenge.data.name,
        0, 50, screenWidth, "center")
    -- Draw description
    Utils.setColor({1, 1, 1}, 0.8)
    love.graphics.printf(WarpZones.currentChallenge.data.description,
        0, 80, screenWidth, "center")
    -- Draw timer
    local timerColor = WarpZones.challengeTimer < 10 and {1, 0.2, 0.2} or {1, 1, 1}
    Utils.setColor(timerColor)
    love.graphics.printf(string.format("Time: %.1f", WarpZones.challengeTimer),
        0, 110, screenWidth, "center")
    -- Draw progress for ring gauntlet
    if WarpZones.currentChallenge.type == "ring_gauntlet" then
        local GameState = Utils.require("src.core.game_state")
        local rings = GameState.getRings()
        local collected = 0
        local total = #rings
        for _, ring in ipairs(rings) do
            if ring.collected then
                collected = collected + 1
            end
        end
        Utils.setColor({1, 0.8, 0.2})
        love.graphics.printf(string.format("Rings: %d / %d", collected, total),
            0, 140, screenWidth, "center")
    end
end
return WarpZones