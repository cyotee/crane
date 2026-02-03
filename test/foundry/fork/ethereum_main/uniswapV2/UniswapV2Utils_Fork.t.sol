// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_UniswapV2Fork} from "./TestBase_UniswapV2Fork.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/// @title UniswapV2Utils_Fork
/// @notice Fork tests validating ConstProdUtils quote parity with Uniswap V2 on Ethereum mainnet
/// @dev Tests use real mainnet pairs via Infura RPC
contract UniswapV2Utils_Fork is TestBase_UniswapV2Fork {

    /* -------------------------------------------------------------------------- */
    /*                        US-CRANE-202.2: Quote/Math Parity                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Test getAmountsOut parity with ConstProdUtils._saleQuote (small amount)
    function test_saleQuoteParity_small() public {
        // Use WETH/USDC pair
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        // Small amount: 0.1 ETH
        uint256 amountIn = 0.1 ether;

        // Get reserves
        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        // Get quote from router
        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, USDC);

        // Get quote from ConstProdUtils
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveUsdc);

        // They should match exactly
        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "Small amount: ConstProdUtils._saleQuote should match router getAmountsOut"
        );
    }

    /// @notice Test getAmountsOut parity with ConstProdUtils._saleQuote (medium amount)
    function test_saleQuoteParity_medium() public {
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        // Medium amount: 10 ETH
        uint256 amountIn = 10 ether;

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, USDC);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveUsdc);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "Medium amount: ConstProdUtils._saleQuote should match router getAmountsOut"
        );
    }

    /// @notice Test getAmountsOut parity with ConstProdUtils._saleQuote (large amount near reserve)
    function test_saleQuoteParity_nearReserveBound() public {
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        // Large amount: ~10% of reserve
        uint256 amountIn = reserveWeth / 10;

        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, USDC);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveUsdc);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "Near reserve bound: ConstProdUtils._saleQuote should match router getAmountsOut"
        );
    }

    /// @notice Test getAmountsIn parity with ConstProdUtils._purchaseQuote (small amount)
    function test_purchaseQuoteParity_small() public {
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        // Small output: 100 USDC
        uint256 amountOut = 100 * 1e6;

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        uint256 routerAmountIn = quoteAmountIn(amountOut, WETH, USDC);
        uint256 constProdAmountIn = quoteConstProdPurchase(amountOut, reserveWeth, reserveUsdc);

        assertWithinRounding(
            routerAmountIn,
            constProdAmountIn,
            "Small amount: ConstProdUtils._purchaseQuote should match router getAmountsIn"
        );
    }

    /// @notice Test getAmountsIn parity with ConstProdUtils._purchaseQuote (medium amount)
    function test_purchaseQuoteParity_medium() public {
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        // Medium output: 10,000 USDC
        uint256 amountOut = 10_000 * 1e6;

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        uint256 routerAmountIn = quoteAmountIn(amountOut, WETH, USDC);
        uint256 constProdAmountIn = quoteConstProdPurchase(amountOut, reserveWeth, reserveUsdc);

        assertWithinRounding(
            routerAmountIn,
            constProdAmountIn,
            "Medium amount: ConstProdUtils._purchaseQuote should match router getAmountsIn"
        );
    }

    /// @notice Test getAmountsIn parity with ConstProdUtils._purchaseQuote (large amount)
    function test_purchaseQuoteParity_nearReserveBound() public {
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        // Large output: ~5% of USDC reserve
        uint256 amountOut = reserveUsdc / 20;

        uint256 routerAmountIn = quoteAmountIn(amountOut, WETH, USDC);
        uint256 constProdAmountIn = quoteConstProdPurchase(amountOut, reserveWeth, reserveUsdc);

        assertWithinRounding(
            routerAmountIn,
            constProdAmountIn,
            "Near reserve bound: ConstProdUtils._purchaseQuote should match router getAmountsIn"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                      Revert Parity Tests (Invalid Inputs)                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Verify zero amount reverts on router
    function test_zeroAmountReverts_router() public {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        vm.expectRevert("UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        uniswapV2Router.getAmountsOut(0, path);
    }

    /// @notice Verify empty path reverts on router
    function test_emptyPathReverts_router() public {
        address[] memory path = new address[](1);
        path[0] = WETH;

        vm.expectRevert("UniswapV2Library: INVALID_PATH");
        uniswapV2Router.getAmountsOut(1 ether, path);
    }

    /// @notice Verify zero output amount reverts on router getAmountsIn
    function test_zeroOutputReverts_router() public {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        vm.expectRevert("UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        uniswapV2Router.getAmountsIn(0, path);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Additional Pair Tests                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote parity on WETH/DAI pair (18/18 decimals)
    function test_saleQuoteParity_18_18_decimals() public {
        IUniswapV2Pair pair = getPair(WETH_DAI_PAIR);
        skipIfPairInvalid(WETH_DAI_PAIR, "WETH_DAI");

        uint256 amountIn = 1 ether;

        (uint256 reserveWeth, uint256 reserveDai) = getReserves(pair, WETH, DAI);

        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, DAI);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveDai);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "18/18 decimals: ConstProdUtils._saleQuote should match router"
        );
    }

    /// @notice Test quote parity on WETH/USDT pair (18/6 decimals)
    function test_saleQuoteParity_18_6_decimals() public {
        IUniswapV2Pair pair = getPair(WETH_USDT_PAIR);
        skipIfPairInvalid(WETH_USDT_PAIR, "WETH_USDT");

        uint256 amountIn = 1 ether;

        (uint256 reserveWeth, uint256 reserveUsdt) = getReserves(pair, WETH, USDT);

        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, USDT);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveUsdt);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "18/6 decimals: ConstProdUtils._saleQuote should match router"
        );
    }

    /// @notice Test reverse direction (USDC -> WETH)
    function test_saleQuoteParity_reverseDirection() public {
        IUniswapV2Pair pair = getPair(WETH_USDC_PAIR);
        skipIfPairInvalid(WETH_USDC_PAIR, "WETH_USDC");

        // Sell 1000 USDC for WETH
        uint256 amountIn = 1000 * 1e6;

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        // Note: reserves are swapped for reverse direction
        uint256 routerAmountOut = quoteAmountOut(amountIn, USDC, WETH);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveUsdc, reserveWeth);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "Reverse direction: ConstProdUtils._saleQuote should match router"
        );
    }
}
