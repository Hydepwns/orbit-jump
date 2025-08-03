--[[
    Performance Monitor: Real-time Monitoring with Educational Insights
    This combines real-time performance tracking with educational insights
    to help developers understand performance characteristics and learn
    optimization strategies.
    Design Philosophy:
    - Performance data without context is just noise
    - Every metric should teach something about optimization
    - Suggestions should be specific and actionable
    - The monitor itself should have near-zero overhead
    "In the pursuit of speed, understanding beats guessing every time."
--]]
local Utils = require("src.utils.utils")
local PerformanceMonitor = {}
-- Performance metrics
PerformanceMonitor.metrics = {
    fps = {
        current = 0,
        average = 0,
        min = math.huge,
        max = 0,
        samples = {}
    },
    frameTime = {
        current = 0,
        average = 0,
        min = math.huge,
        max = 0,
        samples = {}
    },
    memory = {
        current = 0,
        peak = 0
    },
    collisionChecks = {
        count = 0,
        time = 0
    },
    particleCount = {
        current = 0,
        peak = 0
    },
    updateTime = {
        total = 0,
        gameLogic = 0,
        rendering = 0,
        ui = 0
    }
}
-- Performance thresholds based on 60fps target (16.67ms budget)
PerformanceMonitor.THRESHOLDS = {
    frame_time = 16.67,           -- Total frame budget in ms
    update_time = 8.0,            -- Half budget for logic
    render_time = 8.0,            -- Half budget for rendering
    gc_allocation = 10,           -- KB allocated per frame before concern
    particle_update = 1.0,        -- Particle system budget
    collision_check = 2.0,        -- Collision detection budget
    state_management = 0.5        -- State updates should be quick
}
-- Educational insights for common performance patterns
PerformanceMonitor.INSIGHTS = {
    allocation_in_loop = {
        pattern = "Memory allocation detected in hot loop",
        explanation = "Creating tables or strings in loops triggers garbage collection",
        suggestion = "Pre-allocate tables outside loops, use table pools for temporary objects"
    },
    excessive_particles = {
        pattern = "Particle count exceeding performance budget",
        explanation = "Each particle requires position updates and rendering",
        suggestion = "Consider particle pooling, spatial culling, or LOD systems"
    },
    redundant_calculations = {
        pattern = "Same calculation performed multiple times per frame",
        explanation = "Recalculating values wastes precious CPU cycles",
        suggestion = "Cache results, use dirty flags, or move calculations outside loops"
    },
    unoptimized_collision = {
        pattern = "Collision checking all entities against all others",
        explanation = "O(n²) collision checks scale poorly with entity count",
        suggestion = "Implement spatial partitioning (quadtree/grid) for O(n log n) performance"
    }
}
-- Configuration
PerformanceMonitor.config = {
    enabled = true,
    sampleSize = 60, -- Number of samples to keep for averages
    logInterval = 5.0, -- Seconds between performance logs
    showOnScreen = false,
    trackMemory = true,
    trackCollisions = true,
    educationalMode = true -- Enable educational insights
}
-- Internal state
PerformanceMonitor.state = {
    lastLogTime = 0,
    frameCount = 0,
    lastFrameTime = 0,
    timers = {}
}
-- Timer utilities
function PerformanceMonitor.startTimer(name)
    if not PerformanceMonitor.config.enabled then return end
    PerformanceMonitor.state.timers[name] = love.timer.getTime()
end
function PerformanceMonitor.endTimer(name)
    if not PerformanceMonitor.config.enabled then return 0 end
    local startTime = PerformanceMonitor.state.timers[name]
    if startTime then
        local duration = love.timer.getTime() - startTime
        PerformanceMonitor.metrics.updateTime[name] = duration
        PerformanceMonitor.state.timers[name] = nil
        return duration
    end
    return 0
