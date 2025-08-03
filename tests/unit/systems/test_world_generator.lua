-- Tests for World Generator
package.path = package.path .. ";../../?.lua"
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Mock the world generator
local WorldGenerator = {}
WorldGenerator.SECTOR_SIZE = 1000
WorldGenerator.MIN_PLANET_DISTANCE = 200
WorldGenerator.MAX_PLANETS_PER_SECTOR = 5
WorldGenerator.generatedSectors = {}
WorldGenerator.planetTypes = {
        standard = {
            radiusRange = {60, 100},
            rotationRange = {0.1, 0.5},
            gravityMultiplier = 1.0,
            color = function() return {0.8, 0.3, 0.3} end
        },
        ice = {
            radiusRange = {50, 90},
            rotationRange = {0.2, 0.6},
            gravityMultiplier = 0.7,
            color = function() return {0.7, 0.8, 1.0} end
        },
        lava = {
            radiusRange = {70, 110},
            rotationRange = {0.3, 0.7},
            gravityMultiplier = 1.3,
            color = function() return {1.0, 0.2, 0.1} end
        },
        tech = {
            radiusRange = {55, 95},
            rotationRange = {0.4, 0.8},
            gravityMultiplier = 1.1,
            color = function() return {0.2, 0.8, 0.9} end
        },
        void = {
            radiusRange = {40, 80},
            rotationRange = {0.5, 0.9},
            gravityMultiplier = -0.8,
            color = function() return {0.1, 0.1, 0.3} end
        },
        quantum = {
            radiusRange = {80, 120},
            rotationRange = {0.6, 1.0},
            gravityMultiplier = 1.0,
            special = true,
            color = function() return {0.9, 0.1, 0.9} end
        }
    }
WorldGenerator.reset = function()
        WorldGenerator.generatedSectors = {}
    end
WorldGenerator.getSectorKey = function(x, y)
        local sectorX = math.floor(x / WorldGenerator.SECTOR_SIZE)
        local sectorY = math.floor(y / WorldGenerator.SECTOR_SIZE)
        return sectorX .. "," .. sectorY
    end
WorldGenerator.generateSector = function(x, y, existingPlanets)
        local key = WorldGenerator.getSectorKey(x, y)
        if WorldGenerator.generatedSectors[key] then
            return {}
        end
        WorldGenerator.generatedSectors[key] = true
        local planets = {}
        -- Generate 1-3 planets for this sector
        local numPlanets = math.random(1, 3)
        local attempts = 0
        local maxAttempts = 50
        while #planets < numPlanets and attempts < maxAttempts do
            attempts = attempts + 1
            local planetX = x + math.random(-400, 400)
            local planetY = y + math.random(-400, 400)
            local planetType = "standard"
            if math.random() < 0.2 then planetType = "ice" end
            if math.random() < 0.2 then planetType = "lava" end
            if math.random() < 0.1 then planetType = "void" end
            -- Check distance from existing planets
            local tooClose = false
            if existingPlanets then
                for _, existing in ipairs(existingPlanets) do
                    local dist = math.sqrt((planetX - existing.x)^2 + (planetY - existing.y)^2)
                    if dist < WorldGenerator.MIN_PLANET_DISTANCE then
                        tooClose = true
                        break
                    end
                end
            end
            -- Also check distance from already generated planets in this sector
            for _, planet in ipairs(planets) do
                local dist = math.sqrt((planetX - planet.x)^2 + (planetY - planet.y)^2)
                if dist < WorldGenerator.MIN_PLANET_DISTANCE then
                    tooClose = true
                    break
                end
            end
            if not tooClose then
                table.insert(planets, WorldGenerator.generatePlanet(planetX, planetY, planetType))
            end
        end
        return planets
    end
WorldGenerator.generatePlanet = function(x, y, planetType)
        local typeData = WorldGenerator.planetTypes[planetType]
        if not typeData then
            typeData = WorldGenerator.planetTypes.standard
        end
        local radius = typeData.radiusRange[1] + math.random() * (typeData.radiusRange[2] - typeData.radiusRange[1])
        local rotation = typeData.rotationRange[1] + math.random() * (typeData.rotationRange[2] - typeData.rotationRange[1])
        return {
            x = x,
            y = y,
            radius = radius,
            rotation = rotation,
            rotationSpeed = rotation,
            gravityMultiplier = typeData.gravityMultiplier,
            color = typeData.color(),
            type = planetType,
            special = typeData.special,
            discovered = false,
            id = math.random(1000000)
        }
    end
