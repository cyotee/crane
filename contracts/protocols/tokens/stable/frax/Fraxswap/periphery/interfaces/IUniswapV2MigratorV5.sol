pragma solidity ^0.8.35;

interface IUniswapV2MigratorV5 {
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external;
}
