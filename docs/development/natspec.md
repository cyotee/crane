# NatSpec and Documentation Standard

Crane combines NatSpec comments with AsciiDoc include-tags to keep documentation accurate and extractable. This standard is defined by LR-1 in PRD.md and aligns with AGENTS.md.

**Canonical Gold Standard (required quality and format):**

- `contracts/access/ERC8023/IMultiStepOwnable.sol`
- `contracts/access/ERC8023/MultiStepOwnableTarget.sol`
- `contracts/access/ERC8023/MultiStepOwnableRepo.sol`
- `contracts/access/ERC8023/MultiStepOwnableFacet.sol`

Follow these files exactly for include-tag style, custom tags, rich NatSpec (`@notice`, `@param`, `@return`, `@custom:emits`, `@custom:throws`), and overload tagging.

## Include Tags

Wrap every documented symbol. Tag names must match the symbol exactly (no extra spaces inside `[]`).

Use hyphen-separated parameter types (no spaces, param names omitted) for disambiguation, especially overloads and events:

```solidity
// tag::initiateOwnershipTransfer(address)[]
/**
 * @notice Initiates a ownership transfer by storing `newOwner` as the pending owner.
 * @param newOwner The address to which to initiate a ownership transfer.
 * @custom:selector 0xc0b6f561
 * @custom:signature initiateOwnershipTransfer(address)
 * @custom:emits OwnershipTransferInitiated(address,address)
 * @custom:throws NotOwner(address)
 */
function initiateOwnershipTransfer(address newOwner) external;
// end::initiateOwnershipTransfer(address)[]

// tag::OwnershipTransferInitiated(address-address)[]
/**
 * @notice Emitted when an ownership transfer is initiated.
 * @param prevOwner The address initiating the transfer. Will only be current owner.
 * @param newOwner The address to which ownership is being transferred.
 * @custom:topiczero 0xb150023a879fd806e3599b6ca8ee3b60f0e360ab3846d128d67ebce1a391639a
 */
event OwnershipTransferInitiated(address indexed prevOwner, address indexed newOwner);
// end::OwnershipTransferInitiated(address-address)[]

// tag::_layoutStruct(bytes32)[]
/**
 * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
 * @param slot Storage slot to bind to the Repo's Storage struct.
 * @return layoutStruct The bound Storage struct.
 */
function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct);
// end::_layoutStruct(bytes32)[]

// tag::_layoutStruct()[]
/**
 * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
 * @return layoutStruct The bound Storage struct.
 */
function _layoutStruct() internal pure returns (Storage storage layoutStruct);
// end::_layoutStruct()[]
```

The markers must be exact. Wrap the entire declaration (including NatSpec) between the tags.

## Custom Tags

| Symbol Type | Tag                    | Value Type | Example Computation |
|-------------|------------------------|------------|---------------------|
| Function    | `@custom:signature`    | string     | See Verification Script / Central Values |
| Function    | `@custom:selector`     | bytes4     | See Verification Script / Central Values |
| Error       | `@custom:signature`    | string     | See Verification Script / Central Values |
| Error       | `@custom:selector`     | bytes4     | See Verification Script / Central Values |
| Event       | `@custom:signature`    | string     | (optional, e.g. `@custom:topic-signature`) |
| Event       | `@custom:topiczero`    | bytes32    | See Verification Script / Central Values |
| Interface   | `@custom:interfaceid`  | bytes4     | `type(I).interfaceId` (preferred in script) or XOR |

Gold standard also uses `@custom:topic-signature` on some events for clarity.

## Verification Script Requirement (Mandatory)

Per LR-1:

> The custom NatSpec tag values (interface IDs, function selectors, and event topic0 where applicable) **MUST** be calculated using a dedicated **Foundry Script** (not one-off terminal `cast` commands or manual math).
>
> - The script must output compiler-computed values for interface IDs (using `type(I).interfaceId` where possible) and function selectors.
> - For events (topic0 hashes), the script should calculate or derive the values if direct compiler output for the event signature is not available in the script context.
> - This script is intended for one-time / iterative use by developers/agents to generate the exact values to paste into `@custom:*` tags.
> - The script (and instructions for running it) must be committed to the repository so values can be regenerated or audited at any time.

**Critical Accuracy Rule**: All `@custom:selector`, `@custom:topiczero`, and `@custom:interfaceid` values **MUST** be authoritatively computed using a Forge Script or Foundry Test (see `scripts/foundry/ComputeNatSpecValues.s.sol`). This ensures values are verifiable, reproducible in CI, and eliminates hallucination risk. Never rely solely on ad-hoc terminal `cast sig` / `cast keccak` for final values (though `cast` can match keccak for selectors/topics).

### How to Use the Dedicated Verification Script

Primary script (committed in `scripts/` per LR-1):
```bash
forge script scripts/foundry/ComputeNatSpecValues.s.sol --sig "run()" -vvv
```

- The script uses `type(IInterface).interfaceId` for IDs and `keccak256` (via Solidity) inside the compiled contract for selectors and topic0.
- Output appears in console; copy the exact `0x...` bytes into `CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (or directly into `@custom:*` during population).
- Re-run after changing any documented interface or adding symbols. Commit regenerated central values if the pass updates them.
- For convenience during exploration, the helper `scripts/compute_natspec_values.sh` (updated to launch/ reference the .s.sol) can quickly emit selectors via cast, but **always verify final authoritative values via the Foundry Script**.

Example in script (illustrative):
```solidity
// inside ComputeNatSpecValues.s.sol
console2.logBytes4(type(IFacet).interfaceId);
// and
bytes4 sel = bytes4(keccak256(bytes("facetName()")));
```

See `scripts/foundry/ComputeNatSpecValues.s.sol` (includes // tag:: and NatSpec itself) and `scripts/compute_natspec_values.sh`.

Existing `docs/development/natspec.md` (this file) reflects the full scope (incl. tests) and the required Foundry Script verification approach.

## Central Values Process (Single Source of Truth)

Use `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` exclusively:

1. Find the symbol in the relevant gap report under `docs/reports/gap/`.
2. Insert the `@custom:` lines using **ONLY** the pre-computed values from that file.
3. Wrap with the exact `// tag::...[]` / `// end::...[]` as per gold standard.
4. Verify with `forge build` and targeted tests.

