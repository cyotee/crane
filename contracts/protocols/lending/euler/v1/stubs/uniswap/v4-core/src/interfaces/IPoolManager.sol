// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolManager {
    struct Slot0 { uint160 sqrtPriceX96; int24 tick; uint24 observationIndex; uint24 observationCardinality; uint24 observationCardinalityNext; uint8 feeProtocol; bool unlocked; }
    function getSlot0(uint256 poolId) external view returns (Slot0 memory);
    function unlock(bytes calldata data) external returns (bytes memory result);
}

interface PoolKey {
    address token0;
    address token1;
    uint24 fee;
    int24 tickSpacing;
    address hooks;
}

interface BeforeSwapDelta {
    int256 amount0;
    int256 amount1;
}
