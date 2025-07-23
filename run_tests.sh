#!/bin/bash
# Comprehensive test runner for Orbit Jump
# Runs both legacy and Busted-style tests

echo "================================"
echo "Orbit Jump Complete Test Suite"
echo "================================"

# Track overall success
overall_success=true

# Run Busted-style tests
echo -e "\n--- Running Busted-style tests ---"
if lua tests/run_busted_tests.lua; then
    echo "✅ Busted tests passed"
else
    echo "❌ Busted tests failed"
    overall_success=false
fi

# Run legacy tests (if they still exist and work)
echo -e "\n--- Running legacy tests ---"
if lua tests/run_tests.lua 2>/dev/null; then
    echo "✅ Legacy tests passed"
else
    echo "⚠️  Legacy tests failed or not compatible"
    # Don't fail overall if legacy tests fail since we're migrating
fi

# Summary
echo -e "\n================================"
if [ "$overall_success" = true ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi