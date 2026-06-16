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
 * @title AccessFacetFactoryService
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Stateless library for deterministic CREATE3 deployments of access control facets (MultiStepOwnable, Operable, ReentrancyLock).
 * @dev Core factory service used during bootstrap (via InitDevService/CraneTest) and in TestBases to ensure full LR-7 initialization with real non-zero facets (never address(0)).
 * Salt derivation: `abi.encode(type(XXXFacet).name)._hash()` for CREATE3 determinism across chains.
 * Always vm.label()s deployed instances for improved trace/debugging in foundry.
 * Deployed instances conform to IFacet (facetName: 0x5b6f4d01, facetInterfaces: 0x2ea80826, facetFuncs: 0x574a4cff, facetMetadata: 0xf10d7a75 per CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
 * References IDiamondFactoryPackage flow indirectly via package deployments that consume these facets.
 */
library AccessFacetFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::deployMultiStepOwnableFacet(ICreate3FactoryProxy)[]
    /**
     * @notice Deploys the MultiStepOwnableFacet using the provided ICreate3FactoryProxy and labels it for easier identification.
     * @dev Performs CREATE3 deployment via `create3Factory.deployFacet(creationCode, salt)` using salt derived from the facet type name.
     * The deployed facet implements the full EIP-8023 IMultiStepOwnable + IFacet surface for two-step ownership transfer in Diamond contexts.
     * @param create3Factory The factory proxy used to deploy the facet.
     * @return multiStepOwnableFacet The deployed MultiStepOwnableFacet instance (as IFacet).
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

    // end::deployMultiStepOwnableFacet(ICreate3FactoryProxy)[]

    // tag::deployOperableFacet(ICreate3FactoryProxy)[]
    /**
     * @notice Deploys the OperableFacet using the provided ICreate3FactoryProxy and labels it for easier identification.
     * @dev Performs CREATE3 deployment via `create3Factory.deployFacet(creationCode, salt)` using salt derived from the facet type name.
     * The deployed facet implements IOperable (interfaceId 0xa7f11160; selectors: isOperator 0x6d70f7ae, isOperatorFor 0xea562a25, setOperator 0x558a7297, setOperatorFor 0x755dbe7c per CENTRALLY_COMPUTED_NATSPEC_VALUES.md) + IFacet for operator-based access control.
     * @param create3Factory The factory proxy used to deploy the facet.
     * @return operableFacet The deployed OperableFacet instance (as IFacet).
     */
    function deployOperableFacet(ICreate3FactoryProxy create3Factory) internal returns (IFacet operableFacet) {
        operableFacet =
            create3Factory.deployFacet(type(OperableFacet).creationCode, abi.encode(type(OperableFacet).name)._hash());
        vm.label(address(operableFacet), type(OperableFacet).name);
    }

    // end::deployOperableFacet(ICreate3FactoryProxy)[]

    // tag::deployReentrancyLockFacet(ICreate3FactoryProxy)[]
    /**
     * @notice Deploys the ReentrancyLockFacet using the provided ICreate3FactoryProxy and labels it for easier identification.
     * @dev Performs CREATE3 deployment via `create3Factory.deployFacet(creationCode, salt)` using salt derived from the facet type name.
     * The deployed facet implements IReentrancyLock + IFacet for reentrancy protection in Diamond functions.
     * @param create3Factory The factory proxy used to deploy the facet.
     * @return reentrancyLockFacet The deployed ReentrancyLockFacet instance (as IFacet).
     */
    function deployReentrancyLockFacet(ICreate3FactoryProxy create3Factory)
        internal
        returns (IFacet reentrancyLockFacet)
    {
        reentrancyLockFacet = create3Factory.deployFacet(
            type(ReentrancyLockFacet).creationCode, abi.encode(type(ReentrancyLockFacet).name)._hash()
        );
        vm.label(address(reentrancyLockFacet), type(ReentrancyLockFacet).name);
    }
    // end::deployReentrancyLockFacet(ICreate3FactoryProxy)[]

// end::AccessFacetFactoryService[]
}
