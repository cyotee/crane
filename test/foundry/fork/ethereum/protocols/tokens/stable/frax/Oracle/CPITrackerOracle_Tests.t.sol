// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/CPITrackerOracle-Tests.js`
/// @dev Forks mainnet and exercises time-warped oracle reads (JS logged values; we assert invariants).

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CPITrackerOracle} from "@crane/contracts/protocols/tokens/stable/frax/Oracle/CPITrackerOracle.sol";
import {TestBase_FraxEthereumFork, FraxEthereumAddresses} from "../TestBase_FraxEthereumFork.sol";

contract CPITrackerOracle_Tests is TestBase_FraxEthereumFork {
    CPITrackerOracle internal oracle;
    IERC20 internal link;

    function setUp() public {
        _forkEthereum();
        oracle = CPITrackerOracle(FraxEthereumAddresses.CPI_TRACKER_ORACLE);
        link = IERC20(FraxEthereumAddresses.LINK);
    }

    function test_Main_fundOracleWithLink() public {
        uint256 amount = 100e18;
        vm.prank(FraxEthereumAddresses.LINK_WHALE);
        link.transfer(address(oracle), amount);
        assertGe(link.balanceOf(address(oracle)), amount);
    }

    function test_MainScript_timeWarpedReads() public {
        _assertOracleSnapshot("week0");

        vm.warp(block.timestamp + 14 days);
        _assertOracleSnapshot("week2");

        vm.warp(block.timestamp + 14 days);
        _assertOracleSnapshot("week4");

        vm.warp(block.timestamp + 7 days);
        _assertOracleSnapshot("week5");
    }

    function _assertOracleSnapshot(string memory) internal view {
        assertGt(oracle.peg_price_last(), 0);
        assertGt(oracle.peg_price_target(), 0);
        assertGt(oracle.cpi_last(), 0);
        assertGt(oracle.cpi_target(), 0);
        assertGt(oracle.currPegPrice(), 0);
        assertLe(oracle.currDeltaFracE6(), 1e6);

        (uint256 year, uint256 month,) = oracle.upcomingCPIParams();
        assertGt(year, 2000);
        assertGt(month, 0);
        assertLt(month, 13);

        string memory serie = oracle.upcomingSerie();
        assertTrue(bytes(serie).length > 0);
    }
}
