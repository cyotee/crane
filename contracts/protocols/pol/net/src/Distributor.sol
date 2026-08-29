// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IDistributor} from "@crane/contracts/protocols/pol/net/src/interfaces/IDistributor.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";

/// @title Distributor — algorithmic, no-governance emissions
/// @notice specs/mechanism.md §2. Every parameter is a compile-time constant;
///         every reference is immutable; there are NO owner functions on this
///         path — no function on this contract can mutate state except
///         `distribute()`, which only Staking may call.
/// @dev Cap behavior (D2): the mint CLAMPS to remaining RFV capacity so the
///      permissionless rebase can never be bricked; `totalSupply × 1 USDG ≤
///      Treasury.rfv()` holds after every mint. Staleness behavior (D1): a
///      stale TWAP mints 0 for the epoch rather than reverting — no NET is
///      ever minted without a live TWAP, and rebase liveness (which carries
///      the checkpoint that heals the oracle) is preserved.
contract Distributor is IDistributor {
    error NotStaking();

    ITreasury public immutable treasury;
    INET public immutable net;
    IsNET public immutable sNet;
    address public immutable staking;
    IPairOracle public immutable oracle;

    uint256 public epochsDistributed;

    constructor(address treasury_, address net_, address sNet_, address staking_, address oracle_) {
        treasury = ITreasury(treasury_);
        net = INET(net_);
        sNet = IsNET(sNet_);
        staking = staking_;
        oracle = IPairOracle(oracle_);
    }

    /// @inheritdoc IDistributor
    function distribute() external returns (uint256 minted) {
        if (msg.sender != staking) revert NotStaking();
        minted = nextReward();
        epochsDistributed += 1;
        if (minted == 0) {
            emit Distributed(epochsDistributed, 0, 0);
            return 0;
        }
        treasury.mintNet(staking, minted);
        emit Distributed(epochsDistributed, minted, _rateWad());
    }

    /// @inheritdoc IDistributor
    function nextReward() public view returns (uint256) {
        // No stakers → nothing to distribute (avoids stranding NET in Staking).
        if (sNet.balanceOf(staking) == sNet.totalSupply()) return 0;
        uint256 rate = _rateWad();
        if (rate == 0) return 0;
        uint256 supply = net.totalSupply();
        uint256 reward = FixedPointMath.mulDiv(supply, rate, Constants.WAD);
        // RFV hard cap: post-mint supply (WAD USDG terms at the 1 USDG floor)
        // must not exceed Treasury.rfv(). Clamp (D2).
        uint256 supplyWad = supply * Constants.NET_UNIT;
        uint256 rfvWad = treasury.rfv();
        if (rfvWad <= supplyWad) return 0;
        uint256 capacity = (rfvWad - supplyWad) / Constants.NET_UNIT;
        return reward < capacity ? reward : capacity;
    }

    /// @inheritdoc IDistributor
    function premium() public view returns (uint256) {
        uint256 twap = oracle.twapNetUsdg(); // reverts when stale (D1)
        uint256 backing = treasury.backingPerToken();
        if (backing == 0) return 0;
        return FixedPointMath.mulDiv(twap, Constants.WAD, backing);
    }

    /// @inheritdoc IDistributor
    function currentRateWad() external view returns (uint256) {
        return _rateWad();
    }

    /// @dev rate = R_MAX × clamp((P − 1) / (K − 1), 0, 1); 0 on stale TWAP.
    function _rateWad() internal view returns (uint256) {
        uint256 p;
        try Distributor(address(this)).premium() returns (uint256 p_) {
            p = p_;
        } catch {
            return 0; // stale oracle → mint nothing this epoch (D1)
        }
        if (p <= Constants.WAD) return 0;
        uint256 frac = FixedPointMath.mulDiv(
            p - Constants.WAD, Constants.WAD, Constants.K_WAD - Constants.WAD
        );
        if (frac > Constants.WAD) frac = Constants.WAD;
        return FixedPointMath.mulDiv(Constants.R_MAX_WAD, frac, Constants.WAD);
    }

    function rMaxWad() external pure returns (uint256) {
        return Constants.R_MAX_WAD;
    }

    function kWad() external pure returns (uint256) {
        return Constants.K_WAD;
    }
}
