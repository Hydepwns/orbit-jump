--[[
    Debug Configuration for Orbit Jump
    
    This module contains debug system configuration, color themes,
    validation rules, and logging levels.
--]]

local DebugConfig = {}

-- Debug levels
DebugConfig.LogLevel = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
    VERBOSE = 5
}

-- Enhanced debug colors with theme support
DebugConfig.colorThemes = {
    default = {
        frame = {1, 0, 0, 0.3},           -- Red for frame boundaries
        element = {0, 1, 0, 0.3},         -- Green for elements
        text = {1, 1, 1, 1},              -- White for labels
        overlap = {1, 0, 1, 0.5},         -- Magenta for overlapping elements
        outOfBounds = {1, 1, 0, 0.5},     -- Yellow for out-of-bounds elements
        performance = {0, 0.8, 1, 0.7},   -- Cyan for performance issues
        memory = {1, 0.5, 0, 0.6},        -- Orange for memory issues
        background = {0, 0, 0, 0.8},      -- Semi-transparent black
        success = {0, 1, 0, 0.8},         -- Green for success
        warning = {1, 0.8, 0, 0.8},       -- Yellow for warnings
        error = {1, 0, 0, 0.8}            -- Red for errors
    },
    darkMode = {
        frame = {0.8, 0.2, 0.2, 0.4},
        element = {0.2, 0.8, 0.2, 0.4},
        text = {0.9, 0.9, 0.9, 1},
        overlap = {0.8, 0.2, 0.8, 0.6},
        outOfBounds = {0.8, 0.8, 0.2, 0.6},
        performance = {0.2, 0.6, 0.8, 0.7},
        memory = {0.8, 0.4, 0.2, 0.6},
        background = {0.1, 0.1, 0.1, 0.9},
        success = {0.2, 0.8, 0.2, 0.9},
        warning = {0.8, 0.6, 0.2, 0.9},
        error = {0.8, 0.2, 0.2, 0.9}
    },
    highContrast = {
        frame = {1, 0, 0, 0.8},
        element = {0, 1, 0, 0.8},
        text = {1, 1, 1, 1},
        overlap = {1, 0, 1, 0.9},
        outOfBounds = {1, 1, 0, 0.9},
        performance = {0, 1, 1, 0.9},
        memory = {1, 0.5, 0, 0.9},
        background = {0, 0, 0, 0.95},
        success = {0, 1, 0, 1},
        warning = {1, 1, 0, 1},
        error = {1, 0, 0, 1}
    }
}

-- Initialize validation rules
function DebugConfig.initializeValidationRules()
    DebugConfig.validationRules = {
        -- Screen boundary rules
        {
            name = "screen_boundaries",
            description = "Elements must be within screen bounds",
            validate = function(element, screenWidth, screenHeight)
                local issues = {}
                if element.x < 0 then table.insert(issues, "exceeds_left_boundary") end
                if element.y < 0 then table.insert(issues, "exceeds_top_boundary") end
                if element.x + element.width > screenWidth then table.insert(issues, "exceeds_right_boundary") end
                if element.y + element.height > screenHeight then table.insert(issues, "exceeds_bottom_boundary") end
                return issues
            end,
            severity = "error"
        },
        
        -- Minimum size rules
        {
            name = "minimum_size",
            description = "Elements must have reasonable minimum size",
            validate = function(element)
                local issues = {}
                if element.width and element.width < 5 then
                    table.insert(issues, "width_too_small")
                end
                if element.height and element.height < 5 then
                    table.insert(issues, "height_too_small")
                end
                return issues
            end,
            severity = "warning"
        },
        
        -- Maximum size rules
        {
            name = "maximum_size",
            description = "Elements should not be excessively large",
            validate = function(element, screenWidth, screenHeight)
                local issues = {}
                if element.width and element.width > screenWidth * 0.9 then
                    table.insert(issues, "width_too_large")
                end
                if element.height and element.height > screenHeight * 0.9 then
                    table.insert(issues, "height_too_large")
                end
                return issues
            end,
            severity = "warning"
        },
        
        -- Aspect ratio rules
        {
            name = "aspect_ratio",
            description = "Elements should have reasonable aspect ratios",
            validate = function(element)
                local issues = {}
                if element.width and element.height then
                    local ratio = element.width / element.height
                    if ratio > 10 or ratio < 0.1 then
                        table.insert(issues, "extreme_aspect_ratio")
                    end
                end
                return issues
            end,
            severity = "warning"
        },
        
        -- Position validation
        {
            name = "position_validation",
            description = "Element positions should be valid numbers",
            validate = function(element)
                local issues = {}
                if element.x and (type(element.x) ~= "number" or element.x ~= element.x) then
                    table.insert(issues, "invalid_x_position")
                end
                if element.y and (type(element.y) ~= "number" or element.y ~= element.y) then
                    table.insert(issues, "invalid_y_position")
                end
                return issues
            end,
            severity = "error"
        },
        
        -- Required properties
        {
            name = "required_properties",
            description = "Elements must have required properties",
            validate = function(element)
                local issues = {}
                local required = {"x", "y", "width", "height"}
                for _, prop in ipairs(required) do
                    if element[prop] == nil then
                        table.insert(issues, "missing_" .. prop)
                    end
                end
                return issues
            end,
            severity = "error"
        }
    }
end

-- Get validation rule by name
function DebugConfig.getValidationRule(ruleName)
    for _, rule in ipairs(DebugConfig.validationRules) do
        if rule.name == ruleName then
            return rule
        end
    end
    return nil
end

-- Get all validation rules
function DebugConfig.getAllValidationRules()
    return DebugConfig.validationRules
end

-- Get theme by name
function DebugConfig.getTheme(themeName)
    return DebugConfig.colorThemes[themeName] or DebugConfig.colorThemes.default
end

-- Get all available themes
function DebugConfig.getAvailableThemes()
    local themes = {}
    for themeName, _ in pairs(DebugConfig.colorThemes) do
        table.insert(themes, themeName)
    end
    return themes
end

-- Get log level name
function DebugConfig.getLogLevelName(level)
    local levelNames = {"ERROR", "WARN", "INFO", "DEBUG", "VERBOSE"}
    return levelNames[level] or "UNKNOWN"
end

-- Check if log level should be displayed
function DebugConfig.shouldLog(currentLevel, messageLevel)
    return messageLevel <= currentLevel
end

-- Initialize the configuration
DebugConfig.initializeValidationRules()

return DebugConfig 