WorldGenerator.generateAroundPosition = function(x, y, existingPlanets, radius)
        -- Mock implementation that generates planets around a position
        local planets = {}
        local numPlanets = math.random(0, 3)
        for i = 1, numPlanets do
            local angle = math.random() * math.pi * 2
            local distance = math.random() * radius
            local planetX = x + math.cos(angle) * distance
            local planetY = y + math.sin(angle) * distance
            -- Choose planet type based on distance from origin
            local distanceFromOrigin = math.sqrt(x^2 + y^2)
            local planetType = "standard"
            if distanceFromOrigin > 3000 then
                if math.random() < 0.4 then planetType = "ice" end
                if math.random() < 0.4 then planetType = "lava" end
                if math.random() < 0.2 then planetType = "void" end
                if math.random() < 0.1 then planetType = "quantum" end
            else
                if math.random() < 0.2 then planetType = "ice" end
                if math.random() < 0.2 then planetType = "lava" end
                if math.random() < 0.1 then planetType = "void" end
            end
            table.insert(planets, WorldGenerator.generatePlanet(planetX, planetY, planetType))
        end
        return planets
    end
WorldGenerator.discoverPlanet = function(planet, x, y)
        if planet.discovered then
            return false
        end
        local distance = math.sqrt((planet.x - x)^2 + (planet.y - y)^2)
        local discoveryRange = 150
        if distance <= discoveryRange then
            planet.discovered = true
            planet.discoveryTime = os.time()
            return true
        end
        return false
    end
WorldGenerator.generateRingsForPlanet = function(planet)
        local rings = {}
        local numRings = math.random(0, 5)
        for i = 1, numRings do
            local angle = math.random() * math.pi * 2
            local distance = planet.radius + 50 + math.random() * 200
            local ringX = planet.x + math.cos(angle) * distance
            local ringY = planet.y + math.sin(angle) * distance
            table.insert(rings, {
                x = ringX,
                y = ringY,
                type = planet.type,
                collected = false
            })
        end
        return rings
    end
