// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';

library SuperChainBridgeTokenRegistryRepo {

    bytes32 internal constant STORAGE_SLOT = keccak256('crane.superChain.registry.bridgeToken');

    struct Storage {
        mapping(uint256 chainId => mapping(IERC20 localToken => IERC20 remoteToken)) remoteToken;
        mapping(uint256 chainId => mapping(IERC20 remoteToken => uint256 minGasLimit)) minGasLimit;
    }

    // tag::_layout(bytes32)[]
    /**
     * @dev Argumented version of _layout to allow for custom storage slot usage.
     * @param slot Storage slot to bind to the Repo's Storage struct.
     * @return layout The bound Storage struct.
     */
    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }
    // end::_layout(bytes32)[]

    // tag::_layout()[]
    /**
     * @dev Default version of _layout binding to the standard STORAGE_SLOT.
     * @return layout The bound Storage struct.
     */
    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _getRemoteToken(Storage storage layout, uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken) {
        return layout.remoteToken[chainId][localToken];
    }

    function _getRemoteToken(uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken) {
        return _getRemoteToken(_layout(), chainId, localToken);
    }

    function _getMinGasLimit(Storage storage layout, uint256 chainId, IERC20 remoteToken) internal view returns (uint256 minGasLimit) {
        return layout.minGasLimit[chainId][remoteToken];
    }

    function _getMinGasLimit(uint256 chainId, IERC20 remoteToken) internal view returns (uint256 minGasLimit) {
        return _getMinGasLimit(_layout(), chainId, remoteToken);
    }

    function _getRemoteTokenAndLimit(Storage storage layout, uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken, uint256 minGasLimit) {
        remoteToken = _getRemoteToken(layout, chainId, localToken);
        minGasLimit = _getMinGasLimit(layout, chainId, remoteToken);
    }

    function _getRemoteTokenAndLimit(uint256 chainId, IERC20 localToken) internal view returns (IERC20 remoteToken, uint256 minGasLimit) {
        return _getRemoteTokenAndLimit(_layout(), chainId, localToken);
    }

    function _setRemoteToken(Storage storage layout, uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) internal {
        layout.remoteToken[chainId][localToken] = remoteToken;
        layout.minGasLimit[chainId][remoteToken] = minGasLimit;
    }

    function _setRemoteToken(uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) internal {
        _setRemoteToken(_layout(), chainId, localToken, remoteToken, minGasLimit);
    }

    function _setRemoteTokenMinGasLimit(Storage storage layout, uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) internal {
        layout.minGasLimit[chainId][remoteToken] = minGasLimit;
    }

    function _setRemoteTokenMinGasLimit(uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) internal {
        _setRemoteTokenMinGasLimit(_layout(), chainId, remoteToken, minGasLimit);
    }

}