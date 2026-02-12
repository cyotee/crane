// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// tag::IERC1271[]
/// @notice ERC-1271 signature validation interface
/// @dev Ported from Uniswap Permit2
interface IERC1271 {
    /// @notice Returns whether the signature is valid for the provided hash.
    /// @custom:signature isValidSignature(bytes32,bytes)
    /// @custom:selector 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}
// end::IERC1271[]
