-- Test for SaveSystem Registry Pattern
-- Verifies the new dependency injection architecture

local function run()
    local TestFramework = require("tests.test_framework")
    local Utils = require("src.utils.utils")
    
    -- Clear module cache to get fresh instances
    Utils.clearModuleCache()
    
    -- Setup mocks
    local Mocks = require("tests.mocks")
    Mocks.setup()
    
    -- Get fresh SaveSystem instance
    local SaveSystem = require("src.systems.save_system")
    
    -- Clear any existing registrations and set up mock systems globally
    SaveSystem.saveables = {}
    
    -- Create mock systems with serialize/deserialize
    local MockSystem1 = {
        data = { value = 42, name = "test" },
        serialize = function()
            return { value = MockSystem1.data.value, name = MockSystem1.data.name }
        end,
        deserialize = function(data)
            MockSystem1.data.value = data.value
            MockSystem1.data.name = data.name
        end
    }
    
    local MockSystem2 = {
        items = { "apple", "banana" },
        serialize = function()
            return { items = MockSystem2.items }
        end,
        deserialize = function(data)
            MockSystem2.items = data.items
        end
    }
    
    local function testRegistry()
        -- Test registration
        local success1 = SaveSystem.registerSaveable("system1", MockSystem1)
        local success2 = SaveSystem.registerSaveable("system2", MockSystem2)
        
        TestFramework.utils.assertTrue(success1, "Should register MockSystem1")
        TestFramework.utils.assertTrue(success2, "Should register MockSystem2")
        TestFramework.utils.assertTrue(Utils.tableLength(SaveSystem.saveables) == 2, "Should have 2 registered systems")
        
        print("✅ Registry registration works")
    end
    
    local function testSaveDataCollection()
        local saveData = SaveSystem.collectSaveData()
        
        TestFramework.utils.assertTrue(saveData.version, "Save data should have version")
        TestFramework.utils.assertTrue(saveData.timestamp, "Save data should have timestamp")
        TestFramework.utils.assertTrue(saveData.systems, "Save data should have systems table")
        TestFramework.utils.assertTrue(saveData.systems.system1, "Should have system1 data")
        TestFramework.utils.assertTrue(saveData.systems.system2, "Should have system2 data")
        TestFramework.utils.assertTrue(saveData.systems.system1.value == 42, "Should preserve system1 value")
        TestFramework.utils.assertTrue(saveData.systems.system1.name == "test", "Should preserve system1 name")
        TestFramework.utils.assertTrue(#saveData.systems.system2.items == 2, "Should preserve system2 items")
        
        print("✅ Save data collection works")
        return saveData
    end
    
    local function testSaveDataApplication(saveData)
        -- Modify the mock systems to different values
        MockSystem1.data.value = 999
        MockSystem1.data.name = "changed"
        MockSystem2.items = { "different" }
        
        -- Apply the save data
        SaveSystem.applySaveData(saveData)
        
        -- Verify restoration
        TestFramework.utils.assertTrue(MockSystem1.data.value == 42, "Should restore system1 value")
        TestFramework.utils.assertTrue(MockSystem1.data.name == "test", "Should restore system1 name")
        TestFramework.utils.assertTrue(#MockSystem2.items == 2, "Should restore system2 items count")
        TestFramework.utils.assertTrue(MockSystem2.items[1] == "apple", "Should restore system2 first item")
        
        print("✅ Save data application works")
    end
    
    local function testInvalidSystem()
        local InvalidSystem = {
            -- Missing serialize/deserialize methods
            data = {}
        }
        
        local success = SaveSystem.registerSaveable("invalid", InvalidSystem)
        TestFramework.utils.assertTrue(not success, "Should reject system without serialize method")
        
        print("✅ Invalid system rejection works")
    end
    
    local function testSystemError()
        local ErrorSystem = {
            serialize = function()
                error("Simulated serialization error")
            end,
            deserialize = function(data)
                -- This should work fine
            end
        }
        
        SaveSystem.registerSaveable("error_system", ErrorSystem)
        
        -- This should not crash, but log an error
        local saveData = SaveSystem.collectSaveData()
        TestFramework.utils.assertTrue(not saveData.systems.error_system, "Should not include errored system data")
        
        print("✅ Error handling works")
    end
    
    local function testLegacyCompatibility()
        -- Create legacy format save data
        local legacyData = {
            version = 1,
            timestamp = os.time(),
            player = {
                totalScore = 1000,
                gameTime = 3600
            },
            upgrades = {},
            achievements = {}
        }
        
        -- Create a system that supports legacy deserialization
        local LegacySystem = {
            score = 0,
            serialize = function()
                return { score = LegacySystem.score }
            end,
            deserialize = function(data)
                LegacySystem.score = data.score
            end,
            deserializeLegacy = function(saveData)
                if saveData.player then
                    LegacySystem.score = saveData.player.totalScore or 0
                end
            end
        }
        
        SaveSystem.registerSaveable("legacy_test", LegacySystem)
        
        -- Apply legacy data
        SaveSystem.applySaveData(legacyData)
        
        TestFramework.utils.assertTrue(LegacySystem.score == 1000, "Should apply legacy data correctly")
        
        print("✅ Legacy compatibility works")
    end
    
    -- Run all tests
    testRegistry()
    testSaveDataCollection()
    local saveData = testSaveDataCollection()
    testSaveDataApplication(saveData)
    testInvalidSystem()
    testSystemError()
    testLegacyCompatibility()
    
    print("✅ All SaveSystem registry tests passed!")
end

return { run = run }