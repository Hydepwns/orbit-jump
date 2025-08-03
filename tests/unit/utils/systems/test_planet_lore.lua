-- Test file for Planet Lore System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
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
-- Mock love.graphics
love.graphics.getWidth = function() return 800 end
love.graphics.getHeight = function() return 600 end
love.graphics.setColor = function() end
love.graphics.rectangle = function() end
love.graphics.setLineWidth = function() end
love.graphics.circle = function() end
love.graphics.print = function() end
love.graphics.printf = function() end
love.graphics.getFont = function() return {} end
love.graphics.setFont = function() end
-- Initialize test framework
TestFramework.init()
-- Clear module cache before tests
Utils.moduleCache["src.systems.planet_lore"] = nil
-- Test suite
local tests = {
    ["test lore structure"] = function()
        -- Clear module cache to ensure fresh state
        Utils.moduleCache["src.systems.planet_lore"] = nil
        local PlanetLore = Utils.require("src.systems.planet_lore")
        TestFramework.assert.notNil(PlanetLore.entries, "Entries should exist")
        TestFramework.assert.notNil(PlanetLore.entries.ice, "Ice entries")
        TestFramework.assert.notNil(PlanetLore.entries.lava, "Lava entries")
        TestFramework.assert.notNil(PlanetLore.entries.tech, "Tech entries")
        TestFramework.assert.notNil(PlanetLore.entries.void, "Void entries")
        TestFramework.assert.notNil(PlanetLore.entries.standard, "Standard entries")
        TestFramework.assert.notNil(PlanetLore.specialEntries, "Special entries")
        -- Check ice entries
        TestFramework.assert.equal(3, #PlanetLore.entries.ice, "3 ice entries")
        TestFramework.assert.equal("ice_1", PlanetLore.entries.ice[1].id)
        TestFramework.assert.notNil(PlanetLore.entries.ice[1].discovered, "Should have discovered field")
    end,
    ["test discover random lore"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Reset all entries
        for _, entry in ipairs(PlanetLore.entries.ice) do
            entry.discovered = false
        end
        -- Mock random
        math.random = function(n) return 1 end
        local entry = PlanetLore.discoverRandomLore("ice")
        TestFramework.assert.notNil(entry, "Should discover entry")
        TestFramework.assert.equal("ice_1", entry.id, "Should be first ice entry")
        TestFramework.assert.equal(true, entry.discovered, "Should be marked discovered")
        TestFramework.assert.equal(entry, PlanetLore.currentDisplay, "Should be displayed")
    end,
    ["test discover all entries"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Reset lava entries
        for _, entry in ipairs(PlanetLore.entries.lava) do
            entry.discovered = false
        end
        local discovered = {}
        math.random = function(n) return 1 end
        -- Discover all lava entries
        for i = 1, 3 do
            local entry = PlanetLore.discoverRandomLore("lava")
            TestFramework.assert.notNil(entry, "Should discover entry " .. i)
            discovered[entry.id] = true
        end
        -- Try to discover more - should return nil
        local entry = PlanetLore.discoverRandomLore("lava")
        TestFramework.assert.isNil(entry, "No more entries to discover")
        -- Check all were discovered
        local count = 0
        for _ in pairs(discovered) do count = count + 1 end
        TestFramework.assert.equal(3, count, "All 3 entries discovered")
    end,
    ["test invalid planet type"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        local entry = PlanetLore.discoverRandomLore("invalid")
        TestFramework.assert.isNil(entry, "Should return nil for invalid type")
    end,
    ["test special entries unlocked"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        local AchievementSystem = Utils.moduleCache["src.systems.achievement_system"]
        -- Reset special entries
        for _, entry in ipairs(PlanetLore.specialEntries) do
            entry.discovered = false
        end
        -- Unlock achievement
        AchievementSystem.achievements.ring_collector.unlocked = true
        local entry = PlanetLore.checkSpecialEntries()
        TestFramework.assert.notNil(entry, "Should unlock special entry")
        TestFramework.assert.equal("special_1", entry.id)
        TestFramework.assert.equal(true, entry.discovered)
    end,
    ["test special entries not unlocked"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        local AchievementSystem = Utils.moduleCache["src.systems.achievement_system"]
        -- Reset
        for _, entry in ipairs(PlanetLore.specialEntries) do
            entry.discovered = false
        end
        AchievementSystem.achievements.ring_collector.unlocked = false
        local entry = PlanetLore.checkSpecialEntries()
        TestFramework.assert.isNil(entry, "Should not unlock without achievement")
    end,
    ["test display functionality"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        local testEntry = {
            id = "test",
            title = "Test",
            text = "Test text"
        }
        PlanetLore.display(testEntry)
        TestFramework.assert.equal(testEntry, PlanetLore.currentDisplay)
        TestFramework.assert.equal(8.0, PlanetLore.displayTimer)
        TestFramework.assert.equal(0, PlanetLore.fadeIn)
    end,
    ["test update fade in"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        PlanetLore.currentDisplay = { id = "test" }
        PlanetLore.displayTimer = 5
        PlanetLore.fadeIn = 0
        PlanetLore.update(0.1)
        TestFramework.assert.equal(0.2, PlanetLore.fadeIn, "Fade in at 2x speed")
        TestFramework.assert.equal(4.9, PlanetLore.displayTimer)
    end,
    ["test update fade out"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        PlanetLore.currentDisplay = { id = "test" }
        PlanetLore.displayTimer = 0.5
        PlanetLore.fadeIn = 1
        PlanetLore.update(0.1)
        TestFramework.assert.equal(0.4, PlanetLore.fadeIn, "Should fade out")
        TestFramework.assert.equal(0.4, PlanetLore.displayTimer)
    end,
    ["test update remove display"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        PlanetLore.currentDisplay = { id = "test" }
        PlanetLore.displayTimer = 0.1
        PlanetLore.update(0.2)
        TestFramework.assert.isNil(PlanetLore.currentDisplay, "Display removed")
    end,
    ["test get stats"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Reset all
        for _, entries in pairs(PlanetLore.entries) do
            for _, entry in ipairs(entries) do
                entry.discovered = false
            end
        end
        for _, entry in ipairs(PlanetLore.specialEntries) do
            entry.discovered = false
        end
        -- Discover some
        PlanetLore.entries.ice[1].discovered = true
        PlanetLore.entries.lava[2].discovered = true
        PlanetLore.specialEntries[1].discovered = true
        local stats = PlanetLore.getStats()
        -- ice:3 + lava:3 + tech:3 + void:3 + standard:2 + special:3 = 17
        TestFramework.assert.equal(17, stats.total, "Total entries")
        TestFramework.assert.equal(3, stats.discovered, "Discovered entries")
        TestFramework.assert.approx(17.65, stats.percentage, 0.01, "Percentage")
    end,
    ["test save data"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Set some discovered
        PlanetLore.entries.ice[1].discovered = true
        PlanetLore.entries.tech[3].discovered = true
        PlanetLore.specialEntries[2].discovered = true
        local saveData = PlanetLore.getSaveData()
        TestFramework.assert.notNil(saveData.entries)
        TestFramework.assert.notNil(saveData.specialEntries)
        TestFramework.assert.equal(true, saveData.entries.ice["ice_1"])
        TestFramework.assert.equal(true, saveData.entries.tech["tech_3"])
        TestFramework.assert.equal(true, saveData.specialEntries["special_2"])
    end,
    ["test load save data"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Reset all
        for _, entries in pairs(PlanetLore.entries) do
            for _, entry in ipairs(entries) do
                entry.discovered = false
            end
        end
        for _, entry in ipairs(PlanetLore.specialEntries) do
            entry.discovered = false
        end
        local saveData = {
            entries = {
                ice = { ice_2 = true },
                void = { void_1 = true }
            },
            specialEntries = {
                special_3 = true
            }
        }
        PlanetLore.loadSaveData(saveData)
        TestFramework.assert.equal(true, PlanetLore.entries.ice[2].discovered)
        TestFramework.assert.equal(true, PlanetLore.entries.void[1].discovered)
        TestFramework.assert.equal(true, PlanetLore.specialEntries[3].discovered)
        TestFramework.assert.equal(false, PlanetLore.entries.ice[1].discovered)
    end,
    ["test load nil save data"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Should not crash
        PlanetLore.loadSaveData(nil)
        PlanetLore.loadSaveData({})
    end,
    ["test draw with no display"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        PlanetLore.currentDisplay = nil
        -- Should not crash
        PlanetLore.draw()
    end,
    ["test draw with display"] = function()
        local PlanetLore = Utils.require("src.systems.planet_lore")
        local rectCalls = 0
        local circleCalls = 0
        love.graphics.rectangle = function(...) rectCalls = rectCalls + 1 end
        love.graphics.circle = function(...) circleCalls = circleCalls + 1 end
        PlanetLore.currentDisplay = {
            title = "Test",
            text = "Test text"
        }
        PlanetLore.fadeIn = 1
        PlanetLore.draw()
        TestFramework.assert.equal(2, rectCalls, "Should draw 2 rectangles (bg + border)")
        TestFramework.assert.equal(1, circleCalls, "Should draw 1 circle (icon)")
    end,
    ["test lore content appropriate"] = function()
        -- Clear module cache to ensure fresh state
        Utils.moduleCache["src.systems.planet_lore"] = nil
        local PlanetLore = Utils.require("src.systems.planet_lore")
        -- Just verify lore exists and is structured properly
        local count = 0
        -- Check if entries exist
        TestFramework.assert.notNil(PlanetLore.entries, "Should have entries table")
        -- Check each planet type
        local types = {"ice", "lava", "tech", "void", "standard"}
        for _, planetType in ipairs(types) do
            local entries = PlanetLore.entries[planetType]
            TestFramework.assert.notNil(entries, "Should have entries for " .. planetType)
            -- Count entries for this type
            local typeCount = 0
            if type(entries) == "table" then
                for _, entry in ipairs(entries) do
                    typeCount = typeCount + 1
                    TestFramework.assert.notNil(entry.id, "Entry should have id")
                    TestFramework.assert.notNil(entry.title, "Entry should have title")
                    TestFramework.assert.notNil(entry.text, "Entry should have text")
                    TestFramework.assert.notNil(entry.discovered, "Entry should have discovered flag")
                    count = count + 1
                end
            end
            -- Check expected counts
            if planetType == "standard" then
                TestFramework.assert.equal(2, typeCount, "Should have 2 standard entries")
            else
                TestFramework.assert.equal(3, typeCount, "Should have 3 " .. planetType .. " entries")
            end
        end
        TestFramework.assert.equal(14, count, "Should have 14 regular lore entries")
    end
}
-- Run tests
TestFramework.runTests(tests)