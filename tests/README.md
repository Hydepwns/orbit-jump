# Orbit Jump Test Suite

This directory contains the comprehensive test suite for Orbit Jump, organized by test type and purpose.

## Test Structure

```
tests/
├── README.md                    # This file
├── run_tests.sh                 # Main test runner (runs all test types)
├── run_busted_tests.lua         # Fast unit tests using Busted-style framework
├── run_unit_tests.lua           # Comprehensive unit tests using new framework
├── run_tests.lua                # Legacy tests (being phased out)
├── modern_test_framework.lua    # New test framework with advanced features
├── mocks.lua                    # Comprehensive mocking system
├── test_framework.lua           # Legacy test framework
├── mocks.lua                    # Legacy mocks
├── unit/                        # Unit tests (isolated, fast)
│   ├── game_logic_tests.lua
│   ├── renderer_tests.lua
│   ├── save_system_tests.lua
│   ├── utils_tests.lua
│   ├── camera_tests.lua
│   └── collision_tests.lua
├── ui/                          # UI and interface tests
│   ├── layout/                  # UI layout and positioning tests
│   │   ├── ui_layout_tests.lua          # Basic layout validation
│   │   ├── ui_layout_tests_enhanced.lua # Advanced testing framework
│   │   └── README.md                    # Layout testing documentation
│   ├── test_ui_system.lua
│   ├── test_pause_menu.lua
│   ├── test_settings_menu.lua
│   ├── test_tutorial_system.lua
│   ├── test_upgrade_system.lua
│   └── test_achievement_system.lua
├── integration/                 # Integration tests (end-to-end flows)
│   └── (future integration tests)
└── performance/                 # Performance and benchmark tests
    └── (future performance tests)
```

## Test Types

### 1. **Unit Tests** (`tests/unit/`)

- **Purpose**: Test individual functions and modules in isolation
- **Framework**: Custom modern framework with comprehensive mocking
- **Speed**: Fast (milliseconds per test)
- **Coverage**: Deep coverage of edge cases and error conditions
- **Dependencies**: Fully mocked external dependencies

**Features:**

- Call tracking and verification
- Comprehensive assertion library
- Performance benchmarking
- Test decorators (beforeEach, afterEach, skip)
- Detailed error reporting

### 2. **Busted Tests** (`tests/run_busted_tests.lua`)

- **Purpose**: Fast unit tests using Busted-style syntax
- **Framework**: Lightweight Busted-compatible framework
- **Speed**: Very fast
- **Coverage**: Basic functionality testing
- **Dependencies**: Minimal mocking

### 3. **Legacy Tests** (`tests/run_tests.lua`)

- **Purpose**: Original test suite (being phased out)
- **Framework**: Custom legacy framework
- **Status**: Deprecated, maintained for compatibility
- **Dependencies**: Some external dependencies

### 4. **Integration Tests** (`tests/integration/`)

- **Purpose**: Test complete game flows and system interactions
- **Status**: Planned for future development
- **Scope**: End-to-end game scenarios

### 5. **Performance Tests** (`tests/performance/`)

- **Purpose**: Benchmark critical game systems
- **Status**: Planned for future development
- **Scope**: Frame rate, memory usage, load times

## Running Tests

### Run All Tests

```bash
./run_tests.sh
```

### Run Specific Test Types

```bash
# Unit tests only
lua tests/run_unit_tests.lua

# Busted tests only
lua tests/run_busted_tests.lua

# Legacy tests only
lua tests/run_tests.lua
```

## Test Framework Comparison

| Feature | Unit Tests | Busted Tests | Legacy Tests |
|---------|------------|--------------|--------------|
| **Speed** | Fast | Very Fast | Medium |
| **Mocking** | Comprehensive | Basic | Limited |
| **Assertions** | Rich library | Basic | Basic |
| **Call Tracking** | ✅ Yes | ❌ No | ❌ No |
| **Performance Testing** | ✅ Yes | ❌ No | ❌ No |
| **Error Reporting** | Detailed | Basic | Basic |
| **Test Decorators** | ✅ Yes | ❌ No | ❌ No |
| **Maintenance** | Active | Active | Deprecated |

## Migration Strategy

### Current State

- **Unit Tests**: Primary test suite (comprehensive, well-maintained)
- **Busted Tests**: Fast feedback tests (complementary)
- **Legacy Tests**: Deprecated (maintained for compatibility)

### Future Plan

1. **Phase 1**: ✅ Complete unit test coverage
2. **Phase 2**: Add integration tests for game flows
3. **Phase 3**: Add performance benchmarks
4. **Phase 4**: Remove legacy tests when no longer needed

## Why This Structure?

### **Not "Modern" vs "Old"**

The tests aren't "modern" vs "legacy" - they serve different purposes:

- **Unit Tests**: Deep, isolated testing with comprehensive mocking
- **Busted Tests**: Fast feedback during development
- **Legacy Tests**: Compatibility during transition

### **Complementary, Not Replacement**

Each test type serves a specific purpose:

- **Unit Tests**: Catch bugs in individual functions
- **Busted Tests**: Quick feedback during development
- **Integration Tests**: Catch bugs in system interactions
- **Performance Tests**: Catch performance regressions

### **Clear Organization**

- `unit/`: Isolated function testing
- `integration/`: System interaction testing
- `performance/`: Benchmark testing

## Best Practices

### Writing Unit Tests

```lua
-- Use descriptive test names
["should calculate distance correctly"] = function()
    local distance = Utils.distance(0, 0, 3, 4)
    ModernTestFramework.assert.equal(5, distance)
end

-- Test edge cases
["should handle nil inputs gracefully"] = function()
    local distance = Utils.distance(nil, 0, 3, 4)
    ModernTestFramework.assert.equal(0, distance)
end

-- Use call tracking for verification
["should call graphics functions"] = function()
    ModernTestFramework.utils.resetCalls()
    Renderer.drawPlayer(player)
    ModernTestFramework.assert.calledAtLeast("setColor", 1)
end
```

### Test Organization

- Group related tests together
- Use descriptive test names
- Test both success and failure cases
- Test edge cases and error conditions
- Keep tests independent and fast

## Contributing

When adding new tests:

1. **Unit Tests**: Add to `tests/unit/` for isolated function testing
2. **Integration Tests**: Add to `tests/integration/` for system testing
3. **Performance Tests**: Add to `tests/performance/` for benchmarks
4. **Update Documentation**: Keep this README current

## Test Coverage Goals

- **Unit Tests**: >80% function coverage
- **Integration Tests**: >70% game flow coverage
- **Performance Tests**: Critical path benchmarks
- **Overall**: >90% combined coverage
