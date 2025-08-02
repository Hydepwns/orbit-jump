#!/bin/bash

# Orbit Jump Optimized Test Suite - Phase 4
# Enhanced test runner with parallel execution, caching, and selective running

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values
TEST_TYPE="all"
VERBOSE=false
QUICK=false
PARALLEL=true
CACHE=true
SELECTIVE=true
WORKERS=4
WATCH=false
CLEAR_CACHE=false
SHOW_CACHE=false

# Help function
show_help() {
    echo -e "${CYAN}Orbit Jump Optimized Test Suite (Phase 4)${NC}"
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
    echo "  -h, --help           Show this help message"
    echo "  -v, --verbose        Verbose output"
    echo "  -q, --quick          Quick mode (skip slow tests)"
    echo "  -p, --parallel       Enable parallel execution (default: true)"
    echo "  -s, --sequential     Disable parallel execution"
    echo "  -c, --cache          Enable test caching (default: true)"
    echo "  -n, --no-cache       Disable test caching"
    echo "  -w, --workers N      Set number of parallel workers (default: 4)"
    echo "  -t, --selective      Enable selective test running (default: true)"
    echo "  -a, --all-tests      Run all tests (disable selective)"
    echo "  --watch              Watch mode - rerun tests on file changes"
    echo "  --clear-cache        Clear test cache before running"
    echo "  --show-cache         Show cache statistics"
    echo ""
    echo "Examples:"
    echo "  $0                           # Run all tests with optimizations"
    echo "  $0 unit                      # Run unit tests only"
    echo "  $0 integration -v            # Run integration tests with verbose output"
    echo "  $0 performance -q            # Run performance tests in quick mode"
    echo "  $0 unit -s -n                # Run unit tests sequentially without caching"
    echo "  $0 --watch                   # Watch mode for development"
    echo "  $0 --clear-cache             # Clear cache and run all tests"
    echo "  $0 --show-cache              # Show cache statistics"
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
        -p|--parallel)
            PARALLEL=true
            shift
            ;;
        -s|--sequential)
            PARALLEL=false
            shift
            ;;
        -c|--cache)
            CACHE=true
            shift
            ;;
        -n|--no-cache)
            CACHE=false
            shift
            ;;
        -w|--workers)
            WORKERS="$2"
            shift 2
            ;;
        -t|--selective)
            SELECTIVE=true
            shift
            ;;
        -a|--all-tests)
            SELECTIVE=false
            shift
            ;;
        --watch)
            WATCH=true
            shift
            ;;
        --clear-cache)
            CLEAR_CACHE=true
            shift
            ;;
        --show-cache)
            SHOW_CACHE=true
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

# Function to run tests with optimized runner
run_optimized_tests() {
    local test_type="$1"
    local options="$2"
    
    echo -e "${BLUE}Running optimized tests for: $test_type${NC}"
    
    # Build Lua options string
    local lua_options="{"
    lua_options="${lua_options}enable_parallel = $PARALLEL,"
    lua_options="${lua_options}enable_caching = $CACHE,"
    lua_options="${lua_options}enable_selective = $SELECTIVE,"
    lua_options="${lua_options}parallel_workers = $WORKERS,"
    lua_options="${lua_options}verbose = $VERBOSE,"
    lua_options="${lua_options}quick_mode = $QUICK"
    lua_options="${lua_options}}"
    
    # Run the optimized test runner
    lua -e "
        local runner = require('tests.frameworks.optimized_test_runner')
        local success = runner.run('$test_type', $lua_options)
        os.exit(success and 0 or 1)
    "
}

# Function to watch for file changes
watch_tests() {
    echo -e "${CYAN}Watch mode enabled - monitoring for file changes...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop watching${NC}"
    echo ""
    
    local last_run=0
    local check_interval=2
    
    while true; do
        local current_time=$(date +%s)
        
        # Check if any test files have changed
        local changed_files=$(find tests/ -name "*.lua" -newermt "@$last_run" 2>/dev/null | wc -l)
        
        if [ "$changed_files" -gt 0 ]; then
            echo -e "${GREEN}File changes detected! Running tests...${NC}"
            echo ""
            
            run_optimized_tests "$TEST_TYPE"
            
            last_run=$current_time
            echo ""
            echo -e "${CYAN}Watching for changes... (Press Ctrl+C to stop)${NC}"
        fi
        
        sleep $check_interval
    done
}

# Function to clear cache
clear_test_cache() {
    echo -e "${YELLOW}Clearing test cache...${NC}"
    lua -e "
        local runner = require('tests.frameworks.optimized_test_runner')
        runner.clear_cache()
    "
    echo -e "${GREEN}Cache cleared!${NC}"
}

# Function to show cache statistics
show_cache_stats() {
    echo -e "${CYAN}Cache Statistics:${NC}"
    lua -e "
        local runner = require('tests.frameworks.optimized_test_runner')
        runner.show_cache_stats()
    "
}

# Main execution
echo -e "${CYAN}=== Orbit Jump Optimized Test Suite (Phase 4) ===${NC}"
echo -e "${BLUE}Test type: $TEST_TYPE${NC}"
echo -e "${BLUE}Parallel execution: $PARALLEL${NC}"
echo -e "${BLUE}Caching: $CACHE${NC}"
echo -e "${BLUE}Selective running: $SELECTIVE${NC}"
echo -e "${BLUE}Workers: $WORKERS${NC}"
echo -e "${BLUE}Verbose: $VERBOSE${NC}"
echo -e "${BLUE}Quick mode: $QUICK${NC}"
echo -e "${BLUE}Watch mode: $WATCH${NC}"
echo ""

# Change to the project root directory
cd "$(dirname "$0")/.."

# Handle special commands
if [ "$SHOW_CACHE" = true ]; then
    show_cache_stats
    exit 0
fi

if [ "$CLEAR_CACHE" = true ]; then
    clear_test_cache
    echo ""
fi

# Run tests
if [ "$WATCH" = true ]; then
    watch_tests
else
    run_optimized_tests "$TEST_TYPE"
fi

echo ""
echo -e "${GREEN}Test execution completed!${NC}" 