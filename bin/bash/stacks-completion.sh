#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for stacks.sh commands

_stacks_completion() {
  local opts="list run help"
  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  if [[ $COMP_CWORD -eq 1 && -z "$cur" ]]; then
  read -ra COMPREPLY <<< "$(compgen -W "$opts" -- "")"
    return 0
  fi
  read -ra COMPREPLY <<< "$(compgen -W "$opts" -- "$cur")"
  return 0
}

complete -F _stacks_completion stacks.sh
complete -F _stacks_completion run_stack
