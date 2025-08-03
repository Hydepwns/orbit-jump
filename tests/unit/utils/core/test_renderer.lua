-- Comprehensive tests for Renderer
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks before requiring Renderer
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Track all drawing calls
local graphicsCalls = {}
-- Store original love.graphics functions BEFORE any module loading
local originalGraphics = {}
for k, v in pairs(love.graphics) do
    if type(v) == "function" then
        originalGraphics[k] = v
    end
end
-- Set up enhanced tracking IMMEDIATELY
love.graphics.circle = function(mode, x, y, radius, segments)
    table.insert(graphicsCalls, {type = "circle", mode = mode, x = x, y = y, radius = radius})
    return originalGraphics.circle(mode, x, y, radius, segments)
end
love.graphics.arc = function(mode, arctype, x, y, radius, angle1, angle2, segments)
    table.insert(graphicsCalls, {type = "arc", mode = mode, arctype = arctype, x = x, y = y,
                                radius = radius, angle1 = angle1, angle2 = angle2})
    return originalGraphics.arc(mode, arctype, x, y, radius, angle1, angle2, segments)
end
love.graphics.line = function(...)
    local args = {...}
    table.insert(graphicsCalls, {type = "line", args = args})
    return originalGraphics.line(...)
end
love.graphics.rectangle = function(mode, x, y, width, height, rx, ry)
    table.insert(graphicsCalls, {type = "rectangle", mode = mode, x = x, y = y,
                                width = width, height = height})
    return originalGraphics.rectangle(mode, x, y, width, height, rx, ry)
end
love.graphics.print = function(text, x, y, r, sx, sy, ox, oy, kx, ky)
    table.insert(graphicsCalls, {type = "print", text = tostring(text), x = x, y = y})
    return originalGraphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
