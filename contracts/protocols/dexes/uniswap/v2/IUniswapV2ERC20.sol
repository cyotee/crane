// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    BetterIERC20 as IERC20
} from "../../../../token/ERC20/BetterIERC20.sol";
import {IERC2612} from "../../../../token/ERC20/extensions/IERC2612.sol";

interface IUniswapV2ERC20 is IERC20, IERC2612 {

    // function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    // function nonces(address owner) external view returns (uint);

    // function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
