pragma solidity ^0.8.35;

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}
