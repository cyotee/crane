// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IDistributor — algorithmic staking emissions
/// @notice Mints epoch staking rewards under the immutable premium-throttled
///         rate (specs/mechanism.md §2):
///             P    = twapPrice / backingPerToken
///             rate = R_MAX × clamp((P − 1) / (K − 1), 0, 1),  R_MAX = 0.45%/epoch, K = 1.75
///         subject to the RFV hard cap (post-mint totalSupply ≤ Treasury.rfv()
///         in USDG terms; the mint CLAMPS to remaining capacity — see
///         OPEN_QUESTIONS D2). There are NO owner functions on this path; all
///         parameters are immutable.
interface IDistributor {
    event Distributed(uint256 indexed epoch, uint256 amount, uint256 rateWad);

    /// @notice Mints the current epoch reward to the Staking contract.
    ///         Staking only; called from rebase().
    /// @return minted NET actually minted (post RFV clamp).
    function distribute() external returns (uint256 minted);

    /// @notice The reward the formula would mint right now, post RFV clamp.
    function nextReward() external view returns (uint256);

    /// @notice Current premium multiple P = TWAP / backingPerToken, WAD.
    ///         Reverts if the TWAP is stale (spot is never used).
    function premium() external view returns (uint256);

    /// @notice Current epoch rate, WAD fraction of staked-eligible supply.
    function currentRateWad() external view returns (uint256);

    /// @notice R_MAX as WAD (0.0045e18). Immutable.
    function rMaxWad() external view returns (uint256);

    /// @notice K as WAD (1.75e18). Immutable.
    function kWad() external view returns (uint256);
}
