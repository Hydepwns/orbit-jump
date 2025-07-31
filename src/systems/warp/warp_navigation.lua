--[[
    ═══════════════════════════════════════════════════════════════════════════
    Warp Navigation: Path Calculation and Target Selection
    ═══════════════════════════════════════════════════════════════════════════
    
    This module handles all navigation-related features of the warp drive,
    including path calculation, planet selection, and targeting.
--]]

local Utils = require("src.utils.utils")
local WarpNavigation = {}

-- Selection state
WarpNavigation.isSelecting = false
WarpNavigation.selectedPlanet = nil
WarpNavigation.selectionRadius = 50

-- Calculate distance between player and target
function WarpNavigation.calculateDistance(sourceX, sourceY, targetX, targetY)
    return Utils.distance(sourceX, sourceY, targetX, targetY)
end

-- Check if player can afford to warp to target
function WarpNavigation.canAffordWarp(targetPlanet, player, energy, calculateCostFn, isUnlocked)
    if not isUnlocked then return false end
    if not targetPlanet.discovered then return false end
    
    local distance = WarpNavigation.calculateDistance(player.x, player.y, targetPlanet.x, targetPlanet.y)
    local cost = calculateCostFn(distance, player.x, player.y, targetPlanet)
    
    return energy >= cost
end

-- Toggle planet selection mode
function WarpNavigation.toggleSelection(isUnlocked, isWarping)
    if not isUnlocked then return false end
    if isWarping then return false end
    
    WarpNavigation.isSelecting = not WarpNavigation.isSelecting
    WarpNavigation.selectedPlanet = nil
    
    return WarpNavigation.isSelecting
end

-- Handle planet selection at given coordinates
function WarpNavigation.selectPlanetAt(worldX, worldY, planets, player, canAffordFn, startWarpFn)
    if not WarpNavigation.isSelecting then return nil end
    
    -- Find closest discovered planet to click position
    local closestPlanet = nil
    local closestDistance = WarpNavigation.selectionRadius
    
    for _, planet in ipairs(planets) do
        if planet.discovered then
            local dist = WarpNavigation.calculateDistance(worldX, worldY, planet.x, planet.y)
            if dist < closestDistance and dist < planet.radius + WarpNavigation.selectionRadius then
                closestPlanet = planet
                closestDistance = dist
            end
        end
    end
    
    if closestPlanet then
        WarpNavigation.selectedPlanet = closestPlanet
        
        -- Auto-start warp if we can afford it
        if canAffordFn(closestPlanet, player) then
            startWarpFn(closestPlanet, player)
            WarpNavigation.isSelecting = false
            WarpNavigation.selectedPlanet = nil
        end
    end
    
    return closestPlanet
end

-- Calculate optimal route between planets (for future expansion)
function WarpNavigation.calculateOptimalRoute(sourceX, sourceY, targetPlanet, knownPlanets)
    -- For now, direct routes only
    -- Future: implement multi-hop optimization
    return {
        direct = true,
        hops = 1,
        totalDistance = WarpNavigation.calculateDistance(sourceX, sourceY, targetPlanet.x, targetPlanet.y)
    }
end

-- Get nearby planets within warp range
function WarpNavigation.getPlanetsInRange(player, planets, maxRange, energy, calculateCostFn)
    local planetsInRange = {}
    
    for _, planet in ipairs(planets) do
        if planet.discovered then
            local distance = WarpNavigation.calculateDistance(player.x, player.y, planet.x, planet.y)
            local cost = calculateCostFn(distance, player.x, player.y, planet)
            
            if distance <= maxRange and energy >= cost then
                table.insert(planetsInRange, {
                    planet = planet,
                    distance = distance,
                    cost = cost
                })
            end
        end
    end
    
    -- Sort by distance
    table.sort(planetsInRange, function(a, b)
        return a.distance < b.distance
    end)
    
    return planetsInRange
end

-- Draw navigation UI
function WarpNavigation.drawSelectionUI(planets, player, camera, energy, calculateCostFn)
    if not WarpNavigation.isSelecting then return end
    
    local screenWidth = love.graphics.getWidth()
    
    -- Selection mode indicator
    Utils.setColor({1, 1, 0}, 0.8)
    love.graphics.printf("SELECT WARP DESTINATION", 0, 150, screenWidth, "center")
    
    -- Draw selection circles on discovered planets
    for _, planet in ipairs(planets) do
        if planet.discovered then
            local screenX, screenY = camera:worldToScreen(planet.x, planet.y)
            
            -- Calculate affordability
            local distance = WarpNavigation.calculateDistance(player.x, player.y, planet.x, planet.y)
            local cost = calculateCostFn(distance, player.x, player.y, planet)
            local canAfford = energy >= cost
            
            if canAfford then
                Utils.setColor({0, 1, 0}, 0.5)
            else
                Utils.setColor({1, 0, 0}, 0.3)
            end
            
            -- Pulsing selection circle
            local pulse = math.sin(love.timer.getTime() * 3) * 5 + planet.radius + 20
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", screenX, screenY, pulse)
            
            -- Cost indicator for selected planet
            if planet == WarpNavigation.selectedPlanet then
                Utils.setColor({1, 1, 1}, 0.9)
                love.graphics.setFont(love.graphics.newFont(10))
                love.graphics.print("Cost: " .. cost, screenX + planet.radius + 10, screenY)
            end
        end
    end
end

-- Reset navigation state
function WarpNavigation.reset()
    WarpNavigation.isSelecting = false
    WarpNavigation.selectedPlanet = nil
end

return WarpNavigation