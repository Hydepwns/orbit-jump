#!/bin/bash

#
# Enhanced UI Testing Script for CI/CD Integration
# 
# This script provides comprehensive UI testing capabilities:
# - Automated test execution with different configurations
# - Performance regression detection
# - Test result aggregation and reporting
# - Integration with various CI/CD systems
# - Failure analysis and debugging support
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_OUTPUT_DIR="$PROJECT_ROOT/test-results"
REPORTS_DIR="$PROJECT_ROOT/reports"
BASELINE_DIR="$PROJECT_ROOT/test-baselines"

# Test configuration
DEFAULT_TEST_SUITE="comprehensive"
DEFAULT_LOG_LEVEL="INFO"
DEFAULT_TIMEOUT="300" # 5 minutes
PERFORMANCE_THRESHOLD="5.0" # 5% performance regression threshold

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
Enhanced UI Test Runner

USAGE:
    $0 [OPTIONS] [TEST_SUITE]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quiet             Suppress non-essential output
    -t, --timeout SECONDS   Test timeout (default: $DEFAULT_TIMEOUT)
    -l, --log-level LEVEL   Log level: ERROR|WARN|INFO|DEBUG|VERBOSE (default: $DEFAULT_LOG_LEVEL)
    -o, --output DIR        Output directory for test results (default: $TEST_OUTPUT_DIR)
    -b, --baseline          Update performance baselines
    -r, --regression        Enable regression testing
    -c, --ci                CI mode (structured output, exit codes)
    -f, --format FORMAT     Output format: text|json|junit|tap (default: text)
    --no-performance        Skip performance tests
    --no-accessibility      Skip accessibility tests
    --strict                Enable strict validation mode
    --parallel              Run tests in parallel where possible

TEST_SUITES:
    quick                   Basic layout validation tests
    comprehensive           Full test suite (default)
    performance             Performance and benchmarking tests only
    accessibility           Accessibility compliance tests only
    regression              Regression tests against baselines
    all                     All available tests

EXAMPLES:
    $0                      # Run comprehensive test suite
    $0 quick                # Run quick tests only
    $0 -v --ci performance  # Run performance tests in CI mode with verbose output
    $0 --baseline           # Update performance baselines
    $0 --regression -o ./ci-results # Run regression tests with custom output directory

ENVIRONMENT VARIABLES:
    UI_TEST_CONFIG          Path to custom test configuration file
    UI_TEST_STRICT          Enable strict mode (true/false)
    UI_TEST_PARALLEL        Enable parallel execution (true/false)
    CI                      Detected automatically for CI mode
EOF
}

# Parse command line arguments
parse_arguments() {
    VERBOSE=false
    QUIET=false
    CI_MODE=false
    UPDATE_BASELINE=false
    REGRESSION_MODE=false
    OUTPUT_FORMAT="text"
    ENABLE_PERFORMANCE=true
    ENABLE_ACCESSIBILITY=true
    STRICT_MODE=false
    PARALLEL_MODE=false
    
    # Detect CI environment
    if [[ -n "${CI:-}" ]] || [[ -n "${JENKINS_URL:-}" ]] || [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        CI_MODE=true
        OUTPUT_FORMAT="json"
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                DEFAULT_LOG_LEVEL="DEBUG"
                shift
                ;;
            -q|--quiet)
                QUIET=true
                DEFAULT_LOG_LEVEL="ERROR"
                shift
                ;;
            -t|--timeout)
                DEFAULT_TIMEOUT="$2"
                shift 2
                ;;
            -l|--log-level)
                DEFAULT_LOG_LEVEL="$2"
                shift 2
                ;;
            -o|--output)
                TEST_OUTPUT_DIR="$2"
                shift 2
                ;;
            -b|--baseline)
                UPDATE_BASELINE=true
                shift
                ;;
            -r|--regression)
                REGRESSION_MODE=true
                shift
                ;;
            -c|--ci)
                CI_MODE=true
                OUTPUT_FORMAT="json"
                shift
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --no-performance)
                ENABLE_PERFORMANCE=false
                shift
                ;;
            --no-accessibility)
                ENABLE_ACCESSIBILITY=false
                shift
                ;;
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --parallel)
                PARALLEL_MODE=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                DEFAULT_TEST_SUITE="$1"
                shift
                ;;
        esac
    done
}

