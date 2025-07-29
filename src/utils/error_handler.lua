-- Error handling utilities
local Utils = require("src.utils.utils")

local ErrorHandler = {}

function ErrorHandler.safeCall(func, ...)
  local results = { Utils.ErrorHandler.rawPcall(func, ...) }
  local success = results[1]
  if not success then
    local result = results[2]
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
  -- Return all results including success flag
  if table.unpack then
    return table.unpack(results)
  else
    return unpack(results)
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

function ErrorHandler.handleModuleError(moduleName, err)
  Utils.Logger.error("Module %s error: %s", moduleName, tostring(err))
end

return ErrorHandler
