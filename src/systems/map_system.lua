-- Map System for Orbit Jump
-- Provides navigation and discovery tracking

local Utils = Utils.Utils.require("src.utils.utils")
local MapSystem = {}

-- Map state
MapSystem.isVisible = false
MapSystem.discoveredPlanets = {}
MapSystem.visitedSectors = {}
MapSystem.zoomLevel = 1 -- 1 = local (2000 units), 2 = sector (5000 units), 3 = galaxy (10000 units)
MapSystem.zoomLevels = {2000, 5000, 10000}
MapSystem.mapOffset = {x = 0, y = 0}
MapSystem.isDragging = false
MapSystem.dragStart = {x = 0, y = 0}

-- Visual settings
MapSystem.mapAlpha = 0 -- For fade in/out
MapSystem.mapSize = 0.8 -- 80% of screen
MapSystem.planetIconSize = 8
MapSystem.playerIconSize = 10

-- Initialize
function MapSystem.init()
    MapSystem.discoveredPlanets = {}
    MapSystem.visitedSectors = {}
    MapSystem.isVisible = false
    MapSystem.mapAlpha = 0
end

-- Toggle map visibility
function MapSystem.toggle()
    MapSystem.isVisible = not MapSystem.isVisible
    if MapSystem.isVisible then
        -- Center map on player when opened
        MapSystem.mapOffset = {x = 0, y = 0}
    end
end

-- Update map
function MapSystem.update(dt, player, planets)
    -- Update map fade
    if MapSystem.isVisible then
        MapSystem.mapAlpha = math.min(MapSystem.mapAlpha + dt * 5, 1)
    else
        MapSystem.mapAlpha = math.max(MapSystem.mapAlpha - dt * 5, 0)
    end
    
    -- Track discovered planets
    for _, planet in ipairs(planets) do
        if planet.discovered and not MapSystem.discoveredPlanets[planet.id] then
            MapSystem.discoveredPlanets[planet.id] = {
                x = planet.x,
                y = planet.y,
                type = planet.type,
                radius = planet.radius,
                discovered = true
            }
        end
    end
    
    -- Track visited sectors
    local sectorX = math.floor(player.x / 1000)
    local sectorY = math.floor(player.y / 1000)
    local sectorKey = sectorX .. "," .. sectorY
    MapSystem.visitedSectors[sectorKey] = true
end

-- Handle mouse input for map
function MapSystem.mousepressed(x, y, button)
    if not MapSystem.isVisible then return end
    
    if button == 1 then
        MapSystem.isDragging = true
        MapSystem.dragStart.x = x - MapSystem.mapOffset.x
        MapSystem.dragStart.y = y - MapSystem.mapOffset.y
    elseif button == 3 then -- Right click to center on player
        MapSystem.mapOffset = {x = 0, y = 0}
    end
end

function MapSystem.mousereleased(x, y, button)
    if button == 1 then
        MapSystem.isDragging = false
    end
end

function MapSystem.mousemoved(x, y)
    if MapSystem.isDragging then
        MapSystem.mapOffset.x = x - MapSystem.dragStart.x
        MapSystem.mapOffset.y = y - MapSystem.dragStart.y
    end
end

function MapSystem.wheelmoved(x, y)
    if not MapSystem.isVisible then return end
    
    if y > 0 then
        -- Zoom in
        MapSystem.zoomLevel = math.max(1, MapSystem.zoomLevel - 1)
    elseif y < 0 then
        -- Zoom out
        MapSystem.zoomLevel = math.min(3, MapSystem.zoomLevel + 1)
    end
end