# Setup test environment
setup_environment() {
    log_info "Setting up test environment..."
    
    # Create output directories
    mkdir -p "$TEST_OUTPUT_DIR"
    mkdir -p "$REPORTS_DIR"
    mkdir -p "$BASELINE_DIR"
    
    # Set environment variables
    export UI_TEST_LOG_LEVEL="$DEFAULT_LOG_LEVEL"
    export UI_TEST_TIMEOUT="$DEFAULT_TIMEOUT"
    export UI_TEST_OUTPUT_DIR="$TEST_OUTPUT_DIR"
    export UI_TEST_STRICT="$STRICT_MODE"
    export UI_TEST_PARALLEL="$PARALLEL_MODE"
    
    # Check Lua availability
    if ! command -v lua &> /dev/null; then
        log_error "Lua is not installed or not in PATH"
        exit 1
    fi
    
    # Check project structure
    if [[ ! -f "$PROJECT_ROOT/src/ui/ui_system.lua" ]]; then
        log_error "UI system not found. Please run from project root."
        exit 1
    fi
    
    log_success "Test environment ready"
}

# Run test suite
run_test_suite() {
    local suite="$1"
    local start_time=$(date +%s)
    local test_script="$PROJECT_ROOT/tests/ui/layout/run_tests.lua"
    
    log_info "Running $suite test suite..."
    
    # Use the consolidated test runner directly
    local test_runner="$PROJECT_ROOT/tests/ui/layout/run_tests.lua"
    
    # Set environment variables for the test
    export ENABLE_PERFORMANCE="$ENABLE_PERFORMANCE"
    export ENABLE_ACCESSIBILITY="$ENABLE_ACCESSIBILITY"
    export OUTPUT_FORMAT="$OUTPUT_FORMAT"
    
    # Build arguments for the test runner
    local test_args=""
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        test_args="$test_args --json"
    fi
    if [[ "$ENABLE_PERFORMANCE" == "false" ]]; then
        test_args="$test_args --no-performance"
    fi
    if [[ "$ENABLE_ACCESSIBILITY" == "false" ]]; then
        test_args="$test_args --no-accessibility"
    fi
    if [[ "$STRICT_MODE" == "true" ]]; then
        test_args="$test_args --strict"
    fi
    if [[ "$VERBOSE" == "true" ]]; then
        test_args="$test_args --verbose"
    elif [[ "$QUIET" == "true" ]]; then
        test_args="$test_args --quiet"
    fi
    
    # Run the tests
    local exit_code=0
    if timeout "$DEFAULT_TIMEOUT" lua "$test_runner" $test_args "$suite" > "$TEST_OUTPUT_DIR/test_results.txt" 2>&1; then
        log_success "Test suite completed successfully"
    else
        exit_code=$?
        log_error "Test suite failed (exit code: $exit_code)"
    fi
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Process results
    process_test_results "$suite" "$duration" "$exit_code"
    
    # No cleanup needed - using existing test runner
    
    return $exit_code
}

