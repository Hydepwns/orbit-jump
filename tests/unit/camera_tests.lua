-- Modern Camera Tests
-- Tests for camera system

local Utils = require("src.utils.utils")
local ModernTestFramework = Utils.require("tests.modern_test_framework")
local Camera = Utils.require("src.core.camera")

local tests = {
    -- Camera initialization
    ["should initialize camera with default values"] = function()
        local camera = Camera:new()
        
        ModernTestFramework.assert.equal(0, camera.x, "Camera should start at x=0")
        ModernTestFramework.assert.equal(0, camera.y, "Camera should start at y=0")
        ModernTestFramework.assert.equal(1, camera.scale, "Camera should start at scale=1")
        ModernTestFramework.assert.equal(0, camera.rotation, "Camera should start at rotation=0")
        ModernTestFramework.assert.equal(8, camera.smoothSpeed, "Camera should have default smooth speed")
        ModernTestFramework.assert.equal(0.15, camera.lookAheadFactor, "Camera should have default look ahead factor")
        ModernTestFramework.assert.equal(0, camera.shakeIntensity, "Camera should start with no shake")
        ModernTestFramework.assert.equal(0, camera.shakeDuration, "Camera should start with no shake duration")
        ModernTestFramework.assert.isTrue(camera.enableShake, "Camera should have shake enabled by default")
        ModernTestFramework.assert.isNil(camera.bounds, "Camera should start with no bounds")
    end,
    
    ["should capture screen dimensions"] = function()
        local camera = Camera:new()
        
        -- Initialize dimensions manually for testing
        camera:initDimensions()
        
        -- In test environment, dimensions default to 800x600
        ModernTestFramework.assert.equal(800, camera.screenWidth, "Camera should capture screen width")
        ModernTestFramework.assert.equal(600, camera.screenHeight, "Camera should capture screen height")
    end,
    
    -- Camera following
    ["should follow stationary target"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200}
        
        camera:follow(target, 0.1)
        
        -- Camera should move toward target (negative because it translates negatively)
        ModernTestFramework.assert.isTrue(camera.x < 0, "Camera should move toward target x")
        ModernTestFramework.assert.isTrue(camera.y < 0, "Camera should move toward target y")
    end,
    
    ["should follow moving target with look-ahead"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200, vx = 50, vy = 30}
        
        camera:follow(target, 0.1)
        
        -- Camera should move toward target with look-ahead
        ModernTestFramework.assert.isTrue(camera.x < 0, "Camera should move toward target with look-ahead")
        ModernTestFramework.assert.isTrue(camera.y < 0, "Camera should move toward target with look-ahead")
    end,
    
    ["should respect bounds when following"] = function()
        local camera = Camera:new()
        camera:setBounds(0, 0, 1000, 1000)
        local target = {x = 2000, y = 2000} -- Outside bounds
        
        camera:follow(target, 0.1)
        
        ModernTestFramework.assert.isTrue(camera.x <= 1000 - camera.screenWidth / camera.scale, "Camera should respect max X bound")
        ModernTestFramework.assert.isTrue(camera.y <= 1000 - camera.screenHeight / camera.scale, "Camera should respect max Y bound")
        ModernTestFramework.assert.isTrue(camera.x >= 0, "Camera should respect min X bound")
        ModernTestFramework.assert.isTrue(camera.y >= 0, "Camera should respect min Y bound")
    end,
    
    ["should not move with nil target"] = function()
        local camera = Camera:new()
        local originalX = camera.x
        local originalY = camera.y
        
        camera:follow(nil, 0.1)
        
        ModernTestFramework.assert.equal(originalX, camera.x, "Camera should not move with nil target")
        ModernTestFramework.assert.equal(originalY, camera.y, "Camera should not move with nil target")
    end,
    
    -- Camera shake
    ["should activate shake"] = function()
        local camera = Camera:new()
        
        camera:shake(10, 1.0)
        
        ModernTestFramework.assert.equal(10, camera.shakeIntensity, "Camera should have shake intensity set")
        ModernTestFramework.assert.equal(1.0, camera.shakeDuration, "Camera should have shake duration set")
    end,
    
    ["should not shake when disabled"] = function()
        local camera = Camera:new()
        camera.enableShake = false
        
        camera:shake(10, 1.0)
        
        ModernTestFramework.assert.equal(0, camera.shakeIntensity, "Camera should not set shake intensity when disabled")
        ModernTestFramework.assert.equal(0, camera.shakeDuration, "Camera should not set shake duration when disabled")
    end,
    
    ["should expire shake over time"] = function()
        local camera = Camera:new()
        camera:shake(10, 1.0)
        
        camera:follow({x = 0, y = 0}, 1.5) -- More than shake duration
        
        ModernTestFramework.assert.equal(0, camera.shakeIntensity, "Camera shake should expire")
        ModernTestFramework.assert.equal(0, camera.shakeDuration, "Camera shake duration should expire")
    end,
    
    -- Camera bounds
    ["should set bounds correctly"] = function()
        local camera = Camera:new()
        
        camera:setBounds(0, 0, 1000, 1000)
        
        ModernTestFramework.assert.notNil(camera.bounds, "Camera should have bounds set")
        ModernTestFramework.assert.equal(0, camera.bounds.minX, "Should set min X bound")
        ModernTestFramework.assert.equal(0, camera.bounds.minY, "Should set min Y bound")
        ModernTestFramework.assert.equal(1000, camera.bounds.maxX, "Should set max X bound")
        ModernTestFramework.assert.equal(1000, camera.bounds.maxY, "Should set max Y bound")
    end,
    
    ["should clear bounds"] = function()
        local camera = Camera:new()
        camera:setBounds(0, 0, 1000, 1000)
        
        camera:removeBounds()
        
        ModernTestFramework.assert.isNil(camera.bounds, "Camera should have no bounds after clear")
    end,
    
    -- Camera transformation
    ["should apply transformation"] = function()
        local camera = Camera:new()
        camera.x = 100
        camera.y = 200
        camera.scale = 2.0
        camera.rotation = math.pi/4
        
        -- Initialize dimensions for transformation
        camera:initDimensions()
        
        ModernTestFramework.utils.resetCalls()
        
        camera:apply()
        
        ModernTestFramework.assert.calledAtLeast("push", 1, "Should push graphics state")
        ModernTestFramework.assert.calledAtLeast("translate", 1, "Should translate for camera position")
        ModernTestFramework.assert.calledAtLeast("scale", 1, "Should scale for camera zoom")
        ModernTestFramework.assert.calledAtLeast("rotate", 1, "Should rotate for camera rotation")
    end,
    
    ["should clear transformation"] = function()
        local camera = Camera:new()
        
        ModernTestFramework.utils.resetCalls()
        
        camera:clear()
        
        ModernTestFramework.assert.calledAtLeast("pop", 1, "Should pop graphics state")
    end,
    
    -- Camera smooth following
    ["should smoothly approach target"] = function()
        local camera = Camera:new()
        local target = {x = 100, y = 200}
        
        camera:follow(target, 0.1)
        local firstX, firstY = camera.x, camera.y
        
        camera:follow(target, 0.1)
        local secondX, secondY = camera.x, camera.y
        
        ModernTestFramework.assert.isTrue(secondX < firstX, "Camera should smoothly approach target")
        ModernTestFramework.assert.isTrue(secondY < firstY, "Camera should smoothly approach target")
    end,
    
    -- Camera look ahead factor
    ["should apply look ahead factor"] = function()
        local camera1 = Camera:new()
        camera1.lookAheadFactor = 0.1
        local camera2 = Camera:new()
        camera2.lookAheadFactor = 0.3
        
        local target = {x = 100, y = 200, vx = 50, vy = 30}
        
        camera1:follow(target, 0.1)
        camera2:follow(target, 0.1)
        
        -- Both cameras should move toward the target (negative positions)
        ModernTestFramework.assert.isTrue(camera1.x < 0, "Camera should move toward target")
        ModernTestFramework.assert.isTrue(camera1.y < 0, "Camera should move toward target")
        ModernTestFramework.assert.isTrue(camera2.x < 0, "Camera should move toward target")
        ModernTestFramework.assert.isTrue(camera2.y < 0, "Camera should move toward target")
    end,
    
    -- Camera scale
    ["should handle different scales"] = function()
        local camera = Camera:new()
        camera.scale = 2.0
        
        ModernTestFramework.assert.equal(2.0, camera.scale, "Camera should have correct scale")
        
        camera:setBounds(0, 0, 1000, 1000)
        local target = {x = 2000, y = 2000}
        camera:follow(target, 0.1)
        
        -- Should respect bounds with scale
        ModernTestFramework.assert.isTrue(camera.x <= 1000 - camera.screenWidth / camera.scale, "Should respect bounds with scale")
    end,
    
    -- Camera rotation
    ["should handle rotation"] = function()
        local camera = Camera:new()
        camera.rotation = math.pi/2
        
        ModernTestFramework.assert.approx(math.pi/2, camera.rotation, 0.001, "Camera should have correct rotation")
    end,
    
    -- Edge cases
    ["should handle zero smooth speed"] = function()
        local camera = Camera:new()
        camera.smoothSpeed = 0
        local target = {x = 100, y = 200}
        
        camera:follow(target, 0.1)
        
        ModernTestFramework.assert.equal(0, camera.x, "Camera should not move with zero smooth speed")
        ModernTestFramework.assert.equal(0, camera.y, "Camera should not move with zero smooth speed")
    end,
    
    ["should handle negative shake intensity"] = function()
        local camera = Camera:new()
        
        camera:shake(-10, 1.0)
        
        ModernTestFramework.assert.equal(-10, camera.shakeIntensity, "Should allow negative shake intensity")
    end,
    
    ["should handle zero shake duration"] = function()
        local camera = Camera:new()
        
        camera:shake(10, 0)
        
        ModernTestFramework.assert.equal(10, camera.shakeIntensity, "Should still set intensity even with zero duration")
    end
}

return tests 