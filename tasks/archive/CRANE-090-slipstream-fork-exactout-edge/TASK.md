# Task CRANE-090: Add Exact-Output Edge Case Tests to Slipstream Fork Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Updated:** 2026-02-04
**Dependencies:** CRANE-039
**Worktree:** `test/slipstream-fork-exactout-edge`
**Origin:** Code review suggestion from CRANE-039

---

## Description

Comprehensive edge-case coverage for exact-output quoting in SlipstreamUtils. The exact-input path has extensive edge case coverage, but exact-output needs parity. This task adds both fork tests (against real Base mainnet pools) and unit tests (with mocks for deterministic edge cases) covering all relevant edge case categories.

## Dependencies

- CRANE-039: Add Slipstream Fork Tests (Complete - parent task)

## Slipstream Architecture Context

### Exact-Output Function Overloads

SlipstreamUtils provides 4 exact-output function overloads:

1. **Core (sqrtPriceX96)**
   ```solidity
   _quoteExactOutputSingle(uint256 amountOut, uint160 sqrtPriceX96, uint128 liquidity, uint24 feePips, bool zeroForOne)
   ```

2. **Tick-based**
   ```solidity
   _quoteExactOutputSingle(uint256 amountOut, int24 tick, uint128 liquidity, uint24 feePips, bool zeroForOne)
   ```

3. **With unstaked fee (sqrtPriceX96)**
   ```solidity
   _quoteExactOutputSingle(uint256 amountOut, uint160 sqrtPriceX96, uint128 liquidity, uint24 feePips, uint24 unstakedFeePips, bool zeroForOne)
   ```

4. **With unstaked fee (tick)**
   ```solidity
   _quoteExactOutputSingle(uint256 amountOut, int24 tick, uint128 liquidity, uint24 feePips, uint24 unstakedFeePips, bool zeroForOne)
   ```

### Key Constants

- **Tick boundaries**: `MIN_TICK = -887272`, `MAX_TICK = 887272`
- **Price boundaries**: `MIN_SQRT_RATIO + 1` to `MAX_SQRT_RATIO - 1`
- **Tick spacings**: 1, 10, 50, 100, 200
- **Fee tiers**: FEE_LOW (100), FEE_MEDIUM (500), FEE_HIGH (3000), FEE_HIGHEST (10000)

---

## User Stories

### US-CRANE-090.1: Amount-Based Edge Cases

As a developer, I want edge case tests for various output amounts so that the library handles boundary conditions correctly.

**Acceptance Criteria:**

- [ ] **Zero output**: `quoteExactOutputSingle(0, ...) == 0` for all 4 overloads
- [ ] **Dust output (1 wei)**: Verify correct input calculation for minimal output
- [ ] **Sub-fee output**: Amounts smaller than the fee itself (where fee dominates)
- [ ] **Small amounts**: `amountOut = 1e6` to `1e12` range
- [ ] **Large amounts**: `amountOut = 1e18` to `1e30+` range
- [ ] **Near-depletion**: Output that consumes most available liquidity without crossing tick
- [ ] **Maximum precision**: Amounts requiring maximum input precision (rounding edge cases)

### US-CRANE-090.2: Liquidity-Based Edge Cases

As a developer, I want edge case tests for various liquidity levels so that the library handles sparse and dense liquidity correctly.

**Acceptance Criteria:**

- [ ] **Zero liquidity**: Returns zero or appropriate error behavior
- [ ] **Minimal liquidity (1 wei)**: Single wei of liquidity
- [ ] **Dust liquidity + normal output**: Just enough liquidity to facilitate one swap
- [ ] **Max liquidity**: `uint128.max` without overflow
- [ ] **High liquidity**: `type(uint128).max / 2`
- [ ] **Asymmetric liquidity**: Different liquidity distributions across tick widths

### US-CRANE-090.3: Fee Tier Edge Cases

As a developer, I want edge case tests for all fee tiers and combinations so that fee calculations are correct across all scenarios.

**Acceptance Criteria:**

