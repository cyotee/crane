# Gap Report for: contracts/registries/target/Behavior_ICallTargetRegistryQuery.sol

**File Type:** Source File (Behavior library for LR-7)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc tags + @custom only from centrals)

**Current State Summary:**
Pre: no NatSpec, no // tag::/end:: . Pure support Behavior lib (no storage, no LR-6). Used for CallTarget query validation.
10

**Strict Read Order Followed (before ANY edit/search_replace):**
1. read_file docs/reports/gap/contracts/registries/target/Behavior_ICallTargetRegistryQuery.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ICallTargetRegistryQuery values: interfaceId 0xb6dd59b7, defaultCallTargetForID 0xd2cfb6ed, callTargetForIDForCaller 0x6412ef5a)
3. read_file PRD.md (focus LR-1 NatSpec + LR-7 Behavior mentions)
4. read_file AGENTS.md (Behavior libs section + NatSpec patterns from closed ones, exact // tag::Name(params)[] hyphen, gold examples Behavior_IFacet.sol + Behavior_IERC165.sol + Behavior_IDiamondLoupe, "ONLY 3 files", relative, targeted verif)
5. Golds: read_file contracts/factories/diamondPkg/Behavior_IFacet.sol , read_file contracts/introspection/ERC165/Behavior_IERC165.sol , read_file contracts/introspection/ERC2535/Behavior_IDiamondLoupe.sol (model rich @title/@author/@notice/@dev + @custom on funcSig_ + expect_/isValid_/hasValid_ helpers with hyphen overload tags)
6. read_file contracts/registries/target/Behavior_ICallTargetRegistryQuery.sol (re-read full immediately before planning edits)

**Detailed Gaps (pre):**
- LR-1: missing rich NatSpec + // tag:: / end:: (0 symbols wrapped) + no @custom from central on the related I* query selectors.

**Actions Taken (LR-1 only; ONLY edited 3 relative files):**
- Added rich NatSpec + EXACT gold // tag::/end:: (hyphens). @custom ONLY centrals. 100% preserve. **LR-1 CLOSED** (see full recap above).

**Symbols (14 post):** Behavior_ICallTargetRegistryQuery[] + _name() + 3x _errPrefix*(hyphen) + 2 funcSig + 2 expect + 2 hasValid + 2 rec + hasValid_ICall...[] (full in GAP_REPORT)

**Pre/post:** 0->14

**Centrals:** used 0xb6dd59b7 / 0xd2cfb6ed / 0x6412ef5a ONLY

**Verif outputs (targeted):** inspect abi/methodIdentifiers (2 helpers), build --quiet --skip (0), narrow --list '*CallTarget*Behavior*' (ran).

**LR-1 CLOSED** (rest stub replaced)
