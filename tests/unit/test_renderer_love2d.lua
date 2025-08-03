--[[
    Renderer tests that require LÖVE2D context
    Tests the actual rendering functions with LÖVE2D graphics APIs
--]]
local Utils = require("src.utils.utils")
local Renderer = Utils.require("src.core.renderer")
local TestSuite = {}
-- Setup function to initialize renderer
function TestSuite.setup()
    -- Initialize fonts (required by renderer)
    _G.GameFonts = {
        regular = love.graphics.newFont(12),
        bold = love.graphics.newFont(14),
        light = love.graphics.newFont(10)
    }
    -- Initialize renderer if needed
    if Renderer.init then
        Renderer.init()
    end
end
-- Test planet rendering
TestSuite["Planet rendering"] = function()
    -- Create a test planet
    local planet = {
        x = 100,
        y = 100,
        radius = 50,
        type = "earth",
        color = {0.2, 0.6, 0.2}
    }
    -- Create a canvas to render to
    local canvas = love.graphics.newCanvas(200, 200)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    -- Render the planet
    Renderer.drawPlanet(planet)
    love.graphics.setCanvas()
    -- Verify canvas was drawn to (check that it's not all black)
    local imageData = canvas:newImageData()
    local hasColor = false
    for x = 0, imageData:getWidth() - 1 do
        for y = 0, imageData:getHeight() - 1 do
            local r, g, b, a = imageData:getPixel(x, y)
            if r > 0 or g > 0 or b > 0 then
                hasColor = true
                break
            end
        end
        if hasColor then break end
    end
    TestFramework.assert.truthy(hasColor, "Planet should be rendered to canvas")
end
-- Test particle rendering
TestSuite["Particle rendering"] = function()
    local particles = {
        {x = 50, y = 50, vx = 10, vy = 0, life = 1, maxLife = 2, size = 5, color = {1, 1, 0, 1}},
        {x = 100, y = 100, vx = -10, vy = 10, life = 0.5, maxLife = 1, size = 3, color = {1, 0, 0, 1}}
    }
    -- Should not error
    local success = pcall(function()
        Renderer.drawParticles(particles)
    end)
    TestFramework.assert.truthy(success, "Particle rendering should not error")
end
-- Test text rendering with shadows
TestSuite["Text with shadow"] = function()
    local canvas = love.graphics.newCanvas(200, 100)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    -- Draw text with shadow
    Renderer.drawTextWithShadow("Test Text", 50, 50, {1, 1, 1, 1}, "center")
    love.graphics.setCanvas()
    -- Check that something was drawn
    local imageData = canvas:newImageData()
    local hasNonBlack = false
    for x = 0, imageData:getWidth() - 1 do
        for y = 0, imageData:getHeight() - 1 do
            local r, g, b = imageData:getPixel(x, y)
            if r > 0 or g > 0 or b > 0 then
                hasNonBlack = true
                break
            end
        end
        if hasNonBlack then break end
    end
    TestFramework.assert.truthy(hasNonBlack, "Text should be rendered")
end
-- Test ring rendering
TestSuite["Ring rendering"] = function()
    local ring = {
        x = 100,
        y = 100,
        collected = false,
        rarity = {color = {1, 0.5, 0, 1}, name = "rare"},
        floatOffset = 0
    }
    -- Should render without error
    local success = pcall(function()
        Renderer.drawRing(ring)
    end)
    TestFramework.assert.truthy(success, "Ring rendering should not error")
end
-- Test background rendering
TestSuite["Background stars"] = function()
    -- Initialize stars if needed
    if not Renderer.stars then
        Renderer.initStars(800, 600)
    end
    local canvas = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 1)
    -- Draw background
    Renderer.drawBackground()
    love.graphics.setCanvas()
    -- Verify stars were drawn
    local imageData = canvas:newImageData()
    local starCount = 0
    for x = 0, imageData:getWidth() - 1, 10 do -- Sample every 10 pixels for speed
        for y = 0, imageData:getHeight() - 1, 10 do
            local r, g, b = imageData:getPixel(x, y)
            if r > 0.1 or g > 0.1 or b > 0.1 then
                starCount = starCount + 1
            end
        end
    end
    TestFramework.assert.truthy(starCount > 0, "Background should have stars")
end
-- Test shader effects if available
TestSuite["Shader effects"] = function()
    -- Try to create a simple shader
    local shaderCode = [[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            return vec4(1.0, 0.0, 0.0, 1.0) * color;
        }
    ]]
    local success, shader = pcall(love.graphics.newShader, shaderCode)
    if success then
        -- Test setting and unsetting shader
        love.graphics.setShader(shader)
        TestFramework.assert.equal(love.graphics.getShader(), shader, "Shader should be set")
        love.graphics.setShader()
        TestFramework.assert.falsy(love.graphics.getShader(), "Shader should be unset")
    else
        print("   ⚠️  Shaders not supported, skipping shader tests")
    end
end
-- Cleanup
function TestSuite.teardown()
    -- Reset graphics state
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    -- Clear globals
    _G.GameFonts = nil
end
return TestSuite