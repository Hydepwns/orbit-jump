#!/usr/bin/env lua
-- Script to find inconsistencies in the Orbit Jump codebase
-- Run with: lua scripts/find_inconsistencies.lua
local function findFiles(dir, pattern)
    local files = {}
    local handle = io.popen("find " .. dir .. " -name '" .. pattern .. "' 2>/dev/null")
    if handle then
        for file in handle:lines() do
            table.insert(files, file)
        end
        handle:close()
    end
    return files
end
local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end
local function analyzeFile(path, content)
    local issues = {}
    local lineNumber = 0
    for line in content:gmatch("[^\r\n]+") do
        lineNumber = lineNumber + 1
        -- Check for direct require calls (should use Utils.require)
        if line:match("local%s+%w+%s*=%s*require%(") and not line:match("Utils%.require") then
            table.insert(issues, {
                type = "direct_require",
                line = line:match("^%s*(.+)"),
                lineNumber = lineNumber,
                description = "Consider using Utils.require() for module caching"
            })
        end
        -- Check for direct math.atan2 usage
        if line:match("math%.atan2") and not line:match("Utils%.atan2") then
            table.insert(issues, {
                type = "direct_atan2",
                line = line:match("^%s*(.+)"),
                lineNumber = lineNumber,
                description = "Consider using Utils.atan2() for consistency"
            })
        end
        -- Check for direct print statements
        if line:match("^%s*print%(") then
            table.insert(issues, {
                type = "direct_print",
                line = line:match("^%s*(.+)"),
                lineNumber = lineNumber,
                description = "Consider using Utils.Logger for consistent logging"
            })
        end
        -- Check for direct pcall usage
        if line:match("pcall%(") and not line:match("Utils%.ErrorHandler%.safeCall") then
            table.insert(issues, {
                type = "direct_pcall",
                line = line:match("^%s*(.+)"),
                lineNumber = lineNumber,
                description = "Consider using Utils.ErrorHandler.safeCall() for consistent error handling"
            })
        end
        -- Check for duplicate distance calculations
        if line:match("math%.sqrt%(") and line:match("dx%*dx") then
            table.insert(issues, {
                type = "manual_distance",
                line = line:match("^%s*(.+)"),
                lineNumber = lineNumber,
                description = "Consider using Utils.distance() for distance calculations"
            })
        end
    end
    return issues
end
local function main()
    print("=== Orbit Jump Codebase Consistency Check ===\n")
    local luaFiles = findFiles("src", "*.lua")
    local testFiles = findFiles("tests", "*.lua")
    local allFiles = {}
    for _, file in ipairs(luaFiles) do
        table.insert(allFiles, file)
    end
    for _, file in ipairs(testFiles) do
        table.insert(allFiles, file)
    end
    local totalIssues = 0
    local issuesByType = {
        direct_require = 0,
        direct_atan2 = 0,
        direct_print = 0,
        direct_pcall = 0,
        manual_distance = 0
    }
    for _, filePath in ipairs(allFiles) do
        local content = readFile(filePath)
        if content then
            local issues = analyzeFile(filePath, content)
            if #issues > 0 then
                print(string.format("📁 %s", filePath))
                for _, issue in ipairs(issues) do
                    print(string.format("  ⚠️  Line %d: %s", issue.lineNumber, issue.description))
                    print(string.format("     %s", issue.line))
                    print()
                    totalIssues = totalIssues + 1
                    issuesByType[issue.type] = issuesByType[issue.type] + 1
                end
            end
        end
    end
    print("=== Summary ===")
    print(string.format("Total files analyzed: %d", #allFiles))
    print(string.format("Total issues found: %d", totalIssues))
    print()
    print("Issues by type:")
    print(string.format("  Direct require calls: %d", issuesByType.direct_require))
    print(string.format("  Direct atan2 usage: %d", issuesByType.direct_atan2))
    print(string.format("  Direct print statements: %d", issuesByType.direct_print))
    print(string.format("  Direct pcall usage: %d", issuesByType.direct_pcall))
    print(string.format("  Manual distance calculations: %d", issuesByType.manual_distance))
    print()
    if totalIssues == 0 then
        print("🎉 No consistency issues found! The codebase is well-structured.")
    else
        print("💡 Consider addressing these issues to improve code consistency.")
        print("   See REFACTORING_GUIDE.md for detailed recommendations.")
    end
end
main()