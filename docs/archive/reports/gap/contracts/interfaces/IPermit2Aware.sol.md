# Gap Report for: contracts/interfaces/IPermit2Aware.sol

**File Type:** Source File (Interface)

**Status:** CLOSED (LR-1)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags)

**Tagged Symbols (2):**
- `IPermit2Aware[]` (the interface)
- `permit2()[]` (the single external function; added for full treatment)

**Summary of Changes:**
Enhanced to LR-1 gold standard for interfaces (rich NatSpec + exact // tag:: / // end::) while preserving existing tag and all logic/pragma/import exactly. Modeled on gold interfaces: `contracts/factories/create3/ICreate3Factory.sol`, `contracts/interfaces/IDiamondPackageCallBackFactory.sol`, `contracts/access/ERC8023/IMultiStepOwnable.sol`, `contracts/interfaces/IEIP712.sol`, and `contracts/interfaces/protocols/utils/permit2/IPermit2.sol` + consistency with closed `Permit2AwareRepo.sol`. Added @title/@author/@dev/@notice (multi-line), section header, proper @return (named), richer @notice. NO @custom:* added (see centrals below). Inner function tag added to improve documentation coverage.

**Detailed Gaps (historical before close):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Historical pre-close note:** Original stub had partial LR-1 gap description (now resolved; see above recap).

**Historical pre-close (actions):** Original listed wrap symbols, add @custom etc. (addressed; centrals none so prose; no other changes).

**Strict Ordered Reads Performed (EXACT ORDER before ANY edit + re-reads of key before search_replace):**
1. docs/reports/gap/contracts/interfaces/IPermit2Aware.sol.md (stub per-file)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (NONE for this; prose only)
3. PRD.md (LR-1 sections)
4. AGENTS.md (patterns, ONLY 3 files: .sol+perfile+GAP_REPORT.md , relative, targeted verif)
5. contracts/interfaces/IPermit2Aware.sol (source)
6. Golds: contracts/factories/create3/ICreate3Factory.sol + IDiamondPackageCallBackFactory.sol + IMultiStepOwnable.sol + IPermit2.sol + Permit2AwareRepo.sol

**Centrals:** none
**ONLY 3 files edited (relative)**
**Tagged:** IPermit2Aware[] (kept/enhanced), permit2()[] (added for func @param/@return)

**Historical stub text:**
**NatSpec Symbols to Tag (preliminary - expand by reading file):**
- Main contract/library/interface name
- All public/external functions
- Events
- Errors
- (Add exact list when reviewing this report)

**Verification (TARGETED ONLY, executed post all edits):**
- `forge inspect contracts/interfaces/IPermit2Aware.sol:IPermit2Aware (abi|methodIdentifiers)` -> clean output: abi lists the permit2() view fn returning address (IPermit2); methodIdentifiers includes "permit2()" (value per compiler; no change from prior as only NatSpec/docs edit).
- `forge build contracts/interfaces/IPermit2Aware.sol --skip test --quiet` -> BUILD_EXIT=0, success (docs/NatSpec only; logic/pragma preserved).
- `forge test --list --match-path '*Permit2*'` -> narrow success, lists relevant *Permit2* entries (e.g. tests using IPermit2Aware/Permit2AwareRepo without error).

**Files edited:** ONLY the allowed 3 using relative paths + search_replace after the strict 6 reads.

**LR-1 closed for this interface (polish for consistency with closed Permit2AwareRepo).** 2 tags. See GAP_REPORT.md for [x] entry.
