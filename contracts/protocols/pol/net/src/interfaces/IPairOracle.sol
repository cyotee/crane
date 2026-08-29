// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IPairOracle — canonical-pair TWAP oracle
/// @notice Uniswap v2 cumulative-price TWAP on the canonical NET/USDG pair
///         (specs/mechanism.md §2, FINAL). Permissionless checkpoint with a
///         30-minute minimum spacing; reads are valid only over a window in
///         [30 minutes, 4 hours] and fail closed outside the band — spot
///         price is never used. Single TWAP source for the Distributor,
///         PremiumSeller, TaxCollector bounds, and market-op liveness gates.
interface IPairOracle {
    event Checkpointed(uint256 priceCumulative, uint32 timestamp);

    /// @notice Records a cumulative-price observation if at least
    ///         CHECKPOINT_MIN_INTERVAL has passed since the previous one.
    ///         Permissionless; no-op when called too early (never reverts on
    ///         cadence).
    function checkpoint() external;

    /// @notice Time-weighted NET price in WAD USDG per whole NET over a
    ///         window within [TWAP_MIN_WINDOW, TWAP_MAX_WINDOW]. Reverts if
    ///         no observation lands in the band (fail-closed).
    function twapNetUsdg() external view returns (uint256);

    /// @notice The canonical Uniswap v2 pair being observed.
    function pair() external view returns (address);

    /// @notice Minimum valid TWAP window in seconds (30 minutes).
    function twapMinWindow() external view returns (uint256);

    /// @notice Maximum valid TWAP window in seconds (4 hours).
    function twapMaxWindow() external view returns (uint256);
}
