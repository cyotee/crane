// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {ISuperChainBridgeTokenRegistry} from '@crane/contracts/interfaces/ISuperChainBridgeTokenRegistry.sol';
import {SuperChainBridgeTokenRegistryTarget} from '@crane/contracts/protocols/l2s/superchain/registries/token/bridge/SuperChainBridgeTokenRegistryTarget.sol';
import {FacetBase} from '@crane/contracts/factories/diamondPkg/FacetBase.sol';

contract SuperChainBridgeTokenRegistryFacet is SuperChainBridgeTokenRegistryTarget, FacetBase {
    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public view virtual override returns (string memory name) {
        return type(SuperChainBridgeTokenRegistryFacet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public view virtual override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISuperChainBridgeTokenRegistry).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     */
    function facetFuncs() public view virtual override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = ISuperChainBridgeTokenRegistry.getRemoteToken.selector;
        funcs[1] = ISuperChainBridgeTokenRegistry.getMinGasLimit.selector;
        funcs[2] = ISuperChainBridgeTokenRegistry.getRemoteTokenAndLimit.selector;
        funcs[3] = ISuperChainBridgeTokenRegistry.setRemoteToken.selector;
        funcs[4] = ISuperChainBridgeTokenRegistry.setRemoteTokenMinGasLimit.selector;
    }
    // end::facetFuncs()[]

}