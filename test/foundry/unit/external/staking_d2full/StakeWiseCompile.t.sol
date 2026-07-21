// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {OsToken} from "@crane/contracts/external/stakewise/tokens/OsToken.sol";
import {OsTokenVaultController} from "@crane/contracts/external/stakewise/tokens/OsTokenVaultController.sol";
contract StakeWiseCompileTest is Test {
    function test_OsTokenDeploys() public {
        OsToken t = new OsToken(address(this), address(this), "osETH", "osETH");
        assertEq(t.name(), "osETH");
    }
}
