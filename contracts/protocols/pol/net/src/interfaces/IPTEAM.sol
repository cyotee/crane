// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IPTEAM — team option token (hard-capped, auto-vesting)
/// @notice The team's only compensation besides the decaying tax share
///         (specs/mechanism.md §5). Exercise mints NET at a strike of exactly
///         1 USDG per NET, paid into the Treasury — the strike equals the
///         backing floor, so exercise can never dilute it. All parameters
///         immutable; holder set fixed at deploy (OPEN_QUESTIONS Q6).
///         Cumulative exercised NET ≤ 15% of circulating supply at each
///         exercise, scaled by the 30-day linear vest from
///         GenesisBond.finalize(). Exclusion list: OPEN_QUESTIONS Q5.
interface IPTEAM {
    event Exercised(address indexed holder, uint256 netMinted, uint256 usdgPaidWad);

    /// @notice Mints `netAmount` NET to the holder against 1 USDG per NET
    ///         paid into the Treasury. Reverts beyond the vested cap.
    function exercise(uint256 netAmount) external;

    /// @notice Vested fraction v ∈ [0, 1e18]: clamp((now − finalize)/30d, 0, 1).
    ///         The single clock shared with the tax-split decay.
    function vestedFraction() external view returns (uint256);

    /// @notice Cumulative NET minted through exercise.
    function exercised() external view returns (uint256);

    /// @notice Max additional NET exercisable right now
    ///         (v × 15% × circulating − exercised, floored at 0).
    function exercisableNow() external view returns (uint256);

    /// @notice Circulating supply per the approved exclusion list (Q5).
    function circulatingSupply() external view returns (uint256);

    /// @notice Strike in WAD USDG per NET (1e18). Immutable.
    function strikeWad() external view returns (uint256);

    /// @notice Supply cap in bps of circulating (1500). Immutable.
    function capBps() external view returns (uint256);
}
