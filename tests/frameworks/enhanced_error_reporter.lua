-- Enhanced Error Reporter for Orbit Jump
-- Phase 5: Improved Error Reporting
-- Provides detailed error analysis, suggestions, and debugging information

local Utils = require("src.utils.utils")

local EnhancedErrorReporter = {}

-- Error categories and their severity levels
local ERROR_CATEGORIES = {
    SYNTAX = { level = "CRITICAL", color = "red", icon = "💥" },
    RUNTIME = { level = "ERROR", color = "red", icon = "❌" },
    ASSERTION = { level = "FAILURE", color = "red", icon = "🔴" },
    TIMEOUT = { level = "WARNING", color = "yellow", icon = "⏰" },
    DEPENDENCY = { level = "ERROR", color = "red", icon = "🔗" },
    CONFIGURATION = { level = "WARNING", color = "yellow", icon = "⚙️" },
    PERFORMANCE = { level = "WARNING", color = "yellow", icon = "🐌" },
    MEMORY = { level = "ERROR", color = "red", icon = "💾" },
    NETWORK = { level = "WARNING", color = "yellow", icon = "🌐" },
    FILE = { level = "ERROR", color = "red", icon = "📁" }
}

-- ANSI color codes
local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    bold = "\27[1m",
    reset = "\27[0m"
}

-- Error storage
local errorStore = {
    errors = {},
    warnings = {},
    suggestions = {},
    statistics = {
        totalErrors = 0,
        totalWarnings = 0,
        totalSuggestions = 0,
        categories = {}
    }
}

-- Helper functions
local function printColored(color, text)
    local colorCode = colors[color] or colors.reset
    if Utils and Utils.Logger and Utils.Logger.output then
        Utils.Logger.output(colorCode .. text .. colors.reset)
    else
        print(colorCode .. text .. colors.reset)
    end
end

local function printBold(text)
    printColored("bold", text)
end

-- Stack trace analysis
local function analyzeStackTrace(stackTrace)
    if not stackTrace then return {} end
    
    local analysis = {
        lines = {},
        functions = {},
        files = {},
        suggestions = {}
    }
    
    -- Parse stack trace lines
    for line in stackTrace:gmatch("[^\r\n]+") do
        table.insert(analysis.lines, line)
        
        -- Extract function names
        local funcName = line:match("in function '([^']+)'")
        if funcName then
            table.insert(analysis.functions, funcName)
        end
        
        -- Extract file names
        local fileName = line:match("([^/\\]+%.lua):")
        if fileName then
            table.insert(analysis.files, fileName)
        end
    end
    
    -- Generate suggestions based on stack trace
    if #analysis.functions > 0 then
        local topFunction = analysis.functions[1]
        if topFunction:match("assert") then
            table.insert(analysis.suggestions, "Check assertion condition - value may be nil or false")
        elseif topFunction:match("require") then
            table.insert(analysis.suggestions, "Module dependency issue - check if module exists and is properly loaded")
        elseif topFunction:match("pairs") or topFunction:match("ipairs") then
            table.insert(analysis.suggestions, "Table iteration error - check if table is nil or not a table")
        end
    end
    
    return analysis
end

-- Error context analysis
local function analyzeErrorContext(error, context)
    local analysis = {
        type = "unknown",
        severity = "medium",
        suggestions = {},
        relatedFiles = {},
        commonCauses = {}
    }
    
    local errorMessage = tostring(error):lower()
    
    -- Analyze error type
    if errorMessage:match("attempt to") then
        analysis.type = "runtime"
        analysis.severity = "high"
        table.insert(analysis.suggestions, "Check variable initialization and type")
    elseif errorMessage:match("module.*not found") then
        analysis.type = "dependency"
        analysis.severity = "high"
        table.insert(analysis.suggestions, "Verify module path and dependencies")
    elseif errorMessage:match("syntax error") then
        analysis.type = "syntax"
        analysis.severity = "critical"
        table.insert(analysis.suggestions, "Check Lua syntax and missing brackets/parentheses")
    elseif errorMessage:match("timeout") then
        analysis.type = "timeout"
        analysis.severity = "medium"
        table.insert(analysis.suggestions, "Consider increasing timeout or optimizing test")
    elseif errorMessage:match("memory") then
        analysis.type = "memory"
        analysis.severity = "high"
        table.insert(analysis.suggestions, "Check for memory leaks or excessive resource usage")
    end
    
    -- Add context-specific suggestions
    if context and context.testFile then
        table.insert(analysis.relatedFiles, context.testFile)
        
        if context.testFile:match("unit") then
            table.insert(analysis.suggestions, "Unit test issue - check mock setup and test isolation")
        elseif context.testFile:match("integration") then
            table.insert(analysis.suggestions, "Integration test issue - check system dependencies")
        elseif context.testFile:match("performance") then
            table.insert(analysis.suggestions, "Performance test issue - check timing and resource constraints")
        end
    end
    
    return analysis
