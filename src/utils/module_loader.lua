-- Module loading utilities
local Utils = require("src.utils.utils")
local ErrorHandler = require("src.utils.error_handler")

local ModuleLoader = {}

function ModuleLoader.initModule(moduleName, initFunction, ...)
    -- Load module
    local success, module = pcall(require, "src." .. moduleName)
    if not success then
        Utils.Logger.error("Failed to load module %s: %s", moduleName, tostring(module))
        return false
    end
    
    -- Initialize module
    if initFunction and module[initFunction] then
        local args = {...}
        local initSuccess = ErrorHandler.safeCall(module[initFunction], unpack(args))
        if not initSuccess then
            Utils.Logger.error("Failed to initialize module %s", moduleName)
            return false
        end
    end
    
    Utils.Logger.info("Module %s loaded successfully", moduleName)
    return true
end

return ModuleLoader