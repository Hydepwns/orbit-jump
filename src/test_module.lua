-- Simple test module for module loader tests
local TestModule = {}
-- Control variable for testing different return values
TestModule._testMode = "success"
TestModule._receivedArgs = {}
TestModule._config = { initialized = false }
function TestModule.init(...)
    -- Store arguments for testing
    TestModule._receivedArgs = {...}
    if TestModule._testMode == "nil" then
        return nil
    elseif TestModule._testMode == "false" then
        return false
    elseif TestModule._testMode == "error" then
        error("Init failed")
    elseif TestModule._testMode == "multiple" then
        return true, "success", 123
    elseif TestModule._testMode == "complex" then
        -- Modify the first argument (config) if it's a table
        local config = select(1, ...)
        if type(config) == "table" then
            config.initialized = true
        end
        return true
    elseif TestModule._testMode == "arguments" then
        -- Just return true and let test check the received args
        return true
    else
        return true
    end
end
function TestModule.getValue()
    return 42
end
function TestModule.getConfig()
    return TestModule._config
end
function TestModule.getReceivedArgs()
    return TestModule._receivedArgs
end
-- For testing multiple return values
function TestModule.getMultiple()
    return true, "success", 123
end
-- Reset state for clean tests
function TestModule.reset()
    TestModule._testMode = "success"
    TestModule._receivedArgs = {}
    TestModule._config = { initialized = false }
end
return TestModule