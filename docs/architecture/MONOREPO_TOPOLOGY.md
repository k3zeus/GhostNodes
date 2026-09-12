# GhostNodes Monorepo Topology

## Status

Approved on 2026-09-11. This document is the authoritative taxonomy for the repository reorganization.

## One repository, one base installation

GhostNodes is one Git monorepo. Its nodes are first-level subprojects, not nested Git repositories. Each equipment receives exactly one base node installation. A second base node must be refused instead of being installed beside or over the first one.

A base node may opt into shared tools through its manifest. For example, Halfin can install Bitcoin Core in pruned mode as a shared capability. That does not turn the equipment into a Satoshi base installation.

## Approved nodes

| Directory | Status | Product responsibility |
| --- | --- | --- |
| `halfin/` | Active | Edge networking, access point, routing and hardware baseline. |
| `satoshi/` | Active | Dedicated Bitcoin full or pruned node. |
| `nick/` | Planned | Lightning node. |
| `adam/` | Planned | Sovereign identity node. |
| `fiatjaf/` | Planned | Nostr node. |
| `nash/` | Planned | Scope must be recovered and approved before implementation. |
| `craig/` | Planned | Experimental scope; implementation remains blocked until specified. |

Planned means that the directory carries its product contract and README, but contains no installer, runtime service or automatic hardware profile yet.

## Shared areas

| Area | Responsibility |
| --- | --- |
| `lib/` | Node-neutral shell libraries and shared contracts. |
| `bin/` | Repository-level developer and maintenance utilities. |
| `var/` | Registry, detected hardware, installation state and other root-level state. |
| `web/` | Shared management control plane, never a base node. |
| `shared/` | Reusable tools such as Vault, Hermes, Tailscale, Nostr and NetBird. |
| `incubator/` | Unapproved or unowned experiments only. |
| `docs/` | Architecture, node contracts and operational documentation. |
| `tests/` | Unit, integration and disposable end-to-end validation. |
| `archive/` | Historical artifacts kept outside active source paths. |

Tools in `shared/` are selectable capabilities. A node manifest declares which tools it supports and how they are configured. A tool does not silently imply that a node is installed.

## Hardware profile contract

The established automatic installation flow is retained:

1. `nodenation` detects model, architecture, resources and operating system.
2. It stages the project in `/tmp` and loads the profile registry from the staged source.
3. It offers a matching profile; it never applies it without confirmation.
4. The selected node performs its pre-installation work.
5. Only after success does the staged project become the definitive root installation.

`var/auto.sh` remains the compatibility registry during the migration. The Orange Pi Zero 3, arm64, Debian Bookworm profile for Halfin is a protected baseline and must remain covered by regression tests. Future manifests may replace the registry implementation only through an adapter that preserves the same selection and confirmation behaviour.

## Boundaries

- `halfin/lib/` may contain Halfin-specific code only. Shared code belongs in root `lib/`.
- `ghostnode` and `web/` consume node manifests; they must not hardcode Halfin paths, hostnames or service assumptions.
- Root state must identify the installed base node and reject a competing base node installation.
- No production tool, secret, generated data or historical snapshot belongs in an active node source path.

## Migration order

1. Establish the taxonomy and node contracts.
2. Preserve `var/auto.sh` and its automated Halfin profile with tests.
3. Introduce a root node manifest contract and an installed-base-node state.
4. Move shared libraries out of Halfin with compatibility shims.
5. Move reusable tools to `shared/` and migrate their callers.
6. Make `ghostnode`, `nodenation` and `web/` consume manifests.
7. Move historical material to `archive/` only after a content inventory and reproducible restore check.
