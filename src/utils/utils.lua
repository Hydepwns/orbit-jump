--[[
    Orbit Jump Utilities: The Foundation of Elegant Game Architecture
    
    This module embodies the philosophy that utilities should be more than just
    helpers - they should be the elegant foundation that makes complex systems
    feel simple and intuitive.
    
    Core Principles Demonstrated:
    • Performance through design (object pooling, spatial partitioning)
    • Graceful degradation (comprehensive nil handling)
    • Zero-surprise interfaces (consistent behavior across all functions)
    • Teaching through code (each section demonstrates programming patterns)
    
    This isn't just a utility library - it's a masterclass in Lua game development
    architecture, designed to make both the game and its developers better.
--]]

local Utils = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Module Loading: Performance Through Intelligent Caching
    ═══════════════════════════════════════════════════════════════════════════
    
    The require() function in Lua already caches modules, but our wrapper adds:
    • Explicit cache control for testing scenarios
    • Predictable behavior in edge cases
    • Clear separation of concerns between system modules and user modules
    
    This pattern prevents the "require hell" that can happen in complex Lua
    applications while maintaining the flexibility to reset state when needed.
--]]

Utils.moduleCache = {}

function Utils.require(modulePath)
    -- Philosophy: Cache what's expensive, make cache invalidation explicit
    -- This prevents duplicate loading while allowing controlled resets for testing
    if not Utils.moduleCache[modulePath] then
        Utils.moduleCache[modulePath] = require(modulePath)
    end
    return Utils.moduleCache[modulePath]
end

function Utils.clearModuleCache()
    -- Teaching moment: Sometimes you need to forget everything and start fresh
    -- Essential for test isolation and hot-reloading during development
    Utils.moduleCache = {}
end

function Utils.safeRequire(modulePath)
    -- Safe require that returns nil instead of erroring if module doesn't exist
    local success, module = pcall(require, modulePath)
    if success then
        return module
    else
        Utils.Logger.warn("Failed to load module: %s (%s)", modulePath, module)
        return nil
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Mathematical Foundation: The Physics of Virtual Worlds
    ═══════════════════════════════════════════════════════════════════════════
    
    Game mathematics isn't just about getting the right answer - it's about
    creating the foundation for emergent experiences. Every calculation here
    contributes to the "feel" of planetary jumping and space navigation.
--]]

-- Lua version compatibility: Ensuring graceful behavior across environments
local atan2 = math.atan2 or function(y, x)
    -- Fallback for newer Lua versions where atan2 was removed
    -- Handle nil values gracefully
    if not y or not x then
        return 0
    end
    return math.atan(y, x)
end
Utils.atan2 = atan2

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Zero-Allocation Math Utilities: Performance Through Precision
    ═══════════════════════════════════════════════════════════════════════════
    
    These functions are called thousands of times per frame. Every allocation
    eliminated here prevents garbage collection stutter and enables the
    butter-smooth 60fps that defines 101% performance.
--]]

-- Pre-allocated temporary variables for zero-allocation math
local temp_dx, temp_dy, temp_distance = 0, 0, 0
local temp_length, temp_nx, temp_ny = 0, 0, 0

function Utils.distance(x1, y1, x2, y2)
    --[[
        The Foundation of All Game Physics - Zero Allocation Edition
        
        This function is called thousands of times per frame. The original
        version was already efficient, but this version eliminates even the
        temporary local variables by reusing module-level storage.
        
        Performance Optimization:
        • Reuse module-level variables instead of creating locals
        • Early return for nil inputs without variable creation
        • Triple return prevents redundant calculations elsewhere
        
        Hot path impact: 1000+ calls/frame × 0 allocations = smooth performance
    --]]
    
    if not x1 or not y1 or not x2 or not y2 then
        -- Graceful degradation: Return safe values rather than erroring
        return 0, 0, 0
    end
    
    -- Use pre-allocated temporaries (zero allocation)
    temp_dx = x2 - x1
    temp_dy = y2 - y1
    temp_distance = math.sqrt(temp_dx*temp_dx + temp_dy*temp_dy)
    
    return temp_distance, temp_dx, temp_dy
end

