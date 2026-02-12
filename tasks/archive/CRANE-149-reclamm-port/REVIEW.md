# Code Review: CRANE-149

**Reviewer:** OpenCode
**Review Started:** 2026-02-01
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

- None. Review based on TASK.md acceptance criteria and current Foundry config.

---

## Review Findings

### Finding 1: ReClaMM port still depends on `lib/reclamm` via remappings
**File:** `remappings.txt`
**Severity:** High
**Description:** `@balancer-labs/v3-*` remappings resolve into `lib/reclamm/lib/balancer-v3-monorepo/...`. The ported ReClaMM contracts in `contracts/protocols/dexes/balancer/v3/reclamm/**` still import `@balancer-labs/v3-*`, so removing the `lib/reclamm` submodule will break compilation.
**Status:** Open
**Resolution:** Vendor/move the Balancer v3 packages out of `lib/reclamm` (or update imports/remappings to point at an in-repo copy). Until then, TASK.md “enable removal of `lib/reclamm`” is not met.

### Finding 2: `exclude_paths` in Foundry config is not a supported key
**File:** `foundry.toml`
**Severity:** Medium
**Description:** `exclude_paths = ["lib/reclamm/test"]` is ignored. `forge config --json` prints: `Warning: Found unknown \`exclude_paths\` config for profile \`default\``. This means compilation/test behavior can unintentionally include `lib/reclamm/test` (and any other unwanted paths) depending on what Foundry discovers.
**Status:** Resolved
**Resolution:** Updated config to a supported key: `skip = ["lib/reclamm/**"]`.

### Finding 3: One test asserts a hard-coded CREATE3 deployment address
**File:** `test/foundry/spec/protocols/dexes/balancer/v3/reclamm/ReClammPoolFactory.t.sol`
**Severity:** Low
**Description:** `testDeploymentAddress()` asserts a fixed address for `getDeploymentAddress(ONE_BYTES32)`. This is environment-sensitive (factory address, init code hashing, etc.) and is currently failing in this worktree.
**Status:** Open
**Resolution:** Assert a property instead of a fixed address (e.g., consistency between predicted address and actual deployed pool) or gate the assertion behind an environment that pins the deployer/factory.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Make `lib/reclamm` removal actually possible
**Priority:** High
**Description:** Stop resolving Balancer v3 dependencies via `lib/reclamm`. Either (a) move/vend the needed Balancer v3 monorepo packages into a dedicated repo path (e.g., `lib/balancer-v3-monorepo/` or `contracts/external/balancer-v3/`) and update `remappings.txt`, or (b) convert ReClaMM imports to use Crane-owned interfaces/contracts that do not re-export from `@balancer-labs/v3-*`.
**Affected Files:**
- `remappings.txt`
- `contracts/protocols/dexes/balancer/v3/reclamm/ReClammPool.sol`
- `contracts/protocols/dexes/balancer/v3/reclamm/ReClammPoolExtension.sol`
- `contracts/protocols/dexes/balancer/v3/reclamm/ReClammPoolFactory.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-195. Original note: `contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol` currently re-exports the upstream interface via `@balancer-labs/v3-interfaces`.

### Suggestion 2: Replace unsupported Foundry config key
**Priority:** Medium
**Description:** Remove `exclude_paths` and use supported Foundry configuration to avoid compiling unwanted submodule test sources.
**Affected Files:**
- `foundry.toml`
**User Response:** Accepted
**Notes:** Converted to task CRANE-196. Partially implemented by switching to `skip = ["lib/reclamm/**"]`.

### Suggestion 3: Stabilize or relax deterministic-address test
**Priority:** Low
**Description:** Change `testDeploymentAddress()` to validate deterministic behavior without hard-coding a single expected address.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/reclamm/ReClammPoolFactory.t.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-197. This also makes CI/worktree differences less brittle.

---

## Review Summary

**Findings:** 3 (1 high, 1 medium, 1 low)
**Suggestions:** 3
**Recommendation:** Not ready to claim “`lib/reclamm` removable” until remappings/import strategy is corrected.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
