// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Permit} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol";

interface IERC20WithPermit is IERC20, IERC20Permit {}
