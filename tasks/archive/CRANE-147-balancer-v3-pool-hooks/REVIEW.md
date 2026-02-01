# Code Review: CRANE-147

**Reviewer:** OpenCode (gpt-5.2)
**Review Started:** 2026-01-31
**Status:** Complete

---

## Clarifying Questions

None - acceptance criteria and scope were clear from `tasks/CRANE-147-balancer-v3-pool-hooks/TASK.md`.

---

## Review Findings

### Finding 1: Hook Contracts Under 24KB ✅
**Severity:** Info
**Description:** Verified runtime bytecode sizes are under the 24,576 byte limit.
**Status:** Resolved

Runtime sizes (bytes):
- `contracts/protocols/dexes/balancer/v3/hooks/StableSurgeHook.sol`: 8,484
- `contracts/protocols/dexes/balancer/v3/hooks/MevCaptureHook.sol`: 8,210
- `contracts/protocols/dexes/balancer/v3/hooks/ExitFeeHookExample.sol`: 5,368
- `contracts/protocols/dexes/balancer/v3/hooks/DirectionalFeeHookExample.sol`: 4,286
- `contracts/protocols/dexes/balancer/v3/hooks/VeBALFeeDiscountHookExample.sol`: 3,671
- `contracts/protocols/dexes/balancer/v3/hooks/ECLPSurgeHook.sol`: 18,521
- `contracts/protocols/dexes/balancer/v3/hooks/MinimalRouter.sol`: 10,265

### Finding 2: Hook Test Suite Passes ✅
**Severity:** Info
**Description:** Hook test suite passes (43 tests).
**Status:** Resolved

Command:
- `forge test --match-path "test/foundry/spec/protocols/dexes/balancer/v3/hooks/*.t.sol"`

### Finding 3: “Works With Diamond Vault” Not Directly Covered By Tests
**Severity:** Medium
**Description:** The hook tests use Balancer's `BaseVaultTest` harness and do not explicitly deploy and exercise Crane's Balancer V3 Diamond Vault (`contracts/protocols/dexes/balancer/v3/vault/diamond/**`). This means the key acceptance criterion "Works with Diamond Vault" is indirectly satisfied (hooks use `IVault` and `onlyVault` gating), but not validated end-to-end against the Diamond implementation.
**Status:** Open
**Resolution:** Add a follow-up integration test that deploys the Diamond vault and registers/runs at least one swap + one proportional add/remove with each hook.

### Finding 4: Minor Doc/Comment Mismatches
**Severity:** Low
**Description:** A few comments in examples/tests are slightly misleading:
**Status:** Open

- `contracts/protocols/dexes/balancer/v3/hooks/ExitFeeHookExample.sol`: inside the hook callback, `msg.sender` is the Vault (due to `onlyVault`), but the comment says "Router" in the donation call.
- `test/foundry/spec/protocols/dexes/balancer/v3/hooks/VeBALFeeDiscountHookExample.t.sol`: comments mention "linear" discount, but the hook implements a binary 50% discount when `balanceOf(user) > 0`.

### Finding 5: StableSurgePoolFactory Not Present (Optional)
**Severity:** Info
**Description:** `StableSurgePoolFactory` is not implemented in this worktree.
**Status:** Acknowledged
**Resolution:** This matches `tasks/CRANE-147-balancer-v3-pool-hooks/TASK.md` where it is marked optional / not implemented.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add Diamond-Vault Integration Tests
**Priority:** High
**Description:** Add a small integration suite that deploys Crane's Balancer V3 Diamond Vault and validates hook registration + one swap + one proportional add/remove per hook.
**Affected Files:**
- New test(s) under `test/foundry/spec/protocols/dexes/balancer/v3/hooks/`
**User Response:** (pending)
**Notes:** This directly closes the primary integration acceptance criteria.

### Suggestion 2: Align Comments With Actual Behavior
**Priority:** Low
**Description:** Fix minor comment mismatches (Vault vs Router `msg.sender`, “linear” vs binary discount wording).
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/hooks/ExitFeeHookExample.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/hooks/VeBALFeeDiscountHookExample.t.sol`
**User Response:** (pending)
**Notes:** Non-blocking; improves readability.

---

## Review Summary

**Findings:** 5 (2 resolved, 1 acknowledged, 2 open)
**Suggestions:** 2
**Recommendation:** Approve with follow-up (integration tests recommended)

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
