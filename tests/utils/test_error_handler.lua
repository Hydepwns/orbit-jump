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
    local testFunc = function(a, b)
      return a + b
    end

    local success, result = Utils.ErrorHandler.safeCall(testFunc, 5, 3)

    TestFramework.assert.isTrue(success, "Should return success for valid function")
    TestFramework.assert.equal(8, result, "Should return correct result")
  end,

  ["test safe call with error function"] = function()
    local errorFunc = function()
      error("test error")
    end

    local success, result = Utils.ErrorHandler.safeCall(errorFunc)

    TestFramework.assert.isFalse(success, "Should return false for error function")
    TestFramework.assert.notNil(result, "Should return error message")
    TestFramework.assert.stringContains("test error", result, "Should contain error message")
  end,

  ["test safe call with nil function"] = function()
    local success, result = Utils.ErrorHandler.safeCall(nil)

    TestFramework.assert.isFalse(success, "Should return false for nil function")
    TestFramework.assert.notNil(result, "Should return error message")
  end,

  ["test safe call with function that returns multiple values"] = function()
    local multiFunc = function()
      return 1, 2, 3
    end

    local success, result = Utils.ErrorHandler.safeCall(multiFunc)

    TestFramework.assert.isTrue(success, "Should return success for multi-value function")
    TestFramework.assert.equal(1, result, "Should return first value")
  end,

  ["test handle module error"] = function()
    -- Reset call tracking
    TestFramework.utils.resetCalls()

    -- Test the actual handleModuleError function
    Utils.ErrorHandler.handleModuleError("test_module", "test error message")

    -- Should log the error
    TestFramework.assert.calledAtLeast("error", 1, "Should log module error")
  end,

  ["test safe call with complex arguments"] = function()
    local testFunc = function(tab, str, num)
      return tab.key + num, str .. " processed"
    end

    local testTable = { key = 10 }
    local success, result1 = Utils.ErrorHandler.safeCall(testFunc, testTable, "test", 5)

    TestFramework.assert.isTrue(success, "Should handle complex arguments")
    TestFramework.assert.equal(15, result1, "Should return first result correctly")
    -- Note: Utils.ErrorHandler.safeCall only returns first result
  end,

  ["test safe call with function that throws error with arguments"] = function()
    local errorFunc = function(arg1, arg2)
      error("Error with args: " .. tostring(arg1) .. ", " .. tostring(arg2))
    end

    local success, result = Utils.ErrorHandler.safeCall(errorFunc, "hello", 42)

    TestFramework.assert.isFalse(success, "Should handle error with arguments")
    TestFramework.assert.stringContains("hello", result, "Should include argument in error")
    TestFramework.assert.stringContains("42", result, "Should include argument in error")
  end,

  ["test safe call with coroutine"] = function()
    local co = coroutine.create(function()
      return "coroutine result"
    end)

    local success, result = Utils.ErrorHandler.safeCall(coroutine.resume, co)

    TestFramework.assert.isTrue(success, "Should handle coroutine calls")
    TestFramework.assert.isTrue(result, "Should return coroutine success")
  end,

  ["test safe call with pcall"] = function()
    local success, result = Utils.ErrorHandler.safeCall(pcall, function() return "success" end)

    TestFramework.assert.isTrue(success, "Should handle pcall")
    TestFramework.assert.isTrue(result, "Should return pcall result")
  end,

  ["test error handler integration with logger"] = function()
    -- Reset call tracking
    TestFramework.utils.resetCalls()

    local errorFunc = function()
      error("integration test error")
    end

    -- The safeCall function should log the error through Utils.Logger.error
    local success, result = Utils.ErrorHandler.safeCall(errorFunc)

    TestFramework.assert.isFalse(success, "Should return false for error")
    -- Should have logged the error
    TestFramework.assert.calledAtLeast("error", 1, "Should log error through integration")
  end
}

-- Test runner
local function run()
    Utils.Logger.info("Running Error Handler Tests")
    Utils.Logger.info("==================================================")
    return TestFramework.runTests(tests)
end

return {run = run}
