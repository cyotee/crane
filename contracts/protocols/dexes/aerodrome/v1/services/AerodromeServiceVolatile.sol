// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/**
 * @title AerodromeServiceVolatile
 * @notice Library for interacting with Aerodrome volatile pools (xy = k curve)
 * @dev For stable pools (x³y + xy³ = k curve), use AerodromeServiceStable instead.
 *
 * This library provides functions for:
 * - Swapping tokens in volatile pools
 * - Swap-deposit (zap in) to volatile pools
 * - Withdraw-swap (zap out) from volatile pools
 * - Quoting optimal swap amounts for balanced deposits
 *
 * All functions explicitly use `stable: false` for pool/router interactions.
 */
library AerodromeServiceVolatile {
    using ConstProdUtils for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                  Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Aerodrome fee denominator is 10000 (not 100000 like Uniswap V2)
    uint256 constant AERO_FEE_DENOM = 10000;

    /* -------------------------------------------------------------------------- */
    /*                                   Structs                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Parameters for swapping tokens in a volatile pool
     * @param router The Aerodrome router contract
     * @param factory The Aerodrome pool factory contract
     * @param pool The volatile pool to swap in
     * @param tokenIn The token being sold
     * @param tokenOut The token being purchased
     * @param amountIn The amount of tokenIn to swap
     * @param recipient The address to receive tokenOut
     * @param deadline The transaction deadline timestamp
     */
    struct SwapVolatileParams {
        IRouter router;
        IPoolFactory factory;
        IPool pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
    }

    /**
     * @notice Parameters for swap-deposit (zap in) to a volatile pool
     * @param router The Aerodrome router contract
     * @param factory The Aerodrome pool factory contract
     * @param pool The volatile pool to deposit into
     * @param token0 The token0 of the pool (for reserve sorting)
     * @param tokenIn The single token being deposited
     * @param opposingToken The other token in the pool
     * @param amountIn The amount of tokenIn to deposit
     * @param recipient The address to receive LP tokens
     * @param deadline The transaction deadline timestamp
     */
    struct SwapDepositVolatileParams {
        IRouter router;
        IPoolFactory factory;
        IPool pool;
        IERC20 token0;
        IERC20 tokenIn;
        IERC20 opposingToken;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
    }

    /**
     * @notice Parameters for withdraw-swap (zap out) from a volatile pool
     * @param aerodromeRouter The Aerodrome router contract
     * @param pool The volatile pool to withdraw from
     * @param factory The Aerodrome pool factory contract
     * @param tokenOut The desired output token
     * @param opposingToken The other token in the pool (will be swapped)
     * @param lpBurnAmt The amount of LP tokens to burn
     * @param recipient The address to receive tokenOut
     * @param deadline The transaction deadline timestamp
     */
    struct WithdrawSwapVolatileParams {
        IRouter aerodromeRouter;
        IPool pool;
        IPoolFactory factory;
        IERC20 tokenOut;
        IERC20 opposingToken;
        uint256 lpBurnAmt;
        address recipient;
        uint256 deadline;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                  */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Swaps tokens in a volatile pool
     * @dev Uses `stable: false` for the swap route
     * @param params The swap parameters
     * @return amountOut The amount of tokenOut received
     */
    function _swapVolatile(
        SwapVolatileParams memory params
    ) internal returns (uint256 amountOut) {
        IRouter.Route memory route = IRouter.Route({
            from: address(params.tokenIn),
            to: address(params.tokenOut),
            stable: false, // Volatile pool
            factory: address(params.factory)
        });
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;

        params.tokenIn.approve(address(params.router), params.amountIn);

        uint256[] memory amountsOut = params.router.swapExactTokensForTokens(
            params.amountIn,
            0, // amountOutMin - caller should implement slippage protection
            routes,
            params.recipient,
            params.deadline
        );

        return amountsOut[amountsOut.length - 1];
    }

    /**
     * @notice Performs a swap-deposit (zap in) to a volatile pool
     * @dev Swaps a portion of tokenIn for opposingToken, then deposits both
     * @param params The swap-deposit parameters
     * @return lpOut The amount of LP tokens minted
     */
    function _swapDepositVolatile(
        SwapDepositVolatileParams memory params
    ) internal returns (uint256 lpOut) {
        // Calculate optimal swap amount
        uint256 swapAmount = _quoteSwapDepositSaleAmtVolatile(params);

        // Swap portion of tokenIn for opposingToken
        SwapVolatileParams memory swapParams = SwapVolatileParams({
            router: params.router,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.tokenIn,
            tokenOut: params.opposingToken,
            amountIn: swapAmount,
            recipient: address(this),
            deadline: params.deadline
        });
        uint256 swapAmountOut = _swapVolatile(swapParams);

        // Deposit remaining tokenIn and swapped opposingToken
        uint256 depositAmountIn = params.amountIn - swapAmount;
        params.tokenIn.approve(address(params.router), depositAmountIn);
        params.opposingToken.approve(address(params.router), swapAmountOut);

        (
            , // amountA
            , // amountB
            lpOut
        ) = params.router.addLiquidity(
            address(params.tokenIn),
            address(params.opposingToken),
            false, // Volatile pool
            depositAmountIn,
            swapAmountOut,
            0, // amountAMin - caller should implement slippage protection
            0, // amountBMin
            params.recipient,
            params.deadline
        );
    }

    /**
     * @notice Calculates the optimal swap amount for a swap-deposit operation
     * @dev Uses ConstProdUtils for volatile pool math (xy = k)
     * @param params The swap-deposit parameters
     * @return saleAmt The optimal amount to swap
     */
    function _quoteSwapDepositSaleAmtVolatile(
        SwapDepositVolatileParams memory params
    ) internal view returns (uint256 saleAmt) {
        uint256 saleReserve = address(params.tokenIn) == address(params.token0)
            ? params.pool.reserve0()
            : params.pool.reserve1();

        saleAmt = ConstProdUtils._swapDepositSaleAmt(
            params.amountIn,
            saleReserve,
            params.factory.getFee(address(params.pool), false), // Volatile pool fee
            AERO_FEE_DENOM
        );
    }

    /**
     * @notice Performs a withdraw-swap (zap out) from a volatile pool
     * @dev Removes liquidity and swaps opposingToken to tokenOut
     * @param params The withdraw-swap parameters
     * @return amountOut The total amount of tokenOut received
     */
    function _withdrawSwapVolatile(
        WithdrawSwapVolatileParams memory params
    ) internal returns (uint256 amountOut) {
        // Remove liquidity
        (uint256 amountA, uint256 amountB) = params.aerodromeRouter.removeLiquidity(
            address(params.tokenOut),
            address(params.opposingToken),
            false, // Volatile pool
            params.lpBurnAmt,
            0, // amountAMin
            0, // amountBMin
            address(this),
            params.deadline
        );

        // Swap opposingToken (amountB) to tokenOut
        SwapVolatileParams memory swapParams = SwapVolatileParams({
            router: params.aerodromeRouter,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.opposingToken,
            tokenOut: params.tokenOut,
            amountIn: amountB,
            recipient: params.recipient,
            deadline: params.deadline
        });
        uint256 swapAmountOut = _swapVolatile(swapParams);

        // Transfer the tokenOut portion from removeLiquidity to recipient
        params.tokenOut.transfer(params.recipient, amountA);

        return amountA + swapAmountOut;
    }
}
