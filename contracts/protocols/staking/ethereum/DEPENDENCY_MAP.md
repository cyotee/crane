# Ethereum Staking Ports — Dependency Map (D2-FULL)

**Policy:** No new Foundry remapping **aliases**. Imports use existing `@crane/...` paths (and already-configured paths).  
**Mode:** Full project vendoring + transitive unique deps.

## Shared (remap — already in Crane or dual-pin under external)

| Upstream | Crane path |
|----------|------------|
| OZ 4.8/4.9 | `@crane/contracts/external/openzeppelin-contracts/` or `openzeppelin-contracts-v4/` |
| OZ 5.x | `@crane/contracts/external/openzeppelin-contracts-v5/` |
| OZ Upgradeable 4.x | `@crane/contracts/external/openzeppelin-upgradeable-v4/` |
| OZ Upgradeable 5.x | `@crane/contracts/external/openzeppelin-upgradeable-v5/` |
| Solady | `@crane/contracts/external/solady/` |
| forge-std | Foundry / existing remaps |

## Unique transitive (vendored)

| Dep | Location | Used by |
|-----|----------|---------|
| EigenLayer | `contracts/external/eigenlayer/` | ether.fi |
| Aragon OS/apps | `contracts/external/aragon/` | Lido |

## Protocol domain roots

| Protocol | Path | Pin |
|----------|------|-----|
| StakeWise | `contracts/external/stakewise/` | fc70cbe1… |
| ether.fi | `contracts/external/etherfi/` | b4a0968… |
| Lido | `contracts/external/lido/` | 372b02e… |
| Rocket Pool | `contracts/external/rocketpool/` | fef41a4… |
| Frax | thin only — `tokens/stable/frax` | existing |

## Explicitly not deferred

EigenLayer and Aragon **are in scope** when imported by the pin (D2-FULL).
