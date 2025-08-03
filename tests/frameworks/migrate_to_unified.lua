-- Migration Script for Unified Test Framework
-- Converts existing Busted-style tests to use the unified framework
local Utils = require("src.utils.utils")
local UnifiedTestFramework = Utils.require("tests.unified_test_framework")
local MigrationScript = {}
-- Configuration
local config = {
    backupOriginal = true,
    dryRun = false,
    verbose = true
}
-- ANSI color codes
local colors = {
    green = "\27[32m",
    red = "\27[31m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m"
}
local function printColored(color, text)
    Utils.Logger.output(colors[color] .. text .. colors.reset)
end
-- File operations
local function backupFile(filePath)
    if not config.backupOriginal then
        return true
    end
    local backupPath = filePath .. ".backup"
    local success, error = Utils.ErrorHandler.safeCall(function()
        local file = io.open(filePath, "r")
        if not file then
            return false, "Could not open file for backup"
        end
        local content = file:read("*all")
        file:close()
        local backup = io.open(backupPath, "w")
        if not backup then
            return false, "Could not create backup file"
        end
        backup:write(content)
        backup:close()
        return true
    end)
    if success then
        printColored("blue", "  📁 Created backup: " .. backupPath)
    else
        printColored("red", "  ❌ Backup failed: " .. (error or "Unknown error"))
    end
    return success
end
local function readFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil, "Could not open file"
    end
    local content = file:read("*all")
    file:close()
    return content
end
local function writeFile(filePath, content)
    if config.dryRun then
        printColored("yellow", "  🔍 DRY RUN: Would write to " .. filePath)
        return true
    end
    local file = io.open(filePath, "w")
    if not file then
        return false, "Could not open file for writing"
    end
    file:write(content)
    file:close()
    return true
end
-- Test file detection
local function isBustedTestFile(content)
    -- Check for Busted-style patterns
    local bustedPatterns = {
        "describe%(",
        "it%(",
        "before_each%(",
        "after_each%(",
        "assert%.",
        "spy%("
    }
    for _, pattern in ipairs(bustedPatterns) do
        if content:match(pattern) then
            return true
        end
    end
    return false
end
local function isModernTestFile(content)
    -- Check for Modern framework patterns
    local modernPatterns = {
        "ModernTestFramework",
        "ModernTestFramework%.",
        "ModernTestFramework%.assert"
    }
    for _, pattern in ipairs(modernPatterns) do
        if content:match(pattern) then
            return true
        end
    end
    return false
