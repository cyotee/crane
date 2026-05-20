// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

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

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    /**
     * @notice Initialize the LBP with sale parameters.
     * @param layoutStruct Storage pointer.
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
        Storage storage layoutStruct,
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

        layoutStruct.projectTokenIndex = projectTokenIndex_;
        layoutStruct.reserveTokenIndex = reserveTokenIndex_;
        layoutStruct.projectTokenStartWeight = projectTokenStartWeight_;
        layoutStruct.projectTokenEndWeight = projectTokenEndWeight_;
        layoutStruct.reserveTokenStartWeight = reserveTokenStartWeight_;
        layoutStruct.reserveTokenEndWeight = reserveTokenEndWeight_;
        layoutStruct.startTime = startTime_;
        layoutStruct.endTime = endTime_;
        layoutStruct.blockProjectTokenSwapsIn = blockProjectTokenSwapsIn_;
        layoutStruct.reserveTokenVirtualBalanceScaled18 = reserveTokenVirtualBalanceScaled18_;
        layoutStruct.reserveTokenScalingFactor = reserveTokenScalingFactor_;
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
            _layoutStruct(),
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

    function _getProjectTokenIndex(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.projectTokenIndex;
    }

    function _getProjectTokenIndex() internal view returns (uint256) {
        return _getProjectTokenIndex(_layoutStruct());
    }

    function _getReserveTokenIndex(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.reserveTokenIndex;
    }

    function _getReserveTokenIndex() internal view returns (uint256) {
        return _getReserveTokenIndex(_layoutStruct());
    }

    function _getStartTime(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.startTime;
    }

    function _getStartTime() internal view returns (uint256) {
        return _getStartTime(_layoutStruct());
    }

    function _getEndTime(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.endTime;
    }

    function _getEndTime() internal view returns (uint256) {
        return _getEndTime(_layoutStruct());
    }

    function _getProjectTokenStartWeight(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.projectTokenStartWeight;
    }

    function _getProjectTokenStartWeight() internal view returns (uint256) {
        return _getProjectTokenStartWeight(_layoutStruct());
    }

    function _getProjectTokenEndWeight(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.projectTokenEndWeight;
    }

    function _getProjectTokenEndWeight() internal view returns (uint256) {
        return _getProjectTokenEndWeight(_layoutStruct());
    }

    function _getReserveTokenStartWeight(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.reserveTokenStartWeight;
    }

    function _getReserveTokenStartWeight() internal view returns (uint256) {
        return _getReserveTokenStartWeight(_layoutStruct());
    }

    function _getReserveTokenEndWeight(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.reserveTokenEndWeight;
    }

    function _getReserveTokenEndWeight() internal view returns (uint256) {
        return _getReserveTokenEndWeight(_layoutStruct());
    }

    function _isBlockProjectTokenSwapsIn(Storage storage layoutStruct) internal view returns (bool) {
        return layoutStruct.blockProjectTokenSwapsIn;
    }

    function _isBlockProjectTokenSwapsIn() internal view returns (bool) {
        return _isBlockProjectTokenSwapsIn(_layoutStruct());
    }

    function _getReserveTokenVirtualBalanceScaled18(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.reserveTokenVirtualBalanceScaled18;
    }

    function _getReserveTokenVirtualBalanceScaled18() internal view returns (uint256) {
        return _getReserveTokenVirtualBalanceScaled18(_layoutStruct());
    }

    function _getReserveTokenScalingFactor(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.reserveTokenScalingFactor;
    }

    function _getReserveTokenScalingFactor() internal view returns (uint256) {
        return _getReserveTokenScalingFactor(_layoutStruct());
    }

    /**
     * @notice Check if swaps are currently enabled (within sale period).
     * @return True if current time is between startTime and endTime.
     */
    function _isSwapEnabled(Storage storage layoutStruct) internal view returns (bool) {
        return block.timestamp >= layoutStruct.startTime && block.timestamp <= layoutStruct.endTime;
    }

    function _isSwapEnabled() internal view returns (bool) {
        return _isSwapEnabled(_layoutStruct());
    }

    /**
     * @notice Get the gradual weight update parameters.
     * @return startTime Sale start timestamp.
     * @return endTime Sale end timestamp.
     * @return startWeights Array of [projectTokenStartWeight, reserveTokenStartWeight].
     * @return endWeights Array of [projectTokenEndWeight, reserveTokenEndWeight].
     */
    function _getGradualWeightUpdateParams(Storage storage layoutStruct)
        internal
        view
        returns (uint256 startTime, uint256 endTime, uint256[] memory startWeights, uint256[] memory endWeights)
    {
        startTime = layoutStruct.startTime;
        endTime = layoutStruct.endTime;

        startWeights = new uint256[](2);
        startWeights[layoutStruct.projectTokenIndex] = layoutStruct.projectTokenStartWeight;
        startWeights[layoutStruct.reserveTokenIndex] = layoutStruct.reserveTokenStartWeight;

        endWeights = new uint256[](2);
        endWeights[layoutStruct.projectTokenIndex] = layoutStruct.projectTokenEndWeight;
        endWeights[layoutStruct.reserveTokenIndex] = layoutStruct.reserveTokenEndWeight;
    }

    function _getGradualWeightUpdateParams()
        internal
        view
        returns (uint256 startTime, uint256 endTime, uint256[] memory startWeights, uint256[] memory endWeights)
    {
        return _getGradualWeightUpdateParams(_layoutStruct());
    }
}
