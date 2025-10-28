#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for tools.sh aliases
#
# This completion script dynamically fetches available tools from tools.sh
# using the --list-options flag.

# Source shared completion utilities
IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bin/bash/completion-utils.sh
source "$IBT_DIR/completion-utils.sh"

# Completion function for tools command
_tools_completion() {
  _ibt_generic_completion "$IBT_DIR/tools.sh"
}

complete -F _tools_completion tools.sh
complete -F _tools_completion dasb
complete -F _tools_completion dap
complete -F _tools_completion daws
complete -F _tools_completion dpk
complete -F _tools_completion dtf
complete -F _tools_completion dbash
