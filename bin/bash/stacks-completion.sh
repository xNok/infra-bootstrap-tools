#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for stacks.sh commands
#
# This completion script dynamically fetches available commands from stacks.sh
# using the --list-options flag.

# Source shared completion utilities
IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bin/bash/completion-utils.sh
source "$IBT_DIR/completion-utils.sh"

# Completion function for stacks command
_stacks_completion() {
  _ibt_generic_completion "$IBT_DIR/stacks.sh"
}

complete -F _stacks_completion stacks.sh
complete -F _stacks_completion run_stack
