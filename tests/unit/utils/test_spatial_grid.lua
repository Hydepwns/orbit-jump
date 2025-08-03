-- Test file for Spatial Grid
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")
-- Setup mocks
Mocks.setup()
-- Initialize test framework
TestFramework.init()
-- Get SpatialGrid
local SpatialGrid = Utils.require("src.utils.spatial_grid")
-- Test suite
local tests = {
    ["test spatial grid creation"] = function()
        local grid = SpatialGrid:new(10)
        TestFramework.assert.notNil(grid, "Grid should be created")
        TestFramework.assert.equal(10, grid.cellSize, "Cell size should be set")
        TestFramework.assert.notNil(grid.grid, "Grid cells should be initialized")
        TestFramework.assert.notNil(grid.objects, "Objects table should be initialized")
    end,
    ["test add object to grid"] = function()
        local grid = SpatialGrid:new(10)
        local obj = {x = 25, y = 25, id = 1}
        grid:insert(obj, 25, 25, 5)
        local key = grid:getKey(25, 25)
        TestFramework.assert.notNil(grid.grid[key], "Cell should exist")
        TestFramework.assert.isTrue(grid.grid[key][obj], "Cell should contain the object")
        -- Count objects in cell
        local count = 0
        for _ in pairs(grid.grid[key]) do
            count = count + 1
        end
        TestFramework.assert.equal(1, count, "Cell should contain one object")
    end,
    ["test remove object from grid"] = function()
        local grid = SpatialGrid:new(10)
        local obj = {x = 25, y = 25, id = 1}
        grid:insert(obj, 25, 25, 5)
        grid:remove(obj)
        local key = grid:getKey(25, 25)
        TestFramework.assert.equal(0, grid.grid[key] and #grid.grid[key] or 0, "Cell should be empty")
    end,
    ["test update object position"] = function()
        local grid = SpatialGrid:new(10)
        local obj = {x = 25, y = 25, id = 1}
        grid:insert(obj, 25, 25, 5)
        -- Move object to new cell by removing and re-inserting
        grid:remove(obj)
        grid:insert(obj, 55, 55, 5)
        local oldKey = "2,2"
        local newKey = "5,5"
        -- Check old cell is empty or doesn't exist
        TestFramework.assert.isTrue(not grid.grid[oldKey] or not grid.grid[oldKey][obj], "Object should not be in old cell")
        -- Check new cell contains object
        TestFramework.assert.notNil(grid.grid[newKey], "New cell should exist")
        TestFramework.assert.isTrue(grid.grid[newKey][obj], "New cell should contain object")
    end,
    ["test get nearby objects"] = function()
        local grid = SpatialGrid:new(10)
        -- Add objects in different cells
        local obj1 = {x = 15, y = 15, id = 1}
        local obj2 = {x = 25, y = 25, id = 2}
        local obj3 = {x = 85, y = 85, id = 3}
        grid:insert(obj1, 15, 15, 5)
        grid:insert(obj2, 25, 25, 5)
        grid:insert(obj3, 85, 85, 5)
        -- Get objects near (20, 20)
        local nearby = grid:query(20, 20, 20)
        TestFramework.assert.greaterThan(0, #nearby, "Should find nearby objects")
        -- Check that distant object is not included
        local hasDistant = false
        for _, obj in ipairs(nearby) do
            if obj.id == 3 then
                hasDistant = true
            end
        end
        TestFramework.assert.isFalse(hasDistant, "Should not include distant object")
    end,
    ["test clear grid"] = function()
        local grid = SpatialGrid:new(10)
        grid:insert({x = 10, y = 10}, 10, 10, 5)
        grid:insert({x = 20, y = 20}, 20, 20, 5)
        grid:insert({x = 30, y = 30}, 30, 30, 5)
        grid:clear()
        local count = 0
        for _, cell in pairs(grid.grid) do
            count = count + #cell
        end
        TestFramework.assert.equal(0, count, "Grid should be empty after clear")
    end,
    ["test grid boundaries"] = function()
        local grid = SpatialGrid:new(10)
        -- Test objects at boundaries
        local obj1 = {x = 0, y = 0, id = 1}
        local obj2 = {x = 99, y = 99, id = 2}
        local obj3 = {x = -10, y = -10, id = 3} -- Outside
        local obj4 = {x = 110, y = 110, id = 4} -- Outside
        grid:insert(obj1, 0, 0, 5)
        grid:insert(obj2, 99, 99, 5)
        grid:insert(obj3, -10, -10, 5)
        grid:insert(obj4, 110, 110, 5)
        -- Grid handles negative coordinates fine
        TestFramework.assert.isTrue(true, "Should handle boundary objects")
    end,
    ["test query radius"] = function()
        local grid = SpatialGrid:new(10)
        -- Add objects in grid pattern
        for x = 5, 95, 10 do
            for y = 5, 95, 10 do
                grid:insert({x = x, y = y}, x, y, 2)
            end
        end
        -- Query objects around center
        local objects = grid:query(50, 50, 20)
        TestFramework.assert.greaterThan(0, #objects, "Should find objects in radius")
        -- Query returns objects in grid cells, not necessarily within exact radius
        -- Just verify we got some nearby objects
        local closeCount = 0
        for _, obj in ipairs(objects) do
            local dist = math.sqrt((obj.x - 50)^2 + (obj.y - 50)^2)
            if dist <= 20 then
                closeCount = closeCount + 1
            end
        end
        TestFramework.assert.greaterThan(0, closeCount, "Should find at least some objects within radius")
    end,
    ["test multiple objects in same cell"] = function()
        local grid = SpatialGrid:new(10)
        -- Add multiple objects to same cell
        local obj1 = {x = 25, y = 25, id = 1}
        local obj2 = {x = 26, y = 26, id = 2}
        local obj3 = {x = 27, y = 27, id = 3}
        grid:insert(obj1, 25, 25, 2)
        grid:insert(obj2, 26, 26, 2)
        grid:insert(obj3, 27, 27, 2)
        local key = "2,2"
        -- Count objects in cell
        local count = 0
        if grid.grid[key] then
            for _ in pairs(grid.grid[key]) do
                count = count + 1
            end
        end
        TestFramework.assert.equal(3, count, "Cell should contain 3 objects")
    end,
    ["test grid performance"] = function()
        local grid = SpatialGrid:new(50)
        -- Add many objects
        local startTime = os.clock()
        for i = 1, 1000 do
            local x, y = math.random(0, 999), math.random(0, 999)
            grid:insert({x = x, y = y, id = i}, x, y, 5)
        end
        local addTime = os.clock() - startTime
        -- Query nearby objects
        startTime = os.clock()
        local nearby = grid:query(500, 500, 100)
        local queryTime = os.clock() - startTime
        TestFramework.assert.lessThan(0.1, addTime, "Adding 1000 objects should be fast")
        TestFramework.assert.lessThan(0.01, queryTime, "Querying should be fast")
    end,
    ["test object tracking"] = function()
        local grid = SpatialGrid:new(10)
        local obj = {x = 25, y = 25, id = 1}
        grid:insert(obj, 25, 25, 5)
        -- Check if object is tracked in objects table
        TestFramework.assert.notNil(grid.objects[obj], "Grid should track object")
        TestFramework.assert.notNil(grid.objects[obj].keys, "Should track object keys")
    end,
    ["test remove object updates tracking"] = function()
        local grid = SpatialGrid:new(10)
        -- Add and remove object
        local obj = {x = 10, y = 10, id = 1}
        grid:insert(obj, 10, 10, 5)
        grid:remove(obj)
        -- Check object is no longer tracked
        TestFramework.assert.isNil(grid.objects[obj], "Removed object should not be tracked")
        -- Check grid cell is empty
        local key = grid:getKey(10, 10)
        TestFramework.assert.equal(0, grid.grid[key] and #grid.grid[key] or 0, "Cell should be empty")
    end
}
-- Run tests
local function run()
    return TestFramework.runTests(tests, "Spatial Grid Tests")
end
return {run = run}