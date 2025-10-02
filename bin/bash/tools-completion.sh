#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for tools.sh aliases

_tools_completion() {
  local opts="dasb dap daws dpk dtf dbash"
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

complete -F _tools_completion tools.sh
complete -F _tools_completion dasb
complete -F _tools_completion dap
complete -F _tools_completion daws
complete -F _tools_completion dpk
complete -F _tools_completion dtf
complete -F _tools_completion dbash
