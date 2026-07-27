// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    IMorpho,
    Id,
    MarketParams,
    Market,
    Position
} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {Behavior_IMorpho} from "@crane/contracts/protocols/lending/morpho/blue/Behavior_IMorpho.sol";
import {TestBase_MorphoBlue} from
    "@crane/contracts/protocols/lending/morpho/blue/test/bases/TestBase_MorphoBlue.sol";

contract Behavior_IMorpho_Test is TestBase_MorphoBlue {
    function test_behavior_market_and_position_after_supply() public {
        uint256 amount = 50e18;
        _fundSupplier(amount);

        vm.prank(SUPPLIER);
        (, uint256 shares) = morpho.supply(marketParams, amount, 0, SUPPLIER, "");

        Market memory m = morpho.market(marketId);
        Market memory expectedMarket = Market({
            totalSupplyAssets: uint128(amount),
            totalSupplyShares: uint128(shares),
            totalBorrowAssets: 0,
            totalBorrowShares: 0,
            lastUpdate: uint128(block.timestamp),
            fee: 0
        });
        assertTrue(Behavior_IMorpho.isValid_IMorpho_market(morpho, marketId, expectedMarket, m));

        Position memory p = morpho.position(marketId, SUPPLIER);
        Position memory expectedPos = Position({supplyShares: shares, borrowShares: 0, collateral: 0});
        assertTrue(Behavior_IMorpho.isValid_IMorpho_position(morpho, marketId, SUPPLIER, expectedPos, p));
    }
}
