//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import {
    AggregatorV3Interface
} from "@crane/contracts/external/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "forge-std/console.sol";
import "./Fraxoracle.sol";

contract FraxoraclePriceSource {
    Fraxoracle public immutable fraxoracle;
    IPriceOracle public immutable priceOracle;

    constructor(Fraxoracle _fraxoracle, IPriceOracle _priceOracle) {
        fraxoracle = _fraxoracle;
        priceOracle = _priceOracle;
    }

    function addRoundData() external {
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = priceOracle.getPrices();
        fraxoracle.addRoundData(_isBadData, _priceLow, _priceHigh, uint32(block.timestamp));
    }
}

