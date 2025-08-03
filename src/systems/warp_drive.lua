--[[
    ═══════════════════════════════════════════════════════════════════════════
    Adaptive Warp Drive: The Learning Heart of Interstellar Travel
    ═══════════════════════════════════════════════════════════════════════════
    This is the main interface for the warp drive system. It orchestrates
    the various subsystems (memory, navigation, energy, core) to provide
    a unified warp drive experience.
    The actual implementation is now modularized into:
    - warp_core.lua: Core mechanics and state
    - warp_memory.lua: Adaptive learning and route optimization
    - warp_navigation.lua: Path calculation and targeting
    - warp_energy.lua: Energy management and regeneration
--]]
local Utils = require("src.utils.utils")
local WarpCore = require("src.systems.warp.warp_core")
local WarpMemory = require("src.systems.warp.warp_memory")
local WarpNavigation = require("src.systems.warp.warp_navigation")
local WarpEnergy = require("src.systems.warp.warp_energy")
local WarpDrive = {}
-- Initialize all subsystems
function WarpDrive.init()
    WarpCore.init()
    WarpEnergy.init()
    WarpMemory.init()
    WarpNavigation.reset()
end
-- Unlock warp drive
function WarpDrive.unlock()
    WarpCore.unlock()
end
-- Check if warp drive is unlocked
function WarpDrive.isUnlocked()
    return WarpCore.isUnlocked
end
-- Check if currently warping
function WarpDrive.isWarping()
    return WarpCore.isWarping
end
-- Adaptive Warp Affordability Check
function WarpDrive.canAffordWarp(targetPlanet, currentPlayer, gameContext)
    if not WarpCore.isUnlocked then return false end
    if not targetPlanet.discovered then return false end
    local distance = Utils.distance(currentPlayer.x, currentPlayer.y, targetPlanet.x, targetPlanet.y)
    local cost = WarpDrive.calculateCost(distance, currentPlayer.x, currentPlayer.y, targetPlanet, gameContext)
    return WarpEnergy.hasEnergy(cost)
end
-- Adaptive Cost Calculation: The Heart of Learning Economics
function WarpDrive.calculateCost(distance, sourceX, sourceY, targetPlanet, gameContext)
    -- Foundation: Physics-based cost scaling
    local baseCost = WarpEnergy.calculateBaseCost(distance)
    -- If no adaptive context provided, fall back to static calculation
    if not sourceX or not targetPlanet or not gameContext then
        return baseCost
    end
    -- Learning Factor 1: Route Familiarity Bonus
    local familiarityBonus = WarpMemory.getRouteFamiliarityBonus(sourceX, sourceY, targetPlanet)
    -- Learning Factor 2: Player Mastery Scaling
    local masteryMultiplier = WarpMemory.calculateMasteryMultiplier()
    -- Learning Factor 3: Emergency Compassion
    local emergencyFactor = WarpMemory.detectEmergencyWarp(gameContext)
    local compassionMultiplier = 1.0
    if emergencyFactor > 0.5 then
        -- Reduce cost during emergencies (the warp drive "helps" the player)
        compassionMultiplier = 0.7 - (emergencyFactor * 0.3) -- Up to 60% reduction
        Utils.Logger.info("🆘 Emergency warp detected - applying %.0f%% cost relief",
            (1 - compassionMultiplier) * 100)
    end
    -- Learning Factor 4: Exploration Incentive
    local explorationBonus = WarpMemory.calculateExplorationBonus(targetPlanet)
    -- Learning Factor 5: Planet Affinity
    local affinityBonus = WarpMemory.calculateAffinityBonus(targetPlanet)
    -- Synthesis: Combine all learning factors
    local adaptiveCost = baseCost * familiarityBonus * masteryMultiplier *
                        compassionMultiplier * explorationBonus * affinityBonus
    -- Ensure reasonable bounds (never less than 25% of base cost)
    local finalCost = math.max(math.floor(baseCost * 0.25), math.floor(adaptiveCost))
    -- Log the learning process for transparency
    WarpMemory.logCostCalculation(baseCost, finalCost, {
        familiarity = familiarityBonus,
        mastery = masteryMultiplier,
        emergency = compassionMultiplier,
        exploration = explorationBonus,
        affinity = affinityBonus
    })
    return finalCost
