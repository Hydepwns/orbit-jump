# Test Suite

Unified test framework for Orbit Jump.

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

## Structure

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

## Framework

- `unified_test_framework.lua`: Main test framework
- `enhanced_error_reporter.lua`: Error reporting system
- `interactive_test_runner.lua`: Interactive test runner
