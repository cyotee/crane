// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IGenesisBond — founding shareholder subscription
/// @notice Fixed-price (3 USDG/NET) founding offering with 300k USDG hard
///         cap, 10k per-wallet cap, on-chain founding-shareholder registry,
///         and the atomic `finalize()` that turns the protocol on
///         (specs/genesis.md). Deadline / min-raise / receipt form are
///         OPEN_QUESTIONS Q1–Q3.
interface IGenesisBond {
    /// @notice Founding-shareholder registry entry (specs/genesis.md §1).
    struct PurchaseRecord {
        address purchaser;
        uint96 usdgAmountWad;
        uint64 timestamp;
    }

    event Purchased(address indexed purchaser, uint256 usdgWad, uint256 netAmount);
    event Refunded(address indexed purchaser, uint256 usdgWad);
    event Finalized(uint256 raisedWad, uint256 toTreasuryWad, uint256 toPolWad, address pair);
    event Claimed(address indexed purchaser, uint256 netAmount);

    /// @notice Buys NET at GENESIS_PRICE with USDG (raw token units).
    ///         Reverts past the wallet cap, the hard cap, or the deadline.
    function purchase(uint256 usdgAmountRaw) external;

    /// @notice Refunds the caller's full purchase if the sale failed
    ///         (deadline passed below min raise — OPEN_QUESTIONS Q2).
    function refund() external;

    /// @notice Claims vested NET (5-day linear vest from finalize).
    function claim() external returns (uint256 netAmount);

    /// @notice Atomic protocol switch-on (specs/genesis.md §2): splits
    ///         proceeds 70/30 treasury/POL, mints + seeds the canonical v2
    ///         pool, enables staking + bonds + trading tax, starts the pTEAM
    ///         vest clock. Callable by anyone once cap is hit (or deadline
    ///         passed with ≥ min raise).
    function finalize() external;

    function finalized() external view returns (bool);

    /// @notice Timestamp of finalize(); the single vest/tax-decay clock origin.
    function finalizeTime() external view returns (uint64);

    /// @notice Total USDG raised, WAD.
    function totalRaised() external view returns (uint256);

    /// @notice NET purchased by `account` (total, vesting from finalize).
    function purchasedNetOf(address account) external view returns (uint256);

    /// @notice NET currently claimable by `account`.
    function claimableNetOf(address account) external view returns (uint256);

    /// @notice Number of registry entries.
    function registryLength() external view returns (uint256);

    /// @notice Registry entry `i` (append-only, on-chain cohort record).
    function registryAt(uint256 i) external view returns (PurchaseRecord memory);
}
