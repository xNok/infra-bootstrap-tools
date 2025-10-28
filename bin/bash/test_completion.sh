#!/usr/bin/env bash
# shellcheck shell=bash
# test_completion.sh - Tests for bash completion functionality
#
# This script tests the bash completion system without installing or running actual tools.
# It verifies that:
# 1. --list-options flag works for all scripts
# 2. Completion functions are properly defined
# 3. Tab completion produces correct results
# 4. No hardcoded options remain in completion scripts

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Helper functions
pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  echo -e "  ${RED}$2${NC}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_header() {
  echo ""
  echo "======================================"
  echo "$1"
  echo "======================================"
}

# Test 1: Verify --list-options flag works for all scripts
test_list_options() {
  test_header "Test 1: --list-options Flag"
  
  # Test setup.sh
  OUTPUT=$(bash "$SCRIPT_DIR/setup.sh" --list-options 2>&1)
  if echo "$OUTPUT" | grep -q "pre-commit" && echo "$OUTPUT" | grep -q "ansible"; then
    pass "setup.sh --list-options returns expected tools"
  else
    fail "setup.sh --list-options" "Expected 'pre-commit' and 'ansible' in output, got: $OUTPUT"
  fi
  
  # Test stacks.sh
  OUTPUT=$(bash "$SCRIPT_DIR/stacks.sh" --list-options 2>&1)
  if echo "$OUTPUT" | grep -q "list" && echo "$OUTPUT" | grep -q "run" && echo "$OUTPUT" | grep -q "help"; then
    pass "stacks.sh --list-options returns expected commands"
  else
    fail "stacks.sh --list-options" "Expected 'list', 'run', 'help' in output, got: $OUTPUT"
  fi
  
  # Test tools.sh
  OUTPUT=$(bash "$SCRIPT_DIR/tools.sh" --list-options 2>&1)
  if echo "$OUTPUT" | grep -q "dasb" && echo "$OUTPUT" | grep -q "dap" && echo "$OUTPUT" | grep -q "daws"; then
    pass "tools.sh --list-options returns expected tools"
  else
    fail "tools.sh --list-options" "Expected 'dasb', 'dap', 'daws' in output, got: $OUTPUT"
  fi
  
  # Test ibt.sh
  OUTPUT=$(bash "$SCRIPT_DIR/ibt.sh" --list-options 2>&1)
  if echo "$OUTPUT" | grep -q "setup" && echo "$OUTPUT" | grep -q "stacks" && echo "$OUTPUT" | grep -q "tools"; then
    pass "ibt.sh --list-options returns expected subcommands"
  else
    fail "ibt.sh --list-options" "Expected 'setup', 'stacks', 'tools' in output, got: $OUTPUT"
  fi
}

# Test 2: Verify completion functions exist and are properly defined
test_completion_functions() {
  test_header "Test 2: Completion Functions"
  
  # Source ibt.sh to load all completion functions
  cd "$REPO_ROOT"
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/ibt.sh"
  
  # Test _ibt_completion
  if declare -F _ibt_completion >/dev/null; then
    pass "_ibt_completion function is defined"
  else
    fail "_ibt_completion function" "Function not found"
  fi
  
  # Test _setup_completion
  if declare -F _setup_completion >/dev/null; then
    pass "_setup_completion function is defined"
  else
    fail "_setup_completion function" "Function not found"
  fi
  
  # Test _stacks_completion
  if declare -F _stacks_completion >/dev/null; then
    pass "_stacks_completion function is defined"
  else
    fail "_stacks_completion function" "Function not found"
  fi
  
  # Test _tools_completion
  if declare -F _tools_completion >/dev/null; then
    pass "_tools_completion function is defined"
  else
    fail "_tools_completion function" "Function not found"
  fi
  
  # Test shared utility functions
  if declare -F _ibt_generic_completion >/dev/null; then
    pass "_ibt_generic_completion utility function is defined"
  else
    fail "_ibt_generic_completion utility" "Function not found"
  fi
  
  if declare -F _ibt_tool_list_completion >/dev/null; then
    pass "_ibt_tool_list_completion utility function is defined"
  else
    fail "_ibt_tool_list_completion utility" "Function not found"
  fi
}

