// SPDX-License-Identifier: GPL-2.0-or-later
// Ported from morpho-org/morpho-blue@55d2d99304fb3fb930c688462ae2ccabb1d533ad (v1.0.0) — path: test/forge/MarketParamsLibTest.sol
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {MarketParamsLib, MarketParams, Id} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";

contract MarketParamsLibTest is Test {
    using MarketParamsLib for MarketParams;

    function testMarketParamsId(MarketParams memory marketParamsFuzz) public {
        assertEq(Id.unwrap(marketParamsFuzz.id()), keccak256(abi.encode(marketParamsFuzz)));
    }
}
