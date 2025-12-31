// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IAuthentication} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3VaultAwareStorage
} from "contracts/crane/protocols/dexes/balancer/v3/utils/BalancerV3VaultAwareStorage.sol";

struct BalancerV3AuthenticationLayout {
    bytes32 actionIdDisambiguator;
}

library BalancerV3AuthenticationRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (BalancerV3AuthenticationLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}

contract BalancerV3AuthenticationStorage is BalancerV3VaultAwareStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using EfficientHashLib for bytes;

    using BalancerV3AuthenticationRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(BalancerV3AuthenticationRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(IAuthentication).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_authentication()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _authentication() internal pure virtual returns (BalancerV3AuthenticationLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_authentication()[]

    /* ---------------------------------------------------------------------- */
    /*                             INITIALIZATION                             */
    /* ---------------------------------------------------------------------- */

    function _initBalancerV3Authentication(IVault vault_, bytes32 actionIdDisambiguator_) internal {
        _initBalancerV3VaultAware(vault_);
        _authentication().actionIdDisambiguator = actionIdDisambiguator_;
    }

    function _actionIdDisambiguator() internal view returns (bytes32) {
        return _authentication().actionIdDisambiguator;
    }

    /// @dev Reverts unless the caller is allowed to call the entry point function.
    function _authenticateCaller(address where) internal view {
        bytes32 actionId = _getActionId(msg.sig);

        if (!_canPerform(actionId, msg.sender, where)) {
            revert IAuthentication.SenderNotAllowed();
        }
    }

    /**
     * @dev Derived contracts may implement this function to perform the divergent access control logic.
     * @param actionId The action identifier associated with an external function
     * @param user The account performing the action
     * @return success True if the action is permitted
     */
    function _canPerform(bytes32 actionId, address user, address where) internal view returns (bool) {
        return _balV3Vault().getAuthorizer().canPerform(actionId, user, where);
    }
}
