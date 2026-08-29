// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IInverseBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IInverseBond.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IGenesisBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IGenesisBond.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";

/// @title InverseBond — the standing bid below backing ("buyback program")
/// @notice Form FINAL 2026-07-12 (specs/treasury.md §4): direct bonds at
///         `payoutPerNET = backingPerToken × (1 − INVERSE_SPREAD_BPS)`.
///         Seller-initiated and fully permissionless — no trigger, no keeper:
///         hitting the bid is only rational when market trades below
///         backing × (1 − spread), so it functions as the standing floor bid.
///         All NET received is burned; every fill is strictly accretive.
///         Capacity: INVERSE_EPOCH_CAP_BPS of liquid (non-Morpho) reserves
///         per epoch, fresh each epoch, no rollover. The TWAP oracle is used
///         as a fail-closed liveness gate (mechanism §2): out-of-band oracle
///         → no settlement. Backing itself is k-based (2·√(x·y)), so the
///         settlement inputs are not spot-manipulable.
contract InverseBond is IInverseBond {
    error NotActive();
    error ZeroAmount();
    error ExceedsCapacity();
    error SlippageExceeded();
    error TransferFailed();
    error ZeroAddress();

    INET public immutable net;
    IERC20Metadata public immutable usdg;
    ITreasury public immutable treasury;
    IPairOracle public immutable oracle;
    IGenesisBond public immutable genesisBond;
    uint256 private immutable _usdgWadFactor;

    /// @notice USDG (WAD) filled per epoch index.
    mapping(uint256 => uint256) public filledInEpoch;
    /// @notice Epoch capacity (USDG WAD), snapshotted at the epoch's first
    ///         fill so mid-epoch liquid inflows cannot inflate the budget
    ///         (treasury §4: "recomputed fresh each epoch"). 0 = not yet
    ///         snapshotted (views fall back to the live reading).
    mapping(uint256 => uint256) public capOfEpoch;

    constructor(
        address net_,
        address usdg_,
        address treasury_,
        address oracle_,
        address genesisBond_
    ) {
        if (
            net_ == address(0) || usdg_ == address(0) || treasury_ == address(0)
                || oracle_ == address(0) || genesisBond_ == address(0)
        ) revert ZeroAddress();
        net = INET(net_);
        usdg = IERC20Metadata(usdg_);
        treasury = ITreasury(treasury_);
        oracle = IPairOracle(oracle_);
        genesisBond = IGenesisBond(genesisBond_);
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @inheritdoc IInverseBond
    function swap(uint256 netAmount, uint256 minUsdgOutRaw) external returns (uint256 usdgOutRaw) {
        if (netAmount == 0) revert ZeroAmount();
        if (genesisBond.finalizeTime() == 0) revert NotActive();
        // Fail-closed oracle gate (mechanism §2): out-of-band → refuse to
        // settle. The value is not used in pricing.
        oracle.twapNetUsdg();

        uint256 payoutWad = FixedPointMath.mulDiv(netAmount, price(), Constants.NET_UNIT);
        uint256 epochIdx = _epochIndex();
        if (capOfEpoch[epochIdx] == 0) capOfEpoch[epochIdx] = _liveCap();
        uint256 remaining = _capacityRemaining(epochIdx);
        if (payoutWad > remaining) revert ExceedsCapacity();
        filledInEpoch[epochIdx] += payoutWad;

        usdgOutRaw = payoutWad / _usdgWadFactor;
        if (usdgOutRaw < minUsdgOutRaw) revert SlippageExceeded();

        // Pull and burn — buyback settles immediately, escrow is transient.
        if (!net.transferFrom(msg.sender, address(this), netAmount)) revert TransferFailed();
        net.burn(netAmount);
        treasury.spendUsdg(msg.sender, usdgOutRaw);
        emit InverseBonded(msg.sender, netAmount, payoutWad);
    }

    /// @inheritdoc IInverseBond
    function active() external view returns (bool) {
        if (genesisBond.finalizeTime() == 0) return false;
        try InverseBond(address(this)).oracleGate() {}
        catch {
            return false;
        }
        return _capacityRemaining(_epochIndex()) > 0;
    }

    /// @notice External self-call helper for `active()`'s try/catch.
    function oracleGate() external view returns (uint256) {
        return oracle.twapNetUsdg();
    }

    /// @inheritdoc IInverseBond
    function price() public view returns (uint256) {
        return
            treasury.backingPerToken() * (Constants.BPS - Constants.INVERSE_SPREAD_BPS)
                / Constants.BPS;
    }

    /// @inheritdoc IInverseBond
    function capacityRemaining() external view returns (uint256) {
        if (genesisBond.finalizeTime() == 0) return 0;
        return _capacityRemaining(_epochIndex());
    }

    function spreadBps() external pure returns (uint256) {
        return Constants.INVERSE_SPREAD_BPS;
    }

    function _epochIndex() internal view returns (uint256) {
        return (block.timestamp - genesisBond.finalizeTime()) / Constants.EPOCH_LENGTH;
    }

    function _liveCap() internal view returns (uint256) {
        return treasury.liquidUsdg() * Constants.INVERSE_EPOCH_CAP_BPS / Constants.BPS;
    }

    /// @dev Capacity is fixed per epoch: snapshotted from liquid reserves at
    ///      the epoch's first fill (live reading until then); unused capacity
    ///      does not roll over (treasury §4).
    function _capacityRemaining(uint256 epochIdx) internal view returns (uint256) {
        uint256 cap = capOfEpoch[epochIdx];
        if (cap == 0) cap = _liveCap();
        uint256 filled = filledInEpoch[epochIdx];
        return cap > filled ? cap - filled : 0;
    }
}