-- Zero-allocation distance calculation (single return for pure distance checks)
function Utils.fastDistance(x1, y1, x2, y2)
    --[[Optimized for cases where only distance matters, not components--]]
    if not x1 or not y1 or not x2 or not y2 then
        return 0
    end
    
    temp_dx = x2 - x1
    temp_dy = y2 - y1
    return math.sqrt(temp_dx*temp_dx + temp_dy*temp_dy)
end

-- Zero-allocation squared distance (avoids sqrt for comparison-only operations)
function Utils.distanceSquared(x1, y1, x2, y2)
    --[[For comparisons where sqrt is unnecessary (major performance gain)--]]
    if not x1 or not y1 or not x2 or not y2 then
        return 0
    end
    
    temp_dx = x2 - x1
    temp_dy = y2 - y1
    return temp_dx*temp_dx + temp_dy*temp_dy
end

function Utils.normalize(x, y)
    --[[
        Vector Normalization: From Chaos to Direction - Zero Allocation Edition
        
        Normalization transforms any vector into a unit vector - one that points
        in the same direction but has length 1. This critical function is used
        in player movement, AI steering, and particle effects.
        
        Performance Enhancement:
        • Uses pre-allocated module variables (zero local allocation)
        • Avoids redundant sqrt calculations when possible
        • Optimized for the hot paths of player physics
    --]]
    
    if not x or not y then
        -- The safe default: when lost, don't move
        return 0, 0
    end
    
    -- Use pre-allocated temporary (zero allocation)
    temp_length = math.sqrt(x*x + y*y)
    if temp_length == 0 then
        -- Mathematical edge case: zero vector has no direction
        return 0, 0
    end
    
    -- Calculate normalized components using pre-allocated storage
    temp_nx = x / temp_length
    temp_ny = y / temp_length
    return temp_nx, temp_ny
end

-- Fast normalize that modifies values in-place (ultimate zero allocation)
function Utils.normalizeInPlace(vectorObj)
    --[[
        In-place normalization for objects with x,y fields
        Modifies the input directly - zero allocation, zero return values
        Perfect for hot path vector operations
    --]]
    if not vectorObj or not vectorObj.x or not vectorObj.y then
        return
    end
    
    temp_length = math.sqrt(vectorObj.x*vectorObj.x + vectorObj.y*vectorObj.y)
    if temp_length == 0 then
        vectorObj.x = 0
        vectorObj.y = 0
        return
    end
    
    vectorObj.x = vectorObj.x / temp_length
    vectorObj.y = vectorObj.y / temp_length
end

function Utils.clamp(value, min, max)
    --[[
        Constraint Enforcement: The Art of Staying Within Bounds
        
        Simple but essential. This function embodies the principle that
        freedom exists within constraints. Whether it's limiting velocity,
        keeping UI elements on screen, or preventing values from breaking
        the game's physics, clamp is the guardian of reasonable behavior.
    --]]
    return math.max(min, math.min(max, value))
end

function Utils.lerp(a, b, t)
    --[[
        Linear Interpolation: The Mathematics of Smooth Transitions
        
        The foundation of all smooth animation in games. When you see a camera
        smoothly following a player, a color gradually changing, or a value
        smoothly transitioning - linear interpolation is usually involved.
        
        t=0 returns a, t=1 returns b, values between create smooth progression.
        This is the mathematical expression of "gradual change feels natural".
    --]]
    return a + (b - a) * t
end

function Utils.angleBetween(x1, y1, x2, y2)
    -- Use Utils.atan2 for consistency across the codebase
    return Utils.atan2(y2 - y1, x2 - x1)
end

function Utils.rotatePoint(x, y, centerX, centerY, angle)
    local cos = math.cos(angle)
    local sin = math.sin(angle)
    local dx = x - centerX
    local dy = y - centerY
    return centerX + dx * cos - dy * sin, centerY + dx * sin + dy * cos
end

-- Vector utilities
function Utils.vectorLength(x, y)
    if not x or not y then
        return 0
    end
    return math.sqrt(x*x + y*y)
end

function Utils.vectorScale(x, y, scale)
    if not x or not y or not scale then
        return 0, 0
    end
    return x * scale, y * scale
end

