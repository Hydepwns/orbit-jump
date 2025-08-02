-- Tests for Planet Lore System
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Function to get fresh PlanetLore module
local function getPlanetLore()
    -- Clear the module from cache
    package.loaded["src.systems.planet_lore"] = nil
    if Utils.moduleCache then
        Utils.moduleCache["src.systems.planet_lore"] = nil
    end
    
    -- Setup mocks
    Mocks.setup()
    
    -- Mock math.random to return valid indices
    local originalRandom = math.random
    math.random = function(n)
        if type(n) == "number" and n > 0 then
            return 1  -- Always return first index for predictable tests
        end
        return originalRandom(n)
    end
    
    -- Mock dependencies
    Utils.moduleCache["src.systems.achievement_system"] = {
        achievements = {
            ring_collector = { unlocked = false },
            void_walker = { unlocked = false },
            space_explorer = { unlocked = false }
        }
    }
    
    Utils.moduleCache["src.audio.sound_manager"] = {
        playLoreDiscovered = function() end
    }
    
    -- Load the module fresh
    local PlanetLore = require("src.systems.planet_lore")
    
    -- Initialize if available
    if PlanetLore.init then
        PlanetLore.init()
    end
    
    return PlanetLore
end

-- Test suite
local tests = {
    ["planet lore initialization"] = function()
        local PlanetLore = getPlanetLore()
        TestFramework.assert.notNil(PlanetLore.entries, "Lore entries should be initialized")
        TestFramework.assert.notNil(PlanetLore.specialEntries, "Special entries should be initialized")
    end,
    
    ["lore type definitions"] = function()
        local PlanetLore = getPlanetLore()
        
        TestFramework.assert.notNil(PlanetLore.entries, "Lore entries should be defined")
        TestFramework.assert.notNil(PlanetLore.entries.ice, "Ice planet lore should exist")
        TestFramework.assert.notNil(PlanetLore.entries.lava, "Lava planet lore should exist")
        TestFramework.assert.notNil(PlanetLore.entries.tech, "Tech planet lore should exist")
        TestFramework.assert.notNil(PlanetLore.entries.void, "Void planet lore should exist")
        TestFramework.assert.notNil(PlanetLore.entries.standard, "Standard planet lore should exist")
    end,
    
    ["generate lore for planet"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Reset ice entries
        for _, entry in ipairs(PlanetLore.entries.ice) do
            entry.discovered = false
        end
        
        local lore = PlanetLore.discoverRandomLore("ice")
        TestFramework.assert.notNil(lore, "Should discover lore for planet")
        TestFramework.assert.notNil(lore.title, "Lore should have title")
        TestFramework.assert.notNil(lore.text, "Lore should have text")
        TestFramework.assert.isTrue(lore.discovered, "Lore should be marked discovered")
    end,
    
    ["discover planet lore"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Reset tech entries
        for _, entry in ipairs(PlanetLore.entries.tech) do
            entry.discovered = false
        end
        
        local lore = PlanetLore.discoverRandomLore("tech")
        TestFramework.assert.notNil(lore, "Should unlock lore for new planet")
        TestFramework.assert.isTrue(lore.discovered, "Entry should be marked as discovered")
        
        -- Check it's truly discovered
        local techEntry = PlanetLore.entries.tech[1]
        TestFramework.assert.isTrue(techEntry.discovered, "First tech entry should be discovered")
    end,
    
    ["get lore for planet"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Reset void entries
        for _, entry in ipairs(PlanetLore.entries.void) do
            entry.discovered = false
        end
        
        -- Discover a void entry
        local lore = PlanetLore.discoverRandomLore("void")
        TestFramework.assert.notNil(lore, "Should discover void lore")
        
        -- Verify it's in the entries
        local found = false
        for _, entry in ipairs(PlanetLore.entries.void) do
            if entry.discovered and entry.id == lore.id then
                found = true
                break
            end
        end
        TestFramework.assert.isTrue(found, "Discovered lore should be in entries")
    end,
    
    ["lore collection progress"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Reset all entries
        for _, entries in pairs(PlanetLore.entries) do
            for _, entry in ipairs(entries) do
                entry.discovered = false
            end
        end
        for _, entry in ipairs(PlanetLore.specialEntries) do
            entry.discovered = false
        end
        
        -- Discover some entries
        PlanetLore.entries.ice[1].discovered = true
        PlanetLore.entries.lava[1].discovered = true
        PlanetLore.entries.tech[1].discovered = true
        
        local stats = PlanetLore.getStats()
        TestFramework.assert.equal(3, stats.discovered, "Should track discovered count")
        TestFramework.assert.isTrue(stats.percentage > 0, "Should calculate progress percentage")
    end,
    
    ["special lore entries"] = function()
        -- Clear cache and reload with proper mocks
        package.loaded["src.systems.planet_lore"] = nil
        if Utils.moduleCache then
            Utils.moduleCache["src.systems.planet_lore"] = nil
        end
        
        -- Setup mocks first
        Mocks.setup()
        
        -- Mock achievement system with unlocked achievement
        Utils.moduleCache["src.systems.achievement_system"] = {
            achievements = {
                ring_collector = { unlocked = true },
                void_walker = { unlocked = false },
                space_explorer = { unlocked = false }
            }
        }
        
        Utils.moduleCache["src.audio.sound_manager"] = {
            playLoreDiscovered = function() end
        }
        
        -- Now load PlanetLore
        local PlanetLore = require("src.systems.planet_lore")
        
        -- Reset special entries
        for _, entry in ipairs(PlanetLore.specialEntries) do
            entry.discovered = false
        end
        
        local entry = PlanetLore.checkSpecialEntries()
        TestFramework.assert.notNil(entry, "Should unlock special entry")
        TestFramework.assert.isTrue(#entry.text > 50, "Special lore should be detailed")
    end,
    
    ["lore categories"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Check that all expected categories exist
        local expectedTypes = {"ice", "lava", "tech", "void", "standard"}
        for _, planetType in ipairs(expectedTypes) do
            TestFramework.assert.notNil(PlanetLore.entries[planetType], "Should have " .. planetType .. " category")
            TestFramework.assert.isTrue(#PlanetLore.entries[planetType] > 0, planetType .. " should have entries")
        end
        
        -- Verify special entries exist too
        TestFramework.assert.isTrue(#PlanetLore.specialEntries > 0, "Should have special entries")
    end,
    
    ["lore by category"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Check ice lore count
        local iceEntries = PlanetLore.entries.ice
        TestFramework.assert.equal(3, #iceEntries, "Should have 3 ice entries")
        
        -- Verify each has required fields
        for _, entry in ipairs(iceEntries) do
            TestFramework.assert.notNil(entry.id, "Entry should have id")
            TestFramework.assert.notNil(entry.title, "Entry should have title")
            TestFramework.assert.notNil(entry.text, "Entry should have text")
        end
    end,
    
    ["lore hints for undiscovered planets"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Verify undiscovered entries exist
        local undiscoveredCount = 0
        for _, entries in pairs(PlanetLore.entries) do
            for _, entry in ipairs(entries) do
                if not entry.discovered then
                    undiscoveredCount = undiscoveredCount + 1
                end
            end
        end
        
        TestFramework.assert.isTrue(undiscoveredCount > 0, "Should have undiscovered entries")
        
        -- The hint is shown in the draw function
        TestFramework.assert.notNil(PlanetLore.draw, "Should have draw function for hints")
    end,
    
    ["save and load lore data"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Reset and discover some entries
        for _, entries in pairs(PlanetLore.entries) do
            for _, entry in ipairs(entries) do
                entry.discovered = false
            end
        end
        
        PlanetLore.entries.ice[1].discovered = true
        PlanetLore.entries.lava[2].discovered = true
        
        -- Save
        local saveData = PlanetLore.getSaveData()
        TestFramework.assert.notNil(saveData, "Should generate save data")
        TestFramework.assert.notNil(saveData.entries, "Save data should have entries")
        
        -- Reset and load
        PlanetLore = getPlanetLore()
        PlanetLore.loadSaveData(saveData)
        
        TestFramework.assert.isTrue(PlanetLore.entries.ice[1].discovered, "Ice entry should be restored")
        TestFramework.assert.isTrue(PlanetLore.entries.lava[2].discovered, "Lava entry should be restored")
    end,
    
    ["lore viewer state"] = function()
        local PlanetLore = getPlanetLore()
        
        -- Test display functionality
        local testEntry = {
            id = "test",
            title = "Test Title",
            text = "Test text content"
        }
        
        PlanetLore.display(testEntry)
        TestFramework.assert.equal(testEntry, PlanetLore.currentDisplay, "Should display entry")
        TestFramework.assert.equal(8.0, PlanetLore.displayTimer, "Display timer should be set")
        
        -- Test update reduces timer
        PlanetLore.update(1.0)
        TestFramework.assert.equal(7.0, PlanetLore.displayTimer, "Timer should decrease")
        
        -- Test display clears after timeout
        PlanetLore.update(10.0)
        TestFramework.assert.isNil(PlanetLore.currentDisplay, "Display should clear after timeout")
    end,
}

-- Run the test suite
local function run()
    -- Setup mocks and initialize framework
    Mocks.setup()
    TestFramework.init()
    
    local success = TestFramework.runTests(tests, "Planet Lore Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("planet_lore", 12) -- All major functions tested
    
    return success
end

return {run = run}