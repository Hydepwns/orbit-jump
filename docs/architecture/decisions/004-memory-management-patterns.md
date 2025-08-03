# ADR-004: Memory Management Patterns

## Status
Accepted

## Context
Performance analysis revealed several memory leaks:
- Unbounded table growth in analytics systems
- Font caches growing indefinitely
- Event history accumulating forever
- No cleanup of old data

This caused:
- Increasing memory usage over time
- Performance degradation in long sessions
- Potential out-of-memory crashes

## Decision
Implement consistent memory management patterns:

1. **Bounded Collections**: All collections must have size limits
2. **LRU Eviction**: Use Least Recently Used pattern for caches
3. **Circular Buffers**: For fixed-size history tracking
4. **Periodic Cleanup**: Remove old data on intervals

## Consequences

### Positive
- Predictable memory usage
- No memory leaks in long sessions
- Better performance consistency
- Mobile-friendly memory footprint

### Negative
- Some historical data is lost
- Slightly more complex code
- Need to tune size limits

### Neutral
- Requires profiling to find optimal limits
- May need adjustment based on platform

## Implementation Patterns

### Bounded Array
```lua
local MAX_ENTRIES = 100

function addEntry(entry)
    table.insert(entries, entry)
    
    -- Enforce bounds
    if #entries > MAX_ENTRIES then
        -- Remove oldest
        table.remove(entries, 1)
    end
end
```

### LRU Cache
```lua
local cache = {}
local cacheOrder = {}
local MAX_CACHE_SIZE = 50

function getCached(key)
    if cache[key] then
        -- Update access order
        updateAccessOrder(key)
        return cache[key]
    end
    
    -- Add new entry
    if #cacheOrder >= MAX_CACHE_SIZE then
        -- Evict least recently used
        local lru = table.remove(cacheOrder, 1)
        cache[lru] = nil
    end
    
    cache[key] = createValue(key)
    table.insert(cacheOrder, key)
    return cache[key]
end
```

### Periodic Cleanup
```lua
function update(dt)
    -- Cleanup every minute
    if love.timer.getTime() % 60 < dt then
        cleanupOldData()
    end
end
```

## Size Recommendations
- Event History: 100-200 entries
- Font Cache: 10-20 fonts
- Analytics Data: 1 hour of samples
- Particle Pool: 1000 objects
- Planet Visit Tracking: 200 planets