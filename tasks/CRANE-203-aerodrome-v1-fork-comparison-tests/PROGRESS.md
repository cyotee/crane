# Progress Log: CRANE-203

## Current Checkpoint

**Last checkpoint:** All acceptance criteria completed
**Next step:** Code review
**Build status:** :white_check_mark: Passing
**Test status:** :white_check_mark: 19/19 tests passing

---

## Session Log

### 2026-02-02 - Implementation Complete

#### Files Created

1. **TestBase_AerodromeFork.sol** - Base test contract for Aerodrome V1 fork tests
   - Location: `test/foundry/fork/base_main/aerodrome/TestBase_AerodromeFork.sol`
   - Features:
     - Fork gating via `INFURA_KEY` environment variable
     - Uses `vm.createSelectFork("base_mainnet_infura", FORK_BLOCK)` at block 28,000,000
     - Contract references from `BASE_MAIN` (factory, router)
     - Well-known pool addresses (WETH/USDC volatile, WETH/AERO volatile, USDC/USDbC stable)
     - Helper functions for pool metadata, reserves, fees
     - Swap execution via router and direct pool
     - Pool existence/liquidity validation
     - Assertion helpers for quote accuracy

2. **AerodromeVolatileUtils_Fork.t.sol** - Volatile pool fork tests
   - Location: `test/foundry/fork/base_main/aerodrome/AerodromeVolatileUtils_Fork.t.sol`
   - Tests:
     - `test_volatileQuote_WETH_USDC_sellWETH_small` - Small trade parity
     - `test_volatileQuote_WETH_USDC_sellUSDC_small` - Reverse direction
     - `test_volatileQuote_WETH_USDC_sellWETH_medium` - Medium trade
     - `test_volatileQuote_WETH_USDC_sellWETH_large` - Large trade with price impact
     - `test_volatileQuote_WETH_AERO_sellWETH` - Different pool pair
     - `test_volatileQuote_WETH_AERO_sellAERO` - Reverse direction
     - `test_constProdUtils_saleQuote_parity` - ConstProdUtils library validation
     - `test_constProdUtils_saleQuote_parity_reverse` - Reverse direction
     - `test_volatileFee_isApplied` - Fee application validation
     - `test_volatileFee_denominator_is_10000` - Confirms 10,000 fee denom

3. **AerodromeStableUtils_Fork.t.sol** - Stable pool fork tests
   - Location: `test/foundry/fork/base_main/aerodrome/AerodromeStableUtils_Fork.t.sol`
   - Tests:
     - `test_stableQuote_USDC_USDbC_sellUSDC_small` - Small trade parity
     - `test_stableQuote_USDC_USDbC_sellUSDbC_small` - Reverse direction
     - `test_stableQuote_USDC_USDbC_sellUSDC_medium` - Medium trade
     - `test_stableQuote_USDC_USDbC_sellUSDC_large` - Large trade
     - `test_serviceStable_getAmountOutStable_parity` - AerodromServiceStable validation
     - `test_serviceStable_getAmountOutStable_parity_reverse` - Reverse direction
     - `test_serviceStable_getAmountOutStable_multipleAmounts` - Multiple trade sizes
     - `test_stableCurve_lowerSlippageThanVolatile` - Curve property validation
     - `test_stableFee_isApplied` - Fee validation (5 bps for stable)

#### Acceptance Criteria Status

**US-CRANE-203.1: Fork Test Base**
- [x] Create `test/foundry/fork/base_main/aerodrome/TestBase_AerodromeFork.sol`
- [x] Fork gating: tests skip when `INFURA_KEY` is unset
- [x] Fork uses `vm.createSelectFork("base_mainnet_infura", blockNumber)`
- [x] Addresses pulled from `BASE_MAIN` (AERODROME_POOL_FACTORY, AERODROME_ROUTER)

**US-CRANE-203.2: Volatile Pool Quote Parity (Core Deliverable)**
- [x] Validate AerodromeUtils/ConstProdUtils amount-out calculations against on-chain pool
- [x] Include tests for multiple trade sizes (small, medium, large)
- [x] Include tests for both swap directions
- [x] Validate fee handling (Aerodrome uses 10,000 denominator)

**US-CRANE-203.3: Stable Pool Quote Parity (Core Deliverable)**
- [x] Validate AerodromServiceStable amount-out calculations against on-chain pool
- [x] Include tests for multiple trade sizes
- [x] Include tests for both swap directions

**US-CRANE-203.4: Minimal Execution Sanity**
- [x] Execute swaps through mainnet router on known pools
- [x] Assert balances change as expected
- [x] Output amount matches quote exactly (integer equality)

**Inventory Check**
- [x] `contracts/constants/networks/BASE_MAIN.sol` contains Aerodrome addresses
- [x] `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceVolatile.sol` exists
- [x] `contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol` exists
- [x] `contracts/utils/math/AerodromeUtils.sol` exists
- [x] `foundry.toml` includes `base_mainnet_infura` RPC endpoint

**Completion Criteria**
- [x] Tests pass: `forge test --match-path "test/foundry/fork/base_main/aerodrome/**"` (19/19)
- [x] Tests skip gracefully when `INFURA_KEY` is not set

#### Key Findings

1. **Exact Parity Achieved**: Both volatile and stable pool quotes from Crane service libraries match Aerodrome's on-chain `pool.getAmountOut()` exactly (integer equality).

2. **Fee Denominator Confirmed**: Aerodrome V1 uses 10,000 as fee denominator (not 100,000 like Uniswap V2).
   - Volatile pool fee: 30 bps (0.30%)
   - Stable pool fee: 5 bps (0.05%)

3. **ConstProdUtils Validation**: `ConstProdUtils._saleQuote()` produces exact matches with Aerodrome volatile pool math when using the correct fee denominator.

4. **AerodromServiceStable Validation**: `AerodromServiceStable._getAmountOutStable()` Newton-Raphson implementation matches Aerodrome stable pool math exactly.

5. **Stable Curve Property**: The x^3y + xy^3 = k curve provides significantly lower slippage than xy=k for similarly-priced assets (validated against actual pool reserves).

---

### 2026-02-02 - Task Created

- Task designed via /design:design
- TASK.md populated with requirements for Aerodrome V1 fork comparison tests
- Scope: Base mainnet fork comparing local service libraries vs deployed contracts
- Pool types: Both volatile (xy=k) AND stable (x^3y+xy^3=k) pools
- Ready for agent assignment via /backlog:launch
