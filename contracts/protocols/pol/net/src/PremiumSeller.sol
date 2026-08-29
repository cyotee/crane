// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IPremiumSeller} from "@crane/contracts/protocols/pol/net/src/interfaces/IPremiumSeller.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IGenesisBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IGenesisBond.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";

/// @title PremiumSeller — the standing ask above the premium threshold
/// @notice Params FINAL 2026-07-12 (specs/treasury.md §4): when TWAP >
///         backing × 2.0 (above K = 1.75 — the treasury only sells after
///         emissions are already maxed, into genuine euphoria), anyone may
///         `execute()`: mint PREMIUM_CLIP_BPS (25 bps) of pool NET reserves,
///         sell into the canonical pool with TWAP-bounded slippage
///         (PREMIUM_MAX_DEV_BPS — D3), sweep USDG to the Treasury. Minimum
///         PREMIUM_MIN_INTERVAL (1 h) between executions. Purely formulaic;
///         no parameter-change path. Fails closed on an out-of-band oracle.
contract PremiumSeller is IPremiumSeller {
    error NotActive();
    error IntervalNotElapsed();
    error SlippageExceeded();
    error TransferFailed();
    error ZeroAddress();

    INET public immutable net;
    IERC20 public immutable usdg;
    IUniswapV2Router02 public immutable router;
    IUniswapV2Pair public immutable pairContract;
    ITreasury public immutable treasury;
    IPairOracle public immutable oracle;
    IGenesisBond public immutable genesisBond;
    bool private immutable _netIsToken0;
    uint256 private immutable _usdgWadFactor;

    /// @inheritdoc IPremiumSeller
    uint64 public lastExecuteAt;

    constructor(
        address net_,
        address usdg_,
        address router_,
        address pair_,
        address treasury_,
        address oracle_,
        address genesisBond_
    ) {
        if (
            net_ == address(0) || usdg_ == address(0) || router_ == address(0)
                || pair_ == address(0) || treasury_ == address(0) || oracle_ == address(0)
                || genesisBond_ == address(0)
        ) revert ZeroAddress();
        net = INET(net_);
        usdg = IERC20(usdg_);
        router = IUniswapV2Router02(router_);
        pairContract = IUniswapV2Pair(pair_);
        treasury = ITreasury(treasury_);
        oracle = IPairOracle(oracle_);
        genesisBond = IGenesisBond(genesisBond_);
        _netIsToken0 = IUniswapV2Pair(pair_).token0() == net_;
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @inheritdoc IPremiumSeller
    function execute(uint256 minUsdgOutRaw) external returns (uint256 netSold, uint256 usdgOutRaw) {
        uint256 twap = _requireAboveThreshold(); // fail-closed oracle gate
        if (block.timestamp - lastExecuteAt < Constants.PREMIUM_MIN_INTERVAL) {
            revert IntervalNotElapsed();
        }
        lastExecuteAt = uint64(block.timestamp);

        netSold = clipSize();
        if (netSold == 0) revert NotActive();

        // Transient mint: backed by the swap proceeds within this same tx.
        treasury.mintNet(address(this), netSold);

        uint256 expectedWad = FixedPointMath.mulDiv(netSold, twap, Constants.NET_UNIT);
        uint256 minAllowedRaw = expectedWad * (Constants.BPS - Constants.PREMIUM_MAX_DEV_BPS)
            / Constants.BPS / _usdgWadFactor;
        uint256 minOut = minUsdgOutRaw > minAllowedRaw ? minUsdgOutRaw : minAllowedRaw;

        uint256 before = usdg.balanceOf(address(this));
        net.approve(address(router), netSold);
        address[] memory path = new address[](2);
        path[0] = address(net);
        path[1] = address(usdg);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            netSold, minOut, path, address(this), block.timestamp
        );
        usdgOutRaw = usdg.balanceOf(address(this)) - before;
        if (usdgOutRaw < minOut) revert SlippageExceeded();
        if (!usdg.transfer(address(treasury), usdgOutRaw)) revert TransferFailed();
        emit PremiumSold(netSold, usdgOutRaw);
    }

    /// @inheritdoc IPremiumSeller
    function active() external view returns (bool) {
        if (genesisBond.finalizeTime() == 0) return false;
        if (block.timestamp - lastExecuteAt < Constants.PREMIUM_MIN_INTERVAL) return false;
        try PremiumSeller(address(this)).twapIfAbove() returns (uint256) {
            return clipSize() > 0;
        } catch {
            return false;
        }
    }

    /// @notice External self-call helper for `active()`'s try/catch.
    function twapIfAbove() external view returns (uint256) {
        return _requireAboveThreshold();
    }

    /// @inheritdoc IPremiumSeller
    function clipSize() public view returns (uint256) {
        (uint112 r0, uint112 r1,) = pairContract.getReserves();
        uint112 netReserve = _netIsToken0 ? r0 : r1;
        return uint256(netReserve) * Constants.PREMIUM_CLIP_BPS / Constants.BPS;
    }

    function premiumThresholdWad() external pure returns (uint256) {
        return Constants.PREMIUM_THRESHOLD_WAD;
    }

    function _requireAboveThreshold() internal view returns (uint256 twap) {
        if (genesisBond.finalizeTime() == 0) revert NotActive();
        twap = oracle.twapNetUsdg();
        uint256 threshold = FixedPointMath.mulDiv(
            treasury.backingPerToken(), Constants.PREMIUM_THRESHOLD_WAD, Constants.WAD
        );
        if (twap <= threshold) revert NotActive();
    }
}
