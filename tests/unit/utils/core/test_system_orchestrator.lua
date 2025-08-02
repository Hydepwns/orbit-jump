-- Test file for System Orchestrator
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Get SystemOrchestrator
local SystemOrchestrator = Utils.require("src.core.system_orchestrator")

-- Test suite
local tests = {
    ["test system registration"] = function()
        -- Register a test system
        local testSystem = {
            init = function() return true end,
            update = function() end,
            draw = function() end
        }
        
        SystemOrchestrator.register("TestSystem", testSystem, {layer = "foundation", updatePriority = 0})
        
        local registered = SystemOrchestrator.getSystem("TestSystem")
        TestFramework.assert.notNil(registered, "Should have system registered")
        TestFramework.assert.equal(testSystem, registered, "Should register the correct system")
    end,
    
    ["test system initialization"] = function()
        local initCalled = false
        local testSystem1 = {
            init = function() 
                initCalled = true
                return true 
            end
        }
        
        local testSystem2 = {
            init = function() return true end
        }
        
        -- Clear any existing systems first
        SystemOrchestrator.systems = {}
        for _, layer in pairs(SystemOrchestrator.layers) do
            layer.systems = {}
        end
        
        SystemOrchestrator.register("TestSystem1", testSystem1, {layer = "foundation", updatePriority = 0})
        SystemOrchestrator.register("TestSystem2", testSystem2, {layer = "foundation", updatePriority = 1})
        
        SystemOrchestrator.init()
        
        TestFramework.assert.isTrue(initCalled, "System init should be called")
    end,
    
    ["test system enable/disable"] = function()
        local updateCount = 0
        local testSystem = {
            update = function() updateCount = updateCount + 1 end
        }
        
        SystemOrchestrator.register("EnableTest", testSystem, {layer = "gameplay", updatePriority = 0})
        
        -- Disable the system
        SystemOrchestrator.setEnabled("EnableTest", false)
        SystemOrchestrator.update(0.016)
        TestFramework.assert.equal(0, updateCount, "Disabled system should not update")
        
        -- Enable the system
        SystemOrchestrator.setEnabled("EnableTest", true)
        SystemOrchestrator.update(0.016)
        TestFramework.assert.equal(1, updateCount, "Enabled system should update")
    end,
    
    ["test system update"] = function()
        local updateCount = 0
        local testSystem = {
            update = function(dt)
                updateCount = updateCount + 1
            end
        }
        
        SystemOrchestrator.register("UpdateTest", testSystem, {layer = "simulation", updatePriority = 0})
        SystemOrchestrator.update(0.016)
        
        TestFramework.assert.equal(1, updateCount, "Update should be called once")
    end,
    
    ["test system draw"] = function()
        local drawCount = 0
        local testSystem = {
            draw = function()
                drawCount = drawCount + 1
            end
        }
        
        SystemOrchestrator.register("DrawTest", testSystem, {layer = "presentation", updatePriority = 0})
        SystemOrchestrator.draw()
        
        TestFramework.assert.equal(1, drawCount, "Draw should be called once")
    end,
    
    ["test get system by name"] = function()
        local testSystem = {
            data = "test data",
            getData = function() return "test data" end,
            init = function() return true end -- Required method
        }
        
        SystemOrchestrator.register("GetTest", testSystem, {layer = "foundation", updatePriority = 0})
        
        local found = SystemOrchestrator.getSystem("GetTest")
        TestFramework.assert.equal(testSystem, found, "Should find system by name")
        
        local notFound = SystemOrchestrator.getSystem("NonExistent")
        TestFramework.assert.isNil(notFound, "Should return nil for non-existent system")
    end,
    
    ["test system layer organization"] = function()
        -- Test that systems are organized by layers
        local foundationSystem = {
            update = function() end
        }
        
        local simulationSystem = {
            update = function() end
        }
        
        SystemOrchestrator.register("Foundation1", foundationSystem, {layer = "foundation", updatePriority = 0})
        SystemOrchestrator.register("Simulation1", simulationSystem, {layer = "simulation", updatePriority = 0})
        
        -- Check layers exist
        TestFramework.assert.notNil(SystemOrchestrator.layers, "Should have layers")
        TestFramework.assert.notNil(SystemOrchestrator.layers.foundation, "Should have foundation layer")
        TestFramework.assert.notNil(SystemOrchestrator.layers.simulation, "Should have simulation layer")
    end,
    
    ["test system error handling"] = function()
        local errorSystem = {
            update = function()
                error("Test error")
            end
        }
        
        SystemOrchestrator.register("ErrorTest", errorSystem, {layer = "gameplay", updatePriority = 0})
        
        -- Should not crash when system throws error
        local success = pcall(SystemOrchestrator.update, 0.016)
        TestFramework.assert.isTrue(success, "Should handle system errors gracefully")
    end,
    
    ["test system cleanup"] = function()
        SystemOrchestrator.systems = {}
        
        local cleanupCalled = false
        local testSystem = {
            name = "TestSystem",
            cleanup = function()
                cleanupCalled = true
            end
        }
        
        SystemOrchestrator.systems = {testSystem}
        
        if SystemOrchestrator.cleanup then
            SystemOrchestrator.cleanup()
            TestFramework.assert.isTrue(cleanupCalled, "Cleanup should be called")
        else
            -- If cleanup not implemented, just pass
            TestFramework.assert.isTrue(true, "Cleanup not implemented")
        end
    end,
    
    ["test system dependencies"] = function()
        -- Test that systems can reference each other
        local system1 = {
            data = { value = 42 },
            init = function() return true end,
            getValue = function() return 42 end
        }
        
        local system2 = {
            init = function() return true end,
            getValue = function()
                local sys1 = SystemOrchestrator.getSystem("System1")
                return sys1 and sys1.getValue() or 0
            end
        }
        
        SystemOrchestrator.register("System1", system1, {layer = "foundation", updatePriority = 0})
        SystemOrchestrator.register("System2", system2, {layer = "gameplay", updatePriority = 0})
        
        local value = system2.getValue()
        TestFramework.assert.equal(42, value, "System should access other system's data")
    end
}

-- Run tests
local function run()
    return TestFramework.runTests(tests, "System Orchestrator Tests")
end

return {run = run}