-- Module loading utilities
local Utils = Utils or require("src.utils.utils")
local ErrorHandler = Utils.require("src.utils.error_handler")
local ModuleLoader = {}
function ModuleLoader.initModule(moduleName, initFunction, ...)
    -- Load module
    local success, module = Utils.ErrorHandler.safeCall(Utils.require, "src." .. moduleName)
    if not success then
        Utils.Logger.error("Failed to load module %s: %s", moduleName, tostring(module))
        return false
    end
    -- Initialize module
    if initFunction and module[initFunction] then
        -- Pass the arguments directly to safeCall, which will forward them to the function
        local initSuccess, initResult = ErrorHandler.safeCall(module[initFunction], ...)
        if not initSuccess then
            Utils.Logger.error("Failed to initialize module %s", moduleName)
            return false
        end
        -- Check if init function returned false or nil (indicating failure)
        if initResult == false or initResult == nil then
            Utils.Logger.error("Module %s initialization returned false/nil", moduleName)
            return false
        end
    end
    Utils.Logger.info("Module %s loaded successfully", moduleName)
    return true
end
return ModuleLoader