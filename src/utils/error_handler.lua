-- Error handling utilities
local Utils = require("src.utils.utils")

local ErrorHandler = {}

function ErrorHandler.safeCall(func, ...)
    local success, result = Utils.ErrorHandler.rawPcall(func, ...)
    if not success then
        Utils.Logger.error("Function call failed: %s", tostring(result))
        -- Extract just the error message without file path and line number
        local errorMessage = tostring(result)
        -- Look for the last colon followed by a space (file:line: message format)
        local lastColonPos = string.find(errorMessage, ":%s*[^:]*$")
        if lastColonPos then
            errorMessage = string.sub(errorMessage, lastColonPos + 1)
        else
            -- Fallback: look for any colon
            local colonPos = string.find(errorMessage, ":")
            if colonPos then
                errorMessage = string.sub(errorMessage, colonPos + 1)
            end
        end
        return false, errorMessage
    end
    -- Handle multiple return values
    if select('#', ...) > 0 then
        return true, result, select(2, ...)
    else
        return true, result
    end
end

function ErrorHandler.validateModule(module, requiredFunctions)
    if not module then
        return false, "Module is nil"
    end
    
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