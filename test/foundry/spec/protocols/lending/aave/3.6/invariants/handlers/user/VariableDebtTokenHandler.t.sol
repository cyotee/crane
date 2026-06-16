// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {
    ICreditDelegationToken
} from "@crane/contracts/protocols/lending/aave/v3.6/interfaces/ICreditDelegationToken.sol";

// Libraries

// Test Contracts
import {Actor} from "@crane/contracts/protocols/lending/aave/v3.6/utils/Actor.sol";
import {BaseHandler} from "test/foundry/spec/protocols/lending/aave/3.6/invariants/base/BaseHandler.t.sol";

/// @title VariableDebtTokenHandler
/// @notice Handler test contract for a set of actions
contract VariableDebtTokenHandler is BaseHandler {
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      STATE VARIABLES                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                          ACTIONS                                          //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    function approveDelegation(uint256 amount, uint8 i, uint8 j) external setup {
        bool success;
        bytes memory returnData;

        // Get one of the three actors randomly
        address delegatee = _getRandomActor(i);

        address target = _getRandomDebtToken(j);

        (success, returnData) = actor.proxy(
            target, abi.encodeWithSelector(ICreditDelegationToken.approveDelegation.selector, delegatee, amount)
        );

        if (success) {
            assert(true);
        } else {
            revert("VariableDebtTokenHandler: approveDelegation failed");
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                         OWNER ACTIONS                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                           HELPERS                                         //
    ///////////////////////////////////////////////////////////////////////////////////////////////
}
