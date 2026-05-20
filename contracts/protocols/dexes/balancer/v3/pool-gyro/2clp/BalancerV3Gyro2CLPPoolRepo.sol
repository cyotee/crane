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
     * @notice Storage layoutStruct for 2-CLP pool parameters.
     * @dev sqrtAlpha must be less than sqrtBeta.
     */
    struct Storage {
        uint256 sqrtAlpha;
        uint256 sqrtBeta;
    }

    /* ------ Layout Functions ------ */

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize the 2-CLP pool with parameters.
     * @dev sqrtAlpha must be less than sqrtBeta.
     * @param layoutStruct Storage pointer.
     * @param sqrtAlpha_ Square root of alpha (lower price bound).
     * @param sqrtBeta_ Square root of beta (upper price bound).
     */
    function _initialize(Storage storage layoutStruct, uint256 sqrtAlpha_, uint256 sqrtBeta_) internal {
        if (sqrtAlpha_ >= sqrtBeta_) revert SqrtParamsWrong();

        layoutStruct.sqrtAlpha = sqrtAlpha_;
        layoutStruct.sqrtBeta = sqrtBeta_;
    }

    function _initialize(uint256 sqrtAlpha_, uint256 sqrtBeta_) internal {
        _initialize(_layoutStruct(), sqrtAlpha_, sqrtBeta_);
    }

    /* ------ Parameter Getters ------ */

    /**
     * @notice Get the 2-CLP parameters.
     * @param layoutStruct Storage pointer.
     * @return sqrtAlpha Square root of alpha (lower price bound).
     * @return sqrtBeta Square root of beta (upper price bound).
     */
    function _get2CLPParams(Storage storage layoutStruct) internal view returns (uint256 sqrtAlpha, uint256 sqrtBeta) {
        sqrtAlpha = layoutStruct.sqrtAlpha;
        sqrtBeta = layoutStruct.sqrtBeta;
    }

    function _get2CLPParams() internal view returns (uint256 sqrtAlpha, uint256 sqrtBeta) {
        return _get2CLPParams(_layoutStruct());
    }

    /**
     * @notice Get the sqrtAlpha parameter.
     * @param layoutStruct Storage pointer.
     * @return The sqrtAlpha parameter.
     */
    function _getSqrtAlpha(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.sqrtAlpha;
    }

    function _getSqrtAlpha() internal view returns (uint256) {
        return _getSqrtAlpha(_layoutStruct());
    }

    /**
     * @notice Get the sqrtBeta parameter.
     * @param layoutStruct Storage pointer.
     * @return The sqrtBeta parameter.
     */
    function _getSqrtBeta(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.sqrtBeta;
    }

    function _getSqrtBeta() internal view returns (uint256) {
        return _getSqrtBeta(_layoutStruct());
    }
}
