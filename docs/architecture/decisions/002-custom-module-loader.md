# ADR-002: Custom Module Loader with Caching

## Status
Accepted

## Context
The standard Lua `require()` function has limitations:
- No built-in error handling
- No logging of load failures
- Modules can be loaded multiple times
- No support for hot reloading
- Difficult to track dependencies

## Decision
We will use `Utils.require()` as the standard module loader throughout the codebase. This custom loader provides:
- Module caching to prevent duplicate loads
- Error handling with graceful fallbacks
- Logging of module load attempts and failures
- Foundation for future hot-reload capability
- Consistent module path resolution

## Consequences

### Positive
- Prevents duplicate module loading (performance win)
- Easier debugging with load failure logs
- Consistent error handling across codebase
- Enables future enhancements (hot reload, dependency tracking)
- Reduced memory usage from module caching

### Negative
- One more layer of indirection
- Developers must remember to use Utils.require
- Slightly different from standard Lua practices

### Neutral
- Need to migrate existing require() calls
- Documentation needed for new developers

## Implementation
```lua
-- Always use
local Module = Utils.require("src.category.module")

-- Never use
local Module = require("src/category/module")
```

## Migration
1. Search for all `require(` calls
2. Replace with `Utils.require(`
3. Convert paths to dot notation
4. Test module loading