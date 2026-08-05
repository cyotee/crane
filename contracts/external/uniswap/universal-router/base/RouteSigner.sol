// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {EIP712} from '@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/EIP712.sol';
import {ECDSA} from '@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/ECDSA.sol';

/// @title RouteSigner
/// @notice Contract for managing signed execution context using transient storage
abstract contract RouteSigner is EIP712 {
    /// @notice Transient storage slot for the route signer address
    /// @dev bytes32(uint256(keccak256("RouteSigner")) - 1)
    bytes32 private constant ROUTE_SIGNER_SLOT = 0xd317c76a4357223a1868125ee857a1f31cabfcec288f6cdd0ea8c52b6a71ee31;

    /// @notice Transient storage slot for the route intent
    /// @dev bytes32(uint256(keccak256("RouteIntent")) - 1)
    bytes32 private constant ROUTE_INTENT_SLOT = 0xa42de8dec63499ed8713dc6815ea14006a1f8e80e1664c66e3beb461bb65b0da;

    /// @notice Transient storage slot for the route data
    /// @dev bytes32(uint256(keccak256("RouteData")) - 1)
    bytes32 private constant ROUTE_DATA_SLOT = 0x17350132762f24cc4b86e10621ea1e0b5c33483a51cca86a1b11e7ed029b6eb6;

    /// @notice EIP712 typehash for signed execution
    bytes32 internal constant EXECUTE_SIGNED_TYPEHASH = keccak256(
        'ExecuteSigned(bytes commands,bytes[] inputs,bytes32 intent,bytes32 data,address sender,bytes32 nonce,uint256 deadline)'
    );

    /// @notice Mapping of used nonces for replay protection
    /// @dev Unordered nonces allow parallel execution of signed routes
    mapping(address user => mapping(bytes32 nonce => bool used)) public noncesUsed;

    /// @notice Thrown when a nonce has already been used
    error NonceAlreadyUsed();

    /// @dev EIP-712 ExecuteSigned field bundle (keeps abi.encode stack under limit without via_ir).
    struct ExecuteSignedFields {
        bytes32 commandsHash;
        bytes32 inputsHash;
        bytes32 intent;
        bytes32 data;
        address sender;
        bytes32 nonce;
        uint256 deadline;
    }

    /// @dev Stores the signature context (signer, intent, data) in transient storage
    function _setSignatureContext(
        bytes calldata commands,
        bytes[] calldata inputs,
        bytes32 intent,
        bytes32 data,
        bool verifySender,
        bytes32 nonce,
        bytes calldata signature,
        uint256 deadline
    ) internal returns (address signer) {
        ExecuteSignedFields memory fields;
        fields.commandsHash = keccak256(commands);
        fields.inputsHash = _hashInputs(inputs);
        fields.intent = intent;
        fields.data = data;
        fields.sender = verifySender ? msg.sender : address(0);
        fields.nonce = nonce;
        fields.deadline = deadline;

        bytes32 digest = _hashTypedDataV4(_executeSignedStructHash(fields));
        signer = ECDSA.recover(digest, signature);

        // Check and mark nonce as used (skip if nonce == bytes32(type(uint256).max))
        if (nonce != bytes32(type(uint256).max)) {
            if (noncesUsed[signer][nonce]) revert NonceAlreadyUsed();
            noncesUsed[signer][nonce] = true;
        }

        // Store signer, intent, and data in transient storage
        assembly ('memory-safe') {
            tstore(ROUTE_SIGNER_SLOT, signer)
            tstore(ROUTE_INTENT_SLOT, intent)
            tstore(ROUTE_DATA_SLOT, data)
        }
    }

    function _hashInputs(bytes[] calldata inputs) private pure returns (bytes32 inputsHash) {
        uint256 inputsLength = inputs.length;
        bytes32[] memory inputHashes = new bytes32[](inputsLength);
        for (uint256 i = 0; i < inputsLength; ++i) {
            inputHashes[i] = keccak256(inputs[i]);
        }
        inputsHash = keccak256(abi.encodePacked(inputHashes));
    }

    function _executeSignedStructHash(ExecuteSignedFields memory f) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                EXECUTE_SIGNED_TYPEHASH,
                f.commandsHash,
                f.inputsHash,
                f.intent,
                f.data,
                f.sender,
                f.nonce,
                f.deadline
            )
        );
    }

    /// @dev Clears the signature context from transient storage
    function _resetSignatureContext() internal {
        assembly ('memory-safe') {
            tstore(ROUTE_SIGNER_SLOT, 0)
            tstore(ROUTE_INTENT_SLOT, 0)
            tstore(ROUTE_DATA_SLOT, 0)
        }
    }

    /// @dev Internal function to read signed route context from transient storage
    function _signedRouteContext() internal view returns (address signer, bytes32 intent, bytes32 data) {
        assembly ('memory-safe') {
            signer := tload(ROUTE_SIGNER_SLOT)
            intent := tload(ROUTE_INTENT_SLOT)
            data := tload(ROUTE_DATA_SLOT)
        }
    }
}
