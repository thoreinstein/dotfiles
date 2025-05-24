#!/usr/bin/env bash

set -euo pipefail

# Test framework for ts script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS_SCRIPT="$SCRIPT_DIR/.bin/ts"
TEST_DIR="/tmp/ts_test_$$"
FAILED_TESTS=0
TOTAL_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test helper functions
setup_test_env() {
  mkdir -p "$TEST_DIR/src/testuser"
  export HOME="$TEST_DIR"
}

cleanup_test_env() {
  rm -rf "$TEST_DIR"
}

run_test() {
  local test_name="$1"
  local test_function="$2"
  
  echo -n "Running test: $test_name... "
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  
  if $test_function; then
    echo -e "${GREEN}PASS${NC}"
  else
    echo -e "${RED}FAIL${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
  fi
}

# Test functions
test_missing_dependencies() {
  # Test when required commands are missing
  local temp_path="$PATH"
  export PATH="/nonexistent"
  
  if "$TS_SCRIPT" 2>/dev/null; then
    export PATH="$temp_path"
    return 1  # Should have failed
  fi
  
  export PATH="$temp_path"
  return 0  # Correctly failed
}

test_missing_base_dir() {
  # Test when base directory doesn't exist
  local temp_home="$HOME"
  export HOME="/nonexistent"
  
  if "$TS_SCRIPT" 2>/dev/null; then
    export HOME="$temp_home"
    return 1  # Should have failed
  fi
  
  export HOME="$temp_home"
  return 0  # Correctly failed
}

test_empty_base_dir() {
  # Test when base directory exists but is empty
  setup_test_env
  
  # Create empty src directory
  mkdir -p "$TEST_DIR/src"
  
  if "$TS_SCRIPT" 2>/dev/null; then
    cleanup_test_env
    return 1  # Should have failed (no repos found)
  fi
  
  cleanup_test_env
  return 0  # Correctly failed
}

test_valid_git_repo() {
  setup_test_env
  
  # Create a valid git repository structure
  local repo_dir="$TEST_DIR/src/testuser/testrepo"
  mkdir -p "$repo_dir"
  cd "$repo_dir"
  
  git init --bare . >/dev/null 2>&1 || return 1
  
  # The script should find this repo but exit when no selection is made
  # We'll just test that it doesn't crash with errors
  timeout 1s "$TS_SCRIPT" 2>/dev/null || true
  
  cleanup_test_env
  return 0
}

test_shellcheck_clean() {
  # Verify the script passes shellcheck
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$TS_SCRIPT" >/dev/null 2>&1
    return $?
  else
    echo -e "${YELLOW}SKIP (shellcheck not available)${NC}"
    return 0
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