Subagents and consumers must not independently compute values (e.g. via ad-hoc `cast`). Date of current central pass: 2026-07-02. Values were derived via cast for this pass but the strict requirement (LR-1) is to use the dedicated Foundry Script (`scripts/foundry/ComputeNatSpecValues.s.sol`) for authoritative values going forward. The central file is the single source of truth populated from the script output.

See the top of `CENTRALLY_COMPUTED_NATSPEC_VALUES.md` for usage and expansion instructions. Regenerate via the script when symbols are added.

## Required Elements for Every Documented Symbol (LR-1)

- Every public/external symbol in interfaces, and corresponding implementations, must be wrapped with exact include tags.
- Interfaces must declare `@custom:interfaceid` (computed bytes4).
- Events must declare `@custom:topiczero` (full bytes32 keccak topic hash) and preferably `@custom:topic-signature`.
- Errors and functions must declare:
  - `@custom:selector` (exact bytes4)
  - `@custom:signature` (canonical string form)
- Functions must include rich NatSpec: `@notice`, `@param`, `@return`, `@custom:emits`, `@custom:throws` where applicable.
- Repos must document both the parameterized (`Storage storage layoutStruct`) and default overload versions (with distinct hyphenated tags).
- Targets and Facets should use `@inheritdoc` where they delegate, plus their own tags for clarity.
- Facets must fully implement `IFacet` with documented `facetName()`, `facetInterfaces()`, `facetFuncs()`, `facetMetadata()`.

## Full Scope (incl. Tests)

- **All Solidity code**, including production contracts, libraries, interfaces, DFPkgs, and **all test files** (e.g. `*.t.sol`, `TestBase_*.sol`, `Behavior_*.sol`, handlers, stubs, comparators, etc.).
- Test contracts, complex helpers, handlers, and TestBases that expose public APIs must follow the same NatSpec + include-tag standards as production code (LR-7).
- Declaration tests for facets/packages (using `Behavior_IFacet`, `Behavior_IDiamondFactoryPackage`) reference the documented selectors/interfaceIds.

## Validation

Before merging changes that affect documented symbols:

- Confirm include tags surround the complete symbol exactly.
- Values for custom tags match the central computed list (or freshly generated via the dedicated verification script). Do not rely solely on terminal `cast`.
- Verify that `facetInterfaces()` and `facetFuncs()` (and equivalent package methods) return the documented values.
- For test surfaces: ensure documented public test APIs are covered by Behavior validation where applicable.
- Run `forge build` and relevant tests (e.g. declaration tests) to confirm.

## Extraction

The include-tag convention supports extraction of exact source snippets for published documentation (GitBook, AsciiDoc) and specifications. Tag names are chosen to be stable identifiers for `include::` directives in downstream systems.

## Agent Use, LR-2 and LR-3 Alignment

This standard enables safe reuse by other agents and projects:

- Follow AGENTS.md "NatSpec & Documentation Comment Standard" together with this doc (PRD LR-1 is authoritative; it requires the stricter Foundry Script + central values over older `cast`-only examples).
- `crane-natspec` skill (and references/natspec-examples.md) operationalizes this for agents. Keep skills in sync (LR-3).
- Supports LR-2 GitBook requirements: accurate extractable NatSpec underpins required content on CREATE3 Package for chain setup, DiamondPackageCallBackFactory public reuse (no per-chain redeploy), Registries (purpose/population/usage), ported protocol TestBases + utilities, general Sets/math/collections (cross-link to `docs/deployment/*`, `docs/concepts/*`, `docs/protocols/*`).
- LR-4 value prop: Fully documented, centrally-verified facets/packages allow "deploy once, attach everywhere" -- security via reuse of verified code (agent-error reduction), cost via not re-deploying bytecode.
- When working: always read the target gap report + CENTRALLY_COMPUTED... + PRD LR sections + AGENTS.md + referenced sources (in that strict order) before editing.
- Document test code when referenced in public surfaces or behaviors.

See also:
- `docs/development/testing.md` (Behavior, TestBase, declaration tests)
- `docs/deployment/dfpkg.md`, `docs/deployment/create3.md`, `docs/deployment/factory-services.md`
- `docs/concepts/facet-target-repo.md`, `docs/concepts/storage-slots.md`
- `docs/reference/agent-skills.md`
- `PRD.md` (LR-1, LR-2, LR-3, LR-7)
- `GAP_REPORT.md` (tracking)
- Gold standard ERC8023 sources

## Related Files

- `scripts/foundry/ComputeNatSpecValues.s.sol` (PRIMARY dedicated Foundry Script per LR-1 for compiler-accurate values; see "Verification Script Requirement")
- `scripts/compute_natspec_values.sh` (helper wrapper referencing the .s.sol for central pass)
- `docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md` (use ONLY these values)
- Per-file gap reports under `docs/reports/gap/`
- `contracts/factories/diamondPkg/Behavior_IFacet.sol` and `TestBase_IFacet.sol` (example usage of documented IFacet surface)
- Gold standard: `contracts/access/ERC8023/*` (full tags + custom + rich NatSpec + duals)
