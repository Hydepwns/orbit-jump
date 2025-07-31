--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player State: State management, analytics integration, and persistence
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles player state management, landing analytics, and 
    integration with save systems and player analytics.
--]]

local Utils = require("src.utils.utils")

local PlayerState = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    State Management and Analytics
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerState.init()
    Utils.Logger.info("📊 Player State initialized")
    return true
end

function PlayerState.onPlanetLanding(player, planet, gameState)
    --[[
        React to player landing on planet (analytics opportunity)
        
        Learn from successful landings and feed data to analytics systems
        for understanding player skill progression and preferences.
    --]]
    
    -- Learn from successful landings
    if gameState and gameState.lastJumpContext then
        local jumpContext = gameState.lastJumpContext
        local actualX, actualY = player.x, player.y
        
        -- Analyze landing accuracy vs prediction
        local PlayerMovement = Utils.require("src.systems.player.player_movement")
        local predictedX, predictedY = PlayerMovement.predictLandingPosition(
            {x = jumpContext.startX, y = jumpContext.startY}, 
            player.vx, player.vy
        )
        
        local landingAccuracy = 1.0 - (Utils.distance(actualX, actualY, predictedX, predictedY) / 500)
        landingAccuracy = Utils.clamp(landingAccuracy, 0, 1)
        
        -- Update analytics with landing success
        local PlayerAnalytics = Utils.require("src.systems.player_analytics")
        PlayerAnalytics.onEmotionalEvent("success", landingAccuracy, {
            jumpContext = jumpContext,
            landingAccuracy = landingAccuracy,
            planet = planet
        })
        
        -- Trigger emotional feedback based on landing quality
        local EmotionalFeedback = Utils.require("src.systems.emotional_feedback")
        local landingSpeed = Utils.distance(0, 0, player.vx or 0, player.vy or 0)
        EmotionalFeedback.processEvent("landing", {
            player = player,
            planet = planet,
            speed = landingSpeed
        })
        
        Utils.Logger.debug("🎯 Landing analyzed: accuracy %.1f%%", landingAccuracy * 100)
    end
    
    -- Update game state
    if gameState then
        gameState.landings = (gameState.landings or 0) + 1
        gameState.lastLandingTime = love.timer.getTime()
        gameState.lastPlanet = planet
    end
end

function PlayerState.updateSessionStats(player, gameState, dt)
    --[[Update session statistics and player state--]]
    
    if not gameState then
        return
    end
    
    -- Update session time
    gameState.sessionTime = (gameState.sessionTime or 0) + dt
    
    -- Track current speed for statistics
    local currentSpeed = Utils.distance(0, 0, player.vx or 0, player.vy or 0)
    if not gameState.maxSpeed or currentSpeed > gameState.maxSpeed then
        gameState.maxSpeed = currentSpeed
    end
    
    -- Track distance traveled
    if gameState.lastX and gameState.lastY then
        local distance = Utils.distance(gameState.lastX, gameState.lastY, player.x, player.y)
        gameState.totalDistance = (gameState.totalDistance or 0) + distance
    end
    gameState.lastX = player.x
    gameState.lastY = player.y
    
    -- Update player state history for analytics
    local currentTime = love.timer.getTime()
    if not gameState.lastAnalyticsUpdate or currentTime - gameState.lastAnalyticsUpdate > 1.0 then
        PlayerState.recordPlayerState(player, gameState)
        gameState.lastAnalyticsUpdate = currentTime
    end
end