function Utils.vectorAdd(x1, y1, x2, y2)
    return x1 + x2, y1 + y2
end

function Utils.vectorSubtract(x1, y1, x2, y2)
    return x1 - x2, y1 - y2
end

function Utils.randomFloat(min, max)
    return min + math.random() * (max - min)
end

-- Centralized math constants
Utils.MATH = {
    PI = math.pi,
    TWO_PI = math.pi * 2,
    HALF_PI = math.pi / 2,
    DEG_TO_RAD = math.pi / 180,
    RAD_TO_DEG = 180 / math.pi
}

-- Drawing utilities
function Utils.setColor(color, alpha)
    if alpha then
        love.graphics.setColor(color[1], color[2], color[3], alpha)
    else
        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    end
end

function Utils.drawCircle(x, y, radius, color, alpha)
    Utils.setColor(color, alpha)
    love.graphics.circle("fill", x, y, radius)
end

function Utils.drawRing(x, y, outerRadius, innerRadius, color, alpha, segments)
    segments = segments or 16
    Utils.setColor(color, alpha)
    
    for i = 1, segments do
        local angle1 = (i-1) / segments * math.pi * 2
        local angle2 = i / segments * math.pi * 2
        local gap = 0.1
        
        love.graphics.arc("line", "open", x, y, outerRadius, angle1 + gap, angle2 - gap)
        love.graphics.arc("line", "open", x, y, innerRadius, angle1 + gap, angle2 - gap)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    Object Pooling: Zero-Allocation Performance Architecture
    ═══════════════════════════════════════════════════════════════════════════
    
    The philosophy: Create once, reuse forever. Object pools eliminate garbage
    collection stutter by reusing objects instead of constantly creating and
    destroying them. This pattern transforms object management from a performance
    liability into a performance advantage.
    
    Essential for: Particles, bullets, temporary UI elements, or any object
    created/destroyed frequently during gameplay.
--]]

Utils.ObjectPool = {}

function Utils.ObjectPool.new(createFunc, resetFunc)
    --[[
        Factory for Sustainable Object Management
        
        createFunc: How to make a new object when the pool is empty
        resetFunc: How to clean an object before reusing it
        
        This pattern implements the "reduce, reuse, recycle" philosophy at the
        code level, turning potential garbage collection into elegant reuse.
    --]]
    
    local pool = {
        objects = {},           -- The treasure chest of reusable objects
        createFunc = createFunc, -- How to mint new treasure when needed
        resetFunc = resetFunc,   -- How to polish treasure for reuse
        totalCreated = 0,       -- Analytics: How many objects ever created
        totalReused = 0         -- Analytics: How many times we avoided creation
    }
    
    function pool:get()
        if #self.objects > 0 then
            -- Reuse: The environmentally and performance-friendly choice
            self.totalReused = self.totalReused + 1
            return table.remove(self.objects)
        else
            -- Create: Only when absolutely necessary
            self.totalCreated = self.totalCreated + 1
            return self.createFunc()
        end
    end
    
    function pool:returnObject(obj)
        -- Clean before storing: Prepare for next life cycle
        if self.resetFunc then
            self.resetFunc(obj)
        end
        table.insert(self.objects, obj)
    end
    
    function pool:getStats()
        -- Performance insight: How effective is this pool?
        local reuse_ratio = self.totalReused / math.max(1, self.totalCreated + self.totalReused)
        return {
            created = self.totalCreated,
            reused = self.totalReused,
            available = #self.objects,
            efficiency = reuse_ratio
        }
    end
    
    return pool
end

-- Logging system
Utils.Logger = {
    levels = {DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4},
    currentLevel = 2, -- INFO by default
    logFile = nil
}

function Utils.Logger.init(level, filename)
    Utils.Logger.currentLevel = level or 2
    if filename then
        Utils.Logger.logFile = io.open(filename, "a")
    end
end

function Utils.Logger.log(level, message, ...)
    if Utils.Logger.levels[level] >= Utils.Logger.currentLevel then
        local formatted = string.format(message, ...)
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local logMessage = string.format("[%s] %s: %s", timestamp, level, formatted)
        
        Utils.Logger.output(logMessage)
        if Utils.Logger.logFile then
            Utils.Logger.logFile:write(logMessage .. "\n")
            Utils.Logger.logFile:flush()
        end
    end
