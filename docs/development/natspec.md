# NatSpec and Documentation

Crane combines NatSpec comments with AsciiDoc include-tags to keep documentation accurate and extractable.

## Include Tags

Wrap every documented symbol:

```solidity
// tag::transfer[]
/// @notice Transfers tokens to a recipient
/// @param to_ Recipient address
/// @param amount_ Amount to transfer
/// @return success True on success
/// @custom:signature transfer(address,uint256)
/// @custom:selector 0xa9059cbb
function transfer(address to_, uint256 amount_) external returns (bool success);
// end::transfer[]
```

Tag names match the symbol. Exact matching is required (no extra spaces inside `[]`).

## Custom Tags

| Symbol Type | Tag                    | Value Type | Example Computation          |
|-------------|------------------------|------------|------------------------------|
| Function    | `@custom:signature`    | string     | `cast sig "name(types)"`     |
| Function    | `@custom:selector`     | bytes4     | `cast sig "..."`             |
| Error       | `@custom:signature`    | string     | `cast sig "ErrorName(types)"`|
| Error       | `@custom:selector`     | bytes4     | `cast sig "..."`             |
| Event       | `@custom:signature`    | string     | `cast keccak "Event(...)"`   |
| Event       | `@custom:topiczero`    | bytes32    | `cast keccak "..."`          |
| Interface   | `@custom:interfaceid`  | bytes4     | `type(I).interfaceId` or XOR |

## Required Tags by Symbol

- All external and public functions that form part of an interface: signature and selector.
- All custom errors: signature and selector.
- All events: signature and topic0.
- All interfaces intended for ERC165 registration: interfaceid.

## Validation

Before merging changes that affect documented symbols:

- Confirm include tags surround the complete symbol.
- Recompute selectors and hashes with `cast` and compare to the tags.
- Verify that `facetInterfaces()` and `facetFuncs()` return the documented values for facets.

## Extraction

The include-tag convention supports extraction of exact source snippets for published documentation and specifications. Tag names are chosen to be stable identifiers for include directives in downstream documentation systems.
