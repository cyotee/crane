// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {DiamondPackageFactoryAwareRepo} from "@crane/contracts/factories/diamondPkg/DiamondPackageFactoryAwareRepo.sol";
import {Create3FactoryService} from "@crane/contracts/factories/create3/Create3FactoryService.sol";
import {MultiStepOwnableModifiers} from '@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol';
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
// import {OperableModifiers} from '@crane/contracts/access/operable/OperableModifiers.sol';

contract Create3FactoryTarget is MultiStepOwnableModifiers, OperableModifiers, ICreate3Factory {
    function diamondPackageFactory() external view returns (IDiamondPackageCallBackFactory factory) {
        return DiamondPackageFactoryAwareRepo._diamondPackageFactory();
    }

    function setDiamondPackageFactory(IDiamondPackageCallBackFactory diamondPackageFactory_) external onlyOwner returns (bool) {
        DiamondPackageFactoryAwareRepo._initialize(diamondPackageFactory_);
        return true;
    }

    function create3(bytes memory initCode, bytes32 salt) external onlyOwnerOrOperator returns (address proxy) {
        return Create3FactoryService._create3(initCode, salt);
    }

    function create3WithArgs(bytes memory initCode, bytes memory initData, bytes32 salt)
        external
        onlyOwnerOrOperator
        returns (address proxy)
    {
        return Create3FactoryService._create3WithArgs(initCode, initData, salt);
    }
}
