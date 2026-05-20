pragma solidity ^0.8.35;

interface ILiquidityModifier {
    function getUpdatedReserve() external returns (uint256 reserve0, uint256 reserve1);
}
