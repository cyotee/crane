// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IBalancerV3StablePool
 * @notice Minimal interface for stable pool functionality in Crane framework.
 * @dev Provides access to amplification parameter for stable pool math operations.
 * This interface is designed for use with the Diamond pattern and focuses on
 * the core functions needed for stable pool operations.
 *
 * Stable pools use the StableMath invariant which is optimized for assets that
 * trade near parity (e.g., stablecoins). The amplification parameter controls
 * the "flatness" of the curve - higher values (up to 50000) allow larger trades
 * with lower slippage when prices are near parity.
 *
 * @custom:interfaceid 0x4c7691e3
 */
interface IBalancerV3StablePool {
    /**
     * @notice Get the current amplification parameter.
     * @dev The amplification parameter may be in the process of updating. The returned
     * value includes the precision multiplier (AMP_PRECISION = 1000).
     * @return value Current amplification parameter (includes precision).
     * @return isUpdating True if the amplification is currently transitioning.
     * @return precision The precision multiplier (always 1000).
     * @custom:signature getAmplificationParameter()
     * @custom:selector 0x6daccffa
     */
    function getAmplificationParameter() external view returns (uint256 value, bool isUpdating, uint256 precision);

    /**
     * @notice Get the full amplification state including transition parameters.
     * @return startValue Starting amplification value for current/last transition.
     * @return endValue Ending amplification value for current/last transition.
     * @return startTime Start timestamp of the transition.
     * @return endTime End timestamp of the transition.
     * @return precision The precision multiplier (always 1000).
     * @custom:signature getAmplificationState()
     * @custom:selector 0x21da5e19
     */
    function getAmplificationState()
        external
        view
        returns (
            uint256 startValue,
            uint256 endValue,
            uint256 startTime,
            uint256 endTime,
            uint256 precision
        );
}
