{ pkgs }:

let
  lib = pkgs.lib;

  mkShellHook = {
    name,
    withVenv ? false,
    withRootRequirements ? false,
    withAgenticRequirements ? false,
    withAnsibleGalaxy ? false,
    withPreCommit ? false
  }:
    ''
      echo "Entering ${name} development shell..."
    ''
    + lib.optionalString withVenv ''

      if [ ! -d ".venv" ]; then
        echo "Creating Python virtual environment..."
        python -m venv .venv
      fi

      echo "Activating Python virtual environment..."
      source .venv/bin/activate
    ''
    + lib.optionalString withRootRequirements ''

      echo "Installing Python dependencies from requirements.txt..."
      pip install -r requirements.txt
    ''
    + lib.optionalString withAgenticRequirements ''

      echo "Installing Python dependencies from agentic/requirements.txt..."
      pip install -r agentic/requirements.txt
    ''
    + lib.optionalString withAnsibleGalaxy ''

      echo "Installing Ansible Galaxy roles and collections..."
      ansible-galaxy install -r requirements.yml
    ''
    + lib.optionalString withPreCommit ''

      echo "Installing pre-commit hooks..."
      pre-commit install --install-hooks
    ''
    + ''

      echo "${name} shell ready."
    '';

  basePackages = with pkgs; [
    git
    docker
    pre-commit
  ];

  pythonPackages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.yamllint
  ];

  ansiblePackages = with pkgs; [
    ansible
    ansible-lint
    _1password-cli
  ];

  fluxPackages = with pkgs; [
    jq
    kubectl
    kubernetes-helm
    kind
    fluxcd
  ];

  docsPackages = with pkgs; [
    go
    hugo
  ];
in
{
  # Allow unfree packages (specifically 1password-cli)
  nixpkgsConfig = {
    allowUnfreePredicate = pkg: pkg.pname == "1password-cli";
  };

  shells = {
    default = {
      buildInputs = basePackages ++ pythonPackages;
      shellHook = mkShellHook {
        name = "default";
        withVenv = true;
        withRootRequirements = true;
        withAgenticRequirements = true;
        withPreCommit = true;
      };
    };

    ansible = {
      buildInputs = basePackages ++ pythonPackages ++ ansiblePackages;
      shellHook = mkShellHook {
        name = "ansible";
        withVenv = true;
        withRootRequirements = true;
        withAgenticRequirements = true;
        withAnsibleGalaxy = true;
        withPreCommit = true;
      };
    };

    flux = {
      buildInputs = basePackages ++ fluxPackages;
      shellHook = mkShellHook {
        name = "flux";
        withPreCommit = true;
      };
    };

    docs = {
      buildInputs = basePackages ++ docsPackages;
      shellHook = mkShellHook {
        name = "docs";
        withPreCommit = true;
      };
    };

    full = {
      buildInputs = lib.unique (basePackages ++ pythonPackages ++ ansiblePackages ++ fluxPackages ++ docsPackages);
      shellHook = mkShellHook {
        name = "full";
        withVenv = true;
        withRootRequirements = true;
        withAgenticRequirements = true;
        withAnsibleGalaxy = true;
        withPreCommit = true;
      };
    };
  };
}
