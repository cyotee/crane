// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

library UniswapV2Service {
    using ConstProdUtils for uint256;
    using SafeERC20 for IERC20;
    using UniswapV2Service for IUniswapV2Router;
    using UniswapV2Service for IUniswapV2Pair;

    // Structs to help avoid stack too deep errors

    struct ReserveInfo {
        uint256 knownReserve;
        uint256 opposingReserve;
        uint256 feePercent;
        uint256 unknownFee;
    }

    struct SwapParams {
        IUniswapV2Router router;
        uint256 amountIn;
        IERC20 tokenIn;
        uint256 reserveIn;
        uint256 feePercent;
        IERC20 tokenOut;
        uint256 reserveOut;
    }

    struct BalanceParams {
        IUniswapV2Router router;
        uint256 saleAmt;
        IERC20 tokenIn;
        uint256 saleReserve;
        uint256 saleTokenFeePerc;
        IERC20 tokenOut;
        uint256 reserveOut;
    }

    function _sortReserves(
        // IUniswapV2Pair pool,
        IERC20 knownToken,
        address token0,
        uint256 token0Resereves,
        uint256 token1Resereves
    )
        internal
        pure
        returns (uint256 knownReserve, uint256 opposingReserve, uint256 feePercent, uint256 unknownFee)
    {
        feePercent = 300;
        unknownFee = 300;

        if (address(knownToken) == address(token0)) {
            knownReserve = token0Resereves;
            opposingReserve = token1Resereves;
        } else {
            knownReserve = token1Resereves;
            opposingReserve = token0Resereves;
        }

        return (knownReserve, opposingReserve, feePercent, unknownFee);
    }

    function _sortReserves(IUniswapV2Pair pool, IERC20 knownToken, uint256 token0Resereves, uint256 token1Resereves)
        internal
        view
        returns (uint256 knownReserve, uint256 opposingReserve, uint256 feePercent, uint256 unknownFee)
    {
        feePercent = 300;
        unknownFee = 300;

        if (address(knownToken) == address(pool.token0())) {
            knownReserve = token0Resereves;
            opposingReserve = token1Resereves;
        } else {
            knownReserve = token1Resereves;
            opposingReserve = token0Resereves;
        }

        return (knownReserve, opposingReserve, feePercent, unknownFee);
    }

    function _sortReserves(IERC20 knownToken, IERC20 token0, uint256 token0Resereves, uint256 token1Resereves)
        internal
        pure
        returns (ReserveInfo memory reserves)
    {
        // (
        //     uint112 reserve0,
        //     uint112 reserve1,

        // ) = pool.getReserves();
        reserves.feePercent = 300;
        reserves.unknownFee = 300;

        if (address(knownToken) == address(token0)) {
            reserves.knownReserve = token0Resereves;
            reserves.opposingReserve = token1Resereves;
        } else {
            reserves.knownReserve = token1Resereves;
            reserves.opposingReserve = token0Resereves;
        }

        return reserves;
    }

    function _sortReserves(IUniswapV2Pair pool, IERC20 knownToken, IERC20 token0)
        // uint256 token0Resereves,
        // uint256 token1Resereves
        internal
        view
        returns (ReserveInfo memory reserves)
    {
        (uint112 reserve0, uint112 reserve1,) = pool.getReserves();
        reserves.feePercent = 300;
        reserves.unknownFee = 300;

        if (address(knownToken) == address(token0)) {
            reserves.knownReserve = reserve0;
            reserves.opposingReserve = reserve1;
        } else {
            reserves.knownReserve = reserve1;
            reserves.opposingReserve = reserve0;
        }

        return reserves;
    }

    function _sortReserves(IUniswapV2Pair pool, IERC20 knownToken) internal view returns (ReserveInfo memory reserves) {
        (uint112 reserve0, uint112 reserve1,) = pool.getReserves();
        reserves.feePercent = 300;
        reserves.unknownFee = 300;

        if (address(knownToken) == pool.token0()) {
            reserves.knownReserve = reserve0;
            reserves.opposingReserve = reserve1;
        } else {
            reserves.knownReserve = reserve1;
            reserves.opposingReserve = reserve0;
        }

        return reserves;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    function _deposit(
        IUniswapV2Router router,
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint256 liquidity) {
        tokenA.safeApprove(address(router), amountADesired);
        tokenB.safeApprove(address(router), amountBDesired);
        (,, liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), amountADesired, amountBDesired, 1, 1, address(this), block.timestamp
        );
        tokenA.safeApprove(address(router), 0);
        tokenB.safeApprove(address(router), 0);
    }

    /* ---------------------------------------------------------------------- */
    /*                                Withdraw                                */
    /* ---------------------------------------------------------------------- */

    function _withdrawDirect(IUniswapV2Pair pool, uint256 amt) internal returns (uint256 amount0, uint256 amount1) {
        pool.transfer(address(pool), amt);
        (amount0, amount1) = pool.burn(address(this));
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Swap                                  */
    /* ---------------------------------------------------------------------- */

    function _swapExactTokensForTokens(
        IUniswapV2Router router,
        IERC20 tokenIn,
        uint256 amountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        address recipient
    ) internal returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        tokenIn.safeApprove(address(router), amountIn);

        uint256[] memory amounts =
            router.swapExactTokensForTokens(amountIn, minAmountOut, path, recipient, block.timestamp + 1);

        tokenIn.safeApprove(address(router), 0);

        return amounts[amounts.length - 1];
    }

    function _swapTokensForExactTokens(
        IUniswapV2Router router,
        IERC20 tokenIn,
        uint256 amountInMax,
        IERC20 tokenOut,
        uint256 amountOut,
        address recipient
    ) internal returns (uint256 amountIn) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);

        tokenIn.safeApprove(address(router), amountInMax);

        uint256[] memory amounts = router.swapTokensForExactTokens(
            // uint amountOut,
            amountOut,
            // uint amountInMax,
            amountInMax,
            // address[] calldata path,
            path,
            // address to,
            recipient,
            // uint deadline
            block.timestamp + 1
        );

        tokenIn.safeApprove(address(router), 0);

        // return amounts[amounts.length - 1];
        return amounts[0];
    }

    function _swap(IUniswapV2Router router, IUniswapV2Pair pool, uint256 amountIn, IERC20 tokenIn, IERC20 tokenOut)
        internal
        returns (uint256 amountOut)
    {
        // Get reserves and fees
        ReserveInfo memory reserves = _sortReserves(pool, tokenIn);

        // Forward to the main swap function
        return _swap(
            router, amountIn, tokenIn, reserves.knownReserve, reserves.feePercent, tokenOut, reserves.opposingReserve
        );
    }

    function _swap(
        IUniswapV2Router router,
        uint256 amountIn,
        IERC20 tokenIn,
        uint256 reserveIn,
        uint256 feePercent,
        IERC20 tokenOut,
        uint256 reserveOut
    ) internal returns (uint256 amountOut) {
        // console.log("swap: amountIn", amountIn);
        // console.log("swap: tokenIn", address(tokenIn));
        // console.log("swap: tokenIn name = %s", IERC20(address(tokenIn)).name());
        // console.log("swap: reserveIn", reserveIn);
        // console.log("swap: feePercent", feePercent);
        // console.log("swap: tokenOut", address(tokenOut));
        // console.log("swap: tokenOut name = %s", IERC20(address(tokenOut)).name());
        // console.log("swap: reserveOut", reserveOut);
        // Create parameter struct to avoid stack too deep error
        SwapParams memory params = SwapParams({
            router: router,
            amountIn: amountIn,
            tokenIn: tokenIn,
            reserveIn: reserveIn,
            feePercent: feePercent,
            tokenOut: tokenOut,
            reserveOut: reserveOut
        });

        // Calculate expected output
        amountOut = ConstProdUtils._saleQuote(params.amountIn, params.reserveIn, params.reserveOut, params.feePercent);
        // console.log("swap: amountOut", amountOut);

        // Prepare swap
        address[] memory path = _prepareSwap(params);
        // console.log("swap: path[0]", path[0]);
        // console.log("swap: path[1]", path[1]);

        // Execute swap
        _executeSwap(params, path);
        // console.log("swap: tokenOut.balanceOf(this) = ", tokenOut.balanceOf(address(this)));
    }

    // Helper function to create path and approve token
    function _prepareSwap(SwapParams memory params) private returns (address[] memory path) {
        path = new address[](2);
        path[0] = address(params.tokenIn);
        path[1] = address(params.tokenOut);
        params.tokenIn.approve(address(params.router), params.amountIn);
        return path;
    }

    // Helper function to perform router swap
    function _executeSwap(SwapParams memory params, address[] memory path) private {
        params.router
            .swapExactTokensForTokens(
                params.amountIn,
                1, // uint amountOutMin
                path,
                address(this), // address to
                block.timestamp + 1
            );
    }

    /* ---------------------------------------------------------------------- */
    /*                              Swap/Deposit                              */
    /* ---------------------------------------------------------------------- */

    function _swapDeposit(IUniswapV2Router router, IUniswapV2Pair pool, IERC20 tokenIn, uint256 saleAmt, IERC20 opToken)
        internal
        returns (uint256)
    {
        // console.log("swapDeposit: tokenIn", address(tokenIn));
        // console.log("swapDeposit: tokenIn name = %s", IERC20(address(tokenIn)).name());
        // console.log("swapDeposit: saleAmt", saleAmt);
        // console.log("swapDeposit: opToken", address(opToken));
        // console.log("swapDeposit: opToken name = %s", IERC20(address(opToken)).name());

        // Get reserves
        ReserveInfo memory reserves = _sortReserves(pool, tokenIn);
        // console.log("swapDeposit: reserves.reserveIn", reserves.reserveIn);
        // console.log("swapDeposit: reserves.reserveOut", reserves.reserveOut);
        // console.log("swapDeposit: reserves.feePercent", reserves.feePercent);
        // console.log("swapDeposit: reserves.unknownFee", reserves.unknownFee);

        // Create parameter struct to avoid stack too deep error
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: reserves.knownReserve,
            saleTokenFeePerc: reserves.feePercent,
            tokenOut: opToken,
            reserveOut: reserves.opposingReserve
        });

        // Balance assets using the reserves
        uint256[] memory balancedAmounts = _balanceAssetsInternal(params);
        // console.log("swapDeposit: balancedAmounts[0]", balancedAmounts[0]);
        // console.log("swapDeposit: balancedAmounts[1]", balancedAmounts[1]);

        // Deposit balanced amounts
        uint256 poolTokenAmount = _deposit(router, tokenIn, opToken, balancedAmounts[0], balancedAmounts[1]);
        // console.log("swapDeposit: poolTokenAmount", poolTokenAmount);

        return poolTokenAmount;
    }

    // Helper function to implement _balanceAssets logic to avoid stack too deep
    function _balanceAssetsInternal(BalanceParams memory params) private returns (uint256[] memory amounts) {
        // console.log("balanceAssetsInternal: params.saleAmt", params.saleAmt);
        // console.log("balanceAssetsInternal: params.saleReserve", params.saleReserve);
        // console.log("balanceAssetsInternal: params.saleTokenFeePerc", params.saleTokenFeePerc);

        // Get amount of input token to be swapped
        uint256 swapAmountIn = _calculateSwapAmount(params.saleAmt, params.saleReserve, params.saleTokenFeePerc);
        // console.log("balanceAssetsInternal: swapAmountIn", swapAmountIn);

        amounts = new uint256[](2);
        amounts[0] = params.saleAmt - swapAmountIn;
        // console.log("balanceAssetsInternal: amounts[0]", amounts[0]);

        // Perform swap to get the second token
        amounts[1] = _swap(
            params.router,
            swapAmountIn,
            params.tokenIn,
            params.saleReserve,
            params.saleTokenFeePerc,
            params.tokenOut,
            params.reserveOut
        );
        // console.log("balanceAssetsInternal: amounts[1]", amounts[1]);
        return amounts;
    }

    // Helper function to calculate swap amount for balanced deposit
    function _calculateSwapAmount(uint256 saleAmt, uint256 saleReserve, uint256 saleTokenFeePerc)
        internal
        pure
        returns (uint256)
    {
        return ConstProdUtils._swapDepositSaleAmt(saleAmt, saleReserve, saleTokenFeePerc);
    }

    /* ---------------------------------------------------------------------- */
    /*                              Withdraw/Swap                             */
    /* ---------------------------------------------------------------------- */

    struct WithdrawSwapParams {
        IUniswapV2Pair pool;
        IUniswapV2Router router;
        uint256 amt;
        IERC20 tokenOut;
        IERC20 opToken;
    }

    function _withdrawSwapDirect(
        IUniswapV2Pair pool,
        IUniswapV2Router router,
        uint256 amt,
        IERC20 tokenOut,
        IERC20 opToken
    ) internal returns (uint256 amountOut) {
        // Create struct to avoid stack too deep
        WithdrawSwapParams memory params =
            WithdrawSwapParams({pool: pool, router: router, amt: amt, tokenOut: tokenOut, opToken: opToken});

        // Withdraw tokens from pool
        (uint256 amount0, uint256 amount1) = _withdrawDirect(params.pool, params.amt);

        // Determine which token is which
        (uint256 tokenOutWDAmt, uint256 saleTokenWDAmt) = _determineTokenAmounts(params, amount0, amount1);

        // Swap the other token to the target token and add to result
        uint256 proceedsAmount = _swapWithdrawnTokens(params, saleTokenWDAmt);
        amountOut = tokenOutWDAmt + proceedsAmount;
    }

    // Helper function to determine token amounts after withdrawal
    function _determineTokenAmounts(WithdrawSwapParams memory params, uint256 amount0, uint256 amount1)
        internal
        view
        returns (uint256 tokenOutAmount, uint256 saleTokenAmount)
    {
        address token0 = params.pool.token0();

        if (address(params.tokenOut) == token0) {
            tokenOutAmount = amount0;
            saleTokenAmount = amount1;
        } else {
            tokenOutAmount = amount1;
            saleTokenAmount = amount0;
        }
    }

    // Helper function to swap withdrawn tokens
    function _swapWithdrawnTokens(WithdrawSwapParams memory params, uint256 saleTokenWDAmt) internal returns (uint256) {
        return params.router._swap(params.pool, saleTokenWDAmt, params.opToken, params.tokenOut);
    }
}
