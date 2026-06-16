# Gap Report for: contracts/registries/target/ICallTargetRegistryQuery.sol

**File Type:** Interface

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full // tag:: / end:: + @custom:selector/signature/interfaceid)

**Current State Summary:**
LR-1 closed. Full NatSpec + exact gold-standard // tag:: / // end:: added for the interface and both query functions. Used values from cast (recorded in CENTRALLY_COMPUTED_NATSPEC_VALUES.md). (Only edited this .sol + this gap report + GAP_REPORT.md where applicable.)

**Detailed Gaps (Closed):**
- LR-1: Added // tag::ICallTargetRegistryQuery[] ... // end:: and per-function tags (defaultCallTargetForID(bytes4)[] and callTargetForIDForCaller(bytes4,address)[]).
- Added @custom:interfaceid 0xb6dd59b7 on interface.
- Added @custom:selector and @custom:signature on each function using centrally recorded / cast values (0xd2cfb6ed, 0x6412ef5a).
- Rich @notice/@param/@return/@dev retained and aligned.

**Actions Completed:**
- Strict read order followed (gap report, CENTRALLY..., PRD LR-1, AGENTS.md, source).
- Inserted tags and customs only.
- Updated central values doc with the new symbols.
- Updated this per-file gap + main GAP_REPORT.md.
- Verification: targeted forge build / inspect on dependents (facets + repo + CallTarget DFPkg use it); no logic change.

**NatSpec Symbols Tagged (using central/cast values):**
- ICallTargetRegistryQuery (interfaceId 0xb6dd59b7)
- defaultCallTargetForID(bytes4) : 0xd2cfb6ed
- callTargetForIDForCaller(bytes4,address) : 0x6412ef5a

**Testing Gaps (LR-7 specific if applicable):**
N/A for pure interface. Behavior_ICallTargetRegistryQuery + handlers + declaration tests in consuming tests (DevEnvSmokeTest, registry facets already closed) provide coverage.

**Documentation/Skills Gaps (if applicable):**
Covered in CODEBASE_MAP, deployment, crane-architecture (registries section).

**Notes for Subagents:**
- Only edited allowed files for LR-1 on this interface.
- Values from cast + added to CENTRALLY_COMPUTED_NATSPEC_VALUES.md.
- The top-level contracts/interfaces/ICallTargetRegistryQuery.sol is a 2-line re-export shim; canonical definition is here.
- Addresses the untracked interfaces note surfaced in CallTarget verification (shims support import paths).

**Status:** CLOSED (LR-1)
**Priority:** High (core registry surface for call target indirection / reusable proxies)
