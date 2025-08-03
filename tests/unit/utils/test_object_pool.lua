-- Test file for Object Pool
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Get ObjectPool
local ObjectPool = Utils.require("src.utils.object_pool")
-- Test suite
local tests = {
    ["test pool creation"] = function()
        local pool = ObjectPool:new(function()
            return {x = 0, y = 0, active = false}
        end, 10)
        TestFramework.assert.notNil(pool, "Pool should be created")
        TestFramework.assert.equal(10, pool.size, "Pool size should be set")
        TestFramework.assert.notNil(pool.objects, "Pool should have objects array")
    end,
    ["test pool pre-allocation"] = function()
        local createCount = 0
        local pool = ObjectPool:new(function()
            createCount = createCount + 1
            return {x = 0, y = 0, active = false}
        end, 5)
        TestFramework.assert.equal(5, createCount, "Should pre-allocate objects")
        TestFramework.assert.equal(5, #pool.objects, "Should have 5 objects")
    end,
    ["test get object from pool"] = function()
        local pool = ObjectPool:new(function()
            return {x = 0, y = 0, active = false}
        end, 5)
        local obj = pool:get()
        TestFramework.assert.notNil(obj, "Should get object from pool")
        TestFramework.assert.isTrue(obj.active, "Object should be marked active")
    end,
    ["test release object to pool"] = function()
        local pool = ObjectPool:new(function()
            return {x = 0, y = 0, active = false}
        end, 5)
        local obj = pool:get()
        obj.x = 100
        obj.y = 200
        pool:release(obj)
        TestFramework.assert.isFalse(obj.active, "Object should be marked inactive")
        -- Get the same object again
        local obj2 = pool:get()
        TestFramework.assert.equal(obj, obj2, "Should reuse the same object")
    end,
    ["test pool expansion"] = function()
        local pool = ObjectPool:new(function()
            return {x = 0, y = 0, active = false}
        end, 2)
        -- Get all objects
        local obj1 = pool:get()
        local obj2 = pool:get()
        -- Request one more - should expand pool
        local obj3 = pool:get()
        TestFramework.assert.notNil(obj3, "Should expand pool when needed")
        TestFramework.assert.greaterThan(2, pool.size, "Pool size should increase")
    end,
    ["test reset function"] = function()
        local resetCalled = false
        local pool = ObjectPool:new(
            function() return {x = 0, y = 0, active = false} end,
            5,
            function(obj) -- Reset function
                resetCalled = true
                obj.x = 0
                obj.y = 0
            end
        )
        local obj = pool:get()
        obj.x = 100
        obj.y = 200
        pool:release(obj)
        TestFramework.assert.isTrue(resetCalled, "Reset function should be called")
        TestFramework.assert.equal(0, obj.x, "Object should be reset")
        TestFramework.assert.equal(0, obj.y, "Object should be reset")
    end,
    ["test pool statistics"] = function()
        local pool = ObjectPool:new(function()
            return {x = 0, y = 0, active = false}
        end, 5)
        -- Get some objects
        pool:get()
        pool:get()
        pool:get()
        local stats = pool:getStats()
        TestFramework.assert.notNil(stats, "Should provide statistics")
        TestFramework.assert.equal(3, stats.active, "Should track active objects")
        TestFramework.assert.equal(2, stats.available, "Should track available objects")
    end,
    ["test clear pool"] = function()
        local pool = ObjectPool:new(function()
            return {x = 0, y = 0, active = false}
        end, 5)
        -- Get some objects
        pool:get()
        pool:get()
        pool:clear()
        local stats = pool:getStats()
        TestFramework.assert.equal(0, stats.active, "Should have no active objects")
        TestFramework.assert.equal(5, stats.available, "All objects should be available")
    end,
    ["test pool with complex objects"] = function()
        local pool = ObjectPool:new(function()
            return {
                position = {x = 0, y = 0},
                velocity = {x = 0, y = 0},
                components = {},
                active = false
            }
        end, 3)
        local obj = pool:get()
        obj.position.x = 100
        obj.components.renderer = "test"
        TestFramework.assert.notNil(obj.position, "Complex object should maintain structure")
        TestFramework.assert.equal(100, obj.position.x, "Should modify complex object")
    end,
    ["test pool memory efficiency"] = function()
        local pool = ObjectPool:new(function()
            return {data = {}}
        end, 100)
        -- Get and release many times
        for i = 1, 1000 do
            local obj = pool:get()
            obj.data.value = i
            pool:release(obj)
        end
        -- Pool should not grow beyond reasonable size
        TestFramework.assert.lessThanOrEqual(150, pool.size, "Pool should not grow excessively")
    end,
    ["test concurrent access"] = function()
        local pool = ObjectPool:new(function()
            return {id = math.random(), active = false}
        end, 5)
        local objects = {}
        -- Get multiple objects
        for i = 1, 5 do
            objects[i] = pool:get()
        end
        -- All objects should be unique
        for i = 1, 5 do
            for j = i + 1, 5 do
                TestFramework.assert.notEqual(objects[i], objects[j], "Objects should be unique")
            end
        end
    end,
    ["test pool with nil factory"] = function()
        local success = pcall(function()
            ObjectPool:new(nil, 5)
        end)
        TestFramework.assert.isFalse(success, "Should fail with nil factory")
    end
}
-- Run tests
local function run()
    return TestFramework.runTests(tests, "Object Pool Tests")
end
return {run = run}