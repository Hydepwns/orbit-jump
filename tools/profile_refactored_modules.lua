#!/usr/bin/env lua
--[[
    Performance Profiler for Refactored Modules
    This tool profiles the performance of all refactored modules to identify
    bottlenecks and optimization opportunities in Phase 1 systems.
--]]
package.path = package.path .. ";?.lua"
local Utils = require("src.utils.utils")
-- Setup performance monitoring
local PerformanceMonitor = require("src.performance.performance_monitor")
-- Profile metrics
local profileData = {
    warpSystem = {},
    playerAnalytics = {},
    emotionalFeedback = {},
    playerSystem = {}
}
-- Mock dependencies for isolated testing
local function setupMocks()
    -- Mock logger
    Utils.Logger = {
        info = function(...) end,
        error = function(...) end,
        debug = function(...) end
    }
    -- Mock Utils.require for dependencies
    local originalRequire = Utils.require
    Utils.require = function(module)
        if module == "src.systems.particle_system" then
            return {
                createEmotionalParticles = function() end,
                burst = function() end,
                create = function() end
            }
        elseif module == "src.audio.sound_manager" then
            return {
                playEmotionalCue = function() end,
                playSound = function() end
            }
        elseif module == "src.core.camera" then
            return {
                addEmotionalShake = function() end
            }
        elseif module == "src.core.game_state" then
            return {player = {x = 100, y = 200}}
        elseif module == "src.systems.achievement_system" then
            return {}
        end
        return originalRequire(module)
    end
    -- Set global mocks
    ParticleSystem = {burst = function() end, create = function() end}
    SoundManager = {playSound = function() end}
end
-- Profile a function call
local function profileFunction(name, func, iterations)
    iterations = iterations or 1000
    collectgarbage("collect")
    local startMemory = collectgarbage("count")
    local startTime = os.clock()
    for i = 1, iterations do
        func()
    end
    local endTime = os.clock()
    collectgarbage("collect")
    local endMemory = collectgarbage("count")
    return {
        name = name,
        totalTime = (endTime - startTime) * 1000, -- Convert to ms
        avgTime = ((endTime - startTime) * 1000) / iterations,
        memoryDelta = endMemory - startMemory,
        iterations = iterations
    }
end
-- Profile warp system
local function profileWarpSystem()
    print("🔍 Profiling Warp Drive System...")
    local WarpCore = require("src.systems.warp.warp_core")
    local WarpEnergy = require("src.systems.warp.warp_energy")
    local WarpMemory = require("src.systems.warp.warp_memory")
    local WarpNavigation = require("src.systems.warp.warp_navigation")
    -- Initialize systems
    WarpCore.init()
    WarpEnergy.init()
    WarpMemory.init()
    WarpNavigation.init()
    -- Profile core operations
    profileData.warpSystem.coreUpdate = profileFunction("WarpCore.update", function()
        WarpCore.update(0.016) -- 60 FPS delta
    end, 10000)
    profileData.warpSystem.energyRegeneration = profileFunction("WarpEnergy.regenerate", function()
        WarpEnergy.regenerateEnergy(0.016)
    end, 10000)
    profileData.warpSystem.memoryOptimize = profileFunction("WarpMemory.optimizeRoute", function()
        WarpMemory.optimizeRoute({x = 100, y = 100}, {x = 200, y = 200})
    end, 1000)
    profileData.warpSystem.navigationCalc = profileFunction("WarpNavigation.calculateRoute", function()
        WarpNavigation.calculateRoute({x = 0, y = 0}, {x = 500, y = 500}, {{x = 250, y = 250, radius = 50}})
    end, 1000)
end
-- Profile player analytics system
local function profilePlayerAnalytics()
    print("📊 Profiling Player Analytics System...")
    local BehaviorTracker = require("src.systems.analytics.behavior_tracker")
    local PatternAnalyzer = require("src.systems.analytics.pattern_analyzer")
    local InsightGenerator = require("src.systems.analytics.insight_generator")
    -- Initialize systems
    BehaviorTracker.init()
    PatternAnalyzer.init()
    InsightGenerator.init()
    -- Profile analytics operations
    profileData.playerAnalytics.behaviorUpdate = profileFunction("BehaviorTracker.update", function()
        BehaviorTracker.update(0.016)
    end, 10000)
    profileData.playerAnalytics.patternAnalysis = profileFunction("PatternAnalyzer.analyze", function()
        PatternAnalyzer.analyzePlayerBehavior()
    end, 1000)
    profileData.playerAnalytics.insightGeneration = profileFunction("InsightGenerator.generateInsights", function()
        InsightGenerator.generatePlayerInsights()
    end, 500)
end
-- Profile emotional feedback system
local function profileEmotionalFeedback()
    print("💝 Profiling Emotional Feedback System...")
    local EmotionCore = require("src.systems.emotion.emotion_core")
    local EmotionalFeedback = require("src.systems.emotional_feedback")
    -- Initialize systems
    EmotionCore.init()
    EmotionalFeedback.init()
    -- Profile emotional operations
    profileData.emotionalFeedback.coreUpdate = profileFunction("EmotionCore.update", function()
        EmotionCore.update(0.016)
    end, 10000)
    profileData.emotionalFeedback.eventProcessing = profileFunction("EmotionalFeedback.processEvent", function()
        EmotionalFeedback.processEvent("jump", {pullPower = 0.7, success = true})
    end, 5000)
    profileData.emotionalFeedback.moodTransition = profileFunction("EmotionCore.transitionToMood", function()
        EmotionCore.transitionToMood("excited", 0.8)
    end, 5000)
