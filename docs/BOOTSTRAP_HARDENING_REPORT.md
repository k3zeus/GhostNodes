# GhostNodes Bootstrap Hardening Report

## Objective

Document the installer/bootstrap issues that were fixed, the proof that exists today, and the implementation rules required so new subprojects do not reintroduce the same classes of failure.

## Scope

This report covers:

- `nodenation` bootstrap and main menu orchestration
- `ghostnode` submenu alignment
- `halfin` Wi-Fi/TUI regressions already corrected
- `satoshi` installer/menu restructuring
- current proof assets in `tests/` and `tests/e2e/`

It does not claim that every external service image, apt repository, or upstream node binary is always available. Those remain external runtime dependencies.

## Root causes already corrected

### 1. Bootstrap branch drift

Problem:

- the raw bootstrap entrypoint could come from `main`
- but the tarball payload was still pointing at another branch

Impact:

- users thought they were installing `main`
- runtime behavior came from a different branch snapshot

Correction:

- `nodenation` now points to `main.tar.gz`
- the raw `curl .../main/nodenation | bash` path and the payload branch are aligned

### 2. Menu and shell library desynchronization

Problem:

- scripts like `ghostnode`, `wifi_show.sh`, `wifi_connect.sh` and `banner.sh` could execute with partially-loaded `_GN_*` guards
- this left UI variables and helper functions undefined

Observed failures:

- `BOLD: unbound variable`
- `RED: unbound variable`
- `header: command not found`
- `section/log_msg/banner/sep: command not found`

Correction:

- hardened bootstrap/source guards
- normalized helper loading
- added compatibility alias for `header()`
- forced child scripts to load clean shell context

### 3. False-positive success in Docker orchestration

Problem:

- Docker/Compose steps could continue after refusal or partial failure
- menu flow implied success even when `docker compose up -d` failed

Correction:

- explicit confirmation gates for Docker, Compose, Cockpit
- no auto-advance after refusal
- failure paths no longer report success

### 4. Satoshi installer/menu mismatch

Problem:

- main menu exposed `Satoshi Node`
- actual flow did not let the user choose `Core` vs `Knots`, version, `Full` vs `Pruned`, or prune size
- `ghostnode` Satoshi submenu still referenced old service names and paths

Correction:

- `nodenation` now has two real flows:
  - automated install
  - manual guided install
- `satoshi/install.sh` now accepts:
  - implementation
  - version
  - full/pruned mode
  - prune size in GB
- `ghostnode` now points to:
  - `satoshi-bitcoind.service`
  - `/home/bitcoin/.bitcoin`
  - `${GN_ROOT}/satoshi/logs/bitcoin.log`

### 5. Un-testable bootstrap entrypoint

Problem:

- `nodenation` executed immediately on source
- this made function-level contract tests fragile and discouraged regression coverage

Correction:

- `nodenation` now distinguishes direct execution from sourcing
- `main()` is explicit
- tests can source the file and exercise helper/menu functions safely
- CI/container validation can opt into `GN_BOOTSTRAP_ALLOW_NONTTY=true` instead of depending on `/dev/tty`

## Current proof assets

### Shell contract tests

- `tests/test_auto_registry.sh`
- `tests/test_halfin_install.sh`
- `tests/test_satoshi_install.sh`
- `tests/test_nodenation_bootstrap.sh`

### Real bootstrap tests

- `tests/e2e/container_bootstrap_matrix.sh`
- `tests/e2e/run_bootstrap_matrix.sh`
- `tests/e2e/Dockerfile.debian`
- `tests/e2e/Dockerfile.ubuntu`

What the real bootstrap test proves:

1. `curl | bash` works against a served snapshot of the current workspace
2. `--detect-hw` runs inside a real Debian/Ubuntu container
3. `--download-only` builds a real staging tree in `/tmp/ghostnodes_staging`
4. the downloaded tree contains the expected project payload for `halfin` and `satoshi`
5. shell contract suites still pass after the bootstrap step

What it does not prove:

- public internet availability of upstream repos at all times
- Bitcoin sync completion
- container images from third-party registries always existing
- host-specific Wi-Fi hardware behavior

## Required acceptance checklist before claiming "stable"

For any future bootstrap or submenu change:

1. `bash -n` passes for every changed shell file
2. the affected dedicated test script passes
3. `tests/test_nodenation_bootstrap.sh` passes if `nodenation` changed
4. `tests/e2e/run_bootstrap_matrix.sh` passes if bootstrap/menu/install flow changed
5. docs are updated if:
   - menu text changed
   - new subproject was added
   - install contract changed

## Implementation rules for new subprojects

### Registry and routing

Every subproject must register in `var/auto.sh` with:

- target project id
- hardware regex
- architecture
- OS regex
- `pre_install.sh` path
- human-readable description

No subproject should be reachable only by hardcoded if/else logic in `nodenation`.

### Menu contract

Every main-menu subproject must provide:

1. entry from `menu_principal`
2. an installation decision layer
3. an automated path when hardware mapping exists
4. a manual path
5. `0` back and `q` exit in every submenu

### Installer contract

Every `install.sh` must:

- use `set -euo pipefail`
- accept exported `GN_*` context
- accept `GN_AUTO_INSTALL=true`
- use explicit service names
- use explicit data paths
- avoid silent fallback to legacy paths
- persist configuration under `${GN_ROOT}` or clearly-documented runtime paths

### Operational menu contract

If a subproject is exposed in `ghostnode`, the runtime menu must match the installer exactly:

- same service name
- same config path
- same log path
- same operational binary names

The runtime menu is not allowed to guess legacy paths.

## Anti-regression rules

Do not reintroduce:

- branch mismatch between bootstrap entrypoint and payload tarball
- `|| true` on submenu execution paths that should surface real failure
- legacy paths like `/home/pleb/.bitcoin` when the installer writes elsewhere
- helper names that are not defined in the loaded shell libs
- hidden automatic mode selection without user-visible summary

## Next implementation template for Adam Node / Nash Node

Minimum order:

1. create `adam/` or `nash/`
2. add `pre_install.sh`
3. add `install.sh`
4. add optional `docker/`
5. register hardware in `var/auto.sh`
6. add main menu entry in `nodenation`
7. add operational submenu in `ghostnode` only after service/path contract exists
8. add dedicated test script in `tests/`
9. run `tests/e2e/run_bootstrap_matrix.sh`

## Recommended next hardening steps

1. add a non-interactive test mode for `ghostnode`
2. standardize install summaries for every subproject
3. split `nodenation` manual-config menu into smaller testable helpers
4. add one Ubuntu-specific dedicated install test for `satoshi`
5. add a release checklist that blocks merge when bootstrap e2e is not green
