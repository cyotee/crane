// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BalancerV3StablePoolTarget} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolTarget.sol";
import {BalancerV3StablePoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolRepo.sol";

/**
 * @title BalancerV3StablePoolTargetStub
 * @notice Test helper contract that wraps BalancerV3StablePoolTarget for direct testing.
 * @dev Exposes initialization and repo functions for testing outside of Diamond proxy context.
 *
 * This stub allows testing:
 * - Invariant calculations with various amplification values
 * - Swap math with StableMath
 * - Amplification parameter transitions
 * - Edge cases with different token counts
 */
contract BalancerV3StablePoolTargetStub is BalancerV3StablePoolTarget {
    /**
     * @notice Initialize the stub with an amplification parameter.
     * @param amplificationParameter_ Amplification factor (1-5000).
     */
    function initialize(uint256 amplificationParameter_) external {
        BalancerV3StablePoolRepo._initialize(amplificationParameter_);
    }

    /**
     * @notice Start an amplification parameter update.
     * @dev Exposed for testing time-based transitions.
     * @param rawEndValue Target amplification value (without precision).
     * @param endTime Timestamp when update should complete.
     */
    function startAmplificationParameterUpdate(uint256 rawEndValue, uint256 endTime) external {
        BalancerV3StablePoolRepo._startAmplificationParameterUpdate(rawEndValue, endTime);
    }

    /**
     * @notice Stop an in-progress amplification update.
     * @dev Freezes the current interpolated value.
     */
    function stopAmplificationParameterUpdate() external {
        BalancerV3StablePoolRepo._stopAmplificationParameterUpdate();
    }

    /**
     * @notice Get the raw amplification state directly from storage.
     * @dev Useful for testing to verify storage state.
     */
    function getRawAmplificationState()
        external
        view
        returns (
            uint64 startValue,
            uint64 endValue,
            uint32 startTime,
            uint32 endTime
        )
    {
        BalancerV3StablePoolRepo.Storage storage layout = BalancerV3StablePoolRepo._layout();
        startValue = layout.startValue;
        endValue = layout.endValue;
        startTime = layout.startTime;
        endTime = layout.endTime;
    }
}
