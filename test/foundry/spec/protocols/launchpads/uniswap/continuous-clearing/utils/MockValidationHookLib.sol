// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    IValidationHook
} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/interfaces/IValidationHook.sol";
import {
    ValidationHookLib
} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/ValidationHookLib.sol";

/// @notice Mock implementation of the library
contract MockValidationHookLib {
    function handleValidate(
        IValidationHook hook,
        uint256 maxPrice,
        uint128 amount,
        address owner,
        address sender,
        bytes calldata hookData
    ) external {
        return ValidationHookLib.handleValidate(hook, maxPrice, amount, owner, sender, hookData);
    }
}
