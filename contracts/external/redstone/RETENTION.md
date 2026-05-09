# RedStone — retention notice (Crane)

This subtree is a vendored snapshot of the [RedStone Oracle](https://github.com/redstone-finance/redstone-oracles-monorepo) monorepo (~173 `.sol` files across `packages/` — EVM connector, oracle adapters, ERC-7412 helpers, multichain kit, protocol stubs). See `README.md` for upstream's own description.

## Status (2026-05-15)

There are **no consumers of this subtree under `contracts/protocols/`**. The only imports of `@crane/contracts/external/redstone/...` anywhere in the repo are internal — files inside this tree referencing each other.

It is intentionally retained for future reference and as a ready dependency target for a future RedStone-pull-oracle adapter (likely under `contracts/protocols/lending/...` or `contracts/protocols/oracles/`). Treat this directory as a **read-only vendored snapshot**, not as live protocol code.

## When the first consumer arrives

Decide whether this subtree should:

- Stay in `contracts/external/redstone/` as a shared dependency (the Balancer V3 pattern — upstream-pinned source + Diamond consumer in `protocols/`), or
- Promote into `contracts/protocols/oracles/redstone/` as a Diamond-refactored protocol of its own (the Uniswap V3 / Pendle pattern from the 2026-05-15 dedup pass).

See `DEDUPLICATION.md` (§1) at the repo root for the broader rationale.

## Import convention

Going forward, all consumers must use the `@crane/` remapping:

```solidity
import {Foo} from "@crane/contracts/external/redstone/packages/<pkg>/contracts/Foo.sol";
```

No relative imports across the protocol boundary; no bare `contracts/...` paths.
