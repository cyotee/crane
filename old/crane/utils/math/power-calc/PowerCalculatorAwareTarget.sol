// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPowerCalculatorAware} from "contracts/crane/interfaces/IPowerCalculatorAware.sol";

import {IPower} from "contracts/crane/interfaces/IPower.sol";

import {PowerCalculatorAwareStorage} from "contracts/crane/utils/math/power-calc/PowerCalculatorAwareStorage.sol";

contract PowerCalculatorAwareTarget is PowerCalculatorAwareStorage, IPowerCalculatorAware {
    function powerCalculator() public view returns (IPower) {
        return _power();
    }
}
