// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';
import {ISuperChainBridgeTokenRegistry} from '@crane/contracts/interfaces/ISuperChainBridgeTokenRegistry.sol';
import {SuperChainBridgeTokenRegistryRepo} from '@crane/contracts/protocols/l2s/superchain/registries/token/bridge/SuperChainBridgeTokenRegistryRepo.sol';
import {OperableModifiers} from '@crane/contracts/access/operable/OperableModifiers.sol';

contract SuperChainBridgeTokenRegistryTarget is ISuperChainBridgeTokenRegistry, OperableModifiers {

    function getRemoteToken(uint256 chainId, IERC20 localToken) external view returns (IERC20 remoteToken) {
        return SuperChainBridgeTokenRegistryRepo._getRemoteToken(chainId, localToken);
    }

    function getMinGasLimit(uint256 chainId, IERC20 remoteToken) external view returns (uint256 minGasLimit) {
        return SuperChainBridgeTokenRegistryRepo._getMinGasLimit(chainId, remoteToken);
    }

    function getRemoteTokenAndLimit(uint256 chainId, IERC20 localToken) external view returns (IERC20 remoteToken, uint256 minGasLimit) {
        return SuperChainBridgeTokenRegistryRepo._getRemoteTokenAndLimit(chainId, localToken);
    }

    function setRemoteToken(uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) external onlyOwnerOrOperator returns (bool) {
        SuperChainBridgeTokenRegistryRepo._setRemoteToken(chainId, localToken, remoteToken, minGasLimit);
        return true;
    }

    function setRemoteTokenMinGasLimit(uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) external onlyOwnerOrOperator returns (bool) {
        SuperChainBridgeTokenRegistryRepo._setRemoteTokenMinGasLimit(chainId, remoteToken, minGasLimit);
        return true;
    }

}