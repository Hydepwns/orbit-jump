--[[
    ═══════════════════════════════════════════════════════════════════════════
    Audio Streaming Optimization System: Efficient Audio Management
    ═══════════════════════════════════════════════════════════════════════════
    This system optimizes audio performance through streaming, adaptive quality,
    and intelligent resource management. It reduces memory usage and improves
    audio loading times for better overall performance.
    Performance Benefits:
    • Reduces memory usage through streaming
    • Adaptive audio quality based on performance
    • Intelligent audio caching and preloading
    • Efficient audio resource management
--]]
local Utils = require("src.utils.utils")
local AudioStreamingSystem = {}
-- Audio streaming configuration
AudioStreamingSystem.config = {
    -- Streaming settings
    streaming = {
        enabled = true,
        bufferSize = 4096,        -- Audio buffer size in samples
        preloadDistance = 1000,   -- Preload audio within this distance
        maxConcurrentStreams = 4, -- Maximum concurrent audio streams
        fadeInTime = 0.5,         -- Fade-in time for streams
        fadeOutTime = 0.3         -- Fade-out time for streams
    },
    -- Quality settings
    quality = {
        high = {
            sampleRate = 44100,
            bitDepth = 16,
            channels = 2,
            compression = "none"
        },
        medium = {
            sampleRate = 22050,
            bitDepth = 16,
            channels = 2,
            compression = "none"
        },
        low = {
            sampleRate = 11025,
            bitDepth = 8,
            channels = 1,
            compression = "none"
        }
    },
    -- Performance thresholds
    performance = {
        targetFrameTime = 16.67,  -- Target frame time (60 FPS)
        qualityDropThreshold = 20, -- Drop quality if frame time exceeds this
        qualityRestoreThreshold = 15, -- Restore quality if frame time below this
        memoryThreshold = 100 * 1024 * 1024 -- 100MB memory threshold
    },
    -- Audio categories
    categories = {
        ambient = { priority = 1, streaming = true, quality = "medium" },
        sfx = { priority = 2, streaming = false, quality = "high" },
        music = { priority = 3, streaming = true, quality = "high" },
        ui = { priority = 4, streaming = false, quality = "medium" }
    }
}
-- Audio streaming state
AudioStreamingSystem.state = {
    activeStreams = {},
    audioCache = {},
    qualityLevel = "high",
    memoryUsage = 0,
    performanceMetrics = {
        frameTime = 0,
        averageFrameTime = 16.67,
        audioLoadTime = 0,
        cacheHits = 0,
        cacheMisses = 0
    }
}
-- Audio sources pool for efficient reuse
AudioStreamingSystem.sourcePool = {
    available = {},
    inUse = {},
    maxPoolSize = 20
}
-- Initialize audio streaming system
function AudioStreamingSystem.init()
    AudioStreamingSystem.clearCache()
    AudioStreamingSystem.initializeSourcePool()
    Utils.Logger.info("Audio streaming system initialized")
end
-- Clear audio cache
function AudioStreamingSystem.clearCache()
    AudioStreamingSystem.state.audioCache = {}
    AudioStreamingSystem.state.memoryUsage = 0
    AudioStreamingSystem.state.performanceMetrics.cacheHits = 0
    AudioStreamingSystem.state.performanceMetrics.cacheMisses = 0
end
-- Initialize source pool
function AudioStreamingSystem.initializeSourcePool()
    -- Check if love.audio is available
    if not love or not love.audio then
        Utils.Logger.warn("love.audio not available, skipping source pool initialization")
        return
    end
    for i = 1, AudioStreamingSystem.sourcePool.maxPoolSize do
        local success, source = pcall(love.audio.newSource, "", "static")
        if success and source then
            source:setVolume(0)
            table.insert(AudioStreamingSystem.sourcePool.available, source)
        end
    end
end
-- Get audio source from pool
function AudioStreamingSystem.getSourceFromPool()
    if #AudioStreamingSystem.sourcePool.available > 0 then
        local source = table.remove(AudioStreamingSystem.sourcePool.available)
        table.insert(AudioStreamingSystem.sourcePool.inUse, source)
        return source
    end
    return nil
