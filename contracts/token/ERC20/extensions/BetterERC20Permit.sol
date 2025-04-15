// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    ERC20PermitStorage
} from "./utils/ERC20PermitStorage.sol";
import {
    ERC5267Target
} from "../../../utils/cryptography/erc5267/ERC5267Target.sol";
import {
    ERC2612Target
} from "./ERC2612Target.sol";
import {
    BetterIERC20Permit as IERC20Permit
} from "../../../interfaces/BetterIERC20Permit.sol";
import {
    BetterERC20 as ERC20
} from "../BetterERC20.sol"; 

// Mostly a reminder to include this in tokens.
contract BetterERC20Permit
is
ERC5267Target,
ERC20,
ERC2612Target,
ERC20PermitStorage,
IERC20Permit
{

}