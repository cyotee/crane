// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";

/**
 * @title IBalancerPoolToken
 * @author cyotee doge <doge.cyotee>
 * @notice Interface for BalancerPoolToken from Balancer V3 Monorepo.
 */
interface IBalancerPoolToken is IRateProvider {
    /**
     * @dev Emit the Transfer event. This function can only be called by the MultiToken.
     * @custom:selector 0x23de6651
     */
    function emitTransfer(address from, address to, uint256 amount) external;

    /**
     * @dev Emit the Approval event. This function can only be called by the MultiToken.
     * @custom:selector 0x5687f2b8
     */
    function emitApproval(address owner, address spender, uint256 amount) external;
}
