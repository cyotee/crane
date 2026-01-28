// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IAuthentication} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";

import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";
import {VaultStateLib, VaultStateBits} from "@balancer-labs/v3-vault/contracts/lib/VaultStateLib.sol";

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
contract VaultAdminFacet is BalancerV3VaultModifiers {
    using PackedTokenBalance for bytes32;
    using PoolConfigLib for PoolConfigBits;
    using VaultStateLib for VaultStateBits;
    using SafeCast for *;
    using FixedPoint for uint256;

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
}
