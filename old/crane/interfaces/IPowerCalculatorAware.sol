// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPower} from "./IPower.sol";

interface IPowerCalculatorAware {
    function powerCalculator() external view returns (IPower);
}
