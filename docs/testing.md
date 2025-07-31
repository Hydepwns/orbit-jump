# Testing

Orbit Jump has comprehensive test coverage with multiple testing frameworks and approaches.

## Test Overview

- **179+ tests** with 100% pass rate
- **Enhanced Busted framework** with 26+ assertion types
- **Unit, integration, and performance tests**
- **Automated CI/CD pipeline**

## Running Tests

### All Tests

```bash
# Run complete modern test suite
lua tests/run_modern_tests.lua

# Run integration tests
lua tests/run_integration_tests.lua

# Run final integration tests for refactored systems
lua tests/final_integration_test.lua
```

### Specific System Tests

```bash
# Warp system tests
lua tests/systems/warp/test_warp_core_busted.lua
lua tests/systems/warp/test_warp_energy_busted.lua

# Player system tests  
lua tests/systems/player/test_player_movement_busted.lua
lua tests/systems/player/test_player_abilities_busted.lua

# Analytics tests
lua tests/systems/analytics/test_behavior_tracker_busted.lua
lua tests/systems/analytics/test_pattern_analyzer_busted.lua

# Emotion system tests
lua tests/systems/emotion/test_emotion_core_busted.lua
lua tests/systems/emotion/test_feedback_renderer_busted.lua
```

### Legacy Tests

```bash
# Run original test suite
bash run_tests.sh
```

## Test Framework

### Enhanced Busted Framework

Custom testing framework with advanced features:

```lua
local TestFramework = require("tests.modern_test_framework")
TestFramework.init()

-- Rich assertion library
TestFramework.assert.assertEqual(actual, expected)
TestFramework.assert.near(actual, expected, tolerance)
TestFramework.assert.contains(array, element)
TestFramework.assert.matches(string, pattern)
TestFramework.assert.isEmpty(table)
TestFramework.assert.hasError(function)
```

### Test Structure

```text
tests/
├── modern_test_framework.lua    # Enhanced testing framework
├── run_modern_tests.lua         # Modern test runner
├── run_integration_tests.lua    # Integration test runner
├── final_integration_test.lua   # Refactored systems integration
├── systems/                     # System-specific tests
│   ├── warp/                   # Warp drive tests
│   ├── analytics/              # Analytics tests
│   ├── emotion/                # Emotional feedback tests
│   └── player/                 # Player system tests
├── core/                       # Core game logic tests
├── utils/                      # Utility function tests
└── integration_tests/          # Cross-system integration tests
```

## Writing Tests

### Basic Test Structure

```lua
package.path = package.path .. ";../../?.lua"

local Utils = require("src.utils.utils")
local TestFramework = Utils.require("tests.modern_test_framework")

-- Initialize framework
TestFramework.init()

-- Define tests
local tests = {
    ["test name"] = function()
        -- Test implementation
        local result = someFunction(input)
        TestFramework.assert.assertEqual(expected, result)
    end
}

-- Run tests
local success = TestFramework.runTests(tests, "Test Suite Name")
return success
```

### Mocking

```lua
local Mocks = Utils.require("tests.mocks")

-- Setup mocks
Mocks.setup()

-- Create mock objects
local mockPlayer = Mocks.patterns.entity(x, y, radius)

-- Track function calls
Mocks.trackCall("FunctionName", arg1, arg2)
```

### Performance Testing

```lua
-- Time operations
local start = os.clock()
someExpensiveOperation()
local duration = os.clock() - start

TestFramework.assert.assertTrue(duration < 0.1, "Operation too slow")
```

## Test Categories

### Unit Tests

- **Scope**: Individual functions and modules
- **Coverage**: All public APIs and edge cases
- **Location**: `tests/systems/`, `tests/core/`, `tests/utils/`

### Integration Tests

- **Scope**: System interactions and workflows
- **Coverage**: Cross-system communication and data flow
- **Location**: `tests/integration_tests/`, `tests/final_integration_test.lua`

### Performance Tests

- **Scope**: Performance requirements and optimizations
- **Coverage**: Memory usage, execution time, GC impact
- **Location**: Embedded in system tests

## CI/CD Integration

Tests run automatically on:

- **Every push** to main/develop branches
- **Pull requests**
- **Release builds**

### GitHub Actions Workflow

```yaml
# Quality gates
- Code quality checks
- File structure verification

# Unit tests
- Modern test framework
- Enhanced Busted tests
- Individual module tests

# Integration tests
- System integration
- Game loading tests

# Performance tests
- Benchmark validation
- Memory usage checks
```

## Debugging Tests

### Verbose Output

```lua
-- Enable detailed test output
TestFramework.setVerbose(true)

-- Add debug prints
print("Debug: variable =", variable)
```

### Selective Test Running

```lua
-- Run specific test
local tests = {
    ["specific test only"] = function()
        -- Your test here
    end
}
```

### Test Isolation

```lua
-- Clear state between tests
Utils.clearModuleCache()

-- Reset mock state
Mocks.reset()
```
