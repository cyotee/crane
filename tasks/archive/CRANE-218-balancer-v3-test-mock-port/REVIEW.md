# Code Review: CRANE-218

**Reviewer:** (pending)
**Review Started:** 2026-02-04
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

(Questions and answers will be recorded here during review)

---

## Review Findings

### Finding 1: Fork parity test file missing (path + coverage)
**File:** `tasks/CRANE-218-balancer-v3-test-mock-port/TASK.md`
**Severity:** Medium
**Description:** TASK requires `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol`, but no such file exists. Existing Balancer fork tests live under `test/foundry/fork/ethereum_main/balancerV3/` and cover WeightedMath parity (and other pool types), not the specific mock/token parity described in US-CRANE-218.5.
**Status:** Resolved
**Resolution:** Added the required fork parity test at `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol`.

### Finding 2: Acceptance-grep false positives due to comment text
**File:** `contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol`
**Severity:** Low
**Description:** `rg "@balancer-labs/.*/contracts/test" contracts/` currently returns matches due to comments containing the literal substring `@balancer-labs/.../contracts/test/` (also present in `contracts/protocols/dexes/balancer/v3/test/mocks/WETHTestToken.sol`, `contracts/protocols/dexes/balancer/v3/test/mocks/ERC4626TestToken.sol`, `contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol`, `contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol`, `contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol`, `contracts/protocols/dexes/balancer/v3/test/mocks/ProtocolFeeControllerMock.sol`).
**Status:** Resolved
**Resolution:** Reworded the affected doc comments to remove the literal `@balancer-labs/.../contracts/test/` substring so the acceptance `rg` returns zero results.

### Finding 3: Commented Balancer test import still matches acceptance regex
**File:** `contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol`
**Severity:** Low
**Description:** `rg "@balancer-labs/.*/test/foundry/utils" contracts/` returns a match due to a commented-out import line: `// import {BaseVaultTest} from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";`.
**Status:** Resolved
**Resolution:** Removed the commented-out Balancer import line so the acceptance `rg` returns zero results.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Make acceptance-grep checks pass deterministically
**Priority:** High
**Description:** Update comment text and remove the commented-out import so the exact `rg` commands in US-CRANE-218.4 return zero results.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/WETHTestToken.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/ERC4626TestToken.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/ProtocolFeeControllerMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol`
**User Response:** (pending)
**Notes:** This is a documentation-only change; no runtime behavior impact.

### Suggestion 2: Align fork test requirement with reality
**Priority:** Medium
**Description:** Either (a) implement `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol` as specified (deploy upstream Balancer test mocks + Crane ports on a mainnet fork and compare behavior), or (b) update US-CRANE-218.5 to reference the existing fork suite under `test/foundry/fork/ethereum_main/balancerV3/` and narrow the claim to WeightedMath parity.
**Affected Files:**
- `test/foundry/fork/ethereum_main/balancerV3/BalancerV3WeightedPool_Fork.t.sol` (if expanding coverage)
- `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol` (if adding the requested file)
- `tasks/CRANE-218-balancer-v3-test-mock-port/TASK.md` (if adjusting acceptance criteria)
**User Response:** (pending)
**Notes:** Current PROGRESS.md notes a Foundry macOS fork-test issue; consider adding a deterministic skip mechanism if forks cannot run in some environments.

---

## Review Summary

**Findings:** 3 (1 medium, 2 low)
**Suggestions:** 2
**Recommendation:** Approve after addressing the acceptance-grep false positives and reconciling US-CRANE-218.5 with the actual fork test strategy.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
