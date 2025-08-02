-- Performance Optimization Systems Demo
-- Demonstrates texture atlas, LOD, and audio streaming optimizations

local Utils = require("src.utils.utils")
local TextureAtlasSystem = require("src.performance.texture_atlas_system")
local LODSystem = require("src.performance.lod_system")
local AudioStreamingSystem = require("src.performance.audio_streaming_system")
local PerformanceSystem = require("src.performance.performance_system")

print("🚀 Performance Optimization Systems Demo")
print("========================================")

-- Initialize all performance systems
print("1. Initializing performance optimization systems...")

TextureAtlasSystem.init()
print("   ✅ Texture Atlas System initialized")

LODSystem.init()
print("   ✅ LOD System initialized")

AudioStreamingSystem.init()
print("   ✅ Audio Streaming System initialized")

PerformanceSystem.init()
print("   ✅ Performance System initialized")

-- Demonstrate Texture Atlas System
print("\n2. Texture Atlas System:")
local atlasStats = TextureAtlasSystem.getStats()
print("   - Atlases created: " .. atlasStats.atlasCount)
print("   - Sprites packed: " .. atlasStats.spriteCount)
print("   - Memory usage: " .. string.format("%.2f MB", atlasStats.totalMemory / (1024 * 1024)))

-- Show sprite definitions
print("   - Available sprites:")
for name, def in pairs(TextureAtlasSystem.spriteDefinitions) do
    print("     • " .. name .. " (" .. def.width .. "x" .. def.height .. ")")
end

-- Demonstrate LOD System
print("\n3. LOD (Level of Detail) System:")
print("   - Distance thresholds:")
for level, distance in pairs(LODSystem.config.distances) do
    print("     • " .. level .. ": " .. distance .. "px")
end

-- Test LOD calculations
local testDistances = {100, 750, 1500, 3500}
print("   - LOD level examples:")
for _, distance in ipairs(testDistances) do
    local lodLevel = LODSystem.calculateLOD(distance, "planet")
    print("     • " .. distance .. "px → " .. lodLevel .. " LOD")
end

-- Show quality settings
print("   - Quality settings:")
for level, settings in pairs(LODSystem.config.quality) do
    print("     • " .. level .. ": " .. 
          string.format("particles=%.1f, detail=%.1f, animation=%.1f", 
          settings.particleCount, settings.detailLevel, settings.animationSpeed))
end

-- Demonstrate Audio Streaming System
print("\n4. Audio Streaming System:")
print("   - Streaming configuration:")
for setting, value in pairs(AudioStreamingSystem.config.streaming) do
    if type(value) == "boolean" then
        print("     • " .. setting .. ": " .. (value and "enabled" or "disabled"))
    else
        print("     • " .. setting .. ": " .. tostring(value))
    end
end

-- Show audio categories
print("   - Audio categories:")
for category, settings in pairs(AudioStreamingSystem.config.categories) do
    print("     • " .. category .. ": priority=" .. settings.priority .. 
          ", streaming=" .. tostring(settings.streaming) .. 
          ", quality=" .. settings.quality)
end

-- Show quality levels
print("   - Audio quality levels:")
for level, settings in pairs(AudioStreamingSystem.config.quality) do
    print("     • " .. level .. ": " .. settings.sampleRate .. "Hz, " .. 
          settings.bitDepth .. "bit, " .. settings.channels .. "ch")
end

-- Demonstrate Performance System Integration
print("\n5. Performance System Integration:")
local perfStats = PerformanceSystem.getComprehensiveStats()
print("   - Basic performance metrics:")
print("     • Visible planets: " .. (perfStats.basic.visiblePlanets or 0))
print("     • Visible rings: " .. (perfStats.basic.visibleRings or 0))
print("     • Active particles: " .. (perfStats.basic.activeParticles or 0))

-- Show optimization system status
print("   - Optimization systems:")
print("     • Texture Atlas: " .. (PerformanceSystem.textureAtlas and "✅ Active" or "❌ Inactive"))
print("     • LOD System: " .. (PerformanceSystem.lodSystem and "✅ Active" or "❌ Inactive"))
print("     • Audio Streaming: " .. (PerformanceSystem.audioStreaming and "✅ Active" or "❌ Inactive"))

-- Demonstrate performance optimization
print("\n6. Performance Optimization Demo:")
print("   - Simulating performance optimization...")

-- Simulate different performance scenarios
local scenarios = {
    { name = "High Performance", frameTime = 12 },
    { name = "Medium Performance", frameTime = 18 },
    { name = "Low Performance", frameTime = 25 }
}

for _, scenario in ipairs(scenarios) do
    print("   - " .. scenario.name .. " (" .. scenario.frameTime .. "ms):")
    
    -- Simulate LOD adjustment
    LODSystem.adjustForPerformance(scenario.frameTime, 16.67)
    print("     • LOD distances adjusted for performance")
    
    -- Simulate audio quality adjustment
    AudioStreamingSystem.state.performanceMetrics.averageFrameTime = scenario.frameTime
    AudioStreamingSystem.adjustQualityForPerformance()
    print("     • Audio quality: " .. AudioStreamingSystem.state.qualityLevel)
end

-- Show final statistics
print("\n7. Final System Statistics:")

-- Texture Atlas stats
local finalAtlasStats = TextureAtlasSystem.getStats()
print("   - Texture Atlas:")
print("     • Memory usage: " .. string.format("%.2f MB", finalAtlasStats.totalMemory / (1024 * 1024)))
print("     • Efficiency: " .. string.format("%.1f%%", (finalAtlasStats.spriteCount / finalAtlasStats.atlasCount) * 100))

-- LOD stats
local finalLODStats = LODSystem.getStats()
print("   - LOD System:")
print("     • Cache size: " .. finalLODStats.cacheSize)
print("     • Objects by LOD: " .. 
      "high=" .. finalLODStats.objectsByLOD.high .. 
      ", medium=" .. finalLODStats.objectsByLOD.medium .. 
      ", low=" .. finalLODStats.objectsByLOD.low .. 
      ", culled=" .. finalLODStats.objectsByLOD.culled)

-- Audio Streaming stats
local finalAudioStats = AudioStreamingSystem.getStats()
print("   - Audio Streaming:")
print("     • Quality level: " .. finalAudioStats.qualityLevel)
print("     • Memory usage: " .. string.format("%.2f MB", finalAudioStats.memoryUsage / (1024 * 1024)))
print("     • Source pool: " .. finalAudioStats.sourcePool.available .. " available, " .. 
      finalAudioStats.sourcePool.inUse .. " in use")
print("     • Cache hits: " .. finalAudioStats.performance.cacheHits .. 
      ", misses: " .. finalAudioStats.performance.cacheMisses)

-- Performance benefits summary
print("\n8. Performance Benefits Summary:")
print("   ✅ Reduced draw calls through texture atlasing")
print("   ✅ Adaptive detail levels for distant objects")
print("   ✅ Efficient audio resource management")
print("   ✅ Dynamic quality adjustment based on performance")
print("   ✅ Intelligent caching and preloading")
print("   ✅ Memory usage optimization")

print("\n🎉 Performance Optimization Demo Complete!")
print("All systems are ready for production use in Orbit Jump.") 