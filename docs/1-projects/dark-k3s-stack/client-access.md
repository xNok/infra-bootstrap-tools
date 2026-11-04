---
type: project
status: active
description: Client access architecture and configuration guide for OpenZiti zero-trust services in the Dark K3s Stack
related_projects:
  - dark-k3s-stack
related_resources:
  - openziti
related_areas:
  - networking
  - security-identity
---

# Dark K3s Stack: Client Access Guide

This guide details how clients (laptops, mobile devices, and developer tools) securely connect to the Dark K3s Stack without opening public ports, configuring Ingress controllers, or relying on ad-hoc local port forwarding.

---

## 1. Zero-Trust Access Models

The Dark K3s Stack provisions internal services that are bound to `127.0.0.1` or in-cluster `ClusterIP` addresses. They are only reachable through the OpenZiti overlay fabric:

| Access Model | Example | Root / Daemon Required? | How it connects |
| :--- | :--- | :--- | :--- |
| **Zitified CLI** | `kubeztl` | **No** (SDK compiled in) | Runs standalone; directly dials `k3s.ziti` using `~/.ziti/laptop-client.json` |
| **Transparent OS Intercept** | `ziti-edge-tunnel` (Linux)<br>`Ziti Mobile Edge` (iOS/Android) | **Yes** (Runs as system daemon / OS VPN) | Native domain interception (`http://flux.ziti`) via virtual TUN device |

> [!NOTE]
> Ad-hoc userspace port-forwarding helpers (listening on `localhost:<port>`) are intentionally avoided in favor of transparent OS tunnelers. Transparent interception allows native browser navigation (`http://flux.ziti`), preserves standard ports (80/443), and requires no per-service manual proxy scripts.

---

## 2. Linux Client Setup (Ubuntu 24.04 / Debian)

### Why NOT Home Manager (`systemd.user.services`)?

It is tempting to manage `ziti-edge-tunnel` inside a Home Manager configuration as a user systemd service. However, **this does not work cleanly**:
1. **Kernel TUN Device**: Creating and managing the virtual network interface (`tun0` / `/dev/net/tun`) and host IP routing requires `CAP_NET_ADMIN` / root privileges.
2. **System DNS Management**: Intercepting `.ziti` domains requires controlling `systemd-resolved` via D-Bus (`org.freedesktop.resolve1.Link.SetLinkDomains`), which an unprivileged user session cannot do.
3. **Official Package**: The official Debian/Ubuntu package ships with a fully managed systemd system unit (`/lib/systemd/system/ziti-edge-tunnel.service`) and handles group permissions (`ziti` group) cleanly.

### Installation Steps

#### 1. Add OpenZiti Apt Repository
```bash
# Install signing key
curl -sSLf https://get.openziti.io/tun/package-repos.gpg | sudo gpg --dearmor --output /usr/share/keyrings/openziti.gpg
sudo chmod -c +r /usr/share/keyrings/openziti.gpg

# Add stable repository (Ubuntu 24.04 noble)
echo "deb [signed-by=/usr/share/keyrings/openziti.gpg] https://packages.openziti.org/zitipax-openziti-deb-stable noble main" | sudo tee /etc/apt/sources.list.d/openziti.list

# Install ziti-edge-tunnel
sudo apt update && sudo apt install -y ziti-edge-tunnel
```

#### 2. Enable and Start the System Service
```bash
sudo systemctl enable --now ziti-edge-tunnel.service
```

#### 3. Load Your Identity
Copy your enrolled identity (e.g., `~/.ziti/laptop-client.json`) to the tunneler identities directory:
```bash
sudo cp ~/.ziti/laptop-client.json /opt/openziti/etc/identities/
sudo chown -R :ziti /opt/openziti/etc/identities
sudo chmod -R ug=rwX,o-rwx /opt/openziti/etc/identities
sudo systemctl restart ziti-edge-tunnel.service
```

Alternatively, if you have an un-enrolled token (`laptop-client.jwt`), you can enroll it dynamically:
```bash
sudo ziti-edge-tunnel add --jwt "$(< ~/.ziti/laptop-client.jwt)" --identity laptop-client
```

#### 4. Verify System Resolver
Check that `systemd-resolved` has bound the `ziti-tunnel` link for `.ziti` domain resolution:
```bash
resolvectl status ziti-tunnel
```

---

## 3. Mobile Client Setup (iOS / Android)

1. **Install App**: Download **Ziti Mobile Edge** from Apple App Store or Google Play Store.
2. **Enroll Identity**:
   - Open Ziti Mobile Edge and tap **Add Identity** / Scan QR Code.
   - Scan the enrollment QR code or import `mobile-client.jwt`.
3. **Enable Tunnel**:
   - Toggle the identity switch to **ON**.
   - Allow the operating system VPN configuration prompt.
4. **Browse Services**:
   - Once connected, open Safari or Chrome on your phone and navigate to:
     ```text
     http://flux.ziti
     ```
   - The Flux Operator Web UI dashboard will load directly over the encrypted cellular/Wi-Fi tunnel.

---

## 4. Available Dark Services

| Service Name | Intercept Address | Cluster Destination | Access Policy | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `k3s` | `k3s.ziti:6443` | `127.0.0.1:6443` | `#k3s-clients` | Kubernetes API control plane |
| `flux-ui` | `flux.ziti:80`<br>`flux.ziti:9080` | `flux-operator.flux-system.svc.cluster.local:9080` | `#k3s-clients` | Flux Operator status dashboard |

---

## 5. Summary of Client Tools

* **Day-to-day Kubernetes operations**: Use [`kubeztl`](file:///home/xnok/.gemini/antigravity/worktrees/infra-bootstrap-tools/update_k3s_setup/bin/nix/pkgs/kubeztl.nix) in your terminal without needing any VPN or background daemon active.
* **Web UI / Browser access**: Run `ziti-edge-tunnel` on your laptop or `Ziti Mobile Edge` on your phone to resolve `http://flux.ziti` natively in your browser.
