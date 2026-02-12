// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA as SoladyECDSA} from "@crane/contracts/solady/utils/ECDSA.sol";

/**
 * @dev OpenZeppelin-compatible ECDSA library using Solady's ECDSA.
 * @notice Native Crane implementation - no external dependencies
 *
 * Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error.
     * This will not return address(0) without also returning an error.
     *
     * If no error, the address can be used for verification purposes.
     *
     * This differs from `recoverSigner` in that it returns an error rather than reverting.
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal view returns (address signer, bool valid) {
        signer = SoladyECDSA.tryRecover(hash, signature);
        valid = signer != address(0);
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature`.
     *
     * The `hash` should have been the result of hashing with keccak256.
     *
     * Requirements:
     * - `signature` must be a valid signature.
     */
    function recover(bytes32 hash, bytes memory signature) internal view returns (address) {
        return SoladyECDSA.recover(hash, signature);
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address signer, bool valid) {
        signer = SoladyECDSA.tryRecover(hash, r, vs);
        valid = signer != address(0);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address) {
        return SoladyECDSA.recover(hash, r, vs);
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (address signer, bool valid) {
        signer = SoladyECDSA.tryRecover(hash, v, r, s);
        valid = signer != address(0);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (address) {
        return SoladyECDSA.recover(hash, v, r, s);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`.
     *
     * This produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return SoladyECDSA.toEthSignedMessageHash(hash);
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`.
     *
     * This produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return SoladyECDSA.toEthSignedMessageHash(s);
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`.
     *
     * This produces hash corresponding to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}
