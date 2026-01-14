# Progress Log: CRANE-012

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** Ready for code review
**Build status:** ✅ PASS (826 files compiled with warnings only)
**Test status:** ✅ PASS (55 Camelot tests, 0 failures)

---

## Session Log

### 2026-01-13 - Review Complete

Completed comprehensive review of Camelot V2 utilities. Key findings documented below.

### 2026-01-13 - Task Launched

- Task launched via /backlog:launch
- Agent worktree created
- Ready to begin implementation

---

## Camelot V2 Correctness Memo

### Key Invariants for Camelot V2

#### 1. Constant Product Invariant (Non-Stable Pools)
- **Formula**: `K = reserve0 * reserve1`
- **Preservation**: After any swap, `K_new >= K_old` (fees accumulate into reserves)
- **Verification**: `CamelotPair._k()` computes this invariant
- **Location**: `CamelotPair.sol:375-384`

```solidity
function _k(uint256 balance0, uint256 balance1) internal view returns (uint256) {
    if (stableSwap) {
        // Stable pool uses: x3y + y3x >= k (cubic)
        uint256 _x = balance0.mul(1e18) / precisionMultiplier0;
        uint256 _y = balance1.mul(1e18) / precisionMultiplier1;
        uint256 _a = (_x.mul(_y)) / 1e18;
        uint256 _b = (_x.mul(_x) / 1e18).add(_y.mul(_y) / 1e18);
        return _a.mul(_b) / 1e18;
    }
    return balance0.mul(balance1);  // Non-stable: x*y
}
```

#### 2. Fee Denominator Invariant
- **Value**: `FEE_DENOMINATOR = 100,000` (PPHK - parts per hundred thousand)
- **Max Fee**: `MAX_FEE_PERCENT = 2,000` (2%)
- **Default Fee**: `token0FeePercent = token1FeePercent = 500` (0.5%)
- **Location**: `CamelotPair.sol:28-34`

#### 3. Protocol Fee Mint Invariant
- **Trigger**: On mint/burn operations when `feeTo != address(0)` and `kLast != 0`
- **Formula**:
  ```
  d = (FEE_DENOMINATOR * 100 / ownerFeeShare) - 100
  liquidity = totalSupply * (rootK - rootKLast) * 100 / (rootK * d + rootKLast * 100)
  ```
- **Location**: `CamelotPair._mintFee()` at lines 155-189
- **Mirrored in**: `ConstProdUtils._calculateProtocolFee()` at lines 706-746

#### 4. Minimum Liquidity Lock Invariant
- **Value**: `MINIMUM_LIQUIDITY = 1000` (burned to address(0) on first deposit)
- **Purpose**: Prevents total supply from reaching zero
- **Location**: `CamelotPair.sol:19`

#### 5. Reserve Overflow Invariant
- **Constraint**: `reserve0, reserve1 <= type(uint112).max`
- **Enforcement**: `_update()` function at line 146

---

### Directional Fee Mechanisms

Camelot V2's distinguishing feature is **directional fees** - different fees for token0 vs token1 swaps.

#### Fee Storage
```solidity
uint16 public token0FeePercent = 500;  // Default 0.5%
uint16 public token1FeePercent = 500;  // Default 0.5%
```

#### Fee Application in Swaps

1. **Fee Selection by Direction**: The fee applied depends on which token is being sold:
   - Selling token0 → uses `token0FeePercent`
   - Selling token1 → uses `token1FeePercent`

2. **Implementation in `_swap()`** (CamelotPair.sol:291-373):
   ```solidity
   tokensData.remainingFee0 = amount0In.mul(_token0FeePercent) / FEE_DENOMINATOR;
   tokensData.remainingFee1 = amount1In.mul(_token1FeePercent) / FEE_DENOMINATOR;
   ```

3. **Implementation in `_getAmountOut()`** (CamelotPair.sol:418-451):
   ```solidity
   uint16 feePercent = tokenIn == token0 ? token0FeePercent : token1FeePercent;
   return _getAmountOut(amountIn, tokenIn, reserve0, reserve1, feePercent);
   ```

#### Fee Sorting in Crane Utilities

**CamelotV2Service** correctly handles directional fees via `_sortReservesStruct()`:
```solidity
function _sortReservesStruct(ICamelotPair pool, IERC20 knownToken)
    internal view returns (ReserveInfo memory reserves)
{
    (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent) = pool.getReserves();
    address token0 = pool.token0();

    if (address(knownToken) == token0) {
        reserves.feePercent = token0feePercent;      // Use token0's fee when selling token0
        reserves.unknownFee = token1FeePercent;
    } else {
        reserves.feePercent = token1FeePercent;      // Use token1's fee when selling token1
        reserves.unknownFee = token0feePercent;
    }
}
```

