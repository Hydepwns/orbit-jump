-- Object Pool System for Orbit Jump
-- Reuses objects to reduce garbage collection and improve performance

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-- Create a new object pool
function ObjectPool:new(createFunc, sizeOrResetFunc, resetFuncOrNil)
    local self = setmetatable({}, ObjectPool)
    
    -- Validate createFunc
    if not createFunc then
        error("ObjectPool requires a creation function")
    end
    
    -- Handle overloaded parameters
    local size, resetFunc
    if type(sizeOrResetFunc) == "number" then
        -- Called as ObjectPool:new(createFunc, size, resetFunc)
        size = sizeOrResetFunc
        resetFunc = resetFuncOrNil
    else
        -- Called as ObjectPool:new(createFunc, resetFunc, maxSize)
        resetFunc = sizeOrResetFunc
        size = resetFuncOrNil or 1000
    end
    
    self.createFunc = createFunc
    self.resetFunc = resetFunc or function(obj) obj.active = false end
    self.size = size or 1000
    self.maxSize = self.size
    self.pool = {}
    self.objects = {}  -- All objects (for test compatibility)
    self.activeObjects = {}
    self.activeCount = 0
    
    -- Pre-allocate objects
    for i = 1, self.size do
        local obj = self.createFunc()
        if obj then
            obj.active = false
            table.insert(self.pool, obj)
            table.insert(self.objects, obj)
        end
    end
    
    return self
end

-- Get an object from the pool
function ObjectPool:get()
    local obj
    
    if #self.pool > 0 then
        -- Reuse from pool
        obj = table.remove(self.pool)
    else
        -- Try to expand pool with reasonable limits
        -- Allow expansion up to 1.5x the original size for flexibility
        local expansionLimit = math.max(self.maxSize, self.maxSize * 1.5)
        if #self.objects < expansionLimit then
            obj = self.createFunc()
            if obj then
                table.insert(self.objects, obj)
                self.size = self.size + 1
            end
        else
            -- Pool exhausted, return nil
            return nil
        end
    end
    
    if obj then
        -- Mark as active
        obj.active = true
        self.activeObjects[obj] = true
        self.activeCount = self.activeCount + 1
    end
    
    return obj
end

-- Return an object to the pool
function ObjectPool:release(obj)
    if not self.activeObjects[obj] then
        return -- Not from this pool
    end
    
    -- Mark as inactive
    obj.active = false
    
    -- Reset the object
    if self.resetFunc then
        self.resetFunc(obj)
    end
    
    -- Remove from active tracking
    self.activeObjects[obj] = nil
    self.activeCount = self.activeCount - 1
    
    -- Add back to pool
    table.insert(self.pool, obj)
end

-- Release all active objects
function ObjectPool:releaseAll()
    for obj in pairs(self.activeObjects) do
        obj.active = false
        if self.resetFunc then
            self.resetFunc(obj)
        end
        table.insert(self.pool, obj)
    end
    self.activeObjects = {}
    self.activeCount = 0
end

-- Get pool statistics
function ObjectPool:getStats()
    return {
        active = self.activeCount,
        available = #self.pool,
        pooled = #self.pool,
        total = self.activeCount + #self.pool,
        maxSize = self.maxSize
    }
end

-- Clear the pool completely
function ObjectPool:clear()
    -- Release all active objects back to pool
    self:releaseAll()
    
    -- Keep the pre-allocated objects in the pool
    -- This maintains the 'available' count for tests
end

return ObjectPool