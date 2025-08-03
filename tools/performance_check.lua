#!/usr/bin/env lua
--[[
    Quick Performance Check for Refactored Modules
    A streamlined performance check to identify any obvious bottlenecks
    in the refactored modules from Phase 1.
--]]
package.path = package.path .. ";?.lua"
local Utils = require("src.utils.utils")
-- Setup basic mocks
local function setupMocks()
    Utils.Logger = {
        info = function(...) end,
        error = function(...) end,
        debug = function(...) end
    }
    -- Global mocks
    ParticleSystem = {burst = function() end, create = function() end}
    SoundManager = {playSound = function() end}
    -- Mock Utils.require for common dependencies
    local originalRequire = Utils.require
    Utils.require = function(module)
        if module == "src.systems.particle_system" then
            return ParticleSystem
        elseif module == "src.audio.sound_manager" then
            return SoundManager
        elseif module == "src.core.camera" then
            return {addEmotionalShake = function() end}
        elseif module == "src.core.game_state" then
            return {player = {x = 100, y = 200}}
        elseif module == "src.systems.achievement_system" then
            return {}
        end
        return originalRequire(module)
    end
end
-- Simple profiling function
local function timeFunction(name, func, iterations)
    iterations = iterations or 1000
    local startTime = os.clock()
    for i = 1, iterations do
        func()
    end
    local endTime = os.clock()
    local totalMs = (endTime - startTime) * 1000
    local avgMs = totalMs / iterations
    return {
        name = name,
        totalMs = totalMs,
        avgMs = avgMs,
        iterations = iterations
    }
end
-- Performance check results
local results = {}
local function runPerformanceCheck()
    print("🚀 Running Performance Check on Refactored Modules...")
    setupMocks()
    -- Test 1: Warp System Performance
    print("  🔍 Checking Warp Drive System...")
    local WarpCore = require("src.systems.warp.warp_core")
    local WarpEnergy = require("src.systems.warp.warp_energy")
    WarpCore.init()
    WarpEnergy.init()
    results.warpCoreUpdate = timeFunction("WarpCore.update", function()
        WarpCore.update(0.016)
    end, 5000)
    results.warpEnergyUpdate = timeFunction("WarpEnergy.update", function()
        WarpEnergy.update(0.016)
    end, 5000)
    -- Test 2: Emotional Feedback Performance
    print("  💝 Checking Emotional Feedback System...")
    local EmotionCore = require("src.systems.emotion.emotion_core")
    local EmotionalFeedback = require("src.systems.emotional_feedback")
    EmotionCore.init()
    EmotionalFeedback.init()
    results.emotionCoreUpdate = timeFunction("EmotionCore.update", function()
        EmotionCore.update(0.016)
    end, 5000)
    results.emotionalEventProcessing = timeFunction("EmotionalFeedback.processEvent", function()
        EmotionalFeedback.processEvent("jump", {pullPower = 0.7, success = true})
    end, 2000)
    -- Test 3: Player System Performance
    print("  🎮 Checking Player System...")
    local PlayerMovement = require("src.systems.player.player_movement")
    local PlayerAbilities = require("src.systems.player.player_abilities")
    PlayerMovement.init()
    PlayerAbilities.init()
    local testPlayer = {
        x = 100, y = 100, vx = 0, vy = 0, landed = false,
        jumpCooldown = 0, dashCooldown = 0, health = 100, energy = 100,
        powerUps = {}, trail = {points = {}}
    }
    results.playerAbilityCooldowns = timeFunction("PlayerAbilities.updateCooldowns", function()
        PlayerAbilities.updateCooldowns(testPlayer, 0.016)
    end, 5000)
    -- Test 4: Analytics Performance
    print("  📊 Checking Player Analytics System...")
    local BehaviorTracker = require("src.systems.analytics.behavior_tracker")
    BehaviorTracker.init()
    results.behaviorTrackerUpdate = timeFunction("BehaviorTracker.update", function()
        BehaviorTracker.update(0.016)
    end, 5000)
    print("✅ Performance check complete!")
end
-- Generate performance report
local function generateReport()
    print("\n" .. string.rep("=", 70))
    print("📊 REFACTORED MODULES PERFORMANCE REPORT")
    print(string.rep("=", 70))
    -- Sort results by average time
    local sortedResults = {}
    for _, result in pairs(results) do
        table.insert(sortedResults, result)
    end
    table.sort(sortedResults, function(a, b) return a.avgMs > b.avgMs end)
    print(string.format("%-30s | %10s | %12s | %10s", "Function", "Avg (ms)", "Total (ms)", "Iterations"))
    print(string.rep("-", 70))
    for _, result in ipairs(sortedResults) do
        local status = "✅"
        if result.avgMs > 0.1 then
            status = "⚠️ "
        elseif result.avgMs > 0.5 then
            status = "🚨"
        end
        print(string.format("%-30s | %9.4f | %11.2f | %10d %s",
            result.name, result.avgMs, result.totalMs, result.iterations, status))
    end
    print(string.rep("=", 70))
    -- Analysis
    local totalAvg = 0
    local hotspots = {}
    for _, result in ipairs(sortedResults) do
        totalAvg = totalAvg + result.avgMs
        if result.avgMs > 0.05 then
            table.insert(hotspots, result)
        end
    end
    totalAvg = totalAvg / #sortedResults
    print(string.format("📈 PERFORMANCE ANALYSIS:"))
    print(string.format("   Average execution time: %.4f ms per call", totalAvg))
    if #hotspots > 0 then
        print(string.format("   🔥 Performance hotspots found: %d", #hotspots))
        for i, hotspot in ipairs(hotspots) do
            print(string.format("      %d. %s (%.4f ms)", i, hotspot.name, hotspot.avgMs))
        end
    else
        print("   ✅ No significant performance hotspots detected")
    end
    -- Overall score
    local score
    if totalAvg < 0.01 then
        score = "🏆 EXCELLENT"
    elseif totalAvg < 0.05 then
        score = "✅ VERY GOOD"
    elseif totalAvg < 0.1 then
        score = "⚡ GOOD"
    else
        score = "⚠️  NEEDS OPTIMIZATION"
    end
    print(string.format("   🎯 Performance Grade: %s", score))
    print(string.rep("=", 70))
    -- Recommendations
    if #hotspots > 0 then
        print("💡 OPTIMIZATION RECOMMENDATIONS:")
        for _, hotspot in ipairs(hotspots) do
            print(string.format("   • Optimize %s - Currently %.4f ms per call", hotspot.name, hotspot.avgMs))
        end
    else
        print("✅ All refactored modules performing excellently!")
        print("💡 Focus optimization efforts on non-refactored systems if needed.")
    end
    print(string.rep("=", 70))
end
-- Main execution
runPerformanceCheck()
generateReport()