# Code Review: CRANE-152

**Reviewer:** OpenCode (AI)
**Review Started:** 2026-02-01
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

1) `tasks/CRANE-152-uniswap-v4-port-verification/TASK.md` lists `PositionDescriptor.sol`, `WETHHook.sol`, `WstETHHook.sol`, `WstETHRoutingHook.sol`, and `UniswapV4DeployerCompetition.sol` as required acceptance items (US-CRANE-152.5 + US-CRANE-152.7). `tasks/CRANE-152-uniswap-v4-port-verification/PROGRESS.md` marks these as “Optional Items Not Ported”, and they are not present under `contracts/protocols/dexes/uniswap/v4/**`.

   - Should these items be treated as required for CRANE-152 completion, or is `TASK.md` outdated and should be amended to match the intended scope?

---

## Review Findings

### Finding 1: TASK acceptance criteria mismatch vs ported files
**File:** `tasks/CRANE-152-uniswap-v4-port-verification/TASK.md`
**Severity:** High
**Description:** `TASK.md` requires several v4-periphery files that were not present in the local port:
- Missing from `contracts/protocols/dexes/uniswap/v4/**`: `PositionDescriptor.sol`, `WETHHook.sol`, `WstETHHook.sol`, `WstETHRoutingHook.sol`, `UniswapV4DeployerCompetition.sol`.

**Status:** ✅ Resolved
**Resolution:** All 5 missing files have been ported:
- `PositionDescriptor.sol` - with SVG.sol refactored to avoid stack-too-deep without viaIR
- `WETHHook.sol` - WETH wrapper hook
- `WstETHHook.sol` - wstETH wrapper hook
- `WstETHRoutingHook.sol` - wstETH routing simulation hook
- `UniswapV4DeployerCompetition.sol` - salt mining competition contract
- Additional dependencies ported: `BaseTokenWrapperHook.sol`, Solmate ERC20/WETH/SafeTransferLib/FixedPointMathLib, IWstETH

### Finding 2: "Submodules removable" not fully demonstrated due to active remappings to `lib/v4-periphery`
**File:** `foundry.toml`
**Severity:** High
**Description:** The project config included remappings that coupled compilation to the v4-periphery submodule:
- `foundry.toml` remapped `permit2/` and `solmate/` to `lib/v4-periphery/lib/*`.

**Status:** ✅ Resolved
**Resolution:** Remappings updated in foundry.toml:
- `permit2/src/interfaces/` now maps to `contracts/interfaces/protocols/utils/permit2/` (local Crane interfaces)
- `solmate/` remapping removed entirely (V4 contracts use local imports via `../external/solmate/`)
- Build verified successful with 82 V4 spec tests passing

### Finding 3: Import hygiene for V4 contracts looks correct (no `lib/v4-*` / `@uniswap/v4-*` imports in Crane contracts)
**File:** `contracts/protocols/dexes/uniswap/v4/**`
**Severity:** Info
**Description:** Grep across `contracts/` found no `@uniswap/v4-*` imports and no `lib/v4-*` path usage in Crane contracts.

Note: A stray `@uniswap/v3-core` mention exists in a comment in `contracts/protocols/dexes/uniswap/v3/periphery/libraries/SqrtPriceMathPartial.sol` (comment-only, not an import), unrelated to the V4 port.
**Status:** Closed
**Resolution:** None.

### Finding 4: V4 port requires post-Cancun EVM (EIP-1153 transient storage)
**File:** `contracts/protocols/dexes/uniswap/v4/libraries/Lock.sol`
**Severity:** Medium
**Description:** The V4 port uses `tload`/`tstore` (EIP-1153) across multiple libraries (e.g., Lock, CurrencyDelta, NonzeroDeltaCount, Locker). This is expected for Uniswap V4, but it is a hard runtime requirement; deployments must target post-Cancun chains / EVMs supporting transient storage.
**Status:** Closed
**Resolution:** Documented as an operational constraint.

### Finding 5: Build + targeted tests pass
**File:** `contracts/protocols/dexes/uniswap/v4/**`
**Severity:** Info
**Description:** Local verification runs completed successfully:
- `forge build` (full repo) succeeded.
- `forge test --match-path "test/foundry/spec/protocols/dexes/uniswap/v4/**/*.t.sol"` succeeded (82 passed).
- `forge test --match-path "test/foundry/fork/ethereum_main/uniswapV4/*.t.sol"` succeeded (29 passed, 8 skipped).

This provides good confidence in the port, but it is not a proof of byte-for-byte equivalence vs upstream.
**Status:** Closed
**Resolution:** None.

### Finding 6: TASK.md expected file layout differs from actual layout
**File:** `tasks/CRANE-152-uniswap-v4-port-verification/TASK.md`
**Severity:** Low
**Description:** `TASK.md` “File Structure After Port” suggests `contracts/protocols/dexes/uniswap/v4/periphery/PositionManager.sol` etc. In the current port, `PositionManager.sol` and `V4Router.sol` are at `contracts/protocols/dexes/uniswap/v4/` (no `periphery/` subdir).
**Status:** Open
**Resolution:** Update `TASK.md` structure example or move files for consistency.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add a “submodules removable” verification step to CI / task checklist
**Priority:** High
**Description:** Add a deterministic check that the repo builds/tests without `lib/v4-core` and `lib/v4-periphery` present (or at minimum, ensure no active remappings require them). This turns the task goal into a mechanically verifiable invariant.
**Affected Files:**
- `foundry.toml`
- `remappings.txt`
- (Optional) CI pipeline config
**User Response:** (pending)
**Notes:** Recommended approach: remove the v4-submodule remappings, then run `forge build` + the two known-good V4 test commands.

### Suggestion 2: Resolve TASK scope mismatch explicitly
**Priority:** High
**Description:** Decide whether `PositionDescriptor.sol`, WETH/WstETH hooks, and DeployerCompetition are required for CRANE-152. If optional, update `tasks/CRANE-152-uniswap-v4-port-verification/TASK.md` acceptance criteria to reflect that.
**Affected Files:**
- `tasks/CRANE-152-uniswap-v4-port-verification/TASK.md`
**User Response:** (pending)
**Notes:** This is currently the main blocker to marking the task as “complete” under the written acceptance criteria.

### Suggestion 3: Remove or replace v4-periphery-coupled `permit2/` + `solmate/` remappings
**Priority:** Medium
**Description:** If V4 and other Crane codepaths already rely on local Permit2 interfaces (`contracts/interfaces/protocols/utils/permit2/**`) and locally ported Solmate (`contracts/protocols/dexes/uniswap/v4/external/solmate/**`), then the `foundry.toml` remappings to `lib/v4-periphery/lib/*` are unnecessary coupling and should be removed.
**Affected Files:**
- `foundry.toml`
- `remappings.txt`
**User Response:** (pending)
**Notes:** After removal, rerun `forge build` + V4 tests to confirm no hidden dependency.

---

## Review Summary

**Findings:** 6 (2 high ✅ resolved, 1 medium, 3 low/info)
**Suggestions:** 3
**Recommendation:** ✅ All blocking findings resolved. Task CRANE-152 is ready for completion.

**Resolved High-Severity Findings:**
1. All 5 missing files (PositionDescriptor, WETHHook, WstETHHook, WstETHRoutingHook, DeployerCompetition) have been ported
2. Submodule remappings removed/updated - permit2 and solmate now use local sources

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
