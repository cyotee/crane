// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

// import {BetterIERC20 as IERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

// tag::CamelotV2Service[]
/**
 * @title CamelotV2Service - Stateless library for Camelot V2 DEX operations: swaps, liquidity deposit/withdraw, and balanced asset operations.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Internal-only API (prefixed _). Consumed via `using CamelotV2Service for ...` in targets/services or tests.
 * @dev Uses `ConstProdUtils` for constant-product AMM math (purchase/sale quotes, swap deposit calcs).
 * @dev Structs bundle parameters to avoid stack-too-deep in complex flows.
 * @dev See AGENTS.md for *Service pattern and PRD LR-1 for NatSpec requirements.
 */
library CamelotV2Service {
    using ConstProdUtils for uint256;
    // using CamelotV2Utils for uint256;
    using CamelotV2Service for ICamelotPair;
    using CamelotV2Service for ICamelotV2Router;
    using SafeERC20 for IERC20;

    // tag::ReserveInfo[]
    /**
     * @dev Internal struct bundling reserve and fee data for a token pair side.
     * Used to avoid stack depth issues in swap/deposit logic.
     */
    struct ReserveInfo {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 unknownFee;
    }
    // end::ReserveInfo[]

    // tag::SwapParams[]
    /**
     * @dev Internal param struct for _swap flows.
     */
    struct SwapParams {
        ICamelotV2Router router;
        uint256 amountIn;
        IERC20 tokenIn;
        uint256 reserveIn;
        uint256 feePercent;
        IERC20 tokenOut;
        uint256 reserveOut;
        address referrer;
    }
    // end::SwapParams[]

    // tag::BalanceParams[]
    /**
     * @dev Internal param struct for _balanceAssets and _swapDeposit flows.
     */
    struct BalanceParams {
        ICamelotV2Router router;
        uint256 saleAmt;
        IERC20 tokenIn;
        uint256 saleReserve;
        uint256 saleTokenFeePerc;
        IERC20 tokenOut;
        uint256 reserveOut;
        address referrer;
    }
    // end::BalanceParams[]

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    // tag::_deposit(ICamelotV2Router-IERC20-IERC20-uint256-uint256)[]
    /**
     * @notice Deposits (adds) liquidity for a token pair via the Camelot router.
     * Approves and calls addLiquidity; returns minted LP tokens to self.
     * @dev Internal; slippage tolerance set to 1 wei min.
     * @param router The CamelotV2 router instance.
     * @param tokenA First token of the pair.
     * @param tokenB Second token of the pair.
     * @param amountADesired Desired amount of tokenA to deposit.
     * @param amountBDesired Desired amount of tokenB to deposit.
     * @return liquidity Amount of LP tokens minted.
     */
    function _deposit(
        ICamelotV2Router router,
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint256 liquidity) {
        tokenA.approve(address(router), amountADesired);
        tokenB.approve(address(router), amountBDesired);
        (,, liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), amountADesired, amountBDesired, 1, 1, address(this), block.timestamp
        );
    }
    // end::_deposit(ICamelotV2Router-IERC20-IERC20-uint256-uint256)[]

    /* ---------------------------------------------------------------------- */
    /*                                Withdraw                                */
    /* ---------------------------------------------------------------------- */

    // tag::_withdrawDirect(ICamelotPair-uint256)[]
    /**
     * @notice Burns LP tokens directly on the pair to withdraw underlying reserves.
     * @dev Sends LP to pool then calls burn; returns withdrawn token amounts.
     * @param pool The Camelot pair (LP token).
     * @param amt Amount of LP tokens to burn/withdraw.
     * @return amount0 Amount of token0 withdrawn.
     * @return amount1 Amount of token1 withdrawn.
     */
    function _withdrawDirect(ICamelotPair pool, uint256 amt) internal returns (uint256 amount0, uint256 amount1) {
        pool.transfer(address(pool), amt);
        (amount0, amount1) = pool.burn(address(this));
    }
    // end::_withdrawDirect(ICamelotPair-uint256)[]

    /* ---------------------------------------------------------------------- */
    /*                                  Swap                                  */
    /* ---------------------------------------------------------------------- */

    // tag::_prepareSwap(SwapParams)[]
    /**
     * @dev Helper: builds 2-hop path array and approves input for router.
     * @param params Swap params bundle.
     * @return path The token path for the swap.
     */
    function _prepareSwap(SwapParams memory params) private returns (address[] memory path) {
        path = new address[](2);
        path[0] = address(params.tokenIn);
        path[1] = address(params.tokenOut);
        params.tokenIn.approve(address(params.router), params.amountIn);
        return path;
    }
    // end::_prepareSwap(SwapParams)[]

    // tag::_executeSwap(SwapParams-address[])[]
    /**
     * @dev Helper: executes the fee-on-transfer supporting exact-in swap via router.
     * @param params Swap params bundle.
     * @param path The token path.
     */
    function _executeSwap(SwapParams memory params, address[] memory path) private {
        params.router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                params.amountIn,
                1, // uint amountOutMin
                path,
                address(this), // address to
                params.referrer,
                block.timestamp // uint deadline
            );
    }
    // end::_executeSwap(SwapParams-address[])[]

    // tag::_swap(ICamelotV2Router-uint256-IERC20-uint256-uint256-IERC20-uint256-address)[]
    /**
     * @notice Executes a token swap using provided reserves and fee, via Camelot router (supports fee-on-transfer tokens).
     * Computes sale quote via ConstProdUtils then performs the swap.
     * @param router The CamelotV2 router.
     * @param amountIn Amount of input token to swap.
     * @param tokenIn Input token.
     * @param reserveIn Current reserve of input token.
     * @param feePercent Fee percent for the input side (in basis points or as used by pair).
     * @param tokenOut Output token.
     * @param reserveOut Current reserve of output token.
     * @param referrer Referrer address for fee sharing (if any).
     * @return amountOut Actual output amount received (after fees/transfer).
     * @custom:emits (via router) Transfer events and swap events from pair.
     */
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
        // Create parameter struct to avoid stack too deep error
        SwapParams memory params = SwapParams({
            router: router,
            amountIn: amountIn,
            tokenIn: tokenIn,
            reserveIn: reserveIn,
            feePercent: feePercent,
            tokenOut: tokenOut,
            reserveOut: reserveOut,
            referrer: referrer
        });

        // Calculate expected output
        amountOut = ConstProdUtils._saleQuote(params.amountIn, params.reserveIn, params.reserveOut, params.feePercent);

        // Prepare swap
        address[] memory path = _prepareSwap(params);

        // Execute swap
        _executeSwap(params, path);
    }
    // end::_swap(ICamelotV2Router-uint256-IERC20-uint256-uint256-IERC20-uint256-address)[]

    // tag::_swap(ICamelotV2Router-ICamelotPair-uint256-IERC20-IERC20-address)[]
    /**
     * @notice Overload: swaps given a pool, fetching reserves/fees via _sortReservesStruct.
     * @param router The CamelotV2 router.
     * @param pool The pair to derive reserves/fees from.
     * @param amountIn Amount of input token to swap.
     * @param tokenIn Input token.
     * @param tokenOut Output token.
     * @param referrer Referrer address.
     * @return amountOut Actual amount out.
     */
    function _swap(
        ICamelotV2Router router,
        ICamelotPair pool,
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address referrer
    ) internal returns (uint256 amountOut) {
        // Get reserves and fees
        ReserveInfo memory reserves = _sortReservesStruct(pool, tokenIn);

        // Forward to the main swap function
        return _swap(
            router, amountIn, tokenIn, reserves.reserveIn, reserves.feePercent, tokenOut, reserves.reserveOut, referrer
        );
    }
    // end::_swap(ICamelotV2Router-ICamelotPair-uint256-IERC20-IERC20-address)[]

    // tag::_sortReserves(ICamelotPair-IERC20)[]
    /**
     * @notice Returns sorted reserves + fees for known token vs opposing.
     * @param pool The pair.
     * @param knownToken The token whose side to treat as "in".
     * @return knownReserve Reserve of known.
     * @return opposingReserve Reserve of the other.
     * @return knownFeePercent Fee for known side.
     * @return opposingFeePercent Fee for opposing side.
     */
    function _sortReserves(ICamelotPair pool, IERC20 knownToken)
        internal
        view
        returns (uint256 knownReserve, uint256 opposingReserve, uint256 knownFeePercent, uint256 opposingFeePercent)
    {
        ReserveInfo memory reserves = _sortReservesStruct(pool, knownToken);
        return (reserves.reserveIn, reserves.reserveOut, reserves.feePercent, reserves.unknownFee);
    }
    // end::_sortReserves(ICamelotPair-IERC20)[]

    // tag::_sortReservesStruct(ICamelotPair-IERC20)[]
    /**
     * @notice Returns ReserveInfo struct with reserves and fees sorted by known token.
     * Reads getReserves() and token0 to decide sides.
     * @param pool The pair.
     * @param knownToken The token for "in" side (or zero to default to token0).
     * @return reserves Populated ReserveInfo.
     */
    function _sortReservesStruct(ICamelotPair pool, IERC20 knownToken)
        internal
        view
        returns (ReserveInfo memory reserves)
    {
        (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent) = pool.getReserves();
        address token0 = pool.token0();
        if (address(knownToken) == address(0)) {
            knownToken = IERC20(token0);
        }

        if (address(knownToken) == token0) {
            reserves.reserveIn = reserve0;
            reserves.reserveOut = reserve1;
            reserves.feePercent = token0feePercent;
            reserves.unknownFee = token1FeePercent;
        } else {
            reserves.reserveIn = reserve1;
            reserves.reserveOut = reserve0;
            reserves.feePercent = token1FeePercent;
            reserves.unknownFee = token0feePercent;
        }

        return reserves;
    }
    // end::_sortReservesStruct(ICamelotPair-IERC20)[]

    // tag::_swapDeposit(ICamelotV2Router-ICamelotPair-IERC20-uint256-IERC20-address)[]
    /**
     * @notice Performs a swap of some input to balance for a subsequent deposit into the pool.
     * Returns the LP amount received.
     * @param router Router.
     * @param pool Pair for reserves.
     * @param tokenIn The sale token (input for balancing swap).
     * @param saleAmt Amount of tokenIn available to (partially) swap + deposit.
     * @param opToken The opposing token.
     * @param referrer Referrer.
     * @return LP tokens minted.
     */
    function _swapDeposit(
        ICamelotV2Router router,
        ICamelotPair pool,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        address referrer
    ) internal returns (uint256) {
        // Get reserves
        ReserveInfo memory reserves = _sortReservesStruct(pool, tokenIn);

        // Create parameter struct to avoid stack too deep error
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: reserves.reserveIn,
            saleTokenFeePerc: reserves.feePercent,
            tokenOut: opToken,
            reserveOut: reserves.reserveOut,
            referrer: referrer
        });

        // Balance assets using the reserves
        uint256[] memory balancedAmounts = _balanceAssetsInternal(params);

        // Deposit balanced amounts
        uint256 poolTokenAmount = _deposit(router, tokenIn, opToken, balancedAmounts[0], balancedAmounts[1]);

        return poolTokenAmount;
    }
    // end::_swapDeposit(ICamelotV2Router-ICamelotPair-IERC20-uint256-IERC20-address)[]

    // tag::_balanceAssets(ICamelotV2Router-ICamelotPair-uint256-IERC20-IERC20-address)[]
    /**
     * @notice Computes balanced deposit amounts by optionally swapping excess of sale token.
     * Overload taking a pool to derive reserves.
     * @param router Router.
     * @param pool Pair.
     * @param saleAmt Amount of sale/input token.
     * @param tokenIn Sale token.
     * @param tokenOut Opposing token.
     * @param referrer Referrer.
     * @return amounts [amountInToDeposit, amountOutToDeposit]
     */
    function _balanceAssets(
        ICamelotV2Router router,
        ICamelotPair pool,
        uint256 saleAmt,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address referrer
    ) internal returns (uint256[] memory amounts) {
        // Get reserves
        ReserveInfo memory reserves = _sortReservesStruct(pool, tokenIn);

        // Create parameter struct to avoid stack too deep error
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: reserves.reserveIn,
            saleTokenFeePerc: reserves.feePercent,
            tokenOut: tokenOut,
            reserveOut: reserves.reserveOut,
            referrer: referrer
        });

        // Use the helper with direct reserves
        return _balanceAssetsInternal(params);
    }
    // end::_balanceAssets(ICamelotV2Router-ICamelotPair-uint256-IERC20-IERC20-address)[]

    // tag::_balanceAssets(ICamelotV2Router-uint256-IERC20-uint256-uint256-IERC20-uint256-address)[]
    /**
     * @notice Computes balanced amounts given explicit reserves.
     * @param router Router.
     * @param saleAmt Amount of sale token.
     * @param tokenIn Sale token.
     * @param saleReserve Reserve of sale token.
     * @param saleTokenFeePerc Fee % for sale side.
     * @param tokenOut Opposing.
     * @param reserveOut Opposing reserve.
     * @param referrer Referrer.
     * @return amounts Balanced pair amounts ready for deposit.
     */
    function _balanceAssets(
        ICamelotV2Router router,
        uint256 saleAmt,
        IERC20 tokenIn,
        uint256 saleReserve,
        uint256 saleTokenFeePerc,
        IERC20 tokenOut,
        uint256 reserveOut,
        address referrer
    ) internal returns (uint256[] memory amounts) {
        // Package parameters to avoid stack too deep
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: saleReserve,
            saleTokenFeePerc: saleTokenFeePerc,
            tokenOut: tokenOut,
            reserveOut: reserveOut,
            referrer: referrer
        });

        return _balanceAssetsInternal(params);
    }
    // end::_balanceAssets(ICamelotV2Router-uint256-IERC20-uint256-uint256-IERC20-uint256-address)[]

    // tag::_balanceAssetsInternal(BalanceParams)[]
    /**
     * @dev Core impl for balancing: computes swap portion then performs the swap.
     * @param params Balance params.
     * @return amounts [keepForDeposit, swappedAmount]
     */
    function _balanceAssetsInternal(BalanceParams memory params) private returns (uint256[] memory amounts) {
        // Get amount of input token to be swapped
        uint256 swapAmountIn = _calculateSwapAmount(params.saleAmt, params.saleReserve, params.saleTokenFeePerc);

        amounts = new uint256[](2);
        amounts[0] = params.saleAmt - swapAmountIn;

        // Perform swap to get the second token
        amounts[1] = _swap(
            params.router,
            swapAmountIn,
            params.tokenIn,
            params.saleReserve,
            params.saleTokenFeePerc,
            params.tokenOut,
            params.reserveOut,
            params.referrer
        );

        return amounts;
    }
    // end::_balanceAssetsInternal(BalanceParams)[]

    // tag::_calculateSwapAmount(uint256-uint256-uint256)[]
    /**
     * @notice Pure calc of how much of the sale amount should be swapped for balanced deposit.
     * Delegates to ConstProdUtils._swapDepositSaleAmt.
     * @param saleAmt Total sale token input.
     * @param saleReserve Current reserve of sale token.
     * @param saleTokenFeePerc Fee percent.
     * @return Amount to swap (remainder kept for direct deposit).
     */
    function _calculateSwapAmount(uint256 saleAmt, uint256 saleReserve, uint256 saleTokenFeePerc)
        internal
        pure
        returns (uint256)
    {
        return ConstProdUtils._swapDepositSaleAmt(saleAmt, saleReserve, saleTokenFeePerc);
    }
    // end::_calculateSwapAmount(uint256-uint256-uint256)[]

    /* ---------------------------------------------------------------------- */
    /*                              Withdraw/Swap                             */
    /* ---------------------------------------------------------------------- */

    // tag::WithdrawSwapParams[]
    /**
     * @dev Internal struct for _withdrawSwapDirect to avoid stack depth.
     */
    struct WithdrawSwapParams {
        ICamelotPair pool;
        ICamelotV2Router router;
        uint256 amt;
        IERC20 tokenOut;
        IERC20 opToken;
        address referrer;
    }
    // end::WithdrawSwapParams[]

    // tag::_withdrawSwapDirect(ICamelotPair-ICamelotV2Router-uint256-IERC20-IERC20-address)[]
    /**
     * @notice Withdraws LP then swaps the non-target token to target, returning total in target token.
     * @param pool Pool/LP.
     * @param router Router for possible swap.
     * @param amt LP amount to withdraw.
     * @param tokenOut Desired final token.
     * @param opToken The other token in pair.
     * @param referrer Referrer.
     * @return amountOut Total received in tokenOut (direct + swapped proceeds).
     */
    function _withdrawSwapDirect(
        ICamelotPair pool,
        ICamelotV2Router router,
        uint256 amt,
        IERC20 tokenOut,
        IERC20 opToken,
        address referrer
    ) internal returns (uint256 amountOut) {
        // Create struct to avoid stack too deep
        WithdrawSwapParams memory params = WithdrawSwapParams({
            pool: pool, router: router, amt: amt, tokenOut: tokenOut, opToken: opToken, referrer: referrer
        });

        // Withdraw tokens from pool
        (uint256 amount0, uint256 amount1) = _withdrawDirect(params.pool, params.amt);

        // Determine which token is which
        (uint256 tokenOutWDAmt, uint256 saleTokenWDAmt) = _determineTokenAmounts(params, amount0, amount1);

        // Swap the other token to the target token and add to result
        uint256 proceedsAmount = _swapWithdrawnTokens(params, saleTokenWDAmt);
        amountOut = tokenOutWDAmt + proceedsAmount;
    }
    // end::_withdrawSwapDirect(ICamelotPair-ICamelotV2Router-uint256-IERC20-IERC20-address)[]

    // tag::_determineTokenAmounts(WithdrawSwapParams-uint256-uint256)[]
    /**
     * @dev Splits withdrawn amounts according to which is the target tokenOut.
     * @param params Withdraw params.
     * @param amount0 Withdrawn token0 amt.
     * @param amount1 Withdrawn token1 amt.
     * @return tokenOutAmount Amount of desired tokenOut.
     * @return saleTokenAmount Amount of the other (to be swapped).
     */
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
    // end::_determineTokenAmounts(WithdrawSwapParams-uint256-uint256)[]

    // tag::_swapWithdrawnTokens(WithdrawSwapParams-uint256)[]
    /**
     * @dev Swaps the sale/withdrawn other token into the target using router overload.
     * @param params Withdraw params.
     * @param saleTokenWDAmt Amount of sale token withdrawn.
     * @return Amount received from the swap.
     */
    function _swapWithdrawnTokens(WithdrawSwapParams memory params, uint256 saleTokenWDAmt) internal returns (uint256) {
        return params.router._swap(params.pool, saleTokenWDAmt, params.opToken, params.tokenOut, params.referrer);
    }
    // end::_swapWithdrawnTokens(WithdrawSwapParams-uint256)[]

// end::CamelotV2Service[]
}
