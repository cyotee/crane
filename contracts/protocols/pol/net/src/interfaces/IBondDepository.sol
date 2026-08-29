// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title IBondDepository — standard bonds post-genesis (primary offerings)
/// @notice USDG reserve bonds and NET/USDG v2 LP bonds, 5-day linear vesting
///         (DEFAULT — TUNE BEFORE DEPLOY). Pricing formula is OPEN_QUESTIONS
///         Q11 — this interface is formula-agnostic: `bondPrice` is whatever
///         the resolved formula computes, and deposits are slippage-guarded
///         by `maxPrice`.
interface IBondDepository {
    event BondCreated(
        address indexed depositor,
        uint256 indexed marketId,
        uint256 amountIn,
        uint256 payout,
        uint256 priceWad
    );
    event BondRedeemed(address indexed depositor, uint256 indexed noteId, uint256 payout);

    /// @notice Deposits `amount` of the market's quote token (USDG or LP,
    ///         raw units) for a vesting NET payout.
    /// @param marketId   Bond market (0 = USDG reserve, 1 = NET/USDG v2 LP).
    /// @param amount     Quote-token amount in.
    /// @param maxPriceWad Reverts if the bond price exceeds this (slippage guard).
    /// @param to         Payout recipient.
    /// @return noteId    Vesting-note id.
    /// @return payout    NET payout that will vest.
    function deposit(uint256 marketId, uint256 amount, uint256 maxPriceWad, address to)
        external
        returns (uint256 noteId, uint256 payout);

    /// @notice Redeems all vested NET across the caller's notes to `to`.
    function redeem(address to) external returns (uint256 paid);

    /// @notice Current bond price for `marketId`, WAD USDG per NET.
    function bondPrice(uint256 marketId) external view returns (uint256);

    /// @notice Total NET currently pending (vested + unvested) for `account`.
    function pendingFor(address account)
        external
        view
        returns (uint256 totalPending, uint256 claimableNow);

    /// @notice Number of bond markets.
    function marketCount() external view returns (uint256);

    /// @notice Quote token for `marketId`.
    function quoteToken(uint256 marketId) external view returns (address);

    /// @notice True once enabled by GenesisBond.finalize().
    function enabled() external view returns (bool);

    /// @notice Enables bonding. GenesisBond only, once.
    function enable() external;
}
