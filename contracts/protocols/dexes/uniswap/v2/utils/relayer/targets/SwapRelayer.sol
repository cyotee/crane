// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20, SafeERC20} from "../../../../../../../tokens/erc20/libs/SafeERC20.sol";
import {IUniswapV2Pair, BetterUniV2Service} from "../../../libs/BetterUniV2Service.sol";
import {ISwapRelayer} from "../interfaces/ISwapRelayer.sol";

/**
 * @dev Provides a distinct address from a contained token for LPs.
 */
contract SwapRelayer is ISwapRelayer {

    using BetterUniV2Service for IUniswapV2Pair;
    using SafeERC20 for IERC20;

    function swapDepositTo(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_,
        address recipient
    ) public returns(uint256 lpAmount) {
        lpAmount = pair._swapDepositDirectTo(
            saleToken,
            saleTokenAmount,
            saleTokenReserve,
            opposingToken_,
            recipient
        );
    }

    function swapDeposit(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_
    ) public returns(uint256 lpAmount) {
        lpAmount = swapDepositTo(
            pair,
            saleToken,
            saleTokenAmount,
            saleTokenReserve,
            opposingToken_,
            msg.sender
        );
    }

    function swapDepositToPull(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_,
        address recipient
    ) public returns(uint256 lpAmount) {
        IERC20(saleToken)._safeTransfer(msg.sender, saleTokenAmount);
        lpAmount = swapDepositTo(
            pair,
            saleToken,
            saleTokenAmount,
            saleTokenReserve,
            opposingToken_,
            recipient
        );
    }

    function swapDepositPull(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_
    ) public returns(uint256 lpAmount) {
        lpAmount = swapDepositToPull(
            pair,
            saleToken,
            saleTokenAmount,
            saleTokenReserve,
            opposingToken_,
            msg.sender
        );
    }

}