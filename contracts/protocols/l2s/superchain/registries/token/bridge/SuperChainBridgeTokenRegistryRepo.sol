// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

// tag::SuperChainBridgeTokenRegistryRepo[]
/**
 * @title SuperChainBridgeTokenRegistryRepo
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Storage library for Superchain bridge token registry (remote token + min gas limit mappings by chainId).
 * @dev Implements the Repo tier of the Facet-Target-Repo pattern for SuperChainBridgeTokenRegistry.
 *      All functions have dual overloads: parameterized (explicit `Storage storage layoutStruct`) and default
 *      (using the internal ERC1967 STORAGE_SLOT). Follows gold standards from ERC20Repo, OperableRepo,
 *      MultiStepOwnableRepo, ERC2535Repo.
 * @dev This library is intended for internal use by the corresponding Target/Facet and related services.
 *      Initialization is typically performed via package initAccount delegatecall (higher layers).
 */
library SuperChainBridgeTokenRegistryRepo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.registries.token.bridge"))) - 1).
     *      This follows the canonical pattern used by OperableRepo, ERC20Repo, MultiStepOwnableRepo, ERC2535Repo,
     *      FacetRegistryRepo and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("crane.protocols.l2s.superchain.registries.token.bridge"))) - 1);
    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Storage layout for Superchain bridge token registry.
     *      remoteToken: maps (chainId, localToken) -> remoteToken address on that chain.
     *      minGasLimit: maps (chainId, remoteToken) -> minimum gas limit for bridge messages.
     */
    struct Storage {
        mapping(uint256 chainId => mapping(IERC20 localToken => IERC20 remoteToken)) remoteToken;
        mapping(uint256 chainId => mapping(IERC20 remoteToken => uint256 minGasLimit)) minGasLimit;
    }
    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Parameterized _layoutStruct allowing custom slot (for testing or special cases).
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }
    // end::_layoutStruct()[]

    // tag::_getRemoteToken(Storage-uint256-IERC20)[]
    /**
     * @dev Argumented version of _getRemoteToken to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param chainId The target chain id.
     * @param localToken The local token address.
     * @return remoteToken The corresponding remote token (or zero if unset).
     */
    function _getRemoteToken(Storage storage layoutStruct, uint256 chainId, IERC20 localToken)
        internal
        view
        returns (IERC20 remoteToken)
    {
        return layoutStruct.remoteToken[chainId][localToken];
    }
    // end::_getRemoteToken(Storage-uint256-IERC20)[]

    // tag::_getRemoteToken(uint256-IERC20)[]
    /**
     * @dev Default version of _getRemoteToken binding to the standard STORAGE_SLOT.
     * @param chainId The target chain id.
     * @param localToken The local token address.
     * @return remoteToken The corresponding remote token (or zero if unset).
     */
    function _getRemoteToken(uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken) {
        return _getRemoteToken(_layoutStruct(), chainId, localToken);
    }
    // end::_getRemoteToken(uint256-IERC20)[]

    // tag::_getMinGasLimit(Storage-uint256-IERC20)[]
    /**
     * @dev Argumented version of _getMinGasLimit to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param chainId The target chain id.
     * @param remoteToken The remote token address.
     * @return minGasLimit The configured min gas limit for bridge operations.
     */
    function _getMinGasLimit(Storage storage layoutStruct, uint256 chainId, IERC20 remoteToken)
        internal
        view
        returns (uint256 minGasLimit)
    {
        return layoutStruct.minGasLimit[chainId][remoteToken];
    }
    // end::_getMinGasLimit(Storage-uint256-IERC20)[]

    // tag::_getMinGasLimit(uint256-IERC20)[]
    /**
     * @dev Default version of _getMinGasLimit binding to the standard STORAGE_SLOT.
     * @param chainId The target chain id.
     * @param remoteToken The remote token address.
     * @return minGasLimit The configured min gas limit for bridge operations.
     */
    function _getMinGasLimit(uint256 chainId, IERC20 remoteToken) internal view returns (uint256 minGasLimit) {
        return _getMinGasLimit(_layoutStruct(), chainId, remoteToken);
    }
    // end::_getMinGasLimit(uint256-IERC20)[]

    // tag::_getRemoteTokenAndLimit(Storage-uint256-IERC20)[]
    /**
     * @dev Argumented version of _getRemoteTokenAndLimit to allow direct Storage access.
     *      Fetches both remote token and its min gas limit (using remote for the limit lookup).
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param chainId The target chain id.
     * @param localToken The local token address.
     * @return remoteToken The corresponding remote token.
     * @return minGasLimit The associated min gas limit.
     */
    function _getRemoteTokenAndLimit(Storage storage layoutStruct, uint256 chainId, IERC20 localToken)
        internal
        view
        returns (IERC20 remoteToken, uint256 minGasLimit)
    {
        remoteToken = _getRemoteToken(layoutStruct, chainId, localToken);
        minGasLimit = _getMinGasLimit(layoutStruct, chainId, remoteToken);
    }
    // end::_getRemoteTokenAndLimit(Storage-uint256-IERC20)[]

    // tag::_getRemoteTokenAndLimit(uint256-IERC20)[]
    /**
     * @dev Default version of _getRemoteTokenAndLimit binding to the standard STORAGE_SLOT.
     * @param chainId The target chain id.
     * @param localToken The local token address.
     * @return remoteToken The corresponding remote token.
     * @return minGasLimit The associated min gas limit.
     */
    function _getRemoteTokenAndLimit(uint256 chainId, IERC20 localToken)
        internal
        view
        returns (IERC20 remoteToken, uint256 minGasLimit)
    {
        return _getRemoteTokenAndLimit(_layoutStruct(), chainId, localToken);
    }
    // end::_getRemoteTokenAndLimit(uint256-IERC20)[]

    // tag::_setRemoteToken(Storage-uint256-IERC20-IERC20-uint256)[]
    /**
     * @dev Argumented version of _setRemoteToken to allow direct Storage access.
     *      Sets both the remote token mapping and the minGasLimit for the remote.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param chainId The target chain id.
     * @param localToken The local token address.
     * @param remoteToken The remote token address to map to.
     * @param minGasLimit The min gas limit to associate.
     */
    function _setRemoteToken(
        Storage storage layoutStruct,
        uint256 chainId,
        IERC20 localToken,
        IERC20 remoteToken,
        uint256 minGasLimit
    ) internal {
        layoutStruct.remoteToken[chainId][localToken] = remoteToken;
        layoutStruct.minGasLimit[chainId][remoteToken] = minGasLimit;
    }
    // end::_setRemoteToken(Storage-uint256-IERC20-IERC20-uint256)[]

    // tag::_setRemoteToken(uint256-IERC20-IERC20-uint256)[]
    /**
     * @dev Default version of _setRemoteToken binding to the standard STORAGE_SLOT.
     * @param chainId The target chain id.
     * @param localToken The local token address.
     * @param remoteToken The remote token address to map to.
     * @param minGasLimit The min gas limit to associate.
     */
    function _setRemoteToken(uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) internal {
        _setRemoteToken(_layoutStruct(), chainId, localToken, remoteToken, minGasLimit);
    }
    // end::_setRemoteToken(uint256-IERC20-IERC20-uint256)[]

    // tag::_setRemoteTokenMinGasLimit(Storage-uint256-IERC20-uint256)[]
    /**
     * @dev Argumented version of _setRemoteTokenMinGasLimit to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param chainId The target chain id.
     * @param remoteToken The remote token address.
     * @param minGasLimit The min gas limit to set.
     */
    function _setRemoteTokenMinGasLimit(
        Storage storage layoutStruct,
        uint256 chainId,
        IERC20 remoteToken,
        uint256 minGasLimit
    ) internal {
        layoutStruct.minGasLimit[chainId][remoteToken] = minGasLimit;
    }
    // end::_setRemoteTokenMinGasLimit(Storage-uint256-IERC20-uint256)[]

    // tag::_setRemoteTokenMinGasLimit(uint256-IERC20-uint256)[]
    /**
     * @dev Default version of _setRemoteTokenMinGasLimit binding to the standard STORAGE_SLOT.
     * @param chainId The target chain id.
     * @param remoteToken The remote token address.
     * @param minGasLimit The min gas limit to set.
     */
    function _setRemoteTokenMinGasLimit(uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) internal {
        _setRemoteTokenMinGasLimit(_layoutStruct(), chainId, remoteToken, minGasLimit);
    }
    // end::_setRemoteTokenMinGasLimit(uint256-IERC20-uint256)[]
}
// end::SuperChainBridgeTokenRegistryRepo[]