# Test 3: Test completion results
test_completion_results() {
  test_header "Test 3: Completion Results"
  
  cd "$REPO_ROOT"
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/ibt.sh"
  
  # Test ibt subcommand completion
  COMP_WORDS=(ibt "")
  COMP_CWORD=1
  _ibt_completion
  if [[ " ${COMPREPLY[*]} " == *" setup "* ]] && [[ " ${COMPREPLY[*]} " == *" stacks "* ]] && [[ " ${COMPREPLY[*]} " == *" tools "* ]]; then
    pass "ibt subcommand completion includes setup, stacks, tools"
  else
    fail "ibt subcommand completion" "Expected 'setup', 'stacks', 'tools', got: ${COMPREPLY[*]}"
  fi
  
  # Test ibt setup tool completion
  COMP_WORDS=(ibt setup "")
  COMP_CWORD=2
  _ibt_completion
  if [[ " ${COMPREPLY[*]} " == *" ansible "* ]] && [[ " ${COMPREPLY[*]} " == *" pre-commit "* ]]; then
    pass "ibt setup completion includes ansible, pre-commit"
  else
    fail "ibt setup completion" "Expected 'ansible', 'pre-commit', got: ${COMPREPLY[*]}"
  fi
  
  # Test partial completion for ibt
  COMP_WORDS=(ibt "s")
  COMP_CWORD=1
  _ibt_completion
  if [[ " ${COMPREPLY[*]} " == *" setup "* ]] && [[ " ${COMPREPLY[*]} " == *" stacks "* ]]; then
    pass "ibt partial completion 's' matches setup and stacks"
  else
    fail "ibt partial completion" "Expected 'setup', 'stacks' for 's', got: ${COMPREPLY[*]}"
  fi
  
  # Test partial completion for setup tools
  COMP_WORDS=(ibt setup "an")
  COMP_CWORD=2
  _ibt_completion
  if [[ " ${COMPREPLY[*]} " == *" ansible "* ]]; then
    pass "ibt setup partial completion 'an' matches ansible"
  else
    fail "ibt setup partial completion" "Expected 'ansible' for 'an', got: ${COMPREPLY[*]}"
  fi
  
  # Test stacks completion
  COMP_WORDS=(ibt stacks "")
  COMP_CWORD=2
  _ibt_completion
  if [[ " ${COMPREPLY[*]} " == *" list "* ]] && [[ " ${COMPREPLY[*]} " == *" run "* ]]; then
    pass "ibt stacks completion includes list, run"
  else
    fail "ibt stacks completion" "Expected 'list', 'run', got: ${COMPREPLY[*]}"
  fi
}

# Test 4: Verify no hardcoded options in completion scripts
test_no_hardcoded_options() {
  test_header "Test 4: No Hardcoded Options"
  
  # Check setup-completion.sh
  if ! grep -q '"pre-commit ansible' "$SCRIPT_DIR/setup-completion.sh"; then
    pass "setup-completion.sh has no hardcoded options"
  else
    fail "setup-completion.sh" "Found hardcoded options"
  fi
  
  # Check stacks-completion.sh
  if ! grep -q '"list run help"' "$SCRIPT_DIR/stacks-completion.sh"; then
    pass "stacks-completion.sh has no hardcoded options"
  else
    fail "stacks-completion.sh" "Found hardcoded options"
  fi
  
  # Check tools-completion.sh
  if ! grep -q '"dasb dap daws' "$SCRIPT_DIR/tools-completion.sh"; then
    pass "tools-completion.sh has no hardcoded options"
  else
    fail "tools-completion.sh" "Found hardcoded options"
  fi
  
  # Check ibt-completion.sh
  if ! grep -q '"setup stacks tools' "$SCRIPT_DIR/ibt-completion.sh"; then
    pass "ibt-completion.sh has no hardcoded options"
  else
    fail "ibt-completion.sh" "Found hardcoded options"
  fi
}

