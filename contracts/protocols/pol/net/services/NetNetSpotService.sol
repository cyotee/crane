// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {ITaxCollector} from "@crane/contracts/protocols/pol/net/src/interfaces/ITaxCollector.sol";

// tag::NetNetSpotService[]
/**
 * @title NetNetSpotService - FoT buy/sell on the canonical NET/USDG pair and tax convert.
 * @author Crane
 * @dev Caller context is the token holder. Uses `swapExactTokensForTokensSupportingFeeOnTransferTokens`.
 */
library NetNetSpotService {
    // tag::BuyParams[]
    struct BuyParams {
        IUniswapV2Router02 router;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address to;
        uint256 deadline;
    }
    // end::BuyParams[]

    // tag::SellParams[]
    struct SellParams {
        IUniswapV2Router02 router;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address to;
        uint256 deadline;
    }
    // end::SellParams[]

    // tag::ConvertParams[]
    struct ConvertParams {
        ITaxCollector taxCollector;
        uint256 netAmount;
        uint256 minUsdgOutRaw;
    }
    // end::ConvertParams[]

    // tag::_buyNetWithUsdg(BuyParams)[]
    /**
     * @notice Buy NET with USDG on the canonical v2 pair (FoT path).
     * @custom:signature _buyNetWithUsdg((address,address,address,uint256,uint256,address,uint256))
     */
    function _buyNetWithUsdg(BuyParams memory p) internal {
        p.tokenIn.approve(address(p.router), p.amountIn);
        address[] memory path = new address[](2);
        path[0] = address(p.tokenIn);
        path[1] = address(p.tokenOut);
        p.router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            p.amountIn, p.amountOutMin, path, p.to, p.deadline
        );
    }
    // end::_buyNetWithUsdg(BuyParams)[]

    // tag::_sellNetForUsdg(SellParams)[]
    /**
     * @notice Sell NET for USDG on the canonical v2 pair (FoT path).
     * @custom:signature _sellNetForUsdg((address,address,address,uint256,uint256,address,uint256))
     */
    function _sellNetForUsdg(SellParams memory p) internal {
        p.tokenIn.approve(address(p.router), p.amountIn);
        address[] memory path = new address[](2);
        path[0] = address(p.tokenIn);
        path[1] = address(p.tokenOut);
        p.router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            p.amountIn, p.amountOutMin, path, p.to, p.deadline
        );
    }
    // end::_sellNetForUsdg(SellParams)[]

    // tag::_convert(ConvertParams)[]
    /**
     * @notice Convert accrued tax NET via `ITaxCollector.convert`.
     * @custom:signature _convert((address,uint256,uint256))
     */
    function _convert(ConvertParams memory p) internal {
        p.taxCollector.convert(p.netAmount, p.minUsdgOutRaw);
    }
    // end::_convert(ConvertParams)[]
}
// end::NetNetSpotService[]
