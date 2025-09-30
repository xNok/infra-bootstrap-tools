#!/bin/bash

# --- infra-bootstrap-tools: Stacks Tools Alias ---
#
# Usage:
#   Source this script in your shell (e.g. via curl):
#     source <(curl -s https://raw.githubusercontent.com/xNok/infra-bootstrap-tools/main/bin/bash/stacks_tools_alias.sh)
#
#   Or add to your ~/.bashrc.d/ for persistent aliases.
#
# Features:
#   - List and run stacks from anywhere, no repo clone needed
#   - Supports stacks in multiple folders
#   - Local stacks: <name>.local.yaml
#   - Modular stacks: a stack can have multiple components
#   - Aliases for quick stack start/stop
#
# Examples:
#   list_stacks
#   run_stack n8n
#   run_stack n8n local
#   run_stack openziti
#   run_stack n8n component1 component2
#


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

REPO_ROOT="$(find_repo_root)"
if [ -n "$REPO_ROOT" ]; then
  INFRA_BOOTSTRAP_TOOLS_STACK_PATH="$REPO_ROOT/stacks"
else
  DEFAULT_PATH="$HOME/.local/share/infra-bootstrap-tools"
  INFRA_BOOTSTRAP_TOOLS_PATH="${INFRA_BOOTSTRAP_TOOLS_PATH:-$DEFAULT_PATH}"
  INFRA_BOOTSTRAP_TOOLS_STACK_PATH="${INFRA_BOOTSTRAP_TOOLS_STACK_PATH:-$INFRA_BOOTSTRAP_TOOLS_PATH/stacks}"
  # Download stacks if not present (for first-time use)
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
  COMPREPLY=( $(compgen -W "${stacks[*]}" -- "$cur") )
}
complete -F _complete_stacks run_stack

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  # If run directly, parse args
  case "$1" in
    list_stacks)
      list_stacks
      ;;
    run_stack)
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