end

-- Separate output function for easier testing and mocking
function Utils.Logger.output(message)
    -- Use io.write for direct output without newline
    io.write(message .. "\n")
    io.flush()
end

function Utils.Logger.debug(message, ...)
    Utils.Logger.log("DEBUG", message, ...)
end

function Utils.Logger.info(message, ...)
    Utils.Logger.log("INFO", message, ...)
end

function Utils.Logger.warn(message, ...)
    Utils.Logger.log("WARN", message, ...)
end

function Utils.Logger.error(message, ...)
    Utils.Logger.log("ERROR", message, ...)
end

function Utils.Logger.close()
    if Utils.Logger.logFile then
        Utils.Logger.logFile:close()
        Utils.Logger.logFile = nil
    end
end

-- Error handling utilities
Utils.ErrorHandler = {}

function Utils.ErrorHandler.safeCall(func, ...)
    local success, result = Utils.ErrorHandler.rawPcall(func, ...)
    if not success then
        Utils.Logger.error("Function call failed: %s", result)
        return false, result
    end
    return true, result
end

-- Raw pcall wrapper for internal use
function Utils.ErrorHandler.rawPcall(func, ...)
    return pcall(func, ...)
end
function Utils.ErrorHandler.handleModuleError(moduleName, err)
    Utils.Logger.error("Module %s error: %s", moduleName, tostring(err))
end

function Utils.ErrorHandler.validateInput(value, expectedType, name)
    if type(value) ~= expectedType then
        local error = string.format("Invalid input for %s: expected %s, got %s", 
            name or "parameter", expectedType, type(value))
        Utils.Logger.error(error)
        return false, error
    end
    return true
end

-- Spatial partitioning for collision detection optimization
Utils.SpatialGrid = {}
function Utils.SpatialGrid.new(cellSize)
    local grid = {
        cellSize = cellSize or 100,
        cells = {}
    }
    
    function grid:getCellKey(x, y)
        local cellX = math.floor(x / self.cellSize)
        local cellY = math.floor(y / self.cellSize)
        return cellX .. "," .. cellY
    end
    
    function grid:addObject(x, y, obj)
        local key = self:getCellKey(x, y)
        if not self.cells[key] then
            self.cells[key] = {}
        end
        table.insert(self.cells[key], obj)
    end
    
    -- Alias for addObject to match test expectations
    function grid:insert(obj)
        if obj.x and obj.y then
            self:addObject(obj.x, obj.y, obj)
        end
    end
    
    function grid:getNearbyObjects(x, y, radius)
        local nearby = {}
        local cellRadius = math.ceil(radius / self.cellSize)
        local centerCellX = math.floor(x / self.cellSize)
        local centerCellY = math.floor(y / self.cellSize)
        
        for dx = -cellRadius, cellRadius do
            for dy = -cellRadius, cellRadius do
                local key = (centerCellX + dx) .. "," .. (centerCellY + dy)
                if self.cells[key] then
                    for _, obj in ipairs(self.cells[key]) do
                        table.insert(nearby, obj)
                    end
                end
            end
        end
        
        return nearby
    end
    
    -- Alias for getNearbyObjects to match test expectations
    function grid:getNearby(x, y, radius)
        return self:getNearbyObjects(x, y, radius)
    end
    
    function grid:clear()
        self.cells = {}
    end
    
    return grid
end

