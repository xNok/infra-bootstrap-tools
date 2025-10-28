#!/usr/bin/env bash
# shellcheck shell=bash
# ibt.sh - Infra Bootstrap Tools dispatcher with subcommand completion
#
# Purpose:
#   Unified command-line interface for infrastructure bootstrap tools.
#   Provides a consistent interface for wrapping various tools with bash completion.
#
# Usage:
#   source this file in your shell to enable the 'ibt' command and completions
#     source /path/to/ibt.sh
#   Then use:
#     ibt <setup|stacks|tools> [args...]
#     ibt --list-options  # List available subcommands
#
# Subcommands:
#   setup  - Install required tools and dependencies
#   stacks - Manage and run infrastructure stacks
#   tools  - Use Docker-based aliases for infrastructure tools
#   help   - Show usage information
#
# See also:
#   IBT_SPEC.md - Complete specification for the ibt command system

# List available subcommands for completion
if [[ "$1" == "--list-options" ]]; then
  echo "setup"
  echo "stacks"
  echo "tools"
  echo "help"
  exit 0
fi

IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source completion utilities and subcommand completions
if [ -f "$IBT_DIR/completion-utils.sh" ]; then
  # shellcheck source=bin/bash/completion-utils.sh
  source "$IBT_DIR/completion-utils.sh"
fi

if [ -f "$IBT_DIR/setup-completion.sh" ]; then
  # shellcheck source=bin/bash/setup-completion.sh
  source "$IBT_DIR/setup-completion.sh"
fi

if [ -f "$IBT_DIR/stacks-completion.sh" ]; then
  # shellcheck source=bin/bash/stacks-completion.sh
  source "$IBT_DIR/stacks-completion.sh"
fi

if [ -f "$IBT_DIR/tools-completion.sh" ]; then
  # shellcheck source=bin/bash/tools-completion.sh
  source "$IBT_DIR/tools-completion.sh"
fi

# Main ibt command dispatcher
ibt() {
  local cmd="$1"; shift || true
  case "$cmd" in
    setup)
      if [[ $# -eq 0 ]]; then
        echo "Usage: ibt setup <tool1> [tool2 ...]"
        echo "Available tools:"
        "$IBT_DIR/setup.sh" --list-options | sed 's/^/  - /'
        return 1
      fi
      "$IBT_DIR/setup.sh" "$@"
      ;;
    stacks)
      "$IBT_DIR/stacks.sh" "$@"
      ;;
    tools)
      "$IBT_DIR/tools.sh" "$@"
      ;;
    ""|-h|--help|help)
      echo "Usage: ibt <setup|stacks|tools> [args...]"
      echo ""
      echo "Subcommands:"
      echo "  setup   - Install required tools and dependencies"
      echo "  stacks  - Manage and run infrastructure stacks"
      echo "  tools   - Use Docker-based aliases for infrastructure tools"
      echo "  help    - Show this help message"
      echo ""
      echo "For subcommand help, use: ibt <subcommand> --help"
      ;;
    *)
      echo "ibt: unknown subcommand: $cmd" >&2
      echo "Run 'ibt help' for usage information." >&2
      return 1
      ;;
  esac
}

# Bash completion for ibt command
_ibt_completion() {
  local cur opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  
  # Complete first argument (subcommand)
  if [[ $COMP_CWORD -eq 1 ]]; then
    opts=$("$IBT_DIR/ibt.sh" --list-options 2>/dev/null)
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    return 0
  fi
  
  # Delegate to subcommand completion if available
  # Subcommand completion functions use COMP_WORDS[COMP_CWORD] to get the current word,
  # so they work correctly with the full COMP_WORDS array without adjustment.
  case "${COMP_WORDS[1]}" in
    setup)
      if declare -F _setup_completion >/dev/null; then
        _setup_completion
      fi
      ;;
    stacks)
      if declare -F _stacks_completion >/dev/null; then
        _stacks_completion
      fi
      ;;
    tools)
      if declare -F _tools_completion >/dev/null; then
        _tools_completion
      fi
      ;;
    *)
      ;;
  esac
}

complete -F _ibt_completion ibt
