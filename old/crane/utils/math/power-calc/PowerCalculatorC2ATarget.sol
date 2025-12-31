// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {ICreate3Aware} from "contracts/crane/interfaces/ICreate3Aware.sol";
import {PowerCalculator} from "contracts/crane/utils/math/power-calc/PowerCalculator.sol";

contract PowerCalculatorC2ATarget is PowerCalculator, Create3AwareContract {
    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        // No additional initialization needed for this target
    }
}
