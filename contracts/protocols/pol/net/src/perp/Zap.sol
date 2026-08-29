// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {WrappedStakedNET} from "@crane/contracts/protocols/pol/net/src/perp/WrappedStakedNET.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";

/// @title Zap — NET → sNET → wsNET in one transaction (specs/perp.md §2)
/// @notice Makes the three-step margin flow invisible: a trader hands NET,
///         receives wsNET — and becomes a dividend-program staker along the
///         way. Stateless pass-through: holds no balances between calls, has
///         no owner.
/// @dev    Requires zero staking warmup (Staking.warmupEpochs() == 0, the
///         deployed configuration); asserted in the constructor so a future
///         warmup change fails loudly at deploy, not silently at runtime.
contract Zap {
    error TransferFailed();
    error WarmupNotZero();
    error ZeroAmount();

    event Zapped(address indexed account, uint256 netIn, uint256 wsOut);

    IERC20 public immutable net;
    IERC20 public immutable sNet;
    IStaking public immutable staking;
    WrappedStakedNET public immutable wsNet;

    constructor(address net_, address sNet_, address staking_, address wsNet_) {
        if (IStaking(staking_).warmupEpochs() != 0) revert WarmupNotZero();
        net = IERC20(net_);
        sNet = IERC20(sNet_);
        staking = IStaking(staking_);
        wsNet = WrappedStakedNET(wsNet_);
        // One-time unlimited approvals to the fixed, trusted protocol
        // contracts this zap composes.
        IERC20(net_).approve(staking_, type(uint256).max);
        IERC20(sNet_).approve(wsNet_, type(uint256).max);
    }

    /// @notice NET in, wsNET out, one transaction.
    function zap(uint256 netAmount) external returns (uint256 wsOut) {
        if (netAmount == 0) revert ZeroAmount();
        if (!net.transferFrom(msg.sender, address(this), netAmount)) revert TransferFailed();
        staking.stake(address(this), netAmount);
        wsOut = wsNet.wrap(sNet.balanceOf(address(this)));
        if (!IERC20(address(wsNet)).transfer(msg.sender, wsOut)) revert TransferFailed();
        emit Zapped(msg.sender, netAmount, wsOut);
    }
}
