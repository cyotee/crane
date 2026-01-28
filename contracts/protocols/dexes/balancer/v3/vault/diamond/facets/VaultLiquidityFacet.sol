// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IPoolLiquidity} from "@balancer-labs/v3-interfaces/contracts/vault/IPoolLiquidity.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";
import {ScalingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import {CastingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {TransientStorageHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";
import {StorageSlotExtension} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";

import {HooksConfigLib} from "@balancer-labs/v3-vault/contracts/lib/HooksConfigLib.sol";
import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";
import {PoolDataLib} from "@balancer-labs/v3-vault/contracts/lib/PoolDataLib.sol";
import {BasePoolMath} from "@balancer-labs/v3-vault/contracts/BasePoolMath.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";
import {BalancerV3MultiTokenRepo} from "../BalancerV3MultiTokenRepo.sol";

/* -------------------------------------------------------------------------- */
/*                            VaultLiquidityFacet                             */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultLiquidityFacet
 * @notice Handles addLiquidity and removeLiquidity operations.
 * @dev Implements the liquidity functions from IVaultMain with full hook support.
 *
 * Supported AddLiquidityKind:
 * - PROPORTIONAL: Add liquidity with exact BPT out
 * - UNBALANCED: Add with arbitrary token amounts
 * - SINGLE_TOKEN_EXACT_OUT: Add single token for exact BPT out
 * - DONATION: Add tokens without receiving BPT
 * - CUSTOM: Pool-defined custom logic
 *
 * Supported RemoveLiquidityKind:
 * - PROPORTIONAL: Remove with exact BPT in
 * - SINGLE_TOKEN_EXACT_IN: Burn BPT for single token
 * - SINGLE_TOKEN_EXACT_OUT: Exact amount of single token
 * - CUSTOM: Pool-defined custom logic
 */
contract VaultLiquidityFacet is BalancerV3VaultModifiers {
    using PackedTokenBalance for bytes32;
    using FixedPoint for *;
    using SafeCast for *;
    using CastingHelpers for uint256[];
    using PoolConfigLib for PoolConfigBits;
    using HooksConfigLib for PoolConfigBits;
    using ScalingHelpers for *;
    using TransientStorageHelpers for *;
    using StorageSlotExtension for *;
    using PoolDataLib for PoolData;
    using InputHelpers for uint256;

    /* ========================================================================== */
    /*                              INTERNAL STRUCTS                              */
    /* ========================================================================== */

    struct LiquidityLocals {
        uint256 numTokens;
        uint256 aggregateSwapFeeAmountRaw;
        uint256 tokenIndex;
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Adds liquidity to a pool.
     * @param params AddLiquidity parameters including pool, amounts, and kind
     * @return amountsIn Actual amounts of each token added
     * @return bptAmountOut Amount of BPT minted
     * @return returnData Custom return data from pool (for CUSTOM kind)
     */
    function addLiquidity(
        AddLiquidityParams memory params
    )
        external
        onlyWhenUnlocked
        withInitializedPool(params.pool)
        returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData)
    {
        _ensureUnpaused(params.pool);

        // Record that add liquidity was called in this session (for round-trip fee)
        _addLiquidityCalled().tSet(_sessionIdSlot().tload(), params.pool, true);

        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        PoolData memory poolData = _loadPoolDataUpdatingBalancesAndYieldFees(params.pool, Rounding.ROUND_UP);
        InputHelpers.ensureInputLengthMatch(poolData.tokens.length, params.maxAmountsIn.length);

        uint256[] memory maxAmountsInScaled18 = params.maxAmountsIn.copyToScaled18ApplyRateRoundDownArray(
            poolData.decimalScalingFactors,
            poolData.tokenRates
        );

        if (poolData.poolConfigBits.shouldCallBeforeAddLiquidity()) {
            HooksConfigLib.callBeforeAddLiquidityHook(
                msg.sender,
                maxAmountsInScaled18,
                params,
                poolData,
                layout.hooksContracts[params.pool]
            );

            poolData.reloadBalancesAndRates(layout.poolTokenBalances[params.pool], Rounding.ROUND_UP);
            maxAmountsInScaled18 = params.maxAmountsIn.copyToScaled18ApplyRateRoundDownArray(
                poolData.decimalScalingFactors,
                poolData.tokenRates
            );
        }

        uint256[] memory amountsInScaled18;
        (amountsIn, amountsInScaled18, bptAmountOut, returnData) = _addLiquidity(
            poolData,
            params,
            maxAmountsInScaled18
        );

        if (poolData.poolConfigBits.shouldCallAfterAddLiquidity()) {
            IHooks hooksContract = layout.hooksContracts[params.pool];

            amountsIn = poolData.poolConfigBits.callAfterAddLiquidityHook(
                msg.sender,
                amountsInScaled18,
                amountsIn,
                bptAmountOut,
                params,
                poolData,
                hooksContract
            );
        }
    }

    /**
     * @notice Removes liquidity from a pool.
     * @param params RemoveLiquidity parameters
     * @return bptAmountIn Amount of BPT burned
     * @return amountsOut Actual amounts of each token received
     * @return returnData Custom return data from pool (for CUSTOM kind)
     */
    function removeLiquidity(
        RemoveLiquidityParams memory params
    )
        external
        onlyWhenUnlocked
        withInitializedPool(params.pool)
        returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData)
    {
        _ensureUnpaused(params.pool);

        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        PoolData memory poolData = _loadPoolDataUpdatingBalancesAndYieldFees(params.pool, Rounding.ROUND_DOWN);
        InputHelpers.ensureInputLengthMatch(poolData.tokens.length, params.minAmountsOut.length);

        uint256[] memory minAmountsOutScaled18 = params.minAmountsOut.copyToScaled18ApplyRateRoundUpArray(
            poolData.decimalScalingFactors,
            poolData.tokenRates
        );

        if (poolData.poolConfigBits.shouldCallBeforeRemoveLiquidity()) {
            HooksConfigLib.callBeforeRemoveLiquidityHook(
                minAmountsOutScaled18,
                msg.sender,
                params,
                poolData,
                layout.hooksContracts[params.pool]
            );

            poolData.reloadBalancesAndRates(layout.poolTokenBalances[params.pool], Rounding.ROUND_DOWN);
            minAmountsOutScaled18 = params.minAmountsOut.copyToScaled18ApplyRateRoundUpArray(
                poolData.decimalScalingFactors,
                poolData.tokenRates
            );
        }

        uint256[] memory amountsOutScaled18;
        (bptAmountIn, amountsOut, amountsOutScaled18, returnData) = _removeLiquidity(
            poolData,
            params,
            minAmountsOutScaled18
        );

        if (poolData.poolConfigBits.shouldCallAfterRemoveLiquidity()) {
            IHooks hooksContract = layout.hooksContracts[params.pool];

            amountsOut = poolData.poolConfigBits.callAfterRemoveLiquidityHook(
                msg.sender,
                amountsOutScaled18,
                amountsOut,
                bptAmountIn,
                params,
                poolData,
                hooksContract
            );
        }
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _addLiquidity(
        PoolData memory poolData,
        AddLiquidityParams memory params,
        uint256[] memory maxAmountsInScaled18
    )
        internal
        nonReentrant
        returns (
            uint256[] memory amountsInRaw,
            uint256[] memory amountsInScaled18,
            uint256 bptAmountOut,
            bytes memory returnData
        )
    {
        LiquidityLocals memory locals;
        locals.numTokens = poolData.tokens.length;
        amountsInRaw = new uint256[](locals.numTokens);
        uint256[] memory swapFeeAmounts;

        if (params.kind == AddLiquidityKind.PROPORTIONAL) {
            bptAmountOut = params.minBptAmountOut;
            swapFeeAmounts = new uint256[](locals.numTokens);

            amountsInScaled18 = BasePoolMath.computeProportionalAmountsIn(
                poolData.balancesLiveScaled18,
                BalancerV3MultiTokenRepo._totalSupply(params.pool),
                bptAmountOut
            );
        } else if (params.kind == AddLiquidityKind.DONATION) {
            poolData.poolConfigBits.requireDonationEnabled();

            swapFeeAmounts = new uint256[](maxAmountsInScaled18.length);
            bptAmountOut = 0;
            amountsInScaled18 = maxAmountsInScaled18;
        } else if (params.kind == AddLiquidityKind.UNBALANCED) {
            poolData.poolConfigBits.requireUnbalancedLiquidityEnabled();

            amountsInScaled18 = maxAmountsInScaled18;
            ScalingHelpers.copyToArray(params.maxAmountsIn, amountsInRaw);

            (bptAmountOut, swapFeeAmounts) = BasePoolMath.computeAddLiquidityUnbalanced(
                poolData.balancesLiveScaled18,
                maxAmountsInScaled18,
                BalancerV3MultiTokenRepo._totalSupply(params.pool),
                poolData.poolConfigBits.getStaticSwapFeePercentage(),
                IBasePool(params.pool)
            );
        } else if (params.kind == AddLiquidityKind.SINGLE_TOKEN_EXACT_OUT) {
            poolData.poolConfigBits.requireUnbalancedLiquidityEnabled();

            bptAmountOut = params.minBptAmountOut;
            locals.tokenIndex = InputHelpers.getSingleInputIndex(maxAmountsInScaled18);

            amountsInScaled18 = maxAmountsInScaled18;
            (amountsInScaled18[locals.tokenIndex], swapFeeAmounts) = BasePoolMath
                .computeAddLiquiditySingleTokenExactOut(
                    poolData.balancesLiveScaled18,
                    locals.tokenIndex,
                    bptAmountOut,
                    BalancerV3MultiTokenRepo._totalSupply(params.pool),
                    poolData.poolConfigBits.getStaticSwapFeePercentage(),
                    IBasePool(params.pool)
                );
        } else if (params.kind == AddLiquidityKind.CUSTOM) {
            poolData.poolConfigBits.requireAddLiquidityCustomEnabled();

            (amountsInScaled18, bptAmountOut, swapFeeAmounts, returnData) = IPoolLiquidity(params.pool)
                .onAddLiquidityCustom(
                    msg.sender,
                    maxAmountsInScaled18,
                    params.minBptAmountOut,
                    poolData.balancesLiveScaled18,
                    params.userData
                );
        } else {
            revert InvalidAddLiquidityKind();
        }

        if (bptAmountOut < params.minBptAmountOut) {
            revert BptAmountOutBelowMin(bptAmountOut, params.minBptAmountOut);
        }

        _ensureValidTradeAmount(bptAmountOut);

        for (uint256 i = 0; i < locals.numTokens; ++i) {
            uint256 amountInRaw;

            {
                uint256 amountInScaled18 = amountsInScaled18[i];
                _ensureValidTradeAmount(amountInScaled18);

                if (amountsInRaw[i] == 0) {
                    amountInRaw = amountInScaled18.toRawUndoRateRoundUp(
                        poolData.decimalScalingFactors[i],
                        poolData.tokenRates[i]
                    );
                    amountsInRaw[i] = amountInRaw;
                } else {
                    amountInRaw = amountsInRaw[i];
                }
            }

            IERC20 token = poolData.tokens[i];

            if (amountInRaw > params.maxAmountsIn[i]) {
                revert AmountInAboveMax(token, amountInRaw, params.maxAmountsIn[i]);
            }

            _takeDebt(token, amountInRaw);

            (swapFeeAmounts[i], locals.aggregateSwapFeeAmountRaw) = _computeAndChargeAggregateSwapFees(
                poolData,
                swapFeeAmounts[i],
                params.pool,
                token,
                i
            );

            poolData.updateRawAndLiveBalance(
                i,
                poolData.balancesRaw[i] + amountInRaw - locals.aggregateSwapFeeAmountRaw,
                Rounding.ROUND_DOWN
            );
        }

        _writePoolBalancesToStorage(params.pool, poolData);
        BalancerV3MultiTokenRepo._mint(params.pool, params.to, bptAmountOut);

        emit LiquidityAdded(
            params.pool,
            params.to,
            params.kind,
            BalancerV3MultiTokenRepo._totalSupply(params.pool),
            amountsInRaw,
            swapFeeAmounts
        );
    }

    function _removeLiquidity(
        PoolData memory poolData,
        RemoveLiquidityParams memory params,
        uint256[] memory minAmountsOutScaled18
    )
        internal
        nonReentrant
        returns (
            uint256 bptAmountIn,
            uint256[] memory amountsOutRaw,
            uint256[] memory amountsOutScaled18,
            bytes memory returnData
        )
    {
        LiquidityLocals memory locals;
        locals.numTokens = poolData.tokens.length;
        amountsOutRaw = new uint256[](locals.numTokens);
        uint256[] memory swapFeeAmounts;

        if (params.kind == RemoveLiquidityKind.PROPORTIONAL) {
            bptAmountIn = params.maxBptAmountIn;
            swapFeeAmounts = new uint256[](locals.numTokens);
            amountsOutScaled18 = BasePoolMath.computeProportionalAmountsOut(
                poolData.balancesLiveScaled18,
                BalancerV3MultiTokenRepo._totalSupply(params.pool),
                bptAmountIn
            );

            // Round-trip fee if add liquidity was called in this session
            if (_addLiquidityCalled().tGet(_sessionIdSlot().tload(), params.pool)) {
                uint256 swapFeePercentage = poolData.poolConfigBits.getStaticSwapFeePercentage();
                for (uint256 i = 0; i < locals.numTokens; ++i) {
                    swapFeeAmounts[i] = amountsOutScaled18[i].mulUp(swapFeePercentage);
                    amountsOutScaled18[i] -= swapFeeAmounts[i];
                }
            }
        } else if (params.kind == RemoveLiquidityKind.SINGLE_TOKEN_EXACT_IN) {
            poolData.poolConfigBits.requireUnbalancedLiquidityEnabled();
            bptAmountIn = params.maxBptAmountIn;
            amountsOutScaled18 = minAmountsOutScaled18;
            locals.tokenIndex = InputHelpers.getSingleInputIndex(params.minAmountsOut);

            (amountsOutScaled18[locals.tokenIndex], swapFeeAmounts) = BasePoolMath
                .computeRemoveLiquiditySingleTokenExactIn(
                    poolData.balancesLiveScaled18,
                    locals.tokenIndex,
                    bptAmountIn,
                    BalancerV3MultiTokenRepo._totalSupply(params.pool),
                    poolData.poolConfigBits.getStaticSwapFeePercentage(),
                    IBasePool(params.pool)
                );
        } else if (params.kind == RemoveLiquidityKind.SINGLE_TOKEN_EXACT_OUT) {
            poolData.poolConfigBits.requireUnbalancedLiquidityEnabled();
            amountsOutScaled18 = minAmountsOutScaled18;
            locals.tokenIndex = InputHelpers.getSingleInputIndex(params.minAmountsOut);
            amountsOutRaw[locals.tokenIndex] = params.minAmountsOut[locals.tokenIndex];

            (bptAmountIn, swapFeeAmounts) = BasePoolMath.computeRemoveLiquiditySingleTokenExactOut(
                poolData.balancesLiveScaled18,
                locals.tokenIndex,
                amountsOutScaled18[locals.tokenIndex],
                BalancerV3MultiTokenRepo._totalSupply(params.pool),
                poolData.poolConfigBits.getStaticSwapFeePercentage(),
                IBasePool(params.pool)
            );
        } else if (params.kind == RemoveLiquidityKind.CUSTOM) {
            poolData.poolConfigBits.requireRemoveLiquidityCustomEnabled();
            (bptAmountIn, amountsOutScaled18, swapFeeAmounts, returnData) = IPoolLiquidity(params.pool)
                .onRemoveLiquidityCustom(
                    msg.sender,
                    params.maxBptAmountIn,
                    minAmountsOutScaled18,
                    poolData.balancesLiveScaled18,
                    params.userData
                );
        } else {
            revert InvalidRemoveLiquidityKind();
        }

        if (bptAmountIn > params.maxBptAmountIn) {
            revert BptAmountInAboveMax(bptAmountIn, params.maxBptAmountIn);
        }

        _ensureValidTradeAmount(bptAmountIn);

        for (uint256 i = 0; i < locals.numTokens; ++i) {
            uint256 amountOutRaw;

            {
                uint256 amountOutScaled18 = amountsOutScaled18[i];
                _ensureValidTradeAmount(amountOutScaled18);

                if (amountsOutRaw[i] == 0) {
                    amountOutRaw = amountOutScaled18.toRawUndoRateRoundDown(
                        poolData.decimalScalingFactors[i],
                        poolData.tokenRates[i]
                    );
                    amountsOutRaw[i] = amountOutRaw;
                } else {
                    amountOutRaw = amountsOutRaw[i];
                }
            }

            IERC20 token = poolData.tokens[i];
            if (amountOutRaw < params.minAmountsOut[i]) {
                revert AmountOutBelowMin(token, amountOutRaw, params.minAmountsOut[i]);
            }

            _supplyCredit(token, amountOutRaw);

            (swapFeeAmounts[i], locals.aggregateSwapFeeAmountRaw) = _computeAndChargeAggregateSwapFees(
                poolData,
                swapFeeAmounts[i],
                params.pool,
                token,
                i
            );

            poolData.updateRawAndLiveBalance(
                i,
                poolData.balancesRaw[i] - (amountOutRaw + locals.aggregateSwapFeeAmountRaw),
                Rounding.ROUND_DOWN
            );
        }

        _writePoolBalancesToStorage(params.pool, poolData);

        BalancerV3MultiTokenRepo._spendAllowance(params.pool, params.from, msg.sender, bptAmountIn);

        if (_isQueryContext()) {
            BalancerV3MultiTokenRepo._queryModeBalanceIncrease(params.pool, params.from, bptAmountIn);
        }

        BalancerV3MultiTokenRepo._burn(params.pool, params.from, bptAmountIn);

        emit LiquidityRemoved(
            params.pool,
            params.from,
            params.kind,
            BalancerV3MultiTokenRepo._totalSupply(params.pool),
            amountsOutRaw,
            swapFeeAmounts
        );
    }

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

    function _ensureValidTradeAmount(uint256 tradeAmount) internal view {
        if (tradeAmount != 0 && tradeAmount < BalancerV3VaultStorageRepo._minimumTradeAmount()) {
            revert TradeAmountTooSmall();
        }
    }
}
