// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';

library SuperChainBridgeTokenRegistryRepo {

    bytes32 internal constant STORAGE_SLOT = keccak256('crane.superChain.registry.bridgeToken');

    struct Storage {
        mapping(uint256 chainId => mapping(IERC20 localToken => IERC20 remoteToken)) remoteToken;
        mapping(uint256 chainId => mapping(IERC20 remoteToken => uint256 minGasLimit)) minGasLimit;
    }

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot Storage slot to bind to the Repo's Storage struct.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default version of _layoutStruct binding to the standard STORAGE_SLOT.
     * @return layoutStruct The bound Storage struct.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _getRemoteToken(Storage storage layoutStruct, uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken) {
        return layoutStruct.remoteToken[chainId][localToken];
    }

    function _getRemoteToken(uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken) {
        return _getRemoteToken(_layoutStruct(), chainId, localToken);
    }

    function _getMinGasLimit(Storage storage layoutStruct, uint256 chainId, IERC20 remoteToken) internal view returns (uint256 minGasLimit) {
        return layoutStruct.minGasLimit[chainId][remoteToken];
    }

    function _getMinGasLimit(uint256 chainId, IERC20 remoteToken) internal view returns (uint256 minGasLimit) {
        return _getMinGasLimit(_layoutStruct(), chainId, remoteToken);
    }

    function _getRemoteTokenAndLimit(Storage storage layoutStruct, uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken, uint256 minGasLimit) {
        remoteToken = _getRemoteToken(layoutStruct, chainId, localToken);
        minGasLimit = _getMinGasLimit(layoutStruct, chainId, remoteToken);
    }

    function _getRemoteTokenAndLimit(uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken, uint256 minGasLimit) {
        return _getRemoteTokenAndLimit(_layoutStruct(), chainId, localToken);
    }

    function _setRemoteToken(Storage storage layoutStruct, uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) internal {
        layoutStruct.remoteToken[chainId][localToken] = remoteToken;
        layoutStruct.minGasLimit[chainId][remoteToken] = minGasLimit;
    }

    function _setRemoteToken(uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) internal {
        _setRemoteToken(_layoutStruct(), chainId, localToken, remoteToken, minGasLimit);
    }

    function _setRemoteTokenMinGasLimit(Storage storage layoutStruct, uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) internal {
        layoutStruct.minGasLimit[chainId][remoteToken] = minGasLimit;
    }

    function _setRemoteTokenMinGasLimit(uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) internal {
        _setRemoteTokenMinGasLimit(_layoutStruct(), chainId, remoteToken, minGasLimit);
    }

}