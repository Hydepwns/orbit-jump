-- Test file for Utils Module
local Utils = require("src.utils.utils")
local TestFramework = require("tests.modern_test_framework")
local Mocks = require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Ensure love.graphics exists for graphics tests
if not love then love = {} end
if not love.graphics then love.graphics = {} end

-- Store original love.graphics functions
local originalSetColor = love.graphics.setColor
local originalCircle = love.graphics.circle
local originalRectangle = love.graphics.rectangle
local originalArc = love.graphics.arc
local originalPrint = love.graphics.print

-- Initialize test framework
TestFramework.init()

-- Test suite
local tests = {
    -- Module cache tests
    ["test module cache functionality"] = function()
        -- Clear cache first
        Utils.clearModuleCache()
        
        -- First require should load module
        local config1 = Utils.require("src.utils.config")
        TestFramework.assert.notNil(config1, "Should load module")
        
        -- Second require should return cached version
        local config2 = Utils.require("src.utils.config")
        TestFramework.assert.equal(config1, config2, "Should return cached module")
        
        -- Clear cache and require again
        Utils.clearModuleCache()
        local config3 = Utils.require("src.utils.config")
        TestFramework.assert.notNil(config3, "Should reload module after cache clear")
    end,
    
    -- Math utilities tests
    ["test distance calculation"] = function()
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
        local dist, dx, dy = FreshUtils.distance(0, 0, 3, 4)
        TestFramework.assert.equal(5, dist, "Distance should be 5")
        TestFramework.assert.equal(3, dx, "DX should be 3")
        TestFramework.assert.equal(4, dy, "DY should be 4")
        
        -- Test with negative coordinates
        local dist2, dx2, dy2 = FreshUtils.distance(-1, -1, 2, 3)
        TestFramework.assert.equal(5, dist2, "Distance with negative coords should be 5")
        TestFramework.assert.equal(3, dx2, "DX with negative coords should be 3")
        TestFramework.assert.equal(4, dy2, "DY with negative coords should be 4")
        
        -- Test with nil inputs
        local dist3, dx3, dy3 = FreshUtils.distance(nil, nil, 1, 1)
        TestFramework.assert.equal(0, dist3, "Distance with nil should be 0")
        TestFramework.assert.equal(0, dx3, "DX with nil should be 0")
        TestFramework.assert.equal(0, dy3, "DY with nil should be 0")
    end,
    
    ["test vector normalization"] = function()
        local nx, ny = Utils.normalize(3, 4)
        TestFramework.assert.equal(0.6, nx, "Normalized x should be 0.6")
        TestFramework.assert.equal(0.8, ny, "Normalized y should be 0.8")
        
        -- Test magnitude
        local mag = math.sqrt(nx*nx + ny*ny)
        TestFramework.assert.approx(1.0, mag, 0.001, "Normalized vector magnitude should be 1")
        
        -- Test zero vector
        local zx, zy = Utils.normalize(0, 0)
        TestFramework.assert.equal(0, zx, "Zero vector x should be 0")
        TestFramework.assert.equal(0, zy, "Zero vector y should be 0")
        
        -- Test nil inputs
        local nx2, ny2 = Utils.normalize(nil, nil)
        TestFramework.assert.equal(0, nx2, "Nil input x should be 0")
        TestFramework.assert.equal(0, ny2, "Nil input y should be 0")
    end,
    
    ["test value clamping"] = function()
        TestFramework.assert.equal(5, Utils.clamp(5, 0, 10), "Value within range")
        TestFramework.assert.equal(0, Utils.clamp(-5, 0, 10), "Value below range")
        TestFramework.assert.equal(10, Utils.clamp(15, 0, 10), "Value above range")
        TestFramework.assert.equal(0, Utils.clamp(0, 0, 10), "Value at min")
        TestFramework.assert.equal(10, Utils.clamp(10, 0, 10), "Value at max")
    end,
    
    ["test linear interpolation"] = function()
        TestFramework.assert.equal(5, Utils.lerp(0, 10, 0.5), "Lerp at 0.5")
        TestFramework.assert.equal(0, Utils.lerp(0, 10, 0), "Lerp at 0")
        TestFramework.assert.equal(10, Utils.lerp(0, 10, 1), "Lerp at 1")
        TestFramework.assert.equal(2.5, Utils.lerp(0, 10, 0.25), "Lerp at 0.25")
        TestFramework.assert.equal(7.5, Utils.lerp(0, 10, 0.75), "Lerp at 0.75")
    end,
    
    ["test angle calculation"] = function()
        local angle = Utils.angleBetween(0, 0, 1, 0)
        TestFramework.assert.approx(0, angle, 0.001, "Angle to right should be 0")
        
        local angle2 = Utils.angleBetween(0, 0, 0, 1)
        TestFramework.assert.approx(math.pi/2, angle2, 0.001, "Angle up should be π/2")
        
        local angle3 = Utils.angleBetween(0, 0, -1, 0)
        TestFramework.assert.approx(math.pi, math.abs(angle3), 0.001, "Angle to left should be ±π")
        
        local angle4 = Utils.angleBetween(0, 0, 0, -1)
        TestFramework.assert.approx(-math.pi/2, angle4, 0.001, "Angle down should be -π/2")
    end,
    
    ["test point rotation"] = function()
        local x, y = Utils.rotatePoint(1, 0, 0, 0, math.pi/2)
        TestFramework.assert.approx(0, x, 0.001, "Rotated x should be ~0")
        TestFramework.assert.approx(1, y, 0.001, "Rotated y should be ~1")
        
        local x2, y2 = Utils.rotatePoint(1, 0, 0, 0, math.pi)
        TestFramework.assert.approx(-1, x2, 0.001, "Rotated x should be ~-1")
        TestFramework.assert.approx(0, y2, 0.001, "Rotated y should be ~0")
        
        local x3, y3 = Utils.rotatePoint(1, 0, 0, 0, -math.pi/2)
        TestFramework.assert.approx(0, x3, 0.001, "Rotated x should be ~0")
        TestFramework.assert.approx(-1, y3, 0.001, "Rotated y should be ~-1")
    end,
    
    -- Vector utilities tests
    ["test vector length"] = function()
        TestFramework.assert.equal(5, Utils.vectorLength(3, 4), "Vector length 3,4")
        TestFramework.assert.equal(0, Utils.vectorLength(0, 0), "Zero vector length")
        TestFramework.assert.equal(1, Utils.vectorLength(1, 0), "Unit vector length")
        TestFramework.assert.equal(1, Utils.vectorLength(0, 1), "Unit vector length")
        TestFramework.assert.equal(0, Utils.vectorLength(nil, nil), "Nil vector length")
    end,
    
    ["test vector scaling"] = function()
        local sx, sy = Utils.vectorScale(3, 4, 2)
        TestFramework.assert.equal(6, sx, "Scaled x by 2")
        TestFramework.assert.equal(8, sy, "Scaled y by 2")
        
        local sx2, sy2 = Utils.vectorScale(3, 4, 0.5)
        TestFramework.assert.equal(1.5, sx2, "Scaled x by 0.5")
        TestFramework.assert.equal(2, sy2, "Scaled y by 0.5")
        
        local sx3, sy3 = Utils.vectorScale(nil, nil, 2)
        TestFramework.assert.equal(0, sx3, "Nil vector scaled x")
        TestFramework.assert.equal(0, sy3, "Nil vector scaled y")
    end,
    
    ["test vector addition"] = function()
        local ax, ay = Utils.vectorAdd(1, 2, 3, 4)
        TestFramework.assert.equal(4, ax, "Added x")
        TestFramework.assert.equal(6, ay, "Added y")
        
        local ax2, ay2 = Utils.vectorAdd(-1, -2, 1, 2)
        TestFramework.assert.equal(0, ax2, "Added opposite x")
        TestFramework.assert.equal(0, ay2, "Added opposite y")
    end,
    
    ["test vector subtraction"] = function()
        local sx, sy = Utils.vectorSubtract(5, 6, 2, 3)
        TestFramework.assert.equal(3, sx, "Subtracted x")
        TestFramework.assert.equal(3, sy, "Subtracted y")
        
        local sx2, sy2 = Utils.vectorSubtract(1, 1, 1, 1)
        TestFramework.assert.equal(0, sx2, "Same vector x")
        TestFramework.assert.equal(0, sy2, "Same vector y")
    end,
    
    ["test random float generation"] = function()
        -- Save original math.random
        local originalRandom = math.random
        
        -- Reload Utils to get fresh implementation  
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
        -- Test with different mock values
        math.random = function() return 0 end
        local value1 = FreshUtils.randomFloat(0, 10)
        TestFramework.assert.equal(0, value1, "Min value when random returns 0")
        
        math.random = function() return 1 end
        local value2 = FreshUtils.randomFloat(0, 10)
        TestFramework.assert.equal(10, value2, "Max value when random returns 1")
        
        math.random = function() return 0.5 end
        local value3 = FreshUtils.randomFloat(0, 10)
        TestFramework.assert.equal(5, value3, "Mid value when random returns 0.5")
        
        -- Restore original
        math.random = originalRandom
    end,
    
    -- Math constants tests
    ["test math constants"] = function()
        TestFramework.assert.equal(math.pi, Utils.MATH.PI, "PI constant")
        TestFramework.assert.equal(math.pi * 2, Utils.MATH.TWO_PI, "TWO_PI constant")
        TestFramework.assert.equal(math.pi / 2, Utils.MATH.HALF_PI, "HALF_PI constant")
        TestFramework.assert.approx(math.pi / 180, Utils.MATH.DEG_TO_RAD, 0.00001, "DEG_TO_RAD")
        TestFramework.assert.approx(180 / math.pi, Utils.MATH.RAD_TO_DEG, 0.00001, "RAD_TO_DEG")
    end,
    
    -- Collision detection tests
    ["test circle collision detection"] = function()
        -- Touching circles
        TestFramework.assert.equal(true, Utils.circleCollision(0, 0, 5, 10, 0, 5), "Touching circles")
        
        -- Overlapping circles
        TestFramework.assert.equal(true, Utils.circleCollision(0, 0, 5, 5, 0, 5), "Overlapping circles")
        
        -- Separate circles
        TestFramework.assert.equal(false, Utils.circleCollision(0, 0, 5, 20, 0, 5), "Separate circles")
        
        -- Same position
        TestFramework.assert.equal(true, Utils.circleCollision(0, 0, 5, 0, 0, 5), "Same position")
    end,
    
    ["test ring collision detection"] = function()
        -- Player in ring
        TestFramework.assert.equal(true, Utils.ringCollision(120, 100, 5, 100, 100, 30, 15), "Player in ring")
        
        -- Player outside ring
        TestFramework.assert.equal(false, Utils.ringCollision(200, 100, 5, 100, 100, 30, 15), "Player outside ring")
        
        -- Player in center hole
        TestFramework.assert.equal(false, Utils.ringCollision(100, 100, 5, 100, 100, 30, 15), "Player in hole")
        
        -- Player touching inner edge
        TestFramework.assert.equal(true, Utils.ringCollision(115, 100, 5, 100, 100, 30, 15), "Player at inner edge")
    end,
    
    ["test point in rectangle"] = function()
        -- Point inside
        TestFramework.assert.equal(true, Utils.pointInRect(5, 5, 0, 0, 10, 10), "Point inside rect")
        
        -- Point outside
        TestFramework.assert.equal(false, Utils.pointInRect(15, 15, 0, 0, 10, 10), "Point outside rect")
        
        -- Point on edge
        TestFramework.assert.equal(true, Utils.pointInRect(0, 0, 0, 0, 10, 10), "Point on edge")
        TestFramework.assert.equal(true, Utils.pointInRect(10, 10, 0, 0, 10, 10), "Point on opposite edge")
    end,
    
    -- Particle tests
    ["test particle creation"] = function()
        -- Ensure Utils is properly loaded
        local Utils = require("src.utils.utils")
        
        -- Ensure colors are available
        TestFramework.assert.notNil(Utils.colors, "Colors should exist")
        TestFramework.assert.notNil(Utils.colors.particle, "Particle color should exist")
        
        local particle = Utils.createParticle(100, 200, 10, -20)
        
        TestFramework.assert.equal(100, particle.x, "Particle x")
        TestFramework.assert.equal(200, particle.y, "Particle y")
        TestFramework.assert.equal(10, particle.vx, "Particle vx")
        TestFramework.assert.equal(-20, particle.vy, "Particle vy")
        TestFramework.assert.equal(1.0, particle.lifetime, "Default lifetime")
        TestFramework.assert.equal(3, particle.size, "Default size")
        TestFramework.assert.notNil(particle.color, "Should have color")
    end,
    
    ["test particle update"] = function()
        local particle = {
            x = 100,
            y = 100,
            vx = 10,
            vy = -10,
            lifetime = 1.0
        }
        
        local alive = Utils.updateParticle(particle, 0.1, 100)
        
        TestFramework.assert.equal(true, alive, "Particle should be alive")
        TestFramework.assert.equal(101, particle.x, "Particle x after update")
        TestFramework.assert.equal(99, particle.y, "Particle y after update")
        TestFramework.assert.equal(0.9, particle.lifetime, "Particle lifetime after update")
        TestFramework.assert.equal(0, particle.vy, "Particle vy after gravity")
    end,
    
    ["test particle death"] = function()
        local particle = {
            x = 100,
            y = 100,
            vx = 10,
            vy = -10,
            lifetime = 0.1
        }
        
        local alive = Utils.updateParticle(particle, 0.2, 100)
        
        TestFramework.assert.equal(false, alive, "Particle should be dead")
        TestFramework.assert.equal(-0.1, particle.lifetime, "Particle lifetime should be -0.1")
    end,
    
    -- String utilities tests
    ["test number formatting"] = function()
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
        TestFramework.assert.equal("100", FreshUtils.formatNumber(100), "Small number")
        TestFramework.assert.equal("999", FreshUtils.formatNumber(999), "Just under 1K")
        TestFramework.assert.equal("1.0K", FreshUtils.formatNumber(1000), "Exactly 1K")
        TestFramework.assert.equal("1.5K", FreshUtils.formatNumber(1500), "1.5K")
        TestFramework.assert.equal("999.9K", FreshUtils.formatNumber(999900), "Just under 1M")
        TestFramework.assert.equal("1.0M", FreshUtils.formatNumber(1000000), "Exactly 1M")
        TestFramework.assert.equal("1.2M", FreshUtils.formatNumber(1200000), "1.2M")
    end,
    
    ["test time formatting"] = function()
        TestFramework.assert.equal("00:00", Utils.formatTime(0), "Zero seconds")
        TestFramework.assert.equal("00:30", Utils.formatTime(30), "30 seconds")
        TestFramework.assert.equal("01:00", Utils.formatTime(60), "1 minute")
        TestFramework.assert.equal("02:30", Utils.formatTime(150), "2:30")
        TestFramework.assert.equal("10:45", Utils.formatTime(645), "10:45")
        TestFramework.assert.equal("59:59", Utils.formatTime(3599), "59:59")
    end,
    
    -- Table utilities tests
    ["test deep copy"] = function()
        local original = {
            a = 1,
            b = {c = 2, d = 3},
            e = {f = {g = 4}}
        }
        
        local copy = Utils.deepCopy(original)
        
        TestFramework.assert.equal(original.a, copy.a, "Simple value copied")
        TestFramework.assert.equal(original.b.c, copy.b.c, "Nested value copied")
        TestFramework.assert.equal(original.e.f.g, copy.e.f.g, "Deep nested value copied")
        
        -- Modify copy and ensure original unchanged
        copy.b.c = 999
        TestFramework.assert.equal(2, original.b.c, "Original unchanged")
        TestFramework.assert.equal(999, copy.b.c, "Copy modified")
    end,
    
    ["test table merging"] = function()
        local t1 = {a = 1, b = 2}
        local t2 = {b = 3, c = 4}
        
        local merged = Utils.mergeTables(t1, t2)
        
        TestFramework.assert.equal(1, merged.a, "First table value")
        TestFramework.assert.equal(3, merged.b, "Second table override")
        TestFramework.assert.equal(4, merged.c, "Second table new value")
        
        -- Original tables should be unchanged
        TestFramework.assert.equal(2, t1.b, "Original t1 unchanged")
    end,
    
    -- Color utilities tests
    ["test color setting"] = function()
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
        FreshUtils.setColor({0.5, 0.7, 0.9}, 0.8)
        
        TestFramework.assert.equal(1, #setColorCalls, "setColor called once")
        TestFramework.assert.equal(0.5, setColorCalls[1][1], "Red component")
        TestFramework.assert.equal(0.7, setColorCalls[1][2], "Green component")
        TestFramework.assert.equal(0.9, setColorCalls[1][3], "Blue component")
        TestFramework.assert.equal(0.8, setColorCalls[1][4], "Alpha component")
        
        -- Restore original
        love.graphics.setColor = originalSetColor
    end,
    
    ["test color setting with default alpha"] = function()
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
        FreshUtils.setColor({0.5, 0.7, 0.9})
        
        TestFramework.assert.equal(1, #setColorCalls, "setColor called once")
        TestFramework.assert.equal(1, setColorCalls[1][4], "Default alpha is 1")
        
        -- Test with alpha in color array
        setColorCalls = {}
        FreshUtils.setColor({0.5, 0.7, 0.9, 0.6})
        TestFramework.assert.equal(0.6, setColorCalls[1][4], "Alpha from color array")
        
        -- Restore original
        love.graphics.setColor = originalSetColor
    end,
    
    -- Drawing utilities tests
    ["test circle drawing"] = function()
        local drawCalls = {}
        love.graphics.circle = function(mode, x, y, radius)
            table.insert(drawCalls, {mode, x, y, radius})
        end
        
        local setColorCalls = {}
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
        FreshUtils.drawCircle(100, 200, 50, {1, 0, 0}, 0.8)
        
        TestFramework.assert.equal(1, #setColorCalls, "Color set")
        TestFramework.assert.equal(1, #drawCalls, "Circle drawn")
        TestFramework.assert.equal("fill", drawCalls[1][1], "Fill mode")
        TestFramework.assert.equal(100, drawCalls[1][2], "Circle x")
        TestFramework.assert.equal(200, drawCalls[1][3], "Circle y")
        TestFramework.assert.equal(50, drawCalls[1][4], "Circle radius")
        
        -- Restore originals
        love.graphics.circle = originalCircle
        love.graphics.setColor = originalSetColor
    end,
    
    ["test ring drawing"] = function()
        -- First ensure love.graphics exists
        if not love.graphics then
            love.graphics = {}
        end
        
        local arcCalls = {}
        local originalArc = love.graphics.arc
        love.graphics.arc = function(mode, drawMode, x, y, radius, startAngle, endAngle)
            table.insert(arcCalls, {mode, drawMode, x, y, radius, startAngle, endAngle})
        end
        
        local originalSetColor = love.graphics.setColor
        love.graphics.setColor = function(r, g, b, a) end
        
        Utils.drawRing(100, 200, 50, 25, {1, 0, 0}, 0.8, 8)
        
        -- Should draw 16 arcs (8 segments × 2 radii)
        TestFramework.assert.equal(16, #arcCalls, "16 arcs drawn (8 segments × 2 radii)")
        TestFramework.assert.equal("line", arcCalls[1][1], "Line mode")
        TestFramework.assert.equal("open", arcCalls[1][2], "Open arc")
        
        -- Restore originals
        love.graphics.arc = originalArc
        love.graphics.setColor = originalSetColor
    end,
    
    -- Object pool tests
    ["test object pool creation"] = function()
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
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
        
        local pool = FreshUtils.ObjectPool.new(createFunc, resetFunc)
        
        TestFramework.assert.notNil(pool, "Pool created")
        TestFramework.assert.notNil(pool.get, "Pool has get method")
        TestFramework.assert.notNil(pool.returnObject, "Pool has returnObject method")
    end,
    
    ["test object pool usage"] = function()
        -- Reload Utils to get fresh implementation
        package.loaded["src.utils.utils"] = nil
        local FreshUtils = require("src.utils.utils")
        
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
        
        local pool = FreshUtils.ObjectPool.new(createFunc, resetFunc)
        
        -- Get object
        local obj1 = pool:get()
        TestFramework.assert.equal(1, createCount, "Object created")
        TestFramework.assert.notNil(obj1, "Object returned")
        TestFramework.assert.equal(1, obj1.id, "Object id")
        
        -- Get another object
        local obj2 = pool:get()
        TestFramework.assert.equal(2, createCount, "Second object created")
        TestFramework.assert.equal(2, obj2.id, "Second object id")
        
        -- Return object
        obj1.value = 100
        pool:returnObject(obj1)
        TestFramework.assert.equal(1, resetCount, "Object reset")
        
        -- Get object again (should reuse)
        local obj3 = pool:get()
        TestFramework.assert.equal(2, createCount, "No new object created")
        TestFramework.assert.equal(1, obj3.id, "Reused object id")
        TestFramework.assert.equal(0, obj3.value, "Object was reset")
    end,
    
    -- Logger tests
    ["test logger initialization"] = function()
        -- Mock file operations
        local fileOpened = false
        local originalOpen = io.open
        io.open = function(filename, mode)
            fileOpened = true
            return {
                write = function() end,
                flush = function() end,
                close = function() end
            }
        end
        
        Utils.Logger.init(Utils.Logger.levels.INFO, "test.log")
        
        TestFramework.assert.equal(Utils.Logger.levels.INFO, Utils.Logger.currentLevel, "Log level set")
        TestFramework.assert.equal(true, fileOpened, "Log file opened")
        
        Utils.Logger.close()
        io.open = originalOpen
    end,
    
    ["test logger levels"] = function()
        -- Mock output
        local outputs = {}
        local originalOutput = Utils.Logger.output
        Utils.Logger.output = function(message)
            table.insert(outputs, message)
        end
        
        -- Mock os.date for consistent timestamps
        local originalDate = os.date
        os.date = function(format)
            return "2024-01-01 00:00:00"
        end
        
        Utils.Logger.init(Utils.Logger.levels.WARN)
        
        Utils.Logger.debug("Debug message")
        Utils.Logger.info("Info message")
        Utils.Logger.warn("Warning message")
        Utils.Logger.error("Error message")
        
        TestFramework.assert.equal(2, #outputs, "Only WARN and ERROR logged")
        -- Check full message format
        TestFramework.assert.equal("[2024-01-01 00:00:00] WARN: Warning message", outputs[1], "Warning message")
        TestFramework.assert.equal("[2024-01-01 00:00:00] ERROR: Error message", outputs[2], "Error message")
        
        Utils.Logger.close()
        
        -- Restore originals
        Utils.Logger.output = originalOutput
        os.date = originalDate
    end,
    
    ["test logger formatting"] = function()
        -- Ensure Utils is properly loaded
        local Utils = require("src.utils.utils")
        
        local outputs = {}
        local originalOutput = Utils.Logger.output
        Utils.Logger.output = function(message)
            table.insert(outputs, message)
        end
        
        -- Mock os.date to return consistent timestamp
        local originalDate = os.date
        os.date = function(format)
            return "2025-01-01 12:00:00"
        end
        
        Utils.Logger.init(Utils.Logger.levels.INFO)
        Utils.Logger.info("Test %s %d", "message", 123)
        
        TestFramework.assert.equal(1, #outputs, "Message logged")
        -- The actual log format is: [timestamp] LEVEL: message
        TestFramework.assert.equal("[2025-01-01 12:00:00] INFO: Test message 123", outputs[1], "Full log message")
        
        Utils.Logger.close()
        
        -- Restore originals
        Utils.Logger.output = originalOutput
        os.date = originalDate
    end,
    
    -- Error handler tests
    ["test safe function call success"] = function()
        local success, result = Utils.ErrorHandler.safeCall(function() return "success" end)
        TestFramework.assert.equal(true, success, "Function succeeded")
        TestFramework.assert.equal("success", result, "Result returned")
    end,
    
    ["test safe function call failure"] = function()
        local outputs = {}
        local originalOutput = Utils.Logger.output
        Utils.Logger.output = function(message)
            table.insert(outputs, message)
        end
        
        -- Initialize logger to ensure error level is enabled
        Utils.Logger.init(Utils.Logger.levels.DEBUG)  -- Set to DEBUG to ensure logging
        
        local success, err = Utils.ErrorHandler.safeCall(function() error("test error") end)
        TestFramework.assert.equal(false, success, "Function failed")
        -- The error message will include the file location
        TestFramework.assert.notNil(string.find(err, "test error"), "Error message contains 'test error'")
        TestFramework.assert.equal(1, #outputs, "Error was logged")
        
        Utils.Logger.close()
        Utils.Logger.output = originalOutput
    end,
    
    ["test input validation"] = function()
        local outputs = {}
        local originalOutput = Utils.Logger.output
        Utils.Logger.output = function(message)
            table.insert(outputs, message)
        end
        
        -- Initialize logger to ensure error level is enabled
        Utils.Logger.init(Utils.Logger.levels.ERROR)
        
        local valid, err = Utils.ErrorHandler.validateInput(5, "number", "test")
        TestFramework.assert.equal(true, valid, "Valid input")
        TestFramework.assert.equal(nil, err, "No error")
        
        local valid2, err2 = Utils.ErrorHandler.validateInput("string", "number", "test")
        TestFramework.assert.equal(false, valid2, "Invalid input")
        TestFramework.assert.notNil(err2, "Error returned")
        TestFramework.assert.equal("Invalid input for test: expected number, got string", err2, "Error message")
        
        Utils.Logger.close()
        Utils.Logger.output = originalOutput
    end,
    
    -- Spatial grid tests
    ["test spatial grid creation"] = function()
        local grid = Utils.SpatialGrid.new(100)
        
        TestFramework.assert.notNil(grid, "Grid created")
        TestFramework.assert.equal(100, grid.cellSize, "Cell size set")
        TestFramework.assert.notNil(grid.cells, "Cells initialized")
        TestFramework.assert.notNil(grid.getCellKey, "Has getCellKey method")
        TestFramework.assert.notNil(grid.addObject, "Has addObject method")
        TestFramework.assert.notNil(grid.insert, "Has insert method")
    end,
    
    ["test spatial grid insertion and retrieval"] = function()
        local grid = Utils.SpatialGrid.new(100)
        
        local obj = {x = 150, y = 250, radius = 10}
        grid:insert(obj)
        
        local nearby = grid:getNearby(150, 250, 50)
        TestFramework.assert.equal(1, #nearby, "Found 1 nearby object")
        TestFramework.assert.equal(obj, nearby[1], "Found inserted object")
        
        -- Test from different location
        local far = grid:getNearby(500, 500, 50)
        TestFramework.assert.equal(0, #far, "No objects far away")
    end,
    
    ["test spatial grid clearing"] = function()
        local grid = Utils.SpatialGrid.new(100)
        
        local obj = {x = 150, y = 250, radius = 10}
        grid:insert(obj)
        
        grid:clear()
        
        local nearby = grid:getNearby(150, 250, 50)
        TestFramework.assert.equal(0, #nearby, "No objects after clear")
    end,
    
    -- Mobile input tests
    ["test mobile detection"] = function()
        -- Mock screen dimensions
        local originalGetDimensions = love.graphics.getDimensions
        
        love.graphics.getDimensions = function()
            return 600, 800  -- Mobile portrait
        end
        
        TestFramework.assert.equal(true, Utils.MobileInput.isMobile(), "Should detect mobile")
        
        love.graphics.getDimensions = function()
            return 1920, 1080  -- Desktop
        end
        
        TestFramework.assert.equal(false, Utils.MobileInput.isMobile(), "Should detect desktop")
        
        -- Restore original
        love.graphics.getDimensions = originalGetDimensions
    end,
    
    ["test orientation detection"] = function()
        local originalGetDimensions = love.graphics.getDimensions
        
        love.graphics.getDimensions = function()
            return 800, 600  -- Landscape
        end
        
        TestFramework.assert.equal("landscape", Utils.MobileInput.getOrientation(), "Landscape orientation")
        
        love.graphics.getDimensions = function()
            return 600, 800  -- Portrait
        end
        
        TestFramework.assert.equal("portrait", Utils.MobileInput.getOrientation(), "Portrait orientation")
        
        -- Restore original
        love.graphics.getDimensions = originalGetDimensions
    end,
    
    -- Color palette tests
    ["test color palette structure"] = function()
        -- Ensure Utils is properly loaded
        local Utils = require("src.utils.utils")
        
        TestFramework.assert.notNil(Utils.colors, "Colors exist")
        TestFramework.assert.notNil(Utils.colors.player, "Player color exists")
        TestFramework.assert.notNil(Utils.colors.text, "Text color exists")
        TestFramework.assert.notNil(Utils.colors.accent, "Accent color exists")
        
        -- Test color format
        TestFramework.assert.equal(3, #Utils.colors.player, "Color has 3 components")
        TestFramework.assert.equal(3, #Utils.colors.text, "Text color has 3 components")
    end,
    
    -- Text rendering tests
    ["test text with shadow"] = function()
        -- Ensure Utils is properly loaded
        local Utils = require("src.utils.utils")
        
        -- Ensure love.graphics exists
        if not love.graphics then
            love.graphics = {}
        end
        
        local printCalls = {}
        local originalPrint = love.graphics.print
        love.graphics.print = function(text, x, y)
            table.insert(printCalls, {text, x, y})
        end
        
        local setColorCalls = {}
        local originalSetColor = love.graphics.setColor
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        Utils.drawTextWithShadow("Test", 100, 200, nil, {1, 1, 1}, {0, 0, 0, 0.8}, 2)
        
        TestFramework.assert.equal(2, #printCalls, "Text printed twice")
        TestFramework.assert.equal(2, #setColorCalls, "Color set twice")
        TestFramework.assert.equal(102, printCalls[1][2], "Shadow x offset")
        TestFramework.assert.equal(202, printCalls[1][3], "Shadow y offset")
        
        -- Restore originals
        love.graphics.print = originalPrint
        love.graphics.setColor = originalSetColor
    end,
    
    -- Progress bar test
    ["test progress bar drawing"] = function()
        -- Ensure Utils is properly loaded
        local Utils = require("src.utils.utils")
        
        -- First ensure love.graphics exists
        if not love.graphics then
            love.graphics = {}
        end
        
        local rectCalls = {}
        local originalRect = love.graphics.rectangle
        love.graphics.rectangle = function(mode, x, y, w, h, rx, ry)
            -- Ensure all parameters are numbers to avoid nil arithmetic
            x = x or 0
            y = y or 0
            w = w or 0
            h = h or 0
            rx = rx or 0
            ry = ry or 0
            table.insert(rectCalls, {mode, x, y, w, h, rx, ry})
        end
        
        local setColorCalls = {}
        local originalSetColor = love.graphics.setColor
        love.graphics.setColor = function(r, g, b, a)
            table.insert(setColorCalls, {r, g, b, a})
        end
        
        local originalPrint = love.graphics.print
        love.graphics.print = function(text, x, y) end
        
        -- Mock Utils.setColor to avoid issues
        local originalUtilsSetColor = Utils.setColor
        Utils.setColor = function(color, alpha)
            -- Call the mocked love.graphics.setColor
            love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
        end
        
        -- Mock Utils.drawTextWithShadow to avoid issues
        local originalDrawTextWithShadow = Utils.drawTextWithShadow
        Utils.drawTextWithShadow = function(text, x, y, font, color, shadowColor, shadowOffset) end
        
        Utils.drawProgressBar(100, 200, 300, 20, 0.75)
        
        -- Should draw 3 rectangles: background, progress, border
        TestFramework.assert.equal(3, #rectCalls, "3 rectangles drawn")
        
        -- Check progress fill width
        local found = false
        for _, call in ipairs(rectCalls) do
            if call[1] == "fill" and call[4] == 225 then  -- 300 * 0.75
                found = true
                break
            end
        end
        TestFramework.assert.equal(true, found, "Progress bar filled correctly")
        
        -- Restore originals
        love.graphics.rectangle = originalRect
        love.graphics.setColor = originalSetColor
        love.graphics.print = originalPrint
        Utils.setColor = originalUtilsSetColor
        Utils.drawTextWithShadow = originalDrawTextWithShadow
    end,
    
    -- Compatibility tests
    ["test atan2 compatibility"] = function()
        TestFramework.assert.notNil(Utils.atan2, "atan2 exists")
        TestFramework.assert.equal("function", type(Utils.atan2), "atan2 is function")
        
        -- Test basic functionality
        local angle = Utils.atan2(1, 1)
        TestFramework.assert.approx(math.pi/4, angle, 0.001, "atan2 works correctly")
    end
}

-- Run the test suite
local function run()
    return TestFramework.runTests(tests, "Utils Tests")
end

return {run = run}