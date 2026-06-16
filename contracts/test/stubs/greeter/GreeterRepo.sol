// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::GreeterLayout[]
struct GreeterLayout {
    string message;
}
// end::GreeterLayout[]

// tag::GreeterRepo[]
/**
 * @title GreeterRepo - Storage library (Repo) for the greeter stub (message) used in tests/stubs.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for Greeter stub per simple message storage.
 * @dev Provides dual (parameterized + default) overloads for _layoutStruct, _setMessage, _getMessage.
 * @dev Follows the gold standard from OperableRepo, FacetRegistryRepo, ERC20Repo, EIP712Repo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT, layoutStruct param name).
 * @dev Used by Greeter*Target/Greeter*Facet stubs and DevEnvSmokeTest for LR-7.
 */
library GreeterRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.test.stubs.greeter"))) - 1).
     *      This follows the canonical pattern used by FacetRegistryRepo, ERC20Repo, EIP712Repo, OperableRepo
     *      and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.test.stubs.greeter"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The GreeterLayout struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (GreeterLayout storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The GreeterLayout struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (GreeterLayout storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_setMessage(GreeterLayout-string)[]
    /**
     * @dev Argumented version of _setMessage to allow direct GreeterLayout access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param message The message to set.
     */
    function _setMessage(GreeterLayout storage layoutStruct, string memory message) internal {
        layoutStruct.message = message;
    }
    // end::_setMessage(GreeterLayout-string)[]

    // tag::_setMessage(string)[]
    /**
     * @dev Default version of _setMessage binding to the standard STORAGE_SLOT.
     * @param message The message to set.
     */
    function _setMessage(string memory message) internal {
        _setMessage(_layoutStruct(), message);
    }
    // end::_setMessage(string)[]

    // tag::_getMessage(GreeterLayout)[]
    /**
     * @dev Argumented version of _getMessage to allow direct GreeterLayout access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return The stored message.
     */
    function _getMessage(GreeterLayout storage layoutStruct) internal view returns (string memory) {
        return layoutStruct.message;
    }
    // end::_getMessage(GreeterLayout)[]

    // tag::_getMessage()[]
    /**
     * @dev Default version of _getMessage binding to the standard STORAGE_SLOT.
     * @return The stored message.
     */
    function _getMessage() internal view returns (string memory) {
        return _getMessage(_layoutStruct());
    }
    // end::_getMessage()[]
}
// end::GreeterRepo[]
