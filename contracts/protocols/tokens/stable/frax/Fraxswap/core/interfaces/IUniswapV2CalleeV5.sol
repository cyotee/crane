pragma solidity ^0.8.35;

interface IUniswapV2CalleeV5 {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