end
-- Update performance metrics
function PerformanceMonitor.update(dt)
    if not PerformanceMonitor.config.enabled then return end
    -- Update FPS metrics
    local currentFPS = 1 / dt
    PerformanceMonitor.metrics.fps.current = currentFPS
    PerformanceMonitor.metrics.fps.min = math.min(PerformanceMonitor.metrics.fps.min, currentFPS)
    PerformanceMonitor.metrics.fps.max = math.max(PerformanceMonitor.metrics.fps.max, currentFPS)
    table.insert(PerformanceMonitor.metrics.fps.samples, currentFPS)
    if #PerformanceMonitor.metrics.fps.samples > PerformanceMonitor.config.sampleSize then
        table.remove(PerformanceMonitor.metrics.fps.samples, 1)
    end
    -- Calculate average FPS
    local sum = 0
    for _, fps in ipairs(PerformanceMonitor.metrics.fps.samples) do
        sum = sum + fps
    end
    PerformanceMonitor.metrics.fps.average = sum / #PerformanceMonitor.metrics.fps.samples
    -- Update frame time metrics
    PerformanceMonitor.metrics.frameTime.current = dt * 1000 -- Convert to milliseconds
    PerformanceMonitor.metrics.frameTime.min = math.min(PerformanceMonitor.metrics.frameTime.min, dt * 1000)
    PerformanceMonitor.metrics.frameTime.max = math.max(PerformanceMonitor.metrics.frameTime.max, dt * 1000)
    table.insert(PerformanceMonitor.metrics.frameTime.samples, dt * 1000)
    if #PerformanceMonitor.metrics.frameTime.samples > PerformanceMonitor.config.sampleSize then
        table.remove(PerformanceMonitor.metrics.frameTime.samples, 1)
    end
    -- Calculate average frame time
    sum = 0
    for _, frameTime in ipairs(PerformanceMonitor.metrics.frameTime.samples) do
        sum = sum + frameTime
    end
    PerformanceMonitor.metrics.frameTime.average = sum / #PerformanceMonitor.metrics.frameTime.samples
    -- Update memory usage (if available)
    if PerformanceMonitor.config.trackMemory then
        local memUsage = collectgarbage("count") -- KB
        PerformanceMonitor.metrics.memory.current = memUsage
        PerformanceMonitor.metrics.memory.peak = math.max(PerformanceMonitor.metrics.memory.peak, memUsage)
    end
    -- Log performance periodically
    PerformanceMonitor.state.lastLogTime = PerformanceMonitor.state.lastLogTime + dt
    if PerformanceMonitor.state.lastLogTime >= PerformanceMonitor.config.logInterval then
        PerformanceMonitor.logPerformance()
        PerformanceMonitor.state.lastLogTime = 0
    end
end
-- Log performance metrics
function PerformanceMonitor.logPerformance()
    Utils.Logger.info("Performance Report:")
    Utils.Logger.info("  FPS: %.1f avg (%.1f min, %.1f max)",
        PerformanceMonitor.metrics.fps.average,
        PerformanceMonitor.metrics.fps.min,
        PerformanceMonitor.metrics.fps.max)
    Utils.Logger.info("  Frame Time: %.2fms avg (%.2f min, %.2f max)",
        PerformanceMonitor.metrics.frameTime.average,
        PerformanceMonitor.metrics.frameTime.min,
        PerformanceMonitor.metrics.frameTime.max)
    if PerformanceMonitor.config.trackMemory then
        Utils.Logger.info("  Memory: %.1f KB current, %.1f KB peak",
            PerformanceMonitor.metrics.memory.current,
            PerformanceMonitor.metrics.memory.peak)
    end
    if PerformanceMonitor.config.trackCollisions then
        Utils.Logger.info("  Collision Checks: %d (%.2fms)",
            PerformanceMonitor.metrics.collisionChecks.count,
            PerformanceMonitor.metrics.collisionChecks.time * 1000)
    end
    Utils.Logger.info("  Update Times: Game Logic %.2fms, Rendering %.2fms, UI %.2fms",
        PerformanceMonitor.metrics.updateTime.gameLogic * 1000,
        PerformanceMonitor.metrics.updateTime.rendering * 1000,
        PerformanceMonitor.metrics.updateTime.ui * 1000)
    Utils.Logger.info("  Particles: %d current, %d peak",
        PerformanceMonitor.metrics.particleCount.current,
        PerformanceMonitor.metrics.particleCount.peak)
end
-- Track collision checks
function PerformanceMonitor.trackCollision(startTime)
    if not PerformanceMonitor.config.enabled or not PerformanceMonitor.config.trackCollisions then return end
    PerformanceMonitor.metrics.collisionChecks.count = PerformanceMonitor.metrics.collisionChecks.count + 1
    PerformanceMonitor.metrics.collisionChecks.time = PerformanceMonitor.metrics.collisionChecks.time + (love.timer.getTime() - startTime)
