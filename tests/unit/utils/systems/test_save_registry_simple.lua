-- Simple test to verify SaveSystem registry pattern works
local Utils = require("src.utils.utils")
local Mocks = require("tests.mocks")
Mocks.setup()
Utils.clearModuleCache()
local SaveSystem = require("src.systems.save_system")
SaveSystem.saveables = {}
-- Test system
local TestSystem = {
    data = { score = 100, name = "player" }
}
function TestSystem:serialize()
    return { score = self.data.score, name = self.data.name }
end
function TestSystem:deserialize(data)
    self.data.score = data.score
    self.data.name = data.name
end
-- Test registration
local success = SaveSystem.registerSaveable("test", TestSystem)
assert(success, "Should register system")
-- Test save data collection
local saveData = SaveSystem.collectSaveData()
assert(saveData.systems, "Should have systems")
assert(saveData.systems.test, "Should have test system data")
assert(saveData.systems.test.score == 100, "Should preserve score")
-- Test restoration
TestSystem.data.score = 999  -- Change it
SaveSystem.applySaveData(saveData)
assert(TestSystem.data.score == 100, "Should restore score")
print("✅ SaveSystem registry pattern works!")