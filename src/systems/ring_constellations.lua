-- Ring Constellations System for Orbit Jump
-- Detects patterns in collected rings for bonus rewards
local Utils = require("src.utils.utils")
local RingConstellations = {}
-- Constellation patterns
RingConstellations.patterns = {
    {
        id = "star",
        name = "Star Formation",
        description = "Collect 5 rings in a star pattern",
        requiredRings = 5,
        timeLimit = 10, -- seconds
        bonusMultiplier = 3,
        checkPattern = function(positions)
            -- Check if positions form a rough star shape
            if #positions < 5 then return false end
            -- Calculate center point
            local centerX, centerY = 0, 0
            for _, pos in ipairs(positions) do
                centerX = centerX + pos.x
                centerY = centerY + pos.y
            end
            centerX = centerX / #positions
            centerY = centerY / #positions
            -- Check if points are roughly equidistant from center
            local distances = {}
            for _, pos in ipairs(positions) do
                local dist = Utils.distance(centerX, centerY, pos.x, pos.y)
                table.insert(distances, dist)
            end
            -- Calculate average distance
            local avgDist = 0
            for _, d in ipairs(distances) do
                avgDist = avgDist + d
            end
            avgDist = avgDist / #distances
            -- Check if all points are within 30% of average distance
            for _, d in ipairs(distances) do
                if math.abs(d - avgDist) / avgDist > 0.3 then
                    return false
                end
            end
            return true
        end
    },
    {
        id = "spiral",
        name = "Spiral Galaxy",
        description = "Collect 8 rings in a spiral pattern",
        requiredRings = 8,
        timeLimit = 15,
        bonusMultiplier = 4,
        checkPattern = function(positions)
            if #positions < 8 then return false end
            -- Sort positions by collection time
            local sorted = {}
            for i, pos in ipairs(positions) do
                table.insert(sorted, {x = pos.x, y = pos.y, order = i})
            end
            -- Check if distances from center increase progressively
            local centerX, centerY = sorted[1].x, sorted[1].y
            local prevDist = 0
            local increasing = true
            for i = 2, #sorted do
                local dist = Utils.distance(centerX, centerY, sorted[i].x, sorted[i].y)
                if dist < prevDist * 0.9 then -- Allow some tolerance
                    increasing = false
                    break
                end
                prevDist = dist
            end
            return increasing
        end
    },
    {
        id = "line",
        name = "Linear Acceleration",
        description = "Collect 6 rings in a straight line",
        requiredRings = 6,
        timeLimit = 8,
        bonusMultiplier = 2.5,
        checkPattern = function(positions)
            if #positions < 6 then return false end
            -- Use least squares to find best fit line
            local sumX, sumY, sumXY, sumX2 = 0, 0, 0, 0
            local n = #positions
            for _, pos in ipairs(positions) do
                sumX = sumX + pos.x
                sumY = sumY + pos.y
                sumXY = sumXY + pos.x * pos.y
                sumX2 = sumX2 + pos.x * pos.x
            end
            -- Calculate line parameters
            local meanX = sumX / n
            local meanY = sumY / n
            -- Check variance from line
            local maxDeviation = 50 -- pixels
            local deviations = 0
            for _, pos in ipairs(positions) do
                -- Simple perpendicular distance approximation
                local expectedY = meanY + (pos.x - meanX) * ((sumXY - n * meanX * meanY) / (sumX2 - n * meanX * meanX))
                local deviation = math.abs(pos.y - expectedY)
                if deviation > maxDeviation then
                    deviations = deviations + 1
                end
            end
            -- Allow up to 1 outlier
            return deviations <= 1
        end
    },
    {
        id = "circle",
        name = "Perfect Orbit",
        description = "Collect 8 rings in a circular pattern",
        requiredRings = 8,
        timeLimit = 12,
        bonusMultiplier = 3.5,
        checkPattern = function(positions)
            if #positions < 8 then return false end
            -- Calculate center
            local centerX, centerY = 0, 0
            for _, pos in ipairs(positions) do
                centerX = centerX + pos.x
                centerY = centerY + pos.y
            end
            centerX = centerX / #positions
            centerY = centerY / #positions
            -- Calculate average radius
            local avgRadius = 0
            for _, pos in ipairs(positions) do
                avgRadius = avgRadius + Utils.distance(centerX, centerY, pos.x, pos.y)
            end
            avgRadius = avgRadius / #positions
            -- Check if all points are on the circle (within tolerance)
            local tolerance = avgRadius * 0.2
            for _, pos in ipairs(positions) do
                local dist = Utils.distance(centerX, centerY, pos.x, pos.y)
                if math.abs(dist - avgRadius) > tolerance then
                    return false
                end
            end
            return true
        end
    },
    {
        id = "zigzag",
        name = "Lightning Path",
        description = "Collect 7 rings in a zigzag pattern",
        requiredRings = 7,
        timeLimit = 10,
        bonusMultiplier = 3,
        checkPattern = function(positions)
            if #positions < 7 then return false end
            -- Check for alternating direction changes
            local directionChanges = 0
            for i = 3, #positions do
                local dx1 = positions[i-1].x - positions[i-2].x
                local dy1 = positions[i-1].y - positions[i-2].y
                local dx2 = positions[i].x - positions[i-1].x
                local dy2 = positions[i].y - positions[i-1].y
                -- Calculate angle between vectors
                local dot = dx1 * dx2 + dy1 * dy2
                local cross = dx1 * dy2 - dy1 * dx2
                local angle = Utils.atan2(cross, dot)
                -- Count significant direction changes
                if math.abs(angle) > math.pi / 4 then
                    directionChanges = directionChanges + 1
                end
            end
            -- Expect at least 4 direction changes for zigzag
            return directionChanges >= 4
        end
    },
    {
        id = "infinity",
        name = "Infinite Loop",
        description = "Collect 10 rings in an infinity symbol pattern",
        requiredRings = 10,
        timeLimit = 20,
        bonusMultiplier = 5,
        checkPattern = function(positions)
            if #positions < 10 then return false end
            -- This is complex - simplified check for two loops
            -- Divide positions into two halves
            local half = math.floor(#positions / 2)
            local firstHalf = {}
            local secondHalf = {}
            for i = 1, half do
                table.insert(firstHalf, positions[i])
            end
            for i = half + 1, #positions do
                table.insert(secondHalf, positions[i])
            end
            -- Check if each half forms a rough circle
            local function isCircular(points)
                if #points < 4 then return false end
                local cx, cy = 0, 0
                for _, p in ipairs(points) do
                    cx = cx + p.x
                    cy = cy + p.y
                end
                cx = cx / #points
                cy = cy / #points
                local avgR = 0
                for _, p in ipairs(points) do
                    avgR = avgR + Utils.distance(cx, cy, p.x, p.y)
                end
                avgR = avgR / #points
                for _, p in ipairs(points) do
                    local r = Utils.distance(cx, cy, p.x, p.y)
                    if math.abs(r - avgR) / avgR > 0.4 then
                        return false
                    end
                end
                return true
            end
            return isCircular(firstHalf) and isCircular(secondHalf)
        end
    }
}
-- Active constellation tracking
RingConstellations.active = {
    pattern = nil,
    positions = {},
    startTime = 0,
    completed = false
}
-- Completed constellations this session
RingConstellations.completedPatterns = {}
-- Visual effects
RingConstellations.effects = {}
-- Initialize
function RingConstellations.init()
    RingConstellations.active.pattern = nil
    RingConstellations.active.positions = {}
    RingConstellations.active.startTime = 0
    RingConstellations.active.completed = false
    RingConstellations.completedPatterns = {}
    RingConstellations.effects = {}
    Utils.Logger.info("Ring Constellations system initialized")
    return true
end
-- Called when a ring is collected
function RingConstellations.onRingCollected(ring, player)
    -- Add position to active tracking
    table.insert(RingConstellations.active.positions, {
        x = ring.x,
        y = ring.y,
        time = love.timer.getTime()
    })
    -- Start timer on first ring
    if #RingConstellations.active.positions == 1 then
        RingConstellations.active.startTime = love.timer.getTime()
    end
    -- Check all patterns
    for _, pattern in ipairs(RingConstellations.patterns) do
        if #RingConstellations.active.positions >= pattern.requiredRings then
            -- Get last N positions
            local recentPositions = {}
            local startIdx = #RingConstellations.active.positions - pattern.requiredRings + 1
            for i = startIdx, #RingConstellations.active.positions do
                table.insert(recentPositions, RingConstellations.active.positions[i])
            end
            -- Check time limit
            local timeTaken = love.timer.getTime() - recentPositions[1].time
            if timeTaken <= pattern.timeLimit then
                -- Check pattern
                if pattern.checkPattern(recentPositions) then
                    RingConstellations.completePattern(pattern, recentPositions)
                    break
                end
            end
        end
    end
    -- Clean old positions (keep last 20)
    if #RingConstellations.active.positions > 20 then
        table.remove(RingConstellations.active.positions, 1)
    end
end
-- Complete a constellation pattern
function RingConstellations.completePattern(pattern, positions)
    RingConstellations.active.pattern = pattern
    RingConstellations.active.completed = true
    -- Track completion
    table.insert(RingConstellations.completedPatterns, {
        pattern = pattern,
        time = love.timer.getTime()
    })
    -- Calculate bonus
    local GameState = Utils.require("src.core.game_state")
    local baseScore = 100 * pattern.requiredRings
    local bonus = math.floor(baseScore * pattern.bonusMultiplier)
    GameState.addScore(bonus)
    -- Create visual effect
    RingConstellations.createConstellationEffect(pattern, positions)
    -- Show message
    GameState.addMessage(string.format("%s! +%d points!", pattern.name, bonus))
    -- Play special sound
    local soundManager = Utils.require("src.audio.sound_manager")
    if soundManager.playConstellation then
        soundManager:playConstellation()
    else
        soundManager:playCollect() -- Fallback
    end
    -- Achievement tracking
    local AchievementSystem = Utils.require("src.systems.achievement_system")
    if AchievementSystem.onConstellationComplete then
        AchievementSystem.onConstellationComplete(pattern.id)
    end
    -- Clear positions for next pattern
    RingConstellations.active.positions = {}
    Utils.Logger.info("Constellation completed: %s", pattern.name)
end
-- Create visual effect for completed constellation
function RingConstellations.createConstellationEffect(pattern, positions)
    local effect = {
        pattern = pattern,
        positions = positions,
        startTime = love.timer.getTime(),
        duration = 3.0,
        particles = {}
    }
    -- Create connecting lines effect
    for i = 1, #positions - 1 do
        local p1 = positions[i]
        local p2 = positions[i + 1]
        -- Create particles along the line
        local steps = 10
        for j = 0, steps do
            local t = j / steps
            local x = p1.x + (p2.x - p1.x) * t
            local y = p1.y + (p2.y - p1.y) * t
            table.insert(effect.particles, {
                x = x,
                y = y,
                vx = math.random(-50, 50),
                vy = math.random(-50, 50),
                life = 1.0,
                size = math.random(3, 6),
                color = {math.random(0.5, 1), math.random(0.5, 1), math.random(0.5, 1)}
            })
        end
    end
    -- Special effect for infinity pattern
    if pattern.id == "infinity" then
        -- Add center crossing particle burst
        local centerX = (positions[1].x + positions[#positions].x) / 2
        local centerY = (positions[1].y + positions[#positions].y) / 2
        for i = 1, 20 do
            local angle = (i / 20) * math.pi * 2
            local speed = math.random(100, 200)
            table.insert(effect.particles, {
                x = centerX,
                y = centerY,
                vx = math.cos(angle) * speed,
                vy = math.sin(angle) * speed,
                life = 1.5,
                size = math.random(4, 8),
                color = {1, 0.8, 0}
            })
        end
    end
    table.insert(RingConstellations.effects, effect)
end
-- Update constellation effects
function RingConstellations.update(dt)
    -- Update visual effects
    for i = #RingConstellations.effects, 1, -1 do
        local effect = RingConstellations.effects[i]
        local elapsed = love.timer.getTime() - effect.startTime
        if elapsed > effect.duration then
            table.remove(RingConstellations.effects, i)
        else
            -- Update particles
            for j = #effect.particles, 1, -1 do
                local p = effect.particles[j]
                p.x = p.x + p.vx * dt
                p.y = p.y + p.vy * dt
                p.life = p.life - dt
                p.vy = p.vy + 100 * dt -- Gravity
                if p.life <= 0 then
                    table.remove(effect.particles, j)
                end
            end
        end
    end
    -- Clear completed pattern flag after a delay
    if RingConstellations.active.completed then
        if love.timer.getTime() - RingConstellations.active.startTime > 3 then
            RingConstellations.active.completed = false
            RingConstellations.active.pattern = nil
        end
    end
end
-- Draw constellation effects and UI
function RingConstellations.draw()
    -- Draw effects
    for _, effect in ipairs(RingConstellations.effects) do
        local alpha = 1 - (love.timer.getTime() - effect.startTime) / effect.duration
        -- Draw connecting lines
        love.graphics.setLineWidth(2)
        for i = 1, #effect.positions - 1 do
            Utils.setColor({0.5, 0.8, 1}, alpha * 0.5)
            love.graphics.line(
                effect.positions[i].x, effect.positions[i].y,
                effect.positions[i + 1].x, effect.positions[i + 1].y
            )
        end
        -- Draw particles
        for _, p in ipairs(effect.particles) do
            Utils.setColor(p.color, p.life * alpha)
            love.graphics.circle("fill", p.x, p.y, p.size * p.life)
        end
    end
end
-- Draw UI hints
function RingConstellations.drawUI()
    -- Show active pattern progress
    if #RingConstellations.active.positions > 0 then
        local y = 250
        love.graphics.setFont(love.graphics.newFont(14))
        -- Find potential patterns
        for _, pattern in ipairs(RingConstellations.patterns) do
            local remaining = pattern.requiredRings - #RingConstellations.active.positions
            if remaining > 0 and remaining <= 3 then
                -- Show hint
                Utils.setColor({1, 1, 1}, 0.7)
                love.graphics.print(
                    string.format("%s: %d more rings", pattern.name, remaining),
                    10, y
                )
                y = y + 20
            end
        end
    end
    -- Show completed pattern celebration
    if RingConstellations.active.completed and RingConstellations.active.pattern then
        local pattern = RingConstellations.active.pattern
        local elapsed = love.timer.getTime() - RingConstellations.active.startTime
        local alpha = math.max(0, 1 - elapsed / 3)
        love.graphics.setFont(love.graphics.newFont(24))
        Utils.setColor({1, 0.8, 0}, alpha)
        love.graphics.printf(
            pattern.name .. "!",
            0, love.graphics.getHeight() / 2 - 100,
            love.graphics.getWidth(), "center"
        )
        love.graphics.setFont(love.graphics.newFont(18))
        Utils.setColor({1, 1, 1}, alpha * 0.8)
        love.graphics.printf(
            string.format("x%g Bonus!", pattern.bonusMultiplier),
            0, love.graphics.getHeight() / 2 - 70,
            love.graphics.getWidth(), "center"
        )
    end
end
-- Get constellation stats
function RingConstellations.getStats()
    local stats = {
        totalCompleted = #RingConstellations.completedPatterns,
        patternCounts = {}
    }
    -- Count each pattern type
    for _, completion in ipairs(RingConstellations.completedPatterns) do
        local id = completion.pattern.id
        stats.patternCounts[id] = (stats.patternCounts[id] or 0) + 1
    end
    return stats
end
-- Reset for new game
function RingConstellations.reset()
    RingConstellations.active.pattern = nil
    RingConstellations.active.positions = {}
    RingConstellations.active.startTime = 0
    RingConstellations.active.completed = false
    RingConstellations.completedPatterns = {}
    RingConstellations.effects = {}
    return true
end
return RingConstellations