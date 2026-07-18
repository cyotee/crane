// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

// tag::AerodromeServiceVolatile[]
/**
 * @title AerodromeServiceVolatile
 * @notice Library for interacting with Aerodrome volatile pools (xy = k curve) via router/factory.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Active specialized service for volatile (non-stable) pools using xy=k constant product curve.
 * For stable pools (x³y + xy³ = k curve), use AerodromeServiceStable instead.
 *
 * This library provides functions for:
 * - Swapping tokens in volatile pools
 * - Swap-deposit (zap in) to volatile pools
 * - Withdraw-swap (zap out) from volatile pools
 * - Quoting optimal swap amounts for balanced deposits
 *
 * All functions explicitly use `stable: false` for pool/router interactions.
 *
 * @dev Internal-only (_-prefixed). For *Service pattern see AGENTS.md; NatSpec per PRD LR-1.
 * @dev Uses `ConstProdUtils` for constant-product AMM math (volatile xy=k case).
 * @dev Structs bundle parameters to avoid stack-too-deep in complex flows.
 * @dev Ties to LR-2 (protocol utility docs + test usage in Aerodrome ports).
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

    // tag::SwapVolatileParams[]
    /**
     * @dev Internal param struct for _swapVolatile flows.
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

    // end::SwapVolatileParams[]

    // tag::SwapDepositVolatileParams[]
    /**
     * @dev Internal param struct for _swapDepositVolatile and _quoteSwapDepositSaleAmtVolatile.
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

    // end::SwapDepositVolatileParams[]

    // tag::WithdrawSwapVolatileParams[]
    /**
     * @dev Internal param struct for _withdrawSwapVolatile (zap out).
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

    // end::WithdrawSwapVolatileParams[]

    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                  */
    /* -------------------------------------------------------------------------- */

    // tag::_swapVolatile(SwapVolatileParams)[]
    /**
     * @notice Executes exact-in swap for volatile (non-stable) Aerodrome pool.
     * Builds single-hop Route (stable=false), approves, calls router.swapExactTokensForTokens.
     * @dev Uses `stable: false` explicitly. Caller responsible for slippage (amountOutMin=0 here).
     * @param params Bundle with router/factory/pool + tokens/amounts/recipient/deadline.
     * @return amountOut Output token amount received.
     * @custom:emits Transfer (token approvals + router/pool transfers).
     */
    function _swapVolatile(SwapVolatileParams memory params) internal returns (uint256 amountOut) {
        IRouter.Route memory route = IRouter.Route({
            // address from;
            from: address(params.tokenIn),
            // address to;
            to: address(params.tokenOut),
            // bool stable;
            stable: false,
            // address factory;
            factory: address(params.factory)
        });
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;
        params.tokenIn.approve(address(params.router), params.amountIn);
        uint256[] memory amountsOut = params.router
            .swapExactTokensForTokens(
                // uint256 amountIn,
                params.amountIn,
                // uint256 amountOutMin,
                0,
                // Route[] calldata routes,
                routes,
                // address to,
                params.recipient,
                // uint256 deadline
                params.deadline
            );
        return amountsOut[amountsOut.length - 1];
    }

    // end::_swapVolatile(SwapVolatileParams)[]

    // tag::_swapDepositVolatile(SwapDepositVolatileParams)[]
    /**
     * @notice Performs swap-deposit (zap in) for balanced LP in volatile Aerodrome pool.
     * Quotes sale amt using _quote..., swaps portion of tokenIn for opposing, then adds liquidity (stable=false).
     * @dev Internal use only. Recipient receives the LP tokens.
     * @param params Bundle (router, factory, pool, token0, tokenIn, opposingToken, amountIn, recipient, deadline).
     * @return lpOut Amount of LP tokens minted to recipient.
     * @custom:emits Transfer (approvals + deposits) + liquidity add events from router/pool.
     */
    function _swapDepositVolatile(SwapDepositVolatileParams memory params) internal returns (uint256 lpOut) {
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

        (,, lpOut) = params.router
            .addLiquidity(
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

    // end::_swapDepositVolatile(SwapDepositVolatileParams)[]

    // tag::_quoteSwapDepositSaleAmtVolatile(SwapDepositVolatileParams)[]
    /**
     * @notice Quotes the amount of tokenIn to sell (swap) to balance a deposit into the pool.
     * Uses ConstProdUtils + pool reserves + factory fee (for volatile=false).
     * @dev Internal view helper for swap-deposit flows.
     * @param params The swap-deposit params (amountIn, token0 side, pool, factory).
     * @return saleAmt Portion to swap out for opposing token.
     */
    function _quoteSwapDepositSaleAmtVolatile(SwapDepositVolatileParams memory params)
        internal
        view
        returns (uint256 saleAmt)
    {
        uint256 saleReserve =
            address(params.tokenIn) == address(params.token0) ? params.pool.reserve0() : params.pool.reserve1();
        saleAmt = ConstProdUtils._swapDepositSaleAmt(
            params.amountIn, saleReserve, params.factory.getFee(address(params.pool), false), AERO_FEE_DENOM
        );
    }

    // end::_quoteSwapDepositSaleAmtVolatile(SwapDepositVolatileParams)[]

    // tag::_withdrawSwapVolatile(WithdrawSwapVolatileParams)[]
    /**
     * @notice Withdraw-swap (zap out): remove LP, swap the opposing portion to target tokenOut.
     * Removes liquidity to self (stable=false), swaps the B portion to tokenOut, transfers A + swapped to recipient.
     * @dev Assumes volatile pool (stable=false). Caller responsible for mins/slippage.
     * @param params Bundle with router/pool/factory + tokenOut + opposing + lpBurnAmt + recipient + deadline.
     * @return amountOut Total tokenOut received (direct A + swapped proceeds).
     * @custom:emits Transfer (from remove + swap) + liquidity remove events.
     */
    function _withdrawSwapVolatile(WithdrawSwapVolatileParams memory params) internal returns (uint256 amountOut) {
        // Remove liquidity
        (uint256 amountA, uint256 amountB) = params.aerodromeRouter
            .removeLiquidity(
                // address tokenA,
                address(params.tokenOut),
                // address tokenB,
                address(params.opposingToken),
                // bool stable,
                false,
                // uint256 liquidity,
                params.lpBurnAmt,
                // uint256 amountAMin,
                0,
                // uint256 amountBMin,
                0,
                // address to,
                address(this),
                // uint256 deadline
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
    // end::_withdrawSwapVolatile(WithdrawSwapVolatileParams)[]

    // end::AerodromeServiceVolatile[]
}
