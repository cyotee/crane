// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    BetterIERC20
} from "./BetterIERC20.sol";

interface IERC20MintBurn
is
BetterIERC20
{

    function mint(
        address account,
        uint256 amount
    ) external returns(bool);

    function burn(
        address account,
        uint256 amount
    ) external returns(bool);
    
}