-- Enhanced color palette for better readability
Utils.colors = {
    -- Core game colors
    background = {0.1, 0.1, 0.15},
    player = {1, 1, 1},
    playerDashing = {0.3, 0.7, 1},
    planet1 = {0.8, 0.3, 0.3},
    planet2 = {0.3, 0.8, 0.3},
    planet3 = {0.3, 0.3, 0.8},
    ring = {1, 0.8, 0.2},
    particle = {1, 0.8, 0.2},
    
    -- UI colors with better contrast
    text = {1, 1, 1},
    textSecondary = {0.8, 0.8, 0.8},
    textMuted = {0.6, 0.6, 0.6},
    backgroundSecondary = {0.15, 0.15, 0.2},
    accent = {0.2, 0.6, 1.0},
    success = {0.2, 0.8, 0.4},
    warning = {1.0, 0.7, 0.2},
    error = {1.0, 0.4, 0.4},
    
    -- Additional colors
    white = {1, 1, 1},
    black = {0, 0, 0},
    gray = {0.5, 0.5, 0.5},
    red = {1, 0, 0},
    green = {0, 1, 0},
    blue = {0, 0, 1},
    yellow = {1, 1, 0},
    dash = {0.3, 0.7, 1},
    combo = {1, 0.8, 0.2},
    gameOver = {1, 0.4, 0.4},
    blockchain = {0.2, 0.6, 1.0},
    highlight = {1, 1, 0.5},
    score = {0.2, 0.8, 1.0},
    
    cyan = {0, 1, 1},
    magenta = {1, 0, 1}
}

-- Enhanced text rendering with better readability
function Utils.drawTextWithShadow(text, x, y, font, color, shadowColor, shadowOffset)
    shadowColor = shadowColor or {0, 0, 0, 0.8}
    shadowOffset = shadowOffset or 2
    
    -- Draw shadow
    love.graphics.setColor(shadowColor[1], shadowColor[2], shadowColor[3], shadowColor[4] or 1)
    love.graphics.print(text, x + shadowOffset, y + shadowOffset)
    
    -- Draw main text
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.print(text, x, y)
end

function Utils.drawTextWithOutline(text, x, y, font, color, outlineColor, outlineWidth)
    outlineColor = outlineColor or {0, 0, 0, 0.8}
    outlineWidth = outlineWidth or 1
    
    -- Draw outline
    love.graphics.setColor(outlineColor[1], outlineColor[2], outlineColor[3], outlineColor[4] or 1)
    for dx = -outlineWidth, outlineWidth do
        for dy = -outlineWidth, outlineWidth do
            if dx ~= 0 or dy ~= 0 then
                love.graphics.print(text, x + dx, y + dy)
            end
        end
    end
    
    -- Draw main text
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.print(text, x, y)
end

-- Enhanced button drawing with better visual feedback
function Utils.drawButton(text, x, y, width, height, color, hoverColor, isHovered)
    -- Handle case where love.graphics is not available (e.g., in test environment)
    if not love or not love.graphics or not love.graphics.rectangle then
        return -- Skip drawing in test environment
    end
    
    color = color or Utils.colors.accent
    hoverColor = hoverColor or {color[1] * 1.2, color[2] * 1.2, color[3] * 1.2}
    
    local buttonColor = isHovered and hoverColor or color
    
    -- Draw button background with rounded corners
    Utils.setColor(buttonColor, 0.8)
    love.graphics.rectangle("fill", x, y, width, height, 8)
    
    -- Draw button border
    Utils.setColor(Utils.colors.white, 0.3)
    love.graphics.rectangle("line", x, y, width, height, 8)
    
    -- Draw text with shadow for better readability
    local textX = x + width / 2
    local textY = y + height / 2 - 8
    Utils.drawTextWithShadow(text, textX, textY, nil, Utils.colors.text, {0, 0, 0, 0.8}, 1)
end

-- Enhanced progress bar with better visual feedback
function Utils.drawProgressBar(x, y, width, height, progress, color, backgroundColor)
    color = color or Utils.colors.success
    backgroundColor = backgroundColor or Utils.colors.backgroundSecondary
    
    -- Draw background
    Utils.setColor(backgroundColor, 0.6)
    love.graphics.rectangle("fill", x, y, width, height, 5)
    
    -- Draw progress
    Utils.setColor(color, 0.8)
    love.graphics.rectangle("fill", x, y, width * progress, height, 5)
    
    -- Draw border
    Utils.setColor(Utils.colors.white, 0.4)
    love.graphics.rectangle("line", x, y, width, height, 5)
    
    -- Draw progress text
    local textX = x + width / 2
    local textY = y + height / 2 - 8
    Utils.drawTextWithShadow(
        math.floor(progress * 100) .. "%", 
        textX, textY, nil, Utils.colors.text, {0, 0, 0, 0.8}, 1
    )
end

