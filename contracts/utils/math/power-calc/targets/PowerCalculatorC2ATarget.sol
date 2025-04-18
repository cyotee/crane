// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Create2CallbackContract} from "../../../../factories/create2/callback/targets/Create2CallbackContract.sol";
import {PowerCalculator} from "../../power-calc/targets/PowerCalculator.sol";

contract PowerCalculatorC2ATarget
is
PowerCalculator,
Create2CallbackContract
{

}