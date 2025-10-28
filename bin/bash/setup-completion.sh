#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for setup.sh tools
#
# This completion script dynamically fetches available tools from setup.sh
# using the --list-options flag.

# Source shared completion utilities
IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bin/bash/completion-utils.sh
source "$IBT_DIR/completion-utils.sh"

# Completion function for setup command
_setup_completion() {
  _ibt_tool_list_completion "$IBT_DIR/setup.sh"
}

complete -F _setup_completion setup.sh
