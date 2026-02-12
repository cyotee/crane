// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

import {IAllowanceTransfer} from "@crane/contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "@crane/contracts/interfaces/protocols/utils/permit2/ISignatureTransfer.sol";

library PermitHash {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(asm-keccak256)
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");

    /// forge-lint: disable-next-line(asm-keccak256)
    bytes32 public constant _PERMIT_SINGLE_TYPEHASH = keccak256(
        "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    /// forge-lint: disable-next-line(asm-keccak256)
    bytes32 public constant _PERMIT_BATCH_TYPEHASH = keccak256(
        "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    /// forge-lint: disable-next-line(asm-keccak256)
    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    /// forge-lint: disable-next-line(asm-keccak256)
    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    /// forge-lint: disable-next-line(asm-keccak256)
    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    string public constant _TOKEN_PERMISSIONS_TYPESTRING = "TokenPermissions(address token,uint256 amount)";

    string public constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    string public constant _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB =
        "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,";

    function hash(IAllowanceTransfer.PermitSingle memory permitSingle) internal pure returns (bytes32) {
        bytes32 permitHash = _hashPermitDetails(permitSingle.details);
        // return keccak256(abi.encode(_PERMIT_SINGLE_TYPEHASH, permitHash, permitSingle.spender, permitSingle.sigDeadline));
        return abi.encode(_PERMIT_SINGLE_TYPEHASH, permitHash, permitSingle.spender, permitSingle.sigDeadline)._hash();
    }

    function hash(IAllowanceTransfer.PermitBatch memory permitBatch) internal pure returns (bytes32) {
        uint256 numPermits = permitBatch.details.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitDetails(permitBatch.details[i]);
        }
        // return keccak256(
        //     abi.encode(
        //         _PERMIT_BATCH_TYPEHASH,
        //         keccak256(abi.encodePacked(permitHashes)),
        //         permitBatch.spender,
        //         permitBatch.sigDeadline
        //     )
        // );
        return abi.encode(
                _PERMIT_BATCH_TYPEHASH,
                abi.encodePacked(permitHashes)._hash(),
                permitBatch.spender,
                permitBatch.sigDeadline
            )._hash();
    }

    function hash(ISignatureTransfer.PermitTransferFrom memory permit) internal view returns (bytes32) {
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        // return keccak256(
        //     abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline)
        // );
        return abi.encode(
                _PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline
            )._hash();
    }

    function hash(ISignatureTransfer.PermitBatchTransferFrom memory permit) internal view returns (bytes32) {
        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        // return keccak256(
        //     abi.encode(
        //         _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
        //         keccak256(abi.encodePacked(tokenPermissionHashes)),
        //         msg.sender,
        //         permit.nonce,
        //         permit.deadline
        //     )
        // );
        return abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                abi.encodePacked(tokenPermissionHashes)._hash(),
                msg.sender,
                permit.nonce,
                permit.deadline
            )._hash();
    }

    function hashWithWitness(
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        // bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeString));
        bytes32 typeHash = abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeString)._hash();

        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        // return keccak256(abi.encode(typeHash, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline, witness));
        return abi.encode(typeHash, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline, witness)._hash();
    }

    function hashWithWitness(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        // bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, witnessTypeString));
        bytes32 typeHash = abi.encodePacked(_PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, witnessTypeString)._hash();

        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        // return keccak256(
        //     abi.encode(
        //         typeHash,
        //         keccak256(abi.encodePacked(tokenPermissionHashes)),
        //         msg.sender,
        //         permit.nonce,
        //         permit.deadline
        //         witness
        //     )
        // );
        return abi.encode(
                typeHash,
                abi.encodePacked(tokenPermissionHashes)._hash(),
                msg.sender,
                permit.nonce,
                permit.deadline,
                witness
            )._hash();
    }

    function _hashPermitDetails(IAllowanceTransfer.PermitDetails memory details) private pure returns (bytes32) {
        // return keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, details));
        return abi.encode(_PERMIT_DETAILS_TYPEHASH, details)._hash();
    }

    function _hashTokenPermissions(ISignatureTransfer.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        // return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
        return abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted)._hash();
    }
}
