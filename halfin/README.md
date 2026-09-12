# Halfin Node

Halfin is the GhostNodes base node for edge networking: access point, network ownership, routing, DNS/DHCP coordination and hardware operations.

The protected reference profile is Orange Pi Zero 3 on arm64 Debian Bookworm. `nodenation` detects it through `var/auto.sh`, offers the automated installation, and requires confirmation before applying it.

Halfin may install shared capabilities when its manifest allows them, including Bitcoin Core in pruned mode. That does not make the equipment a Satoshi base node.

Operational references:

- [Network standard](../docs/HALFIN_NETWORK_STANDARD.md)
- [Runtime update layout](../docs/architecture/HALFIN_RUNTIME_LAYOUT.md)
- [Monorepo topology](../docs/architecture/MONOREPO_TOPOLOGY.md)
