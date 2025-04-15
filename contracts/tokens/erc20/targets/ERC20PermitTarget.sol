// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    ERC20PermitStorage
} from "../../../tokens/erc20/storage/ERC20PermitStorage.sol";
import {
    ERC5267Target
} from "../../../access/erc5267/targets/ERC5267Target.sol";
import {
    ERC2612Target
} from "../../../access/erc2612/targets/ERC2612Target.sol";
import {
    IERC20Permit
} from "../../../tokens/erc20/interfaces/IERC20Permit.sol";
import {
    ERC20Target
} from "../../../tokens/erc20/targets/ERC20Target.sol";

// Mostly a reminder to include this in tokens.
contract ERC20PermitTarget
is
ERC5267Target,
ERC20Target,
ERC2612Target,
ERC20PermitStorage,
IERC20Permit
{

}