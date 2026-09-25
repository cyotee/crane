// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                  Indexedex                                 */
/* -------------------------------------------------------------------------- */

import {IStandardExchangeErrors} from "./IStandardExchangeErrors.sol";
/**
 * @custom:interfaceid 0xba39dfe2
 */

interface IStandardExchangeOut is IStandardExchangeErrors {
    struct OutArgs {
        IERC20 tokenIn;
        uint256 maxAmountIn;
        IERC20 tokenOut;
        uint256 amountOut;
        address recipient;
        bool pretransferred;
        uint256 deadline;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Events                                 */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                                 Errors                                 */
    /* ---------------------------------------------------------------------- */

    error ExchangeOutNotAvailable();

    /* ---------------------------------------------------------------------- */
    /*                                Functions                               */
    /* ---------------------------------------------------------------------- */

    /**
     * @param tokenIn The token provided to the vault for an exchange.
     * @param tokenOut The token the caller wishes to receive in exchange for `tokenIn`.
     * @param amountOut The amount of `tokenOut` the caller wishes to receive in exchange for `tokenIn`.
     * @return amountIn The amount of `tokenIn` the caller will need to provide in exchange for `amountOut` of `tokenOut`.
     * @custom:selector 0xdb149bc5
     */
    function previewExchangeOut(IERC20 tokenIn, IERC20 tokenOut, uint256 amountOut)
        external
        view
        returns (uint256 amountIn);

    /**
     * @notice Exact-output pretransfer refunds only `min(unrecorded balance, maxAmountIn) - used` to `msg.sender`. False-flag exact-output pulls quoted used and refunds nothing.
     * @param tokenIn The token provided to the vault for an exchange.
     * @param maxAmountIn The maximum amount of `tokenIn` the caller is willing to provide.
     * @param tokenOut The token the caller wishes to receive in exchange for `tokenIn`.
     * @param amountOut The amount of `tokenOut` the caller wishes to receive in exchange for `tokenIn`.
     * @param recipient The address to receive the `tokenOut` tokens.
     * @param pretransferred Integrating-contract flag only. The caller must transfer and consume atomically; staged use is at integrator risk with no ownership or timing guarantee. Callers with no bytecode revert `EOAPretransferNotAllowed()`. Unrecorded balance across transactions may be consumed by the next contract caller. Booked holder backing is never pretransfer credit. Exact-output refunds only `min(unrecorded balance, maxAmountIn) - used`. Amounts above `maxAmountIn` are never refunded. False-flag exact-output pulls quoted used and refunds nothing.
     * @return amountIn The amount of `tokenIn` the caller has provided in exchange for `amountOut` of `tokenOut`.
     * @custom:selector 0x612d4427
     */
    function exchangeOut(
        IERC20 tokenIn,
        uint256 maxAmountIn,
        IERC20 tokenOut,
        uint256 amountOut,
        address recipient,
        bool pretransferred,
        uint256 deadline
    ) external returns (uint256 amountIn);
}
