// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPowerCalculatorAware} from "./IPowerCalculatorAware.sol";

import {IPower} from "./IPower.sol";

import {PowerCalculatorAwareStorage} from "./PowerCalculatorAwareStorage.sol";

contract PowerCalculatorAwareTarget
is
PowerCalculatorAwareStorage,
IPowerCalculatorAware
{
    
    function powerCalculator()
    public view returns(IPower) {
        return _power();
    }

}