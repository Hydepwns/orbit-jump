-- World Generator for Orbit Jump
-- Procedurally generates planets as the player explores

local Utils = require("src.utils.utils")
local WorldGenerator = {}

-- Generation parameters
WorldGenerator.SECTOR_SIZE = 1000
WorldGenerator.MIN_PLANET_DISTANCE = 300
WorldGenerator.MAX_PLANETS_PER_SECTOR = 3

-- Track generated sectors
WorldGenerator.generatedSectors = {}

-- Planet type definitions
WorldGenerator.planetTypes = {
    standard = {
        radiusRange = {60, 90},
        rotationRange = {-1, 1},
        gravityMultiplier = 1.0,
        color = function() 
            return {
                0.3 + math.random() * 0.5,
                0.3 + math.random() * 0.5,
                0.3 + math.random() * 0.5
            }
        end
    },
    ice = {
        radiusRange = {50, 80},
        rotationRange = {-1.5, 1.5}, -- Faster rotation
        gravityMultiplier = 0.7,
        color = function() 
            return {
                0.6 + math.random() * 0.2,
                0.7 + math.random() * 0.2,
                0.9 + math.random() * 0.1
            }
        end
    },
    lava = {
        radiusRange = {70, 100},
        rotationRange = {-0.5, 0.5}, -- Slower rotation
        gravityMultiplier = 1.3,
        color = function() 
            return {
                0.8 + math.random() * 0.2,
                0.3 + math.random() * 0.2,
                0.1 + math.random() * 0.1
            }
        end
    },
    tech = {
        radiusRange = {40, 70},
        rotationRange = {-2, 2},
        gravityMultiplier = 1.0, -- Will pulse later
        color = function() 
            return {
                0.2 + math.random() * 0.2,
                0.8 + math.random() * 0.2,
                0.8 + math.random() * 0.2
            }
        end
    },
    void = {
        radiusRange = {30, 60},
        rotationRange = {-0.3, 0.3}, -- Very slow
        gravityMultiplier = -0.8, -- Negative gravity!
        color = function() 
            return {
                0.2 + math.random() * 0.1,
                0.1 + math.random() * 0.1,
                0.3 + math.random() * 0.2
            }
        end
    },
    quantum = {
        radiusRange = {30, 50},
        rotationRange = {-3, 3}, -- Very fast rotation
        gravityMultiplier = 1.0,
        color = function()
            -- Shifting colors (will be animated in renderer)
            return {
                0.5 + math.random() * 0.5,
                0.5 + math.random() * 0.5,
                0.5 + math.random() * 0.5
            }
        end,
        special = true -- Mark as special type
    }
}

function WorldGenerator.getSectorKey(x, y)
    local sectorX = math.floor(x / WorldGenerator.SECTOR_SIZE)
    local sectorY = math.floor(y / WorldGenerator.SECTOR_SIZE)
    return sectorX .. "," .. sectorY
end

function WorldGenerator.generateSector(sectorX, sectorY, existingPlanets)
    local key = sectorX .. "," .. sectorY
    if WorldGenerator.generatedSectors[key] then
        return {} -- Already generated
    end
    
    WorldGenerator.generatedSectors[key] = true
    
    local newPlanets = {}
    local planetCount = math.random(1, WorldGenerator.MAX_PLANETS_PER_SECTOR)
    
    -- Distance from origin affects difficulty
    local distanceFromOrigin = math.sqrt(sectorX^2 + sectorY^2)
    local difficultyFactor = 1 + (distanceFromOrigin * 0.2)
    
    for i = 1, planetCount do
        local attempts = 0
        local validPosition = false
        local planet = nil
        
        while attempts < 50 and not validPosition do
            -- Random position within sector
            local x = sectorX * WorldGenerator.SECTOR_SIZE + math.random(100, WorldGenerator.SECTOR_SIZE - 100)
            local y = sectorY * WorldGenerator.SECTOR_SIZE + math.random(100, WorldGenerator.SECTOR_SIZE - 100)
            
            -- Choose planet type (more exotic types further from origin)
            local typeRoll = math.random()
            local planetType = "standard"
            
            if distanceFromOrigin > 2 then
                if typeRoll < 0.25 then
                    planetType = "ice"
                elseif typeRoll < 0.5 then
                    planetType = "lava"
                elseif typeRoll < 0.7 then
                    planetType = "tech"
                elseif typeRoll < 0.85 then
                    planetType = "void"
                elseif distanceFromOrigin > 5 and typeRoll < 0.95 then
                    -- Quantum planets are very rare and only in deep space
                    planetType = "quantum"
                end
            elseif distanceFromOrigin > 5 then
                -- Void and quantum planets more common in deep space
                if typeRoll < 0.4 then
                    planetType = "void"
                elseif typeRoll < 0.45 then
                    planetType = "quantum"
                end
            end
            
            local typeData = WorldGenerator.planetTypes[planetType]
            
            planet = {
                x = x,
                y = y,
                radius = math.random(typeData.radiusRange[1], typeData.radiusRange[2]),
                rotationSpeed = Utils.randomFloat(typeData.rotationRange[1], typeData.rotationRange[2]),
                color = typeData.color(),
                type = planetType,
                gravityMultiplier = typeData.gravityMultiplier,
                discovered = false,
                id = "planet_" .. x .. "_" .. y
            }
            
            -- Check distance from all existing planets
            validPosition = true
            for _, other in ipairs(existingPlanets) do
                local dist = Utils.distance(planet.x, planet.y, other.x, other.y)
                if dist < WorldGenerator.MIN_PLANET_DISTANCE then
                    validPosition = false
                    break
                end
            end
            
            for _, other in ipairs(newPlanets) do
                local dist = Utils.distance(planet.x, planet.y, other.x, other.y)
                if dist < WorldGenerator.MIN_PLANET_DISTANCE then
                    validPosition = false
                    break
                end
            end
            
            attempts = attempts + 1
        end
        
        if validPosition and planet then
            table.insert(newPlanets, planet)
        end
    end
    
    return newPlanets
