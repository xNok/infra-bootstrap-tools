---
title: "A Walkthrough of My Home Manager Configuration"
date: 2026-05-03
draft: true
author: xNok
summary: "A section-by-section tour of my personal home-manager setup: what each piece does, why I chose it, and the lessons learned along the way."
tags:
  - Nix
  - Home Manager
  - Developer Experience
  - Dotfiles
---

# A Walkthrough of My Home Manager Configuration

In [The Holy Grail of Development Environments](/blog/journey-to-nix/), I briefly mentioned `home-manager` as the tool I use to manage my personal Ubuntu laptop declaratively. This article is the companion deep-dive: a section-by-section tour of my actual [`home.nix`](https://github.com/xNok/my-home-manager) file, with learnings and rationale for each choice.

The philosophy here is simple: **everything that can be codified, should be**. No more forgotten manual steps when reinstalling a machine.

---

## The Basics: Identity and Version Lock

```nix
home.username = "xnok";
home.homeDirectory = "/home/xnok";
home.stateVersion = "25.05";
```

The `stateVersion` is a critical field that trips up many beginners. It does **not** mean "I want home-manager version 25.05". It means "my configuration was written targeting the 25.05 release semantics." You set it once at initial setup and leave it alone. Changing it after the fact can break your configuration in subtle ways.

> **Learning**: Never update `stateVersion` unless you've carefully read the home-manager release notes and intentionally want to migrate. It is a compatibility marker, not a version pin.

---

## Allowing Unfree Packages

```nix
nixpkgs.config.allowUnfree = true;
```

By default, Nix only allows packages with open-source licenses. Tools like `vscode`, `_1password-gui`, and `freelens-bin` are proprietary, so this flag is necessary. Without it, the build fails with a licensing error.

> **Learning**: Nix takes software licensing seriously at the package manager level. You have to explicitly opt in to unfree software—which also makes it easy to audit exactly which closed-source tools you rely on.

---

## Package Management: Categorized `home.packages`

```nix
home.packages = [
  # core
  pkgs.git
  pkgs.gh
  pkgs.zsh
  pkgs.vscode
  pkgs.docker
  pkgs.nodejs_22

  # dev tools
  pkgs.uv
  pkgs.just

  # more
  pkgs.gemini-cli
  pkgs._1password-cli
  pkgs._1password-gui

  # k8s
  pkgs.kind
  pkgs.kubectl
  pkgs.freelens-bin

  pkgs.ffmpeg-full
];
```

This is the heart of the home-manager config: a flat list of every tool I want available globally. Packages are grouped with comments for readability.

A few notable choices:
- **`pkgs.uv`** – A fast Python package manager (written in Rust) that I use for Python tooling instead of pip.
- **`pkgs.just`** – A modern `make` alternative; I use it as a project-level command runner.
- **`pkgs.nodejs_22`** – Pinned to Node 22 rather than `pkgs.nodejs` (which would follow unstable). Pinning a major version gives stability without locking to a patch version.
- **`pkgs.ffmpeg-full`** – The full build variant with all codecs enabled; the default `pkgs.ffmpeg` strips many codecs to minimize the closure size.

> **Learning**: Nix's package names are not always obvious. The pattern `pkgs.<tool>-<variant>` (e.g., `ffmpeg-full`, `nodejs_22`) is common. When in doubt, search [search.nixos.org](https://search.nixos.org/packages) to find the exact attribute name.

---

## Dotfiles: `home.file`

```nix
home.file = {
  ".npmrc".text = ''
    prefix=~/.npm-global
  '';

  ".config/nix/nix.conf".text = ''
    experimental-features = nix-command flakes
  '';
};
```

`home.file` manages arbitrary dotfiles by writing content directly into the Nix store and symlinking them into `$HOME`. Here I use it for two things:

1. **`.npmrc`** – Setting the npm global prefix to `~/.npm-global` avoids needing `sudo` for `npm install -g`. Combined with the `sessionPath` below, globally installed npm packages are available without any extra setup.

2. **`nix.conf`** – Enabling `nix-command` and `flakes` experimental features at the user level. Without this, every `nix develop` or `nix build` command would error unless you pass `--experimental-features` each time.

> **Learning**: You can bootstrap Nix Flakes support *using* home-manager itself. The first time, you need to enable flakes manually; after that, home-manager manages it for you. It's a one-time bootstrap chicken-and-egg situation.

---

## Session Path

```nix
home.sessionPath = [
  "${config.home.homeDirectory}/.local/bin"
  "${config.home.homeDirectory}/.npm-global/bin"
];
```

`home.sessionPath` appends entries to `$PATH` when a shell managed by home-manager starts. The two entries cover:
- `~/.local/bin` – The standard XDG location for user-installed binaries (used by `uv tool install`, `pipx`, etc.).
- `~/.npm-global/bin` – Where `npm install -g` places executables when using our custom `.npmrc` prefix.

> **Learning**: home-manager's `sessionPath` is cleaner than manually editing `.zshrc` or `.bashrc` because it composes with the rest of your configuration and survives shell upgrades.

---

## Session Variables

```nix
home.sessionVariables = {
  EDITOR = "code";
};
```

Setting `EDITOR` to `code` means that CLI tools that spawn an editor (like `git commit` without `-m`, or `crontab -e`) will open VS Code instead of Vim. Note that VS Code needs the `--wait` flag to block the calling process—this is handled in the Git config below.

---

## Direnv + nix-direnv

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

This is one of the highest-leverage options in the entire config. `direnv` watches for `.envrc` files as you `cd` between directories and automatically loads/unloads environment variables. `nix-direnv` extends this with a Nix-aware backend that caches evaluated flakes so shell entry is near-instant.

With a simple `.envrc` in any project:

```bash
use flake
```

...the correct `nix develop` shell loads automatically whenever you enter that directory.

> **Learning**: Without `nix-direnv`, every directory entry re-evaluates the flake from scratch, which can take several seconds. The `nix-direnv` caching layer makes this transparent and fast. Always enable both together.

---

## Zsh: Oh My Zsh + Powerlevel10k

```nix
programs.zsh = {
  enable = true;

  initContent = "source ~/.p10k.zsh";
  plugins = [
    {
      name = "powerlevel10k";
      src = pkgs.zsh-powerlevel10k;
      file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }
  ];

  oh-my-zsh = {
    enable = true;
    plugins = [ "git" ];
  };

  shellAliases = {
    code = "code --no-sandbox";
    nix-conf = "code ~/.config/home-manager/home.nix";
  };
};
```

Home-manager generates your `.zshrc` entirely from this block. Key points:

- **`initContent`** – Appends arbitrary Zsh initialization, here sourcing the Powerlevel10k prompt config (`.p10k.zsh` is generated interactively by running `p10k configure` once and is not managed by Nix).
- **`plugins`** – Installs Nix packages as Zsh plugins. Powerlevel10k is a highly customizable prompt theme.
- **`oh-my-zsh`** – The `git` plugin adds a large set of useful git aliases and prompt indicators.
- **`shellAliases`**:
  - `code --no-sandbox` is needed because VS Code's sandbox mode conflicts with how it runs inside a Nix-managed environment on Linux.
  - `nix-conf` is a productivity shortcut: I can instantly open my home-manager config from any terminal with one word.

> **Learning**: The Powerlevel10k config file (`.p10k.zsh`) is intentionally kept outside of home-manager because it's generated interactively. Mixing interactive wizard output with declarative Nix config is messy. The hybrid approach—Nix installs the theme, the wizard generates the config—works well in practice.

---

## Git: Signing Commits with 1Password

```nix
programs.git = {
  enable = true;
  settings = {
    user = {
      name = "xNok";
      email = "nokwebspace@gmail.com";
      signingKey = "ssh-ed25519 AAAA...";
    };
    core = {
      editor = "code --wait --no-sandbox";
    };
    gpg = { format = "ssh"; };
    "gpg \"ssh\"" = {
      program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
    };
    commit = { gpgsign = true; };
  };
};
```

This configures Git to sign every commit using an SSH key stored in 1Password, via 1Password's `op-ssh-sign` helper binary. The flow:

1. Git needs to sign a commit.
2. Git calls the `op-ssh-sign` program (discovered through the 1Password GUI package using `lib.getExe'`).
3. `op-ssh-sign` prompts 1Password (via the system tray agent) to authorize the signature.
4. The commit is signed with the SSH key that never leaves 1Password's vault.

The `${lib.getExe' pkgs._1password-gui "op-ssh-sign"}` expression is particularly clever: instead of hardcoding the binary path, it asks Nix to resolve it from the `_1password-gui` package at build time. The path is always correct regardless of Nix store hash changes.

Note `core.editor = "code --wait --no-sandbox"` – `--wait` makes the terminal block until you close the VS Code tab, so Git knows when you've finished your commit message.

> **Learning**: Using `lib.getExe'` to reference binaries from other packages is the idiomatic Nix way to avoid hardcoded store paths. It makes your config resilient to Nix store reorganizations.

---

## SSH: 1Password Agent

```nix
programs.ssh = {
  enable = true;
  enableDefaultConfig = false;
  matchBlocks = {
    "*" = {
      host = "*";
      identityAgent = "~/.1password/agent.sock";
    };
  };
};
```

This configures SSH to use 1Password's SSH agent for all connections. The agent socket at `~/.1password/agent.sock` is created by the 1Password GUI running in the background. When SSH needs a key, it asks the agent, which in turn asks 1Password to authorize the use of the stored key.

`enableDefaultConfig = false` prevents home-manager from prepending an opinionated default `~/.ssh/config` block that could conflict with our wildcard match block.

> **Learning**: Setting `identityAgent` globally with `host = "*"` means you never have to think about which key to use. 1Password manages key selection based on what's in your vault. The trade-off is you need the GUI running—hence the systemd service below.

---

## Systemd: Auto-starting 1Password

```nix
systemd.user.services.onepassword = {
  Unit = {
    Description = "1Password GUI";
    After = [ "graphical-session.target" ];
  };
  Service = {
    ExecStart = "${pkgs._1password-gui}/bin/1password";
    Restart = "always";
  };
  Install = {
    WantedBy = [ "graphical-session.target" ];
  };
};
```

Home-manager can manage `systemd` user services—processes that run under your user account and start with your graphical session. This service auto-starts 1Password so the SSH agent socket is always available from the moment you log in.

`After = [ "graphical-session.target" ]` ensures the service only starts once the desktop environment is up. `Restart = "always"` means it will restart if it crashes.

> **Learning**: Managing autostart applications via systemd user services (rather than desktop-environment-specific autostart files) is more portable and gives you proper logging via `journalctl --user -u onepassword`. It's also fully declarative—no hidden files in `~/.config/autostart`.

---

## Applying the Configuration

After editing `home.nix`, apply with:

```bash
home-manager switch
```

If you want to do a dry run first to see what would change:

```bash
home-manager build
```

And if something goes wrong, roll back to the previous generation:

```bash
home-manager generations
home-manager switch --switch-generation <number>
```

> **Learning**: Home-manager keeps a full history of every applied generation. You can always roll back. This is one of the most underrated features—fearless configuration changes knowing you can always undo.

---

## Relevant Resources

- **[`my-home-manager` GitHub Repo](https://github.com/xNok/my-home-manager)**: The full source of this configuration.
- **[Home Manager Options Search](https://home-manager-options.extranix.com/)**: The best way to discover available `programs.*` and `services.*` options.
- **[Home Manager Manual](https://nix-community.github.io/home-manager/)**: Official documentation.
- **[The Journey to Nix](/blog/journey-to-nix/)**: The broader story of how I got here.
- **[NixOS Search](https://search.nixos.org/packages)**: For finding the correct Nix attribute name for any package.
