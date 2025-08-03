# Testing Guide for Orbit Jump

## Overview

Orbit Jump uses a custom test framework that can run tests in two modes:
1. **Standalone Lua** - For pure logic tests
2. **LÖVE2D Context** - For tests requiring graphics, physics, or other LÖVE2D features

## Running Tests

### Quick Start

```bash
# Run all tests (auto-detects LÖVE2D)
./run_tests.sh

# Run specific test suite
./run_tests.sh unit
./run_tests.sh integration
./run_tests.sh performance

# Run with options
./run_tests.sh --filter "player" --coverage
```

### LÖVE2D Test Mode

When LÖVE2D is available, tests automatically run in the LÖVE2D context:

```bash
# Direct LÖVE2D test execution
love . test

# Run specific suite
love . test unit

# With visual mode (shows test progress graphically)
love . test --visual

# Filter tests by name
love . test --filter "render"
```

### Test Runner Options

| Option | Description | Example |
|--------|-------------|---------|
| `--filter` | Run only tests matching pattern | `--filter "player"` |
| `--visual` | Show graphical test progress | `--visual` |
| `--coverage` | Generate coverage report | `--coverage` |
| `--stop-on-failure` | Stop after first failure | `--stop-on-failure` |
| `--no-progress` | Minimal output | `--no-progress` |
| `--time-limit` | Set per-test time limit (seconds) | `--time-limit 10` |

## Writing Tests

### Basic Test Structure

```lua
-- tests/unit/test_my_feature.lua
local TestSuite = {}

-- Optional setup (runs before all tests in suite)
function TestSuite.setup()
    -- Initialize test data
end

-- Test functions
TestSuite["Feature should work correctly"] = function()
    -- Arrange
    local input = 5
    
    -- Act
    local result = myFunction(input)
    
    -- Assert
    TestFramework.assert.equal(result, 10, "Result should be double input")
end

-- Optional teardown (runs after all tests)
function TestSuite.teardown()
    -- Cleanup
end

return TestSuite
```

### Available Assertions

```lua
-- Equality
TestFramework.assert.equal(actual, expected, message)

-- Truthiness
TestFramework.assert.truthy(value, message)
TestFramework.assert.falsy(value, message)

-- Numeric comparison with tolerance
TestFramework.assert.near(actual, expected, epsilon, message)

-- Error checking
TestFramework.assert.throws(function, message)
```

### Testing LÖVE2D Features

Tests can access all LÖVE2D APIs when run in LÖVE2D context:

```lua
TestSuite["Graphics test"] = function()
    -- Create canvas
    local canvas = love.graphics.newCanvas(100, 100)
    TestFramework.assert.truthy(canvas, "Should create canvas")
    
    -- Test rendering
    love.graphics.setCanvas(canvas)
    love.graphics.clear(1, 0, 0, 1) -- Red
    love.graphics.setCanvas()
    
    -- Verify pixel color
    local imageData = canvas:newImageData()
    local r, g, b = imageData:getPixel(50, 50)
    TestFramework.assert.near(r, 1, 0.01, "Should be red")
end
```

### Testing Game Systems

```lua
-- Load game modules
local Utils = require("src.utils.utils")
local PlayerSystem = Utils.require("src.systems.player_system")

TestSuite["Player jump physics"] = function()
    -- Create test player
    local player = {
        x = 100, y = 100,
        vx = 0, vy = 0,
        onPlanet = true
    }
    
    -- Perform jump
    PlayerSystem.jump(player, 45, 500) -- angle, power
    
    -- Verify velocity
    TestFramework.assert.truthy(player.vy < 0, "Should have upward velocity")
    TestFramework.assert.falsy(player.onPlanet, "Should leave planet")
end
```

## Test Organization

### Directory Structure

```
tests/
├── unit/               # Fast, isolated unit tests
│   ├── systems/       # System-specific tests
│   ├── utils/         # Utility tests
│   └── core/          # Core module tests
├── integration/       # Tests requiring multiple systems
├── performance/       # Performance benchmarks
├── fixtures/          # Test data and mocks
└── love2d_test_runner.lua  # LÖVE2D test runner
```

### Naming Conventions

- Test files: `test_<module_name>.lua`
- Test names: Descriptive sentences, e.g., `"Player should jump when spacebar pressed"`
- Use clear arrange-act-assert structure

## Best Practices

### 1. Fast Tests

Keep unit tests fast (< 100ms):
- Mock external dependencies
- Use minimal test data
- Avoid file I/O when possible

### 2. Isolated Tests

Each test should be independent:
- Don't rely on test execution order
- Clean up after each test
- Use setup/teardown for shared state

### 3. Descriptive Failures

Write assertions with clear messages:
```lua
-- Good
TestFramework.assert.equal(player.health, 100, 
    "Player should have full health after respawn")

-- Bad
TestFramework.assert.equal(player.health, 100)
```

### 4. Test Coverage

Aim for coverage targets:
- Critical paths: 90%
- Game systems: 70%
- Utilities: 80%

Use `--coverage` flag to generate reports.

## Continuous Integration

The test runner returns appropriate exit codes:
- 0: All tests passed
- 1: One or more tests failed

This integrates with CI systems:

```yaml
# Example GitHub Actions
- name: Run tests
  run: |
    sudo apt-get install love
    ./run_tests.sh --coverage
```

## Debugging Tests

### Visual Mode

Use `--visual` flag to see test progress graphically:
- Real-time test status
- Failed test details
- Performance metrics

### Interactive Debugging

When a test fails:
1. Run with filter to isolate: `./run_tests.sh --filter "failing test"`
2. Add print statements or use debugger
3. Use `--stop-on-failure` to halt on first error

## Performance Testing

### Writing Performance Tests

```lua
-- tests/performance/test_render_performance.lua
TestSuite["Render 1000 planets"] = function()
    local planets = {}
    for i = 1, 1000 do
        planets[i] = {
            x = math.random(0, 800),
            y = math.random(0, 600),
            radius = 20
        }
    end
    
    local startTime = love.timer.getTime()
    
    for i = 1, 60 do -- 60 frames
        Renderer.drawPlanets(planets)
    end
    
    local duration = love.timer.getTime() - startTime
    local avgFrameTime = duration / 60
    
    TestFramework.assert.truthy(avgFrameTime < 0.016, 
        "Should maintain 60 FPS with 1000 planets")
end
```

### Performance Baselines

Track performance over time:
1. Run performance suite: `./run_tests.sh performance`
2. Save results to track regressions
3. Set thresholds for critical paths

## Troubleshooting

### Common Issues

**Issue**: Tests fail with "module not found"
**Solution**: Ensure proper require paths and run from project root

**Issue**: LÖVE2D features unavailable
**Solution**: Install LÖVE2D or use appropriate test stubs

**Issue**: Tests pass individually but fail together
**Solution**: Check for shared state, add proper cleanup

### Getting Help

1. Check test output for detailed error messages
2. Use `--filter` to isolate problematic tests
3. Review test examples in `tests/unit/test_graphics_features.lua`