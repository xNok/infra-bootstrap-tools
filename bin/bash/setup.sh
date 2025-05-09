#!/bin/bash

# Function to install pre-commit hooks
install_pre_commit() {
  echo "Installing pre-commit hooks..."
  pip install pre-commit
  pre-commit install --install-hooks
  echo "Pre-commit hooks installed."
}

# Function to install ansible from requirements files
install_ansible() {
  echo "Installing ansible from requirements files..."
  python -m pip install --upgrade pip
  if [ -f requirements.txt ]; then
    echo "Installing from requirements.txt"
    pip install -r requirements.txt
  fi
  if [ -f test-requirements.txt ]; then
    echo "Installing from test-requirements.txt"
    pip install -r test-requirements.txt
  fi
  if [ -f requirements.yml ]; then
    echo "Installing from requirements.yml"
    ansible-galaxy install -r requirements.yml
  fi
  echo "Tools installed."
}

# Function to install 1password CLI
install_1password_cli() {
  echo "Installing 1password CLI..."
  curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list && \
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
    sudo apt update && sudo apt install -y 1password-cli
  echo "1password CLI installed."
}

# Function to install Boilerplate
install_boilerplate() {
  echo "Installing Boilerplate..."
  go install github.com/gruntwork-io/boilerplate@v0.6.0
  echo "Boilerplate installed."
}

# Function to install Hugo and start the server
install_hugo() {
  echo "Installing Hugo..."
  # Check if brew is installed
  if ! command -v brew &> /dev/null
  then
    echo "brew could not be found. Please install it before running this script."
    exit 1
  fi
  git -c url.https://github.com/.insteadOf=git@github.com: submodule update --init --remote --recursive
  brew install hugo
  echo "Hugo installed."
  echo "Starting Hugo server..."
  cd website && hugo server -D -F --baseURL $(gp url 1313) --liveReloadPort=443 --appendPort=false --bind=0.0.0.0 &
  echo "Hugo server started."
}

_setup_completion() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="pre-commit ansible 1password-cli boilerplate hugo"

  case "${COMP_CWORD}" in
    1)
      COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
      ;;
    *)
      COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
      ;;
  esac
  return 0
}

# Main script logic
complete -F _setup_completion setup.sh

for tool in "$@"; do
  case "$tool" in
    pre-commit)
      install_pre_commit
      ;;
    ansible)
      install_ansible
      ;;
    1password-cli)
      install_1password_cli
      ;;
    boilerplate)
      install_boilerplate
      ;;
    hugo)
      install_hugo
      ;;
    *)
      echo "Error: Unknown tool: $tool"
      echo "Available tools: pre-commit, tools, 1password-cli, boilerplate, hugo"
      ;;
  esac
done
