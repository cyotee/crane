// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title ITaxCollector — trading-tax accrual and conversion
/// @notice Receives the NET-denominated 5% fee-on-transfer accrual
///         (collect-then-convert; no re-entry into the pool during swaps).
///         A keeper entrypoint batch-swaps NET → USDG on the canonical pool
///         with TWAP-bounded slippage and clip-size limits, then splits USDG
///         proceeds team/treasury by the deterministic decay
///         (specs/mechanism.md §4, specs/tax.md §4):
///             teamBps     = 300 × (1 − v)   // v = pTEAM vestedFraction
///             treasuryBps = 500 − teamBps
///         Treasury share is deposited per treasury policy; team share goes
///         to the team multisig. No admin setter exists for the split.
interface ITaxCollector {
    event Converted(
        uint256 netIn, uint256 usdgOutRaw, uint256 teamUsdgRaw, uint256 treasuryUsdgRaw
    );

    /// @notice Swaps up to `netAmount` accrued NET to USDG and distributes
    ///         per the current split. Reverts if the clip exceeds
    ///         TAX_SWAP_MAX_CLIP_BPS of pool reserves or execution deviates
    ///         more than TAX_SWAP_MAX_DEV_BPS from the TWAP.
    function convert(uint256 netAmount, uint256 minUsdgOutRaw) external;

    /// @notice Current team share of the 500 bps total (300 → 0 over 30 days).
    function teamBps() external view returns (uint256);

    /// @notice Current treasury share (500 − teamBps; 200 → 500).
    function treasuryBps() external view returns (uint256);

    /// @notice NET accrued and not yet converted.
    function pendingNet() external view returns (uint256);

    /// @notice The team multisig receiving the team share.
    function teamWallet() external view returns (address);
}
