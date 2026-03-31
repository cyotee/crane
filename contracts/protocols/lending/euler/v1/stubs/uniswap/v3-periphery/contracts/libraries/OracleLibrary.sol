// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OracleLibrary {
    function getQuoteAtTick(int24 tick, uint128 baseAmount, address baseToken, address quoteToken) external pure returns (uint256 quoteAmount);
    function getSqrtPriceAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96);
}