function PlayerState.recordPlayerState(player, gameState)
    --[[Record current player state for analytics--]]
    
    local PlayerAnalytics = Utils.require("src.systems.player_analytics")
    if not PlayerAnalytics then
        return
    end
    
    local state = {
        position = {x = player.x, y = player.y},
        velocity = {x = player.vx or 0, y = player.vy or 0},
        onPlanet = player.onPlanet,
        isDashing = player.isDashing,
        dashCooldown = player.dashCooldown or 0,
        sessionTime = gameState.sessionTime or 0,
        jumps = gameState.jumps or 0,
        landings = gameState.landings or 0
    }
    
    PlayerAnalytics.trackGameplay(state)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Save System Integration
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerState.savePlayerState(player, gameState)
    --[[Prepare player state data for saving--]]
    
    local saveData = {
        -- Core position and physics
        x = player.x,
        y = player.y,
        vx = player.vx or 0,
        vy = player.vy or 0,
        angle = player.angle or 0,
        onPlanet = player.onPlanet,
        
        -- Ability states
        dashCooldown = player.dashCooldown or 0,
        isDashing = player.isDashing or false,
        dashTimer = player.dashTimer or 0,
        
        -- Power-ups
        powerUps = player.powerUps or {},
        
        -- Session statistics
        gameState = gameState and {
            jumps = gameState.jumps or 0,
            landings = gameState.landings or 0,
            sessionTime = gameState.sessionTime or 0,
            totalDistance = gameState.totalDistance or 0,
            maxSpeed = gameState.maxSpeed or 0
        } or nil,
        
        -- Adaptive physics state
        adaptivePhysics = nil  -- Will be filled by PlayerMovement module
    }
    
    -- Get adaptive physics state
    local PlayerMovement = Utils.require("src.systems.player.player_movement")
    saveData.adaptivePhysics = PlayerMovement.getAdaptivePhysicsStatus()
    
    return saveData
end

function PlayerState.loadPlayerState(player, gameState, saveData)
    --[[Restore player state from save data--]]
    
    if not saveData then
        return false
    end
    
    -- Restore core position and physics
    player.x = saveData.x or 0
    player.y = saveData.y or 0
    player.vx = saveData.vx or 0
    player.vy = saveData.vy or 0
    player.angle = saveData.angle or 0
    player.onPlanet = saveData.onPlanet
    
    -- Restore ability states
    player.dashCooldown = saveData.dashCooldown or 0
    player.isDashing = saveData.isDashing or false
    player.dashTimer = saveData.dashTimer or 0
    
    -- Restore power-ups
    player.powerUps = saveData.powerUps or {}
    
    -- Restore session statistics
    if saveData.gameState and gameState then
        gameState.jumps = saveData.gameState.jumps or 0
        gameState.landings = saveData.gameState.landings or 0
        gameState.sessionTime = saveData.gameState.sessionTime or 0
        gameState.totalDistance = saveData.gameState.totalDistance or 0
        gameState.maxSpeed = saveData.gameState.maxSpeed or 0
    end
    
    -- Restore adaptive physics state
    if saveData.adaptivePhysics then
        local PlayerMovement = Utils.require("src.systems.player.player_movement")
        PlayerMovement.restoreAdaptivePhysics(saveData.adaptivePhysics)
    end
    
    Utils.Logger.info("💾 Player state loaded successfully")
    return true
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Player Profile and Preferences
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerState.getPlayerProfile(gameState)
    --[[Get current player profile for analytics and adaptive systems--]]
    
    if not gameState then
        return nil
    end
    
    local profile = {
        -- Performance metrics
        totalJumps = gameState.jumps or 0,
        totalLandings = gameState.landings or 0,
        sessionTime = gameState.sessionTime or 0,
        maxSpeed = gameState.maxSpeed or 0,
        totalDistance = gameState.totalDistance or 0,
        
        -- Calculated metrics
        jumpSuccessRate = 0,
        averageSpeed = 0,
        sessionLength = gameState.sessionTime or 0
    }
    
    -- Calculate success rate
    if profile.totalJumps > 0 then
        profile.jumpSuccessRate = profile.totalLandings / profile.totalJumps
    end
    
    -- Calculate average speed
    if profile.sessionTime > 0 then
        profile.averageSpeed = (profile.totalDistance or 0) / profile.sessionTime
    end
    
    return profile
end

function PlayerState.updatePlayerPreferences(player, preferences)
    --[[Update player preferences that affect gameplay--]]
    
    if not player.preferences then
        player.preferences = {}
    end
    
    -- Merge new preferences
    for key, value in pairs(preferences) do
        player.preferences[key] = value
    end
    
    Utils.Logger.info("⚙️ Player preferences updated: %d settings", Utils.tableSize(preferences))
