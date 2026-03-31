// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHooks {
    function beforeSwap(address sender, PoolKey calldata key, BeforeSwapDelta calldata delta, bytes calldata data) external returns (BeforeSwapDelta memory);
    function afterSwap(address sender, PoolKey calldata key, BeforeSwapDelta calldata delta, bytes calldata data) external returns (BeforeSwapDelta memory);
}
