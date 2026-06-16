// SPDX-License-Identifier: MIT
import "../Interfaces/IPriceFeed.sol";
import "../Dependencies/AggregatorV3Interface.sol";

pragma solidity ^0.8.35;

interface IMainnetPriceFeed is IPriceFeed {
    enum PriceSource {
        primary,
        ETHUSDxCanonical,
        lastGoodPrice
    }

    function ethUsdOracle() external view returns (AggregatorV3Interface, uint256, uint8);
    function priceSource() external view returns (PriceSource);
}
