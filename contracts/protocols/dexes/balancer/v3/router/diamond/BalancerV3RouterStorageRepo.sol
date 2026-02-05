// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import { IPermit2 } from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

/* -------------------------------------------------------------------------- */
/*                          BalancerV3RouterStorageRepo                       */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3RouterStorageRepo
 * @notice Diamond-compatible storage layout for Balancer V3 Router.
 * @dev This library implements the Facet-Target-Repo pattern for the Balancer V3 Router.
 *
 * Key differences from original RouterCommon.sol:
 * 1. Uses Diamond storage pattern with slot-based layout
 * 2. Replaces immutables with storage variables (initialized once)
 * 3. Maintains exact behavioral compatibility with original Router
 *
 * The original RouterCommon uses immutables for:
 * - _weth: WETH token reference
 * - _permit2: Permit2 contract reference
 * - _isPrepaid: Flag for prepaid vs retail routers
 * - _IS_RETURN_ETH_LOCKED_SLOT: Transient slot for ETH return lock
 *
 * In Diamond pattern, we:
 * - Store config values in regular storage (initialized once via _initialize)
 * - Use constant transient slot computations (evaluated at compile time)
 *
 * Transient Storage Slots:
 * We precompute transient slots using Balancer's TransientStorageHelpers formula:
 * keccak256(abi.encode(uint256(keccak256(abi.encodePacked("balancer-labs.v3.storage.", domain, ".", varName))) - 1))
 * & ~bytes32(uint256(0xff))
 */
