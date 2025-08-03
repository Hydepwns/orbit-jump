# Error Handling Standards for Orbit Jump

## Overview

This document defines the standardized error handling patterns for the Orbit Jump codebase. All new code should follow these patterns, and existing code should be migrated during refactoring.

## Standard Pattern: Utils.ErrorHandler.safeCall

Use `Utils.ErrorHandler.safeCall` for all operations that might fail:

```lua
local result = Utils.ErrorHandler.safeCall(potentiallyFailingFunction, {
    onError = function(err)
        Utils.Logger.error("ComponentName: Action failed", err)
    end,
    fallback = defaultValue
})
```

### Parameters

- **Function**: The function to execute safely
- **Options table**:
  - `onError`: Callback function called when an error occurs
  - `fallback`: Value returned if the function fails
  - `context`: Optional context object passed to error handler

## Error Handling by System Type

### 1. Core Systems (game.lua, renderer.lua, etc.)

Critical systems should log errors and attempt recovery:

```lua
local success = Utils.ErrorHandler.safeCall(criticalOperation, {
    onError = function(err)
        Utils.Logger.error("CriticalSystem: Operation failed, attempting recovery", err)
        -- Record in system health
        systemHealth.criticalSystems[systemName] = {
            error = err,
            timestamp = love.timer.getTime()
        }
        -- Attempt recovery
        recoverFromError(systemName)
    end,
    fallback = false
})
```

### 2. Game Systems (player_system.lua, warp_drive.lua, etc.)

Game systems should degrade gracefully:

```lua
local result = Utils.ErrorHandler.safeCall(gameOperation, {
    onError = function(err)
        Utils.Logger.warn("GameSystem: Feature disabled due to error", err)
        -- Disable feature
        self.featureEnabled = false
    end,
    fallback = nil
})
```

### 3. UI Systems

UI errors should not crash the game:

```lua
Utils.ErrorHandler.safeCall(uiRenderFunction, {
    onError = function(err)
        Utils.Logger.warn("UISystem: Render failed, using fallback UI", err)
        -- Render minimal UI
        renderFallbackUI()
    end
})
```

### 4. Utility Functions

Utilities should return sensible defaults:

```lua
function Utils.parseJSON(jsonString)
    return Utils.ErrorHandler.safeCall(function()
        return json.decode(jsonString)
    end, {
        onError = function(err)
            Utils.Logger.debug("Utils: JSON parse failed", err)
        end,
        fallback = {}
    })
end
```

## Logging Levels

Use appropriate log levels for different error severities:

- **ERROR**: System failures, data corruption, unrecoverable states
- **WARN**: Feature failures, degraded functionality, recoverable errors
- **INFO**: Expected errors (e.g., file not found during optional load)
- **DEBUG**: Validation failures, parsing errors in development

## Error Context

Always provide meaningful context in error messages:

```lua
-- Good
Utils.Logger.error("PlayerSystem: Failed to apply gravity - player=%s, planet=%s", 
    tostring(player.id), tostring(planet.id))

-- Bad
Utils.Logger.error("Gravity failed")
```

## Migration Guide

To migrate existing code:

1. Find all `pcall` usage:
   ```bash
   grep -r "pcall(" src/
   ```

2. Replace with standardized pattern:
   ```lua
   -- Old
   local success, result = pcall(someFunction, arg1, arg2)
   if not success then
       print("Error: " .. result)
   end
   
   -- New
   local result = Utils.ErrorHandler.safeCall(function()
       return someFunction(arg1, arg2)
   end, {
       onError = function(err)
           Utils.Logger.error("ComponentName: someFunction failed", err)
       end,
       fallback = nil
   })
   ```

3. Remove try/catch style error handling
4. Add appropriate logging and recovery

## Testing Error Handlers

All error paths should be tested:

```lua
function testErrorHandling()
    local errorFunction = function()
        error("Simulated error")
    end
    
    local result = Utils.ErrorHandler.safeCall(errorFunction, {
        onError = function(err)
            -- Verify error was caught
            TestFramework.assert.truthy(err:match("Simulated error"))
        end,
        fallback = "fallback_value"
    })
    
    TestFramework.assert.equal(result, "fallback_value")
end
```

## Common Patterns

### Resource Loading

```lua
function loadResource(path)
    return Utils.ErrorHandler.safeCall(function()
        return love.filesystem.read(path)
    end, {
        onError = function(err)
            Utils.Logger.info("Resource: Optional file not found - %s", path)
        end,
        fallback = nil
    })
end
```

### System Initialization

```lua
function System.init()
    local initialized = Utils.ErrorHandler.safeCall(function()
        -- Complex initialization
        self.resource = loadRequiredResource()
        self.config = parseConfig()
        return true
    end, {
        onError = function(err)
            Utils.Logger.error("System: Initialization failed", err)
            self.fallbackMode = true
        end,
        fallback = false
    })
    
    return initialized
end
```

### Event Handlers

```lua
function onEvent(event)
    Utils.ErrorHandler.safeCall(function()
        processEvent(event)
    end, {
        onError = function(err)
            Utils.Logger.warn("EventHandler: Failed to process event type=%s", 
                event.type, err)
        end
    })
end
```

## Performance Considerations

- Error handlers have minimal overhead when no error occurs
- Avoid creating closures in hot paths
- Cache error handler options for frequently called functions

```lua
-- Cache options for hot path
local updateErrorOptions = {
    onError = function(err)
        Utils.Logger.warn("Update: Frame skipped due to error", err)
    end
}

function update(dt)
    Utils.ErrorHandler.safeCall(updateLogic, updateErrorOptions, dt)
end
```