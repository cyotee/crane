// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20, IUniswapV2Pair} from "../../../interfaces/IUniswapV2Pair.sol";

interface ISwapRelayer {

    function swapDepositTo(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_,
        address recipient
    ) external returns(uint256 lpAmount);

    function swapDeposit(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_
    ) external returns(uint256 lpAmount);

    function swapDepositToPull(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_,
        address recipient
    ) external returns(uint256 lpAmount);

    function swapDepositPull(
        IUniswapV2Pair pair,
        IERC20 saleToken,
        uint256 saleTokenAmount,
        uint256 saleTokenReserve,
        IERC20 opposingToken_
    ) external returns(uint256 lpAmount);

}