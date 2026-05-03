# GhostNodes Subproject Blueprint

## Objective

Define the exact contract a new GhostNodes subproject must satisfy before it is exposed in `nodenation`, `ghostnode`, documentation, or release flows.

This blueprint exists to stop three regressions from coming back:

1. menu text promising flows that do not exist
2. installer/runtime paths drifting apart
3. new nodes shipping without reproducible proof

## Non-goals

- not a product roadmap
- not a design spec for the node itself
- not a place for one-off host hacks

If a step only works for one board, distro, or personal machine and cannot be explained, it does not belong in the shared bootstrap path.

## Required repository structure

Every new node must start with:

```text
<project>/
├── pre_install.sh
├── install.sh
├── README.md
├── docker/                  # optional, only when justified
├── logs/                    # if installer/runtime emits managed logs
└── extras/                  # optional
```

Supporting integration points:

- `var/auto.sh` entry
- `tests/test_<project>_install.sh`
- `ghostnode` submenu only after runtime contract is real
- `README.md` or `docs/` updates when user-facing behavior changes

## Phase model for every node

### Phase 1 — Discovery

Before code:

- supported hardware
- supported OS matrix
- storage model
- service/process model
- data paths
- logs and health checks
- automated vs manual install expectations

Deliverable:

- short design note or issue summary with assumptions

### Phase 2 — Bootstrap contract

Add `var/auto.sh` entries for:

- project id
- hardware regex
- architecture
- OS regex
- `pre_install.sh`
- human-readable description

Rule:

- bootstrap routing must be data-driven from `var/auto.sh`
- do not hardcode hardware-only routing in random menu branches

### Phase 3 — Pre-install contract

`pre_install.sh` is responsible for:

- host prerequisites
- base packages
- runtime user preparation
- persistent directory preparation
- safe handoff from staging to `${GN_ROOT}`

Hard requirements:

- `#!/bin/bash`
- `set -euo pipefail`
- clean sourcing of shared shell libs
- no dependency on already-installed project paths when still running from staging
- explicit failure when a required precondition is missing

### Phase 4 — Install contract

`install.sh` is responsible for:

- node binary installation
- config generation
- service registration
- health validation
- operational summary for the user

Hard requirements:

- consumes exported `GN_*` context
- supports `GN_AUTO_INSTALL=true`
- uses explicit service names
- uses explicit config and log paths
- does not silently fallback to legacy names/paths
- surfaces non-zero failures

### Phase 5 — Menu contract

There are two different menu layers and they must not drift:

#### `nodenation`

Purpose:

- install/bootstrap/orchestrate

Minimum:

- automated path if hardware registry exists
- manual path
- user-visible summary of the selected plan
- `0` back and `q` exit

#### `ghostnode`

Purpose:

- operate the installed node

Minimum:

- status
- logs
- start
- stop
- summary of runtime paths/service
- `0` back and `q` exit

Rule:

- `ghostnode` must only ship after installer paths and service names are final

## Menu design standard

Every new submenu must follow:

```text
[1] Primary action
[2] Secondary action
[0] Back   [q] Exit
```

Required behavior:

- `q` exits immediately from any submenu
- `0` returns one level
- warnings are explicit
- automatic choices are shown back to the user before execution
- destructive or expensive operations require confirmation

## Configuration model

Prefer this layering:

1. exported `GN_*` runtime context
2. project-specific exported variables like `SATOSHI_*`
3. generated config files under `${GN_ROOT}/var` when shared with other layers
4. runtime-native config in the service user home only when justified

Do not:

- store critical state only in ephemeral temp files
- hide final config path from the operator
- hardcode personal usernames unless they are part of an intentional runtime contract

## Docker and web integration rules

Use `docker/` only when it adds clear value.

If the subproject includes Compose services:

- keep paths relative to `${GN_ROOT}`
- keep env files explicit
- ensure failure does not print success
- separate install confirmation from compose-up confirmation

If the subproject exposes web control:

- document service ownership
- document ports
- document auth expectations
- document host vs container network assumptions

## Test requirements

Every new subproject must ship with:

### Dedicated install test

At minimum:

- shell parse check
- required function declarations
- config safeguard assertions
- `var/auto.sh` registry match

### Bootstrap coverage

If the node is reachable from `nodenation`, it must survive:

- `tests/test_nodenation_bootstrap.sh`
- `tests/e2e/run_bootstrap_matrix.sh`

### Real-environment expectation

For any install-flow change:

- Debian Bookworm container validation is mandatory
- Ubuntu container validation is strongly recommended

## Acceptance checklist before exposing a new node in the main menu

1. `var/auto.sh` route exists
2. `pre_install.sh` exists and is staged-safe
3. `install.sh` exists and supports automation
4. node has explicit config path, log path, and service name
5. `nodenation` path exists
6. `ghostnode` path exists or is intentionally deferred
7. dedicated test exists
8. bootstrap matrix passes
9. docs are updated

## Template decision flow for future nodes

Use this when implementing `Adam Node`, `Nash Node`, or similar:

### Automated path

- detect hardware
- resolve recommended install mode
- choose default implementation/version if multiple distributions exist
- show summary
- confirm
- run `pre_install.sh`
- promote staging
- run `install.sh`

### Manual path

- choose implementation family
- choose version
- choose storage/runtime mode
- choose optional extras
- show summary
- confirm
- execute

## Known anti-patterns

Do not merge code that:

- adds a main-menu entry without a real install path
- uses runtime paths that the installer never creates
- marks a failed command as success
- hides branch or tarball source from the operator
- depends on implicit helper functions that are not loaded
- introduces `|| true` on critical execution paths

## Recommended first steps for Adam Node / Nash Node

1. write the runtime contract:
   - service name
   - data dir
   - config dir
   - log location
   - supported binaries
2. create `pre_install.sh`
3. create `install.sh`
4. add auto-registry entry
5. create `tests/test_<project>_install.sh`
6. add `nodenation` manual and automated flow
7. add `ghostnode` runtime submenu
8. run container bootstrap matrix
