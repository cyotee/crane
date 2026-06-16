// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol";

interface ILQTY is IERC20, IERC20Permit {
    function domainSeparator() external view returns (bytes32);
}
