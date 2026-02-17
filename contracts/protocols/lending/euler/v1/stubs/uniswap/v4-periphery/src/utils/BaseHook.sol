// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolKey, BeforeSwapDelta} from "../interfaces/IPoolManager.sol";

abstract contract BaseHook {
    function beforeSwap(address sender, PoolKey calldata key, BeforeSwapDelta calldata delta, bytes calldata data) external virtual returns (BeforeSwapDelta memory);
    function afterSwap(address sender, PoolKey calldata key, BeforeSwapDelta calldata delta, bytes calldata data) external virtual returns (BeforeSwapDelta memory);
}
