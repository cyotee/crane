// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    CamelotV2Utils
} from "../libs/CamelotV2Utils.sol";

import {
    CamelotV2Service
} from "../libs/CamelotV2Service.sol";

import {
    ICamelotPair
} from "../interfaces/ICamelotPair.sol";

import {
    ICamelotFactory
} from "../interfaces/ICamelotFactory.sol";

import {
    ICamelotV2Router
} from "../interfaces/ICamelotV2Router.sol";

import {
    IERC20
} from "../../../../../tokens/erc20/interfaces/IERC20.sol";

import {
    SafeERC20
} from "../../../../../tokens/erc20/libs/SafeERC20.sol";

interface ICamV2SwapRelayer {

    function swapDepositTo(
        ICamelotV2Router router,
        ICamelotPair pair,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        address recipient,
        bool pretransferred
    ) external returns(uint256 lpAmount);

    function swapDeposit(
        ICamelotV2Router router,
        ICamelotPair pair,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        bool pretransferred
    ) external returns(uint256 lpAmount);

}

contract CamV2SwapRelayer
is
ICamV2SwapRelayer
{

    using CamelotV2Service for ICamelotPair;
    using CamelotV2Service for ICamelotFactory;
    using CamelotV2Service for ICamelotV2Router;
    using SafeERC20 for IERC20;

    address referrer;

    constructor(
        address referrer_
    ) {
        referrer = referrer_;
    }

    function swapDepositTo(
        ICamelotV2Router router,
        ICamelotPair pair,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        address recipient,
        bool pretransferred
    ) public returns(uint256 lpAmount) {
        if(!pretransferred) {
            tokenIn._safeTransferFrom(msg.sender, address(this), saleAmt);
        }
        lpAmount = router
        ._swapDeposit(
            // ICamelotV2Router router,
            // ICamelotPair pair,
            pair,
            // IERC20 tokenIn,
            tokenIn,
            // uint256 saleAmt,
            saleAmt,
            // IERC20 opToken,
            opToken,
            // address referrer
            referrer
        );
        // pair._safeTransfer(recipient, pair,balanceOf(address(this)));
        IERC20(address(pair))._safeTransfer(recipient, lpAmount);
    }

    function swapDeposit(
        ICamelotV2Router router,
        ICamelotPair pair,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        bool pretransferred
    ) public returns(uint256 lpAmount) {
        return swapDepositTo(
            router,
            pair,
            tokenIn,
            saleAmt,
            opToken,
            msg.sender,
            pretransferred
        );
    }

}