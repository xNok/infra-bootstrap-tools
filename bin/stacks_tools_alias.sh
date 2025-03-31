#!/bin/bash

help() {
  echo "Usage:"
  echo "  $(basename "$0") [INFRA_BOOTSTRAP_TOOLS_PATH]"
  echo ""
  echo "Commands:"
  echo "  list_stacks      List available stacks."
  echo "  run_stack <name> Run a specific stack."
  echo "  help             Display this help message."
  echo ""
  echo "Examples:"
  echo "  $(basename "$0") list_stacks"
  echo "  $(basename "$0") run_stack n8n"
  echo "  $(basename "$0") /path/to/my/custom/stacks"
}

DEFAULT_PATH="$HOME/.local/share/infra-bootstrap-tools"
INFRA_BOOTSTRAP_TOOLS_PATH="${INFRA_BOOTSTRAP_TOOLS_PATH:-$DEFAULT_PATH}"
INFRA_BOOTSTRAP_TOOLS_STACK_PATH=${INFRA_BOOTSTRAP_TOOLS_STACK_PATH:-"$INFRA_BOOTSTRAP_TOOLS_PATH/stacks-local"}

if [ ! -d "$INFRA_BOOTSTRAP_TOOLS_PATH" ]; then
  mkdir -p "$INFRA_BOOTSTRAP_TOOLS_PATH"
fi

if [ "$INFRA_BOOTSTRAP_TOOLS_PATH" = "$DEFAULT_PATH" ]; then
  if [ ! -d "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH" ]; then
    mkdir -p "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
    curl -sL https://api.github.com/repos/xNok/infra-bootstrap-tools/tarball/main | tar -xz -C "$INFRA_BOOTSTRAP_TOOLS_PATH" --strip=1 --wildcards "*/stacks-local"
    if [ $? -eq 0 ]; then
      echo "Success: downloaded stacks"
    else
      echo "Error: Failed to download stacks."
    fi
  fi
fi

run_stack() {
  local stack_name="$1"
  local compose_file="$INFRA_BOOTSTRAP_TOOLS_STACK_PATH/$stack_name/docker-compose.yml"

  if [ -f "$compose_file" ]; then
    docker compose -f "$compose_file" up
  else
    echo "Error: docker-compose.yml not found at $INFRA_BOOTSTRAP_TOOLS_STACK_PATH$stack_name/"
  fi
}

list_stacks() {
  if [ -d "$INFRA_BOOTSTRAP_TOOLS_PATH" ]; then
    # shellcheck disable=SC2207
    local stacks=($(find "$INFRA_BOOTSTRAP_TOOLS_STACK_PATHl" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"))
    if [ ${#stacks[@]} -gt 0 ]; then
      echo "Available stacks:"
      for stack in "${stacks[@]}"; do
        if [ -f "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH/$stack/docker-compose.yml" ]; then
          echo "- $stack"
        fi
      done
    else
      echo "No stacks found in INFRA_BOOTSTRAP_TOOLS_STACK_PATH"
    fi
  else
    echo "INFRA_BOOTSTRAP_TOOLS_STACK_PATH does not exist."
  fi
}

_complete_stacks() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  # shellcheck disable=SC2207
  local stacks=($(find "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH" -maxdepth 1 -mindepth 1 -type d -printf "%f\n"))
  local completions=()

  for stack in "${stacks[@]}"; do
    if [ -f "$INFRA_BOOTSTRAP_TOOLS_STACK_PATH/$stack/docker-compose.yml" ]; then
      completions+=("$stack")
    fi
  done

  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "${completions[*]}" -- "$cur"))
}

complete -F _complete_stacks "$(basename "$0")"

if [ "$1" = "list_stacks" ]; then
  list_stacks
elif [ "$1" = "run_stack" ]; then
  if [ -z "$2" ]; then
    echo "Error: Stack name is required."
    help
    exit 1
  fi
  run_stack "$2"
elif [ "$1" = "help" ]; then
  help
elif [ -n "$1" ] && [ ! -d "$1" ] && [ "$1" != "list_stacks" ] && [ "$1" != "run_stack" ] && [ "$1" != "help" ]; then
    help
    exit 1
fi
