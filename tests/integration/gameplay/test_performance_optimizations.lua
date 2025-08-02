-- Tests for Performance Optimization Systems
-- Verifies texture atlas, LOD, and audio streaming optimizations

local TestFramework = require("tests.test_framework")
local Utils = require("src.utils.utils")

local PerformanceOptimizationTests = {
    ["texture atlas system initialization"] = function()
        -- Test texture atlas system initialization
        local TextureAtlasSystem = Utils.require("src.performance.texture_atlas_system")
        TestFramework.utils.assertNotNil(TextureAtlasSystem, "Texture atlas system should be available")
        
        -- Test initialization
        local success = pcall(function()
            TextureAtlasSystem.init()
        end)
        TestFramework.utils.assertTrue(success, "Texture atlas system should initialize without errors")
        
        -- Test atlas creation
        TestFramework.utils.assertNotNil(TextureAtlasSystem.atlases, "Atlases should be initialized")
        TestFramework.utils.assertNotNil(TextureAtlasSystem.spriteData, "Sprite data should be initialized")
    end,
    
    ["texture atlas sprite management"] = function()
        -- Test sprite management functionality
        local TextureAtlasSystem = Utils.require("src.performance.texture_atlas_system")
        
        -- Test sprite definitions
        TestFramework.utils.assertNotNil(TextureAtlasSystem.spriteDefinitions, "Sprite definitions should exist")
        TestFramework.utils.assertNotNil(TextureAtlasSystem.spriteDefinitions.player, "Player sprite should be defined")
        TestFramework.utils.assertNotNil(TextureAtlasSystem.spriteDefinitions.planet_small, "Planet sprite should be defined")
        
        -- Test sprite retrieval
        local playerSprite = TextureAtlasSystem.getSprite("player")
        TestFramework.utils.assertNotNil(playerSprite, "Player sprite should be retrievable")
        TestFramework.utils.assertEqual(32, playerSprite.width, "Player sprite should have correct width")
        TestFramework.utils.assertEqual(32, playerSprite.height, "Player sprite should have correct height")
    end,
    
    ["texture atlas statistics"] = function()
        -- Test atlas statistics
        local TextureAtlasSystem = Utils.require("src.performance.texture_atlas_system")
        
        local stats = TextureAtlasSystem.getStats()
        TestFramework.utils.assertNotNil(stats, "Atlas statistics should be available")
        TestFramework.utils.assertNotNil(stats.atlasCount, "Atlas count should be available")
        TestFramework.utils.assertNotNil(stats.spriteCount, "Sprite count should be available")
        TestFramework.utils.assertNotNil(stats.totalMemory, "Total memory usage should be available")
    end,
    
    ["LOD system initialization"] = function()
        -- Test LOD system initialization
        local LODSystem = Utils.require("src.performance.lod_system")
        TestFramework.utils.assertNotNil(LODSystem, "LOD system should be available")
        
        -- Test initialization
        local success = pcall(function()
            LODSystem.init()
        end)
        TestFramework.utils.assertTrue(success, "LOD system should initialize without errors")
        
        -- Test configuration
        TestFramework.utils.assertNotNil(LODSystem.config.distances, "LOD distances should be configured")
        TestFramework.utils.assertNotNil(LODSystem.config.quality, "LOD quality settings should be configured")
    end,
    
    ["LOD level calculation"] = function()
        -- Test LOD level calculation
        local LODSystem = Utils.require("src.performance.lod_system")
        
        -- Test distance-based LOD calculation
        local highLOD = LODSystem.calculateLOD(100, "planet")
        local mediumLOD = LODSystem.calculateLOD(750, "planet")
        local lowLOD = LODSystem.calculateLOD(1500, "planet")
        local cullLOD = LODSystem.calculateLOD(3500, "planet")
        
        TestFramework.utils.assertEqual("high", highLOD, "Close objects should have high LOD")
        TestFramework.utils.assertEqual("medium", mediumLOD, "Medium distance should have medium LOD")
        TestFramework.utils.assertEqual("low", lowLOD, "Far objects should have low LOD")
        TestFramework.utils.assertEqual("cull", cullLOD, "Very far objects should be culled")
    end,
    
    ["LOD settings retrieval"] = function()
        -- Test LOD settings retrieval
        local LODSystem = Utils.require("src.performance.lod_system")
        
        local highSettings = LODSystem.getLODSettings("planet", "high")
        local mediumSettings = LODSystem.getLODSettings("planet", "medium")
        local lowSettings = LODSystem.getLODSettings("planet", "low")
        
        TestFramework.utils.assertNotNil(highSettings, "High LOD settings should be available")
        TestFramework.utils.assertNotNil(mediumSettings, "Medium LOD settings should be available")
        TestFramework.utils.assertNotNil(lowSettings, "Low LOD settings should be available")
        
        TestFramework.utils.assertNotNil(highSettings.quality, "Quality settings should be available")
        TestFramework.utils.assertNotNil(highSettings.object, "Object settings should be available")
    end,
    
    ["LOD object optimization"] = function()
        -- Test LOD object optimization
        local LODSystem = Utils.require("src.performance.lod_system")
        
        -- Create test objects
        local objects = {
            { x = 100, y = 100, type = "planet" },
            { x = 1000, y = 1000, type = "ring" },
            { x = 2000, y = 2000, type = "particle" }
        }
        
        local camera = { x = 0, y = 0 }
        
        -- Test object LOD updates
        local updated, culled = LODSystem.updateObjectsLOD(objects, camera)
        TestFramework.utils.assertNotNil(updated, "Updated count should be available")
        TestFramework.utils.assertNotNil(culled, "Culled count should be available")
        
        -- Test visible objects
        local visible = LODSystem.getVisibleObjects(objects)
        TestFramework.utils.assertNotNil(visible, "Visible objects should be available")
    end,
    
    ["audio streaming system initialization"] = function()
        -- Test audio streaming system initialization
        local AudioStreamingSystem = Utils.require("src.performance.audio_streaming_system")
        TestFramework.utils.assertNotNil(AudioStreamingSystem, "Audio streaming system should be available")
        
        -- Test initialization
        local success = pcall(function()
            AudioStreamingSystem.init()
        end)
        TestFramework.utils.assertTrue(success, "Audio streaming system should initialize without errors")
        
        -- Test configuration
        TestFramework.utils.assertNotNil(AudioStreamingSystem.config.streaming, "Streaming config should be available")
        TestFramework.utils.assertNotNil(AudioStreamingSystem.config.quality, "Quality config should be available")
        TestFramework.utils.assertNotNil(AudioStreamingSystem.config.categories, "Categories config should be available")
    end,
    
    ["audio streaming source pool"] = function()
        -- Test audio source pool management
        local AudioStreamingSystem = Utils.require("src.performance.audio_streaming_system")
        
        -- Test source pool
        TestFramework.utils.assertNotNil(AudioStreamingSystem.sourcePool, "Source pool should be available")
        TestFramework.utils.assertNotNil(AudioStreamingSystem.sourcePool.available, "Available sources should be initialized")
        TestFramework.utils.assertNotNil(AudioStreamingSystem.sourcePool.inUse, "In-use sources should be initialized")
        
        -- Test source retrieval (mock test since we can't create real audio sources in test environment)
        local sourceCount = #AudioStreamingSystem.sourcePool.available
        TestFramework.utils.assertNotNil(sourceCount, "Source count should be available")
    end,
    
    ["audio streaming statistics"] = function()
        -- Test audio streaming statistics
        local AudioStreamingSystem = Utils.require("src.performance.audio_streaming_system")
        
        local stats = AudioStreamingSystem.getStats()
        TestFramework.utils.assertNotNil(stats, "Audio streaming statistics should be available")
        TestFramework.utils.assertNotNil(stats.qualityLevel, "Quality level should be available")
        TestFramework.utils.assertNotNil(stats.memoryUsage, "Memory usage should be available")
        TestFramework.utils.assertNotNil(stats.sourcePool, "Source pool stats should be available")
        TestFramework.utils.assertNotNil(stats.performance, "Performance metrics should be available")
    end,
    
    ["performance system integration"] = function()
        -- Test performance system integration
        local PerformanceSystem = Utils.require("src.performance.performance_system")
        TestFramework.utils.assertNotNil(PerformanceSystem, "Performance system should be available")
        
        -- Test initialization
        local success = pcall(function()
            PerformanceSystem.init()
        end)
        TestFramework.utils.assertTrue(success, "Performance system should initialize without errors")
        
        -- Test optimization systems
        TestFramework.utils.assertNotNil(PerformanceSystem.textureAtlas, "Texture atlas should be integrated")
        TestFramework.utils.assertNotNil(PerformanceSystem.lodSystem, "LOD system should be integrated")
        TestFramework.utils.assertNotNil(PerformanceSystem.audioStreaming, "Audio streaming should be integrated")
    end,
    
    ["performance optimization update"] = function()
        -- Test performance optimization update
        local PerformanceSystem = Utils.require("src.performance.performance_system")
        
        -- Test update function
        local success = pcall(function()
            PerformanceSystem.updateOptimizations(0.016) -- 60 FPS
        end)
        TestFramework.utils.assertTrue(success, "Performance optimization update should work without errors")
    end,
    
    ["comprehensive performance statistics"] = function()
        -- Test comprehensive performance statistics
        local PerformanceSystem = Utils.require("src.performance.performance_system")
        
        local stats = PerformanceSystem.getComprehensiveStats()
        TestFramework.utils.assertNotNil(stats, "Comprehensive stats should be available")
        TestFramework.utils.assertNotNil(stats.basic, "Basic stats should be available")
        TestFramework.utils.assertNotNil(stats.textureAtlas, "Texture atlas stats should be available")
        TestFramework.utils.assertNotNil(stats.lod, "LOD stats should be available")
        TestFramework.utils.assertNotNil(stats.audioStreaming, "Audio streaming stats should be available")
    end,
    
    ["performance system cleanup"] = function()
        -- Test performance system cleanup
        local PerformanceSystem = Utils.require("src.performance.performance_system")
        
        -- Test cleanup function
        local success = pcall(function()
            PerformanceSystem.cleanup()
        end)
        TestFramework.utils.assertTrue(success, "Performance system cleanup should work without errors")
    end
}

return PerformanceOptimizationTests 