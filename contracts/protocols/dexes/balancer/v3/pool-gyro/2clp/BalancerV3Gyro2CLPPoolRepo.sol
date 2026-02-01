// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title BalancerV3Gyro2CLPPoolRepo
 * @notice Storage library for Balancer V3 Gyro 2-CLP pool parameters.
 * @dev Implements the standard Crane Repo pattern with dual overloads (parameterized and default).
 *
 * 2-CLP pools use simpler concentrated liquidity with just two parameters:
 * - sqrtAlpha: Square root of the lower price bound
 * - sqrtBeta: Square root of the upper price bound
 *
 * The invariant is L^2 = (x + a)(y + b) where:
 * - a = L / sqrtBeta (virtual offset for token 0)
 * - b = L * sqrtAlpha (virtual offset for token 1)
 */
library BalancerV3Gyro2CLPPoolRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.pool.gyro.2clp");

    /// @notice The informed sqrtAlpha is greater than or equal to sqrtBeta.
    error SqrtParamsWrong();

    /**
     * @notice Storage layout for 2-CLP pool parameters.
     * @dev sqrtAlpha must be less than sqrtBeta.
     */
    struct Storage {
        uint256 sqrtAlpha;
        uint256 sqrtBeta;
    }

    /* ------ Layout Functions ------ */

    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage layout) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize the 2-CLP pool with parameters.
     * @dev sqrtAlpha must be less than sqrtBeta.
     * @param layout Storage pointer.
     * @param sqrtAlpha_ Square root of alpha (lower price bound).
     * @param sqrtBeta_ Square root of beta (upper price bound).
     */
    function _initialize(Storage storage layout, uint256 sqrtAlpha_, uint256 sqrtBeta_) internal {
        if (sqrtAlpha_ >= sqrtBeta_) revert SqrtParamsWrong();

        layout.sqrtAlpha = sqrtAlpha_;
        layout.sqrtBeta = sqrtBeta_;
    }

    function _initialize(uint256 sqrtAlpha_, uint256 sqrtBeta_) internal {
        _initialize(_layout(), sqrtAlpha_, sqrtBeta_);
    }

    /* ------ Parameter Getters ------ */

    /**
     * @notice Get the 2-CLP parameters.
     * @param layout Storage pointer.
     * @return sqrtAlpha Square root of alpha (lower price bound).
     * @return sqrtBeta Square root of beta (upper price bound).
     */
    function _get2CLPParams(Storage storage layout) internal view returns (uint256 sqrtAlpha, uint256 sqrtBeta) {
        sqrtAlpha = layout.sqrtAlpha;
        sqrtBeta = layout.sqrtBeta;
    }

    function _get2CLPParams() internal view returns (uint256 sqrtAlpha, uint256 sqrtBeta) {
        return _get2CLPParams(_layout());
    }

    /**
     * @notice Get the sqrtAlpha parameter.
     * @param layout Storage pointer.
     * @return The sqrtAlpha parameter.
     */
    function _getSqrtAlpha(Storage storage layout) internal view returns (uint256) {
        return layout.sqrtAlpha;
    }

    function _getSqrtAlpha() internal view returns (uint256) {
        return _getSqrtAlpha(_layout());
    }

    /**
     * @notice Get the sqrtBeta parameter.
     * @param layout Storage pointer.
     * @return The sqrtBeta parameter.
     */
    function _getSqrtBeta(Storage storage layout) internal view returns (uint256) {
        return layout.sqrtBeta;
    }

    function _getSqrtBeta() internal view returns (uint256) {
        return _getSqrtBeta(_layout());
    }
}