-- Collision utilities
function Utils.circleCollision(x1, y1, r1, x2, y2, r2)
    -- Handle edge cases
    if r1 <= 0 or r2 <= 0 then
        return false
    end
    local distance = Utils.distance(x1, y1, x2, y2)
    return distance <= r1 + r2
end

function Utils.ringCollision(x, y, radius, ringX, ringY, ringRadius, ringInnerRadius)
    local distance = Utils.distance(x, y, ringX, ringY)
    -- Check if player is within the ring (between inner and outer radius)
    -- Player is in the ring if: innerRadius <= distance <= outerRadius
    return distance <= ringRadius and distance >= ringInnerRadius
end

function Utils.pointInRect(x, y, rectX, rectY, rectWidth, rectHeight)
    return x >= rectX and x <= rectX + rectWidth and y >= rectY and y <= rectY + rectHeight
end

-- Particle utilities
function Utils.createParticle(x, y, vx, vy, color, lifetime, size)
    return {
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        color = color or Utils.colors.particle,
        lifetime = lifetime or 1.0,
        maxLifetime = lifetime or 1.0,
        size = size or 3
    }
end

function Utils.updateParticle(particle, dt, gravity)
    particle.x = particle.x + particle.vx * dt
    particle.y = particle.y + particle.vy * dt
    particle.lifetime = particle.lifetime - dt
    
    if gravity then
        particle.vy = particle.vy + gravity * dt
    end
    
    return particle.lifetime > 0
end

-- String utilities
function Utils.formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

function Utils.formatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

