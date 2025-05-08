// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {BetterIERC20 as IERC20, BetterSafeERC20 as SafeERC20} from "../../../../../../token/ERC20/utils/BetterSafeERC20.sol";
import {IUniswapV2Pair, BetterUniV2Service} from "../BetterUniV2Service.sol";
import {ISwapRelayer} from "./ISwapRelayer.sol";

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
        IERC20(saleToken).safeTransfer(msg.sender, saleTokenAmount);
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