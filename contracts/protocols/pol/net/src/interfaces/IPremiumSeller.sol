// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IPremiumSeller — standing ask above the premium threshold
/// @notice Params FINAL 2026-07-12 (specs/treasury.md §4): when the canonical
///         TWAP > backingPerToken × 2.0 (deliberately above K = 1.75, so the
///         treasury only sells after emissions are maxed), `execute()` —
///         permissionless — mints a clip of PREMIUM_CLIP_BPS (25 bps) of the
///         pool's NET reserves PER EXECUTION, with a minimum 1-hour interval
///         between executions, sells it into the canonical pool with
///         TWAP-bounded slippage, and sweeps the USDG to the Treasury. Small,
///         slow, formulaic; each NET sold brings in > 1 USDG by construction.
interface IPremiumSeller {
    event PremiumSold(uint256 netSold, uint256 usdgSweptRaw);

    /// @notice Mints and sells one clip, sweeping USDG to Treasury. Reverts
    ///         unless the premium threshold holds and PREMIUM_MIN_INTERVAL
    ///         has elapsed since the previous execution.
    function execute(uint256 minUsdgOutRaw) external returns (uint256 netSold, uint256 usdgOutRaw);

    /// @notice True when TWAP > backing × threshold and the interval has elapsed.
    function active() external view returns (bool);

    /// @notice NET clip that the next execution would sell (25 bps of pool
    ///         NET reserves).
    function clipSize() external view returns (uint256);

    /// @notice Timestamp of the last execution.
    function lastExecuteAt() external view returns (uint64);

    /// @notice Premium threshold as WAD multiple of backing (2e18, DEFAULT — TUNE BEFORE DEPLOY).
    function premiumThresholdWad() external view returns (uint256);
}
