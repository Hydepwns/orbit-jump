--[[
    Interpolation Utilities for Orbit Jump
    
    This module provides smooth interpolation and easing functions
    for animations, transitions, and smooth movement.
--]]

local Vector = require("src.utils.math.vector")

local Interpolation = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Easing Functions: The Art of Smooth Motion
    ═══════════════════════════════════════════════════════════════════════════
    
    These functions transform linear time progress (0 to 1) into non-linear
    motion curves that feel natural and pleasing to the eye. Each function
    creates a different "personality" for animations.
--]]

function Interpolation.linear(t)
    --[[
        Linear Interpolation - The Foundation
        
        The simplest form of interpolation. Time progresses linearly,
        creating constant-speed motion. Perfect for:
        • Simple movements
        • UI elements that should move at constant speed
        • When you want predictable, mechanical motion
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    return Vector.clamp(t, 0, 1)
end

function Interpolation.easeInQuad(t)
    --[[
        Ease-In Quadratic - Gentle Start, Strong Finish
        
        Starts slowly and accelerates. Perfect for:
        • Objects falling under gravity
        • UI elements appearing on screen
        • Natural deceleration
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    return t * t
end

function Interpolation.easeOutQuad(t)
    --[[
        Ease-Out Quadratic - Strong Start, Gentle Finish
        
        Starts quickly and decelerates. Perfect for:
        • Objects coming to rest
        • UI elements settling into position
        • Natural acceleration
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    return t * (2 - t)
end

function Interpolation.easeInOutQuad(t)
    --[[
        Ease-In-Out Quadratic - Smooth S-Curve
        
        Combines ease-in and ease-out for smooth acceleration and deceleration.
        Perfect for:
        • Natural object movement
        • Camera transitions
        • Most general-purpose animations
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

function Interpolation.easeInCubic(t)
    --[[
        Ease-In Cubic - Stronger Acceleration
        
        More pronounced acceleration than quadratic. Perfect for:
        • Dramatic entrances
        • Objects with high initial velocity
        • Emphasis on the end of motion
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    return t * t * t
end

function Interpolation.easeOutCubic(t)
    --[[
        Ease-Out Cubic - Stronger Deceleration
        
        More pronounced deceleration than quadratic. Perfect for:
        • Objects coming to a dramatic stop
        • UI elements settling with authority
        • Emphasis on the beginning of motion
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    local f = t - 1
    return f * f * f + 1
end

function Interpolation.easeInOutCubic(t)
    --[[
        Ease-In-Out Cubic - Smooth S-Curve with More Character
        
        Combines cubic ease-in and ease-out for more pronounced
        acceleration and deceleration than quadratic.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = 2 * t - 2
        return 0.5 * f * f * f + 1
    end
end

function Interpolation.easeInSine(t)
    --[[
        Ease-In Sine - Natural Acceleration
        
        Uses sine function for very natural acceleration.
        Perfect for organic, flowing motion.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    return 1 - math.cos(t * math.pi * 0.5)
end

function Interpolation.easeOutSine(t)
    --[[
        Ease-Out Sine - Natural Deceleration
        
        Uses sine function for very natural deceleration.
        Perfect for organic, flowing motion.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    return math.sin(t * math.pi * 0.5)
end

function Interpolation.easeInOutSine(t)
    --[[
        Ease-In-Out Sine - Natural S-Curve
        
        Combines sine ease-in and ease-out for the most natural
        motion curve. Perfect for organic animations.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    return 0.5 * (1 - math.cos(t * math.pi))
end

function Interpolation.bounce(t)
    --[[
        Bounce - Playful Bouncing Motion
        
        Creates a bouncing effect that's perfect for:
        • Playful UI elements
        • Celebration animations
        • Attention-grabbing effects
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    
    if t < 1/2.75 then
        return 7.5625 * t * t
    elseif t < 2/2.75 then
        t = t - 1.5/2.75
        return 7.5625 * t * t + 0.75
    elseif t < 2.5/2.75 then
        t = t - 2.25/2.75
        return 7.5625 * t * t + 0.9375
    else
        t = t - 2.625/2.75
        return 7.5625 * t * t + 0.984375
    end
end

function Interpolation.elastic(t)
    --[[
        Elastic - Spring-like Motion
        
        Creates a spring-like elastic motion. Perfect for:
        • Spring physics
        • Rubber band effects
        • Organic, bouncy animations
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    t = Vector.clamp(t, 0, 1)
    
    if t == 0 then return 0 end
    if t == 1 then return 1 end
    
    return math.pow(2, -10 * t) * math.sin((t - 0.075) * (2 * math.pi) / 0.3) + 1
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Vector Interpolation: Smooth Movement in 2D Space
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Interpolation.lerpVector(x1, y1, x2, y2, t, easing)
    --[[
        Vector Linear Interpolation
        
        Interpolates between two 2D points with optional easing.
        
        Performance: O(1) with zero allocations
    --]]
    
    if not x1 or not y1 or not x2 or not y2 or not t then
        return x1 or 0, y1 or 0
    end
    
    local easedT = t
    if easing and type(easing) == "function" then
        easedT = easing(t)
    end
    
    return Vector.lerp(x1, x2, easedT), Vector.lerp(y1, y2, easedT)
end

function Interpolation.lerpVectorObject(vector1, vector2, t, easing)
    --[[
        Vector Object Interpolation
        
        Interpolates between two vector objects with optional easing.
        
        Performance: O(1) with single allocation for return table
    --]]
    
    if not vector1 or not vector2 or not t then
        return {x = 0, y = 0}
    end
    
    local x, y = Interpolation.lerpVector(vector1.x, vector1.y, vector2.x, vector2.y, t, easing)
    return {x = x, y = y}
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Color Interpolation: Smooth Color Transitions
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Interpolation.lerpColor(color1, color2, t, easing)
    --[[
        Color Interpolation
        
        Interpolates between two colors with optional easing.
        Colors are expected to be tables with r, g, b, a components.
        
        Performance: O(1) with single allocation for return table
    --]]
    
    if not color1 or not color2 or not t then
        return {r = 1, g = 1, b = 1, a = 1}
    end
    
    local easedT = t
    if easing and type(easing) == "function" then
        easedT = easing(t)
    end
    
    return {
        r = Vector.lerp(color1.r or 1, color2.r or 1, easedT),
        g = Vector.lerp(color1.g or 1, color2.g or 1, easedT),
        b = Vector.lerp(color1.b or 1, color2.b or 1, easedT),
        a = Vector.lerp(color1.a or 1, color2.a or 1, easedT)
    }
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Utility Functions: Animation Helpers
    ═══════════════════════════════════════════════════════════════════════════
--]]

function Interpolation.pingPong(t, duration)
    --[[
        Ping-Pong Animation
        
        Creates a back-and-forth animation that oscillates between 0 and 1.
        Perfect for:
        • Breathing effects
        • Pulsing animations
        • Continuous motion
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t or not duration then return 0 end
    
    local normalized = (t % (duration * 2)) / duration
    if normalized > 1 then
        normalized = 2 - normalized
    end
    
    return normalized
end

function Interpolation.repeat(t, duration)
    --[[
        Repeat Animation
        
        Creates a repeating animation that loops from 0 to 1.
        Perfect for:
        • Continuous rotations
        • Scrolling backgrounds
        • Cyclic animations
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t or not duration then return 0 end
    
    return (t % duration) / duration
end

function Interpolation.reverse(t)
    --[[
        Reverse Animation
        
        Reverses the time progress (1 - t).
        Perfect for:
        • Reverse animations
        • Fade-out effects
        • Exit animations
        
        Performance: O(1) with zero allocations
    --]]
    
    if not t then return 0 end
    return 1 - Vector.clamp(t, 0, 1)
end

return Interpolation 