-- Test file for Error Handler
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    ["test safe call with successful function"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local testFunc = function(a, b)
            return a + b
        end
        
        local success, result = ErrorHandler.safeCall(testFunc, 5, 3)
        
        TestFramework.assert.isTrue(success, "Should return success for valid function")
        TestFramework.assert.equal(8, result, "Should return correct result")
    end,

    ["test safe call with error function"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local errorFunc = function()
            error("test error")
        end
        
        local success, result = ErrorHandler.safeCall(errorFunc)
        
        TestFramework.assert.isFalse(success, "Should return false for error function")
        TestFramework.assert.notNil(result, "Should return error message")
        TestFramework.assert.stringContains(result, "test error", "Should contain error message")
    end,

    ["test safe call with nil function"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local success, result = ErrorHandler.safeCall(nil)
        
        TestFramework.assert.isFalse(success, "Should return false for nil function")
        TestFramework.assert.notNil(result, "Should return error message")
    end,

    ["test safe call with function that returns multiple values"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local multiFunc = function()
            return 1, 2, 3
        end
        
        local success, result = ErrorHandler.safeCall(multiFunc)
        
        TestFramework.assert.isTrue(success, "Should return success for multi-value function")
        TestFramework.assert.equal(1, result, "Should return first value")
    end,

    ["test validate module with valid module"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local validModule = {
            func1 = function() end,
            func2 = function() end,
            func3 = function() end
        }
        
        local requiredFunctions = {"func1", "func2", "func3"}
        local success, error = ErrorHandler.validateModule(validModule, requiredFunctions)
        
        TestFramework.assert.isTrue(success, "Should validate module with all required functions")
        TestFramework.assert.isNil(error, "Should not return error for valid module")
    end,

    ["test validate module with missing function"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local invalidModule = {
            func1 = function() end,
            func2 = function() end
            -- Missing func3
        }
        
        local requiredFunctions = {"func1", "func2", "func3"}
        local success, error = ErrorHandler.validateModule(invalidModule, requiredFunctions)
        
        TestFramework.assert.isFalse(success, "Should fail validation for missing function")
        TestFramework.assert.notNil(error, "Should return error message")
        TestFramework.assert.stringContains(error, "func3", "Should mention missing function")
    end,

    ["test validate module with non-function value"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local invalidModule = {
            func1 = function() end,
            func2 = "not a function",
            func3 = function() end
        }
        
        local requiredFunctions = {"func1", "func2", "func3"}
        local success, error = ErrorHandler.validateModule(invalidModule, requiredFunctions)
        
        TestFramework.assert.isFalse(success, "Should fail validation for non-function value")
        TestFramework.assert.notNil(error, "Should return error message")
        TestFramework.assert.stringContains(error, "func2", "Should mention invalid function")
    end,

    ["test validate module with empty required functions"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local module = {
            func1 = function() end
        }
        
        local success, error = ErrorHandler.validateModule(module, {})
        
        TestFramework.assert.isTrue(success, "Should validate module with no required functions")
        TestFramework.assert.isNil(error, "Should not return error")
    end,

    ["test validate module with nil module"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local requiredFunctions = {"func1", "func2"}
        local success, error = ErrorHandler.validateModule(nil, requiredFunctions)
        
        TestFramework.assert.isFalse(success, "Should fail validation for nil module")
        TestFramework.assert.notNil(error, "Should return error message")
    end,

    ["test handle module error"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        -- Reset call tracking
        TestFramework.utils.resetCalls()
        
        ErrorHandler.handleModuleError("test_module", "test error message")
        
        -- Should log the error
        TestFramework.assert.calledAtLeast("error", 1, "Should log module error")
    end,

    ["test safe call with complex arguments"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local testFunc = function(tab, str, num)
            return tab.key + num, str .. " processed"
        end
        
        local testTable = {key = 10}
        local success, result1, result2 = ErrorHandler.safeCall(testFunc, testTable, "test", 5)
        
        TestFramework.assert.isTrue(success, "Should handle complex arguments")
        TestFramework.assert.equal(15, result1, "Should return first result correctly")
        TestFramework.assert.equal("test processed", result2, "Should return second result correctly")
    end,

    ["test safe call with function that throws error with arguments"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local errorFunc = function(arg1, arg2)
            error("Error with args: " .. tostring(arg1) .. ", " .. tostring(arg2))
        end
        
        local success, result = ErrorHandler.safeCall(errorFunc, "hello", 42)
        
        TestFramework.assert.isFalse(success, "Should handle error with arguments")
        TestFramework.assert.stringContains(result, "hello", "Should include argument in error")
        TestFramework.assert.stringContains(result, "42", "Should include argument in error")
    end,

    ["test validate module with nested functions"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local module = {
            func1 = function() end,
            nested = {
                func2 = function() end
            }
        }
        
        local requiredFunctions = {"func1"}
        local success, error = ErrorHandler.validateModule(module, requiredFunctions)
        
        TestFramework.assert.isTrue(success, "Should validate module with nested structure")
        TestFramework.assert.isNil(error, "Should not return error")
    end,

    ["test validate module with function that returns function"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local module = {
            func1 = function() 
                return function() end
            end
        }
        
        local requiredFunctions = {"func1"}
        local success, error = ErrorHandler.validateModule(module, requiredFunctions)
        
        TestFramework.assert.isTrue(success, "Should validate function that returns function")
        TestFramework.assert.isNil(error, "Should not return error")
    end,

    ["test safe call with coroutine"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local co = coroutine.create(function()
            return "coroutine result"
        end)
        
        local success, result = ErrorHandler.safeCall(coroutine.resume, co)
        
        TestFramework.assert.isTrue(success, "Should handle coroutine calls")
        TestFramework.assert.isTrue(result, "Should return coroutine success")
    end,

    ["test safe call with pcall"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        local success, result = ErrorHandler.safeCall(pcall, function() return "success" end)
        
        TestFramework.assert.isTrue(success, "Should handle pcall")
        TestFramework.assert.isTrue(result, "Should return pcall result")
    end,

    ["test error handler integration with logger"] = function()
        local ErrorHandler = Utils.require("src.utils.error_handler")
        
        -- Reset call tracking
        TestFramework.utils.resetCalls()
        
        local errorFunc = function()
            error("integration test error")
        end
        
        ErrorHandler.safeCall(errorFunc)
        
        -- Should have logged the error
        TestFramework.assert.calledAtLeast("error", 1, "Should log error through integration")
    end
}

return tests 