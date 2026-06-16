// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IAToken} from "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IAToken.sol";
import {TestnetProcedures} from "../../utils/TestnetProcedures.sol";
import {Errors} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/helpers/Errors.sol";

contract ATokenModifiersTests is TestnetProcedures {
    IAToken public aToken;

    function setUp() public {
        initTestEnvironment();

        address aUSDX = contracts.poolProxy.getReserveAToken(tokenList.usdx);
        aToken = IAToken(aUSDX);
    }

    function test_revert_notAdmin_mint() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBePool.selector));

        vm.prank(alice);

        aToken.mint(alice, alice, 1, 1);
    }

    function test_revert_notAdmin_burn() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBePool.selector));

        vm.prank(alice);

        aToken.burn(alice, alice, 1, 1, 1);
    }

    function test_revert_notAdmin_transferOnLiquidation() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBePool.selector));

        vm.prank(alice);

        aToken.transferOnLiquidation(alice, alice, 1, 1, 1);
    }

    function test_revert_notAdmin_transferUnderlyingTo() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerMustBePool.selector));

        vm.prank(alice);

        aToken.transferUnderlyingTo(alice, 1);
    }
}
