--[[
    Warp Energy System: Energy Management and Regeneration
    This module handles all energy-related functionality for the warp drive,
    including energy storage, consumption, regeneration, and efficiency.
--]]
local Utils = require("src.utils.utils")
local WarpEnergy = {}
-- Energy state
WarpEnergy.energy = 1000
WarpEnergy.maxEnergy = 1000
WarpEnergy.energyRegenRate = 50 -- Per second
WarpEnergy.baseCost = 100 -- Base energy cost for warping
-- Initialize energy system
function WarpEnergy.init()
    WarpEnergy.energy = WarpEnergy.maxEnergy
end
-- Update energy regeneration
function WarpEnergy.update(dt)
    -- Regenerate energy over time
    if WarpEnergy.energy < WarpEnergy.maxEnergy then
        WarpEnergy.energy = math.min(WarpEnergy.maxEnergy,
            WarpEnergy.energy + WarpEnergy.energyRegenRate * dt)
    end
end
-- Check if we have enough energy for a warp
function WarpEnergy.hasEnergy(cost)
    return WarpEnergy.energy >= cost
end
-- Consume energy for warp
function WarpEnergy.consumeEnergy(cost)
    if WarpEnergy.energy >= cost then
        WarpEnergy.energy = WarpEnergy.energy - cost
        return true
    end
    return false
end
-- Add energy (for pickups, bonuses, etc.)
function WarpEnergy.addEnergy(amount)
    WarpEnergy.energy = math.min(WarpEnergy.maxEnergy, WarpEnergy.energy + amount)
end
-- Set max energy (for upgrades)
function WarpEnergy.setMaxEnergy(newMax)
    local ratio = WarpEnergy.energy / WarpEnergy.maxEnergy
    WarpEnergy.maxEnergy = newMax
    -- Maintain energy ratio when upgrading
    WarpEnergy.energy = math.floor(newMax * ratio)
end
-- Get current energy percentage
function WarpEnergy.getEnergyPercent()
    return WarpEnergy.energy / WarpEnergy.maxEnergy
end
-- Calculate base energy cost based on distance
function WarpEnergy.calculateBaseCost(distance)
    -- Foundation: Physics-based cost scaling
    return math.max(50, math.floor(distance / 100))
end
-- Draw energy UI
function WarpEnergy.drawEnergyBar()
    local screenWidth = love.graphics.getWidth()
    local barWidth = 200
    local barHeight = 20
    local barX = screenWidth - barWidth - 20
    local barY = 100
    -- Background
    Utils.setColor({0, 0, 0}, 0.5)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 5)
    -- Energy fill
    local energyPercent = WarpEnergy.getEnergyPercent()
    -- Color based on energy level
    if energyPercent > 0.6 then
        Utils.setColor({0.2, 0.5, 1}, 0.8) -- Blue
    elseif energyPercent > 0.3 then
        Utils.setColor({1, 0.8, 0}, 0.8) -- Yellow
    else
        Utils.setColor({1, 0.2, 0.2}, 0.8) -- Red
    end
    love.graphics.rectangle("fill", barX, barY, barWidth * energyPercent, barHeight, 5)
    -- Border
    Utils.setColor({0.5, 0.7, 1}, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight, 5)
    -- Text
    Utils.setColor({1, 1, 1}, 0.9)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf("Warp Energy", barX, barY - 20, barWidth, "center")
    love.graphics.printf(math.floor(WarpEnergy.energy) .. " / " .. WarpEnergy.maxEnergy,
        barX, barY + 2, barWidth, "center")
end
-- Get energy status
function WarpEnergy.getStatus()
    return {
        current = WarpEnergy.energy,
        max = WarpEnergy.maxEnergy,
        percent = WarpEnergy.getEnergyPercent(),
        regenRate = WarpEnergy.energyRegenRate
    }
end
-- Save energy state
function WarpEnergy.saveState()
    return {
        energy = WarpEnergy.energy,
        maxEnergy = WarpEnergy.maxEnergy,
        energyRegenRate = WarpEnergy.energyRegenRate
    }
end
-- Restore energy state
function WarpEnergy.restoreState(state)
    if state then
        WarpEnergy.energy = state.energy or WarpEnergy.energy
        WarpEnergy.maxEnergy = state.maxEnergy or WarpEnergy.maxEnergy
        WarpEnergy.energyRegenRate = state.energyRegenRate or WarpEnergy.energyRegenRate
    end
end
-- Upgrade energy capacity
function WarpEnergy.upgradeCapacity(upgradeLevel)
    -- Each upgrade increases max energy by 20%
    local newMax = 1000 * (1 + upgradeLevel * 0.2)
    WarpEnergy.setMaxEnergy(newMax)
end
-- Upgrade regeneration rate
function WarpEnergy.upgradeRegeneration(upgradeLevel)
    -- Each upgrade increases regen by 25%
    WarpEnergy.energyRegenRate = 50 * (1 + upgradeLevel * 0.25)
end
return WarpEnergy