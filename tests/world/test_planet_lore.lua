-- Tests for Planet Lore System
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.require("tests.test_framework")
local Mocks = Utils.require("tests.mocks")

Mocks.setup()

local PlanetLore = Utils.require("src.systems.planet_lore")

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["planet lore initialization"] = function()
        PlanetLore.init()
        TestFramework.utils.assertNotNil(PlanetLore.loreEntries, "Lore entries should be initialized")
        TestFramework.utils.assertNotNil(PlanetLore.discoveredLore, "Discovered lore tracking should be initialized")
    end,
    
    ["lore type definitions"] = function()
        PlanetLore.init()
        
        TestFramework.utils.assertNotNil(PlanetLore.loreTypes, "Lore types should be defined")
        TestFramework.utils.assertNotNil(PlanetLore.loreTypes.ice, "Ice planet lore should exist")
        TestFramework.utils.assertNotNil(PlanetLore.loreTypes.lava, "Lava planet lore should exist")
        TestFramework.utils.assertNotNil(PlanetLore.loreTypes.tech, "Tech planet lore should exist")
        TestFramework.utils.assertNotNil(PlanetLore.loreTypes.void, "Void planet lore should exist")
        TestFramework.utils.assertNotNil(PlanetLore.loreTypes.quantum, "Quantum planet lore should exist")
    end,
    
    ["generate lore for planet"] = function()
        PlanetLore.init()
        
        local planet = {
            id = "test_planet_1",
            type = "ice",
            x = 100,
            y = 200,
            radius = 50
        }
        
        local lore = PlanetLore.generateLore(planet)
        TestFramework.utils.assertNotNil(lore, "Should generate lore for planet")
        TestFramework.utils.assertNotNil(lore.title, "Lore should have title")
        TestFramework.utils.assertNotNil(lore.description, "Lore should have description")
        TestFramework.utils.assertEqual("ice", lore.type, "Lore type should match planet type")
    end,
    
    ["discover planet lore"] = function()
        PlanetLore.init()
        
        local planet = {
            id = "discover_test",
            type = "tech",
            discovered = false
        }
        
        local loreUnlocked = PlanetLore.discoverPlanet(planet)
        TestFramework.utils.assertTrue(loreUnlocked, "Should unlock lore for new planet")
        TestFramework.utils.assertTrue(PlanetLore.isDiscovered(planet.id), "Planet should be marked as discovered")
        
        -- Try discovering again
        loreUnlocked = PlanetLore.discoverPlanet(planet)
        TestFramework.utils.assertFalse(loreUnlocked, "Should not unlock lore twice")
    end,
    
    ["get lore for planet"] = function()
        PlanetLore.init()
        
        local planet = {
            id = "lore_test",
            type = "void"
        }
        
        -- Generate and discover
        PlanetLore.generateLore(planet)
        PlanetLore.discoverPlanet(planet)
        
        local lore = PlanetLore.getLore(planet.id)
        TestFramework.utils.assertNotNil(lore, "Should retrieve lore for discovered planet")
        TestFramework.utils.assertEqual("void", lore.type, "Retrieved lore should match planet type")
    end,
    
    ["lore collection progress"] = function()
        PlanetLore.init()
        
        -- Discover some planets
        for i = 1, 5 do
            local planet = {
                id = "progress_test_" .. i,
                type = i <= 2 and "ice" or "lava"
            }
            PlanetLore.generateLore(planet)
            PlanetLore.discoverPlanet(planet)
        end
        
        local progress = PlanetLore.getProgress()
        TestFramework.utils.assertEqual(5, progress.discovered, "Should track discovered count")
        TestFramework.utils.assertTrue(progress.percentage > 0, "Should calculate progress percentage")
    end,
    
    ["special lore entries"] = function()
        PlanetLore.init()
        
        -- Create a special planet
        local planet = {
            id = "special_planet",
            type = "quantum",
            special = true
        }
        
        local lore = PlanetLore.generateLore(planet)
        TestFramework.utils.assertNotNil(lore.special, "Special planets should have special lore")
        TestFramework.utils.assertTrue(#lore.description > 50, "Special lore should be detailed")
    end,
    
    ["lore categories"] = function()
        PlanetLore.init()
        
        local categories = PlanetLore.getCategories()
        TestFramework.utils.assertNotNil(categories, "Should return lore categories")
        TestFramework.utils.assertTrue(#categories > 0, "Should have multiple categories")
        
        -- Check if standard planet types are categories
        local hasIce = false
        for _, cat in ipairs(categories) do
            if cat == "ice" then hasIce = true end
        end
        TestFramework.utils.assertTrue(hasIce, "Should include ice as category")
    end,
    
    ["lore by category"] = function()
        PlanetLore.init()
        
        -- Generate some ice planet lore
        for i = 1, 3 do
            local planet = {
                id = "ice_planet_" .. i,
                type = "ice"
            }
            PlanetLore.generateLore(planet)
            PlanetLore.discoverPlanet(planet)
        end
        
        local iceLore = PlanetLore.getLoreByCategory("ice")
        TestFramework.utils.assertEqual(3, #iceLore, "Should return all ice planet lore")
    end,
    
    ["lore hints for undiscovered planets"] = function()
        PlanetLore.init()
        
        local planet = {
            id = "hint_test",
            type = "tech",
            discovered = false
        }
        
        PlanetLore.generateLore(planet)
        
        local hint = PlanetLore.getHint(planet.id)
        TestFramework.utils.assertNotNil(hint, "Should provide hint for undiscovered planet")
        TestFramework.utils.assertTrue(#hint > 10, "Hint should have content")
    end,
    
    ["save and load lore data"] = function()
        PlanetLore.init()
        
        -- Discover some planets
        local planets = {
            {id = "save_test_1", type = "ice"},
            {id = "save_test_2", type = "lava"}
        }
        
        for _, planet in ipairs(planets) do
            PlanetLore.generateLore(planet)
            PlanetLore.discoverPlanet(planet)
        end
        
        -- Save
        local saveData = PlanetLore.getSaveData()
        TestFramework.utils.assertNotNil(saveData, "Should generate save data")
        
        -- Reset and load
        PlanetLore.init()
        PlanetLore.loadSaveData(saveData)
        
        TestFramework.utils.assertTrue(PlanetLore.isDiscovered("save_test_1"), "First planet should be restored")
        TestFramework.utils.assertTrue(PlanetLore.isDiscovered("save_test_2"), "Second planet should be restored")
    end,
    
    ["lore viewer state"] = function()
        PlanetLore.init()
        
        -- Open viewer
        PlanetLore.openViewer()
        TestFramework.utils.assertTrue(PlanetLore.isViewerOpen(), "Viewer should be open")
        
        -- Select entry
        local planet = {id = "viewer_test", type = "void"}
        PlanetLore.generateLore(planet)
        PlanetLore.discoverPlanet(planet)
        
        PlanetLore.selectEntry(planet.id)
        local selected = PlanetLore.getSelectedEntry()
        TestFramework.utils.assertEqual(planet.id, selected.planetId, "Should select correct entry")
        
        -- Close viewer
        PlanetLore.closeViewer()
        TestFramework.utils.assertFalse(PlanetLore.isViewerOpen(), "Viewer should be closed")
    end,
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Planet Lore Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("planet_lore", 12) -- All major functions tested
    
    return success
end

return {run = run}