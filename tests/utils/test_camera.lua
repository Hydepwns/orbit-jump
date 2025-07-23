-- Tests for Camera System
package.path = package.path .. ";../../?.lua"

local TestFramework = require("tests.test_framework")
local Mocks = require("tests.mocks")
local Camera = require("src.core.camera")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test camera initialization
    ["camera initialization"] = function()
        local camera = Camera:new()
        
        TestFramework.utils.assertEqual(0, camera.x, "Camera should start at x=0")
        TestFramework.utils.assertEqual(0, camera.y, "Camera should start at y=0")
        TestFramework.utils.assertEqual(1, camera.scale, "Camera should start at scale=1")
        TestFramework.utils.assertEqual(0, camera.rotation, "Camera should start at rotation=0")
        TestFramework.utils.assertEqual(8, camera.smoothSpeed, "Camera should have default smooth speed")
        TestFramework.utils.assertEqual(0.15, camera.lookAheadFactor, "Camera should have default look ahead factor")
        TestFramework.utils.assertEqual(0, camera.shakeIntensity, "Camera should start with no shake")
        TestFramework.utils.assertEqual(0, camera.shakeDuration, "Camera should start with no shake duration")
        TestFramework.utils.assertTrue(camera.enableShake, "Camera should have shake enabled by default")
        TestFramework.utils.assertNil(camera.bounds, "Camera should start with no bounds")
    end,
    
    ["camera screen dimensions"] = function()
        local camera = Camera:new()
        
        TestFramework.utils.assertEqual(800, camera.screenWidth, "Camera should capture screen width")
        TestFramework.utils.assertEqual(600, camera.screenHeight, "Camera should capture screen height")
    end,
    
    -- Test camera following
    ["camera following stationary target"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200}
        
        camera:follow(target, 0.1)
        
        -- Camera should move toward target
        TestFramework.utils.assertTrue(camera.x > 0, "Camera should move toward target x")
        TestFramework.utils.assertTrue(camera.y > 0, "Camera should move toward target y")
    end,
    
    ["camera following moving target"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200, vx = 50, vy = 30}
        
        camera:follow(target, 0.1)
        
        -- Camera should move toward target with look-ahead
        TestFramework.utils.assertTrue(camera.x > 0, "Camera should move toward target with look-ahead")
        TestFramework.utils.assertTrue(camera.y > 0, "Camera should move toward target with look-ahead")
    end,
    
    ["camera following with bounds"] = function()
        local camera = Camera:new()
        camera:setBounds(0, 0, 1000, 1000)
        local target = {x = 2000, y = 2000} -- Outside bounds
        
        camera:follow(target, 0.1)
        
        -- Camera should respect bounds
        TestFramework.utils.assertTrue(camera.x <= 1000 - camera.screenWidth / camera.scale, "Camera should respect max X bound")
        TestFramework.utils.assertTrue(camera.y <= 1000 - camera.screenHeight / camera.scale, "Camera should respect max Y bound")
        TestFramework.utils.assertTrue(camera.x >= 0, "Camera should respect min X bound")
        TestFramework.utils.assertTrue(camera.y >= 0, "Camera should respect min Y bound")
    end,
    
    ["camera following nil target"] = function()
        local camera = Camera:new()
        local originalX = camera.x
        local originalY = camera.y
        
        camera:follow(nil, 0.1)
        
        -- Camera should not move when target is nil
        TestFramework.utils.assertEqual(originalX, camera.x, "Camera should not move with nil target")
        TestFramework.utils.assertEqual(originalY, camera.y, "Camera should not move with nil target")
    end,
    
    -- Test camera shake
    ["camera shake activation"] = function()
        local camera = Camera:new()
        
        camera:shake(10, 1.0)
        
        TestFramework.utils.assertEqual(10, camera.shakeIntensity, "Camera should have shake intensity set")
        TestFramework.utils.assertEqual(1.0, camera.shakeDuration, "Camera should have shake duration set")
    end,
    
    ["camera shake disabled"] = function()
        local camera = Camera:new()
        camera.enableShake = false
        
        camera:shake(10, 1.0)
        
        TestFramework.utils.assertEqual(0, camera.shakeIntensity, "Camera should not shake when disabled")
        TestFramework.utils.assertEqual(0, camera.shakeDuration, "Camera should not shake when disabled")
    end,
    
    ["camera shake expiration"] = function()
        local camera = Camera:new()
        camera:shake(10, 1.0)
        
        -- Simulate time passing
        camera:follow({x = 0, y = 0}, 1.1) -- More than shake duration
        
        TestFramework.utils.assertEqual(0, camera.shakeIntensity, "Camera shake should expire")
        TestFramework.utils.assertEqual(0, camera.shakeDuration, "Camera shake duration should be 0")
    end,
    
    -- Test camera zoom
    ["camera scale setting"] = function()
        local camera = Camera:new()
        
        camera:setScale(2.0)
        TestFramework.utils.assertEqual(2.0, camera.scale, "Camera scale should be set correctly")
        
        camera:setScale(0.05) -- Below minimum
        TestFramework.utils.assertEqual(0.1, camera.scale, "Camera scale should be clamped to minimum")
        
        camera:setScale(10.0) -- Above maximum
        TestFramework.utils.assertEqual(5.0, camera.scale, "Camera scale should be clamped to maximum")
    end,
    
    ["camera zoom in"] = function()
        local camera = Camera:new()
        local originalScale = camera.scale
        
        camera:zoomIn(0.5)
        
        TestFramework.utils.assertEqual(originalScale * 1.5, camera.scale, "Camera should zoom in correctly")
    end,
    
    ["camera zoom out"] = function()
        local camera = Camera:new()
        local originalScale = camera.scale
        
        camera:zoomOut(0.3)
        
        TestFramework.utils.assertEqual(originalScale * 0.7, camera.scale, "Camera should zoom out correctly")
    end,
    
    -- Test coordinate transformations
    ["world to screen coordinates"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        
        local screenX, screenY = camera:worldToScreen(200, 300)
        
        TestFramework.utils.assertEqual(200, screenX, "World to screen X should be correct")
        TestFramework.utils.assertEqual(200, screenY, "World to screen Y should be correct")
    end,
    
    ["screen to world coordinates"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        
        local worldX, worldY = camera:screenToWorld(200, 200)
        
        TestFramework.utils.assertEqual(200, worldX, "Screen to world X should be correct")
        TestFramework.utils.assertEqual(300, worldY, "Screen to world Y should be correct")
    end,
    
    ["coordinate transformation round trip"] = function()
        local camera = Camera:new()
        camera.x = 50
        camera.y = 75
        camera.scale = 1.5
        
        local originalWorldX, originalWorldY = 300, 400
        local screenX, screenY = camera:worldToScreen(originalWorldX, originalWorldY)
        local worldX, worldY = camera:screenToWorld(screenX, screenY)
        
        TestFramework.utils.assertEqual(originalWorldX, worldX, "Round trip transformation should preserve X")
        TestFramework.utils.assertEqual(originalWorldY, worldY, "Round trip transformation should preserve Y")
    end,
    
    -- Test bounds
    ["camera bounds setting"] = function()
        local camera = Camera:new()
        
        camera:setBounds(0, 0, 1000, 1000)
        
        TestFramework.utils.assertNotNil(camera.bounds, "Camera bounds should be set")
        TestFramework.utils.assertEqual(0, camera.bounds.minX, "Camera bounds minX should be correct")
        TestFramework.utils.assertEqual(0, camera.bounds.minY, "Camera bounds minY should be correct")
        TestFramework.utils.assertEqual(1000, camera.bounds.maxX, "Camera bounds maxX should be correct")
        TestFramework.utils.assertEqual(1000, camera.bounds.maxY, "Camera bounds maxY should be correct")
    end,
    
    ["camera bounds removal"] = function()
        local camera = Camera:new()
        camera:setBounds(0, 0, 1000, 1000)
        
        camera:removeBounds()
        
        TestFramework.utils.assertNil(camera.bounds, "Camera bounds should be removed")
    end,
    
    -- Test resize
    ["camera resize"] = function()
        local camera = Camera:new()
        
        camera:resize(1024, 768)
        
        TestFramework.utils.assertEqual(1024, camera.screenWidth, "Camera screen width should be updated")
        TestFramework.utils.assertEqual(768, camera.screenHeight, "Camera screen height should be updated")
    end,
    
    -- Test visible area
    ["camera visible area"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        
        local x1, y1, x2, y2 = camera:getVisibleArea()
        
        TestFramework.utils.assertEqual(100, x1, "Visible area x1 should be correct")
        TestFramework.utils.assertEqual(200, y1, "Visible area y1 should be correct")
        TestFramework.utils.assertEqual(500, x2, "Visible area x2 should be correct")
        TestFramework.utils.assertEqual(500, y2, "Visible area y2 should be correct")
    end,
    
    -- Test smooth following over time
    ["camera smooth following"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200}
        
        -- Follow for multiple frames
        for i = 1, 10 do
            camera:follow(target, 0.1)
        end
        
        -- Camera should be close to target after multiple frames
        local distance = math.sqrt((camera.x - 100)^2 + (camera.y - 200)^2)
        TestFramework.utils.assertTrue(distance < 50, "Camera should smoothly approach target")
    end,
    
    -- Test camera with different smooth speeds
    ["camera smooth speed variation"] = function()
        local camera1 = Camera:new()
        local camera2 = Camera:new()
        camera2.smoothSpeed = 16 -- Faster
        
        local target = {x = 100, y = 200}
        
        camera1:follow(target, 0.1)
        camera2:follow(target, 0.1)
        
        -- Faster camera should move more
        local distance1 = math.sqrt((camera1.x - 100)^2 + (camera1.y - 200)^2)
        local distance2 = math.sqrt((camera2.x - 100)^2 + (camera2.y - 200)^2)
        
        TestFramework.utils.assertTrue(distance2 > distance1, "Faster camera should move more per frame")
    end,
    
    -- Test camera with different look-ahead factors
    ["camera look ahead factor"] = function()
        local camera1 = Camera:new()
        local camera2 = Camera:new()
        camera2.lookAheadFactor = 0.3 -- More look-ahead
        
        local target = {x = 100, y = 200, vx = 50, vy = 30}
        
        camera1:follow(target, 0.1)
        camera2:follow(target, 0.1)
        
        -- Camera with more look-ahead should be further ahead
        local distance1 = math.sqrt((camera1.x - 100)^2 + (camera1.y - 200)^2)
        local distance2 = math.sqrt((camera2.x - 100)^2 + (camera2.y - 200)^2)
        
        TestFramework.utils.assertTrue(distance2 > distance1, "Camera with more look-ahead should be further ahead")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Camera System Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = require("tests.test_coverage")
    TestCoverage.updateModule("camera", 6) -- All major functions tested
    
    return success
end

return {run = run} 