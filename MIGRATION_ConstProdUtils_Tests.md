ConstProdUtils tests migration checklist

This checklist tracks legacy tests from `snippets/indexedex/old/spec/crane/utils/math/` that need to be migrated into the Crane test suite (per-DEX `.t.sol`). Check items as you migrate them.

- Test_ConstProdUtils_withdrawSwapQuote.sol
  - [x] test_withdrawSwapQuote_Camelot_balancedPool
  - [x] test_withdrawSwapQuote_Camelot_unbalancedPool
  - [x] test_withdrawSwapQuote_Camelot_extremeUnbalancedPool
  - [x] test_withdrawSwapQuote_Uniswap_balancedPool
  - [x] test_withdrawSwapQuote_Uniswap_unbalancedPool
  - [x] test_withdrawSwapQuote_Uniswap_extremeUnbalancedPool
  - [x] test_withdrawSwapQuote_edgeCase_smallLPAmount
  - [x] test_withdrawSwapQuote_edgeCase_largeLPAmount
  - [x] test_withdrawSwapQuote_edgeCase_differentFees
  - [x] test_withdrawSwapQuote_edgeCase_verySmallReserves
  - [x] test_withdrawSwapQuote_edgeCase_midRangeLPAmount
  - [x] test_withdrawSwapQuote_edgeCase_maxLPAmount

- Test_ConstProdUtils_withdrawTargetQuote.sol
 - Test_ConstProdUtils_withdrawTargetQuote.sol
  - [x] test_withdrawTargetQuote_Camelot_balancedPool
  - [x] test_withdrawTargetQuote_Camelot_unbalancedPool
  - [x] test_withdrawTargetQuote_Camelot_extremeUnbalancedPool
  - [x] test_withdrawTargetQuote_Uniswap_BalancedPool
  - [x] test_withdrawTargetQuote_Uniswap_UnbalancedPool
  - [x] test_withdrawTargetQuote_Uniswap_ExtremeUnbalancedPool
  - [x] test_withdrawTargetQuote_edgeCases

- Test_ConstProdUtils_withdrawSwapTargetQuote.sol
  - [x] test_withdrawSwapTargetQuote_Camelot_balancedPool_executionValidation
  - [x] test_withdrawSwapTargetQuote_Camelot_unbalancedPool_executionValidation
  - [x] test_withdrawSwapTargetQuote_Camelot_extremeUnbalancedPool_executionValidation
  - [x] test_withdrawSwapTargetQuote_Uniswap_balancedPool_executionValidation
  - [x] test_withdrawSwapTargetQuote_Uniswap_unbalancedPool_executionValidation
  - [x] test_withdrawSwapTargetQuote_Uniswap_extremeUnbalancedPool_executionValidation

- Test_ConstProdUtils_quoteWithdrawSwapWithFee.sol
  - Uniswap extract Token A (fees disabled/enabled, 3 percentages × 3 pools)
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesDisabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesEnabled_extractTokenA
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesEnabled_extractTokenA
  - Uniswap extract Token B (same set)
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesDisabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesEnabled_extractTokenB
    - [ ] test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesEnabled_extractTokenB

- Test_ConstProdUtils_quoteSwapDepositWithFee.sol
  - Uniswap fees disabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesDisabled
  - Uniswap fees enabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenA_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_balancedPool_swapsTokenB_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenA_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_unbalancedPool_swapsTokenB_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenA_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Uniswap_extremeUnbalancedPool_swapsTokenB_feesEnabled
  - Camelot fees disabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenA_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenB_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenA_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenB_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenA_feesDisabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenB_feesDisabled
  - Camelot fees enabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenA_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenB_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenA_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenB_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenA_feesEnabled
    - [ ] test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenB_feesEnabled

- Test_ConstProdUtils_calculateVaultFee.sol
  - [ ] test_calculateVaultFee_Camelot_extremeUnbalancedPool
  - [ ] test_calculateVaultFee_Uniswap_balancedPool
  - [ ] test_calculateVaultFee_Uniswap_unbalancedPool
  - [ ] test_calculateVaultFee_Uniswap_extremeUnbalancedPool
  - [ ] test_calculateVaultFeeNoNewK_Camelot_balancedPool
  - [ ] test_calculateVaultFeeNoNewK_Camelot_unbalancedPool
  - [ ] test_calculateVaultFeeNoNewK_Camelot_extremeUnbalancedPool
  - [ ] test_calculateVaultFeeNoNewK_Uniswap_balancedPool
  - [ ] test_calculateVaultFeeNoNewK_Uniswap_unbalancedPool
  - [ ] test_calculateVaultFeeNoNewK_Uniswap_extremeUnbalancedPool
  - [ ] test_calculateVaultFee_consistency

