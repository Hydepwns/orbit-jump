-- Test file for Module Loader
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["test init module with valid module"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Mock a simple module
        local mockModule = {
            init = function()
                return true
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should successfully load and init module")
    end,

    ["test init module without init function"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Mock a module without init function
        local mockModule = {
            someFunction = function() end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should successfully load module without init")
    end,

    ["test init module with failing require"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Mock require to fail
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.failing_module" then
                error("Module not found")
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("failing_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isFalse(success, "Should fail when require fails")
    end,

    ["test init module with failing init function"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Mock a module with failing init function
        local mockModule = {
            init = function()
                error("Init failed")
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isFalse(success, "Should fail when init function fails")
    end,

    ["test init module with init function that returns false"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Mock a module with init function that returns false
        local mockModule = {
            init = function()
                return false
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isFalse(success, "Should fail when init function returns false")
    end,

    ["test init module with init function and arguments"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local initArgs = {}
        local mockModule = {
            init = function(arg1, arg2, arg3)
                initArgs = {arg1, arg2, arg3}
                return true
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init", "arg1", "arg2", "arg3")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should successfully init module with arguments")
        TestFramework.assert.equal("arg1", initArgs[1], "Should pass first argument")
        TestFramework.assert.equal("arg2", initArgs[2], "Should pass second argument")
        TestFramework.assert.equal("arg3", initArgs[3], "Should pass third argument")
    end,

    ["test init module with non-existent init function"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Mock a module without the specified init function
        local mockModule = {
            otherFunction = function() end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should succeed when init function doesn't exist")
    end,

    ["test init module with nil init function name"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local mockModule = {
            init = function()
                return true
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", nil)
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should succeed with nil init function name")
    end,

    ["test init module with empty init function name"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local mockModule = {
            init = function()
                return true
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should succeed with empty init function name")
    end,

    ["test init module with complex module structure"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local mockModule = {
            init = function(config)
                config.initialized = true
                return true
            end,
            getConfig = function()
                return {initialized = false}
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local config = {initialized = false}
        local success = ModuleLoader.initModule("test_module", "init", config)
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should handle complex module structure")
        TestFramework.assert.isTrue(config.initialized, "Should modify passed config")
    end,

    ["test init module with multiple arguments of different types"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local receivedArgs = {}
        local mockModule = {
            init = function(str, num, tab, bool)
                receivedArgs = {str, num, tab, bool}
                return true
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local testTable = {key = "value"}
        local success = ModuleLoader.initModule("test_module", "init", "string", 42, testTable, true)
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should handle multiple argument types")
        TestFramework.assert.equal("string", receivedArgs[1], "Should pass string argument")
        TestFramework.assert.equal(42, receivedArgs[2], "Should pass number argument")
        TestFramework.assert.equal(testTable, receivedArgs[3], "Should pass table argument")
        TestFramework.assert.equal(true, receivedArgs[4], "Should pass boolean argument")
    end,

    ["test init module with init function that returns multiple values"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local mockModule = {
            init = function()
                return true, "success", 123
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isTrue(success, "Should handle init function returning multiple values")
    end,

    ["test init module with init function that returns nil"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        local mockModule = {
            init = function()
                return nil
            end
        }
        
        -- Mock require to return our module
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.test_module" then
                return mockModule
            end
            return originalRequire(modulePath)
        end
        
        local success = ModuleLoader.initModule("test_module", "init")
        
        -- Restore require
        require = originalRequire
        
        TestFramework.assert.isFalse(success, "Should fail when init function returns nil")
    end,

    ["test module loader integration with error handler"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Reset call tracking
        TestFramework.utils.resetCalls()
        
        -- Mock require to fail
        local originalRequire = require
        require = function(modulePath)
            if modulePath == "src.integration_test" then
                error("Integration test error")
            end
            return originalRequire(modulePath)
        end
        
        ModuleLoader.initModule("integration_test", "init")
        
        -- Restore require
        require = originalRequire
        
        -- Should have logged the error
        TestFramework.assert.calledAtLeast("error", 1, "Should log error through integration")
    end,

    ["test module loader with real utils module"] = function()
        local ModuleLoader = Utils.require("src.utils.module_loader")
        
        -- Test with a real module that exists
        local success = ModuleLoader.initModule("utils.utils")
        
        TestFramework.assert.isTrue(success, "Should load real utils module")
    end
}

return tests 