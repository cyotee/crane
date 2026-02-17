// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Hooks {
    function validateHook(address hook, uint24 fee, int24 tickSpacing) external pure returns (bool);
}
