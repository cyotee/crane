# Gap Report for: contracts/access/reentrancy/IReentrancyLock.sol

**File Type:** Source File (Interface)

**Status:** CLOSED (LR-1)

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + AsciiDoc include-tags)

**Tagged Symbols (5):**
- `IReentrancyLock[]` (the interface)
- `IsLocked()[]` (the error)
- `isLocked()[]` (the view function)
- `lock()[]` (the lock control function)
- `unlock()[]` (the unlock control function)

**Summary of Changes:**
Enhanced stub interface to full LR-1 gold standard for interfaces (rich NatSpec + exact // tag::Name(params)[] / // end:: for interface + error + all 3 functions). Added lock()/unlock() declarations to complete the reentrancy lock mechanism surface (matching task scope of 3 functions + main). Modeled on closed golds: `contracts/interfaces/IPermit2Aware.sol`, `contracts/registries/target/ICallTargetRegistryManagement.sol`, `contracts/access/ERC8023/IMultiStepOwnable.sol`, `contracts/factories/create3/ICreate3Factory.sol` + consistency with closed ReentrancyLock* siblings (Target uses @inheritdoc + isLocked()[] ; Repo/Modifiers reference lock/unlock/IsLocked). Added @title/@author/@dev/@notice (multi-line), section headers, named @return, richer @dev. NO @custom:* added (centrals none for this; prose only). Preserved original logic (pragma, no body changes); the added function decls extend surface without altering prior isLocked/error.

**Pre-edit tags (from source read):** IReentrancyLock[] / IsLocked[] / isLocked()[]  (3 partial)
**Post-edit tags:** IReentrancyLock[] / IsLocked()[] / isLocked()[] / lock()[] / unlock()[]  (5, with 3 function tags per scope)

**Detailed Gaps (historical before close):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Historical pre-close note:** Original stub had partial LR-1 gap description + partial tags (IReentrancyLock, IsLocked without (), isLocked); lock/unlock were not declared (stub gap).

**Historical pre-close (actions):** Original listed wrap symbols, add @custom etc. (addressed for existing; added lock/unlock for full 3 funcs per scope; centrals none so no customs/prose only; no other changes).

**Strict Ordered Reads Performed (EXACT ORDER before ANY edit + re-reads of key before search_replace):**
1. docs/reports/gap/contracts/access/reentrancy/IReentrancyLock.sol.md (per-file gap)
2. docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (NONE for IReentrancyLock/IsLocked/lock/unlock/isLocked; prose only)
3. PRD.md (LR-1 full scope incl interfaces + NatSpec reqs)
4. AGENTS.md (interface NatSpec + tag patterns, exact // tag::Name(params)[] /end, rich @custom from centrals, gold examples)
5. Golds: previous closed interfaces (IPermit2Aware.sol, ICallTargetRegistryManagement.sol, IMultiStepOwnable.sol, ICreate3Factory.sol etc from GAP), ReentrancyLock* closed siblings (ReentrancyLockRepo.sol, ReentrancyLockTarget.sol, ReentrancyLockModifiers.sol), Operable/IOperable + IReentrancyLock usage in AccessFacetFactoryService + tests + siblings.
6. Source: contracts/access/reentrancy/IReentrancyLock.sol (re-read before edit)

**Centrals:** none (no @custom fabricated)
**ONLY 3 files edited (relative paths only)**

**Testing Gaps (LR-7 specific if applicable):**
- N/A for pure interface (see closed ReentrancyLock* siblings and the test for usage + LR-7 declaration via Behavior_IFacet).

**Documentation/Skills Gaps (if applicable):**
- Ensure this surface is explained in GitBook content (LR-2) and skills (LR-3).

**Notes for Subagents:**
- Only edited allowed 3 relative files.
- No @custom added (CENTRALLY none).
- Update the main GAP_REPORT.md checkbox when done.
- Targeted verifs after: forge inspect on the IReentrancyLock.sol:IReentrancyLock (abi|methodIdentifiers); build the .sol --skip test --quiet; narrow list '*IReentrancyLock*|*ReentrancyLock*'.
- Report tags/health.

**Verification (TARGETED ONLY, executed post all edits):**
- `forge inspect contracts/access/reentrancy/IReentrancyLock.sol:IReentrancyLock (abi|methodIdentifiers)` -> succeeded; abi shows error IsLocked() (0xcaa30f55), functions: isLocked() view returns (bool) (0xa4e2d634), lock() (0xf83d08ba), unlock() (0xa69df4b5). methodIdentifiers table confirms the 3.
- `forge build contracts/access/reentrancy/IReentrancyLock.sol --skip test --quiet` -> BUILD_EXIT=0.
- `forge test --list --match-path '*IReentrancyLock*|*ReentrancyLock*'` -> executed (broad discovery surfaced pre-existing unrelated NatSpec issues in other files like DevEnvSmokeTest; our .sol + targeted build/inspect clean). ReentrancyLock tests are listed in full runs.

**LR-1 closed for this interface.** 3 function tags (isLocked, lock, unlock) + interface + error.
