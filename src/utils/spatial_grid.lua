-- Spatial Grid for Orbit Jump
-- Efficient spatial indexing for collision detection

local SpatialGrid = {}
SpatialGrid.__index = SpatialGrid

-- Create a new spatial grid
function SpatialGrid:new(cellSize)
    local self = setmetatable({}, SpatialGrid)
    self.cellSize = cellSize or 100
    self.grid = {}
    self.objects = {}
    return self
end

-- Get grid key for a position
function SpatialGrid:getKey(x, y)
    local gx = math.floor(x / self.cellSize)
    local gy = math.floor(y / self.cellSize)
    return gx .. "," .. gy
end

-- Get all keys for an object's bounds
function SpatialGrid:getKeysForBounds(x, y, radius)
    local keys = {}
    local minX = math.floor((x - radius) / self.cellSize)
    local maxX = math.floor((x + radius) / self.cellSize)
    local minY = math.floor((y - radius) / self.cellSize)
    local maxY = math.floor((y + radius) / self.cellSize)
    
    for gx = minX, maxX do
        for gy = minY, maxY do
            table.insert(keys, gx .. "," .. gy)
        end
    end
    
    return keys
end

-- Insert an object into the grid
function SpatialGrid:insert(object, x, y, radius)
    -- Remove from old position if tracked
    if self.objects[object] then
        self:remove(object)
    end
    
    -- Get all cells this object occupies
    local keys = self:getKeysForBounds(x, y, radius)
    
    -- Store object info
    self.objects[object] = {
        x = x,
        y = y,
        radius = radius,
        keys = keys
    }
    
    -- Insert into grid cells
    for _, key in ipairs(keys) do
        if not self.grid[key] then
            self.grid[key] = {}
        end
        self.grid[key][object] = true
    end
end

-- Remove an object from the grid
function SpatialGrid:remove(object)
    local info = self.objects[object]
    if not info then return end
    
    -- Remove from all cells
    for _, key in ipairs(info.keys) do
        if self.grid[key] then
            self.grid[key][object] = nil
            -- Clean up empty cells
            local empty = true
            for _ in pairs(self.grid[key]) do
                empty = false
                break
            end
            if empty then
                self.grid[key] = nil
            end
        end
    end
    
    -- Remove object info
    self.objects[object] = nil
end

-- Update an object's position
function SpatialGrid:update(object, x, y, radius)
    local info = self.objects[object]
    if not info then
        -- New object
        self:insert(object, x, y, radius)
        return
    end
    
    -- Check if we need to update cells
    local newKeys = self:getKeysForBounds(x, y, radius)
    local keysChanged = false
    
    if #newKeys ~= #info.keys then
        keysChanged = true
    else
        for i, key in ipairs(newKeys) do
            if key ~= info.keys[i] then
                keysChanged = true
                break
            end
        end
    end
    
    -- Update position
    info.x = x
    info.y = y
    info.radius = radius
    
    -- Update cells if needed
    if keysChanged then
        -- Remove from old cells
        for _, key in ipairs(info.keys) do
            if self.grid[key] then
                self.grid[key][object] = nil
            end
        end
        
        -- Add to new cells
        info.keys = newKeys
        for _, key in ipairs(newKeys) do
            if not self.grid[key] then
                self.grid[key] = {}
            end
            self.grid[key][object] = true
        end
    end
end

-- Get potential collision candidates for a position
function SpatialGrid:query(x, y, radius, excludeObject)
    local candidates = {}
    local seen = {}
    
    -- Get all cells to check
    local keys = self:getKeysForBounds(x, y, radius)
    
    -- Collect unique objects from cells
    for _, key in ipairs(keys) do
        local cell = self.grid[key]
        if cell then
            for obj in pairs(cell) do
                if obj ~= excludeObject and not seen[obj] then
                    seen[obj] = true
                    table.insert(candidates, obj)
                end
            end
        end
    end
    
    return candidates
end

-- Get nearby objects within a radius
function SpatialGrid:queryRadius(x, y, radius, excludeObject)
    local candidates = self:query(x, y, radius, excludeObject)
    local nearby = {}
    
    -- Filter by actual distance
    for _, obj in ipairs(candidates) do
        local info = self.objects[obj]
        if info then
            local dx = info.x - x
            local dy = info.y - y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist <= radius + info.radius then
                table.insert(nearby, {
                    object = obj,
                    distance = dist,
                    x = info.x,
                    y = info.y,
                    radius = info.radius
                })
            end
        end
    end
    
    -- Sort by distance
    table.sort(nearby, function(a, b) return a.distance < b.distance end)
    
    return nearby
end

-- Clear the grid
function SpatialGrid:clear()
    self.grid = {}
    self.objects = {}
end

-- Get statistics
function SpatialGrid:getStats()
    local cellCount = 0
    local objectCount = 0
    local maxObjectsPerCell = 0
    
    for key, cell in pairs(self.grid) do
        cellCount = cellCount + 1
        local count = 0
        for _ in pairs(cell) do
            count = count + 1
        end
        maxObjectsPerCell = math.max(maxObjectsPerCell, count)
    end
    
    for _ in pairs(self.objects) do
        objectCount = objectCount + 1
    end
    
    return {
        cellSize = self.cellSize,
        cellCount = cellCount,
        objectCount = objectCount,
        maxObjectsPerCell = maxObjectsPerCell
    }
end

return SpatialGrid