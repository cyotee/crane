// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Vm} from "forge-std/Vm.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {ReentrancyLockFacet} from "@crane/contracts/access/reentrancy/ReentrancyLockFacet.sol";


library AccessFacetFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    function deployMultiStepOwnableFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet multiStepOwnableFacet) {
        multiStepOwnableFacet = create3Factory.deployFacet(
            type(MultiStepOwnableFacet).creationCode,
            abi.encode(type(MultiStepOwnableFacet).name)._hash()
        );
        vm.label(address(multiStepOwnableFacet), type(MultiStepOwnableFacet).name);
    }

    function deployOperableFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet operableFacet) {
        operableFacet = create3Factory.deployFacet(
            type(OperableFacet).creationCode,
            abi.encode(type(OperableFacet).name)._hash()
        );
        vm.label(address(operableFacet), type(OperableFacet).name);
    }

    function deployReentrancyLockFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet reentrancyLockFacet) {
        reentrancyLockFacet = create3Factory.deployFacet(
            type(ReentrancyLockFacet).creationCode,
            abi.encode(type(ReentrancyLockFacet).name)._hash()
        );
        vm.label(address(reentrancyLockFacet), type(ReentrancyLockFacet).name);
    }
}
