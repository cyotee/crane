// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IStaking — NET ⇄ sNET (shareholder dividend program)
/// @notice Stake NET 1:1 for sNET; balances grow via epoch rebases
///         (EPOCH_LENGTH = 8 hours). `rebase()` is permissionless once the
///         epoch has elapsed: it pulls the Distributor mint (RFV-capped) and
///         rebases sNET (specs/mechanism.md §2–3). Disabled until
///         GenesisBond.finalize().
interface IStaking {
    event Staked(address indexed from, address indexed to, uint256 amount);
    event Unstaked(address indexed from, address indexed to, uint256 amount);
    event Rebased(uint256 indexed epoch, uint256 distributed);

    /// @notice Stakes `amount` NET from the caller, minting sNET to `to`.
    /// @return The sNET amount credited (1:1 net of any warmup).
    function stake(address to, uint256 amount) external returns (uint256);

    /// @notice Burns `amount` sNET from the caller, returning NET to `to`.
    /// @return The NET amount returned (1:1).
    function unstake(address to, uint256 amount) external returns (uint256);

    /// @notice Advances the epoch if elapsed: distributor mint → sNET rebase.
    ///         Permissionless; also checkpoints the TWAP oracle (OPEN_QUESTIONS D1).
    function rebase() external;

    /// @notice Current epoch state.
    /// @return length Epoch length in seconds (8 hours).
    /// @return number Epoch counter.
    /// @return end   Timestamp at which the current epoch can be rebased.
    /// @return distribute NET queued for distribution at next rebase.
    function epoch()
        external
        view
        returns (uint64 length, uint64 number, uint64 end, uint256 distribute);

    /// @notice True once staking has been enabled by GenesisBond.finalize().
    function enabled() external view returns (bool);

    /// @notice Enables staking and starts the epoch clock. GenesisBond only, once.
    function enable() external;

    /// @notice Warmup period in epochs (DEFAULT 0 — TUNE BEFORE DEPLOY).
    function warmupEpochs() external view returns (uint256);

    /// @notice Total NET held for stakers (backs all sNET fragments 1:1).
    function totalStaked() external view returns (uint256);
}
