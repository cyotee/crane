# Gap Report for: contracts/interfaces/IDiamondCut.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
LR-1: NatSpec Documentation Standard (Mandatory & Verifiable) - rich NatSpec + exact // tag::/end:: + @custom:*

**Strict Read Order Performed (BEFORE ANY EDIT):**
1. read_file docs/reports/gap/contracts/interfaces/IDiamondCut.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (diamondCut selector 0x1f931c1c present; used ONLY values present)
3. read_file PRD.md (focus LR-1 NatSpec requirements: rich @title/@author/@notice/@dev/@param/@return/@custom:emits + tags, gold refs to IMultiStepOwnable etc)
4. read_file AGENTS.md (full relevant: NatSpec section, interface patterns, exact tag format e.g. // tag::Name(params)[] with hyphens, gold examples like IOperable / IMultiStepOwnable / closed IDiamond, "ONLY 3 files", relative, targeted verif only)
5. Golds: read_file contracts/introspection/ERC2535/IDiamond.sol , read_file contracts/access/operable/IOperable.sol , read_file contracts/access/ERC8023/IMultiStepOwnable.sol (model rich @title/@author/@notice/@dev/@param/@return/@custom:emits + @custom:selector + hyphen tags)
6. read_file contracts/interfaces/IDiamondCut.sol (re-read full immediately before planning edits)

**Exact Symbols Tagged:**
- IDiamondCut (interface)
- diamondCut(IDiamond.FacetCut[]-address-bytes) (the one external function; hyphenated per spec)

**Pre/Post Tag Counts:**
- Pre: 0
- Post: 2
- Final tag count for file: 2

**Recap of Centrals Used:**
- From CENTRALLY_COMPUTED_NATSPEC_VALUES.md: diamondCut(...) (IDiamondCut) : 0x1f931c1c (ONLY value used; no interfaceid present so none fabricated)
- @custom:selector 0x1f931c1c ; @custom:emits DiamondCut (per task; modeled @custom:signature also)
- No other customs present in central for this; no fabrication.

**LR-1 Changes:**
- Added rich NatSpec: @title, @author (from gold IDiamond), @notice, @dev, @param (diamondCut_, initTarget, initCalldata), @custom:signature, @custom:selector, @custom:emits
- Wrapped EXACT // tag::IDiamondCut[] ... // end::IDiamondCut[]
- Function: // tag::diamondCut(IDiamond.FacetCut[]-address-bytes)[] ... // end::
- Kept the import and all existing code EXACTLY (pragma, import, function sig+body unchanged, no logic).
- No viaIR, relative paths only, ONLY edited this + perfile + GAP_REPORT (3 files max).

**Targeted Verification Outputs (ONLY after edits):**
- `forge inspect contracts/interfaces/IDiamondCut.sol:IDiamondCut abi && forge inspect contracts/interfaces/IDiamondCut.sol:IDiamondCut methodIdentifiers`
  Output:
  (abi table): function diamondCut(IDiamond.FacetCut[],address,bytes) nonpayable | 0x1f931c1c
  (methodIdentifiers): diamondCut((address,uint8,bytes4[])[],address,bytes) | 1f931c1c
  (matches central exactly)
- `forge build contracts/interfaces/IDiamondCut.sol --skip test --quiet`
  Exit: 0 (success)
- `forge test --list --match-path '*IDiamondCut*' ` (narrow, with timeout/head for target scope)
  (Executed; limited output due to list cost but no errors; build/inspect confirm; interface surface healthy. No broad test execution.)

**LR-1 CLOSED**

**Notes for Subagents:**
- Only fixes for this file's LR-1 gaps (per strict scope).
- 100% original source (except NatSpec/tags addition) preserved.
- Update main GAP_REPORT.md with concise [x] entry modeled on recent IDiamond.sol .
- Priority: High (core Diamond interface).

**Current State Summary (post close):**
LR-1 CLOSED for contracts/interfaces/IDiamondCut.sol . 2 tags. All verifs targeted passed (selector matched central, build 0). Only the 3 allowed relative files were edited.
