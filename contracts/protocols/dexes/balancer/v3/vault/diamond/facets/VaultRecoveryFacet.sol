// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {StorageSlotExtension} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";
import {
    TransientStorageHelpers,
    UintToAddressToBooleanMappingSlot
} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";

import {BasePoolMath} from "@balancer-labs/v3-vault/contracts/BasePoolMath.sol";
import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";
import {BalancerV3MultiTokenRepo} from "../BalancerV3MultiTokenRepo.sol";

/* -------------------------------------------------------------------------- */
/*                            VaultRecoveryFacet                              */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultRecoveryFacet
 * @notice Handles recovery mode liquidity removal.
 * @dev Implements removeLiquidityRecovery from IVaultExtension.
 *
 * Recovery mode allows proportional exits without relying on pool math,
 * enabling users to withdraw liquidity even if the pool is in a broken state.
 *
 * Key features:
 * - Proportional-only withdrawals based on BPT share
 * - No pool callbacks or hooks invoked
 * - Roundtrip fee protection if add liquidity was called in same tx
 * - Raw balances only (no rate scaling)
 */
contract VaultRecoveryFacet is BalancerV3VaultModifiers {
    using PackedTokenBalance for bytes32;
    using PoolConfigLib for PoolConfigBits;
    using FixedPoint for uint256;
    using StorageSlotExtension for *;
    using TransientStorageHelpers for *;

    /// @dev Struct to avoid stack-too-deep errors.
    struct RecoveryLocals {
        IERC20[] tokens;
        uint256 swapFeePercentage;
        uint256 numTokens;
        uint256[] swapFeeAmountsRaw;
        uint256[] balancesRaw;
        bool chargeRoundtripFee;
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Removes liquidity from a pool in recovery mode.
     * @dev Only allows proportional exits. Uses raw balances (no rate scaling).
     *
     * @param pool The pool address
     * @param from The address burning BPT
     * @param exactBptAmountIn Amount of BPT to burn
     * @param minAmountsOut Minimum amounts of each token to receive
     * @return amountsOutRaw Actual amounts received
     */
    function removeLiquidityRecovery(
        address pool,
        address from,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut
    )
        external
        onlyWhenUnlocked
        nonReentrant
        withInitializedPool(pool)
        onlyInRecoveryMode(pool)
        returns (uint256[] memory amountsOutRaw)
    {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        mapping(uint256 tokenIndex => bytes32 packedTokenBalance) storage poolTokenBalances = layout.poolTokenBalances[pool];

        RecoveryLocals memory locals;

        // Get tokens and balances
        locals.tokens = layout.poolTokens[pool];
        locals.numTokens = locals.tokens.length;
        locals.balancesRaw = new uint256[](locals.numTokens);

        for (uint256 i = 0; i < locals.numTokens; ++i) {
            locals.balancesRaw[i] = poolTokenBalances[i].getBalanceRaw();
        }

        // Compute proportional amounts out
        amountsOutRaw = BasePoolMath.computeProportionalAmountsOut(
            locals.balancesRaw,
            BalancerV3MultiTokenRepo._totalSupply(pool),
            exactBptAmountIn
        );

        // Check for roundtrip attack (add + remove in same tx)
        locals.swapFeeAmountsRaw = new uint256[](locals.numTokens);
        locals.chargeRoundtripFee = _addLiquidityCalled().tGet(_sessionIdSlot().tload(), pool);

        if (locals.chargeRoundtripFee) {
            locals.swapFeePercentage = layout.poolConfigBits[pool].getStaticSwapFeePercentage();
        }

        for (uint256 i = 0; i < locals.numTokens; ++i) {
            // Apply roundtrip fee if needed
            if (locals.chargeRoundtripFee) {
                locals.swapFeeAmountsRaw[i] = amountsOutRaw[i].mulUp(locals.swapFeePercentage);
                amountsOutRaw[i] -= locals.swapFeeAmountsRaw[i];
            }

            // Check minimum amounts
            if (amountsOutRaw[i] < minAmountsOut[i]) {
                revert AmountOutBelowMin(locals.tokens[i], amountsOutRaw[i], minAmountsOut[i]);
            }

            // Credit tokens to caller
            _supplyCredit(locals.tokens[i], amountsOutRaw[i]);

            // Update balance
            locals.balancesRaw[i] -= amountsOutRaw[i];
        }

        // Store new balances (raw only - no rate scaling in recovery mode)
        for (uint256 i = 0; i < locals.numTokens; ++i) {
            bytes32 packedBalance = poolTokenBalances[i];
            poolTokenBalances[i] = packedBalance.setBalanceRaw(locals.balancesRaw[i]);
        }

        // Check and spend allowance
        BalancerV3MultiTokenRepo._spendAllowance(pool, from, msg.sender, exactBptAmountIn);

        // Handle query context
        if (_isQueryContext()) {
            BalancerV3MultiTokenRepo._queryModeBalanceIncrease(pool, from, exactBptAmountIn);
        }

        // Burn BPT
        BalancerV3MultiTokenRepo._burn(pool, from, exactBptAmountIn);

        emit LiquidityRemoved(
            pool,
            from,
            RemoveLiquidityKind.PROPORTIONAL,
            BalancerV3MultiTokenRepo._totalSupply(pool),
            amountsOutRaw,
            locals.swapFeeAmountsRaw
        );
    }
}
