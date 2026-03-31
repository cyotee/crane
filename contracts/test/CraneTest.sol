// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";

abstract contract CraneTest is BetterTest {
    ICreate3FactoryProxy create3Factory;

    IDiamondPackageCallBackFactory diamondFactory;
    IDiamondPackageCallBackFactory diamondPackageFactory;

    function setUp() public virtual override {
        BetterTest.setUp();
        if (address(diamondFactory) == address(0)) {
            (create3Factory, diamondPackageFactory) = InitDevService.initEnv(address(this));
            diamondFactory = diamondPackageFactory;
        }
    }
}
