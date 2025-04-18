// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPowerCalculatorAware} from "../interfaces/IPowerCalculatorAware.sol";

import {IPower} from "../interfaces/IPower.sol";

import {PowerCalculatorAwareStorage} from "../storage/PowerCalculatorAwareStorage.sol";

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