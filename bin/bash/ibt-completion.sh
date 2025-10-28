#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for ibt command
#
# NOTE: This file is maintained for backwards compatibility.
# The main completion logic is now in ibt.sh itself.
# If you source ibt.sh, this file is not needed.
#
# This completion script dynamically fetches available subcommands from ibt.sh
# using the --list-options flag.

# Source shared completion utilities
IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bin/bash/completion-utils.sh
source "$IBT_DIR/completion-utils.sh"

# Completion function for ibt command (standalone)
_ibt_completion() {
  _ibt_generic_completion "$IBT_DIR/ibt.sh"
}

complete -F _ibt_completion ibt
