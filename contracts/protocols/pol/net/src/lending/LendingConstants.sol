// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title LendingConstants — Loopback named constants (specs/lending.md)
/// @notice Every number in specs/lending.md appears exactly once here.
///         All values RESOLVED by the human 2026-07-22; retuning any of them
///         means a successor market + oracle (specs/lending.md §1.3) — there
///         are no owner functions anywhere in Loopback.
library LendingConstants {
    /// @dev Oracle haircut h = 10% off TWAP (specs/lending.md §3).
    uint256 internal constant HAIRCUT_BPS = 1000;

    /// @dev Premium-credit cap C = 5× floor — the euphoria governor
    ///      (specs/lending.md §3): market pricing below ~5.6× premium,
    ///      backing-anchored credit above it.
    uint256 internal constant PREMIUM_CAP = 5;

    /// @dev Divergence guard: the oracle fails closed when the pair's
    ///      instantaneous price sits more than 15% below TWAP
    ///      (specs/lending.md §3 — blocks stale-high-mark borrowing).
    ///      DEFAULT — TUNE BEFORE DEPLOY.
    uint256 internal constant DIVERGENCE_BPS = 1500;

    /// @dev Morpho LLTV tier (advance rate ceiling): 62.5%
    ///      (specs/lending.md §5 — LIF ≈ 12.7% clears the 5% sell tax).
    uint256 internal constant LLTV = 0.625e18;

    /// @dev TurboRouter opens no position above 53.125% LTV — 85% of LLTV.
    ///      The 15% buffer survives the worst-case pTEAM floor step (−13%)
    ///      plus interest headroom (specs/lending.md §5). UX-layer: manual
    ///      Morpho users can exceed it.
    uint256 internal constant TARGET_LTV_WAD = 0.53125e18;

    uint256 internal constant BPS = 10_000;

    /// @dev Morpho oracle price scale (1e36) net of decimals:
    ///      36 + loan(6) − collateral(18) = 24; from a WAD USD-per-wsNET
    ///      value that is a further ×1e6 (specs/lending.md §3).
    uint256 internal constant WAD_TO_MORPHO_PRICE = 1e6;
}
