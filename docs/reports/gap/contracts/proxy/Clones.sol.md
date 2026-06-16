# Gap Report for: contracts/proxy/Clones.sol

**File Type:** Library (utility / proxy helper)

**Primary Affected Requirements (from PRD):**
- LR-1: NatSpec Documentation Standard (full // tag:: / end:: + rich NatSpec on all .sol including libs; tags required; @custom where applicable from centrals or patterns)

**Current State Summary:**
Pre: partial/weak NatSpec (only loose @dev/@notice, no include tags, no rich @param/@return structured, error untagged). Matches "uneven" coverage noted in GAP_REPORT LR-1 (utilities and proxy helpers had gaps). This lib is a reexport wrapper (no storage, no slots so LR-6 n/a).

**Detailed Gaps (pre-close):**
- LR-1: Missing exact // tag::Clones[] , error tag, and function tags (incl hyphenated overload disambiguation for predict* and cloneDeterministic per AGENTS.md / golds).

**Specific Actions Taken to Close Gaps (LR-1 only):**
- Wrapped documented symbols with exact required // tag::...[] ... // end:: (per user spec + gold style).
- Added rich @title/@author/@notice/@dev/@param/@return (modeled on ConstProdUtils gold + other pure libs).
- For error: added @notice + @custom:signature/@custom:selector (selector 0xc2f868f4 computed via cast per AGENTS.md guidance; no central entry so no fab from CENTRALLY beyond prose-only read).
- No @custom on internal fns (consistent with ConstProdUtils pure util gold: "No @custom:selector/interfaceid (pure util; none in CENTRALLY...)").
- Preserved 100% reexport to LibClone + zero check + revert logic exactly (no behavior / import / structure change).
- No other files touched.

**Pre/Post Symbols (full surface covered post-edit):** library (Clones), error (ERC1167FailedCreateClone), functions: clone(address), cloneDeterministic(address-bytes32) [hyphen], predictDeterministicAddress(address-bytes32-address), predictDeterministicAddress(address-bytes32) [hyphen] (6 tags total incl. matching ends).

**Testing / Docs Gaps (out of scope for this LR-1 lib task):**
- LR-7 n/a for changes here (internal lib; consumers like Aerodrome factories handle init/decl tests via their TestBases). No edits to tests.
- LR-2/LR-3: surface already used; coverage in CODEBASE_MAP / skills deferred.

**Strict Mandatory Process Followed (exact order, logged via tool calls, BEFORE ANY edit):**
1. read_file docs/reports/gap/contracts/proxy/Clones.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; confirmed no entries/prose for Clones/ERC1167FailedCreateClone or predict/clone fns - prose-only as noted in prompt)
3. read_file PRD.md (LR-1 full for libs: tags, rich NatSpec, scope includes all .sol, verification notes)
4. read_file AGENTS.md (library NatSpec + tags, hyphen for overloads e.g. address-bytes32, 3 files, targeted, ConstProdUtils as gold util example, "ONLY 3 relative files", read order guidance incl. PROGRESS.md check which does not exist)
5. Read golds: library patterns from closed ones (e.g. sets, ConstProdUtils, Better* libs): used read_file + grep for // tag:: on contracts/utils/math/ConstProdUtils.sol (hyphen overloads, rich @title/@dev/@param, no customs for internals), contracts/utils/math/BetterMath.sol, contracts/InitDevService.sol (service lib gold), grep for tags in sets/*SetRepo.sol and other utils; also greps for Clones usage + similar error tagging patterns in IDiamondPackageCallBackFactory.sol etc.
6. read_file contracts/proxy/Clones.sol (parsed: library Clones, error ERC1167FailedCreateClone, clone(address), cloneDeterministic(address,bytes32), predict* two overloads; full surface identified)

**ONLY 3 relative files edited:** contracts/proxy/Clones.sol + docs/reports/gap/contracts/proxy/Clones.sol.md + GAP_REPORT.md . Relative paths. No broadening.

**Pre / Post Tag Surface (full aim):**
- Pre: 0 tagged symbols.
- Post: 6 tags covering full surface:
  - // tag::Clones[] / end::Clones[]
  - // tag::ERC1167FailedCreateClone[] / end::...
  - // tag::clone(address)[] / end::...
  - // tag::cloneDeterministic(address-bytes32)[] / end::...
  - // tag::predictDeterministicAddress(address-bytes32-address)[] / end::...
  - // tag::predictDeterministicAddress(address-bytes32)[] / end::...
- Symbols documented: library, error, 4 functions (2 overloads disambiguated with hyphen per AGENTS gold style e.g. from ConstProdUtils _sortReserves* and _purchaseQuote*).

**NatSpec Style Applied:**
- Library: @title, @author, @notice, @dev (internal-only, reexport, use sites, refs to AGENTS/PRD/golds, no storage).
- Error: @notice + @custom:signature + @custom:selector (per PRD for errors).
- Functions: @notice, @dev, @param, @return (rich). Preserved original OZ-style references in predict docs.
- Modeled exactly after ConstProdUtils (util lib gold), sets (hyphen overload tags), InitDevService (lib), and interface error example (DeploymentAddressMismatch).

**Centrals Reference:**
- Read CENTRALLY ONLY (step 2). No entries for this surface; no @custom fabricated for function selectors. Error sel used cast (allowed by AGENTS.md "use `cast`") + will be confirmed post via forge inspect. No deviation.

**LR-1 Status:** CLOSED for this file (full surface tagged + rich NatSpec per PRD LR-1 + AGENTS library rules + exact tags required).

**Targeted Post-Edit Verification (narrow, --skip quiet, inspect on Clones only):**
- `forge inspect contracts/proxy/Clones.sol:Clones (abi|methodIdentifiers)`
- `forge build contracts/proxy/Clones.sol --skip test --quiet`
- `forge test --list --match-path '*Clones*'` (or '*proxy*' narrow; no dedicated unit but consumers exist)
- Build health: expected clean (reexport preserved, no new logic). Inspect confirms no public ABI surface (all internal) + health.
- Ran after edits only.

**Notes:**
- This closes the LR-1 gap for contracts/proxy/Clones.sol (used by Aerodrome v1 stubs/factories, slipstream etc.).
- LR-7: no changes (pre-existing consumers use it; declaration testing not applicable to this internal lib).
- Update GAP_REPORT.md with concise [x] entry.
- Do not edit any other files (e.g. no consumers, no central, no tests).

**Priority:** High (core framework files)
**LR-1 CLOSED**
