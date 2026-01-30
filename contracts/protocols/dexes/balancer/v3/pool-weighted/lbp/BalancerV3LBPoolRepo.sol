// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

/**
 * @title BalancerV3LBPoolRepo
 * @notice Storage library for Balancer V3 Liquidity Bootstrapping Pool (LBP) parameters.
 * @dev Implements the standard Crane Repo pattern with dual overloads (parameterized and default).
 * LBPs have time-based gradual weight transitions for token launches.
 *
 * Key concepts:
 * - Project token: The token being launched/sold
 * - Reserve token: The capital token (usually stablecoin or WETH)
 * - Weights transition linearly from start to end over the sale period
 */
library BalancerV3LBPoolRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.lbp");

    error InvalidTimeRange();
    error InvalidWeights();
    error StartTimeInPast();
    error WeightsMustSumToOne();

    struct Storage {
        // Token indices (determined by token address sorting)
        uint256 projectTokenIndex;
        uint256 reserveTokenIndex;
        // Weight transition parameters
        uint256 projectTokenStartWeight;
        uint256 projectTokenEndWeight;
        uint256 reserveTokenStartWeight;
        uint256 reserveTokenEndWeight;
        // Time boundaries for the sale
        uint256 startTime;
        uint256 endTime;
        // If true, project tokens can only be bought, not sold back
        bool blockProjectTokenSwapsIn;
        // Virtual balance for seedless LBPs (reserve token only)
        uint256 reserveTokenVirtualBalanceScaled18;
        uint256 reserveTokenScalingFactor;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /**
     * @notice Initialize the LBP with sale parameters.
     * @param layout Storage pointer.
     * @param projectTokenIndex_ Index of the project token (0 or 1).
     * @param reserveTokenIndex_ Index of the reserve token (0 or 1).
     * @param projectTokenStartWeight_ Starting weight for project token (e.g., 0.99e18 for 99%).
     * @param projectTokenEndWeight_ Ending weight for project token (e.g., 0.50e18 for 50%).
     * @param startTime_ Sale start timestamp.
     * @param endTime_ Sale end timestamp.
     * @param blockProjectTokenSwapsIn_ If true, project token cannot be sold back.
     * @param reserveTokenVirtualBalanceScaled18_ Virtual reserve balance for seedless LBPs.
     * @param reserveTokenScalingFactor_ Scaling factor for reserve token decimals.
     */
    function _initialize(
        Storage storage layout,
        uint256 projectTokenIndex_,
        uint256 reserveTokenIndex_,
        uint256 projectTokenStartWeight_,
        uint256 projectTokenEndWeight_,
        uint256 startTime_,
        uint256 endTime_,
        bool blockProjectTokenSwapsIn_,
        uint256 reserveTokenVirtualBalanceScaled18_,
        uint256 reserveTokenScalingFactor_
    ) internal {
        if (startTime_ >= endTime_) revert InvalidTimeRange();

        // Compute reserve token weights (complement of project token)
        uint256 reserveTokenStartWeight_ = FixedPoint.ONE - projectTokenStartWeight_;
        uint256 reserveTokenEndWeight_ = FixedPoint.ONE - projectTokenEndWeight_;

        // Validate weights (minimum 1%)
        uint256 minWeight = 0.01e18;
        if (projectTokenStartWeight_ < minWeight || projectTokenEndWeight_ < minWeight) {
            revert InvalidWeights();
        }
        if (reserveTokenStartWeight_ < minWeight || reserveTokenEndWeight_ < minWeight) {
            revert InvalidWeights();
        }

        layout.projectTokenIndex = projectTokenIndex_;
        layout.reserveTokenIndex = reserveTokenIndex_;
        layout.projectTokenStartWeight = projectTokenStartWeight_;
        layout.projectTokenEndWeight = projectTokenEndWeight_;
        layout.reserveTokenStartWeight = reserveTokenStartWeight_;
        layout.reserveTokenEndWeight = reserveTokenEndWeight_;
        layout.startTime = startTime_;
        layout.endTime = endTime_;
        layout.blockProjectTokenSwapsIn = blockProjectTokenSwapsIn_;
        layout.reserveTokenVirtualBalanceScaled18 = reserveTokenVirtualBalanceScaled18_;
        layout.reserveTokenScalingFactor = reserveTokenScalingFactor_;
    }

    function _initialize(
        uint256 projectTokenIndex_,
        uint256 reserveTokenIndex_,
        uint256 projectTokenStartWeight_,
        uint256 projectTokenEndWeight_,
        uint256 startTime_,
        uint256 endTime_,
        bool blockProjectTokenSwapsIn_,
        uint256 reserveTokenVirtualBalanceScaled18_,
        uint256 reserveTokenScalingFactor_
    ) internal {
        _initialize(
            _layout(),
            projectTokenIndex_,
            reserveTokenIndex_,
            projectTokenStartWeight_,
            projectTokenEndWeight_,
            startTime_,
            endTime_,
            blockProjectTokenSwapsIn_,
            reserveTokenVirtualBalanceScaled18_,
            reserveTokenScalingFactor_
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                               Getters                                   */
    /* ---------------------------------------------------------------------- */

    function _getProjectTokenIndex(Storage storage layout) internal view returns (uint256) {
        return layout.projectTokenIndex;
    }

    function _getProjectTokenIndex() internal view returns (uint256) {
        return _getProjectTokenIndex(_layout());
    }

    function _getReserveTokenIndex(Storage storage layout) internal view returns (uint256) {
        return layout.reserveTokenIndex;
    }

    function _getReserveTokenIndex() internal view returns (uint256) {
        return _getReserveTokenIndex(_layout());
    }

    function _getStartTime(Storage storage layout) internal view returns (uint256) {
        return layout.startTime;
    }

    function _getStartTime() internal view returns (uint256) {
        return _getStartTime(_layout());
    }

    function _getEndTime(Storage storage layout) internal view returns (uint256) {
        return layout.endTime;
    }

    function _getEndTime() internal view returns (uint256) {
        return _getEndTime(_layout());
    }

    function _getProjectTokenStartWeight(Storage storage layout) internal view returns (uint256) {
        return layout.projectTokenStartWeight;
    }

    function _getProjectTokenStartWeight() internal view returns (uint256) {
        return _getProjectTokenStartWeight(_layout());
    }

    function _getProjectTokenEndWeight(Storage storage layout) internal view returns (uint256) {
        return layout.projectTokenEndWeight;
    }

    function _getProjectTokenEndWeight() internal view returns (uint256) {
        return _getProjectTokenEndWeight(_layout());
    }

    function _getReserveTokenStartWeight(Storage storage layout) internal view returns (uint256) {
        return layout.reserveTokenStartWeight;
    }

    function _getReserveTokenStartWeight() internal view returns (uint256) {
        return _getReserveTokenStartWeight(_layout());
    }

    function _getReserveTokenEndWeight(Storage storage layout) internal view returns (uint256) {
        return layout.reserveTokenEndWeight;
    }

    function _getReserveTokenEndWeight() internal view returns (uint256) {
        return _getReserveTokenEndWeight(_layout());
    }

    function _isBlockProjectTokenSwapsIn(Storage storage layout) internal view returns (bool) {
        return layout.blockProjectTokenSwapsIn;
    }

    function _isBlockProjectTokenSwapsIn() internal view returns (bool) {
        return _isBlockProjectTokenSwapsIn(_layout());
    }

    function _getReserveTokenVirtualBalanceScaled18(Storage storage layout) internal view returns (uint256) {
        return layout.reserveTokenVirtualBalanceScaled18;
    }

    function _getReserveTokenVirtualBalanceScaled18() internal view returns (uint256) {
        return _getReserveTokenVirtualBalanceScaled18(_layout());
    }

    function _getReserveTokenScalingFactor(Storage storage layout) internal view returns (uint256) {
        return layout.reserveTokenScalingFactor;
    }

    function _getReserveTokenScalingFactor() internal view returns (uint256) {
        return _getReserveTokenScalingFactor(_layout());
    }

    /**
     * @notice Check if swaps are currently enabled (within sale period).
     * @return True if current time is between startTime and endTime.
     */
    function _isSwapEnabled(Storage storage layout) internal view returns (bool) {
        return block.timestamp >= layout.startTime && block.timestamp <= layout.endTime;
    }

    function _isSwapEnabled() internal view returns (bool) {
        return _isSwapEnabled(_layout());
    }

    /**
     * @notice Get the gradual weight update parameters.
     * @return startTime Sale start timestamp.
     * @return endTime Sale end timestamp.
     * @return startWeights Array of [projectTokenStartWeight, reserveTokenStartWeight].
     * @return endWeights Array of [projectTokenEndWeight, reserveTokenEndWeight].
     */
    function _getGradualWeightUpdateParams(Storage storage layout)
        internal
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        )
    {
        startTime = layout.startTime;
        endTime = layout.endTime;

        startWeights = new uint256[](2);
        startWeights[layout.projectTokenIndex] = layout.projectTokenStartWeight;
        startWeights[layout.reserveTokenIndex] = layout.reserveTokenStartWeight;

        endWeights = new uint256[](2);
        endWeights[layout.projectTokenIndex] = layout.projectTokenEndWeight;
        endWeights[layout.reserveTokenIndex] = layout.reserveTokenEndWeight;
    }

    function _getGradualWeightUpdateParams()
        internal
        view
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        )
    {
        return _getGradualWeightUpdateParams(_layout());
    }
}
