// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

/// @title IsNET — staked NET (rebasing)
/// @notice OHM-v1 gons/fragments accounting (specs/mechanism.md §3): total
///         gons are fixed and rebases scale gonsPerFragment so every holder's
///         balance grows proportionally each epoch. 9 decimals, 1 sNET pegs
///         1 staked NET.
interface IsNET is IERC20Metadata {
    /// @notice Emitted on each rebase.
    event LogRebase(uint256 indexed epoch, uint256 rebaseAmount, uint256 index);

    /// @notice Applies an epoch rebase distributing `profit` NET across all
    ///         staked balances. Staking contract only.
    /// @return newTotalSupply Total sNET fragments after the rebase.
    function rebase(uint256 profit, uint256 epoch) external returns (uint256 newTotalSupply);

    /// @notice Cumulative growth index since genesis (starts at 1e9). The UI's
    ///         "dividend index" (specs/mechanism.md §3).
    function index() external view returns (uint256);

    /// @notice Gons corresponding to `amount` fragments at the current scalar.
    function gonsForBalance(uint256 amount) external view returns (uint256);

    /// @notice Fragments corresponding to `gons` at the current scalar.
    function balanceForGons(uint256 gons) external view returns (uint256);
}