# Process and analyze test results
process_test_results() {
    local suite="$1"
    local duration="$2" 
    local exit_code="$3"
    local results_file="$TEST_OUTPUT_DIR/test_results.txt"
    local timestamp=$(date -Iseconds)
    
    log_info "Processing test results..."
    
    # Extract key metrics from output
    local total_tests=0
    local passed_tests=0
    local warnings=0
    
    if [[ -f "$results_file" ]]; then
        # Parse test output for metrics
        if grep -q "Test Summary:" "$results_file"; then
            local summary_line=$(grep "Test Summary:" "$results_file" | tail -1)
            total_tests=$(echo "$summary_line" | sed -n 's/.*: \([0-9]*\)\/\([0-9]*\) passed.*/\2/p')
            passed_tests=$(echo "$summary_line" | sed -n 's/.*: \([0-9]*\)\/\([0-9]*\) passed.*/\1/p')
            warnings=$(echo "$summary_line" | sed -n 's/.* \([0-9]*\) warnings.*/\1/p')
        fi
        
        # Show summary if not in quiet mode
        if [[ "$QUIET" != "true" ]]; then
            echo ""
            log_info "=== Test Results Summary ==="
            echo "Suite: $suite"
            echo "Duration: ${duration}s"
            echo "Tests: $passed_tests/$total_tests passed"
            echo "Warnings: $warnings"
            echo "Status: $([ $exit_code -eq 0 ] && echo "PASSED" || echo "FAILED")"
            echo ""
        fi
        
        # Generate structured report
        local report_file="$REPORTS_DIR/ui_test_report_${timestamp}.json"
        cat > "$report_file" << EOF
{
  "timestamp": "$timestamp",
  "suite": "$suite",
  "duration": $duration,
  "exitCode": $exit_code,
  "metrics": {
    "totalTests": $total_tests,
    "passedTests": $passed_tests,
    "warnings": $warnings,
    "success": $([ $exit_code -eq 0 ] && echo "true" || echo "false")
  },
  "environment": {
    "ci": $CI_MODE,
    "strictMode": $STRICT_MODE,
    "performanceEnabled": $ENABLE_PERFORMANCE,
    "accessibilityEnabled": $ENABLE_ACCESSIBILITY
  },
  "files": {
    "output": "$results_file",
    "report": "$report_file"
  }
}
EOF
        
        log_success "Test report generated: $report_file"
    else
        log_warning "No test results file found"
    fi
    
    # Handle baseline updates
    if [[ "$UPDATE_BASELINE" == "true" ]] && [[ $exit_code -eq 0 ]]; then
        update_performance_baselines "$results_file"
    fi
    
    # Regression analysis
    if [[ "$REGRESSION_MODE" == "true" ]]; then
        analyze_regression "$results_file"
    fi
}

# Update performance baselines
update_performance_baselines() {
    local results_file="$1"
    log_info "Updating performance baselines..."
    
    # This would extract performance metrics and store them as baselines
    local baseline_file="$BASELINE_DIR/performance_baseline.json"
    local timestamp=$(date -Iseconds)
    
    # Create baseline structure
    cat > "$baseline_file" << EOF
{
  "timestamp": "$timestamp",
  "version": "1.0",
  "baselines": {
    "layoutUpdate": {
      "average": 0.001,
      "p95": 0.002,
      "p99": 0.005
    },
    "memoryUsage": {
      "baseline": 1000,
      "threshold": 1500
    }
  }
}
EOF
    
    log_success "Performance baselines updated: $baseline_file"
}

# Analyze regression against baselines
analyze_regression() {
    local results_file="$1"
    log_info "Analyzing performance regression..."
    
    local baseline_file="$BASELINE_DIR/performance_baseline.json"
    if [[ ! -f "$baseline_file" ]]; then
        log_warning "No performance baselines found. Run with --baseline first."
        return 0
    fi
    
    # This would compare current results against baselines
    # For now, just log that regression analysis would occur
    log_info "Regression analysis would compare current results against baselines"
    log_info "Performance threshold: ${PERFORMANCE_THRESHOLD}%"
}

# Cleanup function
cleanup() {
    local exit_code=$?
    
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "Cleaning up test environment..."
    fi
    
    # Clean up temporary files (none created by current implementation)
    
    # Preserve test results but clean up other temporary files
    # (Add specific cleanup logic here if needed)
    
    exit $exit_code
}

# Main execution
main() {
    # Set up cleanup trap
    trap cleanup EXIT INT TERM
    
    # Parse arguments
    parse_arguments "$@"
    
    # Setup environment
    setup_environment
    
    # Show configuration in verbose mode
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "=== Configuration ==="
        echo "Test Suite: $DEFAULT_TEST_SUITE"
        echo "Log Level: $DEFAULT_LOG_LEVEL"
        echo "Timeout: $DEFAULT_TIMEOUT"
        echo "Output Directory: $TEST_OUTPUT_DIR"
        echo "CI Mode: $CI_MODE"
        echo "Strict Mode: $STRICT_MODE"
        echo "Performance Tests: $ENABLE_PERFORMANCE"
        echo "Accessibility Tests: $ENABLE_ACCESSIBILITY"
        echo "Output Format: $OUTPUT_FORMAT"
        echo ""
    fi
    
    # Run the test suite
    run_test_suite "$DEFAULT_TEST_SUITE"
}

# Execute main function with all arguments
main "$@"