// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import {ERC20PermitStorage} from "@crane/contracts/crane/token/ERC20/extensions/utils/ERC20PermitStorage.sol";
import {ERC5267Target} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Target.sol";
import {ERC2612Target} from "@crane/contracts/tokens/ERC2612/ERC2612Target.sol";
import {BetterIERC20Permit as IERC20Permit} from "@crane/contracts/interfaces/BetterIERC20Permit.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";

// Mostly a reminder to include this in tokens.
contract ERC20PermitTarget is ERC5267Target, ERC20Target, ERC2612Target, IERC20Permit {}
