// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

import {
    IERC20
} from "../../../../../tokens/erc20/interfaces/IERC20.sol";

import {
    SafeERC20
} from "../../../../../tokens/erc20/libs/SafeERC20.sol";

import {
    ICamelotPair
} from "../interfaces/ICamelotPair.sol";
import {
    ICamelotFactory
} from "../interfaces/ICamelotFactory.sol";
import {
    ICamelotV2Router
} from "../interfaces/ICamelotV2Router.sol";

// import {
//     CamelotV2Utils
// } from "../libs/CamelotV2Utils.sol";
import {
    ConstProdUtils
} from "../../../../../utils/math/ConstProdUtils.sol";

library CamelotV2Service {

    using ConstProdUtils for uint256;
    // using CamelotV2Utils for uint256;
    using CamelotV2Service for ICamelotPair;
    using CamelotV2Service for ICamelotV2Router;
    using SafeERC20 for IERC20;

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    function _deposit(
        ICamelotV2Router router,
        IERC20 tokenA,
        IERC20 tokenB,
        uint amountADesired,
        uint amountBDesired
    ) internal returns (uint256 liquidity) {
        tokenA.approve(address(router), amountADesired);
        tokenB.approve(address(router), amountBDesired);
        (,, liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountADesired,
            amountBDesired,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                                Withdraw                                */
    /* ---------------------------------------------------------------------- */

    function _withdrawDirect(
        ICamelotPair pool,
        uint256 amt
    ) internal returns(uint amount0, uint amount1) {
        pool.transfer(address(pool), amt);
        (amount0, amount1) = pool.burn(address(this));
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Swap                                  */
    /* ---------------------------------------------------------------------- */

    function _swap(
        ICamelotV2Router router,
        uint256 amountIn,
        IERC20 tokenIn,
        uint256 reserveIn,
        uint256 feePercent,
        IERC20 tokenOut,
        uint256 reserveOut,
        address referrer
    ) internal returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);
        amountOut = amountIn
        ._saleQuote(
            // uint256 amountIn,
            reserveIn,
            reserveOut,
            feePercent
        );
        tokenIn.approve(address(router), amountIn);
        router
        .swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            // uint amountOutMin,
            1,
            path,
            // address to,
            address(this),
            referrer,
            // uint deadline
            block.timestamp
        );
        // console.log("CamelotV2Service:_swap:: Exiting function");
    }
    
    function _swap(
        ICamelotV2Router router,
        ICamelotPair pool,
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address referrer
    ) internal returns (uint256 amountOut) {
        // address[] memory path = new address[](2);
        // path[0] = address(tokenIn);
        // path[1] = address(tokenOut);
        // (
        //     uint112 reserve0,
        //     uint112 reserve1,
        //     uint16 token0feePercent,
        //     uint16 token1FeePercent
        // ) =  pool.getReserves();
        // (
        //     uint256 reserveIn,
        //     uint256 reserveOut,
        //     uint256 feePercent
        // ) = address(tokenIn) == pool.token0()
        // ? (reserve0, reserve1, token0feePercent)
        // : (reserve1, reserve0, token1FeePercent);
        (
            uint256 reserveIn,
            uint256 reserveOut,
            uint256 feePercent,

        ) = _sortReserves(
            // ICamelotPair pool,
            pool,
            // IERC20 knownToken
            tokenIn
        );
        return _swap(
            // ICamelotV2Router router,
            router,
            // uint256 amountIn,
            amountIn,
            // IERC20 tokenIn,
            tokenIn,
            // uint256 reserveIn,
            reserveIn,
            // uint256 feePercent,
            feePercent,
            // IERC20 tokenOut,
            tokenOut,
            // uint256 reserveOut,
            reserveOut,
            // address referrer
            referrer
        );
        // amountOut = amountIn
        // ._calcAmountOutConstProd(
        //     // uint256 amountIn,
        //     reserveIn,
        //     reserveOut,
        //     feePercent
        // );
        // tokenIn.approve(address(router), amountIn);
        // router
        // .swapExactTokensForTokensSupportingFeeOnTransferTokens(
        //     amountIn,
        //     // uint amountOutMin,
        //     1,
        //     path,
        //     // address to,
        //     address(this),
        //     referrer,
        //     // uint deadline
        //     block.timestamp
        // );
        // console.log("CamelotV2Service:_swap:: Exiting function");
    }

    function _sortReserves(
        ICamelotPair pool,
        IERC20 knownToken
    ) internal view returns(
        uint256 knownReserve,
        uint256 unknownReserve,
        uint256 knownFee,
        uint256 unknownFee
    ) {
        (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0feePercent,
            uint16 token1FeePercent
        ) = pool.getReserves();
        (
            knownReserve,
            unknownReserve,
            knownFee,
            unknownFee
        ) = address(knownToken) == pool.token0()
        ? (reserve0, reserve1, token0feePercent, token1FeePercent)
        : (reserve1, reserve0, token1FeePercent, token0feePercent);
    }
    
    function _swapDeposit(
        ICamelotV2Router router,
        ICamelotPair pool,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        address referrer
    ) internal returns (uint256) {
        // (
        //     uint112 reserve0,
        //     uint112 reserve1,
        //     uint16 token0feePercent,
        //     uint16 token1FeePercent
        // ) = pool.getReserves();
        // (
        //     uint256 saleReserve,
        //     uint256 saleTokenFeePerc
        // ) = address(tokenIn) == pool.token0()
        // ? (reserve0, token0feePercent)
        // : (reserve1, token1FeePercent);
        // (
        //     uint256 saleReserve,
        //     uint256 reserveOut,
        //     uint256 saleTokenFeePerc
        // ) = address(tokenIn) == pool.token0()
        // ? (reserve0, reserve1, token0feePercent)
        // : (reserve1, reserve0, token1FeePercent);
        (
            uint256 saleReserve,
            uint256 reserveOut,
            uint256 saleTokenFeePerc,

        ) = _sortReserves(
            // ICamelotPair pool,
            pool,
            // IERC20 knownToken
            tokenIn
        );
        // uint256[] memory balancedAmounts = _balanceAssets(
        //     router,
        //     pool,
        //     saleAmt,
        //     // tokenA,
        //     tokenIn,
        //     // tokenB,
        //     opToken,
        //     referrer
        // );
        uint256[] memory balancedAmounts = _balanceAssets(
            // ICamelotV2Router router,
            router,
            // uint256 saleAmt,
            saleAmt,
            // IERC20 tokenIn,
            tokenIn,
            // uint256 saleReserve,
            saleReserve,
            // uint256 saleTokenFeePerc,
            saleTokenFeePerc,
            // IERC20 tokenOut,
            opToken,
            // uint256 reserveOut,
            reserveOut,
            // address referrer
            referrer
        );
        // tokenIn.approve(address(router),  balancedAmounts[0]);
        // opToken.approve(address(router),  balancedAmounts[1]);
        uint256 poolTokenAmount = _deposit(
            router,
            // tokenA,
            tokenIn,
            // tokenB,
            opToken,
            balancedAmounts[0],
            balancedAmounts[1]
            // extra
        );
        return poolTokenAmount;
    }

    function _balanceAssets(
        ICamelotV2Router router,
        ICamelotPair pool,
        uint256 saleAmt,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address referrer
    ) internal returns(uint256[] memory amounts) {
        (
            uint112 reserve0,
            uint112 reserve1,
            uint16 token0feePercent,
            uint16 token1FeePercent
        ) = pool.getReserves();
        // (
        //     uint256 saleReserve,
        //     uint256 saleTokenFeePerc
        // ) = address(tokenIn) == pool.token0()
        // ? (reserve0, token0feePercent)
        // : (reserve1, token1FeePercent);
        (
            uint256 saleReserve,
            uint256 reserveOut,
            uint256 saleTokenFeePerc
        ) = address(tokenIn) == pool.token0()
        ? (reserve0, reserve1, token0feePercent)
        : (reserve1, reserve0, token1FeePercent);
        // get amount of input token to be swapped
        uint256 swapAmountIn = saleAmt
        ._swapDepositSaleAmt(
            saleReserve,
            saleTokenFeePerc
        );
        // tokenIn.approve(address(router), swapAmountIn);
        amounts = new uint256[](2);
        amounts[0] = saleAmt - swapAmountIn;
        // console.log("Swapping to balance pool");
        // amounts[1] = _swap(
        //     router,
        //     pool,
        //     swapAmountIn,
        //     tokenIn,
        //     tokenOut,
        //     referrer
        // );
        amounts[1] = _swap(
            // ICamelotV2Router router,
            router,
            // uint256 amountIn,
            swapAmountIn,
            // IERC20 tokenIn,
            tokenIn,
            // uint256 reserveIn,
            saleReserve,
            // uint256 feePercent,
            saleTokenFeePerc,
            // IERC20 tokenOut,
            tokenOut,
            // uint256 reserveOut,
            reserveOut,
            // address referrer
            referrer
        );
    }

    function _balanceAssets(
        ICamelotV2Router router,
        uint256 saleAmt,
        IERC20 tokenIn,
        uint256 saleReserve,
        uint256 saleTokenFeePerc,
        IERC20 tokenOut,
        uint256 reserveOut,
        address referrer
    ) internal returns(uint256[] memory amounts) {
        // (
        //     uint112 reserve0,
        //     uint112 reserve1,
        //     uint16 token0feePercent,
        //     uint16 token1FeePercent
        // ) = pool.getReserves();
        // (
        //     uint256 saleReserve,
        //     uint256 saleTokenFeePerc
        // ) = address(tokenIn) == pool.token0()
        // ? (reserve0, token0feePercent)
        // : (reserve1, token1FeePercent);
        // (
        //     uint256 saleReserve,
        //     uint256 reserveOut,
        //     uint256 saleTokenFeePerc
        // ) = address(tokenIn) == pool.token0()
        // ? (reserve0, reserve1, token0feePercent)
        // : (reserve1, reserve0, token1FeePercent);
        // get amount of input token to be swapped
        uint256 swapAmountIn = saleAmt
        ._swapDepositSaleAmt(
            saleReserve,
            saleTokenFeePerc
        );
        // tokenIn.approve(address(router), swapAmountIn);
        amounts = new uint256[](2);
        amounts[0] = saleAmt - swapAmountIn;
        // console.log("Swapping to balance pool");
        // amounts[1] = _swap(
        //     router,
        //     pool,
        //     swapAmountIn,
        //     tokenIn,
        //     tokenOut,
        //     referrer
        // );
        amounts[1] = _swap(
            // ICamelotV2Router router,
            router,
            // uint256 amountIn,
            swapAmountIn,
            // IERC20 tokenIn,
            tokenIn,
            // uint256 reserveIn,
            saleReserve,
            // uint256 feePercent,
            saleTokenFeePerc,
            // IERC20 tokenOut,
            tokenOut,
            // uint256 reserveOut,
            reserveOut,
            // address referrer
            referrer
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                              Withdraw/Swap                             */
    /* ---------------------------------------------------------------------- */

    function _withdrawSwapDirect(
        ICamelotPair pool,
        ICamelotV2Router router,
        uint256 amt,
        IERC20 tokenOut,
        IERC20 opToken,
        address referrer
    ) internal returns(uint256 amountOut) {
        (uint amount0, uint amount1) = pool
        ._withdrawDirect(amt);
        address token0 = pool.token0();

        (
            uint256 tokenOutWDAmt,
            uint256 saleTokenWDAmt
        ) = address(tokenOut) == address(token0)
            ? (amount0, amount1)
            : (amount1, amount0);
        (uint256 proceedsAmount) = router
        ._swap(
            pool,
            saleTokenWDAmt,
            opToken,
            tokenOut,
            referrer
        );
        amountOut = (tokenOutWDAmt + proceedsAmount);
        // tokenOut._safeTransfer(recipient, amountOut);
    }

}