- Test_ConstProdUtils_calculateYieldForOwnedLP.sol
  - [ ] test_calculateYieldForOwnedLP_5Param_Camelot_balancedPool
  - [ ] test_calculateYieldForOwnedLP_5Param_Camelot_unbalancedPool
  - [ ] test_calculateYieldForOwnedLP_5Param_Camelot_extremeUnbalancedPool
  - [ ] test_calculateYieldForOwnedLP_5Param_Uniswap_balancedPool
  - [ ] test_calculateYieldForOwnedLP_5Param_Uniswap_unbalancedPool
  - [ ] test_calculateYieldForOwnedLP_5Param_Uniswap_extremeUnbalancedPool
  - [ ] test_calculateYieldForOwnedLP_6Param_Camelot_balancedPool
  - [ ] test_calculateYieldForOwnedLP_6Param_Camelot_unbalancedPool
  - [ ] test_calculateYieldForOwnedLP_6Param_Camelot_extremeUnbalancedPool
  - [ ] test_calculateYieldForOwnedLP_6Param_Uniswap_balancedPool
  - [ ] test_calculateYieldForOwnedLP_6Param_Uniswap_unbalancedPool
  - [ ] test_calculateYieldForOwnedLP_6Param_Uniswap_extremeUnbalancedPool
  - [ ] test_calculateYieldForOwnedLP_5Param_edgeCase_noGrowth
  - [ ] test_calculateYieldForOwnedLP_5Param_edgeCase_zeroOwnedLP
  - [ ] test_calculateYieldForOwnedLP_5Param_edgeCase_zeroTotalSupply
  - [ ] test_calculateYieldForOwnedLP_5Param_edgeCase_decreasedK
  - [ ] test_calculateYieldForOwnedLP_6Param_edgeCase_noGrowth
  - [ ] test_calculateYieldForOwnedLP_6Param_edgeCase_zeroOwnedLP
  - [ ] test_calculateYieldForOwnedLP_6Param_edgeCase_zeroTotalSupply
  - [ ] test_calculateYieldForOwnedLP_6Param_edgeCase_decreasedK
  - [ ] test_calculateYieldForOwnedLP_consistency
  - [ ] test_calculateYieldForOwnedLP_differentOwnedAmounts

- Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol
  - [ ] test_calculateFeePortionForPosition_Camelot_executionValidation
  - [ ] test_calculateFeePortionForPosition_Uniswap_executionValidation

- Test_ConstProdUtils_calculateFeePortionForPosition.sol
  - [ ] test_calculateFeePortionForPosition_Camelot_balancedPool
  - [ ] test_calculateFeePortionForPosition_Camelot_unbalancedPool
  - [ ] test_calculateFeePortionForPosition_Camelot_extremeUnbalancedPool
  - [ ] (Uniswap variants commented in legacy; consider migration candidates)

- Test_ConstProdUtils_sortReserves.sol
  - [ ] test_sortReserves_4Param_knownTokenIsToken0
  - [ ] test_sortReserves_4Param_knownTokenIsToken1
  - [ ] test_sortReserves_4Param_sameToken
  - [ ] test_sortReserves_4Param_differentToken
  - [ ] test_sortReserves_4Param_zeroReserves
  - [ ] test_sortReserves_4Param_largeReserves
  - [ ] test_sortReserves_6Param_knownTokenIsToken0
  - [ ] test_sortReserves_6Param_knownTokenIsToken1
  - [ ] test_sortReserves_6Param_sameToken
  - [ ] test_sortReserves_6Param_differentToken
  - [ ] test_sortReserves_6Param_zeroReserves
  - [ ] test_sortReserves_6Param_largeReserves
  - [ ] test_sortReserves_6Param_differentFees
  - [ ] test_sortReserves_6Param_highFees

- Test_ConstProdUtils_k.sol
  - [ ] test_k_Camelot_balancedPool
  - [ ] test_k_Camelot_unbalancedPool
  - [ ] test_k_Camelot_extremeUnbalancedPool
  - [ ] test_k_Uniswap_balancedPool
  - [ ] test_k_Uniswap_unbalancedPool
  - [ ] test_k_Uniswap_extremeUnbalancedPool
  - [ ] test_k_edgeCase_zeroBalances
  - [ ] test_k_edgeCase_oneZeroBalance
  - [ ] test_k_edgeCase_smallBalances
  - [ ] test_k_edgeCase_largeBalances
  - [ ] test_k_edgeCase_veryDifferentBalances
  - [ ] test_k_edgeCase_maxUint256