end
-- Update particle count
function PerformanceMonitor.updateParticleCount(count)
    if not PerformanceMonitor.config.enabled then return end
    PerformanceMonitor.metrics.particleCount.current = count
    PerformanceMonitor.metrics.particleCount.peak = math.max(PerformanceMonitor.metrics.particleCount.peak, count)
end
-- Draw performance overlay
function PerformanceMonitor.draw()
    if not PerformanceMonitor.config.enabled or not PerformanceMonitor.config.showOnScreen then return end
    local x, y = 10, 10
    local lineHeight = 20
    -- Background
    Utils.setColor(Utils.colors.black, 0.7)
    love.graphics.rectangle("fill", x - 5, y - 5, 200, 120)
    -- Performance text
    Utils.setColor(Utils.colors.white, 1)
    love.graphics.print(string.format("FPS: %.1f", PerformanceMonitor.metrics.fps.current), x, y)
    love.graphics.print(string.format("Frame: %.1fms", PerformanceMonitor.metrics.frameTime.current), x, y + lineHeight)
    if PerformanceMonitor.config.trackMemory then
        love.graphics.print(string.format("Memory: %.1f KB", PerformanceMonitor.metrics.memory.current), x, y + lineHeight * 2)
    end
    love.graphics.print(string.format("Particles: %d", PerformanceMonitor.metrics.particleCount.current), x, y + lineHeight * 3)
    if PerformanceMonitor.config.trackCollisions then
        love.graphics.print(string.format("Collisions: %d", PerformanceMonitor.metrics.collisionChecks.count), x, y + lineHeight * 4)
    end
    -- Performance warnings
    if PerformanceMonitor.metrics.fps.current < 30 then
        Utils.setColor(Utils.colors.red, 1)
        love.graphics.print("LOW FPS WARNING", x, y + lineHeight * 5)
    elseif PerformanceMonitor.metrics.fps.current < 50 then
        Utils.setColor(Utils.colors.yellow, 1)
        love.graphics.print("PERFORMANCE WARNING", x, y + lineHeight * 5)
    end
end
-- Get performance report
function PerformanceMonitor.getReport()
    return {
        fps = {
            current = PerformanceMonitor.metrics.fps.current,
            average = PerformanceMonitor.metrics.fps.average,
            min = PerformanceMonitor.metrics.fps.min,
            max = PerformanceMonitor.metrics.fps.max
        },
        frameTime = {
            current = PerformanceMonitor.metrics.frameTime.current,
            average = PerformanceMonitor.metrics.frameTime.average,
            min = PerformanceMonitor.metrics.frameTime.min,
            max = PerformanceMonitor.metrics.frameTime.max
        },
        memory = {
            current = PerformanceMonitor.metrics.memory.current,
            peak = PerformanceMonitor.metrics.memory.peak
        },
        particles = {
            current = PerformanceMonitor.metrics.particleCount.current,
            peak = PerformanceMonitor.metrics.particleCount.peak
        },
        collisions = {
            count = PerformanceMonitor.metrics.collisionChecks.count,
            time = PerformanceMonitor.metrics.collisionChecks.time
        },
        updateTimes = PerformanceMonitor.metrics.updateTime
    }
end
-- Reset performance metrics
function PerformanceMonitor.reset()
    PerformanceMonitor.metrics.fps.min = math.huge
    PerformanceMonitor.metrics.fps.max = 0
    PerformanceMonitor.metrics.fps.samples = {}
    PerformanceMonitor.metrics.frameTime.min = math.huge
    PerformanceMonitor.metrics.frameTime.max = 0
    PerformanceMonitor.metrics.frameTime.samples = {}
    PerformanceMonitor.metrics.memory.peak = 0
    PerformanceMonitor.metrics.particleCount.peak = 0
    PerformanceMonitor.metrics.collisionChecks.count = 0
    PerformanceMonitor.metrics.collisionChecks.time = 0
    PerformanceMonitor.state.lastLogTime = 0
    PerformanceMonitor.state.frameCount = 0
    PerformanceMonitor.state.timers = {}
end
-- Initialize performance monitor
function PerformanceMonitor.init(config)
    if config then
        for k, v in pairs(config) do
            PerformanceMonitor.config[k] = v
        end
    end
    PerformanceMonitor.reset()
    Utils.Logger.info("Performance monitor initialized")
    return true
