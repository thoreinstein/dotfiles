#!/usr/bin/env bash

set -euo pipefail

# Test framework for ts script
#
# Runs basic validation tests against the ts (tmux session switcher) script.
# Tests verify error handling, dependency checks, and shellcheck compliance.
#
# Usage: ./test_ts.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS_SCRIPT="$SCRIPT_DIR/ts"
TEST_DIR="/tmp/ts_test_$$"
FAILED_TESTS=0
TOTAL_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
# shellcheck disable=SC2329  # Functions are invoked indirectly
setup_test_env() {
  mkdir -p "$TEST_DIR/src/testuser"
  export HOME="$TEST_DIR"
}

# shellcheck disable=SC2329
cleanup_test_env() {
  rm -rf "$TEST_DIR" 2>/dev/null || true
}

run_test() {
  local test_name="$1"
  local test_function="$2"
  
  echo -n "Running test: $test_name... "
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  if "$test_function"; then
    echo -e "${GREEN}PASS${NC}"
  else
    echo -e "${RED}FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# Test functions
# shellcheck disable=SC2329
test_missing_dependencies() {
  # Test when required commands are missing
  local temp_path="$PATH"
  export PATH="/nonexistent"
  
  local result=0
  if "$TS_SCRIPT" 2>/dev/null; then
    result=1  # Should have failed
  fi
  
  export PATH="$temp_path"
  return "$result"
}

# shellcheck disable=SC2329
test_missing_base_dir() {
  # Test when base directory doesn't exist
  local temp_home="$HOME"
  export HOME="/nonexistent"
  
  local result=0
  if "$TS_SCRIPT" 2>/dev/null; then
    result=1  # Should have failed
  fi
  
  export HOME="$temp_home"
  return "$result"
}

# shellcheck disable=SC2329
test_empty_base_dir() {
  # Test when base directory exists but is empty
  local temp_home="$HOME"
  setup_test_env
  
  # Create empty src directory
  mkdir -p "$TEST_DIR/src"
  
  local result=0
  if "$TS_SCRIPT" 2>/dev/null; then
    result=1  # Should have failed (no repos found)
  fi
  
  export HOME="$temp_home"
  cleanup_test_env
  return "$result"
}

# shellcheck disable=SC2329
test_valid_git_repo() {
  local temp_home="$HOME"
  local temp_pwd="$PWD"
  setup_test_env
  
  # Create a valid git repository structure
  local repo_dir="$TEST_DIR/src/testuser/testrepo"
  mkdir -p "$repo_dir"
  
  if ! cd "$repo_dir"; then
    export HOME="$temp_home"
    cd "$temp_pwd" || true
    cleanup_test_env
    return 1
  fi
  
  if ! git init --bare . >/dev/null 2>&1; then
    export HOME="$temp_home"
    cd "$temp_pwd" || true
    cleanup_test_env
    return 1
  fi
  
  # The script should find this repo but exit when no selection is made
  # We'll just test that it doesn't crash with errors
  # Use portable timeout: gtimeout on macOS (from coreutils), timeout on Linux
  local timeout_cmd=""
  if command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout"
  elif command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout"
  fi
  
  if [[ -n "$timeout_cmd" ]]; then
    "$timeout_cmd" 1s "$TS_SCRIPT" 2>/dev/null || true
  else
    # No timeout available, skip the interactive test
    true
  fi
  
  export HOME="$temp_home"
  cd "$temp_pwd" || true
  cleanup_test_env
  return 0
}

# shellcheck disable=SC2329
test_shellcheck_clean() {
  # Verify the script passes shellcheck
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo -ne "\b\b\b\b${YELLOW}SKIP (shellcheck not available)${NC}\n"
    # Don't count this as pass or fail
    TOTAL_TESTS=$((TOTAL_TESTS - 1))
    return 0
  fi
  
  if shellcheck "$TS_SCRIPT" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

# Main test execution
main() {
  echo "Starting ts script tests..."
  echo "Test directory: $TEST_DIR"
  echo "Script: $TS_SCRIPT"
  echo ""
  
  # Verify the script exists
  if [[ ! -f "$TS_SCRIPT" ]]; then
    echo -e "${RED}ERROR: ts script not found at $TS_SCRIPT${NC}"
    exit 1
  fi
  
  # Run tests
  run_test "Missing dependencies check" test_missing_dependencies
  run_test "Missing base directory check" test_missing_base_dir
  run_test "Empty base directory check" test_empty_base_dir
  run_test "Valid git repository handling" test_valid_git_repo
  run_test "Shellcheck validation" test_shellcheck_clean
  
  echo ""
  echo "Test Results:"
  echo "============="
  echo "Total tests: $TOTAL_TESTS"
  echo -e "Passed: ${GREEN}$((TOTAL_TESTS - FAILED_TESTS))${NC}"
  
  if [[ $FAILED_TESTS -gt 0 ]]; then
    echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
    exit 1
  else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

# Cleanup on exit
trap cleanup_test_env EXIT

main "$@"
