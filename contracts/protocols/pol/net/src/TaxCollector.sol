// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {ITaxCollector} from "@crane/contracts/protocols/pol/net/src/interfaces/ITaxCollector.sol";
import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title TaxCollector — trading-tax accrual and conversion (specs/tax.md §4)
/// @notice NET tax accrues here during swaps (collect-then-convert; this
///         contract never re-enters the pool inside a taxed transfer).
///         `convert()` is permissionless (Q12): batch-swaps NET → USDG on the
///         canonical pool, clip-limited to TAX_SWAP_MAX_CLIP_BPS of pool NET
///         reserves and TWAP-bounded by TAX_SWAP_MAX_DEV_BPS, then splits
///         proceeds by the deterministic decay (mechanism §4):
///         teamBps = 400 × (1 − v), treasuryBps = 500 − teamBps, where v is
///         pTEAM's vestedFraction — one clock, no admin setter.
contract TaxCollector is ITaxCollector, Wired {
    error ZeroAmount();
    error ClipTooLarge();
    error SlippageExceeded();
    error TransferFailed();

    IERC20 public immutable net;
    IERC20 public immutable usdg;
    IUniswapV2Router02 public immutable router;
    IUniswapV2Pair public immutable pairContract;
    IPairOracle public immutable oracle;
    address public immutable treasury;
    address public immutable teamWallet;
    bool private immutable _netIsToken0;
    uint256 private immutable _usdgWadFactor;

    IPTEAM public pTeam;

    constructor(
        address net_,
        address usdg_,
        address router_,
        address pair_,
        address oracle_,
        address treasury_,
        address teamWallet_
    ) {
        net = IERC20(_nonZero(net_));
        usdg = IERC20(_nonZero(usdg_));
        router = IUniswapV2Router02(_nonZero(router_));
        pairContract = IUniswapV2Pair(_nonZero(pair_));
        oracle = IPairOracle(_nonZero(oracle_));
        treasury = _nonZero(treasury_);
        teamWallet = _nonZero(teamWallet_);
        _netIsToken0 = IUniswapV2Pair(pair_).token0() == net_;
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @notice One-time wiring (pTEAM ↔ TaxCollector deploy cycle).
    function wire(address pTeam_) external wiring {
        pTeam = IPTEAM(_nonZero(pTeam_));
    }

    /// @inheritdoc ITaxCollector
    function convert(uint256 netAmount, uint256 minUsdgOutRaw) external {
        _checkWired();
        if (netAmount == 0) revert ZeroAmount();

        // Clip bound: keep swaps small relative to pool depth.
        (uint112 r0, uint112 r1,) = pairContract.getReserves();
        uint112 netReserve = _netIsToken0 ? r0 : r1;
        if (netAmount * Constants.BPS > uint256(netReserve) * Constants.TAX_SWAP_MAX_CLIP_BPS) {
            revert ClipTooLarge();
        }

        // TWAP bound: reverts on stale oracle (D1) — no conversion without a
        // live TWAP.
        uint256 twap = oracle.twapNetUsdg();
        uint256 expectedWad = FixedPointMath.mulDiv(netAmount, twap, Constants.NET_UNIT);
        uint256 minAllowedRaw = expectedWad * (Constants.BPS - Constants.TAX_SWAP_MAX_DEV_BPS)
            / Constants.BPS / _usdgWadFactor;
        uint256 minOut = minUsdgOutRaw > minAllowedRaw ? minUsdgOutRaw : minAllowedRaw;

        uint256 usdgBefore = usdg.balanceOf(address(this));
        if (!net.approve(address(router), netAmount)) revert TransferFailed();
        address[] memory path = new address[](2);
        path[0] = address(net);
        path[1] = address(usdg);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            netAmount, minOut, path, address(this), block.timestamp
        );
        uint256 usdgOut = usdg.balanceOf(address(this)) - usdgBefore;
        if (usdgOut < minOut) revert SlippageExceeded();

        uint256 teamShare = usdgOut * teamBps() / Constants.TAX_TOTAL_BPS;
        uint256 treasuryShare = usdgOut - teamShare;
        if (teamShare != 0 && !usdg.transfer(teamWallet, teamShare)) revert TransferFailed();
        if (!usdg.transfer(treasury, treasuryShare)) revert TransferFailed();
        emit Converted(netAmount, usdgOut, teamShare, treasuryShare);
    }

    /// @inheritdoc ITaxCollector
    function teamBps() public view returns (uint256) {
        uint256 v = pTeam.vestedFraction(); // WAD, clamps at 1e18 forever
        return Constants.TAX_TEAM_START_BPS * (Constants.WAD - v) / Constants.WAD;
    }

    /// @inheritdoc ITaxCollector
    function treasuryBps() external view returns (uint256) {
        return Constants.TAX_TOTAL_BPS - teamBps();
    }

    /// @inheritdoc ITaxCollector
    function pendingNet() external view returns (uint256) {
        return net.balanceOf(address(this));
    }
}
