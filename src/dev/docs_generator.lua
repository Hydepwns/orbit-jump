-- Documentation Generator for Orbit Jump
-- Automatically generates API documentation from code comments and function signatures

local Utils = require("src.utils.utils")
local DocsGenerator = {}

-- Documentation templates
DocsGenerator.templates = {
    moduleHeader = [[
# %s

%s

## Functions

]],
    
    functionDoc = [[
### %s

%s

**Parameters:**
%s

**Returns:**
%s

**Example:**
```lua
%s
```

]],
    
    classDoc = [[
## %s

%s

### Methods

]],
    
    methodDoc = [[
#### %s

%s

**Parameters:**
%s

**Returns:**
%s

]],
    
    configDoc = [[
## Configuration

%s

]],
    
    configSection = [[
### %s

%s

**Options:**
%s

]]
}

-- Parse function documentation from comments
function DocsGenerator.parseFunctionDoc(filePath, functionName)
    local file = io.open(filePath, "r")
    if not file then return nil end
    
    local content = file:read("*all")
    file:close()
    
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    
    local doc = {
        description = "",
        parameters = {},
        returns = {},
        example = ""
    }
    
    local inFunction = false
    local inComment = false
    
    for i, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.+)")
        if not trimmed then goto continue end
        
        -- Check if we're entering the target function
        if line:match("function%s+" .. functionName) or line:match(functionName .. "%s*=") then
            inFunction = true
            goto continue
        end
        
        -- Look for comments before the function
        if not inFunction and line:match("^%s*%-%-") then
            local comment = line:match("^%s*%-%-%s*(.+)")
            if comment then
                if comment:match("^@param") then
                    local param = comment:match("^@param%s+(%S+)%s+(.+)")
                    if param then
                        table.insert(doc.parameters, {name = param, description = comment:match("^@param%s+%S+%s+(.+)")})
                    end
                elseif comment:match("^@return") then
                    local ret = comment:match("^@return%s+(.+)")
                    if ret then
                        table.insert(doc.returns, ret)
                    end
                elseif comment:match("^@example") then
                    doc.example = comment:match("^@example%s+(.+)")
                else
                    doc.description = doc.description .. comment .. " "
                end
            end
        end
        
        ::continue::
    end
    
    return doc
end

-- Generate module documentation
function DocsGenerator.generateModuleDoc(moduleName, modulePath)
    local doc = string.format(DocsGenerator.templates.moduleHeader, moduleName, "")
    
    -- Try to load the module to get function names
    local success, module = pcall(require, modulePath)
    if success and type(module) == "table" then
        for name, value in pairs(module) do
            if type(value) == "function" then
                local funcDoc = DocsGenerator.parseFunctionDoc(modulePath .. ".lua", name)
                if funcDoc then
                    local params = ""
                    for _, param in ipairs(funcDoc.parameters) do
                        params = params .. string.format("- `%s`: %s\n", param.name, param.description)
                    end
                    
                    local returns = ""
                    for _, ret in ipairs(funcDoc.returns) do
                        returns = returns .. string.format("- %s\n", ret)
                    end
                    
                    doc = doc .. string.format(DocsGenerator.templates.functionDoc,
                        name,
                        funcDoc.description,
                        params ~= "" and params or "- None",
                        returns ~= "" and returns or "- None",
                        funcDoc.example ~= "" and funcDoc.example or "```lua\n-- Example usage\n```"
                    )
                end
            end
        end
    end
    
    return doc
end

-- Generate configuration documentation
function DocsGenerator.generateConfigDoc()
    local Config = require("src.utils.config")
    local doc = string.format(DocsGenerator.templates.configDoc, "")
    
    for sectionName, section in pairs(Config) do
        if type(section) == "table" and sectionName ~= "validators" then
            local sectionDoc = ""
            local options = ""
            
            for optionName, optionValue in pairs(section) do
                local optionType = type(optionValue)
                local optionDesc = ""
                
                -- Try to get description from comments
                if sectionName == "blockchain" then
                    if optionName == "enabled" then
                        optionDesc = "Enable or disable blockchain features"
                    elseif optionName == "network" then
                        optionDesc = "Blockchain network to use (ethereum, polygon, bsc, etc.)"
                    elseif optionName == "batchInterval" then
                        optionDesc = "Seconds between blockchain batch processing"
                    end
                elseif sectionName == "game" then
                    if optionName == "jumpPower" then
                        optionDesc = "Base jump power for the player"
                    elseif optionName == "dashPower" then
                        optionDesc = "Base dash power for the player"
                    elseif optionName == "maxCombo" then
                        optionDesc = "Maximum combo multiplier"
                    end
                elseif sectionName == "sound" then
                    if optionName == "enabled" then
                        optionDesc = "Enable or disable sound system"
                    elseif optionName == "masterVolume" then
                        optionDesc = "Master volume (0.0 to 1.0)"
                    end
                end
                
                options = options .. string.format("- `%s` (%s): %s\n", optionName, optionType, optionDesc)
            end
            
            doc = doc .. string.format(DocsGenerator.templates.configSection,
                sectionName:gsub("^%l", string.upper),
                sectionDoc,
                options
            )
        end
    end
    
    return doc
