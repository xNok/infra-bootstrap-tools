#!/usr/bin/env bash
# shellcheck shell=bash
# Bash completion for setup.sh tools


# Generic completion function for tool scripts
# Usage: _tool_completion "tool1 tool2 ..."
_tool_completion() {
  local opts="$1"
  local cur
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"

  # If no argument after command, list all options
  if [[ $COMP_CWORD -eq 1 && -z "$cur" ]]; then
  read -ra COMPREPLY <<< "$(compgen -W "$opts" -- "")"
    return 0
  fi

  # If partial argument, complete matching options
  read -ra COMPREPLY <<< "$(compgen -W "$opts" -- "$cur")"
  return 0
}

# For setup.sh
_setup_completion() {
  _tool_completion "pre-commit ansible 1password-cli boilerplate hugo"
}

# For stacks.sh (example, update with real stack names if needed)
_stacks_completion() {
  _tool_completion "list run help"
}

# For tools.sh (example, update with real tool aliases if needed)
_tools_completion() {
  _tool_completion "dasb dap daws dpk dtf dbash"
}
