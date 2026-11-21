---
type: resource
description: Step-by-step setup, configuration, identity enrollment, and troubleshooting for ziti-edge-tunnel daemon on Linux
related_resources:
  - openziti
related_projects:
  - dark-k3s-stack
---

# OpenZiti Client Tunneling (`ziti-edge-tunnel`)

## Overview

The **`ziti-edge-tunnel`** daemon is the lightweight Linux background service that connects client machines (such as developer workstations, CI runners, or edge devices) to an OpenZiti overlay network. It creates a virtual TUN device (`tun0` or `ziti0`), intercepts specified DNS domains and IP ranges, and encrypts outbound traffic directly to the nearest OpenZiti Edge Router over mTLS.

---

## 1. Installation on Linux (Debian / Ubuntu / Pop!_OS)

### Step 1: Add OpenZiti Official Repository
```bash
# Add OpenZiti GPG signing key
curl -sSLf https://get.openziti.io/tun/package-repos.gpg | sudo gpg --dearmor --output /usr/share/keyrings/openziti.gpg
sudo chmod -c +r /usr/share/keyrings/openziti.gpg

# Add stable APT repository (replace noble with your release if needed)
echo "deb [signed-by=/usr/share/keyrings/openziti.gpg] https://packages.openziti.org/zitipax-openziti-deb-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/openziti.list

# Update package index and install daemon
sudo apt update
sudo apt install -y ziti-edge-tunnel
```

---

## 2. Identity Enrollment & Permissions

When an identity is created on the OpenZiti controller, an enrollment JWT file is generated (e.g., `developer-laptop.jwt`). This one-time token must be enrolled to generate the permanent cryptographic identity JSON.

### Step 1: Enroll the Token
```bash
# Enroll JWT to create identity JSON
ziti edge enroll developer-laptop.jwt -o developer-laptop.json
```

### Step 2: Install Identity into System Daemon Directory
The system daemon automatically loads all valid `.json` files placed inside `/opt/openziti/etc/identities/`:

```bash
# Copy identity to daemon directory
sudo cp developer-laptop.json /opt/openziti/etc/identities/

# Apply hardened file permissions (owned by group ziti, readable only by daemon)
sudo chown -R :ziti /opt/openziti/etc/identities
sudo chmod -R ug=rwX,o-rwx /opt/openziti/etc/identities
```

### Step 3: Enable and Start the Systemd Service
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ziti-edge-tunnel.service
```

---

## 3. Verifying Interception & DNS Routing

Once running, verify that `ziti-edge-tunnel` has established a tunnel session:

```bash
# Check service status
systemctl status ziti-edge-tunnel.service

# View tunnel log messages
journalctl -u ziti-edge-tunnel.service -f
```

Look for lines indicating:
- `connected to edge router`
- `intercepting service [k3s-api] on [k3s.ziti:6443]`

### Test Virtual DNS Resolution
Ping or curl the virtual dark service:
```bash
curl -k https://k3s.ziti:6443/version
```
If configured correctly, the request resolves directly through the virtual interface without leaking to upstream public DNS servers.

---

## 4. Operational Troubleshooting

| Symptom | Root Cause | Solution |
| :--- | :--- | :--- |
| **`failed to load identity`** | Invalid permissions or corrupted JSON file. | Ensure permissions are `chmod -R ug=rwX,o-rwx /opt/openziti/etc/identities` and owned by group `ziti`. |
| **`dns lookup failed for *.ziti`** | `systemd-resolved` or local DNS conflict. | Check `/etc/resolv.conf` or verify `resolvectl status tun0`. Restart `systemd-resolved`. |
| **`connection refused / timeout`** | Edge Router unreachable or client not authorized in Service Policy. | Verify edge router port is reachable from client, and identity has `#clients` role assigned to service Dial policy. |
