#!/usr/bin/env lua
--[[
    Memory Allocation Analysis for Refactored Modules
    This tool analyzes the refactored modules for potential memory allocation
    patterns and provides optimization recommendations without requiring
    runtime execution.
--]]
package.path = package.path .. ";?.lua"
local Utils = require("src.utils.utils")
-- Static analysis results
local analysisResults = {
    warpSystem = {},
    playerAnalytics = {},
    emotionalFeedback = {},
    playerSystem = {}
}
-- Pattern detection for memory allocations
local memoryPatterns = {
    tableCreation = "%{.*%}",              -- Table literals
    stringConcat = "%.%..*%.%.",           -- String concatenation
    functionCalls = "%w+%(",               -- Function calls
    loops = "for%s+.*%s+do",               -- Loop constructs
    conditionals = "if%s+.*%s+then"        -- Conditional statements
}
-- Analyze a Lua file for memory patterns
local function analyzeFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    local analysis = {
        filePath = filePath,
        lineCount = 0,
        functionCount = 0,
        tableCreations = 0,
        stringConcats = 0,
        loopCount = 0,
        complexityScore = 0,
        memoryRisk = "LOW"
    }
    -- Count lines and basic patterns
    for line in content:gmatch("[^\r\n]+") do
        analysis.lineCount = analysis.lineCount + 1
        -- Skip comments and empty lines for pattern analysis
        local trimmedLine = line:match("^%s*(.-)%s*$")
        if trimmedLine and not trimmedLine:match("^%-%-") and trimmedLine ~= "" then
            -- Check for table creations
            if trimmedLine:match(memoryPatterns.tableCreation) then
                analysis.tableCreations = analysis.tableCreations + 1
            end
            -- Check for string concatenations
            if trimmedLine:match(memoryPatterns.stringConcat) then
                analysis.stringConcats = analysis.stringConcats + 1
            end
            -- Check for loops
            if trimmedLine:match(memoryPatterns.loops) then
                analysis.loopCount = analysis.loopCount + 1
            end
        end
    end
    -- Count functions
    for func in content:gmatch("function%s+[%w%.]+") do
        analysis.functionCount = analysis.functionCount + 1
    end
    -- Calculate complexity score
    analysis.complexityScore = (analysis.functionCount * 2) +
                              (analysis.loopCount * 3) +
                              (analysis.tableCreations * 1) +
                              (analysis.stringConcats * 2)
    -- Determine memory risk
    if analysis.complexityScore > 100 then
        analysis.memoryRisk = "HIGH"
    elseif analysis.complexityScore > 50 then
        analysis.memoryRisk = "MEDIUM"
    else
        analysis.memoryRisk = "LOW"
    end
    return analysis
end
-- Analyze warp system modules
local function analyzeWarpSystem()
    print("🔍 Analyzing Warp Drive System memory patterns...")
    local modules = {
        "src/systems/warp/warp_core.lua",
        "src/systems/warp/warp_energy.lua",
        "src/systems/warp/warp_memory.lua",
        "src/systems/warp/warp_navigation.lua"
    }
    for _, module in ipairs(modules) do
        local analysis = analyzeFile(module)
        if analysis then
            analysisResults.warpSystem[module] = analysis
        end
    end
end
-- Analyze player analytics system
local function analyzePlayerAnalytics()
    print("📊 Analyzing Player Analytics System memory patterns...")
    local modules = {
        "src/systems/analytics/behavior_tracker.lua",
        "src/systems/analytics/pattern_analyzer.lua",
        "src/systems/analytics/insight_generator.lua"
    }
    for _, module in ipairs(modules) do
        local analysis = analyzeFile(module)
        if analysis then
            analysisResults.playerAnalytics[module] = analysis
        end
    end
end
-- Analyze emotional feedback system
local function analyzeEmotionalFeedback()
    print("💝 Analyzing Emotional Feedback System memory patterns...")
    local modules = {
        "src/systems/emotion/emotion_core.lua",
        "src/systems/emotion/feedback_renderer.lua",
        "src/systems/emotion/emotion_analytics.lua",
        "src/systems/emotional_feedback.lua"
    }
    for _, module in ipairs(modules) do
        local analysis = analyzeFile(module)
        if analysis then
            analysisResults.emotionalFeedback[module] = analysis
        end
    end
end
-- Analyze player system
local function analyzePlayerSystem()
    print("🎮 Analyzing Player System memory patterns...")
    local modules = {
        "src/systems/player/player_movement.lua",
        "src/systems/player/player_abilities.lua",
        "src/systems/player/player_state.lua",
        "src/systems/player_system.lua"
    }
    for _, module in ipairs(modules) do
        local analysis = analyzeFile(module)
        if analysis then
            analysisResults.playerSystem[module] = analysis
        end
    end
