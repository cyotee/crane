// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFeeModule} from "./IFeeModule.sol";

/// @title ICustomFeeModule
/// @notice Interface for fee modules that support custom per-pool fee overrides
/// @dev Ported from Slipstream (Solidity 0.7.6) to Solidity 0.8.x
interface ICustomFeeModule is IFeeModule {
    /// @notice Emitted when a custom fee is set for a pool
    /// @param pool The pool address
    /// @param fee The custom fee that was set
    event CustomFeeSet(address indexed pool, uint24 indexed fee);

    /// @notice Returns the custom fee for a given pool if set, otherwise returns 0
    /// @dev Can use default fee by setting the fee to 0, can set zero fee by setting to ZERO_FEE_INDICATOR
    /// @param _pool The pool to get the custom fee for
    /// @return The custom fee for the given pool
    function customFee(address _pool) external view returns (uint24);

    /// @notice Sets a custom fee for a given pool
    /// @dev Can use default fee by setting the fee to 0, can set zero fee by setting to ZERO_FEE_INDICATOR
    /// @dev Must be called by the current fee manager
    /// @param _pool The pool to set the custom fee for
    /// @param _fee The fee to set for the given pool
    function setCustomFee(address _pool, uint24 _fee) external;
}
