// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {IGenesisBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IGenesisBond.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title PTeam (pTEAM) — team option position (specs/mechanism.md §5)
/// @notice Single-holder (team multisig — Q6) option: mint NET at a strike of
///         exactly 1 USDG per NET, paid into the Treasury. Strike = the
///         backing floor, so exercise never dilutes the floor — only the
///         premium. Rights vest linearly over 30 days from
///         GenesisBond.finalize(); cumulative exercise ≤ vestedFraction ×
///         15% × circulating at each exercise. All parameters immutable.
/// @dev Float exclusions (Q5): NET held by Treasury, InverseBond,
///      TaxCollector, GenesisBond, BondDepository. Staked NET and LP-pool
///      NET count as circulating.
contract PTeam is IPTEAM, Wired {
    error NotHolder();
    error ExceedsVestedCap();
    error TransferFailed();

    IERC20 public immutable net;
    IERC20 public immutable usdg;
    ITreasury public immutable treasury;
    address public immutable holder;
    uint256 private immutable _usdgWadFactor;

    IGenesisBond public genesisBond;
    address[] private _excludedFromFloat;

    uint256 public exercised;

    constructor(address net_, address usdg_, address treasury_, address holder_) {
        net = IERC20(_nonZero(net_));
        usdg = IERC20(_nonZero(usdg_));
        treasury = ITreasury(_nonZero(treasury_));
        holder = _nonZero(holder_);
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @notice One-time wiring: the vest clock source and the Q5 exclusion
    ///         list, fixed forever.
    function wire(address genesisBond_, address[] calldata excludedFromFloat_) external wiring {
        genesisBond = IGenesisBond(_nonZero(genesisBond_));
        for (uint256 i = 0; i < excludedFromFloat_.length; i++) {
            _excludedFromFloat.push(_nonZero(excludedFromFloat_[i]));
        }
    }

    /// @inheritdoc IPTEAM
    function exercise(uint256 netAmount) external {
        _checkWired();
        if (msg.sender != holder) revert NotHolder();
        if (netAmount > exercisableNow()) revert ExceedsVestedCap();
        exercised += netAmount;
        // Strike: 1 USDG per NET, rounded up so the treasury is never
        // underpaid; paid straight into reserves (adds 1 USDG of backing per
        // NET minted — invariant §6.4).
        uint256 paidWad =
            FixedPointMath.mulDiv(netAmount, Constants.PTEAM_STRIKE_WAD, Constants.NET_UNIT);
        uint256 paidRaw = FixedPointMath.mulDivUp(paidWad, 1, _usdgWadFactor);
        if (!usdg.transferFrom(msg.sender, address(treasury), paidRaw)) revert TransferFailed();
        treasury.mintNet(holder, netAmount);
        emit Exercised(holder, netAmount, paidWad);
    }

    /// @inheritdoc IPTEAM
    function vestedFraction() public view returns (uint256) {
        if (!wired) return 0;
        uint64 finalizeTime = genesisBond.finalizeTime();
        if (finalizeTime == 0) return 0;
        uint256 elapsed = block.timestamp - finalizeTime;
        if (elapsed >= Constants.VEST_DURATION) return Constants.WAD;
        return elapsed * Constants.WAD / Constants.VEST_DURATION;
    }

    /// @inheritdoc IPTEAM
    function exercisableNow() public view returns (uint256) {
        uint256 maxCumulative = FixedPointMath.mulDiv(
            vestedFraction() * Constants.PTEAM_CAP_BPS,
            circulatingSupply(),
            Constants.WAD * Constants.BPS
        );
        return maxCumulative > exercised ? maxCumulative - exercised : 0;
    }

    /// @inheritdoc IPTEAM
    function circulatingSupply() public view returns (uint256) {
        uint256 supply = net.totalSupply();
        uint256 excluded = 0;
        for (uint256 i = 0; i < _excludedFromFloat.length; i++) {
            excluded += net.balanceOf(_excludedFromFloat[i]);
        }
        return supply > excluded ? supply - excluded : 0;
    }

    function excludedFromFloat() external view returns (address[] memory) {
        return _excludedFromFloat;
    }

    function strikeWad() external pure returns (uint256) {
        return Constants.PTEAM_STRIKE_WAD;
    }

    function capBps() external pure returns (uint256) {
        return Constants.PTEAM_CAP_BPS;
    }
}