end
-- Generate comprehensive report
local function generateReport()
    print("\n" .. string.rep("=", 90))
    print("🧠 REFACTORED MODULES MEMORY ANALYSIS REPORT")
    print(string.rep("=", 90))
    local function printSystemAnalysis(systemName, systemData)
        print(string.format("\n📊 %s ANALYSIS:", systemName:upper()))
        print(string.rep("-", 80))
        local systemTotals = {
            lineCount = 0,
            functionCount = 0,
            tableCreations = 0,
            stringConcats = 0,
            loopCount = 0,
            complexityScore = 0,
            moduleCount = 0
        }
        -- Module details
        for filePath, analysis in pairs(systemData) do
            local fileName = filePath:match("([^/]+)%.lua$") or filePath
            print(string.format("  %-25s | %4d lines | %3d funcs | %3d tables | %3d loops | %s risk",
                fileName,
                analysis.lineCount,
                analysis.functionCount,
                analysis.tableCreations,
                analysis.loopCount,
                analysis.memoryRisk
            ))
            -- Add to totals
            systemTotals.lineCount = systemTotals.lineCount + analysis.lineCount
            systemTotals.functionCount = systemTotals.functionCount + analysis.functionCount
            systemTotals.tableCreations = systemTotals.tableCreations + analysis.tableCreations
            systemTotals.stringConcats = systemTotals.stringConcats + analysis.stringConcats
            systemTotals.loopCount = systemTotals.loopCount + analysis.loopCount
            systemTotals.complexityScore = systemTotals.complexityScore + analysis.complexityScore
            systemTotals.moduleCount = systemTotals.moduleCount + 1
        end
        -- System summary
        print(string.rep("-", 80))
        print(string.format("  %-25s | %4d lines | %3d funcs | %3d tables | %3d loops | Score: %d",
            "SYSTEM TOTAL",
            systemTotals.lineCount,
            systemTotals.functionCount,
            systemTotals.tableCreations,
            systemTotals.loopCount,
            systemTotals.complexityScore
        ))
        -- System assessment
        local avgComplexity = systemTotals.complexityScore / systemTotals.moduleCount
        local assessment
        if avgComplexity > 50 then
            assessment = "⚠️  NEEDS OPTIMIZATION"
        elseif avgComplexity > 25 then
            assessment = "⚡ MODERATE COMPLEXITY"
        else
            assessment = "✅ WELL OPTIMIZED"
        end
        print(string.format("  Assessment: %s (Avg complexity: %.1f per module)", assessment, avgComplexity))
        return systemTotals
    end
    -- Analyze each system
    local warpTotals = printSystemAnalysis("Warp Drive System", analysisResults.warpSystem)
    local analyticsTotals = printSystemAnalysis("Player Analytics System", analysisResults.playerAnalytics)
    local emotionTotals = printSystemAnalysis("Emotional Feedback System", analysisResults.emotionalFeedback)
    local playerTotals = printSystemAnalysis("Player System", analysisResults.playerSystem)
    -- Overall summary
    print("\n" .. string.rep("=", 90))
    print("📈 OVERALL ANALYSIS & RECOMMENDATIONS")
    print(string.rep("=", 90))
    local grandTotals = {
        lineCount = warpTotals.lineCount + analyticsTotals.lineCount + emotionTotals.lineCount + playerTotals.lineCount,
        functionCount = warpTotals.functionCount + analyticsTotals.functionCount + emotionTotals.functionCount + playerTotals.functionCount,
        tableCreations = warpTotals.tableCreations + analyticsTotals.tableCreations + emotionTotals.tableCreations + playerTotals.tableCreations,
        complexityScore = warpTotals.complexityScore + analyticsTotals.complexityScore + emotionTotals.complexityScore + playerTotals.complexityScore,
        moduleCount = warpTotals.moduleCount + analyticsTotals.moduleCount + emotionTotals.moduleCount + playerTotals.moduleCount
    }
    print(string.format("📊 REFACTORING IMPACT:"))
    print(string.format("   Total modules analyzed: %d", grandTotals.moduleCount))
    print(string.format("   Total lines of code: %d", grandTotals.lineCount))
    print(string.format("   Average lines per module: %.1f", grandTotals.lineCount / grandTotals.moduleCount))
    print(string.format("   Total functions: %d", grandTotals.functionCount))
    print(string.format("   Total complexity score: %d", grandTotals.complexityScore))
    -- Module size assessment
    local avgLinesPerModule = grandTotals.lineCount / grandTotals.moduleCount
    if avgLinesPerModule > 400 then
        print("   ⚠️  CONCERN: Some modules may still be too large")
    else
        print("   ✅ EXCELLENT: Module sizes are well-balanced")
    end
    -- Memory optimization recommendations
    print("\n💡 MEMORY OPTIMIZATION RECOMMENDATIONS:")
    local highRiskModules = {}
    for system, modules in pairs(analysisResults) do
        for path, analysis in pairs(modules) do
            if analysis.memoryRisk == "HIGH" then
                table.insert(highRiskModules, {path = path, analysis = analysis})
            end
        end
    end
    if #highRiskModules > 0 then
        print("   🔥 HIGH PRIORITY:")
        for _, module in ipairs(highRiskModules) do
            local fileName = module.path:match("([^/]+)%.lua$") or module.path
            print(string.format("      • %s - Complexity: %d", fileName, module.analysis.complexityScore))
        end
    else
        print("   ✅ No high-risk modules identified")
    end
    print("\n   🎯 GENERAL OPTIMIZATIONS:")
    print("      • Pre-allocate tables in hot paths where possible")
    print("      • Use object pooling for frequently created/destroyed objects")
    print("      • Cache expensive calculations in update loops")
    print("      • Consider string.format instead of concatenation in loops")
    -- Success assessment
    local overallGrade
    local avgComplexityPerModule = grandTotals.complexityScore / grandTotals.moduleCount
    if avgComplexityPerModule < 25 then
        overallGrade = "🏆 EXCELLENT (A+)"
    elseif avgComplexityPerModule < 50 then
        overallGrade = "✅ VERY GOOD (A)"
    elseif avgComplexityPerModule < 75 then
        overallGrade = "⚡ GOOD (B+)"
    else
        overallGrade = "⚠️  NEEDS WORK (B-)"
    end
    print(string.format("\n🎯 REFACTORING QUALITY GRADE: %s", overallGrade))
    print(string.rep("=", 90))
end
-- Main execution
local function main()
    print("🧠 Starting Memory Allocation Analysis of Refactored Modules...")
    analyzeWarpSystem()
    analyzePlayerAnalytics()
    analyzeEmotionalFeedback()
    analyzePlayerSystem()
    generateReport()
    print("\n✅ Memory analysis complete!")
end
main()