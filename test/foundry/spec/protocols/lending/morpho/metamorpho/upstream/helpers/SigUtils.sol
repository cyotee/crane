// SPDX-License-Identifier: GPL-2.0-or-later
// Ported from morpho-org/metamorpho-v1.1@bcc003108c0fbb9f715566207c52a1d3f279c5c3 — path: test/helpers/SigUtils.sol
pragma solidity ^0.8.0;

import {MessageHashUtils} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";

struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;
    uint256 deadline;
}

bytes32 constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

library SigUtils {
    function toTypedDataHash(bytes32 domainSeparator, Permit memory permit) internal pure returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(
            domainSeparator,
            keccak256(
                abi.encode(PERMIT_TYPEHASH, permit.owner, permit.spender, permit.value, permit.nonce, permit.deadline)
            )
        );
    }
}
