-- Test file for Camera System
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Ensure love.graphics exists for camera tests
if not love then love = {} end
if not love.graphics then love.graphics = {} end
-- Mock love.graphics functions
love.graphics.getWidth = function() return 800 end
love.graphics.getHeight = function() return 600 end
love.graphics.push = function() end
love.graphics.pop = function() end
love.graphics.translate = function() end
love.graphics.scale = function() end
love.graphics.rotate = function() end
-- Initialize test framework
TestFramework.init()
-- Test suite
local tests = {
    ["test camera creation"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        TestFramework.assert.notNil(camera, "Camera should be created")
        TestFramework.assert.equal(0, camera.x, "Initial x should be 0")
        TestFramework.assert.equal(0, camera.y, "Initial y should be 0")
        TestFramework.assert.equal(1, camera.scale, "Initial scale should be 1")
        TestFramework.assert.equal(0, camera.rotation, "Initial rotation should be 0")
        TestFramework.assert.equal(8, camera.smoothSpeed, "Smooth speed should be 8")
        TestFramework.assert.equal(0.15, camera.lookAheadFactor, "Look ahead factor should be 0.15")
        TestFramework.assert.equal(true, camera.enableShake, "Shake should be enabled by default")
        TestFramework.assert.equal(800, camera.screenWidth, "Screen width should be 800")
        TestFramework.assert.equal(600, camera.screenHeight, "Screen height should be 600")
    end,
    ["test camera follow without velocity"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Start with camera at a different position
        camera.x = 100
        camera.y = 100
        local target = {x = 400, y = 300}
        camera:follow(target, 0.016) -- ~60 FPS
        -- Camera should move towards centering the target
        TestFramework.assert.notEqual(100, camera.x, "Camera x should have moved from initial position")
        TestFramework.assert.notEqual(100, camera.y, "Camera y should have moved from initial position")
        -- Test multiple updates to see smooth following
        for i = 1, 100 do
            camera:follow(target, 0.016)
        end
        -- Camera should be nearly centered on target
        -- With scale=1, screen center is at 400,300
        -- So camera position should be target - screen_center
        local expectedX = target.x - 400 -- (screenWidth / 2)
        local expectedY = target.y - 300 -- (screenHeight / 2)
        TestFramework.assert.approx(expectedX, camera.x, 1, "Camera x should center on target")
        TestFramework.assert.approx(expectedY, camera.y, 1, "Camera y should center on target")
    end,
    ["test camera follow with velocity"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        local target = {x = 400, y = 300, vx = 100, vy = 50}
        camera:follow(target, 0.016)
        -- Camera should look ahead based on velocity
        TestFramework.assert.notEqual(0, camera.x, "Camera x should have moved")
        TestFramework.assert.notEqual(0, camera.y, "Camera y should have moved")
    end,
    ["test camera follow with nil target"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        local initialX = camera.x
        local initialY = camera.y
        camera:follow(nil, 0.016)
        TestFramework.assert.equal(initialX, camera.x, "Camera x should not change")
        TestFramework.assert.equal(initialY, camera.y, "Camera y should not change")
    end,
    ["test camera bounds"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Set bounds
        camera:setBounds(0, 0, 1000, 800)
        TestFramework.assert.notNil(camera.bounds, "Bounds should be set")
        TestFramework.assert.equal(0, camera.bounds.minX, "Min X bound")
        TestFramework.assert.equal(0, camera.bounds.minY, "Min Y bound")
        TestFramework.assert.equal(1000, camera.bounds.maxX, "Max X bound")
        TestFramework.assert.equal(800, camera.bounds.maxY, "Max Y bound")
        -- Test following with bounds
        local target = {x = 2000, y = 1500} -- Far outside bounds
        for i = 1, 100 do
            camera:follow(target, 0.016)
        end
        -- Camera should be constrained by bounds
        TestFramework.assert.lessThanOrEqual(camera.x, 1000 - 800, "Camera x should respect max bound")
        TestFramework.assert.lessThanOrEqual(camera.y, 800 - 600, "Camera y should respect max bound")
        -- Remove bounds
        camera:removeBounds()
        TestFramework.assert.isNil(camera.bounds, "Bounds should be removed")
    end,
    ["test camera shake"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Initial state
        TestFramework.assert.equal(0, camera.shakeIntensity, "Initial shake intensity should be 0")
        TestFramework.assert.equal(0, camera.shakeDuration, "Initial shake duration should be 0")
        -- Apply shake
        camera:shake(10, 0.1)
        TestFramework.assert.equal(10, camera.shakeIntensity, "Shake intensity should be set")
        TestFramework.assert.equal(0.1, camera.shakeDuration, "Shake duration should be set")
        -- Update shake - duration becomes exactly 0
        camera:follow({x = 0, y = 0}, 0.1)
        -- At this point: shakeDuration was 0.1, which is > 0, so it subtracts 0.1 making it 0
        -- On next call, shakeDuration is 0 (not > 0), so else clause runs
        -- Call follow again to trigger the else clause
        camera:follow({x = 0, y = 0}, 0.01)
        TestFramework.assert.equal(0, camera.shakeIntensity, "Shake intensity should be reset to 0")
        -- Test with negative duration
        camera:shake(5, 0.05)
        camera:follow({x = 0, y = 0}, 0.1) -- Makes duration negative
        camera:follow({x = 0, y = 0}, 0.01) -- Should reset intensity
        TestFramework.assert.equal(0, camera.shakeIntensity, "Shake intensity reset after negative duration")
    end,
    ["test camera shake disabled"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        camera.enableShake = false
        camera:shake(10, 0.5)
        TestFramework.assert.equal(0, camera.shakeIntensity, "Shake intensity should remain 0")
        TestFramework.assert.equal(0, camera.shakeDuration, "Shake duration should remain 0")
    end,
    ["test camera scale"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Test setScale
        camera:setScale(2)
        TestFramework.assert.equal(2, camera.scale, "Scale should be 2")
        -- Test scale limits
        camera:setScale(10)
        TestFramework.assert.equal(5, camera.scale, "Scale should be clamped to 5")
        camera:setScale(0.01)
        TestFramework.assert.equal(0.1, camera.scale, "Scale should be clamped to 0.1")
        -- Test zoomIn
        camera:setScale(1)
        camera:zoomIn(0.5)
        TestFramework.assert.equal(1.5, camera.scale, "Scale should be 1.5 after zoom in")
        -- Test zoomOut from 1.5
        camera:zoomOut(0.2)
        TestFramework.assert.approx(1.2, camera.scale, 0.0001, "Scale should be 1.2 after zoom out")
    end,
    ["test coordinate conversion"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Set camera position and scale
        camera.x = 100
        camera.y = 50
        camera.scale = 2
        -- Test worldToScreen
        local screenX, screenY = camera:worldToScreen(200, 150)
        TestFramework.assert.equal(200, screenX, "Screen X = (200-100)*2")
        TestFramework.assert.equal(200, screenY, "Screen Y = (150-50)*2")
        -- Test screenToWorld
        local worldX, worldY = camera:screenToWorld(200, 200)
        TestFramework.assert.equal(200, worldX, "World X = 200/2+100")
        TestFramework.assert.equal(150, worldY, "World Y = 200/2+50")
        -- Test round trip
        local wx, wy = camera:screenToWorld(screenX, screenY)
        TestFramework.assert.equal(200, wx, "Round trip world X")
        TestFramework.assert.equal(150, wy, "Round trip world Y")
    end,
    ["test camera resize"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        camera:resize(1024, 768)
        TestFramework.assert.equal(1024, camera.screenWidth, "Screen width should update")
        TestFramework.assert.equal(768, camera.screenHeight, "Screen height should update")
    end,
    ["test get visible area"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Set camera position and scale
        camera.x = 100
        camera.y = 50
        camera.scale = 2
        local x1, y1, x2, y2 = camera:getVisibleArea()
        TestFramework.assert.equal(100, x1, "Visible area x1")
        TestFramework.assert.equal(50, y1, "Visible area y1")
        TestFramework.assert.equal(500, x2, "Visible area x2 = 100 + 800/2")
        TestFramework.assert.equal(350, y2, "Visible area y2 = 50 + 600/2")
    end,
    ["test camera apply and clear"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        local pushCalled = false
        local popCalled = false
        local transformCalls = {}
        love.graphics.push = function()
            pushCalled = true
        end
        love.graphics.pop = function()
            popCalled = true
        end
        love.graphics.translate = function(x, y)
            table.insert(transformCalls, {type = "translate", x = x, y = y})
        end
        love.graphics.scale = function(sx, sy)
            table.insert(transformCalls, {type = "scale", sx = sx, sy = sy})
        end
        love.graphics.rotate = function(angle)
            table.insert(transformCalls, {type = "rotate", angle = angle})
        end
        -- Apply camera transformations
        camera.x = 100
        camera.y = 50
        camera.scale = 2
        camera.rotation = math.pi / 4
        camera:apply()
        TestFramework.assert.equal(true, pushCalled, "Push should be called")
        TestFramework.assert.equal(5, #transformCalls, "Should have 5 transformation calls")
        -- Check transformation types
        local hasTranslate = false
        local hasScale = false
        local hasRotate = false
        for _, call in ipairs(transformCalls) do
            if call.type == "translate" then hasTranslate = true end
            if call.type == "scale" then hasScale = true end
            if call.type == "rotate" then hasRotate = true end
        end
        TestFramework.assert.equal(true, hasTranslate, "Should have translate calls")
        TestFramework.assert.equal(true, hasScale, "Should have scale calls")
        TestFramework.assert.equal(true, hasRotate, "Should have rotate calls")
        -- Clear camera
        camera:clear()
        TestFramework.assert.equal(true, popCalled, "Pop should be called")
    end,
    ["test camera shake with apply"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Mock math.random for predictable shake
        local originalRandom = math.random
        math.random = function() return 0.5 end
        local translateCalls = {}
        love.graphics.translate = function(x, y)
            table.insert(translateCalls, {x = x, y = y})
        end
        -- Mock other graphics functions
        love.graphics.scale = function() end
        love.graphics.rotate = function() end
        camera.shakeIntensity = 10
        camera.shakeDuration = 1
        camera:apply()
        -- Should have 3 translate calls:
        -- 1. Center to screen width/2, height/2
        -- 2. Uncenter after scale/rotate (-width/2, -height/2)
        -- 3. Apply camera position with shake
        TestFramework.assert.equal(3, #translateCalls, "Should have 3 translate calls")
        -- Last translate should include shake offset
        -- Shake offset = (0.5 - 0.5) * 10 = 0 for both x and y
        local lastTranslate = translateCalls[#translateCalls]
        TestFramework.assert.equal(-camera.x, lastTranslate.x, "X should be -camera.x + shake (0)")
        TestFramework.assert.equal(-camera.y, lastTranslate.y, "Y should be -camera.y + shake (0)")
        -- Restore original random
        math.random = originalRandom
    end,
    ["test camera follow with bounds edge cases"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        -- Set very small bounds
        camera:setBounds(0, 0, 400, 300)
        -- Target at origin
        local target = {x = 0, y = 0}
        for i = 1, 100 do
            camera:follow(target, 0.016)
        end
        -- Camera should be at minimum bounds
        TestFramework.assert.greaterThanOrEqual(camera.x, 0, "Camera x at min bound")
        TestFramework.assert.greaterThanOrEqual(camera.y, 0, "Camera y at min bound")
    end,
    ["test camera metatable"] = function()
        local Camera = Utils.require("src.core.camera")
        local camera = Camera:new()
        TestFramework.assert.equal(Camera, getmetatable(camera).__index, "Metatable should be set correctly")
    end
}
-- Run tests
TestFramework.runTests(tests)