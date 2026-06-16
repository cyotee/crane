// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

// tag::IPermit2Aware[]
/**
 * @title IPermit2Aware
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Interface for contracts that depend on / are aware of a Permit2 contract (for signature-based and allowance-based token transfers).
 * @dev Follows the Permit2 integration pattern used across Crane token standards (e.g. ERC4626) and utilities. The concrete reference is typically injected via Permit2AwareRepo (see its closed LR-1/LR-6 treatment for consistency).
 * @dev This is a simple surface (one function); interfaceId is the XOR of declared selectors (permit2 selector). No @custom:interfaceid is present because CENTRALLY_COMPUTED_NATSPEC_VALUES.md contains no entry for IPermit2Aware (prose only; values populated centrally in follow-up).
 */
interface IPermit2Aware {
    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::permit2()[]
    /// @notice Returns the Permit2 contract used by this aware implementation.
    /// @return permit2_ The Permit2 contract interface (IPermit2).
    function permit2() external view returns (IPermit2);
    // end::permit2()[]
}
// end::IPermit2Aware[]
