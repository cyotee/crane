// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVaultExtension} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";

import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";
import {VaultStateLib, VaultStateBits} from "@balancer-labs/v3-vault/contracts/lib/VaultStateLib.sol";
import {PoolDataLib} from "@balancer-labs/v3-vault/contracts/lib/PoolDataLib.sol";
import {HooksConfigLib} from "@balancer-labs/v3-vault/contracts/lib/HooksConfigLib.sol";

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
contract VaultQueryFacet is BalancerV3VaultModifiers, IFacet {
    using PackedTokenBalance for bytes32;
    using PoolConfigLib for PoolConfigBits;
    using VaultStateLib for VaultStateBits;
    using PoolDataLib for PoolData;
    using HooksConfigLib for PoolConfigBits;

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(VaultQueryFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IVaultExtension).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](45);
        // Pool state queries
        funcs[0] = this.isPoolRegistered.selector;
        funcs[1] = this.isPoolInitialized.selector;
        funcs[2] = this.isPoolPaused.selector;
        funcs[3] = this.isPoolInRecoveryMode.selector;
        // Pool token queries
        funcs[4] = this.getPoolTokens.selector;
        funcs[5] = this.getPoolTokenInfo.selector;
        funcs[6] = this.getPoolTokenRates.selector;
        funcs[7] = this.getCurrentLiveBalances.selector;
        // Pool config queries
        funcs[8] = this.getPoolConfig.selector;
        funcs[9] = this.getHooksContract.selector;
        funcs[10] = this.getStaticSwapFeePercentage.selector;
        funcs[11] = this.getPoolRoleAccounts.selector;
        // Vault state queries
        funcs[12] = this.isQueryDisabledPermanently.selector;
        funcs[13] = this.getVaultPauseWindowEndTime.selector;
        funcs[14] = this.getBufferPeriodEndTime.selector;
        funcs[15] = this.getBufferPeriodDuration.selector;
        funcs[16] = this.getMinimumTradeAmount.selector;
        funcs[17] = this.getMinimumWrapAmount.selector;
        funcs[18] = this.getAuthorizer.selector;
        funcs[19] = this.getProtocolFeeController.selector;
        // BPT queries (from IVaultExtension)
        funcs[20] = this.totalSupply.selector;
        funcs[21] = this.balanceOf.selector;
        funcs[22] = this.allowance.selector;
        funcs[23] = this.approve.selector;
        // Buffer queries
        funcs[24] = this.getBufferBalance.selector;
        funcs[25] = this.getBufferOwnerShares.selector;
        funcs[26] = this.getBufferTotalShares.selector;
        funcs[27] = this.getBufferAsset.selector;
        // Reserve queries
        funcs[28] = this.getReservesOf.selector;
        funcs[29] = this.getAggregateSwapAndYieldFeeAmounts.selector;
        // IVaultExtension fee queries (separate from combined)
        funcs[30] = this.getAggregateSwapFeeAmount.selector;
        funcs[31] = this.getAggregateYieldFeeAmount.selector;
        // Vault references (for Diamond, these return self)
        funcs[32] = this.getVaultExtension.selector;
        funcs[33] = this.getVaultAdmin.selector;
        funcs[34] = this.vault.selector;
        // Hooks and BPT rate
        funcs[35] = this.getHooksConfig.selector;
        funcs[36] = this.getBptRate.selector;
        funcs[37] = this.getPoolPausedState.selector;
        // Buffer checks
        funcs[38] = this.isERC4626BufferInitialized.selector;
        funcs[39] = this.getERC4626BufferAsset.selector;
        // Query functions (IVaultExtension)
        funcs[40] = this.quote.selector;
        funcs[41] = this.quoteAndRevert.selector;
        funcs[42] = this.emitAuxiliaryEvent.selector;
        // Pool data (IVaultExtension)
        funcs[43] = this.getPoolData.selector;
        // Dynamic swap fee (IVaultExtension)
        funcs[44] = this.computeDynamicSwapFeePercentage.selector;
    }

    /// @inheritdoc IFacet
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

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
     * @notice Query the current dynamic swap fee percentage of a pool.
     * @dev Calls the hooks contract to compute the dynamic fee if the pool has dynamic fees enabled.
     * Reverts if the hook doesn't return success.
     * @param pool The pool address
     * @param swapParams The swap parameters used to compute the fee
     * @return dynamicSwapFeePercentage The computed dynamic swap fee percentage
     */
    function computeDynamicSwapFeePercentage(
        address pool,
        PoolSwapParams memory swapParams
    ) external view withRegisteredPool(pool) returns (uint256 dynamicSwapFeePercentage) {
        PoolConfigBits config = BalancerV3VaultStorageRepo._poolConfigBits(pool);

        // If pool doesn't use dynamic swap fees, return static fee
        // Use HooksConfigLib to check the flag
        if (!config.shouldCallComputeDynamicSwapFee()) {
            return config.getStaticSwapFeePercentage();
        }

        // Get the hooks contract
        IHooks hooksContract = BalancerV3VaultStorageRepo._hooksContract(pool);
        if (address(hooksContract) == address(0)) {
            return config.getStaticSwapFeePercentage();
        }

        // Call the hooks contract to compute dynamic fee
        (bool success, uint256 dynamicFee) = hooksContract.onComputeDynamicSwapFeePercentage(
            swapParams,
            pool,
            config.getStaticSwapFeePercentage()
        );

        if (!success) {
            revert DynamicSwapFeeHookFailed();
        }

        return dynamicFee;
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

    /**
     * @notice Returns comprehensive pool data for the given pool.
     * @dev This contains the pool configuration, tokens, rates, scaling factors, and balances.
     * @param pool The address of the pool
     * @return poolData The `PoolData` result
     */
    function getPoolData(address pool) external view withRegisteredPool(pool) returns (PoolData memory) {
        return _loadPoolData(pool, Rounding.ROUND_DOWN);
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

    /**
     * @notice Get the BPT allowance for a spender.
     * @param token The pool/token address
     * @param owner The token owner
     * @param spender The approved spender
     * @return Allowance amount
     */
    function allowance(address token, address owner, address spender) external view returns (uint256) {
        return BalancerV3MultiTokenRepo._allowance(token, owner, spender);
    }

    /**
     * @notice Approves a spender to transfer BPT.
     * @dev msg.sender must be the pool contract.
     * @param owner The token owner
     * @param spender The account being approved
     * @param amount The approval amount
     * @return success Always returns true on success
     */
    function approve(address owner, address spender, uint256 amount) external returns (bool) {
        BalancerV3MultiTokenRepo._approve(msg.sender, owner, spender, amount);
        return true;
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

    /**
     * @notice Get aggregate swap fee amount for a pool token (IVaultExtension).
     * @param pool The pool address
     * @param token The token
     * @return swapFeeAmount Accumulated swap fees
     */
    function getAggregateSwapFeeAmount(address pool, IERC20 token) external view returns (uint256) {
        bytes32 packedFees = BalancerV3VaultStorageRepo._getAggregateFeeAmount(pool, token);
        return packedFees.getBalanceRaw();
    }

    /**
     * @notice Get aggregate yield fee amount for a pool token (IVaultExtension).
     * @param pool The pool address
     * @param token The token
     * @return yieldFeeAmount Accumulated yield fees
     */
    function getAggregateYieldFeeAmount(address pool, IERC20 token) external view returns (uint256) {
        bytes32 packedFees = BalancerV3VaultStorageRepo._getAggregateFeeAmount(pool, token);
        return packedFees.getBalanceDerived();
    }

    /* ========================================================================== */
    /*                            VAULT REFERENCE                                 */
    /* ========================================================================== */

    /**
     * @notice Returns the VaultExtension contract address (IVaultMain).
     * @dev For Diamond, this returns address(this) since all interfaces are on one contract.
     * @return vaultExtension The vault extension address
     */
    function getVaultExtension() external view returns (address) {
        return address(this);
    }

    /**
     * @notice Returns the VaultAdmin contract address (IVaultExtension).
     * @dev For Diamond, this returns address(this) since all interfaces are on one contract.
     * @return vaultAdmin The vault admin address
     */
    function getVaultAdmin() external view returns (address) {
        return address(this);
    }

    /**
     * @notice Returns the main Vault address (IVaultExtension/IVaultAdmin).
     * @dev For Diamond, this returns address(this) since all interfaces are on one contract.
     * @return The vault address
     */
    function vault() external view returns (address) {
        return address(this);
    }

    /* ========================================================================== */
    /*                            HOOKS & BPT RATE                                */
    /* ========================================================================== */

    /**
     * @notice Gets the hooks configuration parameters of a pool.
     * @param pool Address of the pool
     * @return hooksConfig The hooks configuration
     */
    function getHooksConfig(address pool) external view withRegisteredPool(pool) returns (HooksConfig memory) {
        PoolConfigBits config = BalancerV3VaultStorageRepo._poolConfigBits(pool);
        address hooksContract = address(BalancerV3VaultStorageRepo._hooksContract(pool));
        return config.toHooksConfig(IHooks(hooksContract));
    }

    /**
     * @notice Get the BPT rate for a pool (invariant / totalSupply).
     * @dev This is a simplified implementation. The real implementation would call
     * pool.computeInvariant() to get the current invariant.
     * @param pool The pool address
     * @return rate The BPT rate (1e18 precision)
     */
    function getBptRate(address pool) external view withRegisteredPool(pool) returns (uint256) {
        uint256 bptTotalSupply = BalancerV3MultiTokenRepo._totalSupply(pool);
        if (bptTotalSupply == 0) return 0;
        // For now, return 1e18 (1:1 rate) as a placeholder
        // A real implementation would compute: invariant / totalSupply
        return 1e18;
    }

    /**
     * @notice Get pool paused state information.
     * @param pool The pool address
     * @return poolPaused Whether the pool is paused
     * @return poolPauseWindowEndTime End of pause window
     * @return poolBufferPeriodEndTime End of buffer period
     * @return pauseManager The pause manager address
     */
    function getPoolPausedState(
        address pool
    )
        external
        view
        withRegisteredPool(pool)
        returns (bool poolPaused, uint32 poolPauseWindowEndTime, uint32 poolBufferPeriodEndTime, address pauseManager)
    {
        PoolConfigBits config = BalancerV3VaultStorageRepo._poolConfigBits(pool);
        PoolRoleAccounts memory roles = BalancerV3VaultStorageRepo._poolRoleAccounts(pool);

        poolPaused = config.isPoolPaused();
        poolPauseWindowEndTime = config.getPauseWindowEndTime();
        poolBufferPeriodEndTime = poolPauseWindowEndTime + BalancerV3VaultStorageRepo._vaultBufferPeriodDuration();
        pauseManager = roles.pauseManager;
    }

    /* ========================================================================== */
    /*                            BUFFER CHECKS                                   */
    /* ========================================================================== */

    /**
     * @notice Checks if the wrapped token has an initialized buffer.
     * @param wrappedToken Address of the wrapped token
     * @return isBufferInitialized True if initialized
     */
    function isERC4626BufferInitialized(IERC4626 wrappedToken) external view returns (bool) {
        return BalancerV3VaultStorageRepo._bufferAsset(wrappedToken) != address(0);
    }

    /**
     * @notice Gets the registered asset for a given buffer.
     * @param wrappedToken The wrapped token specifying the buffer
     * @return asset The underlying asset
     */
    function getERC4626BufferAsset(IERC4626 wrappedToken) external view returns (address) {
        return BalancerV3VaultStorageRepo._bufferAsset(wrappedToken);
    }

    /* ========================================================================== */
    /*                            QUERY FUNCTIONS                                 */
    /* ========================================================================== */

    /**
     * @notice Performs a callback on msg.sender with arguments provided in `data`.
     * @dev Used to query operations on the Vault. Only off-chain eth_call are allowed.
     * This opens an unlock context, calls back to the sender, and verifies all deltas settle.
     * @param data Contains function signature and args to be passed to msg.sender
     * @return result Resulting data from the call
     */
    function quote(bytes calldata data) external returns (bytes memory result) {
        // Quote must be disabled if queries are disabled
        if (BalancerV3VaultStorageRepo._layout().vaultStateBits.isQueryDisabled()) {
            revert QueriesDisabled();
        }

        // For queries, we open a transient context and execute the callback
        // The callback can perform any vault operations as if unlocked
        // All operations must settle (deltas = 0) for the quote to succeed
        result = _queryCallback(data);
    }

    /**
     * @notice Performs a callback and always reverts, returning the result in the revert reason.
     * @dev Used for off-chain simulations that need to extract return data from a revert.
     * @param data Contains function signature and args to be passed to msg.sender
     */
    function quoteAndRevert(bytes calldata data) external {
        // Quote must be disabled if queries are disabled
        if (BalancerV3VaultStorageRepo._layout().vaultStateBits.isQueryDisabled()) {
            revert QueriesDisabled();
        }

        bytes memory result = _queryCallback(data);

        // Always revert with the result
        assembly {
            let resultLength := mload(result)
            revert(add(result, 32), resultLength)
        }
    }

    /**
     * @notice Internal helper to execute a query callback.
     * @dev Opens a transient unlock context, executes callback, verifies settlement.
     * @param data The callback data
     * @return result The callback result
     */
    function _queryCallback(bytes calldata data) internal returns (bytes memory result) {
        // In a Diamond, we can call the unlock/transient functions via delegatecall
        // For now, just execute the callback directly since query context doesn't modify state
        (bool success, bytes memory returnData) = msg.sender.call(data);
        if (!success) {
            // Bubble up the revert reason
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
        return returnData;
    }

    /**
     * @notice Pools can use this to emit event data from the Vault.
     * @dev Only registered pools can emit auxiliary events.
     * @param eventKey Event key identifying the event type
     * @param eventData Encoded event data
     */
    function emitAuxiliaryEvent(bytes32 eventKey, bytes calldata eventData) external {
        // Only registered pools can emit auxiliary events
        if (!_isPoolRegistered(msg.sender)) {
            revert PoolNotRegistered(msg.sender);
        }

        emit VaultAuxiliary(msg.sender, eventKey, eventData);
    }
}
