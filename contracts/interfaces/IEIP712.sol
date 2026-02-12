// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// tag::IEIP712[]
/// @title IEIP712
/// @notice Interface for EIP-712 domain separator
/// @custom:interfaceid 0x3644e515
interface IEIP712 {
    /// @notice Returns the domain separator for the current chain.
    /// @custom:signature DOMAIN_SEPARATOR()
    /// @custom:selector 0x3644e515
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// end::IEIP712[]