end

function PlayerState.getPlayerPreferences(player)
    --[[Get current player preferences--]]
    
    return player.preferences or {}
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Health and Energy Management
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerState.initializeHealthEnergy(player)
    --[[Initialize health and energy systems--]]
    
    player.health = player.health or {
        current = 100,
        maximum = 100,
        regenerationRate = 5  -- HP per second
    }
    
    player.energy = player.energy or {
        current = 100,
        maximum = 100,
        regenerationRate = 10,  -- Energy per second
        jumpCost = 10,
        dashCost = 20
    }
end

function PlayerState.updateHealthEnergy(player, dt)
    --[[Update health and energy regeneration--]]
    
    if not player.health or not player.energy then
        PlayerState.initializeHealthEnergy(player)
    end
    
    -- Health regeneration (only if not at max)
    if player.health.current < player.health.maximum then
        player.health.current = math.min(
            player.health.maximum,
            player.health.current + player.health.regenerationRate * dt
        )
    end
    
    -- Energy regeneration (only if not at max)
    if player.energy.current < player.energy.maximum then
        player.energy.current = math.min(
            player.energy.maximum,
            player.energy.current + player.energy.regenerationRate * dt
        )
    end
end

function PlayerState.canAffordAbility(player, abilityType)
    --[[Check if player has enough energy for an ability--]]
    
    if not player.energy then
        PlayerState.initializeHealthEnergy(player)
        return true  -- Default to allowing abilities if energy system not initialized
    end
    
    local cost = 0
    if abilityType == "jump" then
        cost = player.energy.jumpCost
    elseif abilityType == "dash" then
        cost = player.energy.dashCost
    end
    
    return player.energy.current >= cost
end

function PlayerState.consumeEnergy(player, abilityType)
    --[[Consume energy for an ability--]]
    
    if not player.energy then
        return false
    end
    
    local cost = 0
    if abilityType == "jump" then
        cost = player.energy.jumpCost
    elseif abilityType == "dash" then
        cost = player.energy.dashCost
    end
    
    if player.energy.current >= cost then
        player.energy.current = player.energy.current - cost
        return true
    end
    
    return false
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Debug and Utility Functions
    ═══════════════════════════════════════════════════════════════════════════
--]]

function PlayerState.getDebugInfo(player, gameState)
    --[[Get comprehensive debug information about player state--]]
    
    local profile = PlayerState.getPlayerProfile(gameState)
    
    return {
        position = {x = player.x, y = player.y},
        velocity = {x = player.vx or 0, y = player.vy or 0},
        onPlanet = player.onPlanet,
        abilities = {
            dashCooldown = player.dashCooldown or 0,
            isDashing = player.isDashing or false,
            dashTimer = player.dashTimer or 0
        },
        powerUps = player.powerUps or {},
        health = player.health,
        energy = player.energy,
        preferences = player.preferences or {},
        profile = profile,
        trail = player.trail and #player.trail or 0
    }
end

function PlayerState.resetPlayerState(player, gameState)
    --[[Reset player to initial state (useful for respawn/restart)--]]
    
    -- Reset position and physics
    player.x = 0
    player.y = 0
    player.vx = 0
    player.vy = 0
    player.angle = 0
    player.onPlanet = false
    
    -- Reset abilities
    local PlayerAbilities = Utils.require("src.systems.player.player_abilities")
    PlayerAbilities.resetAbilities(player)
    
    -- Reset health and energy
    PlayerState.initializeHealthEnergy(player)
    player.health.current = player.health.maximum
    player.energy.current = player.energy.maximum
    
    -- Clear trail
    player.trail = {}
    
    -- Reset some game state but preserve long-term stats
    if gameState then
        gameState.lastJumpContext = nil
        gameState.lastJumpTime = nil
        gameState.lastLandingTime = nil
        gameState.lastPlanet = nil
        -- Preserve: jumps, landings, sessionTime, totalDistance, maxSpeed
    end
    
    Utils.Logger.info("🔄 Player state reset")
end

return PlayerState