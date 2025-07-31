# UI Layout Tests

This directory contains comprehensive tests for UI layout and positioning functionality in Orbit Jump.

## Files

- **`ui_layout_tests.lua`** - Basic UI layout testing suite
  - Element positioning validation
  - Screen size adaptation tests
  - Basic responsiveness checks
  
- **`ui_layout_tests_enhanced.lua`** - Advanced testing framework
  - Performance benchmarking
  - Accessibility compliance validation
  - Multi-device simulation
  - CI/CD integration support
  - Automated regression testing

## Running Tests

### Unified Test Runner

```bash
# From project root - comprehensive tests (default)
lua tests/ui/layout/run_tests.lua

# Quick validation tests
lua tests/ui/layout/run_tests.lua quick

# Performance tests only
lua tests/ui/layout/run_tests.lua performance

# With verbose output
lua tests/ui/layout/run_tests.lua --verbose comprehensive

# JSON output for CI/CD
lua tests/ui/layout/run_tests.lua --json

# Run with CI/CD integration
./scripts/ui_test_runner.sh comprehensive
```

### Advanced Options

```bash
# Strict mode (warnings as errors)
lua tests/ui/layout/run_tests.lua --strict

# Skip performance tests
lua tests/ui/layout/run_tests.lua --no-performance

# Update performance baselines
lua tests/ui/layout/run_tests.lua --baseline

# Show help
lua tests/ui/layout/run_tests.lua --help
```

## Test Coverage

- ✅ Element positioning accuracy
- ✅ Screen size responsiveness  
- ✅ Mobile device compatibility
- ✅ Performance benchmarking
- ✅ Accessibility compliance
- ✅ Memory usage validation
- ✅ Regression detection

## Dependencies

- `src.ui.ui_system` - Main UI system
- `src.ui.debug.ui_debug_enhanced` - Advanced debugging tools
- `src.utils.utils` - Utility functions

## Integration

These tests are integrated with:
- Unified test runner (`tests/ui/layout/run_tests.lua`)
- CI/CD pipeline (`scripts/ui_test_runner.sh`)
- Development debugging tools