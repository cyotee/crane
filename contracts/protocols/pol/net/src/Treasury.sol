// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@crane/contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title Treasury — NetNet reserve treasury (specs/treasury.md)
/// @notice Custodies USDG (liquid + Morpho) and the canonical-pair POL LP;
///         sole NET minter of record. RFV (WAD USDG terms):
///           liquid + morpho × (1 − 2% haircut) + POL at 2·√(x·y) (Q14 —
///           treasury-owned NET valued at its 1 USDG floor, never market).
///         Morpho rebalance entrypoints are permissionless (Q12) and
///         precondition-checked: deployed fraction ≤ 70% after any deposit.
/// @dev The haircut is prudence, not loss (Q16): a deposit lowers *measured*
///      RFV by 2% of the moved amount — conservative accounting, no value
///      leaves the treasury. With the 70% cap, the maximum understatement of
///      reserves is 1.4%. The invariant suite exempts the rebalance from NAV
///      monotonicity (bounded by the haircut); supply ≤ RFV is unconditional.
contract Treasury is ITreasury, Wired {
    error NotMinter();
    error NotSpender();
    error MorphoCapExceeded();
    error TransferFailed();

    INET private immutable _net;
    IERC20 private immutable _usdg;
    IERC4626 private immutable _vault;
    IUniswapV2Pair private immutable _pair;
    bool private immutable _netIsToken0;
    /// @dev 10^(18 − usdgDecimals): raw USDG → WAD.
    uint256 private immutable _usdgWadFactor;

    mapping(address => bool) public isMinter;
    mapping(address => bool) public isSpender;

    constructor(address net_, address usdg_, address morphoVault_, address pair_) {
        _net = INET(_nonZero(net_));
        _usdg = IERC20(_nonZero(usdg_));
        _vault = IERC4626(_nonZero(morphoVault_));
        _pair = IUniswapV2Pair(_nonZero(pair_));
        _netIsToken0 = IUniswapV2Pair(pair_).token0() == net_;
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @notice One-time wiring of the fixed minter/spender sets:
    ///         minters = Distributor, GenesisBond, BondDepository,
    ///         PremiumSeller, pTEAM; spenders = InverseBond.
    function wire(address[] calldata minters, address[] calldata spenders) external wiring {
        for (uint256 i = 0; i < minters.length; i++) {
            isMinter[_nonZero(minters[i])] = true;
        }
        for (uint256 i = 0; i < spenders.length; i++) {
            isSpender[_nonZero(spenders[i])] = true;
        }
    }

    // ── Addresses ──

    function usdg() external view returns (address) {
        return address(_usdg);
    }

    function net() external view returns (address) {
        return address(_net);
    }

    function morphoVault() external view returns (address) {
        return address(_vault);
    }

    function canonicalPair() external view returns (address) {
        return address(_pair);
    }

    // ── Valuation (all WAD USDG terms) ──

    function liquidUsdg() public view returns (uint256) {
        return _usdg.balanceOf(address(this)) * _usdgWadFactor;
    }

    function morphoAssets() public view returns (uint256) {
        return _vault.convertToAssets(_vault.balanceOf(address(this))) * _usdgWadFactor;
    }

    /// @notice POL RFV: LP share of 2·√(xWad·yWad), NET leg at 1 USDG
    ///         intrinsic (Q14). k-invariant under swaps, grows with fees.
    function polRfv() public view returns (uint256) {
        uint256 lp = _pair.balanceOf(address(this));
        if (lp == 0) return 0;
        (uint112 r0, uint112 r1,) = _pair.getReserves();
        (uint112 netR, uint112 quoteR) = _netIsToken0 ? (r0, r1) : (r1, r0);
        uint256 xWad = uint256(quoteR) * _usdgWadFactor;
        uint256 yWad = uint256(netR) * Constants.NET_UNIT;
        uint256 rfvAll = 2 * FixedPointMath.sqrt(xWad * yWad);
        return FixedPointMath.mulDiv(rfvAll, lp, _pair.totalSupply());
    }

    /// @inheritdoc ITreasury
    function rfv() public view returns (uint256) {
        uint256 morphoWad = morphoAssets();
        uint256 morphoAfterHaircut =
            morphoWad * (Constants.BPS - Constants.MORPHO_HAIRCUT_BPS) / Constants.BPS;
        return liquidUsdg() + morphoAfterHaircut + polRfv();
    }

    /// @inheritdoc ITreasury
    function backingPerToken() external view returns (uint256) {
        uint256 supply = _net.totalSupply();
        if (supply == 0) return 0;
        return FixedPointMath.mulDiv(rfv(), Constants.NET_UNIT, supply);
    }

    function morphoCapBps() external pure returns (uint256) {
        return Constants.MORPHO_CAP_BPS;
    }

    // ── Mint / spend (fixed authorized sets) ──

    /// @inheritdoc ITreasury
    function mintNet(address to, uint256 amount) external {
        _checkWired();
        if (!isMinter[msg.sender]) revert NotMinter();
        _net.mint(to, amount);
        emit NetMinted(msg.sender, to, amount);
    }

    /// @inheritdoc ITreasury
    function spendUsdg(address to, uint256 amountRaw) external {
        _checkWired();
        if (!isSpender[msg.sender]) revert NotSpender();
        uint256 liquid = _usdg.balanceOf(address(this));
        if (liquid < amountRaw) {
            // Unwind Morpho so buyback obligations can always be met
            // (specs/treasury.md §2).
            _vault.withdraw(amountRaw - liquid, address(this), address(this));
            emit MorphoWithdrawn(amountRaw - liquid);
        }
        if (!_usdg.transfer(to, amountRaw)) revert TransferFailed();
        emit UsdgSpent(msg.sender, to, amountRaw);
    }

    // ── Morpho rebalance (permissionless, precondition-checked — Q12) ──

    /// @inheritdoc ITreasury
    function rebalanceToMorpho(uint256 assetsRaw) external {
        uint256 liquidRaw = _usdg.balanceOf(address(this));
        uint256 morphoRaw = _vault.convertToAssets(_vault.balanceOf(address(this)));
        uint256 totalRaw = liquidRaw + morphoRaw;
        if ((morphoRaw + assetsRaw) * Constants.BPS > totalRaw * Constants.MORPHO_CAP_BPS) {
            revert MorphoCapExceeded();
        }
        if (!_usdg.approve(address(_vault), assetsRaw)) revert TransferFailed();
        _vault.deposit(assetsRaw, address(this));
        emit MorphoDeposited(assetsRaw);
    }

    /// @inheritdoc ITreasury
    /// @dev Formulaic (mechanism §8): permissionless withdrawal may only trim
    ///      the deployed fraction back DOWN TO the 70% cap (yield accrual
    ///      pushes it above). Obligations are served by `spendUsdg`'s
    ///      auto-unwind instead — so an attacker cannot flush Morpho to
    ///      liquid, which would both grief yield and inflate InverseBond's
    ///      liquid-keyed epoch capacity.
    function rebalanceFromMorpho(uint256 assetsRaw) external {
        uint256 liquidRaw = _usdg.balanceOf(address(this));
        uint256 morphoRaw = _vault.convertToAssets(_vault.balanceOf(address(this)));
        if (assetsRaw > morphoRaw) revert MorphoCapExceeded();
        uint256 totalRaw = liquidRaw + morphoRaw;
        if ((morphoRaw - assetsRaw) * Constants.BPS < totalRaw * Constants.MORPHO_CAP_BPS) {
            revert MorphoCapExceeded();
        }
        _vault.withdraw(assetsRaw, address(this), address(this));
        emit MorphoWithdrawn(assetsRaw);
    }
}