end
-- Adaptive Warp Initiation: Learning in Real-Time
function WarpDrive.startWarp(targetPlanet, player, gameContext)
    -- Enhanced affordability check with game context
    if not WarpDrive.canAffordWarp(targetPlanet, player, gameContext) then
        -- Even failed attempts teach us about player intent
        WarpMemory.learnFromFailedWarp(targetPlanet, player, gameContext)
        return false
    end
    local distance = Utils.distance(player.x, player.y, targetPlanet.x, targetPlanet.y)
    local cost = WarpDrive.calculateCost(distance, player.x, player.y, targetPlanet, gameContext)
    -- Consume energy
    if not WarpEnergy.consumeEnergy(cost) then
        return false
    end
    -- Start warp sequence
    WarpCore.startWarpSequence(targetPlanet)
    -- Create visual effects
    WarpCore.createWarpParticles(player, cost)
    -- Play adaptive sound
    WarpCore.playWarpSound(cost)
    -- Learn from this warp attempt
    WarpMemory.learnFromWarp(player.x, player.y, targetPlanet, cost, gameContext)
    -- Save memory state after learning
    WarpMemory.saveMemoryState()
    return true
end
-- Toggle selection mode
function WarpDrive.toggleSelection()
    return WarpNavigation.toggleSelection(WarpCore.isUnlocked, WarpCore.isWarping)
end
-- Handle planet selection
function WarpDrive.selectPlanetAt(worldX, worldY, planets, player)
    return WarpNavigation.selectPlanetAt(worldX, worldY, planets, player,
        function(planet, p) return WarpDrive.canAffordWarp(planet, p) end,
        function(planet, p) return WarpDrive.startWarp(planet, p) end
    )
end
-- Update warp systems
function WarpDrive.update(dt, player)
    -- Update energy regeneration
    WarpEnergy.update(dt)
    -- Update warp animation and check for completion
    local warpComplete = WarpCore.update(dt, player)
    if warpComplete then
        WarpCore.completeWarp(player)
    end
end
-- Draw warp effects
function WarpDrive.draw(player)
    WarpCore.drawEffects(player)
end
-- Complete warp (for testing and direct control)
function WarpDrive.completeWarp(player)
    if WarpCore.completeWarp then
        WarpCore.completeWarp(player)
    end
end
-- Create warp particles (for testing)
function WarpDrive.createWarpParticles(player, count)
    if WarpCore.createWarpParticles then
        WarpCore.createWarpParticles(player, count)
    end
end
-- Draw UI elements
function WarpDrive.drawUI(player, planets, camera)
    if not WarpCore.isUnlocked then return end
    -- Draw energy bar
    WarpEnergy.drawEnergyBar()
    -- Draw selection UI
    WarpNavigation.drawSelectionUI(planets, player, camera, WarpEnergy.energy,
        function(distance, x, y, planet)
            return WarpDrive.calculateCost(distance, x, y, planet)
        end
    )
    -- Draw warp progress
    WarpCore.drawProgressUI()
end
-- Get enhanced upgrade status for UI (includes learning info)
function WarpDrive.getStatus()
    local memoryStats = WarpMemory.getMemoryStats()
    local coreStatus = WarpCore.getStatus()
    local energyStatus = WarpEnergy.getStatus()
    local navStatus = WarpNavigation.getStatus()
    return {
        -- Core status
        unlocked = coreStatus.isUnlocked,
        isWarping = coreStatus.isWarping,
        -- Energy status
        energy = energyStatus.current,
        maxEnergy = energyStatus.max,
        canWarp = energyStatus.current >= 50,
        -- Memory and learning stats
        totalWarps = memoryStats.totalWarps,
        knownRoutes = memoryStats.knownRoutes,
        efficiency = memoryStats.efficiency,
        skillLevel = memoryStats.skillLevel,
        adaptationLevel = memoryStats.adaptationLevel,
        -- Navigation status
        isSelecting = navStatus.isSelecting,
        selectedPlanet = navStatus.selectedPlanet
    }
end
-- Save state
function WarpDrive.saveState()
    WarpMemory.saveMemoryState()
    return {
        energy = WarpEnergy.saveState(),
        unlocked = WarpCore.isUnlocked
    }
end
-- Restore state
function WarpDrive.restoreState(state)
    if state then
        if state.energy then
            WarpEnergy.restoreState(state.energy)
        end
        if state.unlocked then
            WarpCore.isUnlocked = state.unlocked
        end
    end
end
-- Backwards compatibility exports
WarpDrive.isUnlocked = false -- Will be updated by getters
WarpDrive.energy = 0 -- Will be updated by getters
WarpDrive.maxEnergy = 1000
-- Update backwards compatibility properties
local function updateCompatibilityProps()
    WarpDrive.isUnlocked = WarpCore.isUnlocked
    WarpDrive.energy = WarpEnergy.energy
    WarpDrive.maxEnergy = WarpEnergy.maxEnergy
end
-- Override property access for backwards compatibility
setmetatable(WarpDrive, {
    __index = function(t, k)
        updateCompatibilityProps()
        return rawget(t, k)
    end
})
return WarpDrive