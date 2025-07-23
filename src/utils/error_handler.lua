-- Error handling utilities
local Utils = require("src.utils.utils")

local ErrorHandler = {}

function ErrorHandler.safeCall(func, ...)
    local success, result = Utils.ErrorHandler.rawPcall(func, ...)
    if not success then
        Utils.Logger.error("Function call failed: %s", tostring(result))
        return false, result
    end
    return true, result
end

function ErrorHandler.validateModule(module, requiredFunctions)
    for _, funcName in ipairs(requiredFunctions) do
        if type(module[funcName]) ~= "function" then
            return false, string.format("Missing required function: %s", funcName)
        end
    end
    return true
end

function ErrorHandler.handleModuleError(moduleName, error)
    Utils.Logger.error("Module %s error: %s", moduleName, tostring(error))
end

return ErrorHandler