end
-- Content transformation
local function transformBustedToUnified(content)
    local transformed = content
    -- Replace framework imports
    transformed = transformed:gsub(
        "local BustedLite = Utils%.require%(\"tests%.busted\")",
        "local UnifiedTestFramework = Utils.require(\"tests.unified_test_framework\")"
    )
    transformed = transformed:gsub(
        "local ModernTestFramework = Utils%.require%(\"tests%.modern_test_framework\")",
        "local UnifiedTestFramework = Utils.require(\"tests.unified_test_framework\")"
    )
    -- Replace framework initialization
    transformed = transformed:gsub(
        "BustedLite%.reset%()",
        "UnifiedTestFramework.reset()"
    )
    transformed = transformed:gsub(
        "ModernTestFramework%.init%()",
        "UnifiedTestFramework.init()"
    )
    -- Replace framework execution
    transformed = transformed:gsub(
        "BustedLite%.run%()",
        "UnifiedTestFramework.run()"
    )
    transformed = transformed:gsub(
        "ModernTestFramework%.runAllSuites%(",
        "UnifiedTestFramework.runAllSuites("
    )
    -- Replace assertion calls (they're compatible, but for consistency)
    transformed = transformed:gsub(
        "ModernTestFramework%.assert%.",
        "UnifiedTestFramework.assert."
    )
    -- Add unified framework import if not present
    if not transformed:match("UnifiedTestFramework") then
        local importLine = "local UnifiedTestFramework = Utils.require(\"tests.unified_test_framework\")\n"
        transformed = importLine .. transformed
    end
    return transformed
end
-- Test runner conversion
local function convertTestRunner(filePath)
    printColored("blue", "🔄 Converting test runner: " .. filePath)
    local content, error = readFile(filePath)
    if not content then
        printColored("red", "  ❌ Could not read file: " .. (error or "Unknown error"))
        return false
    end
    -- Check if this is a test runner file
    local isRunner = content:match("run_.*_tests") or
                    content:match("BustedLite") or
                    content:match("ModernTestFramework")
    if not isRunner then
        printColored("yellow", "  ⚠️  Not a test runner file, skipping")
        return true
    end
    -- Backup original
    if not backupFile(filePath) then
        return false
    end
    -- Transform content
    local transformed = transformBustedToUnified(content)
    -- Write transformed content
    local success, writeError = writeFile(filePath, transformed)
    if not success then
        printColored("red", "  ❌ Could not write file: " .. (writeError or "Unknown error"))
        return false
    end
    printColored("green", "  ✅ Successfully converted")
    return true
end
-- Directory scanning
local function scanDirectory(dirPath, filePattern)
    local files = {}
    local function scanRecursive(path)
        local items = io.popen("find " .. path .. " -name '" .. filePattern .. "' -type f 2>/dev/null")
        if items then
            for file in items:lines() do
                table.insert(files, file)
            end
            items:close()
        end
    end
    scanRecursive(dirPath)
    return files
end
-- Main migration function
function MigrationScript.migrate(directory, options)
    if options then
        for key, value in pairs(options) do
            config[key] = value
        end
    end
    printColored("yellow", "🚀 Starting Migration to Unified Test Framework")
    printColored("yellow", string.rep("=", 60))
    printColored("blue", "📁 Directory: " .. directory)
    printColored("blue", "🔍 Pattern: *.lua")
    printColored("blue", "💾 Backup: " .. tostring(config.backupOriginal))
    printColored("blue", "🔍 Dry Run: " .. tostring(config.dryRun))
    print(string.rep("=", 60))
    -- Scan for test files
    local testFiles = scanDirectory(directory, "*.lua")
    if #testFiles == 0 then
        printColored("yellow", "⚠️  No test files found")
        return true
    end
    printColored("blue", "📋 Found " .. #testFiles .. " test files")
    local converted = 0
    local failed = 0
    local skipped = 0
    -- Process each file
    for _, filePath in ipairs(testFiles) do
        local content, error = readFile(filePath)
        if not content then
            printColored("red", "❌ Could not read " .. filePath .. ": " .. (error or "Unknown error"))
            failed = failed + 1
        else
            local isBusted = isBustedTestFile(content)
            local isModern = isModernTestFile(content)
            if isBusted or isModern then
                if convertTestRunner(filePath) then
                    converted = converted + 1
                else
                    failed = failed + 1
                end
            else
                if config.verbose then
                    printColored("yellow", "⏭️  Skipping " .. filePath .. " (not a test file)")
                end
                skipped = skipped + 1
            end
        end
    end
    -- Summary
    print(string.rep("=", 60))
    printColored("green", "📊 Migration Summary:")
    printColored("green", "  ✅ Converted: " .. converted)
    printColored("red", "  ❌ Failed: " .. failed)
    printColored("yellow", "  ⏭️  Skipped: " .. skipped)
    printColored("blue", "  📁 Total: " .. #testFiles)
    if config.dryRun then
        printColored("yellow", "\n🔍 This was a dry run. No files were actually modified.")
    end
    return failed == 0
end
-- Command line interface
local function main(...)
    local args = {...}
    local directory = args[1] or "tests"
    local options = {}
    -- Parse command line options
    for i = 2, #args do
        local arg = args[i]
        if arg == "--dry-run" then
            options.dryRun = true
        elseif arg == "--no-backup" then
            options.backupOriginal = false
        elseif arg == "--quiet" then
            options.verbose = false
        elseif arg == "--help" then
            print("Usage: lua migrate_to_unified.lua [directory] [options]")
            print("Options:")
            print("  --dry-run     Show what would be changed without making changes")
            print("  --no-backup   Don't create backup files")
            print("  --quiet       Reduce output verbosity")
            print("  --help        Show this help message")
            return
        end
    end
    local success = MigrationScript.migrate(directory, options)
    os.exit(success and 0 or 1)
end
-- Run if called directly
if arg and #arg > 0 then
    main(table.unpack(arg))
end
return MigrationScript