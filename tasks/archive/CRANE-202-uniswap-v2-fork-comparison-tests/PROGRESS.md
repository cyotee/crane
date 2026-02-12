# Progress Log: CRANE-202

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Verify with INFURA_KEY set for full fork tests
**Build status:** ✅ Pass
**Test status:** ✅ Stub tests pass (8/8), Fork tests skip gracefully without INFURA_KEY

---

## Session Log

### 2026-02-02 - Implementation Complete

**Files Created:**

1. **TestBase files (US-CRANE-202.1):**
   - `test/foundry/fork/ethereum_main/uniswapV2/TestBase_UniswapV2Fork.sol`
   - `test/foundry/fork/base_main/uniswapV2/TestBase_UniswapV2ForkBase.sol`

2. **Fork tests (US-CRANE-202.2):**
   - `test/foundry/fork/ethereum_main/uniswapV2/UniswapV2Utils_Fork.t.sol`
   - `test/foundry/fork/base_main/uniswapV2/UniswapV2Utils_ForkBase.t.sol`

3. **Stub sanity tests (US-CRANE-202.3):**
   - `test/foundry/spec/protocols/dexes/uniswap/v2/UniswapV2Stubs_Sanity.t.sol`

**Test Results (without INFURA_KEY):**

Stub sanity tests (local, non-fork):
```
Ran 8 tests for UniswapV2Stubs_Sanity.t.sol:UniswapV2Stubs_Sanity
[PASS] test_stub18_18_reverseSwapOutputMatchesConstProdQuote()
[PASS] test_stub18_18_swapOutputMatchesConstProdQuote()
[PASS] test_stub18_6_reverseSwapOutputMatchesConstProdQuote()
[PASS] test_stub18_6_swapOutputMatchesConstProdQuote()
[PASS] test_stubLiquidityProvision()
[PASS] test_stubPairCreation()
[PASS] test_stubRouterGetAmountsInMatchesConstProdQuote()
[PASS] test_stubRouterGetAmountsOutMatchesConstProdQuote()
Suite result: ok. 8 passed; 0 failed; 0 skipped
```

Fork tests (skip gracefully without INFURA_KEY):
```
Ran 1 test for UniswapV2Utils_Fork.t.sol:UniswapV2Utils_Fork
[SKIP: skipped] setUp()
Suite result: ok. 0 passed; 0 failed; 1 skipped

Ran 1 test for UniswapV2Utils_ForkBase.t.sol:UniswapV2Utils_ForkBase
[SKIP: skipped] setUp()
Suite result: ok. 0 passed; 0 failed; 1 skipped
```

**Acceptance Criteria Status:**

US-CRANE-202.1: Fork Test Base
- [x] Create `test/foundry/fork/ethereum_main/uniswapV2/TestBase_UniswapV2Fork.sol`
- [x] Create `test/foundry/fork/base_main/uniswapV2/TestBase_UniswapV2ForkBase.sol`
- [x] Fork gating: tests skip when `INFURA_KEY` is unset
- [x] Forks use `vm.createSelectFork("ethereum_mainnet_infura", blockNumber)` / `vm.createSelectFork("base_mainnet_infura", blockNumber)`
- [x] Mainnet addresses come from `ETHEREUM_MAIN.UNISWAP_V2_*` / `BASE_MAIN.UNISWAP_V2_*`

US-CRANE-202.2: Quote/Math Parity
- [x] Verify `getAmountsOut` aligns with `ConstProdUtils._saleQuote()` (same fee basis)
- [x] Verify `getAmountsIn` aligns with `ConstProdUtils._purchaseQuote()`
- [x] Tests for small, medium, and near-reserve-bound amounts
- [x] Tests for revert behavior (zero amount, empty path)

US-CRANE-202.3: Stub Sanity (Local) Tests
- [x] Deploy `UniV2Factory` + `UniV2Router02` stubs locally
- [x] Create pair, seed liquidity, assert swap output equals ConstProdUtils quote
- [x] Include 18/18 and 18/6 token decimal combinations

**Inventory Check:**
- [x] `contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol` exists
- [x] `contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol` exists
- [x] `contracts/utils/math/ConstProdUtils.sol` exists
- [x] `contracts/tokens/ERC20/ERC20PermitMintableStub.sol` exists
- [x] `foundry.toml` includes `ethereum_mainnet_infura` and `base_mainnet_infura`

**Technical Notes:**

1. Fee parity: Uniswap V2 uses 997/1000 internally (0.3% fee). ConstProdUtils uses 300/100000 = 0.3%. Both produce identical results.

3. The stub tests validate that local UniV2 stubs produce exact same output as ConstProdUtils, confirming behavioral parity.

---

### 2026-02-02 - Task Created

- Task designed via /design:design
- TASK.md populated with requirements for Uniswap V2 fork comparison tests
- Scope: Ethereum + Base mainnet forks comparing local stubs vs deployed contracts
- Test token approach: Deploy ERC20PermitMintableStub with 18 and 6 decimals
- Comparison method: Execute same operations on both, assert exact output match
- Ready for agent assignment via /backlog:launch