-- Draw map
function MapSystem.draw(player, planets, camera)
    if MapSystem.mapAlpha <= 0 then return end
    
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Map dimensions
    local mapWidth = screenWidth * MapSystem.mapSize
    local mapHeight = screenHeight * MapSystem.mapSize
    local mapX = (screenWidth - mapWidth) / 2
    local mapY = (screenHeight - mapHeight) / 2
    
    -- Semi-transparent background
    Utils.setColor({0, 0, 0}, 0.8 * MapSystem.mapAlpha)
    love.graphics.rectangle("fill", mapX, mapY, mapWidth, mapHeight, 10)
    
    -- Map border
    Utils.setColor({0.5, 0.8, 1}, 0.8 * MapSystem.mapAlpha)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", mapX, mapY, mapWidth, mapHeight, 10)
    
    -- Title
    Utils.setColor({1, 1, 1}, MapSystem.mapAlpha)
    love.graphics.setFont(love.graphics.getFont())
    love.graphics.printf("GALACTIC MAP", mapX, mapY + 10, mapWidth, "center")
    
    -- Zoom level indicator
    local zoomText = "Local"
    if MapSystem.zoomLevel == 2 then zoomText = "Sector"
    elseif MapSystem.zoomLevel == 3 then zoomText = "Galaxy" end
    love.graphics.printf("View: " .. zoomText, mapX, mapY + 30, mapWidth, "center")
    
    -- Set up clipping to keep content within map bounds
    love.graphics.push()
    love.graphics.setScissor(mapX + 5, mapY + 50, mapWidth - 10, mapHeight - 60)
    
    -- Calculate scale based on zoom level
    local zoomRange = MapSystem.zoomLevels[MapSystem.zoomLevel]
    local scale = math.min(mapWidth, mapHeight) / (zoomRange * 2)
    
    -- Map center (follows player)
    local centerX = mapX + mapWidth / 2 + MapSystem.mapOffset.x
    local centerY = mapY + mapHeight / 2 + MapSystem.mapOffset.y
    
    -- Draw grid
    Utils.setColor({0.2, 0.3, 0.4}, 0.3 * MapSystem.mapAlpha)
    love.graphics.setLineWidth(1)
    local gridSize = 500 * scale
    for i = -10, 10 do
        local x = centerX + i * gridSize - (player.x * scale) % gridSize
        local y = centerY + i * gridSize - (player.y * scale) % gridSize
        love.graphics.line(x, mapY + 50, x, mapY + mapHeight - 10)
        love.graphics.line(mapX + 5, y, mapX + mapWidth - 5, y)
    end
    
    -- Draw discovered planets
    for id, planetData in pairs(MapSystem.discoveredPlanets) do
        local px = centerX + (planetData.x - player.x) * scale
        local py = centerY + (planetData.y - player.y) * scale
        
        -- Only draw if within map bounds
        if px > mapX and px < mapX + mapWidth and py > mapY + 50 and py < mapY + mapHeight then
            -- Planet icon
            local iconSize = math.max(5, planetData.radius * scale * 0.5)
            
            -- Planet type colors
            local color = {0.5, 0.5, 0.5}
            if planetData.type == "ice" then
                color = {0.6, 0.8, 1}
            elseif planetData.type == "lava" then
                color = {1, 0.4, 0.2}
            elseif planetData.type == "tech" then
                color = {0.2, 1, 0.8}
            elseif planetData.type == "void" then
                color = {0.7, 0.3, 1}
            elseif planetData.type == "quantum" then
                color = {1, 0, 1}
            end
            
            Utils.setColor(color, 0.8 * MapSystem.mapAlpha)
            love.graphics.circle("fill", px, py, iconSize)
            
            -- Outline
            Utils.setColor({1, 1, 1}, 0.5 * MapSystem.mapAlpha)
            love.graphics.circle("line", px, py, iconSize)
            
            -- Show type on hover (if close to mouse)
            local mx, my = love.mouse.getPosition()
            if math.abs(mx - px) < 20 and math.abs(my - py) < 20 then
                Utils.setColor({1, 1, 1}, MapSystem.mapAlpha)
                love.graphics.setFont(love.graphics.newFont(10))
                love.graphics.print(planetData.type or "standard", px + iconSize + 5, py - 5)
            end
        end
    end
    
    -- Draw undiscovered planets (dimmer)
    for _, planet in ipairs(planets) do
        if not planet.discovered then
            local px = centerX + (planet.x - player.x) * scale
            local py = centerY + (planet.y - player.y) * scale
            
            if px > mapX and px < mapX + mapWidth and py > mapY + 50 and py < mapY + mapHeight then
                Utils.setColor({0.3, 0.3, 0.3}, 0.3 * MapSystem.mapAlpha)
                love.graphics.circle("line", px, py, 5)
            end
        end
    end
    
    -- Draw warp zones if visible
    local WarpZones = Utils.Utils.require("src.systems.warp_zones")
    if WarpZones and WarpZones.activeZones then
        for _, zone in ipairs(WarpZones.activeZones) do
            local zx = centerX + (zone.x - player.x) * scale
            local zy = centerY + (zone.y - player.y) * scale
            
            if zx > mapX and zx < mapX + mapWidth and zy > mapY + 50 and zy < mapY + mapHeight then
                if zone.discovered then
                    Utils.setColor(zone.data.color, 0.6 * MapSystem.mapAlpha)
                    love.graphics.circle("line", zx, zy, 15)
                    love.graphics.circle("line", zx, zy, 12)
                    love.graphics.circle("line", zx, zy, 9)
                else
                    Utils.setColor({0.5, 0, 0.5}, 0.3 * MapSystem.mapAlpha)
                    love.graphics.print("?", zx - 5, zy - 7)
                end
            end
        end
    end
    
    -- Draw artifacts on map
    local ArtifactSystem = Utils.Utils.require("src.systems.artifact_system")
    if ArtifactSystem and ArtifactSystem.drawOnMap then
        ArtifactSystem.drawOnMap(camera, centerX, centerY, scale, MapSystem.mapAlpha)
    end
    
    -- Draw player (always in center)
    Utils.setColor({1, 1, 0}, MapSystem.mapAlpha)
    love.graphics.circle("fill", centerX, centerY, MapSystem.playerIconSize)
    Utils.setColor({1, 1, 1}, MapSystem.mapAlpha)
    love.graphics.circle("line", centerX, centerY, MapSystem.playerIconSize)
    
    -- Draw player direction indicator
    local angleIndicator = player.angle or 0
    local indicatorLength = 20
    love.graphics.setLineWidth(2)
    love.graphics.line(
        centerX,
        centerY,
        centerX + math.cos(angleIndicator) * indicatorLength,
        centerY + math.sin(angleIndicator) * indicatorLength
    )
    
    -- Clear scissor
    love.graphics.setScissor()
    love.graphics.pop()
    
    -- Controls help
    Utils.setColor({0.6, 0.6, 0.6}, MapSystem.mapAlpha)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.printf(
        "Mouse Wheel: Zoom | Drag: Pan | Right Click: Center | TAB: Close",
        mapX, mapY + mapHeight - 20, mapWidth, "center"
    )
    
    -- Stats
    local discoveredCount = 0
    for _ in pairs(MapSystem.discoveredPlanets) do
        discoveredCount = discoveredCount + 1
    end
    
    Utils.setColor({0.8, 0.8, 0.8}, MapSystem.mapAlpha)
    love.graphics.print("Planets Discovered: " .. discoveredCount, mapX + 10, mapY + mapHeight - 40)
    
    local sectorCount = 0
    for _ in pairs(MapSystem.visitedSectors) do
        sectorCount = sectorCount + 1
    end
    love.graphics.print("Sectors Explored: " .. sectorCount, mapX + 10, mapY + mapHeight - 20)
end

-- Check if map is blocking input
function MapSystem.isBlockingInput()
    return MapSystem.isVisible and MapSystem.mapAlpha > 0.5
end

-- Get discovered planet count
function MapSystem.getDiscoveredCount()
    local count = 0
    for _ in pairs(MapSystem.discoveredPlanets) do
        count = count + 1
    end
    return count
end

return MapSystem