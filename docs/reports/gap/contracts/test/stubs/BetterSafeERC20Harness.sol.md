# Gap Report for: contracts/test/stubs/BetterSafeERC20Harness.sol

**File Type:** Source File

**Primary Affected Requirements (from PRD):**
LR-1 (NatSpec + include-tags on all .sol incl. stubs/test/harnesses)

**Current State Summary:**
LR-1 closed for this harness stub. (0 tags initially, generic "Likely missing".)

**Detailed Gaps (pre-close):**
- LR-1: Likely missing or incomplete NatSpec with // tag:: and @custom: tags (per ERC8023 gold standard).

**Specific Actions Needed to Close Gaps:**
1. Wrap documented symbols with exact // tag::Symbol(params)[] ... // end:: 
2. Add @notice, @param, @return, @custom:selector / signature / topiczero / interfaceid with accurate values (to be centrally computed).
3. For Repos: ensure DEFAULT_SLOT uses bytes32(uint256(keccak256(...)) - 1) per ERC1967.
- For NatSpec custom tags: List all public/external functions, errors, events, and the interface here. Values (selectors, topic0, interfaceId) will be centrally computed and populated in a follow-up pass. Do NOT implement computation in per-file work.

**NatSpec Symbols to Tag (from source parse):**
- BetterSafeERC20Harness (contract)
- safeTransfer(IERC20,address,uint256)
- safeTransferFrom(IERC20,address,address,uint256)
- trySafeTransfer(IERC20,address,uint256)
- trySafeTransferFrom(IERC20,address,address,uint256)
- safeIncreaseAllowance(IERC20,address,uint256)
- safeDecreaseAllowance(IERC20,address,uint256)
- forceApprove(IERC20,address,uint256)
- safeApprove(IERC20,address,uint256)
- safeName(IERC20Metadata)
- safeSymbol(IERC20Metadata)
- safeDecimals(IERC20Metadata)
- cast(IERC20[] memory)
(No events, no errors, no interfaces requiring custom id.)

**Testing Gaps (LR-7 specific if applicable):**
- Harness itself (used by higher tests) - no direct init/assert changes here per rules (only doc).
- (See CraneTest/InitDev for full non-0; no edits outside 3 files.)

**Documentation/Skills Gaps (if applicable):**
- n/a for this scoped stub fix.

**Notes for Subagents:**
- Implement only fixes for this file's gaps.
- NatSpec values will be pre-filled centrally after review.
- Update the main GAP_REPORT.md checkbox when done.
- Do not edit other files.

**Priority:** High (core framework files)

---

## Closure Summary (LR-1)

**Strict read order started** (followed exactly before any edit/search_replace):

1. read_file docs/reports/gap/contracts/test/stubs/BetterSafeERC20Harness.sol.md
2. read_file docs/reports/gap/CENTRALLY_COMPUTED_NATSPEC_VALUES.md (ONLY; prose)
3. read_file PRD.md (LR-1 for stubs/test)
4. read_file AGENTS.md (stub/Target gold patterns like GreeterTarget/OperableTargetStub, exact tags, 3 files only, relative, targeted verif)
5. Read golds: closed stubs (GreeterTarget just closed, Counter, OperableTargetStub, MultiStep* stubs) [via relative reads: contracts/test/stubs/greeter/GreeterTarget.sol, contracts/test/stubs/counter/Counter.sol, contracts/access/operable/OperableTargetStub.sol, contracts/access/ERC8023/MultiStepOwnableFacetStub.sol]
6. read_file contracts/test/stubs/BetterSafeERC20Harness.sol (parse symbols) [re-reads before edits]

All reads used relative paths only. No other files edited.

**Pre:** 0 tags. Generic per-file gap "Likely missing".

**Post:** 13 tags (BetterSafeERC20Harness[] + 12 funcs using hyphen for multi-param tags per gold patterns).

LR-1: rich NatSpec + EXACT // tag::BetterSafeERC20Harness[] / safeTransfer(IERC20-address-uint256)[] / safeTransferFrom(IERC20-address-address-uint256)[] / trySafeTransfer(IERC20-address-uint256)[] / trySafeTransferFrom(IERC20-address-address-uint256)[] / safeIncreaseAllowance(IERC20-address-uint256)[] / safeDecreaseAllowance(IERC20-address-uint256)[] / forceApprove(IERC20-address-uint256)[] / safeApprove(IERC20-address-uint256)[] / safeName(IERC20Metadata)[] / safeSymbol(IERC20Metadata)[] / safeDecimals(IERC20Metadata)[] / cast(IERC20[]-memory)[] (13 total). Modeled exactly on GreeterTarget (just closed) + Counter + OperableTargetStub + MultiStepOwnableFacetStub golds. @title/@author/@notice/@dev/@param/@return; @dev notes test-only + "like GreeterTarget, Counter". No @custom fabricated (CENTRALLY prose only, no entries for this harness). Preserved 100% logic (only added docs/tags).

ONLY edited exactly 3 relative files: contracts/test/stubs/BetterSafeERC20Harness.sol + docs/reports/gap/contracts/test/stubs/BetterSafeERC20Harness.sol.md + GAP_REPORT.md.

Post-edit targeted ONLY: `forge inspect contracts/test/stubs/BetterSafeERC20Harness.sol:BetterSafeERC20Harness (abi|storageLayout|methodIdentifiers)`, `forge build contracts/test/stubs/BetterSafeERC20Harness.sol --skip test --quiet`.

Per-file gap updated with full 6-read recap + symbols + pre/post (0->13) + verif + "LR-1 CLOSED". Report tags:13 , health (targeted 0). (Advances test stubs LR-1 for BetterSafeERC20 usage.)
