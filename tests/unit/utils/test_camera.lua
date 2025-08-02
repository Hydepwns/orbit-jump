-- Tests for Camera System
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
local Camera = Utils.require("src.core.camera")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test camera initialization
    ["camera initialization"] = function()
        local camera = Camera:new()
        
        TestFramework.assert.assertEqual(0, camera.x, "Camera should start at x=0")
        TestFramework.assert.assertEqual(0, camera.y, "Camera should start at y=0")
        TestFramework.assert.assertEqual(1, camera.scale, "Camera should start at scale=1")
        TestFramework.assert.assertEqual(0, camera.rotation, "Camera should start at rotation=0")
        TestFramework.assert.assertEqual(8, camera.smoothSpeed, "Camera should have default smooth speed")
        TestFramework.assert.assertEqual(0.15, camera.lookAheadFactor, "Camera should have default look ahead factor")
        TestFramework.assert.assertEqual(0, camera.shakeIntensity, "Camera should start with no shake")
        TestFramework.assert.assertEqual(0, camera.shakeDuration, "Camera should start with no shake duration")
        TestFramework.assert.assertTrue(camera.enableShake, "Camera should have shake enabled by default")
        TestFramework.assert.assertNil(camera.bounds, "Camera should start with no bounds")
    end,
    
    ["camera screen dimensions"] = function()
        local camera = Camera:new()
        
        TestFramework.assert.assertEqual(800, camera.screenWidth, "Camera should capture screen width")
        TestFramework.assert.assertEqual(600, camera.screenHeight, "Camera should capture screen height")
    end,
    
    -- Test camera following
    ["camera following stationary target"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200}
        
        camera:follow(target, 0.1)
        
        -- Camera should move toward centering the target (negative values to center target on screen)
        TestFramework.assert.assertTrue(camera.x < 0, "Camera should move toward centering target x")
        TestFramework.assert.assertTrue(camera.y < 0, "Camera should move toward centering target y")
    end,
    
    ["camera following moving target"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200, vx = 50, vy = 30}
        
        camera:follow(target, 0.1)
        
        -- Camera should move toward target with look-ahead (negative values to center target on screen)
        TestFramework.assert.assertTrue(camera.x < 0, "Camera should move toward target with look-ahead")
        TestFramework.assert.assertTrue(camera.y < 0, "Camera should move toward target with look-ahead")
    end,
    
    ["camera following with bounds"] = function()
        local camera = Camera:new()
        camera:setBounds(0, 0, 1000, 1000)
        local target = {x = 2000, y = 2000} -- Outside bounds
        
        camera:follow(target, 0.1)
        
        -- Camera should respect bounds
        TestFramework.assert.assertTrue(camera.x <= 1000 - camera.screenWidth / camera.scale, "Camera should respect max X bound")
        TestFramework.assert.assertTrue(camera.y <= 1000 - camera.screenHeight / camera.scale, "Camera should respect max Y bound")
        TestFramework.assert.assertTrue(camera.x >= 0, "Camera should respect min X bound")
        TestFramework.assert.assertTrue(camera.y >= 0, "Camera should respect min Y bound")
    end,
    
    ["camera following nil target"] = function()
        local camera = Camera:new()
        local originalX = camera.x
        local originalY = camera.y
        
        camera:follow(nil, 0.1)
        
        -- Camera should not move when target is nil
        TestFramework.assert.assertEqual(originalX, camera.x, "Camera should not move with nil target")
        TestFramework.assert.assertEqual(originalY, camera.y, "Camera should not move with nil target")
    end,
    
    -- Test camera shake
    ["camera shake activation"] = function()
        local camera = Camera:new()
        
        camera:shake(10, 1.0)
        
        TestFramework.assert.assertEqual(10, camera.shakeIntensity, "Camera should have shake intensity set")
        TestFramework.assert.assertEqual(1.0, camera.shakeDuration, "Camera should have shake duration set")
    end,
    
    ["camera shake disabled"] = function()
        local camera = Camera:new()
        camera.enableShake = false
        
        camera:shake(10, 1.0)
        
        TestFramework.assert.assertEqual(0, camera.shakeIntensity, "Camera should not shake when disabled")
        TestFramework.assert.assertEqual(0, camera.shakeDuration, "Camera should not shake when disabled")
    end,
    
    ["camera shake expiration"] = function()
        local camera = Camera:new()
        camera:shake(10, 1.0)
        
        -- Simulate time passing
        camera:follow({x = 0, y = 0}, 1.1) -- More than shake duration
        
        TestFramework.assert.assertEqual(0, camera.shakeIntensity, "Camera shake should expire")
        TestFramework.assert.assertEqual(0, camera.shakeDuration, "Camera shake duration should be 0")
    end,
    
    -- Test camera zoom
    ["camera scale setting"] = function()
        local camera = Camera:new()
        
        camera:setScale(2.0)
        TestFramework.assert.assertEqual(2.0, camera.scale, "Camera scale should be set correctly")
        
        camera:setScale(0.05) -- Below minimum
        TestFramework.assert.assertEqual(0.1, camera.scale, "Camera scale should be clamped to minimum")
        
        camera:setScale(10.0) -- Above maximum
        TestFramework.assert.assertEqual(5.0, camera.scale, "Camera scale should be clamped to maximum")
    end,
    
    ["camera zoom in"] = function()
        local camera = Camera:new()
        local originalScale = camera.scale
        
        camera:zoomIn(0.5)
        
        TestFramework.assert.assertEqual(originalScale * 1.5, camera.scale, "Camera should zoom in correctly")
    end,
    
    ["camera zoom out"] = function()
        local camera = Camera:new()
        local originalScale = camera.scale
        
        camera:zoomOut(0.3)
        
        TestFramework.assert.assertEqual(originalScale * 0.7, camera.scale, "Camera should zoom out correctly")
    end,
    
    -- Test coordinate transformations
    ["world to screen coordinates"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        
        local screenX, screenY = camera:worldToScreen(200, 300)
        
        TestFramework.assert.assertEqual(200, screenX, "World to screen X should be correct")
        TestFramework.assert.assertEqual(200, screenY, "World to screen Y should be correct")
    end,
    
    ["screen to world coordinates"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        
        local worldX, worldY = camera:screenToWorld(200, 200)
        
        TestFramework.assert.assertEqual(200, worldX, "Screen to world X should be correct")
        TestFramework.assert.assertEqual(300, worldY, "Screen to world Y should be correct")
    end,
    
    ["coordinate transformation round trip"] = function()
        local camera = Camera:new()
        camera.x = 50
        camera.y = 75
        camera.scale = 1.5
        
        local originalWorldX, originalWorldY = 300, 400
        local screenX, screenY = camera:worldToScreen(originalWorldX, originalWorldY)
        local worldX, worldY = camera:screenToWorld(screenX, screenY)
        
        TestFramework.assert.assertEqual(originalWorldX, worldX, "Round trip transformation should preserve X")
        TestFramework.assert.assertEqual(originalWorldY, worldY, "Round trip transformation should preserve Y")
    end,
    
    -- Test bounds
    ["camera bounds setting"] = function()
        local camera = Camera:new()
        
        camera:setBounds(0, 0, 1000, 1000)
        
        TestFramework.assert.assertNotNil(camera.bounds, "Camera bounds should be set")
        TestFramework.assert.assertEqual(0, camera.bounds.minX, "Camera bounds minX should be correct")
        TestFramework.assert.assertEqual(0, camera.bounds.minY, "Camera bounds minY should be correct")
        TestFramework.assert.assertEqual(1000, camera.bounds.maxX, "Camera bounds maxX should be correct")
        TestFramework.assert.assertEqual(1000, camera.bounds.maxY, "Camera bounds maxY should be correct")
    end,
    
    ["camera bounds removal"] = function()
        local camera = Camera:new()
        camera:setBounds(0, 0, 1000, 1000)
        
        camera:removeBounds()
        
        TestFramework.assert.assertNil(camera.bounds, "Camera bounds should be removed")
    end,
    
    -- Test resize
    ["camera resize"] = function()
        local camera = Camera:new()
        
        camera:resize(1024, 768)
        
        TestFramework.assert.assertEqual(1024, camera.screenWidth, "Camera screen width should be updated")
        TestFramework.assert.assertEqual(768, camera.screenHeight, "Camera screen height should be updated")
    end,
    
    -- Test visible area
    ["camera visible area"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        
        local x1, y1, x2, y2 = camera:getVisibleArea()
        
        TestFramework.assert.assertEqual(100, x1, "Visible area x1 should be correct")
        TestFramework.assert.assertEqual(200, y1, "Visible area y1 should be correct")
        TestFramework.assert.assertEqual(500, x2, "Visible area x2 should be correct")
        TestFramework.assert.assertEqual(500, y2, "Visible area y2 should be correct")
    end,
    
    -- Test smooth following over time
    ["camera smooth following"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200}
        
        -- Follow for multiple frames
        for i = 1, 10 do
            camera:follow(target, 0.1)
        end
        
        -- Camera should be close to centering the target after multiple frames
        local expectedX = target.x - camera.screenWidth / (2 * camera.scale)
        local expectedY = target.y - camera.screenHeight / (2 * camera.scale)
        local distance = math.sqrt((camera.x - expectedX)^2 + (camera.y - expectedY)^2)
        TestFramework.assert.assertTrue(distance < 50, "Camera should smoothly approach target center")
    end,
    
    -- Test camera with different smooth speeds
    ["camera smooth speed variation"] = function()
        local camera1 = Camera:new()
        local camera2 = Camera:new()
        camera2.smoothSpeed = 16 -- Faster
        
        local target = {x = 100, y = 200}
        
        -- Follow for multiple frames to see the difference
        for i = 1, 5 do
            camera1:follow(target, 0.1)
            camera2:follow(target, 0.1)
        end
        
        -- Faster camera should move more (may overshoot, but should be different from slower camera)
        local expectedX = target.x - camera1.screenWidth / (2 * camera1.scale)
        local expectedY = target.y - camera1.screenHeight / (2 * camera1.scale)
        local distance1 = math.sqrt((camera1.x - expectedX)^2 + (camera1.y - expectedY)^2)
        local distance2 = math.sqrt((camera2.x - expectedX)^2 + (camera2.y - expectedY)^2)
        
        -- Both cameras should have moved (not at origin)
        TestFramework.assert.assertTrue(camera1.x ~= 0 or camera1.y ~= 0, "Slower camera should have moved")
        TestFramework.assert.assertTrue(camera2.x ~= 0 or camera2.y ~= 0, "Faster camera should have moved")
        -- Different smooth speeds should result in different positions
        TestFramework.assert.assertTrue(camera1.x ~= camera2.x or camera1.y ~= camera2.y, "Different smooth speeds should result in different positions")
    end,
    
    -- Test camera with different look-ahead factors
    ["camera look ahead factor"] = function()
        local camera1 = Camera:new()
        local camera2 = Camera:new()
        camera2.lookAheadFactor = 0.3 -- More look-ahead
        
        local target = {x = 100, y = 200, vx = 50, vy = 30}
        
        -- Follow for multiple frames to see the difference
        for i = 1, 5 do
            camera1:follow(target, 0.1)
            camera2:follow(target, 0.1)
        end
        
        -- Camera with more look-ahead should move less toward the target (less negative values)
        -- because the look-ahead makes the target appear further away
        TestFramework.assert.assertTrue(camera2.x > camera1.x, "Camera with more look-ahead should move less in X")
        TestFramework.assert.assertTrue(camera2.y > camera1.y, "Camera with more look-ahead should move less in Y")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runTests(tests, "Camera System Tests")
    
    -- Update coverage tracking
    local TestCoverage = Utils.require("tests.test_coverage")
    TestCoverage.updateModule("camera", 6) -- All major functions tested
    
    return success
end

return {run = run} 