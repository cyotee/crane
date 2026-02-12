# Task CRANE-210: Add Slipstream Fork Parity Tests (Superseded)

**Repo:** Crane Framework
**Status:** Superseded
**Created:** 2026-02-02
**Dependencies:** CRANE-212
**Worktree:** -
**Priority:** HIGH

---

## Description

Superseded by CRANE-212, which includes these parity tests as part of a single consolidated port+parity workflow.

- the production Slipstream deployment (factory + pool implementation), and
- our locally ported Slipstream contracts from CRANE-209.

These tests should deploy **fresh pools** on both factories (using the same freshly-deployed test tokens on a Base mainnet fork), run identical operations, and assert state/output parity.

Note: this repo already has fork tests that validate `SlipstreamUtils` quote accuracy against production pools. Those are useful, but they are **not** “port parity” because they do not run our ported core contracts.

## Dependencies

- CRANE-209: Port Slipstream Contracts to Local Codebase (provides ported CLPool, CLFactory, etc.)

## User Stories

### US-CRANE-210.1: Fork Test Base Infrastructure for Slipstream

As a developer, I want a TestBase for Slipstream parity tests so that I can write consistent, reproducible tests comparing ported code against mainnet.

**Acceptance Criteria:**
- [ ] Extend `TestBase_SlipstreamFork.sol` to support deploying our local Slipstream stack
- [ ] Support Base mainnet forks with configurable block numbers
- [ ] Skip tests gracefully when RPC credentials are not available (follow existing `INFURA_KEY` pattern)
- [ ] Provide Slipstream factory address from `BASE_MAIN.sol`
- [ ] Include helpers for deploying our local ported Slipstream factory and pools
- [ ] Include helpers for creating pools on BOTH mainnet factory AND our local factory
- [ ] Support deploying test tokens with configurable decimals

### US-CRANE-210.2: Pool Creation + Initialization Parity Tests

As a developer, I want tests proving pool creation produces identical behavior on mainnet factory and our ported factory.

**Acceptance Criteria:**
- [ ] Create a pool on the production factory and on the ported factory with identical params
- [ ] Verify `createPool()` revert/success behavior matches for invalid/valid params
- [ ] Initialize both pools with the same `sqrtPriceX96` and assert key state matches (`slot0`, `liquidity`, `tickSpacing`, `fee`)
- [ ] Cover at least: 18/6 and 8/18 decimal token pairs
- [ ] Tick spacing: cover the fee tiers actually exercised by Slipstream on Base (don’t assume Uniswap v3 fee/tick mappings)

### US-CRANE-210.3: Swap Parity Tests (Pool-Level)

As a developer, I want tests proving swap operations produce identical results on mainnet pools and our ported pools.

**Acceptance Criteria:**
- [ ] Use direct `pool.swap()` calls (no periphery) against both pools
- [ ] Assert swap deltas and post-swap `slot0` parity for the same input conditions
- [ ] Cover both swap directions
- [ ] Include at least one tick-crossing case (seed liquidity so crossing is deterministic)
- [ ] Verify fee growth fields evolve identically (at minimum: global fee growth accumulators)

### US-CRANE-210.4: Liquidity Parity Tests (Pool-Level)

As a developer, I want tests proving NonfungiblePositionManager operations produce identical results.

**Acceptance Criteria:**
- [ ] Add liquidity to both pools using the pool mint callback flow (no NonfungiblePositionManager requirement)
- [ ] Remove liquidity and collect fees; assert emitted amounts/state match
- [ ] Cover at least one in-range and one out-of-range position

### US-CRANE-210.5: Oracle Observation Parity Tests

As a developer, I want tests proving oracle observations are recorded identically.

**Acceptance Criteria:**
- [ ] Test `pool.observe()` returns identical historical data
- [ ] Test oracle cardinality growth matches mainnet
- [ ] Verify TWAP calculations are identical

## Technical Details

### Directory Structure

```
test/foundry/fork/
└── base_main/
    └── slipstream/
        ├── TestBase_SlipstreamFork.sol          (existing - extend)
        ├── SlipstreamUtils_Fork.t.sol           (existing - quote accuracy vs prod pools)
        ├── SlipstreamGas_Fork.t.sol             (existing - gas benchmarks)
        ├── SlipstreamCoreParity_Fork.t.sol      (new - factory/pool parity)
        └── SlipstreamOracleParity_Fork.t.sol    (new - observe/cardinality/TWAP parity)
```

### Mainnet Contract Addresses (from BASE_MAIN.sol)

**Base Mainnet:**
- Factory: `BASE_MAIN.AERODROME_SLIPSTREAM_POOL_FACTORY`
- QuoterV2: `BASE_MAIN.AERODROME_SLIPSTREAM_QUOTER_V2` (used by existing fork tests; not required for core parity)

### Test Token Configuration

Deploy test ERC20s on the fork and use those addresses to create pools on both factories:
- 18 decimals token (WETH-style)
- 6 decimals token (USDC-style)
- 8 decimals token (WBTC-style)

### Tick Spacing / Fee Tiers

Do not hardcode Uniswap v3 fee->tickSpacing assumptions. Use the fee/tickSpacing model from the ported Slipstream factory and ensure both sides are configured consistently for the parity scenario.

### Comparison Methodology

1. Fork Base mainnet at a pinned block (deterministic)
2. Deploy test tokens (these exist in the forked state)
3. Deploy our local Slipstream stack (Factory + Pool implementation is the minimum)
4. Create pools on BOTH factories with identical params
5. Seed both pools with identical initial liquidity (pool-level mint flow)
6. Execute the same operations on both pools
7. Assert exact parity for core operations (no tolerance) unless a specific field is expected to diverge and is explicitly justified

### Key Considerations

1. Fork parity must compare **fresh pools with matched configuration**, not unrelated existing pools.
2. Avoid periphery parity (router/NFT/quoter) in this task unless CRANE-209 explicitly ports those components as part of the agreed minimal set.

## Files to Create/Modify

**New Files:**
- `test/foundry/fork/base_main/slipstream/SlipstreamCoreParity_Fork.t.sol`
- `test/foundry/fork/base_main/slipstream/SlipstreamOracleParity_Fork.t.sol`

**Modified Files:**
- `test/foundry/fork/base_main/slipstream/TestBase_SlipstreamFork.sol` - Add helpers for local stack deployment

## Inventory Check

Before starting, verify:
- [ ] CRANE-209 is complete (Slipstream contracts ported)
- [ ] Ported Slipstream core exists and compiles (CLFactory + CLPool equivalent)
- [ ] Existing `TestBase_SlipstreamFork.sol` can be extended
- [ ] `foundry.toml` has `base_mainnet_infura` RPC endpoint

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass with `forge test --match-path "test/foundry/fork/base_main/slipstream/*"`
- [ ] Tests skip gracefully when fork RPC credentials are not set
- [ ] Build succeeds with no new warnings
- [ ] Parity coverage includes: create+initialize, mint/burn liquidity, swap (both directions), observe/cardinality

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
