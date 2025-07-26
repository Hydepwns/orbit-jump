-- Object Pool System for Orbit Jump
-- Reuses objects to reduce garbage collection and improve performance

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-- Create a new object pool
function ObjectPool:new(createFunc, resetFunc, maxSize)
    local self = setmetatable({}, ObjectPool)
    self.createFunc = createFunc or function() return {} end
    self.resetFunc = resetFunc or function(obj) end
    self.maxSize = maxSize or 1000
    self.pool = {}
    self.activeObjects = {}
    self.activeCount = 0
    return self
end

-- Get an object from the pool
function ObjectPool:get()
    local obj
    
    if #self.pool > 0 then
        -- Reuse from pool
        obj = table.remove(self.pool)
    else
        -- Create new if under max size
        if self.activeCount < self.maxSize then
            obj = self.createFunc()
        else
            -- Pool exhausted, return nil
            return nil
        end
    end
    
    -- Track as active
    self.activeObjects[obj] = true
    self.activeCount = self.activeCount + 1
    
    return obj
end

-- Return an object to the pool
function ObjectPool:release(obj)
    if not self.activeObjects[obj] then
        return -- Not from this pool
    end
    
    -- Reset the object
    self.resetFunc(obj)
    
    -- Remove from active tracking
    self.activeObjects[obj] = nil
    self.activeCount = self.activeCount - 1
    
    -- Add back to pool
    table.insert(self.pool, obj)
end

-- Release all active objects
function ObjectPool:releaseAll()
    for obj in pairs(self.activeObjects) do
        self.resetFunc(obj)
        table.insert(self.pool, obj)
    end
    self.activeObjects = {}
    self.activeCount = 0
end

-- Get pool statistics
function ObjectPool:getStats()
    return {
        active = self.activeCount,
        pooled = #self.pool,
        total = self.activeCount + #self.pool,
        maxSize = self.maxSize
    }
end

-- Clear the pool completely
function ObjectPool:clear()
    self.pool = {}
    self.activeObjects = {}
    self.activeCount = 0
end

return ObjectPool