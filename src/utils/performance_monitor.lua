--[[
    Performance Monitor: Teaching Through Measurement
    
    This isn't just a profiler - it's an educational tool that helps developers
    understand performance characteristics and learn optimization strategies.
    Every measurement comes with insights and actionable suggestions.
    
    Design Philosophy:
    - Performance data without context is just noise
    - Every metric should teach something about optimization
    - Suggestions should be specific and actionable
    - The monitor itself should have near-zero overhead
    
    "In the pursuit of speed, understanding beats guessing every time."
--]]

local Utils = require("src.utils.utils")

local PerformanceMonitor = {
    -- Metric storage with educational context
    metrics = {},
    
    -- Performance thresholds based on 60fps target (16.67ms budget)
    THRESHOLDS = {
        frame_time = 16.67,           -- Total frame budget in ms
        update_time = 8.0,            -- Half budget for logic
        render_time = 8.0,            -- Half budget for rendering
        gc_allocation = 10,           -- KB allocated per frame before concern
        particle_update = 1.0,        -- Particle system budget
        collision_check = 2.0,        -- Collision detection budget
        state_management = 0.5        -- State updates should be quick
    },
    
    -- Educational insights for common performance patterns
    INSIGHTS = {
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
}

--[[
    Profile a function execution with educational insights
    
    This function measures not just time, but provides context about why
    performance matters and how to improve it.
--]]
function PerformanceMonitor.profile(name, fn, ...)
    local startTime = love.timer.getTime()
    local startMem = collectgarbage("count")
    
    -- Execute the function
    local results = {fn(...)}
    
    local duration = (love.timer.getTime() - startTime) * 1000  -- Convert to ms
    local memDelta = collectgarbage("count") - startMem
    
    -- Store metric with context
    if not PerformanceMonitor.metrics[name] then
        PerformanceMonitor.metrics[name] = {
            samples = {},
            totalTime = 0,
            totalMemory = 0,
            callCount = 0,
            insights = {}
        }
    end
    
    local metric = PerformanceMonitor.metrics[name]
    metric.callCount = metric.callCount + 1
    metric.totalTime = metric.totalTime + duration
    metric.totalMemory = metric.totalMemory + memDelta
    
    -- Keep rolling window of samples for trend analysis
    table.insert(metric.samples, {
        time = duration,
        memory = memDelta,
        timestamp = love.timer.getTime()
    })
    
    -- Limit sample history to last 60 frames
    if #metric.samples > 60 then
        table.remove(metric.samples, 1)
    end
    
    -- Generate insights based on performance characteristics
    local insight = PerformanceMonitor.generateInsight(name, duration, memDelta, metric)
    if insight then
        metric.insights[insight.type] = insight
    end
    
    return unpack(results)
end

--[[
    Generate contextual insights based on performance patterns
    
    This is where the monitor becomes a teacher, explaining not just what
    is slow, but why it's slow and how to fix it.
--]]
function PerformanceMonitor.generateInsight(name, duration, memory, metric)
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
            },
            code_example = [[
-- Instead of updating all particles:
for i = 1, #particles do
    updateParticle(particles[i])
end

-- Use spatial partitioning:
local visibleParticles = spatialGrid:getVisible(camera.bounds)
for i = 1, #visibleParticles do
    updateParticle(visibleParticles[i])
end]]
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
            },
            code_example = [[
-- Avoid allocating in loops:
local collision = {x = obj1.x - obj2.x, y = obj1.y - obj2.y}  -- BAD

-- Pre-allocate and reuse:
local tempVector = {x = 0, y = 0}  -- Module level
tempVector.x = obj1.x - obj2.x      -- Reuse in function
tempVector.y = obj1.y - obj2.y]]
        }
    elseif duration > 0 and metric.callCount > 60 then
        -- Analyze trends over time
        local avgTime = metric.totalTime / metric.callCount
        local recentAvg = 0
        local recentCount = math.min(10, #metric.samples)
        
        for i = #metric.samples - recentCount + 1, #metric.samples do
            recentAvg = recentAvg + metric.samples[i].time
        end
        recentAvg = recentAvg / recentCount
        
        -- Detect performance degradation
        if recentAvg > avgTime * 1.5 then
            return {
                type = "performance_degradation",
                severity = "warning",
                message = string.format("%s performance degrading: %.2fms recent vs %.2fms average", 
                                      name, recentAvg, avgTime),
                explanation = "Performance is getting worse over time, indicating a leak or scaling issue",
                suggestions = {
                    "Check for growing data structures",
                    "Look for O(n²) algorithms with increasing n",
                    "Verify cleanup/pooling is working correctly",
                    "Profile memory usage for leaks"
                }
            }
        end
    end
    
    return nil
end

--[[
    Get performance summary with actionable recommendations
    
    This provides a holistic view of performance with prioritized
    recommendations for optimization.
--]]
function PerformanceMonitor.getSummary()
    local summary = {
        metrics = {},
        recommendations = {},
        learningPoints = {}
    }
    
    -- Analyze each metric
    for name, metric in pairs(PerformanceMonitor.metrics) do
        if metric.callCount > 0 then
            local avgTime = metric.totalTime / metric.callCount
            local avgMemory = metric.totalMemory / metric.callCount
            
            summary.metrics[name] = {
                averageTime = avgTime,
                totalTime = metric.totalTime,
                averageMemory = avgMemory,
                totalMemory = metric.totalMemory,
                callCount = metric.callCount,
                insights = metric.insights
            }
        end
    end
    
    -- Generate prioritized recommendations
    local totalFrameTime = 0
    for name, data in pairs(summary.metrics) do
        totalFrameTime = totalFrameTime + data.averageTime
    end
    
    if totalFrameTime > PerformanceMonitor.THRESHOLDS.frame_time then
        table.insert(summary.recommendations, {
            priority = "critical",
            issue = string.format("Frame time %.1fms exceeds 60fps budget (16.67ms)", totalFrameTime),
            action = "Focus on the largest time consumers first",
            learning = "Every millisecond over 16.67ms causes frame drops and stuttering"
        })
    end
    
    -- Add learning points based on observed patterns
    table.insert(summary.learningPoints, {
        title = "The Frame Budget",
        content = [[At 60fps, you have 16.67ms to update and render everything.
This breaks down roughly to:
- 8ms for game logic (update)
- 8ms for rendering (draw)
- 0.67ms safety margin for GC

Every optimization counts!]]
    })
    
    return summary
end

--[[
    Clear all metrics and start fresh
--]]
function PerformanceMonitor.reset()
    PerformanceMonitor.metrics = {}
end

--[[
    Get a specific metric's details
--]]
function PerformanceMonitor.getMetric(name)
    return PerformanceMonitor.metrics[name]
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