// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BttBase} from 'test/foundry/spec/protocols/launchpads/uniswap/continuous-clearing/btt/BttBase.sol';
import {Checkpoint, CheckpointLib} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/CheckpointLib.sol';
import {ConstantsLib} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/ConstantsLib.sol';

contract RemainingMpsInAuctionTest is BttBase {
    function test_WhenCalledWithCheckpoint(uint24 _cumulativeMps) external pure {
        // it returns mps - checkpoint.cumulativeMps

        uint24 cumulativeMps = uint24(bound(_cumulativeMps, 0, ConstantsLib.MPS));

        Checkpoint memory checkpoint;
        checkpoint.cumulativeMps = cumulativeMps;

        assertEq(CheckpointLib.remainingMpsInAuction(checkpoint), ConstantsLib.MPS - cumulativeMps);
    }
}
