---
title: "1Password CLI"
weight: 2
---

The 1Password CLI (`op`) provides a command-line interface to interact with your 1Password vaults. It allows you to securely fetch secrets, credentials, and other sensitive information stored in 1Password, making it useful for scripting and automation.

## Tutorial

Here's a basic example of how to use the `op` CLI to read a secret:

```bash
# Read a secret from a specific vault
op read "op://<YourVault>/<YourSecretItem>/password"
```

Make sure to replace `<YourVault>` and `<YourSecretItem>` with actual vault and item names or placeholders.

## Usage in this Project

This project recommends using 1Password CLI for managing sensitive data like API tokens, SSH keys, and other credentials needed by Ansible and Terraform.

*   **Secret Retrieval**: The Ansible playbooks are configured to use the `op` lookup plugin to fetch secrets directly from 1Password vaults during runtime. This avoids hardcoding sensitive information in your configuration files. You can see examples in `ansible/playbooks/host_vars/localhost.yml`.
*   **Setup**: The `./bin/bash/setup.sh 1password-cli` script can help you install the 1Password CLI.

You will need to have a 1Password account and the CLI configured to use it with this project if you choose this method for secret management.
