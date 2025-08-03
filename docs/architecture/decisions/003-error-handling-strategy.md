# ADR-003: Standardized Error Handling with ErrorHandler

## Status
Accepted

## Context
The codebase had inconsistent error handling:
- Direct `pcall()` usage without logging
- No error handling in many places
- Inconsistent error recovery strategies
- Poor error visibility in production

## Decision
Standardize on `Utils.ErrorHandler.safeCall()` for all error-prone operations:

```lua
local result = Utils.ErrorHandler.safeCall(riskyFunction, {
    onError = function(err)
        Utils.Logger.error("Context: Operation failed", err)
    end,
    fallback = defaultValue
})
```

Different strategies by system type:
- **Core Systems**: Log and attempt recovery
- **Game Systems**: Degrade gracefully
- **UI Systems**: Use fallback rendering
- **Utilities**: Return sensible defaults

## Consequences

### Positive
- Consistent error handling across codebase
- All errors are logged for debugging
- Graceful degradation instead of crashes
- Better player experience
- Easier to track down issues in production

### Negative
- Slight performance overhead (minimal)
- More verbose than direct calls
- Developers must understand the pattern

### Neutral
- Requires migration from existing pcall usage
- Need to define appropriate fallbacks

## Implementation Guidelines

### Critical Systems
```lua
-- Must attempt recovery
local initialized = Utils.ErrorHandler.safeCall(function()
    return system.init()
end, {
    onError = function(err)
        Utils.Logger.error("System: Init failed", err)
        attemptRecovery()
    end,
    fallback = false
})
```

### Game Features
```lua
-- Disable feature on error
Utils.ErrorHandler.safeCall(function()
    complexFeature.update(dt)
end, {
    onError = function(err)
        Utils.Logger.warn("Feature disabled due to error", err)
        complexFeature.enabled = false
    end
})
```

### UI Rendering
```lua
-- Fallback UI on error
Utils.ErrorHandler.safeCall(renderComplexUI, {
    onError = function(err)
        Utils.Logger.warn("UI render failed", err)
        renderSimpleUI()
    end
})
```