end
love.graphics.printf = function(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    table.insert(graphicsCalls, {type = "printf", text = tostring(text), x = x, y = y, limit = limit, align = align})
    return originalGraphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
end
love.graphics.push = function(...)
    table.insert(graphicsCalls, {type = "push", args = {...}})
    return originalGraphics.push(...)
end
love.graphics.pop = function()
    table.insert(graphicsCalls, {type = "pop"})
    return originalGraphics.pop()
end
-- Mock Utils color functions
local colorCalls = {}
Utils.setColor = function(color, alpha)
    table.insert(colorCalls, {color = color, alpha = alpha})
end
Utils.drawCircle = function(x, y, radius, color)
    -- Track this call too
    table.insert(graphicsCalls, {type = "circle", mode = "fill", x = x, y = y, radius = radius})
    Utils.setColor(color)
    love.graphics.circle("fill", x, y, radius)
end
Utils.drawButton = function(text, x, y, width, height, color1, color2, isHovered)
    love.graphics.rectangle("fill", x, y, width, height)
end
Utils.drawProgressBar = function(x, y, width, height, progress)
    love.graphics.rectangle("fill", x, y, width * progress, height)
end
Utils.formatNumber = function(num)
    return tostring(num)
end
Utils.vectorLength = function(x, y)
    if not x or not y then
        return 0
    end
    return math.sqrt(x*x + y*y)
end
-- Mock color constants
Utils.colors = {
    white = {1, 1, 1},
    player = {0.8, 0.9, 1},
    playerDashing = {1, 1, 0.5},
    gray = {0.5, 0.5, 0.5},
    red = {1, 0, 0},
    green = {0, 1, 0},
    text = {1, 1, 1},
    combo = {1, 1, 0},
    gameOver = {1, 0, 0},
    background = {0.1, 0.1, 0.2},
    dash = {0.8, 0.8, 1},
    planet1 = {0.7, 0.4, 0.3},
    planet2 = {0.4, 0.7, 0.3},
    planet3 = {0.3, 0.4, 0.7}
}
-- Function to ensure graphics tracking is in place
local function ensureGraphicsTracking()
    -- Re-apply our tracking functions
    love.graphics.circle = function(mode, x, y, radius, segments)
        table.insert(graphicsCalls, {type = "circle", mode = mode, x = x, y = y, radius = radius})
        return originalGraphics.circle(mode, x, y, radius, segments)
    end
    love.graphics.arc = function(mode, arctype, x, y, radius, angle1, angle2, segments)
        table.insert(graphicsCalls, {type = "arc", mode = mode, arctype = arctype, x = x, y = y,
                                    radius = radius, angle1 = angle1, angle2 = angle2})
        return originalGraphics.arc(mode, arctype, x, y, radius, angle1, angle2, segments)
    end
    love.graphics.line = function(...)
        local args = {...}
        table.insert(graphicsCalls, {type = "line", args = args})
        return originalGraphics.line(...)
    end
    love.graphics.rectangle = function(mode, x, y, width, height, rx, ry)
        table.insert(graphicsCalls, {type = "rectangle", mode = mode, x = x, y = y,
                                    width = width, height = height})
        return originalGraphics.rectangle(mode, x, y, width, height, rx, ry)
    end
    love.graphics.print = function(text, x, y, r, sx, sy, ox, oy, kx, ky)
        table.insert(graphicsCalls, {type = "print", text = tostring(text), x = x, y = y})
        return originalGraphics.print(text, x, y, r, sx, sy, ox, oy, kx, ky)
    end
    love.graphics.printf = function(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
        table.insert(graphicsCalls, {type = "printf", text = tostring(text), x = x, y = y, limit = limit, align = align})
        return originalGraphics.printf(text, x, y, limit, align, r, sx, sy, ox, oy, kx, ky)
    end
    love.graphics.push = function(...)
        table.insert(graphicsCalls, {type = "push", args = {...}})
        return originalGraphics.push(...)
    end
    love.graphics.pop = function()
        table.insert(graphicsCalls, {type = "pop"})
        return originalGraphics.pop()
    end
end
-- Function to get Renderer with proper initialization
local function getRenderer()
    -- Clear module cache to ensure fresh load with our enhanced tracking
    package.loaded["src.core.renderer"] = nil
    package.loaded["src/core/renderer"] = nil
    if Utils.moduleCache then
        Utils.moduleCache["src.core.renderer"] = nil
    end
    -- Reset graphicsCalls before each fresh load
    graphicsCalls = {}
    -- Re-setup mocks to ensure clean state
    Mocks.setup()
    -- Ensure our tracking is in place
    ensureGraphicsTracking()
    -- Require Renderer after basic mocks are set up
    local Renderer = require("src.core.renderer")
    -- Initialize if needed
    if Renderer and Renderer.init then
        Renderer.init()
    end
    return Renderer
end
-- Get initial Renderer instance
local Renderer = getRenderer()
-- Add missing fonts to prevent nil access
if Renderer then
    Renderer.fonts = Renderer.fonts or {}
    Renderer.fonts.bold = love.graphics.getFont()
    Renderer.fonts.normal = love.graphics.getFont()
end
-- Mock dependencies
local mockRingSystem = {
    isActive = function(type)
        return false
    end
}
local mockGameState = {
    player = {
        x = 400,
        y = 300,
        extraJumps = 0
    }
}
local mockUpgradeSystem = {
    upgrades = {
        warp_drive = { currentLevel = 0 }
    }
}
-- Test helper functions
local function clearGraphicsCalls()
    graphicsCalls = {}
end
local function hasDrawCall(callType, checkFunc)
    for _, call in ipairs(graphicsCalls) do
        if call.type == callType then
            if not checkFunc or checkFunc(call) then
                return true
            end
        end
    end
    return false
end
local function countDrawCalls(callType)
    local count = 0
    for _, call in ipairs(graphicsCalls) do
        if call.type == callType then
            count = count + 1
        end
    end
    return count
end
-- Test suite
local tests = {
    -- Add setUp to ensure clean state for each test
    setUp = function()
        -- Clear graphics calls
        graphicsCalls = {}
        -- Ensure our tracking functions are in place (in case other tests overwrote them)
        ensureGraphicsTracking()
        -- Ensure fonts are set
        if Renderer then
            Renderer.fonts = Renderer.fonts or {}
            Renderer.fonts.bold = Renderer.fonts.bold or love.graphics.getFont()
            Renderer.fonts.normal = Renderer.fonts.normal or love.graphics.getFont()
            Renderer.fonts.regular = Renderer.fonts.regular or love.graphics.getFont()
            Renderer.fonts.light = Renderer.fonts.light or love.graphics.getFont()
            Renderer.fonts.extraBold = Renderer.fonts.extraBold or love.graphics.getFont()
        end
    end,
    ["test initialization"] = function()
        local fonts = {
            regular = "regular_font",
            bold = "bold_font",
            light = "light_font",
            extraBold = "extra_bold_font"
        }
        Renderer.init(fonts)
        TestFramework.assert.equal("regular_font", Renderer.fonts.regular, "Regular font should be set")
        TestFramework.assert.equal("bold_font", Renderer.fonts.bold, "Bold font should be set")
        TestFramework.assert.equal("light_font", Renderer.fonts.light, "Light font should be set")
        TestFramework.assert.equal("extra_bold_font", Renderer.fonts.extraBold, "Extra bold font should be set")
    end,
    ["test draw background"] = function()
        clearGraphicsCalls()
        -- Set camera
        Renderer.camera = { x = 100, y = 100 }
        Renderer.drawBackground()
        -- Debug: print what calls were made
        if #graphicsCalls == 0 then
            print("WARNING: No graphics calls captured for drawBackground")
        end
        -- Should draw multiple layers of stars
        local circleCount = countDrawCalls("circle")
        TestFramework.assert.isTrue(circleCount > 0, "Should draw star circles")
        -- Check that stars are drawn at different positions
        local positions = {}
        for _, call in ipairs(graphicsCalls) do
            if call.type == "circle" then
                local key = call.x .. "," .. call.y
                positions[key] = true
            end
        end
        -- Should have multiple unique positions
        local positionCount = 0
        for _ in pairs(positions) do
            positionCount = positionCount + 1
        end
        TestFramework.assert.isTrue(positionCount > 10, "Should draw stars at multiple positions")
    end,
    ["test draw player"] = function()
        clearGraphicsCalls()
        local player = {
            x = 100,
            y = 200,
            radius = 10,
            hasShield = false
        }
        Renderer.drawPlayer(player, false)
        -- Should draw player circle
        TestFramework.assert.isTrue(hasDrawCall("circle", function(call)
            return call.x == 100 and call.y == 200 and call.radius == 10
        end), "Should draw player at correct position")
    end,
    ["test draw player with shield"] = function()
        clearGraphicsCalls()
        love.timer.currentTime = 1.0
        local player = {
            x = 100,
            y = 200,
            radius = 10,
            hasShield = true
        }
        Renderer.drawPlayer(player, false)
        -- Should draw shield effect (multiple circles)
        local circleCount = countDrawCalls("circle")
        TestFramework.assert.isTrue(circleCount >= 2, "Should draw shield circles")
        -- Should have shield circle larger than player
        TestFramework.assert.isTrue(hasDrawCall("circle", function(call)
            return call.radius > player.radius
        end), "Shield should be larger than player")
    end,
    ["test draw player dashing"] = function()
        clearGraphicsCalls()
        local player = {
            x = 100,
            y = 200,
            radius = 10,
            hasShield = false
        }
        Renderer.drawPlayer(player, true)
        -- Should draw larger circle when dashing
        TestFramework.assert.isTrue(hasDrawCall("circle", function(call)
            return call.radius > 10
        end), "Dashing player should be larger")
    end,
    ["test draw player trail"] = function()
        clearGraphicsCalls()
        local trail = {
            {x = 100, y = 100, life = 1.0, isDashing = false},
            {x = 110, y = 110, life = 0.8, isDashing = false},
            {x = 120, y = 120, life = 0.6, isDashing = true}
        }
        Renderer.drawPlayerTrail(trail)
        -- Should draw circles for each trail point
        local circleCount = countDrawCalls("circle")
        TestFramework.assert.equal(3, circleCount, "Should draw circle for each trail point")
    end,
    ["test draw dash cooldown"] = function()
        clearGraphicsCalls()
        local player = {
            x = 100,
            y = 200,
            radius = 10,
            onPlanet = false
        }
        Renderer.drawDashCooldown(player, 0.5, 1.0)
        -- Should draw arc for cooldown
        TestFramework.assert.isTrue(hasDrawCall("arc"), "Should draw cooldown arc")
    end,
    ["test draw planets"] = function()
        clearGraphicsCalls()
        love.timer.currentTime = 1.0
        local planets = {
            {x = 100, y = 100, radius = 50, rotationSpeed = 1.0, discovered = true},
            {x = 300, y = 300, radius = 40, rotationSpeed = 0.5, discovered = false, type = "ice"}
        }
        Renderer.drawPlanets(planets)
        -- Should draw circles for planets
        local circleCount = countDrawCalls("circle")
        TestFramework.assert.isTrue(circleCount >= 2, "Should draw planet circles")
        -- Should draw rotation indicators (lines)
        TestFramework.assert.isTrue(hasDrawCall("line"), "Should draw rotation indicators")
    end,
    ["test draw rings"] = function()
        clearGraphicsCalls()
        -- Mock dependencies
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.ring_system" then return mockRingSystem
            elseif path == "src.core.game_state" then return mockGameState
            else return oldRequire(path) end
        end
        local rings = {
            {
                x = 100, y = 100,
                radius = 30, innerRadius = 20,
                rotation = 0, pulsePhase = 0,
                collected = false,
                color = {1, 1, 1, 0.8}
            }
        }
        Renderer.drawRings(rings)
        -- Should draw ring arcs
        TestFramework.assert.isTrue(hasDrawCall("arc"), "Should draw ring arcs")
        -- Restore
        Utils.require = oldRequire
    end,
    ["test draw particles"] = function()
        clearGraphicsCalls()
        local particles = {
            {x = 100, y = 100, color = {1, 0, 0}, lifetime = 1.0, maxLifetime = 1.0, size = 5},
            {x = 200, y = 200, color = {1, 0, 0}, lifetime = 0.5, maxLifetime = 1.0, size = 5},
            {x = 300, y = 300, color = {0, 1, 0}, lifetime = 1.0, maxLifetime = 1.0, size = 3}
        }
        Renderer.drawParticles(particles)
        -- Should draw circles for particles
        local circleCount = countDrawCalls("circle")
        TestFramework.assert.equal(3, circleCount, "Should draw circle for each particle")
    end,
    ["test draw pull indicator"] = function()
        clearGraphicsCalls()
        local player = {
            x = 100,
            y = 100,
            onPlanet = 1
        }
        Renderer.drawPullIndicator(player, 200, 200, 150, 150, 50, 100)
        -- Should draw pull line
        TestFramework.assert.isTrue(hasDrawCall("line"), "Should draw pull line")
        -- Should draw power indicator circle
        TestFramework.assert.isTrue(hasDrawCall("circle"), "Should draw power indicator")
    end,
    ["test draw mobile controls"] = function()
        clearGraphicsCalls()
        -- Mock mobile check
        Utils.MobileInput = { isMobile = function() return true end }
        local player = {
            x = 400,
            y = 300,
            onPlanet = 1,
            dashCooldown = 0,
            isDashing = false
        }
        local fonts = { bold = {}, light = {} }
        Renderer.drawMobileControls(player, fonts)
        -- Should draw dash button
        TestFramework.assert.isTrue(hasDrawCall("circle"), "Should draw dash button")
        -- Should draw pause button
        TestFramework.assert.isTrue(hasDrawCall("rectangle"), "Should draw pause button")
        -- Should draw text
        TestFramework.assert.isTrue(hasDrawCall("printf"), "Should draw button text")
    end,
    ["test draw UI elements"] = function()
        clearGraphicsCalls()
        local fonts = { bold = {}, regular = {} }
        Renderer.drawUI(1000, 5, 2.5, 1.5, fonts)
        -- Should draw score
        TestFramework.assert.isTrue(hasDrawCall("print", function(call)
            return string.find(call.text, "Score")
        end), "Should draw score")
        -- Should draw combo
        TestFramework.assert.isTrue(hasDrawCall("print", function(call)
            return string.find(call.text, "Combo")
        end), "Should draw combo")
    end,
    ["test draw game over"] = function()
        clearGraphicsCalls()
        local fonts = { extraBold = {}, bold = {}, regular = {} }
        Renderer.drawGameOver(5000, fonts)
        -- Should draw game over text
        TestFramework.assert.isTrue(hasDrawCall("printf", function(call)
            return string.find(call.text, "GAME OVER")
        end), "Should draw game over text")
        -- Should draw score
        TestFramework.assert.isTrue(hasDrawCall("printf", function(call)
            return string.find(call.text, "Score")
        end), "Should draw final score")
        -- Should draw restart instruction
        TestFramework.assert.isTrue(hasDrawCall("printf", function(call)
            return string.find(call.text, "Restart")
        end), "Should draw restart instruction")
    end,
    ["test draw sound status"] = function()
        clearGraphicsCalls()
        local fonts = { light = {} }
        Renderer.drawSoundStatus(false, fonts)
        -- Should draw sound off message
        TestFramework.assert.isTrue(hasDrawCall("print", function(call)
            return string.find(call.text, "Sound: OFF")
        end), "Should draw sound status")
    end,
    ["test draw exploration indicator"] = function()
        clearGraphicsCalls()
        local player = { x = 1000, y = 1000 }
        Renderer.camera = { scale = 0.8 }
        Renderer.fonts = { bold = {}, light = {} }
        Renderer.drawExplorationIndicator(player)
        -- Should draw distance
        TestFramework.assert.isTrue(hasDrawCall("print", function(call)
            return string.find(call.text, "Distance")
        end), "Should draw distance indicator")
        -- Should draw zoom
        TestFramework.assert.isTrue(hasDrawCall("print", function(call)
            return string.find(call.text, "Zoom")
        end), "Should draw zoom indicator")
    end,
    ["test draw danger warning"] = function()
        clearGraphicsCalls()
        love.timer.currentTime = 1.0
        local player = { x = 3000, y = 3000 }
        Renderer.fonts = { bold = {} }
        Renderer.camera = { scale = 1.0 }  -- Add missing camera
        Renderer.drawExplorationIndicator(player)
        -- Should draw warning when far from origin
        TestFramework.assert.isTrue(hasDrawCall("printf", function(call)
            return string.find(call.text, "WARNING")
        end), "Should draw void warning")
    end,
    ["test utility drawing functions"] = function()
        clearGraphicsCalls()
        -- Test drawButton
        Renderer.drawButton("Test", 10, 20, 100, 50, false)
        -- Test drawProgressBar
        Renderer.drawProgressBar(10, 100, 200, 20, 0.5)
        -- Test drawText
        Renderer.drawText("Hello", 10, 10)
        -- Test drawCenteredText
        Renderer.drawCenteredText("Centered", 100)
        -- Test drawPanel
        Renderer.drawPanel(0, 0, 100, 100)
        -- Should have various draw calls
        TestFramework.assert.isTrue(#graphicsCalls > 0, "Utility functions should generate draw calls")
    end,
    ["test special ring effects"] = function()
        clearGraphicsCalls()
        love.timer.currentTime = 1.0
        local oldRequire = Utils.require
        Utils.require = function(path)
            if path == "src.systems.ring_system" then return mockRingSystem
            elseif path == "src.core.game_state" then return mockGameState
            else return oldRequire(path) end
        end
        -- Test various ring types
        local rings = {
            {x = 100, y = 100, radius = 30, innerRadius = 20, rotation = 0, pulsePhase = 0,
             collected = false, color = {1, 1, 1, 0.8}, type = "power_shield"},
            {x = 200, y = 200, radius = 30, innerRadius = 20, rotation = 0, pulsePhase = 0,
             collected = false, color = {1, 1, 1, 0.8}, type = "warp"},
            {x = 300, y = 300, radius = 30, innerRadius = 20, rotation = 0, pulsePhase = 0,
             collected = false, color = {1, 1, 1, 0.8}, type = "chain", chainNumber = 1}
        }
        Renderer.drawRings(rings)
        -- Should have special effects for different ring types
        TestFramework.assert.isTrue(hasDrawCall("circle"), "Should draw ring effects")
        TestFramework.assert.isTrue(hasDrawCall("arc"), "Should draw ring arcs")
        -- Warp rings should use push/pop for rotation
        TestFramework.assert.isTrue(hasDrawCall("push"), "Warp rings should use transform push")
        TestFramework.assert.isTrue(hasDrawCall("pop"), "Warp rings should use transform pop")
        -- Chain rings should show numbers
        TestFramework.assert.isTrue(hasDrawCall("printf", function(call)
            return call.text == "1"
        end), "Chain rings should show sequence number")
        -- Restore
        Utils.require = oldRequire
    end
}
-- Function to restore original graphics functions
local function restoreOriginalGraphics()
    for k, v in pairs(originalGraphics) do
        if type(v) == "function" then
            love.graphics[k] = v
        end
    end
end
-- Run the test suite
local function run()
    -- Ensure clean state before running tests
    Mocks.setup()
    TestFramework.init()
    -- Ensure our graphics tracking is in place
    ensureGraphicsTracking()
    local result = TestFramework.runTests(tests, "Renderer Tests")
    -- Restore original graphics functions to prevent pollution
    restoreOriginalGraphics()
    return result
end
-- Run tests if executed directly
if arg and arg[0] and string.find(arg[0], "test_renderer.lua") then
    run()
end
return {run = run}