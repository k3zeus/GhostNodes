# 🚀 Ghost Nodes (NodeNation) — Installation Guide for OrangePi Zero 3

The installation process for **Ghost Nodes (Halfin version)** is designed to be **100% autonomous and hardware-agnostic** in its initial steps. All networking complexity, hardware detection, user creation, and service dependencies are encapsulated within a single bootstrap script (`nodenation`).

---

## 🏗️ 1. Installation Architecture (Bootstrap Flow)

The installation relies on a secure orchestration divided into the following macro-stages, centralized in the main `nodenation` script located at the repository root:

1. **Automatic Memory Bootstrap:** Downloads the code and starts without relying on previous persistent configurations. Content is downloaded to `/tmp/ghostnodes_staging/`.
2. **Hardware Fingerprinting:** Identifies the model (OrangePi Zero 3), architecture (`arm64`), storage, memory, and base OS (Recommended: Debian Bookworm). Saves to `/tmp/ghostnodes_var/hardware.env`.
3. **Pre-requisites and Environment (`halfin/pre_install.sh`):**
   - Guaranteed creation of the `pleb` user with a secure password.
   - Application of official restricted Debian Bookworm `sources.list`.
   - Installation of essential dependencies (Node.js, Python, git, htop, fail2ban).
   - Hiding and deletion of the default legacy user (`orangepi`).
4. **Halfin Node Provisioning (AP and Routing):**
   - Interface Alias rules: Converts `wlx...` interfaces to `wlan1`.
   - `br0` (Network Bridge) setup via `/etc/network/interfaces`.
   - Configures isolated DHCP network service (`dnsmasq`) for `10.21.21.1/24`.
   - Launches the native router via `hostapd` (SSID: `Halfin` operating on a clean 5GHz band, channel 36).
5. **Dashboard Deployment (`halfin/extras/webapp.sh`):**
   - Automated build of the React Frontend.
   - Setup of the FastAPI Backend.
   - Registration of the `ghostnodes-web.service` to start on boot.
6. **Automatic Conclusion:** Moves the finalized project to `/home/pleb/nodenation`, with exact ownership set to the `pleb` user.

---

## 📥 2. Running Installation with a Single Command

Everything is designed to be invoked by a single line of code. Simply plug in your new OrangePi Zero 3, connect the ethernet cable, and run:

```bash
curl -fsSL https://raw.githubusercontent.com/k3zeus/GhostNodes/refs/heads/main/nodenation | sudo bash
```

Once you enter the main menu, you will see the "Hardware Compatible" identification.
**SINGLE STEP:** Choose: `[1] Install Halfin Node` > `[1] Automated Installation`.

> [!NOTE]
> *No other manual Linux steps are required. The system will take control: format wifi network interfaces, initialize docker if applicable, and prepare the `pleb` user for digital sovereignty.*

---

## 🔍 3. Verifying Layers and Services

After completing the bootstrapping process and the necessary reboots, you should validate your OrangePi's behavior:

### Identity & User Verification
SSH login can no longer be done via the default `orangepi` user; it has been completely removed from the host OS.
**Access:** Use the `pleb` user (Default password provided in the script: `Mudar123`).

### Core Network Service Validation
Run the following in your new `pleb` session:

```bash
# 1. Verify if the Soft-Access-Point is On
sudo systemctl status hostapd

# 2. Verify DHCP management for guests and IoTs
sudo systemctl status dnsmasq

# 3. Confirm Network Bridge routing
ip a show br0
```
*(You should see the IP address `10.21.21.1` allocated to the `br0` bridge)*.

### "Sovereignty" Dashboard Verification
Your dashboard and API initialization are now unified and managed by a single service.
- **Unified Web App (React + FastAPI)** running on the default **Port 80**.

Access from your Smartphone by connecting to the **Halfin** Wi-Fi network: `http://10.21.21.1`
*   **Dashboard Control User:** pleb
*   **Initial Dashboard Password:** Mudar123

> [!TIP]
> Thanks to the included RBAC orchestration, you will need to log in as Dashboard Admin. On your first access, test vital Power controls or the Account Management screen (Services > Users). Your hardware supports all natively managed platform commands.
