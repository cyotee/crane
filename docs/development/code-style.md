# Code Style

Crane enforces a strict set of conventions to keep large Diamond codebases consistent and auditable.

## Section Headers

Major sections use 78-character blocks:

```solidity
/* -------------------------------------------------------------------------- */
/*                             Section Name                                   */
/* -------------------------------------------------------------------------- */
```

Subsections use the shorter form:

```solidity
/* ------ Feature Name ------ */
```

## Imports

Group in this order:

1. External libraries (`@openzeppelin`, `@solady`).
2. Crane interfaces (`@crane/contracts/interfaces/...`).
3. Crane contracts (`@crane/contracts/...`).
4. Test utilities (only in test files).

Use the defined remappings:

- `@crane/`
- `@solady/`
- `@openzeppelin/`
- `forge-std/`

## Function Order

Within each contract or library:

1. Constructor
2. Receive / Fallback
3. External
4. Public
5. Internal
6. Private

## Naming

| Element                  | Convention                  | Example                          |
|--------------------------|-----------------------------|----------------------------------|
| Storage access           | `_layoutStruct()`                 | `_layoutStruct()`, `_layoutStruct(bytes32)`  |
| Initialization           | `_initialize(...)`          | `_initialize(address owner_)`    |
| Internal state functions | `_functionName(...)`        | `_isOperator(address)`           |
| Guard functions          | `_onlyXxx(...)`             | `_onlyOperator()`                |
| Modifiers                | `onlyXxx`                   | `onlyOperator`                   |
| Storage parameter        | `layoutStruct`                    | `Storage storage layoutStruct`         |
| All parameters           | trailing underscore         | `owner_`, `amount_`              |

Parameters always end with `_` to prevent shadowing of state or storage variables.

## Storage Slot Names

Hierarchical and deterministic:

- Crane internals: `crane.{domain}.{feature}`
- ERC standards: `eip.erc.{number}`
- Protocols: `protocols.{category}.{name}.{version}.{concern}`

Example:

```solidity
bytes32 internal constant STORAGE_SLOT =
    keccak256(abi.encode("crane.access.operable"));
```

## Compilation Rules

- `viaIR` and `via_ir` must remain disabled.
- Stack-too-deep errors are resolved by grouping parameters and intermediate values into `struct` types passed by `memory` or `calldata`.
- Optimizer runs are set to 1 to respect contract size limits under the Diamond pattern.

## Reference

See `contracts/StyleGuide.sol` for the canonical template.
