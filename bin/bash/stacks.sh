#!/usr/bin/env bash
# shellcheck shell=bash
# ------------------------------------------------------------------------------
# infra-bootstrap-tools: stacks.sh
#
# Purpose:
#   Quickly start and manage stacks defined in this repository.
#   Supports both direct invocation and shell aliases for convenience.
#
# Prerequisites:
#   - Docker Compose must be installed.
#
# Usage:
#   Source for aliases:
#     source /path/to/stacks.sh
#   or add to your ~/.bashrc.d/ for persistent aliases.
#   Direct invocation:
#     ./stacks.sh list
#     ./stacks.sh run <name> [component ...] [local]
#     ./stacks.sh help
#     ./stacks.sh --list-options  # List available commands
#
# Commands/Aliases:
#   list_stacks | list   - List all available stacks
#   run_stack  | run     - Run a stack (with optional components/local)
#   help_stacks | help   - Show usage/help
#
# Examples:
#   run_stack n8n
#   run_stack n8n local
#   run_stack n8n component1 component2
#   ./stacks.sh list
#   ./stacks.sh run n8n local
#
# See also:
#   tools.sh   - Provides Docker-based tool aliases
#   setup.sh   - Installs required tools for this repository
# ------------------------------------------------------------------------------

# List available commands for completion
if [[ "$1" == "--list-options" ]]; then
  echo "list"
  echo "run"
  echo "help"
  exit 0
fi

# Source completion logic if available
if [ -f "$(dirname "${BASH_SOURCE[0]}")/stacks-completion.sh" ]; then
  # shellcheck source=bin/bash/stacks-completion.sh
  source "$(dirname "${BASH_SOURCE[0]}")/stacks-completion.sh"
fi


# Determine if current directory (or parent) is inside a repo clone
find_repo_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/stacks" ]; then
      echo "$dir"
      return
    fi
    dir="$(dirname "$dir")"
  done
}

# Determine stack path based on usage context
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # Direct invocation: prioritize local repo, then default path
  REPO_ROOT="$(find_repo_root)"
  if [ -n "$REPO_ROOT" ]; then
    INFRA_BOOTSTRAP_TOOLS_STACK_PATH="$REPO_ROOT/stacks"
  else
    DEFAULT_PATH="$HOME/.local/share/infra-bootstrap-tools"
    INFRA_BOOTSTRAP_TOOLS_PATH="${INFRA_BOOTSTRAP_TOOLS_PATH:-$DEFAULT_PATH}"
    INFRA_BOOTSTRAP_TOOLS_STACK_PATH="${INFRA_BOOTSTRAP_TOOLS_STACK_PATH:-$INFRA_BOOTSTRAP_TOOLS_PATH/stacks}"
  fi
else
  # Sourced: use default path and download if needed
  DEFAULT_PATH="$HOME/.local/share/infra-bootstrap-tools"
  INFRA_BOOTSTRAP_TOOLS_PATH="${INFRA_BOOTSTRAP_TOOLS_PATH:-$DEFAULT_PATH}"
  INFRA_BOOTSTRAP_TOOLS_STACK_PATH="${INFRA_BOOTSTRAP_TOOLS_STACK_PATH:-$INFRA_BOOTSTRAP_TOOLS_PATH/stacks}"
  # Download stacks if not present (for first-time use when sourced)
  if [ -n "$INFRA_BOOTSTRAP_TOOLS_PATH" ] && [ "$INFRA_BOOTSTRAP_TOOLS_PATH" = "$DEFAULT_PATH" ] && [ ! -d "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH" ]; then
    mkdir -p "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
    curl -sL https://api.github.com/repos/xNok/infra-bootstrap-tools/tarball/main | tar -xz -C "$INFRA_BOOTSTRAP_TOOLS_PATH" --strip=1 --wildcards "*/stacks"
  fi
fi

