#!/usr/bin/env bash
# shellcheck shell=bash
# Source completion logic if available
if [ -f "$(dirname "${BASH_SOURCE[0]}")/stacks-completion.sh" ]; then
  # shellcheck source=bin/bash/stacks-completion.sh
  source "$(dirname "${BASH_SOURCE[0]}")/stacks-completion.sh"
fi

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


# Determine if current directory (or parent) is inside a repo clone
find_repo_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/ansible.cfg" ] && [ -d "$dir/stacks" ]; then
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
  echo "  list_stacks"
  echo "  run_stack <name> [component ...] [local]"
  echo "  help"
  echo ""
  echo "Examples:"
  echo "  run_stack n8n"
  echo "  run_stack n8n local"
  echo "  run_stack n8n component1 component2"
}

# List all available stacks (each subfolder in stacks/ is a stack) and their components
list_stacks() {
  local search_path="$INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
  local found=0
  while IFS= read -r -d '' dir; do
    local stack_name
    stack_name=$(basename "$dir")
    # Only show if the folder contains at least one .yaml file
    if compgen -G "$dir/*.yaml" > /dev/null; then
      found=1
      echo "- $stack_name"
      # List only .local.yaml components
      for comp in "$dir"/*.local.yaml; do
        [ -e "$comp" ] || continue
        comp_name=$(basename "$comp")
        comp_name="${comp_name%.local.yaml}"
        echo "    - $comp_name (local)"
      done
    fi
  done < <(find "$search_path" -mindepth 1 -maxdepth 1 -type d -print0)
  if [ $found -eq 0 ]; then
    echo "No stacks found in $search_path"
  fi
}

# Run a stack (optionally with components and/or local override)
run_stack() {
  local stack_name="$1"
  shift
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
  # Add main stack file
  if [ $use_local -eq 1 ] && [ -f "$base_path.local.yaml" ]; then
    files+=("$base_path.local.yaml")
  elif [ -f "$base_path.yaml" ]; then
    files+=("$base_path.yaml")
  fi
  # Add component files
  for comp in "${components[@]}"; do
    if [ $use_local -eq 1 ] && [ -f "$base_path.$comp.local.yaml" ]; then
      files+=("$base_path.$comp.local.yaml")
    elif [ -f "$base_path.$comp.yaml" ]; then
      files+=("$base_path.$comp.yaml")
    fi
  done
  if [ ${#files[@]} -eq 0 ]; then
    echo "Error: No stack files found for $stack_name"
    return 1
  fi
  echo "Running stack: $stack_name"
  echo "Using files: ${files[*]}"
  # shellcheck disable=SC2068
  docker compose -f "${files[0]}" ${files[@]:1:+-f "${files[@]:1}"} up
}

# Aliases for convenience
alias list_stacks='list_stacks'
alias run_stack='run_stack'
alias help_stacks='help'

# Bash completion for stack names
_complete_stacks() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local search_path="$INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
  local stacks=()
  while IFS= read -r -d '' file; do
    local fname
    fname=$(basename "$file")
    fname="${fname%.yaml}"
    fname="${fname%.local}"
    stacks+=("$fname")
  done < <(find "$search_path" -type f -name "*.yaml" -print0)
  # shellcheck disable=SC2207
  COMPREPLY=( $(compgen -W "${stacks[*]}" -- "$cur") )
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
