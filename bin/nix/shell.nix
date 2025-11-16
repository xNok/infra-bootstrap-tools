let
  nixpkgs = import <nixpkgs> {
    config = {
      allowUnfreePredicate = pkg: pkg.pname == "1password-cli";
    };
  };
in

nixpkgs.mkShell {
  buildInputs = with nixpkgs; [
    python3
    python3Packages.pip
    ansible
    _1password-cli
    go
    hugo
    pre-commit
    git
    docker
  ];

  shellHook = ''
    echo "Setting up development environment..."
    
    # Create virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
      echo "Creating Python virtual environment..."
      python -m venv .venv
    fi
    
    echo "Activating virtual environment..."
    source .venv/bin/activate
    
    echo "Installing Python dependencies..."
    pip install -r requirements.txt
    pip install -r agentic/requirements.txt
    
    echo "Installing Ansible Galaxy roles and collections..."
    ansible-galaxy install -r requirements.yml
    
    echo "Installing pre-commit hooks..."
    pre-commit install --install-hooks
    
    echo "Environment setup complete! Ready to develop."
    echo "Note: Python virtual environment is activated. Run 'deactivate' to exit it."
  '';
}