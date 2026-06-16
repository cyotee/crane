// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

// Libraries

// Test Contracts
import {Actor} from "@crane/contracts/protocols/lending/aave/v3.6/utils/Actor.sol";
import {BaseHandler} from "test/foundry/spec/protocols/lending/aave/3.6/invariants/base/BaseHandler.t.sol";
import {TestnetERC20} from "@crane/contracts/protocols/lending/aave/v3.6/utils/mocks/testnet-helpers/TestnetERC20.sol";

/// @title DonationAttackHandler
/// @notice Handler test contract for a set of actions
contract DonationAttackHandler is BaseHandler {
    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                      STATE VARIABLES                                      //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                          ACTIONS                                          //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice This function transfers any amount of assets to a contract in the system simulating
    /// a big range of donation attacks
    function donateUnderlyingToAToken(uint256 amount, uint8 i) external {
        TestnetERC20 _token = TestnetERC20(_getRandomBaseAsset(i));

        _token.mint(address(this), amount);

        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        _token.transfer(protocolTokens[address(_token)].aTokenAddress, amount);
    }

    function donateUnderlyingToPool(uint256 amount, uint8 i) external {
        TestnetERC20 _token = TestnetERC20(_getRandomBaseAsset(i));

        _token.mint(address(this), amount);

        // forge-lint: disable-next-line(erc20-unchecked-transfer)
        _token.transfer(address(pool), amount);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                         OWNER ACTIONS                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                           HELPERS                                         //
    ///////////////////////////////////////////////////////////////////////////////////////////////
}
