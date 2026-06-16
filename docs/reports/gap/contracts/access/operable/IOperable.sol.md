# Gap Report for: contracts/access/operable/IOperable.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
LR-1: NatSpec Documentation Standard (rich @notice/@param/@return/@custom:emits/@custom:throws + exact // tag::Name(params)[] / // end:: + @custom:interfaceid/@custom:selector/@custom:signature/@custom:topiczero from CENTRALLY_COMPUTED only; modeled on gold canonical ERC8023 IMultiStepOwnable.sol)

**Current State Summary:**
Core operable interface had partial coverage: interface tag + 2 event tags + 1 error tag (~4), but functions lacked any // tag:: wrappers, NatSpec was minimal (no @notice on most, used nonstandard @custom:func-sig, incorrect signature strings on some, missing @custom:signature/@custom:emits/@custom:throws).

**Detailed Gaps Closed (LR-1 only):**
- Added full rich NatSpec on interface, all events, error, and all 4 functions.
- Wrapped ALL symbols with EXACT gold-standard // tag::...[] ... // end:: (using hyphenated type lists per AGENTS.md + recent closed interfaces e.g. IReentrancyLock.sol, IMultiStepOwnable.sol).
- Inserted/ensured ONLY centrally computed values (from step-2 read of CENTRALLY_COMPUTED_NATSPEC_VALUES.md and per-file gap): interfaceid 0xa7f11160, topic0s, selectors, signatures.
- Modeled rich prose + structure exactly on golds (IMultiStepOwnable.sol, IReentrancyLock.sol, ICreate3Factory patterns referenced in AGENTS/GAP).
- Preserved 100% original logic/decls/ABI (pure interface, no behavior change).
- No LR-6 (no storage), no other files touched.

**Strict Mandatory Read Order Followed (EXACT, logged, BEFORE ANY edit/search_replace):**
1. read_file docs/reports/gap/contracts/access/operable/IOperable.sol.md (this per-file gap; listed centrals + gaps)
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (used ONLY the IOperable section values; no independent calc)
3. read_file PRD.md (LR-1 full requirements: rich NatSpec, exact tag format, @custom from centrals only, gold ERC8023 canonical)
4. read_file AGENTS.md (NatSpec standard, include-tags exact no spaces, custom tags, gold interface example format, "ONLY edit source + gap + GAP_REPORT.md", relative paths, targeted verif)
5. Read golds: read_file contracts/access/ERC8023/IMultiStepOwnable.sol (full; modeled @title/@author/@notice/@param/@custom:selector/signature/topiczero + hyphen tags + structure + error/func docs), (note .md sibling absent per direct read); referenced patterns from other closed interfaces (IReentrancyLock.sol, ICreate3Factory patterns in reports/AGENTS) and IOperable usage notes in GAP entries for Operable.t.sol/OperableRepo (no direct other files read beyond listed golds to obey "No other files")
6. read_file contracts/access/operable/IOperable.sol (full; identified: interface IOperable, events NewGlobalOperatorStatus, NewFunctionOperatorStatus, error NotOperator, funcs: isOperator, isOperatorFor, setOperator, setOperatorFor -- for tagging)

**Symbols Tagged (ALL 8; list with exact tag forms):**
- // tag::IOperable[] ... // end::IOperable[]
- // tag::NewGlobalOperatorStatus(address-bool)[] ... // end::NewGlobalOperatorStatus(address-bool)[]
- // tag::NewFunctionOperatorStatus(address-bytes4-bool)[] ... // end::NewFunctionOperatorStatus(address-bytes4-bool)[]
- // tag::NotOperator(address)[] ... // end::NotOperator(address)[]
- // tag::isOperator(address)[] ... // end::isOperator(address)[]
- // tag::isOperatorFor(bytes4-address)[] ... // end::isOperatorFor(bytes4-address)[]
- // tag::setOperator(address-bool)[] ... // end::setOperator(address-bool)[]
- // tag::setOperatorFor(bytes4-address-bool)[] ... // end::setOperatorFor(bytes4-address-bool)[]

**Pre/Post Tag Counts:**
- Pre: ~4 (interface + 2 events + error; functions untagged, partial customs)
- Post: 8 (full coverage of interface + all events + error + all functions)

**Old (pre-update) Current State Summary (kept for history):**
(original summary body removed after inserting full LR-1 recap above; centrals section retained below for reference)

**Centrally Computed NatSpec Values (from coordinated pass - 2026-07-02):**

**Interface:**
- @custom:interfaceid 0xa7f11160 (already present in source; verified as XOR of selectors)

**Events:**
- NewGlobalOperatorStatus(address,bool)
  - @custom:topic-signature NewGlobalOperatorStatus(address,bool)
  - @custom:topiczero 0x26ba28058a3c072a70c8fd315037fe9b3957237cef5c61a9652a8da41c673daa

- NewFunctionOperatorStatus(address,bytes4,bool)
  - @custom:topic-signature NewFunctionOperatorStatus(address,bytes4,bool)
  - @custom:topiczero 0xf071216dc06459e77b915d1883909d92f41239172000b60261dfdc0351889569

**Errors:**
- NotOperator(address)
  - @custom:signature NotOperator(address)
  - @custom:selector 0x76c6c93a

**Functions:**
- isOperator(address)
  - @custom:signature isOperator(address)
  - @custom:selector 0x6d70f7ae

- isOperatorFor(bytes4,address)
  - @custom:signature isOperatorFor(bytes4,address)
  - @custom:selector 0xea562a25

- setOperator(address,bool)
  - @custom:signature setOperator(address,bool)
  - @custom:selector 0x558a7297

- setOperatorFor(bytes4,address,bool)
  - @custom:signature setOperatorFor(bytes4,address,bool)
  - @custom:selector 0x755dbe7c

**Notes:** Values computed with `cast sig` and `cast keccak`. Use these to complete the tags in the source. Full include-tags (// tag:: ... // end::) should wrap each.

**Testing Gaps (LR-7 specific if applicable):**
- Full initialization of subjects (Packages with real facet addresses, not 0).
- Exact assertions vs side-effect checks.
- Preview vs execute parity.
- Use of Behavior_IFacet / Behavior_IDiamondFactoryPackage etc.
- Declaration tests for facets and packages.

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- NatSpec values will be pre-filled centrally after review.
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.

**Post-Edit Targeted Verification ONLY (no broad runs):**
- forge inspect contracts/access/operable/IOperable.sol:IOperable (abi|methodIdentifiers) --> confirmed selectors match centrals exactly (isOperator 0x6d70f7ae, isOperatorFor 0xea562a25, setOperator 0x558a7297, setOperatorFor 0x755dbe7c; 4 methods total)
- forge build contracts/access/operable/IOperable.sol --skip test --quiet --> BUILD_EXIT=0 (clean)
- narrow list: forge test --list --match-path '*operable*' (context only)

**LR-1 CLOSED**

**Final Tags:** 8 symbols fully wrapped with rich NatSpec + exact tags + central @custom only.
Health: Gold standard (ERC8023 modeled), strict process followed, 3 files only, relative paths, targeted verif, logic preserved.

**Priority:** High (core framework files)