end

-- Generate API documentation
function DocsGenerator.generateAPIDoc()
    local modules = {
        {name = "Game Logic", path = "game_logic"},
        {name = "Game State", path = "game_state"},
        {name = "Utils", path = "utils"},
        {name = "Renderer", path = "renderer"},
        {name = "Progression System", path = "progression_system"},
        {name = "Blockchain Integration", path = "blockchain_integration"},
        {name = "UI System", path = "ui_system"},
        {name = "Sound Manager", path = "sound_manager"},
        {name = "Sound Generator", path = "sound_generator"},
        {name = "Performance Monitor", path = "performance_monitor"}
    }
    
    local apiDoc = [[
# Orbit Jump API Documentation

This document provides comprehensive API documentation for the Orbit Jump game engine.

## Modules

]]
    
    for _, module in ipairs(modules) do
        apiDoc = apiDoc .. string.format("- [%s](#%s)\n", module.name, module.name:lower():gsub("%s+", "-"))
    end
    
    apiDoc = apiDoc .. "\n"
    
    for _, module in ipairs(modules) do
        apiDoc = apiDoc .. DocsGenerator.generateModuleDoc(module.name, module.path)
        apiDoc = apiDoc .. "\n"
    end
    
    -- Add configuration documentation
    apiDoc = apiDoc .. DocsGenerator.generateConfigDoc()
    
    return apiDoc
end

-- Generate README with API links
function DocsGenerator.generateREADME()
    local readme = [[
# Orbit Jump

A gravity-based arcade game where players jump between planets and dash through rings to build combos. Now featuring a comprehensive progression system and blockchain integration for continuous building and earning.

## Quick Start

```bash
love .
```

## Documentation

- [API Documentation](docs/API.md) - Complete API reference
- [Configuration Guide](docs/CONFIGURATION.md) - Configuration options
- [Development Guide](docs/DEVELOPMENT.md) - Development setup and guidelines

## Features

### 🚀 Progression System
- Persistent progress across sessions
- Upgrade system with permanent improvements
- Achievement system with rewards
- Meta-progression unlocking new content

### ⛓️ Blockchain Integration
- Web3 event system
- Token rewards for achievements
- NFT unlocks for special milestones
- Smart contract ready architecture

### 🎮 Enhanced Gameplay
- Physics-based gravity mechanics
- Combo system with multipliers
- Particle effects and visual feedback
- Procedural audio generation

## Development

### Running Tests
```bash
lua tests/run_tests.lua
```

### Performance Monitoring
Enable performance monitoring in `config.lua`:
```lua
Config.dev.debugMode = true
Config.dev.showFPS = true
```

### Code Quality
- Comprehensive test suite
- Performance monitoring
- Error handling and logging
- Configuration validation

## License

MIT
]]
    
    return readme
end

-- Generate all documentation
function DocsGenerator.generateAll()
    Utils.Logger.info("Generating documentation...")
    
    -- Create docs directory if it doesn't exist
    local docsDir = "docs"
    if not love.filesystem.getInfo(docsDir) then
        love.filesystem.createDirectory(docsDir)
    end
    
    -- Generate API documentation
    local apiDoc = DocsGenerator.generateAPIDoc()
    love.filesystem.write(docsDir .. "/API.md", apiDoc)
    
    -- Generate configuration documentation
    local configDoc = DocsGenerator.generateConfigDoc()
    love.filesystem.write(docsDir .. "/CONFIGURATION.md", configDoc)
    
    -- Generate README
    local readme = DocsGenerator.generateREADME()
    love.filesystem.write("README.md", readme)
    
    Utils.Logger.info("Documentation generated successfully")
end

-- Initialize documentation generator
function DocsGenerator.init()
    Utils.Logger.info("Documentation generator initialized")
end

return DocsGenerator 