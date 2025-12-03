// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

interface IPermit2Aware {
    function permit2() external view returns (IPermit2);
}
