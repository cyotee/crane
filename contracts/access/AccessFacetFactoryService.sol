// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Vm} from "forge-std/Vm.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {ReentrancyLockFacet} from "@crane/contracts/access/reentrancy/ReentrancyLockFacet.sol";

// tag::AccessFacetFactoryService[]
/**
 * @title AccessFacetFactoryService - A factory service for deploying access control facets.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice This library provides functions to deploy various access control facets, such as MultiStepOwnableFacet, OperableFacet, and ReentrancyLockFacet, using a provided ICreate3FactoryProxy. It also labels the deployed facets for easier identification during development and testing.
 */
library AccessFacetFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::deployMultiStepOwnableFacet(address)[]
    /**
     * @notice Deploys the MultiStepOwnableFacet using the provided ICreate3FactoryProxy and labels it for easier identification.
     * @param create3Factory The factory proxy used to deploy the facet.
     * @return multiStepOwnableFacet The deployed MultiStepOwnableFacet instance.
     */
    function deployMultiStepOwnableFacet(ICreate3FactoryProxy create3Factory)
        internal
        returns (IFacet multiStepOwnableFacet)
    {
        multiStepOwnableFacet = create3Factory.deployFacet(
            type(MultiStepOwnableFacet).creationCode, abi.encode(type(MultiStepOwnableFacet).name)._hash()
        );
        vm.label(address(multiStepOwnableFacet), type(MultiStepOwnableFacet).name);
    }
    // end::deployMultiStepOwnableFacet(address)[]

    // tag::deployOperableFacet(address)[]
    /**
     * @notice Deploys the OperableFacet using the provided ICreate3FactoryProxy and labels it for easier identification.
     * @param create3Factory The factory proxy used to deploy the facet.
     * @return operableFacet The deployed OperableFacet instance.
     */
    function deployOperableFacet(ICreate3FactoryProxy create3Factory) internal returns (IFacet operableFacet) {
        operableFacet =
            create3Factory.deployFacet(type(OperableFacet).creationCode, abi.encode(type(OperableFacet).name)._hash());
        vm.label(address(operableFacet), type(OperableFacet).name);
    }
    // end::deployOperableFacet(address)[]

    // tag::deployReentrancyLockFacet(address)[]
    /**
     * @notice Deploys the ReentrancyLockFacet using the provided ICreate3FactoryProxy and labels it for easier identification.
     * @param create3Factory The factory proxy used to deploy the facet.
     * @return reentrancyLockFacet The deployed ReentrancyLockFacet instance.
     */
    function deployReentrancyLockFacet(ICreate3FactoryProxy create3Factory) internal returns (IFacet reentrancyLockFacet) {
        reentrancyLockFacet = create3Factory.deployFacet(
            type(ReentrancyLockFacet).creationCode, abi.encode(type(ReentrancyLockFacet).name)._hash()
        );
        vm.label(address(reentrancyLockFacet), type(ReentrancyLockFacet).name);
    }
    // end::deployReentrancyLockFacet(address)[]
}
