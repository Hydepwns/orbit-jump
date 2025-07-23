# Orbit Jump Test Suite

This directory contains the comprehensive test suite for Orbit Jump, featuring a custom Busted-style test framework.

## Test Framework

We use a custom implementation of Busted-style syntax (`tests/busted.lua`) that provides:

- **BDD-style syntax**: `describe`, `it`, `before_each`, `after_each`
- **Rich assertions**: `assert.equals`, `assert.is_true`, `assert.is_false`, `assert.is_nil`, `assert.are_same`
- **Spy/Mock support**: `spy()` for function mocking and call tracking
- **Colored output**: Green for passing tests, red for failures
- **Detailed error reporting**: Shows exact assertion failures with expected vs actual values

## Running Tests

### Run all tests
```bash
./run_tests.sh
```

### Run only Busted-style tests
```bash
lua tests/run_busted_tests.lua
```

### Run legacy tests (if available)
```bash
lua tests/run_tests.lua
```

## Writing Tests

### Basic Test Structure

```lua
require("tests.busted")
local MyModule = require("src.my_module")

describe("MyModule", function()
    describe("functionality group", function()
        local testData
        
        before_each(function()
            -- Setup before each test
            testData = {value = 42}
        end)
        
        after_each(function()
            -- Cleanup after each test
            testData = nil
        end)
        
        it("should do something", function()
            local result = MyModule.doSomething(testData.value)
            assert.equals(84, result)
        end)
        
        it("should handle edge cases", function()
            assert.has_error(function()
                MyModule.doSomething(nil)
            end)
        end)
    end)
end)
```

### Available Assertions

- `assert.equals(expected, actual, [message])` - Check equality
- `assert.is_true(value, [message])` - Check if value is true
- `assert.is_false(value, [message])` - Check if value is false
- `assert.is_nil(value, [message])` - Check if value is nil
- `assert.is_not_nil(value, [message])` - Check if value is not nil
- `assert.has_error(fn, [message])` - Check if function throws error
- `assert.are_same(expected, actual, [message])` - Deep table comparison

### Using Spies

```lua
it("should call callback", function()
    local callback = spy()
    
    MyModule.processWithCallback(callback)
    
    assert.equals(1, callback.callCount())
    assert.equals("expected_arg", callback.calls[1][1])
end)
```

## Test Organization

Tests are organized by module type:

- `core/` - Core game systems (game logic, state, rendering)
- `systems/` - Game systems (collision, particles, progression)
- `utils/` - Utility modules
- `audio/` - Audio system tests
- `ui/` - User interface tests
- `world/` - World generation tests
- `performance/` - Performance monitoring tests
- `blockchain/` - Blockchain integration tests
- `integration_tests/` - Full integration tests

## Converting Legacy Tests

To convert a legacy test to Busted format:

```bash
lua tests/convert_to_busted.lua tests/old_test.lua tests/new_test_busted.lua
```

## Mocking

Some tests require mocking Love2D functions. Configure mocks in test runner:

```lua
local testFiles = {
    {file = "tests/core/test_game_logic_busted.lua", useMocks = false},
    {file = "tests/ui/test_ui_system_busted.lua", useMocks = true},
}
```

## CI/CD Integration

The test suite is automatically run on GitHub Actions for every push and pull request. See `.github/workflows/test.yml` for configuration.