// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import "../data-services/KydServiceConsumerBase.sol";

contract SampleKydServiceConsumer is KydServiceConsumerBase {
    using BetterEfficientHashLib for bytes;

    error UserDidNotPassKYD(address user);

    bool passedKYD;

    function executeActionPassingKYD() public {
        // bytes32 dataFeedId = keccak256(abi.encodePacked(msg.sender));
        bytes32 dataFeedId = abi.encodePacked(msg.sender)._hash();
        uint256 isVerified = getOracleNumericValueFromTxMsg(dataFeedId);
        if (isVerified != 1) {
            revert UserDidNotPassKYD(msg.sender);
        }
        passedKYD = true;
    }

    function getPassedKYDValue() public view returns (bool) {
        return passedKYD;
    }
}
