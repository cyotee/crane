# Sets and Set Repos

Crane provides type-specific set libraries optimized for **Diamond storage** (mutate storage in place, avoid unnecessary copies).

## Types

| Set | Repo | Typical use |
|-----|------|-------------|
| `AddressSet` | `AddressSetRepo` | Facet addresses, registry membership |
| `Bytes32Set` | `Bytes32SetRepo` | General 32-byte keys |
| `Bytes4Set` | `Bytes4SetRepo` | Selectors (ERC2535, comparators) |
| `StringSet` | `StringSetRepo` | Named registries |
| `UInt256Set` | `UInt256SetRepo` | Numeric id sets |

Path: `contracts/utils/collections/sets/`.

## Storage shape (AddressSet example)

```solidity
struct AddressSet {
    mapping(address => uint256) indexes; // 0 = absent; values are 1-indexed
    address[] values;
}
```

## Repo operations

Common pattern on `*SetRepo` libraries:

- `_add` / `_remove` (idempotent membership)
- `_contains`, `_length`, `_index`, `_indexOf`
- `_values` (often returns storage pointer for gas)
- `_asArray`, `_range`
- `_addAsc` / `_removeAsc` / `_sortAsc` — ordered variants for deterministic enumeration

Repos typically expose dual overloads: operate on an explicit `Storage`/`set` parameter, or on a default layout when applicable.

## Why not OpenZeppelin EnumerableSet only?

Crane sets are tuned for:

- Direct storage mutation in Diamond Repos
- Ascending/ordered membership for deterministic walks (registries, facets)
- Multi-value add/remove loops without copying entire sets into memory unnecessarily

## Where they appear

- `FacetRegistryRepo` — facets by name/interface/function
- `ERC2535Repo` — facet addresses + per-facet selector sets
- `DiamondFactoryPackageRegistryRepo` — package membership
- `OperableRepo` — function operator sets
- Test handlers and `Bytes4SetComparator` / comparator repos

## Testing tip

Handlers and Behavior libraries often track expected sets in ghost state and assert equality with on-chain membership after fuzz ops. See [Testing Patterns](../development/testing.md).

## See also

- [Utilities Overview](overview.md)
- [Registries](../concepts/registries.md)
- [Codebase Map](../CODEBASE_MAP.md)
- [Facet-Target-Repo](../concepts/facet-target-repo.md)
