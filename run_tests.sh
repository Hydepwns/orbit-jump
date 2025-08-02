#!/bin/bash
# Streamlined Test Runner for Orbit Jump
# Uses the new unified test framework for faster, more organized testing

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
TEST_OUTPUT_DIR="$PROJECT_ROOT/test-results"
REPORTS_DIR="$PROJECT_ROOT/reports"

# Test configuration
DEFAULT_TEST_SUITE="all"
DEFAULT_LOG_LEVEL="INFO"
DEFAULT_TIMEOUT="60" # 1 minute
PERFORMANCE_THRESHOLD="5.0" # 5% performance regression threshold

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage information
show_usage() {
    cat << EOF
Streamlined Test Runner for Orbit Jump

USAGE:
    $0 [OPTIONS] [TEST_SUITE]

OPTIONS:
    --unit-only        Run only unit tests (fastest)
    --integration-only Run only integration tests
    --performance-only Run only performance tests
    --ui-only          Run only UI tests
    --parallel         Run tests in parallel (experimental)
    --verbose, -v      Enable verbose output
    --filter <pattern> Filter tests by name pattern
    --timeout <seconds> Set test timeout (default: 60)
    --watch            Watch mode - rerun tests on file changes
    --coverage         Generate coverage report
    --help, -h         Show this help message

TEST_SUITES:
    all                Run all tests (default)
    unit               Run unit tests only
    integration        Run integration tests only
    performance        Run performance tests only
    ui                 Run UI tests only
    fast               Run fast tests (unit + basic integration)
    full               Run full test suite with coverage

EXAMPLES:
    $0                    # Run all tests
    $0 --unit-only        # Run only unit tests
    $0 --filter "player"  # Run tests with 'player' in name
    $0 --watch            # Watch mode for development
    $0 fast               # Run fast test suite

EOF
}

# Parse command line arguments
parse_args() {
    local args=("$@")
    local test_suite="all"
    local test_options=()
    
    for i in "${!args[@]}"; do
        local arg="${args[$i]}"
        
        case "$arg" in
            --unit-only)
                test_options+=("--unit-only")
                ;;
            --integration-only)
                test_options+=("--integration-only")
                ;;
            --performance-only)
                test_options+=("--performance-only")
                ;;
            --ui-only)
                test_options+=("--ui-only")
                ;;
            --parallel)
                test_options+=("--parallel")
                ;;
            --verbose|-v)
                test_options+=("--verbose")
                ;;
            --filter)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    test_options+=("--filter" "${args[$((i+1))]}")
                    ((i++))
                fi
                ;;
            --timeout)
                if [[ $((i+1)) -lt ${#args[@]} ]]; then
                    test_options+=("--timeout" "${args[$((i+1))]}")
                    ((i++))
                fi
                ;;
            --watch)
                WATCH_MODE=true
                ;;
            --coverage)
                COVERAGE_MODE=true
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            all|unit|integration|performance|ui|fast|full)
                test_suite="$arg"
                ;;
            *)
                # Skip unknown arguments for now
                ;;
        esac
    done
    
    echo "$test_suite"
    printf '%s\n' "${test_options[@]}"
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create output directories
    mkdir -p "$TEST_OUTPUT_DIR"
    mkdir -p "$REPORTS_DIR"
    
    # Set environment variables
    export LUA_PATH="$PROJECT_ROOT/?.lua;$PROJECT_ROOT/src/?.lua;$PROJECT_ROOT/tests/?.lua;;"
    export TEST_MODE=true
    export UNIFIED_TEST_FRAMEWORK=true
    
    log_success "Test environment ready"
}

# Run unified test suite
run_unified_tests() {
    local test_suite="$1"
    shift
    local test_options=("$@")
    
    local start_time=$(date +%s)
    local test_script="$PROJECT_ROOT/tests/run_unified_tests_simple.lua"
    
    log_info "Running $test_suite test suite..."
    
    # Build arguments for the test runner
    local test_args=()
    for option in "${test_options[@]}"; do
        test_args+=("$option")
    done
    
    # Run the tests
    local exit_code=0
    if timeout "$DEFAULT_TIMEOUT" lua "$test_script" > "$TEST_OUTPUT_DIR/test_results.txt" 2>&1; then
        log_success "Test suite completed successfully"
    else
        exit_code=$?
        log_error "Test suite failed (exit code: $exit_code)"
    fi
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Process results
    process_test_results "$test_suite" "$duration" "$exit_code"
    
    return $exit_code
}

