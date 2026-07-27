// SPDX-License-Identifier: GPL-2.0-or-later
// Ported from morpho-org/morpho-blue@55d2d99304fb3fb930c688462ae2ccabb1d533ad (v1.0.0) — path: test/forge/helpers/SigUtils.sol
pragma solidity ^0.8.0;

import {AUTHORIZATION_TYPEHASH} from "@crane/contracts/external/morpho/blue/libraries/ConstantsLib.sol";

import {Authorization} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";

library SigUtils {
    /// @dev Computes the hash of the EIP-712 encoded data.
    function getTypedDataHash(bytes32 domainSeparator, Authorization memory authorization)
        public
        pure
        returns (bytes32)
    {
        return keccak256(bytes.concat("\x19\x01", domainSeparator, hashStruct(authorization)));
    }

    function hashStruct(Authorization memory authorization) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                AUTHORIZATION_TYPEHASH,
                authorization.authorizer,
                authorization.authorized,
                authorization.isAuthorized,
                authorization.nonce,
                authorization.deadline
            )
        );
    }
}
