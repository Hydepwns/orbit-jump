# Testing

Orbit Jump uses a unified testing framework for all test types.

## Quick Start

```bash
# Run all tests
./run_tests.sh

# Run specific test types
./run_tests.sh unit
./run_tests.sh integration
./run_tests.sh performance

# Interactive runner
lua tests/run_interactive_tests.lua
```

## Test Framework

```lua
local TestFramework = require("tests.frameworks.unified_test_framework")
TestFramework.init()

-- Basic assertions
TestFramework.assert.equal(expected, actual)
TestFramework.assert.isTrue(condition)
TestFramework.assert.isFalse(condition)
TestFramework.assert.isNil(value)
TestFramework.assert.notNil(value)

-- Advanced assertions
TestFramework.assert.near(expected, actual, tolerance)
TestFramework.assert.matches(string, pattern)
TestFramework.assert.contains(table, element)
TestFramework.assert.isEmpty(table)

-- Test decorators
TestFramework.beforeEach(function() end)
TestFramework.afterEach(function() end)

-- Spies for mocking
local spy = TestFramework.spy(originalFunction)
```

## Test Structure

```
tests/
├── frameworks/              # Test framework
├── unit/                   # Unit tests
├── integration/            # Integration tests
├── performance/            # Performance tests
└── fixtures/               # Test data
```

## Writing Tests

```lua
local TestFramework = require("tests.frameworks.unified_test_framework")
TestFramework.init()

local tests = {
    ["test name"] = function()
        TestFramework.assert.equal(expected, actual)
    end
}

TestFramework.runTests(tests, "Test Suite Name")
```

## Error Reporting

```lua
local EnhancedErrorReporter = require("tests.frameworks.enhanced_error_reporter")

EnhancedErrorReporter.addError("RUNTIME", "Error message", "Details")
EnhancedErrorReporter.showFullReport()
```
