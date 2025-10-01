#!/bin/bash
# ibt.sh - Infra Bootstrap Tools dispatcher with subcommand completion
# Usage: source this file in your shell to enable the 'ibt' command and completions

IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ibt() {
  local cmd="$1"; shift || true
  case "$cmd" in
    setup)
      "$IBT_DIR/setup.sh" "$@" ;;
    stacks)
      "$IBT_DIR/stacks.sh" "$@" ;;
    tools)
      "$IBT_DIR/tools.sh" "$@" ;;
    ""|-h|--help|help)
      echo "Usage: ibt <setup|stacks|tools> [args...]"
      ;;
    *)
      echo "ibt: unknown subcommand: $cmd" >&2
      return 1
      ;;
  esac
}

_ibt_completion() {
  local cur opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  opts="setup stacks tools help"
  if [[ $COMP_CWORD -eq 1 ]]; then
  read -ra COMPREPLY <<< "$(compgen -W "$opts" -- "$cur")"
    return 0
  fi
  # Delegate to subcommand completion if available
  case "${COMP_WORDS[1]}" in
    setup)
      # Source setup.sh completion if not already loaded
      if declare -F _setup_completion >/dev/null; then
        _setup_completion
      fi
      ;;
    # Add more subcommand completions here if needed
    *)
      ;;
  esac
}

complete -F _ibt_completion ibt

# Optional: create a short alias
alias ibt=ibt
