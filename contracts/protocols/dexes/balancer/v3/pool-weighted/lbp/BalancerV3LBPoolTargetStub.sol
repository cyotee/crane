// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BalancerV3LBPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolTarget.sol";
import {BalancerV3LBPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolRepo.sol";

/**
 * @title BalancerV3LBPoolTargetStub
 * @notice Test stub for BalancerV3LBPoolTarget that exposes initialization.
 * @dev This contract should only be used for testing purposes.
 */
contract BalancerV3LBPoolTargetStub is BalancerV3LBPoolTarget {
    /**
     * @notice Initialize the LBP with sale parameters.
     * @param projectTokenIndex_ Index of the project token (0 or 1).
     * @param reserveTokenIndex_ Index of the reserve token (0 or 1).
     * @param projectTokenStartWeight_ Starting weight for project token.
     * @param projectTokenEndWeight_ Ending weight for project token.
     * @param startTime_ Sale start timestamp.
     * @param endTime_ Sale end timestamp.
     * @param blockProjectTokenSwapsIn_ If true, project token cannot be sold back.
     */
    function initialize(
        uint256 projectTokenIndex_,
        uint256 reserveTokenIndex_,
        uint256 projectTokenStartWeight_,
        uint256 projectTokenEndWeight_,
        uint256 startTime_,
        uint256 endTime_,
        bool blockProjectTokenSwapsIn_
    ) external {
        BalancerV3LBPoolRepo._initialize(
            projectTokenIndex_,
            reserveTokenIndex_,
            projectTokenStartWeight_,
            projectTokenEndWeight_,
            startTime_,
            endTime_,
            blockProjectTokenSwapsIn_,
            0, // no virtual balance
            0  // no scaling factor needed
        );
    }

    /**
     * @notice Initialize the LBP as a seedless pool with virtual reserve balance.
     * @param projectTokenIndex_ Index of the project token (0 or 1).
     * @param reserveTokenIndex_ Index of the reserve token (0 or 1).
     * @param projectTokenStartWeight_ Starting weight for project token.
     * @param projectTokenEndWeight_ Ending weight for project token.
     * @param startTime_ Sale start timestamp.
     * @param endTime_ Sale end timestamp.
     * @param blockProjectTokenSwapsIn_ If true, project token cannot be sold back.
     * @param reserveTokenVirtualBalanceScaled18_ Virtual reserve balance (scaled to 18 decimals).
     */
    function initializeSeedless(
        uint256 projectTokenIndex_,
        uint256 reserveTokenIndex_,
        uint256 projectTokenStartWeight_,
        uint256 projectTokenEndWeight_,
        uint256 startTime_,
        uint256 endTime_,
        bool blockProjectTokenSwapsIn_,
        uint256 reserveTokenVirtualBalanceScaled18_
    ) external {
        BalancerV3LBPoolRepo._initialize(
            projectTokenIndex_,
            reserveTokenIndex_,
            projectTokenStartWeight_,
            projectTokenEndWeight_,
            startTime_,
            endTime_,
            blockProjectTokenSwapsIn_,
            reserveTokenVirtualBalanceScaled18_,
            1e18 // assume 18 decimal token
        );
    }
}
