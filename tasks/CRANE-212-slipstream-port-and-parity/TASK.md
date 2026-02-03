# Task CRANE-212: Port Slipstream + Add Fork Parity Tests (Temporary forge install)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-03
**Dependencies:** None
**Worktree:** `feature/slipstream-port-and-parity`
**Priority:** HIGH

---

## Description

Consolidate the Slipstream port + parity validation into a single task that follows the temporary dependency workflow:

1. Create worktree
2. Install upstream as a temporary submodule/dependency via `forge install <URL>`
3. Pin the upstream revision (commit) and port required contracts into Crane-owned paths
4. Add fork-parity tests that compare our ported core behavior against production Slipstream on Base mainnet
5. Remove the installed upstream dependency and ensure Crane builds + tests still pass

This replaces split tasks CRANE-209 (port) and CRANE-210 (parity tests).

## Upstream Source (pin before code changes)

- Upstream repo: https://github.com/aerodrome-finance/slipstream
- Pinned upstream commit/tag: 7844368af8f83459b5056ff5f3334ff041232382
- Install command (run inside worktree):
  - `forge install https://github.com/aerodrome-finance/slipstream`

## User Stories

### US-CRANE-212.1: Temporary Upstream Install (Worktree-Local)

As a developer, I want the upstream Slipstream source installed only in the worktree so that porting/parity can reference upstream without reintroducing a permanent submodule.

**Acceptance Criteria:**
- [ ] Create the task worktree `feature/slipstream-port-and-parity`
- [ ] Run `forge install https://github.com/aerodrome-finance/slipstream` inside the worktree
- [ ] Checkout the pinned commit/tag recorded above (do not rely on default branch head)
- [ ] Record the actual resolved revision (commit hash) in this TASK.md if it differs

### US-CRANE-212.2: Port Slipstream Core + Fee Modules

As a developer, I want the Slipstream factory/pool + required fee modules ported into Crane-owned paths so we can deploy and test parity.

**Acceptance Criteria:**
- [ ] Port the Slipstream factory + pool implementation needed to create pools locally (minimum for parity):
  - `CLFactory` (or Slipstream-equivalent factory)
  - `CLPool` (or Slipstream-equivalent pool)
- [ ] Port the fee modules required by mainnet Slipstream pools used in our fork parity scenarios:
  - `CustomSwapFeeModule`
  - `CustomUnstakedFeeModule`
- [ ] Reuse existing Uniswap V3 ports where code is identical (TickMath, FullMath, SwapMath, etc.)
- [ ] All imports resolve to Crane-owned paths (no `lib/` imports in the final state)
- [ ] `forge build` succeeds

### US-CRANE-212.3: Fork Parity Tests vs Production Slipstream (Base)

As a developer, I want fork parity tests that compare production Slipstream behavior to our ported contracts.

**Acceptance Criteria:**
- [ ] Tests skip gracefully when `INFURA_KEY` is not set
- [ ] Fork Base mainnet using a foundry rpc alias (e.g. `base_mainnet_infura`)
- [ ] Deploy test tokens on the fork; create fresh pools on both factories
- [ ] Parity coverage includes at minimum:
  - createPool + initialize parity (slot0, liquidity, tickSpacing, fee)
  - mint/burn liquidity parity using pool callback flow
  - swap parity (both directions; include a deterministic tick-crossing case)
  - observe/cardinality parity for oracle state
- [ ] Tests runnable via:
  - `forge test --match-path "test/foundry/fork/base_main/slipstream/*"`

### US-CRANE-212.4: Remove Temporary Upstream Dependency

As a developer, I want the upstream install removed after validation so the repo no longer depends on it.

**Acceptance Criteria:**
- [ ] Remove the installed upstream dependency from the worktree (delete the `lib/` entry and any remappings it introduced)
- [ ] Confirm there are no remaining imports referencing the installed upstream dependency
- [ ] `forge build` succeeds after removal
- [ ] Slipstream tests still pass (spec + fork) after removal

## Technical Details

### Expected Crane Port Location

```
contracts/protocols/dexes/aerodrome/slipstream/
```

### Expected Fork Test Location

```
test/foundry/fork/base_main/slipstream/
```

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Temporary upstream dependency removed
- [ ] `forge build` succeeds
- [ ] Fork tests pass when enabled and skip cleanly when disabled

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