# Test 5: Test completion-utils.sh functions directly
test_completion_utils() {
  test_header "Test 5: Completion Utilities"
  
  cd "$REPO_ROOT"
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/completion-utils.sh"
  
  # Test _ibt_generic_completion with setup.sh
  COMP_WORDS=(setup "")
  COMP_CWORD=1
  _ibt_generic_completion "$SCRIPT_DIR/setup.sh"
  if [[ " ${COMPREPLY[*]} " == *" ansible "* ]]; then
    pass "_ibt_generic_completion correctly fetches options"
  else
    fail "_ibt_generic_completion" "Expected 'ansible' in results, got: ${COMPREPLY[*]}"
  fi
  
  # Test _ibt_tool_list_completion with tools.sh
  COMP_WORDS=(tools "")
  COMP_CWORD=1
  _ibt_tool_list_completion "$SCRIPT_DIR/tools.sh"
  if [[ " ${COMPREPLY[*]} " == *" dasb "* ]] && [[ " ${COMPREPLY[*]} " == *" dap "* ]]; then
    pass "_ibt_tool_list_completion correctly fetches tool list"
  else
    fail "_ibt_tool_list_completion" "Expected 'dasb', 'dap', got: ${COMPREPLY[*]}"
  fi
  
  # Test with non-existent file (should handle gracefully)
  COMP_WORDS=(test "")
  COMP_CWORD=1
  _ibt_generic_completion "/nonexistent/file.sh"
  if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
    pass "_ibt_generic_completion handles missing file gracefully"
  else
    fail "_ibt_generic_completion" "Should return empty for missing file, got: ${COMPREPLY[*]}"
  fi
}

# Test 6: Test ibt command functionality (without running tools)
test_ibt_command() {
  test_header "Test 6: IBT Command Functionality"
  
  cd "$REPO_ROOT"
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/ibt.sh"
  
  # Test ibt help
  OUTPUT=$(ibt help 2>&1)
  if echo "$OUTPUT" | grep -q "Usage: ibt"; then
    pass "ibt help displays usage information"
  else
    fail "ibt help" "Expected usage information, got: $OUTPUT"
  fi
  
  # Test ibt with unknown subcommand
  OUTPUT=$(ibt unknown-command 2>&1 || true)
  if echo "$OUTPUT" | grep -q "unknown subcommand"; then
    pass "ibt handles unknown subcommand correctly"
  else
    fail "ibt unknown subcommand" "Expected error message, got: $OUTPUT"
  fi
  
  # Test ibt setup without arguments
  OUTPUT=$(ibt setup 2>&1 || true)
  if echo "$OUTPUT" | grep -q "Available tools:"; then
    pass "ibt setup without args shows available tools"
  else
    fail "ibt setup" "Expected tools list, got: $OUTPUT"
  fi
}

# Test 7: Test multiple argument completion (for setup)
test_multi_argument_completion() {
  test_header "Test 7: Multi-Argument Completion"
  
  cd "$REPO_ROOT"
  # shellcheck source=/dev/null
  source "$SCRIPT_DIR/ibt.sh"
  
  # Test completion after first tool is entered
  COMP_WORDS=(ibt setup ansible "")
  COMP_CWORD=3
  _ibt_completion
  if [[ " ${COMPREPLY[*]} " == *" pre-commit "* ]] && [[ " ${COMPREPLY[*]} " == *" hugo "* ]]; then
    pass "Multi-argument completion works (setup with multiple tools)"
  else
    fail "Multi-argument completion" "Expected all tools in second position, got: ${COMPREPLY[*]}"
  fi
}

# Main test execution
main() {
  echo ""
  echo "=========================================="
  echo "Bash Completion Test Suite"
  echo "=========================================="
  echo "Testing bash completion without installing or running tools"
  echo ""
  
  test_list_options
  test_completion_functions
  test_completion_results
  test_no_hardcoded_options
  test_completion_utils
  test_ibt_command
  test_multi_argument_completion
  
  # Summary
  echo ""
  echo "=========================================="
  echo "Test Summary"
  echo "=========================================="
  echo "Tests run:    $TESTS_RUN"
  echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    exit 1
  else
    echo -e "Tests failed: ${GREEN}0${NC}"
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
  fi
}

# Run tests
main "$@"
