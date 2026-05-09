// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IValidationHook} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/interfaces/IValidationHook.sol';

contract MockValidationHook is IValidationHook {
    function validate(uint256 maxPrice, uint128 amount, address owner, address sender, bytes calldata hookData)
        external
        pure {}
}