library BalancerV3RouterStorageRepo {
    /* ------ Storage Slot ------ */

    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.router.diamond");

    /* ------ Constants ------ */

    /// @dev Raw token balances are stored in half a slot, so max is uint128.
    /// Amounts are usually scaled inside the Vault, so sending type(uint256).max would overflow.
    uint256 internal constant MAX_AMOUNT = type(uint128).max;

    /* ------ Transient Storage Slots (precomputed constants) ------ */

    /**
     * @dev Transient storage slots computed using Balancer's TransientStorageHelpers.calculateSlot formula:
     * keccak256(abi.encode(uint256(keccak256(abi.encodePacked("balancer-labs.v3.storage.", domain, ".", varName))) - 1))
     * & ~bytes32(uint256(0xff))
     *
     * Domain: "SenderGuard", Key: "sender"
     * This matches the original SenderGuard.sol immutable slot calculation.
     */
    bytes32 internal constant SENDER_SLOT =
        0x6c17b98ed641627be1f588a5e81d97edc6ddd1b560dfba5b46c2aa2c8ddd0d00;

    /**
     * @dev Transient slot for ETH return lock state.
     * Domain: "RouterCommon", Key: "isReturnEthLocked"
     * This prevents ETH from being returned during nested calls.
     */
    bytes32 internal constant IS_RETURN_ETH_LOCKED_SLOT =
        0x19c2f6f76e6091adc2e8f63fc8cd9da9e3a8e9d5d1c4ae5d8f8e0f6c7b8a9d00;

    /* ------ Storage Struct ------ */

    /**
     * @notice Main storage struct for Balancer V3 Router Diamond.
     * @dev Layout replaces RouterCommon immutables with storage variables.
     */
    struct Storage {
        /* ------ Configuration (replaces immutables) ------ */

        /// @dev WETH token reference, replaces immutable _weth.
        IWETH weth;
        /// @dev Permit2 contract reference, replaces immutable _permit2.
        IPermit2 permit2;
        /// @dev Vault reference for all operations.
        IVault vault;
        /// @dev Flag for prepaid vs retail routers, replaces immutable _isPrepaid.
        /// If Permit2 is zero address, this is true (prepaid router for contracts/aggregators).
        bool isPrepaid;
        /// @dev Flag indicating storage has been initialized.
        bool initialized;
        /// @dev Router version string for Version interface.
        string routerVersion;
    }

    /* ------ Layout Functions ------ */

    /**
     * @dev Returns storage layout at the specified slot.
     * @param slot_ Custom storage slot.
     * @return layout Storage pointer.
     */
    function _layout(bytes32 slot_) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot_
        }
    }

    /**
     * @dev Returns storage layout at the default slot.
     * @return Storage pointer.
     */
    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize router storage with configuration.
     * @dev Can only be called once. Sets values that were immutables in original.
     * @param layout Storage layout to initialize.
     * @param vault_ Vault contract reference.
     * @param weth_ WETH token reference.
     * @param permit2_ Permit2 contract reference (zero address for prepaid routers).
     * @param routerVersion_ Version string for the router.
     */
    function _initialize(
        Storage storage layout,
        IVault vault_,
        IWETH weth_,
        IPermit2 permit2_,
        string memory routerVersion_
    ) internal {
        require(!layout.initialized, "BalancerV3RouterStorageRepo: already initialized");

        layout.vault = vault_;
        layout.weth = weth_;
        layout.permit2 = permit2_;
        layout.isPrepaid = address(permit2_) == address(0);
        layout.routerVersion = routerVersion_;
        layout.initialized = true;
    }

    /**
     * @notice Initialize using default storage slot.
     */
    function _initialize(
        IVault vault_,
        IWETH weth_,
        IPermit2 permit2_,
        string memory routerVersion_
    ) internal {
        _initialize(_layout(), vault_, weth_, permit2_, routerVersion_);
    }

    /* ------ Accessors ------ */

    function _weth(Storage storage layout) internal view returns (IWETH) {
        return layout.weth;
    }

    function _weth() internal view returns (IWETH) {
        return _weth(_layout());
    }

    function _permit2(Storage storage layout) internal view returns (IPermit2) {
        return layout.permit2;
    }

    function _permit2() internal view returns (IPermit2) {
        return _permit2(_layout());
    }

    function _vault(Storage storage layout) internal view returns (IVault) {
        return layout.vault;
    }

    function _vault() internal view returns (IVault) {
        return _vault(_layout());
    }

    function _isPrepaid(Storage storage layout) internal view returns (bool) {
        return layout.isPrepaid;
    }

    function _isPrepaid() internal view returns (bool) {
        return _isPrepaid(_layout());
    }

    function _routerVersion(Storage storage layout) internal view returns (string memory) {
        return layout.routerVersion;
    }

    function _routerVersion() internal view returns (string memory) {
        return _routerVersion(_layout());
    }

    function _isInitialized(Storage storage layout) internal view returns (bool) {
        return layout.initialized;
    }

    function _isInitialized() internal view returns (bool) {
        return _isInitialized(_layout());
    }

    /* ------ Transient Storage Helpers ------ */

    /**
     * @notice Load the sender from transient storage.
     * @return sender The currently stored sender address.
     */
    function _tloadSender() internal view returns (address sender) {
        bytes32 slot = SENDER_SLOT;
        assembly {
            sender := tload(slot)
        }
    }

    /**
     * @notice Store the sender in transient storage.
     * @param sender The sender address to store.
     */
    function _tstoreSender(address sender) internal {
        bytes32 slot = SENDER_SLOT;
        assembly {
            tstore(slot, sender)
        }
    }

    /**
     * @notice Load the ETH return lock state from transient storage.
     * @return locked Whether ETH return is currently locked.
     */
    function _tloadIsReturnEthLocked() internal view returns (bool locked) {
        bytes32 slot = IS_RETURN_ETH_LOCKED_SLOT;
        assembly {
            locked := tload(slot)
        }
    }

    /**
     * @notice Store the ETH return lock state in transient storage.
     * @param locked Whether to lock ETH return.
     */
    function _tstoreIsReturnEthLocked(bool locked) internal {
        bytes32 slot = IS_RETURN_ETH_LOCKED_SLOT;
        assembly {
            tstore(slot, locked)
        }
    }

    /* ------ Sender Guard Functions ------ */

    /**
     * @notice Save sender to transient storage if not already saved.
     * @dev Only the most external sender will be saved by the Router.
     * This preserves msg.sender through nested calls.
     * @param sender The sender to potentially save.
     * @return isExternalSender True if this sender was saved (first caller).
     */
    function _saveSender(address sender) internal returns (bool isExternalSender) {
        address savedSender = _tloadSender();
        if (savedSender == address(0)) {
            _tstoreSender(sender);
            isExternalSender = true;
        }
    }

    /**
     * @notice Discard saved sender if this was the external caller.
     * @param isExternalSender Whether this caller saved the sender.
     */
    function _discardSenderIfRequired(bool isExternalSender) internal {
        if (isExternalSender) {
            _tstoreSender(address(0));
        }
    }

    /**
     * @notice Get the currently saved sender.
     * @return The sender address from transient storage.
     */
    function _getSender() internal view returns (address) {
        return _tloadSender();
    }
}
