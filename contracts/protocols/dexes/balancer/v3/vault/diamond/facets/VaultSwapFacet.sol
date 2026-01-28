// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";
import {ScalingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {HooksConfigLib} from "@balancer-labs/v3-vault/contracts/lib/HooksConfigLib.sol";
import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";
import {PoolDataLib} from "@balancer-labs/v3-vault/contracts/lib/PoolDataLib.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                              VaultSwapFacet                                */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultSwapFacet
 * @notice Handles swap operations for the Balancer V3 Vault Diamond.
 * @dev Implements the swap() function from IVaultMain along with all
 * supporting internal logic: fee computation, hook callbacks, and
 * balance accounting.
 *
 * The swap flow:
 * 1. Load pool data (updating balances and yield fees)
 * 2. Call beforeSwap hook (if configured)
 * 3. Compute dynamic swap fee (if configured)
 * 4. Execute swap via pool's onSwap() callback
 * 5. Account deltas (debit tokenIn, credit tokenOut)
 * 6. Charge aggregate fees (protocol + creator)
 * 7. Update pool balances
 * 8. Call afterSwap hook (if configured)
 */
contract VaultSwapFacet is BalancerV3VaultModifiers {
    using PackedTokenBalance for bytes32;
    using FixedPoint for *;
    using SafeCast for *;
    using PoolConfigLib for PoolConfigBits;
    using HooksConfigLib for PoolConfigBits;
    using ScalingHelpers for *;
    using PoolDataLib for PoolData;

    /* ========================================================================== */
    /*                              INTERNAL STRUCTS                              */
    /* ========================================================================== */

    /// @dev Auxiliary struct to prevent stack-too-deep issues inside `_swap`.
    struct SwapInternalLocals {
        uint256 totalSwapFeeAmountScaled18;
        uint256 totalSwapFeeAmountRaw;
        uint256 aggregateFeeAmountRaw;
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Executes a swap operation on an initialized pool.
     * @dev This is the main entry point for swaps. It:
     * - Validates inputs
     * - Loads and updates pool data
     * - Calls before/after swap hooks if configured
     * - Executes the core swap via the pool's onSwap callback
     * - Manages fee accounting
     *
     * @param vaultSwapParams The swap parameters
     * @return amountCalculated The computed amount (out for ExactIn, in for ExactOut)
     * @return amountIn The final amount of tokenIn
     * @return amountOut The final amount of tokenOut
     */
    function swap(
        VaultSwapParams memory vaultSwapParams
    )
        external
        onlyWhenUnlocked
        withInitializedPool(vaultSwapParams.pool)
        returns (uint256 amountCalculated, uint256 amountIn, uint256 amountOut)
    {
        _ensureUnpaused(vaultSwapParams.pool);

        if (vaultSwapParams.amountGivenRaw == 0) {
            revert AmountGivenZero();
        }

        if (vaultSwapParams.tokenIn == vaultSwapParams.tokenOut) {
            revert CannotSwapSameToken();
        }

        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        // Load pool data updating yield fees (non-reentrant internally).
        PoolData memory poolData = _loadPoolDataUpdatingBalancesAndYieldFees(vaultSwapParams.pool, Rounding.ROUND_DOWN);
        SwapState memory swapState = _loadSwapState(vaultSwapParams, poolData);
        PoolSwapParams memory poolSwapParams = _buildPoolSwapParams(vaultSwapParams, swapState, poolData);

        if (poolData.poolConfigBits.shouldCallBeforeSwap()) {
            HooksConfigLib.callBeforeSwapHook(
                poolSwapParams,
                vaultSwapParams.pool,
                layout.hooksContracts[vaultSwapParams.pool]
            );

            // Reload after hook may have altered balances/rates
            poolData.reloadBalancesAndRates(layout.poolTokenBalances[vaultSwapParams.pool], Rounding.ROUND_DOWN);
            swapState.amountGivenScaled18 = _computeAmountGivenScaled18(vaultSwapParams, poolData, swapState);
            poolSwapParams = _buildPoolSwapParams(vaultSwapParams, swapState, poolData);
        }

        if (poolData.poolConfigBits.shouldCallComputeDynamicSwapFee()) {
            swapState.swapFeePercentage = HooksConfigLib.callComputeDynamicSwapFeeHook(
                poolSwapParams,
                vaultSwapParams.pool,
                swapState.swapFeePercentage,
                layout.hooksContracts[vaultSwapParams.pool]
            );
        }

        // Execute the core swap (non-reentrant, updates accounting).
        uint256 amountCalculatedScaled18;
        (amountCalculated, amountCalculatedScaled18, amountIn, amountOut) = _swap(
            vaultSwapParams,
            swapState,
            poolData,
            poolSwapParams
        );

        if (poolData.poolConfigBits.shouldCallAfterSwap()) {
            IHooks hooksContract = layout.hooksContracts[vaultSwapParams.pool];

            amountCalculated = poolData.poolConfigBits.callAfterSwapHook(
                amountCalculatedScaled18,
                amountCalculated,
                msg.sender,
                vaultSwapParams,
                swapState,
                poolData,
                hooksContract
            );
        }

        if (vaultSwapParams.kind == SwapKind.EXACT_IN) {
            amountOut = amountCalculated;
        } else {
            amountIn = amountCalculated;
        }
    }

    /* ========================================================================== */
    /*                          VIEW FUNCTIONS                                    */
    /* ========================================================================== */

    /**
     * @notice Returns the token count and index for a specific token in a pool.
     * @param pool The pool address
     * @param token The token to find
     * @return tokenCount Total number of tokens in the pool
     * @return index Index of the specified token
     */
    function getPoolTokenCountAndIndexOfToken(
        address pool,
        IERC20 token
    ) external view withRegisteredPool(pool) returns (uint256, uint256) {
        IERC20[] storage poolTokens = BalancerV3VaultStorageRepo._poolTokens(pool);

        IERC20[] memory tokens = poolTokens;
        uint256 index = _findTokenIndex(tokens, token);

        return (tokens.length, index);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _loadSwapState(
        VaultSwapParams memory vaultSwapParams,
        PoolData memory poolData
    ) internal pure returns (SwapState memory swapState) {
        swapState.indexIn = _findTokenIndex(poolData.tokens, vaultSwapParams.tokenIn);
        swapState.indexOut = _findTokenIndex(poolData.tokens, vaultSwapParams.tokenOut);
        swapState.amountGivenScaled18 = _computeAmountGivenScaled18(vaultSwapParams, poolData, swapState);
        swapState.swapFeePercentage = poolData.poolConfigBits.getStaticSwapFeePercentage();
    }

    function _buildPoolSwapParams(
        VaultSwapParams memory vaultSwapParams,
        SwapState memory swapState,
        PoolData memory poolData
    ) internal view returns (PoolSwapParams memory) {
        return PoolSwapParams({
            kind: vaultSwapParams.kind,
            amountGivenScaled18: swapState.amountGivenScaled18,
            balancesScaled18: poolData.balancesLiveScaled18,
            indexIn: swapState.indexIn,
            indexOut: swapState.indexOut,
            router: msg.sender,
            userData: vaultSwapParams.userData
        });
    }

    function _computeAmountGivenScaled18(
        VaultSwapParams memory vaultSwapParams,
        PoolData memory poolData,
        SwapState memory swapState
    ) internal pure returns (uint256) {
        return
            vaultSwapParams.kind == SwapKind.EXACT_IN
                ? vaultSwapParams.amountGivenRaw.toScaled18ApplyRateRoundDown(
                    poolData.decimalScalingFactors[swapState.indexIn],
                    poolData.tokenRates[swapState.indexIn]
                )
                : vaultSwapParams.amountGivenRaw.toScaled18ApplyRateRoundUp(
                    poolData.decimalScalingFactors[swapState.indexOut],
                    poolData.tokenRates[swapState.indexOut].computeRateRoundUp()
                );
    }

    /**
     * @dev Core swap logic - non-reentrant, updates all accounting.
     */
    function _swap(
        VaultSwapParams memory vaultSwapParams,
        SwapState memory swapState,
        PoolData memory poolData,
        PoolSwapParams memory poolSwapParams
    )
        internal
        nonReentrant
        returns (
            uint256 amountCalculatedRaw,
            uint256 amountCalculatedScaled18,
            uint256 amountInRaw,
            uint256 amountOutRaw
        )
    {
        SwapInternalLocals memory locals;

        if (vaultSwapParams.kind == SwapKind.EXACT_IN) {
            locals.totalSwapFeeAmountScaled18 = poolSwapParams.amountGivenScaled18.mulUp(swapState.swapFeePercentage);
            poolSwapParams.amountGivenScaled18 -= locals.totalSwapFeeAmountScaled18;
        }

        _ensureValidSwapAmount(poolSwapParams.amountGivenScaled18);

        amountCalculatedScaled18 = IBasePool(vaultSwapParams.pool).onSwap(poolSwapParams);
        _ensureValidSwapAmount(amountCalculatedScaled18);

        if (vaultSwapParams.kind == SwapKind.EXACT_IN) {
            poolSwapParams.amountGivenScaled18 = swapState.amountGivenScaled18;

            amountCalculatedRaw = amountCalculatedScaled18.toRawUndoRateRoundDown(
                poolData.decimalScalingFactors[swapState.indexOut],
                poolData.tokenRates[swapState.indexOut].computeRateRoundUp()
            );

            (amountInRaw, amountOutRaw) = (vaultSwapParams.amountGivenRaw, amountCalculatedRaw);

            if (amountOutRaw < vaultSwapParams.limitRaw) {
                revert SwapLimit(amountOutRaw, vaultSwapParams.limitRaw);
            }
        } else {
            locals.totalSwapFeeAmountScaled18 = amountCalculatedScaled18.mulDivUp(
                swapState.swapFeePercentage,
                swapState.swapFeePercentage.complement()
            );

            amountCalculatedScaled18 += locals.totalSwapFeeAmountScaled18;

            amountCalculatedRaw = amountCalculatedScaled18.toRawUndoRateRoundUp(
                poolData.decimalScalingFactors[swapState.indexIn],
                poolData.tokenRates[swapState.indexIn]
            );

            (amountInRaw, amountOutRaw) = (amountCalculatedRaw, vaultSwapParams.amountGivenRaw);

            if (amountInRaw > vaultSwapParams.limitRaw) {
                revert SwapLimit(amountInRaw, vaultSwapParams.limitRaw);
            }
        }

        // 3) Deltas
        _takeDebt(vaultSwapParams.tokenIn, amountInRaw);
        _supplyCredit(vaultSwapParams.tokenOut, amountOutRaw);

        // 4) Fees
        (locals.totalSwapFeeAmountRaw, locals.aggregateFeeAmountRaw) = _computeAndChargeAggregateSwapFees(
            poolData,
            locals.totalSwapFeeAmountScaled18,
            vaultSwapParams.pool,
            vaultSwapParams.tokenIn,
            swapState.indexIn
        );

        // 5) Pool balances
        poolData.updateRawAndLiveBalance(
            swapState.indexIn,
            poolData.balancesRaw[swapState.indexIn] + amountInRaw - locals.aggregateFeeAmountRaw,
            Rounding.ROUND_DOWN
        );
        poolData.updateRawAndLiveBalance(
            swapState.indexOut,
            poolData.balancesRaw[swapState.indexOut] - amountOutRaw,
            Rounding.ROUND_DOWN
        );

        // 6) Store pool balances
        mapping(uint256 tokenIndex => bytes32 packedTokenBalance) storage poolBalances =
            BalancerV3VaultStorageRepo._poolTokenBalances(vaultSwapParams.pool);
        poolBalances[swapState.indexIn] = PackedTokenBalance.toPackedBalance(
            poolData.balancesRaw[swapState.indexIn],
            poolData.balancesLiveScaled18[swapState.indexIn]
        );
        poolBalances[swapState.indexOut] = PackedTokenBalance.toPackedBalance(
            poolData.balancesRaw[swapState.indexOut],
            poolData.balancesLiveScaled18[swapState.indexOut]
        );

        // 7) Event
        emit Swap(
            vaultSwapParams.pool,
            vaultSwapParams.tokenIn,
            vaultSwapParams.tokenOut,
            amountInRaw,
            amountOutRaw,
            swapState.swapFeePercentage,
            locals.totalSwapFeeAmountRaw
        );
    }

    /**
     * @dev Computes and charges aggregate swap fees (protocol + pool creator).
     */
    function _computeAndChargeAggregateSwapFees(
        PoolData memory poolData,
        uint256 totalSwapFeeAmountScaled18,
        address pool,
        IERC20 token,
        uint256 index
    ) internal returns (uint256 totalSwapFeeAmountRaw, uint256 aggregateSwapFeeAmountRaw) {
        if (totalSwapFeeAmountScaled18 > 0) {
            totalSwapFeeAmountRaw = totalSwapFeeAmountScaled18.toRawUndoRateRoundDown(
                poolData.decimalScalingFactors[index],
                poolData.tokenRates[index]
            );

            if (poolData.poolConfigBits.isPoolInRecoveryMode() == false) {
                uint256 aggregateSwapFeePercentage = poolData.poolConfigBits.getAggregateSwapFeePercentage();

                aggregateSwapFeeAmountRaw = totalSwapFeeAmountRaw.mulDown(aggregateSwapFeePercentage);

                if (aggregateSwapFeeAmountRaw > totalSwapFeeAmountRaw) {
                    revert ProtocolFeesExceedTotalCollected();
                }

                bytes32 currentPackedBalance = BalancerV3VaultStorageRepo._getAggregateFeeAmount(pool, token);
                BalancerV3VaultStorageRepo._setAggregateFeeAmount(
                    pool,
                    token,
                    currentPackedBalance.setBalanceRaw(
                        currentPackedBalance.getBalanceRaw() + aggregateSwapFeeAmountRaw
                    )
                );
            }
        }
    }

    /**
     * @dev Enforces minimum swap amount to prevent rounding exploitation.
     */
    function _ensureValidSwapAmount(uint256 tradeAmount) internal view {
        if (tradeAmount < BalancerV3VaultStorageRepo._minimumTradeAmount()) {
            revert TradeAmountTooSmall();
        }
    }

    /**
     * @dev Enforces minimum trade amount, but allows zero for single-token liquidity operations.
     */
    function _ensureValidTradeAmount(uint256 tradeAmount) internal view {
        if (tradeAmount != 0) {
            _ensureValidSwapAmount(tradeAmount);
        }
    }
}
