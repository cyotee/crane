// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Test} from "forge-std/Test.sol";
import {WeETH} from "@crane/contracts/external/etherfi/core/WeETH.sol";
import {EETH} from "@crane/contracts/external/etherfi/core/EETH.sol";
contract EtherFiCompileTest is Test {
    function test_WeETHBytecode() public {
        // just force compile of import graph
        assertTrue(type(WeETH).creationCode.length > 100);
        assertTrue(type(EETH).creationCode.length > 100);
    }
}