end
-- Profile player system
local function profilePlayerSystem()
    print("🎮 Profiling Player System...")
    local PlayerMovement = require("src.systems.player.player_movement")
    local PlayerAbilities = require("src.systems.player.player_abilities")
    local PlayerState = require("src.systems.player.player_state")
    local PlayerSystem = require("src.systems.player_system")
    -- Initialize systems
    PlayerMovement.init()
    PlayerAbilities.init()
    PlayerState.init()
    PlayerSystem.init()
    -- Create test player
    local testPlayer = {
        x = 100, y = 100, vx = 0, vy = 0,
        landed = false, jumpCooldown = 0, dashCooldown = 0,
        health = 100, energy = 100, maxHealth = 100, maxEnergy = 100,
        powerUps = {}, trail = {points = {}}, landedPlanet = nil,
        profile = {skillLevel = 0.5, preferences = {}}
    }
    -- Profile player operations
    profileData.playerSystem.movementUpdate = profileFunction("PlayerMovement.updateMovement", function()
        PlayerMovement.updateMovement(testPlayer, {}, 0.016)
    end, 10000)
    profileData.playerSystem.abilityCooldowns = profileFunction("PlayerAbilities.updateCooldowns", function()
        PlayerAbilities.updateCooldowns(testPlayer, 0.016)
    end, 10000)
    profileData.playerSystem.systemCoordination = profileFunction("PlayerSystem.update", function()
        PlayerSystem.update(testPlayer, {}, 0.016, {})
    end, 5000)
end
-- Generate performance report
local function generateReport()
    print("\n" .. string.rep("=", 80))
    print("🚀 REFACTORED MODULES PERFORMANCE REPORT")
    print(string.rep("=", 80))
    local function printSystemReport(systemName, systemData)
        print(string.format("\n📊 %s PERFORMANCE:", systemName:upper()))
        print(string.rep("-", 50))
        local totalTime = 0
        local totalMemory = 0
        for _, profile in pairs(systemData) do
            print(string.format("  %-25s | %6.3f ms avg | %6.1f ms total | %+6.1f KB mem",
                profile.name,
                profile.avgTime,
                profile.totalTime,
                profile.memoryDelta
            ))
            totalTime = totalTime + profile.totalTime
            totalMemory = totalMemory + profile.memoryDelta
        end
        print(string.format("  %-25s | %18s | %6.1f ms total | %+6.1f KB mem",
            "SYSTEM TOTAL", "", totalTime, totalMemory))
        -- Performance analysis
        if totalTime > 100 then
            print("  ⚠️  HIGH LATENCY: Consider optimization")
        elseif totalTime > 50 then
            print("  ⚡ MODERATE LATENCY: Monitor closely")
        else
            print("  ✅ EXCELLENT PERFORMANCE")
        end
        if totalMemory > 100 then
            print("  ⚠️  HIGH MEMORY USAGE: Check for leaks")
        elseif totalMemory > 50 then
            print("  ⚡ MODERATE MEMORY USAGE: Monitor")
        else
            print("  ✅ LOW MEMORY FOOTPRINT")
        end
    end
    printSystemReport("Warp Drive System", profileData.warpSystem)
    printSystemReport("Player Analytics System", profileData.playerAnalytics)
    printSystemReport("Emotional Feedback System", profileData.emotionalFeedback)
    printSystemReport("Player System", profileData.playerSystem)
    -- Overall summary
    print(string.rep("=", 80))
    print("📈 OPTIMIZATION RECOMMENDATIONS:")
    print(string.rep("-", 50))
    -- Find the slowest operations
    local allProfiles = {}
    for system, profiles in pairs(profileData) do
        for _, profile in pairs(profiles) do
            profile.system = system
            table.insert(allProfiles, profile)
        end
    end
    table.sort(allProfiles, function(a, b) return a.avgTime > b.avgTime end)
    print("🔥 Top 5 Slowest Operations:")
    for i = 1, math.min(5, #allProfiles) do
        local profile = allProfiles[i]
        print(string.format("  %d. %s (%s) - %.3f ms avg",
            i, profile.name, profile.system, profile.avgTime))
        if profile.avgTime > 1.0 then
            print("     💡 Optimization opportunity: Focus here first")
        end
    end
    print("\n🎯 PERFORMANCE SCORE: " .. calculatePerformanceScore(allProfiles))
    print(string.rep("=", 80))
end
-- Calculate overall performance score
local function calculatePerformanceScore(profiles)
    local totalTime = 0
    local count = 0
    for _, profile in ipairs(profiles) do
        totalTime = totalTime + profile.avgTime
        count = count + 1
    end
    local avgTime = totalTime / count
    if avgTime < 0.01 then
        return "🏆 EXCELLENT (A+)"
    elseif avgTime < 0.05 then
        return "✅ VERY GOOD (A)"
    elseif avgTime < 0.1 then
        return "⚡ GOOD (B+)"
    elseif avgTime < 0.5 then
        return "⚠️  NEEDS ATTENTION (B)"
    else
        return "🚨 OPTIMIZATION REQUIRED (C)"
    end
end
-- Main execution
local function main()
    print("🚀 Starting Performance Profiling of Refactored Modules...")
    print("⏱️  This may take a few moments...")
    setupMocks()
    local startTime = os.clock()
    profileWarpSystem()
    profilePlayerAnalytics()
    profileEmotionalFeedback()
    profilePlayerSystem()
    local totalTime = os.clock() - startTime
    generateReport()
    print(string.format("\n⏱️  Total profiling time: %.2f seconds", totalTime))
    print("✅ Performance profiling complete!")
end
-- Run the profiler
main()