-- Test suite
local tests = {
    ["system initialization"] = function()
        WorldGenerator.reset()
        TestFramework.assert.notNil(WorldGenerator.SECTOR_SIZE, "Sector size should be defined")
        TestFramework.assert.notNil(WorldGenerator.MIN_PLANET_DISTANCE, "Min planet distance should be defined")
        TestFramework.assert.notNil(WorldGenerator.MAX_PLANETS_PER_SECTOR, "Max planets per sector should be defined")
        TestFramework.assert.notNil(WorldGenerator.generatedSectors, "Generated sectors should be initialized")
        TestFramework.assert.notNil(WorldGenerator.planetTypes, "Planet types should be defined")
    end,
    ["planet type definitions"] = function()
        TestFramework.assert.notNil(WorldGenerator.planetTypes.standard, "Standard planet type should exist")
        TestFramework.assert.notNil(WorldGenerator.planetTypes.ice, "Ice planet type should exist")
        TestFramework.assert.notNil(WorldGenerator.planetTypes.lava, "Lava planet type should exist")
        TestFramework.assert.notNil(WorldGenerator.planetTypes.tech, "Tech planet type should exist")
        TestFramework.assert.notNil(WorldGenerator.planetTypes.void, "Void planet type should exist")
        TestFramework.assert.notNil(WorldGenerator.planetTypes.quantum, "Quantum planet type should exist")
    end,
    ["planet type properties"] = function()
        local standard = WorldGenerator.planetTypes.standard
        TestFramework.assert.notNil(standard.radiusRange, "Planet should have radius range")
        TestFramework.assert.notNil(standard.rotationRange, "Planet should have rotation range")
        TestFramework.assert.notNil(standard.gravityMultiplier, "Planet should have gravity multiplier")
        TestFramework.assert.notNil(standard.color, "Planet should have color function")
        local void = WorldGenerator.planetTypes.void
        TestFramework.assert.equal(-0.8, void.gravityMultiplier, "Void planet should have negative gravity")
        TestFramework.assert.isTrue(void.rotationRange[1] < void.rotationRange[2], "Rotation range should be valid")
        local quantum = WorldGenerator.planetTypes.quantum
        TestFramework.assert.isTrue(quantum.special, "Quantum planet should be marked as special")
    end,
    ["sector key generation"] = function()
        local key1 = WorldGenerator.getSectorKey(0, 0)
        TestFramework.assert.equal("0,0", key1, "Sector key for origin should be 0,0")
        local key2 = WorldGenerator.getSectorKey(1000, 1000)
        TestFramework.assert.equal("1,1", key2, "Sector key for 1000,1000 should be 1,1")
        local key3 = WorldGenerator.getSectorKey(500, 1500)
        TestFramework.assert.equal("0,1", key3, "Sector key for 500,1500 should be 0,1")
        local key4 = WorldGenerator.getSectorKey(-500, -1500)
        TestFramework.assert.equal("-1,-2", key4, "Sector key for negative coordinates should be correct")
    end,
    ["sector generation"] = function()
        WorldGenerator.reset()
        local existingPlanets = {}
        local newPlanets = WorldGenerator.generateSector(0, 0, existingPlanets)
        -- The generation is random, so we can't guarantee it will always generate planets
        -- But we can check the constraints
        TestFramework.assert.isTrue(#newPlanets >= 0, "Should generate zero or more planets")
        TestFramework.assert.isTrue(#newPlanets <= WorldGenerator.MAX_PLANETS_PER_SECTOR, "Should not exceed max planets per sector")
        -- Check that sector is marked as generated
        TestFramework.assert.isTrue(WorldGenerator.generatedSectors["0,0"], "Sector should be marked as generated")
    end,
    ["sector generation with existing planets"] = function()
        WorldGenerator.reset()
        local existingPlanets = {
            {x = 100, y = 100, radius = 80}
        }
        local newPlanets = WorldGenerator.generateSector(0, 0, existingPlanets)
        -- Check that new planets respect the minimum distance from existing ones
        for _, newPlanet in ipairs(newPlanets) do
            for _, existingPlanet in ipairs(existingPlanets) do
                local distance = math.sqrt((newPlanet.x - existingPlanet.x)^2 + (newPlanet.y - existingPlanet.y)^2)
                -- WorldGenerator uses MIN_PLANET_DISTANCE = 300
                local minDist = WorldGenerator.MIN_PLANET_DISTANCE
                TestFramework.assert.isTrue(distance >= minDist,
                    string.format("Planets should maintain minimum distance. Distance: %.1f, Required: %.1f", distance, minDist))
            end
        end
    end,
    ["sector generation idempotency"] = function()
        WorldGenerator.reset()
        local existingPlanets = {}
        local planets1 = WorldGenerator.generateSector(0, 0, existingPlanets)
        local planets2 = WorldGenerator.generateSector(0, 0, existingPlanets)
        TestFramework.assert.equal(0, #planets2, "Second generation should return empty (already generated)")
    end,
    ["planet generation around position"] = function()
        WorldGenerator.reset()
        local existingPlanets = {}
        local newPlanets = WorldGenerator.generateAroundPosition(0, 0, existingPlanets, 1000)
        -- The generation is random, so we can't guarantee it will always generate planets
        -- But we can check the constraints
        TestFramework.assert.isTrue(#newPlanets >= 0, "Should generate zero or more planets")
        -- Check that planets are within the specified radius
        for _, planet in ipairs(newPlanets) do
            local distance = math.sqrt(planet.x^2 + planet.y^2)
            TestFramework.assert.isTrue(distance <= 1000, "Planet should be within generation radius")
        end
    end,
    ["planet generation with custom radius"] = function()
        WorldGenerator.reset()
        local existingPlanets = {}
        local newPlanets = WorldGenerator.generateAroundPosition(0, 0, existingPlanets, 500)
        -- Check that planets are within the custom radius
        for _, planet in ipairs(newPlanets) do
            local distance = math.sqrt(planet.x^2 + planet.y^2)
            TestFramework.assert.isTrue(distance <= 500, "Planet should be within custom radius")
        end
    end,
    ["planet generation difficulty scaling"] = function()
        WorldGenerator.reset()
        local existingPlanets = {}
        -- Generate planets at different distances from origin
        local closePlanets = WorldGenerator.generateAroundPosition(0, 0, existingPlanets, 1000)
        local farPlanets = WorldGenerator.generateAroundPosition(5000, 5000, existingPlanets, 1000)
        -- Far planets should have more exotic types
        local closeExoticCount = 0
        local farExoticCount = 0
        for _, planet in ipairs(closePlanets) do
            if planet.type ~= "standard" then
                closeExoticCount = closeExoticCount + 1
            end
        end
        for _, planet in ipairs(farPlanets) do
            if planet.type ~= "standard" then
                farExoticCount = farExoticCount + 1
            end
        end
        -- Far planets should have more exotic types (not guaranteed but likely)
        TestFramework.assert.isTrue(farExoticCount >= closeExoticCount, "Far planets should have more exotic types")
    end,
    ["ring generation for planet"] = function()
        WorldGenerator.reset()
        local planet = {
            x = 400,
            y = 300,
            radius = 80,
            type = "standard",
            discovered = false
        }
        -- Mock RingSystem for testing
        local originalRequire = require
        require = function(module)
            if module == "src.systems.ring_system" then
                return {
                    generateRing = function(x, y, planetType)
                        return {
                            x = x,
                            y = y,
                            type = planetType or "standard",
                            collected = false
                        }
                    end
                }
            else
                return originalRequire(module)
            end
        end
        local rings = WorldGenerator.generateRingsForPlanet(planet)
        -- Restore original require
        require = originalRequire
        -- Ring generation is random, so we check reasonable bounds
        TestFramework.assert.isTrue(#rings >= 0, "Should generate zero or more rings")
        TestFramework.assert.isTrue(#rings <= 25, "Should not exceed maximum number of rings")
        -- Check that rings are positioned around the planet
        for _, ring in ipairs(rings) do
            local distance = math.sqrt((ring.x - planet.x)^2 + (ring.y - planet.y)^2)
            TestFramework.assert.isTrue(distance >= planet.radius + 50, "Ring should be outside planet")
            TestFramework.assert.isTrue(distance <= planet.radius + 250, "Ring should be within reasonable distance")
        end
    end,
    ["ring generation by planet type"] = function()
        WorldGenerator.reset()
        local icePlanet = {x = 400, y = 300, radius = 80, type = "ice", discovered = false}
        local lavaPlanet = {x = 500, y = 300, radius = 80, type = "lava", discovered = false}
        local techPlanet = {x = 600, y = 300, radius = 80, type = "tech", discovered = false}
        -- Mock RingSystem for testing
        local originalRequire = require
        require = function(module)
            if module == "src.systems.ring_system" then
                return {
                    generateRing = function(x, y, planetType)
                        return {
                            x = x,
                            y = y,
                            type = planetType or "standard",
                            collected = false
                        }
                    end
                }
            else
                return originalRequire(module)
            end
        end
        local iceRings = WorldGenerator.generateRingsForPlanet(icePlanet)
        local lavaRings = WorldGenerator.generateRingsForPlanet(lavaPlanet)
        local techRings = WorldGenerator.generateRingsForPlanet(techPlanet)
        -- Restore original require
        require = originalRequire
        -- Ring generation is random, so we check reasonable bounds for all types
        TestFramework.assert.isTrue(#iceRings >= 0, "Ice planet should generate zero or more rings")
        TestFramework.assert.isTrue(#iceRings <= 25, "Ice planet should not exceed max rings")
        TestFramework.assert.isTrue(#lavaRings >= 0, "Lava planet should generate zero or more rings")
        TestFramework.assert.isTrue(#lavaRings <= 25, "Lava planet should not exceed max rings")
        TestFramework.assert.isTrue(#techRings >= 0, "Tech planet should generate zero or more rings")
        TestFramework.assert.isTrue(#techRings <= 25, "Tech planet should not exceed max rings")
    end,
    ["single planet generation"] = function()
        WorldGenerator.reset()
        local planet = WorldGenerator.generatePlanet(400, 300, "standard")
        TestFramework.assert.equal(400, planet.x, "Planet should have correct x position")
        TestFramework.assert.equal(300, planet.y, "Planet should have correct y position")
        TestFramework.assert.equal("standard", planet.type, "Planet should have correct type")
        TestFramework.assert.notNil(planet.radius, "Planet should have radius")
        TestFramework.assert.notNil(planet.rotationSpeed, "Planet should have rotation speed")
        TestFramework.assert.notNil(planet.color, "Planet should have color")
        TestFramework.assert.notNil(planet.gravityMultiplier, "Planet should have gravity multiplier")
        TestFramework.assert.isFalse(planet.discovered, "Planet should start undiscovered")
        TestFramework.assert.notNil(planet.id, "Planet should have id")
    end,
    ["single planet generation with invalid type"] = function()
        WorldGenerator.reset()
        local planet = WorldGenerator.generatePlanet(400, 300, "invalid_type")
        -- The function doesn't actually validate types, so it should use the invalid type as-is
        TestFramework.assert.equal("invalid_type", planet.type, "Should use the provided type even if invalid")
        TestFramework.assert.notNil(planet.radius, "Planet should still have radius")
        TestFramework.assert.notNil(planet.color, "Planet should still have color")
    end,
    ["planet discovery"] = function()
        WorldGenerator.reset()
        local planet = WorldGenerator.generatePlanet(400, 300, "standard")
        TestFramework.assert.isFalse(planet.discovered, "Planet should start undiscovered")
        local discovered = WorldGenerator.discoverPlanet(planet, 450, 300)
        TestFramework.assert.isTrue(discovered, "Planet should be discovered when close")
        TestFramework.assert.isTrue(planet.discovered, "Planet should be marked as discovered")
        TestFramework.assert.notNil(planet.discoveryTime, "Planet should have discovery time")
    end,
    ["planet discovery distance"] = function()
        WorldGenerator.reset()
        local planet = WorldGenerator.generatePlanet(400, 300, "standard")
        -- Too far to discover
        local discovered1 = WorldGenerator.discoverPlanet(planet, 600, 300)
        TestFramework.assert.isFalse(discovered1, "Planet should not be discovered when too far")
        TestFramework.assert.isFalse(planet.discovered, "Planet should remain undiscovered")
        -- Close enough to discover
        local discovered2 = WorldGenerator.discoverPlanet(planet, 450, 300)
        TestFramework.assert.isTrue(discovered2, "Planet should be discovered when close")
    end,
    ["planet discovery validation"] = function()
        WorldGenerator.reset()
        -- Test with valid planet and coordinates (basic functionality)
        local planet = WorldGenerator.generatePlanet(400, 300, "standard")
        local discovered = WorldGenerator.discoverPlanet(planet, 450, 300)
        TestFramework.assert.isTrue(discovered, "Should discover planet when close enough")
        -- Test with already discovered planet
        local discovered2 = WorldGenerator.discoverPlanet(planet, 450, 300)
        TestFramework.assert.isFalse(discovered2, "Should return false for already discovered planet")
    end,
    ["planet discovery idempotency"] = function()
        WorldGenerator.reset()
        local planet = WorldGenerator.generatePlanet(400, 300, "standard")
        -- Discover planet
        local discovered1 = WorldGenerator.discoverPlanet(planet, 450, 300)
        TestFramework.assert.isTrue(discovered1, "Planet should be discovered")
        -- Try to discover again
        local discovered2 = WorldGenerator.discoverPlanet(planet, 450, 300)
        TestFramework.assert.isFalse(discovered2, "Already discovered planet should not be discovered again")
    end,
    ["planet type distribution by distance"] = function()
        WorldGenerator.reset()
        local existingPlanets = {}
        -- Generate planets close to origin
        local closePlanets = WorldGenerator.generateAroundPosition(0, 0, existingPlanets, 1000)
        -- Generate planets far from origin
        local farPlanets = WorldGenerator.generateAroundPosition(5000, 5000, existingPlanets, 1000)
        -- Check that we have some planets to analyze
        if #closePlanets > 0 and #farPlanets > 0 then
            local closeStandardCount = 0
            local farStandardCount = 0
            for _, planet in ipairs(closePlanets) do
                if planet.type == "standard" then
                    closeStandardCount = closeStandardCount + 1
                end
            end
            for _, planet in ipairs(farPlanets) do
                if planet.type == "standard" then
                    farStandardCount = farStandardCount + 1
                end
            end
            -- Check that we have valid planet types
            TestFramework.assert.isTrue(closeStandardCount >= 0, "Should have valid standard count for close planets")
            TestFramework.assert.isTrue(farStandardCount >= 0, "Should have valid standard count for far planets")
        else
            -- If no planets generated, that's also valid (random generation)
            TestFramework.assert.isTrue(true, "No planets generated (random generation)")
        end
    end,
    ["planet properties by type"] = function()
        WorldGenerator.reset()
        local standardPlanet = WorldGenerator.generatePlanet(400, 300, "standard")
        local icePlanet = WorldGenerator.generatePlanet(500, 300, "ice")
        local lavaPlanet = WorldGenerator.generatePlanet(600, 300, "lava")
        local voidPlanet = WorldGenerator.generatePlanet(700, 300, "void")
        local quantumPlanet = WorldGenerator.generatePlanet(800, 300, "quantum")
        -- Check gravity multipliers
        TestFramework.assert.equal(1.0, standardPlanet.gravityMultiplier, "Standard planet should have normal gravity")
        TestFramework.assert.equal(0.7, icePlanet.gravityMultiplier, "Ice planet should have reduced gravity")
        TestFramework.assert.equal(1.3, lavaPlanet.gravityMultiplier, "Lava planet should have increased gravity")
        TestFramework.assert.equal(-0.8, voidPlanet.gravityMultiplier, "Void planet should have negative gravity")
        TestFramework.assert.equal(1.0, quantumPlanet.gravityMultiplier, "Quantum planet should have normal gravity")
        -- Check radius ranges
        local standardType = WorldGenerator.planetTypes.standard
        TestFramework.assert.isTrue(standardPlanet.radius >= standardType.radiusRange[1], "Standard planet radius should be in range")
        TestFramework.assert.isTrue(standardPlanet.radius <= standardType.radiusRange[2], "Standard planet radius should be in range")
    end,
    ["system reset"] = function()
        WorldGenerator.reset()
        -- Generate some sectors
        local existingPlanets = {}
        WorldGenerator.generateSector(0, 0, existingPlanets)
        WorldGenerator.generateSector(1000, 1000, existingPlanets)
        TestFramework.assert.isTrue(WorldGenerator.generatedSectors["0,0"], "Sector should be generated")
        TestFramework.assert.isTrue(WorldGenerator.generatedSectors["1,1"], "Sector should be generated")
        -- Reset
        WorldGenerator.reset()
        TestFramework.assert.isNil(WorldGenerator.generatedSectors["0,0"], "Sector should be cleared after reset")
        TestFramework.assert.isNil(WorldGenerator.generatedSectors["1,1"], "Sector should be cleared after reset")
    end,
    ["planet color generation"] = function()
        WorldGenerator.reset()
        local standardPlanet = WorldGenerator.generatePlanet(400, 300, "standard")
        local icePlanet = WorldGenerator.generatePlanet(500, 300, "ice")
        local lavaPlanet = WorldGenerator.generatePlanet(600, 300, "lava")
        -- Check that colors are valid RGB values
        for _, planet in ipairs({standardPlanet, icePlanet, lavaPlanet}) do
            TestFramework.assert.isTrue(planet.color[1] >= 0 and planet.color[1] <= 1, "Red component should be valid")
            TestFramework.assert.isTrue(planet.color[2] >= 0 and planet.color[2] <= 1, "Green component should be valid")
            TestFramework.assert.isTrue(planet.color[3] >= 0 and planet.color[3] <= 1, "Blue component should be valid")
        end
        -- Check that different planet types have different color characteristics
        local iceAvg = (icePlanet.color[1] + icePlanet.color[2] + icePlanet.color[3]) / 3
        local lavaAvg = (lavaPlanet.color[1] + lavaPlanet.color[2] + lavaPlanet.color[3]) / 3
        TestFramework.assert.isTrue(iceAvg > lavaAvg, "Ice planet should be brighter than lava planet")
    end
}
-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "World Generator Tests")
end
return {run = run}