end

-- Enhanced error reporting functions
function EnhancedErrorReporter.addError(category, message, details, context)
    local errorInfo = {
        id = #errorStore.errors + 1,
        category = category,
        message = message,
        details = details,
        context = context or {},
        timestamp = os.time(),
        stackTrace = debug.traceback(),
        analysis = {}
    }
    
    -- Analyze error
    errorInfo.analysis = analyzeErrorContext(message, context)
    errorInfo.analysis.stackTrace = analyzeStackTrace(errorInfo.stackTrace)
    
    table.insert(errorStore.errors, errorInfo)
    errorStore.statistics.totalErrors = errorStore.statistics.totalErrors + 1
    
    -- Update category statistics
    errorStore.statistics.categories[category] = (errorStore.statistics.categories[category] or 0) + 1
    
    return errorInfo.id
end

function EnhancedErrorReporter.addWarning(category, message, details, context)
    local warningInfo = {
        id = #errorStore.warnings + 1,
        category = category,
        message = message,
        details = details,
        context = context or {},
        timestamp = os.time(),
        suggestions = {}
    }
    
    table.insert(errorStore.warnings, warningInfo)
    errorStore.statistics.totalWarnings = errorStore.statistics.totalWarnings + 1
    
    return warningInfo.id
end

function EnhancedErrorReporter.addSuggestion(category, message, details, priority)
    local suggestionInfo = {
        id = #errorStore.suggestions + 1,
        category = category,
        message = message,
        details = details,
        priority = priority or "medium",
        timestamp = os.time()
    }
    
    table.insert(errorStore.suggestions, suggestionInfo)
    errorStore.statistics.totalSuggestions = errorStore.statistics.totalSuggestions + 1
    
    return suggestionInfo.id
end

-- Error reporting display functions
function EnhancedErrorReporter.showDetailedError(errorId)
    local error = errorStore.errors[errorId]
    if not error then
        printColored("red", "Error not found: " .. errorId)
        return
    end
    
    local category = ERROR_CATEGORIES[error.category] or { level = "UNKNOWN", color = "white", icon = "❓" }
    
    printColored("bold", "\n" .. string.rep("=", 80))
    printColored("bold", category.icon .. " ERROR #" .. error.id .. " - " .. category.level)
    printColored("bold", string.rep("=", 80))
    
    printColored("white", "Category: " .. error.category)
    printColored("white", "Message: " .. error.message)
    printColored("white", "Time: " .. os.date("%Y-%m-%d %H:%M:%S", error.timestamp))
    
    if error.context.testFile then
        printColored("white", "Test File: " .. error.context.testFile)
    end
    
    if error.details then
        printColored("yellow", "\nDetails:")
        printColored("yellow", "  " .. error.details)
    end
    
    -- Show analysis
    if error.analysis.suggestions and #error.analysis.suggestions > 0 then
        printColored("cyan", "\n💡 Suggestions:")
        for i, suggestion in ipairs(error.analysis.suggestions) do
            printColored("cyan", "  " .. i .. ". " .. suggestion)
        end
    end
    
    -- Show stack trace analysis
    if error.analysis.stackTrace and error.analysis.stackTrace.suggestions and #error.analysis.stackTrace.suggestions > 0 then
        printColored("magenta", "\n🔍 Stack Trace Analysis:")
        for i, suggestion in ipairs(error.analysis.stackTrace.suggestions) do
            printColored("magenta", "  " .. i .. ". " .. suggestion)
        end
    end
    
    -- Show related files
    if error.analysis.relatedFiles and #error.analysis.relatedFiles > 0 then
        printColored("blue", "\n📁 Related Files:")
        for i, file in ipairs(error.analysis.relatedFiles) do
            printColored("blue", "  " .. i .. ". " .. file)
        end
    end
    
    printColored("bold", string.rep("=", 80))
