// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BttBase} from 'test/foundry/spec/protocols/launchpads/uniswap/continuous-clearing/btt/BttBase.sol';
import {Bid, BidLib} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/BidLib.sol';
import {ConstantsLib} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/ConstantsLib.sol';

contract MpsRemainingInAuctionAfterSubmissionTest is BttBase {
    function test_WhenCalledWithBid(uint24 _startCumulativeMps) external pure {
        // it returns mps - bid.startCumulativeMps

        uint24 startCumulativeMps = uint24(bound(_startCumulativeMps, 0, ConstantsLib.MPS));

        Bid memory bid;
        bid.startCumulativeMps = startCumulativeMps;

        uint24 result = BidLib.mpsRemainingInAuctionAfterSubmission(bid);

        assertEq(result, ConstantsLib.MPS - startCumulativeMps);
    }
}
