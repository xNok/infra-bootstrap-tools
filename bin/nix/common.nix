{ pkgs }:

let
  lib = pkgs.lib;

  # --- Package Bundles ---
  
  # Core utilities and standard tools required across all environments
  basePackages = with pkgs; [
    git
    docker
    pre-commit
    tenv
    terraform-docs
    yq-go
    bats
    conftest
  ];

  # Python ecosystem for scripting, linting, and agentic workflows
  pythonPackages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.yamllint
    python3Packages.build
    python3Packages.twine
  ];

  # Ansible and infrastructure automation tools
  ansiblePackages = with pkgs; [
    ansible
    ansible-lint
    _1password-cli
  ];

  # Zitified kubectl for OpenZiti zero-trust overlay access
  kubeztl = pkgs.buildGoModule {
    pname = "kubeztl";
    version = "0.28.4";
    src = pkgs.fetchFromGitHub {
      owner = "openziti-test-kitchen";
      repo = "kubeztl";
      rev = "bee7d35265a74beb2e35fffb8f926e917c56b7c5";
      hash = "sha256-9o2U0YZYSmq9sny0gt/qSjgTR+xjpfu37dD2DbpuzCc=";
    };
    vendorHash = "sha256-O4N+irJqeS8Tl4Is58K72ciF0zg6z2B6cZa3cggnTOg=";
    preBuild = ''
      chmod -R +w vendor
      substituteInPlace vendor/github.com/openziti/sdk-golang/ziti/ziti.go \
        --replace-warn 'session.Service.ID' '*session.ServiceID'

      substituteInPlace main.go \
        --replace-warn 'if configFilePath == "" || serviceName == "" {' \
          'if configFilePath == "" { if env := os.Getenv("ZCONFIG"); env != "" { configFilePath = env } else if home, err := os.UserHomeDir(); err == nil { p := filepath.Join(home, ".ziti", "laptop-client.json"); if _, err := os.Stat(p); err == nil { configFilePath = p } } }; if serviceName == "" { if env := os.Getenv("ZITI_SERVICE"); env != "" { serviceName = env } else { serviceName = "k3s" } }; if false {'
    '';
    doCheck = false;
    meta = with pkgs.lib; {
      description = "Zitified kubectl client for OpenZiti zero-trust networks";
      homepage = "https://github.com/openziti-test-kitchen/kubeztl";
      license = licenses.asl20;
      mainProgram = "kubeztl";
    };
  };

  # Kubernetes and GitOps configuration tools
  fluxPackages = (with pkgs; [
    jq
    kubectl
    kubernetes-helm
    kind
    fluxcd
  ]) ++ [ kubeztl ];

  # Documentation and site generation tools
  docsPackages = with pkgs; [
    go
    hugo
  ];

  # --- Shell Hook Generator ---

  # A dynamic shell hook generator to set up environments conditionally.
  # This factory function takes boolean flags (like `withVenv`) and
  # returns a bash script string that Nix will execute upon entering the shell.
  # This prevents running heavy setup scripts (like Ansible Galaxy) unless needed.
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
      
      # Bypass Terraform PGP signature verification due to expired HashiCorp keys, rely on SHA checkout instead
      export TENV_VALIDATION=sha
      # Automatically install the correct version of Terraform when invoked
      export TENV_AUTO_INSTALL=true

      # Pre-install the pinned Terraform version so tenv shims resolve immediately (e.g. for pre-commit hooks)
      tenv tf install

      ${lib.optionalString withVenv ''
      if [ ! -d ".venv" ]; then
        echo "Creating Python virtual environment..."
        python -m venv .venv
      fi

      echo "Activating Python virtual environment..."
      source .venv/bin/activate
      ''}

      ${lib.optionalString withRootRequirements ''
      echo "Installing Python dependencies from requirements.txt..."
      pip install -r requirements.txt
      ''}

      ${lib.optionalString withAgenticRequirements ''
      echo "Installing Python dependencies from agentic/requirements.txt..."
      pip install -r agentic/requirements.txt
      ''}

      ${lib.optionalString withAnsibleGalaxy ''
      echo "Installing Ansible Galaxy roles and collections..."
      ansible-galaxy install -r requirements.yml
      ''}

      ${lib.optionalString withPreCommit ''
      echo "Installing pre-commit hooks..."
      pre-commit install --install-hooks
      ''}

      echo "${name} shell ready."
    '';
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

  packages = {
    inherit kubeztl;
  };
}
