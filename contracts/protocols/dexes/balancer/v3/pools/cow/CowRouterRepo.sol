// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                              OpenZeppelin                                  */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                              Balancer V3 Interfaces                        */
/* -------------------------------------------------------------------------- */

import {ICowRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowRouter.sol";

/**
 * @title CowRouterRepo
 * @notice Storage library for Balancer V3 CoW Router state.
 * @dev Implements the standard Crane Repo pattern with dual overloads.
 * CoW Routers handle MEV-protected swaps and surplus donations for CoW Protocol.
 *
 * @custom:storage-slot protocols.dexes.balancer.v3.router.cow
 */
library CowRouterRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.router.cow");

    /// @notice Protocol fee percentage capped at 50% (50e16 in 18-decimal fixed point).
    uint256 internal constant MAX_PROTOCOL_FEE_PERCENTAGE = 50e16;

    /* ------ Errors ------ */

    /// @notice Thrown when attempting to set a fee percentage above the maximum.
    error ProtocolFeePercentageAboveLimit(uint256 newProtocolFeePercentage, uint256 maxProtocolFeePercentage);

    /// @notice Thrown when attempting to set an invalid (zero) fee sweeper address.
    error InvalidFeeSweeper();

    /* ------ Storage ------ */

    /**
     * @notice Storage layoutStruct for CoW Router.
     * @param feeSweeper Address that receives protocol fees on withdrawal.
     * @param protocolFeePercentage Percentage of donations charged as protocol fee (18-decimal FP).
     * @param collectedProtocolFees Mapping of token => accumulated fees not yet withdrawn.
     */
    struct Storage {
        address feeSweeper;
        uint256 protocolFeePercentage;
        mapping(IERC20 token => uint256 feeAmount) collectedProtocolFees;
    }

    /* ------ Layout Functions ------ */

    /**
     * @notice Returns a storage pointer for a given slot.
     * @param slot The storage slot to use.
     * @return layoutStruct Storage pointer.
     */
    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot
        }
    }

    /**
     * @notice Returns a storage pointer using the default slot.
     * @return layoutStruct Storage pointer.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    /* ------ Initialization ------ */

    /**
     * @notice Initialize the CoW Router with fee settings.
     * @param layoutStruct Storage pointer.
     * @param protocolFeePercentage_ Initial protocol fee percentage (18-decimal FP, max 50%).
     * @param feeSweeper_ Address to receive collected fees.
     */
    function _initialize(Storage storage layoutStruct, uint256 protocolFeePercentage_, address feeSweeper_) internal {
        _setProtocolFeePercentage(layoutStruct, protocolFeePercentage_);
        _setFeeSweeper(layoutStruct, feeSweeper_);
    }

    /**
     * @notice Initialize the CoW Router with fee settings (default slot).
     * @param protocolFeePercentage_ Initial protocol fee percentage.
     * @param feeSweeper_ Address to receive collected fees.
     */
    function _initialize(uint256 protocolFeePercentage_, address feeSweeper_) internal {
        _initialize(_layoutStruct(), protocolFeePercentage_, feeSweeper_);
    }

    /* ------ Getters ------ */

    /**
     * @notice Get the maximum allowed protocol fee percentage.
     * @return maxFee Maximum fee percentage (50%).
     */
    function _getMaxProtocolFeePercentage() internal pure returns (uint256 maxFee) {
        return MAX_PROTOCOL_FEE_PERCENTAGE;
    }

    /**
     * @notice Get the current protocol fee percentage.
     * @param layoutStruct Storage pointer.
     * @return protocolFeePercentage Current fee percentage.
     */
    function _getProtocolFeePercentage(Storage storage layoutStruct)
        internal
        view
        returns (uint256 protocolFeePercentage)
    {
        return layoutStruct.protocolFeePercentage;
    }

    /**
     * @notice Get the current protocol fee percentage (default slot).
     * @return protocolFeePercentage Current fee percentage.
     */
    function _getProtocolFeePercentage() internal view returns (uint256 protocolFeePercentage) {
        return _getProtocolFeePercentage(_layoutStruct());
    }

    /**
     * @notice Get the fee sweeper address.
     * @param layoutStruct Storage pointer.
     * @return feeSweeper Address that receives fees.
     */
    function _getFeeSweeper(Storage storage layoutStruct) internal view returns (address feeSweeper) {
        return layoutStruct.feeSweeper;
    }

    /**
     * @notice Get the fee sweeper address (default slot).
     * @return feeSweeper Address that receives fees.
     */
    function _getFeeSweeper() internal view returns (address feeSweeper) {
        return _getFeeSweeper(_layoutStruct());
    }

    /**
     * @notice Get collected protocol fees for a specific token.
     * @param layoutStruct Storage pointer.
     * @param token The token to check.
     * @return fees Accumulated fees for the token.
     */
    function _getCollectedProtocolFees(Storage storage layoutStruct, IERC20 token)
        internal
        view
        returns (uint256 fees)
    {
        return layoutStruct.collectedProtocolFees[token];
    }

    /**
     * @notice Get collected protocol fees for a specific token (default slot).
     * @param token The token to check.
     * @return fees Accumulated fees for the token.
     */
    function _getCollectedProtocolFees(IERC20 token) internal view returns (uint256 fees) {
        return _getCollectedProtocolFees(_layoutStruct(), token);
    }

    /* ------ Setters ------ */

    /**
     * @notice Set the protocol fee percentage.
     * @dev Emits ProtocolFeePercentageChanged event.
     * @param layoutStruct Storage pointer.
     * @param newProtocolFeePercentage_ New fee percentage (must be <= 50%).
     */
    function _setProtocolFeePercentage(Storage storage layoutStruct, uint256 newProtocolFeePercentage_) internal {
        if (newProtocolFeePercentage_ > MAX_PROTOCOL_FEE_PERCENTAGE) {
            revert ProtocolFeePercentageAboveLimit(newProtocolFeePercentage_, MAX_PROTOCOL_FEE_PERCENTAGE);
        }

        layoutStruct.protocolFeePercentage = newProtocolFeePercentage_;

        emit ICowRouter.ProtocolFeePercentageChanged(newProtocolFeePercentage_);
    }

    /**
     * @notice Set the protocol fee percentage (default slot).
     * @param newProtocolFeePercentage_ New fee percentage.
     */
    function _setProtocolFeePercentage(uint256 newProtocolFeePercentage_) internal {
        _setProtocolFeePercentage(_layoutStruct(), newProtocolFeePercentage_);
    }

    /**
     * @notice Set the fee sweeper address.
     * @dev Emits FeeSweeperChanged event.
     * @param layoutStruct Storage pointer.
     * @param newFeeSweeper_ New fee sweeper address.
     */
    function _setFeeSweeper(Storage storage layoutStruct, address newFeeSweeper_) internal {
        if (newFeeSweeper_ == address(0)) {
            revert InvalidFeeSweeper();
        }

        layoutStruct.feeSweeper = newFeeSweeper_;

        emit ICowRouter.FeeSweeperChanged(newFeeSweeper_);
    }

    /**
     * @notice Set the fee sweeper address (default slot).
     * @param newFeeSweeper_ New fee sweeper address.
     */
    function _setFeeSweeper(address newFeeSweeper_) internal {
        _setFeeSweeper(_layoutStruct(), newFeeSweeper_);
    }

    /* ------ Fee Operations ------ */

    /**
     * @notice Add collected fees for a token.
     * @param layoutStruct Storage pointer.
     * @param token The token to add fees for.
     * @param amount Amount to add.
     */
    function _addCollectedFees(Storage storage layoutStruct, IERC20 token, uint256 amount) internal {
        layoutStruct.collectedProtocolFees[token] += amount;
    }

    /**
     * @notice Add collected fees for a token (default slot).
     * @param token The token to add fees for.
     * @param amount Amount to add.
     */
    function _addCollectedFees(IERC20 token, uint256 amount) internal {
        _addCollectedFees(_layoutStruct(), token, amount);
    }

    /**
     * @notice Clear collected fees for a token and return the amount.
     * @param layoutStruct Storage pointer.
     * @param token The token to clear fees for.
     * @return amount Amount that was cleared.
     */
    function _clearCollectedFees(Storage storage layoutStruct, IERC20 token) internal returns (uint256 amount) {
        amount = layoutStruct.collectedProtocolFees[token];
        if (amount > 0) {
            layoutStruct.collectedProtocolFees[token] = 0;
        }
    }

    /**
     * @notice Clear collected fees for a token and return the amount (default slot).
     * @param token The token to clear fees for.
     * @return amount Amount that was cleared.
     */
    function _clearCollectedFees(IERC20 token) internal returns (uint256 amount) {
        return _clearCollectedFees(_layoutStruct(), token);
    }
}
