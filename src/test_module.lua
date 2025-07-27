-- Simple test module for module loader tests
local TestModule = {}

-- Control variable for testing different return values
TestModule._testMode = "success"

function TestModule.init()
    if TestModule._testMode == "nil" then
        return nil
    elseif TestModule._testMode == "false" then
        return false
    elseif TestModule._testMode == "multiple" then
        return true, "success", 123
    else
        return true
    end
end

function TestModule.getValue()
    return 42
end

-- For testing multiple return values
function TestModule.getMultiple()
    return true, "success", 123
end

return TestModule