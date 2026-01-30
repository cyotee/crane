// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

// tag::IPermit2Aware[]
/// @title IPermit2Aware
/// @notice Interface for contracts that are aware of the Permit2 contract
interface IPermit2Aware {
    /// @notice Returns the Permit2 contract address
    /// @return The Permit2 contract interface
    function permit2() external view returns (IPermit2);
}
// end::IPermit2Aware[]
