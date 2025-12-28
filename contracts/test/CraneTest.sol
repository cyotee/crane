// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";

abstract contract CraneTest is BetterTest {

    ICreate3Factory create3Factory;

    IDiamondPackageCallBackFactory diamondFactory;
    IDiamondPackageCallBackFactory diamondPackageFactory;

    function setUp() public virtual override {
        BetterTest.setUp();
        (create3Factory, diamondPackageFactory) = InitDevService.initEnv(address(this));
        diamondFactory = diamondPackageFactory;
    }

}