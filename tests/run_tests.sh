#!/bin/bash

# Orbit Jump Test Suite - Main Entry Point
# This script provides a unified interface for running all test types

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TEST_TYPE="all"
VERBOSE=false
QUICK=false

# Help function
show_help() {
    echo "Orbit Jump Test Suite"
    echo ""
    echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
    echo ""
    echo "TEST_TYPE:"
    echo "  all          Run all tests (default)"
    echo "  unit         Run unit tests only"
    echo "  integration  Run integration tests only"
    echo "  performance  Run performance tests only"
    echo ""
    echo "OPTIONS:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Verbose output"
    echo "  -q, --quick    Quick mode (skip slow tests)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 unit              # Run unit tests only"
    echo "  $0 integration -v    # Run integration tests with verbose output"
    echo "  $0 performance -q    # Run performance tests in quick mode"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -q|--quick)
            QUICK=true
            shift
            ;;
        unit|integration|performance|all)
            TEST_TYPE="$1"
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Function to run tests with timing
run_test_suite() {
    local suite_name="$1"
    local runner_script="$2"
    local start_time=$(date +%s.%N)
    
    echo -e "${BLUE}Running $suite_name tests...${NC}"
    
    if [ "$VERBOSE" = true ]; then
        lua "$runner_script"
    else
        lua "$runner_script" 2>/dev/null || lua "$runner_script"
    fi
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l)
    echo -e "${GREEN}✓ $suite_name tests completed in ${duration}s${NC}"
}

# Main execution
echo -e "${BLUE}=== Orbit Jump Test Suite ===${NC}"
echo "Test type: $TEST_TYPE"
echo "Verbose: $VERBOSE"
echo "Quick mode: $QUICK"
echo ""

# Change to the tests directory
cd "$(dirname "$0")"

# Run tests based on type
case $TEST_TYPE in
    "unit")
        run_test_suite "Unit" "frameworks/run_unit_tests.lua"
        ;;
    "integration")
        run_test_suite "Integration" "frameworks/run_integration_tests.lua"
        ;;
    "performance")
        run_test_suite "Performance" "frameworks/run_performance_tests.lua"
        ;;
    "all")
        echo -e "${YELLOW}Running complete test suite...${NC}"
        echo ""
        
        run_test_suite "Unit" "frameworks/run_unit_tests.lua"
        echo ""
        
        run_test_suite "Integration" "frameworks/run_integration_tests.lua"
        echo ""
        
        run_test_suite "Performance" "frameworks/run_performance_tests.lua"
        echo ""
        
        echo -e "${GREEN}=== All test suites completed successfully! ===${NC}"
        ;;
    *)
        echo -e "${RED}Error: Unknown test type '$TEST_TYPE'${NC}"
        show_help
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Test execution completed!${NC}" 