**ConstProdUtils** also provides a fee-aware `_sortReserves()` overload:
```solidity
function _sortReserves(
    address knownToken, address token0,
    uint256 reserve0, uint256 reserve0Fee,
    uint256 reserve1, uint256 reserve1Fee
) internal pure returns (
    uint256 knownReserve, uint256 knownReserveFee,
    uint256 unknownReserve, uint256 unknownReserveFee
)
```

#### Referrer Fee Share
Camelot supports referrer fee rebates that reduce the remaining LP fee:
```solidity
uint256 referrerInputFeeShare = referrer != address(0)
    ? ICamelotFactory(factory).referrersFeeShare(referrer) : 0;
if (referrerInputFeeShare > 0) {
    fee = amount0In.mul(referrerInputFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 2);
    tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
    _safeTransfer(tokensData.token0, referrer, fee);
}
```

---

### Fee-on-Transfer Token Handling

#### Router-Level Support

**CamelotRouter** provides explicit fee-on-transfer support via balance-check patterns:

1. **`swapExactTokensForTokensSupportingFeeOnTransferTokens()`** (CamelotRouter.sol:239-256):
   - Measures balance delta rather than trusting input amounts
   - Pattern: `balanceAfter - balanceBefore >= amountOutMin`

2. **`_swapSupportingFeeOnTransferTokens()`** (CamelotRouter.sol:217-237):
   ```solidity
   uint256 amountInput = IERC20(input).balanceOf(address(pair)).sub(reserve0);
   amountOutput = pair.getAmountOut(amountInput, input);
   ```

3. **`removeLiquidityETHSupportingFeeOnTransferTokens()`** (CamelotRouter.sol:179-191):
   - Transfers actual token balance rather than expected amount
   - `TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));`

#### Service-Level Pattern

**CamelotV2Service** uses `swapExactTokensForTokensSupportingFeeOnTransferTokens` by default for all swaps:
```solidity
function _executeSwap(SwapParams memory params, address[] memory path) private {
    params.router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        params.amountIn,
        1, // amountOutMin - minimal to allow any output
        path,
        address(this),
        params.referrer,
        block.timestamp
    );
}
```

**Critical Observation**: The service sets `amountOutMin = 1`, meaning it accepts any output. This is intentional for maximum compatibility with fee-on-transfer tokens but shifts slippage protection responsibility to the caller.

#### Quote Accuracy with Fee-on-Transfer Tokens

The **ConstProdUtils** library quotes assume standard ERC20 behavior. When fee-on-transfer tokens are used:

1. **`_saleQuote()`** will overestimate output
2. **`_purchaseQuote()`** will underestimate required input
3. **Workaround**: Applications must apply their own reduction factor based on known token transfer tax

---

### Missing Tests and Recommendations

#### Currently Covered Tests

| Test File | Coverage Area |
|-----------|---------------|
| `ConstProdUtils_purchaseQuote_Camelot.t.sol` | Exact-output quote calculations |
| `ConstProdUtils_depositQuote_Camelot.t.sol` | LP mint calculations |
| `ConstProdUtils_withdrawQuote_Camelot.t.sol` | LP burn calculations |
| `ConstProdUtils_quoteSwapDepositWithFee_Camelot.t.sol` | Zap-in with protocol fees |
| `ConstProdUtils_quoteWithdrawWithFee_Camelot.t.sol` | Withdrawal with protocol fees |
| `ConstProdUtils_quoteWithdrawSwapWithFee_Camelot.t.sol` | Zap-out calculations |
| `ConstProdUtils_quoteZapOutToTargetWithFee_Camelot.t.sol` | Target-amount zap-out |
| `ConstProdUtils_calculateFeePortionForPosition_Camelot.t.sol` | Fee attribution |
| `ConstProdUtils_swapDepositSaleAmt_Camelot.t.sol` | Optimal swap amount for zap-in |

#### Identified Gaps

##### 1. **Asymmetric Fee Testing** (CRITICAL)
**Gap**: No tests verify behavior when `token0FeePercent != token1FeePercent`

