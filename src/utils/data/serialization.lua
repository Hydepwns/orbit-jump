--[[
    Serialization Utilities for Orbit Jump
    
    This module provides data serialization and deserialization functions
    for save/load functionality and data persistence.
--]]

local Serialization = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Basic Serialization: Simple Data Persistence
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Serialization.serialize(data)
    --[[
        Serialize Data to String
        
        Converts Lua data structures to a string representation.
        Handles tables, strings, numbers, booleans, and nil values.
        
        Parameters:
        - data: The data to serialize
        
        Returns: Serialized string representation
        Performance: O(n) where n is the size of the data structure
    --]]
    
    if type(data) == "table" then
        local result = "{"
        local first = true
        for k, v in pairs(data) do
            if not first then 
                result = result .. "," 
            end
            first = false
            
            -- Serialize key
            if type(k) == "string" then
                result = result .. string.format("[%q]", k)
            else
                result = result .. "[" .. tostring(k) .. "]"
            end
            
            -- Serialize value
            result = result .. "=" .. Serialization.serialize(v)
        end
        return result .. "}"
    elseif type(data) == "string" then
        return string.format("%q", data)
    elseif type(data) == "number" or type(data) == "boolean" then
        return tostring(data)
    else
        return "nil"
    end
end

function Serialization.deserialize(str)
    --[[
        Deserialize String to Data
        
        Converts a serialized string back to Lua data structures.
        Handles tables, strings, numbers, booleans, and nil values.
        
        Parameters:
        - str: The serialized string to deserialize
        
        Returns: Deserialized data or nil if failed
        Performance: O(n) where n is the length of the string
    --]]
    
    if not str or str == "" then
        return nil
    end
    
    local func, err = load("return " .. str)
    if func then
        local success, result = pcall(func)
        if success then
            return result
        end
    end
    
    -- Log error if available
    if _G.Utils and _G.Utils.Logger then
        _G.Utils.Logger.warn("Failed to deserialize data: %s", err or "unknown error")
    end
    
    return nil
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    File Operations: Persistent Storage
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Serialization.saveToFile(data, filename)
    --[[
        Save Data to File
        
        Serializes data and saves it to a file.
        
        Parameters:
        - data: The data to save
        - filename: The filename to save to
        
        Returns: true if successful, false otherwise
        Performance: O(n) where n is the size of the data
    --]]
    
    if not data or not filename then
        return false
    end
    
    local serialized = Serialization.serialize(data)
    if not serialized then
        return false
    end
    
    local file, err = io.open(filename, "w")
    if not file then
        if _G.Utils and _G.Utils.Logger then
            _G.Utils.Logger.error("Failed to open file for writing: %s (%s)", filename, err)
        end
        return false
    end
    
    file:write(serialized)
    file:close()
    
    return true
end

function Serialization.loadFromFile(filename)
    --[[
        Load Data from File
        
        Loads and deserializes data from a file.
        
        Parameters:
        - filename: The filename to load from
        
        Returns: Deserialized data or nil if failed
        Performance: O(n) where n is the file size
    --]]
    
    if not filename then
        return nil
    end
    
    local file, err = io.open(filename, "r")
    if not file then
        if _G.Utils and _G.Utils.Logger then
            _G.Utils.Logger.error("Failed to open file for reading: %s (%s)", filename, err)
        end
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        return nil
    end
    
    return Serialization.deserialize(content)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    JSON-like Serialization: Human Readable Format
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Serialization.serializeToJSON(data, indent)
    --[[
        Serialize Data to JSON-like Format
        
        Converts Lua data structures to a JSON-like string representation.
        More readable than the basic serialization format.
        
        Parameters:
        - data: The data to serialize
        - indent: Optional indentation string (default: "  ")
        
        Returns: JSON-like string representation
        Performance: O(n) where n is the size of the data structure
    --]]
    
    indent = indent or "  "
    
    local function serializeValue(value, currentIndent)
        local valueType = type(value)
        
        if valueType == "nil" then
            return "null"
        elseif valueType == "boolean" then
            return tostring(value)
        elseif valueType == "number" then
            return tostring(value)
        elseif valueType == "string" then
            return string.format("%q", value)
        elseif valueType == "table" then
            local result = "{\n"
            local nextIndent = currentIndent .. indent
            local first = true
            
            for k, v in pairs(value) do
                if not first then
                    result = result .. ",\n"
                end
                first = false
                
                result = result .. nextIndent
                
                -- Handle table keys
                if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
                    -- Valid identifier, no quotes needed
                    result = result .. k .. ": "
                else
                    -- Need quotes for key
                    result = result .. string.format("%q: ", tostring(k))
                end
                
                result = result .. serializeValue(v, nextIndent)
            end
            
            result = result .. "\n" .. currentIndent .. "}"
            return result
        else
            return string.format("%q", tostring(value))
        end
    end
    
    return serializeValue(data, "")
