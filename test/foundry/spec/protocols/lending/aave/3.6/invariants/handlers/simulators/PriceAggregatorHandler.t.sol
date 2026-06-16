// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

// Libraries

// Test Contracts
import {Actor} from "@crane/contracts/protocols/lending/aave/v3.6/utils/Actor.sol";
import {BaseHandler} from "test/foundry/spec/protocols/lending/aave/3.6/invariants/base/BaseHandler.t.sol";
import {
    MockAggregatorSetPrice
} from "@crane/contracts/protocols/lending/aave/v3.6/utils/mocks/MockAggregatorSetPrice.sol";

/// @title PriceAggregatorHandler
/// @notice Handler test contract for a set of actions
contract PriceAggregatorHandler is BaseHandler {
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      STATE VARIABLES                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                          ACTIONS                                          //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function setLatestAnswer(int72 _price, uint8 i) public {
        // Get a random price aggregator
        address priceAggregator = _getRandomPriceAggregator(i);

        // No need in fuzzing the price that are biggger than 2**68
        // log2(1'000'000'000'000 * 10**8) = 66.4385618977

        _before();
        MockAggregatorSetPrice(priceAggregator).setLatestAnswer(_price);
        _after();

        assert(true);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                         OWNER ACTIONS                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                           HELPERS                                         //
    ///////////////////////////////////////////////////////////////////////////////////////////////
}
