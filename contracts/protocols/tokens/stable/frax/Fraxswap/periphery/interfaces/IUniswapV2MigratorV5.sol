pragma solidity ^0.8.35;

interface IUniswapV2MigratorV5 {
    function migrate(address token, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external;
}
