#!/usr/bin/env bash
# shellcheck shell=bash
# ibt.sh - Infra Bootstrap Tools dispatcher with subcommand completion
# Usage: source this file in your shell to enable the 'ibt' command and completions


IBT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$IBT_DIR/ibt-completion.sh" ]; then
  # shellcheck source=bin/bash/ibt-completion.sh
  source "$IBT_DIR/ibt-completion.sh"
fi

ibt() {
  local cmd="$1"; shift || true
  case "$cmd" in
    setup)
      if [[ $# -eq 0 ]]; then
        echo "Usage: ibt setup <tool1> [tool2 ...]"
        return 1
      fi
      "$IBT_DIR/setup.sh" "$@"
      ;;
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

# Optional: create a short alias
# alias ibt=ibt
