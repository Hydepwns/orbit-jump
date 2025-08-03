--[[
    Example test using LÖVE2D graphics features
    This demonstrates how to test code that depends on LÖVE2D APIs
    like graphics, physics, and audio.
--]]
local TestSuite = {}
-- Test that we can create graphics objects
TestSuite["Canvas creation"] = function()
    -- This would fail in standard Lua but works in LÖVE2D
    local canvas = love.graphics.newCanvas(100, 100)
    TestFramework.assert.truthy(canvas, "Should create canvas")
    TestFramework.assert.equal(canvas:getWidth(), 100, "Canvas width should be 100")
    TestFramework.assert.equal(canvas:getHeight(), 100, "Canvas height should be 100")
end
-- Test font loading
TestSuite["Font loading"] = function()
    local font = love.graphics.newFont(12)
    TestFramework.assert.truthy(font, "Should create font")
    TestFramework.assert.equal(font:getHeight(), 12, "Font height should match size")
end
-- Test color operations
TestSuite["Color setting"] = function()
    love.graphics.setColor(1, 0.5, 0.25, 0.75)
    local r, g, b, a = love.graphics.getColor()
    TestFramework.assert.near(r, 1, 0.01, "Red component should be 1")
    TestFramework.assert.near(g, 0.5, 0.01, "Green component should be 0.5")
    TestFramework.assert.near(b, 0.25, 0.01, "Blue component should be 0.25")
    TestFramework.assert.near(a, 0.75, 0.01, "Alpha component should be 0.75")
end
-- Test transformation stack
TestSuite["Transform stack"] = function()
    love.graphics.push()
    love.graphics.translate(100, 200)
    love.graphics.scale(2, 2)
    -- Create transform and check it
    local transform = love.graphics.newTransform()
    transform:translate(100, 200)
    transform:scale(2, 2)
    love.graphics.pop()
    TestFramework.assert.truthy(transform, "Should create transform")
end
-- Test shader compilation
TestSuite["Shader creation"] = function()
    local vertexCode = [[
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return transform_projection * vertex_position;
        }
    ]]
    local pixelCode = [[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            return vec4(1.0, 0.0, 0.0, 1.0); // Red
        }
    ]]
    local success, shader = pcall(love.graphics.newShader, pixelCode, vertexCode)
    if success then
        TestFramework.assert.truthy(shader, "Should create shader")
    else
        -- Skip test if shaders not supported
        print("   ⚠️  Shaders not supported on this system")
    end
end
-- Test image data operations
TestSuite["ImageData manipulation"] = function()
    local imageData = love.image.newImageData(10, 10)
    TestFramework.assert.equal(imageData:getWidth(), 10, "Width should be 10")
    TestFramework.assert.equal(imageData:getHeight(), 10, "Height should be 10")
    -- Set and get pixel
    imageData:setPixel(5, 5, 1, 0, 0, 1) -- Red pixel
    local r, g, b, a = imageData:getPixel(5, 5)
    TestFramework.assert.near(r, 1, 0.01, "Red should be 1")
    TestFramework.assert.near(g, 0, 0.01, "Green should be 0")
    TestFramework.assert.near(b, 0, 0.01, "Blue should be 0")
    TestFramework.assert.near(a, 1, 0.01, "Alpha should be 1")
end
-- Test physics world creation
TestSuite["Physics world"] = function()
    local world = love.physics.newWorld(0, 9.81 * 64) -- Gravity
    TestFramework.assert.truthy(world, "Should create physics world")
    local gx, gy = world:getGravity()
    TestFramework.assert.equal(gx, 0, "Gravity X should be 0")
    TestFramework.assert.near(gy, 9.81 * 64, 0.01, "Gravity Y should match")
    -- Create a body
    local body = love.physics.newBody(world, 100, 100, "dynamic")
    TestFramework.assert.truthy(body, "Should create physics body")
    TestFramework.assert.equal(body:getX(), 100, "Body X should be 100")
    TestFramework.assert.equal(body:getY(), 100, "Body Y should be 100")
end
-- Test audio source creation
TestSuite["Audio system"] = function()
    -- Test with generated audio data
    local sampleRate = 44100
    local samples = sampleRate * 0.1 -- 0.1 seconds
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    -- Generate a simple sine wave
    for i = 0, samples - 1 do
        local amplitude = 0.5
        local frequency = 440 -- A4 note
        local sample = amplitude * math.sin(2 * math.pi * frequency * i / sampleRate)
        soundData:setSample(i, sample)
    end
    local source = love.audio.newSource(soundData)
    TestFramework.assert.truthy(source, "Should create audio source")
    TestFramework.assert.equal(source:getChannelCount(), 1, "Should be mono")
end
return TestSuite