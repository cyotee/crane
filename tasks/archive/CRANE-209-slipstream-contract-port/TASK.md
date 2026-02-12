# Task CRANE-209: Port Slipstream Contracts to Local Codebase (Superseded)

**Repo:** Crane Framework
**Status:** Superseded
**Created:** 2026-02-02
**Dependencies:** None
**Worktree:** `feature/slipstream-contract-port`
**Priority:** HIGH

---

## Description

Superseded by CRANE-212, which consolidates the port + fork parity validation and requires a temporary upstream install workflow (create worktree -> `forge install` -> pin -> port -> parity -> remove dependency).

Note: this repo already contains Slipstream-facing utilities/tests (e.g. `ICLPool`, `SlipstreamRewardUtils`, `SlipstreamQuoter`, `SlipstreamZapQuoter`, fork tests under `test/foundry/fork/base_main/slipstream/`). The missing piece is the actual on-chain-equivalent Slipstream implementation (factory/pool/router/NFT PM/quoter/fee modules) needed to support real deploy-and-compare parity (CRANE-210).

Slipstream is Aerodrome's concentrated liquidity implementation on Base, sharing architecture with Uniswap V3 but with custom fee modules, gauges, and reward systems specific to Aerodrome.

## Dependencies

None (independent port task)

## User Stories

### US-CRANE-209.1: Port Core Pool Contracts

As a developer, I want Slipstream pool contracts ported locally so that I can integrate them with our Diamond-pattern infrastructure.

**Acceptance Criteria:**
- [ ] Record the exact upstream source (repo + commit hash/tag) in this TASK.md before code changes
- [ ] Port the Slipstream factory + pool implementation needed to create pools locally (minimum for CRANE-210):
  - `CLFactory` (or Slipstream-equivalent factory)
  - `CLPool` (or Slipstream-equivalent pool)
- [ ] Contracts compile with the repo compiler (Solidity 0.8.30)
- [ ] Behavior preserved; only minimal mechanical edits allowed (pragma bumps, import path rewrites, SPDX, cast/uint conversions required by 0.8.x)

### US-CRANE-209.2: Port Fee Module Contracts

As a developer, I want Slipstream fee modules ported so that I can test custom fee configurations.

**Acceptance Criteria:**
- [ ] Port the fee module contracts required by mainnet Slipstream pools used in fork tests (at minimum):
  - CustomSwapFeeModule
  - CustomUnstakedFeeModule
- [ ] Fee modules integrate with the ported pool/factory (pool.fee()/unstakedFee() behavior matches upstream)

### US-CRANE-209.3: Port Supporting Libraries

As a developer, I want all supporting libraries ported so that the ported contracts are self-contained.

**Acceptance Criteria:**
- [ ] Reuse existing Uniswap V3 ports where Slipstream is identical (TickMath, FullMath, SwapMath, etc.)
- [ ] Port only the Slipstream-different libraries/state structs (rewards, staking, fee module hooks)
- [ ] All imports resolve to Crane-owned paths (no lib/ submodule paths)

### US-CRANE-209.4: Update Remappings and Imports

As a developer, I want import paths updated so that the ported contracts don't depend on the submodule.

**Acceptance Criteria:**
- [ ] All Slipstream ports import from Crane-owned paths (no `lib/...` imports)
- [ ] `forge build` succeeds

### US-CRANE-209.5: Verify Compilation and Basic Tests

As a developer, I want ported contracts verified so that they're ready for integration and parity testing.

**Acceptance Criteria:**
- [ ] All ported contracts compile without errors
- [ ] Add/extend a minimal deploy test that deploys the ported factory + creates a pool
- [ ] Existing Slipstream tests continue to pass (spec + fork)
- [ ] No new compiler warnings introduced

## Technical Details

### Directory Structure

```
contracts/protocols/dexes/aerodrome/slipstream/
├── interfaces/
│   ├── ICLPool.sol              (existing)
│   ├── ICLFactory.sol           (new)
│   ├── INonfungiblePositionManager.sol (new)
│   ├── ISwapRouter.sol          (new)
│   └── IQuoterV2.sol            (new)
├── core/
│   ├── CLPool.sol               (new - ported)
│   ├── CLFactory.sol            (new - ported)
│   └── libraries/               (new/updated - only Slipstream-specific)
├── periphery/                   (optional for initial parity; add as needed)
│   ├── SwapRouter.sol           (new - ported)
│   ├── NonfungiblePositionManager.sol (new - ported)
│   └── lens/
│       └── QuoterV2.sol         (new - ported)
├── fee-modules/
│   ├── CustomSwapFeeModule.sol  (new - ported)
│   ├── CustomUnstakedFeeModule.sol (new - ported)
│   └── (others if required)
├── test/
│   └── bases/
│       └── TestBase_Slipstream.sol (existing)
├── SlipstreamRewardUtils.sol    (existing)
└── SlipstreamUtils.sol          (if exists, or in utils/)
```

### Source Contracts

Identify and port from Aerodrome Slipstream upstream:
- https://github.com/aerodrome-finance/slipstream

Before starting the port, pin the exact source revision here:
- Upstream commit/tag: 7844368af8f83459b5056ff5f3334ff041232382
- Upstream paths ported: (fill in)

### Key Differences from Uniswap V3

Slipstream differs from Uniswap V3 in:
1. **Fee modules** - Pluggable fee modules instead of fixed fees
2. **Gauge integration** - Liquidity mining rewards via gauges
3. **Unstaked fees** - Separate fee handling for unstaked positions
4. **veAERO integration** - Voting escrow mechanics for rewards

### Remapping Updates

Prefer continuing to import via `@crane/contracts/...` (already used across the codebase). Only add a dedicated Slipstream remapping if it is already a repo convention elsewhere.

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/core/CLPool.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/core/CLFactory.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/periphery/NonfungiblePositionManager.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/periphery/SwapRouter.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/periphery/lens/QuoterV2.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/fee-modules/*.sol`
- Various interfaces and libraries

**Modified Files:**
- `foundry.toml` - Add/update remappings
- Existing imports that reference submodule paths

## Inventory Check

Before starting, verify:
- [ ] Identify + pin source of Slipstream contracts (upstream repo + commit)
- [ ] Existing `ICLPool.sol` interface is complete or needs expansion
- [ ] Existing `SlipstreamUtils.sol` location and dependencies
- [ ] `TestBase_Slipstream.sol` and fork tests work before changes
- [ ] No circular dependencies with existing Aerodrome V1 contracts

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` succeeds
- [ ] Existing tests pass:
  - `forge test --match-path "test/foundry/spec/**/slipstream/**/*.t.sol"`
  - `forge test --match-path "test/foundry/fork/base_main/slipstream/*.t.sol"`
- [ ] No new compiler warnings
- [ ] Ready for CRANE-210 fork parity tests

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