end

function Serialization.deserializeFromJSON(str)
    --[[
        Deserialize JSON-like String to Data
        
        Converts a JSON-like string back to Lua data structures.
        Handles basic JSON syntax with some Lua extensions.
        
        Parameters:
        - str: The JSON-like string to deserialize
        
        Returns: Deserialized data or nil if failed
        Performance: O(n) where n is the length of the string
    --]]
    
    if not str or str == "" then
        return nil
    end
    
    -- Simple JSON parser (handles basic cases)
    local function parseJSON(str, pos)
        pos = pos or 1
        
        -- Skip whitespace
        while pos <= #str and string.match(str:sub(pos, pos), "%s") do
            pos = pos + 1
        end
        
        if pos > #str then
            return nil, pos
        end
        
        local char = str:sub(pos, pos)
        
        if char == "{" then
            -- Parse object
            local result = {}
            pos = pos + 1
            
            while pos <= #str do
                -- Skip whitespace
                while pos <= #str and string.match(str:sub(pos, pos), "%s") do
                    pos = pos + 1
                end
                
                if pos > #str then
                    break
                end
                
                if str:sub(pos, pos) == "}" then
                    pos = pos + 1
                    break
                end
                
                -- Parse key
                local key
                if str:sub(pos, pos) == '"' then
                    -- Quoted key
                    local endPos = str:find('"', pos + 1)
                    if not endPos then
                        return nil, pos
                    end
                    key = str:sub(pos + 1, endPos - 1)
                    pos = endPos + 1
                else
                    -- Unquoted key (identifier)
                    local startPos = pos
                    while pos <= #str and string.match(str:sub(pos, pos), "[%w_]") do
                        pos = pos + 1
                    end
                    key = str:sub(startPos, pos - 1)
                end
                
                -- Skip whitespace and colon
                while pos <= #str and string.match(str:sub(pos, pos), "%s") do
                    pos = pos + 1
                end
                
                if pos > #str or str:sub(pos, pos) ~= ":" then
                    return nil, pos
                end
                pos = pos + 1
                
                -- Parse value
                local value
                value, pos = parseJSON(str, pos)
                if not value then
                    return nil, pos
                end
                
                result[key] = value
                
                -- Skip whitespace and comma
                while pos <= #str and string.match(str:sub(pos, pos), "%s") do
                    pos = pos + 1
                end
                
                if pos <= #str and str:sub(pos, pos) == "," then
                    pos = pos + 1
                end
            end
            
            return result, pos
        elseif char == "[" then
            -- Parse array
            local result = {}
            pos = pos + 1
            
            while pos <= #str do
                -- Skip whitespace
                while pos <= #str and string.match(str:sub(pos, pos), "%s") do
                    pos = pos + 1
                end
                
                if pos > #str then
                    break
                end
                
                if str:sub(pos, pos) == "]" then
                    pos = pos + 1
                    break
                end
                
                -- Parse value
                local value
                value, pos = parseJSON(str, pos)
                if not value then
                    return nil, pos
                end
                
                table.insert(result, value)
                
                -- Skip whitespace and comma
                while pos <= #str and string.match(str:sub(pos, pos), "%s") do
                    pos = pos + 1
                end
                
                if pos <= #str and str:sub(pos, pos) == "," then
                    pos = pos + 1
                end
            end
            
            return result, pos
        elseif char == '"' then
            -- Parse string
            local endPos = str:find('"', pos + 1)
            if not endPos then
                return nil, pos
            end
            local result = str:sub(pos + 1, endPos - 1)
            return result, endPos + 1
        elseif string.match(char, "%d") or char == "-" then
            -- Parse number
            local startPos = pos
            while pos <= #str and (string.match(str:sub(pos, pos), "%d") or str:sub(pos, pos) == "." or str:sub(pos, pos) == "e" or str:sub(pos, pos) == "E" or str:sub(pos, pos) == "+" or str:sub(pos, pos) == "-") do
                pos = pos + 1
            end
            local result = tonumber(str:sub(startPos, pos - 1))
            return result, pos
        elseif str:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        elseif str:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        elseif str:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        else
            return nil, pos
        end
    end
    
    local result, pos = parseJSON(str)
    return result
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Data Validation: Safe Serialization
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Serialization.validateData(data, schema)
    --[[
        Validate Data Against Schema
        
        Validates data structure against a schema definition.
        Useful for ensuring data integrity before serialization.
        
        Parameters:
        - data: The data to validate
        - schema: Schema definition table
        
        Returns: true if valid, false and error message otherwise
        Performance: O(n) where n is the size of the data structure
    --]]
    
    if not schema then
        return true -- No schema means no validation
    end
    
    local function validateValue(value, fieldSchema)
        if fieldSchema.required and value == nil then
            return false, "Required field is missing"
        end
        
        if value == nil then
            return true -- Optional field can be nil
        end
        
        if fieldSchema.type and type(value) ~= fieldSchema.type then
            return false, string.format("Expected type %s, got %s", fieldSchema.type, type(value))
        end
        
        if fieldSchema.min and type(value) == "number" and value < fieldSchema.min then
            return false, string.format("Value %f is below minimum %f", value, fieldSchema.min)
        end
        
        if fieldSchema.max and type(value) == "number" and value > fieldSchema.max then
            return false, string.format("Value %f is above maximum %f", value, fieldSchema.max)
        end
        
        if fieldSchema.pattern and type(value) == "string" and not string.match(value, fieldSchema.pattern) then
            return false, string.format("String does not match pattern: %s", fieldSchema.pattern)
        end
        
        if fieldSchema.enum and not fieldSchema.enum[value] then
            return false, string.format("Value %s is not in allowed enum", tostring(value))
        end
        
        return true
    end
    
    local function validateTable(tableData, tableSchema)
        if type(tableData) ~= "table" then
            return false, "Expected table"
        end
        
        -- Validate required fields
        for fieldName, fieldSchema in pairs(tableSchema) do
            if fieldSchema.required then
                if tableData[fieldName] == nil then
                    return false, string.format("Required field '%s' is missing", fieldName)
                end
            end
        end
        
        -- Validate all fields
        for fieldName, fieldValue in pairs(tableData) do
            local fieldSchema = tableSchema[fieldName]
            if fieldSchema then
                local valid, error = validateValue(fieldValue, fieldSchema)
                if not valid then
                    return false, string.format("Field '%s': %s", fieldName, error)
                end
            end
        end
        
        return true
    end
    
    return validateTable(data, schema)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions: Data Manipulation
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Serialization.deepCopy(orig)
    --[[
        Deep Copy Data Structure
        
        Creates a complete copy of a data structure, including nested tables.
        Useful for creating backups before modification.
        
        Parameters:
        - orig: The original data to copy
        
        Returns: Deep copy of the data
        Performance: O(n) where n is the size of the data structure
    --]]
    
    if type(orig) ~= "table" then
        return orig
    end
    
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = Serialization.deepCopy(v)
    end
    return copy
end

function Serialization.mergeTables(t1, t2)
    --[[
        Merge Tables
        
        Merges two tables, with values from t2 taking precedence over t1.
        Creates a new table rather than modifying the originals.
        
        Parameters:
        - t1: First table (base)
        - t2: Second table (overrides)
        
        Returns: Merged table
        Performance: O(n + m) where n and m are the sizes of the tables
    --]]
    
    local result = {}
    
    -- Copy all values from t1
    for k, v in pairs(t1 or {}) do
        result[k] = v
    end
    
    -- Override with values from t2
    for k, v in pairs(t2 or {}) do
        result[k] = v
    end
    
    return result
end

function Serialization.tableLength(t)
    --[[
        Get Table Length
        
        Returns the number of elements in a table.
        Handles both array-style and hash-style tables.
        
        Parameters:
        - t: The table to measure
        
        Returns: Number of elements
        Performance: O(n) where n is the number of elements
    --]]
    
    if not t or type(t) ~= "table" then
        return 0
    end
    
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return Serialization 