end

function WorldGenerator.generateAroundPosition(x, y, existingPlanets, radius)
    radius = radius or WorldGenerator.SECTOR_SIZE * 2
    
    local newPlanets = {}
    
    -- Check all sectors in radius
    local minSectorX = math.floor((x - radius) / WorldGenerator.SECTOR_SIZE)
    local maxSectorX = math.floor((x + radius) / WorldGenerator.SECTOR_SIZE)
    local minSectorY = math.floor((y - radius) / WorldGenerator.SECTOR_SIZE)
    local maxSectorY = math.floor((y + radius) / WorldGenerator.SECTOR_SIZE)
    
    for sx = minSectorX, maxSectorX do
        for sy = minSectorY, maxSectorY do
            local sectorPlanets = WorldGenerator.generateSector(sx, sy, existingPlanets)
            for _, planet in ipairs(sectorPlanets) do
                table.insert(newPlanets, planet)
                table.insert(existingPlanets, planet)
            end
        end
    end
    
    return newPlanets
end

function WorldGenerator.generateRingsForPlanet(planet)
    local RingSystem = Utils.require("src.systems.ring_system")
    local rings = {}
    local ringCount = math.random(5, 15)
    
    -- Ring patterns based on planet type
    if planet.type == "ice" then
        -- Ice planets have more rings in organized patterns
        ringCount = math.random(10, 20)
    elseif planet.type == "lava" then
        -- Lava planets have fewer but more valuable rings
        ringCount = math.random(3, 8)
    elseif planet.type == "tech" then
        -- Tech planets have rings in geometric patterns
        ringCount = math.random(8, 16)
    end
    
    for i = 1, ringCount do
        local angle = (i / ringCount) * math.pi * 2 + math.random() * 0.5
        local distance = planet.radius + 50 + math.random(50, 200)
        
        -- Use RingSystem to generate rings with special abilities
        local ring = RingSystem.generateRing(
            planet.x + math.cos(angle) * distance,
            planet.y + math.sin(angle) * distance,
            planet.type
        )
        
        table.insert(rings, ring)
    end
    
    return rings
end

function WorldGenerator.reset()
    WorldGenerator.generatedSectors = {}
    
    -- Generate initial planets for game start
    local GameState = Utils.require("src.core.game_state")
    local initialPlanets = WorldGenerator.generateInitialWorld()
    GameState.setPlanets(initialPlanets)
end

-- Generate initial world with starting planets
function WorldGenerator.generateInitialWorld()
    local planets = {}
    
    -- Create starting planet at center
    table.insert(planets, WorldGenerator.generatePlanet(0, 0, "standard"))
    
    -- Create a few nearby planets in a circle
    local planetCount = 5
    local radius = 500
    for i = 1, planetCount do
        local angle = (i / planetCount) * math.pi * 2
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        
        -- Random planet type
        local types = {"standard", "ice", "lava", "tech"}
        local planetType = types[math.random(#types)]
        
        table.insert(planets, WorldGenerator.generatePlanet(x, y, planetType))
    end
    
    return planets
end

-- Generate a single planet at specified position
function WorldGenerator.generatePlanet(x, y, planetType)
    planetType = planetType or "standard"
    local typeData = WorldGenerator.planetTypes[planetType]
    
    if not typeData then
        typeData = WorldGenerator.planetTypes.standard
    end
    
    local radius = Utils.randomFloat(typeData.radiusRange[1], typeData.radiusRange[2])
    
    return {
        x = x,
        y = y,
        radius = radius,
        rotation = 0,
        rotationSpeed = Utils.randomFloat(typeData.rotationRange[1], typeData.rotationRange[2]),
        color = typeData.color(),
        type = planetType,
        gravityMultiplier = typeData.gravityMultiplier,
        discovered = false,
        id = "planet_" .. x .. "_" .. y
    }
end

-- Discover a planet when player gets close
function WorldGenerator.discoverPlanet(planet, playerX, playerY)
    if planet.discovered then return false end
    
    -- Validate inputs
    if not planet or not planet.x or not planet.y or not playerX or not playerY then
        return false
    end
    
    local distance = Utils.distance(playerX, playerY, planet.x, planet.y)
    local discoveryRadius = planet.radius + 100
    
    if distance <= discoveryRadius then
        planet.discovered = true
        planet.discoveryTime = love.timer.getTime()
        
        -- Trigger discovery event
        local success, achievementSystem  = Utils.ErrorHandler.safeCall(require, "achievement_system")
        if success and achievementSystem and achievementSystem.onPlanetDiscovered then
            achievementSystem.onPlanetDiscovered(planet.type)
        end
        
        return true
    end
    
    return false
end

return WorldGenerator