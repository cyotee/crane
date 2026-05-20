//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

interface IPriceOracle {
   function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);
}

