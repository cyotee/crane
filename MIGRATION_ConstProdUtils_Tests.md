ConstProdUtils tests migration checklist (Crane root)

This file maps legacy `snippets/.../Test_ConstProdUtils_*.sol` tests to the migrated per-DEX `.t.sol` tests under Crane's `test/foundry/spec/utils/math/constProdUtils`.

Legend: [x] migrated/present, [ ] missing / needs migration or parity work.

- Test_ConstProdUtils_withdrawSwapQuote.sol
  - [x] ConstProdUtils_withdrawSwapQuote_Uniswap.t.sol
  - [x] ConstProdUtils_withdrawSwapQuote_Camelot.t.sol

- Test_ConstProdUtils_withdrawTargetQuote.sol
  - [x] ConstProdUtils_withdrawTargetQuote_Uniswap.t.sol
  - [x] ConstProdUtils_withdrawTargetQuote_Camelot.t.sol

- Test_ConstProdUtils_withdrawSwapTargetQuote.sol
  - [x] ConstProdUtils_withdrawSwapTargetQuote_Uniswap.t.sol
  - [x] ConstProdUtils_withdrawSwapTargetQuote_Camelot.t.sol

# ConstProdUtils — Tests Remaining to Migrate

This compact checklist lists only the legacy `snippets/indexedex/old/spec/crane/utils/math/` tests that still need migration or parity work into Crane's per‑DEX test suite (`test/foundry/spec/utils/math/constProdUtils`).

Legend: • not migrated / missing

Files still needing migration or parity checks:

-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_swapDepositSaleAmt.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateZapOutLP.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_minZapInAmount.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_quoteZapOutAmount.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_saleQuoteMin.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateYieldForOwnedLP.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_swapDeposit.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_helpers.sol  
  (verify helper consolidation into `TestBase_*`; migrate remaining helper tests if needed)
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_purchaseQuote.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateVaultFee.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateFeePortionForPosition.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_saleQuote.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_sortReserves.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateZapOutLPPrecise.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_quoteSwapDepositWithFee.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_k.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateProtocolFee.sol

Partial/missing DEX counterparts to add:

- Camelot variant missing for: snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_quoteZapOutToTargetWithFee.sol (Uniswap present; add Camelot parity)

Notes:
- This file intentionally lists only the items that still require migration or verification. All other legacy tests were already migrated into per‑DEX `.t.sol` files.
- For each item, create a per‑DEX `.t.sol` test (Uniswap and/or Camelot as applicable) following the `TestBase_ConstProdUtils_*` patterns and verify with focused `forge test` runs.

Recommended next commands:

```bash
# run full migrated spec locally (focused)
forge test --match-path "test/foundry/spec/utils/math/constProdUtils/**" -vvv

# run a single migrated file for quick verification (example)
forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_quoteWithdrawSwapWithFee_Uniswap.t.sol -vvv
```

Updated: 2025-12-16


Planned next migration: none — `Test_ConstProdUtils_quoteWithdrawSwapWithFee.sol` already migrated; pick an item from the list above to prioritize.


