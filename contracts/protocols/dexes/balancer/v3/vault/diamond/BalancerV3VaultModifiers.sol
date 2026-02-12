// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {SafeCast} from "@crane/contracts/utils/SafeCast.sol";

import {IVaultErrors} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultErrors.sol";
import {IVaultEvents} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultEvents.sol";
import {PoolData, Rounding} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {IAuthentication} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

import {StorageSlotExtension} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/openzeppelin/StorageSlotExtension.sol";
import {EVMCallModeHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/EVMCallModeHelpers.sol";
import {PackedTokenBalance} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/PackedTokenBalance.sol";
import {ScalingHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/ScalingHelpers.sol";
import {
    TransientStorageHelpers,
    TokenDeltaMappingSlotType,
    UintToAddressToBooleanMappingSlot
} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/TransientStorageHelpers.sol";

import {VaultStateBits, VaultStateLib} from "@crane/contracts/external/balancer/v3/vault/contracts/lib/VaultStateLib.sol";
import {PoolConfigBits, PoolConfigLib} from "@crane/contracts/external/balancer/v3/vault/contracts/lib/PoolConfigLib.sol";
import {PoolDataLib} from "@crane/contracts/external/balancer/v3/vault/contracts/lib/PoolDataLib.sol";

import {BalancerV3VaultStorageRepo} from "./BalancerV3VaultStorageRepo.sol";
import {BalancerV3ReentrancyGuardRepo} from "./BalancerV3ReentrancyGuardRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                          BalancerV3VaultModifiers                          */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3VaultModifiers
 * @notice Shared modifiers and internal functions for Balancer V3 Vault facets.
 * @dev This abstract contract provides:
 * - Transient storage accessors (matching VaultStorage)
 * - Common modifiers (onlyWhenUnlocked, whenVaultNotPaused, etc.)
 * - Delta accounting functions
 * - Pool data loading utilities
 *
 * Inherits from IVaultErrors and IVaultEvents for error/event definitions.
 * Uses storage repo pattern for Diamond compatibility.
 */
abstract contract BalancerV3VaultModifiers is IVaultEvents, IVaultErrors {
    using BalancerV3VaultStorageRepo for BalancerV3VaultStorageRepo.Storage;
    using BalancerV3ReentrancyGuardRepo for BalancerV3ReentrancyGuardRepo.Storage;
    using BetterEfficientHashLib for bytes;
    using PoolConfigLib for PoolConfigBits;
    using VaultStateLib for VaultStateBits;
    using SafeCast for *;
    using TransientStorageHelpers for *;
    using StorageSlotExtension for *;
    using PackedTokenBalance for bytes32;
    using PoolDataLib for PoolData;

    /* ========================================================================== */
    /*                             TRANSIENT STORAGE                              */
    /* ========================================================================== */

    /**
     * @dev Returns the transient slot for unlock state.
     */
    function _isUnlocked() internal view returns (StorageSlotExtension.BooleanSlotType slot) {
        return BalancerV3VaultStorageRepo.IS_UNLOCKED_SLOT.asBoolean();
    }

    /**
     * @dev Returns the transient slot for non-zero delta count.
     */
    function _nonZeroDeltaCount() internal view returns (StorageSlotExtension.Uint256SlotType slot) {
        return BalancerV3VaultStorageRepo.NON_ZERO_DELTA_COUNT_SLOT.asUint256();
    }

    /**
     * @dev Returns the transient slot for token deltas mapping.
     */
    function _tokenDeltas() internal view returns (TokenDeltaMappingSlotType slot) {
        return TokenDeltaMappingSlotType.wrap(BalancerV3VaultStorageRepo.TOKEN_DELTAS_SLOT);
    }

    /**
     * @dev Returns the transient slot for add liquidity called flag.
     */
    function _addLiquidityCalled() internal view returns (UintToAddressToBooleanMappingSlot slot) {
        return UintToAddressToBooleanMappingSlot.wrap(BalancerV3VaultStorageRepo.ADD_LIQUIDITY_CALLED_SLOT);
    }

    /**
     * @dev Returns the transient slot for session ID.
     */
    function _sessionIdSlot() internal view returns (StorageSlotExtension.Uint256SlotType slot) {
        return BalancerV3VaultStorageRepo.SESSION_ID_SLOT.asUint256();
    }

    /* ========================================================================== */
    /*                                 MODIFIERS                                  */
    /* ========================================================================== */

    /**
     * @dev Ensures the vault is unlocked (within an unlock/settle transaction).
     */
    modifier onlyWhenUnlocked() {
        _ensureUnlocked();
        _;
    }

    /**
     * @dev Ensures the vault is not paused.
     */
    modifier whenVaultNotPaused() {
        _ensureVaultNotPaused();
        _;
    }

    /**
     * @dev Ensures vault buffers are not paused.
     */
    modifier whenVaultBuffersAreNotPaused() {
        _ensureVaultBuffersAreNotPaused();
        _;
    }

    /**
     * @dev Ensures the pool is registered.
     */
    modifier withRegisteredPool(address pool) {
        _ensureRegisteredPool(pool);
        _;
    }

    /**
     * @dev Ensures the pool is initialized.
     */
    modifier withInitializedPool(address pool) {
        _ensureInitializedPool(pool);
        _;
    }

    /**
     * @dev Ensures the buffer is initialized.
     */
    modifier withInitializedBuffer(IERC4626 wrappedToken) {
        _ensureBufferInitialized(wrappedToken);
        _;
    }

    /**
     * @dev Ensures the pool is in recovery mode.
     */
    modifier onlyInRecoveryMode(address pool) {
        _ensurePoolInRecoveryMode(pool);
        _;
    }

    /**
     * @dev Reentrancy guard using transient storage.
     */
    modifier nonReentrant() {
        BalancerV3ReentrancyGuardRepo._nonReentrantBefore();
        _;
        BalancerV3ReentrancyGuardRepo._nonReentrantAfter();
    }

    /**
     * @dev Ensures only the protocol fee controller can call this function.
     */
    modifier onlyProtocolFeeController() {
        _ensureCallerIsProtocolFeeController();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call this function (via authorizer).
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /* ========================================================================== */
    /*                             INTERNAL FUNCTIONS                             */
    /* ========================================================================== */

    /* ------ Unlock State ------ */

    function _ensureUnlocked() internal view {
        if (_isUnlocked().tload() == false) {
            revert VaultIsNotUnlocked();
        }
    }

    /**
     * @notice Expose the state of the Vault's reentrancy guard.
     * @return True if the Vault is currently executing a nonReentrant function
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return BalancerV3ReentrancyGuardRepo._reentrancyGuardEntered();
    }

    /* ------ Delta Accounting ------ */

    /**
     * @notice Records the `credit` for a given token.
     * @param token The ERC20 token for which the 'credit' will be accounted
     * @param credit The amount of `token` supplied to the Vault in favor of the caller
     */
    function _supplyCredit(IERC20 token, uint256 credit) internal {
        _accountDelta(token, -credit.toInt256());
    }

    /**
     * @notice Records the `debt` for a given token.
     * @param token The ERC20 token for which the `debt` will be accounted
     * @param debt The amount of `token` taken from the Vault in favor of the caller
     */
    function _takeDebt(IERC20 token, uint256 debt) internal {
        _accountDelta(token, debt.toInt256());
    }

    /**
     * @dev Accounts the delta for the given token.
     * Positive delta = debt, negative delta = credit.
     */
    function _accountDelta(IERC20 token, int256 delta) internal {
        if (delta == 0) return;

        int256 current = _tokenDeltas().tGet(token);
        int256 next = current + delta;

        if (next == 0) {
            _nonZeroDeltaCount().tDecrement();
        } else if (current == 0) {
            _nonZeroDeltaCount().tIncrement();
        }

        _tokenDeltas().tSet(token, next);
    }

    /* ------ Vault Pausing ------ */

    function _ensureVaultNotPaused() internal view {
        if (_isVaultPaused()) {
            revert VaultPaused();
        }
    }

    function _ensureUnpaused(address pool) internal view {
        _ensureVaultNotPaused();
        _ensurePoolNotPaused(pool);
    }

    function _isVaultPaused() internal view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp <= BalancerV3VaultStorageRepo._vaultBufferPeriodEndTime() &&
               BalancerV3VaultStorageRepo._vaultStateBits().isVaultPaused();
    }

    /* ------ Pool Pausing ------ */

    function _ensurePoolNotPaused(address pool) internal view {
        if (_isPoolPaused(pool)) {
            revert PoolPaused(pool);
        }
    }

    function _isPoolPaused(address pool) internal view returns (bool) {
        (bool paused, ) = _getPoolPausedState(pool);
        return paused;
    }

    function _getPoolPausedState(address pool) internal view returns (bool, uint32) {
        PoolConfigBits config = BalancerV3VaultStorageRepo._poolConfigBits(pool);

        bool isPoolPaused = config.isPoolPaused();
        uint32 pauseWindowEndTime = config.getPauseWindowEndTime();

        // Use the Vault's buffer period.
        // solhint-disable-next-line not-rely-on-time
        return (
            isPoolPaused && block.timestamp <= pauseWindowEndTime + BalancerV3VaultStorageRepo._vaultBufferPeriodDuration(),
            pauseWindowEndTime
        );
    }

    /* ------ Buffer Pausing ------ */

    function _ensureVaultBuffersAreNotPaused() internal view {
        if (BalancerV3VaultStorageRepo._vaultStateBits().areBuffersPaused()) {
            revert VaultBuffersArePaused();
        }
    }

    /* ------ Pool Registration ------ */

    function _ensureRegisteredPool(address pool) internal view {
        if (!_isPoolRegistered(pool)) {
            revert PoolNotRegistered(pool);
        }
    }

    function _isPoolRegistered(address pool) internal view returns (bool) {
        return BalancerV3VaultStorageRepo._poolConfigBits(pool).isPoolRegistered();
    }

    function _ensureInitializedPool(address pool) internal view {
        if (!_isPoolInitialized(pool)) {
            revert PoolNotInitialized(pool);
        }
    }

    function _isPoolInitialized(address pool) internal view returns (bool) {
        return BalancerV3VaultStorageRepo._poolConfigBits(pool).isPoolInitialized();
    }

    /* ------ Buffer Initialization ------ */

    function _ensureBufferInitialized(IERC4626 wrappedToken) internal view {
        if (BalancerV3VaultStorageRepo._bufferAsset(wrappedToken) == address(0)) {
            revert BufferNotInitialized(wrappedToken);
        }
    }

    function _ensureCorrectBufferAsset(IERC4626 wrappedToken, address underlyingToken) internal view {
        if (BalancerV3VaultStorageRepo._bufferAsset(wrappedToken) != underlyingToken) {
            revert WrongUnderlyingToken(wrappedToken, underlyingToken);
        }
    }

    /* ------ Recovery Mode ------ */

    function _ensurePoolInRecoveryMode(address pool) internal view {
        if (!_isPoolInRecoveryMode(pool)) {
            revert PoolNotInRecoveryMode(pool);
        }
    }

    function _ensurePoolNotInRecoveryMode(address pool) internal view {
        if (_isPoolInRecoveryMode(pool)) {
            revert PoolInRecoveryMode(pool);
        }
    }

    function _isPoolInRecoveryMode(address pool) internal view returns (bool) {
        return BalancerV3VaultStorageRepo._poolConfigBits(pool).isPoolInRecoveryMode();
    }

    /* ------ Pool Data Utilities ------ */

    /**
     * @dev Packs and sets the raw and live balances of a Pool's tokens to storage.
     */
    function _writePoolBalancesToStorage(address pool, PoolData memory poolData) internal {
        mapping(uint256 tokenIndex => bytes32 packedTokenBalance) storage poolBalances =
            BalancerV3VaultStorageRepo._poolTokenBalances(pool);

        for (uint256 i = 0; i < poolData.balancesRaw.length; ++i) {
            poolBalances[i] = PackedTokenBalance.toPackedBalance(
                poolData.balancesRaw[i],
                poolData.balancesLiveScaled18[i]
            );
        }
    }

    /**
     * @dev Load pool data (view only, no side effects).
     */
    function _loadPoolData(address pool, Rounding roundingDirection) internal view returns (PoolData memory poolData) {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        poolData.load(
            layout.poolTokenBalances[pool],
            layout.poolConfigBits[pool],
            layout.poolTokenInfo[pool],
            layout.poolTokens[pool],
            roundingDirection
        );
    }

    /**
     * @dev Load pool data and update balances and yield fees in storage.
     */
    function _loadPoolDataUpdatingBalancesAndYieldFees(
        address pool,
        Rounding roundingDirection
    ) internal nonReentrant returns (PoolData memory poolData) {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        poolData.load(
            layout.poolTokenBalances[pool],
            layout.poolConfigBits[pool],
            layout.poolTokenInfo[pool],
            layout.poolTokens[pool],
            roundingDirection
        );

        PoolDataLib.syncPoolBalancesAndFees(
            poolData,
            layout.poolTokenBalances[pool],
            layout.aggregateFeeAmounts[pool]
        );
    }

    /**
     * @dev Updates the raw and live token balances in poolData.
     */
    function _updateRawAndLiveTokenBalancesInPoolData(
        PoolData memory poolData,
        uint256 newRawBalance,
        Rounding roundingDirection,
        uint256 tokenIndex
    ) internal pure returns (uint256) {
        poolData.balancesRaw[tokenIndex] = newRawBalance;

        function(uint256, uint256, uint256) internal pure returns (uint256) _upOrDown = roundingDirection ==
            Rounding.ROUND_UP
            ? ScalingHelpers.toScaled18ApplyRateRoundUp
            : ScalingHelpers.toScaled18ApplyRateRoundDown;

        poolData.balancesLiveScaled18[tokenIndex] = _upOrDown(
            newRawBalance,
            poolData.decimalScalingFactors[tokenIndex],
            poolData.tokenRates[tokenIndex]
        );

        return _upOrDown(newRawBalance, poolData.decimalScalingFactors[tokenIndex], poolData.tokenRates[tokenIndex]);
    }

    /**
     * @dev Set static swap fee percentage with validation.
     */
    function _setStaticSwapFeePercentage(address pool, uint256 swapFeePercentage) internal {
        if (swapFeePercentage < ISwapFeePercentageBounds(pool).getMinimumSwapFeePercentage()) {
            revert SwapFeePercentageTooLow();
        }

        if (swapFeePercentage > ISwapFeePercentageBounds(pool).getMaximumSwapFeePercentage()) {
            revert SwapFeePercentageTooHigh();
        }

        PoolConfigBits config = BalancerV3VaultStorageRepo._poolConfigBits(pool);
        BalancerV3VaultStorageRepo._setPoolConfigBits(pool, config.setStaticSwapFeePercentage(swapFeePercentage));

        emit SwapFeePercentageChanged(pool, swapFeePercentage);
    }

    /**
     * @dev Find the index of a token in a token array.
     */
    function _findTokenIndex(IERC20[] memory tokens, IERC20 token) internal pure returns (uint256) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                return i;
            }
        }
        revert TokenNotRegistered(token);
    }

    /**
     * @dev Check if we're in a query context (static call with queries enabled).
     */
    function _isQueryContext() internal view returns (bool) {
        return EVMCallModeHelpers.isStaticCall() &&
               BalancerV3VaultStorageRepo._vaultStateBits().isQueryDisabled() == false;
    }

    /* ------ Authentication ------ */

    function _ensureCallerIsProtocolFeeController() internal view {
        if (msg.sender != address(BalancerV3VaultStorageRepo._protocolFeeController())) {
            revert IAuthentication.SenderNotAllowed();
        }
    }

    function _authenticateCaller() internal view {
        bytes32 actionId = _getActionId(msg.sig);

        if (!BalancerV3VaultStorageRepo._authorizer().canPerform(actionId, msg.sender, address(this))) {
            revert IAuthentication.SenderNotAllowed();
        }
    }

    function _getActionId(bytes4 selector) internal view returns (bytes32) {
        // Compute action ID: keccak256(abi.encodePacked(disambiguator, selector))
        // We use address(this) as the disambiguator for Diamond facets
        // return keccak256(abi.encodePacked(bytes32(uint256(uint160(address(this)))), selector));
        return abi.encodePacked(bytes32(uint256(uint160(address(this)))), selector)._hash();
    }
}
