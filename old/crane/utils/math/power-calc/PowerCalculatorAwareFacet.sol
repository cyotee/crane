// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPowerCalculatorAware} from "contracts/crane/interfaces/IPowerCalculatorAware.sol";
import {PowerCalculatorAwareTarget} from "contracts/crane/utils/math/power-calc/PowerCalculatorAwareTarget.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";

contract PowerCalculatorAwareFacet is Create3AwareContract, PowerCalculatorAwareTarget, IFacet {
    constructor(CREATE3InitData memory initData_) Create3AwareContract(initData_) {}

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IPowerCalculatorAware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);

        funcs[0] = IPowerCalculatorAware.powerCalculator.selector;
    }
}