-- Table utilities
function Utils.deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.deepCopy(orig_key)] = Utils.deepCopy(orig_value)
        end
        setmetatable(copy, Utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Utils.mergeTables(t1, t2)
    local result = Utils.deepCopy(t1)
    for k, v in pairs(t2) do
        result[k] = v
    end
    return result
end

function Utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Mobile Input Utilities
Utils.MobileInput = {}

-- Touch state tracking
Utils.MobileInput.touchState = {
    touches = {},
    gestures = {},
    lastTapTime = 0,
    doubleTapDelay = 0.3
}

-- Initialize mobile input
function Utils.MobileInput.init()
    Utils.MobileInput.touchState.touches = {}
    Utils.MobileInput.touchState.gestures = {}
    Utils.MobileInput.touchState.lastTapTime = 0
end

-- Detect if device is mobile
function Utils.MobileInput.isMobile()
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width, height = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        width, height = love.graphics.getDimensions()
    end
    return width < 768 or height < 768
end

-- Get device orientation
function Utils.MobileInput.getOrientation()
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width, height = 800, 600 -- Default values
    if love and love.graphics and love.graphics.getDimensions then
        width, height = love.graphics.getDimensions()
    end
    if width > height then
        return "landscape"
    else
        return "portrait"
    end
end

-- Handle touch events with improved gesture recognition
function Utils.MobileInput.handleTouch(id, x, y, event)
    local touchState = Utils.MobileInput.touchState
    
    if event == "pressed" then
        touchState.touches[id] = {
            x = x,
            y = y,
            startX = x,
            startY = y,
            startTime = love.timer.getTime(),
            moved = false
        }
        
        -- Check for two-finger gesture
        local touchCount = 0
        for _ in pairs(touchState.touches) do
            touchCount = touchCount + 1
        end
        
        if touchCount == 2 then
            touchState.twoFingerStart = love.timer.getTime()
        end
    elseif event == "moved" and touchState.touches[id] then
        local touch = touchState.touches[id]
        local dx = x - touch.startX
        local dy = y - touch.startY
        local distance = Utils.vectorLength(dx, dy)
        
        if distance > Config.mobile.minSwipeDistance then
            touch.moved = true
        end
        
        touch.x = x
        touch.y = y
    elseif event == "released" and touchState.touches[id] then
        local touch = touchState.touches[id]
        local currentTime = love.timer.getTime()
        local dx = x - touch.startX
        local dy = y - touch.startY
        local distance = Utils.vectorLength(dx, dy)
        local duration = currentTime - touch.startTime
        
        -- Detect tap vs swipe
        if distance < Config.mobile.minSwipeDistance and duration < 0.3 then
            -- Single tap
            Utils.MobileInput.handleTap(x, y)
        elseif distance > Config.mobile.minSwipeDistance then
            -- Swipe gesture
            Utils.MobileInput.handleSwipe(touch.startX, touch.startY, x, y, distance, duration)
        end
        
        touchState.touches[id] = nil
        
        -- Check if this was a two-finger swipe
        local touchCount = 0
        for _ in pairs(touchState.touches) do
            touchCount = touchCount + 1
        end
        
        if touchCount == 0 and touchState.twoFingerStart and 
           currentTime - touchState.twoFingerStart < 1.0 then
            -- Two-finger gesture completed, toggle map
            local MapSystem = Utils.require("src.systems.map_system")
            MapSystem.toggle()
            touchState.twoFingerStart = nil
        end
    end
end

-- Handle tap events
function Utils.MobileInput.handleTap(x, y)
    local currentTime = love.timer.getTime()
    local touchState = Utils.MobileInput.touchState
    
    -- Check for double tap
    if currentTime - touchState.lastTapTime < Utils.MobileInput.touchState.doubleTapDelay then
        -- Double tap detected
        Utils.MobileInput.handleDoubleTap(x, y)
    else
        -- Single tap
        love.mousepressed(x, y, 1)
    end
    
    touchState.lastTapTime = currentTime
end

-- Handle swipe gestures
function Utils.MobileInput.handleSwipe(startX, startY, endX, endY, distance, duration)
    local dx = endX - startX
    local dy = endY - startY
    local angle = Utils.atan2(dy, dx) * 180 / math.pi
    
    -- Normalize distance for power calculation
    local normalizedDistance = math.min(distance / Config.mobile.maxSwipeDistance, 1.0)
    
    -- Apply touch sensitivity
    normalizedDistance = normalizedDistance * Config.mobile.touchSensitivity
    
    -- Trigger haptic feedback if enabled
    if Config.mobile.hapticFeedback then
        Utils.MobileInput.vibrate(normalizedDistance)
    end
    
    -- Handle the swipe as mouse input
    love.mousepressed(startX, startY, 1)
    love.mousemoved(endX, endY)
    love.mousereleased(endX, endY, 1)
end

-- Handle double tap
function Utils.MobileInput.handleDoubleTap(x, y)
    -- Double tap could be used for dash or special moves
    local GameState = Utils.require("src.core.game_state")
    if GameState.isPlayerInSpace() then
        -- Double tap to dash
        local dash = Utils.require("main").dash
        if dash then dash() end
    end
end

-- Vibrate device (if supported)
function Utils.MobileInput.vibrate(intensity)
    -- This would need platform-specific implementation
    -- For now, just log the vibration
    Utils.Logger.debug("Vibration: %f", intensity)
end

-- Get UI scale factor based on screen size
function Utils.MobileInput.getUIScale()
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width = 800 -- Default width
    if love and love.graphics and love.graphics.getWidth then
        width = love.graphics.getWidth()
    end
    
    local Config = Utils.require("src.utils.config")
    if not Config or not Config.responsive or not Config.responsive.enabled then
        return 1.0
    end
    
    local breakpoints = Config.responsive.breakpoints
    
    if width <= breakpoints.mobile then
        return Config.responsive.scaling.mobile
    elseif width <= breakpoints.tablet then
        return Config.responsive.scaling.tablet
    else
        return Config.responsive.scaling.desktop
    end
end

-- Get appropriate font sizes for current device
function Utils.MobileInput.getFontSizes()
    -- Handle case where love.graphics is not available (e.g., in test environment)
    local width = 800 -- Default width
    if love and love.graphics and love.graphics.getWidth then
        width = love.graphics.getWidth()
    end
    
    if not Config or not Config.responsive or not Config.responsive.enabled then
        return Config.responsive.fontSizes.desktop
    end
    
    local breakpoints = Config.responsive.breakpoints
    
    if width <= breakpoints.mobile then
        return Config.responsive.fontSizes.mobile
    elseif width <= breakpoints.tablet then
        return Config.responsive.fontSizes.tablet
    else
        return Config.responsive.fontSizes.desktop
    end
end

return Utils 