end

function EnhancedErrorReporter.showErrorSummary()
    printColored("bold", "\n" .. string.rep("=", 60))
    printColored("bold", "📊 ERROR SUMMARY")
    printColored("bold", string.rep("=", 60))
    
    printColored("white", "Total Errors: " .. errorStore.statistics.totalErrors)
    printColored("white", "Total Warnings: " .. errorStore.statistics.totalWarnings)
    printColored("white", "Total Suggestions: " .. errorStore.statistics.totalSuggestions)
    
    if errorStore.statistics.totalErrors > 0 then
        printColored("red", "\n❌ Errors by Category:")
        for category, count in pairs(errorStore.statistics.categories) do
            local categoryInfo = ERROR_CATEGORIES[category] or { icon = "❓", color = "white" }
            printColored(categoryInfo.color, "  " .. categoryInfo.icon .. " " .. category .. ": " .. count)
        end
    end
    
    if #errorStore.errors > 0 then
        printColored("red", "\n🔍 Recent Errors:")
        local recentErrors = math.min(5, #errorStore.errors)
        for i = #errorStore.errors - recentErrors + 1, #errorStore.errors do
            local error = errorStore.errors[i]
            local category = ERROR_CATEGORIES[error.category] or { icon = "❓" }
            printColored("red", "  " .. i .. ". " .. category.icon .. " " .. error.message)
        end
    end
end

function EnhancedErrorReporter.showWarnings()
    if #errorStore.warnings == 0 then
        printColored("green", "✅ No warnings to display")
        return
    end
    
    printColored("bold", "\n" .. string.rep("=", 60))
    printColored("bold", "⚠️  WARNINGS")
    printColored("bold", string.rep("=", 60))
    
    for i, warning in ipairs(errorStore.warnings) do
        printColored("yellow", i .. ". " .. warning.category .. ": " .. warning.message)
        if warning.details then
            printColored("white", "   Details: " .. warning.details)
        end
        print()
    end
end

function EnhancedErrorReporter.showSuggestions()
    if #errorStore.suggestions == 0 then
        printColored("green", "✅ No suggestions to display")
        return
    end
    
    printColored("bold", "\n" .. string.rep("=", 60))
    printColored("bold", "💡 SUGGESTIONS")
    printColored("bold", string.rep("=", 60))
    
    -- Sort suggestions by priority
    local sortedSuggestions = {}
    for i, suggestion in ipairs(errorStore.suggestions) do
        table.insert(sortedSuggestions, { index = i, suggestion = suggestion })
    end
    
    table.sort(sortedSuggestions, function(a, b)
        local priorities = { high = 3, medium = 2, low = 1 }
        return priorities[a.suggestion.priority] > priorities[b.suggestion.priority]
    end)
    
    for _, item in ipairs(sortedSuggestions) do
        local suggestion = item.suggestion
        local priorityColor = suggestion.priority == "high" and "red" or 
                             suggestion.priority == "medium" and "yellow" or "cyan"
        
        printColored(priorityColor, item.index .. ". [" .. suggestion.priority:upper() .. "] " .. suggestion.category .. ": " .. suggestion.message)
        if suggestion.details then
            printColored("white", "   Details: " .. suggestion.details)
        end
        print()
    end
end

function EnhancedErrorReporter.showFullReport()
    EnhancedErrorReporter.showErrorSummary()
    EnhancedErrorReporter.showWarnings()
    EnhancedErrorReporter.showSuggestions()
end

-- Utility functions
function EnhancedErrorReporter.clearAll()
    errorStore.errors = {}
    errorStore.warnings = {}
    errorStore.suggestions = {}
    errorStore.statistics = {
        totalErrors = 0,
        totalWarnings = 0,
        totalSuggestions = 0,
        categories = {}
    }
end

function EnhancedErrorReporter.reset()
    EnhancedErrorReporter.clearAll()
end

function EnhancedErrorReporter.getStatistics()
    return errorStore.statistics
end

function EnhancedErrorReporter.getErrors()
    return errorStore.errors
end

function EnhancedErrorReporter.getWarnings()
    return errorStore.warnings
end

function EnhancedErrorReporter.getSuggestions()
    return errorStore.suggestions
end

-- Export the module
return EnhancedErrorReporter 