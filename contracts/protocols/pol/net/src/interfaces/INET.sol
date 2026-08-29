// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

/// @title INET — NetNet reserve token
/// @notice ERC-20, 9 decimals, with a 5% (500 bps, immutable) fee-on-transfer
///         keyed to a mapping of AMM pair addresses (specs/tax.md):
///         transfers to a mapped pair (sell) or from a mapped pair (buy) are
///         taxed; wallet-to-wallet transfers are free. Tax accrues in NET to
///         the TaxCollector. Minting is restricted to the Treasury
///         (specs/treasury.md §1 — sole minter of record).
/// @dev The tax is disabled until `GenesisBond.finalize()` registers the
///      canonical Uniswap v2 pair and flips it on (specs/genesis.md §2).
///      The pair-mapping/whitelist key model is OPEN_QUESTIONS Q7; this
///      interface exposes an add-only pair surface pending that resolution.
interface INET is IERC20Metadata {
    /// @notice Emitted when an AMM pair is registered as taxed.
    event TaxedPairAdded(address indexed pair);
    /// @notice Emitted when a tax exemption is queued (executable after EXEMPT_DELAY).
    event TaxExemptQueued(address indexed account, uint64 executableAt);
    /// @notice Emitted when a queued tax exemption takes effect. Permanent.
    event TaxExemptAdded(address indexed account);

    event TaxExemptCancelled(address indexed account);
    /// @notice Emitted when the trading tax is enabled at genesis finalize.
    event TaxEnabled(address indexed canonicalPair);
    /// @notice Emitted on every taxed transfer leg.
    event TaxCollected(address indexed payer, address indexed pair, uint256 netAmount);

    /// @notice Immutable total trading tax, in bps. Always 500.
    function taxTotalBps() external pure returns (uint256);

    /// @notice True once GenesisBond.finalize() has enabled the trading tax.
    function taxEnabled() external view returns (bool);

    /// @notice The TaxCollector receiving NET-denominated tax accrual.
    function taxCollector() external view returns (address);

    /// @notice The canonical Uniswap v2 NET/USDG pair (TWAP + tax + POL venue).
    function canonicalPair() external view returns (address);

    /// @notice Whether `pair` is registered in the taxed AMM-pair mapping.
    function isTaxedPair(address pair) external view returns (bool);

    /// @notice Whether `account` is exempt from the trading tax.
    function isTaxExempt(address account) external view returns (bool);

    /// @notice Enables the trading tax and registers the canonical pair.
    ///         Callable once, by GenesisBond only, during finalize().
    function enableTax(address canonicalPair_) external;

    /// @notice Factory kind used for on-chain pool validation in
    ///         `addTaxedPair` (specs/tax.md §1 FINAL).
    enum PoolKind {
        UniswapV2,
        UniswapV3
    }

    /// @notice Registers an additional AMM pair as taxed. Guardian key;
    ///         executes instantly (only widens coverage). Add-only — no
    ///         removal path exists. The address is validated on-chain against
    ///         the canonical factory for `kind` (`v3Fee` ignored for v2): it
    ///         must be a live pool with NET as one of its tokens
    ///         (specs/tax.md §1 FINAL).
    function addTaxedPair(address pair, PoolKind kind, uint24 v3Fee) external;

    /// @notice Queues a tax exemption for `account`, executable after
    ///         EXEMPT_DELAY. Guardian key.
    function queueTaxExempt(address account) external;

    /// @notice Guardian cancels a queued (not-yet-effective) exemption.
    function cancelTaxExempt(address account) external;

    /// @notice Executes a queued exemption once its delay has elapsed.
    ///         Exemptions are permanent — no removal path exists (Q7).
    function executeTaxExempt(address account) external;

    /// @notice Mints NET. Treasury only.
    function mint(address to, uint256 amount) external;

    /// @notice Burns NET from the caller.
    function burn(uint256 amount) external;

    /// @notice Burns NET from `from` using the caller's allowance.
    function burnFrom(address from, uint256 amount) external;
}
