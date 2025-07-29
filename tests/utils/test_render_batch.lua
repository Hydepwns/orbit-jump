-- Test file for Render Batch
local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Initialize test framework
TestFramework.init()

-- Get RenderBatch
local RenderBatch = Utils.require("src.utils.render_batch")

-- Test suite
local tests = {
    ["test render batch creation"] = function()
        local batch = RenderBatch:new()
        
        TestFramework.assert.notNil(batch, "Batch should be created")
        TestFramework.assert.notNil(batch.batches, "Should have batches table")
        TestFramework.assert.equal(0, batch.drawCalls, "Should start with 0 draw calls")
        TestFramework.assert.equal(0, batch.itemsDrawn, "Should start with 0 items drawn")
    end,
    
    ["test add items to batch"] = function()
        local batch = RenderBatch:new()
        
        batch:add("circles", "fill", {x = 100, y = 100, radius = 20})
        batch:add("circles", "fill", {x = 200, y = 200, radius = 30})
        batch:add("circles", "line", {x = 300, y = 300, radius = 40})
        
        TestFramework.assert.notNil(batch.batches.circles, "Should have circles category")
        TestFramework.assert.equal(2, #batch.batches.circles.fill, "Should have 2 filled circles")
        TestFramework.assert.equal(1, #batch.batches.circles.line, "Should have 1 line circle")
    end,
    
    ["test add circle to batch"] = function()
        local batch = RenderBatch:new()
        
        batch:addCircle("fill", 100, 100, 20, {1, 0, 0}, nil)
        batch:addCircle("line", 200, 200, 30, {0, 1, 0}, 2)
        
        TestFramework.assert.notNil(batch.batches.circles, "Should have circles category")
        TestFramework.assert.equal(100, batch.batches.circles.fill[1].x, "Should store x coordinate")
        TestFramework.assert.equal(30, batch.batches.circles.line[1].radius, "Should store radius")
        TestFramework.assert.equal(2, batch.batches.circles.line[1].lineWidth, "Should store line width")
    end,
    
    ["test clear batch"] = function()
        local batch = RenderBatch:new()
        
        -- Add some items
        batch:add("circles", "fill", {x = 100, y = 100})
        batch:add("rectangles", "fill", {x = 200, y = 200})
        batch.drawCalls = 5
        batch.itemsDrawn = 10
        
        -- Clear
        batch:clear()
        
        TestFramework.assert.isEmpty(batch.batches, "Batches should be empty")
        TestFramework.assert.equal(0, batch.drawCalls, "Draw calls should be reset")
        TestFramework.assert.equal(0, batch.itemsDrawn, "Items drawn should be reset")
    end,
    
    ["test batch categories"] = function()
        local batch = RenderBatch:new()
        
        -- Add different categories
        batch:add("circles", "fill", {})
        batch:add("rectangles", "fill", {})
        batch:add("lines", "default", {})
        batch:add("text", "default", {})
        
        TestFramework.assert.notNil(batch.batches.circles, "Should have circles")
        TestFramework.assert.notNil(batch.batches.rectangles, "Should have rectangles")
        TestFramework.assert.notNil(batch.batches.lines, "Should have lines")
        TestFramework.assert.notNil(batch.batches.text, "Should have text")
    end,
    
    ["test batch subcategories"] = function()
        local batch = RenderBatch:new()
        
        -- Add different subcategories
        batch:add("circles", "fill", {})
        batch:add("circles", "line", {})
        batch:add("circles", "fill", {})
        
        TestFramework.assert.equal(2, #batch.batches.circles.fill, "Should have 2 filled circles")
        TestFramework.assert.equal(1, #batch.batches.circles.line, "Should have 1 line circle")
    end,
    
    ["test batch with complex objects"] = function()
        local batch = RenderBatch:new()
        
        local complexItem = {
            x = 100,
            y = 200,
            radius = 30,
            color = {1, 0.5, 0.2, 0.8},
            lineWidth = 3,
            segments = 16,
            rotation = math.pi / 4
        }
        
        batch:add("complex", "default", complexItem)
        
        local retrieved = batch.batches.complex.default[1]
        TestFramework.assert.equal(complexItem.x, retrieved.x, "Should preserve x")
        TestFramework.assert.equal(complexItem.rotation, retrieved.rotation, "Should preserve rotation")
        TestFramework.assert.deepEqual(complexItem.color, retrieved.color, "Should preserve color array")
    end,
    
    ["test empty batch operations"] = function()
        local batch = RenderBatch:new()
        
        -- Operations on empty batch should not crash
        batch:clear()
        
        TestFramework.assert.isEmpty(batch.batches, "Empty batch should remain empty")
    end
}

-- Test runner
local function run()
    Utils.Logger.info("Running Render Batch Tests")
    Utils.Logger.info("==================================================")
    return TestFramework.runTests(tests)
end

return {run = run}