- Test_ConstProdUtils_calculateProtocolFee.sol
  - [ ] test_calculateProtocolFee_ExecutionValidation_BalancedPool
  - [ ] test_calculateProtocolFee_ExecutionValidation_UnbalancedPool
  - [ ] test_calculateProtocolFee_ExecutionValidation_ExtremeUnbalancedPool

- Test_ConstProdUtils_helpers.sol
  - [ ] test_withdrawTargetQuote
  - [ ] test_withdrawTargetQuote_edgeCases
  - [ ] test_saleQuoteMin
  - [ ] test_calculateProtocolFee
  - [ ] test_sortReserves
  - [ ] test_sortReservesWithFees
  - [ ] test_k_calculation

**Detected in Crane tests (per-DEX `.t.sol` files present in** `test/foundry/spec/utils/math/ConstProdUtils.sol`)**:**

- [x] ConstProdUtils_depositQuote_Camelot.t.sol
- [x] ConstProdUtils_depositQuote_Uniswap.t.sol
- [x] ConstProdUtils_equivLiquidity_Camelot.t.sol
- [x] ConstProdUtils_equivLiquidity_Uniswap.t.sol
- [x] ConstProdUtils_quoteWithdrawWithFee_Uniswap.t.sol
 - [x] ConstProdUtils_quoteWithdrawWithFee_Camelot.t.sol
- [x] ConstProdUtils_quoteZapInLP_Camelot.t.sol
- [x] ConstProdUtils_quoteZapInLP_Uniswap.t.sol
- [x] ConstProdUtils_quoteZapOutLP_Camelot.t.sol
- [x] ConstProdUtils_quoteZapOutLP_Uniswap.t.sol
- [x] ConstProdUtils_quoteZapOutToTargetWithFee_Uniswap.t.sol
- [x] ConstProdUtils_swapDepositQuote_Camelot.t.sol
- [x] ConstProdUtils_swapDepositQuote_Uniswap.t.sol
- [x] ConstProdUtils_swapQuote_Camelot.t.sol
- [x] ConstProdUtils_swapQuote_Uniswap.t.sol
- [x] ConstProdUtils_withdrawQuote_Camelot.t.sol
- [x] ConstProdUtils_withdrawQuote_Uniswap.t.sol
- [x] ConstProdUtils_withdrawSwap_Camelot.t.sol
- [x] ConstProdUtils_withdrawSwap_Uniswap.t.sol
- [x] ConstProdUtils_withdrawSwapQuote_Camelot.t.sol
- [x] ConstProdUtils_withdrawSwapQuote_Uniswap.t.sol
- [x] TestBase_ConstProdUtils_Aerodrome.sol
- [x] TestBase_ConstProdUtils_Camelot.sol
- [x] TestBase_ConstProdUtils_Uniswap.sol
 - [x] ConstProdUtils_withdrawTargetQuote_Uniswap.t.sol
 - [x] ConstProdUtils_withdrawTargetQuote_Camelot.t.sol

---
Notes:
- Some legacy tests were commented or contain TODOs about "stack too deep"; migrate using memory-struct overloads or contract-scoped Exec structs as needed.
- After migrating each test, run the focused Foundry test for that file's target suite.

Recent updates (2025-12-15 → 2025-12-15):

- **Completed / Present (migrated or added as per-DEX `.t.sol` files):**
  - `withdrawSwapQuote` — Camelot & Uniswap (per-DEX `.t.sol`) — focused suites present and passing in prior focused runs.
  - `swapDepositQuote` — Camelot & Uniswap — per-DEX `.t.sol` present.
  - `swapQuote` — Camelot & Uniswap — per-DEX `.t.sol` present.
  - `depositQuote` — Camelot & Uniswap — per-DEX `.t.sol` present.
  - `equivLiquidity` — Camelot & Uniswap — per-DEX `.t.sol` present.
  - `quoteWithdrawWithFee` — Uniswap & Camelot variants present (`ConstProdUtils_quoteWithdrawWithFee_Uniswap.t.sol`, `ConstProdUtils_quoteWithdrawWithFee_Camelot.t.sol`).
  - `quoteZapInLP` — Uniswap variant present; Camelot scaffold exists (see In-progress).
  - `quoteZapInLP` — Uniswap & Camelot — per-DEX `.t.sol` present (Camelot focused suite passed).
  - `quoteZapOutLP` — Uniswap and Camelot — per-DEX `.t.sol` present (focused fixes applied).
  - `quoteZapOutToTargetWithFee` — Uniswap variant present.
  - `withdrawTargetQuote` — Camelot & Uniswap — per-DEX `.t.sol` present and passing focused tests (Uniswap: 4, Camelot: 3).

