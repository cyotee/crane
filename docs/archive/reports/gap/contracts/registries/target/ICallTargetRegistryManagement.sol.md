# Gap Report for: contracts/registries/target/ICallTargetRegistryManagement.sol

**File Type:** Interface

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full // tag:: / end:: + @custom:selector/signature/interfaceid)

**Current State Summary:**
LR-1 closed. Full NatSpec + exact gold-standard // tag:: / // end:: added for the interface and both functions. Used values from cast (recorded in CENTRALLY_COMPUTED_NATSPEC_VALUES.md). Re-exports in contracts/interfaces/ are tiny shims (no symbols). (Only edited this .sol + this gap report + GAP_REPORT.md where applicable.)

**Detailed Gaps (Closed):**
- LR-1: Added // tag::ICallTargetRegistryManagement[] ... // end:: and per-function tags (setDefaultCallTargetForID(bytes4,address)[] and setCallTargetForIDForCaller(bytes4,address,address)[]).
- Added @custom:interfaceid 0x9400c76a on interface.
- Added @custom:selector and @custom:signature on each function using centrally recorded / cast values (0xaf87fa1d, 0x3b873d77).
- Rich @notice/@param/@return/@dev retained and aligned.

**Actions Completed:**
- Strict read order followed (gap report, CENTRALLY..., PRD LR-1, AGENTS.md, source).
- Inserted tags and customs only.
- Updated central values doc with the new symbols.
- Updated this per-file gap + main GAP_REPORT.md.
- Verification: targeted forge build / inspect on dependents (facets use it); no logic change.

**NatSpec Symbols Tagged (using central/cast values):**
- ICallTargetRegistryManagement (interfaceId 0x9400c76a)
- setDefaultCallTargetForID(bytes4,address) : 0xaf87fa1d
- setCallTargetForIDForCaller(bytes4,address,address) : 0x3b873d77

**Testing Gaps (LR-7 specific if applicable):**
N/A for pure interface. Behavior_ICallTargetRegistryManagement + handlers + declaration tests in consuming tests (DevEnvSmokeTest, CallTarget facets) provide coverage. Registry facets already closed with IFacet + Behavior.

**Documentation/Skills Gaps (if applicable):**
Covered in CODEBASE_MAP, deployment, crane-architecture (registries section).

**Notes for Subagents:**
- Only edited allowed files for LR-1 on this interface.
- Values from cast + added to CENTRALLY_COMPUTED_NATSPEC_VALUES.md.
- The top-level contracts/interfaces/ICallTargetRegistryManagement.sol is a 2-line re-export shim (supports @crane/contracts/interfaces/ imports in Init*Service etc.); canonical definition is here.
- The untracked shim note from verification is informational (many dev files are ?? ; source here is the important one).

**Status:** CLOSED (LR-1)
**Priority:** High (core registry surface for call target indirection / reusable proxies)
