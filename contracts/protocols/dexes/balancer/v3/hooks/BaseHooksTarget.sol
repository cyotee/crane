// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IHooks} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IVaultErrors} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultErrors.sol";
import {
    AddLiquidityKind,
    HookFlags,
    LiquidityManagement,
    RemoveLiquidityKind,
    TokenConfig,
    PoolSwapParams,
    AfterSwapParams
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                              BaseHooksTarget                               */
/* -------------------------------------------------------------------------- */

/**
 * @title BaseHooksTarget
 * @notice Base contract for Balancer V3 hook implementations following Crane patterns.
 * @dev Provides VaultGuard functionality and default IHooks implementations.
 * Hook contracts inherit from this and override specific callbacks they need.
 *
 * Unlike Balancer's BaseHooks which uses immutable for vault storage,
 * this version stores the vault reference in the constructor but could be
 * extended to use a Repo pattern for more complex hook deployments.
 */
abstract contract BaseHooksTarget is IHooks {
    /* ========================================================================== */
    /*                                   ERRORS                                   */
    /* ========================================================================== */

    /// @notice Thrown when a non-vault address attempts to call a vault-only function.
    error SenderIsNotVault(address sender);

    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice The Balancer V3 Vault this hook is registered with.
    IVault internal immutable _vault;

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new BaseHooksTarget.
     * @param vault_ The Balancer V3 Vault address.
     */
    constructor(IVault vault_) {
        _vault = vault_;
    }

    /* ========================================================================== */
    /*                                  MODIFIERS                                 */
    /* ========================================================================== */

    /**
     * @notice Restricts function access to only the Vault.
     * @dev Reverts with SenderIsNotVault if called by any other address.
     */
    modifier onlyVault() {
        _ensureOnlyVault();
        _;
    }

    /* ========================================================================== */
    /*                              INTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Checks that the caller is the Vault.
     * @dev Called by the onlyVault modifier.
     */
    function _ensureOnlyVault() internal view {
        if (msg.sender != address(_vault)) {
            revert SenderIsNotVault(msg.sender);
        }
    }

    /* ========================================================================== */
    /*                               IHOOKS DEFAULTS                              */
    /* ========================================================================== */

    /// @inheritdoc IHooks
    function onRegister(
        address,
        address,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public virtual returns (bool) {
        // By default, deny all factories. Override in derived contracts.
        return false;
    }

    /// @inheritdoc IHooks
    function getHookFlags() public view virtual returns (HookFlags memory);

    /// @inheritdoc IHooks
    function onBeforeInitialize(uint256[] memory, bytes memory) public virtual returns (bool) {
        return false;
    }

    /// @inheritdoc IHooks
    function onAfterInitialize(uint256[] memory, uint256, bytes memory) public virtual returns (bool) {
        return false;
    }

    /// @inheritdoc IHooks
    function onBeforeAddLiquidity(
        address,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool) {
        return false;
    }

    /// @inheritdoc IHooks
    function onAfterAddLiquidity(
        address,
        address,
        AddLiquidityKind,
        uint256[] memory,
        uint256[] memory amountsInRaw,
        uint256,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool, uint256[] memory) {
        return (false, amountsInRaw);
    }

    /// @inheritdoc IHooks
    function onBeforeRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool) {
        return false;
    }

    /// @inheritdoc IHooks
    function onAfterRemoveLiquidity(
        address,
        address,
        RemoveLiquidityKind,
        uint256,
        uint256[] memory,
        uint256[] memory amountsOutRaw,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bool, uint256[] memory) {
        return (false, amountsOutRaw);
    }

    /// @inheritdoc IHooks
    function onBeforeSwap(PoolSwapParams calldata, address) public virtual returns (bool) {
        return false;
    }

    /// @inheritdoc IHooks
    function onAfterSwap(AfterSwapParams calldata) public virtual returns (bool, uint256) {
        return (false, 0);
    }

    /// @inheritdoc IHooks
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata,
        address,
        uint256
    ) public view virtual returns (bool, uint256) {
        return (false, 0);
    }
}