end
--[[
    Educational profiling with insights - from the Utils version
    This function measures not just time, but provides context about why
    performance matters and how to improve it.
--]]
function PerformanceMonitor.profile(name, fn, ...)
    if not PerformanceMonitor.config.educationalMode then
        return fn(...)
    end
    local startTime = love.timer.getTime()
    local startMem = collectgarbage("count")
    -- Execute the function
    local results = {fn(...)}
    local duration = (love.timer.getTime() - startTime) * 1000  -- Convert to ms
    local memDelta = collectgarbage("count") - startMem
    -- Generate educational insights based on performance characteristics
    if PerformanceMonitor.config.educationalMode then
        local insight = PerformanceMonitor.generateInsight(name, duration, memDelta)
        if insight then
            Utils.Logger.info("Performance Insight [%s]: %s", name, insight.message)
            if insight.suggestions then
                for i, suggestion in ipairs(insight.suggestions) do
                    Utils.Logger.info("  Suggestion %d: %s", i, suggestion)
                end
            end
        end
    end
    local unpack = table.unpack or unpack
    return unpack and unpack(results) or results[1], results[2], results[3]
end
--[[
    Generate contextual insights based on performance patterns
    This is where the monitor becomes a teacher, explaining not just what
    is slow, but why it's slow and how to fix it.
--]]
function PerformanceMonitor.generateInsight(name, duration, memory)
    -- Check against known thresholds
    local threshold = PerformanceMonitor.THRESHOLDS[name]
    if name == "particle_update" and duration > PerformanceMonitor.THRESHOLDS.particle_update then
        return {
            type = "particle_performance",
            severity = duration > threshold * 2 and "critical" or "warning",
            message = string.format("Particle update taking %.2fms (budget: %.2fms)", duration, threshold),
            explanation = "Particle systems can quickly consume frame budget with high counts",
            suggestions = {
                "Reduce particle count or lifetime",
                "Implement particle LOD (fewer particles when zoomed out)",
                "Use spatial partitioning to update only visible particles",
                "Consider GPU-based particle systems for massive counts"
            }
        }
    elseif name == "collision_check" and memory > PerformanceMonitor.THRESHOLDS.gc_allocation then
        return {
            type = "collision_allocation",
            severity = "warning",
            message = string.format("Collision detection allocating %.1fKB per frame", memory),
            explanation = "Memory allocation in collision detection causes GC pressure",
            suggestions = {
                "Pre-allocate collision result tables",
                "Use object pools for temporary vectors",
                "Avoid creating new tables for collision pairs"
            }
        }
    elseif duration > PerformanceMonitor.THRESHOLDS.frame_time then
        return {
            type = "frame_budget_exceeded",
            severity = "critical",
            message = string.format("%s exceeded frame budget: %.2fms (limit: %.2fms)",
                                  name, duration, PerformanceMonitor.THRESHOLDS.frame_time),
            explanation = "Function is consuming too much of the 16.67ms frame budget",
            suggestions = {
                "Profile sub-functions to find bottlenecks",
                "Consider spreading work across multiple frames",
                "Look for algorithmic improvements",
                "Use early-exit optimizations where possible"
            }
        }
    end
    return nil
end
--[[
    Educational helper: Explain a performance concept
--]]
function PerformanceMonitor.explainConcept(concept)
    local concepts = {
        frame_budget = [[
The Frame Budget: Your 16.67ms Allowance
At 60 FPS, each frame must complete in 16.67ms (1000ms / 60).
This includes:
1. Processing input
2. Updating game state
3. Running physics
4. Checking collisions
5. Rendering everything
6. Garbage collection
Going over budget causes stuttering and poor game feel.]],
        garbage_collection = [[
Garbage Collection in Lua: The Hidden Performance Killer
Lua automatically manages memory, but this comes at a cost:
- Creating tables/strings generates garbage
- GC runs periodically to clean up
- GC can cause frame spikes
Strategies:
1. Pre-allocate and reuse objects
2. Use object pools for temporary data
3. Avoid string concatenation in loops
4. Monitor allocation with collectgarbage("count")]],
        optimization_order = [[
Optimization Priority: Where to Start
1. Profile first - don't guess!
2. Optimize the hottest paths (most time spent)
3. Reduce algorithmic complexity (O(n²) → O(n log n))
4. Minimize allocations in loops
5. Cache expensive calculations
6. Only then consider micro-optimizations
Remember: Premature optimization is evil, but
necessary optimization is divine.]]
    }
    return concepts[concept] or "Concept not found. Available: " .. table.concat(Utils.getKeys(concepts), ", ")
end
return PerformanceMonitor