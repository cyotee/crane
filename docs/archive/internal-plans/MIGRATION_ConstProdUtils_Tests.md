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

  (migrated as `ConstProdUtils_quoteZapOutLP_*` files)
 
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateVaultFee.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateFeePortionForPosition.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_saleQuote.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_sortReserves.sol
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateZapOutLP.sol
  (migrated as `ConstProdUtils_quoteZapOutLP_*` files)
- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_minZapInAmount.sol  (migrated as `ConstProdUtils_minZapInAmount_*`)
 

Notes on quick findings (updated):
- `Test_ConstProdUtils_swapDepositSaleAmt.sol` — already migrated to:
  - test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_swapDepositSaleAmt_Uniswap.t.sol
  - test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_swapDepositSaleAmt_Camelot.t.sol
- `Test_ConstProdUtils_calculateZapOutLP.sol` — migrated under `ConstProdUtils_quoteZapOutLP_*` (Uniswap + Camelot)
- `Test_ConstProdUtils_swapDeposit.sol` — migrated as `ConstProdUtils_swapDepositQuote_*` and `ConstProdUtils_swapDepositSaleAmt_*`
- `Test_ConstProdUtils_saleQuote.sol` — analogous tests exist (see `ConstProdUtils_swapQuote_*` and related files)

Remaining items (need migration/parity verification):
- `Test_ConstProdUtils_quoteZapOutAmount.sol` (Uniswap & Camelot migrated)
- `Test_ConstProdUtils_calculateYieldForOwnedLP.sol` (Uniswap & Camelot migrated)
- `Test_ConstProdUtils_calculateVaultFee.sol`
- `Test_ConstProdUtils_calculateFeePortionForPosition.sol`
- `Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol`
- `Test_ConstProdUtils_sortReserves.sol`
- `Test_ConstProdUtils_calculateZapOutLPPrecise.sol`
- `Test_ConstProdUtils_k.sol`
- `Test_ConstProdUtils_calculateProtocolFee.sol`

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

Planned next migration: `Test_ConstProdUtils_quoteZapOutAmount.sol` — recommended

Rationale: `quoteZapOutAmount` exercises ZapOut/burn-to-output math and will surface rounding and fee-mint edgecases across DEXes; migrating it next helps validate current `quoteZapOut*` implementations early.
-Remaining items (need migration/parity verification):
- `Test_ConstProdUtils_calculateYieldForOwnedLP.sol`
- `Test_ConstProdUtils_purchaseQuote.sol`
- `Test_ConstProdUtils_calculateVaultFee.sol`
- `Test_ConstProdUtils_calculateFeePortionForPosition.sol`
- `Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol`
- `Test_ConstProdUtils_sortReserves.sol`
- `Test_ConstProdUtils_k.sol`
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

  (migrated as `ConstProdUtils_quoteZapOutLP_*` files)

-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateYieldForOwnedLP.sol
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_purchaseQuote.sol
- [x] snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateVaultFee.sol
- [x] snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateFeePortionForPosition.sol
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_saleQuote.sol
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_sortReserves.sol
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_calculateZapOutLP.sol
  (migrated as `ConstProdUtils_quoteZapOutLP_*` files)
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_minZapInAmount.sol  (migrated as `ConstProdUtils_minZapInAmount_*`)
- [x] snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_quoteZapOutAmount.sol
-- snippets/indexedex/old/spec/crane/utils/math/Test_ConstProdUtils_saleQuoteMin.sol

Notes on quick findings (updated):
- `Test_ConstProdUtils_swapDepositSaleAmt.sol` — already migrated to:
  - test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_swapDepositSaleAmt_Uniswap.t.sol
  - test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_swapDepositSaleAmt_Camelot.t.sol
- `Test_ConstProdUtils_calculateZapOutLP.sol` — migrated under `ConstProdUtils_quoteZapOutLP_*` (Uniswap + Camelot)
- `Test_ConstProdUtils_swapDeposit.sol` — migrated as `ConstProdUtils_swapDepositQuote_*` and `ConstProdUtils_swapDepositSaleAmt_*`
- `Test_ConstProdUtils_saleQuote.sol` — analogous tests exist (see `ConstProdUtils_swapQuote_*` and related files)

-Remaining items (need migration/parity verification):
- `Test_ConstProdUtils_quoteZapOutAmount.sol` (verify if fully covered by existing `quoteZapOut*` tests)
- `Test_ConstProdUtils_calculateYieldForOwnedLP.sol`
- `Test_ConstProdUtils_calculateVaultFee.sol`
- `Test_ConstProdUtils_calculateFeePortionForPosition.sol`
- `Test_ConstProdUtils_calculateFeePortionForPosition_struct.sol`
- `Test_ConstProdUtils_sortReserves.sol`
- `Test_ConstProdUtils_calculateZapOutLPPrecise.sol`
- `Test_ConstProdUtils_k.sol`
- `Test_ConstProdUtils_calculateProtocolFee.sol`

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


Planned next migration: `Test_ConstProdUtils_quoteZapOutAmount.sol` — recommended

Rationale: `quoteZapOutAmount` exercises ZapOut/burn-to-output math and will surface rounding and fee-mint edgecases across DEXes; migrating it next helps validate current `quoteZapOut*` implementations early.


