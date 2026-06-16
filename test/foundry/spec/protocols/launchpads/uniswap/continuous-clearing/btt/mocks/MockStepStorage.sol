// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {StepStorage} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/StepStorage.sol";
import {AuctionStep} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/StepLib.sol";

contract MockStepStorage is StepStorage {
    constructor(bytes memory _auctionStepsData, uint64 _startBlock, uint64 _endBlock)
        StepStorage(_auctionStepsData, _startBlock, _endBlock)
    {}

    function advanceStep() public returns (AuctionStep memory) {
        return _advanceStep();
    }

    function validate(address _pointer) public view {
        _validate(_pointer);
    }

    function startBlock() external view returns (uint64) {
        return START_BLOCK;
    }

    function endBlock() external view returns (uint64) {
        return END_BLOCK;
    }
}
