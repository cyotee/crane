// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_UniswapV2ForkBase} from "./TestBase_UniswapV2ForkBase.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/// @title UniswapV2Utils_ForkBase
/// @notice Fork tests validating ConstProdUtils quote parity with Uniswap V2 on Base mainnet
/// @dev Tests use real Base mainnet pairs via Infura RPC
contract UniswapV2Utils_ForkBase is TestBase_UniswapV2ForkBase {

    /* -------------------------------------------------------------------------- */
    /*                        US-CRANE-202.2: Quote/Math Parity                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Test getAmountsOut parity with ConstProdUtils._saleQuote (small amount)
    function test_saleQuoteParity_small() public {
        // Get WETH/USDC pair dynamically from factory
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

        // Small amount: 0.1 ETH
        uint256 amountIn = 0.1 ether;

        (uint256 reserveWeth, uint256 reserveUsdc) = getReserves(pair, WETH, USDC);

        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, USDC);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveUsdc);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "Small amount: ConstProdUtils._saleQuote should match router getAmountsOut"
        );
    }

    /// @notice Test getAmountsOut parity with ConstProdUtils._saleQuote (medium amount)
    function test_saleQuoteParity_medium() public {
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

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
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

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
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

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
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

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
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

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
    /*                         USDbC Tests (bridged USDC)                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote parity on WETH/USDbC pair (18/6 decimals, bridged USDC)
    function test_saleQuoteParity_bridgedUSDC() public {
        address pairAddress = uniswapV2Factory.getPair(WETH, USDbC);
        skipIfPairInvalid(pairAddress, "WETH_USDbC");

        IUniswapV2Pair pair = getPair(pairAddress);

        uint256 amountIn = 1 ether;

        (uint256 reserveWeth, uint256 reserveUsdbC) = getReserves(pair, WETH, USDbC);

        uint256 routerAmountOut = quoteAmountOut(amountIn, WETH, USDbC);
        uint256 constProdAmountOut = quoteConstProdSale(amountIn, reserveWeth, reserveUsdbC);

        assertExactMatch(
            routerAmountOut,
            constProdAmountOut,
            "Bridged USDC: ConstProdUtils._saleQuote should match router"
        );
    }

    /// @notice Test reverse direction (USDC -> WETH)
    function test_saleQuoteParity_reverseDirection() public {
        address pairAddress = uniswapV2Factory.getPair(WETH, USDC);
        skipIfPairInvalid(pairAddress, "WETH_USDC");

        IUniswapV2Pair pair = getPair(pairAddress);

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