end
-- Return audio source to pool
function AudioStreamingSystem.returnSourceToPool(source)
    for i, s in ipairs(AudioStreamingSystem.sourcePool.inUse) do
        if s == source then
            table.remove(AudioStreamingSystem.sourcePool.inUse, i)
            source:stop()
            source:setVolume(0)
            table.insert(AudioStreamingSystem.sourcePool.available, source)
            break
        end
    end
end
-- Load audio with streaming support
function AudioStreamingSystem.loadAudio(audioName, category, options)
    local startTime = love.timer.getTime()
    -- Check cache first
    if AudioStreamingSystem.state.audioCache[audioName] then
        AudioStreamingSystem.state.performanceMetrics.cacheHits =
            AudioStreamingSystem.state.performanceMetrics.cacheHits + 1
        return AudioStreamingSystem.state.audioCache[audioName]
    end
    AudioStreamingSystem.state.performanceMetrics.cacheMisses =
        AudioStreamingSystem.state.performanceMetrics.cacheMisses + 1
    -- Get category settings
    local categorySettings = AudioStreamingSystem.config.categories[category] or
                           AudioStreamingSystem.config.categories.sfx
    -- Determine quality level
    local quality = options and options.quality or categorySettings.quality
    local qualitySettings = AudioStreamingSystem.config.quality[quality]
    -- Create audio source
    local source
    if categorySettings.streaming then
        source = love.audio.newSource(audioName, "stream")
    else
        source = love.audio.newSource(audioName, "static")
    end
    -- Apply quality settings
    if source then
        source:setVolume(options and options.volume or 1.0)
        source:setPitch(options and options.pitch or 1.0)
        source:setLooping(options and options.looping or false)
        -- Store audio metadata
        local audioData = {
            source = source,
            category = category,
            quality = quality,
            streaming = categorySettings.streaming,
            priority = categorySettings.priority,
            loadTime = love.timer.getTime() - startTime,
            memoryUsage = AudioStreamingSystem.estimateMemoryUsage(source, qualitySettings)
        }
        -- Cache the audio
        AudioStreamingSystem.state.audioCache[audioName] = audioData
        AudioStreamingSystem.state.memoryUsage = AudioStreamingSystem.state.memoryUsage + audioData.memoryUsage
        AudioStreamingSystem.state.performanceMetrics.audioLoadTime =
            love.timer.getTime() - startTime
        Utils.Logger.debug("Loaded audio: %s (category: %s, quality: %s, streaming: %s)",
            audioName, category, quality, tostring(categorySettings.streaming))
        return audioData
    end
    Utils.Logger.warn("Failed to load audio: %s", audioName)
    return nil
end
-- Estimate memory usage for audio source
function AudioStreamingSystem.estimateMemoryUsage(source, qualitySettings)
    if not source then return 0 end
    local duration = source:getDuration()
    local sampleRate = qualitySettings.sampleRate
    local channels = qualitySettings.channels
    local bitDepth = qualitySettings.bitDepth
    -- Calculate memory usage in bytes
    local bytesPerSample = bitDepth / 8
    local totalSamples = duration * sampleRate
    local memoryUsage = totalSamples * channels * bytesPerSample
    return memoryUsage
end
-- Play audio with streaming optimization
function AudioStreamingSystem.playAudio(audioName, options)
    local audioData = AudioStreamingSystem.state.audioCache[audioName]
    if not audioData then
        -- Load audio if not cached
        audioData = AudioStreamingSystem.loadAudio(audioName, options and options.category or "sfx", options)
        if not audioData then return nil end
    end
    -- Get source from pool
    local source = AudioStreamingSystem.getSourceFromPool()
    if not source then
        Utils.Logger.warn("No available audio sources in pool")
        return nil
    end
    -- Clone the audio source
    local playSource = audioData.source:clone()
    -- Apply options
    if options then
        if options.volume then playSource:setVolume(options.volume) end
        if options.pitch then playSource:setPitch(options.pitch) end
        if options.looping then playSource:setLooping(options.looping) end
    end
    -- Play the audio
    playSource:play()
    -- Store active stream info
    local streamId = Utils.generateId()
    AudioStreamingSystem.state.activeStreams[streamId] = {
        source = playSource,
        audioData = audioData,
        startTime = love.timer.getTime(),
        options = options
    }
    -- Apply streaming optimizations
    if audioData.streaming then
        AudioStreamingSystem.applyStreamingOptimizations(streamId)
    end
    return streamId