- [ ] **FEE_LOW (100 pips / 0.01%)**: Exact-output with minimal fee
- [ ] **FEE_MEDIUM (500 pips / 0.05%)**: Standard Slipstream fee tier
- [ ] **FEE_HIGH (3000 pips / 0.3%)**: Higher fee tier
- [ ] **FEE_HIGHEST (10000 pips / 1%)**: Maximum standard fee tier
- [ ] **Zero fee (0 pips)**: Output with no fee deduction
- [ ] **Fee ordering**: Verify higher fee → requires more input for same output
- [ ] **Fee precision**: Fee calculation maintains precision through rounding

### US-CRANE-090.4: Unstaked Fee Edge Cases

As a developer, I want edge case tests for unstaked fee combinations so that Slipstream's unique fee mechanics work correctly.

**Acceptance Criteria:**

- [ ] **Base + unstaked combinations**: Test (100+100), (500+500), (3000+3000), (10000+10000)
- [ ] **Zero base + non-zero unstaked**: Unstaked fee only scenario
- [ ] **Non-zero base + zero unstaked**: Standard fee scenario via combined function
- [ ] **Maximum total fee**: Near-maximum combined fee scenarios
- [ ] **Combined fee precision**: Verify no precision loss in combined calculation

### US-CRANE-090.5: Price/Tick Boundary Edge Cases

As a developer, I want edge case tests at price and tick boundaries so that the library handles extreme values safely.

**Acceptance Criteria:**

- [ ] **1:1 price ratio**: `sqrtPriceX96 = (1 << 96)` (equal token values)
- [ ] **MIN_SQRT_RATIO + 1**: Near-minimum valid price
- [ ] **MAX_SQRT_RATIO - 1**: Near-maximum valid price
- [ ] **MIN_TICK boundary**: Current tick at or near minimum
- [ ] **MAX_TICK boundary**: Current tick at or near maximum
- [ ] **Full-range positions**: MIN_TICK to MAX_TICK liquidity
- [ ] **Extreme price ratios (high)**: Very high token0 vs token1 price
- [ ] **Extreme price ratios (low)**: Very low token0 vs token1 price
- [ ] **Reserve dominance**: Prices where one token dominates reserves

### US-CRANE-090.6: Tick Spacing Edge Cases

As a developer, I want edge case tests for all tick spacings so that the library works correctly across all pool configurations.

**Acceptance Criteria:**

- [ ] **Tick spacing 1**: Finest granularity (0.0001% per tick)
- [ ] **Tick spacing 10**: Common low-fee pool spacing
- [ ] **Tick spacing 50**: Medium granularity
- [ ] **Tick spacing 100**: Coarser granularity
- [ ] **Tick spacing 200**: Production pool standard
- [ ] **Tick-aligned outputs**: Output that lands exactly on tick boundaries
- [ ] **Non-aligned outputs**: Output that falls between tick boundaries
- [ ] **Near-tick-crossing**: Output amounts that nearly trigger tick crossing

### US-CRANE-090.7: Direction Edge Cases

As a developer, I want edge case tests for both swap directions so that the library handles directional asymmetry correctly.

**Acceptance Criteria:**

- [ ] **zeroForOne direction**: token0 → token1 (price decreases)
- [ ] **oneForZero direction**: token1 → token0 (price increases)
- [ ] **Both directions same pool**: Symmetric behavior validation
- [ ] **Directional + extreme prices**: Direction-specific edge cases at boundaries
- [ ] **Low-reserve direction**: Output precision when reserve is depleted

### US-CRANE-090.8: Precision & Rounding Edge Cases

As a developer, I want edge case tests for numerical precision so that the library maintains accuracy through all calculations.

**Acceptance Criteria:**

- [ ] **Off-by-one wei precision**: Exact boundary precision validation
- [ ] **Round-trip parity**: `exactOutput(X) → inputRequired → exactInput(inputRequired) ≈ X`
- [ ] **Fee rounding precision**: Fee calculation doesn't lose precision
- [ ] **Liquidity → amount conversions**: Boundary value conversions
- [ ] **sqrtPrice ↔ tick conversions**: TickMath precision in conversions
- [ ] **Tolerance bounds**: Define and validate explicit tolerance thresholds

### US-CRANE-090.9: Function Overload Parity

As a developer, I want tests ensuring all 4 function overloads produce consistent results so that developers can use any overload interchangeably.

