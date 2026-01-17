// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BalancerV3WeightedPoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolTarget.sol";
import {BalancerV3WeightedPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol";

/**
 * @title BalancerV3WeightedPoolTargetStub
 * @notice Test stub that exposes initialization function for testing weighted pool logic.
 */
contract BalancerV3WeightedPoolTargetStub is BalancerV3WeightedPoolTarget {
    /**
     * @notice Initialize the weighted pool with normalized weights.
     * @param normalizedWeights_ Array of normalized weights (e.g., [0.8e18, 0.2e18] for 80/20 pool).
     */
    function initialize(uint256[] memory normalizedWeights_) external {
        BalancerV3WeightedPoolRepo._initialize(normalizedWeights_);
    }
}