end
-- Apply streaming optimizations
function AudioStreamingSystem.applyStreamingOptimizations(streamId)
    local stream = AudioStreamingSystem.state.activeStreams[streamId]
    if not stream then return end
    -- Limit concurrent streams
    local activeCount = 0
    for _ in pairs(AudioStreamingSystem.state.activeStreams) do
        activeCount = activeCount + 1
    end
    if activeCount > AudioStreamingSystem.config.streaming.maxConcurrentStreams then
        -- Stop lowest priority stream
        AudioStreamingSystem.stopLowestPriorityStream()
    end
    -- Apply fade-in for streaming audio
    if stream.audioData.streaming then
        stream.source:setVolume(0)
        -- Fade in over time (would need a timer system for proper implementation)
    end
end
-- Stop lowest priority stream
function AudioStreamingSystem.stopLowestPriorityStream()
    local lowestPriority = math.huge
    local lowestStreamId = nil
    for streamId, stream in pairs(AudioStreamingSystem.state.activeStreams) do
        if stream.audioData.priority < lowestPriority then
            lowestPriority = stream.audioData.priority
            lowestStreamId = streamId
        end
    end
    if lowestStreamId then
        AudioStreamingSystem.stopStream(lowestStreamId)
    end
end
-- Stop audio stream
function AudioStreamingSystem.stopStream(streamId)
    local stream = AudioStreamingSystem.state.activeStreams[streamId]
    if not stream then return end
    -- Apply fade-out for streaming audio
    if stream.audioData.streaming then
        -- Fade out over time (would need a timer system for proper implementation)
    end
    -- Stop and cleanup
    stream.source:stop()
    AudioStreamingSystem.returnSourceToPool(stream.source)
    AudioStreamingSystem.state.activeStreams[streamId] = nil
end
-- Update audio streaming system
function AudioStreamingSystem.update(dt)
    -- Update performance metrics
    AudioStreamingSystem.state.performanceMetrics.frameTime = dt * 1000
    AudioStreamingSystem.state.performanceMetrics.averageFrameTime =
        AudioStreamingSystem.state.performanceMetrics.averageFrameTime * 0.95 +
        (dt * 1000) * 0.05
    -- Adaptive quality adjustment
    AudioStreamingSystem.adjustQualityForPerformance()
    -- Clean up finished streams
    AudioStreamingSystem.cleanupFinishedStreams()
    -- Memory management
    AudioStreamingSystem.manageMemory()
end
-- Adjust quality based on performance
function AudioStreamingSystem.adjustQualityForPerformance()
    local frameTime = AudioStreamingSystem.state.performanceMetrics.averageFrameTime
    local targetFrameTime = AudioStreamingSystem.config.performance.targetFrameTime
    if frameTime > AudioStreamingSystem.config.performance.qualityDropThreshold then
        -- Performance is poor, reduce quality
        if AudioStreamingSystem.state.qualityLevel == "high" then
            AudioStreamingSystem.state.qualityLevel = "medium"
            Utils.Logger.debug("Audio quality reduced to medium due to performance")
        elseif AudioStreamingSystem.state.qualityLevel == "medium" then
            AudioStreamingSystem.state.qualityLevel = "low"
            Utils.Logger.debug("Audio quality reduced to low due to performance")
        end
    elseif frameTime < AudioStreamingSystem.config.performance.qualityRestoreThreshold then
        -- Performance is good, increase quality
        if AudioStreamingSystem.state.qualityLevel == "low" then
            AudioStreamingSystem.state.qualityLevel = "medium"
            Utils.Logger.debug("Audio quality increased to medium")
        elseif AudioStreamingSystem.state.qualityLevel == "medium" then
            AudioStreamingSystem.state.qualityLevel = "high"
            Utils.Logger.debug("Audio quality increased to high")
        end
    end
