---
title: "The Holy Grail of Development Environments: My Journey to Nix"
date: 2026-05-02
author: xNok
summary: "How I moved from Docker and custom Bash scripts to Nix Flakes to achieve the same configuration and environment locally, in the cloud, and in CI."
tags:
  - Nix
  - Developer Experience
  - CI/CD
  - Gitpod
---

# The Holy Grail of Development Environments: My Journey to Nix

If you've ever bounced between a local Linux machine, cloud-based IDEs like Gitpod or GitHub Codespaces, and CI/CD pipelines, you know the struggle. Keeping your toolchains, environment variables, and bootstrapping scripts synchronized across all these environments is a massive pain point. 

For a long time, my goal was to find a smart, reproducible way to manage my Ubuntu laptop alongside my various cloud environments. I wanted to eliminate the age-old "it works on my machine" problem, not just for my code, but for the very tools I used to build and deploy that code.

This is the story of that journey, the iterations I went through in my `infra-bootstrap-tools` repository, and how I finally found the holy grail: **Nix**.

## Phase 1: The Docker Era

My first serious attempt at solving this problem was leaning heavily into containers. If everything ran in a container, it would run exactly the same everywhere, right? I created a system called `docker_tools_alias`. 

The idea was simple: build a massive, portable Docker container with all the tools I needed (Terraform, Ansible, AWS CLI, Packer, etc.) pre-installed. Instead of installing tools natively, I aliased commands on my host machine to run inside the container. 

Here is what that looked like under the hood in `tools.sh`:

```bash
drun () 
{
  docker run --rm "${TTY}" \
            -w /home/ubuntu \
            -v "$(pwd)":/home/ubuntu \
            -v ~/.ssh:/home/ubuntu/.ssh \
            -v ~/.aws:/home/ubuntu/.aws \
            -e AWS_PROFILE \
            "$INFRA_IMAGE_NAME" "$@"
}

dasb () 
{
  drun ansible "$@"
}
```

Whenever I typed `dasb` (Docker Ansible), it spun up the container, mounted my current directory, AWS credentials, and SSH keys, and executed the command. 

While this gave me a portable environment, the reality was less than ideal. Executing commands felt sluggish due to container startup overhead. Furthermore, integrating this containerized approach into CI pipelines often meant wrestling with Docker-in-Docker complexities and clunky volume mounts. It was portable, but it wasn't graceful.

## Phase 2: The Bash Era (`ibt`)

Realizing Docker wasn't the silver bullet for local tooling, I pivoted. I decided to build a custom CLI framework using Bash, which I dubbed `ibt` (infra-bootstrap-tools).

This script acted as a central dispatcher for setting up the environment. You could run `ibt setup` and it would pull down binaries, configure paths, install Python virtual environments, and get you ready to code. 

To its credit, `ibt` worked surprisingly well. It integrated seamlessly with Gitpod and Codespaces, and I even used it successfully in CI pipelines. However, the maintenance burden grew rapidly. Writing cross-platform, idempotent Bash scripts for complex toolchains is a headache. I was maintaining an immense amount of complex shell code for relatively little value. The setup was brittle; if a download URL changed or a dependency shifted, the bash scripts would break.

## Phase 3: The Nix Discovery and `shell.nix`

I knew there had to be a better way to declare dependencies without heavy containers or fragile shell scripts. That's when I discovered Nix.

I was immediately seduced by `nix-shell`. It seemed like the perfect compromise. With a single `shell.nix` file, I could define exactly which packages and versions my project needed. When a developer entered the project directory, Nix would provision the exact environment described, completely isolated from the host OS. 

To keep my monolithic repository organized without creating a massive, bloated default environment, I designed a dynamic setup. Instead of one big `shell.nix`, I split the configuration into a `common.nix` file that defines modular package lists and a `shellHook` factory.

Here is the secret sauce in [`bin/nix/common.nix`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/nix/common.nix):

```nix
  # --- Package Bundles ---
  basePackages = with pkgs; [ git docker pre-commit tenv ];
  pythonPackages = with pkgs; [ python3 python3Packages.pip ];

  # --- Shell Hook Generator ---
  # Returns a bash script string that Nix will execute upon entering the shell.
  mkShellHook = { name, withVenv ? false, withAnsibleGalaxy ? false, ... }: ''
    echo "Entering ${name} development shell..."
    ${pkgs.lib.optionalString withVenv ''
      if [ ! -d ".venv" ]; then python -m venv .venv; fi
    ''}
  '';
```

