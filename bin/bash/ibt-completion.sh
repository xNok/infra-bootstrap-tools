#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for ibt command

_ibt_completion() {
  local opts="setup stacks tools help"
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

complete -F _ibt_completion ibt
