// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {SafeCast} from "@crane/contracts/utils/SafeCast.sol";

import {IAuthorizer} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IProtocolFeeController.sol";
import {IAuthentication} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";
import {IVaultAdmin} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {PackedTokenBalance} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/PackedTokenBalance.sol";

import {PoolConfigLib, PoolConfigBits} from "@crane/contracts/external/balancer/v3/vault/contracts/lib/PoolConfigLib.sol";
import {VaultStateLib, VaultStateBits} from "@crane/contracts/external/balancer/v3/vault/contracts/lib/VaultStateLib.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";
import {BalancerV3MultiTokenRepo} from "../BalancerV3MultiTokenRepo.sol";

/* -------------------------------------------------------------------------- */
/*                              VaultAdminFacet                               */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultAdminFacet
 * @notice Handles vault and pool administrative functions.
 * @dev Implements IVaultAdmin functions:
 * - Vault pause/unpause
 * - Pool pause/unpause
 * - Buffer pause/unpause
 * - Swap fee management
 * - Protocol fee collection
 * - Recovery mode
 * - Authorizer management
 */
contract VaultAdminFacet is BalancerV3VaultModifiers, IFacet {
    using PackedTokenBalance for bytes32;
    using PoolConfigLib for PoolConfigBits;
    using VaultStateLib for VaultStateBits;
    using SafeCast for *;
    using FixedPoint for uint256;

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(VaultAdminFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IVaultAdmin).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](29);
        // Vault pause
        funcs[0] = this.pauseVault.selector;
        funcs[1] = this.unpauseVault.selector;
        funcs[2] = this.isVaultPaused.selector;
        funcs[3] = this.getVaultPausedState.selector;
        // Pool pause
        funcs[4] = this.pausePool.selector;
        funcs[5] = this.unpausePool.selector;
        // Buffer pause
        funcs[6] = this.pauseVaultBuffers.selector;
        funcs[7] = this.unpauseVaultBuffers.selector;
        funcs[8] = this.areBuffersPaused.selector;
        // Swap fees
        funcs[9] = this.setStaticSwapFeePercentage.selector;
        funcs[10] = this.updateAggregateSwapFeePercentage.selector;
        funcs[11] = this.updateAggregateYieldFeePercentage.selector;
        // Fee collection
        funcs[12] = this.collectAggregateFees.selector;
        // Recovery mode
        funcs[13] = this.enableRecoveryMode.selector;
        funcs[14] = this.disableRecoveryMode.selector;
        // Query functions
        funcs[15] = this.disableQuery.selector;
        funcs[16] = this.disableQueryPermanently.selector;
        funcs[17] = this.enableQuery.selector;
        funcs[18] = this.isQueryDisabled.selector;
        // Authorizer
        funcs[19] = this.setAuthorizer.selector;
        funcs[20] = this.setProtocolFeeController.selector;
        // IVaultAdmin constants
        funcs[21] = this.getPauseWindowEndTime.selector;
        funcs[22] = this.getMinimumPoolTokens.selector;
        funcs[23] = this.getMaximumPoolTokens.selector;
        funcs[24] = this.getPoolMinimumTotalSupply.selector;
        funcs[25] = this.getBufferMinimumTotalSupply.selector;
        // Buffer operations
        funcs[26] = this.initializeBuffer.selector;
        funcs[27] = this.addLiquidityToBuffer.selector;
        funcs[28] = this.removeLiquidityFromBuffer.selector;
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
    /*                          VAULT PAUSE FUNCTIONS                             */
    /* ========================================================================== */

    /**
     * @notice Pauses the vault.
     * @dev Can only be called within the pause window by governance.
     */
    function pauseVault() external authenticate {
        _setVaultPaused(true);
    }

    /**
     * @notice Unpauses the vault.
     * @dev Can be called within the buffer period by governance.
     */
    function unpauseVault() external authenticate {
        _setVaultPaused(false);
    }

    /**
     * @notice Returns the vault's paused state.
     */
    function isVaultPaused() external view returns (bool) {
        return _isVaultPaused();
    }

    /**
     * @notice Returns the vault's paused state and time windows.
     */
    function getVaultPausedState() external view returns (bool paused, uint32 pauseWindowEndTime, uint32 bufferPeriodEndTime) {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        return (
            layout.vaultStateBits.isVaultPaused(),
            layout.vaultPauseWindowEndTime,
            layout.vaultBufferPeriodEndTime
        );
    }

    function _setVaultPaused(bool pausing) internal {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        if (_isVaultPaused()) {
            if (pausing) {
                // Already paused, and trying to pause again
                revert VaultPaused();
            }
            // Can always unpause while paused (within buffer period)
        } else {
            if (pausing) {
                // Not paused; can pause within window
                if (block.timestamp >= layout.vaultPauseWindowEndTime) {
                    revert VaultPauseWindowExpired();
                }
            } else {
                // Not paused, trying to unpause
                revert VaultNotPaused();
            }
        }

        layout.vaultStateBits = layout.vaultStateBits.setVaultPaused(pausing);
        emit VaultPausedStateChanged(pausing);
    }

    /* ========================================================================== */
    /*                           POOL PAUSE FUNCTIONS                             */
    /* ========================================================================== */

    /**
     * @notice Pauses a pool.
     * @param pool The pool to pause
     */
    function pausePool(address pool) external withRegisteredPool(pool) {
        _setPoolPaused(pool, true);
    }

    /**
     * @notice Unpauses a pool.
     * @param pool The pool to unpause
     */
    function unpausePool(address pool) external withRegisteredPool(pool) {
        _setPoolPaused(pool, false);
    }

    function _setPoolPaused(address pool, bool pausing) internal {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        PoolRoleAccounts memory roleAccounts = layout.poolRoleAccounts[pool];

        // Only pause manager can pause/unpause
        if (msg.sender != roleAccounts.pauseManager) {
            revert IAuthentication.SenderNotAllowed();
        }

        PoolConfigBits config = layout.poolConfigBits[pool];
        uint32 pauseWindowEndTime = config.getPauseWindowEndTime();

        if (pausing) {
            if (block.timestamp >= pauseWindowEndTime) {
                revert PoolPauseWindowExpired(pool);
            }
        }

        layout.poolConfigBits[pool] = config.setPoolPaused(pausing);
        emit PoolPausedStateChanged(pool, pausing);
    }

    /* ========================================================================== */
    /*                          BUFFER PAUSE FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Pauses all vault buffers.
     */
    function pauseVaultBuffers() external authenticate {
        _setVaultBufferPauseState(true);
    }

    /**
     * @notice Unpauses all vault buffers.
     */
    function unpauseVaultBuffers() external authenticate {
        _setVaultBufferPauseState(false);
    }

    /**
     * @notice Returns whether buffers are paused.
     */
    function areBuffersPaused() external view returns (bool) {
        return BalancerV3VaultStorageRepo._layout().vaultStateBits.areBuffersPaused();
    }

    function _setVaultBufferPauseState(bool pausing) internal {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.vaultStateBits = layout.vaultStateBits.setBuffersPaused(pausing);
        emit VaultBuffersPausedStateChanged(pausing);
    }

    /* ========================================================================== */
    /*                            SWAP FEE FUNCTIONS                              */
    /* ========================================================================== */

    /**
     * @notice Sets the static swap fee percentage for a pool.
     * @param pool The pool address
     * @param swapFeePercentage The new swap fee percentage
     */
    function setStaticSwapFeePercentage(
        address pool,
        uint256 swapFeePercentage
    ) external withRegisteredPool(pool) {
        _ensureUnpaused(pool);

        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        PoolRoleAccounts memory roleAccounts = layout.poolRoleAccounts[pool];

        // Only swap fee manager can set fees
        if (msg.sender != roleAccounts.swapFeeManager) {
            revert IAuthentication.SenderNotAllowed();
        }

        // Use the inherited function from BalancerV3VaultModifiers
        _setStaticSwapFeePercentage(pool, swapFeePercentage);
    }

    /**
     * @notice Updates the aggregate swap fee percentage for a pool.
     * @dev Only callable by the protocol fee controller.
     */
    function updateAggregateSwapFeePercentage(
        address pool,
        uint256 newAggregateSwapFeePercentage
    ) external withRegisteredPool(pool) onlyProtocolFeeController {
        if (newAggregateSwapFeePercentage > FixedPoint.ONE) {
            revert IProtocolFeeController.ProtocolSwapFeePercentageTooHigh();
        }

        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.poolConfigBits[pool] = layout.poolConfigBits[pool].setAggregateSwapFeePercentage(
            newAggregateSwapFeePercentage
        );
        emit AggregateSwapFeePercentageChanged(pool, newAggregateSwapFeePercentage);
    }

    /**
     * @notice Updates the aggregate yield fee percentage for a pool.
     * @dev Only callable by the protocol fee controller.
     */
    function updateAggregateYieldFeePercentage(
        address pool,
        uint256 newAggregateYieldFeePercentage
    ) external withRegisteredPool(pool) onlyProtocolFeeController {
        if (newAggregateYieldFeePercentage > FixedPoint.ONE) {
            revert IProtocolFeeController.ProtocolYieldFeePercentageTooHigh();
        }

        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.poolConfigBits[pool] = layout.poolConfigBits[pool].setAggregateYieldFeePercentage(
            newAggregateYieldFeePercentage
        );
        emit AggregateYieldFeePercentageChanged(pool, newAggregateYieldFeePercentage);
    }

    /* ========================================================================== */
    /*                          FEE COLLECTION FUNCTIONS                          */
    /* ========================================================================== */

    /**
     * @notice Collects accumulated aggregate fees for a pool.
     * @dev Only callable by the protocol fee controller.
     * @param pool The pool address
     * @return totalSwapFees Swap fees per token
     * @return totalYieldFees Yield fees per token
     */
    function collectAggregateFees(
        address pool
    )
        external
        onlyWhenUnlocked
        onlyProtocolFeeController
        withRegisteredPool(pool)
        returns (uint256[] memory totalSwapFees, uint256[] memory totalYieldFees)
    {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        IERC20[] memory poolTokens = layout.poolTokens[pool];
        uint256 numTokens = poolTokens.length;

        totalSwapFees = new uint256[](numTokens);
        totalYieldFees = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; ++i) {
            IERC20 token = poolTokens[i];
            bytes32 packedFees = layout.aggregateFeeAmounts[pool][token];

            totalSwapFees[i] = packedFees.getBalanceRaw();
            totalYieldFees[i] = packedFees.getBalanceDerived();

            if (totalSwapFees[i] > 0 || totalYieldFees[i] > 0) {
                // Reset accumulated fees
                layout.aggregateFeeAmounts[pool][token] = bytes32(0);

                // Supply credit to fee controller
                uint256 totalFees = totalSwapFees[i] + totalYieldFees[i];
                _supplyCredit(token, totalFees);
            }
        }
    }

    /* ========================================================================== */
    /*                          RECOVERY MODE FUNCTIONS                           */
    /* ========================================================================== */

    /**
     * @notice Enables recovery mode for a pool.
     * @dev Recovery mode allows proportional exits only and forfeits yield fees.
     * Permissionless if pool/vault is paused, otherwise requires governance.
     */
    function enableRecoveryMode(address pool) external withRegisteredPool(pool) {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        PoolConfigBits config = layout.poolConfigBits[pool];

        if (config.isPoolInRecoveryMode()) {
            revert PoolInRecoveryMode(pool);
        }

        // Permissionless if pool or vault is paused
        bool poolPaused = config.isPoolPaused();
        bool vaultPaused = layout.vaultStateBits.isVaultPaused();

        if (!poolPaused && !vaultPaused) {
            // Requires governance if not paused
            _authenticateCaller();
        }

        layout.poolConfigBits[pool] = config.setPoolInRecoveryMode(true);
        emit PoolRecoveryModeStateChanged(pool, true);
    }

    /**
     * @notice Disables recovery mode for a pool.
     * @dev Only governance can disable recovery mode.
     */
    function disableRecoveryMode(address pool) external withRegisteredPool(pool) authenticate {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        PoolConfigBits config = layout.poolConfigBits[pool];

        if (!config.isPoolInRecoveryMode()) {
            revert PoolNotInRecoveryMode(pool);
        }

        // Sync pool balances after recovery
        _syncPoolBalancesAfterRecoveryMode(pool);

        layout.poolConfigBits[pool] = config.setPoolInRecoveryMode(false);
        emit PoolRecoveryModeStateChanged(pool, false);
    }

    function _syncPoolBalancesAfterRecoveryMode(address pool) internal {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        IERC20[] memory poolTokens = layout.poolTokens[pool];
        uint256 numTokens = poolTokens.length;

        for (uint256 i = 0; i < numTokens; ++i) {
            bytes32 packedBalance = layout.poolTokenBalances[pool][i];
            uint256 rawBalance = packedBalance.getBalanceRaw();

            // Set live balance equal to raw balance (forfeit any yield)
            layout.poolTokenBalances[pool][i] = PackedTokenBalance.toPackedBalance(rawBalance, rawBalance);
        }
    }

    /* ========================================================================== */
    /*                            QUERY FUNCTIONS                                 */
    /* ========================================================================== */

    /**
     * @notice Disables query functionality.
     */
    function disableQuery() external authenticate {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.vaultStateBits = layout.vaultStateBits.setQueryDisabled(true);
        emit VaultQueriesDisabled();
    }

    /**
     * @notice Permanently disables query functionality.
     */
    function disableQueryPermanently() external authenticate {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.queriesDisabledPermanently = true;
        layout.vaultStateBits = layout.vaultStateBits.setQueryDisabled(true);
        emit VaultQueriesDisabled();
    }

    /**
     * @notice Re-enables query functionality.
     * @dev Will revert if queries were permanently disabled.
     */
    function enableQuery() external authenticate {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        if (layout.queriesDisabledPermanently) {
            revert QueriesDisabledPermanently();
        }

        layout.vaultStateBits = layout.vaultStateBits.setQueryDisabled(false);
        emit VaultQueriesEnabled();
    }

    /**
     * @notice Returns whether queries are disabled.
     */
    function isQueryDisabled() external view returns (bool) {
        return BalancerV3VaultStorageRepo._layout().vaultStateBits.isQueryDisabled();
    }

    /* ========================================================================== */
    /*                          AUTHORIZER FUNCTIONS                              */
    /* ========================================================================== */

    /**
     * @notice Sets a new authorizer.
     * @param newAuthorizer The new authorizer contract
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external authenticate {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.authorizer = newAuthorizer;
        emit AuthorizerChanged(newAuthorizer);
    }

    /**
     * @notice Sets the protocol fee controller.
     * @param newProtocolFeeController The new fee controller
     */
    function setProtocolFeeController(
        IProtocolFeeController newProtocolFeeController
    ) external authenticate nonReentrant {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        layout.protocolFeeController = newProtocolFeeController;
        emit ProtocolFeeControllerChanged(newProtocolFeeController);
    }

    /* ========================================================================== */
    /*                         CONSTANTS AND IMMUTABLES                           */
    /* ========================================================================== */

    /**
     * @notice Returns the Vault's pause window end time.
     * @dev This is the IVaultAdmin version (different from getVaultPauseWindowEndTime in IVaultExtension).
     * @return pauseWindowEndTime The timestamp when the Vault's pause window ends
     */
    function getPauseWindowEndTime() external view returns (uint32) {
        return BalancerV3VaultStorageRepo._vaultPauseWindowEndTime();
    }

    /**
     * @notice Get the minimum number of tokens in a pool.
     * @return minTokens The minimum token count (2)
     */
    function getMinimumPoolTokens() external pure returns (uint256) {
        return BalancerV3VaultStorageRepo.MIN_TOKENS;
    }

    /**
     * @notice Get the maximum number of tokens in a pool.
     * @return maxTokens The maximum token count (8)
     */
    function getMaximumPoolTokens() external pure returns (uint256) {
        return BalancerV3VaultStorageRepo.MAX_TOKENS;
    }

    /**
     * @notice Get the minimum total supply of pool tokens (BPT) for an initialized pool.
     * @return poolMinimumTotalSupply The minimum total supply (1e6)
     */
    function getPoolMinimumTotalSupply() external pure returns (uint256) {
        return BalancerV3VaultStorageRepo.POOL_MINIMUM_TOTAL_SUPPLY;
    }

    /**
     * @notice Get the minimum total supply of an ERC4626 wrapped token buffer in the Vault.
     * @return bufferMinimumTotalSupply The minimum buffer supply (1e4)
     */
    function getBufferMinimumTotalSupply() external pure returns (uint256) {
        return BalancerV3VaultStorageRepo.BUFFER_MINIMUM_TOTAL_SUPPLY;
    }

    /* ========================================================================== */
    /*                          BUFFER OPERATIONS                                 */
    /* ========================================================================== */

    /**
     * @notice Initializes buffer for the given wrapped token.
     * @dev This is a placeholder - full implementation requires transient accounting.
     * @param wrappedToken Address of the wrapped token that implements IERC4626
     * @param amountUnderlyingRaw Amount of underlying tokens that will be deposited
     * @param amountWrappedRaw Amount of wrapped tokens that will be deposited
     * @param minIssuedShares Minimum amount of shares to receive
     * @param sharesOwner Address that will own the deposited liquidity
     * @return issuedShares The amount of shares issued
     */
    function initializeBuffer(
        IERC4626 wrappedToken,
        uint256 amountUnderlyingRaw,
        uint256 amountWrappedRaw,
        uint256 minIssuedShares,
        address sharesOwner
    ) external nonReentrant returns (uint256 issuedShares) {
        // Ensure buffer not already initialized
        if (BalancerV3VaultStorageRepo._bufferAsset(wrappedToken) != address(0)) {
            revert BufferAlreadyInitialized(wrappedToken);
        }

        // Register the underlying asset
        address underlyingToken = wrappedToken.asset();
        BalancerV3VaultStorageRepo._setBufferAsset(wrappedToken, underlyingToken);

        // Calculate shares (simple: underlying + wrapped value)
        issuedShares = amountUnderlyingRaw + amountWrappedRaw;
        if (issuedShares < minIssuedShares) {
            revert IssuedSharesBelowMin(issuedShares, minIssuedShares);
        }

        // Ensure minimum total supply
        uint256 totalShares = issuedShares + BalancerV3VaultStorageRepo.BUFFER_MINIMUM_TOTAL_SUPPLY;
        BalancerV3VaultStorageRepo._setBufferTotalShares(wrappedToken, totalShares);
        BalancerV3VaultStorageRepo._setBufferLpShares(wrappedToken, sharesOwner, issuedShares);

        // Store balances using PackedTokenBalance
        bytes32 packedBalance = PackedTokenBalance.toPackedBalance(amountUnderlyingRaw, amountWrappedRaw);
        BalancerV3VaultStorageRepo._setBufferTokenBalance(wrappedToken, packedBalance);

        emit BufferSharesMinted(wrappedToken, sharesOwner, issuedShares);
    }

    /**
     * @notice Adds liquidity to an internal ERC4626 buffer proportionally.
     * @param wrappedToken Address of the wrapped token
     * @param maxAmountUnderlyingInRaw Maximum underlying to add
     * @param maxAmountWrappedInRaw Maximum wrapped to add
     * @param exactSharesToIssue Exact shares to issue
     * @param sharesOwner Address that will own the shares
     * @return amountUnderlyingRaw Amount of underlying added
     * @return amountWrappedRaw Amount of wrapped added
     */
    function addLiquidityToBuffer(
        IERC4626 wrappedToken,
        uint256 maxAmountUnderlyingInRaw,
        uint256 maxAmountWrappedInRaw,
        uint256 exactSharesToIssue,
        address sharesOwner
    ) external nonReentrant returns (uint256 amountUnderlyingRaw, uint256 amountWrappedRaw) {
        // Ensure buffer is initialized
        if (BalancerV3VaultStorageRepo._bufferAsset(wrappedToken) == address(0)) {
            revert BufferNotInitialized(wrappedToken);
        }

        // Get current buffer state
        bytes32 currentBalance = BalancerV3VaultStorageRepo._bufferTokenBalance(wrappedToken);
        uint256 currentUnderlying = currentBalance.getBalanceRaw();
        uint256 currentWrapped = currentBalance.getBalanceDerived();
        uint256 currentTotal = BalancerV3VaultStorageRepo._bufferTotalShares(wrappedToken);

        // Calculate proportional amounts
        if (currentTotal > 0) {
            amountUnderlyingRaw = (currentUnderlying * exactSharesToIssue) / currentTotal;
            amountWrappedRaw = (currentWrapped * exactSharesToIssue) / currentTotal;
        }

        // Check against maximums
        if (amountUnderlyingRaw > maxAmountUnderlyingInRaw || amountWrappedRaw > maxAmountWrappedInRaw) {
            revert AmountInAboveMax(IERC20(address(wrappedToken)), amountUnderlyingRaw + amountWrappedRaw, maxAmountUnderlyingInRaw + maxAmountWrappedInRaw);
        }

        // Update state
        BalancerV3VaultStorageRepo._setBufferTotalShares(wrappedToken, currentTotal + exactSharesToIssue);
        uint256 existingShares = BalancerV3VaultStorageRepo._bufferLpShares(wrappedToken, sharesOwner);
        BalancerV3VaultStorageRepo._setBufferLpShares(wrappedToken, sharesOwner, existingShares + exactSharesToIssue);

        bytes32 newBalance = PackedTokenBalance.toPackedBalance(
            currentUnderlying + amountUnderlyingRaw,
            currentWrapped + amountWrappedRaw
        );
        BalancerV3VaultStorageRepo._setBufferTokenBalance(wrappedToken, newBalance);

        emit BufferSharesMinted(wrappedToken, sharesOwner, exactSharesToIssue);
    }

    /**
     * @notice Removes liquidity from an internal ERC4626 buffer.
     * @param wrappedToken Address of the wrapped token
     * @param sharesToRemove Amount of shares to remove
     * @param minAmountUnderlyingOutRaw Minimum underlying to receive
     * @param minAmountWrappedOutRaw Minimum wrapped to receive
     * @return removedUnderlyingBalanceRaw Amount of underlying returned
     * @return removedWrappedBalanceRaw Amount of wrapped returned
     */
    function removeLiquidityFromBuffer(
        IERC4626 wrappedToken,
        uint256 sharesToRemove,
        uint256 minAmountUnderlyingOutRaw,
        uint256 minAmountWrappedOutRaw
    ) external nonReentrant returns (uint256 removedUnderlyingBalanceRaw, uint256 removedWrappedBalanceRaw) {
        // Ensure buffer is initialized
        if (BalancerV3VaultStorageRepo._bufferAsset(wrappedToken) == address(0)) {
            revert BufferNotInitialized(wrappedToken);
        }

        // Check sender has enough shares
        uint256 senderShares = BalancerV3VaultStorageRepo._bufferLpShares(wrappedToken, msg.sender);
        if (senderShares < sharesToRemove) {
            revert NotEnoughBufferShares();
        }

        // Get current buffer state
        bytes32 currentBalance = BalancerV3VaultStorageRepo._bufferTokenBalance(wrappedToken);
        uint256 currentUnderlying = currentBalance.getBalanceRaw();
        uint256 currentWrapped = currentBalance.getBalanceDerived();
        uint256 currentTotal = BalancerV3VaultStorageRepo._bufferTotalShares(wrappedToken);

        // Calculate proportional amounts out
        removedUnderlyingBalanceRaw = (currentUnderlying * sharesToRemove) / currentTotal;
        removedWrappedBalanceRaw = (currentWrapped * sharesToRemove) / currentTotal;

        // Check minimums
        if (removedUnderlyingBalanceRaw < minAmountUnderlyingOutRaw) {
            revert AmountOutBelowMin(IERC20(address(wrappedToken)), removedUnderlyingBalanceRaw, minAmountUnderlyingOutRaw);
        }
        if (removedWrappedBalanceRaw < minAmountWrappedOutRaw) {
            revert AmountOutBelowMin(IERC20(address(wrappedToken)), removedWrappedBalanceRaw, minAmountWrappedOutRaw);
        }

        // Update state
        BalancerV3VaultStorageRepo._setBufferTotalShares(wrappedToken, currentTotal - sharesToRemove);
        BalancerV3VaultStorageRepo._setBufferLpShares(wrappedToken, msg.sender, senderShares - sharesToRemove);

        bytes32 newBalance = PackedTokenBalance.toPackedBalance(
            currentUnderlying - removedUnderlyingBalanceRaw,
            currentWrapped - removedWrappedBalanceRaw
        );
        BalancerV3VaultStorageRepo._setBufferTokenBalance(wrappedToken, newBalance);

        emit BufferSharesBurned(wrappedToken, msg.sender, sharesToRemove);
    }
}