**Acceptance Criteria:**

- [ ] **sqrtPriceX96 vs tick overloads**: Match exactly or within small tolerance
- [ ] **Base fee vs combined fee overloads**: Equivalent when unstakedFeePips = 0
- [ ] **All 4 overloads parity**: Identical results for equivalent inputs
- [ ] **Tick conversion precision**: No precision loss in tick → sqrtPrice conversion

### US-CRANE-090.10: Fork Tests (Real Pool Validation)

As a developer, I want fork tests against real Base mainnet pools so that edge cases are validated against production state.

**Acceptance Criteria:**

- [ ] **WETH/USDC 0.05% pool**: High liquidity, stable pair edge cases
- [ ] **cbBTC/WETH pool**: Bitcoin pair edge cases
- [ ] **Quote accuracy tolerance**: 0.1% for sqrtPrice, 0.5% for tick overloads
- [ ] **Edge cases on real pools**: Zero, dust, large amounts on actual pools

---

## Technical Details

### Test File Organization

**Fork Tests (real pools):**
- `test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol` - Add exact-output edge cases

**Unit Tests (mocks):**
- `test/foundry/spec/protocols/dexes/slipstream/SlipstreamUtils_quoteExactOutput.t.sol` - Add edge cases
- `test/foundry/spec/protocols/dexes/slipstream/SlipstreamUtils_edgeCases.t.sol` - Add exact-output variants

### Edge Case Matrix

| Category | Edge Case | Test Type | Priority |
|----------|-----------|-----------|----------|
| Amount | Zero output | Fork + Unit | P1 |
| Amount | Dust (1 wei) | Fork + Unit | P1 |
| Amount | Sub-fee amounts | Unit | P1 |
| Amount | Near-depletion | Unit | P2 |
| Liquidity | Zero liquidity | Unit | P1 |
| Liquidity | Minimal (1 wei) | Unit | P2 |
| Liquidity | Max (uint128.max) | Unit | P1 |
| Fee | All tiers (0, 100, 500, 3000, 10000) | Unit | P1 |
| Fee | Fee ordering validation | Unit | P2 |
| Unstaked | Base + unstaked combos | Unit | P1 |
| Unstaked | Zero base scenarios | Unit | P2 |
| Price | 1:1 ratio | Fork + Unit | P1 |
| Price | MIN_SQRT_RATIO + 1 | Unit | P1 |
| Price | MAX_SQRT_RATIO - 1 | Unit | P1 |
| Tick | MIN_TICK boundary | Unit | P1 |
| Tick | MAX_TICK boundary | Unit | P1 |
| Tick | All spacings (1,10,50,100,200) | Unit | P2 |
| Tick | Aligned vs non-aligned | Unit | P3 |
| Direction | zeroForOne | Fork + Unit | P1 |
| Direction | oneForZero | Fork + Unit | P1 |
| Precision | Off-by-one wei | Unit | P1 |
| Precision | Round-trip parity | Unit | P1 |
| Overload | sqrtPriceX96 vs tick | Fork + Unit | P1 |
| Overload | 4-way parity | Unit | P2 |

---

## Files to Create/Modify

**Modified Files:**
- `test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol` - Add fork edge cases
- `test/foundry/spec/protocols/dexes/slipstream/SlipstreamUtils_quoteExactOutput.t.sol` - Add unit edge cases
- `test/foundry/spec/protocols/dexes/slipstream/SlipstreamUtils_edgeCases.t.sol` - Add exact-output variants

---

## Inventory Check

Before starting, verify:
- [x] CRANE-039 is complete
- [x] SlipstreamUtils_Fork.t.sol exists
- [x] SlipstreamUtils_quoteExactOutput.t.sol exists
- [x] SlipstreamUtils_edgeCases.t.sol exists
- [ ] Understand all 4 function overloads in SlipstreamUtils.sol

---

## Completion Criteria

- [ ] All acceptance criteria met across all 10 user stories
- [ ] Edge cases cover all categories in the matrix
- [ ] Fork tests pass against Base mainnet
- [ ] Unit tests pass with mocks
- [ ] `forge build` succeeds
- [ ] No regressions in existing tests

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
