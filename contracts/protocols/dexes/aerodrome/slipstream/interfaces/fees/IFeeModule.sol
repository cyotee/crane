// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICLFactory} from "../ICLFactory.sol";

/// @title IFeeModule
/// @notice Interface for fee modules that can dynamically adjust pool fees
/// @dev Ported from Slipstream (Solidity 0.7.6) to Solidity 0.8.x
interface IFeeModule {
    /// @notice Get the factory that the fee module belongs to
    function factory() external view returns (ICLFactory);

    /// @notice Get fee for a given pool. Accounts for default and dynamic fees
    /// @dev Fee is denominated in pips (1e-6)
    /// @param _pool The pool to get the fee for
    /// @return The fee for the given pool
    function getFee(address _pool) external view returns (uint24);
}
