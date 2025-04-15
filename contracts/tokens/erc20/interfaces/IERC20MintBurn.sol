// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IERC20
} from "./IERC20.sol";

interface IERC20MintBurn
is
IERC20
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