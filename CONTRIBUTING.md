# Contributing to Orbit Jump

Thank you for your interest in contributing to Orbit Jump! This document provides guidelines and standards for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Architecture Guidelines](#architecture-guidelines)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Performance Considerations](#performance-considerations)

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to create a welcoming environment for all contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/orbit-jump.git`
3. Install LÖVE2D (version 11.0+)
4. Run the game: `love .`

## Development Setup

### Prerequisites

- LÖVE2D 11.0 or higher
- Lua 5.1+ (included with LÖVE2D)
- Git
- A text editor with Lua support (VSCode recommended)

### Recommended Tools

- **Linter**: luacheck (configuration in `.luacheckrc`)
- **Formatter**: lua-fmt or stylua
- **Debugger**: ZeroBrane Studio or VSCode with Lua extensions

## Coding Standards

### Lua Style Guide

1. **Naming Conventions**
   - Classes/Modules: PascalCase (e.g., `PlayerSystem`)
   - Functions: camelCase (e.g., `updatePosition`)
   - Constants: UPPER_SNAKE_CASE (e.g., `MAX_SPEED`)
   - Private members: prefix with underscore (e.g., `_privateMethod`)

2. **Indentation**
   - Use 4 spaces (no tabs)
   - Align continuation lines with opening delimiter

3. **Comments**
   - Use `--` for single-line comments
   - Use `--[[...--]]` for multi-line comments
   - Document complex functions with purpose, parameters, and return values

4. **Module Structure**
   ```lua
   -- Module header comment
   local Utils = require("src.utils.utils")
   
   local ModuleName = {}
   
   -- Constants
   ModuleName.CONSTANT = 100
   
   -- Private variables
   local privateVar = 0
   
   -- Public functions
   function ModuleName.publicFunction()
       -- Implementation
   end
   
   -- Private functions
   local function privateFunction()
       -- Implementation
   end
   
   return ModuleName
   ```

### Error Handling

Always use the standardized error handling pattern:

```lua
local result = Utils.ErrorHandler.safeCall(riskyFunction, {
    onError = function(err)
        Utils.Logger.error("ModuleName: Operation failed", err)
    end,
    fallback = defaultValue
})
```

See `docs/ERROR_HANDLING_STANDARD.md` for detailed guidelines.

### Memory Management

1. **Prevent Memory Leaks**
   - Limit table sizes (implement bounds checking)
   - Use object pools for frequently created/destroyed objects
   - Clean up event listeners and references

2. **Example Pattern**
   ```lua
   local MAX_ENTRIES = 100
   if #myTable > MAX_ENTRIES then
       -- Remove oldest entries
       for i = 1, #myTable - MAX_ENTRIES do
           table.remove(myTable, 1)
       end
   end
   ```

## Architecture Guidelines

### Module Organization

1. **Core Systems** (`src/core/`)
   - Game loop, state management, rendering
   - Must be highly stable and performant

2. **Game Systems** (`src/systems/`)
   - Gameplay mechanics, features
   - Use facade pattern for complex systems

3. **UI Systems** (`src/ui/`)
   - User interface components
   - Separate logic from rendering

4. **Utilities** (`src/utils/`)
   - Shared functionality
   - Must be stateless when possible

### Facade Pattern

For complex systems, use a facade:

```lua
-- Main facade file: src/systems/complex_system.lua
local ComplexSystem = {}

-- Delegate to submodules
local SubModule1 = require("src.systems.complex/sub_module1")
local SubModule2 = require("src.systems.complex/sub_module2")

function ComplexSystem.init()
    SubModule1.init()
    SubModule2.init()
end

return ComplexSystem
```

### Dependency Management

- Use `Utils.require()` for consistent module loading
- Avoid circular dependencies
- Prefer dependency injection over global access

## Testing

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Run specific test suite
./run_tests.sh unit

# Run with coverage
./run_tests.sh --coverage
```

### Writing Tests

1. Place tests in appropriate directory:
   - Unit tests: `tests/unit/`
   - Integration tests: `tests/integration/`
   - Performance tests: `tests/performance/`

2. Test file naming: `test_<module_name>.lua`

3. Test structure:
   ```lua
   local TestFramework = require("tests.test_framework")
   
   return {
       ["Should do something"] = function()
           -- Arrange
           local input = 5
           
           -- Act
           local result = myFunction(input)
           
           -- Assert
           TestFramework.assert.equal(result, 10)
       end
   }
   ```

## Submitting Changes

### Pull Request Process

1. **Before Starting**
   - Check existing issues/PRs
   - Discuss major changes in an issue first

2. **Branch Naming**
   - Feature: `feature/description`
   - Bug fix: `fix/description`
   - Refactor: `refactor/description`

3. **Commit Messages**
   - Use conventional commits format
   - Examples:
     - `feat: add warp drive cooldown`
     - `fix: memory leak in particle system`
     - `docs: update API documentation`
     - `perf: optimize collision detection`

4. **PR Requirements**
   - Update relevant documentation
   - Add/update tests
   - Ensure all tests pass
   - Run linter: `luacheck .`
   - Update CHANGELOG.md if applicable

### Code Review Checklist

- [ ] Follows coding standards
- [ ] Includes appropriate tests
- [ ] Documentation updated
- [ ] No memory leaks introduced
- [ ] Performance impact considered
- [ ] Error handling implemented
- [ ] Backwards compatibility maintained

## Performance Considerations

### Guidelines

1. **Profile Before Optimizing**
   - Use the in-game performance monitor
   - Measure actual impact

2. **Common Optimizations**
   - Cache frequently accessed values
   - Use object pools
   - Minimize table allocations in hot paths
   - Batch rendering operations

3. **Mobile Performance**
   - Test on lower-end devices
   - Consider battery impact
   - Optimize texture usage

### Performance Targets

- Maintain 60 FPS on target hardware
- Frame time budget: 16.67ms
  - Update: 8ms
  - Render: 8ms
- Memory usage < 100MB
- Load time < 2 seconds

## Deprecation Process

When deprecating code:

1. Mark file with `DEPRECATED_` prefix
2. Add deprecation notice in code
3. Update all imports
4. Document in CHANGELOG
5. Remove after 2 release cycles

## Questions?

- Open an issue for bugs/features
- Start a discussion for questions
- Check existing documentation in `docs/`

Thank you for contributing to Orbit Jump! 🚀