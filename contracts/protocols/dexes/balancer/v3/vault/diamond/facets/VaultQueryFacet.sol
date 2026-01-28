// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";

import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";
import {VaultStateLib, VaultStateBits} from "@balancer-labs/v3-vault/contracts/lib/VaultStateLib.sol";
import {PoolDataLib} from "@balancer-labs/v3-vault/contracts/lib/PoolDataLib.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";
import {BalancerV3MultiTokenRepo} from "../BalancerV3MultiTokenRepo.sol";

/* -------------------------------------------------------------------------- */
/*                             VaultQueryFacet                                */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultQueryFacet
 * @notice Provides view functions for querying vault and pool state.
 * @dev Implements query functions from IVaultExtension for pool data access.
 *
 * Key queries:
 * - Pool registration and initialization state
 * - Pool tokens and balances
 * - Pool configuration and rates
 * - Vault state (pausing, fees, etc.)
 */
contract VaultQueryFacet is BalancerV3VaultModifiers {
    using PackedTokenBalance for bytes32;
    using PoolConfigLib for PoolConfigBits;
    using VaultStateLib for VaultStateBits;
    using PoolDataLib for PoolData;

    /* ========================================================================== */
    /*                          POOL STATE QUERIES                                */
    /* ========================================================================== */

    /**
     * @notice Check if a pool is registered with the vault.
     * @param pool The pool address
     * @return True if registered
     */
    function isPoolRegistered(address pool) external view returns (bool) {
        return _isPoolRegistered(pool);
    }

    /**
     * @notice Check if a pool is initialized (has received initial liquidity).
     * @param pool The pool address
     * @return True if initialized
     */
    function isPoolInitialized(address pool) external view returns (bool) {
        return _isPoolInitialized(pool);
    }

    /**
     * @notice Check if a pool is paused.
     * @param pool The pool address
     * @return True if paused
     */
    function isPoolPaused(address pool) external view returns (bool) {
        return _isPoolPaused(pool);
    }

    /**
     * @notice Check if a pool is in recovery mode.
     * @param pool The pool address
     * @return True if in recovery mode
     */
    function isPoolInRecoveryMode(address pool) external view returns (bool) {
        return _isPoolInRecoveryMode(pool);
    }

    /* ========================================================================== */
    /*                           POOL TOKEN QUERIES                               */
    /* ========================================================================== */

    /**
     * @notice Get the list of tokens in a pool.
     * @param pool The pool address
     * @return tokens Array of token addresses
     */
    function getPoolTokens(address pool) external view withRegisteredPool(pool) returns (IERC20[] memory tokens) {
        return BalancerV3VaultStorageRepo._poolTokens(pool);
    }

    /**
     * @notice Get comprehensive token information for a pool.
     * @param pool The pool address
     * @return tokens Array of token addresses
     * @return tokenInfo Token configuration (type, rate provider, etc.)
     * @return balancesRaw Raw token balances
     * @return lastBalancesLiveScaled18 Last live balances (scaled to 18 decimals)
     */
    function getPoolTokenInfo(
        address pool
    )
        external
        view
        withRegisteredPool(pool)
        returns (
            IERC20[] memory tokens,
            TokenInfo[] memory tokenInfo,
            uint256[] memory balancesRaw,
            uint256[] memory lastBalancesLiveScaled18
        )
    {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        tokens = layout.poolTokens[pool];
        uint256 numTokens = tokens.length;
        tokenInfo = new TokenInfo[](numTokens);
        balancesRaw = new uint256[](numTokens);
        lastBalancesLiveScaled18 = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; ++i) {
            tokenInfo[i] = layout.poolTokenInfo[pool][tokens[i]];
            bytes32 packedBalance = layout.poolTokenBalances[pool][i];
            balancesRaw[i] = packedBalance.getBalanceRaw();
            lastBalancesLiveScaled18[i] = packedBalance.getBalanceDerived();
        }
    }

    /**
     * @notice Get pool token rates and scaling factors.
     * @param pool The pool address
     * @return decimalScalingFactors Scaling factors for each token
     * @return tokenRates Current rates for each token
     */
    function getPoolTokenRates(
        address pool
    )
        external
        view
        withRegisteredPool(pool)
        returns (uint256[] memory decimalScalingFactors, uint256[] memory tokenRates)
    {
        PoolData memory poolData = _loadPoolData(pool, Rounding.ROUND_DOWN);
        return (poolData.decimalScalingFactors, poolData.tokenRates);
    }

    /**
     * @notice Get current live balances for a pool.
     * @param pool The pool address
     * @return balancesLiveScaled18 Live balances scaled to 18 decimals
     */
    function getCurrentLiveBalances(
        address pool
    ) external view withRegisteredPool(pool) returns (uint256[] memory balancesLiveScaled18) {
        PoolData memory poolData = _loadPoolData(pool, Rounding.ROUND_DOWN);
        return poolData.balancesLiveScaled18;
    }

    /* ========================================================================== */
    /*                           POOL CONFIG QUERIES                              */
    /* ========================================================================== */

    /**
     * @notice Get the pool configuration.
     * @param pool The pool address
     * @return poolConfig The pool configuration struct
     */
    function getPoolConfig(address pool) external view withRegisteredPool(pool) returns (PoolConfig memory) {
        PoolConfigBits config = BalancerV3VaultStorageRepo._poolConfigBits(pool);

        return PoolConfig({
            isPoolRegistered: config.isPoolRegistered(),
            isPoolInitialized: config.isPoolInitialized(),
            isPoolPaused: config.isPoolPaused(),
            isPoolInRecoveryMode: config.isPoolInRecoveryMode(),
            staticSwapFeePercentage: config.getStaticSwapFeePercentage(),
            aggregateSwapFeePercentage: config.getAggregateSwapFeePercentage(),
            aggregateYieldFeePercentage: config.getAggregateYieldFeePercentage(),
            tokenDecimalDiffs: config.getTokenDecimalDiffs(),
            pauseWindowEndTime: config.getPauseWindowEndTime(),
            liquidityManagement: LiquidityManagement({
                disableUnbalancedLiquidity: !config.supportsUnbalancedLiquidity(),
                enableAddLiquidityCustom: config.supportsAddLiquidityCustom(),
                enableRemoveLiquidityCustom: config.supportsRemoveLiquidityCustom(),
                enableDonation: config.supportsDonation()
            })
        });
    }

    /**
     * @notice Get the hooks contract for a pool.
     * @param pool The pool address
     * @return hooksContract The hooks contract address
     */
    function getHooksContract(address pool) external view returns (IHooks hooksContract) {
        return BalancerV3VaultStorageRepo._hooksContract(pool);
    }

    /**
     * @notice Get the static swap fee percentage for a pool.
     * @param pool The pool address
     * @return swapFeePercentage The swap fee percentage (18 decimal fixed point)
     */
    function getStaticSwapFeePercentage(address pool) external view withRegisteredPool(pool) returns (uint256) {
        return BalancerV3VaultStorageRepo._poolConfigBits(pool).getStaticSwapFeePercentage();
    }

    /**
     * @notice Get role accounts for a pool.
     * @param pool The pool address
     * @return roleAccounts The role accounts (pause manager, swap fee manager, pool creator)
     */
    function getPoolRoleAccounts(
        address pool
    ) external view withRegisteredPool(pool) returns (PoolRoleAccounts memory) {
        return BalancerV3VaultStorageRepo._poolRoleAccounts(pool);
    }

    /* ========================================================================== */
    /*                            VAULT STATE QUERIES                             */
    /* ========================================================================== */

    /**
     * @notice Check if the vault is paused.
     * @return True if paused
     */
    function isVaultPaused() external view returns (bool) {
        return _isVaultPaused();
    }

    /**
     * @notice Check if queries are disabled.
     * @return True if disabled
     */
    function isQueryDisabled() external view returns (bool) {
        return BalancerV3VaultStorageRepo._layout().vaultStateBits.isQueryDisabled();
    }

    /**
     * @notice Check if queries are permanently disabled.
     * @return True if permanently disabled
     */
    function isQueryDisabledPermanently() external view returns (bool) {
        return BalancerV3VaultStorageRepo._queriesDisabledPermanently();
    }

    /**
     * @notice Get the vault's pause window end time.
     * @return Timestamp when pause window ends
     */
    function getVaultPauseWindowEndTime() external view returns (uint32) {
        return BalancerV3VaultStorageRepo._vaultPauseWindowEndTime();
    }

    /**
     * @notice Get the vault's buffer period end time.
     * @return Timestamp when buffer period ends
     */
    function getBufferPeriodEndTime() external view returns (uint32) {
        return BalancerV3VaultStorageRepo._vaultBufferPeriodEndTime();
    }

    /**
     * @notice Get the vault's buffer period duration.
     * @return Duration in seconds
     */
    function getBufferPeriodDuration() external view returns (uint32) {
        return BalancerV3VaultStorageRepo._vaultBufferPeriodDuration();
    }

    /**
     * @notice Get the minimum trade amount.
     * @return Minimum amount in scaled18
     */
    function getMinimumTradeAmount() external view returns (uint256) {
        return BalancerV3VaultStorageRepo._minimumTradeAmount();
    }

    /**
     * @notice Get the minimum wrap amount.
     * @return Minimum amount in native decimals
     */
    function getMinimumWrapAmount() external view returns (uint256) {
        return BalancerV3VaultStorageRepo._minimumWrapAmount();
    }

    /**
     * @notice Get the authorizer contract.
     * @return The authorizer
     */
    function getAuthorizer() external view returns (IAuthorizer) {
        return BalancerV3VaultStorageRepo._authorizer();
    }

    /**
     * @notice Get the protocol fee controller.
     * @return The fee controller
     */
    function getProtocolFeeController() external view returns (IProtocolFeeController) {
        return BalancerV3VaultStorageRepo._protocolFeeController();
    }

    /* ========================================================================== */
    /*                              BPT QUERIES                                   */
    /* ========================================================================== */

    /**
     * @notice Get the total supply of a pool's BPT.
     * @param pool The pool address
     * @return Total supply
     */
    function totalSupply(address pool) external view returns (uint256) {
        return BalancerV3MultiTokenRepo._totalSupply(pool);
    }

    /**
     * @notice Get the BPT balance of an account.
     * @param pool The pool address
     * @param account The account
     * @return Balance
     */
    function balanceOf(address pool, address account) external view returns (uint256) {
        return BalancerV3MultiTokenRepo._balanceOf(pool, account);
    }

    /* ========================================================================== */
    /*                            BUFFER QUERIES                                  */
    /* ========================================================================== */

    /**
     * @notice Get buffer balances for a wrapped token.
     * @param wrappedToken The ERC4626 wrapped token
     * @return underlyingBalance Underlying token balance
     * @return wrappedBalance Wrapped token balance
     */
    function getBufferBalance(
        IERC4626 wrappedToken
    ) external view returns (uint256 underlyingBalance, uint256 wrappedBalance) {
        bytes32 packedBalance = BalancerV3VaultStorageRepo._bufferTokenBalance(wrappedToken);
        return (packedBalance.getBalanceRaw(), packedBalance.getBalanceDerived());
    }

    /**
     * @notice Get buffer LP shares for a user.
     * @param wrappedToken The ERC4626 wrapped token
     * @param user The user address
     * @return shares The user's shares
     */
    function getBufferOwnerShares(IERC4626 wrappedToken, address user) external view returns (uint256) {
        return BalancerV3VaultStorageRepo._bufferLpShares(wrappedToken, user);
    }

    /**
     * @notice Get total buffer shares.
     * @param wrappedToken The ERC4626 wrapped token
     * @return totalShares Total shares issued
     */
    function getBufferTotalShares(IERC4626 wrappedToken) external view returns (uint256) {
        return BalancerV3VaultStorageRepo._bufferTotalShares(wrappedToken);
    }

    /**
     * @notice Get the underlying asset for a buffer.
     * @param wrappedToken The ERC4626 wrapped token
     * @return underlyingToken The underlying token address
     */
    function getBufferAsset(IERC4626 wrappedToken) external view returns (address) {
        return BalancerV3VaultStorageRepo._bufferAsset(wrappedToken);
    }

    /* ========================================================================== */
    /*                            RESERVE QUERIES                                 */
    /* ========================================================================== */

    /**
     * @notice Get the vault's reserve of a token.
     * @param token The token
     * @return The reserve amount
     */
    function getReservesOf(IERC20 token) external view returns (uint256) {
        return BalancerV3VaultStorageRepo._reservesOf(token);
    }

    /**
     * @notice Get aggregate fee amounts for a pool token.
     * @param pool The pool address
     * @param token The token
     * @return swapFeeAmount Accumulated swap fees
     * @return yieldFeeAmount Accumulated yield fees
     */
    function getAggregateSwapAndYieldFeeAmounts(
        address pool,
        IERC20 token
    ) external view returns (uint256 swapFeeAmount, uint256 yieldFeeAmount) {
        bytes32 packedFees = BalancerV3VaultStorageRepo._getAggregateFeeAmount(pool, token);
        return (packedFees.getBalanceRaw(), packedFees.getBalanceDerived());
    }
}
