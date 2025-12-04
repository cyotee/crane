// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3AuthenticationRepo.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/BalancerV3VaultAwareRepo.sol";
import {IAuthentication} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IAuthentication.sol";

library BalancerV3AuthenticationService {

    /// @dev Reverts unless the caller is allowed to call the entry point function.
    function authenticateCaller(address where) internal view {
        bytes32 actionId = BalancerV3AuthenticationRepo._getActionId(msg.sig);

        if (!canPerform(actionId, msg.sender, where)) {
            revert IAuthentication.SenderNotAllowed();
        }
    }

    /**
     * @dev Derived contracts may implement this function to perform the divergent access control logic.
     * @param actionId The action identifier associated with an external function
     * @param user The account performing the action
     * @return success True if the action is permitted
     */
    function canPerform(bytes32 actionId, address user, address where) internal view returns (bool) {
        return BalancerV3VaultAwareRepo._balancerV3Vault().getAuthorizer().canPerform(actionId, user, where);
    }
}