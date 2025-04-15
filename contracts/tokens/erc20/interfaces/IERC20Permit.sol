// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IERC2612
} from "../../../access/erc2612/interfaces/IERC2612.sol";
import {
    IERC5267
} from "../../../access/erc5267/interfaces/IERC5267.sol";
import {
    IERC20
} from "./IERC20.sol";

interface IERC20Permit
is
IERC5267,
IERC20,
IERC2612
{

}
