#!/usr/bin/env bash
# shellcheck shell=bash
# completion-utils.sh - Shared utilities for bash completion
#
# This file provides reusable completion functions to eliminate duplication
# across the IBT completion scripts.

# Generic completion function that fetches options from a script
# Usage: _ibt_generic_completion <script_path>
#
# The target script must implement --list-options flag that outputs
# available options one per line.
#
# Arguments:
#   $1 - Path to the script to fetch options from
#
# Environment:
#   COMP_WORDS - Array of words in the current command line
#   COMP_CWORD - Index of the word containing the cursor
#   COMPREPLY - Array where completion results are stored
_ibt_generic_completion() {
  local script_path="$1"
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local opts
  
  COMPREPLY=()
  
  # Check if script exists and is executable
  if [[ ! -x "$script_path" && ! -f "$script_path" ]]; then
    return 0
  fi
  
  # Fetch options from the script
  if [[ -f "$script_path" ]]; then
    opts=$(bash "$script_path" --list-options 2>/dev/null)
  fi
  
  # If no options returned, fall back to empty completion
  if [[ -z "$opts" ]]; then
    return 0
  fi
  
  # Generate completions
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
  return 0
}

# Generic completion for tool lists (multi-argument completion)
# Usage: _ibt_tool_list_completion <script_path>
#
# Similar to _ibt_generic_completion but allows completing multiple
# arguments (tools) in sequence.
#
# Arguments:
#   $1 - Path to the script to fetch options from
_ibt_tool_list_completion() {
  local script_path="$1"
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local opts
  
  COMPREPLY=()
  
  # Check if script exists
  if [[ ! -f "$script_path" ]]; then
    return 0
  fi
  
  # Fetch options from the script
  opts=$(bash "$script_path" --list-options 2>/dev/null)
  
  # If no options returned, fall back to empty completion
  if [[ -z "$opts" ]]; then
    return 0
  fi
  
  # For tool lists, we want to complete any position after the command
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
  return 0
}
