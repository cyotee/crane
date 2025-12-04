// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";

interface ICreate3FactoryAware {
    function create3Factory() external view returns (ICreate3Factory create3Factory_);
}