- **Recent focused migration update (2025-12-15):**
  - Ran newly added `withdrawTargetQuote` per-DEX suites:
    - `ConstProdUtils_withdrawTargetQuote_Uniswap.t.sol` — 4 tests passed
    - `ConstProdUtils_withdrawTargetQuote_Camelot.t.sol` — 3 tests passed
  - Suite result: 7 tests passed, 0 failed.
  - Ran newly added `withdrawSwapTargetQuote` per-DEX suites (2025-12-15):
    - `ConstProdUtils_withdrawSwapTargetQuote_Uniswap.t.sol` — 3 tests passed
    - `ConstProdUtils_quoteWithdrawWithFee_Camelot.t.sol` — 3 tests passed
    - `ConstProdUtils_withdrawSwapTargetQuote_Camelot.t.sol` — 3 tests passed
  - Suite result: 6 tests passed, 0 failed.
  - Ran newly added `quoteZapInLP` Camelot focused suite (2025-12-15):
    - `ConstProdUtils_quoteZapInLP_Camelot.t.sol` — 3 tests passed
  - Suite result: 3 tests passed, 0 failed.
  - Ran newly added `withdrawSwapTargetQuote` per-DEX suites (2025-12-15):
    - `ConstProdUtils_withdrawSwapTargetQuote_Uniswap.t.sol` — 3 tests passed
    - `ConstProdUtils_withdrawSwapTargetQuote_Camelot.t.sol` — 3 tests passed
  - Suite result: 6 tests passed, 0 failed.
  - `withdrawQuote` — Camelot & Uniswap — per-DEX `.t.sol` present.
  - `withdrawSwap` — Camelot & Uniswap — per-DEX `.t.sol` present.

  - Test base contracts: `TestBase_ConstProdUtils_Aerodrome.sol`, `TestBase_ConstProdUtils_Camelot.sol`, `TestBase_ConstProdUtils_Uniswap.sol` — present.

- **Full focused run:**
  - Command: `forge test --match-path "test/foundry/spec/utils/math/ConstProdUtils.sol/**" -vvvv`
  - Result: 57 tests passed, 0 failed, 0 skipped (focused migration suites under the ConstProdUtils spec folder).

- **Fixes applied during migration:**
  - Replaced incorrect pair types (e.g., used `ICamelotPair` for Camelot pair tests).
  - Destructured `getReserves()` to capture fee fields where DEX pair exposes them (Camelot) and used those fee percents in Zap args.
  - Fixed tuple destructuring for factory `feeInfo()` where needed.
  - Removed duplicate contract scaffolds that caused compile errors.
  - Replaced ternary expressions that caused "stack too deep" with explicit if/else assignments.
  - Ensured pools are initialized before `burn()` to avoid zero-reserve panics (called `_initialize<DEX><variant>Pools()` helpers).
  - Used `_sortReserves(...)` to guarantee correct token/reserve ordering where appropriate.
  - Removed stray debug logging where no longer needed (most `console.log` lines removed or gated).

- **In-progress / pending:**
  - `quoteZapInLP` (Camelot): scaffolds present; final parity tests need finishing and verification.
  - Open PR and CI: commit/branch/PR steps not started; CI/workflow validation pending.

- **How to reproduce focused runs (examples):**

  - Run all migrated ConstProdUtils suites under the spec folder:

    forge test --match-path "test/foundry/spec/utils/math/ConstProdUtils.sol/**" -vvvv

  - Run a single per-DEX focused file (example):

    forge test --match-path test/foundry/spec/utils/math/ConstProdUtils.sol/ConstProdUtils_quoteZapOutLP_Camelot.t.sol -vvv

- **Next steps / recommended:**
  - Finish `ConstProdUtils_quoteZapInLP_Camelot.t.sol` parity tests and run focused tests.
  - Create a branch, commit migrations and fixes, run `forge build` and `forge test`, then open a PR for review.
  - Verify CI/remappings; run full `forge test` at repo root before merging.

---
Updated: 2025-12-15 — recorded focused test pass (57/57) and migration statuses.

