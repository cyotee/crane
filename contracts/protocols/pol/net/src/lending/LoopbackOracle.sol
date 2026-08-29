// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {LendingConstants} from "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";

/// @title LoopbackOracle — floor-bounded, euphoria-governed wsNET/USDG price
/// @notice Morpho Blue oracle for the Loopback market (specs/lending.md §3):
///
///             price(wsNET) = clamp(TWAP × (1−h), floor, C × floor) × index
///
///         quoted as USDG loan units per wsNET collateral unit, scaled 1e36
///         per Morpho convention (effective exponent 24 for 18-dec wsNET /
///         6-dec USDG). Market pricing whenever premium ≤ ~5.6×; credit pins
///         to `C × floor` in euphoria — the facility never lends against the
///         kind of premium that can cascade.
///
///         Fail-closed (reverts, pausing borrows AND margin calls) when:
///         - the PairOracle TWAP window is invalid (mechanism.md §2), or
///         - the pair's instantaneous price sits > DIVERGENCE_BPS below TWAP
///           (the stale-high-mark borrow guard — a dump cannot borrow against
///           yesterday's credit; the guard only ever pauses, it never raises
///           credit, so it cannot be exploited upward).
///
///         Immutable, permissionless, no owner; read-only views into live
///         protocol contracts only. Retuning = successor market (§1.3).
contract LoopbackOracle {
    error Diverged();

    IPairOracle public immutable pairOracle;
    ITreasury public immutable treasury;
    IsNET public immutable sNet;
    IUniswapV2Pair public immutable pair;
    /// @dev Cached token ordering of the canonical pair: true when NET is
    ///      token0 (USDG then token1).
    bool public immutable netIsToken0;

    constructor(address pairOracle_, address treasury_, address sNet_, address net_) {
        pairOracle = IPairOracle(pairOracle_);
        treasury = ITreasury(treasury_);
        sNet = IsNET(sNet_);
        IUniswapV2Pair p = IUniswapV2Pair(IPairOracle(pairOracle_).pair());
        pair = p;
        netIsToken0 = p.token0() == net_;
    }

    /// @notice Morpho oracle entrypoint: USDG per wsNET, 1e36-scaled.
    function price() external view returns (uint256) {
        // Fails closed if the TWAP window is invalid (30 min – 4 h band).
        uint256 twapWad = pairOracle.twapNetUsdg();

        // Divergence guard: instantaneous pair price vs TWAP.
        uint256 spotWad = _pairPriceWad();
        if (
            spotWad
                < twapWad * (LendingConstants.BPS - LendingConstants.DIVERGENCE_BPS)
                    / LendingConstants.BPS
        ) {
            revert Diverged();
        }

        uint256 credited =
            twapWad * (LendingConstants.BPS - LendingConstants.HAIRCUT_BPS) / LendingConstants.BPS;
        uint256 floorWad = treasury.backingPerToken();
        uint256 cap = floorWad * LendingConstants.PREMIUM_CAP;
        if (credited > cap) credited = cap;
        if (credited < floorWad) credited = floorWad;

        // NET/USD (WAD) → wsNET/USD (WAD) via the 9-dec dividend index, then
        // WAD → the 1e24-effective Morpho scale.
        return credited * sNet.index() / Constants.NET_UNIT * LendingConstants.WAD_TO_MORPHO_PRICE;
    }

    /// @notice Instantaneous canonical-pair price, WAD USDG per whole NET.
    ///         Used ONLY to reduce/refuse credit (the divergence guard) —
    ///         never to price collateral.
    function _pairPriceWad() internal view returns (uint256) {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 rNet, uint256 rUsdg) =
            netIsToken0 ? (uint256(r0), uint256(r1)) : (uint256(r1), uint256(r0));
        // (rUsdg / 1e6) / (rNet / 1e9) × 1e18  ==  rUsdg × 1e21 / rNet
        return rUsdg * 1e21 / rNet;
    }
}
