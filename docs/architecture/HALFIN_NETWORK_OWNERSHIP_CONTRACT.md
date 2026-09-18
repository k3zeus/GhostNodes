# Halfin Network Ownership Contract

**Status:** mandatory baseline for Halfin installations  
**Applies to:** Orange Pi Zero 3 with two Wi-Fi radios; the primary wired uplink is `end0`.

## Purpose

This contract makes network ownership deterministic before AP, DNS/DHCP, Docker, or application services are installed. No installation stage may infer the primary wired interface from the temporary default route: a saved Wi-Fi connection can be present before Ethernet, and that must never change the role of `wlan1`.

## Immutable roles

| Interface | Role | Owner | Addressing | Prohibited owner/configuration |
| --- | --- | --- | --- | --- |
| `end0` | Primary wired uplink | ifupdown | Explicit DHCP, metric 100 | NetworkManager, Wi-Fi recovery service, AP bridge |
| `wlan0` | Halfin access point radio | hostapd + `br0` preparation | No independent IPv4; clients use `br0` | NetworkManager, ifupdown client/DHCP, wpa_supplicant client |
| `br0` | Halfin AP LAN bridge | ifupdown + AP health service | Static `10.21.21.1/24` | NetworkManager, a second DHCP/DNS owner |
| `wlan1` | Optional client/failover Wi-Fi | NetworkManager only | Saved NM profile; higher route metric/policy routing | ifupdown, dhclient, wpa_supplicant direct, AP service |

`end0` and `wlan1` may both be connected. The wired route is preferred; the policy table for `wlan1` preserves replies sourced from the wireless address when both links use the same LAN.

## Installation order

1. Detect and persist Wi-Fi roles by MAC: `wlan0` for AP and `wlan1` for client when a second radio exists.
2. Select `end0` as `PRIMARY_WAN_IFACE` whenever it exists. Only hardware without `end0` may use an explicit override or route-derived fallback.
3. Write `/etc/network/interfaces.d/halfin-wan` for `end0` only. Rewriting this fragment removes a previous mistaken Wi-Fi declaration.
4. Mark `end0`, `wlan0`, and `br0` unmanaged in NetworkManager; retain `wlan1` as managed.
5. Install `halfin-end0-ensure.service` with `HALFIN_PRIMARY_UPLINK=end0`. It validates an existing lease first and invokes ifupdown only for `end0` when necessary.
6. Configure `br0`, hostapd, the single selected DHCP/DNS owner, routing, and AP health checks.

## Required TDD checks

- `configure_wan_dhcp.sh` emits only `end0` in the Halfin ifupdown fragment.
- The generated service contains `HALFIN_PRIMARY_UPLINK=end0`.
- `wlan1` does not appear in `/etc/network/interfaces` or any fragment.
- NetworkManager reports `wlan1` managed and able to activate a saved profile.
- `end0` and `wlan1` may each hold a default route; `end0` retains the preferred metric.
- A reboot returns the AP, DNS/DHCP owner, NetworkManager, and `halfin-end0-ensure.service` without manual repair.
- With the Ethernet cable absent, halfin-end0-ensure.service exits successfully without running DHCP; wlan1 remains the managed failover uplink.

## Incident record — 2026-09-18

A prior installer selected `wlan1` from the temporary default route, wrote it into ifupdown, and passed that value to the service intended for `end0`. At reboot NetworkManager consequently marked `wlan1` unmanaged, while the recovery unit launched DHCP on the wrong interface. The installer now pins the wired primary role before writing either configuration. This is a regression contract, not a runtime preference.

## Safe recovery

Run only the Orange Pi network stage after preserving the current configuration. It rewrites the Halfin-owned `end0` fragment, refreshes NetworkManager ownership, and reinstalls the guard. Do not add `wlan1` to ifupdown as a workaround.