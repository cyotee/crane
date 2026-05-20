# Multi-Step Ownable (ERC8023)

Two-step ownership transfer with a configurable confirmation delay.

## Pattern

1. Current owner calls `transferOwnership(newOwner)`.
2. A pending owner is recorded together with a timestamp.
3. After the delay elapses, the pending owner calls `acceptOwnership()`.

The delay prevents accidental or malicious immediate takeover.

## Implementation Layers

- `MultiStepOwnableRepo` — stores pending owner and timestamp; contains the guards and state transitions.
- `MultiStepOwnableTarget` — implements the external interface.
- `MultiStepOwnableFacet` — exposes the functions through the Diamond.

A corresponding DFPkg exists for inclusion in new proxies.

## Storage Slot

`crane.access.erc8023`

## Related

Most packages include the multi-step ownable facet as a base building block alongside operable and introspection facets.
