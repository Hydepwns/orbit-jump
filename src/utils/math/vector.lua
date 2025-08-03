--[[
    Vector Math Utilities for Orbit Jump
    
    This module provides efficient vector operations for game physics and calculations.
    All functions are optimized for zero-allocation performance and handle nil values gracefully.
--]]

local Vector = {}

-- Pre-allocated temporary variables for zero-allocation math
local temp_dx, temp_dy, temp_distance = 0, 0, 0
local temp_length, temp_nx, temp_ny = 0, 0, 0

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Zero-Allocation Math Utilities: Performance Through Precision
    ═══════════════════════════════════════════════════════════════════════════
    
    These functions are called thousands of times per frame. Every allocation
    eliminated here prevents garbage collection stutter and enables the
    butter-smooth 60fps that defines 101% performance.
--]]

function Vector.distance(x1, y1, x2, y2)
    --[[
        The Foundation of All Game Physics - Zero Allocation Edition
        
        This function calculates the Euclidean distance between two points
        without creating any temporary tables or strings. It's the backbone
        of collision detection, pathfinding, and spatial awareness.
        
        Performance: O(1) with zero allocations
        Usage: Called 1000+ times per frame in collision detection
    --]]
    
    -- Handle nil values gracefully - essential for robust game systems
    if not x1 or not y1 or not x2 or not y2 then
        return 0
    end
    
    -- Use pre-allocated variables to avoid garbage collection
    temp_dx = x2 - x1
    temp_dy = y2 - y1
    temp_distance = math.sqrt(temp_dx * temp_dx + temp_dy * temp_dy)
    
    return temp_distance
end

function Vector.fastDistance(x1, y1, x2, y2)
    --[[
        Fast Distance - When You Don't Need Perfect Precision
        
        Sometimes you just need to know "is this close?" without the
        computational cost of square root. This is perfect for:
        • Broad-phase collision detection
        • Spatial partitioning
        • Performance-critical distance checks
        
        Performance: O(1) with zero allocations, no square root
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then
        return 0
    end
    
    temp_dx = x2 - x1
    temp_dy = y2 - y1
    return temp_dx * temp_dx + temp_dy * temp_dy
end

function Vector.distanceSquared(x1, y1, x2, y2)
    --[[
        Distance Squared - The Performance-Optimized Distance Check
        
        When you're comparing distances (e.g., "is A closer than B?"),
        you don't need the actual distance - just the squared distance.
        This eliminates the expensive square root operation.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then
        return 0
    end
    
    temp_dx = x2 - x1
    temp_dy = y2 - y1
    return temp_dx * temp_dx + temp_dy * temp_dy
end

function Vector.normalize(x, y)
    --[[
        Vector Normalization - Creating Unit Vectors
        
        Normalizes a vector to unit length (magnitude of 1). This is essential
        for consistent movement speeds, force calculations, and direction vectors.
        
        Returns: {x, y} normalized vector, or {0, 0} if input is zero vector
        Performance: O(1) with single allocation for return table
    --]]
    
    if not x or not y then
        return {x = 0, y = 0}
    end
    
    temp_length = math.sqrt(x * x + y * y)
    
    -- Handle zero vector case
    if temp_length == 0 then
        return {x = 0, y = 0}
    end
    
    -- Return normalized vector
    return {
        x = x / temp_length,
        y = y / temp_length
    }
end

function Vector.normalizeInPlace(vectorObj)
    --[[
        In-Place Normalization - Zero Allocation Edition
        
        Normalizes a vector object in-place, modifying the original object.
        This is perfect for performance-critical code where you want to
        avoid creating new table allocations.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not vectorObj or not vectorObj.x or not vectorObj.y then
        return
    end
    
    temp_length = math.sqrt(vectorObj.x * vectorObj.x + vectorObj.y * vectorObj.y)
    
    if temp_length > 0 then
        vectorObj.x = vectorObj.x / temp_length
        vectorObj.y = vectorObj.y / temp_length
    end
end

function Vector.clamp(value, min, max)
    --[[
        Value Clamping - Keeping Values in Bounds
        
        Ensures a value stays within specified bounds. Essential for:
        • Screen boundaries
        • Physics constraints
        • UI element positioning
        • Animation limits
        
        Performance: O(1) with zero allocations
    --]]
    
    if not value then return min or 0 end
    if not min then min = 0 end
    if not max then max = 1 end
    
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

function Vector.lerp(a, b, t)
    --[[
        Linear Interpolation - Smooth Transitions
        
        Creates smooth transitions between values. Essential for:
        • Smooth animations
        • Camera movement
        • UI transitions
        • Particle effects
        
        Performance: O(1) with zero allocations
    --]]
    
    if not a or not b or not t then
        return a or 0
    end
    
    -- Clamp t to [0, 1] range
    t = Vector.clamp(t, 0, 1)
    
    return a + (b - a) * t
end

function Vector.angleBetween(x1, y1, x2, y2)
    --[[
        Angle Between Points - Directional Awareness
        
        Calculates the angle between two points in radians.
        Essential for aiming, movement direction, and spatial awareness.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then
        return 0
    end
    
    return math.atan2(y2 - y1, x2 - x1)
end

function Vector.rotatePoint(x, y, centerX, centerY, angle)
    --[[
        Point Rotation - Rotating Around a Center
        
        Rotates a point around a center point by the specified angle.
        Essential for orbital mechanics, rotating objects, and camera effects.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not centerX or not centerY or not angle then
        return x or 0, y or 0
    end
    
    local cos_a = math.cos(angle)
    local sin_a = math.sin(angle)
    local dx = x - centerX
    local dy = y - centerY
    
    return centerX + dx * cos_a - dy * sin_a,
           centerY + dx * sin_a + dy * cos_a
end

function Vector.vectorLength(x, y)
    --[[
        Vector Length - Magnitude Calculation
        
        Calculates the magnitude (length) of a vector.
        Essential for physics calculations and spatial measurements.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y then
        return 0
    end
    
    return math.sqrt(x * x + y * y)
end

function Vector.vectorScale(x, y, scale)
    --[[
        Vector Scaling - Magnitude Adjustment
        
        Scales a vector by a factor. Essential for:
        • Speed adjustments
        • Force calculations
        • Size transformations
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x or not y or not scale then
        return x or 0, y or 0
    end
    
    return x * scale, y * scale
end

function Vector.vectorAdd(x1, y1, x2, y2)
    --[[
        Vector Addition - Combining Forces
        
        Adds two vectors together. Essential for:
        • Force combination
        • Movement accumulation
        • Physics calculations
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then
        return (x1 or 0) + (x2 or 0), (y1 or 0) + (y2 or 0)
    end
    
    return x1 + x2, y1 + y2
end

function Vector.vectorSubtract(x1, y1, x2, y2)
    --[[
        Vector Subtraction - Relative Positioning
        
        Subtracts one vector from another. Essential for:
        • Relative positioning
        • Direction calculations
        • Distance vectors
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then
        return (x1 or 0) - (x2 or 0), (y1 or 0) - (y2 or 0)
    end
    
    return x1 - x2, y1 - y2
end

function Vector.randomFloat(min, max)
    --[[
        Random Float - Controlled Randomness
        
        Generates a random float between min and max values.
        Essential for:
        • Particle effects
        • Procedural generation
        • Game variety
        
        Performance: O(1) with zero allocations
    --]]
    
    if not min then min = 0 end
    if not max then max = 1 end
    
    return min + math.random() * (max - min)
end

return Vector 