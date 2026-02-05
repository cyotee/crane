// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {Math} from "@crane/contracts/utils/Math.sol";

import {
    IBalancerContractRegistry
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/standalone-utils/IBalancerContractRegistry.sol";
import {ISenderGuard} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISenderGuard.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    HooksConfig,
    HookFlags,
    LiquidityManagement,
    PoolSwapParams,
    RemoveLiquidityKind,
    TokenConfig,
    MAX_FEE_PERCENTAGE
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {SingletonAuthentication} from "@crane/contracts/external/balancer/v3/vault/contracts/SingletonAuthentication.sol";

import {BaseHooksTarget} from "./BaseHooksTarget.sol";

/* -------------------------------------------------------------------------- */
/*                               IMevCaptureHook                              */
/* -------------------------------------------------------------------------- */

/**
 * @title IMevCaptureHook
 * @notice Interface for the MEV Capture Hook.
 */
interface IMevCaptureHook {
    event MevTaxEnabledSet(bool enabled);
    event MaxMevSwapFeePercentageSet(uint256 maxMevSwapFeePercentage);
    event DefaultMevTaxMultiplierSet(uint256 defaultMevTaxMultiplier);
    event DefaultMevTaxThresholdSet(uint256 defaultMevTaxThreshold);
    event PoolMevTaxMultiplierSet(address indexed pool, uint256 poolMevTaxMultiplier);
    event PoolMevTaxThresholdSet(address indexed pool, uint256 poolMevTaxThreshold);
    event MevTaxExemptSenderAdded(address indexed sender);
    event MevTaxExemptSenderRemoved(address indexed sender);

    error MevCaptureHookNotRegisteredInPool(address pool);
    error InvalidBalancerContractRegistry();
    error MevSwapFeePercentageAboveMax(uint256 feePercentage, uint256 maxAllowed);
    error MevTaxExemptSenderAlreadyAdded(address sender);
    error SenderNotRegisteredAsMevTaxExempt(address sender);

    function isMevTaxEnabled() external view returns (bool);
    function disableMevTax() external;
    function enableMevTax() external;
    function getMaxMevSwapFeePercentage() external view returns (uint256);
    function setMaxMevSwapFeePercentage(uint256 maxMevSwapFeePercentage) external;
    function getDefaultMevTaxMultiplier() external view returns (uint256);
    function setDefaultMevTaxMultiplier(uint256 newDefaultMevTaxMultiplier) external;
    function getPoolMevTaxMultiplier(address pool) external view returns (uint256);
    function setPoolMevTaxMultiplier(address pool, uint256 newPoolMevTaxMultiplier) external;
    function getDefaultMevTaxThreshold() external view returns (uint256);
    function setDefaultMevTaxThreshold(uint256 newDefaultMevTaxThreshold) external;
    function getPoolMevTaxThreshold(address pool) external view returns (uint256);
    function setPoolMevTaxThreshold(address pool, uint256 newPoolMevTaxThreshold) external;
    function isMevTaxExemptSender(address sender) external view returns (bool);
    function addMevTaxExemptSenders(address[] memory senders) external;
    function removeMevTaxExemptSenders(address[] memory senders) external;
}

/* -------------------------------------------------------------------------- */
/*                              MevCaptureHook                                */
/* -------------------------------------------------------------------------- */

/**
 * @title MevCaptureHook
 * @notice Hook that captures MEV by charging higher fees to high-priority transactions.
 * @dev Uses priority gas price (tx.gasprice - block.basefee) to identify MEV opportunities.
 *
 * MEV Tax mechanism:
 * - Transactions with priority gas > threshold pay higher swap fees
 * - Fee increases based on: (priorityGas - threshold) * multiplier
 * - Trusted routers can exempt specific senders from the tax
 *
 * This helps pools capture value that would otherwise go to MEV searchers.
 *
 * @custom:security-contact security@example.com
 */
contract MevCaptureHook is BaseHooksTarget, SingletonAuthentication, IMevCaptureHook {
    /* ========================================================================== */
    /*                                  CONSTANTS                                 */
    /* ========================================================================== */

    /// @notice Maximum fee percentage allowed (99.9999% - same as Vault max).
    uint256 private constant _MEV_MAX_FEE_PERCENTAGE = MAX_FEE_PERCENTAGE;

    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice Registry of trusted Balancer contracts.
    IBalancerContractRegistry internal immutable _registry;

    /// @notice Whether MEV tax is currently enabled.
    bool internal _mevTaxEnabled;

    /// @notice Default multiplier for fee calculation.
    uint256 internal _defaultMevTaxMultiplier;

    /// @notice Default threshold below which no MEV tax applies.
    uint256 internal _defaultMevTaxThreshold;

    /// @notice Maximum swap fee percentage this hook can charge.
    uint256 internal _maxMevSwapFeePercentage;

    /// @notice Addresses exempt from MEV tax (via trusted router).
    mapping(address => bool) internal _isMevTaxExemptSender;

    /// @notice Per-pool MEV tax thresholds.
    mapping(address => uint256) internal _poolMevTaxThresholds;

    /// @notice Per-pool MEV tax multipliers.
    mapping(address => uint256) internal _poolMevTaxMultipliers;

    /* ========================================================================== */
    /*                                  MODIFIERS                                 */
    /* ========================================================================== */

    modifier withMevTaxEnabledPool(address pool) {
        HooksConfig memory hooksConfig = _vault.getHooksConfig(pool);
        if (hooksConfig.hooksContract != address(this)) {
            revert MevCaptureHookNotRegisteredInPool(pool);
        }
        _;
    }

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new MevCaptureHook.
     * @param vault_ The Balancer V3 Vault.
     * @param registry_ The Balancer contract registry.
     * @param defaultMevTaxMultiplier_ Default multiplier for fee calculation.
     * @param defaultMevTaxThreshold_ Default priority gas threshold.
     */
    constructor(
        IVault vault_,
        IBalancerContractRegistry registry_,
        uint256 defaultMevTaxMultiplier_,
        uint256 defaultMevTaxThreshold_
    ) BaseHooksTarget(vault_) SingletonAuthentication(vault_) {
        _registry = registry_;

        // Verify registry isn't broken (trusting address(0) would be a red flag)
        if (registry_.isTrustedRouter(address(0))) {
            revert InvalidBalancerContractRegistry();
        }

        _setMevTaxEnabled(true);
        _setDefaultMevTaxMultiplier(defaultMevTaxMultiplier_);
        _setDefaultMevTaxThreshold(defaultMevTaxThreshold_);
        _setMaxMevSwapFeePercentage(_MEV_MAX_FEE_PERCENTAGE);
    }

    /* ========================================================================== */
    /*                               HOOK CALLBACKS                               */
    /* ========================================================================== */

    /// @inheritdoc BaseHooksTarget
    function onRegister(
        address,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        _poolMevTaxMultipliers[pool] = _defaultMevTaxMultiplier;
        _poolMevTaxThresholds[pool] = _defaultMevTaxThreshold;
        return true;
    }

    /// @inheritdoc BaseHooksTarget
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
        hookFlags.shouldCallBeforeAddLiquidity = true;
        hookFlags.shouldCallBeforeRemoveLiquidity = true;
    }

    /// @inheritdoc BaseHooksTarget
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) public view override returns (bool, uint256) {
        if (_mevTaxEnabled == false) {
            return (true, staticSwapFeePercentage);
        }

        // Check exemption via trusted router
        if (_registry.isTrustedRouter(params.router)) {
            address sender = ISenderGuard(params.router).getSender();
            if (_isMevTaxExemptSender[sender]) {
                return (true, staticSwapFeePercentage);
            }
        }

        return (
            true,
            _calculateSwapFeePercentage(
                staticSwapFeePercentage,
                _poolMevTaxMultipliers[pool],
                _poolMevTaxThresholds[pool]
            )
        );
    }

    /// @inheritdoc BaseHooksTarget
    function onBeforeAddLiquidity(
        address,
        address pool,
        AddLiquidityKind kind,
        uint256[] memory,
        uint256,
        uint256[] memory,
        bytes memory
    ) public view override returns (bool success) {
        if (_mevTaxEnabled == false) {
            return true;
        }

        uint256 priorityGasPrice = _getPriorityGasPrice();

        // Allow proportional or low-priority operations
        return kind == AddLiquidityKind.PROPORTIONAL ||
            priorityGasPrice <= _poolMevTaxThresholds[pool];
    }

    /// @inheritdoc BaseHooksTarget
    function onBeforeRemoveLiquidity(
        address,
        address pool,
        RemoveLiquidityKind kind,
        uint256,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public view override returns (bool success) {
        if (_mevTaxEnabled == false) {
            return true;
        }

        uint256 priorityGasPrice = _getPriorityGasPrice();

        // Allow proportional or low-priority operations
        return kind == RemoveLiquidityKind.PROPORTIONAL ||
            priorityGasPrice <= _poolMevTaxThresholds[pool];
    }

    /* ========================================================================== */
    /*                             GETTERS / SETTERS                              */
    /* ========================================================================== */

    function getBalancerContractRegistry() external view returns (IBalancerContractRegistry) {
        return _registry;
    }

    /// @inheritdoc IMevCaptureHook
    function isMevTaxEnabled() external view returns (bool) {
        return _mevTaxEnabled;
    }

    /// @inheritdoc IMevCaptureHook
    function disableMevTax() external authenticate {
        _setMevTaxEnabled(false);
    }

    /// @inheritdoc IMevCaptureHook
    function enableMevTax() external authenticate {
        _setMevTaxEnabled(true);
    }

    /// @inheritdoc IMevCaptureHook
    function getMaxMevSwapFeePercentage() external view returns (uint256) {
        return _maxMevSwapFeePercentage;
    }

    /// @inheritdoc IMevCaptureHook
    function setMaxMevSwapFeePercentage(uint256 maxMevSwapFeePercentage) external authenticate {
        _setMaxMevSwapFeePercentage(maxMevSwapFeePercentage);
    }

    /// @inheritdoc IMevCaptureHook
    function getDefaultMevTaxMultiplier() external view returns (uint256) {
        return _defaultMevTaxMultiplier;
    }

    /// @inheritdoc IMevCaptureHook
    function setDefaultMevTaxMultiplier(uint256 newDefaultMevTaxMultiplier) external authenticate {
        _setDefaultMevTaxMultiplier(newDefaultMevTaxMultiplier);
    }

    /// @inheritdoc IMevCaptureHook
    function getPoolMevTaxMultiplier(address pool) external view withMevTaxEnabledPool(pool) returns (uint256) {
        return _poolMevTaxMultipliers[pool];
    }

    /// @inheritdoc IMevCaptureHook
    function setPoolMevTaxMultiplier(
        address pool,
        uint256 newPoolMevTaxMultiplier
    ) external withMevTaxEnabledPool(pool) onlySwapFeeManagerOrGovernance(pool) {
        _poolMevTaxMultipliers[pool] = newPoolMevTaxMultiplier;
        emit PoolMevTaxMultiplierSet(pool, newPoolMevTaxMultiplier);
    }

    /// @inheritdoc IMevCaptureHook
    function getDefaultMevTaxThreshold() external view returns (uint256) {
        return _defaultMevTaxThreshold;
    }

    /// @inheritdoc IMevCaptureHook
    function setDefaultMevTaxThreshold(uint256 newDefaultMevTaxThreshold) external authenticate {
        _setDefaultMevTaxThreshold(newDefaultMevTaxThreshold);
    }

    /// @inheritdoc IMevCaptureHook
    function getPoolMevTaxThreshold(address pool) external view withMevTaxEnabledPool(pool) returns (uint256) {
        return _poolMevTaxThresholds[pool];
    }

    /// @inheritdoc IMevCaptureHook
    function setPoolMevTaxThreshold(
        address pool,
        uint256 newPoolMevTaxThreshold
    ) external withMevTaxEnabledPool(pool) onlySwapFeeManagerOrGovernance(pool) {
        _poolMevTaxThresholds[pool] = newPoolMevTaxThreshold;
        emit PoolMevTaxThresholdSet(pool, newPoolMevTaxThreshold);
    }

    /// @inheritdoc IMevCaptureHook
    function isMevTaxExemptSender(address sender) external view returns (bool) {
        return _isMevTaxExemptSender[sender];
    }

    /// @inheritdoc IMevCaptureHook
    function addMevTaxExemptSenders(address[] memory senders) external authenticate {
        for (uint256 i = 0; i < senders.length; ++i) {
            _addMevTaxExemptSender(senders[i]);
        }
    }

    /// @inheritdoc IMevCaptureHook
    function removeMevTaxExemptSenders(address[] memory senders) external authenticate {
        for (uint256 i = 0; i < senders.length; ++i) {
            _removeMevTaxExemptSender(senders[i]);
        }
    }

    /* ========================================================================== */
    /*                              INTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    function _calculateSwapFeePercentage(
        uint256 staticSwapFeePercentage,
        uint256 multiplier,
        uint256 threshold
    ) internal view returns (uint256) {
        uint256 priorityGasPrice = _getPriorityGasPrice();
        uint256 maxMevSwapFeePercentage = _maxMevSwapFeePercentage;

        // No tax for low-priority transactions or if cap is below static fee
        if (priorityGasPrice <= threshold || maxMevSwapFeePercentage <= staticSwapFeePercentage) {
            return staticSwapFeePercentage;
        }

        (bool success, uint256 feeIncrement) = Math.tryMul(priorityGasPrice - threshold, multiplier);

        // Overflow means very high priority = max fee
        if (success == false) {
            return maxMevSwapFeePercentage;
        }

        // Fix 18-decimal precision
        feeIncrement = feeIncrement / 1e18;

        uint256 mevSwapFeePercentage = staticSwapFeePercentage + feeIncrement;

        return Math.min(mevSwapFeePercentage, maxMevSwapFeePercentage);
    }

    function _getPriorityGasPrice() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    function _setMevTaxEnabled(bool value) private {
        _mevTaxEnabled = value;
        emit MevTaxEnabledSet(value);
    }

    function _setMaxMevSwapFeePercentage(uint256 maxMevSwapFeePercentage) internal {
        if (maxMevSwapFeePercentage > _MEV_MAX_FEE_PERCENTAGE) {
            revert MevSwapFeePercentageAboveMax(maxMevSwapFeePercentage, _MEV_MAX_FEE_PERCENTAGE);
        }
        _maxMevSwapFeePercentage = maxMevSwapFeePercentage;
        emit MaxMevSwapFeePercentageSet(maxMevSwapFeePercentage);
    }

    function _setDefaultMevTaxMultiplier(uint256 newDefaultMevTaxMultiplier) private {
        _defaultMevTaxMultiplier = newDefaultMevTaxMultiplier;
        emit DefaultMevTaxMultiplierSet(newDefaultMevTaxMultiplier);
    }

    function _setDefaultMevTaxThreshold(uint256 newDefaultMevTaxThreshold) private {
        _defaultMevTaxThreshold = newDefaultMevTaxThreshold;
        emit DefaultMevTaxThresholdSet(newDefaultMevTaxThreshold);
    }

    function _addMevTaxExemptSender(address sender) internal {
        if (_isMevTaxExemptSender[sender]) {
            revert MevTaxExemptSenderAlreadyAdded(sender);
        }
        _isMevTaxExemptSender[sender] = true;
        emit MevTaxExemptSenderAdded(sender);
    }

    function _removeMevTaxExemptSender(address sender) internal {
        if (_isMevTaxExemptSender[sender] == false) {
            revert SenderNotRegisteredAsMevTaxExempt(sender);
        }
        _isMevTaxExemptSender[sender] = false;
        emit MevTaxExemptSenderRemoved(sender);
    }
}