By defining a factory function (`mkShellHook`), we can conditionally inject Python virtual environments or install Ansible dependencies only when a specific shell variant is requested. 

This modular setup is then consumed by a very lightweight entrypoint in [`bin/nix/shell.nix`](https://github.com/xNok/infra-bootstrap-tools/blob/main/bin/nix/shell.nix):

```nix
# Traditional nix-shell entrypoint for backward compatibility.
# Allows entering targeted environments: `nix-shell --argstr shell ansible bin/nix/shell.nix`
{ shell ? "default" }:
let
  nixpkgs = import <nixpkgs> {};
  common = import ./common.nix { pkgs = nixpkgs; };
in
nixpkgs.mkShell common.shells.${shell}
```

With this architecture, developers can jump into the default environment with a simple `nix-shell bin/nix/shell.nix`. Or, if they are working on Ansible tasks, they can request the specific shell variant: `nix-shell --argstr shell ansible bin/nix/shell.nix`. The environment automatically bootstraps everything—completely eliminating the need for my massive `ibt` bash scripts!

## Phase 4: Going Deep with `home-manager`

Once I saw the power of Nix at the project level, I wanted that same declarative magic for my personal machine. 

I adopted `home-manager` to manage my Ubuntu laptop's configuration and personal tools declaratively. With `home-manager`, my core development tools—like `zsh`, `direnv`, `git`, and my 1Password SSH integration—are completely codified. 

In my [`my-home-manager`](https://github.com/xNok/my-home-manager) repository, I declare everything I need globally in a few lines:

```nix
  # 1. Declare the tools I want installed globally
  home.packages = [
    pkgs.git pkgs.zsh pkgs.vscode pkgs.docker
    pkgs.uv pkgs.just pkgs._1password-cli pkgs._1password-gui
  ];
```

And instead of fragile bash scripts to configure SSH agent forwarding, I configure Git to automatically sign commits using 1Password directly via Nix:

```nix
  # 2. Configure Git with 1Password SSH signing
  programs.git = {
    enable = true;
    settings = {
      user = { name = "xNok"; email = "nokwebspace@gmail.com"; };
      gpg = { format = "ssh"; };
      "gpg \"ssh\"" = {
        program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
      };
      commit = { gpgsign = true; };
    };
  };
```

If I get a new laptop tomorrow, applying this configuration guarantees my entire terminal and Git workflow are identical to what I had yesterday.

## Phase 5: The Ultimate Setup (Flakes + CI)

While `nix-shell` was great, the real game-changer arrived with **Nix Flakes**. 

Flakes standardized how Nix projects are structured and provided built-in lockfiles (`flake.lock`). This meant that my environments weren't just reproducible in theory; they were hermetically sealed and perfectly deterministic. 

Instead of one monolithic shell, I could now dynamically expose targeted shells for different workflows directly in my [`flake.nix`](https://github.com/xNok/infra-bootstrap-tools/blob/main/flake.nix):

```nix
      {
        # Dynamically create shell endpoints (`nix develop .#<name>`)
        # by mapping over the configurations defined in our common.nix file.
        # This keeps our flake.nix extremely clean.
        devShells = pkgs.lib.mapAttrs (_: shell: pkgs.mkShell shell) common.shells;
      }
```

Now, a developer can run `nix develop .#ansible` to get just the Ansible tooling, or `nix develop .#full` to get everything. 

The final piece of the puzzle was integrating Nix Flakes into my GitHub Actions pipelines. By using the exact same `flake.nix` environment in CI that I use locally, I achieved 100% environment parity. No more "it passes locally but fails in CI because the runner has a different version of Ansible."

## Conclusion

It took several iterations—from clunky Docker containers to massive Bash scripts—but I finally achieved the holy grail of developer experience: **"same config, same env in local, cloud env, and CI."**

Nix has a steep learning curve, but the payoff is immense. If you're tired of fighting environment drift across your local machines, cloud IDEs, and CI pipelines, it might be time to take the Nix pill.