**Recommended Tests**:
```solidity
// Fuzz test for asymmetric fees
function testFuzz_asymmetricFees_swapDirection(
    uint16 token0Fee,
    uint16 token1Fee,
    uint256 amountIn
) public {
    vm.assume(token0Fee > 0 && token0Fee <= 2000);
    vm.assume(token1Fee > 0 && token1Fee <= 2000);
    vm.assume(token0Fee != token1Fee);  // Ensure asymmetry
    // Test both swap directions produce correct outputs
}
```

**Test Suite**: Unit + Fuzz

##### 2. **Stable Swap Pool Testing** (HIGH)
**Gap**: `CamelotPair.stableSwap` mode is present in stub but not tested

**Recommended Tests**:
- Cubic invariant preservation: `x^3*y + y^3*x >= k`
- Swap output accuracy for stable pairs
- `_get_y()` Newton-Raphson convergence

**Test Suite**: Unit + Invariant Fuzz

##### 3. **Protocol Fee Mint Parity** (MEDIUM)
**Gap**: Limited testing of `_calculateProtocolFee()` edge cases

**Recommended Tests**:
- `kLast == 0` case
- `rootK == rootKLast` (no fee)
- `ownerFeeShare` boundary values (0, 50000, 100000)
- Cross-reference with actual pair `_mintFee()` output

**Test Suite**: Unit + Property-Based

##### 4. **Fee-on-Transfer Integration** (MEDIUM)
**Gap**: No tests with actual fee-on-transfer token stubs

**Recommended Tests**:
```solidity
contract FeeOnTransferToken is ERC20 {
    uint256 public transferTax = 500; // 5%

    function _transfer(address from, address to, uint256 amount) internal override {
        uint256 tax = amount * transferTax / 10000;
        super._transfer(from, to, amount - tax);
    }
}
```

**Test Suite**: Integration + Fuzz

##### 5. **Referrer Fee Integration** (LOW)
**Gap**: Referrer fee share not tested in Crane utilities

**Recommended Tests**:
- Quote accuracy when referrer rebate applies
- Fee distribution verification

**Test Suite**: Unit

##### 6. **Invariant Preservation Tests** (HIGH)
**Gap**: No invariant fuzz tests verifying K preservation across operations

**Recommended Tests**:
```solidity
function invariant_K_never_decreases() public {
    uint256 kBefore = pair.kLast();
    // Execute random operation
    uint256 kAfter = pair.kLast();
    assertGe(kAfter, kBefore);
}
```

**Test Suite**: Invariant Fuzz

##### 7. **Multi-Hop Swap Testing** (LOW)
**Gap**: Router's multi-hop path handling not tested with directional fees

**Recommended Tests**:
- Path with different fee configurations per hop
- Accumulated fee impact on final output

**Test Suite**: Integration

---

### Quote Accuracy Analysis

#### Swap Quote (`_saleQuote`)
- **Accuracy**: Exact match with `CamelotPair._getAmountOut()` for non-stable pools
- **Formula Parity**: Both use `amountIn * (D - fee) * reserveOut / (reserveIn * D + amountIn * (D - fee))`
- **Confidence**: HIGH

#### Purchase Quote (`_purchaseQuote`)
- **Accuracy**: Conservative (+1 rounding up)
- **Formula**: `(reserveIn * amountOut * D / ((reserveOut - amountOut) * (D - fee))) + 1`
- **Confidence**: HIGH (always sufficient)

#### Zap-In Quote (`_quoteSwapDepositWithFee`)
- **Accuracy**: Accounts for protocol fee mint dilution
- **Limitation**: Assumes router `_addLiquidity` logic (chooses min of A/B optimal)
- **Confidence**: MEDIUM-HIGH

#### Zap-Out Quote (`_quoteWithdrawSwapWithFee`)
- **Accuracy**: Full parity with CamelotV2Utils implementation
- **Includes**: Protocol fee mint, withdrawal, post-burn swap
- **Confidence**: HIGH

---

## Checklist

### Inventory Check
- [x] Camelot V2 utilities reviewed (`contracts/protocols/dexes/camelot/v2/`)
- [x] CamelotV2Service.sol reviewed
- [x] Directional fees documented

### US-CRANE-012.1 Deliverables
- [x] PROGRESS.md lists key invariants for Camelot V2
- [x] PROGRESS.md documents directional fee mechanisms
- [x] PROGRESS.md documents fee-on-transfer token handling
- [x] PROGRESS.md lists missing tests and recommended suites (unit/spec/fuzz)

### Completion
- [x] Review findings documented in PROGRESS.md
- [x] `forge build` passes (826 files, warnings only)
- [x] `forge test` passes (55/55 Camelot tests pass)