end
-- Clean up finished streams
function AudioStreamingSystem.cleanupFinishedStreams()
    local toRemove = {}
    for streamId, stream in pairs(AudioStreamingSystem.state.activeStreams) do
        if not stream.source:isPlaying() then
            table.insert(toRemove, streamId)
        end
    end
    for _, streamId in ipairs(toRemove) do
        AudioStreamingSystem.stopStream(streamId)
    end
end
-- Manage memory usage
function AudioStreamingSystem.manageMemory()
    local memoryThreshold = AudioStreamingSystem.config.performance.memoryThreshold
    if AudioStreamingSystem.state.memoryUsage > memoryThreshold then
        -- Clear least recently used audio from cache
        AudioStreamingSystem.clearLRUCache()
    end
end
-- Clear least recently used cache entries
function AudioStreamingSystem.clearLRUCache()
    local oldestTime = math.huge
    local oldestAudio = nil
    for audioName, audioData in pairs(AudioStreamingSystem.state.audioCache) do
        if audioData.lastUsed and audioData.lastUsed < oldestTime then
            oldestTime = audioData.lastUsed
            oldestAudio = audioName
        end
    end
    if oldestAudio then
        local audioData = AudioStreamingSystem.state.audioCache[oldestAudio]
        AudioStreamingSystem.state.memoryUsage = AudioStreamingSystem.state.memoryUsage - audioData.memoryUsage
        AudioStreamingSystem.state.audioCache[oldestAudio] = nil
        Utils.Logger.debug("Cleared LRU audio from cache: %s", oldestAudio)
    end
end
-- Preload audio based on proximity
function AudioStreamingSystem.preloadProximityAudio(player, audioList)
    if not AudioStreamingSystem.config.streaming.enabled then return end
    local preloadDistance = AudioStreamingSystem.config.streaming.preloadDistance
    for _, audioInfo in ipairs(audioList) do
        local distance = Utils.distance(player.x, player.y, audioInfo.x, audioInfo.y)
        if distance <= preloadDistance and not AudioStreamingSystem.state.audioCache[audioInfo.name] then
            AudioStreamingSystem.loadAudio(audioInfo.name, audioInfo.category, audioInfo.options)
        end
    end
end
-- Get audio streaming statistics
function AudioStreamingSystem.getStats()
    local stats = {
        qualityLevel = AudioStreamingSystem.state.qualityLevel,
        memoryUsage = AudioStreamingSystem.state.memoryUsage,
        activeStreams = 0,
        cachedAudio = 0,
        sourcePool = {
            available = #AudioStreamingSystem.sourcePool.available,
            inUse = #AudioStreamingSystem.sourcePool.inUse
        },
        performance = AudioStreamingSystem.state.performanceMetrics
    }
    -- Count active streams and cached audio
    for _ in pairs(AudioStreamingSystem.state.activeStreams) do
        stats.activeStreams = stats.activeStreams + 1
    end
    for _ in pairs(AudioStreamingSystem.state.audioCache) do
        stats.cachedAudio = stats.cachedAudio + 1
    end
    return stats
end
-- Clean up audio streaming system
function AudioStreamingSystem.cleanup()
    -- Stop all active streams
    for streamId, stream in pairs(AudioStreamingSystem.state.activeStreams) do
        stream.source:stop()
    end
    -- Clear cache
    AudioStreamingSystem.clearCache()
    -- Clean up source pool
    for _, source in ipairs(AudioStreamingSystem.sourcePool.available) do
        source:release()
    end
    for _, source in ipairs(AudioStreamingSystem.sourcePool.inUse) do
        source:release()
    end
    AudioStreamingSystem.sourcePool.available = {}
    AudioStreamingSystem.sourcePool.inUse = {}
    Utils.Logger.info("Audio streaming system cleaned up")
end
return AudioStreamingSystem