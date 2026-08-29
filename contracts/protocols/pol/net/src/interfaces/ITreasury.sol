// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title ITreasury — NetNet reserve treasury
/// @notice Custodies USDG (liquid + Morpho-deployed) and the protocol-owned
///         canonical v2 LP; sole NET minter of record; computes RFV and
///         backingPerToken (specs/treasury.md).
/// @dev Fixed-point conventions (used across the whole suite):
///      - NET amounts: 9 decimals (native).
///      - USDG amounts: the token's native decimals at the raw-transfer layer;
///        all *reported* values below are normalized to WAD (1e18).
///      - `rfv()` is WAD USDG terms; `backingPerToken()` is WAD USDG per whole
///        NET (1e9 base units).
interface ITreasury {
    event MorphoDeposited(uint256 assets);
    event MorphoWithdrawn(uint256 assets);
    event NetMinted(address indexed minter, address indexed to, uint256 amount);
    event UsdgSpent(address indexed spender, address indexed to, uint256 amount);

    function usdg() external view returns (address);
    function net() external view returns (address);
    function morphoVault() external view returns (address);
    function canonicalPair() external view returns (address);

    /// @notice Risk-free value of reserves, WAD USDG terms:
    ///         liquid USDG + Morpho position × (1 − 2% haircut) + POL RFV
    ///         (2·sqrt(x·y) v2 convention). specs/treasury.md §2.
    function rfv() external view returns (uint256);

    /// @notice rfv() / totalSupply, WAD USDG per whole NET. The protocol NAV.
    function backingPerToken() external view returns (uint256);

    /// @notice Un-deployed USDG held by the treasury, WAD.
    function liquidUsdg() external view returns (uint256);

    /// @notice Current Morpho position in USDG terms (pre-haircut), WAD.
    function morphoAssets() external view returns (uint256);

    /// @notice Max fraction of treasury USDG deployable to Morpho, bps (7000).
    function morphoCapBps() external view returns (uint256);

    /// @notice Mints NET to `to`. Authorized minters only (fixed at deploy:
    ///         Distributor, GenesisBond, BondDepository, PremiumSeller, pTEAM).
    function mintNet(address to, uint256 amount) external;

    /// @notice Transfers USDG (raw token units) to `to`. Authorized spenders
    ///         only (fixed at deploy: InverseBond). Unwinds Morpho if liquid
    ///         balance is insufficient (specs/treasury.md §2).
    function spendUsdg(address to, uint256 amountRaw) external;

    /// @notice Deposits idle USDG into the Morpho vault up to the 70% cap.
    ///         Keeper entrypoint; precondition-checked on-chain.
    function rebalanceToMorpho(uint256 assetsRaw) external;

    /// @notice Withdraws USDG from the Morpho vault back to liquid reserves.
    function rebalanceFromMorpho(uint256 assetsRaw) external;

    function isMinter(address account) external view returns (bool);
    function isSpender(address account) external view returns (bool);
}
