-- Tests for Utils Module
package.path = package.path .. ";../../?.lua"

local TestFramework = Utils.Utils.require("tests.test_framework")
local Mocks = Utils.Utils.require("tests.mocks")
local Utils = Utils.Utils.require("src.utils.utils")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Test math utilities
    ["distance calculation"] = function()
        local dist, dx, dy = Utils.distance(0, 0, 3, 4)
        TestFramework.utils.assertEqual(5, dist, "Distance should be calculated correctly")
        TestFramework.utils.assertEqual(3, dx, "DX should be calculated correctly")
        TestFramework.utils.assertEqual(4, dy, "DY should be calculated correctly")
        
        local dist2, dx2, dy2 = Utils.distance(-1, -1, 2, 3)
        TestFramework.utils.assertEqual(5, dist2, "Distance with negative coordinates should be correct")
        TestFramework.utils.assertEqual(3, dx2, "DX with negative coordinates should be correct")
        TestFramework.utils.assertEqual(4, dy2, "DY with negative coordinates should be correct")
    end,
    
    ["vector normalization"] = function()
        local nx, ny = Utils.normalize(3, 4)
        TestFramework.utils.assertEqual(0.6, nx, "Normalized x should be correct")
        TestFramework.utils.assertEqual(0.8, ny, "Normalized y should be correct")
        
        -- Test magnitude
        local mag = math.sqrt(nx*nx + ny*ny)
        TestFramework.utils.assertEqual(1.0, mag, "Normalized vector should have magnitude 1")
        
        -- Test zero vector
        local zx, zy = Utils.normalize(0, 0)
        TestFramework.utils.assertEqual(0, zx, "Zero vector should return 0 for x")
        TestFramework.utils.assertEqual(0, zy, "Zero vector should return 0 for y")
    end,
    
    ["value clamping"] = function()
        TestFramework.utils.assertEqual(5, Utils.clamp(5, 0, 10), "Value within range should be unchanged")
        TestFramework.utils.assertEqual(0, Utils.clamp(-5, 0, 10), "Value below range should be clamped to min")
        TestFramework.utils.assertEqual(10, Utils.clamp(15, 0, 10), "Value above range should be clamped to max")
        TestFramework.utils.assertEqual(0, Utils.clamp(0, 0, 10), "Value at min should be unchanged")
        TestFramework.utils.assertEqual(10, Utils.clamp(10, 0, 10), "Value at max should be unchanged")
    end,
    
    ["linear interpolation"] = function()
        TestFramework.utils.assertEqual(5, Utils.lerp(0, 10, 0.5), "Lerp at 0.5 should be midpoint")
        TestFramework.utils.assertEqual(0, Utils.lerp(0, 10, 0), "Lerp at 0 should be start value")
        TestFramework.utils.assertEqual(10, Utils.lerp(0, 10, 1), "Lerp at 1 should be end value")
        TestFramework.utils.assertEqual(2.5, Utils.lerp(0, 10, 0.25), "Lerp at 0.25 should be quarter")
    end,
    
    ["angle calculation"] = function()
        local angle = Utils.angleBetween(0, 0, 1, 0)
        TestFramework.utils.assertEqual(0, angle, "Angle to right should be 0")
        
        local angle2 = Utils.angleBetween(0, 0, 0, 1)
        TestFramework.utils.assertEqual(math.pi/2, angle2, "Angle to up should be π/2")
        
        local angle3 = Utils.angleBetween(0, 0, -1, 0)
        TestFramework.utils.assertEqual(math.pi, angle3, "Angle to left should be π")
        
        local angle4 = Utils.angleBetween(0, 0, 0, -1)
        TestFramework.utils.assertEqual(-math.pi/2, angle4, "Angle to down should be -π/2")
    end,
    
    ["point rotation"] = function()
        local x, y = Utils.rotatePoint(1, 0, 0, 0, math.pi/2)
        TestFramework.utils.assertTrue(math.abs(x) < 0.001, "Rotated point x should be ~0")
        TestFramework.utils.assertTrue(math.abs(y - 1) < 0.001, "Rotated point y should be ~1")
        
        local x2, y2 = Utils.rotatePoint(1, 0, 0, 0, math.pi)
        TestFramework.utils.assertTrue(math.abs(x2 - (-1)) < 0.001, "Rotated point x should be ~-1")
        TestFramework.utils.assertTrue(math.abs(y2) < 0.001, "Rotated point y should be ~0")
    end,
    
    -- Test vector utilities
    ["vector length"] = function()
        TestFramework.utils.assertEqual(5, Utils.vectorLength(3, 4), "Vector length should be calculated correctly")
        TestFramework.utils.assertEqual(0, Utils.vectorLength(0, 0), "Zero vector should have length 0")
        TestFramework.utils.assertEqual(1, Utils.vectorLength(1, 0), "Unit vector should have length 1")
    end,
    
    ["vector scaling"] = function()
        local sx, sy = Utils.vectorScale(3, 4, 2)
        TestFramework.utils.assertEqual(6, sx, "Scaled x should be correct")
        TestFramework.utils.assertEqual(8, sy, "Scaled y should be correct")
        
        local sx2, sy2 = Utils.vectorScale(3, 4, 0.5)
        TestFramework.utils.assertEqual(1.5, sx2, "Scaled x should be correct")
        TestFramework.utils.assertEqual(2, sy2, "Scaled y should be correct")
    end,
    
    ["vector addition"] = function()
        local ax, ay = Utils.vectorAdd(1, 2, 3, 4)
        TestFramework.utils.assertEqual(4, ax, "Added x should be correct")
        TestFramework.utils.assertEqual(6, ay, "Added y should be correct")
    end,
    
    ["vector subtraction"] = function()
        local sx, sy = Utils.vectorSubtract(5, 6, 2, 3)
        TestFramework.utils.assertEqual(3, sx, "Subtracted x should be correct")
        TestFramework.utils.assertEqual(3, sy, "Subtracted y should be correct")
    end,
    
    ["random float generation"] = function()
        local value = Utils.randomFloat(0, 1)
        TestFramework.utils.assertTrue(value >= 0 and value <= 1, "Random float should be in range")
        
        local value2 = Utils.randomFloat(-5, 5)
        TestFramework.utils.assertTrue(value2 >= -5 and value2 <= 5, "Random float should be in range")
    end,
    
    -- Test collision detection
    ["circle collision detection"] = function()
        -- Circles touching
        TestFramework.utils.assertTrue(Utils.circleCollision(0, 0, 5, 10, 0, 5), "Touching circles should collide")
        
        -- Circles overlapping
        TestFramework.utils.assertTrue(Utils.circleCollision(0, 0, 5, 5, 0, 5), "Overlapping circles should collide")
        
        -- Circles not touching
        TestFramework.utils.assertFalse(Utils.circleCollision(0, 0, 5, 20, 0, 5), "Separate circles should not collide")
        
        -- Same position
        TestFramework.utils.assertTrue(Utils.circleCollision(0, 0, 5, 0, 0, 5), "Same position circles should collide")
    end,
    
    ["ring collision detection"] = function()
        -- Player in ring (between inner and outer radius)
        TestFramework.utils.assertTrue(Utils.ringCollision(120, 100, 5, 100, 100, 30, 15), "Player in ring should collide")
        
        -- Player outside ring
        TestFramework.utils.assertFalse(Utils.ringCollision(200, 100, 5, 100, 100, 30, 15), "Player outside ring should not collide")
        
        -- Player in center hole
        TestFramework.utils.assertFalse(Utils.ringCollision(100, 100, 5, 100, 100, 30, 15), "Player in center hole should not collide")
        
        -- Player touching inner edge
        TestFramework.utils.assertTrue(Utils.ringCollision(115, 100, 5, 100, 100, 30, 15), "Player touching inner edge should collide")
    end,
    
    -- Test particle system
    ["particle update"] = function()
        local particle = {
            x = 100,
            y = 100,
            vx = 10,
            vy = -10,
            lifetime = 1.0
        }
        
        local alive = Utils.updateParticle(particle, 0.1, 100)
        
        TestFramework.utils.assertTrue(alive, "Particle should still be alive")
        TestFramework.utils.assertEqual(101, particle.x, "Particle x should be updated")
        TestFramework.utils.assertEqual(99, particle.y, "Particle y should be updated")
        TestFramework.utils.assertEqual(0.9, particle.lifetime, "Particle lifetime should be updated")
        TestFramework.utils.assertEqual(0, particle.vy, "Particle velocity should be affected by gravity")
    end,
    
    ["particle death"] = function()
        local particle = {
            x = 100,
            y = 100,
            vx = 10,
            vy = -10,
            lifetime = 0.1
        }
        
        local alive = Utils.updateParticle(particle, 0.2, 100)
        
        TestFramework.utils.assertFalse(alive, "Particle should be dead")
        TestFramework.utils.assertTrue(particle.lifetime <= 0, "Particle lifetime should be <= 0")
    end,
    
    -- Test string utilities
    ["number formatting"] = function()
        TestFramework.utils.assertEqual("100", Utils.formatNumber(100), "Small number should be unchanged")
        TestFramework.utils.assertEqual("1.5K", Utils.formatNumber(1500), "Thousands should be formatted with K")
        TestFramework.utils.assertEqual("1.2M", Utils.formatNumber(1200000), "Millions should be formatted with M")
        TestFramework.utils.assertEqual("1.0M", Utils.formatNumber(1000000), "Exact million should be formatted correctly")
    end,
    
    ["time formatting"] = function()
        TestFramework.utils.assertEqual("00:30", Utils.formatTime(30), "30 seconds should format correctly")
        TestFramework.utils.assertEqual("01:00", Utils.formatTime(60), "1 minute should format correctly")
        TestFramework.utils.assertEqual("02:30", Utils.formatTime(150), "2 minutes 30 seconds should format correctly")
        TestFramework.utils.assertEqual("10:45", Utils.formatTime(645), "10 minutes 45 seconds should format correctly")
    end,
    
    -- Test table utilities
    ["deep copy"] = function()
        local original = {
            a = 1,
            b = {c = 2, d = 3},
            e = {f = {g = 4}}
        }
        
        local copy = Utils.deepCopy(original)
        
        TestFramework.utils.assertEqual(original.a, copy.a, "Simple value should be copied")
        TestFramework.utils.assertEqual(original.b.c, copy.b.c, "Nested value should be copied")
        TestFramework.utils.assertEqual(original.e.f.g, copy.e.f.g, "Deep nested value should be copied")
        
        -- Modify copy and ensure original is unchanged
        copy.b.c = 999
        TestFramework.utils.assertEqual(2, original.b.c, "Original should be unchanged")
        TestFramework.utils.assertEqual(999, copy.b.c, "Copy should be modified")
    end,
    
    ["table merging"] = function()
        local t1 = {a = 1, b = 2}
        local t2 = {b = 3, c = 4}
        
        local merged = Utils.mergeTables(t1, t2)
        
        TestFramework.utils.assertEqual(1, merged.a, "First table values should be preserved")
        TestFramework.utils.assertEqual(3, merged.b, "Second table should override")
        TestFramework.utils.assertEqual(4, merged.c, "Second table values should be added")
    end,
    
    -- Test color utilities
    ["color setting"] = function()
        -- Mock love.graphics.setColor to track calls
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        Utils.setColor({0.5, 0.7, 0.9}, 0.8)
        
        TestFramework.utils.assertEqual(1, #setColorCalls, "setColor should be called once")
        TestFramework.utils.assertEqual(0.5, setColorCalls[1][1], "Red component should be set")
        TestFramework.utils.assertEqual(0.7, setColorCalls[1][2], "Green component should be set")
        TestFramework.utils.assertEqual(0.9, setColorCalls[1][3], "Blue component should be set")
        TestFramework.utils.assertEqual(0.8, setColorCalls[1][4], "Alpha component should be set")
    end,
    
    ["color setting without alpha"] = function()
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        Utils.setColor({0.5, 0.7, 0.9, 1.0})
        
        TestFramework.utils.assertEqual(1, #setColorCalls, "setColor should be called once")
        TestFramework.utils.assertEqual(1.0, setColorCalls[1][4], "Default alpha should be 1.0")
    end,
    
    -- Test drawing utilities
    ["circle drawing"] = function()
        local drawCalls = {}
        love.graphics.circle = function(mode, x, y, radius)
            table.insert(drawCalls, {mode, x, y, radius})
        end
        
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        Utils.drawCircle(100, 200, 50, {1, 0, 0}, 0.8)
        
        TestFramework.utils.assertEqual(1, #setColorCalls, "setColor should be called")
        TestFramework.utils.assertEqual(1, #drawCalls, "circle should be drawn")
        TestFramework.utils.assertEqual("fill", drawCalls[1][1], "Circle should be filled")
        TestFramework.utils.assertEqual(100, drawCalls[1][2], "Circle x should be correct")
        TestFramework.utils.assertEqual(200, drawCalls[1][3], "Circle y should be correct")
        TestFramework.utils.assertEqual(50, drawCalls[1][4], "Circle radius should be correct")
    end,
    
    ["ring drawing"] = function()
        local arcCalls = {}
        love.graphics.arc = function(mode, drawMode, x, y, radius, startAngle, endAngle)
            table.insert(arcCalls, {mode, drawMode, x, y, radius, startAngle, endAngle})
        end
        
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        Utils.drawRing(100, 200, 50, 25, {1, 0, 0}, 0.8, 8)
        
        TestFramework.utils.assertEqual(1, #setColorCalls, "setColor should be called")
        TestFramework.utils.assertTrue(#arcCalls > 0, "Arcs should be drawn")
    end,
    
    -- Test object pool
    ["object pool creation"] = function()
        local createCount = 0
        local resetCount = 0
        
        local createFunc = function()
            createCount = createCount + 1
            return {id = createCount, value = 0}
        end
        
        local resetFunc = function(obj)
            resetCount = resetCount + 1
            obj.value = 0
        end
        
        local pool = Utils.ObjectPool.new(createFunc, resetFunc)
        
        TestFramework.utils.assertNotNil(pool, "Pool should be created")
        TestFramework.utils.assertNotNil(pool.get, "Pool should have get method")
        TestFramework.utils.assertNotNil(pool.returnObject, "Pool should have returnObject method")
    end,
    
    ["object pool usage"] = function()
        local createCount = 0
        local resetCount = 0
        
        local createFunc = function()
            createCount = createCount + 1
            return {id = createCount, value = 0}
        end
        
        local resetFunc = function(obj)
            resetCount = resetCount + 1
            obj.value = 0
        end
        
        local pool = Utils.ObjectPool.new(createFunc, resetFunc)
        
        -- Get object
        local obj1 = pool:get()
        TestFramework.utils.assertEqual(1, createCount, "Object should be created")
        TestFramework.utils.assertNotNil(obj1, "Object should be returned")
        
        -- Get another object
        local obj2 = pool:get()
        TestFramework.utils.assertEqual(2, createCount, "Second object should be created")
        
        -- Return object
        pool:returnObject(obj1)
        TestFramework.utils.assertEqual(1, resetCount, "Object should be reset")
        
        -- Get object again (should reuse)
        local obj3 = pool:get()
        TestFramework.utils.assertEqual(2, createCount, "Should reuse object from pool")
    end,
    
    -- Test logging system
    ["logging initialization"] = function()
        Utils.Logger.init(Utils.Logger.levels.INFO, "test.log")
        
        TestFramework.utils.assertEqual(Utils.Logger.levels.INFO, Utils.Logger.currentLevel, "Log level should be set")
        TestFramework.utils.assertNotNil(Utils.Logger.logFile, "Log file should be opened")
        
        Utils.Logger.close()
    end,
    
    ["logging levels"] = function()
        Utils.Logger.init(Utils.Logger.levels.WARN)
        
        -- These should not log at WARN level
        Utils.Logger.debug("Debug message")
        Utils.Logger.info("Info message")
        
        -- These should log
        Utils.Logger.warn("Warning message")
        Utils.Logger.error("Error message")
        
        Utils.Logger.close()
    end,
    
    -- Test error handling
    ["safe function call"] = function()
        local success, result = Utils.ErrorHandler.safeCall(function() return "success" end)
        TestFramework.utils.assertTrue(success, "Successful function should return true")
        TestFramework.utils.assertEqual("success", result, "Function result should be returned")
        
        local success2, error = Utils.ErrorHandler.safeCall(function() error("test error") end)
        TestFramework.utils.assertFalse(success2, "Failing function should return false")
        TestFramework.utils.assertNotNil(error, "Error should be returned")
    end,
    
    ["input validation"] = function()
        local valid, error = Utils.ErrorHandler.validateInput(5, "number", "test")
        TestFramework.utils.assertTrue(valid, "Valid input should pass validation")
        TestFramework.utils.assertNil(error, "No error should be returned for valid input")
        
        local valid2, error2 = Utils.ErrorHandler.validateInput("string", "number", "test")
        TestFramework.utils.assertFalse(valid2, "Invalid input should fail validation")
        TestFramework.utils.assertNotNil(error2, "Error should be returned for invalid input")
    end,
    
    -- Test spatial grid
    ["spatial grid creation"] = function()
        local grid = Utils.SpatialGrid.new(100)
        
        TestFramework.utils.assertNotNil(grid, "Grid should be created")
        TestFramework.utils.assertEqual(100, grid.cellSize, "Cell size should be set")
        TestFramework.utils.assertNotNil(grid.cells, "Cells should be initialized")
    end,
    
    ["spatial grid insertion"] = function()
        local grid = Utils.SpatialGrid.new(100)
        
        local obj = {x = 150, y = 250, radius = 10}
        grid:insert(obj)
        
        local nearby = grid:getNearby(150, 250, 50)
        TestFramework.utils.assertTrue(#nearby > 0, "Should find nearby objects")
        TestFramework.utils.assertEqual(obj, nearby[1], "Should find the inserted object")
    end,
    
    ["spatial grid clearing"] = function()
        local grid = Utils.SpatialGrid.new(100)
        
        local obj = {x = 150, y = 250, radius = 10}
        grid:insert(obj)
        
        grid:clear()
        
        local nearby = grid:getNearby(150, 250, 50)
        TestFramework.utils.assertEqual(0, #nearby, "Should not find objects after clearing")
    end
}

-- Run the test suite
local function run()
    local success = TestFramework.runSuite("Utils Tests", tests)
    
    -- Update coverage tracking
    local TestCoverage = Utils.Utils.require("tests.test_coverage")
    TestCoverage.updateModule("utils", 25) -- All major functions tested
    
    return success
end

return {run = run} 