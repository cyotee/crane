# Utilities Overview

Crane’s `contracts/utils/` libraries are shared building blocks for Repos, Services, tests, and protocol ports. Prefer these over reimplementing sets, AMM math, or hashing in every port — that is part of **reuse already deployed and verified code** at the library level.

## What to read first

| Topic | Page |
|-------|------|
| Address/Bytes/String sets + Repo pattern | [Sets and Set Repos](sets.md) |
| Constant-product AMM math | [ConstProdUtils & Math](math-const-prod.md) |
| Architecture map | [Codebase Map](../CODEBASE_MAP.md) |

## Collections

- **Sets:** `AddressSet`, `Bytes32Set`, `Bytes4Set`, `StringSet`, `UInt256Set` under `utils/collections/sets/` — storage-oriented, 1-indexed Repo APIs.
- **Arrays / helpers:** `BetterArrays` and related Better* helpers.

Used heavily in `ERC2535Repo`, registry Repos, handlers, and comparators.

## Math

- **ConstProdUtils:** shared constant-product quotes, reserve sorting, LP mint/burn helpers (DEX ports + parity tests).
- **Other:** `BetterMath`, fixed-point helpers, `SafeCast` variants.

Protocol-specific quoters (Uniswap V3/V4, Slipstream, Aerodrome, Camelot) live with those ports but often share ConstProdUtils for V2-style math.

## Cryptography & metatx

- EIP-712 / ECDSA helpers under `utils/cryptography/`
- `ERC2771Context` for trusted forwarders
- Message hash utilities

## Tokens & safety

- `SafeERC20` and related transfer helpers
- Nonces / short strings where used by token facets

## Deployment helpers

- CREATE2/CREATE3-oriented helpers (`Creation`, etc.) used by factories
- `BetterEfficientHashLib` for deterministic salts: `abi.encode(type(X).name)._hash()`

## Testing helpers

- Comparators and behavior logging live under `contracts/test/` (see [Testing Patterns](../development/testing.md))
- Transient slot / reentrancy utilities used by access patterns

## See also

- [Sets and Set Repos](sets.md)
- [ConstProdUtils & Math](math-const-prod.md)
- [DEX Integrations](../protocols/dexes.md)
- [Testing Patterns](../development/testing.md)
- [Getting Started](../getting-started.md)
