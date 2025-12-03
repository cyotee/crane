// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {SignatureTransfer} from "./SignatureTransfer.sol";
import {AllowanceTransfer} from "./AllowanceTransfer.sol";
import {IEIP712} from "contracts/interfaces/IEIP712.sol";
import {EIP712} from "contracts/protocols/utils/permit2/EIP712.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
contract BetterPermit2 is SignatureTransfer, AllowanceTransfer {
    // Permit2 unifies the two contracts so users have maximal flexibility with their approval.

    /// @notice Returns the domain separator for the current chain.
    /// @dev Uses cached version if chainid and address are unchanged from construction.
    function DOMAIN_SEPARATOR() public view override(IEIP712, EIP712, SignatureTransfer) returns (bytes32) {
        return SignatureTransfer.DOMAIN_SEPARATOR();
    }
}