help() {
  echo "Usage:"
  echo "  list"
  echo "  run <name> [component ...]"
  echo ""
  echo "Examples:"
  echo "  run n8n"
  echo "  run n8n mcp-hub"
  echo ""
  echo "Notes:"
  echo "  - Local configurations (.local.yaml) are used by default if available"
  echo "  - Otherwise, remote configurations (.yaml) are used"
}

# Get list of available stacks
get_available_stacks() {
  local search_path="$INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
  local stacks=()
  while IFS= read -r -d '' dir; do
    local stack_name
    stack_name=$(basename "$dir")
    # Only include if the folder contains at least one .yaml file
    if compgen -G "$dir/*.yaml" > /dev/null; then
      stacks+=("$stack_name")
    fi
  done < <(find "$search_path" -mindepth 1 -maxdepth 1 -type d -print0)
  echo "${stacks[*]}"
}

# List all available stacks (each subfolder in stacks/ is a stack) and their components
list_stacks() {
  local stacks
  stacks=$(get_available_stacks)
  if [ -z "$stacks" ]; then
    echo "No stacks found in $INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
    return
  fi
  for stack in $stacks; do
    echo "- $stack"
    # List only .local.yaml components
    local base_path="$INFRA_BOOTSTRAP_TOOLS_STACK_PATH/$stack"
    for comp in "$base_path"/*.local.yaml; do
      [ -e "$comp" ] || continue
      comp_name=$(basename "$comp")
      comp_name="${comp_name%.local.yaml}"
      echo "    - $comp_name (local)"
    done
  done
}

# Run a stack (optionally with components and/or local override)
run_stack() {
  local stack_name="$1"
  shift
  local stacks
  stacks=$(get_available_stacks)
  if ! echo "$stacks" | grep -qw "$stack_name"; then
    echo "Error: Stack '$stack_name' not found."
    echo "Available stacks: $stacks"
    return 1
  fi
  local components=()
  local use_local=0
  for arg in "$@"; do
    if [[ "$arg" == "local" ]]; then
      use_local=1
    else
      components+=("$arg")
    fi
  done
  local base_path="$INFRA_BOOTSTRAP_TOOLS_STACK_PATH/$stack_name"
  local files=()
  # Add main stack file (prefer .local.yaml if exists)
  if [ -f "$base_path/$stack_name.local.yaml" ]; then
    files+=("$base_path/$stack_name.local.yaml")
  elif [ -f "$base_path/$stack_name.yaml" ]; then
    files+=("$base_path/$stack_name.yaml")
  fi
  # Add component files (prefer .local.yaml if exists)
  for comp in "${components[@]}"; do
    if [ -f "$base_path/$comp.local.yaml" ]; then
      files+=("$base_path/$comp.local.yaml")
    elif [ -f "$base_path/$comp.yaml" ]; then
      files+=("$base_path/$comp.yaml")
    fi
  done
  if [ ${#files[@]} -eq 0 ]; then
    echo "Error: No stack files found for $stack_name"
    return 1
  fi
  echo "Running stack: $stack_name"
  echo "Using files: ${files[*]}"
  # Build docker compose command with multiple -f flags
  docker compose $(printf -- '-f %q ' "${files[@]}") up
}

# Aliases for convenience
alias list_stacks='list_stacks'
alias run_stack='run_stack'
alias help_stacks='help'

# Bash completion for stack names
_complete_stacks() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local stacks
  stacks=$(get_available_stacks)
  # shellcheck disable=SC2207
  COMPREPLY=( $(compgen -W "$stacks" -- "$cur") )
}
complete -F _complete_stacks run_stack

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # If run directly, parse args
  case "$1" in
    list|list_stacks)
      list_stacks
      ;;
    run|run_stack)
      shift
      run_stack "$@"
      ;;
    help|--help|-h)
      help
      ;;
    "")
      help
      ;;
    *)
      echo "Unknown command: $1"
      help
      exit 1
      ;;
  esac
fi
