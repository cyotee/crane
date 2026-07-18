// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

// tag::AerodromeService[]
/**
 * @title AerodromeService
 * @notice Library for interacting with Aerodrome (volatile) pools via router (deprecated wrapper).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev DEPRECATED. Use specialized instead:
 *   - AerodromeServiceVolatile.sol for volatile pools (xy = k)
 *   - AerodromeServiceStable.sol for stable pools (x³y + xy³ = k)
 *
 * This legacy library only supports volatile pools (stable: false).
 * New libraries provide explicit naming, per-type structs, clearer API.
 *
 * Migration:
 *   - AerodromeService.SwapParams -> AerodromeServiceVolatile.SwapVolatileParams
 *   - AerodromeService._swap() -> AerodromeServiceVolatile._swapVolatile()
 *   - AerodromeService._swapDepositVolatile() -> AerodromeServiceVolatile._swapDepositVolatile()
 *   - AerodromeService._withdrawSwapVolatile() -> AerodromeServiceVolatile._withdrawSwapVolatile()
 *   - AerodromeService._quoteSwapDepositSaleAmt() -> AerodromeServiceVolatile._quoteSwapDepositSaleAmtVolatile()
 *
 * @dev Internal-only (_-prefixed). For *Service pattern see AGENTS.md; NatSpec per PRD LR-1.
 * @dev Uses ConstProdUtils for constant-product AMM calcs (volatile case).
 * @dev Ties to LR-2 (protocol utility docs + test usage in Aerodrome ports).
 * @custom:deprecated See migration guide above. For backward compat only.
 */
library AerodromeService {
    using ConstProdUtils for uint256;

    // tag::SwapParams[]
    /**
     * @dev Internal param struct for legacy _swap on volatile pools.
     */
    struct SwapParams {
        IRouter router;
        IPoolFactory factory;
        IPool pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
    }

    // end::SwapParams[]

    // tag::SwapDepositVolatileParams[]
    /**
     * @dev Internal param struct for _swapDepositVolatile and _quoteSwapDepositSaleAmt.
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

    // tag::_swap(SwapParams)[]
    /**
     * @notice Executes exact-in swap for volatile (non-stable) Aerodrome pool.
     * Builds single-hop Route (stable=false), approves, calls router.swapExactTokensForTokens.
     * @dev Legacy internal; see AerodromeServiceVolatile for active API.
     * @param params Bundle with router/factory/pool + tokens/amounts/recipient/deadline.
     * @return amountOut Output token amount received.
     * @custom:emits Transfer (token approvals + router/pool transfers).
     */
    function _swap(SwapParams memory params) internal returns (uint256 amountOut) {
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

    // end::_swap(SwapParams)[]

    // tag::_swapDepositVolatile(SwapDepositVolatileParams)[]
    /**
     * @notice Performs swap-deposit (zap) for balanced LP in volatile Aerodrome pool.
     * Quotes sale amt, swaps portion of tokenIn, then adds balanced liquidity.
     * @dev Legacy; internal use only. Recipient receives LP.
     * @param params Bundle (router, factory, pool, token0, tokenIn, opposing, amountIn, recipient, deadline).
     * @return lpOut Amount of LP tokens minted to recipient.
     */
    function _swapDepositVolatile(SwapDepositVolatileParams memory params) internal returns (uint256 lpOut) {
        SwapParams memory swapParams = SwapParams({
            router: params.router,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.tokenIn,
            tokenOut: params.opposingToken,
            amountIn: _quoteSwapDepositSaleAmt(params),
            recipient: address(this),
            deadline: params.deadline
        });
        uint256 swapAmountOut = _swap(swapParams);
        uint256 depositAmountIn = params.amountIn - swapParams.amountIn;
        params.tokenIn.approve(address(params.router), depositAmountIn);
        params.opposingToken.approve(address(params.router), swapAmountOut);
        (,, lpOut) = params.router
            .addLiquidity(
                address(params.tokenIn),
                address(params.opposingToken),
                false,
                depositAmountIn,
                swapAmountOut,
                0,
                0,
                params.recipient,
                params.deadline
            );
    }
    // end::_swapDepositVolatile(SwapDepositVolatileParams)[]

    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    // Aerodrome fee denominator is 10000 (not 100000 like Uniswap V2)
    uint256 constant AERO_FEE_DENOM = 10000;

    // tag::_quoteSwapDepositSaleAmt(SwapDepositVolatileParams)[]
    /**
     * @notice Quotes the amount of tokenIn to sell (swap) to balance a deposit into the pool.
     * Uses ConstProdUtils + pool reserves + factory fee (volatile=false).
     * @dev Internal view helper for swap-deposit flows.
     * @param params The swap-deposit params (amountIn, token0 side, pool, factory).
     * @return saleAmt Portion to swap out for opposing token.
     */
    function _quoteSwapDepositSaleAmt(SwapDepositVolatileParams memory params) internal view returns (uint256 saleAmt) {
        uint256 saleReserve =
            address(params.tokenIn) == address(params.token0) ? params.pool.reserve0() : params.pool.reserve1();
        saleAmt = ConstProdUtils._swapDepositSaleAmt(
            params.amountIn, saleReserve, params.factory.getFee(address(params.pool), false), AERO_FEE_DENOM
        );
    }

    // end::_quoteSwapDepositSaleAmt(SwapDepositVolatileParams)[]

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

    // tag::_withdrawSwapVolatile(WithdrawSwapVolatileParams)[]
    /**
     * @notice Withdraw-swap (zap out): remove LP, swap the opposing portion to target tokenOut.
     * Removes liquidity to self, swaps the B portion, transfers A + swapped to recipient.
     * @dev Legacy internal. Assumes volatile pool (stable=false).
     * @param params Bundle with router/pool/factory + tokenOut + opposing + lpBurnAmt + recipient + deadline.
     * @return amountOut Total tokenOut received (direct A + swapped proceeds).
     */
    function _withdrawSwapVolatile(WithdrawSwapVolatileParams memory params) internal returns (uint256 amountOut) {
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
        AerodromeService.SwapParams memory swapParams = AerodromeService.SwapParams({
            router: params.aerodromeRouter,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.opposingToken,
            tokenOut: params.tokenOut,
            amountIn: amountB,
            recipient: params.recipient,
            deadline: params.deadline
        });
        uint256 swapAmountOut = AerodromeService._swap(swapParams);
        // Transfer the tokenOut portion from removeLiquidity to recipient
        params.tokenOut.transfer(params.recipient, amountA);
        return amountA + swapAmountOut;
    }
    // end::_withdrawSwapVolatile(WithdrawSwapVolatileParams)[]

    // end::AerodromeService[]
}