# Process and analyze test results
process_test_results() {
    local suite="$1"
    local duration="$2"
    local exit_code="$3"
    
    log_info "Processing test results for $suite suite..."
    
    # Extract test statistics
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    if [[ -f "$TEST_OUTPUT_DIR/test_results.txt" ]]; then
        # Parse test results
        while IFS= read -r line; do
            if [[ $line =~ Total:\ ([0-9]+)\ \|\ Passed:\ ([0-9]+)\ \|\ Failed:\ ([0-9]+) ]]; then
                total_tests="${BASH_REMATCH[1]}"
                passed_tests="${BASH_REMATCH[2]}"
                failed_tests="${BASH_REMATCH[3]}"
                break
            fi
        done < "$TEST_OUTPUT_DIR/test_results.txt"
    fi
    
    # Generate report
    local report_file="$REPORTS_DIR/${suite}_test_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "Test Report: $suite"
        echo "Generated: $(date)"
        echo "Duration: ${duration}s"
        echo "Exit Code: $exit_code"
        echo ""
        echo "Results:"
        echo "  Total Tests: $total_tests"
        echo "  Passed: $passed_tests"
        echo "  Failed: $failed_tests"
        echo ""
        if [[ -f "$TEST_OUTPUT_DIR/test_results.txt" ]]; then
            echo "Full Output:"
            cat "$TEST_OUTPUT_DIR/test_results.txt"
        fi
    } > "$report_file"
    
    log_info "Test report saved to: $report_file"
    
    # Performance analysis
    if [[ $duration -gt 30 ]]; then
        log_warning "Test suite took ${duration}s to complete (consider optimization)"
    fi
}

# Watch mode for development
run_watch_mode() {
    log_info "Starting watch mode..."
    log_info "Press Ctrl+C to stop"
    
    # Check if fswatch is available
    if command -v fswatch >/dev/null 2>&1; then
        log_info "Using fswatch for file watching"
        fswatch -o "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" | while read -r; do
            echo "File change detected, running tests..."
            run_unified_tests "fast" "--unit-only"
        done
    elif command -v inotifywait >/dev/null 2>&1; then
        log_info "Using inotifywait for file watching"
        while true; do
            inotifywait -r -e modify,create,delete "$PROJECT_ROOT/src" "$PROJECT_ROOT/tests" >/dev/null 2>&1
            echo "File change detected, running tests..."
            run_unified_tests "fast" "--unit-only"
        done
    else
        log_warning "No file watcher available. Install fswatch or inotify-tools for watch mode."
        log_info "Running tests once..."
        run_unified_tests "fast" "--unit-only"
    fi
}

# Main execution
main() {
    echo "================================"
    echo "Orbit Jump Streamlined Test Suite"
    echo "================================"
    
    # Parse arguments
    local args_output
    args_output=$(parse_args "$@")
    local test_suite
    test_suite=$(echo "$args_output" | head -n1)
    local test_options
    mapfile -t test_options < <(echo "$args_output" | tail -n +2)
    
    # Check if help was requested
    if [[ "$*" == *"--help"* ]] || [[ "$*" == *"-h"* ]]; then
        show_usage
        exit 0
    fi
    
    # Setup environment
    setup_test_environment
    
    # Handle watch mode
    if [[ "${WATCH_MODE:-false}" == "true" ]]; then
        run_watch_mode
        exit 0
    fi
    
    # Track overall success
    local overall_success=true
    
    # Run tests based on suite
    case "$test_suite" in
        all)
            log_info "Running complete test suite..."
            if ! run_unified_tests "all" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        unit)
            log_info "Running unit tests..."
            if ! run_unified_tests "unit" "--unit-only" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        integration)
            log_info "Running integration tests..."
            if ! run_unified_tests "integration" "--integration-only" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        performance)
            log_info "Running performance tests..."
            if ! run_unified_tests "performance" "--performance-only" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        ui)
            log_info "Running UI tests..."
            if ! run_unified_tests "ui" "--ui-only" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        fast)
            log_info "Running fast test suite..."
            if ! run_unified_tests "fast" "--unit-only" "--integration-only" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        full)
            log_info "Running full test suite with coverage..."
            if ! run_unified_tests "full" "${test_options[@]}"; then
                overall_success=false
            fi
            ;;
        *)
            log_error "Unknown test suite: $test_suite"
            show_usage
            exit 1
            ;;
    esac
    
    # Summary
    echo "================================"
    if [[ "$overall_success" == "true" ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"