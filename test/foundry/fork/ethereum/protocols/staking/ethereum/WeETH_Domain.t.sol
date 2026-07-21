// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {WeETH} from "@crane/contracts/external/etherfi/core/WeETH.sol";

/// @notice Proves vendored ether.fi WeETH domain compiles (constructor wiring).
contract WeETH_DomainTest is Test {
    function test_Domain_WeETH_BytecodePresent() public {
        address eeth = address(0xE1);
        address pool = address(0xE2);
        address roles = address(0xE3);
        address bl = address(0xE4);
        WeETH w = new WeETH(eeth, pool, roles, bl);
        assertEq(address(w.eETH()), eeth);
        assertEq(address(w.liquidityPool()), pool);
    }
}
